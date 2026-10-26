# Criterion 1 of TASK-10.6, probe B (DEC-0044 §4; rede.md §4; DEC-0025): before any grapple rule,
# the ray of the aim goes through netfox's rollback of 7 ticks on every loop, the depth of a 220 ms
# ping at 60 ticks, and every resimulated tick must find what the fresh one found. Probe A asked
# this of the wall facts (test/fighter/engine_probe_test.gd); the grapple's ray is longer, 25 m,
# and the reticle on screen casts the same ray outside the tick, in a process frame, so this probe
# asks both. Criterion 3 of TASK-10.11 runs it again with the camera over the shoulder: the ray
# leaves the point O, 0,8 m to the right of the shoulder, and a second ray from the shoulder to
# the point refuses a corner (DEC-0045 §2 and §3).
#
# A fighter of fighter.tscn, with the game's capsule and contours, flies across a world built
# here: WallNorth ahead of it, WallWest to its left and WallEast to its right, all within the
# range, WallFar behind it, 28 m off, beyond the range, and the CornerFin, a thin wall to the right
# of the flight between the shoulder and WallEast. On every loop the probe aims the way the camera
# does, through FighterInput.sample_frame, so netfox records the aim as Input:yaw and Input:pitch
# and restores it on every resimulated tick. On every tick, right after the fighter moved, the
# probe casts the adapter's own ray, Fighter.aim_ray of the feet and the box's yaw and pitch: from
# O, grapple_range (25 m) along Aim.direction, on the world's mask, the fighter's own RID excluded,
# and from the shoulder to the point when it hits. The aim changes every tick, through six aims:
# ahead and slanted at WallNorth, at WallWest, behind at WallFar, up at the sky, and right at
# WallEast past the CornerFin; the last three must miss, the corner because the shoulder does not
# see the point its first ray finds. Each result is the hit, the point, the normal and the
# collider's path relative to the Arena; a resimulated tick must give the fresh tick's, the feet,
# the point and the normal within 0,000001 and the rest equal, and so must the same cast made
# after a process frame, as the reticle casts it. Each flight proves its preconditions
# (.claude/harness/registro.md, 10/10/2026): netfox resimulated every tick it owed, the fresh ticks
# saw at least one hit and one miss, every aim found the wall it was built to find, and on every
# corner tick the first ray alone found WallEast while the shoulder's ray alone stopped at the
# CornerFin. The SyncTest's observer compares the body and the whole state on the same ticks.
#
# No grapple rule runs here, so the fighter holds its height as in probe A: its config is a copy
# without gravity, and in the air without input the core keeps the velocity, so O moves on every
# tick. The geometry is the test's own, so the arena never changes what this proves. Each flight
# prints two lines for the gate's log, the observer's and the probe's, and the suite prints the
# time of 1000 aims.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const SyncObserver := preload("res://test/support/sync_observer.gd")
const FIGHTER_SCENE := preload("res://fighter/fighter.tscn")
const MOVEMENT_V0 := "res://data/movement_v0.tres"

## Ticks netfox rolls back on every loop: the depth of a 220 ms ping at 60 ticks (rede.md §4).
const DEPTH := 7
## Feet, a point or a normal resimulated farther than this from the fresh one is a divergence: the
## SyncTest's own (rede.md §4).
const TOLERANCE := SyncObserver.TOLERANCE
## How many aims the timing casts.
const TIMED_RAYS := 1000

# The flight: the feet start at START, at 8 m/s along +X, the wall run's speed, and cross 8 m in
# LOOPS ticks of one loop each, from x = -4 to x = 4.
const START := Vector3(-4.0, 1.0, 0.0)
const VELOCITY := Vector3(8.0, 0.0, 0.0)
const LOOPS := 60

