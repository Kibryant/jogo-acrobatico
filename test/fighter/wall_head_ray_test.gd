# Criterion 3 of TASK-10.10, the wall that covers the body (movimento.md, "Corrida na parede": "A
# parede cobre o corpo"; Q-38; DEC-0042): besides the contact, a ray at the head's height, 1,7 m
# above the feet, from the capsule's axis toward the face and as far as the radius plus 5 cm, must
# find a face of the world in the same plane (normal within 10°), or the wall refuses the run; in
# a run, the head passing the top ends it as at the edge; a stack of two blocks in one plane is one
# wall. A fighter of fighter.tscn, with the game's capsule, margin and contours, flies into walls
# built here under netfox's rollback of 7 ticks on every loop (test/support/wall_flight.gd): every
# resimulated tick must give the same state and body as the fresh one, and the same answer of the
# head ray. Each flight proves its preconditions: it touched the wall, and netfox resimulated every
# tick it owed.
#
# The flights hold their height before the wall the way the run will: their config is a copy of
# movement_v0.tres without gravity, as in engine_probe_test.gd, so the head stays at one height
# against each wall. The geometry is the test's own, so the arena never changes what this proves.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const WallFlight := preload("res://test/support/wall_flight.gd")
const MOVEMENT_V0 := "res://data/movement_v0.tres"

## movimento.md, "A parede cobre o corpo": 1,7 m above the feet of the 1,8 m capsule.
const HEAD_HEIGHT_M := 1.7
## The face of every test wall is the plane z = 0, looking down +Z; the fighter flies along +X on
## that side, 8 m/s along it and 2 m/s into it, about 14°: 8 m/s along, above the 4 of the entry
## (movimento.md, "Corrida na parede").
const FACE_NORMAL := Vector3.BACK
const FLIGHT_VELOCITY := Vector3(8.0, 0.0, -2.0)
## m: the feet fly at this height, so the head ray stands at 2,7 m: above a 2 m top, below a 4 m
## one.
const FLIGHT_Y := 1.0
## m: the flight starts this far off the face, so the move meets it in a few ticks.
const START_GAP := 0.1
const START_X := -3.0
const WALL_FROM_X := -4.0
const WALL_TO_X := 4.0
## The step of the "head passes the top" flight: a 4 m tall collider from WALL_FROM_X to STEP_X
## and a 2 m one from STEP_X to WALL_TO_X, in one plane.
const STEP_X := 0.0
const WALL_THICKNESS := 1.0
const LOOPS := 45
## m: the body moves 8 / 60 m a tick along the wall at 60 ticks; the run ends within a tick of it.
const ONE_TICK_ALONG := 8.0 / 60.0


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	NetfoxTicks.reset()


# The ray's height comes from the data: the capsule's 1,8 m minus the 10 cm below its top.
func test_the_head_ray_stands_1_7_m_above_the_feet() -> void:
	assert_float(_base_config().wall_head_height).is_equal_approx(HEAD_HEIGHT_M, 1e-6)


# Failure: a block of 2 m does not cover a body whose head is at 2,7 m. The move hits its face,
# the probe keeps finding it beside the body, the head ray finds nothing, and no run starts.
func test_a_2_m_block_refuses_the_run() -> void:
	var walls: Array[Box] = [Box.new(&"Bloco2m", WALL_FROM_X, WALL_TO_X, 0.0, 2.0)]
	var flight := await _fly("bloco de 2 m", walls)
	_assert_resimulated_unchanged(flight)
	_assert_touched(flight, &"Bloco2m")
	assert_int(flight.contact_ticks).is_greater(1)
	assert_int(flight.run_ticks).override_failure_message("%s ran on the block" % flight.name) \
			.is_equal(0)
	assert_int(flight.covered_on_contact).is_equal(0)


# One: a wall of 4 m covers the same body. The run starts, with the head below the top.
func test_a_4_m_wall_accepts_the_run_with_the_head_below_the_top() -> void:
	var walls: Array[Box] = [Box.new(&"Parede4m", WALL_FROM_X, WALL_TO_X, 0.0, 4.0)]
	var flight := await _fly("parede de 4 m", walls)
	_assert_resimulated_unchanged(flight)
	_assert_touched(flight, &"Parede4m")
	assert_int(flight.run_ticks).override_failure_message("%s never ran" % flight.name) \
			.is_greater(0)
	assert_str(String(flight.entry_wall)).is_equal("Parede4m")
	assert_float(flight.entry_feet + HEAD_HEIGHT_M).is_less(4.0)
	assert_int(flight.covered_on_contact).is_equal(flight.contact_ticks)


# Many: two blocks of 2 m stacked in one plane are one wall. The move touches the lower one, the
# head ray finds the upper one, and the run starts.
func test_a_stack_of_two_2_m_blocks_in_one_plane_accepts_the_run() -> void:
	var walls: Array[Box] = [
		Box.new(&"PilhaBaixo", WALL_FROM_X, WALL_TO_X, 0.0, 2.0),
		Box.new(&"PilhaCima", WALL_FROM_X, WALL_TO_X, 2.0, 4.0),
	]
	var flight := await _fly("pilha de dois blocos", walls)
	_assert_resimulated_unchanged(flight)
	_assert_touched(flight, &"PilhaBaixo")
	assert_int(flight.run_ticks).override_failure_message("%s never ran" % flight.name) \
			.is_greater(0)
	assert_int(flight.covered_on_contact).is_equal(flight.contact_ticks)


