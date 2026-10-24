# Criterion 4 of TASK-10.10: in the arena, Block1m and Block2m refuse the wall run, and
# ParedeLonga, the corridor's walls and Block3m accept it with the head below the top
# (movimento.md, "Corrida na parede": "A parede cobre o corpo": "Os blocos de 1 e 2 m recusam";
# "Métricas de nível": "Onde ficam na arena", "Corredor estreito"). A fighter of fighter.tscn flies
# into each face of the real arena.tscn under netfox's rollback of 7 ticks on every loop
# (test/support/wall_flight.gd), 8 m/s along the face and 2 m/s into it, about 14°, above the 4 of
# the entry; every resimulated tick must give the same state, body and head ray as the fresh one.
#
# The flights hold their height before the face, as the wall run will: their config is a copy of
# movement_v0.tres without gravity, so the head stays where the case puts it. The feet heights are
# where a body meets these faces in the air: 0,5 m, early in a jump, and 1,2 m, the jump's apex
# (movimento.md, "Pulo e ar"), the highest a body reaches from the floor without a double jump.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const WallFlight := preload("res://test/support/wall_flight.gd")
const ARENA_SCENE := preload("res://arena/arena.tscn")
const MOVEMENT_V0 := "res://data/movement_v0.tres"

## movimento.md, "A parede cobre o corpo": 1,7 m above the feet.
const HEAD_HEIGHT_M := 1.7
## m/s: along the face and into it.
const ALONG := 8.0
const INTO := 2.0
## m: each flight starts this far off its face.
const START_GAP := 0.1
const LOOPS := 20
const EARLY_FEET := 0.5
const APEX_FEET := 1.2 # movimento.md, "Pulo e ar": the jump's 1,2 m

# The faces of arena.tscn ("Métricas de nível": "Onde ficam na arena"; arena.gd): the blocks span
# z -14..-10, so their south faces look down +Z from z = -10 (Block1m over x -10..-6, Block2m over
# -2..2, Block3m over 6..10, tops at 1, 2 and 3 m); ParedeLonga, 4 m tall, has faces at x = 14
# (west) and 15 (east) over z -20..4; the corridor's walls, 5 m tall, face each other from x = 23
# (CorredorOeste's east face) and x = 26,5 (CorredorLeste's west face), over the same z.
const BLOCK_FACE_Z := -10.0
const LANE_Z := 2.0


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	NetfoxTicks.reset()


# Failure: the low blocks refuse. At 0,5 m and at the apex the head is above a 1 m and a 2 m top:
# the move touches the face, and no run starts.
func test_the_1_m_and_2_m_blocks_refuse_the_run(
	block: String,
	from_x: float,
	feet: float,
	_test_parameters := [
		["Block1m", -9.5, EARLY_FEET],
		["Block2m", -1.5, EARLY_FEET],
		["Block2m", -1.5, APEX_FEET],
	],
) -> void:
	var flight := await _fly_along_a_block(block, from_x, feet)
	_assert_resimulated_unchanged(flight)
	var message := "%s never touched %s: %s" % [flight.name, block, flight.touched]
	assert_bool(flight.touched.has(StringName(block))).override_failure_message(message).is_true()
	assert_float(feet + HEAD_HEIGHT_M).is_greater(_top_of(block))
	assert_int(flight.run_ticks).override_failure_message("%s ran" % flight.name).is_equal(0)


# One: Block3m accepts a body that meets it early in a jump or at the apex, the head below its
# 3 m top (at the apex, 2,9 m: 10 cm of room).
func test_block_3m_accepts_the_run_with_the_head_below_the_top(
	feet: float,
	_test_parameters := [[EARLY_FEET], [APEX_FEET]],
) -> void:
	var flight := await _fly_along_a_block("Block3m", 6.5, feet)
	_assert_runs_on(flight, "Block3m", 3.0)


# Many: ParedeLonga's two faces and the corridor's two walls accept, the head below their tops.
func test_the_long_wall_and_the_corridor_walls_accept_the_run(
	wall: String,
	face_x: float,
	normal_x: float,
	top: float,
	_test_parameters := [
		["ParedeLonga", 14.0, -1.0, 4.0],
		["ParedeLonga", 15.0, 1.0, 4.0],
		["CorredorOeste", 23.0, 1.0, 5.0],
		["CorredorLeste", 26.5, -1.0, 5.0],
	],
) -> void:
	var config := _config()
	var face := Vector3(normal_x, 0.0, 0.0)
	var start := Vector3(face_x, APEX_FEET, LANE_Z) + face * (config.capsule_radius + START_GAP)
	var velocity := -face * INTO + Vector3.FORWARD * ALONG
	var flight := WallFlight.new()
	var flight_name := "%s, face at x %.1f" % [wall, face_x]
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
	var head := flight.entry_feet + HEAD_HEIGHT_M
	message = "%s: the head at %.3f m, the top at %.1f m" % [flight.name, head, top]
	assert_float(head).override_failure_message(message).is_less(top)


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
	var flight_name := "%s, feet at %.1f m" % [block, feet]
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


func _config() -> MovementConfig:
	var resource: Resource = load(MOVEMENT_V0)
	assert(resource is MovementData, "%s must load as a MovementData" % MOVEMENT_V0)
	var config := MovementConfig.create(resource as MovementData, NetworkTime.tickrate)
	config.rise_gravity_per_tick = 0.0
	config.fall_gravity_per_tick = 0.0
	return config
