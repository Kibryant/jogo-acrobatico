# The presses in the summary of TASK-14 (tools/replay_summary.gd), followed through the slot of
# the buffer as testes-e-entrega.md §4 says ("O resumo": "Os apertos"; F-166 §7; DEC-0039): on a
# tick with several presses the slot keeps the one of highest priority, the others never enter;
# the press that entered is used when the slot empties within the buffer's window, replaced when
# a newer press takes the slot, and expired when the slot empties later. The matches are played
# by the core's own rules (replay_summary_match.gd), so the slot is the one a replay shows, and
# the summary is read only through its public interface, agreed in the TASK-14 plan.
extends GdUnitTestSuite

const ReplaySummary := preload("res://tools/replay_summary.gd")
const PlayedMatch := preload("res://test/tools/replay_summary_match.gd")
const Tape := preload("res://test/tools/replay_summary_tape.gd")

const JUMP := FighterCommand.JUMP
const DASH := FighterCommand.DASH
const GRAPPLE := FighterCommand.GRAPPLE
const LIGHT := FighterCommand.LIGHT_ATTACK
const CHARGED := FighterCommand.CHARGED_ATTACK
const PARRY := FighterCommand.PARRY

# movimento.md, "Perdão": "Buffer de input", 150 ms, which at the game's 60 ticks are 9 ticks,
# counted inclusive (DEC-0039; Movement._within).
const BUFFER_MS := 150
const BUFFER_TICKS := 9


# A match of one fighter with the v0 numbers at 60 ticks.
func _solo() -> PlayedMatch:
	var played := PlayedMatch.new(Tape.movement_v0(), Tape.combat_v0())
	played.add_fighter()
	return played


# The press of a command on a tick, or a blank one, which fails every assert on it, with a failure
# that says it is missing.
func _press_of(
	report: ReplaySummary.FighterReport,
	command: StringName,
	tick: int,
) -> ReplaySummary.Press:
	for press: ReplaySummary.Press in report.presses:
		if press.command == command and press.tick == tick:
			return press
	fail("no press of %s on tick %d in the report" % [command, tick])
	return ReplaySummary.Press.new()


# The first tick a dash can fire after a jump pressed on tick 0: the first tick that starts on the
# floor again. Found by playing it, with the core's own rule: a dash pressed two ticks before the
# landing waits in the slot and fires there.
func _dash_tick_after_a_jump() -> int:
	var probe := _solo()
	probe.press(0, 0, [JUMP])
	probe.run(120)
	var landing := probe.first_tick(0, 1, _stands)
	assert_int(landing).override_failure_message("the jump never landed").is_greater(0)
	var played := _solo()
	played.press(0, 0, [JUMP])
	played.press(0, landing - 2, [DASH])
	played.run(landing + 20)
	var fired := played.first_tick(0, 1, _dashed_now)
	assert_int(fired).override_failure_message("the dash never fired").is_greater(0)
	return fired


static func _stands(state: FighterState, _tick: int) -> bool:
	return Movement.stands(state)


static func _dashed_now(state: FighterState, tick: int) -> bool:
	return state.dash_tick == tick


static func _jumped_once(state: FighterState, _tick: int) -> bool:
	return state.jumps_used == 1


func test_the_buffer_window_of_150_ms_is_9_ticks_at_60_and_5_at_30() -> void:
	# The conversion and its rounding: 150 ms are 9 ticks at 60 and 4,5 at 30, which rounds up.
	assert_int(Ticks.from_ms(BUFFER_MS, 60)).is_equal(BUFFER_TICKS)
	assert_int(Tape.movement_v0(60).buffer_ticks).is_equal(BUFFER_TICKS)
	assert_int(Tape.movement_v0(30).buffer_ticks).is_equal(5)


func test_a_replay_with_no_press_has_no_presses() -> void:
	var played := _solo()
	played.run(20)
	assert_int(played.summarize().fighter(0).presses.size()).is_equal(0)


