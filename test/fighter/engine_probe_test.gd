# Criterion 1 of TASK-10.5, probe A (rede.md §4; DEC-0042 §4): before any wall rule, the facts the
# engine gives about a wall go through netfox's rollback of 7 ticks on every loop, the depth of a
# 220 ms ping at 60 ticks, and every resimulated tick must give them as the fresh one did. The
# floor had a flag of the engine's own that the rollback did not undo (DEC-0025); this probe asks
# the same of the wall. A fighter of fighter.tscn, with the game's capsule, margin and contours,
# flies along a wall built here: two colliders meet at a seam, and the second ends in an outer
# corner. The fighter hits the wall at an angle and slides along it, crosses the seam and passes
# the corner; it also runs parallel to it, 0 to 4.5 cm off. After every tick the probe reads what
# the wall run's adapter will read (DEC-0042 §1): the move's own collisions (get_slide_collision)
# and the test-only probe 5 cm into the wall (move_and_collide with test_only), each as contact,
# normal and the collider's path relative to the arena. Each flight proves its preconditions (a
# probe asserts what it needs, .claude/harness/registro.md, 10/10/2026): netfox resimulated every
# tick it owed, and the flight hit the wall, crossed the seam in contact and let go at the corner.
#
# No wall rule exists yet, so the fighter holds its height the way the wall run will ("Altura
# mantida", movimento.md, "Corrida na parede"): its config is a copy without gravity, and in the
# air without input the core keeps the velocity, as the run keeps its speed along the wall after
# the entry, the input neither turning nor braking it. One flight keeps the gravity: a hit while
# rising, and a slide while falling. The geometry is the test's own, so the arena never changes
# what this proves. Each flight prints two lines for the gate's log: the SyncTest observer's, the
# body and the whole state, and the probe's, the wall facts and what they measured.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const SyncObserver := preload("res://test/support/sync_observer.gd")
const FIGHTER_SCENE := preload("res://fighter/fighter.tscn")
const MOVEMENT_V0 := "res://data/movement_v0.tres"

## Ticks netfox rolls back on every loop: the depth of a 220 ms ping at 60 ticks (rede.md §4).
const DEPTH := 7
## A normal resimulated farther than this from the fresh one is a divergence: the SyncTest's own.
const TOLERANCE := SyncObserver.TOLERANCE
## m: how far into the wall the test-only probe reaches (TASK-10.5, choice 2; DEC-0042 §1).
const PROBE_DISTANCE := 0.05
## m/s: the push into the wall held in reserve, should the probe lose the seam (TASK-10.5, choice
## 2); measured here only.
const STICK_SPEED := 1.0
## m/s: the speed on the wall (movimento.md, "Corrida na parede": "Velocidade na parede").
const WALL_SPEED := 8.0
## The face of the test wall looks down +Z, and the fighter flies along +X on that side.
const FACE_NORMAL := Vector3.BACK
## yaw 0 looks down -Z: move.x goes along +X, and move.y goes down -Z, into the wall.
const YAW := 0.0

# The test wall: its face is the plane z = 0, from y = -6 to 6, so the falling flight stays beside
# it. The west collider spans x -4..0 and the east one x 0..3: the seam is at x = 0, and the outer
# corner, where the east collider's end face turns away, at x = 3.
const WALL_WEST := &"WallWest"
const WALL_EAST := &"WallEast"
const WALL_FROM_X := -4.0
const SEAM_X := 0.0
const CORNER_X := 3.0
const WALL_THICKNESS := 1.0
const WALL_HEIGHT := 12.0
# m: the feet of every flight start here, with the whole capsule beside the wall.
const FLIGHT_Y := 1.0

