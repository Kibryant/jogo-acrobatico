# Criterion 2 of TASK-10.7, probe C (rede.md §4, "A sonda C"; F-025 §3): one fighter lands on the
# head of another under netfox's rollback of 7 ticks on every loop, the depth of a 220 ms ping at 60
# ticks, and every resimulated tick is compared with the fresh one. The probe of Desenho 2 found its
# last divergences there, 6 at 30 ticks and 32 at 60, up to 15 cm, all with one fighter standing on
# the other's head, and taking the fighters out of platform_floor_layers changed nothing (F-025 §3).
# This probe first ran before the head rule, on the code of that day (round A, 26/10/2026): 0
# divergences, the snap holding the top fighter on the dome until the walk off, and the old
# divergence back only with DEC-0037's reserve snap taken out; rede.md §4 keeps those numbers. Since
# the rule (round B), the same flights prove that it holds under the rollback: the top fighter still
# lands on the head, nothing diverges, the test-only probe down names the fighter below on every
# tick on the head, and the rules never take the head as floor.
#
# Two fighters of fighter.tscn, with the game's capsule, margin and contours, on a floor built here
# and nothing else. The one on top runs at the other, jumps, double jumps at the apex and lands on
# its head, which the engine calls floor up to 45° on the dome; the rule slides it off at 3 m/s
# (before the rule, it stood there). The route then waits HOLD_LOOPS without input, walks forward
# and rests on the floor. The one below stands still, or, in the flights of a moving head, walks at
# 1 m/s from the landing on. After every tick, on netfox's after_process_tick, the probe reads what
# the engine says of each body: is_on_floor(), get_floor_normal(), get_platform_velocity(), every
# collision of the move with its normal, and what a test-only move 5 cm down would hit, moving
# nothing (the probe the adapter also makes, Fighter._head_contact). A resimulated tick must give
# the fresh tick's facts, the normals and velocities within 0,000001; the SyncTest's observer
# compares the body and the whole state on the same ticks. The probe prints, for the gate's log and
# for rede.md §4: the divergences and the largest position error; whether the floor snap holds the
# top fighter on the dome, and for how long; how many ticks on the head the engine says floor with
# no collision of the move at a floor angle, the floor only from the snap, and what the probe down
# names then; whether the floor normal comes out equal on the fresh and the resimulated tick, and
# the largest difference; and the platform velocity on the head. The flights run every loop in one
# physics frame, as the SyncTest does, and the moving head also with a physics step between two
# loops, as the game runs its ticks (DEC-0040): Jolt only steps the kinematic bodies there, so a
# platform velocity would show there first.
#
# It runs with the fighter's own platform settings, only the world as a platform and nothing added
# on leaving one (Fighter.setup; TASK-10.7, choice 2), and again with Godot's defaults, every layer
# and the platform's velocity added on leaving, set here only, as the fighter had them before. It
# asserts what makes its numbers mean something (.claude/harness/registro.md, 10/10/2026): netfox
# resimulated every tick it owed, the top fighter's double jump fired, at least one landing on the
# head happened, and the route finished; and what the rule needs of the engine: zero divergences,
# the probe down naming the fighter below on every tick on the head, and no tick on the head where
# the rules stand. The other numbers are measures, printed and judged in rede.md §4.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const SyncObserver := preload("res://test/support/sync_observer.gd")
const FIGHTER_SCENE := preload("res://fighter/fighter.tscn")
const MOVEMENT_V0 := "res://data/movement_v0.tres"

## Ticks netfox rolls back on every loop: the depth of a 220 ms ping at 60 ticks (rede.md §4).
const DEPTH := 7
## A normal or a velocity resimulated farther than this from the fresh one is a divergence: the
## SyncTest's own (rede.md §4).
const TOLERANCE := SyncObserver.TOLERANCE
## rad: the slack the engine adds to floor_max_angle when it judges a floor
## (character_body_3d.cpp, FLOOR_ANGLE_THRESHOLD, Godot 4.7.2). An engine number, not a game one.
const FLOOR_ANGLE_THRESHOLD := 0.01
## Both fighters look down -Z: the top one's forward input runs it from +Z toward the one below.
const YAW := 0.0
## m: feet resting this high are on the other's head, whose top is 1,8 m above the only floor; the
## dome holds feet from 1,6 m (0,495 m off the axis) to 1,8 m (on it).
const HEAD_MIN_Y := 1.0
## m: how far down the test-only probe looks for what is under the feet, moving nothing: the
## distance of the wall run's probe (Fighter.WALL_PROBE_DISTANCE; TASK-10.7 plan, "Os fatos da
## cabeça").
const DOWN_PROBE := 0.05
## m: feet this low, on the floor, are off the head.
const FLOOR_MAX_Y := 0.5