# The world of the probe, boxes on the world's layer, their faces toward the flight. WallNorth
# faces +Z at z = -15, 40 m wide and from y = -5 to 15: 15 m ahead of O, 18,4 m along the slanted
# aim. WallWest faces +X at x = -12, from z = -5 to 5: 8 to 16 m to the left of the flight.
# WallEast faces -X at x = 16, from z = -5 to 5: 12 to 20 m to the right. WallFar faces -Z at
# z = 28, behind the flight and beyond the range. The CornerFin stands along the flight, 10 cm
# thick, from z = 0,5 to 0,6 and from x = 6 to 15: looking at WallEast (yaw -90°), O is 0,8 m to
# the right, at z = 0,8, so the first ray passes beside the fin, while the shoulder's ray, from
# z = 0 to the point at z = 0,8, crosses it 3 m or more before the point.
const WALL_NORTH := &"WallNorth"
const WALL_WEST := &"WallWest"
const WALL_EAST := &"WallEast"
const WALL_FAR := &"WallFar"
const CORNER_FIN := &"CornerFin"
const NORTH_FACE_Z := -15.0
const WEST_FACE_X := -12.0
const EAST_FACE_X := 16.0
const FAR_FACE_Z := 28.0
const THICKNESS := 1.0
const WALL_BOTTOM := -5.0
const WALL_TOP := 15.0
const FIN_CENTRE := Vector3(10.5, 5.0, 0.55)
const FIN_SIZE := Vector3(9.0, 20.0, 0.1)

# The aims, in turn, one per tick: [yaw, pitch] in degrees, yaw 0 looking down -Z and positive
# turning left, pitch positive up (TickInput; DEC-0044 §2); the wall the aim must find, empty for a
# miss; and the wall its first ray alone finds, the same but for the corner.
const AIMS: Array[Array] = [
	[0.0, 0.0, WALL_NORTH, WALL_NORTH],
	[30.0, 20.0, WALL_NORTH, WALL_NORTH],
	[90.0, -10.0, WALL_WEST, WALL_WEST],
	[180.0, 0.0, &"", &""],
	[0.0, 80.0, &"", &""],
	[-90.0, 0.0, &"", WALL_EAST],
]
const CORNER_AIM := 5

var _first_state_tick := 0


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	if NetworkRollback.before_loop.is_connected(_force_rollback):
		NetworkRollback.before_loop.disconnect(_force_rollback)
	NetfoxTicks.reset()


# The flight as the game runs it (DEC-0040): a physics step between two loops, and after each
# loop a process frame, where the reticle casts the newest tick's ray again.
func test_the_aim_ray_comes_out_equal_when_resimulated_and_in_a_process_frame() -> void:
	var reading := await _fly("stepped, a process frame after every loop", true)
	_assert_equal_everywhere(reading)


# The flight as the SyncTest runs it: every loop inside one physics frame. The process frame comes
# after the last loop, and the reticle's casts of every fresh tick are made there.
func test_the_aim_ray_comes_out_equal_when_every_loop_runs_in_one_physics_frame() -> void:
	var reading := await _fly("every loop in one physics frame", false)
	_assert_equal_everywhere(reading)


# The cost of the aim, printed for the gate's log (DEC-0044 and DEC-0045, "Revisitar se": 16
# fighters). The casts run inside a physics frame, as the adapter's do: the six aims in turn, then
# only hits, which cast both rays, only misses, which cast the first, and only corners, both rays
# with the second one stopped.
func test_the_time_of_1000_aims_is_printed() -> void:
	var config := _config()
	var arena := _arena()
	var fighter := _fighter(arena, config)
	add_child(arena)
	await get_tree().process_frame
	await get_tree().physics_frame
	var feet := fighter.global_position
	var mixed := _time_rays(fighter, feet, [0, 1, 2, 3, 4, 5])
	var hits := _time_rays(fighter, feet, [0, 1, 2])
	var misses := _time_rays(fighter, feet, [3, 4])
	var corners := _time_rays(fighter, feet, [CORNER_AIM])
	print(
		(
			(
				"Probe B, %d aims of %.0f m from O: %s; only hits: %s; only misses: %s;"
				+ " only corners: %s"
			)
			% [
				TIMED_RAYS,
				config.grapple_range,
				mixed.describe(),
				hits.describe(),
				misses.describe(),
				corners.describe(),
			]
		)
	)
	arena.free()
	assert_int(mixed.hits).is_greater(0)
	assert_int(mixed.hits).is_less(TIMED_RAYS)
	assert_int(hits.hits).is_equal(TIMED_RAYS)
	assert_int(misses.hits).is_equal(0)
	assert_int(corners.hits).is_equal(0)