# The hit: 0.6 m off the wall at 30° into it, at the wall speed. It meets the west collider about
# 1.5 m before the seam, at 4 m/s into it, slides on at 6.93 m/s and lets go past the corner
# around its 50th tick.
const HIT_FROM := Vector2(-2.5, 0.6)
const HIT_ANGLE_DEG := 30.0
const HIT_LOOPS := 58
# The parallel runs start 1.5 m before the seam and let go past the corner around the 37th tick.
const PARALLEL_FROM_X := -1.5
const PARALLEL_LOOPS := 42
# m: a probe that reaches 5 cm finds no wall from 6 cm off.
const OUT_OF_REACH := 0.06

var _first_state_tick := 0


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	if NetworkRollback.before_loop.is_connected(_force_rollback):
		NetworkRollback.before_loop.disconnect(_force_rollback)
	NetfoxTicks.reset()


# (a), (b) and (c): the hit at an angle, the slide along the wall, the seam and the corner. The
# same flight is built three times: the second build runs every loop in one physics frame too, as
# the SyncTest does, and the third takes a physics step between two loops, as the game runs them
# (DEC-0040). A fourth flight keeps the gravity: it hits the wall rising, crosses the seam near
# its apex and slides on falling. A collider's path is the same on every build and every tick;
# the engine's instance id and RID are printed, to tell whether they change between builds.
func test_the_wall_facts_of_a_hit_a_seam_and_a_corner_come_out_equal_when_resimulated() -> void:
	var first := await _fly(_hit("hit"))
	var again := await _fly(_hit("hit, built again"))
	var stepped_flight := _hit("hit, built again with a physics step between loops")
	stepped_flight.stepped = true
	var stepped := await _fly(stepped_flight)
	var falling_flight := _hit("hit with gravity, rising then falling")
	falling_flight.gravity = true
	falling_flight.velocity.y = _base_config().jump_speed
	var falling := await _fly(falling_flight)

	for reading: Reading in [first, again, stepped, falling]:
		_assert_resimulated_unchanged(reading)
		_assert_met_the_wall(reading)
		# The hit is the move's own collision with the west collider, and the body slides on.
		var message := "%s: the move never collided with the wall" % reading.name
		assert_int(reading.hit_index).override_failure_message(message).is_not_equal(-1)
		assert_str(reading.hit_path).is_equal(WALL_WEST)
		assert_float(reading.slowest).is_greater(0.0)
	# The fourth hit the wall rising and slid along it falling.
	assert_float(falling.hit_vertical).is_greater(0.0)
	assert_int(falling.falling_beside).is_greater(0)

	print(
		(
			(
				"Probe A, the engine's ids of the colliders on three builds:"
				+ " %s %s / %s / %s; %s %s / %s / %s"
			)
			% [
				WALL_WEST,
				first.ids_of(WALL_WEST),
				again.ids_of(WALL_WEST),
				stepped.ids_of(WALL_WEST),
				WALL_EAST,
				first.ids_of(WALL_EAST),
				again.ids_of(WALL_EAST),
				stepped.ids_of(WALL_EAST),
			]
		)
	)
	for other: Reading in [again, stepped]:
		print("Probe A, %s against %s: %s" % [other.name, first.name, first.compare(other)])
		# The path names the same collider on every tick of every build (DEC-0042 §2).
		var message := "%s: the contact paths differ from the first build" % other.name
		assert_array(other.contact_paths()).override_failure_message(message).is_equal(
			first.contact_paths()
		)


# (d): parallel to the wall at the wall speed, the vertical zeroed, 0 to 4.5 cm off it. The
# test-only probe keeps the contact on every tick beside the wall, the seam's included, which is
# what the wall run's adapter needs (DEC-0042 §1); the move's own collisions are only measured.
func test_the_test_only_probe_holds_the_wall_while_running_parallel_across_the_seam(
	gap: float,
	_test_parameters := [[0.0], [0.01], [0.025], [0.045]],
) -> void:
	var reading := await _fly(_parallel("parallel %.1f cm off" % (gap * 100.0), gap))
	_assert_resimulated_unchanged(reading)
	_assert_met_the_wall(reading)
	var message := "%s: %d of %d ticks beside the wall without the probe, %d at the seam" % [
		reading.name,
		reading.probe_misses,
		reading.beside,
		reading.seam_probe_misses,
	]
	assert_int(reading.probe_misses).override_failure_message(message).is_equal(0)
	assert_int(reading.seam_ticks).is_greater(0)


