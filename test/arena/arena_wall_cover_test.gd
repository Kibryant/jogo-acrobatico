# Criterion 4 of TASK-10.10: in the arena, Block1m and Block2m refuse the wall run at every
# height, a jump pressed into them from the floor included, and ParedeLonga, the corridor's walls
# and Block3m accept it while the wall rises 30 cm above the head (movimento.md, "Corrida na
# parede": "A parede passa da cabeça"; "Métricas de nível": "Onde ficam na arena", "Corredor
# estreito"). A fighter of fighter.tscn meets each face of the real arena.tscn under netfox's
# rollback of 7 ticks on every loop (test/support/wall_flight.gd); every resimulated tick must give
# the same state, body and ray as the fresh one.
#
# Most flights hold their height before the face, as the wall run will: their config is a copy of
# movement_v0.tres without gravity, 8 m/s along the face and 2 m/s into it, about 14°, above the 4
# of the entry, so the ray stays where the case puts it. The feet heights are where a body meets
# these faces in the air: 0,15 m, the second tick of a jump; 0,5 m, early in a jump; 1,2 m, the
# jump's apex (movimento.md, "Pulo e ar"). The jump pressed into a low block plays with the real
# gravity, from the feet on the floor.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const WallFlight := preload("res://test/support/wall_flight.gd")
const ARENA_SCENE := preload("res://arena/arena.tscn")
const MOVEMENT_V0 := "res://data/movement_v0.tres"

## movimento.md, "A parede passa da cabeça": the ray 2,1 m above the feet, 30 cm above the head.
const RAY_HEIGHT_M := 2.1
## m/s: along the face and into it.
const ALONG := 8.0
const INTO := 2.0
## m: each flight starts this far off its face.
const START_GAP := 0.1
const LOOPS := 20
const LOW_FEET := 0.15
const EARLY_FEET := 0.5
const APEX_FEET := 1.2 # movimento.md, "Pulo e ar": the jump's 1,2 m
const HIGH_FEET := 2.5 # on a corridor wall, after a climb: the ray at 4,6 m, below its 5 m

# The faces of arena.tscn ("Métricas de nível": "Onde ficam na arena"; arena.gd): the blocks span
# z -14..-10, so their south faces look down +Z from z = -10 (Block1m over x -10..-6, Block2m over
# -2..2, Block3m over 6..10, tops at 1, 2 and 3 m); ParedeLonga, 4 m tall, has faces at x = 14
# (west) and 15 (east) over z -20..4; the corridor's walls, 5 m tall, face each other from x = 23
# (CorredorOeste's east face) and x = 26,5 (CorredorLeste's west face), over the same z.
const BLOCK_FACE_Z := -10.0
const LANE_Z := 2.0
# The jump pressed into a block: from the floor 2 cm off its face, full run along it with a quarter
# of the speed into it, about 14°, the jump pressed once the run is at full speed.
const PRESSED_RUN := Vector3(1.0, 0.0, -0.25)
const PRESSED_GAP := 0.02
const JUMP_ON_LOOP := 12
const PRESSED_LOOPS := 50


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	NetfoxTicks.reset()


# Failure: the low blocks refuse at every height a body meets them in the air, and Block3m refuses
# at the apex: the ray stands above their tops, the move touches the face, and no run starts.
func test_the_low_blocks_refuse_the_run_when_the_ray_is_above_their_top(
	block: String,
	from_x: float,
	feet: float,
	_test_parameters := [
		["Block1m", -9.5, LOW_FEET],
		["Block1m", -9.5, EARLY_FEET],
		["Block2m", -1.5, LOW_FEET],
		["Block2m", -1.5, EARLY_FEET],
		["Block2m", -1.5, APEX_FEET],
		["Block3m", 6.5, APEX_FEET],
	],
) -> void:
	var flight := await _fly_along_a_block(block, from_x, feet)
	_assert_resimulated_unchanged(flight)
	_assert_touched(flight, block)
	assert_float(feet + RAY_HEIGHT_M).is_greater(_top_of(block))
	assert_int(flight.run_ticks).override_failure_message("%s ran" % flight.name).is_equal(0)