# The world: one floor of 40 × 40 m, its top at y = 0, on the world's layer.
const FLOOR_SIZE := Vector3(40.0, 1.0, 40.0)
# The fighter below starts at the origin; the top one 2,5 m behind it on +Z.
const BELOW_START := Vector3.ZERO
const TOP_START_Z := 2.5
# The route of the top fighter, geometry of the test, not numbers of the game. It runs at
# RUN_UP_SPEED and presses the jump JUMP_FROM before the other's axis. At 60 ticks the jump's apex
# comes 21 ticks later at 1,2 m, where it presses the double jump, which peaks 1 m higher 19 ticks
# later; the feet fall back to the head's 1,8 m about 10 ticks after that. 50 ticks at 2,4 m/s
# cover the 2 m, and the feet are past 1,5 m while still 1 m off the axis, above the other's
# shoulders.
const RUN_UP_SPEED := 2.4
const JUMP_FROM := 2.0
# m: the off-centre flight runs this far beside the other's axis, so the dome's normal under the
# feet leans about asin(0,3 / 0,7) = 25° from the vertical; the centred ones run through it.
const OFF_CENTRE := 0.3
# The input of the fighter below in the flights of a moving head, while the other holds on it: to
# its right, +X, at a seventh of the run speed, 1 m/s.
const BELOW_WALK := Vector2(1.0 / 7.0, 0.0)
# Loops on the head without input, and on the floor after the walk off.
const HOLD_LOOPS := 40
const REST_LOOPS := 5
# A route that has not finished by then failed.
const MAX_LOOPS := 200

var _first_state_tick := 0


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	if NetworkRollback.before_loop.is_connected(_force_rollback):
		NetworkRollback.before_loop.disconnect(_force_rollback)
	NetfoxTicks.reset()


# The fighter's own platform settings (Fighter.setup; TASK-10.7, choice 2): only the world is a
# platform, and leaving one adds nothing, so a fighter's platform velocity never moves another.
func test_the_head_is_measured_under_the_rollback_with_the_fighters_platform_settings() -> void:
	for flight: Flight in _flights(false):
		var reading := await _fly(flight)
		_assert_measured(reading)


# Godot's defaults, the fighter's before TASK-10.7, set on the probe's fighters only: every layer
# is a platform, and leaving one adds its velocity.
func test_the_head_is_measured_under_the_rollback_with_the_engines_platform_defaults() -> void:
	for flight: Flight in _flights(true):
		var reading := await _fly(flight)
		_assert_measured(reading)


# The flights of one platform setting: centred, off-centre, and the moving head, all in one
# physics frame, and the moving head again with a physics step between two loops.
func _flights(engine_defaults: bool) -> Array[Flight]:
	var setting := "the engine's platform defaults" if engine_defaults else "the fighter's platform"
	var flights: Array[Flight] = []
	for kind: int in 4:
		var flight := Flight.new()
		flight.engine_defaults = engine_defaults
		flight.lateral = OFF_CENTRE if kind == 1 else 0.0
		flight.below_move = BELOW_WALK if kind >= 2 else Vector2.ZERO
		flight.stepped = kind == 3
		var route := "centred, the head still"
		if kind == 1:
			route = "%.2f m off the axis, the head still" % OFF_CENTRE
		elif kind >= 2:
			route = "centred, the head walking 1 m/s"
		flight.name = "%s, %s, %s" % [
			route,
			setting,
			"a physics step between loops" if flight.stepped else "every loop in one physics frame",
		]
		flights.append(flight)
	return flights