func test_a_jump_pressed_on_the_floor_fires_on_its_own_tick() -> void:
	var played := _solo()
	played.press(0, 3, [JUMP])
	played.run(12)
	var report := played.summarize().fighter(0)
	assert_int(report.presses.size()).is_equal(1)
	var press := report.presses[0]
	assert_str(press.command).is_equal(JUMP)
	assert_int(press.tick).is_equal(3)
	assert_int(press.mode).is_equal(FighterState.Mode.GROUND)
	assert_int(press.fired_tick).is_equal(3)
	assert_str(press.reason).is_empty()


func test_a_jump_pressed_in_the_air_is_the_double_jump_at_once_with_the_air_as_its_mode() -> void:
	var played := _solo()
	played.press(0, 2, [JUMP])
	played.press(0, 9, [JUMP])
	played.run(20)
	var report := played.summarize().fighter(0)
	assert_int(report.presses.size()).is_equal(2)
	var second := _press_of(report, JUMP, 9)
	assert_int(second.mode).is_equal(FighterState.Mode.AIR)
	assert_int(second.fired_tick).is_equal(9)
	var double_jumps: int = report.maneuvers.get(ReplaySummary.DOUBLE_JUMP, -1)
	assert_int(double_jumps).is_equal(1)


func test_a_dash_pressed_in_the_air_waits_in_the_slot_and_fires_on_the_landing() -> void:
	var fires := _dash_tick_after_a_jump()
	var played := _solo()
	played.press(0, 0, [JUMP])
	played.press(0, fires - 4, [DASH])
	played.run(fires + 20)
	# The scenario, by the core's own stamp: the dash fired where the probe said.
	assert_int(played.state(0, fires).dash_tick).is_equal(fires)
	var report := played.summarize().fighter(0)
	var press := _press_of(report, DASH, fires - 4)
	assert_int(press.mode).is_equal(FighterState.Mode.AIR)
	assert_int(press.fired_tick).is_equal(fires)
	assert_str(press.reason).is_empty()
	var jump := _press_of(report, JUMP, 0)
	assert_int(jump.mode).is_equal(FighterState.Mode.GROUND)
	assert_int(jump.fired_tick).is_equal(0)


func test_a_press_is_still_used_on_the_last_tick_of_the_window() -> void:
	var fires := _dash_tick_after_a_jump()
	var played := _solo()
	played.press(0, 0, [JUMP])
	played.press(0, fires - BUFFER_TICKS, [DASH])
	played.run(fires + 20)
	assert_int(played.state(0, fires).dash_tick).is_equal(fires)
	var report := played.summarize().fighter(0)
	assert_int(_press_of(report, DASH, fires - BUFFER_TICKS).fired_tick).is_equal(fires)
	var dashes: int = report.maneuvers.get(ReplaySummary.DASH, -1)
	assert_int(dashes).is_equal(1)


func test_a_press_one_tick_before_the_window_expires_and_never_fires() -> void:
	var fires := _dash_tick_after_a_jump()
	var played := _solo()
	played.press(0, 0, [JUMP])
	played.press(0, fires - BUFFER_TICKS - 1, [DASH])
	played.run(fires + 20)
	# The scenario: no dash in the whole match.
	assert_int(played.first_tick(0, 0, _dashed_now)).is_equal(-1)
	var report := played.summarize().fighter(0)
	var press := _press_of(report, DASH, fires - BUFFER_TICKS - 1)
	assert_int(press.mode).is_equal(FighterState.Mode.AIR)
	assert_int(press.fired_tick).is_equal(-1)
	# The reason is the attacks' only.
	assert_str(press.reason).is_empty()
	var dashes: int = report.maneuvers.get(ReplaySummary.DASH, -1)
	assert_int(dashes).is_equal(0)


