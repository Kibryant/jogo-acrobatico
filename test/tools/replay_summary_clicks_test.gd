# Criteria 4 and 5 of TASK-14, the clicks: the light's and the charged's presses in the summary
# (tools/replay_summary.gd), as testes-e-entrega.md §4 says ("O resumo": "Os golpes"; F-178 §1;
# F-180 §1; F-205): the swings that fired, the ones that waited in the slot, the chained ones, and
# every click that never fired under the first reason that holds, in the spec's order: replaced on
# the same tick, during a swing (with the phase the click met and the ticks into that swing), in a
# stun, in a stance, off the floor, without stamina. The matches are played by the core's own
# rules (replay_summary_match.gd), and the summary is read only through its public interface,
# agreed in the TASK-14 plan.
extends GdUnitTestSuite

const ReplaySummary := preload("res://tools/replay_summary.gd")
const PlayedMatch := preload("res://test/tools/replay_summary_match.gd")
const Tape := preload("res://test/tools/replay_summary_tape.gd")

const JUMP := FighterCommand.JUMP
const LIGHT := FighterCommand.LIGHT_ATTACK
const CHARGED := FighterCommand.CHARGED_ATTACK
const PARRY := FighterCommand.PARRY

# combate.md, "O leve no tick": "As fases" (DEC-0052): 250, 100 and 200 ms, which at 60 ticks are
# 15, 6 and 12. Fired at F, the light is active from F + 15, in recovery from F + 21 and over at
# F + 33.
const LIGHT_ACTIVE := 15
const LIGHT_RECOVERY := 21
const LIGHT_OVER := 33
# combate.md, "As fases do carregado" (DEC-0056 §2): 42, 7 and 27 ticks at 60. Fired at F, the
# charged is active from F + 42, in recovery from F + 49 and over at F + 76.
const CHARGED_ACTIVE := 42
const CHARGED_OVER := 76
# movimento.md, "Perdão": "Buffer de input", 150 ms: 9 ticks at 60, inclusive (DEC-0039).
const BUFFER_TICKS := 9
# combate.md, "Os golpes e as defesas": the light costs 8 of stamina, paid as it starts, and the
# charged needs 25 on the bar; movimento.md, "Stamina": the bar holds 100.
const LIGHT_COST := 8.0
const CHARGED_COST := 25.0
# The tick the first click of most matches lands on: any tick after the first.
const F := 2


func _solo() -> PlayedMatch:
	var played := PlayedMatch.new(Tape.movement_v0(), Tape.combat_v0())
	played.add_fighter()
	return played


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


# The click of a move on a tick never fired, for this reason.
func _assert_lost(
	report: ReplaySummary.FighterReport,
	command: StringName,
	tick: int,
	reason: StringName,
) -> void:
	var press := _press_of(report, command, tick)
	var fired := "the %s of tick %d fired on %d" % [command, tick, press.fired_tick]
	assert_int(press.fired_tick).override_failure_message(fired).is_equal(-1)
	var message := "the %s of tick %d: expected %s, got %s" % [command, tick, reason, press.reason]
	assert_str(press.reason).override_failure_message(message).is_equal(reason)


# The click never fired because it met a swing: in this phase, this many ticks into it.
func _assert_lost_in_swing(
	report: ReplaySummary.FighterReport,
	command: StringName,
	tick: int,
	phase: FighterState.Action,
	into_swing: int,
) -> void:
	_assert_lost(report, command, tick, ReplaySummary.SWING)
	var press := _press_of(report, command, tick)
	assert_int(press.phase).is_equal(phase)
	assert_int(press.into_swing).is_equal(into_swing)


# `count` lights, each chained on the one before: the first clicked on F, every next one clicked
# BUFFER_TICKS before the swing before it ends, so it fires on that end. Returns the tick the last
# swing is over.
func _chain_lights(played: PlayedMatch, count: int) -> int:
	for swing: int in count:
		var fires := F + swing * LIGHT_OVER
		played.press(0, F if swing == 0 else fires - BUFFER_TICKS, [LIGHT])
	return F + count * LIGHT_OVER


static func _in_windup(state: FighterState, _tick: int) -> bool:
	return state.action == FighterState.Action.WINDUP


static func _stands(state: FighterState, _tick: int) -> bool:
	return Movement.stands(state)


static func _touched_now(state: FighterState, tick: int) -> bool:
	return state.contact_tick == tick


