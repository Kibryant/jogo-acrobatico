# Criterion 6 of TASK-9, the fighter's scene (visao-geral.md, "As cenas"): netfox records the
# body box and every field of FighterState, and the input box (DEC-0022); no fighter predicts
# input (DEC-0026 §2); the capsule is the 1.8 m x 0.35 m of movimento.md, "O corpo", with its
# bottom at the body's origin; the engine judges the floor with the 45°, and its snap covers one
# tick of the fastest ground speed, the dash's, down the steepest floor (TASK-10.4).
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const FIGHTER_SCENE := preload("res://fighter/fighter.tscn")
const MOVEMENT_V0 := "res://data/movement_v0.tres"
const HAIR := 1e-6

const BODY_BOX: Array[String] = [":position", ":velocity"]


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	NetfoxTicks.reset()


func _config(tickrate: int) -> MovementConfig:
	var resource: Resource = load(MOVEMENT_V0)
	assert(resource is MovementData, "%s must load as a MovementData" % MOVEMENT_V0)
	return MovementConfig.create(resource as MovementData, tickrate)


# A fighter set up for tickrate and in the tree: netfox's RollbackSynchronizer leaks a node of
# its own when it never enters the tree.
func _fighter(tickrate := 60) -> Fighter:
	var node: Node = auto_free(FIGHTER_SCENE.instantiate())
	assert(node is Fighter, "fighter.tscn must have a Fighter at its root")
	var fighter := node as Fighter
	fighter.setup(_config(tickrate), Vector3(1, 2, 3), 0.5, true)
	add_child(fighter)
	return fighter


func _synchronizer(fighter: Fighter) -> RollbackSynchronizer:
	var node := fighter.get_node(^"RollbackSynchronizer")
	assert(node is RollbackSynchronizer, "the fighter must have a RollbackSynchronizer")
	return node as RollbackSynchronizer


# The script variables of an object, by name: its fields, without the private ones.
func _fields(object: Object) -> Array[String]:
	var fields: Array[String] = []
	for property: Dictionary in object.get_property_list():
		var usage: int = property["usage"]
		var field: String = property["name"]
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE and not field.begins_with("_"):
			fields.append(field)
	return fields


# A field of FighterState left out of this list would be hidden state: the rollback would
# restore the others and forget it (visao-geral.md, "O estado em quatro caixas").
func test_netfox_records_the_body_and_every_field_of_the_state() -> void:
	var expected: Array[String] = []
	expected.append_array(BODY_BOX)
	for field: String in _fields(FighterState.new()):
		expected.append(":state:" + field)
	var recorded: Array[String] = []
	recorded.assign(_synchronizer(_fighter()).state_properties)
	expected.sort()
	recorded.sort()
	assert_array(recorded).is_equal(expected)


# The input box is what the core reads as a TickInput: move, yaw and jump.
func test_netfox_records_the_input_box() -> void:
	var expected: Array[String] = []
	for field: String in _fields(TickInput.new()):
		expected.append("Input:" + field)
	var recorded: Array[String] = []
	recorded.assign(_synchronizer(_fighter()).input_properties)
	expected.sort()
	recorded.sort()
	assert_array(recorded).is_equal(expected)


func test_no_fighter_predicts_input() -> void:
	assert_bool(_synchronizer(_fighter()).enable_prediction).is_false()


func test_the_capsule_comes_from_the_config_with_its_bottom_at_the_origin() -> void:
	var fighter := _fighter()
	var shape := fighter.collision.shape
	assert_bool(shape is CapsuleShape3D).is_true()
	var capsule := shape as CapsuleShape3D
	assert_float(capsule.height).is_equal_approx(1.8, HAIR) # movimento.md, "O corpo"
	assert_float(capsule.radius).is_equal_approx(0.35, HAIR)
	assert_float(fighter.collision.position.y - capsule.height / 2.0).is_equal_approx(0.0, HAIR)
	assert_vector(fighter.position).is_equal(Vector3(1, 2, 3))
	assert_float(fighter.state.facing_yaw).is_equal(0.5)
	assert_bool(fighter.state.on_floor).is_true()


func test_the_engine_judges_the_floor_with_45_degrees() -> void:
	var fighter := _fighter()
	assert_float(fighter.floor_max_angle).is_equal_approx(deg_to_rad(45.0), HAIR)


# The fastest ground speed is the dash's 20 m/s, not the run's 7 (movimento.md, "Dash"; TASK-10.4):
# across a 45° floor it drops tan(45°) * 20 / tickrate a tick, 0.333 m at 60 and 0.667 m at 30,
# plus three safe margins measured along the floor's normal (Fighter.floor_snap_for): 0.338 m at
# 60. The dash down the ramp in fighter_slope_test.gd proves the 60-tick snap holds the floor.
func test_the_floor_snap_covers_a_dash_tick_down_45_degrees(
	tickrate: int,
	drop_per_tick: float,
	_test_parameters := [[60, 20.0 / 60.0], [30, 20.0 / 30.0]],
) -> void:
	var fighter := _fighter(tickrate)
	var skin := 3.0 * fighter.safe_margin / cos(deg_to_rad(45.0))
	assert_float(fighter.floor_snap_length).is_equal_approx(drop_per_tick + skin, HAIR)
	assert_float(fighter.floor_snap_length).is_greater(drop_per_tick)


func test_the_fighter_collides_with_the_world_and_with_fighters() -> void:
	var fighter := _fighter()
	assert_int(fighter.collision_layer).is_equal(PhysicsLayers.FIGHTERS)
	assert_int(fighter.collision_mask).is_equal(PhysicsLayers.WORLD | PhysicsLayers.FIGHTERS)


# TASK-9, criterion 9: only the server sends a fighter's state, and only to the peers it told that
# the fighter exists (Main._on_player_clock_synced); a state for a node a client does not have
# yet would be dropped there with a warning.
func test_the_state_goes_only_to_the_peers_told_about_the_fighter() -> void:
	var fighter := _fighter()
	var told := 1450222694
	var not_told := 78230771
	var filter := fighter.synchronizer.visibility_filter
	assert_bool(filter.get_visibility_for(told)).is_false()
	assert_bool(filter.get_visibility_for(not_told)).is_false()
	fighter.send_state_to(told)
	assert_bool(filter.get_visibility_for(told)).is_true()
	assert_bool(filter.get_visibility_for(not_told)).is_false()