# Failure, the case Block2m let through with the ray at 1,7 m: a jump pressed from the floor into
# the face of Block1m or Block2m, running along it. The body leaves the floor touching the face,
# and no tick of the jump starts a run, not even the first ones, with the feet a few cm up.
func test_a_jump_pressed_into_a_low_block_from_the_floor_never_runs(
	block: String,
	from_x: float,
	_test_parameters := [["Block1m", -9.8], ["Block2m", -1.9]],
) -> void:
	var config := _real_config()
	var face := Vector3.BACK
	var start := Vector3(from_x, 0.0, BLOCK_FACE_Z + config.capsule_radius + PRESSED_GAP)
	var run := PRESSED_RUN.normalized()
	var flight := WallFlight.new()
	flight.grounded = true
	flight.move = Vector2(0, 1)
	flight.yaw = atan2(-run.x, -run.z)
	flight.jump_on_loop = JUMP_ON_LOOP
	var flight_name := "%s, jump pressed into it from the floor" % block
	await flight.fly(self, flight_name, _arena(), config, start, Vector3.ZERO, face, PRESSED_LOOPS)
	_assert_resimulated_unchanged(flight)
	_assert_touched(flight, block)
	assert_float(flight.highest_feet).override_failure_message("%s never jumped" % flight.name) \
			.is_greater(EARLY_FEET)
	assert_int(flight.run_ticks).override_failure_message("%s ran" % flight.name).is_equal(0)


# One: Block3m accepts a body that meets it early in a jump, the ray at 2,6 m below its 3 m top;
# with the feet at 0,9 m or higher the ray passes the top, as the apex case above shows.
func test_block_3m_accepts_the_run_early_in_a_jump() -> void:
	var flight := await _fly_along_a_block("Block3m", 6.5, EARLY_FEET)
	_assert_runs_on(flight, "Block3m", 3.0)


# Many: ParedeLonga's two faces and the corridor's two walls accept while the ray is below their
# tops: at the apex of a jump from the floor, and on the corridor after a climb.
func test_the_long_wall_and_the_corridor_walls_accept_the_run(
	wall: String,
	face_x: float,
	normal_x: float,
	top: float,
	feet: float,
	_test_parameters := [
		["ParedeLonga", 14.0, -1.0, 4.0, APEX_FEET],
		["ParedeLonga", 15.0, 1.0, 4.0, APEX_FEET],
		["CorredorOeste", 23.0, 1.0, 5.0, APEX_FEET],
		["CorredorLeste", 26.5, -1.0, 5.0, APEX_FEET],
		["CorredorOeste", 23.0, 1.0, 5.0, HIGH_FEET],
	],
) -> void:
	var config := _config()
	var face := Vector3(normal_x, 0.0, 0.0)
	var start := Vector3(face_x, feet, LANE_Z) + face * (config.capsule_radius + START_GAP)
	var velocity := -face * INTO + Vector3.FORWARD * ALONG
	var flight := WallFlight.new()
	var flight_name := "%s, face at x %.1f, feet at %.1f m" % [wall, face_x, feet]
	await flight.fly(self, flight_name, _arena(), config, start, velocity, face, LOOPS)
	_assert_runs_on(flight, wall, top)


# The narrow corridor's metric (movimento.md, "Métricas de nível": "Corredor estreito"): the inner
# gap is at most 4 m, and its walls are the height one means to reach, 5 m in the arena.
func test_the_corridor_is_narrow_and_its_walls_are_5_m_tall() -> void:
	var arena := _arena()
	var west := _box_of(arena, "CorredorOeste")
	var east := _box_of(arena, "CorredorLeste")
	var gap := east.position.x - west.end.x
	assert_float(gap).is_equal_approx(3.5, 1e-4)
	assert_float(gap).is_less_equal(4.0)
	assert_float(west.size.y).is_equal_approx(5.0, 1e-4)
	assert_float(east.size.y).is_equal_approx(5.0, 1e-4)
	arena.free()


