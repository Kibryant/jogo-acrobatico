# Criteria 1, 2, 3, 4 and 6 of TASK-10.1, plus the "apex follows the Resource" half of
# criterion 7: the double jump, one per flight, paid in stamina, and the single slot of the
# buffer (DEC-0039), through the public interface of core/fighter, with the engine's slice of
# the tick played by MovementRig on a flat floor (visao-geral.md, "O tick por dentro: o
# sanduíche"). Every number comes from docs/design/movimento.md, cited by section; ticks by hand
# from the ms, nearest tick with ties up (visao-geral.md, "O tempo e a física no estado").
extends GdUnitTestSuite

const MovementRig := preload("res://test/core/fighter/movement_rig.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)

const DOUBLE_JUMP_HEIGHT_M := 1.0 # movimento.md, "Pulo e ar": "Altura do pulo duplo"
const DOUBLE_JUMP_RISE_MS := 320 # movimento.md, "Pulo e ar": "≈ 320 ms até o topo"
const DOUBLE_JUMP_APEX_STEP_AT_60 := 19 # movimento.md, "Pulo e ar", "No tick": "no 19º tick"
const HEIGHT_TOLERANCE_M := 0.01 # 1 cm (criterion 1; visao-geral.md, "O tempo e a física")
const DOUBLE_JUMP_COST := 10.0 # movimento.md, "Pulo e ar": "Custo do pulo duplo"
const STAMINA_MAX := 100.0 # movimento.md, "Stamina": "Máximo"
const BELOW_COST := 9.5 # TASK-10.1, criterion 5: a bar of 9.5 cannot pay the cost of 10

# The windows by hand (movimento.md, "Perdão"): 100 ms of coyote is 3 ticks at 30 and 6 at 60;
# 150 ms of buffer is 4.5 -> 5 at 30 (tie up) and 9 at 60. Both inclusive: the press counts
# while tick - stamp <= window (DEC-0039).
const COYOTE_TICKS: Dictionary[int, int] = { 30: 3, 60: 6 }
const BUFFER_TICKS: Dictionary[int, int] = { 30: 5, 60: 9 }
# The full jump's rise by hand: 350 ms is 10.5 -> 11 ticks at 30 (tie up) and 21 at 60
# (movimento.md, "Pulo e ar"): one tick later the body sits at the apex.
const RISE_TICKS: Dictionary[int, int] = { 30: 11, 60: 21 }

# Why the double jump is unavailable in the air: used in this flight, or the bar below the cost.
const SPENT := "spent"
const NO_STAMINA := "no stamina"

const HALF_TICK := 0.5
const HAIR := 1e-6 # floating-point slack, not a design number


# One flight recorded from a press. Steps count from the press tick as step 1, because the
# body already moves during it (TASK-9 plan).
class Flight:
	var press_tick := 0
	var press_height := 0.0 # position.y when the press tick began
	var plan: MovePlan # the press tick's plan
	var apex_height := 0.0
	var apex_step := 0 # the first step at the apex
	var landing_step := 0 # the first step back on the floor; 0 if it never landed


	func rise_above_press() -> float:
		return apex_height - press_height


func _rig(tickrate: int) -> MovementRig:
	return MovementRig.new(MovementRig.load_config(tickrate), FIRST_TICK)


func _design_ticks(ms: int, tickrate: int) -> float:
	return ms * tickrate / 1000.0


# The world direction of a move (TASK-9 plan): yaw 0 looks down -Z, move.x goes right and
# move.y goes forward.
func _world_direction(move: Vector2, yaw: float) -> Vector3:
	return Basis(Vector3.UP, yaw) * Vector3(move.x, 0.0, -move.y)


# Presses now and idles until the fighter lands or five seconds pass, recording the flight.
func _press_and_record(rig: MovementRig, input: TickInput) -> Flight:
	var flight := Flight.new()
	flight.press_tick = rig.tick
	flight.press_height = rig.position.y
	flight.plan = rig.step(input)
	flight.apex_height = rig.position.y
	flight.apex_step = 1
	for step: int in range(2, 5 * rig.config.tickrate + 1):
		rig.step(MovementRig.idle())
		if rig.position.y > flight.apex_height + HAIR:
			flight.apex_height = rig.position.y
			flight.apex_step = step
		if rig.state.on_floor:
			flight.landing_step = step
			break
	return flight


# Jumps from the floor now and idles ticks more: the next press comes ticks + 1 after the jump.
func _jump_then_idle(rig: MovementRig, ticks: int) -> void:
	rig.step(MovementRig.press_jump())
	rig.rest(ticks)


# Idles until the fighter lands; returns the landing tick, or fails.
func _idle_until_landed(rig: MovementRig) -> int:
	for _step: int in range(1, 5 * rig.config.tickrate + 1):
		rig.step(MovementRig.idle())
		if rig.state.on_floor:
			return rig.tick - 1
	fail("never landed at %d ticks" % rig.config.tickrate)
	return 0


# Starts a flight at FIRST_TICK with the double jump unavailable: SPENT presses it on the tick
# after the jump; NO_STAMINA leaves the bar at 9.5, stamped now, and jumps.
func _fly_unavailable(rig: MovementRig, reason: String) -> void:
	if reason == NO_STAMINA:
		rig.state.stamina_at_spend = BELOW_COST
		rig.state.stamina_spent_tick = rig.tick
	rig.step(MovementRig.press_jump())
	if reason == SPENT:
		var plan := rig.step(MovementRig.press_jump())
		assert_int(plan.state.jumps_used).override_failure_message("not spent").is_equal(2)


func _landing_tick_unavailable(tickrate: int, reason: String) -> int:
	var rig := _rig(tickrate)
	_fly_unavailable(rig, reason)
	return _idle_until_landed(rig)


# Flies with the double jump unavailable, presses at press_tick, lands at landing_tick and
# returns the plan of the next tick, the first that starts on the floor.
func _fly_unavailable_and_press_at(
	rig: MovementRig,
	reason: String,
	press_tick: int,
	landing_tick: int,
) -> MovePlan:
	_fly_unavailable(rig, reason)
	while rig.tick <= landing_tick:
		var input := MovementRig.press_jump() if rig.tick == press_tick else MovementRig.idle()
		rig.step(input)
	var late := "expected to be on the floor right after tick %d" % landing_tick
	assert_bool(rig.state.on_floor).override_failure_message(late).is_true()
	return rig.step(MovementRig.idle())


# Walks the resting fighter off a ledge; returns the tick that left the floor.
func _leave_ledge(rig: MovementRig) -> int:
	rig.rest(3)
	var ledge_tick := rig.tick
	rig.floor_on = false
	rig.step(MovementRig.idle())
	return ledge_tick


func _assert_slot(state: FighterState, command: StringName, buffered_tick: int) -> void:
	var slot := "slot holds (%s, %d), expected (%s, %d)" % [
		state.buffered_command,
		state.buffered_tick,
		command,
		buffered_tick,
	]
	assert_str(String(state.buffered_command)).override_failure_message(slot).is_equal(
		String(command)
	)
	assert_int(state.buffered_tick).override_failure_message(slot).is_equal(buffered_tick)


# The double jump as the plan says it (TASK-10.1 plan): the exit speed derived for the tick,
# the second jump of the flight, its stamp, and the slot consumed.
func _assert_double_jumped(rig: MovementRig, plan: MovePlan, press_tick: int) -> void:
	assert_float(plan.velocity.y).override_failure_message("not the double jump speed") \
			.is_equal_approx(rig.config.double_jump_speed, HAIR)
	assert_int(plan.state.jumps_used).override_failure_message("not the second jump").is_equal(2)
	assert_int(plan.state.double_jump_tick).is_equal(press_tick)
	_assert_slot(plan.state, FighterCommand.NONE, FighterState.NEVER)


func _assert_ground_jumped(plan: MovePlan) -> void:
	assert_float(plan.velocity.y).override_failure_message("no upward velocity").is_greater(0.0)
	assert_int(plan.state.jumps_used).override_failure_message("not the first jump").is_equal(1)
	_assert_slot(plan.state, FighterCommand.NONE, FighterState.NEVER)


func _assert_rise(flight: Flight, expected_m: float, tickrate: int) -> void:
	var message := (
		"rose %.4f m above the press, the design says %.2f m within %.2f m (at %d ticks)"
		% [flight.rise_above_press(), expected_m, HEIGHT_TOLERANCE_M, tickrate]
	)
	assert_float(flight.rise_above_press()).override_failure_message(message).is_equal_approx(
		expected_m,
		HEIGHT_TOLERANCE_M,
	)


# Criterion 1: pressed 1 tick after the jump (still rising), rise_ticks after it (the body at
# the apex: 11 at 30, 21 at 60) and while falling (16 at 30, 26 at 60), the double jump tops
# 1.0 m above the press, within 1 cm, at both rates.
func test_the_double_jump_tops_1_m_above_the_press_within_1_cm(
	tickrate: int,
	ticks_after_jump: int,
	_test_parameters := [[30, 1], [30, 11], [30, 16], [60, 1], [60, 21], [60, 26]],
) -> void:
	var rig := _rig(tickrate)
	_jump_then_idle(rig, ticks_after_jump - 1)
	var flight := _press_and_record(rig, MovementRig.press_jump())
	_assert_double_jumped(rig, flight.plan, flight.press_tick)
	_assert_rise(flight, DOUBLE_JUMP_HEIGHT_M, tickrate)


# From the apex of the full jump, where the body is at rest: the design's 320 ms within half a
# tick (9.6 ticks at 30, 19.2 at 60), and the 19th tick at 60 that "No tick" names.
func test_the_apex_of_the_double_jump_comes_320_ms_after_the_press_within_half_a_tick(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	_jump_then_idle(rig, RISE_TICKS[tickrate] - 1)
	var flight := _press_and_record(rig, MovementRig.press_jump())
	var expected := _design_ticks(DOUBLE_JUMP_RISE_MS, tickrate)
	var message := "apex first reached at step %d, the design says %.1f ticks (at %d ticks)" % [
		flight.apex_step,
		expected,
		tickrate,
	]
	assert_float(absf(flight.apex_step - expected)).override_failure_message(message) \
			.is_less_equal(HALF_TICK)
	if tickrate == 60:
		assert_int(flight.apex_step).is_equal(DOUBLE_JUMP_APEX_STEP_AT_60)


# One per flight (movimento.md, "Pulo e ar"): a second press after the double jump adds no
# impulse, keeps the stamp of the first and waits in the slot.
func test_a_second_press_in_the_same_flight_does_not_jump_again(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	_jump_then_idle(rig, 0)
	var double_jump_tick := rig.tick
	var double_jump_height := rig.position.y
	_assert_double_jumped(rig, rig.step(MovementRig.press_jump()), double_jump_tick)
	rig.rest(2)
	var press_tick := rig.tick
	var velocity_y_before := rig.velocity.y
	var plan := rig.step(MovementRig.press_jump())
	assert_int(plan.state.jumps_used).is_equal(2)
	assert_float(plan.velocity.y).override_failure_message("a third impulse").is_less(
		velocity_y_before
	)
	assert_int(plan.state.double_jump_tick).is_equal(double_jump_tick)
	_assert_slot(plan.state, FighterCommand.JUMP, press_tick)
	var apex := rig.position.y
	for _step: int in range(1, 5 * tickrate + 1):
		rig.step(MovementRig.idle())
		apex = maxf(apex, rig.position.y)
		if rig.state.on_floor:
			break
	assert_float(apex - double_jump_height).is_equal_approx(
		DOUBLE_JUMP_HEIGHT_M,
		HEIGHT_TOLERANCE_M,
	)


# Criterion 2: with the double jump spent or the bar short, the press waits in the slot and
# becomes the ground jump on the first tick on the floor, while tick - press <= buffer_ticks.
func test_with_the_double_jump_unavailable_a_press_at_the_buffer_limit_jumps_on_landing(
	tickrate: int,
	reason: String,
	_test_parameters := [[30, SPENT], [30, NO_STAMINA], [60, SPENT], [60, NO_STAMINA]],
) -> void:
	var landing_tick := _landing_tick_unavailable(tickrate, reason)
	var rig := _rig(tickrate)
	var press_tick := landing_tick + 1 - BUFFER_TICKS[tickrate]
	_assert_ground_jumped(_fly_unavailable_and_press_at(rig, reason, press_tick, landing_tick))
	assert_bool(rig.state.on_floor).is_false()


func test_with_the_double_jump_unavailable_one_tick_past_the_buffer_does_not_jump(
	tickrate: int,
	reason: String,
	_test_parameters := [[30, SPENT], [30, NO_STAMINA], [60, SPENT], [60, NO_STAMINA]],
) -> void:
	var landing_tick := _landing_tick_unavailable(tickrate, reason)
	var rig := _rig(tickrate)
	var press_tick := landing_tick - BUFFER_TICKS[tickrate]
	var plan := _fly_unavailable_and_press_at(rig, reason, press_tick, landing_tick)
	assert_float(plan.velocity.y).override_failure_message("jumped").is_less_equal(HAIR)
	assert_int(plan.state.jumps_used).is_equal(0)
	rig.rest(2 * BUFFER_TICKS[tickrate])
	assert_bool(rig.state.on_floor).override_failure_message("jumped late").is_true()
	assert_float(rig.position.y).is_equal(0.0)
	assert_int(rig.state.jumps_used).is_equal(0)


func test_with_the_double_jump_unavailable_a_press_on_the_landing_tick_jumps_next_tick(
	tickrate: int,
	reason: String,
	_test_parameters := [[30, SPENT], [30, NO_STAMINA], [60, SPENT], [60, NO_STAMINA]],
) -> void:
	var landing_tick := _landing_tick_unavailable(tickrate, reason)
	var rig := _rig(tickrate)
	_assert_ground_jumped(_fly_unavailable_and_press_at(rig, reason, landing_tick, landing_tick))


# With the double jump available, the press fires at once, even on the landing tick itself
# (movimento.md, "Pulo e ar": "Aperto no ar com o pulo duplo disponível: sai na hora").
func test_with_the_double_jump_available_a_press_near_landing_double_jumps_at_once(
	tickrate: int,
	ticks_before_landing: int,
	_test_parameters := [[30, 0], [30, 1], [30, 4], [60, 0], [60, 1], [60, 8]],
) -> void:
	var probe := _rig(tickrate)
	probe.step(MovementRig.press_jump())
	var landing_tick := _idle_until_landed(probe)
	var rig := _rig(tickrate)
	rig.step(MovementRig.press_jump())
	while rig.tick < landing_tick - ticks_before_landing:
		rig.step(MovementRig.idle())
	var flight := _press_and_record(rig, MovementRig.press_jump())
	_assert_double_jumped(rig, flight.plan, flight.press_tick)
	_assert_rise(flight, DOUBLE_JUMP_HEIGHT_M, tickrate)
	assert_int(flight.landing_step).override_failure_message("never landed").is_greater(1)
	assert_int(rig.state.jumps_used).is_equal(0)


# Criterion 3: a press inside the coyote (1 tick after the ledge and the last tick of the
# window) is the full jump and leaves the double jump for later.
func test_a_coyote_jump_is_the_full_jump_and_keeps_the_double_jump(
	tickrate: int,
	ticks_after_ledge: int,
	_test_parameters := [[30, 1], [30, 3], [60, 1], [60, 6]],
) -> void:
	var rig := _rig(tickrate)
	_leave_ledge(rig)
	rig.rest(ticks_after_ledge - 1)
	var plan := rig.step(MovementRig.press_jump())
	_assert_ground_jumped(plan)
	var full := "the coyote jump must leave faster than the double jump"
	assert_float(plan.velocity.y).override_failure_message(full).is_greater(
		rig.config.double_jump_speed + HAIR
	)
	rig.rest(2)
	var flight := _press_and_record(rig, MovementRig.press_jump())
	_assert_double_jumped(rig, flight.plan, flight.press_tick)
	_assert_rise(flight, DOUBLE_JUMP_HEIGHT_M, tickrate)


# One tick past the coyote, without a jump, the press is the double jump: it pays the cost and
# uses up the flight (movimento.md, "Pulo e ar": "Aperto depois do coyote, sem ter pulado").
func test_a_press_after_the_coyote_without_a_jump_is_the_double_jump(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	_leave_ledge(rig)
	rig.rest(COYOTE_TICKS[tickrate])
	var flight := _press_and_record(rig, MovementRig.press_jump())
	_assert_double_jumped(rig, flight.plan, flight.press_tick)
	_assert_rise(flight, DOUBLE_JUMP_HEIGHT_M, tickrate)
	assert_float(rig.config.double_jump_cost).is_equal(DOUBLE_JUMP_COST)
	assert_float(Stamina.at(rig.state, rig.config, flight.press_tick)).is_equal_approx(
		rig.config.stamina_max - rig.config.double_jump_cost,
		HAIR,
	)
	var velocity_y_before := rig.velocity.y
	var again := rig.step(MovementRig.press_jump())
	assert_int(again.state.jumps_used).is_equal(2)
	assert_float(again.velocity.y).is_less_equal(velocity_y_before + HAIR)


func test_landing_renews_the_double_jump(tickrate: int, _test_parameters := [[30], [60]]) -> void:
	var rig := _rig(tickrate)
	_jump_then_idle(rig, 0)
	_assert_double_jumped(rig, rig.step(MovementRig.press_jump()), FIRST_TICK + 1)
	_idle_until_landed(rig)
	assert_int(rig.state.jumps_used).is_equal(0)
	assert_int(rig.state.double_jump_tick).is_equal(FighterState.NEVER)
	rig.rest(1)
	_assert_ground_jumped(rig.step(MovementRig.press_jump()))
	var flight := _press_and_record(rig, MovementRig.press_jump())
	_assert_double_jumped(rig, flight.plan, flight.press_tick)
	_assert_rise(flight, DOUBLE_JUMP_HEIGHT_M, tickrate)


# Criterion 4: the whole horizontal velocity turns to the pointed direction, relative to the
# camera, with the same magnitude (movimento.md, "Pulo e ar": "vira para onde o jogador aponta",
# "Mantém a velocidade horizontal, sem ganhar"). Cases: right at yaw 0 (+X), forward at a
# quarter turn left (-X), back at yaw 0 (+Z) and a short diagonal, which only gives a direction.
func test_the_double_jump_turns_the_horizontal_velocity_to_the_pointed_direction(
	tickrate: int,
	move: Vector2,
	yaw: float,
	_test_parameters := [
		[30, Vector2(1, 0), 0.0],
		[60, Vector2(1, 0), 0.0],
		[60, Vector2(0, 1), PI / 2],
		[60, Vector2(0, -1), 0.0],
		[60, Vector2(0.5, 0.5), 0.0],
	],
) -> void:
	var rig := _rig(tickrate)
	for _step: int in tickrate:
		rig.step(MovementRig.run(Vector2(0, 1)))
	rig.step(MovementRig.press_jump_toward(Vector2(0, 1)))
	rig.rest(2)
	var before := rig.horizontal_velocity()
	assert_float(before.length()).override_failure_message("no run to turn").is_greater(1.0)
	var plan := rig.step(MovementRig.press_jump_toward(move, yaw))
	assert_int(plan.state.jumps_used).is_equal(2)
	var expected := _world_direction(move, yaw).normalized() * before.length()
	var after := Vector3(plan.velocity.x, 0.0, plan.velocity.z)
	var message := "turned to %s, expected %s (from %s)" % [after, expected, before]
	assert_vector(after).override_failure_message(message).is_equal_approx(
		expected,
		Vector3.ONE * HAIR,
	)
	assert_float(after.length()).is_equal_approx(before.length(), HAIR)


# At a partial speed the magnitude still holds: the air control adds nothing on that tick.
func test_the_turn_keeps_a_partial_speed_without_air_control_gain(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	rig.step(MovementRig.run(Vector2(0, 1)))
	rig.step(MovementRig.press_jump_toward(Vector2(0, 1)))
	rig.rest(2)
	var before := rig.horizontal_velocity()
	assert_float(before.length()).is_greater(HAIR)
	var plan := rig.step(MovementRig.press_jump_toward(Vector2(1, 0)))
	assert_int(plan.state.jumps_used).is_equal(2)
	var after := Vector3(plan.velocity.x, 0.0, plan.velocity.z)
	assert_vector(after).is_equal_approx(Vector3.RIGHT * before.length(), Vector3.ONE * HAIR)


# Without a direction, the horizontal velocity keeps its direction and magnitude, even when
# the camera has turned (movimento.md, "Pulo e ar": "Sem direção apontada, mantém").
func test_without_a_direction_the_double_jump_keeps_the_horizontal_velocity(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	for _step: int in tickrate:
		rig.step(MovementRig.run(Vector2(0, 1)))
	rig.step(MovementRig.press_jump_toward(Vector2(0, 1)))
	rig.rest(2)
	var before := rig.horizontal_velocity()
	var plan := rig.step(MovementRig.press_jump_toward(Vector2.ZERO, PI / 2))
	assert_int(plan.state.jumps_used).is_equal(2)
	assert_float(plan.state.facing_yaw).is_equal(PI / 2)
	var after := Vector3(plan.velocity.x, 0.0, plan.velocity.z)
	assert_vector(after).is_equal_approx(before, Vector3.ONE * HAIR)


# Criterion 6: one slot, the last press wins (movimento.md, "Perdão"; DEC-0039).
func test_a_new_press_replaces_the_one_in_the_slot(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	_fly_unavailable(rig, SPENT)
	rig.rest(1)
	var first_press := rig.tick
	_assert_slot(rig.step(MovementRig.press_jump()).state, FighterCommand.JUMP, first_press)
	rig.rest(1)
	var second_press := rig.tick
	_assert_slot(rig.step(MovementRig.press_jump()).state, FighterCommand.JUMP, second_press)
	_assert_slot(rig.step(MovementRig.idle()).state, FighterCommand.JUMP, second_press)


# The window counts from the last press: an old press, dead by the landing, followed by one at
# the limit of the window, jumps on the first tick on the floor.
func test_the_buffer_window_counts_from_the_last_press(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var landing_tick := _landing_tick_unavailable(tickrate, SPENT)
	var rig := _rig(tickrate)
	_fly_unavailable(rig, SPENT)
	var old_press := landing_tick - BUFFER_TICKS[tickrate] - 1
	var last_press := landing_tick + 1 - BUFFER_TICKS[tickrate]
	while rig.tick <= landing_tick:
		var pressed := rig.tick == old_press or rig.tick == last_press
		rig.step(MovementRig.press_jump() if pressed else MovementRig.idle())
	assert_bool(rig.state.on_floor).is_true()
	_assert_slot(rig.state, FighterCommand.JUMP, last_press)
	_assert_ground_jumped(rig.step(MovementRig.idle()))


func test_a_fresh_state_has_an_empty_slot_no_double_jump_and_a_bar_never_spent() -> void:
	var state := FighterState.new()
	_assert_slot(state, FighterCommand.NONE, FighterState.NEVER)
	assert_int(state.double_jump_tick).is_equal(FighterState.NEVER)
	assert_int(state.stamina_spent_tick).is_equal(FighterState.NEVER)
	assert_str(String(FighterCommand.NONE)).is_equal("")
	assert_str(String(FighterCommand.JUMP)).is_equal("jump")


# Criterion 7, the Resource half (DEC-0004, rule 3): the apex follows double_jump_height_m of a
# duplicated MovementData, without touching code. 0.5 and 2.0 m are arbitrary heights, not
# design numbers.
func test_the_apex_follows_the_double_jump_height_of_a_duplicated_resource(
	tickrate: int,
	height_m: float,
	_test_parameters := [[30, 0.5], [30, 2.0], [60, 0.5], [60, 2.0]],
) -> void:
	var resource: Resource = load(MovementRig.MOVEMENT_V0)
	assert(resource is MovementData, "%s must load as a MovementData" % MovementRig.MOVEMENT_V0)
	var copy: Resource = resource.duplicate()
	assert(copy is MovementData, "a duplicate must still be a MovementData")
	var data := copy as MovementData
	data.double_jump_height_m = height_m
	assert_array(data.validate()).is_empty()
	var rig := MovementRig.new(MovementConfig.create(data, tickrate), FIRST_TICK)
	_jump_then_idle(rig, 2)
	var flight := _press_and_record(rig, MovementRig.press_jump())
	assert_int(flight.plan.state.jumps_used).is_equal(2)
	_assert_rise(flight, height_m, tickrate)
