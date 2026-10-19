# Criterion 5 of TASK-10.1: the stamina as the value right after the last spend plus the stamp
# of that spend, computed from the tick and never counted (movimento.md, "Stamina"; DEC-0022),
# through the public interface of core/fighter (Stamina.at, Stamina.spend and the flight played
# by MovementRig). Every number comes from docs/design/movimento.md, cited by section; ticks by
# hand from the ms, nearest tick with ties up (visao-geral.md, "O tempo e a física no estado").
extends GdUnitTestSuite

const MovementRig := preload("res://test/core/fighter/movement_rig.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)

const STAMINA_MAX := 100.0 # movimento.md, "Stamina": "Máximo"
const DOUBLE_JUMP_COST := 10.0 # movimento.md, "Pulo e ar": "Custo do pulo duplo"
const STAMINA_WAIT_MS := 800 # movimento.md, "Stamina": "Espera para recuperar"
const STAMINA_REGEN_PER_S := 30.0 # movimento.md, "Stamina": "Recuperação"

# By hand: 800 ms of wait is 24 ticks at 30 and 48 at 60, exact multiples; 30 points per second
# is 1.0 per tick at 30 and 0.5 at 60; from empty, 100 points take 100 ticks at 30 and 200 at 60
# after the wait, the design's "≈ 3,3 s depois da espera" (movimento.md, "Stamina").
const WAIT_TICKS: Dictionary[int, int] = { 30: 24, 60: 48 }
const REGEN_PER_TICK: Dictionary[int, float] = { 30: 1.0, 60: 0.5 }
const REFILL_TICKS: Dictionary[int, int] = { 30: 100, 60: 200 }

const BELOW_COST := 9.5 # criterion 5: "com 9,5 de stamina o pulo duplo não sai"
const FAR_AWAY := 100000 # ticks, arithmetic: long after any wait and refill
const HAIR := 1e-9 # floating-point slack, not a design number


func _rig(tickrate: int) -> MovementRig:
	return MovementRig.new(MovementRig.load_config(tickrate), FIRST_TICK)


func _at(rig: MovementRig, tick: int) -> float:
	return Stamina.at(rig.state, rig.config, tick)


# Leaves the bar at value, stamped now: it reads value until the wait passes.
func _set_bar(rig: MovementRig, value: float) -> void:
	rig.state.stamina_at_spend = value
	rig.state.stamina_spent_tick = rig.tick


# Jumps from the floor at the rig's tick and presses again two ticks later; returns that tick.
func _double_jump(rig: MovementRig) -> int:
	rig.step(MovementRig.press_jump())
	rig.rest(1)
	var press_tick := rig.tick
	var plan := rig.step(MovementRig.press_jump())
	assert_int(plan.state.jumps_used).override_failure_message("no double jump").is_equal(2)
	return press_tick


func _idle_until_landed(rig: MovementRig) -> void:
	for _step: int in range(1, 5 * rig.config.tickrate + 1):
		rig.step(MovementRig.idle())
		if rig.state.on_floor:
			return
	fail("never landed at %d ticks" % rig.config.tickrate)


func _assert_bar(rig: MovementRig, tick: int, expected: float, why: String) -> void:
	var message := "%s: the bar at tick %d reads %.4f, expected %.4f" % [
		why,
		tick,
		_at(rig, tick),
		expected,
	]
	assert_float(_at(rig, tick)).override_failure_message(message).is_equal_approx(expected, HAIR)


# The hand numbers above against the config they must match (movement_v0.tres at load).
func test_the_config_carries_the_stamina_numbers_of_the_design(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var config := MovementRig.load_config(tickrate)
	assert_float(config.stamina_max).is_equal_approx(STAMINA_MAX, HAIR)
	assert_float(config.double_jump_cost).is_equal_approx(DOUBLE_JUMP_COST, HAIR)
	assert_int(config.stamina_wait_ticks).is_equal(WAIT_TICKS[tickrate])
	assert_int(config.stamina_wait_ticks).is_equal(Ticks.from_ms(STAMINA_WAIT_MS, tickrate))
	assert_float(config.stamina_regen_per_tick).is_equal_approx(REGEN_PER_TICK[tickrate], HAIR)
	assert_float(config.stamina_regen_per_tick).is_equal_approx(
		STAMINA_REGEN_PER_S / tickrate,
		HAIR,
	)


# None: never spent, the bar is full at any tick, and running and jumping do not spend
# (movimento.md, "Stamina": "Correr, pular, a parede e o gancho não gastam").
func test_the_bar_is_full_while_never_spent(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	_assert_bar(rig, FIRST_TICK, rig.config.stamina_max, "fresh")
	_assert_bar(rig, FIRST_TICK + FAR_AWAY, rig.config.stamina_max, "fresh, far away")
	for _step: int in tickrate:
		rig.step(MovementRig.run(Vector2(0, 1)))
	rig.step(MovementRig.press_jump_toward(Vector2(0, 1)))
	_idle_until_landed(rig)
	assert_int(rig.state.stamina_spent_tick).is_equal(FighterState.NEVER)
	assert_float(rig.stamina()).is_equal_approx(rig.config.stamina_max, HAIR)


# One: the double jump costs 10, stamped on its tick (movimento.md, "Pulo e ar": "Custo do pulo
# duplo"; "Stamina": "Como se guarda").
func test_the_double_jump_costs_10_stamina(tickrate: int, _test_parameters := [[30], [60]]) -> void:
	var rig := _rig(tickrate)
	var press_tick := _double_jump(rig)
	var after_cost := rig.config.stamina_max - rig.config.double_jump_cost
	assert_int(rig.state.stamina_spent_tick).is_equal(press_tick)
	assert_float(rig.state.stamina_at_spend).is_equal_approx(after_cost, HAIR)
	_assert_bar(rig, press_tick, after_cost, "right after the double jump")


# The 800 ms after the spend regain nothing: 24 ticks at 30, 48 at 60, every one of them; the
# tick after the wait is the first to regain (movimento.md, "Stamina": "Espera para recuperar").
func test_nothing_is_regained_during_the_800_ms_wait(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var press_tick := _double_jump(rig)
	var after_cost := rig.config.stamina_max - rig.config.double_jump_cost
	var violations: Array[String] = []
	for ticks_since: int in range(0, WAIT_TICKS[tickrate] + 1):
		var bar := _at(rig, press_tick + ticks_since)
		if absf(bar - after_cost) > HAIR:
			violations.append("%d ticks after the spend the bar reads %.4f" % [ticks_since, bar])
	assert_array(violations).is_empty()
	_assert_bar(
		rig,
		press_tick + WAIT_TICKS[tickrate] + 1,
		after_cost + REGEN_PER_TICK[tickrate],
		"the first tick after the wait",
	)


# After the wait, 30 points per second: 1.0 per tick at 30, 0.5 at 60, tick by tick, until the
# 10 spent are back (10 ticks at 30, 20 at 60); then the bar stays at 100 (movimento.md,
# "Stamina": "Recuperação", "Máximo").
func test_after_the_wait_the_bar_regains_30_per_second_up_to_100_without_passing(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var press_tick := _double_jump(rig)
	var after_cost := rig.config.stamina_max - rig.config.double_jump_cost
	var regen := REGEN_PER_TICK[tickrate]
	var ticks_to_full := int(roundf(rig.config.double_jump_cost / regen))
	var first_regain := press_tick + WAIT_TICKS[tickrate] + 1
	var violations: Array[String] = []
	for regained_ticks: int in range(1, ticks_to_full + 1):
		var tick := first_regain + regained_ticks - 1
		var expected := after_cost + regained_ticks * regen
		if absf(_at(rig, tick) - expected) > HAIR:
			violations.append("tick %d: %.4f, expected %.4f" % [tick, _at(rig, tick), expected])
	assert_array(violations).is_empty()
	_assert_bar(rig, first_regain + ticks_to_full - 1, rig.config.stamina_max, "full again")
	_assert_bar(rig, first_regain + ticks_to_full, rig.config.stamina_max, "one tick past full")
	_assert_bar(rig, first_regain + FAR_AWAY, rig.config.stamina_max, "far away")


# Limit: empty, the bar fills in 100 ticks at 30 and 200 at 60 after the wait, the last tick
# before it still one tick of regen short, and never passes 100 (criterion 5; movimento.md,
# "Stamina": "Vazia, enche em ≈ 3,3 s depois da espera").
func test_an_empty_bar_fills_in_200_ticks_at_60_and_100_at_30_after_the_wait(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	_set_bar(rig, rig.config.double_jump_cost)
	var press_tick := _double_jump(rig)
	_assert_bar(rig, press_tick, 0.0, "empty after paying exactly the cost")
	var full_tick := press_tick + WAIT_TICKS[tickrate] + REFILL_TICKS[tickrate]
	_assert_bar(rig, press_tick + WAIT_TICKS[tickrate], 0.0, "still empty at the end of the wait")
	_assert_bar(
		rig,
		full_tick - 1,
		rig.config.stamina_max - REGEN_PER_TICK[tickrate],
		"one tick before full",
	)
	_assert_bar(rig, full_tick, rig.config.stamina_max, "full")
	_assert_bar(rig, full_tick + 1, rig.config.stamina_max, "one tick past full")


# Failure: with 9.5 the double jump does not fire, nothing is paid and the press waits in the
# slot (movimento.md, "Stamina": "Sem stamina suficiente").
func test_with_9_5_stamina_the_double_jump_is_refused_and_nothing_is_paid(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	_set_bar(rig, BELOW_COST)
	var stamp := rig.state.stamina_spent_tick
	rig.step(MovementRig.press_jump())
	rig.rest(1)
	var press_tick := rig.tick
	var velocity_y_before := rig.velocity.y
	var plan := rig.step(MovementRig.press_jump())
	assert_int(plan.state.jumps_used).override_failure_message("double jumped").is_equal(1)
	assert_float(plan.velocity.y).override_failure_message("an impulse").is_less_equal(
		velocity_y_before + HAIR
	)
	assert_int(plan.state.double_jump_tick).is_equal(FighterState.NEVER)
	assert_float(plan.state.stamina_at_spend).is_equal_approx(BELOW_COST, HAIR)
	assert_int(plan.state.stamina_spent_tick).is_equal(stamp)
	_assert_bar(rig, press_tick, BELOW_COST, "refused: nothing paid")
	assert_str(String(plan.state.buffered_command)).is_equal(String(FighterCommand.JUMP))
	assert_int(plan.state.buffered_tick).is_equal(press_tick)


# Limit: exactly 10 fires and leaves the bar at 0 (criterion 5: "com 10 exatos, sai").
func test_with_exactly_10_stamina_the_double_jump_fires_and_leaves_0(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	_set_bar(rig, rig.config.double_jump_cost)
	var press_tick := _double_jump(rig)
	assert_int(rig.state.stamina_spent_tick).is_equal(press_tick)
	assert_float(rig.state.stamina_at_spend).is_equal_approx(0.0, HAIR)
	_assert_bar(rig, press_tick, 0.0, "exactly the cost paid")


# Many: a second double jump, in the next flight, restarts the wait from its own tick and takes
# its cost from whatever the bar read then (movimento.md, "Stamina": "800 ms sem gastar").
func test_a_second_spend_restarts_the_wait(tickrate: int, _test_parameters := [[30], [60]]) -> void:
	var rig := _rig(tickrate)
	_double_jump(rig)
	_idle_until_landed(rig)
	rig.rest(1)
	rig.step(MovementRig.press_jump())
	rig.rest(1)
	var second_tick := rig.tick
	var bar_before := rig.stamina()
	var plan := rig.step(MovementRig.press_jump())
	assert_int(plan.state.jumps_used).is_equal(2)
	var after_second := bar_before - rig.config.double_jump_cost
	assert_int(rig.state.stamina_spent_tick).is_equal(second_tick)
	assert_float(rig.state.stamina_at_spend).is_equal_approx(after_second, HAIR)
	_assert_bar(rig, second_tick + WAIT_TICKS[tickrate], after_second, "the new wait, last tick")
	_assert_bar(
		rig,
		second_tick + WAIT_TICKS[tickrate] + 1,
		after_second + REGEN_PER_TICK[tickrate],
		"the first regain after the new wait",
	)


# The formula of the design on the pure functions themselves: at 60,
# min(100, value + 0.5 * max(0, tick - stamp - 48)); at 30, 1.0 per tick past 24 (movimento.md,
# "Stamina": "Como se guarda"). A spend during the regen takes its cost from the bar as read.
func test_stamina_at_follows_the_formula_of_the_design(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var config := MovementRig.load_config(tickrate)
	var state := FighterState.new()
	var wait := WAIT_TICKS[tickrate]
	var regen := REGEN_PER_TICK[tickrate]
	assert_float(Stamina.at(state, config, FIRST_TICK)).is_equal_approx(config.stamina_max, HAIR)
	Stamina.spend(state, config, FIRST_TICK, config.double_jump_cost)
	var value := config.stamina_max - config.double_jump_cost
	assert_float(Stamina.at(state, config, FIRST_TICK)).is_equal_approx(value, HAIR)
	assert_float(Stamina.at(state, config, FIRST_TICK + wait)).is_equal_approx(value, HAIR)
	assert_float(Stamina.at(state, config, FIRST_TICK + wait + 1)).is_equal_approx(
		value + regen,
		HAIR,
	)
	assert_float(Stamina.at(state, config, FIRST_TICK + wait + 4)).is_equal_approx(
		value + 4 * regen,
		HAIR,
	)
	assert_float(Stamina.at(state, config, FIRST_TICK + FAR_AWAY)).is_equal_approx(
		config.stamina_max,
		HAIR,
	)
	var second := FIRST_TICK + wait + 4
	Stamina.spend(state, config, second, config.double_jump_cost)
	assert_int(state.stamina_spent_tick).is_equal(second)
	assert_float(state.stamina_at_spend).is_equal_approx(
		value + 4 * regen - config.double_jump_cost,
		HAIR,
	)
	assert_float(Stamina.at(state, config, second + wait)).is_equal_approx(
		state.stamina_at_spend,
		HAIR,
	)
