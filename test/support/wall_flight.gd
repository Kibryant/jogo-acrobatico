# One flight of a fighter of fighter.tscn into a wall, through netfox's real tick loop driven by
# hand (test/support/netfox_ticks.gd), with a rollback of DEPTH ticks on every loop, the depth of
# a 220 ms ping at 60 ticks (rede.md §4): the shared rig of the head ray's tests (TASK-10.10,
# criteria 3 and 4; movimento.md, "Corrida na parede": "A parede passa da cabeça"). After every
# tick, on netfox's after_process_tick, which comes after the fighter moved, it asks the head ray
# (Fighter.covers_body) about the face it flies into: the first reading of a tick is the fresh
# one, and every resimulation of it must give the same answer, the way the probe of TASK-10.5
# read the wall facts (test/fighter/engine_probe_test.gd). The SyncTest's observer compares the
# state and the body on the same ticks. The fresh readings also say what the flight did: the
# colliders the move touched, the run's ticks, its entry and its end.
extends RefCounted

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const SyncObserver := preload("res://test/support/sync_observer.gd")
const FIGHTER_SCENE := preload("res://fighter/fighter.tscn")

## Ticks netfox rolls back on every loop (rede.md §4).
const DEPTH := 7
## How many divergences the failure message describes.
const SHOWN := 5

## The input of every loop, set before fly: the stick (x right, y forward) at this yaw, and the
## loop whose input presses the jump, -1 for none. A grounded flight starts standing on the floor,
## on its first recorded state; otherwise in the air.
var move := Vector2.ZERO
var yaw := 0.0
var jump_on_loop := -1
var grounded := false

var name: String
## One check per resimulated tick, and those whose head ray answered otherwise.
var checks := 0
var mismatches := 0
var shown: Array[String] = []
## The resimulations netfox owed the flight, and the observer's divergences of state and body.
var owed := 0
var body_mismatches := 0
var body_shown: Array[String] = []
## The colliders the move collided with on fresh ticks, by path relative to the arena.
var touched: Array[StringName] = []
## Fresh ticks with a contact (the move's or the test-only probe's), and those whose head ray
## found the face.
var contact_ticks := 0
var covered_on_contact := 0
## Fresh ticks in a wall run.
var run_ticks := 0
## The wall and the feet's height on the first fresh tick of the first run.
var entry_wall: StringName = &""
var entry_feet := INF
## Where the first run ended, the mode then, and whether the test-only probe still found a wall.
var end_position := Vector3.INF
var mode_at_end := -1
var probe_at_end := false
## The highest the feet went on a fresh tick.
var highest_feet := -INF

var _fighter: Fighter
var _arena: Node
var _face: Vector3
var _fresh: Dictionary[int, bool] = { }
var _newest: int
var _was_running := false
var _first_state_tick := 0


# A fighter of fighter.tscn under arena, set up with config at start, at velocity, its wall ids
# relative to arena: in the air, or standing on the floor as setup leaves it when on_floor. Call
# before arena enters the tree: netfox records the first state when the fighter's synchronizer
# processes its settings.
static func fighter_in(
	arena: Node3D,
	config: MovementConfig,
	start: Vector3,
	velocity: Vector3,
	on_floor := false,
) -> Fighter:
	var node := FIGHTER_SCENE.instantiate()
	assert(node is Fighter, "fighter.tscn must have a Fighter at its root")
	var fighter := node as Fighter
	fighter.setup(config, start, 0.0, true)
	fighter.arena = arena
	if not on_floor:
		fighter.state.on_floor = false
		fighter.state.mode = FighterState.Mode.AIR
	fighter.velocity = velocity
	arena.add_child(fighter)
	return fighter