# The preconditions of a flight: what makes its numbers mean something.
func _assert_measured(reading: Reading) -> void:
	var message := "%s: %d ticks resimulated by the observer, %d by the probe, %d owed" % [
		reading.name,
		reading.observer_resimulated,
		reading.checks,
		reading.owed,
	]
	assert_int(reading.owed).override_failure_message(message).is_greater(0)
	assert_int(reading.observer_resimulated).override_failure_message(message).is_equal(
		reading.owed
	)
	assert_int(reading.checks).override_failure_message(message).is_equal(reading.owed)
	message = "%s: the top fighter's double jump never fired" % reading.name
	assert_bool(reading.double_jumped).override_failure_message(message).is_true()
	message = "%s: the top fighter never landed on the other's head" % reading.name
	assert_int(reading.head_landings).override_failure_message(message).is_greater(0)
	message = "%s: the route did not finish (%s)" % [reading.name, reading.route_end]
	assert_bool(reading.route_done).override_failure_message(message).is_true()
	# What the rule needs of the engine: the same answers on every resimulated tick, the fighter
	# below named on every tick on the head, the snap's ticks included, and the rules never
	# standing there (TASK-10.7, criterion 3).
	message = "%s: %d mismatches of the body and the state, %d and %d of the engine facts:\n%s" % [
		reading.name,
		reading.body_mismatches,
		reading.top_mismatches,
		reading.below_mismatches,
		"\n".join(reading.shown),
	]
	assert_int(reading.body_mismatches).override_failure_message(message).is_equal(0)
	assert_int(reading.top_mismatches + reading.below_mismatches) \
			.override_failure_message(message) \
			.is_equal(0)
	message = "%s: the probe down named the fighter below on %d of %d ticks on the head" % [
		reading.name,
		reading.under_fighter_ticks,
		reading.head_ticks,
	]
	assert_int(reading.under_fighter_ticks).override_failure_message(message).is_equal(
		reading.head_ticks
	)
	message = "%s: the rules stood on the head on %d ticks" % [
		reading.name,
		reading.head_floor_ticks,
	]
	assert_int(reading.head_floor_ticks).override_failure_message(message).is_equal(0)


func _config() -> MovementConfig:
	var resource: Resource = load(MOVEMENT_V0)
	assert(resource is MovementData, "%s must load as a MovementData" % MOVEMENT_V0)
	return MovementConfig.create(resource as MovementData, NetworkTime.tickrate)


# The world of the probe: a floor and nothing else, on the world's layer.
func _arena() -> Node3D:
	var arena := Node3D.new()
	arena.name = "Arena"
	var body := StaticBody3D.new()
	body.name = "Floor"
	body.collision_layer = PhysicsLayers.WORLD
	body.position = Vector3(0.0, -FLOOR_SIZE.y / 2.0, 0.0)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = FLOOR_SIZE
	collision.shape = shape
	body.add_child(collision)
	arena.add_child(body)
	return arena


# A fighter of fighter.tscn standing at start, and with the flight's platform settings.
func _fighter(arena: Node3D, config: MovementConfig, start: Vector3, flight: Flight) -> Fighter:
	var node := FIGHTER_SCENE.instantiate()
	assert(node is Fighter, "fighter.tscn must have a Fighter at its root")
	var fighter := node as Fighter
	fighter.setup(config, start, YAW, false)
	if flight.engine_defaults:
		var plain := CharacterBody3D.new()
		fighter.platform_floor_layers = plain.platform_floor_layers
		fighter.platform_on_leave = plain.platform_on_leave
		plain.free()
	arena.add_child(fighter)
	return fighter