# Limit: a wall that steps down from 4 m to 2 m in one plane. The run starts on the tall part and
# ends as at the edge within a tick of the step, where the head passes the low part's top, while
# the body is still beside the low part: the test-only probe still finds it, and the run is far
# from its 2,5 s.
func test_the_run_ends_when_the_head_passes_the_top() -> void:
	var walls: Array[Box] = [
		Box.new(&"Alta", WALL_FROM_X, STEP_X, 0.0, 4.0),
		Box.new(&"Baixa", STEP_X, WALL_TO_X, 0.0, 2.0),
	]
	var flight := await _fly("parede que desce de 4 para 2 m", walls)
	_assert_resimulated_unchanged(flight)
	_assert_touched(flight, &"Alta")
	assert_str(String(flight.entry_wall)).is_equal("Alta")
	var end_x := flight.end_position.x
	var message := "%s: the run ended at x %.3f, the step is at %.1f" % [flight.name, end_x, STEP_X]
	assert_float(end_x).override_failure_message(message).is_between(
		STEP_X,
		STEP_X + ONE_TICK_ALONG,
	)
	assert_bool(flight.probe_at_end) \
			.override_failure_message("%s: no wall beside the body at the end" % flight.name) \
			.is_true()
	assert_int(flight.run_ticks).is_less(_base_config().wall_run_max_ticks)
	assert_int(flight.mode_at_end).is_equal(FighterState.Mode.AIR)


# The ray is a question to the physics space: asking it moves nothing and changes nothing. It
# finds the face it is aimed at, never the one behind the body, and a floor's normal aims nowhere.
func test_asking_the_head_ray_moves_nothing() -> void:
	var arena := _arena([Box.new(&"Parede4m", WALL_FROM_X, WALL_TO_X, 0.0, 4.0)])
	var config := _config()
	var beside := Vector3(0.0, FLIGHT_Y, config.capsule_radius)
	var fighter := WallFlight.fighter_in(arena, config, beside, Vector3.ZERO)
	add_child(arena)
	await get_tree().physics_frame
	var position := fighter.global_position
	var velocity := fighter.velocity
	var state := fighter.state.copy()
	assert_bool(fighter.covers_body(FACE_NORMAL)).is_true()
	assert_bool(fighter.covers_body(-FACE_NORMAL)).is_false()
	assert_bool(fighter.covers_body(Vector3.UP)).is_false()
	assert_vector(fighter.global_position).is_equal(position)
	assert_vector(fighter.velocity).is_equal(velocity)
	for field: String in ReplayFile.script_fields(state):
		assert_bool(fighter.state.get(field) == state.get(field)) \
				.override_failure_message("state.%s changed" % field) \
				.is_true()
	arena.free()


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


func _assert_touched(flight: WallFlight, wall: StringName) -> void:
	var message := "%s never touched %s: %s" % [flight.name, wall, flight.touched]
	assert_bool(flight.touched.has(wall)).override_failure_message(message).is_true()


func _base_config() -> MovementConfig:
	var resource: Resource = load(MOVEMENT_V0)
	assert(resource is MovementData, "%s must load as a MovementData" % MOVEMENT_V0)
	return MovementConfig.create(resource as MovementData, NetworkTime.tickrate)


# The numbers of a flight: movement_v0.tres without gravity, so the head holds its height.
func _config() -> MovementConfig:
	var config := _base_config()
	config.rise_gravity_per_tick = 0.0
	config.fall_gravity_per_tick = 0.0
	return config


# The arena of a flight: its boxes on the world's layer, named so their paths relative to it are
# their names, each with its face on the plane z = 0.
func _arena(walls: Array[Box]) -> Node3D:
	var arena := Node3D.new()
	arena.name = "Arena"
	for wall: Box in walls:
		var body := StaticBody3D.new()
		body.name = wall.name
		body.collision_layer = PhysicsLayers.WORLD
		body.position = Vector3(
			(wall.from_x + wall.to_x) / 2.0,
			(wall.bottom + wall.top) / 2.0,
			-WALL_THICKNESS / 2.0,
		)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(wall.to_x - wall.from_x, wall.top - wall.bottom, WALL_THICKNESS)
		collision.shape = shape
		body.add_child(collision)
		arena.add_child(body)
	return arena


func _fly(flight_name: String, walls: Array[Box]) -> WallFlight:
	var config := _config()
	var start := Vector3(START_X, FLIGHT_Y, config.capsule_radius + START_GAP)
	var flight := WallFlight.new()
	await flight.fly(
		self,
		flight_name,
		_arena(walls),
		config,
		start,
		FLIGHT_VELOCITY,
		FACE_NORMAL,
		LOOPS,
	)
	return flight


# A box of a test wall: its name, its span along X and its bottom and top, the face on z = 0.
class Box:
	extends RefCounted

	var name: StringName
	var from_x: float
	var to_x: float
	var bottom: float
	var top: float


	func _init(box_name: StringName, from: float, to: float, low: float, high: float) -> void:
		name = box_name
		from_x = from
		to_x = to
		bottom = low
		top = high