# The probe can say no: 6 cm off, out of its 5 cm reach, it finds no wall on any tick of a run
# from before the seam to past the corner, and the move collides with nothing.
func test_the_probe_finds_no_wall_out_of_its_reach() -> void:
	var reading := await _fly(_parallel("parallel out of reach", OUT_OF_REACH))
	_assert_resimulated_unchanged(reading)
	assert_int(reading.first_contact).is_equal(-1)
	assert_float(reading.facts[0].position.x).is_less(SEAM_X)
	assert_float(reading.facts[-1].position.x).is_greater(CORNER_X)


# The alternative held in reserve, measured against the probe: a push of 1 m/s into the wall on
# every tick, the "stick" (TASK-10.5, choice 2). Its line in the log reads against the line of
# the parallel run touching the wall: how often the move collides, how often the probe holds, the
# speed along the wall at the seam, and how often the push stays in the velocity the engine hands
# back.
func test_the_stick_alternative_is_measured_against_the_probe() -> void:
	var flight := _parallel("stick, 1 m/s into the wall", 0.0)
	flight.move = Vector2(WALL_SPEED, STICK_SPEED).normalized()
	flight.move_speed = Vector2(WALL_SPEED, STICK_SPEED).length()
	flight.velocity = Vector3(WALL_SPEED, 0.0, -STICK_SPEED)
	var reading := await _fly(flight)
	_assert_resimulated_unchanged(reading)
	_assert_met_the_wall(reading)


func _assert_resimulated_unchanged(reading: Reading) -> void:
	var message := "%s: %d ticks resimulated, %d owed" % [
		reading.name,
		reading.checks,
		reading.owed,
	]
	assert_int(reading.owed).override_failure_message(message).is_greater(0)
	assert_int(reading.checks).override_failure_message(message).is_equal(reading.owed)
	message = "%s: the wall facts diverged (hidden state):\n%s" % [
		reading.name,
		"\n".join(reading.shown),
	]
	assert_int(reading.mismatches).override_failure_message(message).is_equal(0)
	message = "%s: the body diverged:\n%s" % [reading.name, "\n".join(reading.body_shown)]
	assert_int(reading.body_mismatches).override_failure_message(message).is_equal(0)


# The preconditions of a flight along the wall: it touched the wall, crossed the seam in contact
# on both sides, was still in contact with its axis past the face's end, and let go past the
# corner.
func _assert_met_the_wall(reading: Reading) -> void:
	var message := "%s never touched the wall" % reading.name
	assert_int(reading.first_contact).override_failure_message(message).is_not_equal(-1)
	message = "%s did not cross the seam in contact" % reading.name
	assert_bool(reading.crossed_seam).override_failure_message(message).is_true()
	message = "%s did not reach the corner in contact" % reading.name
	assert_bool(reading.met_corner).override_failure_message(message).is_true()
	message = "%s did not let go past the corner" % reading.name
	assert_bool(reading.left_at_corner).override_failure_message(message).is_true()


func _hit(flight_name: String) -> Flight:
	var radius := _base_config().capsule_radius
	var angle := deg_to_rad(HIT_ANGLE_DEG)
	var flight := Flight.new()
	flight.name = flight_name
	flight.start = Vector3(HIT_FROM.x, FLIGHT_Y, radius + HIT_FROM.y)
	flight.velocity = Vector3(cos(angle), 0.0, -sin(angle)) * WALL_SPEED
	flight.loops = HIT_LOOPS
	return flight


