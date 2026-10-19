# Criteria 4 and 5 of TASK-10.3: the state trace (replay/state_trace.gd). It writes the whole state
# after a tick, the body and every field of FighterState found by reflection, with the ticks and
# the stamps counted from the first recorded tick and NEVER kept as NEVER, so a --watch that starts
# on another tick compares with the headless player; where two traces part, it says the tick, the
# fighter, the column and the two values.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const FIGHTER_SCENE := preload("res://fighter/fighter.tscn")
const MOVEMENT_V0 := "res://data/movement_v0.tres"
const FIRST := 1000


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	NetfoxTicks.reset()


# A fighter set up and in the tree: netfox's RollbackSynchronizer leaks a node of its own when it
# never enters the tree (test/fighter/fighter_scene_test.gd).
func _fighter() -> Fighter:
	var node: Node = auto_free(FIGHTER_SCENE.instantiate())
	assert(node is Fighter, "fighter.tscn must have a Fighter at its root")
	var fighter := node as Fighter
	var resource: Resource = load(MOVEMENT_V0)
	assert(resource is MovementData, "%s must load as a MovementData" % MOVEMENT_V0)
	fighter.setup(MovementConfig.create(resource as MovementData, 60), Vector3(1, 2, 3), 0.5, true)
	add_child(fighter)
	return fighter


# The cells of a line by column name.
static func _cells(line: String) -> Dictionary[String, String]:
	var names := StateTrace.header().split(",")
	var values := line.split(",")
	var cells: Dictionary[String, String] = { }
	for index: int in names.size():
		cells[names[index]] = values[index]
	return cells


func test_every_field_of_the_state_is_a_column() -> void:
	var names := StateTrace.header().split(",")
	assert_str(names[0]).is_equal("tick")
	assert_str(names[1]).is_equal("fighter")
	for field: String in ["position.x", "position.y", "position.z", "velocity.x", "velocity.z"]:
		assert_bool(names.has(field)).override_failure_message("no %s" % field).is_true()
	for field: String in ReplayFile.script_fields(FighterState.new()):
		assert_bool(names.has(field)).override_failure_message("no %s" % field).is_true()


# The stamps are the fields named *_tick or *_since (glossario.md, "Carimbo de tick"); a count, as
# jumps_used, or the mode is not one.
func test_the_stamps_are_the_fields_named_tick_or_since() -> void:
	var stamps: Array[String] = [
		"mode_since",
		"left_floor_tick",
		"buffered_tick",
		"stamina_spent_tick",
		"double_jump_tick",
	]
	for field: String in stamps:
		assert_bool(StateTrace.is_stamp(field)).override_failure_message(field).is_true()
	for field: String in ["mode", "jumps_used", "on_floor", "facing_yaw", "stamina_at_spend"]:
		assert_bool(StateTrace.is_stamp(field)).override_failure_message(field).is_false()


func test_ticks_and_stamps_count_from_the_first_tick_and_never_stays_never() -> void:
	var fighter := _fighter()
	fighter.velocity = Vector3(0.0, -1.0 / 3.0, 7.0)
	fighter.state.mode = FighterState.Mode.AIR
	fighter.state.mode_since = FIRST + 10
	fighter.state.left_floor_tick = FighterState.NEVER
	fighter.state.buffered_command = FighterCommand.JUMP
	fighter.state.buffered_tick = FIRST + 3
	fighter.state.jumps_used = 2
	fighter.state.stamina_spent_tick = FIRST
	fighter.state.double_jump_tick = FighterState.NEVER
	var cells := _cells(StateTrace.line_of(fighter, 1, FIRST + 12, FIRST))
	assert_str(cells["tick"]).is_equal("12")
	assert_str(cells["fighter"]).is_equal("1")
	assert_str(cells["mode"]).is_equal(str(FighterState.Mode.AIR))
	assert_str(cells["mode_since"]).is_equal("10")
	assert_str(cells["buffered_tick"]).is_equal("3")
	assert_str(cells["stamina_spent_tick"]).is_equal("0")
	assert_str(cells["left_floor_tick"]).is_equal(str(FighterState.NEVER))
	assert_str(cells["double_jump_tick"]).is_equal(str(FighterState.NEVER))
	assert_str(cells["jumps_used"]).is_equal("2")
	assert_str(cells["on_floor"]).is_equal("1")
	assert_str(cells["buffered_command"]).is_equal("jump".to_utf8_buffer().hex_encode())
	assert_str(cells["facing_yaw"]).is_equal(ReplayFile.f64_cell(0.5))
	assert_str(cells["position.z"]).is_equal(ReplayFile.f64_cell(3.0))
	assert_str(cells["velocity.y"]).is_equal(ReplayFile.f64_cell(fighter.velocity.y))
	# The same state on another clock, every stamp moved as much as the tick: the same line.
	var later := 4321
	fighter.state.mode_since += later
	fighter.state.buffered_tick += later
	fighter.state.stamina_spent_tick += later
	var moved := StateTrace.line_of(fighter, 1, FIRST + 12 + later, FIRST + later)
	fighter.state.mode_since -= later
	fighter.state.buffered_tick -= later
	fighter.state.stamina_spent_tick -= later
	assert_str(moved).is_equal(StateTrace.line_of(fighter, 1, FIRST + 12, FIRST))


# Criterion 4: where two traces part, the tick, the fighter and the column, with both values; and
# nothing when they are equal.
func test_the_first_difference_names_the_tick_the_fighter_the_column_and_both_values() -> void:
	var fighter := _fighter()
	var first := StateTrace.new(FIRST)
	var second := StateTrace.new(FIRST)
	for tick: int in range(FIRST, FIRST + 10):
		first.add(tick, 0, fighter)
		if tick == FIRST + 7:
			fighter.velocity.y = 0.5
		second.add(tick, 0, fighter)
		fighter.velocity.y = 0.0
	assert_object(StateTrace.first_difference(first.text(), first.text())).is_null()
	assert_str(first.sha256()).is_not_equal(second.sha256())
	var difference := StateTrace.first_difference(first.text(), second.text())
	assert_object(difference).is_not_null()
	assert_int(difference.tick).is_equal(7)
	assert_int(difference.fighter).is_equal(0)
	assert_str(difference.column).is_equal("velocity.y")
	assert_str(difference.first).is_equal(ReplayFile.f64_cell(0.0))
	assert_str(difference.second).is_equal(ReplayFile.f64_cell(0.5))
	assert_str(difference.describe()).contains("tick 7").contains("velocity.y").contains("0.5")
	# One trace stops earlier: it says where the other goes on.
	var shorter := StateTrace.new(FIRST)
	for tick: int in range(FIRST, FIRST + 4):
		shorter.add(tick, 0, fighter)
	var ended := StateTrace.first_difference(shorter.text(), first.text())
	assert_str(ended.column).is_equal("lines")
	assert_int(ended.tick).is_equal(4)
