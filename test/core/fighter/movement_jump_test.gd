# Criteria 2 and 4 of TASK-9: the jump, the coyote and the buffer, through the public interface
# of core/fighter, with the engine's slice of the tick played by MovementRig on a flat floor
# (visao-geral.md, "O tick por dentro: o sanduíche"). Every number comes from
# docs/design/movimento.md, cited by section; ticks by hand from the ms, nearest tick with ties
# up (visao-geral.md, "O tempo e a física no estado"). TASK-10.1 brought the double jump and the
# single slot of the buffer (DEC-0039): the tests whose expectation changed say so in their
# comment; the buffered ground jump now needs the double jump spent first.
extends GdUnitTestSuite

const MovementRig := preload("res://test/core/fighter/movement_rig.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)

const JUMP_HEIGHT_M := 1.2 # movimento.md, "Pulo e ar"
const DOUBLE_JUMP_HEIGHT_M := 1.0 # movimento.md, "Pulo e ar": "Altura do pulo duplo"
const JUMP_RISE_MS := 350 # movimento.md, "Pulo e ar": time until the apex
const JUMP_FALL_MS := 280 # movimento.md, "Pulo e ar": time from the apex to the floor
const HEIGHT_TOLERANCE_M := 0.01 # 1 cm (visao-geral.md, "O tempo e a física no estado")

# The windows by hand: 100 ms of coyote is 3 ticks at 30 and 6 at 60; 150 ms of buffer is
# 4.5 -> 5 at 30 (tie up) and 9 at 60 (movimento.md, "Perdão"; visao-geral.md, the table of "O
# tempo e a física no estado"). Both are inclusive: the press counts while
# tick - stamp <= window (TASK-9 plan).
const COYOTE_TICKS: Dictionary[int, int] = { 30: 3, 60: 6 }
const BUFFER_TICKS: Dictionary[int, int] = { 30: 5, 60: 9 }

const HALF_TICK := 0.5
const HAIR := 1e-6 # floating-point slack, not a design number


# One jump recorded tick by tick. Steps count from the press tick as step 1, because the body
# already moves during it: the plan's velocity is applied in the same tick (TASK-9 plan). So the
# rise lasts apex_step steps and the fall landing_step - apex_step steps.
class Flight:
	var press_tick := 0
	var heights: Array[float] = [] # position.y after each step
	var apex_height := 0.0
	var apex_step := 0 # the first step at the apex
	var landing_step := 0 # the first step back on the floor; 0 if it never landed


	func rise_steps() -> int:
		return apex_step


	func fall_steps() -> int:
		return landing_step - apex_step


func _rig(tickrate: int) -> MovementRig:
	return MovementRig.new(MovementRig.load_config(tickrate), FIRST_TICK)


# A design time in ticks of the given rate, unrounded: what the half-tick tolerance is measured
# against (350 ms is 10.5 ticks at 30).
func _design_ticks(ms: int, tickrate: int) -> float:
	return ms * tickrate / 1000.0


# Presses jump now, holds it for hold_ticks ticks, and records until the fighter lands or five
# seconds pass.
func _fly(rig: MovementRig, hold_ticks := 1) -> Flight:
	var flight := Flight.new()
	flight.press_tick = rig.tick
	for step: int in range(1, 5 * rig.config.tickrate + 1):
		var input := MovementRig.press_jump() if step <= hold_ticks else MovementRig.idle()
		rig.step(input)
		flight.heights.append(rig.position.y)
		if step > 1 and rig.state.on_floor:
			flight.landing_step = step
			break
	for height: float in flight.heights:
		flight.apex_height = maxf(flight.apex_height, height)
	for index: int in flight.heights.size():
		if flight.heights[index] >= flight.apex_height - HAIR:
			flight.apex_step = index + 1
			break
	return flight


# Spends the double jump of the flight on the tick after the jump (TASK-10.1): only then does a
# press in the air wait in the slot for the landing.
func _spend_double_jump(rig: MovementRig) -> void:
	var plan := rig.step(MovementRig.press_jump())
	assert_int(plan.state.jumps_used).override_failure_message("not spent").is_equal(2)


# The landing tick of a jump pressed at FIRST_TICK with its double jump spent on the next tick,
# to place presses relative to it.
func _landing_tick(tickrate: int) -> int:
	var rig := _rig(tickrate)
	rig.step(MovementRig.press_jump())
	_spend_double_jump(rig)
	for _step: int in range(1, 5 * tickrate + 1):
		rig.step(MovementRig.idle())
		if rig.state.on_floor:
			return rig.tick - 1
	fail("the jump with its double jump spent never landed at %d ticks" % tickrate)
	return 0


# Jumps at FIRST_TICK, spends the double jump on the next tick, presses jump again at
# press_tick during the flight, lands at landing_tick and returns the plan of the next tick:
# the first one that starts on the floor, where a buffered press fires (TASK-9 plan).
func _fly_and_press_at(rig: MovementRig, press_tick: int, landing_tick: int) -> MovePlan:
	rig.step(MovementRig.press_jump())
	_spend_double_jump(rig)
	while rig.tick <= landing_tick:
		var input := MovementRig.press_jump() if rig.tick == press_tick else MovementRig.idle()
		rig.step(input)
	var late := "expected to be on the floor right after tick %d" % landing_tick
	assert_bool(rig.state.on_floor).override_failure_message(late).is_true()
	return rig.step(MovementRig.idle())


# Walks the resting fighter off a ledge: the floor goes away and that tick's after_move says the
# body left it. Returns the tick that left the floor.
func _leave_ledge(rig: MovementRig) -> int:
	rig.rest(3)
	var ledge_tick := rig.tick
	rig.floor_on = false
	rig.step(MovementRig.idle())
	return ledge_tick


# Idles and presses jump ticks_after ticks after the ledge tick; returns that tick's plan.
func _press_after_ledge(rig: MovementRig, ticks_after: int) -> MovePlan:
	rig.rest(ticks_after - 1)
	return rig.step(MovementRig.press_jump())


func _assert_jumped(plan: MovePlan) -> void:
	assert_float(plan.velocity.y).override_failure_message("no upward velocity").is_greater(0.0)
	assert_int(plan.state.jumps_used).override_failure_message("jump not counted").is_equal(1)
	var consumed := "the press must be consumed by the jump (the slot back to NONE / NEVER)"
	assert_str(String(plan.state.buffered_command)).override_failure_message(consumed).is_equal(
		String(FighterCommand.NONE)
	)
	assert_int(plan.state.buffered_tick).override_failure_message(consumed).is_equal(
		FighterState.NEVER
	)


# The double jump as TASK-10.1 states it: the exit speed derived for the tick, the second jump
# of the flight and its stamp.
func _assert_double_jumped(rig: MovementRig, plan: MovePlan, press_tick: int) -> void:
	assert_float(plan.velocity.y).override_failure_message("not the double jump speed") \
			.is_equal_approx(rig.config.double_jump_speed, HAIR)
	assert_int(plan.state.jumps_used).override_failure_message("not the second jump").is_equal(2)
	assert_int(plan.state.double_jump_tick).is_equal(press_tick)


func _assert_no_jump(plan: MovePlan, velocity_y_before: float, jumps_used_before: int) -> void:
	var rose := "velocity.y went from %.4f to %.4f: it jumped" % [
		velocity_y_before,
		plan.velocity.y,
	]
	assert_float(plan.velocity.y).override_failure_message(rose).is_less_equal(
		velocity_y_before + HAIR
	)
	assert_int(plan.state.jumps_used).is_equal(jumps_used_before)


func _assert_same_state(actual: FighterState, expected: FighterState) -> void:
	assert_int(actual.mode).is_equal(expected.mode)
	assert_int(actual.mode_since).is_equal(expected.mode_since)
	assert_bool(actual.on_floor).is_equal(expected.on_floor)
	assert_int(actual.left_floor_tick).is_equal(expected.left_floor_tick)
	assert_str(String(actual.buffered_command)).is_equal(String(expected.buffered_command))
	assert_int(actual.buffered_tick).is_equal(expected.buffered_tick)
	assert_int(actual.jumps_used).is_equal(expected.jumps_used)
	assert_float(actual.facing_yaw).is_equal(expected.facing_yaw)
	assert_float(actual.stamina_at_spend).is_equal(expected.stamina_at_spend)
	assert_int(actual.stamina_spent_tick).is_equal(expected.stamina_spent_tick)
	assert_int(actual.double_jump_tick).is_equal(expected.double_jump_tick)


# Criterion 2: the jump at 30 and at 60 ticks, derived for the size of the tick. With the
# continuous formula the apex would be 1.09 m at 30 and 1.14 m at 60 (visao-geral.md).
func test_a_jump_from_the_floor_rises_1_2_m_within_1_cm(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var flight := _fly(_rig(tickrate))
	var message := (
		"apex at %.4f m, the design says %.2f m within %.2f m (at %d ticks)"
		% [flight.apex_height, JUMP_HEIGHT_M, HEIGHT_TOLERANCE_M, tickrate]
	)
	assert_float(flight.apex_height).override_failure_message(message).is_equal_approx(
		JUMP_HEIGHT_M,
		HEIGHT_TOLERANCE_M,
	)


func test_the_apex_comes_350_ms_after_the_press_within_half_a_tick(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var flight := _fly(_rig(tickrate))
	var expected := _design_ticks(JUMP_RISE_MS, tickrate)
	var message := (
		"apex first reached at step %d, the design says %.1f ticks (350 ms at %d ticks)"
		% [flight.rise_steps(), expected, tickrate]
	)
	assert_float(absf(flight.rise_steps() - expected)) \
			.override_failure_message(message) \
			.is_less_equal(HALF_TICK)


func test_the_fighter_lands_280_ms_after_the_apex_within_half_a_tick(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var flight := _fly(_rig(tickrate))
	assert_int(flight.landing_step).override_failure_message("never landed").is_greater(0)
	var expected := _design_ticks(JUMP_FALL_MS, tickrate)
	var message := (
		"landed %d steps after the apex, the design says %.1f ticks (280 ms at %d ticks)"
		% [flight.fall_steps(), expected, tickrate]
	)
	assert_float(absf(flight.fall_steps() - expected)) \
			.override_failure_message(message) \
			.is_less_equal(HALF_TICK)


# No variable jump (movimento.md, "Pulo e ar": "Soltar o botão cedo não encurta o pulo"). The
# press is a one-tick touch, so one tick gives the whole 1.2 m, and ten ticks of the button held
# give the very same flight and no second jump after it.
func test_a_press_of_one_tick_gives_the_full_jump_and_holding_adds_nothing(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var tap := _fly(_rig(tickrate))
	var held_rig := _rig(tickrate)
	var held := _fly(held_rig, 10)
	assert_float(tap.apex_height).is_equal_approx(JUMP_HEIGHT_M, HEIGHT_TOLERANCE_M)
	assert_float(held.apex_height).is_equal_approx(tap.apex_height, HAIR)
	assert_int(held.apex_step).is_equal(tap.apex_step)
	assert_int(held.landing_step).is_equal(tap.landing_step)
	held_rig.rest(2 * BUFFER_TICKS[tickrate])
	assert_bool(held_rig.state.on_floor).override_failure_message("jumped again").is_true()
	assert_int(held_rig.state.jumps_used).is_equal(0)


func test_a_press_on_the_floor_jumps_on_the_same_tick(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var plan := rig.step(MovementRig.press_jump())
	_assert_jumped(plan)
	assert_float(rig.position.y).is_greater(0.0)
	assert_bool(rig.state.on_floor).is_false()


# GROUND -> AIR when it jumps, AIR -> GROUND when it lands, each with the tick it began
# (visao-geral.md, "A máquina de estados"); left_floor_tick is the tick whose after_move first
# saw the body off the floor (TASK-9 plan).
func test_the_jump_takes_the_fighter_to_the_air_and_the_landing_brings_it_back(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var press_tick := rig.tick
	rig.step(MovementRig.press_jump())
	assert_int(rig.state.mode).is_equal(FighterState.Mode.AIR)
	assert_int(rig.state.mode_since).is_equal(press_tick)
	assert_int(rig.state.left_floor_tick).is_equal(press_tick)
	assert_bool(rig.state.on_floor).is_false()
	var landing_tick := 0
	for _step: int in range(2, 5 * tickrate + 1):
		rig.step(MovementRig.idle())
		if rig.state.on_floor:
			landing_tick = rig.tick - 1
			break
	assert_int(landing_tick).override_failure_message("never landed").is_greater(0)
	assert_int(rig.state.mode).is_equal(FighterState.Mode.GROUND)
	assert_int(rig.state.mode_since).is_equal(landing_tick)
	assert_float(rig.position.y).is_equal(0.0)


func test_landing_renews_the_jump(tickrate: int, _test_parameters := [[30], [60]]) -> void:
	var rig := _rig(tickrate)
	rig.step(MovementRig.press_jump())
	assert_int(rig.state.jumps_used).is_equal(1)
	var flight_rig_landed := false
	for _step: int in range(2, 5 * tickrate + 1):
		rig.step(MovementRig.idle())
		if rig.state.on_floor:
			flight_rig_landed = true
			break
	assert_bool(flight_rig_landed).override_failure_message("never landed").is_true()
	assert_int(rig.state.jumps_used).is_equal(0)


func test_a_fighter_at_rest_without_a_press_never_jumps(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var violations: Array[String] = []
	for step: int in range(1, 2 * tickrate + 1):
		rig.step(MovementRig.idle())
		if rig.position.y != 0.0 or not rig.state.on_floor:
			violations.append("step %d: left the floor to y = %.4f" % [step, rig.position.y])
		if rig.state.jumps_used != 0 or rig.state.mode != FighterState.Mode.GROUND:
			violations.append("step %d: jumped" % step)
	assert_array(violations).is_empty()


# A fresh FighterState, as the Fighter node would spawn it, must rest too: no stamp in it may
# read as a press or a ledge (NEVER is the "never" stamp, TASK-9 plan).
func test_a_fresh_fighter_state_rests_on_the_floor_without_jumping() -> void:
	var rig := _rig(60)
	rig.state = FighterState.new()
	rig.tick = 0
	var violations: Array[String] = []
	for step: int in range(1, 61):
		rig.step(MovementRig.idle())
		if rig.position.y != 0.0 or rig.state.jumps_used != 0:
			violations.append(
				"step %d: y = %.4f, jumps_used = %d" % [step, rig.position.y, rig.state.jumps_used]
			)
	assert_array(violations).is_empty()
	assert_bool(rig.state.on_floor).is_true()
	assert_int(rig.state.mode).is_equal(FighterState.Mode.GROUND)


func test_a_fighter_jumps_again_after_landing(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var first := _fly(rig)
	rig.rest(1)
	var second := _fly(rig)
	assert_float(second.apex_height).is_equal_approx(JUMP_HEIGHT_M, HEIGHT_TOLERANCE_M)
	assert_int(second.apex_step).is_equal(first.apex_step)
	assert_int(second.landing_step).is_equal(first.landing_step)


# Criterion 4, the coyote (movimento.md, "Perdão": "Ainda pula logo depois de sair da
# beirada"): the press counts while tick - left_floor_tick <= coyote_ticks and no jump was used.
func test_leaving_a_ledge_stamps_the_tick_and_puts_the_fighter_in_the_air(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var ledge_tick := _leave_ledge(rig)
	assert_int(rig.state.left_floor_tick).is_equal(ledge_tick)
	assert_int(rig.state.mode).is_equal(FighterState.Mode.AIR)
	assert_int(rig.state.mode_since).is_equal(ledge_tick)
	assert_bool(rig.state.on_floor).is_false()
	assert_int(rig.state.jumps_used).is_equal(0)


func test_a_press_right_after_the_ledge_still_jumps(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	_leave_ledge(rig)
	_assert_jumped(_press_after_ledge(rig, 1))


func test_the_last_tick_of_the_coyote_window_still_jumps(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	_leave_ledge(rig)
	_assert_jumped(_press_after_ledge(rig, COYOTE_TICKS[tickrate]))


# Changed by TASK-10.1 (criterion 3): one tick past the coyote the press no longer does nothing,
# it is the double jump, 1.0 m above the press instead of the full 1.2 m (movimento.md, "Pulo e
# ar": "Aperto depois do coyote, sem ter pulado: é o pulo duplo").
func test_one_tick_past_the_coyote_window_the_press_is_the_double_jump_not_the_full_one(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	_leave_ledge(rig)
	rig.rest(COYOTE_TICKS[tickrate])
	var press_tick := rig.tick
	var height_at_press := rig.position.y
	var plan := rig.step(MovementRig.press_jump())
	_assert_double_jumped(rig, plan, press_tick)
	var apex := rig.position.y
	for _step: int in range(2, 2 * tickrate + 1):
		rig.step(MovementRig.idle())
		apex = maxf(apex, rig.position.y)
	assert_float(apex - height_at_press).is_equal_approx(DOUBLE_JUMP_HEIGHT_M, HEIGHT_TOLERANCE_M)


func test_a_coyote_jump_is_a_full_jump(tickrate: int, _test_parameters := [[30], [60]]) -> void:
	var rig := _rig(tickrate)
	_leave_ledge(rig)
	rig.rest(COYOTE_TICKS[tickrate] - 1)
	var height_at_press := rig.position.y
	rig.step(MovementRig.press_jump())
	var apex := rig.position.y
	for _step: int in range(2, 2 * tickrate + 1):
		rig.step(MovementRig.idle())
		apex = maxf(apex, rig.position.y)
	assert_float(apex - height_at_press).is_equal_approx(JUMP_HEIGHT_M, HEIGHT_TOLERANCE_M)


# Changed by TASK-10.1 (criterion 1): after jumping, the fighter is one tick off the floor,
# inside the coyote window, but the jump is used, so the press is not a second full jump: it is
# the double jump, 1.0 m above the press (TASK-10.1 plan: the coyote only with jumps_used == 0).
func test_a_press_right_after_the_jump_is_the_double_jump_not_a_second_full_jump(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	rig.step(MovementRig.press_jump())
	var press_tick := rig.tick
	var height_at_press := rig.position.y
	var plan := rig.step(MovementRig.press_jump())
	_assert_double_jumped(rig, plan, press_tick)
	var apex := rig.position.y
	for _step: int in range(3, 5 * tickrate + 1):
		rig.step(MovementRig.idle())
		apex = maxf(apex, rig.position.y)
		if rig.state.on_floor:
			break
	assert_float(apex - height_at_press).is_equal_approx(DOUBLE_JUMP_HEIGHT_M, HEIGHT_TOLERANCE_M)


# Criterion 4, the buffer (movimento.md, "Perdão": the press is kept for up to 150 ms before
# landing): it fires on the first tick that starts on the floor while
# tick - buffered_tick <= buffer_ticks (DEC-0039). Changed by TASK-10.1 (criterion 2): the
# press only waits for the landing once the double jump of the flight is spent; with it
# available the press would fire at once as the double jump.
func test_with_the_double_jump_spent_a_press_within_the_buffer_jumps_on_the_first_tick_on_the_floor(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var landing_tick := _landing_tick(tickrate)
	var rig := _rig(tickrate)
	var press_tick := landing_tick + 1 - BUFFER_TICKS[tickrate]
	_assert_jumped(_fly_and_press_at(rig, press_tick, landing_tick))
	assert_bool(rig.state.on_floor).is_false()


# Changed by TASK-10.1 (criterion 2): the double jump is spent first, as above.
func test_with_the_double_jump_spent_a_press_on_the_landing_tick_jumps_on_the_next_tick(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var landing_tick := _landing_tick(tickrate)
	var rig := _rig(tickrate)
	_assert_jumped(_fly_and_press_at(rig, landing_tick, landing_tick))


# Changed by TASK-10.1 (criterion 2): the double jump is spent first, as above.
func test_with_the_double_jump_spent_one_tick_before_the_buffer_window_does_not_jump_on_landing(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var landing_tick := _landing_tick(tickrate)
	var rig := _rig(tickrate)
	var press_tick := landing_tick - BUFFER_TICKS[tickrate]
	var plan := _fly_and_press_at(rig, press_tick, landing_tick)
	_assert_no_jump(plan, 0.0, 0)
	rig.rest(2 * BUFFER_TICKS[tickrate])
	assert_bool(rig.state.on_floor).override_failure_message("jumped late").is_true()
	assert_float(rig.position.y).is_equal(0.0)
	assert_int(rig.state.jumps_used).is_equal(0)


# Changed by TASK-10.1 (criterion 1): a press in the air right after the jump, outside the
# buffer, no longer does nothing: it is the double jump, fired at once, and it leaves nothing in
# the slot for the landing.
func test_a_press_in_the_air_outside_the_buffer_is_the_double_jump_and_leaves_nothing_to_land_on(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	rig.step(MovementRig.press_jump())
	rig.step(MovementRig.idle())
	var press_tick := rig.tick # FIRST_TICK + 2, outside the buffer of any landing
	_assert_double_jumped(rig, rig.step(MovementRig.press_jump()), press_tick)
	var landed := false
	for _step: int in range(1, 5 * tickrate + 1):
		rig.step(MovementRig.idle())
		if rig.state.on_floor:
			landed = true
			break
	assert_bool(landed).override_failure_message("never landed").is_true()
	rig.rest(2 * BUFFER_TICKS[tickrate])
	assert_bool(rig.state.on_floor).override_failure_message("jumped late").is_true()
	assert_float(rig.position.y).is_equal(0.0)
	assert_int(rig.state.jumps_used).is_equal(0)


# The two slices are pure: neither changes the state it receives (TASK-9 plan), which is what
# lets the netfox rollback re-run a tick from a restored state (visao-geral.md).
func test_before_move_leaves_the_state_it_receives_untouched() -> void:
	var rig := _rig(60)
	var given := rig.state
	var snapshot := given.copy()
	var plan := Movement.before_move(
		given,
		Vector3.ZERO,
		Vector3.ZERO,
		MovementRig.press_jump(),
		rig.config,
		FIRST_TICK,
	)
	assert_int(plan.state.jumps_used).is_equal(1)
	_assert_same_state(given, snapshot)


func test_after_move_leaves_the_state_it_receives_untouched() -> void:
	var rig := _rig(60)
	rig.step(MovementRig.press_jump())
	var given := rig.state # in the air, one jump used
	var snapshot := given.copy()
	var facts := MoveFacts.new()
	facts.on_floor = true
	facts.velocity = Vector3.ZERO
	var landed := Movement.after_move(given, facts, rig.config, rig.tick)
	assert_int(landed.mode).is_equal(FighterState.Mode.GROUND)
	assert_int(landed.jumps_used).is_equal(0)
	_assert_same_state(given, snapshot)


# Every field of the state, the five of TASK-10.1 included, travels with copy(): a field left
# out would come back as its default after a rollback (visao-geral.md).
func test_fighter_state_copy_is_equal_and_independent() -> void:
	var original := _rig(60).state
	original.buffered_command = FighterCommand.JUMP
	original.buffered_tick = 1234
	original.stamina_at_spend = 42.5
	original.stamina_spent_tick = 1200
	original.double_jump_tick = 1230
	var copy := original.copy()
	_assert_same_state(copy, original)
	copy.mode = FighterState.Mode.AIR
	copy.jumps_used = 1
	copy.facing_yaw = 2.0
	copy.buffered_command = FighterCommand.NONE
	copy.double_jump_tick = FighterState.NEVER
	assert_int(original.mode).is_equal(FighterState.Mode.GROUND)
	assert_int(original.jumps_used).is_equal(0)
	assert_float(original.facing_yaw).is_equal(0.0)
	assert_str(String(original.buffered_command)).is_equal(String(FighterCommand.JUMP))
	assert_int(original.double_jump_tick).is_equal(1230)