func _assert_equal_everywhere(reading: Reading) -> void:
	var message := "%s: %d ticks resimulated, %d owed" % [
		reading.name,
		reading.checks,
		reading.owed,
	]
	assert_int(reading.owed).override_failure_message(message).is_greater(0)
	assert_int(reading.checks).override_failure_message(message).is_equal(reading.owed)
	message = "%s: the ray diverged when resimulated:\n%s" % [
		reading.name,
		"\n".join(reading.shown),
	]
	assert_int(reading.mismatches).override_failure_message(message).is_equal(0)
	message = "%s: %d process-frame casts for %d fresh ticks" % [
		reading.name,
		reading.frame_checks,
		reading.fresh,
	]
	assert_int(reading.frame_checks).override_failure_message(message).is_equal(reading.fresh)
	message = "%s: the ray diverged in a process frame:\n%s" % [
		reading.name,
		"\n".join(reading.frame_shown),
	]
	assert_int(reading.frame_mismatches).override_failure_message(message).is_equal(0)
	message = "%s: the body or the state diverged:\n%s" % [
		reading.name,
		"\n".join(reading.body_shown),
	]
	assert_int(reading.body_mismatches).override_failure_message(message).is_equal(0)
	# The preconditions: the run saw both answers, every aim found what it was built to find, and
	# every corner was one: its first ray found WallEast and the shoulder's ray the CornerFin.
	message = "%s: %d hits and %d misses on fresh ticks" % [
		reading.name,
		reading.hits,
		reading.misses,
	]
	assert_int(reading.hits).override_failure_message(message).is_greater(0)
	assert_int(reading.misses).override_failure_message(message).is_greater(0)
	message = "%s: an aim found another wall than its own:\n%s" % [
		reading.name,
		"\n".join(reading.wrong_shown),
	]
	assert_int(reading.wrong_walls).override_failure_message(message).is_equal(0)
	message = "%s: %d of %d corner ticks proven a corner" % [
		reading.name,
		reading.corners_proven,
		reading.corner_ticks,
	]
	assert_int(reading.corner_ticks).override_failure_message(message).is_greater(0)
	assert_int(reading.corners_proven).override_failure_message(message).is_equal(
		reading.corner_ticks
	)


# The numbers of a flight: a config of its own, so movement_v0.tres stays untouched. Without
# gravity the vertical stays at zero, and no wall run starts, so only the ray is measured. The
# aim's height, its side and the range are the game's.
func _config() -> MovementConfig:
	var resource: Resource = load(MOVEMENT_V0)
	assert(resource is MovementData, "%s must load as a MovementData" % MOVEMENT_V0)
	var config := MovementConfig.create(resource as MovementData, NetworkTime.tickrate)
	config.wall_entry_speed = INF
	config.rise_gravity_per_tick = 0.0
	config.fall_gravity_per_tick = 0.0
	return config