func test_the_phases_of_the_two_moves_in_ms_are_these_ticks_at_60() -> void:
	# The conversion: 250, 100 and 200 ms; 700, 120 and 450 ms (120 ms are 7,2 ticks: 7).
	var light: AttackConfig = Tape.combat_v0().attacks[LIGHT]
	assert_int(light.windup_ticks).is_equal(LIGHT_ACTIVE)
	assert_int(light.windup_ticks + light.active_ticks).is_equal(LIGHT_RECOVERY)
	assert_int(light.windup_ticks + light.active_ticks + light.recovery_ticks).is_equal(LIGHT_OVER)
	var charged: AttackConfig = Tape.combat_v0().attacks[CHARGED]
	assert_int(charged.windup_ticks).is_equal(CHARGED_ACTIVE)
	assert_int(charged.active_ticks).is_equal(7)
	assert_int(charged.windup_ticks + charged.active_ticks + charged.recovery_ticks).is_equal(
		CHARGED_OVER,
	)

# --- The swings that fired ---


func test_a_replay_with_no_click_has_no_swing() -> void:
	var played := _solo()
	played.press(0, F, [JUMP])
	played.run(60)
	var report := played.summarize().fighter(0)
	assert_int(report.swings.size()).is_equal(0)


func test_a_light_clicked_standing_fires_at_once_as_one_swing() -> void:
	var played := _solo()
	played.press(0, F, [LIGHT])
	played.run(F + LIGHT_OVER + 10)
	var report := played.summarize().fighter(0)
	assert_int(report.presses.size()).is_equal(1)
	var press := report.presses[0]
	assert_str(press.command).is_equal(LIGHT)
	assert_int(press.mode).is_equal(FighterState.Mode.GROUND)
	assert_int(press.fired_tick).is_equal(F)
	assert_str(press.reason).is_empty()
	assert_int(report.swings.size()).is_equal(1)
	var swing := report.swings[0]
	assert_str(swing.move).is_equal(LIGHT)
	assert_int(swing.fire_tick).is_equal(F)
	assert_int(swing.press_tick).is_equal(F)
	assert_bool(swing.chained).is_false()
	assert_int(swing.active_tick).is_equal(F + LIGHT_ACTIVE)


func test_a_charged_clicked_standing_fires_at_once_as_one_swing_of_its_own_move() -> void:
	var played := _solo()
	played.press(0, F, [CHARGED])
	played.run(F + CHARGED_OVER + 10)
	var report := played.summarize().fighter(0)
	assert_int(_press_of(report, CHARGED, F).fired_tick).is_equal(F)
	assert_int(report.swings.size()).is_equal(1)
	var swing := report.swings[0]
	assert_str(swing.move).is_equal(CHARGED)
	assert_int(swing.fire_tick).is_equal(F)
	assert_int(swing.press_tick).is_equal(F)
	assert_bool(swing.chained).is_false()
	assert_int(swing.active_tick).is_equal(F + CHARGED_ACTIVE)


func test_a_light_clicked_in_the_air_just_before_the_landing_waits_in_the_slot_and_fires() -> void:
	var probe := _solo()
	probe.press(0, 0, [JUMP])
	probe.run(120)
	var landing := probe.first_tick(0, 1, _stands)
	assert_int(landing).override_failure_message("the jump never landed").is_greater(0)
	var played := _solo()
	played.press(0, 0, [JUMP])
	played.press(0, landing - 3, [LIGHT])
	played.run(landing + 50)
	var fires := played.first_tick(0, 0, _in_windup)
	# The scenario: the click waited, then the swing fired within its window.
	assert_int(fires).is_greater(landing - 3)
	assert_int(fires).is_less_equal(landing - 3 + BUFFER_TICKS)
	var report := played.summarize().fighter(0)
	var press := _press_of(report, LIGHT, landing - 3)
	assert_int(press.mode).is_equal(FighterState.Mode.AIR)
	assert_int(press.fired_tick).is_equal(fires)
	assert_str(press.reason).is_empty()
	assert_int(report.swings.size()).is_equal(1)
	var swing := report.swings[0]
	assert_int(swing.fire_tick).is_equal(fires)
	assert_int(swing.press_tick).is_equal(landing - 3)
	assert_bool(swing.chained).is_false()

# --- The chained swings ---


