# Criteria 1 and 4 of TASK-12.4: the guard break as a move (glossario.md, "Quebra de guarda";
# combate.md, "Os golpes e as defesas", "A lâmina e o contato" and "A quebra, o tech e a esquiva no
# tick"; DEC-0058 §2 and §7), through the public interface of core/fighter, with the whole tick
# sandwich played by the GrabRig and, for the contacts, rigs under a Duel with a TickPhoto taken on
# every tick. The windup of 21 ticks, the active of 6 and the recovery of 24; the 15 paid on the
# fire tick; the refusals that wait in the slot; the direction that follows the camera through the
# windup, 41,81° to its right, and stays from the first active tick; the slot order, parry over
# guard break over charged over light, any movement key over all; the hand, a straight segment at
# 1,3 m that advances 0,2 m per active tick up to 1,2 m and touches within 0,35 m of the target's
# axis: with the crosshair on the axis of a target standing on the same floor it grabs at 0,95 and
# 1,4 m centre to centre and misses at 0,85 and 1,55 m; and a light that lands in the windup stops
# the guard break, which has no armor. Every number comes from docs/design, cited by section; ticks
# by hand from the ms, nearest tick with ties up.
extends GdUnitTestSuite

const GrabRig := preload("res://test/core/fighter/grab_rig.gd")
const Player := preload("res://test/core/fighter/grab_player.gd")
const MovementRig := preload("res://test/core/fighter/movement_rig.gd")
const Duel := preload("res://test/core/fighter/duel.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)
const GUARD_BREAK := GrabRig.GUARD_BREAK
const LIGHT := &"light_attack" # glossario.md, "Golpe leve"
# The fighters by name, the photo's key (DEC-0051 §1).
const TARGET := &"A"
const ATTACKER := &"B"

# combate.md, "Os golpes e as defesas", the row "Quebra de guarda": 350 / 100 / 400 ms, "Em ticks:
# 21 / 6 / 24", "15, no início". By hand at 30: 350 ms are 10,5 ticks, the tie that goes up to 11
# (DEC-0022), 100 ms are 3 and 400 ms are 12. Fired at F, the windup is F..F+20, the active
# F+21..F+26, the recovery F+27..F+50, and the body is free on F + 51 ("As fases").
const WINDUP_MS := 350
const ACTIVE_MS := 100
const RECOVERY_MS := 400
const WINDUP_TICKS: Dictionary[int, int] = { 30: 11, 60: 21 }
const ACTIVE_TICKS: Dictionary[int, int] = { 30: 3, 60: 6 }
const RECOVERY_TICKS: Dictionary[int, int] = { 30: 12, 60: 24 }
const GUARD_BREAK_COST := 15.0
const BELOW_COST := 14.5 # a bar of 14,5 cannot pay the 15
# combate.md, "Parry": a parry that meets nothing occupies P..P+38 ("O parry no vazio": "acaba em
# P + 39").
const PARRY_WHIFF_TICKS := 39
# combate.md, "Os golpes e as defesas", the row "Golpe leve": 12 of damage, 8 of stamina; "O tranco
# e a vantagem": "Leve acerta: 400 ms, 24 ticks"; "O hitstop e o tremor": "Leve acerta: 4 ticks".
const LIGHT_DAMAGE := 12
const LIGHT_HITSTUN_TICKS := 24
const LIGHT_HITSTOP_TICKS := 4
# movimento.md, "Stamina": "Máximo: 100"; "Espera para recuperar: 800 ms", 48 ticks at 60 and 24
# at 30; "Recuperação: 30 pontos/s", 0,5 per tick at 60 and 1,0 at 30.
const STAMINA_MAX := 100.0
const STAMINA_WAIT_TICKS: Dictionary[int, int] = { 30: 24, 60: 48 }
const REGEN_PER_TICK: Dictionary[int, float] = { 30: 1.0, 60: 0.5 }
# movimento.md, "Perdão": the slot keeps a press 150 ms, 9 ticks at 60 and 5 at 30 (4,5, the tie
# up), inclusive (DEC-0039).
const BUFFER_TICKS: Dictionary[int, int] = { 30: 5, 60: 9 }
const DASH_COST := 15.0 # movimento.md, "Dash": "Custo"
const GUARD_RAISE_TICKS := 6 # combate.md, "O bloqueio": the guard rises in 100 ms
const MAX_HEALTH := 100 # partida.md, "A vida sem partida"

# combate.md, "A lâmina e o contato", the rows "Quebra de guarda", "Direção" and "Convergência";
# "A quebra, o tech e a esquiva no tick": "A mão" and "A direção e o corpo". The hand leaves the
# body's axis and reaches 1,2 m on the last active tick, 0,2 m per tick at 60; it touches within
# 0,35 m of the target's axis; it points at the point of the aim line 1,2 m from the axis, which
# with the shoulder of 0,8 m (movimento.md, "Câmera") turns it asin(0,8 / 1,2), 41,81°, to the
# right of the camera.
const SHOULDER_M := 0.8
const HAND_CONVERGENCE_M := 1.2
const HAND_STEP_M := 0.2
const HAND_TURN_DEG := 41.81
const TWO_DECIMALS := 0.01 # the degrees above are written to two decimals
const SWORD_CONVERGENCE_M := 2.0 # combate.md, "A lâmina e o contato": "Convergência", the sword
# "Com os dois no mesmo chão e a mira no eixo do alvo, a mão pega de 0,88 a 1,48 m de centro a
# centro; apontada reto para o alvo, até 1,55 m". Criterion 1: 0,95 and 1,4 m grab, 0,85 and 1,55 m
# miss; 1,2 m, where the hand crosses the aim line, grabs. Straight along the hand, 1,5 m grabs and
# 1,6 m misses.
const GRABS_AT_M: Array[float] = [0.95, 1.2, 1.4]
const MISSES_AT_M: Array[float] = [0.85, 1.55]
const STRAIGHT_GRAB_M := 1.5
const STRAIGHT_MISS_M := 1.6
# A target straight along the hand, d metres away, is touched by the first slice whose far end,
# 0,2 · k, comes within 0,35 m of its axis: 0,45 m on the 1st active tick (0,2 against 0,1 needed),
# 0,65 on the 2nd, 0,85 on the 3rd, 1,05 on the 4th, 1,25 on the 5th and 1,45 on the 6th, each
# 0,1 m clear of the slice before and of its own.
const STRAIGHT_M_BY_ACTIVE_TICK: Dictionary[int, float] = {
	1: 0.45,
	2: 0.65,
	3: 0.85,
	4: 1.05,
	5: 1.25,
	6: 1.45,
}

# Criterion 4. The light's attacker 2,3 m from the one who breaks, swinging back at it: its arc
# reaches an axis 2,3 m dead ahead on the third slice at 60 (combate.md, "O arco do leve": the
# slice of the tick k runs from -60° + 20°·(k - 1) to -60° + 20°·k; the third ends dead ahead, its
# corner 0,3 m from the axis, within the 0,43 of the touch, and the second ends 20° to the side,
# 0,79 m from it), so its contact comes 15 + 2 = 17 ticks after its press. The hand never reaches
# 2,3 m.
const LIGHT_FROM := Vector3(0.0, 0.0, -2.3)
const LIGHT_CONTACT_OFFSET := 17
const FACING_BACK := PI # looking toward +Z

const FORWARD := Vector2(0, 1) # move.y goes forward: yaw 0 looks down -Z (TASK-9 plan)
const HAIR := 1e-6 # floating-point slack, not a design number
const YAW_STEP := 0.05 # rad per tick the camera turns: arithmetic
const FIRST_YAW := 0.3 # rad, arithmetic
const SPARE_TICKS := 6 # ticks a run keeps going past the last event: arithmetic
const SETTLE_TICKS := 10 # ticks of guard before a command drops it: arithmetic
const PRESS_AFTER_START := 20 # ticks after FIRST_TICK the guard break is pressed: arithmetic
# Any feet and bearing off the axes, so a wrong component of the placement shows: arithmetic.
const ELSEWHERE := Vector3(3.0, 0.0, -2.0)
const BEARING := 2.1 # rad


func _fighter(
	tickrate: int,
	name: StringName = TARGET,
	feet := Vector3.ZERO,
	yaw := 0.0,
) -> GrabRig:
	return GrabRig.new(
		name,
		MovementRig.load_config(tickrate),
		GrabRig.load_combat(tickrate),
		FIRST_TICK,
		feet,
		yaw,
	)


func _swing_ticks(tickrate: int) -> int:
	return WINDUP_TICKS[tickrate] + ACTIVE_TICKS[tickrate] + RECOVERY_TICKS[tickrate]


func _phase_of(state: FighterState) -> String:
	if state.action == FighterState.Action.NONE:
		return "NONE"
	return "%s since %d with %s" % [
		GrabRig.action_name(state.action),
		state.action_since,
		state.action_move,
	]


# The phase a guard break fired at `first` is in at `tick`, as a line.
func _expected_phase(first: int, tick: int, tickrate: int) -> String:
	var active_from := first + WINDUP_TICKS[tickrate]
	var recovery_from := active_from + ACTIVE_TICKS[tickrate]
	var end := recovery_from + RECOVERY_TICKS[tickrate]
	if tick < first or tick >= end:
		return "NONE"
	if tick < active_from:
		return "WINDUP since %d with %s" % [first, GUARD_BREAK]
	if tick < recovery_from:
		return "ACTIVE since %d with %s" % [active_from, GUARD_BREAK]
	return "RECOVERY since %d with %s" % [recovery_from, GUARD_BREAK]


func _step_checking_phase(
	fighter: GrabRig,
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


func _assert_windup(state: FighterState, since: int, move: StringName = GUARD_BREAK) -> void:
	var message := "phase %s, expected WINDUP since %d with %s" % [_phase_of(state), since, move]
	assert_int(state.action).override_failure_message(message).is_equal(FighterState.Action.WINDUP)
	assert_int(state.action_since).override_failure_message(message).is_equal(since)
	assert_str(String(state.action_move)).override_failure_message(message).is_equal(String(move))


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


func _assert_no(violations: Array[String]) -> void:
	assert_array(violations).override_failure_message(GrabRig.brief(violations)).is_empty()


# Fires a guard break now and returns the tick it fired on.
func _fire(fighter: GrabRig, input: TickInput = GrabRig.press_guard_break()) -> int:
	var first := fighter.tick()
	fighter.step(input)
	_assert_windup(fighter.fought, first)
	return first


# Idles until the fighter lands; returns the landing tick, the one whose after_move saw the floor
# (the rig's own predicate: state().on_floor).
func _idle_until_landed(fighter: GrabRig) -> int:
	for _step: int in range(1, 5 * fighter.config().tickrate + 1):
		fighter.step(GrabRig.idle())
		if fighter.state().on_floor:
			return fighter.tick() - 1
	fail("never landed at %d ticks" % fighter.config().tickrate)
	return 0


func _landing_tick_of_a_jump(tickrate: int) -> int:
	var fighter := _fighter(tickrate)
	fighter.step(MovementRig.press_jump())
	return _idle_until_landed(fighter)


# The camera's yaw that sends the hand along `direction`: asin(0,8 / 1,2) to the left of it.
func _camera_for_hand(direction: float) -> float:
	return GrabRig.camera_for(direction, SHOULDER_M, HAND_CONVERGENCE_M)


# The horizontal direction of a yaw: yaw 0 looks down -Z, a positive yaw turns left (TASK-9 plan).
func _direction(yaw: float) -> Vector3:
	return Vector3(-sin(yaw), 0.0, -cos(yaw))


# The camera's yaw that puts the aim line of a fighter at `feet` on the axis of a target at
# `target`, as the attacking dummy aims (combate.md, "A espada na mira": "o yaw dos pés deles aos
# pés do outro mais asen(ombro / distância)").
func _aim_at(feet: Vector3, target: Vector3) -> float:
	var step := Vector3(target.x - feet.x, 0.0, target.z - feet.z)
	return atan2(-step.x, -step.z) + asin(SHOULDER_M / step.length())


# The target standing still at target_feet, index 0, and the attacker at attacker_feet with the
# camera on camera_yaw, pressing the guard break PRESS_AFTER_START ticks in, index 1; run to past
# the swing's end.
func _break_at(attacker_feet: Vector3, camera_yaw: float, target_feet: Vector3) -> Duel:
	var duel := Duel.new()
	var target := Player.new(FACING_BACK)
	var attacker := Player.new(camera_yaw)
	attacker.press(_press_tick(), GUARD_BREAK)
	duel.add(_fighter(60, TARGET, target_feet, FACING_BACK), target.input)
	duel.add(_fighter(60, ATTACKER, attacker_feet, camera_yaw), attacker.input)
	duel.run_through(_press_tick() + _swing_ticks(60) + SPARE_TICKS)
	return duel


func _press_tick() -> int:
	return FIRST_TICK + PRESS_AFTER_START


# The hand touched the target once, on an active tick, by the core's own stamp, the target is
# GRABBED on the tick after the contact with the contact in its grabbed_tick, and the attacker is
# GRABBING two ticks after it (DEC-0058 §4). Returns the contact tick.
func _assert_grabbed(duel: Duel, where: String) -> int:
	var first_active := _press_tick() + WINDUP_TICKS[60]
	var last_active := first_active + ACTIVE_TICKS[60] - 1
	var contact := duel.contact_tick_of(1)
	var message := "%s: contact at %d, expected one from %d to %d" % [
		where,
		contact,
		first_active,
		last_active,
	]
	assert_int(contact).override_failure_message(message).is_between(first_active, last_active)
	if contact < first_active or contact > last_active:
		return contact
	var stamped := duel.row_at(contact).fought[1]
	assert_str(String(stamped.contact_target)).override_failure_message(message).is_equal(
		String(TARGET)
	)
	assert_str(String(stamped.contact_move)).override_failure_message(message).is_equal(
		String(GUARD_BREAK)
	)
	var held := duel.row_at(contact + 1).fought[0]
	var held_line := "%s: the target at %d is %s" % [where, contact + 1, GrabRig.line(held)]
	assert_bool(GrabRig.is_grabbed(held)).override_failure_message(held_line).is_true()
	assert_int(GrabRig.grabbed_tick(held)).override_failure_message(held_line).is_equal(contact)
	assert_int(held.health).override_failure_message(held_line).is_equal(MAX_HEALTH)
	var holder := duel.row_at(contact + 2).fought[1]
	assert_bool(GrabRig.is_grabbing(holder)) \
			.override_failure_message("%s: the attacker at %d is %s"
	% [where, contact + 2, GrabRig.line(holder)]) \
			.is_true()
	return contact


# The hand touched nobody: no stamp on any tick, the target is never GRABBED, nobody freezes, and
# the attacker is free on F + 51 ("No vazio": the guard break recovers in 400 ms).
func _assert_missed(duel: Duel, where: String) -> void:
	var contact := duel.contact_tick_of(1)
	assert_int(contact).override_failure_message("%s: contact at %d, expected none"
	% [where, contact]) \
			.is_equal(FighterState.NEVER)
	var violations: Array[String] = []
	for row: Duel.Row in duel.rows:
		if GrabRig.is_grabbed(row.fought[0]):
			violations.append("%s, tick %d: the target is GRABBED" % [where, row.tick])
		if GrabRig.is_grabbing(row.fought[1]):
			violations.append("%s, tick %d: the attacker is GRABBING" % [where, row.tick])
		if row.plans[0].frozen or row.plans[1].frozen:
			violations.append("%s, tick %d: somebody froze" % [where, row.tick])
	_assert_no(violations)
	assert_int(GrabRig.free_tick(duel, 1, _press_tick() + 1)).is_equal(
		_press_tick() + _swing_ticks(60)
	)


# None: a fresh state has no grab stamps, the two new actions come after PARRIED, at the end of the
# enum, a fresh input does not touch the guard break, the command carries the design's name, and
# the copy carries the new stamps (DEC-0058 §1).
func test_a_fresh_state_has_no_grab_stamps_and_the_new_actions_come_at_the_end() -> void:
	var state := _fighter(60).state()
	_assert_none(state)
	assert_int(GrabRig.grabbed_tick(state)).override_failure_message("no state.grabbed_tick") \
			.is_equal(FighterState.NEVER)
	assert_int(GrabRig.tech_tick(state)).override_failure_message("no FighterState.tech_tick") \
			.is_equal(FighterState.NEVER)
	assert_int(GrabRig.grabbing()).override_failure_message("no FighterState.Action.GRABBING") \
			.is_greater(FighterState.Action.PARRIED)
	assert_int(GrabRig.grabbed()).override_failure_message("no FighterState.Action.GRABBED") \
			.is_greater(FighterState.Action.PARRIED)
	assert_int(GrabRig.grabbed()).is_not_equal(GrabRig.grabbing())
	assert_bool(GrabRig.has_touch()).override_failure_message("no TickInput.guard_break").is_true()
	assert_bool(GrabRig.touches_guard_break(TickInput.new())) \
			.override_failure_message("a fresh input breaks the guard") \
			.is_false()
	assert_str(String(GrabRig.command())).override_failure_message("no command GUARD_BREAK") \
			.is_equal(String(GUARD_BREAK))
	state.set(GrabRig.GRABBED_TICK, 7)
	state.set(GrabRig.TECH_TICK, 9)
	var copy := state.copy()
	assert_int(GrabRig.grabbed_tick(copy)).is_equal(7)
	assert_int(GrabRig.tech_tick(copy)).is_equal(9)
	copy.set(GrabRig.GRABBED_TICK, FighterState.NEVER)
	assert_int(GrabRig.grabbed_tick(state)).override_failure_message("the copy shares the state") \
			.is_equal(7)


# Criterion 1, the conversion and its rounding: the ticks of each phase by hand against the config
# the move runs on. 350 ms are 21 ticks at 60 and 10,5 at 30, the tie that goes up to 11; 100 ms
# are 6 and 3; 400 ms are 24 and 12; the cost is 15 (combate.md, "Os golpes e as defesas").
func test_the_phases_follow_the_config_made_from_combat_v0(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	assert_int(Ticks.from_ms(WINDUP_MS, tickrate)).is_equal(WINDUP_TICKS[tickrate])
	assert_int(Ticks.from_ms(ACTIVE_MS, tickrate)).is_equal(ACTIVE_TICKS[tickrate])
	assert_int(Ticks.from_ms(RECOVERY_MS, tickrate)).is_equal(RECOVERY_TICKS[tickrate])
	var combat := GrabRig.load_combat(tickrate)
	assert_bool(combat.attacks.has(GUARD_BREAK)).override_failure_message("no guard break in the "
	+ "combat's attacks") \
			.is_true()
	if not combat.attacks.has(GUARD_BREAK):
		return
	var guard_break: AttackConfig = combat.attacks[GUARD_BREAK]
	assert_int(guard_break.windup_ticks).is_equal(WINDUP_TICKS[tickrate])
	assert_int(guard_break.active_ticks).is_equal(ACTIVE_TICKS[tickrate])
	assert_int(guard_break.recovery_ticks).is_equal(RECOVERY_TICKS[tickrate])
	assert_float(guard_break.stamina_cost).is_equal_approx(GUARD_BREAK_COST, HAIR)


# Criterion 1: standing on the floor with no swing and a full bar, the press fires the guard break
# on its own tick, and the action goes through the windup of 21, the active of 6 and the recovery
# of 24, each counted from the tick it began, NONE again on F + 51 (combate.md, "As fases"):
# 11 / 3 / 12 at 30. Alone, it touches nobody and freezes on no tick.
func test_the_guard_break_runs_windup_active_and_recovery_tick_by_tick(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	var first := fighter.tick()
	var violations: Array[String] = []
	for offset: int in _swing_ticks(tickrate) + 3:
		var input := GrabRig.press_guard_break() if offset == 0 else GrabRig.idle()
		var plan := _step_checking_phase(fighter, input, first, violations)
		if plan.frozen:
			violations.append("tick %d: frozen alone" % (first + offset))
		if fighter.fought.contact_tick != FighterState.NEVER:
			violations.append("tick %d: a contact alone" % (first + offset))
	_assert_no(violations)
	_assert_empty_slot(fighter.state())
	assert_int(fighter.fought.mode).is_equal(FighterState.Mode.GROUND)


# Criterion 1: the 15 leave on the fire tick and never again through the move (combate.md, "Quando
# a quebra sai": "Custa 15 de stamina, pagos no disparo").
func test_the_guard_break_pays_15_on_its_fire_tick_and_nothing_after(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	assert_float(fighter.stamina()).is_equal_approx(STAMINA_MAX, HAIR)
	var first := _fire(fighter)
	assert_int(fighter.fought.stamina_spent_tick).is_equal(first)
	assert_float(Stamina.at(fighter.fought, fighter.config(), first)).is_equal_approx(
		STAMINA_MAX - GUARD_BREAK_COST,
		HAIR,
	)
	var violations: Array[String] = []
	for tick: int in range(first + 1, first + _swing_ticks(tickrate) + 1):
		fighter.step(GrabRig.idle())
		if fighter.fought.stamina_spent_tick != first:
			violations.append("tick %d: paid at %d" % [tick, fighter.fought.stamina_spent_tick])
	_assert_no(violations)


# Criterion 1, the failure: with less than 15 on the bar the guard break does not come out and
# nothing is paid; the press waits in the slot and fires on the first tick the bar reads 15, inside
# the 150 ms, paying there (combate.md, "Quando a quebra sai": "sem eles, o aperto espera na vaga
# pelos 150 ms"; movimento.md, "Stamina" and "Perdão").
func test_a_press_without_15_stamina_waits_in_the_slot_and_fires_when_the_bar_can_pay(
	tickrate: int,
	ticks_ahead: int,
	_test_parameters := [[30, 1], [30, 5], [60, 1], [60, 9]],
) -> void:
	var fighter := _fighter(tickrate)
	var press_tick := fighter.tick()
	var stamp := press_tick + ticks_ahead - STAMINA_WAIT_TICKS[tickrate] - 1
	fighter.state().stamina_at_spend = BELOW_COST
	fighter.state().stamina_spent_tick = stamp
	assert_float(fighter.stamina()).is_equal_approx(BELOW_COST, HAIR)
	fighter.step(GrabRig.press_guard_break())
	_assert_none(fighter.fought)
	_assert_slot(fighter.fought, GUARD_BREAK, press_tick)
	for _offset: int in range(1, ticks_ahead):
		fighter.step(GrabRig.idle())
		_assert_none(fighter.fought)
		_assert_slot(fighter.fought, GUARD_BREAK, press_tick)
		assert_int(fighter.fought.stamina_spent_tick).is_equal(stamp)
	var fire_tick := press_tick + ticks_ahead
	assert_int(fighter.tick()).is_equal(fire_tick)
	var bar_at_fire := fighter.stamina()
	assert_float(bar_at_fire).is_equal_approx(BELOW_COST + REGEN_PER_TICK[tickrate], HAIR)
	fighter.step(GrabRig.idle())
	_assert_windup(fighter.fought, fire_tick)
	_assert_empty_slot(fighter.fought)
	assert_int(fighter.fought.stamina_spent_tick).is_equal(fire_tick)
	assert_float(Stamina.at(fighter.fought, fighter.config(), fire_tick)).is_equal_approx(
		bar_at_fire - GUARD_BREAK_COST,
		HAIR,
	)


# Limit: with exactly 15 on the bar the guard break fires at once and the bar reads 0.
func test_with_exactly_15_stamina_the_guard_break_fires_and_the_bar_reads_0() -> void:
	var fighter := _fighter(60)
	var press_tick := fighter.tick()
	fighter.state().stamina_at_spend = GUARD_BREAK_COST
	fighter.state().stamina_spent_tick = press_tick - 1
	fighter.step(GrabRig.press_guard_break())
	_assert_windup(fighter.fought, press_tick)
	assert_float(Stamina.at(fighter.fought, fighter.config(), press_tick)).is_equal_approx(
		0.0,
		HAIR,
	)


# Limit: a bar that reaches 15 one tick past the window never fires the guard break, and the slot
# lets the press go (DEC-0039).
func test_a_press_without_stamina_past_the_buffer_never_fires() -> void:
	var tickrate := 60
	var fighter := _fighter(tickrate)
	var press_tick := fighter.tick()
	var ticks_ahead := BUFFER_TICKS[tickrate] + 1
	var stamp := press_tick + ticks_ahead - STAMINA_WAIT_TICKS[tickrate] - 1
	fighter.state().stamina_at_spend = BELOW_COST
	fighter.state().stamina_spent_tick = stamp
	fighter.step(GrabRig.press_guard_break())
	for _offset: int in range(1, ticks_ahead):
		fighter.step(GrabRig.idle())
		_assert_none(fighter.fought)
		_assert_slot(fighter.fought, GUARD_BREAK, press_tick)
	for _offset: int in 5:
		fighter.step(GrabRig.idle())
		_assert_none(fighter.fought)
		_assert_empty_slot(fighter.fought)
		assert_int(fighter.fought.stamina_spent_tick).is_equal(stamp)


# Criterion 1: in the air the guard break does not come out (combate.md, "Quando a quebra sai":
# "como o leve: em pé no chão"): the press waits in the slot and fires on the first tick that
# starts on the floor, pressed at the limit of the window before it or on the landing tick itself.
func test_a_press_in_the_air_waits_in_the_slot_and_fires_on_the_first_tick_on_the_floor(
	ticks_before_the_first_floor_tick: int,
	_test_parameters := [[1], [9]],
) -> void:
	var tickrate := 60
	var landing_tick := _landing_tick_of_a_jump(tickrate)
	var fighter := _fighter(tickrate)
	fighter.step(MovementRig.press_jump())
	var first_floor_tick := landing_tick + 1
	var press_tick := first_floor_tick - ticks_before_the_first_floor_tick
	assert_int(press_tick).is_greater(FIRST_TICK)
	while fighter.tick() < first_floor_tick:
		var tick := fighter.tick()
		var input := GrabRig.press_guard_break() if tick == press_tick else GrabRig.idle()
		fighter.step(input)
		_assert_none(fighter.fought)
		if tick >= press_tick:
			_assert_slot(fighter.fought, GUARD_BREAK, press_tick)
	assert_bool(fighter.state().on_floor).override_failure_message("not landed yet").is_true()
	fighter.step(GrabRig.idle())
	_assert_windup(fighter.fought, first_floor_tick)
	_assert_empty_slot(fighter.fought)


# Criterion 1: with a light in progress the guard break waits in the slot and fires on the first
# tick after the light's recovery, when still within the 150 ms ("Quando a quebra sai": "sem
# golpe"). The light is 15 / 6 / 12 ticks, 33 in all (combate.md, "Os golpes e as defesas").
func test_a_press_during_a_light_waits_and_fires_on_the_first_tick_after_its_recovery() -> void:
	var fighter := _fighter(60)
	var light_tick := fighter.tick()
	fighter.step(GrabRig.press_light())
	_assert_windup(fighter.fought, light_tick, LIGHT)
	var end := light_tick + 33
	var press_tick := end - 1
	while fighter.tick() < end:
		var tick := fighter.tick()
		var input := GrabRig.press_guard_break() if tick == press_tick else GrabRig.idle()
		fighter.step(input)
		assert_str(String(fighter.fought.action_move)).is_equal(String(LIGHT))
		if tick >= press_tick:
			_assert_slot(fighter.fought, GUARD_BREAK, press_tick)
	fighter.step(GrabRig.idle())
	_assert_windup(fighter.fought, end)
	_assert_empty_slot(fighter.fought)


# Criterion 1 ("Quando a quebra sai": "Sai da guarda também, que cai"): the guard break fires from
# the raised guard and drops it; the move runs with no guard in it.
func test_the_guard_break_fires_from_the_guard_which_falls() -> void:
	var tickrate := 60
	var fighter := _fighter(tickrate)
	for _tick: int in GUARD_RAISE_TICKS + SETTLE_TICKS:
		fighter.step(GrabRig.hold_guard())
		assert_int(fighter.fought.action).is_equal(FighterState.Action.BLOCK)
	var press_tick := fighter.tick()
	fighter.step(GrabRig.guarding(GrabRig.press_guard_break()))
	_assert_windup(fighter.fought, press_tick)
	var end := press_tick + _swing_ticks(tickrate)
	var violations: Array[String] = []
	while fighter.tick() < end:
		_step_checking_phase(fighter, GrabRig.hold_guard(), press_tick, violations)
	_assert_no(violations)


# Criterion 1: no input cuts the sequence (DEC-0016; "As fases": "pelo relógio do leve"): a jump, a
# dash, a light, a charged, a parry and another guard break during the move, none within the buffer
# of its end, leave the phases as they are, start no maneuver and pay nothing more.
func test_no_input_cuts_the_guard_break() -> void:
	var tickrate := 60
	var fighter := _fighter(tickrate)
	var first := _fire(fighter)
	var swing := _swing_ticks(tickrate)
	var presses: Dictionary[int, TickInput] = {
		2: MovementRig.press_jump_toward(FORWARD),
		4: GrabRig.press_parry(),
		6: GrabRig.press_guard_break(),
		10: MovementRig.press_dash_toward(FORWARD),
		22: GrabRig.press_charged(),
		24: GrabRig.press_guard(),
		30: GrabRig.press_light(FORWARD),
	}
	for offset: int in presses:
		assert_int(swing - offset).override_failure_message("press %d is in the buffer" % offset) \
				.is_greater(BUFFER_TICKS[tickrate])
	var violations: Array[String] = []
	for offset: int in range(1, swing + 1):
		var tick := first + offset
		var input := presses[offset] if presses.has(offset) else GrabRig.idle()
		_step_checking_phase(fighter, input, first, violations)
		var state := fighter.fought
		if state.jumps_used != 0 or state.mode != FighterState.Mode.GROUND:
			violations.append("tick %d: jumped or left GROUND" % tick)
		if state.dash_tick != FighterState.NEVER:
			violations.append("tick %d: dashed" % tick)
		if state.stamina_spent_tick != first:
			violations.append("tick %d: paid at %d" % [tick, state.stamina_spent_tick])
	_assert_no(violations)
	fighter.step(GrabRig.idle())
	_assert_none(fighter.fought)


# Criterion 1 ("A direção e o corpo": "a direção segue a câmera em cada tick da preparação, rumo ao
# ponto da linha da mira a 1,2 m [...] e fica fixa do primeiro tick ativo ao fim"): the hand's
# direction and the body follow the camera through the windup, asin(shoulder / 1,2) to the right of
# it, stay as the camera made them on the last windup tick from the first active tick to the end of
# the recovery, and the body follows the camera again on the end tick.
func test_the_hand_direction_is_the_cameras_on_the_last_windup_tick_and_then_fixed() -> void:
	var tickrate := 60
	var fighter := _fighter(tickrate)
	var first := fighter.tick()
	var windup := WINDUP_TICKS[tickrate]
	var swing := _swing_ticks(tickrate)
	var turn := asin(fighter.config().aim_side / HAND_CONVERGENCE_M)
	var fixed := FIRST_YAW + YAW_STEP * (windup - 1) - turn
	var violations: Array[String] = []
	for offset: int in swing + 2:
		var yaw := FIRST_YAW + YAW_STEP * offset
		var input := (
			GrabRig.press_guard_break(Vector2.ZERO, yaw) if offset == 0 else GrabRig.idle(yaw)
		)
		var plan := _step_checking_phase(fighter, input, first, violations)
		var state := plan.state
		if offset < windup:
			var along := yaw - turn
			if absf(state.action_yaw - along) > HAIR or absf(state.facing_yaw - along) > HAIR:
				violations.append(
					"windup tick %d: hand %.3f, facing %.3f, expected %.3f (camera %.3f)"
					% [offset, state.action_yaw, state.facing_yaw, along, yaw]
				)
		elif offset < swing:
			if absf(state.action_yaw - fixed) > HAIR or absf(state.facing_yaw - fixed) > HAIR:
				violations.append(
					"tick %d: hand %.3f, facing %.3f, expected both fixed at %.3f (camera %.3f)"
					% [offset, state.action_yaw, state.facing_yaw, fixed, yaw]
				)
		elif absf(state.facing_yaw - yaw) > HAIR:
			violations.append(
				"tick %d: facing %.3f, camera %.3f after the move" % [offset, state.facing_yaw, yaw]
			)
	_assert_no(violations)


# Criterion 1 ("A direção e o corpo": "Com o ombro de 0,8 m, ela gira ≈ 41,81° para a direita do
# yaw da câmera"; F-209): the turn in degrees, to the two decimals of the design, with the shoulder
# the movement config carries; the sword's 23,58° would be the convergence of 2,0 m.
func test_the_hand_points_41_81_degrees_to_the_right_of_the_camera() -> void:
	var fighter := _fighter(60)
	assert_float(fighter.config().aim_side).is_equal_approx(SHOULDER_M, HAIR)
	fighter.step(GrabRig.press_guard_break(Vector2.ZERO, FIRST_YAW))
	_assert_windup(fighter.fought, FIRST_TICK)
	var turned := rad_to_deg(FIRST_YAW - fighter.fought.action_yaw)
	assert_float(turned).is_equal_approx(HAND_TURN_DEG, TWO_DECIMALS)
	assert_float(rad_to_deg(asin(SHOULDER_M / HAND_CONVERGENCE_M))).is_equal_approx(
		HAND_TURN_DEG,
		TWO_DECIMALS,
	)


# The slot on one tick ("A vaga": "o parry vence a quebra, que vence o carregado, que vence o
# leve"; DEC-0058 §7): the winner fires on its tick and the losers are gone, not waiting: nothing
# else fires after the winner ends, and only the winner is paid for.
func test_on_one_tick_the_parry_beats_the_guard_break_which_beats_the_charged_and_the_light(
	charged: bool,
	parry: bool,
	light: bool,
	winner: StringName,
	_test_parameters := [
		[true, false, false, GUARD_BREAK],
		[false, false, true, GUARD_BREAK],
		[true, false, true, GUARD_BREAK],
		[false, true, false, FighterCommand.PARRY],
		[true, true, true, FighterCommand.PARRY],
	],
) -> void:
	var tickrate := 60
	var fighter := _fighter(tickrate)
	var press_tick := fighter.tick()
	fighter.step(GrabRig.touching(GrabRig.press_many(charged, parry, light), GUARD_BREAK))
	var fought := fighter.fought
	_assert_empty_slot(fought)
	var busy_until := press_tick
	if winner == GUARD_BREAK:
		_assert_windup(fought, press_tick)
		busy_until = press_tick + _swing_ticks(tickrate)
	else:
		assert_int(fought.action).override_failure_message(_phase_of(fought)).is_equal(
			FighterState.Action.PARRY
		)
		assert_int(fought.action_since).is_equal(press_tick)
		busy_until = press_tick + PARRY_WHIFF_TICKS
	# Both winners cost 15, paid on the press tick; no loser is paid for.
	assert_float(Stamina.at(fought, fighter.config(), press_tick)).is_equal_approx(
		STAMINA_MAX - GUARD_BREAK_COST,
		HAIR,
	)
	while fighter.tick() < busy_until:
		fighter.step(GrabRig.idle())
		assert_int(fighter.fought.action).override_failure_message("tick %d: %s"
		% [fighter.tick() - 1, _phase_of(fighter.fought)]) \
				.is_not_equal(FighterState.Action.NONE)
		assert_int(fighter.fought.stamina_spent_tick).is_equal(press_tick)
	for _offset: int in BUFFER_TICKS[tickrate] + 2:
		fighter.step(GrabRig.idle())
		_assert_none(fighter.fought)
		_assert_empty_slot(fighter.fought)


# The slot on one tick: any movement key beats the guard break ("A vaga": "qualquer tecla de
# movimento vence todos"; DEC-0051 §4): the movement command fires as it would alone, nothing is
# paid for the guard break, and it never fires later.
func test_on_one_tick_a_movement_key_beats_the_guard_break(
	jump: bool,
	dash: bool,
	grapple: bool,
	winner: StringName,
	_test_parameters := [
		[true, false, false, FighterCommand.JUMP],
		[false, true, false, FighterCommand.DASH],
		[false, false, true, FighterCommand.GRAPPLE],
		[true, true, true, FighterCommand.JUMP],
	],
) -> void:
	var fighter := _fighter(60)
	var press_tick := fighter.tick()
	var input := GrabRig.touching(
		GrabRig.press_many(false, false, false, jump, dash, grapple),
		GUARD_BREAK,
	)
	var plan := fighter.step(input)
	_assert_none(fighter.fought)
	_assert_slot(fighter.fought, winner, press_tick)
	_assert_none(plan.state)
	match winner:
		FighterCommand.JUMP:
			assert_int(plan.state.jumps_used).is_equal(1)
			assert_float(plan.velocity.y).is_equal_approx(fighter.config().jump_speed, HAIR)
			assert_int(plan.state.stamina_spent_tick).override_failure_message("the loser paid") \
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
			assert_int(plan.state.stamina_spent_tick).override_failure_message("the loser paid") \
					.is_equal(FighterState.NEVER)
	for _offset: int in BUFFER_TICKS[60] + 2:
		fighter.step(GrabRig.idle())
		assert_int(fighter.fought.action) \
				.override_failure_message("the guard break fired later: %s"
		% _phase_of(fighter.fought)) \
				.is_not_equal(FighterState.Action.WINDUP)


# Criterion 1: with the crosshair on the axis of a target standing on the same floor, the hand
# grabs at 0,95 m, at 1,2 m and at 1,4 m centre to centre ("A mão": "a mão pega de 0,88 a 1,48 m
# de centro a centro"; F-209), from any feet and any bearing. The camera's yaw is the one the
# attacking dummy sends: the feet-to-feet yaw plus asin(shoulder / distance).
func test_with_the_crosshair_on_the_targets_axis_the_hand_grabs_from_0_95_to_1_4_m(
	attacker_feet: Vector3,
	bearing: float,
	_test_parameters := [[Vector3.ZERO, 0.0], [ELSEWHERE, BEARING]],
) -> void:
	for distance: float in GRABS_AT_M:
		var target_feet := attacker_feet + _direction(bearing) * distance
		var duel := _break_at(attacker_feet, _aim_at(attacker_feet, target_feet), target_feet)
		_assert_grabbed(duel, "crosshair on the axis %.2f m away" % distance)


# Criterion 1, the limits: with the crosshair on the axis, at 0,85 m the hand passes beside the
# target, which stands nearer than the hand's line reaches the aim line, and at 1,55 m it stops
# short of it; both miss, and the guard break recovers.
func test_with_the_crosshair_on_the_targets_axis_the_hand_misses_at_0_85_m_and_at_1_55_m(
	attacker_feet: Vector3,
	bearing: float,
	_test_parameters := [[Vector3.ZERO, 0.0], [ELSEWHERE, BEARING]],
) -> void:
	for distance: float in MISSES_AT_M:
		var target_feet := attacker_feet + _direction(bearing) * distance
		var duel := _break_at(attacker_feet, _aim_at(attacker_feet, target_feet), target_feet)
		_assert_missed(duel, "crosshair on the axis %.2f m away" % distance)


# Criterion 1 ("A mão": "apontada reto para o alvo, até 1,55 m": the 1,2 m of the hand plus the
# 0,35 m of the capsule): straight along the hand, a target 1,5 m away is grabbed and one 1,6 m
# away is missed; and one behind the attacker is never touched.
func test_straight_along_the_hand_it_reaches_1_5_m_and_not_1_6_m() -> void:
	var camera := _camera_for_hand(BEARING)
	var near := ELSEWHERE + _direction(BEARING) * STRAIGHT_GRAB_M
	_assert_grabbed(_break_at(ELSEWHERE, camera, near), "1,5 m straight along the hand")
	var far := ELSEWHERE + _direction(BEARING) * STRAIGHT_MISS_M
	_assert_missed(_break_at(ELSEWHERE, camera, far), "1,6 m straight along the hand")
	var behind := ELSEWHERE - _direction(BEARING) * STRAIGHT_GRAB_M
	_assert_missed(_break_at(ELSEWHERE, camera, behind), "1,5 m behind the hand")


# Criterion 1 ("A mão": "A fatia do tick k do ativo, de 1 a 6, vai de 0,2 × (k − 1) a 0,2 × k m do
# eixo do corpo"): the hand advances 0,2 m per active tick, so a target straight along it is
# touched on the active tick whose slice first comes within 0,35 m of its axis, and not before.
func test_the_hand_advances_0_2_m_per_active_tick(
	active_tick: int,
	_test_parameters := [[1], [2], [3], [4], [5], [6]],
) -> void:
	var distance := STRAIGHT_M_BY_ACTIVE_TICK[active_tick]
	assert_float(HAND_STEP_M * active_tick).is_greater(distance - 0.35)
	assert_float(HAND_STEP_M * (active_tick - 1)).is_less(distance - 0.35)
	var target_feet := _direction(BEARING) * distance
	var duel := _break_at(Vector3.ZERO, _camera_for_hand(BEARING), target_feet)
	var contact := _assert_grabbed(duel, "%.2f m straight along the hand" % distance)
	assert_int(contact).is_equal(_press_tick() + WINDUP_TICKS[60] + active_tick - 1)


# Criterion 1: the hand goes where the crosshair was on the last windup tick, not where the camera
# looks afterwards: the camera turns away on the first active tick and the target on the old aim
# line is still grabbed.
func test_the_hand_goes_where_the_crosshair_was_on_the_last_windup_tick() -> void:
	var target_feet := _direction(BEARING) * GRABS_AT_M[1]
	var aimed := _aim_at(Vector3.ZERO, target_feet)
	var duel := Duel.new()
	var target := Player.new(FACING_BACK)
	var attacker := Player.new(aimed + PI)
	var press := _press_tick()
	attacker.press(press, GUARD_BREAK)
	attacker.look_from(press + WINDUP_TICKS[60] - 1, aimed)
	attacker.look_from(press + WINDUP_TICKS[60], aimed + PI)
	duel.add(_fighter(60, TARGET, target_feet, FACING_BACK), target.input)
	duel.add(_fighter(60, ATTACKER, Vector3.ZERO, aimed + PI), attacker.input)
	duel.run_through(press + _swing_ticks(60) + SPARE_TICKS)
	_assert_grabbed(duel, "the crosshair on the axis only on the last windup tick")


# Criterion 4: a light that lands in the guard break's windup stops it and stuns whoever tried it:
# the guard break has no armor (combate.md, "A quebra de guarda e o tech": "a quebra não tem
# armadura, e um leve que pega durante os 350 ms a derruba"). The light's contact comes 5 ticks
# into the windup, 17 ticks in, which is the two pressed on the same tick ("Começando juntos, o
# leve (contato no tick 15) chega antes da quebra (21)"), and on the last windup tick, the 20th:
# the 12 of damage, the hitstun of 24 ticks plus the hitstop of 4, the windup over, no active ever,
# and the 15 stay paid.
func test_a_light_on_the_guard_break_windup_stops_it_and_stuns(
	ticks_into_the_windup: int,
	_test_parameters := [[5], [17], [20]],
) -> void:
	var press := _press_tick()
	var contact := press + ticks_into_the_windup
	var light_press := contact - LIGHT_CONTACT_OFFSET
	assert_int(light_press).is_greater_equal(FIRST_TICK)
	var stun_ends := contact + LIGHT_HITSTUN_TICKS + LIGHT_HITSTOP_TICKS
	var duel := Duel.new()
	var breaker := Player.new(_camera_for_hand(0.0))
	breaker.press(press, GUARD_BREAK)
	var other := Player.new(GrabRig.camera_for(FACING_BACK, SHOULDER_M, SWORD_CONVERGENCE_M))
	other.press(light_press, FighterCommand.LIGHT_ATTACK)
	duel.add(_fighter(60, TARGET, Vector3.ZERO, 0.0), breaker.input)
	duel.add(_fighter(60, ATTACKER, LIGHT_FROM, FACING_BACK), other.input)
	duel.run_through(maxi(stun_ends, press + _swing_ticks(60)) + SPARE_TICKS)
	assert_int(duel.contact_tick_of(1)).override_failure_message("the light's contact at %d"
	% duel.contact_tick_of(1)) \
			.is_equal(contact)
	var on_contact := duel.row_at(contact).fought[0]
	assert_int(on_contact.action).override_failure_message(GrabRig.line(on_contact)).is_equal(
		FighterState.Action.WINDUP
	)
	assert_str(String(on_contact.action_move)).is_equal(String(GUARD_BREAK))
	var stunned := duel.row_at(contact + 1).fought[0]
	var message := "tick %d: %s, expected the hitstun of the contact at %d" % [
		contact + 1,
		GrabRig.line(stunned),
		contact,
	]
	assert_int(stunned.action).override_failure_message(message).is_equal(
		FighterState.Action.HITSTUN
	)
	assert_int(stunned.health).override_failure_message(message).is_equal(MAX_HEALTH - LIGHT_DAMAGE)
	assert_int(stunned.hurt_tick).override_failure_message(message).is_equal(contact)
	assert_int(stunned.stun_until_tick).override_failure_message(message).is_equal(stun_ends)
	assert_int(stunned.frozen_until_tick).override_failure_message(message).is_equal(
		contact + LIGHT_HITSTOP_TICKS
	)
	_assert_no(
		GrabRig.action_violations(duel, 0, contact + 1, stun_ends - 1, FighterState.Action.HITSTUN),
	)
	assert_int(GrabRig.free_tick(duel, 0, contact + 1)).is_equal(stun_ends)
	assert_array(GrabRig.ticks_in(duel, 0, FighterState.Action.ACTIVE)) \
			.override_failure_message("the stopped guard break reached its active") \
			.is_empty()
	assert_int(duel.contact_tick_of(0)).override_failure_message("the stopped hand touched") \
			.is_equal(FighterState.NEVER)
	var violations: Array[String] = []
	for row: Duel.Row in duel.rows:
		if row.tick >= press and row.fought[0].stamina_spent_tick != press:
			violations.append("tick %d: paid at %d" % [row.tick, row.fought[0].stamina_spent_tick])
		if GrabRig.is_grabbed(row.fought[1]) or row.fought[1].health != MAX_HEALTH:
			violations.append("tick %d: the light's attacker was touched" % row.tick)
	_assert_no(violations)