# One flight through netfox's real tick loop, driven by hand (test/support/netfox_ticks.gd), with
# a rollback of DEPTH ticks on every loop. The fighter below enters the tree first, so it moves
# first in every tick; both have input on every tick.
func _fly(flight: Flight) -> Reading:
	var config := _config()
	var arena := _arena()
	var below := _fighter(arena, config, BELOW_START, flight)
	var top_start := BELOW_START + Vector3(flight.lateral, 0.0, TOP_START_Z)
	var top := _fighter(arena, config, top_start, flight)
	add_child(arena)
	await get_tree().process_frame
	await get_tree().physics_frame
	var first_tick := NetworkTime.tick
	_first_state_tick = first_tick
	for fighter: Fighter in [below, top]:
		var spawn_tick: int = fighter.synchronizer.spawn_tick
		_first_state_tick = maxi(_first_state_tick, spawn_tick)
	var recorder := HeadRecorder.new(top, below)
	var watched: Array[Fighter] = [below, top]
	var observer := SyncObserver.new(flight.name, watched)
	var bot := HeadBot.new(top, below, RUN_UP_SPEED / config.run_speed)
	NetworkRollback.before_loop.connect(_force_rollback)
	for loop: int in MAX_LOOPS:
		if flight.stepped and loop > 0:
			await get_tree().physics_frame
		bot.drive()
		if bot.phase == HeadBot.Phase.DONE:
			break
		var below_move := flight.below_move if bot.phase == HeadBot.Phase.HOLD else Vector2.ZERO
		below.input.sample_frame(below_move, YAW)
		NetfoxTicks.run_loop()
	NetworkRollback.before_loop.disconnect(_force_rollback)
	recorder.stop()
	observer.stop()
	print(observer.summary())
	for line: String in observer.shown:
		print("  ", line)
	var reading := Reading.new(flight.name, recorder, bot.walk_off_tick)
	reading.owed = _owed_resimulations(first_tick, NetworkTime.tick)
	reading.observer_resimulated = observer.resimulated_ticks
	reading.body_mismatches = observer.mismatches
	reading.max_error = observer.max_error
	reading.route_done = bot.phase == HeadBot.Phase.DONE
	reading.route_end = bot.ending
	reading.platform_layers = top.platform_floor_layers
	reading.platform_on_leave = top.platform_on_leave
	print(reading.summary())
	for line: String in recorder.shown:
		print("  ", line)
	arena.free()
	NetfoxTicks.reset()
	return reading


# On netfox's before_loop, as the SyncTest does: notify_resimulation_start keeps the oldest tick
# asked for, and nothing older than the first recorded state can be restored.
func _force_rollback() -> void:
	NetworkRollback.notify_resimulation_start(maxi(NetworkTime.tick - DEPTH, _first_state_tick))


# The resimulations netfox owes a flight up to the loop that ends at present: the loop of a fresh
# tick t restores the state of max(t + 1 - DEPTH, first state) and simulates from there to t.
func _owed_resimulations(first_tick: int, present: int) -> int:
	var owed := 0
	for tick: int in range(first_tick, present):
		var from := mini(tick, maxi(tick + 1 - DEPTH, _first_state_tick))
		owed += tick - from
	return owed


# What a flight is: beside or through the other's axis, how it is run, and the platform setting.
class Flight:
	extends RefCounted

	var name: String
	## m: how far beside the other's axis the top fighter runs, along +X.
	var lateral := 0.0
	## A physics step between two loops, as the game runs its ticks (DEC-0040); otherwise every
	## loop runs inside one physics frame, as the SyncTest runs them.
	var stepped := false
	## platform_floor_layers and platform_on_leave as Godot leaves them, every layer and the
	## platform's velocity added on leaving; otherwise as Fighter.setup sets them.
	var engine_defaults := false
	## The input of the fighter below while the top one holds on its head: none, the head still.
	var below_move := Vector2.ZERO