func test_a_click_on_the_last_tick_of_its_window_fires_chained_on_the_tick_the_swing_ends() -> void:
	var played := _solo()
	played.press(0, F, [LIGHT])
	var second := F + LIGHT_OVER - BUFFER_TICKS
	played.press(0, second, [LIGHT])
	played.run(F + 2 * LIGHT_OVER + 10)
	var report := played.summarize().fighter(0)
	assert_int(report.swings.size()).is_equal(2)
	assert_bool(report.swings[0].chained).is_false()
	var chained := report.swings[1]
	assert_str(chained.move).is_equal(LIGHT)
	assert_int(chained.fire_tick).is_equal(F + LIGHT_OVER)
	assert_int(chained.press_tick).is_equal(second)
	assert_bool(chained.chained).is_true()
	assert_int(chained.active_tick).is_equal(F + LIGHT_OVER + LIGHT_ACTIVE)
	var press := _press_of(report, LIGHT, second)
	assert_int(press.fired_tick).is_equal(F + LIGHT_OVER)
	assert_str(press.reason).is_empty()


func test_a_click_one_tick_before_that_window_expires_in_the_recovery() -> void:
	var played := _solo()
	played.press(0, F, [LIGHT])
	var late := F + LIGHT_OVER - BUFFER_TICKS - 1
	played.press(0, late, [LIGHT])
	played.run(F + 2 * LIGHT_OVER + 10)
	var report := played.summarize().fighter(0)
	assert_int(report.swings.size()).is_equal(1)
	_assert_lost_in_swing(
		report,
		LIGHT,
		late,
		FighterState.Action.RECOVERY,
		LIGHT_OVER - BUFFER_TICKS - 1,
	)


func test_a_click_on_the_very_tick_the_swing_ends_is_chained_without_waiting() -> void:
	var played := _solo()
	played.press(0, F, [LIGHT])
	played.press(0, F + LIGHT_OVER, [LIGHT])
	played.run(F + 2 * LIGHT_OVER + 10)
	var report := played.summarize().fighter(0)
	assert_int(report.swings.size()).is_equal(2)
	var chained := report.swings[1]
	assert_int(chained.fire_tick).is_equal(F + LIGHT_OVER)
	assert_int(chained.press_tick).is_equal(F + LIGHT_OVER)
	assert_bool(chained.chained).is_true()


func test_a_swing_after_a_gap_is_not_chained() -> void:
	var played := _solo()
	played.press(0, F, [LIGHT])
	# One tick after the end: the state the tick started from was already at rest.
	played.press(0, F + LIGHT_OVER + 1, [LIGHT])
	played.run(F + 2 * LIGHT_OVER + 10)
	var report := played.summarize().fighter(0)
	assert_int(report.swings.size()).is_equal(2)
	var second := report.swings[1]
	assert_int(second.fire_tick).is_equal(F + LIGHT_OVER + 1)
	assert_int(second.press_tick).is_equal(F + LIGHT_OVER + 1)
	assert_bool(second.chained).is_false()


func test_many_chained_lights_are_each_one_swing() -> void:
	var played := _solo()
	var over := _chain_lights(played, 5)
	played.run(over + 10)
	var report := played.summarize().fighter(0)
	assert_int(report.presses.size()).is_equal(5)
	assert_int(report.swings.size()).is_equal(5)
	for index: int in 5:
		var swing := report.swings[index]
		assert_int(swing.fire_tick).is_equal(F + index * LIGHT_OVER)
		assert_bool(swing.chained).is_equal(index > 0)
		# The first fired on its click; every other waited the whole window.
		assert_int(swing.fire_tick - swing.press_tick).is_equal(0 if index == 0 else BUFFER_TICKS)


func test_a_charged_clicked_in_the_light_recovery_is_a_chained_swing_of_the_charged() -> void:
	var played := _solo()
	played.press(0, F, [LIGHT])
	var click := F + LIGHT_OVER - BUFFER_TICKS
	played.press(0, click, [CHARGED])
	played.run(F + LIGHT_OVER + CHARGED_OVER + 10)
	var report := played.summarize().fighter(0)
	assert_int(report.swings.size()).is_equal(2)
	assert_str(report.swings[0].move).is_equal(LIGHT)
	var charged := report.swings[1]
	assert_str(charged.move).is_equal(CHARGED)
	assert_int(charged.fire_tick).is_equal(F + LIGHT_OVER)
	assert_int(charged.press_tick).is_equal(click)
	assert_bool(charged.chained).is_true()
	assert_int(charged.active_tick).is_equal(F + LIGHT_OVER + CHARGED_ACTIVE)

