# Criterion 1 of TASK-12.2: the guard as an action of the fighter (DEC-0055 §1 and §2; DEC-0054;
# combate.md, "O bloqueio, a guarda andando e a stamina"), through the public interface of
# core/fighter with the whole tick sandwich played by the GuardRig. The guard button held standing
# on the floor makes the action BLOCK from that tick, the guard being up 6 ticks later (the block
# suite proves the 6 by a hit); with the guard the body walks at up to 3 m/s; releasing drops it at
# once; a jump, a dash, a grapple or a light drops it, and with the button still held it rises
# again on the first tick the body stands on the floor with no swing; in the air there is no guard.
# Every number comes from docs/design, cited by section; ticks by hand from the ms, nearest tick
# with ties up (visao-geral.md, "O tempo e a física no estado").
extends GdUnitTestSuite

const GuardRig := preload("res://test/core/fighter/guard_rig.gd")
const MovementRig := preload("res://test/core/fighter/movement_rig.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)
const LIGHT := &"light_attack" # the move's ID (glossario.md, "Golpe leve"; TASK-12.1 plan)

# combate.md, "O bloqueio, a guarda andando e a stamina": "Segurar a tecla levanta a guarda em
# 100 ms (6 ticks)"; by hand 3 ticks at 30.
const GUARD_RAISE_TICKS: Dictionary[int, int] = { 30: 3, 60: 6 }
# movimento.md, "Chão": "Andar devagar: com a guarda alta ou durante o carregado: 3 m/s";
# combate.md, "A guarda andando": "com a guarda alta, o corpo anda a até 3 m/s em qualquer
# direção".
const SLOW_WALK_MPS := 3.0
# movimento.md, "Chão": "Velocidade de corrida: 7 m/s"; "Tempo até a velocidade máxima: 150 ms",
# 9 ticks at 60 and 5 at 30, so a tick of full input moves the speed 7 / 9 = 0,778 m/s at 60 and
# 1,4 at 30 toward its target ("Deriva a aceleração").
const RUN_SPEED_MPS := 7.0
const ACCEL_TICKS: Dictionary[int, int] = { 30: 5, 60: 9 }
# combate.md, "Os golpes e as defesas", the row "Golpe leve": 250 / 100 / 200 ms, 8 de stamina
# (DEC-0052); by hand 15 / 6 / 12 ticks at 60 and 8 / 3 / 6 at 30: a swing of 33 or 17 ticks.
const SWING_TICKS: Dictionary[int, int] = { 30: 17, 60: 33 }
const LIGHT_COST := 8.0
const STAMINA_MAX := 100.0 # movimento.md, "Stamina": "Máximo"
# movimento.md, "Dash": "Duração": 200 ms is 12 ticks at 60 and 6 at 30.
const DASH_TICKS: Dictionary[int, int] = { 30: 6, 60: 12 }
# A point the grapple can bite, 6 m up and 8 m ahead: 10 m away, within the range of 25 m and
# beyond the minimum of 3 m (movimento.md, "Gancho"; test/core/fighter/movement_grapple_test.gd).
const POINT_UP_AHEAD := Vector3(0.0, 6.0, -8.0)

const FORWARD := Vector2(0, 1) # move.y goes forward: yaw 0 looks down -Z (TASK-9 plan)
const RIGHT := Vector2(1, 0)
const BACK := Vector2(0, -1)
const HAIR := 1e-6 # floating-point slack, not a design number
const HELD_TICKS := 30 # ticks a hold is watched: arithmetic
const YAW_STEP := 0.05 # rad per tick the camera turns: arithmetic
const SETTLE_TICKS := 10 # ticks of guard before a command drops it: arithmetic


func _fighter(tickrate: int) -> GuardRig:
	return GuardRig.new(
		&"A",
		MovementRig.load_config(tickrate),
		GuardRig.load_combat(tickrate),
		FIRST_TICK,
	)


func _action_name(state: FighterState) -> String:
	var name: Variant = FighterState.Action.find_key(state.action)
	return "%s since %d" % [name, state.action_since]


func _assert_action(state: FighterState, action: FighterState.Action, since: int) -> void:
	var message := "action %s, expected %s since %d" % [
		_action_name(state),
		FighterState.Action.find_key(action),
		since,
	]
	assert_int(state.action).override_failure_message(message).is_equal(action)
	assert_int(state.action_since).override_failure_message(message).is_equal(since)


func _assert_none(state: FighterState) -> void:
	var message := "action %s, expected NONE" % _action_name(state)
	assert_int(state.action).override_failure_message(message).is_equal(FighterState.Action.NONE)


func _horizontal(velocity: Vector3) -> Vector3:
	return Vector3(velocity.x, 0.0, velocity.z)


func _world_direction(move: Vector2, yaw: float) -> Vector3:
	return (Basis(Vector3.UP, yaw) * Vector3(move.x, 0.0, -move.y)).normalized()


# Holds the guard standing for `ticks` ticks from the next tick; returns the tick the hold began.
func _raise(fighter: GuardRig, ticks: int) -> int:
	var began := fighter.tick()
	for _tick: int in ticks:
		fighter.step(GuardRig.hold_guard())
		_assert_action(fighter.fought, FighterState.Action.BLOCK, began)
	return began


# Idles, the guard held, until the fighter lands; returns the landing tick, the one whose
# after_move saw the floor (the rig's own predicate: state().on_floor), and checks that no tick in
# the air had a guard.
func _hold_until_landed(fighter: GuardRig) -> int:
	for _step: int in range(1, 5 * fighter.config().tickrate + 1):
		fighter.step(GuardRig.hold_guard())
		var message := "tick %d: %s in the air" % [fighter.tick() - 1, _action_name(fighter.fought)]
		assert_int(fighter.fought.action).override_failure_message(message).is_equal(
			FighterState.Action.NONE
		)
		if fighter.state().on_floor:
			return fighter.tick() - 1
	fail("never landed at %d ticks" % fighter.config().tickrate)
	return 0


# None: a fresh state has no guard, no stun and no freeze (TASK-12.2 plan), the new actions come
# after RECOVERY, and the copy carries the new fields.
func test_a_fresh_state_has_no_guard_no_stun_and_no_freeze_and_the_copy_carries_them() -> void:
	var fighter := _fighter(60)
	var state := fighter.state()
	_assert_none(state)
	assert_int(state.stun_until_tick).is_equal(FighterState.NEVER)
	assert_int(state.block_tick).is_equal(FighterState.NEVER)
	assert_int(state.frozen_until_tick).is_equal(FighterState.NEVER)
	assert_int(FighterState.Action.BLOCK).is_greater(FighterState.Action.RECOVERY)
	assert_int(FighterState.Action.HITSTUN).is_greater(FighterState.Action.BLOCK)
	assert_int(FighterState.Action.BLOCKSTUN).is_greater(FighterState.Action.HITSTUN)
	assert_bool(TickInput.new().guard).override_failure_message("a fresh input holds the guard") \
			.is_false()
	assert_bool(MovePlan.new().frozen).override_failure_message("a fresh plan is frozen").is_false()
	state.action = FighterState.Action.BLOCKSTUN
	state.stun_until_tick = 7
	state.block_tick = 9
	state.frozen_until_tick = 11
	var copy := state.copy()
	assert_int(copy.action).is_equal(FighterState.Action.BLOCKSTUN)
	assert_int(copy.stun_until_tick).is_equal(7)
	assert_int(copy.block_tick).is_equal(9)
	assert_int(copy.frozen_until_tick).is_equal(11)
	copy.frozen_until_tick = FighterState.NEVER
	assert_int(state.frozen_until_tick).override_failure_message("the copy shares the state") \
			.is_equal(11)


# Criterion 1: held standing on the floor, the guard is the action BLOCK from the tick the hold
# began, kept with that tick while the button stays held (DEC-0055 §2: "BLOCK, com o tick em que
# começou a subir"); raising it costs nothing and freezes nothing. Without the button, no guard.
func test_holding_the_guard_standing_makes_the_action_block_from_that_tick(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	fighter.step(GuardRig.idle())
	_assert_none(fighter.fought)
	var began := _raise(fighter, HELD_TICKS)
	assert_int(began).is_equal(FIRST_TICK + 1)
	var state := fighter.state()
	_assert_action(state, FighterState.Action.BLOCK, began)
	assert_int(state.stamina_spent_tick).override_failure_message("the guard paid stamina") \
			.is_equal(FighterState.NEVER)
	assert_int(state.frozen_until_tick).is_equal(FighterState.NEVER)
	assert_bool(fighter.last_plan.frozen).is_false()
	assert_int(state.mode).is_equal(FighterState.Mode.GROUND)


# Criterion 1: releasing the button drops the guard on that very tick (combate.md: "soltar derruba
# na hora"), and holding it again starts a new rise from the new tick.
func test_releasing_the_button_drops_the_guard_at_once(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	_raise(fighter, GUARD_RAISE_TICKS[tickrate] + SETTLE_TICKS)
	var released := fighter.tick()
	var plan := fighter.step(GuardRig.idle())
	_assert_none(fighter.fought)
	_assert_none(plan.state)
	for _tick: int in 3:
		fighter.step(GuardRig.idle())
		_assert_none(fighter.fought)
	var again := fighter.tick()
	assert_int(again).is_greater(released)
	fighter.step(GuardRig.hold_guard())
	_assert_action(fighter.fought, FighterState.Action.BLOCK, again)


# Criterion 1: with the guard, a full push in any direction moves the body by the ground
# acceleration, 7 / 9 = 0,778 m/s per tick at 60 and 1,4 at 30, up to the slow walk of 3 m/s, never
# beyond it, from the first tick of the hold on (movimento.md, "Chão": "Andar devagar"; combate.md,
# "A guarda andando": "em qualquer direção").
func test_with_the_guard_the_body_walks_up_to_3_mps_in_any_direction(
	tickrate: int,
	move: Vector2,
	_test_parameters := [[30, FORWARD], [60, FORWARD], [60, RIGHT], [60, BACK]],
) -> void:
	var fighter := _fighter(tickrate)
	var accel := RUN_SPEED_MPS / ACCEL_TICKS[tickrate]
	var direction := _world_direction(move, 0.0)
	var began := fighter.tick()
	var violations: Array[String] = []
	for offset: int in GUARD_RAISE_TICKS[tickrate] + HELD_TICKS:
		var plan := fighter.step(GuardRig.hold_guard(move))
		if (
			fighter.fought.action != FighterState.Action.BLOCK
			or fighter.fought.action_since != began
		):
			violations.append("tick %d: %s" % [began + offset, _action_name(fighter.fought)])
		var expected := minf(SLOW_WALK_MPS, (offset + 1) * accel)
		var horizontal := _horizontal(plan.velocity)
		if horizontal.distance_to(direction * expected) > HAIR:
			violations.append(
				"tick %d of the guard: %s, expected %s" % [offset, horizontal, direction * expected]
			)
		if plan.velocity.y != 0.0:
			violations.append("tick %d of the guard: vertical %.3f" % [offset, plan.velocity.y])
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	assert_float(fighter.horizontal_speed()).is_equal_approx(SLOW_WALK_MPS, HAIR)


# Criterion 1: from the run of 7 m/s, holding the guard brings the speed down to 3 by the ground
# acceleration, 7 / 9 per tick at 60, and holds it there while the push goes on; there is no run
# with the guard (combate.md, "A guarda andando": "não há corrida com a guarda").
func test_holding_the_guard_at_a_run_slows_the_body_to_3_mps(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	for _tick: int in ACCEL_TICKS[tickrate] + 2:
		fighter.step(GuardRig.walk(FORWARD))
	assert_float(fighter.horizontal_speed()).is_equal_approx(RUN_SPEED_MPS, HAIR)
	var accel := RUN_SPEED_MPS / ACCEL_TICKS[tickrate]
	var direction := _world_direction(FORWARD, 0.0)
	var violations: Array[String] = []
	for offset: int in GUARD_RAISE_TICKS[tickrate] + HELD_TICKS:
		var plan := fighter.step(GuardRig.hold_guard(FORWARD))
		var expected := maxf(SLOW_WALK_MPS, RUN_SPEED_MPS - (offset + 1) * accel)
		var horizontal := _horizontal(plan.velocity)
		if horizontal.distance_to(direction * expected) > HAIR:
			violations.append(
				"tick %d of the guard: %s, expected %s" % [offset, horizontal, direction * expected]
			)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	assert_float(fighter.horizontal_speed()).is_equal_approx(SLOW_WALK_MPS, HAIR)
	# Released, the push runs the body again.
	var free := fighter.step(GuardRig.walk(FORWARD))
	_assert_none(free.state)
	assert_float(_horizontal(free.velocity).length()).is_greater(SLOW_WALK_MPS)


# Criterion 1 (DEC-0054 §3): with the guard up the body looks where the camera looks, so turning
# the camera turns the guard, on every tick.
func test_with_the_guard_the_body_looks_where_the_camera_looks() -> void:
	var fighter := _fighter(60)
	var violations: Array[String] = []
	for offset: int in GUARD_RAISE_TICKS[60] + HELD_TICKS:
		var yaw := YAW_STEP * offset
		var plan := fighter.step(GuardRig.hold_guard(Vector2.ZERO, yaw))
		if absf(plan.state.facing_yaw - yaw) > HAIR:
			violations.append(
				"tick %d: facing %.3f, camera %.3f" % [offset, plan.state.facing_yaw, yaw]
			)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()


# Criterion 1: in the air there is no guard (combate.md: "No ar não há guarda"): held through a
# whole jump the button raises nothing, and the guard rises on the first tick the body stands on
# the floor again, the one after the landing tick, from that tick.
func test_in_the_air_there_is_no_guard_and_it_rises_on_the_first_tick_standing(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	fighter.step(MovementRig.press_jump())
	_assert_none(fighter.fought)
	assert_int(fighter.state().mode).is_equal(FighterState.Mode.AIR)
	var landing_tick := _hold_until_landed(fighter)
	var first_floor_tick := landing_tick + 1
	assert_int(fighter.tick()).is_equal(first_floor_tick)
	fighter.step(GuardRig.hold_guard())
	_assert_action(fighter.fought, FighterState.Action.BLOCK, first_floor_tick)


# Criterion 1: on another fighter's head the body is in the air for the rules (movimento.md, "O
# corpo": "A cabeça do outro"; Movement.stands), so no guard rises there; it rises on the first
# tick standing on a floor of its own.
func test_on_another_fighters_head_there_is_no_guard() -> void:
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
	fighter.step(GuardRig.hold_guard())
	_assert_none(fighter.fought)
	# The rig has no head: its floor is a floor of the fighter's own, so the next tick stands.
	assert_bool(Movement.stands(fighter.state())).override_failure_message("still on the head") \
			.is_true()
	fighter.step(GuardRig.hold_guard())
	_assert_action(fighter.fought, FighterState.Action.BLOCK, press_tick + 1)


# Criterion 1: a jump pressed with the guard up comes out on its tick and drops the guard (DEC-0055
# §2: "o pulo, o dash e o gancho a derrubam no before_move"); held through the flight, the button
# raises nothing in the air, and the guard rises again on the first tick standing after the
# landing.
func test_a_jump_drops_the_guard_and_it_rises_again_after_the_landing(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	var began := _raise(fighter, GUARD_RAISE_TICKS[tickrate] + SETTLE_TICKS)
	var jump_tick := fighter.tick()
	var plan := fighter.step(GuardRig.guarding(MovementRig.press_jump()))
	# The combat's slice still saw the guard; the movement's slice fired the jump and dropped it.
	_assert_action(fighter.fought, FighterState.Action.BLOCK, began)
	_assert_none(plan.state)
	assert_int(plan.state.jumps_used).override_failure_message("no jump from the guard").is_equal(1)
	assert_float(plan.velocity.y).is_equal_approx(fighter.config().jump_speed, HAIR)
	var landing_tick := _hold_until_landed(fighter)
	assert_int(landing_tick).is_greater(jump_tick)
	var first_floor_tick := landing_tick + 1
	fighter.step(GuardRig.hold_guard())
	_assert_action(fighter.fought, FighterState.Action.BLOCK, first_floor_tick)


# Criterion 1: a dash pressed with the guard up comes out on its tick and drops the guard; in the
# dash the body is not on the ground for the rules (the mode DASH), so nothing rises; the dash ends
# in before_move of its exit tick, after the combat's slice (DEC-0041; DEC-0051 §2), so the guard
# rises on the tick after the exit, from that tick.
func test_a_dash_drops_the_guard_and_it_rises_again_after_the_exit(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	var began := _raise(fighter, GUARD_RAISE_TICKS[tickrate] + SETTLE_TICKS)
	var dash_tick := fighter.tick()
	var plan := fighter.step(GuardRig.guarding(MovementRig.press_dash_toward(FORWARD)))
	_assert_action(fighter.fought, FighterState.Action.BLOCK, began)
	_assert_none(plan.state)
	assert_int(plan.state.mode).override_failure_message("no dash from the guard").is_equal(
		FighterState.Mode.DASH
	)
	assert_int(plan.state.dash_tick).is_equal(dash_tick)
	var exit_tick := dash_tick + DASH_TICKS[tickrate]
	while fighter.tick() <= exit_tick:
		fighter.step(GuardRig.hold_guard())
		_assert_none(fighter.fought)
	assert_int(fighter.state().mode).override_failure_message("the dash did not end").is_equal(
		FighterState.Mode.GROUND
	)
	fighter.step(GuardRig.hold_guard())
	_assert_action(fighter.fought, FighterState.Action.BLOCK, exit_tick + 1)


# Criterion 1: the light fires from the guard and drops it (DEC-0055 §2: "O leve sai da guarda"),
# paying its 8 on that tick; the swing runs its 33 ticks with no guard in them, and with the button
# still held the guard rises again when the swing ends, on the end tick or the one after, with that
# tick as its start.
func test_a_light_drops_the_guard_and_it_rises_again_when_the_swing_ends(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	_raise(fighter, GUARD_RAISE_TICKS[tickrate] + SETTLE_TICKS)
	var press_tick := fighter.tick()
	fighter.step(GuardRig.guarding(GuardRig.press_light()))
	var fired := fighter.fought
	_assert_action(fired, FighterState.Action.WINDUP, press_tick)
	assert_str(String(fired.action_move)).is_equal(String(LIGHT))
	assert_int(fired.stamina_spent_tick).is_equal(press_tick)
	assert_float(Stamina.at(fired, fighter.config(), press_tick)).is_equal_approx(
		STAMINA_MAX - LIGHT_COST,
		HAIR,
	)
	var end := press_tick + SWING_TICKS[tickrate]
	var phases: Array[int] = []
	while fighter.tick() < end:
		fighter.step(GuardRig.hold_guard())
		var action := fighter.fought.action
		assert_int(action) \
				.override_failure_message("tick %d: %s during the swing"
		% [fighter.tick() - 1, _action_name(fighter.fought)]) \
				.is_not_equal(FighterState.Action.BLOCK)
		if phases.is_empty() or phases[phases.size() - 1] != action:
			phases.append(action)
	assert_array(phases).contains_exactly(
		[FighterState.Action.WINDUP, FighterState.Action.ACTIVE, FighterState.Action.RECOVERY]
	)
	fighter.step(GuardRig.hold_guard())
	fighter.step(GuardRig.hold_guard())
	var after := fighter.fought
	var message := "action %s after the swing's end at %d, expected BLOCK since %d or %d" % [
		_action_name(after),
		end,
		end,
		end + 1,
	]
	assert_int(after.action).override_failure_message(message).is_equal(FighterState.Action.BLOCK)
	assert_bool(after.action_since == end or after.action_since == end + 1) \
			.override_failure_message(message) \
			.is_true()


# Criterion 1: a grapple pressed with the guard up asks for the aim on its tick and, the hook
# biting, drops the guard: at the end of the tick the cable is out and the action is NONE
# (DEC-0055 §2; DEC-0044).
func test_a_grapple_drops_the_guard() -> void:
	var fighter := _fighter(60)
	var began := _raise(fighter, GUARD_RAISE_TICKS[60] + SETTLE_TICKS)
	fighter.rig.aim_hit = true
	fighter.rig.aim_point = POINT_UP_AHEAD
	var fire_tick := fighter.tick()
	var plan := fighter.step(GuardRig.guarding(MovementRig.press_grapple()))
	_assert_action(fighter.fought, FighterState.Action.BLOCK, began)
	assert_bool(plan.aim_request).override_failure_message("the guard refused the aim").is_true()
	var state := fighter.state()
	assert_int(state.grapple_fired_tick).override_failure_message("the hook did not bite") \
			.is_equal(fire_tick)
	_assert_none(state)