# The top fighter's route, before each loop, reading the state on screen through the calls the
# keyboard uses (FighterInput.sample_frame and press_jump): it runs at the other, jumps JUMP_FROM
# before its axis, double jumps at the apex with no direction, so the speed carries, and lands on
# the head; it waits HOLD_LOOPS without input, where it slides off (before the rule, it stood
# there), walks forward, off the head if still on it, and rests on the floor.
class HeadBot:
	extends RefCounted

	enum Phase {
		RUN,
		RISE,
		DOUBLE,
		HOLD,
		WALK_OFF,
		REST,
		DONE,
	}

	var phase := Phase.RUN
	## The first tick of the walk off, NEVER before it.
	var walk_off_tick := FighterState.NEVER
	## How the route ended, for the failure message.
	var ending := "running"

	var _top: Fighter
	var _below: Fighter
	var _fraction: float
	var _phase_loops := 0


	func _init(top: Fighter, below: Fighter, fraction: float) -> void:
		_top = top
		_below = below
		_fraction = fraction


	func drive() -> void:
		var state := _top.state
		var run_up := Vector2(0.0, _fraction)
		match phase:
			Phase.RUN:
				_top.input.sample_frame(run_up, YAW)
				if state.on_floor and _top.position.z - _below.position.z <= JUMP_FROM:
					_top.input.press_jump()
					phase = Phase.RISE
			Phase.RISE:
				var at_apex := _top.velocity.y <= 0.0
				if not state.on_floor and state.jumps_used == 1 and at_apex:
					_top.input.sample_frame(Vector2.ZERO, YAW)
					_top.input.press_jump()
					phase = Phase.DOUBLE
				else:
					_top.input.sample_frame(run_up, YAW)
			Phase.DOUBLE:
				_top.input.sample_frame(Vector2.ZERO, YAW)
				if state.on_floor and _top.position.y > HEAD_MIN_Y:
					_enter(Phase.HOLD)
				elif state.on_floor:
					ending = "landed on the floor at %s, not on the head" % _top.position
					_enter(Phase.DONE)
			Phase.HOLD:
				_phase_loops += 1
				if _phase_loops > HOLD_LOOPS:
					walk_off_tick = NetworkTime.tick
					_top.input.sample_frame(Vector2(0.0, 1.0), YAW)
					_enter(Phase.WALK_OFF)
				else:
					_top.input.sample_frame(Vector2.ZERO, YAW)
			Phase.WALK_OFF:
				if state.on_floor and _top.position.y < FLOOR_MAX_Y:
					_top.input.sample_frame(Vector2.ZERO, YAW)
					_enter(Phase.REST)
				else:
					_top.input.sample_frame(Vector2(0.0, 1.0), YAW)
			Phase.REST:
				_phase_loops += 1
				_top.input.sample_frame(Vector2.ZERO, YAW)
				if _phase_loops > REST_LOOPS:
					ending = "done"
					_enter(Phase.DONE)


	func _enter(next: Phase) -> void:
		phase = next
		_phase_loops = 0


# What the engine says of one body right after the tick's move: the floor flag, its normal, the
# platform's velocity, every collision of the move, and what a test-only move down would hit.
class EngineFacts:
	extends RefCounted

	var position: Vector3
	var velocity: Vector3
	var on_floor := false
	var floor_normal := Vector3.ZERO
	var platform_velocity := Vector3.ZERO
	## What a test-only move DOWN_PROBE down would hit, moving nothing: &"fighter", &"world" or
	## &"" for nothing, and the normal of the hit.
	var under: StringName = &""
	var under_normal := Vector3.ZERO
	## Every collision of the move, in the engine's order: whether its collider is a fighter, and
	## its normal.
	var slide_fighters: Array[bool] = []
	var slide_normals: Array[Vector3] = []
	## Collisions of the move at a floor angle, and of those the ones with a fighter.
	var floor_slides := 0
	var fighter_floor_slides := 0
	## The fighter's own state after the tick: the jumps of the flight, the double jump's tick, and
	## whether the rules stand (Movement.stands).
	var jumps_used := 0
	var double_jump_tick := FighterState.NEVER
	var stands := false


	static func read(fighter: Fighter) -> EngineFacts:
		var facts := EngineFacts.new()
		facts.position = fighter.position
		facts.velocity = fighter.velocity
		facts.on_floor = fighter.is_on_floor()
		facts.floor_normal = fighter.get_floor_normal()
		facts.platform_velocity = fighter.get_platform_velocity()
		var hit := fighter.move_and_collide(Vector3.DOWN * DOWN_PROBE, true)
		if hit != null:
			facts.under = &"fighter" if hit.get_collider() is Fighter else &"world"
			facts.under_normal = hit.get_normal()
		var floor_angle := fighter.floor_max_angle + FLOOR_ANGLE_THRESHOLD
		for slide: int in fighter.get_slide_collision_count():
			var collision := fighter.get_slide_collision(slide)
			for index: int in collision.get_collision_count():
				var is_fighter := collision.get_collider(index) is Fighter
				var normal := collision.get_normal(index)
				facts.slide_fighters.append(is_fighter)
				facts.slide_normals.append(normal)
				if normal.angle_to(Vector3.UP) <= floor_angle:
					facts.floor_slides += 1
					if is_fighter:
						facts.fighter_floor_slides += 1
		facts.jumps_used = fighter.state.jumps_used
		facts.double_jump_tick = fighter.state.double_jump_tick
		facts.stands = Movement.stands(fighter.state)
		return facts


	func on_head() -> bool:
		return on_floor and position.y > HEAD_MIN_Y


	# What differs between the fresh facts of a tick and a resimulation's, by kind.
	func differences(again: EngineFacts) -> Dictionary[String, String]:
		var found: Dictionary[String, String] = { }
		if position.distance_to(again.position) > TOLERANCE:
			found["position"] = "%s then %s" % [position, again.position]
		if velocity.distance_to(again.velocity) > TOLERANCE:
			found["velocity"] = "%s then %s" % [velocity, again.velocity]
		if on_floor != again.on_floor:
			found["on_floor"] = "%s then %s" % [on_floor, again.on_floor]
		if floor_normal.distance_to(again.floor_normal) > TOLERANCE:
			found["floor_normal"] = "%s then %s" % [floor_normal, again.floor_normal]
		if platform_velocity.distance_to(again.platform_velocity) > TOLERANCE:
			found["platform_velocity"] = (
				"%s then %s" % [platform_velocity, again.platform_velocity]
			)
		if under != again.under:
			found["under"] = "%s then %s" % [under, again.under]
		elif under_normal.distance_to(again.under_normal) > TOLERANCE:
			found["under_normal"] = "%s then %s" % [under_normal, again.under_normal]
		if slide_fighters != again.slide_fighters:
			found["slides"] = "%s then %s" % [slide_fighters, again.slide_fighters]
		else:
			for index: int in slide_normals.size():
				var first := slide_normals[index]
				var second := again.slide_normals[index]
				if first.distance_to(second) > TOLERANCE:
					found["slide_normal"] = "%d %s then %s" % [index, first, second]
		return found


