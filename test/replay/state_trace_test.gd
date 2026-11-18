# Criteria 4 and 5 of TASK-10.3: the state trace (replay/state_trace.gd). It writes the whole state
# after a tick, the body and every field of FighterState found by reflection, with the ticks and
# the stamps counted from the first recorded tick and NEVER kept as NEVER, so a --watch that starts
# on another tick compares with the headless player; where two traces part, it says the tick, the
# fighter, the column and the two values.
# TASK-14: the writer has its reader (StateTrace.line_from beside StateTrace.parse_line, as
# JSON.stringify beside JSON.parse), which the replay summary counts from: a line read back writes
# the same line again, byte for byte, and a line that is not one of this build's reads as null.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const ReplaySession := preload("res://test/replay/replay_session.gd")
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
	var state := FighterState.new()
	for field: String in ReplayFile.script_fields(state):
		var expected: Array[String] = [field]
		if typeof(state.get(field)) == TYPE_VECTOR3:
			expected = ["%s.x" % field, "%s.y" % field, "%s.z" % field]
		for column: String in expected:
			assert_bool(names.has(column)).override_failure_message("no %s" % column).is_true()


# One name per cell: a vector of the state (dash_direction, TASK-10.4) writes three cells, so it
# has three names, and where two traces part names the right column.
func test_the_header_names_every_cell_of_a_line() -> void:
	var line := StateTrace.line_of(_fighter(), 0, FIRST, FIRST)
	var names := StateTrace.header().split(",")
	assert_int(names.size()).is_equal(line.split(",").size())
	var cells := _cells(line)
	assert_str(cells["dash_direction.z"]).is_equal(ReplayFile.f64_cell(0.0))
	assert_str(cells["dash_tick"]).is_equal(str(FighterState.NEVER))


# The stamps are the fields named *_tick or *_since (glossario.md, "Carimbo de tick"); a count, as
# jumps_used, or the mode is not one.
func test_the_stamps_are_the_fields_named_tick_or_since() -> void:
	var stamps: Array[String] = [
		"mode_since",
		"left_floor_tick",
		"buffered_tick",
		"stamina_spent_tick",
		"double_jump_tick",
		"dash_tick",
	]
	for field: String in stamps:
		assert_bool(StateTrace.is_stamp(field)).override_failure_message(field).is_true()
	for field: String in ["mode", "jumps_used", "on_floor", "facing_yaw", "stamina_at_spend"]:
		assert_bool(StateTrace.is_stamp(field)).override_failure_message(field).is_false()


# Every int field of the state is classified on purpose: a stamp, counted from the first tick in
# the trace, or a count or an enum, written as it is. A new int field with another name fails
# here, not as a silent mismatch between the window and the headless player (review of TASK-10.3).
func test_every_int_field_of_the_state_is_a_stamp_or_listed_as_not_one() -> void:
	# TASK-12.1: the action is an enum and the health a count of points, both written as they are.
	var not_stamps: Array[String] = ["mode", "jumps_used", "action", "health"]
	var state := FighterState.new()
	for field: String in ReplayFile.script_fields(state):
		if typeof(state.get(field)) != TYPE_INT:
			continue
		var classified := StateTrace.is_stamp(field) or not_stamps.has(field)
		var message := "%s is neither a stamp nor listed as not one" % field
		assert_bool(classified).override_failure_message(message).is_true()


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


# A state with every field off its default (TASK-14): stamps before and after the first tick,
# vectors, names and enums, each value its own. A fresh state has the NEVERs.
static func _unusual_state() -> FighterState:
	var state := FighterState.new()
	state.mode = FighterState.Mode.WALL_RUN
	state.mode_since = FIRST - 7
	state.on_floor = false
	state.left_floor_tick = FIRST + 1
	state.buffered_command = FighterCommand.CHARGED_ATTACK
	state.buffered_tick = FIRST + 12
	state.jumps_used = 2
	state.facing_yaw = -PI / 3.0
	state.stamina_at_spend = 41.25
	state.stamina_spent_tick = FIRST + 9
	state.double_jump_tick = FIRST - 3
	state.dash_tick = FIRST + 4
	state.dash_direction = Vector3(0.6, 0.0, -0.8)
	state.wall_normal = Vector3(-1.0, 0.0, 0.0)
	state.wall_id = &"Paredes/ParedeLonga"
	state.wall_jump_tick = FIRST + 5
	state.grapple_fired_tick = FIRST + 6
	state.grapple_point = Vector3(1.5, 20.25, -3.125)
	state.grapple_end_tick = FIRST + 2
	state.slide_off_dir = Vector3(0.0, 0.0, 1.0)
	state.head_landing_tick = FIRST + 8
	state.action = FighterState.Action.PARRIED
	state.action_since = FIRST + 10
	state.action_move = FighterCommand.LIGHT_ATTACK
	state.action_yaw = 0.123456789
	state.contact_tick = FIRST + 11
	state.contact_target = &"Fighter1"
	state.contact_move = FighterCommand.CHARGED_ATTACK
	state.health = 64
	state.hurt_tick = FIRST + 13
	state.stun_until_tick = FIRST + 40
	state.block_tick = FIRST + 14
	state.frozen_until_tick = FIRST + 15
	state.parry_tick = FIRST + 16
	state.parried_tick = FIRST + 17
	state.grabbed_tick = FIRST + 18
	state.tech_tick = FIRST + 19
	state.tech_press_tick = FIRST + 20
	return state


static func _written_again(row: StateTrace.Row) -> String:
	return StateTrace.line_from(row.tick, row.fighter, row.position, row.velocity, row.state, 0)