func _assert_runs_on(flight: WallFlight, wall: String, top: float) -> void:
	_assert_resimulated_unchanged(flight)
	var message := "%s never ran: touched %s" % [flight.name, flight.touched]
	assert_int(flight.run_ticks).override_failure_message(message).is_greater(0)
	assert_str(String(flight.entry_wall)).is_equal(wall)
	var ray := flight.entry_feet + RAY_HEIGHT_M
	message = "%s: the ray at %.3f m, the top at %.1f m" % [flight.name, ray, top]
	assert_float(ray).override_failure_message(message).is_less(top)


func _assert_touched(flight: WallFlight, wall: String) -> void:
	var message := "%s never touched %s: %s" % [flight.name, wall, flight.touched]
	assert_bool(flight.touched.has(StringName(wall))).override_failure_message(message).is_true()


func _assert_resimulated_unchanged(flight: WallFlight) -> void:
	var message := "%s: %d ticks resimulated, %d owed" % [flight.name, flight.checks, flight.owed]
	assert_int(flight.owed).override_failure_message(message).is_greater(0)
	assert_int(flight.checks).override_failure_message(message).is_equal(flight.owed)
	message = "%s: the head ray diverged:\n%s" % [flight.name, "\n".join(flight.shown)]
	assert_int(flight.mismatches).override_failure_message(message).is_equal(0)
	message = "%s: the state or the body diverged:\n%s" % [
		flight.name,
		"\n".join(flight.body_shown),
	]
	assert_int(flight.body_mismatches).override_failure_message(message).is_equal(0)


# Along a block's south face, eastward, starting at from_x with the feet at feet.
func _fly_along_a_block(block: String, from_x: float, feet: float) -> WallFlight:
	var config := _config()
	var face := Vector3.BACK
	var start := Vector3(from_x, feet, BLOCK_FACE_Z + config.capsule_radius + START_GAP)
	var velocity := Vector3.RIGHT * ALONG - face * INTO
	var flight := WallFlight.new()
	var flight_name := "%s, feet at %.2f m" % [block, feet]
	await flight.fly(self, flight_name, _arena(), config, start, velocity, face, LOOPS)
	return flight


func _top_of(block: String) -> float:
	var arena := _arena()
	var box := _box_of(arena, block)
	var top := box.end.y
	arena.free()
	return top


# A collider of the arena as a box in the arena's space.
func _box_of(arena: Node3D, body_name: String) -> AABB:
	var body := arena.get_node(body_name)
	assert(body is StaticBody3D, "%s must be a StaticBody3D of the arena" % body_name)
	var collision := body.get_node(^"Collision")
	assert(collision is CollisionShape3D, "%s must have a Collision" % body_name)
	var shape := (collision as CollisionShape3D).shape
	assert(shape is BoxShape3D, "%s must be a box" % body_name)
	var size := (shape as BoxShape3D).size
	var centre := (body as StaticBody3D).position + (collision as CollisionShape3D).position
	return AABB(centre - size / 2.0, size)


func _arena() -> Node3D:
	var node := ARENA_SCENE.instantiate()
	assert(node is Node3D, "arena.tscn must have a Node3D at its root")
	return node as Node3D


func _real_config() -> MovementConfig:
	var resource: Resource = load(MOVEMENT_V0)
	assert(resource is MovementData, "%s must load as a MovementData" % MOVEMENT_V0)
	return MovementConfig.create(resource as MovementData, NetworkTime.tickrate)


# movement_v0.tres without gravity, so a flight holds its height before the face.
func _config() -> MovementConfig:
	var config := _real_config()
	config.rise_gravity_per_tick = 0.0
	config.fall_gravity_per_tick = 0.0
	return config