func test_a_newer_press_of_the_same_key_takes_the_slot_and_is_the_one_used() -> void:
	var fires := _dash_tick_after_a_jump()
	var played := _solo()
	played.press(0, 0, [JUMP])
	played.press(0, fires - 6, [DASH])
	played.press(0, fires - 2, [DASH])
	played.run(fires + 20)
	assert_int(played.state(0, fires).dash_tick).is_equal(fires)
	var report := played.summarize().fighter(0)
	assert_int(report.presses.size()).is_equal(3)
	# The older press was within its window on the landing, but it had left the slot by then.
	assert_int(_press_of(report, DASH, fires - 6).fired_tick).is_equal(-1)
	assert_int(_press_of(report, DASH, fires - 2).fired_tick).is_equal(fires)


func test_a_newer_press_of_another_key_takes_the_slot_from_the_one_waiting() -> void:
	var fires := _dash_tick_after_a_jump()
	var played := _solo()
	played.press(0, 0, [JUMP])
	played.press(0, fires - 6, [DASH])
	# The grapple finds nothing to bite (no aim hit in the rig): it takes the slot and expires.
	played.press(0, fires - 3, [GRAPPLE])
	played.run(fires + 20)
	assert_int(played.first_tick(0, 0, _dashed_now)).is_equal(-1)
	var report := played.summarize().fighter(0)
	assert_int(_press_of(report, DASH, fires - 6).fired_tick).is_equal(-1)
	var grapple := _press_of(report, GRAPPLE, fires - 3)
	assert_int(grapple.fired_tick).is_equal(-1)
	assert_int(grapple.mode).is_equal(FighterState.Mode.AIR)


func test_a_jump_pressed_in_the_dash_has_the_dash_as_its_mode_and_fires_at_its_end() -> void:
	var played := _solo()
	played.press(0, 2, [DASH])
	played.press(0, 7, [JUMP])
	played.run(40)
	var jumped := played.first_tick(0, 0, _jumped_once)
	# The scenario: the dash holds the jump, which fires later, within its window.
	assert_int(jumped).is_greater(7)
	assert_int(jumped).is_less_equal(7 + BUFFER_TICKS)
	var report := played.summarize().fighter(0)
	var dash := _press_of(report, DASH, 2)
	assert_int(dash.mode).is_equal(FighterState.Mode.GROUND)
	assert_int(dash.fired_tick).is_equal(2)
	var jump := _press_of(report, JUMP, 7)
	assert_int(jump.mode).is_equal(FighterState.Mode.DASH)
	assert_int(jump.fired_tick).is_equal(jumped)


func test_on_one_tick_the_jump_takes_the_slot_and_the_dash_never_enters() -> void:
	var played := _solo()
	played.press(0, 2, [JUMP, DASH])
	played.run(60)
	var report := played.summarize().fighter(0)
	assert_int(report.presses.size()).is_equal(2)
	assert_int(_press_of(report, JUMP, 2).fired_tick).is_equal(2)
	var dash := _press_of(report, DASH, 2)
	assert_int(dash.fired_tick).is_equal(-1)
	assert_int(dash.mode).is_equal(FighterState.Mode.GROUND)
	assert_str(dash.reason).is_empty()


func test_on_one_tick_the_dash_takes_the_slot_from_the_grapple() -> void:
	var played := _solo()
	played.press(0, 2, [DASH, GRAPPLE])
	played.run(30)
	var report := played.summarize().fighter(0)
	assert_int(_press_of(report, DASH, 2).fired_tick).is_equal(2)
	assert_int(_press_of(report, GRAPPLE, 2).fired_tick).is_equal(-1)


func test_a_light_under_a_jump_on_the_same_tick_never_fires_and_says_same_tick() -> void:
	var played := _solo()
	played.press(0, 2, [JUMP, LIGHT])
	played.run(60)
	var report := played.summarize().fighter(0)
	assert_int(_press_of(report, JUMP, 2).fired_tick).is_equal(2)
	var light := _press_of(report, LIGHT, 2)
	assert_int(light.fired_tick).is_equal(-1)
	assert_str(light.reason).is_equal(ReplaySummary.SAME_TICK)
	assert_int(light.mode).is_equal(FighterState.Mode.GROUND)
	assert_int(report.swings.size()).is_equal(0)