func test_a_state_with_every_field_off_its_default_reads_back_into_the_same_line() -> void:
	var state := _unusual_state()
	# The precondition, by reflection: a field a later task adds fails here until it is set too.
	var fresh := FighterState.new()
	for field: String in ReplayFile.script_fields(state):
		var unusual: bool = state.get(field) != fresh.get(field)
		assert_bool(unusual).override_failure_message("%s is at its default" % field).is_true()
	var position := Vector3(1.0, -2.5, 1.0 / 3.0)
	var velocity := Vector3(-0.0, 7.25, -0.0001)
	var line := StateTrace.line_from(FIRST + 25, 1, position, velocity, state, FIRST)
	var row := StateTrace.parse_line(line)
	assert_object(row).is_not_null()
	if row == null:
		return
	# The ticks and the stamps as the line has them, counted from the first tick.
	assert_int(row.tick).is_equal(25)
	assert_int(row.fighter).is_equal(1)
	assert_int(row.state.mode_since).is_equal(-7)
	assert_int(row.state.left_floor_tick).is_equal(1)
	assert_int(row.state.parried_tick).is_equal(17)
	assert_int(row.state.mode).is_equal(FighterState.Mode.WALL_RUN)
	assert_int(row.state.action).is_equal(FighterState.Action.PARRIED)
	assert_bool(row.state.on_floor).is_false()
	assert_int(typeof(row.state.wall_id)).is_equal(TYPE_STRING_NAME)
	assert_str(row.state.wall_id).is_equal("Paredes/ParedeLonga")
	assert_float(row.state.facing_yaw).is_equal(-PI / 3.0)
	assert_vector(row.state.grapple_point).is_equal(Vector3(1.5, 20.25, -3.125))
	assert_vector(row.position).is_equal(position)
	assert_vector(row.velocity).is_equal(velocity)
	assert_str(_written_again(row)).is_equal(line)


# A fresh state, every stamp NEVER: NEVER stays NEVER, never counted from the first tick.
func test_a_fresh_state_reads_back_with_never_as_never() -> void:
	var line := StateTrace.line_from(
		FIRST,
		0,
		Vector3.ZERO,
		Vector3.ZERO,
		FighterState.new(),
		FIRST,
	)
	var row := StateTrace.parse_line(line)
	assert_object(row).is_not_null()
	if row == null:
		return
	assert_int(row.tick).is_equal(0)
	assert_int(row.state.mode_since).is_equal(FighterState.NEVER)
	assert_int(row.state.hurt_tick).is_equal(FighterState.NEVER)
	assert_str(row.state.buffered_command).is_empty()
	assert_str(_written_again(row)).is_equal(line)


# Every line of a real session: the gate's scripted one (test/replay/replay_session.gd), with a
# wall run, double jumps, dashes and a grapple in its fields.
func test_every_line_of_a_recorded_session_reads_back_into_the_same_line() -> void:
	var folder := OS.get_temp_dir().path_join("jogo-acrobatico-trace-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(folder)
	var path := folder.path_join("session.replay")
	var session := await ReplaySession.new().record(self, path)
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(folder)
	# The precondition: the trace holds the fields with something in them.
	assert_int(session.wall_runs).is_greater(0)
	assert_int(session.dashes).is_greater(0)
	assert_int(session.grapples).is_greater(0)
	var lines := session.trace.lines()
	assert_int(lines.size()).is_equal(session.ticks)
	var apart := 0
	var first_apart := ""
	for line: String in lines:
		var row := StateTrace.parse_line(line)
		if row != null and _written_again(row) == line:
			continue
		apart += 1
		if first_apart.is_empty():
			first_apart = line
	var message := "%d lines read back into another line, the first: %s" % [apart, first_apart]
	assert_int(apart).override_failure_message(message).is_equal(0)


func test_a_line_that_is_not_one_of_this_builds_reads_as_null() -> void:
	var line := StateTrace.line_from(
		FIRST + 3,
		0,
		Vector3.ONE,
		Vector3.ZERO,
		_unusual_state(),
		FIRST,
	)
	assert_object(StateTrace.parse_line(line)).is_not_null()
	var cells := line.split(",")
	assert_object(StateTrace.parse_line("")).is_null()
	assert_object(StateTrace.parse_line(StateTrace.header())).is_null()
	assert_object(StateTrace.parse_line(",".join(cells.slice(0, cells.size() - 1)))).is_null()
	assert_object(StateTrace.parse_line(line + ",0")).is_null()
	assert_object(StateTrace.parse_line(line.replace(",", ";"))).is_null()
	# One cell of each kind that is not of its column's type.
	var names := StateTrace.header().split(",")
	var wrong: Dictionary[String, String] = {
		"tick": "3.5",
		"fighter": "",
		"position.x": "3ff0",
		"velocity.y": ReplayFile.f64_cell(1.0).to_upper(),
		"mode_since": "--7",
		"on_floor": "2",
		"facing_yaw": "0",
		"wall_id": "abc",
		"action_move": "zz",
		"dash_direction.z": ReplayFile.f64_cell(0.5) + "0",
		"health": "x",
	}
	for column: String in wrong:
		var index := names.find(column)
		assert_int(index).override_failure_message("no column %s" % column).is_not_equal(-1)
		var spoiled := cells.duplicate()
		spoiled[index] = wrong[column]
		var read := StateTrace.parse_line(",".join(spoiled))
		var message := "%s = %s read as a line" % [column, wrong[column]]
		assert_object(read).override_failure_message(message).is_null()