# The arena of the probe: the walls and the fin, named so their paths relative to it are their
# names.
func _arena() -> Node3D:
	var arena := Node3D.new()
	arena.name = "Arena"
	var height := WALL_TOP - WALL_BOTTOM
	var middle := (WALL_TOP + WALL_BOTTOM) / 2.0
	_wall(
		arena,
		WALL_NORTH,
		Vector3(0.0, middle, NORTH_FACE_Z - THICKNESS / 2.0),
		Vector3(40.0, height, THICKNESS),
	)
	_wall(
		arena,
		WALL_WEST,
		Vector3(WEST_FACE_X - THICKNESS / 2.0, middle, 0.0),
		Vector3(THICKNESS, height, 10.0),
	)
	_wall(
		arena,
		WALL_EAST,
		Vector3(EAST_FACE_X + THICKNESS / 2.0, middle, 0.0),
		Vector3(THICKNESS, height, 10.0),
	)
	_wall(
		arena,
		WALL_FAR,
		Vector3(0.0, middle, FAR_FACE_Z + THICKNESS / 2.0),
		Vector3(40.0, height, THICKNESS),
	)
	_wall(arena, CORNER_FIN, FIN_CENTRE, FIN_SIZE)
	return arena


func _wall(arena: Node3D, wall_name: StringName, center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = wall_name
	body.collision_layer = PhysicsLayers.WORLD
	body.position = center
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	arena.add_child(body)


# A fighter of fighter.tscn under arena, in the air at START and at VELOCITY from its first
# recorded state: its synchronizer records it when it processes its settings, deferred to the
# next frame.
func _fighter(arena: Node3D, config: MovementConfig) -> Fighter:
	var node := FIGHTER_SCENE.instantiate()
	assert(node is Fighter, "fighter.tscn must have a Fighter at its root")
	var fighter := node as Fighter
	fighter.setup(config, START, 0.0, true)
	fighter.state.on_floor = false
	fighter.state.mode = FighterState.Mode.AIR
	fighter.velocity = VELOCITY
	arena.add_child(fighter)
	return fighter


# One flight through netfox's real tick loop, driven by hand (test/support/netfox_ticks.gd), with
# a rollback of DEPTH ticks on every loop. Each loop aims with the next of AIMS, as the camera
# would: no push, the aim's yaw and its pitch.
func _fly(flight_name: String, stepped: bool) -> Reading:
	var config := _config()
	var arena := _arena()
	var fighter := _fighter(arena, config)
	add_child(arena)
	await get_tree().process_frame
	await get_tree().physics_frame
	var first_tick := NetworkTime.tick
	var spawn_tick: int = fighter.synchronizer.spawn_tick
	_first_state_tick = maxi(first_tick, spawn_tick)
	var recorder := RayRecorder.new(fighter, arena, config, first_tick)
	var watched: Array[Fighter] = [fighter]
	var observer := SyncObserver.new(flight_name, watched)
	NetworkRollback.before_loop.connect(_force_rollback)
	for loop: int in LOOPS:
		if stepped and loop > 0:
			await get_tree().physics_frame
		var aim := loop % AIMS.size()
		fighter.input.sample_frame(Vector2.ZERO, Aims.yaw_of(aim), Aims.pitch_of(aim))
		NetfoxTicks.run_loop()
		if stepped:
			await get_tree().process_frame
			recorder.cast_in_frame(recorder.newest)
	NetworkRollback.before_loop.disconnect(_force_rollback)
	if not stepped:
		await get_tree().process_frame
		for tick: int in recorder.ticks:
			recorder.cast_in_frame(tick)
	recorder.stop()
	observer.stop()
	print(observer.summary())
	var reading := Reading.new(flight_name, recorder)
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


# TIMED_RAYS aims of the fighter from feet, the given aims in turn, timed together.
func _time_rays(fighter: Fighter, feet: Vector3, aims: Array[int]) -> Timing:
	var timing := Timing.new()
	var started := Time.get_ticks_usec()
	for ray: int in TIMED_RAYS:
		var aim := aims[ray % aims.size()]
		if not fighter.aim_ray(feet, Aims.yaw_of(aim), Aims.pitch_of(aim)).is_empty():
			timing.hits += 1
	timing.usec = Time.get_ticks_usec() - started
	return timing


# The aims of AIMS, as the input carries them.
class Aims:
	extends RefCounted

	# The yaw of an aim, in rad.
	static func yaw_of(aim: int) -> float:
		var degrees: float = AIMS[aim][0]
		return deg_to_rad(degrees)


	# The pitch of an aim, in rad, positive up.
	static func pitch_of(aim: int) -> float:
		var degrees: float = AIMS[aim][1]
		return deg_to_rad(degrees)


	# The wall an aim must find, empty for a miss.
	static func wall_of(aim: int) -> StringName:
		var wall: StringName = AIMS[aim][2]
		return wall


	# The wall the first ray of an aim finds alone, from O.
	static func first_wall_of(aim: int) -> StringName:
		var wall: StringName = AIMS[aim][3]
		return wall


	# The aim of a tick, counted from the flight's first: the six aims in turn, one per loop.
	static func of_tick(tick: int, first_tick: int) -> int:
		return posmod(tick - first_tick, AIMS.size())


# What the aim found: Fighter.aim_ray of the feet, the yaw and the pitch, the answer the adapter
# hands the core in MoveFacts (DEC-0044 §1), the hit and its point, and what the probe also
# compares, the normal and the collider's path; with the point O and the direction it left along.
class RayResult:
	extends RefCounted

	var feet: Vector3
	var yaw: float
	var pitch: float
	var origin: Vector3
	var direction: Vector3
	var hit := false
	var point := Vector3.ZERO
	var normal := Vector3.ZERO
	var path: StringName = &""


	# The adapter's own aim (Fighter.aim_ray; DEC-0045 §2 and §3).
	static func cast(
		fighter: Fighter,
		arena: Node,
		from_feet: Vector3,
		aim_yaw: float,
		aim_pitch: float,
	) -> RayResult:
		var result := RayResult.new()
		var config := fighter.config
		result.feet = from_feet
		result.yaw = aim_yaw
		result.pitch = aim_pitch
		result.origin = Aim.origin(from_feet, aim_yaw, config.aim_height, config.aim_side)
		result.direction = Aim.direction(aim_yaw, aim_pitch)
		var found := fighter.aim_ray(from_feet, aim_yaw, aim_pitch)
		if found.is_empty():
			return result
		result.hit = true
		result.point = found["position"]
		result.normal = found["normal"]
		result.path = path_of(found, arena)
		return result


	# The collider's path relative to the arena.
	static func path_of(found: Dictionary, arena: Node) -> StringName:
		var collider: Object = found["collider"]
		assert(collider is Node, "every collider of the probe's world is a node")
		return StringName(str(arena.get_path_to(collider as Node)))


	# What differs from another answer to the same question: the hit and the path equal, the point
	# and the normal within TOLERANCE.
	func differences(again: RayResult) -> Array[String]:
		var found: Array[String] = []
		if hit != again.hit:
			found.append("hit %s then %s" % [hit, again.hit])
			return found
		if path != again.path:
			found.append("path %s then %s" % [path, again.path])
		if point.distance_to(again.point) > TOLERANCE:
			found.append("point %s then %s" % [point, again.point])
		if normal.distance_to(again.normal) > TOLERANCE:
			found.append("normal %s then %s" % [normal, again.normal])
		return found


	func describe() -> String:
		if not hit:
			return "miss"
		return "%s at %s, normal %s" % [path, point, normal]


# Casts the aim of one fighter after every simulated tick, on netfox's after_process_tick, which
# comes after every fighter of the tick has moved, the way the SyncTest's observer reads the
# state: the first answer of a tick is the fresh one, and every resimulation of the same tick is
# compared with it. The aim is the input netfox restored for that tick, read from the box as the
# adapter reads it (FighterInput.to_tick_input). The same aim, cast again in a process frame, is
# compared with the fresh one too. On every fresh corner tick it also proves the corner: the first
# ray alone, from O, finds WallEast, and the shoulder's ray alone, to that point, stops at the
# CornerFin more than Fighter.SIGHT_TOLERANCE before it.
class RayRecorder:
	extends RefCounted

	## How many divergences the failure message describes.
	const SHOWN := 5

	## The fresh answers, by tick, and the fresh ticks in order; the newest fresh tick.
	var fresh: Dictionary[int, RayResult] = { }
	var ticks: Array[int] = []
	var newest: int
	## One check per resimulated tick, and those whose answer differed.
	var checks := 0
	var mismatches := 0
	var shown: Array[String] = []
	## One check per cast in a process frame, and those whose answer differed.
	var frame_checks := 0
	var frame_mismatches := 0
	var frame_shown: Array[String] = []
	## Fresh ticks of the corner's aim, and those whose two rays, cast alone, proved the corner.
	var corner_ticks := 0
	var corners_proven := 0

	var _fighter: Fighter
	var _arena: Node
	var _config: MovementConfig
	var _loop_from := 0
	var _loop_starting := false


	func _init(fighter: Fighter, arena: Node, config: MovementConfig, first_tick: int) -> void:
		_fighter = fighter
		_arena = arena
		_config = config
		newest = first_tick - 1
		NetworkRollback.before_loop.connect(_on_loop_start)
		NetworkRollback.after_process_tick.connect(_observe)


	func stop() -> void:
		NetworkRollback.before_loop.disconnect(_on_loop_start)
		NetworkRollback.after_process_tick.disconnect(_observe)


	# The same aim as the fresh tick's, from the same feet along the same yaw and pitch, cast where
	# the reticle casts it: outside the tick, in a process frame.
	func cast_in_frame(tick: int) -> void:
		var first := fresh[tick]
		var again := RayResult.cast(_fighter, _arena, first.feet, first.yaw, first.pitch)
		frame_checks += 1
		var differences := first.differences(again)
		if differences.is_empty():
			return
		frame_mismatches += 1
		if frame_shown.size() < SHOWN:
			frame_shown.append("tick %d: %s" % [tick, "; ".join(differences)])


	func _on_loop_start() -> void:
		_loop_starting = true


	# netfox simulates a tick for the first time as the last tick of its loop, so a tick newer than
	# every tick seen is fresh and any other is a resimulation.
	func _observe(tick: int) -> void:
		if _loop_starting:
			_loop_starting = false
			_loop_from = tick
		var box := _fighter.input.to_tick_input()
		var feet := _fighter.global_position
		var result := RayResult.cast(_fighter, _arena, feet, box.yaw, box.pitch)
		if tick > newest:
			newest = tick
			if posmod(ticks.size(), AIMS.size()) == CORNER_AIM:
				corner_ticks += 1
				if _proves_the_corner(result):
					corners_proven += 1
			fresh[tick] = result
			ticks.append(tick)
			return
		checks += 1
		var first := fresh[tick]
		var differences := first.differences(result)
		if first.feet.distance_to(feet) > TOLERANCE:
			differences.append("feet %s then %s" % [first.feet, feet])
		if first.direction.distance_to(result.direction) > TOLERANCE:
			differences.append("aim %s then %s" % [first.direction, result.direction])
		if differences.is_empty():
			return
		mismatches += 1
		if shown.size() < SHOWN:
			shown.append(
				"tick %d, rolled back to tick %d: %s" % [tick, _loop_from, "; ".join(differences)],
			)


	# The corner's two rays, cast alone on the world's mask: the first, from O, finds WallEast;
	# the second, from the shoulder to that point, stops at the CornerFin, well before the point.
	func _proves_the_corner(result: RayResult) -> bool:
		var reach := result.direction * _config.grapple_range
		var first := _raw(result.origin, result.origin + reach)
		if first.is_empty() or RayResult.path_of(first, _arena) != WALL_EAST:
			return false
		var point: Vector3 = first["position"]
		var sight := _raw(result.feet + Vector3.UP * _config.aim_height, point)
		if sight.is_empty() or RayResult.path_of(sight, _arena) != CORNER_FIN:
			return false
		var stop: Vector3 = sight["position"]
		return stop.distance_to(point) > Fighter.SIGHT_TOLERANCE


	func _raw(from: Vector3, to: Vector3) -> Dictionary:
		var query := PhysicsRayQueryParameters3D.create(
			from,
			to,
			PhysicsLayers.WORLD,
			[_fighter.get_rid()],
		)
		return _fighter.get_world_3d().direct_space_state.intersect_ray(query)


# What a flight showed: the comparisons, its preconditions and its measures, from the fresh
# answers in tick order.
class Reading:
	extends RefCounted

	## How many wrong walls the failure message describes.
	const SHOWN := 5

	var name: String
	var fresh := 0
	var checks := 0
	var owed := 0
	var mismatches := 0
	var shown: Array[String] = []
	var frame_checks := 0
	var frame_mismatches := 0
	var frame_shown: Array[String] = []
	var body_mismatches := 0
	var body_shown: Array[String] = []
	## Fresh ticks whose aim hit, and those whose aim missed; the hits by wall.
	var hits := 0
	var misses := 0
	var by_wall: Dictionary[StringName, int] = { }
	## Fresh ticks whose aim found another wall than its own, or missed where it should hit.
	var wrong_walls := 0
	var wrong_shown: Array[String] = []
	## Fresh ticks of the corner's aim, and those proven a corner by the two rays alone.
	var corner_ticks := 0
	var corners_proven := 0
	## m: the nearest and the farthest hit from O; O's first and last x.
	var nearest := INF
	var farthest := -INF
	var first_x := INF
	var last_x := -INF


	func _init(flight_name: String, recorder: RayRecorder) -> void:
		name = flight_name
		checks = recorder.checks
		mismatches = recorder.mismatches
		shown = recorder.shown
		frame_checks = recorder.frame_checks
		frame_mismatches = recorder.frame_mismatches
		frame_shown = recorder.frame_shown
		corner_ticks = recorder.corner_ticks
		corners_proven = recorder.corners_proven
		fresh = recorder.ticks.size()
		var first_tick: int = recorder.ticks[0] if fresh > 0 else 0
		for tick: int in recorder.ticks:
			_measure(recorder.fresh[tick], Aims.of_tick(tick, first_tick), tick)


	func _measure(result: RayResult, aim: int, tick: int) -> void:
		first_x = minf(first_x, result.origin.x)
		last_x = maxf(last_x, result.origin.x)
		var expected := Aims.wall_of(aim)
		if result.path != expected:
			wrong_walls += 1
			if wrong_shown.size() < SHOWN:
				wrong_shown.append("tick %d, aim %d: %s" % [tick, aim, result.describe()])
		if not result.hit:
			misses += 1
			return
		hits += 1
		var count: int = by_wall.get(result.path, 0)
		by_wall[result.path] = count + 1
		var distance := result.origin.distance_to(result.point)
		nearest = minf(nearest, distance)
		farthest = maxf(farthest, distance)


	func summary() -> String:
		return (
			(
				"Probe B, %s: %d fresh ticks, %d resimulated of %d owed, %d ray mismatches; %d"
				+ " process-frame casts, %d mismatches; %d hits %s and %d misses, %d on the wrong"
				+ " wall; %d of %d corners proven; hits from %.3f to %.3f m off O; O x from %.3f"
				+ " to %.3f"
			)
			% [
				name,
				fresh,
				checks,
				owed,
				mismatches,
				frame_checks,
				frame_mismatches,
				hits,
				by_wall,
				misses,
				wrong_walls,
				corners_proven,
				corner_ticks,
				nearest,
				farthest,
				first_x,
				last_x,
			]
		)


# The time of a batch of aims.
class Timing:
	extends RefCounted

	var usec := 0
	var hits := 0


	func describe() -> String:
		return "%.3f ms, %.2f µs an aim, %d hits" % [usec / 1000.0, float(usec) / TIMED_RAYS, hits]