func _parallel(flight_name: String, gap: float) -> Flight:
	var radius := _base_config().capsule_radius
	var flight := Flight.new()
	flight.name = flight_name
	flight.start = Vector3(PARALLEL_FROM_X, FLIGHT_Y, radius + gap)
	flight.velocity = Vector3(WALL_SPEED, 0.0, 0.0)
	flight.loops = PARALLEL_LOOPS
	return flight


func _base_config() -> MovementConfig:
	var resource: Resource = load(MOVEMENT_V0)
	assert(resource is MovementData, "%s must load as a MovementData" % MOVEMENT_V0)
	return MovementConfig.create(resource as MovementData, NetworkTime.tickrate)


# The movement numbers of a flight: a config of its own, so movement_v0.tres stays untouched.
# Without gravity the vertical stays at zero. A flight with input reaches the input's target in
# one tick, every tick: the stick's push.
func _config(flight: Flight) -> MovementConfig:
	var config := _base_config()
	if not flight.gravity:
		config.rise_gravity_per_tick = 0.0
		config.fall_gravity_per_tick = 0.0
	if flight.move != Vector2.ZERO:
		config.run_speed = flight.move_speed
		config.air_accel_per_tick = 2.0 * flight.move_speed
	return config


# The arena of the probe: the two colliders of the wall, on the world's layer, named so their
# paths relative to it are WallWest and WallEast.
func _arena() -> Node3D:
	var arena := Node3D.new()
	arena.name = "Arena"
	var west_length := SEAM_X - WALL_FROM_X
	var east_length := CORNER_X - SEAM_X
	_wall(arena, WALL_WEST, (WALL_FROM_X + SEAM_X) / 2.0, west_length)
	_wall(arena, WALL_EAST, (SEAM_X + CORNER_X) / 2.0, east_length)
	return arena


func _wall(arena: Node3D, wall_name: StringName, center_x: float, length: float) -> void:
	var body := StaticBody3D.new()
	body.name = wall_name
	body.collision_layer = PhysicsLayers.WORLD
	body.position = Vector3(center_x, 0.0, -WALL_THICKNESS / 2.0)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(length, WALL_HEIGHT, WALL_THICKNESS)
	collision.shape = shape
	body.add_child(collision)
	arena.add_child(body)


# One flight through netfox's real tick loop, driven by hand (test/support/netfox_ticks.gd), with
# a rollback of DEPTH ticks on every loop. The fighter is in the air from its first recorded
# state, at the flight's velocity: its synchronizer records both when it processes its settings,
# deferred to the next frame.
func _fly(flight: Flight) -> Reading:
	var arena := _arena()
	var config := _config(flight)
	var node := FIGHTER_SCENE.instantiate()
	assert(node is Fighter, "fighter.tscn must have a Fighter at its root")
	var fighter := node as Fighter
	fighter.setup(config, flight.start, YAW, true)
	fighter.state.on_floor = false
	fighter.state.mode = FighterState.Mode.AIR
	fighter.velocity = flight.velocity
	arena.add_child(fighter)
	add_child(arena)
	await get_tree().process_frame
	await get_tree().physics_frame
	var first_tick := NetworkTime.tick
	var spawn_tick: int = fighter.synchronizer.spawn_tick
	_first_state_tick = maxi(first_tick, spawn_tick)
	var recorder := WallRecorder.new(fighter, arena)
	var watched: Array[Fighter] = [fighter]
	var observer := SyncObserver.new(flight.name, watched)
	NetworkRollback.before_loop.connect(_force_rollback)
	for loop: int in flight.loops:
		if flight.stepped and loop > 0:
			await get_tree().physics_frame
		fighter.input.sample_frame(flight.move, YAW)
		NetfoxTicks.run_loop()
	NetworkRollback.before_loop.disconnect(_force_rollback)
	recorder.stop()
	observer.stop()
	print(observer.summary())
	var reading := Reading.new(flight.name, recorder, config.capsule_radius)
	reading.owed = _owed_resimulations(first_tick, NetworkTime.tick)
	reading.body_mismatches = observer.mismatches
	reading.body_shown = observer.shown
	print(reading.summary())
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