# --- The clicks lost during a swing ---


func test_light_clicks_spammed_in_the_windup_are_each_lost_in_the_windup() -> void:
	var played := _solo()
	played.press(0, F, [LIGHT])
	for into: int in [3, 5, 7]:
		played.press(0, F + into, [LIGHT])
	played.run(F + LIGHT_OVER + 10)
	var report := played.summarize().fighter(0)
	assert_int(report.presses.size()).is_equal(4)
	assert_int(report.swings.size()).is_equal(1)
	# The first two were replaced in the slot by the next click; the last expired in the active.
	for into: int in [3, 5, 7]:
		_assert_lost_in_swing(report, LIGHT, F + into, FighterState.Action.WINDUP, into)


func test_a_lost_click_says_the_phase_of_the_state_after_its_tick() -> void:
	var played := _solo()
	played.press(0, F, [LIGHT])
	# The last tick of the windup, the first of the active, and the first of the recovery.
	played.press(0, F + LIGHT_ACTIVE - 1, [LIGHT])
	played.press(0, F + LIGHT_ACTIVE, [LIGHT])
	played.press(0, F + LIGHT_RECOVERY, [LIGHT])
	played.run(F + LIGHT_OVER + 10)
	var report := played.summarize().fighter(0)
	assert_int(report.swings.size()).is_equal(1)
	_assert_lost_in_swing(
		report,
		LIGHT,
		F + LIGHT_ACTIVE - 1,
		FighterState.Action.WINDUP,
		LIGHT_ACTIVE - 1,
	)
	_assert_lost_in_swing(report, LIGHT, F + LIGHT_ACTIVE, FighterState.Action.ACTIVE, LIGHT_ACTIVE)
	_assert_lost_in_swing(
		report,
		LIGHT,
		F + LIGHT_RECOVERY,
		FighterState.Action.RECOVERY,
		LIGHT_RECOVERY,
	)


func test_a_click_replaced_in_the_slot_is_lost_and_the_newer_one_fires_chained() -> void:
	var played := _solo()
	played.press(0, F, [LIGHT])
	played.press(0, F + 20, [LIGHT])
	played.press(0, F + 26, [LIGHT])
	played.run(F + 2 * LIGHT_OVER + 10)
	var report := played.summarize().fighter(0)
	assert_int(report.swings.size()).is_equal(2)
	_assert_lost_in_swing(report, LIGHT, F + 20, FighterState.Action.ACTIVE, 20)
	assert_int(_press_of(report, LIGHT, F + 26).fired_tick).is_equal(F + LIGHT_OVER)
	assert_int(report.swings[1].press_tick).is_equal(F + 26)
	assert_bool(report.swings[1].chained).is_true()


func test_a_charged_click_in_the_light_windup_is_a_charged_click_lost_in_the_windup() -> void:
	var played := _solo()
	played.press(0, F, [LIGHT])
	played.press(0, F + 4, [CHARGED])
	played.run(F + LIGHT_OVER + 10)
	var report := played.summarize().fighter(0)
	assert_int(report.swings.size()).is_equal(1)
	_assert_lost_in_swing(report, CHARGED, F + 4, FighterState.Action.WINDUP, 4)


func test_a_light_click_in_the_charged_windup_counts_from_the_charged_fire() -> void:
	var played := _solo()
	played.press(0, F, [CHARGED])
	played.press(0, F + 30, [LIGHT])
	played.press(0, F + CHARGED_ACTIVE + 2, [CHARGED])
	played.run(F + CHARGED_OVER + 10)
	var report := played.summarize().fighter(0)
	assert_int(report.swings.size()).is_equal(1)
	_assert_lost_in_swing(report, LIGHT, F + 30, FighterState.Action.WINDUP, 30)
	_assert_lost_in_swing(
		report,
		CHARGED,
		F + CHARGED_ACTIVE + 2,
		FighterState.Action.ACTIVE,
		CHARGED_ACTIVE + 2,
	)


func test_a_click_in_the_second_swing_counts_its_ticks_from_that_swing() -> void:
	var played := _solo()
	var over := _chain_lights(played, 2)
	var second_fire := F + LIGHT_OVER
	played.press(0, second_fire + 6, [LIGHT])
	played.run(over + 10)
	var report := played.summarize().fighter(0)
	assert_int(report.swings.size()).is_equal(2)
	_assert_lost_in_swing(report, LIGHT, second_fire + 6, FighterState.Action.WINDUP, 6)