# Flies a fighter from start at velocity, with the flight's input, for loops ticks, against the
# face whose normal is face; arena joins host's tree for the flight and is freed after it. Prints
# the observer's line and the flight's for the gate's log.
func fly(
	host: Node,
	flight_name: String,
	arena: Node3D,
	config: MovementConfig,
	start: Vector3,
	velocity: Vector3,
	face: Vector3,
	loops: int,
) -> void:
	var fighter := fighter_in(arena, config, start, velocity, grounded)
	host.add_child(arena)
	await host.get_tree().process_frame
	await host.get_tree().physics_frame
	name = flight_name
	_fighter = fighter
	_arena = arena
	_face = face
	var first_tick := NetworkTime.tick
	var spawn_tick: int = fighter.synchronizer.spawn_tick
	_first_state_tick = maxi(first_tick, spawn_tick)
	_newest = first_tick - 1
	var watched: Array[Fighter] = [fighter]
	var observer := SyncObserver.new(flight_name, watched)
	NetworkRollback.before_loop.connect(_force_rollback)
	NetworkRollback.after_process_tick.connect(_observe)
	for loop: int in loops:
		fighter.input.sample_frame(move, yaw)
		if loop == jump_on_loop:
			fighter.input.press_jump()
		NetfoxTicks.run_loop()
	NetworkRollback.after_process_tick.disconnect(_observe)
	NetworkRollback.before_loop.disconnect(_force_rollback)
	observer.stop()
	owed = _owed_resimulations(first_tick, NetworkTime.tick)
	body_mismatches = observer.mismatches
	body_shown = observer.shown
	print(observer.summary())
	print(summary())
	arena.free()
	NetfoxTicks.reset()


# On netfox's before_loop, as the SyncTest does: nothing older than the first recorded state can
# be restored.
func _force_rollback() -> void:
	NetworkRollback.notify_resimulation_start(maxi(NetworkTime.tick - DEPTH, _first_state_tick))


# The loop of a fresh tick t restores the state of max(t + 1 - DEPTH, first state) and simulates
# from there to t.
func _owed_resimulations(first_tick: int, present: int) -> int:
	var total := 0
	for tick: int in range(first_tick, present):
		var from := mini(tick, maxi(tick + 1 - DEPTH, _first_state_tick))
		total += tick - from
	return total


# netfox simulates a tick for the first time as the last tick of its loop, so a tick newer than
# every tick seen is fresh and any other is a resimulation.
func _observe(tick: int) -> void:
	var covered := _fighter.covers_body(_face)
	if tick <= _newest:
		if not _fresh.has(tick):
			return
		checks += 1
		if _fresh[tick] != covered:
			mismatches += 1
			if shown.size() < SHOWN:
				shown.append(
					"tick %d at %s: %s then %s" % [tick, _fighter.position, _fresh[tick], covered]
				)
		return
	_newest = tick
	_fresh[tick] = covered
	if _note_contact():
		contact_ticks += 1
		if covered:
			covered_on_contact += 1
	highest_feet = maxf(highest_feet, _fighter.position.y)
	var state := _fighter.state
	var running := state.mode == FighterState.Mode.WALL_RUN
	if running:
		run_ticks += 1
		if entry_wall.is_empty():
			entry_wall = state.wall_id
			entry_feet = _fighter.position.y
	elif _was_running and end_position == Vector3.INF:
		end_position = _fighter.position
		mode_at_end = state.mode
		probe_at_end = _probe() != null
	_was_running = running


# Notes the colliders this tick's move touched; true when it touched one, or the test-only probe
# finds one WALL_PROBE_DISTANCE into the face.
func _note_contact() -> bool:
	var contact := false
	for slide: int in _fighter.get_slide_collision_count():
		var collision := _fighter.get_slide_collision(slide)
		for index: int in collision.get_collision_count():
			var collider := collision.get_collider(index)
			if collider is not Node or collider is Fighter:
				continue
			var normal := collision.get_normal(index)
			if normal.dot(_face) < 0.9:
				continue
			contact = true
			var path := StringName(str(_arena.get_path_to(collider as Node)))
			if not touched.has(path):
				touched.append(path)
	return contact or _probe() != null


func _probe() -> KinematicCollision3D:
	return _fighter.move_and_collide(-_face * Fighter.WALL_PROBE_DISTANCE, true)


func summary() -> String:
	return (
		(
			"Head ray, %s: %d resimulated checks, %d mismatches; touched %s; %d contact ticks, %d"
			+ " covered; %d run ticks, entry on %s with the feet at %.3f m; run ended at %s,"
			+ " probe then %s"
		)
		% [
			name,
			checks,
			mismatches,
			touched,
			contact_ticks,
			covered_on_contact,
			run_ticks,
			entry_wall,
			entry_feet,
			end_position,
			probe_at_end,
		]
	)