# Reads the engine facts of both fighters after every simulated tick, on netfox's
# after_process_tick, which comes after every fighter of the tick has moved: the first reading of
# a tick is the fresh one, and every resimulation of the same tick is compared with it.
class HeadRecorder:
	extends RefCounted

	## How many divergences the log describes.
	const SHOWN := 6

	## The fresh facts of the top fighter and of the one below, by tick, and the fresh ticks in
	## order.
	var fresh_top: Dictionary[int, EngineFacts] = { }
	var fresh_below: Dictionary[int, EngineFacts] = { }
	var ticks: Array[int] = []
	## One check per resimulated tick, both fighters at once.
	var checks := 0
	## Resimulated ticks whose facts differ: of the top fighter, of the one below, those whose
	## fresh tick had the top fighter on the head, and those that were the first tick of their
	## loop, where contour D runs.
	var top_mismatches := 0
	var below_mismatches := 0
	var head_mismatches := 0
	var first_tick_mismatches := 0
	## How many resimulated ticks differ in each kind of fact, for either fighter.
	var kinds: Dictionary[String, int] = { }
	## The largest differences between a fresh and a resimulated tick: the top fighter's floor
	## normal and platform velocity, and the floor normal on the head ticks only.
	var floor_normal_apart := 0.0
	var head_floor_normal_apart := 0.0
	var platform_velocity_apart := 0.0
	var shown: Array[String] = []

	var _top: Fighter
	var _below: Fighter
	var _newest: int
	var _loop_from := 0
	var _loop_starting := false


	func _init(top: Fighter, below: Fighter) -> void:
		_top = top
		_below = below
		_newest = NetworkTime.tick - 1
		NetworkRollback.before_loop.connect(_on_loop_start)
		NetworkRollback.after_process_tick.connect(_observe)


	func stop() -> void:
		NetworkRollback.before_loop.disconnect(_on_loop_start)
		NetworkRollback.after_process_tick.disconnect(_observe)


	func _on_loop_start() -> void:
		_loop_starting = true


	# netfox simulates a tick for the first time as the last tick of its loop, so a tick newer than
	# every tick seen is fresh and any other is a resimulation.
	func _observe(tick: int) -> void:
		if _loop_starting:
			_loop_starting = false
			_loop_from = tick
		var top := EngineFacts.read(_top)
		var below := EngineFacts.read(_below)
		if tick > _newest:
			_newest = tick
			fresh_top[tick] = top
			fresh_below[tick] = below
			ticks.append(tick)
			return
		checks += 1
		var fresh := fresh_top[tick]
		floor_normal_apart = maxf(
			floor_normal_apart,
			fresh.floor_normal.distance_to(top.floor_normal),
		)
		if fresh.on_head():
			head_floor_normal_apart = maxf(
				head_floor_normal_apart,
				fresh.floor_normal.distance_to(top.floor_normal),
			)
		platform_velocity_apart = maxf(
			platform_velocity_apart,
			fresh.platform_velocity.distance_to(top.platform_velocity),
		)
		var top_found := fresh.differences(top)
		var below_found := fresh_below[tick].differences(below)
		if top_found.is_empty() and below_found.is_empty():
			return
		if not top_found.is_empty():
			top_mismatches += 1
		if not below_found.is_empty():
			below_mismatches += 1
		if fresh.on_head():
			head_mismatches += 1
		if tick == _loop_from:
			first_tick_mismatches += 1
		var seen: Dictionary[String, bool] = { }
		for kind: String in top_found.keys() + below_found.keys():
			if not seen.has(kind):
				seen[kind] = true
				var count: int = kinds.get(kind, 0)
				kinds[kind] = count + 1
		if shown.size() < SHOWN:
			shown.append(
				(
					"tick %d, rolled back to tick %d, top on the head %s: top %s; below %s"
					% [tick, _loop_from, fresh.on_head(), top_found, below_found]
				),
			)


