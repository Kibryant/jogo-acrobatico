# Criteria 1, 2, 3 and 7 of TASK-12.1: the light attack as the second state machine of the fighter,
# the action (glossario.md, "Ação"; DEC-0022), through the public interface of core/fighter, with
# the whole tick sandwich played by CombatRig (DEC-0051 §2: Combat.step, then Movement.before_move,
# the engine by hand, Movement.after_move). The phases in ticks, the stamina on the first tick, no
# input cutting the sequence (DEC-0016), the refusals that wait in the one slot of the buffer
# (movimento.md, "Perdão" and "Stamina"; DEC-0039), the slow walk during the swing (movimento.md,
# "Chão": "Andar devagar"), the commands that wait for the recovery's end, the tie order on one
# tick and the arc's direction fixed on the last tick of the windup (combate.md, "O leve no tick").
# Every number comes from docs/design, cited by section; ticks by hand from the ms, nearest tick
# with ties up (visao-geral.md, "O tempo e a física no estado").
extends GdUnitTestSuite

const CombatRig := preload("res://test/core/fighter/combat_rig.gd")
const MovementRig := preload("res://test/core/fighter/movement_rig.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)
const LIGHT := &"light_attack" # the move's ID (glossario.md, "Golpe leve"; TASK-12.1 plan)

# combate.md, "Os golpes e as defesas", the row "Golpe leve": 400 / 100 / 250 ms, 8 de stamina
# no início. By hand: 24 / 6 / 15 ticks at 60; 12 / 3 / 8 at 30, the 250 ms a tie of 7.5 that
# rounds up (DEC-0022). A swing lasts 45 ticks at 60 and 23 at 30; fired at F, the body is free
# again on F + 45 (combate.md, "O leve no tick": "As fases").
const WINDUP_TICKS: Dictionary[int, int] = { 30: 12, 60: 24 }
const ACTIVE_TICKS: Dictionary[int, int] = { 30: 3, 60: 6 }
const RECOVERY_TICKS: Dictionary[int, int] = { 30: 8, 60: 15 }
const LIGHT_COST := 8.0
const STAMINA_MAX := 100.0 # movimento.md, "Stamina": "Máximo"
const BELOW_COST := 7.5 # criterion 2: a bar of 7.5 cannot pay the cost of 8
# 150 ms of buffer is 4.5 -> 5 at 30 (tie up) and 9 at 60, inclusive: the press counts while
# tick - stamp <= window (movimento.md, "Perdão"; DEC-0039).
const BUFFER_TICKS: Dictionary[int, int] = { 30: 5, 60: 9 }
# 800 ms of wait is 24 ticks at 30 and 48 at 60; 30 points per second is 1.0 per tick at 30 and
# 0.5 at 60 (movimento.md, "Stamina"). From 7.5, the first tick after the wait reads 8.5 at 30
# and 8.0 at 60: the first tick that can pay the cost of 8.
const STAMINA_WAIT_TICKS: Dictionary[int, int] = { 30: 24, 60: 48 }
const REGEN_PER_TICK: Dictionary[int, float] = { 30: 1.0, 60: 0.5 }
const DASH_COST := 15.0 # movimento.md, "Dash": "Custo"
# movimento.md, "Dash": "Duração": 200 ms is 6 ticks at 30 and 12 at 60.
const DASH_TICKS: Dictionary[int, int] = { 30: 6, 60: 12 }
# movimento.md, "Chão": "Andar devagar: com a guarda alta ou durante um golpe: 3 m/s"; "Velocidade
# de corrida: 7 m/s"; "Tempo até a velocidade máxima: 150 ms", 5 ticks at 30 and 9 at 60, so a
# tick of full input adds 7 / 9 = 0,778 m/s at 60 and 1,4 at 30 ("Deriva a aceleração").
const SLOW_WALK_MPS := 3.0
const RUN_SPEED_MPS := 7.0
const ACCEL_TICKS: Dictionary[int, int] = { 30: 5, 60: 9 }

const FORWARD := Vector2(0, 1) # move.y goes forward: yaw 0 looks down -Z (TASK-9 plan)
const RIGHT := Vector2(1, 0)
const BACK := Vector2(0, -1)
const HAIR := 1e-6 # floating-point slack, not a design number
const YAW_STEP := 0.05 # rad per tick the camera turns in the yaw tests: arithmetic
const FIRST_YAW := 0.3 # rad, arithmetic
const LEDGE_AT := 5 # ticks into the swing the floor goes away: arithmetic


func _fighter(tickrate: int) -> CombatRig:
	return CombatRig.new(
		&"A",
		MovementRig.load_config(tickrate),
		CombatRig.load_combat(tickrate),
		FIRST_TICK,
	)


func _swing_ticks(tickrate: int) -> int:
	return WINDUP_TICKS[tickrate] + ACTIVE_TICKS[tickrate] + RECOVERY_TICKS[tickrate]


func _accel_per_tick(tickrate: int) -> float:
	return RUN_SPEED_MPS / ACCEL_TICKS[tickrate]


# The phase a swing fired at `first` is in at `tick`, as a line: the action, the tick its phase
# began and the move; NONE alone before the swing and from its end on.
func _expected_phase(first: int, tick: int, tickrate: int) -> String:
	var active_from := first + WINDUP_TICKS[tickrate]
	var recovery_from := active_from + ACTIVE_TICKS[tickrate]
	var end := recovery_from + RECOVERY_TICKS[tickrate]
	if tick < first or tick >= end:
		return "NONE"
	if tick < active_from:
		return "WINDUP since %d with %s" % [first, LIGHT]
	if tick < recovery_from:
		return "ACTIVE since %d with %s" % [active_from, LIGHT]
	return "RECOVERY since %d with %s" % [recovery_from, LIGHT]


func _phase_of(state: FighterState) -> String:
	if state.action == FighterState.Action.NONE:
		return "NONE"
	var name: Variant = FighterState.Action.find_key(state.action)
	return "%s since %d with %s" % [name, state.action_since, state.action_move]


# Steps one tick and records a violation when the phase is not the one of a swing fired at first.
func _step_checking_phase(
	fighter: CombatRig,
	input: TickInput,
	first: int,
	violations: Array[String],
) -> MovePlan:
	var tick := fighter.tick()
	var plan := fighter.step(input)
	var seen := _phase_of(fighter.fought)
	var expected := _expected_phase(first, tick, fighter.config().tickrate)
	if seen != expected:
		violations.append("tick %d: %s, expected %s" % [tick, seen, expected])
	return plan


# Fires a light now and returns the tick it fired on.
func _fire(fighter: CombatRig, input: TickInput = CombatRig.press_light()) -> int:
	var first := fighter.tick()
	fighter.step(input)
	_assert_phase(fighter.fought, FighterState.Action.WINDUP, first)
	return first


func _assert_phase(state: FighterState, action: FighterState.Action, since: int) -> void:
	var message := "phase %s, expected %s since %d" % [
		_phase_of(state),
		FighterState.Action.find_key(action),
		since,
	]
	assert_int(state.action).override_failure_message(message).is_equal(action)
	assert_int(state.action_since).override_failure_message(message).is_equal(since)
	assert_str(String(state.action_move)).override_failure_message(message).is_equal(String(LIGHT))


func _assert_none(state: FighterState) -> void:
	var message := "phase %s, expected NONE" % _phase_of(state)
	assert_int(state.action).override_failure_message(message).is_equal(FighterState.Action.NONE)


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


func _assert_empty_slot(state: FighterState) -> void:
	_assert_slot(state, FighterCommand.NONE, FighterState.NEVER)


func _horizontal(velocity: Vector3) -> Vector3:
	return Vector3(velocity.x, 0.0, velocity.z)


func _world_direction(move: Vector2, yaw: float) -> Vector3:
	return (Basis(Vector3.UP, yaw) * Vector3(move.x, 0.0, -move.y)).normalized()


# Idles until the fighter lands; returns the landing tick, the one whose after_move saw the floor.
func _idle_until_landed(fighter: CombatRig) -> int:
	for _step: int in range(1, 5 * fighter.config().tickrate + 1):
		fighter.step(CombatRig.idle())
		if fighter.state().on_floor:
			return fighter.tick() - 1
	fail("never landed at %d ticks" % fighter.config().tickrate)
	return 0


# The landing tick of a plain jump pressed at FIRST_TICK, to place presses relative to it.
func _landing_tick_of_a_jump(tickrate: int) -> int:
	var fighter := _fighter(tickrate)
	fighter.step(MovementRig.press_jump())
	return _idle_until_landed(fighter)


# None: a fresh state has no action, no contact and was never hurt (TASK-12.1 plan).
func test_a_fresh_state_has_no_action_no_contact_and_full_health() -> void:
	var fighter := _fighter(60)
	var state := fighter.state()
	_assert_none(state)
	assert_int(state.action_since).is_equal(FighterState.NEVER)
	assert_str(String(state.action_move)).is_equal("")
	assert_int(state.contact_tick).is_equal(FighterState.NEVER)
	assert_str(String(state.contact_target)).is_equal("")
	assert_str(String(state.contact_move)).is_equal("")
	assert_int(state.hurt_tick).is_equal(FighterState.NEVER)
	assert_int(state.health).is_equal(fighter.combat.max_health)
	assert_int(FighterState.new().health).override_failure_message("fresh health is 0") \
			.is_equal(0)
	# The copy carries the new fields too (TASK-12.1 plan: copy() copies all of them).
	state.action = FighterState.Action.RECOVERY
	state.action_since = 7
	state.action_move = LIGHT
	state.action_yaw = 1.5
	state.contact_tick = 9
	state.contact_target = &"B"
	state.contact_move = LIGHT
	state.health = 88
	state.hurt_tick = 11
	var copy := state.copy()
	assert_int(copy.action).is_equal(FighterState.Action.RECOVERY)
	assert_int(copy.action_since).is_equal(7)
	assert_str(String(copy.action_move)).is_equal(String(LIGHT))
	assert_float(copy.action_yaw).is_equal(1.5)
	assert_int(copy.contact_tick).is_equal(9)
	assert_str(String(copy.contact_target)).is_equal("B")
	assert_str(String(copy.contact_move)).is_equal(String(LIGHT))
	assert_int(copy.health).is_equal(88)
	assert_int(copy.hurt_tick).is_equal(11)


# Criterion 1: standing on the floor with no swing in progress and a full bar, the press fires the
# light on its own tick, and the action goes through the windup, the active and the recovery, each
# counted from the tick it began, and is NONE again right after (combate.md, "O leve no tick":
# "As fases"): 24 / 6 / 15 ticks at 60, 12 / 3 / 8 at 30.
func test_the_light_runs_windup_active_and_recovery_tick_by_tick(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	var first := fighter.tick()
	var violations: Array[String] = []
	for offset: int in _swing_ticks(tickrate) + 3:
		var input := CombatRig.press_light() if offset == 0 else CombatRig.idle()
		_step_checking_phase(fighter, input, first, violations)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	_assert_empty_slot(fighter.state())
	assert_int(fighter.fought.mode).is_equal(FighterState.Mode.GROUND)


# The ticks of each phase by hand against the config the swing runs on: the windup is 400 ms, the
# active 100 and the recovery 250, nearest tick with ties up.
func test_the_phases_follow_the_config_made_from_combat_v0(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var light: AttackConfig = CombatRig.load_combat(tickrate).attacks[LIGHT]
	assert_int(light.windup_ticks).is_equal(WINDUP_TICKS[tickrate])
	assert_int(light.active_ticks).is_equal(ACTIVE_TICKS[tickrate])
	assert_int(light.recovery_ticks).is_equal(RECOVERY_TICKS[tickrate])
	assert_float(light.stamina_cost).is_equal_approx(LIGHT_COST, HAIR)


# Criterion 1: the 8 points are paid on the first tick of the windup, and never again during the
# swing (combate.md, "Os golpes e as defesas": "A stamina no combate": "O leve [...] paga no
# início").
func test_the_light_pays_8_stamina_on_its_first_tick_and_nothing_more(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	assert_float(fighter.stamina()).is_equal_approx(STAMINA_MAX, HAIR)
	var first := _fire(fighter)
	var paid := fighter.fought
	assert_int(paid.stamina_spent_tick).override_failure_message("not paid on the press tick") \
			.is_equal(first)
	assert_float(Stamina.at(paid, fighter.config(), first)).is_equal_approx(
		STAMINA_MAX - LIGHT_COST,
		HAIR,
	)
	for _offset: int in _swing_ticks(tickrate):
		fighter.step(CombatRig.idle())
		assert_int(fighter.fought.stamina_spent_tick).override_failure_message("paid again") \
				.is_equal(first)


# Criterion 1: no input cuts the sequence (DEC-0016): a jump, a dash, a grapple, another light and
# a full push during the swing leave the phases as they are, start no maneuver and pay nothing
# more; the pushes only walk the body (criterion 3).
func test_no_input_cuts_the_light(tickrate: int, _test_parameters := [[30], [60]]) -> void:
	var fighter := _fighter(tickrate)
	var first := _fire(fighter)
	var swing := _swing_ticks(tickrate)
	# Each press lands in a different phase; none of them is within the buffer of the swing's end.
	var presses: Dictionary[int, TickInput] = {
		2: MovementRig.press_jump_toward(FORWARD),
		WINDUP_TICKS[tickrate] - 1: MovementRig.press_dash_toward(RIGHT),
		WINDUP_TICKS[tickrate] + 1: MovementRig.press_grapple_toward(BACK),
		WINDUP_TICKS[tickrate] + ACTIVE_TICKS[tickrate] + 1: CombatRig.press_light(FORWARD),
	}
	var violations: Array[String] = []
	for offset: int in range(1, swing + 1):
		var input := presses[offset] if presses.has(offset) else CombatRig.walk(FORWARD)
		var plan := _step_checking_phase(fighter, input, first, violations)
		var state := fighter.fought
		if state.jumps_used != 0 or state.mode != FighterState.Mode.GROUND:
			violations.append("tick %d: jumped or left GROUND" % (first + offset))
		if state.dash_tick != FighterState.NEVER or state.grapple_fired_tick != FighterState.NEVER:
			violations.append("tick %d: dashed or grappled" % (first + offset))
		if state.stamina_spent_tick != first:
			violations.append("tick %d: paid again" % (first + offset))
		if plan.aim_request:
			violations.append("tick %d: asked for the aim during the swing" % (first + offset))
		if not fighter.state().on_floor:
			violations.append("tick %d: left the floor" % (first + offset))
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()


# Criterion 2: without 8 of stamina the light does not come out and nothing is paid: the press
# waits in the slot and fires on the first tick the bar can pay, inside the 150 ms (movimento.md,
# "Stamina": "Sem stamina suficiente"; "Perdão"). The bar is set by hand to 7.5, stamped so that it
# first reads 8 or more `ticks_ahead` ticks after the press, up to the last tick of the window.
func test_a_press_without_8_stamina_waits_in_the_slot_and_fires_when_the_bar_can_pay(
	tickrate: int,
	ticks_ahead: int,
	_test_parameters := [[30, 1], [30, 3], [30, 5], [60, 1], [60, 4], [60, 9]],
) -> void:
	var fighter := _fighter(tickrate)
	var press_tick := fighter.tick()
	var stamp := press_tick + ticks_ahead - STAMINA_WAIT_TICKS[tickrate] - 1
	fighter.state().stamina_at_spend = BELOW_COST
	fighter.state().stamina_spent_tick = stamp
	assert_float(fighter.stamina()).override_failure_message("the bar must read 7.5 now") \
			.is_equal_approx(BELOW_COST, HAIR)
	fighter.step(CombatRig.press_light())
	_assert_none(fighter.fought)
	_assert_slot(fighter.fought, FighterCommand.LIGHT_ATTACK, press_tick)
	assert_int(fighter.fought.stamina_spent_tick).override_failure_message("paid with 7.5") \
			.is_equal(stamp)
	for offset: int in range(1, ticks_ahead):
		fighter.step(CombatRig.idle())
		_assert_none(fighter.fought)
		_assert_slot(fighter.fought, FighterCommand.LIGHT_ATTACK, press_tick)
		assert_int(fighter.fought.stamina_spent_tick).is_equal(stamp)
	var fire_tick := press_tick + ticks_ahead
	assert_int(fighter.tick()).is_equal(fire_tick)
	var bar_before := fighter.stamina()
	assert_float(bar_before).is_equal_approx(BELOW_COST + REGEN_PER_TICK[tickrate], HAIR)
	fighter.step(CombatRig.idle())
	_assert_phase(fighter.fought, FighterState.Action.WINDUP, fire_tick)
	_assert_empty_slot(fighter.fought)
	assert_int(fighter.fought.stamina_spent_tick).is_equal(fire_tick)
	assert_float(Stamina.at(fighter.fought, fighter.config(), fire_tick)).is_equal_approx(
		bar_before - LIGHT_COST,
		HAIR,
	)


# Limit: a bar that can pay only one tick past the window never fires the light, and the slot
# lets the press go (DEC-0039).
func test_a_press_without_stamina_past_the_buffer_never_fires(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	var press_tick := fighter.tick()
	var ticks_ahead := BUFFER_TICKS[tickrate] + 1
	var stamp := press_tick + ticks_ahead - STAMINA_WAIT_TICKS[tickrate] - 1
	fighter.state().stamina_at_spend = BELOW_COST
	fighter.state().stamina_spent_tick = stamp
	fighter.step(CombatRig.press_light())
	for offset: int in range(1, ticks_ahead):
		fighter.step(CombatRig.idle())
		_assert_none(fighter.fought)
		_assert_slot(fighter.fought, FighterCommand.LIGHT_ATTACK, press_tick)
	for _offset: int in 5:
		fighter.step(CombatRig.idle())
		_assert_none(fighter.fought)
		_assert_empty_slot(fighter.fought)
		assert_int(fighter.fought.stamina_spent_tick).override_failure_message("paid late") \
				.is_equal(stamp)


# Criterion 2: in the air the light does not come out and nothing is paid (combate.md, "O leve no
# tick": "em pé no chão"): the press waits in the slot and fires on the first tick that starts on
# the floor, pressed at the limit of the window before it or on the landing tick itself.
func test_a_press_in_the_air_waits_in_the_slot_and_fires_on_the_first_tick_on_the_floor(
	tickrate: int,
	ticks_before_the_first_floor_tick: int,
	_test_parameters := [[30, 1], [30, 5], [60, 1], [60, 9]],
) -> void:
	var landing_tick := _landing_tick_of_a_jump(tickrate)
	var fighter := _fighter(tickrate)
	fighter.step(MovementRig.press_jump())
	var first_floor_tick := landing_tick + 1
	var press_tick := first_floor_tick - ticks_before_the_first_floor_tick
	assert_int(press_tick).is_greater(FIRST_TICK)
	while fighter.tick() < first_floor_tick:
		var tick := fighter.tick()
		var input := CombatRig.press_light() if tick == press_tick else CombatRig.idle()
		fighter.step(input)
		_assert_none(fighter.fought)
		if tick >= press_tick:
			_assert_slot(fighter.fought, FighterCommand.LIGHT_ATTACK, press_tick)
	assert_bool(fighter.state().on_floor).override_failure_message("not landed yet").is_true()
	assert_int(fighter.state().stamina_spent_tick).override_failure_message("paid in the air") \
			.is_equal(FighterState.NEVER)
	fighter.step(CombatRig.idle())
	_assert_phase(fighter.fought, FighterState.Action.WINDUP, first_floor_tick)
	_assert_empty_slot(fighter.fought)
	assert_int(fighter.fought.stamina_spent_tick).is_equal(first_floor_tick)


func test_a_press_in_the_air_one_tick_past_the_buffer_does_not_fire_on_landing(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var landing_tick := _landing_tick_of_a_jump(tickrate)
	var fighter := _fighter(tickrate)
	fighter.step(MovementRig.press_jump())
	var first_floor_tick := landing_tick + 1
	var press_tick := first_floor_tick - BUFFER_TICKS[tickrate] - 1
	while fighter.tick() < first_floor_tick:
		var input := CombatRig.press_light() if fighter.tick() == press_tick else CombatRig.idle()
		fighter.step(input)
		_assert_none(fighter.fought)
	assert_bool(fighter.state().on_floor).is_true()
	fighter.step(CombatRig.idle())
	_assert_none(fighter.fought)
	_assert_empty_slot(fighter.fought)
	assert_int(fighter.fought.stamina_spent_tick).is_equal(FighterState.NEVER)


# Criterion 2: on another fighter's head the body is in the air for the rules (movimento.md, "O
# corpo": "A cabeça do outro"; Movement.stands), so the light waits there and fires on the first
# tick standing on a floor of its own.
func test_a_press_on_another_fighters_head_waits_and_fires_once_standing() -> void:
	var fighter := _fighter(60)
	var press_tick := fighter.tick()
	var state := fighter.state()
	state.mode = FighterState.Mode.AIR
	state.mode_since = press_tick - 1
	state.on_floor = true
	state.slide_off_dir = Vector3(1.0, 0.0, 0.0)
	state.head_landing_tick = press_tick - 1
	assert_bool(Movement.stands(state)).override_failure_message("a head is not standing") \
			.is_false()
	fighter.step(CombatRig.press_light())
	_assert_none(fighter.fought)
	_assert_slot(fighter.fought, FighterCommand.LIGHT_ATTACK, press_tick)
	assert_int(fighter.fought.stamina_spent_tick).is_equal(FighterState.NEVER)
	# The rig has no head: its floor is a floor of the fighter's own, so the next tick stands.
	assert_bool(Movement.stands(fighter.state())).override_failure_message("still on the head") \
			.is_true()
	fighter.step(CombatRig.idle())
	_assert_phase(fighter.fought, FighterState.Action.WINDUP, press_tick + 1)
	_assert_empty_slot(fighter.fought)


# Criterion 2: in a dash the mode is not GROUND (combate.md, "O leve no tick": "o modo GROUND"),
# so the light waits. The dash ends in before_move of its exit tick, after the combat's step of
# that tick (DEC-0051 §2), so the first tick the light can fire is the one after the exit, here
# the last tick of the window.
func test_a_press_in_a_dash_waits_and_fires_on_the_first_tick_back_on_the_ground(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	var dash_tick := fighter.tick()
	fighter.step(MovementRig.press_dash_toward(FORWARD))
	# The state at the end of the tick: the dash starts in before_move, after the combat's step
	# (DEC-0041 §1), so fought, the state before the movement, still reads GROUND (F-177).
	assert_int(fighter.state().mode).override_failure_message("no dash").is_equal(
		FighterState.Mode.DASH
	)
	var exit_tick := dash_tick + DASH_TICKS[tickrate]
	var fire_tick := exit_tick + 1
	var press_tick := fire_tick - BUFFER_TICKS[tickrate]
	while fighter.tick() < fire_tick:
		var tick := fighter.tick()
		var input := CombatRig.press_light() if tick == press_tick else CombatRig.idle()
		fighter.step(input)
		_assert_none(fighter.fought)
		if tick >= press_tick:
			_assert_slot(fighter.fought, FighterCommand.LIGHT_ATTACK, press_tick)
	assert_int(fighter.state().mode).override_failure_message("the dash did not end") \
			.is_equal(FighterState.Mode.GROUND)
	fighter.step(CombatRig.idle())
	_assert_phase(fighter.fought, FighterState.Action.WINDUP, fire_tick)
	_assert_empty_slot(fighter.fought)
	assert_float(Stamina.at(fighter.fought, fighter.config(), fire_tick)).is_equal_approx(
		STAMINA_MAX - DASH_COST - LIGHT_COST,
		HAIR,
	)


# Criterion 2: with a swing in progress a second press waits in the slot and fires on the first
# tick after the recovery, the swing's end tick, when it is still within the 150 ms; the swing in
# progress is not touched by it.
func test_a_press_during_a_swing_waits_and_fires_on_the_first_tick_after_the_recovery(
	tickrate: int,
	ticks_before_the_end: int,
	_test_parameters := [[30, 1], [30, 5], [60, 1], [60, 9]],
) -> void:
	var fighter := _fighter(tickrate)
	var first := _fire(fighter)
	var end := first + _swing_ticks(tickrate)
	var press_tick := end - ticks_before_the_end
	var violations: Array[String] = []
	while fighter.tick() < end:
		var tick := fighter.tick()
		var input := CombatRig.press_light() if tick == press_tick else CombatRig.idle()
		_step_checking_phase(fighter, input, first, violations)
		if tick >= press_tick:
			_assert_slot(fighter.fought, FighterCommand.LIGHT_ATTACK, press_tick)
		assert_int(fighter.fought.stamina_spent_tick).is_equal(first)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	fighter.step(CombatRig.idle())
	_assert_phase(fighter.fought, FighterState.Action.WINDUP, end)
	_assert_empty_slot(fighter.fought)
	assert_int(fighter.fought.stamina_spent_tick).is_equal(end)
	# The first 8 were paid at `first`, within the wait of 800 ms: nothing regained in between.
	assert_float(Stamina.at(fighter.fought, fighter.config(), end)).is_equal_approx(
		STAMINA_MAX - 2.0 * LIGHT_COST,
		HAIR,
	)


func test_a_press_during_a_swing_past_the_buffer_does_not_fire_at_its_end(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	var first := _fire(fighter)
	var end := first + _swing_ticks(tickrate)
	var press_tick := end - BUFFER_TICKS[tickrate] - 1
	while fighter.tick() < end:
		var input := CombatRig.press_light() if fighter.tick() == press_tick else CombatRig.idle()
		fighter.step(input)
	fighter.step(CombatRig.idle())
	_assert_none(fighter.fought)
	_assert_empty_slot(fighter.fought)
	assert_int(fighter.fought.stamina_spent_tick).is_equal(first)


# Criterion 3: standing, the body walks at up to 3 m/s in any direction during the swing, from
# the swing's first tick, by the ground acceleration (movimento.md, "Chão": "Andar devagar";
# combate.md, "O leve no tick": "O corpo durante o golpe"): from rest, 7 / 9 = 0,778 m/s more per
# tick at 60 until 3, and 1,4 at 30. On the swing's end tick the run of 7 is the target again.
func test_the_body_walks_at_most_3_mps_standing_during_the_light(
	tickrate: int,
	move: Vector2,
	_test_parameters := [[30, FORWARD], [60, FORWARD], [60, RIGHT], [60, BACK]],
) -> void:
	var fighter := _fighter(tickrate)
	var accel := _accel_per_tick(tickrate)
	var direction := _world_direction(move, 0.0)
	var violations: Array[String] = []
	var swing := _swing_ticks(tickrate)
	for offset: int in swing:
		var input := CombatRig.press_light(move) if offset == 0 else CombatRig.walk(move)
		var plan := fighter.step(input)
		var expected := minf(SLOW_WALK_MPS, (offset + 1) * accel)
		var horizontal := _horizontal(plan.velocity)
		if horizontal.distance_to(direction * expected) > HAIR:
			violations.append(
				"tick %d of the swing: %s, expected %s" % [offset, horizontal, direction * expected]
			)
		if horizontal.length() > SLOW_WALK_MPS + HAIR:
			violations.append(
				"tick %d of the swing: %.3f m/s, above 3" % [offset, horizontal.length()]
			)
		if plan.velocity.y != 0.0:
			violations.append("tick %d of the swing: vertical %.3f" % [offset, plan.velocity.y])
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	_assert_phase(
		fighter.fought,
		FighterState.Action.RECOVERY,
		fighter.tick() - RECOVERY_TICKS[tickrate],
	)
	var free := fighter.step(CombatRig.walk(move))
	_assert_none(fighter.fought)
	assert_float(_horizontal(free.velocity).length()) \
			.override_failure_message("the end tick must run again") \
			.is_equal_approx(SLOW_WALK_MPS + accel, HAIR)


# Criterion 3: from the run, the speed falls from 7 toward 3 by the ground acceleration, 0,778
# m/s per tick at 60 and 1,4 at 30, the swing's first tick included (combate.md, "O leve no tick":
# "vindo da corrida, cai de 7 para 3 m/s em uns 90 ms, pela aceleração do chão"): 6 ticks at 60,
# 3 at 30, and 3 m/s from then on.
func test_a_run_slows_to_3_mps_during_the_light_by_the_ground_acceleration(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	var accel := _accel_per_tick(tickrate)
	for _tick: int in ACCEL_TICKS[tickrate] + 2:
		fighter.step(CombatRig.walk(FORWARD))
	assert_float(fighter.horizontal_speed()).is_equal_approx(RUN_SPEED_MPS, HAIR)
	var violations: Array[String] = []
	var direction := _world_direction(FORWARD, 0.0)
	for offset: int in _swing_ticks(tickrate):
		var input := CombatRig.press_light(FORWARD) if offset == 0 else CombatRig.walk(FORWARD)
		var plan := fighter.step(input)
		var expected := maxf(SLOW_WALK_MPS, RUN_SPEED_MPS - (offset + 1) * accel)
		var horizontal := _horizontal(plan.velocity)
		if horizontal.distance_to(direction * expected) > HAIR:
			violations.append(
				"tick %d of the swing: %s, expected %s" % [offset, horizontal, direction * expected]
			)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	assert_float(fighter.horizontal_speed()).is_equal_approx(SLOW_WALK_MPS, HAIR)


# Criterion 3: a jump, a dash or a grapple pressed during the swing waits in the slot and comes out
# on the first tick after the recovery, when still within the 150 ms; during the swing no command
# leaves the slot and the grapple asks for no aim (combate.md, "O leve no tick"; DEC-0051 §5).
func test_a_jump_a_dash_or_a_grapple_pressed_during_the_light_waits_and_fires_at_its_end(
	tickrate: int,
	command: StringName,
	ticks_before_the_end: int,
	_test_parameters := [
		[30, FighterCommand.JUMP, 1],
		[30, FighterCommand.JUMP, 5],
		[60, FighterCommand.JUMP, 1],
		[60, FighterCommand.JUMP, 9],
		[30, FighterCommand.DASH, 1],
		[30, FighterCommand.DASH, 5],
		[60, FighterCommand.DASH, 1],
		[60, FighterCommand.DASH, 9],
		[30, FighterCommand.GRAPPLE, 1],
		[30, FighterCommand.GRAPPLE, 5],
		[60, FighterCommand.GRAPPLE, 1],
		[60, FighterCommand.GRAPPLE, 9],
	],
) -> void:
	var fighter := _fighter(tickrate)
	var first := _fire(fighter)
	var end := first + _swing_ticks(tickrate)
	var press_tick := end - ticks_before_the_end
	var press := MovementRig.press_together(
		command == FighterCommand.JUMP,
		command == FighterCommand.DASH,
		command == FighterCommand.GRAPPLE,
	)
	var violations: Array[String] = []
	while fighter.tick() < end:
		var tick := fighter.tick()
		var plan := _step_checking_phase(
			fighter,
			press if tick == press_tick else CombatRig.idle(),
			first,
			violations,
		)
		var state := plan.state
		if state.jumps_used != 0 or state.mode != FighterState.Mode.GROUND:
			violations.append("tick %d: a command came out during the swing" % tick)
		if state.dash_tick != FighterState.NEVER or plan.aim_request:
			violations.append("tick %d: dashed or asked for the aim during the swing" % tick)
		if plan.velocity != Vector3.ZERO:
			violations.append("tick %d: moved without a push" % tick)
		if tick >= press_tick:
			_assert_slot(state, command, press_tick)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	var out := fighter.step(CombatRig.idle())
	_assert_none(out.state)
	match command:
		FighterCommand.JUMP:
			assert_int(out.state.jumps_used).override_failure_message("no jump at the end") \
					.is_equal(1)
			assert_float(out.velocity.y).is_equal_approx(fighter.config().jump_speed, HAIR)
			_assert_empty_slot(out.state)
		FighterCommand.DASH:
			assert_int(out.state.mode).override_failure_message("no dash at the end").is_equal(
				FighterState.Mode.DASH
			)
			assert_int(out.state.dash_tick).is_equal(end)
			_assert_empty_slot(out.state)
		FighterCommand.GRAPPLE:
			assert_bool(out.aim_request).override_failure_message("no aim asked at the end") \
					.is_true()


# Limit: a jump pressed one tick before the window reaches the swing's end is dropped (DEC-0039).
func test_a_command_pressed_during_the_light_past_the_buffer_is_dropped(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	var first := _fire(fighter)
	var end := first + _swing_ticks(tickrate)
	var press_tick := end - BUFFER_TICKS[tickrate] - 1
	while fighter.tick() < end:
		var input := MovementRig.press_jump() if fighter.tick() == press_tick else CombatRig.idle()
		fighter.step(input)
	var out := fighter.step(CombatRig.idle())
	_assert_none(out.state)
	assert_int(out.state.jumps_used).is_equal(0)
	assert_float(out.velocity.y).is_equal(0.0)
	_assert_empty_slot(out.state)


# Criterion 3: standing, a jump pressed early in the swing never comes out of the slot while the
# swing lasts, and leaves the slot when its window closes, long before the recovery ends.
func test_no_command_leaves_the_slot_during_the_light() -> void:
	var fighter := _fighter(60)
	var first := _fire(fighter)
	var press_tick := first + 2
	var dropped_at := press_tick + BUFFER_TICKS[60] + 1
	var violations: Array[String] = []
	for tick: int in range(first + 1, first + _swing_ticks(60)):
		var input := MovementRig.press_jump() if tick == press_tick else CombatRig.idle()
		var plan := _step_checking_phase(fighter, input, first, violations)
		if plan.state.jumps_used != 0 or plan.velocity.y != 0.0 or not fighter.state().on_floor:
			violations.append("tick %d: jumped during the swing" % tick)
		if tick >= press_tick and tick < dropped_at:
			_assert_slot(plan.state, FighterCommand.JUMP, press_tick)
		elif tick >= dropped_at:
			_assert_empty_slot(plan.state)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()


# Criterion 3, the tie: on one tick any movement key beats the light (combate.md, "O leve no tick":
# "A vaga dividida"; DEC-0051 §4): the slot keeps the movement command, which fires as it would
# alone, and the light press is gone, not waiting.
func test_on_one_tick_a_movement_key_beats_the_light(
	jump: bool,
	dash: bool,
	grapple: bool,
	winner: StringName,
	_test_parameters := [
		[true, false, false, FighterCommand.JUMP],
		[false, true, false, FighterCommand.DASH],
		[false, false, true, FighterCommand.GRAPPLE],
		[true, true, true, FighterCommand.JUMP],
		[false, true, true, FighterCommand.DASH],
	],
) -> void:
	var fighter := _fighter(60)
	var press_tick := fighter.tick()
	var plan := fighter.step(CombatRig.press_light_with(jump, dash, grapple))
	var fought := fighter.fought
	_assert_none(fought)
	_assert_slot(fought, winner, press_tick)
	_assert_none(plan.state)
	match winner:
		FighterCommand.JUMP:
			assert_int(plan.state.jumps_used).is_equal(1)
			assert_float(plan.velocity.y).is_equal_approx(fighter.config().jump_speed, HAIR)
			assert_int(plan.state.stamina_spent_tick).override_failure_message("the light paid") \
					.is_equal(FighterState.NEVER)
		FighterCommand.DASH:
			assert_int(plan.state.mode).is_equal(FighterState.Mode.DASH)
			assert_int(plan.state.dash_tick).is_equal(press_tick)
			assert_float(Stamina.at(plan.state, fighter.config(), press_tick)).is_equal_approx(
				STAMINA_MAX - DASH_COST,
				HAIR,
			)
		FighterCommand.GRAPPLE:
			assert_bool(plan.aim_request).is_true()
			assert_int(plan.state.stamina_spent_tick).override_failure_message("the light paid") \
					.is_equal(FighterState.NEVER)
	# The light is not waiting anywhere: the slot never fires it later.
	for _offset: int in BUFFER_TICKS[60] + 2:
		fighter.step(CombatRig.idle())
		_assert_none(fighter.fought)


# Criterion 7: during the windup the swing's direction follows the camera on every tick, and the
# body looks there; from the first active tick to the end of the recovery it stays as the camera
# was on the last tick of the windup, and the body looks there however the camera turns; on the
# end tick the body follows the camera again (combate.md, "O leve no tick": "A direção").
func test_the_arc_direction_is_the_cameras_on_the_last_windup_tick_and_then_fixed(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	var first := fighter.tick()
	var windup := WINDUP_TICKS[tickrate]
	var swing := _swing_ticks(tickrate)
	var fixed := FIRST_YAW + YAW_STEP * (windup - 1)
	var violations: Array[String] = []
	for offset: int in swing + 2:
		var yaw := FIRST_YAW + YAW_STEP * offset
		var input := (
			CombatRig.press_light(Vector2.ZERO, yaw)
			if offset == 0
			else CombatRig.idle(yaw)
		)
		var plan := _step_checking_phase(fighter, input, first, violations)
		var state := plan.state
		var arc := state.action_yaw
		var facing := state.facing_yaw
		if offset < windup:
			if absf(arc - yaw) > HAIR or absf(facing - yaw) > HAIR:
				violations.append(
					"windup tick %d: arc %.3f, facing %.3f, camera %.3f"
					% [offset, arc, facing, yaw]
				)
		elif offset < swing:
			if absf(arc - fixed) > HAIR or absf(facing - fixed) > HAIR:
				violations.append(
					"tick %d: arc %.3f, facing %.3f, expected both fixed at %.3f (camera %.3f)"
					% [offset, arc, facing, fixed, yaw]
				)
		elif absf(facing - yaw) > HAIR:
			violations.append(
				"tick %d: facing %.3f, camera %.3f after the swing" % [offset, facing, yaw]
			)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()


# The swing continues when the floor goes away under it: off a ledge the air's rules move the
# body and the phases run on (combate.md, "O leve no tick": "Saindo de uma beirada no meio do
# golpe, valem as regras do ar, e o golpe continua").
func test_the_light_continues_after_the_body_leaves_the_floor(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	var first := _fire(fighter)
	var violations: Array[String] = []
	for offset: int in range(1, _swing_ticks(tickrate) + 1):
		if offset == LEDGE_AT:
			fighter.rig.floor_on = false
		_step_checking_phase(fighter, CombatRig.idle(), first, violations)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	assert_int(fighter.state().mode).override_failure_message("still GROUND in the void") \
			.is_equal(FighterState.Mode.AIR)
	assert_float(fighter.feet().y).override_failure_message("did not fall").is_less(0.0)