# --- The other reasons, each in its order ---


func test_a_click_under_a_jump_during_a_swing_says_same_tick_before_the_swing() -> void:
	var played := _solo()
	played.press(0, F, [LIGHT])
	played.press(0, F + 5, [JUMP, LIGHT])
	played.run(F + LIGHT_OVER + 10)
	var report := played.summarize().fighter(0)
	_assert_lost(report, LIGHT, F + 5, ReplaySummary.SAME_TICK)
	assert_int(report.swings.size()).is_equal(1)


func test_a_click_in_the_hitstun_of_a_hit_taken_is_lost_in_the_stun() -> void:
	var played := PlayedMatch.new(Tape.movement_v0(), Tape.combat_v0())
	# The camera turned so the swing goes straight down -Z (combate.md, "A espada na mira").
	var convergence := played.tape.combat.attacks[FighterCommand.LIGHT_ATTACK].aim_convergence
	var aim := asin(played.tape.movement.aim_side / convergence)
	var victim := played.add_fighter(Vector3(0.0, 0.0, -1.5), PI)
	var attacker := played.add_fighter(Vector3.ZERO, aim)
	played.press(attacker, F, [LIGHT])
	played.run_through(F + LIGHT_RECOVERY)
	var contact := played.first_tick(attacker, 0, _touched_now)
	assert_int(contact).override_failure_message("the light never touched").is_greater(0)
	# Six ticks after the contact: past the hitstop, deep in the 400 ms of hitstun.
	var click := contact + 6
	played.press(victim, click, [LIGHT])
	played.run(60)
	# The scenario: in the stun on the click, and still in it when the click's window closed.
	assert_int(played.state(victim, click).action).is_equal(FighterState.Action.HITSTUN)
	var closes := click + BUFFER_TICKS + 1
	assert_int(played.state(victim, closes).action).is_equal(FighterState.Action.HITSTUN)
	var report := played.summarize().fighter(victim)
	_assert_lost(report, LIGHT, click, ReplaySummary.STUN)
	assert_int(report.swings.size()).is_equal(0)


func test_a_click_in_the_parry_stance_is_lost_in_the_stance() -> void:
	var played := _solo()
	played.press(0, F, [PARRY])
	played.press(0, F + 5, [LIGHT])
	played.run(80)
	# The scenario: the stance was up on the click and when its window closed.
	assert_int(played.state(0, F + 5).action).is_equal(FighterState.Action.PARRY)
	assert_int(played.state(0, F + 5 + BUFFER_TICKS + 1).action).is_equal(FighterState.Action.PARRY)
	var report := played.summarize().fighter(0)
	assert_int(report.presses.size()).is_equal(1)
	_assert_lost(report, LIGHT, F + 5, ReplaySummary.STANCE)


func test_a_click_in_the_feint_is_lost_in_the_stance_and_the_feinted_charged_fired() -> void:
	var played := _solo()
	played.press(0, F, [CHARGED])
	played.press(0, F + 4, [PlayedMatch.GUARD_PRESS])
	played.press(0, F + 5, [CHARGED])
	played.run(80)
	# The scenario: the guard button cut the windup into the feint, which held the click.
	assert_int(played.state(0, F + 5).action).is_equal(FighterState.Action.FEINT)
	assert_int(played.first_tick(0, F + 5, _in_windup)).is_equal(-1)
	var report := played.summarize().fighter(0)
	assert_int(_press_of(report, CHARGED, F).fired_tick).is_equal(F)
	_assert_lost(report, CHARGED, F + 5, ReplaySummary.STANCE)
	assert_int(report.swings.size()).is_equal(1)


func test_a_click_in_the_air_far_from_the_landing_is_lost_off_the_floor() -> void:
	var played := _solo()
	played.press(0, F, [JUMP])
	played.press(0, F + 6, [LIGHT])
	played.press(0, F + 8, [CHARGED])
	played.run(80)
	# The scenario: still in the air when the last window closed.
	assert_int(played.state(0, F + 8 + BUFFER_TICKS + 1).mode).is_equal(FighterState.Mode.AIR)
	var report := played.summarize().fighter(0)
	_assert_lost(report, LIGHT, F + 6, ReplaySummary.OFF_FLOOR)
	_assert_lost(report, CHARGED, F + 8, ReplaySummary.OFF_FLOOR)
	assert_int(_press_of(report, LIGHT, F + 6).mode).is_equal(FighterState.Mode.AIR)
	assert_int(report.swings.size()).is_equal(0)