# What a flight is: where it starts, how fast, for how many loops, and how it is run.
class Flight:
	extends RefCounted

	var name: String
	var start: Vector3
	var velocity: Vector3
	var loops: int
	## The input of every tick, x along +X and y into the wall; none keeps the velocity in the air.
	var move := Vector2.ZERO
	## m/s: the speed the input aims at, when there is one.
	var move_speed := 0.0
	var gravity := false
	## A physics step between two loops, as the game runs its ticks (DEC-0040); otherwise every
	## loop runs inside one physics frame, as the SyncTest runs them.
	var stepped := false


# What the wall run's adapter reads after a move (DEC-0042 §1), and where the body was.
class WallFacts:
	extends RefCounted

	var position: Vector3
	var velocity: Vector3
	## Every collision of the move that is not a fighter, in the engine's order: the collider's
	## path relative to the arena, the normal, and the engine's instance id and RID.
	var slide_paths: Array[StringName] = []
	var slide_normals: Array[Vector3] = []
	var slide_ids: Array[int] = []
	var slide_rids: Array[RID] = []
	## The test-only probe, PROBE_DISTANCE into the wall from where the move left the body.
	var probe_contact := false
	var probe_normal := Vector3.ZERO
	var probe_path: StringName = &""
	var probe_id := 0
	var probe_rid := RID()


	# Reads the facts right after the tick's move: its collisions are still there, and nothing has
	# moved since. The probe is the call the adapter will make (TASK-10.5, notes).
	static func read(fighter: Fighter, arena: Node) -> WallFacts:
		var facts := WallFacts.new()
		facts.position = fighter.position
		facts.velocity = fighter.velocity
		for slide: int in fighter.get_slide_collision_count():
			var collision := fighter.get_slide_collision(slide)
			for index: int in collision.get_collision_count():
				var collider := collision.get_collider(index)
				if collider is Fighter:
					continue
				facts.slide_paths.append(path_of(arena, collider))
				facts.slide_normals.append(collision.get_normal(index))
				facts.slide_ids.append(collision.get_collider_id(index))
				facts.slide_rids.append(collision.get_collider_rid(index))
		var hit := fighter.move_and_collide(-FACE_NORMAL * PROBE_DISTANCE, true)
		if hit != null:
			facts.probe_contact = true
			facts.probe_normal = hit.get_normal()
			facts.probe_path = path_of(arena, hit.get_collider())
			facts.probe_id = hit.get_collider_id()
			facts.probe_rid = hit.get_collider_rid()
		return facts


	# The wall's identity in the state (DEC-0042 §2): the collider's node path relative to the
	# arena.
	static func path_of(arena: Node, collider: Object) -> StringName:
		assert(collider is Node, "every collider of the probe's world is a node")
		var node := collider as Node
		return StringName(str(arena.get_path_to(node)))


	# The contact the adapter takes from the move's collisions (DEC-0042 §1): the most horizontal
	# normal, the first in the engine's order on a tie; -1 without a collision.
	func slide_pick() -> int:
		var pick := -1
		for index: int in slide_normals.size():
			if pick < 0 or absf(slide_normals[index].y) < absf(slide_normals[pick].y):
				pick = index
		return pick


	# The contact of the tick as the wall run reads it: the probe's, else the move's.
	func contact_path() -> StringName:
		if probe_contact:
			return probe_path
		var pick := slide_pick()
		return slide_paths[pick] if pick >= 0 else &""


	func contact_normal() -> Vector3:
		if probe_contact:
			return probe_normal
		var pick := slide_pick()
		return slide_normals[pick] if pick >= 0 else Vector3.ZERO


	# What differs between the fresh facts of a tick and a resimulation's: the contact, every
	# normal within TOLERANCE, every path, and the engine's ids.
	func differences(again: WallFacts) -> Array[String]:
		var found: Array[String] = []
		if slide_paths != again.slide_paths:
			found.append("move collided with %s then %s" % [slide_paths, again.slide_paths])
		else:
			for index: int in slide_normals.size():
				var first := slide_normals[index]
				var second := again.slide_normals[index]
				if first.distance_to(second) > TOLERANCE:
					found.append("move normal %d %s then %s" % [index, first, second])
			if slide_ids != again.slide_ids or slide_rids != again.slide_rids:
				found.append(
					"move ids %s %s then %s %s"
					% [slide_ids, slide_rids, again.slide_ids, again.slide_rids]
				)
		if probe_contact != again.probe_contact:
			found.append("probe contact %s then %s" % [probe_contact, again.probe_contact])
		elif probe_contact:
			if probe_path != again.probe_path:
				found.append("probe path %s then %s" % [probe_path, again.probe_path])
			if probe_normal.distance_to(again.probe_normal) > TOLERANCE:
				found.append("probe normal %s then %s" % [probe_normal, again.probe_normal])
			if probe_id != again.probe_id or probe_rid != again.probe_rid:
				found.append(
					"probe ids %d %s then %d %s"
					% [probe_id, probe_rid, again.probe_id, again.probe_rid]
				)
		return found