func test_a_light_under_a_parry_press_says_same_tick_and_the_parry_is_no_press() -> void:
	var played := _solo()
	played.press(0, 2, [PARRY, LIGHT])
	played.run(60)
	var report := played.summarize().fighter(0)
	# The parry counts only for the priority: its press stays out.
	assert_int(report.presses.size()).is_equal(1)
	var light := _press_of(report, LIGHT, 2)
	assert_int(light.fired_tick).is_equal(-1)
	assert_str(light.reason).is_equal(ReplaySummary.SAME_TICK)
	assert_int(report.swings.size()).is_equal(0)


func test_a_parry_press_alone_is_not_a_press_of_the_summary() -> void:
	var played := _solo()
	played.press(0, 2, [PARRY])
	played.run(60)
	assert_int(played.summarize().fighter(0).presses.size()).is_equal(0)


func test_a_charged_under_a_parry_press_says_same_tick() -> void:
	var played := _solo()
	played.press(0, 2, [PARRY, CHARGED])
	played.run(60)
	var report := played.summarize().fighter(0)
	assert_int(report.presses.size()).is_equal(1)
	var charged := _press_of(report, CHARGED, 2)
	assert_int(charged.fired_tick).is_equal(-1)
	assert_str(charged.reason).is_equal(ReplaySummary.SAME_TICK)


func test_a_light_under_a_charged_on_the_same_tick_says_same_tick_and_the_charged_fires() -> void:
	var played := _solo()
	played.press(0, 2, [CHARGED, LIGHT])
	played.run(100)
	var report := played.summarize().fighter(0)
	assert_int(report.presses.size()).is_equal(2)
	var charged := _press_of(report, CHARGED, 2)
	assert_int(charged.fired_tick).is_equal(2)
	assert_str(charged.reason).is_empty()
	var light := _press_of(report, LIGHT, 2)
	assert_int(light.fired_tick).is_equal(-1)
	assert_str(light.reason).is_equal(ReplaySummary.SAME_TICK)
	assert_int(report.swings.size()).is_equal(1)
	assert_str(report.swings[0].move).is_equal(CHARGED)


func test_every_key_on_one_tick_leaves_only_the_jump_used() -> void:
	var played := _solo()
	played.press(0, 2, [JUMP, DASH, GRAPPLE, PARRY, CHARGED, LIGHT])
	played.run(60)
	var report := played.summarize().fighter(0)
	# Five presses: the parry's stays out.
	assert_int(report.presses.size()).is_equal(5)
	assert_int(_press_of(report, JUMP, 2).fired_tick).is_equal(2)
	for command: StringName in [DASH, GRAPPLE, CHARGED, LIGHT]:
		assert_int(_press_of(report, command, 2).fired_tick).is_equal(-1)
	assert_str(_press_of(report, CHARGED, 2).reason).is_equal(ReplaySummary.SAME_TICK)
	assert_str(_press_of(report, LIGHT, 2).reason).is_equal(ReplaySummary.SAME_TICK)
	assert_str(_press_of(report, DASH, 2).reason).is_empty()
	assert_int(report.swings.size()).is_equal(0)


func test_presses_come_in_the_order_of_their_ticks() -> void:
	var played := _solo()
	played.press(0, 2, [JUMP])
	played.press(0, 9, [JUMP])
	played.press(0, 14, [DASH])
	played.press(0, 16, [LIGHT])
	played.run(30)
	var report := played.summarize().fighter(0)
	assert_int(report.presses.size()).is_equal(4)
	var ticks: Array[int] = []
	var commands: Array[StringName] = []
	for press: ReplaySummary.Press in report.presses:
		ticks.append(press.tick)
		commands.append(press.command)
	assert_array(ticks).is_equal([2, 9, 14, 16])
	assert_array(commands).is_equal([JUMP, JUMP, DASH, LIGHT])