# What a flight showed: the comparison of every resimulated tick, the preconditions, and the
# measures of the head, from the fresh facts in tick order.
class Reading:
	extends RefCounted

	var name: String
	var checks := 0
	var owed := 0
	var observer_resimulated := 0
	var body_mismatches := 0
	var max_error := 0.0
	var route_done := false
	var route_end := ""
	var platform_layers := 0
	var platform_on_leave := 0

	var top_mismatches := 0
	var below_mismatches := 0
	var head_mismatches := 0
	var first_tick_mismatches := 0
	var kinds: Dictionary[String, int] = { }
	var floor_normal_apart := 0.0
	var head_floor_normal_apart := 0.0
	var platform_velocity_apart := 0.0

	## The preconditions: the top fighter's double jump fired, and how many times it came onto the
	## head from off it.
	var double_jumped := false
	var head_landings := 0
	## The measures on the fresh ticks of the top fighter: ticks on the head; of those, how many
	## the move collided at a floor angle with nothing, the floor only from the snap, and with the
	## other fighter; the first landing and the last tick of that stay; whether it left the head
	## before the walk off; the dome's angle under the feet; the farthest the feet got from the
	## other's axis; the platform velocity, its largest length and the ticks it was not zero; and
	## the ticks the test-only probe down named the other fighter, and of those the ones whose
	## floor came only from the snap.
	var head_ticks := 0
	var snap_only_ticks := 0
	var fighter_floor_ticks := 0
	var first_landing := FighterState.NEVER
	var stay_end := FighterState.NEVER
	var left_before_walk_off := false
	var walk_off_tick := FighterState.NEVER
	var dome_min_deg := INF
	var dome_max_deg := -INF
	var farthest_off_axis := 0.0
	var platform_speed_max := 0.0
	var platform_moving_ticks := 0
	var under_fighter_ticks := 0
	var snap_only_under_fighter := 0
	## Ticks on the head where the rules stood, as if it were floor: none since the head rule.
	var head_floor_ticks := 0
	## Ticks on the head the shown errors came from.
	var shown: Array[String] = []
	## m: how far the fighter below drifted from where it started.
	var below_drift := 0.0
	## One mark per head tick, in order: F the move collided with the fighter below at a floor
	## angle, S the floor came only from the snap, W only the world collided at a floor angle; a
	## bar where the walk off begins.
	var marks: Array[String] = []


	# The marks in runs: FFFSS reads F3 S2.
	func pattern() -> String:
		var runs: Array[String] = []
		var index := 0
		while index < marks.size():
			var length := 1
			while index + length < marks.size() and marks[index + length] == marks[index]:
				length += 1
			runs.append(marks[index] if marks[index] == "|" else "%s%d" % [marks[index], length])
			index += length
		return " ".join(runs)


	func _init(flight_name: String, recorder: HeadRecorder, walk_off: int) -> void:
		name = flight_name
		checks = recorder.checks
		top_mismatches = recorder.top_mismatches
		below_mismatches = recorder.below_mismatches
		head_mismatches = recorder.head_mismatches
		first_tick_mismatches = recorder.first_tick_mismatches
		kinds = recorder.kinds
		floor_normal_apart = recorder.floor_normal_apart
		head_floor_normal_apart = recorder.head_floor_normal_apart
		platform_velocity_apart = recorder.platform_velocity_apart
		shown = recorder.shown
		walk_off_tick = walk_off
		_measure(recorder)


	func _measure(recorder: HeadRecorder) -> void:
		var was_on_head := false
		var start := Vector3.INF
		for tick: int in recorder.ticks:
			var top := recorder.fresh_top[tick]
			var below := recorder.fresh_below[tick]
			if start == Vector3.INF:
				start = below.position
			below_drift = maxf(below_drift, below.position.distance_to(start))
			if top.double_jump_tick != FighterState.NEVER:
				double_jumped = true
			var on_head := top.on_head()
			if on_head and not was_on_head:
				head_landings += 1
				if first_landing == FighterState.NEVER:
					first_landing = tick
			if was_on_head and not on_head and stay_end == FighterState.NEVER:
				stay_end = tick - 1
				left_before_walk_off = walk_off_tick == FighterState.NEVER or tick < walk_off_tick
			was_on_head = on_head
			if not on_head:
				continue
			head_ticks += 1
			if top.stands:
				head_floor_ticks += 1
			var mark := "W"
			if top.floor_slides == 0:
				snap_only_ticks += 1
				mark = "S"
			if top.fighter_floor_slides > 0:
				fighter_floor_ticks += 1
				mark = "F"
			if walk_off_tick != FighterState.NEVER and tick == walk_off_tick:
				marks.append("|")
			marks.append(mark)
			if walk_off_tick == FighterState.NEVER or tick < walk_off_tick:
				var dome := rad_to_deg(top.floor_normal.angle_to(Vector3.UP))
				dome_min_deg = minf(dome_min_deg, dome)
				dome_max_deg = maxf(dome_max_deg, dome)
			var off_axis := Vector2(
				top.position.x - below.position.x,
				top.position.z - below.position.z,
			)
			farthest_off_axis = maxf(farthest_off_axis, off_axis.length())
			var platform_speed := top.platform_velocity.length()
			platform_speed_max = maxf(platform_speed_max, platform_speed)
			if platform_speed > 0.0:
				platform_moving_ticks += 1
			if top.under == &"fighter":
				under_fighter_ticks += 1
				if top.floor_slides == 0:
					snap_only_under_fighter += 1


	func summary() -> String:
		var line := (
			"Probe C, %s: platform_floor_layers=%d platform_on_leave=%d; %d resimulated of %d"
			+ " owed; body and state: %d mismatches, max_err_m=%s; engine facts: %d mismatches"
			+ " of the top fighter, %d of the one below, %d with the top on the head, %d on the"
			+ " first tick of a loop, by kind %s; floor normal apart up to %s (%s on the head);"
			+ " platform velocity apart up to %s; double jump %s; %d landings on the head, first"
			+ " on tick %d, stayed to tick %d, left before the walk off (tick %d): %s; %d ticks"
			+ " on the head: %d with no collision of the move at a floor angle, %d colliding with"
			+ " the fighter below at a floor angle (%s); dome %.3f..%.3f° before the walk off,"
			+ " feet up to %.4f m off the axis; the test-only probe down names the fighter below"
			+ " on %d head ticks, %d of them with no collision of the move at a floor angle;"
			+ " platform velocity up to %s m/s, not zero on %d head ticks; the rules stood on"
			+ " the head on %d ticks; the fighter below drifted %s m"
		) % [
			name,
			platform_layers,
			platform_on_leave,
			checks,
			owed,
			body_mismatches,
			String.num_scientific(max_error),
			top_mismatches,
			below_mismatches,
			head_mismatches,
			first_tick_mismatches,
			kinds,
			String.num_scientific(floor_normal_apart),
			String.num_scientific(head_floor_normal_apart),
			String.num_scientific(platform_velocity_apart),
			"fired" if double_jumped else "never fired",
			head_landings,
			first_landing,
			stay_end,
			walk_off_tick,
			left_before_walk_off,
			head_ticks,
			snap_only_ticks,
			fighter_floor_ticks,
			pattern(),
			dome_min_deg,
			dome_max_deg,
			farthest_off_axis,
			under_fighter_ticks,
			snap_only_under_fighter,
			String.num_scientific(platform_speed_max),
			platform_moving_ticks,
			head_floor_ticks,
			String.num_scientific(below_drift),
		]
		return line