# Reads the wall facts of one fighter after every simulated tick, on netfox's after_process_tick,
# which comes after every fighter of the tick has moved, the way the SyncTest's observer reads
# the state: the first reading of a tick is the fresh one, and every resimulation of the same tick
# is compared with it.
class WallRecorder:
	extends RefCounted

	## How many divergences the failure message describes.
	const SHOWN := 5

	## The fresh facts, by tick, and the fresh ticks in order.
	var fresh: Dictionary[int, WallFacts] = { }
	var ticks: Array[int] = []
	## One check per resimulated tick.
	var checks := 0
	var mismatches := 0
	var shown: Array[String] = []

	var _fighter: Fighter
	var _arena: Node
	var _newest: int
	var _loop_from := 0
	var _loop_starting := false


	func _init(fighter: Fighter, arena: Node) -> void:
		_fighter = fighter
		_arena = arena
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
		var facts := WallFacts.read(_fighter, _arena)
		if tick > _newest:
			_newest = tick
			fresh[tick] = facts
			ticks.append(tick)
			return
		checks += 1
		var differences := fresh[tick].differences(facts)
		if differences.is_empty():
			return
		mismatches += 1
		if shown.size() < SHOWN:
			shown.append(
				(
					"tick %d, rolled back to tick %d, at %s: %s"
					% [tick, _loop_from, facts.position, "; ".join(differences)]
				),
			)