func test_a_click_off_the_floor_inside_a_swing_says_the_swing_first() -> void:
	var played := _solo()
	played.press(0, F, [LIGHT])
	played.run_through(F + 2)
	# The floor ends under the swing: the rules of the air, and the swing goes on.
	played.set_floor(0, false)
	played.press(0, F + 8, [LIGHT])
	played.run(F + LIGHT_OVER + 10)
	assert_int(played.state(0, F + 7).mode).is_equal(FighterState.Mode.AIR)
	assert_int(played.state(0, F + 8).action).is_equal(FighterState.Action.WINDUP)
	var report := played.summarize().fighter(0)
	_assert_lost_in_swing(report, LIGHT, F + 8, FighterState.Action.WINDUP, 8)


func test_a_light_click_with_the_bar_below_its_cost_is_lost_without_stamina() -> void:
	var played := _solo()
	# Twelve lights at 8 leave 4 of the 100, and chained they never let the bar regain.
	var over := _chain_lights(played, 12)
	played.press(0, over, [LIGHT])
	played.run(over + 30)
	# The scenario, by the core's own bar: below the cost on the click and when the window closed.
	var movement := played.tape.movement
	assert_float(Stamina.at(played.state(0, over - 1), movement, over)).is_less(LIGHT_COST)
	var closes := over + BUFFER_TICKS
	assert_float(Stamina.at(played.state(0, closes), movement, closes)).is_less(LIGHT_COST)
	var report := played.summarize().fighter(0)
	assert_int(report.swings.size()).is_equal(12)
	_assert_lost(report, LIGHT, over, ReplaySummary.NO_STAMINA)


func test_a_charged_click_with_the_bar_below_its_cost_is_lost_without_stamina() -> void:
	var played := _solo()
	# Ten lights leave 20: enough for another light, short of the charged's 25.
	var over := _chain_lights(played, 10)
	played.press(0, over, [CHARGED])
	played.run(over + 30)
	var movement := played.tape.movement
	var bar := Stamina.at(played.state(0, over - 1), movement, over)
	assert_float(bar).is_less(CHARGED_COST)
	assert_float(bar).is_greater_equal(LIGHT_COST)
	var report := played.summarize().fighter(0)
	assert_int(report.swings.size()).is_equal(10)
	_assert_lost(report, CHARGED, over, ReplaySummary.NO_STAMINA)


func test_a_click_in_the_air_with_the_bar_short_says_off_the_floor_first() -> void:
	var played := _solo()
	var over := _chain_lights(played, 12)
	played.press(0, over, [JUMP])
	played.press(0, over + 5, [LIGHT])
	played.run(over + 40)
	assert_int(played.state(0, over + 4).mode).is_equal(FighterState.Mode.AIR)
	var report := played.summarize().fighter(0)
	_assert_lost(report, LIGHT, over + 5, ReplaySummary.OFF_FLOOR)


func test_the_cost_that_refuses_a_click_is_the_one_the_summary_was_made_with() -> void:
	# A replay recorded with another number in its header: a light that costs 60. With the 8 of
	# today's combat_v0.tres the second click would have had the bar to fire.
	var data := Tape.combat_data_v0()
	data.light_attack.stamina_cost = 60.0
	var played := PlayedMatch.new(Tape.movement_v0(), CombatConfig.create(data, 60))
	played.add_fighter()
	played.press(0, F, [LIGHT])
	var click := F + LIGHT_OVER + 3
	played.press(0, click, [LIGHT])
	played.run(click + 30)
	# The scenario: the second click never fired.
	assert_int(played.first_tick(0, click, _in_windup)).is_equal(-1)
	var report := played.summarize().fighter(0)
	assert_int(report.swings.size()).is_equal(1)
	_assert_lost(report, LIGHT, click, ReplaySummary.NO_STAMINA)

# --- The end of the replay ---


func test_a_click_still_waiting_when_the_replay_ends_never_fired() -> void:
	var played := _solo()
	played.press(0, F, [LIGHT])
	played.press(0, F + 10, [LIGHT])
	# The replay ends two ticks later, inside the click's window.
	played.run_through(F + 12)
	var report := played.summarize().fighter(0)
	_assert_lost_in_swing(report, LIGHT, F + 10, FighterState.Action.WINDUP, 10)