# What a flight showed: the comparison of every resimulated tick, its preconditions and its
# measures, from the fresh facts in tick order.
class Reading:
	extends RefCounted

	var name: String
	var facts: Array[WallFacts] = []
	var checks := 0
	var owed := 0
	var mismatches := 0
	var shown: Array[String] = []
	var body_mismatches := 0
	var body_shown: Array[String] = []

	## The preconditions: the index of the first fresh tick with a contact, -1 for none; the seam
	## crossed in contact, west of it on WallWest and east of it on WallEast; a contact with the
	## capsule's axis past the face's full width, at the corner; and past the corner, none.
	var first_contact := -1
	var crossed_seam := false
	var met_corner := false
	var left_at_corner := false

	## The hit: the first tick whose move collided with the wall, the collider's path, its normal,
	## the velocity after the move, and the vertical velocity then.
	var hit_index := -1
	var hit_path: StringName = &""
	var hit_normal := Vector3.ZERO
	var hit_velocity := Vector3.ZERO
	var hit_vertical := 0.0

	## The measures, on the ticks from the first contact with the capsule's axis beside the face's
	## full width: how many, how many without a collision of the move, how many without the probe's
	## contact, and the same at the seam, where the capsule spans both colliders.
	var beside := 0
	var without_slide := 0
	var probe_misses := 0
	var seam_ticks := 0
	var seam_probe_misses := 0
	## Seam ticks whose move collided with both colliders at once.
	var seam_both := 0
	## The collider the probe named on each seam tick, W or E, and - for none.
	var seam_sequence := ""
	## Ticks beside the wall in contact while falling.
	var falling_beside := 0
	## How many times the probe's collider changed from one contact to the next.
	var probe_switches := 0
	## Degrees: the largest angle between a contact normal and the face's, beside the wall away from
	## the seam, at the seam, and at the corner.
	var face_deviation := 0.0
	var seam_deviation := 0.0
	var corner_deviation := 0.0
	## m/s: the speed along the wall beside it, and the slowest at the seam.
	var slowest := INF
	var fastest := -INF
	var slowest_at_seam := INF
	## m: the gap between the capsule and the face beside the wall.
	var nearest := INF
	var farthest := -INF
	## Ticks beside the wall whose velocity still pushes into it at half the stick's speed or more.
	var push_left := 0
	## Where the last contact was, its normal, and where the wall let go.
	var last_contact_x := -INF
	var last_contact_normal := Vector3.ZERO
	var left_x := INF


	func _init(flight_name: String, recorder: WallRecorder, radius: float) -> void:
		name = flight_name
		for tick: int in recorder.ticks:
			facts.append(recorder.fresh[tick])
		checks = recorder.checks
		mismatches = recorder.mismatches
		shown = recorder.shown
		_measure(radius)


	func _measure(radius: float) -> void:
		var west_before_seam := false
		var previous_probe: StringName = &""
		for index: int in facts.size():
			var tick_facts := facts[index]
			var x := tick_facts.position.x
			var path := tick_facts.contact_path()
			if first_contact < 0 and path != &"":
				first_contact = index
			if hit_index < 0 and not tick_facts.slide_paths.is_empty():
				_note_hit(index)
			if first_contact < 0:
				continue
			if path == WALL_WEST and x < SEAM_X:
				west_before_seam = true
			if west_before_seam and path == WALL_EAST and x > SEAM_X:
				crossed_seam = true
			if path != &"":
				last_contact_x = x
				last_contact_normal = tick_facts.contact_normal()
				if x > CORNER_X - radius:
					met_corner = true
					corner_deviation = maxf(corner_deviation, _off_face(last_contact_normal))
			elif met_corner and x > CORNER_X and not left_at_corner:
				left_at_corner = true
				left_x = x
			if tick_facts.probe_contact:
				if previous_probe != &"" and tick_facts.probe_path != previous_probe:
					probe_switches += 1
				previous_probe = tick_facts.probe_path
			if x >= WALL_FROM_X + radius and x <= CORNER_X - radius:
				_measure_beside(tick_facts, radius)


	func _note_hit(index: int) -> void:
		var tick_facts := facts[index]
		var pick := tick_facts.slide_pick()
		hit_index = index
		hit_path = tick_facts.slide_paths[pick]
		hit_normal = tick_facts.slide_normals[pick]
		hit_velocity = tick_facts.velocity
		hit_vertical = tick_facts.velocity.y


	func _measure_beside(tick_facts: WallFacts, radius: float) -> void:
		var x := tick_facts.position.x
		beside += 1
		if tick_facts.slide_paths.is_empty():
			without_slide += 1
		if not tick_facts.probe_contact:
			probe_misses += 1
		var along := tick_facts.velocity.x
		slowest = minf(slowest, along)
		fastest = maxf(fastest, along)
		var gap := tick_facts.position.z - radius
		nearest = minf(nearest, gap)
		farthest = maxf(farthest, gap)
		if tick_facts.velocity.z <= -STICK_SPEED / 2.0:
			push_left += 1
		var deviation := 0.0
		if tick_facts.contact_path() != &"":
			deviation = _off_face(tick_facts.contact_normal())
			if tick_facts.velocity.y < 0.0:
				falling_beside += 1
		for normal: Vector3 in tick_facts.slide_normals:
			deviation = maxf(deviation, _off_face(normal))
		if absf(x - SEAM_X) >= radius:
			face_deviation = maxf(face_deviation, deviation)
			return
		seam_deviation = maxf(seam_deviation, deviation)
		seam_ticks += 1
		slowest_at_seam = minf(slowest_at_seam, along)
		if not tick_facts.probe_contact:
			seam_probe_misses += 1
			seam_sequence += "-"
		else:
			seam_sequence += "W" if tick_facts.probe_path == WALL_WEST else "E"
		if WALL_WEST in tick_facts.slide_paths and WALL_EAST in tick_facts.slide_paths:
			seam_both += 1


	static func _off_face(normal: Vector3) -> float:
		return rad_to_deg(normal.angle_to(FACE_NORMAL))


	# The contact path of every fresh tick, "" without one.
	func contact_paths() -> Array[StringName]:
		var paths: Array[StringName] = []
		for tick_facts: WallFacts in facts:
			paths.append(tick_facts.contact_path())
		return paths


	# The engine's instance id and RID of the first contact on the collider at path, as text.
	func ids_of(path: StringName) -> String:
		for tick_facts: WallFacts in facts:
			if tick_facts.probe_contact and tick_facts.probe_path == path:
				return "id %d %s" % [tick_facts.probe_id, tick_facts.probe_rid]
			var index := tick_facts.slide_paths.find(path)
			if index >= 0:
				var rid := tick_facts.slide_rids[index]
				return "id %d %s" % [tick_facts.slide_ids[index], rid]
		return "never touched"


	# Tick by tick against another build of the same flight: the position, the contact paths and
	# the normals.
	func compare(other: Reading) -> String:
		var count := mini(facts.size(), other.facts.size())
		var farthest_apart := 0.0
		var normal_apart := 0.0
		var path_differences := 0
		for index: int in count:
			var mine := facts[index]
			var theirs := other.facts[index]
			farthest_apart = maxf(farthest_apart, mine.position.distance_to(theirs.position))
			if mine.contact_path() != theirs.contact_path():
				path_differences += 1
			var apart := mine.contact_normal().distance_to(theirs.contact_normal())
			normal_apart = maxf(normal_apart, apart)
		return (
			(
				"%d ticks of %d and %d, positions up to %s m apart, normals up to %s apart,"
				+ " %d paths differ"
			)
			% [
				count,
				facts.size(),
				other.facts.size(),
				String.num_scientific(farthest_apart),
				String.num_scientific(normal_apart),
				path_differences,
			]
		)


	func summary() -> String:
		var line := (
			"Probe A, %s: %d fresh ticks, %d resimulated of %d owed, %d wall-fact mismatches;"
			+ " first contact on tick %d, the move's hit on tick %d (%s, normal %s, velocity after"
			+ " %s); beside the wall %d ticks: %d without a collision of the move, %d without the"
			+ " probe; seam %d ticks, probe %s, %d without it, %d with the move on both colliders;"
			+ " %d probe switches; normals off the face up to %.4f° on it, %.4f° at the seam and"
			+ " %.4f° at the corner; along speed %.4f..%.4f m/s, %.4f at the seam; gap to the face"
			+ " %.5f..%.5f m; push left in the velocity on %d ticks; %d in contact falling; last"
			+ " contact at x %.3f, normal %s; let go at x %.3f"
		) % [
			name,
			facts.size(),
			checks,
			owed,
			mismatches,
			first_contact,
			hit_index,
			hit_path,
			hit_normal,
			hit_velocity,
			beside,
			without_slide,
			probe_misses,
			seam_ticks,
			seam_sequence,
			seam_probe_misses,
			seam_both,
			probe_switches,
			face_deviation,
			seam_deviation,
			corner_deviation,
			slowest,
			fastest,
			slowest_at_seam,
			nearest,
			farthest,
			push_left,
			falling_beside,
			last_contact_x,
			last_contact_normal,
			left_x,
		]
		return line
