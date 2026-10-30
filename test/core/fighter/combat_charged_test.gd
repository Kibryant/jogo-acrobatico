# Criteria 1 and 3 of TASK-12.3: the charged attack (glossario.md, "Golpe carregado"; combate.md,
# "Os golpes e as defesas", "O tranco e a vantagem" and "O carregado, o parry e a finta no tick";
# DEC-0056 §2), through the public interface of core/fighter, with the whole tick sandwich played
# by the ChargedRig and, for the contacts, GuardRigs under a Duel with a TickPhoto taken by hand on
# every tick. The fixed windup of 42 ticks, the active of 7 and the recovery of 27; the 25 paid on
# the first active tick and needed on the bar to begin; the refusals that wait in the slot; the slow
# walk of 3 m/s through the three phases; the direction fixed from the first active tick; the slot
# order, parry over charged over light, any movement key over the three; the vertical cut that
# touches 1,5 m ahead on the first active tick, 2,3 m on the third and 2,5 m never; the hit of 30
# with 42 ticks of hitstun and 7 of hitstop, the block that costs 15 with 25 of blockstun and 4 of
# hitstop, the blocker 9 ticks ahead, the attacker 8 ahead after a hit; and the trade. Every number
# comes from docs/design, cited by section; ticks by hand from the ms, nearest tick with ties up.
extends GdUnitTestSuite

const ChargedRig := preload("res://test/core/fighter/charged_rig.gd")
const MovementRig := preload("res://test/core/fighter/movement_rig.gd")
const Duel := preload("res://test/core/fighter/duel.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)
# The move's IDs (glossario.md, "Golpe carregado" and "Golpe leve"; combate.md, "O carregado, o
# parry e a finta no tick": "Os nomes no código").
const CHARGED := &"charged_attack"
const LIGHT := &"light_attack"
const PARRY_COMMAND := &"parry"
# The fighters by name, the photo's key (DEC-0051 §1); the target first by name.
const TARGET := &"A"
const ATTACKER := &"B"

# combate.md, "Os golpes e as defesas", the row "Golpe carregado": 700 / 120 / 450 ms, "preparação
# fixa", "25, pagos na soltura; precisa de 25 para começar", 30 de dano; "Em ticks: 42 / 7 / 27".
# By hand at 30: 700 ms are 21 ticks, 120 are 3,6, so 4, and 450 are 13,5, the tie that goes up to
# 14 (combate.md, "As fases do carregado": "a 30 ticks, são 21, 4 e 14"). Fired at F, the windup is
# F..F+41, the active F+42..F+48, the recovery F+49..F+75, and the body is free on F + 76.
const WINDUP_TICKS: Dictionary[int, int] = { 30: 21, 60: 42 }
const ACTIVE_TICKS: Dictionary[int, int] = { 30: 4, 60: 7 }
const RECOVERY_TICKS: Dictionary[int, int] = { 30: 14, 60: 27 }
const CHARGED_COST := 25.0
const CHARGED_DAMAGE := 30
const BELOW_COST := 24.5 # criterion 1: a bar of 24.5 cannot begin the charged
# combate.md, "Os golpes e as defesas", the row "Golpe leve": 15 / 6 / 12 ticks at 60, 8 / 3 / 6
# at 30 (DEC-0052): a swing of 33 or 17 ticks.
const LIGHT_SWING_TICKS: Dictionary[int, int] = { 30: 17, 60: 33 }
const LIGHT_COST := 8.0
# combate.md, "O tranco e a vantagem": "Carregado acerta: 700 ms, 42 ticks"; "Carregado bloqueado:
# 417 ms, 25 ticks"; by hand 21 at 30, and 417 ms at 30 are 12,51 ticks, so 13. The stun ends at
# contact + stun + hitstop ("O tranco no tick": "mais a paradinha"; DEC-0055 §5).
const HITSTUN_TICKS: Dictionary[int, int] = { 30: 21, 60: 42 }
const BLOCKSTUN_TICKS: Dictionary[int, int] = { 30: 13, 60: 25 }
# combate.md, "O hitstop e o tremor": "Carregado acerta: os dois, 117 ms, 7 ticks"; "Carregado
# bloqueado: os dois, 67 ms, 4 ticks"; by hand 117 ms at 30 are 3,51 ticks, so 4, and 67 ms are
# 2,01, so 2.
const HITSTOP_HIT_TICKS: Dictionary[int, int] = { 30: 4, 60: 7 }
const HITSTOP_BLOCK_TICKS: Dictionary[int, int] = { 30: 2, 60: 4 }
# combate.md, "O tranco e a vantagem", the rows "Carregado acerta: quem bateu +8" and "Carregado
# bloqueado: quem bloqueou +9", at 60 with the contact on the first active tick.
const HIT_ADVANTAGE := 8
const BLOCK_ADVANTAGE := 9
# combate.md, "Os golpes e as defesas", the row "Bloqueio": "15 por carregado bloqueado"; "Sem
# stamina para pagar [...] a guarda cai e o golpe pega, com o tranco".
const BLOCK_COST := 15.0
const BELOW_BLOCK_COST := 14.5
# combate.md, "O bloqueio, a guarda andando e a stamina": the guard rises in 100 ms, 6 ticks at 60
# and 3 at 30.
const GUARD_RAISE_TICKS: Dictionary[int, int] = { 30: 3, 60: 6 }
# combate.md, "Parry": window 200 ms, "recupera [...] 450 se não": 12 and 27 ticks at 60, so a
# parry that meets nothing occupies P..P+38 and the body acts again on P + 39 ("O parry no vazio").
const PARRY_WHIFF_TICKS: Dictionary[int, int] = { 30: 20, 60: 39 }
# movimento.md, "Stamina": "Máximo: 100"; "Espera para recuperar: 800 ms", 48 ticks at 60 and 24
# at 30; "Recuperação: 30 pontos/s", 0,5 per tick at 60 and 1,0 at 30.
const STAMINA_MAX := 100.0
const STAMINA_WAIT_TICKS: Dictionary[int, int] = { 30: 24, 60: 48 }
const REGEN_PER_TICK: Dictionary[int, float] = { 30: 1.0, 60: 0.5 }
# movimento.md, "Perdão": the slot keeps a press 150 ms, 9 ticks at 60 and 5 at 30 (4,5, the tie
# up), inclusive (DEC-0039).
const BUFFER_TICKS: Dictionary[int, int] = { 30: 5, 60: 9 }
const DASH_COST := 15.0 # movimento.md, "Dash": "Custo"
# movimento.md, "Chão": "Andar devagar: com a guarda alta ou durante o carregado: 3 m/s"
# (combate.md, "A direção e o corpo": "nas três fases, o corpo anda a até 3 m/s"); "Velocidade de
# corrida: 7 m/s"; "Tempo até a velocidade máxima: 150 ms", 9 ticks at 60 and 5 at 30, so a tick
# of full input moves the speed 7 / 9 m/s toward its target at 60 and 7 / 5 at 30.
const SLOW_WALK_MPS := 3.0
const RUN_SPEED_MPS := 7.0
const ACCEL_TICKS: Dictionary[int, int] = { 30: 5, 60: 9 }
const MAX_HEALTH := 100 # partida.md, "A vida sem partida"

# combate.md, "O toque do carregado": "Com os dois no mesmo chão, um alvo de frente a 1,5 m é
# tocado no primeiro tick ativo, um a 2,3 m no terceiro, e um a 2,5 m nunca". The attacker looks
# down -Z (yaw 0) from the origin. By hand at 30, with four slices of 11,8° of elevation instead
# of seven of 6,75°: 1,5 m is still the first (the axis top, 0,15 m above the hand's height and
# 1,507 m out, lies 9,2° under the first slice's lower edge, 0,24 m off it), and 2,3 m is the
# second (the second slice, from 3,1° to 14,9°, holds the axis top's 3,7°, 0,305 m beyond the tip).
const CLOSE := Vector3(0.0, 0.0, -1.5)
const AT_2_3_M := Vector3(0.0, 0.0, -2.3)
const AT_2_5_M := Vector3(0.0, 0.0, -2.5)
const CLOSE_ACTIVE_TICK: Dictionary[int, int] = { 30: 1, 60: 1 }
const AT_2_3_M_ACTIVE_TICK: Dictionary[int, int] = { 30: 2, 60: 3 }
# combate.md, "O toque do carregado": the distance joins the part off the plane and the part in it,
# against the touch of 0,43 m ("O toque"). By hand, 1,5 m ahead the first slice passes 0,372 m
# from the axis in the plane at 60 (0,24 at 30): 0,2 m to the side makes 0,42 m, a touch on the
# first active tick; 0,45 m to the side is beyond 0,43 whatever the slice. Positive X is the
# attacker's right at yaw 0.
const SIDE_TOUCH_M := 0.2
const SIDE_MISS_M := 0.45
const BEHIND := Vector3(0.0, 0.0, 1.5)
# Looking back at the attacker: +Z, the yaw pi; looking away: yaw 0 (DEC-0054 §2).
const FACING_THE_ATTACKER := PI
const LOOKING_AWAY := 0.0

const FORWARD := Vector2(0, 1) # move.y goes forward: yaw 0 looks down -Z (TASK-9 plan)
const RIGHT := Vector2(1, 0)
const BACK := Vector2(0, -1)
const HAIR := 1e-6 # floating-point slack, not a design number
const YAW_STEP := 0.05 # rad per tick the camera turns: arithmetic
const FIRST_YAW := 0.3 # rad, arithmetic
const SPARE_TICKS := 6 # ticks a run keeps going past the last event: arithmetic
const SETTLE_TICKS := 10 # ticks of guard before a command drops it: arithmetic
const PRESS_AFTER_START := 10 # ticks after FIRST_TICK the charged is pressed: arithmetic


func _fighter(tickrate: int) -> ChargedRig:
	return ChargedRig.new(
		&"A",
		MovementRig.load_config(tickrate),
		ChargedRig.load_combat(tickrate),
		FIRST_TICK,
	)


func _named(
	name: StringName,
	tickrate: int,
	feet: Vector3,
	yaw: float,
	combat: CombatConfig,
) -> ChargedRig:
	return ChargedRig.new(name, MovementRig.load_config(tickrate), combat, FIRST_TICK, feet, yaw)


func _swing_ticks(tickrate: int) -> int:
	return WINDUP_TICKS[tickrate] + ACTIVE_TICKS[tickrate] + RECOVERY_TICKS[tickrate]


func _phase_of(state: FighterState) -> String:
	if state.action == FighterState.Action.NONE:
		return "NONE"
	var name: Variant = FighterState.Action.find_key(state.action)
	return "%s since %d with %s" % [name, state.action_since, state.action_move]


# The phase a charged fired at `first` is in at `tick`, as a line.
func _expected_phase(first: int, tick: int, tickrate: int) -> String:
	var active_from := first + WINDUP_TICKS[tickrate]
	var recovery_from := active_from + ACTIVE_TICKS[tickrate]
	var end := recovery_from + RECOVERY_TICKS[tickrate]
	if tick < first or tick >= end:
		return "NONE"
	if tick < active_from:
		return "WINDUP since %d with %s" % [first, CHARGED]
	if tick < recovery_from:
		return "ACTIVE since %d with %s" % [active_from, CHARGED]
	return "RECOVERY since %d with %s" % [recovery_from, CHARGED]


func _step_checking_phase(
	fighter: ChargedRig,
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


func _assert_phase(
	state: FighterState,
	action: FighterState.Action,
	since: int,
	move: StringName = CHARGED,
) -> void:
	var message := "phase %s, expected %s since %d with %s" % [
		_phase_of(state),
		FighterState.Action.find_key(action),
		since,
		move,
	]
	assert_int(state.action).override_failure_message(message).is_equal(action)
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


# Fires a charged now and returns the tick it fired on.
func _fire(fighter: ChargedRig, input: TickInput = ChargedRig.press_charged()) -> int:
	var first := fighter.tick()
	fighter.step(input)
	_assert_phase(fighter.fought, FighterState.Action.WINDUP, first)
	return first


func _horizontal(velocity: Vector3) -> Vector3:
	return Vector3(velocity.x, 0.0, velocity.z)


func _world_direction(move: Vector2, yaw: float) -> Vector3:
	return (Basis(Vector3.UP, yaw) * Vector3(move.x, 0.0, -move.y)).normalized()


# Idles until the fighter lands; returns the landing tick, the one whose after_move saw the floor
# (the rig's own predicate: state().on_floor).
func _idle_until_landed(fighter: ChargedRig) -> int:
	for _step: int in range(1, 5 * fighter.config().tickrate + 1):
		fighter.step(ChargedRig.idle())
		if fighter.state().on_floor:
			return fighter.tick() - 1
	fail("never landed at %d ticks" % fighter.config().tickrate)
	return 0


func _landing_tick_of_a_jump(tickrate: int) -> int:
	var fighter := _fighter(tickrate)
	fighter.step(MovementRig.press_jump())
	return _idle_until_landed(fighter)


# A script that presses the charged on the given ticks, the camera on yaw.
func _charger(presses: PackedInt32Array, yaw: float) -> Callable:
	return func(tick: int) -> TickInput:
		if presses.has(tick):
			return ChargedRig.press_charged(Vector2.ZERO, yaw)
		return ChargedRig.idle(yaw)


# The idle target, the camera on yaw, holding the guard from `guard_from` on when given.
func _idler(yaw: float, guard_from: int = FighterState.NEVER) -> Callable:
	return func(tick: int) -> TickInput:
		var input := ChargedRig.idle(yaw)
		input.guard = guard_from != FighterState.NEVER and tick >= guard_from
		return input


# The target at target_feet with its own script, index 0, and the attacker at the origin looking
# down -Z pressing the charged at `press`, index 1.
func _duel(
	tickrate: int,
	target_feet: Vector3,
	target_yaw: float,
	target_script: Callable,
	press: int,
	combat: CombatConfig = null,
) -> Duel:
	var config := combat if combat != null else ChargedRig.load_combat(tickrate)
	var duel := Duel.new()
	duel.add(_named(TARGET, tickrate, target_feet, target_yaw, config), target_script)
	duel.add(
		_named(ATTACKER, tickrate, Vector3.ZERO, 0.0, config),
		_charger(PackedInt32Array([press]), 0.0),
	)
	return duel


func _action_line(state: FighterState) -> String:
	return "%s since %d, stun_until %d, frozen_until %d, hurt %d, block %d, health %d" % [
		FighterState.Action.find_key(state.action),
		state.action_since,
		state.stun_until_tick,
		state.frozen_until_tick,
		state.hurt_tick,
		state.block_tick,
		state.health,
	]


# The first tick from `from` on which the fighter acts again: NONE, or BLOCK with the button held
# (combate.md, "O tranco e a vantagem": "quem volta a agir primeiro").
func _acts_again(duel: Duel, index: int, from: int) -> int:
	return duel.first_tick(
		index,
		from,
		func(state: FighterState) -> bool:
			return (
				state.action == FighterState.Action.NONE
				or state.action == FighterState.Action.BLOCK
			),
	)


# The fighter `index` is frozen on every tick from `from` to `to`, inclusive, and on no other tick
# of the run, by the rig's own predicate and the plan.
func _assert_frozen_between(duel: Duel, index: int, from: int, to: int) -> void:
	var violations: Array[String] = []
	for row: Duel.Row in duel.rows:
		var frozen := row.tick >= from and row.tick <= to
		if row.plans[index].frozen != frozen:
			violations.append("tick %d: plan.frozen %s" % [row.tick, row.plans[index].frozen])
		if ChargedRig.frozen_at(row.ends[index], row.tick) != frozen:
			violations.append(
				"tick %d: frozen_until %d" % [row.tick, row.ends[index].frozen_until_tick]
			)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()


# The target's combat output on the tick after the contact shows the hit of the charged: 30 of
# damage, the hurt stamp, the hitstun to contact + 42 + 7 and the freeze to contact + 7.
func _assert_hit(duel: Duel, contact: int, tickrate: int, health_before: int) -> void:
	var row := duel.row_at(contact + 1)
	assert_object(row).override_failure_message("tick %d was not run" % (contact + 1)).is_not_null()
	var state := row.fought[0]
	var message := "tick %d: %s, expected a hit of the contact at %d" % [
		row.tick,
		_action_line(state),
		contact,
	]
	assert_int(state.action).override_failure_message(message).is_equal(FighterState.Action.HITSTUN)
	assert_int(state.hurt_tick).override_failure_message(message).is_equal(contact)
	assert_int(state.health).override_failure_message(message).is_equal(
		maxi(0, health_before - CHARGED_DAMAGE)
	)
	assert_int(state.block_tick).override_failure_message(message).is_equal(FighterState.NEVER)
	assert_int(state.stun_until_tick).override_failure_message(message).is_equal(
		contact + HITSTUN_TICKS[tickrate] + HITSTOP_HIT_TICKS[tickrate]
	)
	assert_int(state.frozen_until_tick).override_failure_message(message).is_equal(
		contact + HITSTOP_HIT_TICKS[tickrate]
	)


# The target's combat output on the tick after the contact shows the block of the charged: no
# damage, the block's stamp, 15 paid, the blockstun to contact + 25 + 4 and the freeze to
# contact + 4.
func _assert_blocked(duel: Duel, contact: int, tickrate: int, bar_before: float) -> void:
	var row := duel.row_at(contact + 1)
	assert_object(row).override_failure_message("tick %d was not run" % (contact + 1)).is_not_null()
	var state := row.fought[0]
	var message := "tick %d: %s, expected a block of the contact at %d" % [
		row.tick,
		_action_line(state),
		contact,
	]
	assert_int(state.action).override_failure_message(message).is_equal(
		FighterState.Action.BLOCKSTUN
	)
	assert_int(state.block_tick).override_failure_message(message).is_equal(contact)
	assert_int(state.hurt_tick).override_failure_message(message).is_equal(FighterState.NEVER)
	assert_int(state.health).override_failure_message(message).is_equal(MAX_HEALTH)
	assert_int(state.stun_until_tick).override_failure_message(message).is_equal(
		contact + BLOCKSTUN_TICKS[tickrate] + HITSTOP_BLOCK_TICKS[tickrate]
	)
	assert_int(state.frozen_until_tick).override_failure_message(message).is_equal(
		contact + HITSTOP_BLOCK_TICKS[tickrate]
	)
	var bar := Stamina.at(state, duel.fighter(0).config(), row.tick)
	assert_float(bar).override_failure_message("bar %.2f after the block, had %.2f"
	% [bar, bar_before]) \
			.is_equal_approx(bar_before - BLOCK_COST, HAIR)


func _assert_contact_stamped(duel: Duel, index: int, contact: int, target_name: StringName) -> void:
	var row := duel.row_at(contact)
	assert_object(row).override_failure_message("tick %d was not run" % contact).is_not_null()
	var state := row.fought[index]
	var message := "tick %d: contact (%d, %s, %s), expected (%d, %s, %s)" % [
		row.tick,
		state.contact_tick,
		state.contact_target,
		state.contact_move,
		contact,
		target_name,
		CHARGED,
	]
	assert_int(state.contact_tick).override_failure_message(message).is_equal(contact)
	assert_str(String(state.contact_target)).override_failure_message(message).is_equal(
		String(target_name)
	)
	assert_str(String(state.contact_move)).override_failure_message(message).is_equal(
		String(CHARGED)
	)


# None: a fresh state has no parry stamps, the new actions come after BLOCKSTUN in the order
# PARRY, FEINT, PARRIED, a fresh input touches nothing new, the commands carry the design's names,
# and the copy carries the new stamps (DEC-0056 §1; TASK-12.3 plan).
func test_a_fresh_state_has_no_parry_stamps_and_the_new_actions_come_after_blockstun() -> void:
	var fighter := _fighter(60)
	var state := fighter.state()
	_assert_none(state)
	assert_int(state.parry_tick).is_equal(FighterState.NEVER)
	assert_int(state.parried_tick).is_equal(FighterState.NEVER)
	assert_int(FighterState.Action.PARRY).is_greater(FighterState.Action.BLOCKSTUN)
	assert_int(FighterState.Action.FEINT).is_equal(FighterState.Action.PARRY + 1)
	assert_int(FighterState.Action.PARRIED).is_equal(FighterState.Action.FEINT + 1)
	var input := TickInput.new()
	assert_bool(input.charged_attack).override_failure_message("a fresh input charges").is_false()
	assert_bool(input.parry).override_failure_message("a fresh input parries").is_false()
	assert_bool(input.guard_press).override_failure_message("a fresh input presses the guard") \
			.is_false()
	assert_str(String(FighterCommand.CHARGED_ATTACK)).is_equal(String(CHARGED))
	assert_str(String(FighterCommand.PARRY)).is_equal(String(PARRY_COMMAND))
	state.parry_tick = 7
	state.parried_tick = 9
	var copy := state.copy()
	assert_int(copy.parry_tick).is_equal(7)
	assert_int(copy.parried_tick).is_equal(9)
	copy.parry_tick = FighterState.NEVER
	assert_int(state.parry_tick).override_failure_message("the copy shares the state").is_equal(7)


# Criterion 1: standing on the floor with no swing and a full bar, the press fires the charged on
# its own tick, and the action goes through the windup of 42, the active of 7 and the recovery of
# 27, each counted from the tick it began, NONE again right after (combate.md, "As fases do
# carregado"): 21 / 4 / 14 at 30.
func test_the_charged_runs_windup_active_and_recovery_tick_by_tick(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	var first := fighter.tick()
	var violations: Array[String] = []
	for offset: int in _swing_ticks(tickrate) + 3:
		var input := ChargedRig.press_charged() if offset == 0 else ChargedRig.idle()
		_step_checking_phase(fighter, input, first, violations)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	_assert_empty_slot(fighter.state())
	assert_int(fighter.fought.mode).is_equal(FighterState.Mode.GROUND)


# The ticks of each phase by hand against the config the swing runs on, and the charged's cost
# paid on release (combate.md, "Os golpes e as defesas": "25, pagos na soltura").
func test_the_phases_follow_the_config_made_from_combat_v0(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var combat := ChargedRig.load_combat(tickrate)
	assert_bool(combat.attacks.has(CHARGED)).override_failure_message("no charged attack").is_true()
	var charged: AttackConfig = combat.attacks[CHARGED]
	assert_int(charged.windup_ticks).is_equal(WINDUP_TICKS[tickrate])
	assert_int(charged.active_ticks).is_equal(ACTIVE_TICKS[tickrate])
	assert_int(charged.recovery_ticks).is_equal(RECOVERY_TICKS[tickrate])
	assert_float(charged.stamina_cost).is_equal_approx(CHARGED_COST, HAIR)
	assert_bool(charged.pays_on_release).is_true()
	assert_int(charged.damage).is_equal(CHARGED_DAMAGE)


# Criterion 1: nothing is paid through the windup; the 25 leave on the first active tick, F + 42,
# and never again (combate.md, "Quando o carregado sai": "os 25 saem no primeiro tick ativo").
func test_the_charged_pays_25_on_its_first_active_tick_and_nothing_before_or_after(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	var first := _fire(fighter)
	var active_from := first + WINDUP_TICKS[tickrate]
	var violations: Array[String] = []
	for tick: int in range(first + 1, first + _swing_ticks(tickrate) + 1):
		fighter.step(ChargedRig.idle())
		var state := fighter.fought
		var bar := Stamina.at(state, fighter.config(), tick)
		if tick < active_from:
			if state.stamina_spent_tick != FighterState.NEVER or absf(bar - STAMINA_MAX) > HAIR:
				violations.append(
					"tick %d: paid at %d, bar %.2f, before the active"
					% [tick, state.stamina_spent_tick, bar]
				)
		elif (
			state.stamina_spent_tick != active_from
			or absf(bar - (STAMINA_MAX - CHARGED_COST)) > HAIR
		):
			violations.append(
				"tick %d: paid at %d, bar %.2f, expected %d and %.1f"
				% [tick, state.stamina_spent_tick, bar, active_from, STAMINA_MAX - CHARGED_COST]
			)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	assert_int(fighter.fought.stamina_spent_tick).is_equal(active_from)


# Criterion 1: with less than 25 on the bar the charged does not begin, and nothing is paid: the
# press waits in the slot and fires on the first tick the bar reads 25, inside the 150 ms; the
# bar is still untouched when it fires, and the 25 leave 42 ticks later (combate.md, "A stamina no
# combate": "só começa com 25 na barra"; movimento.md, "Stamina" and "Perdão").
func test_a_press_without_25_stamina_waits_in_the_slot_and_fires_when_the_bar_can_begin(
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
	fighter.step(ChargedRig.press_charged())
	_assert_none(fighter.fought)
	_assert_slot(fighter.fought, FighterCommand.CHARGED_ATTACK, press_tick)
	for _offset: int in range(1, ticks_ahead):
		fighter.step(ChargedRig.idle())
		_assert_none(fighter.fought)
		_assert_slot(fighter.fought, FighterCommand.CHARGED_ATTACK, press_tick)
		assert_int(fighter.fought.stamina_spent_tick).is_equal(stamp)
	var fire_tick := press_tick + ticks_ahead
	assert_int(fighter.tick()).is_equal(fire_tick)
	var bar_at_fire := fighter.stamina()
	assert_float(bar_at_fire).is_equal_approx(BELOW_COST + REGEN_PER_TICK[tickrate], HAIR)
	fighter.step(ChargedRig.idle())
	_assert_phase(fighter.fought, FighterState.Action.WINDUP, fire_tick)
	_assert_empty_slot(fighter.fought)
	assert_int(fighter.fought.stamina_spent_tick).override_failure_message("paid at the start") \
			.is_equal(stamp)
	assert_float(Stamina.at(fighter.fought, fighter.config(), fire_tick)).is_equal_approx(
		bar_at_fire,
		HAIR,
	)
	var active_from := fire_tick + WINDUP_TICKS[tickrate]
	while fighter.tick() < active_from:
		fighter.step(ChargedRig.idle())
		assert_int(fighter.fought.stamina_spent_tick).is_equal(stamp)
	var bar_before_release := fighter.stamina()
	fighter.step(ChargedRig.idle())
	_assert_phase(fighter.fought, FighterState.Action.ACTIVE, active_from)
	assert_int(fighter.fought.stamina_spent_tick).is_equal(active_from)
	assert_float(Stamina.at(fighter.fought, fighter.config(), active_from)).is_equal_approx(
		bar_before_release - CHARGED_COST,
		HAIR,
	)


# Limit: a bar that reaches 25 one tick past the window never fires the charged, and the slot lets
# the press go (DEC-0039).
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
	fighter.step(ChargedRig.press_charged())
	for _offset: int in range(1, ticks_ahead):
		fighter.step(ChargedRig.idle())
		_assert_none(fighter.fought)
		_assert_slot(fighter.fought, FighterCommand.CHARGED_ATTACK, press_tick)
	for _offset: int in 5:
		fighter.step(ChargedRig.idle())
		_assert_none(fighter.fought)
		_assert_empty_slot(fighter.fought)
		assert_int(fighter.fought.stamina_spent_tick).is_equal(stamp)


# Criterion 1: in the air the charged does not come out (combate.md, "Quando o carregado sai": "em
# pé no chão"): the press waits in the slot and fires on the first tick that starts on the floor,
# pressed at the limit of the window before it or on the landing tick itself.
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
		var input := ChargedRig.press_charged() if tick == press_tick else ChargedRig.idle()
		fighter.step(input)
		_assert_none(fighter.fought)
		if tick >= press_tick:
			_assert_slot(fighter.fought, FighterCommand.CHARGED_ATTACK, press_tick)
	assert_bool(fighter.state().on_floor).override_failure_message("not landed yet").is_true()
	fighter.step(ChargedRig.idle())
	_assert_phase(fighter.fought, FighterState.Action.WINDUP, first_floor_tick)
	_assert_empty_slot(fighter.fought)


# Criterion 1: with a light in progress the charged waits in the slot and fires on the first tick
# after the light's recovery, when still within the 150 ms (combate.md, "Quando o carregado sai":
# "sem golpe").
func test_a_press_during_a_light_waits_and_fires_on_the_first_tick_after_its_recovery(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	var light_tick := fighter.tick()
	fighter.step(ChargedRig.press_light())
	_assert_phase(fighter.fought, FighterState.Action.WINDUP, light_tick, LIGHT)
	var end := light_tick + LIGHT_SWING_TICKS[tickrate]
	var press_tick := end - 1
	while fighter.tick() < end:
		var tick := fighter.tick()
		var input := ChargedRig.press_charged() if tick == press_tick else ChargedRig.idle()
		fighter.step(input)
		assert_str(String(fighter.fought.action_move)).is_equal(String(LIGHT))
		if tick >= press_tick:
			_assert_slot(fighter.fought, FighterCommand.CHARGED_ATTACK, press_tick)
	fighter.step(ChargedRig.idle())
	_assert_phase(fighter.fought, FighterState.Action.WINDUP, end)
	_assert_empty_slot(fighter.fought)
	assert_float(Stamina.at(fighter.fought, fighter.config(), end)).is_equal_approx(
		STAMINA_MAX - LIGHT_COST,
		HAIR,
	)


# Criterion 1: no input but the feint cuts the sequence (combate.md, "As fases do carregado":
# "Nenhum input corta a sequência, só a finta"; DEC-0016): a jump, a dash, a grapple, a light, a
# parry and another charged during the swing, none within the buffer of its end, leave the phases
# as they are, start no maneuver and pay nothing but the 25 on release.
func test_no_input_but_the_feint_cuts_the_charged(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	var first := _fire(fighter)
	var swing := _swing_ticks(tickrate)
	var active_from := first + WINDUP_TICKS[tickrate]
	var presses: Dictionary[int, TickInput] = {
		2: MovementRig.press_jump_toward(FORWARD),
		4: ChargedRig.press_parry(),
		6: ChargedRig.press_charged(),
		WINDUP_TICKS[tickrate] - 1: MovementRig.press_dash_toward(RIGHT),
		WINDUP_TICKS[tickrate] + 1: MovementRig.press_grapple_toward(BACK),
		WINDUP_TICKS[tickrate] + ACTIVE_TICKS[tickrate]: ChargedRig.press_light(FORWARD),
		WINDUP_TICKS[tickrate] + ACTIVE_TICKS[tickrate] + 2: ChargedRig.press_parry(),
	}
	for offset: int in presses:
		assert_int(swing - offset).override_failure_message("press %d is in the buffer" % offset) \
				.is_greater(BUFFER_TICKS[tickrate])
	var violations: Array[String] = []
	for offset: int in range(1, swing + 1):
		var tick := first + offset
		var input := presses[offset] if presses.has(offset) else ChargedRig.walk(FORWARD)
		var plan := _step_checking_phase(fighter, input, first, violations)
		var state := fighter.fought
		if state.jumps_used != 0 or state.mode != FighterState.Mode.GROUND:
			violations.append("tick %d: jumped or left GROUND" % tick)
		if state.dash_tick != FighterState.NEVER or state.grapple_fired_tick != FighterState.NEVER:
			violations.append("tick %d: dashed or grappled" % tick)
		var expected_stamp := FighterState.NEVER if tick < active_from else active_from
		if state.stamina_spent_tick != expected_stamp:
			violations.append("tick %d: paid at %d" % [tick, state.stamina_spent_tick])
		if plan.aim_request:
			violations.append("tick %d: asked for the aim during the swing" % tick)
		if not fighter.state().on_floor:
			violations.append("tick %d: left the floor" % tick)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	fighter.step(ChargedRig.idle())
	_assert_none(fighter.fought)


# Criterion 1: a jump, a light or a parry pressed one tick before the charged's end waits in the
# slot and comes out on the end tick (combate.md, "O corpo na postura, na finta e em quem foi
# aparado"; DEC-0051 §5: no command leaves the slot during a swing).
func test_a_command_pressed_during_the_charged_waits_and_fires_at_its_end(
	tickrate: int,
	command: StringName,
	_test_parameters := [
		[30, FighterCommand.JUMP],
		[60, FighterCommand.JUMP],
		[30, FighterCommand.LIGHT_ATTACK],
		[60, FighterCommand.LIGHT_ATTACK],
		[30, FighterCommand.PARRY],
		[60, FighterCommand.PARRY],
	],
) -> void:
	var fighter := _fighter(tickrate)
	var first := _fire(fighter)
	var end := first + _swing_ticks(tickrate)
	var press_tick := end - 1
	var press := MovementRig.press_jump()
	if command == FighterCommand.LIGHT_ATTACK:
		press = ChargedRig.press_light()
	elif command == FighterCommand.PARRY:
		press = ChargedRig.press_parry()
	var violations: Array[String] = []
	while fighter.tick() < end:
		var tick := fighter.tick()
		var plan := _step_checking_phase(
			fighter,
			press if tick == press_tick else ChargedRig.idle(),
			first,
			violations,
		)
		if plan.state.jumps_used != 0 or plan.velocity != Vector3.ZERO:
			violations.append("tick %d: a command came out during the swing" % tick)
		if tick >= press_tick:
			_assert_slot(plan.state, command, press_tick)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	var out := fighter.step(ChargedRig.idle())
	_assert_empty_slot(out.state)
	match command:
		FighterCommand.JUMP:
			_assert_none(out.state)
			assert_int(out.state.jumps_used).is_equal(1)
			assert_float(out.velocity.y).is_equal_approx(fighter.config().jump_speed, HAIR)
		FighterCommand.LIGHT_ATTACK:
			_assert_phase(fighter.fought, FighterState.Action.WINDUP, end, LIGHT)
		FighterCommand.PARRY:
			assert_int(fighter.fought.action).override_failure_message(_phase_of(fighter.fought)) \
					.is_equal(FighterState.Action.PARRY)
			assert_int(fighter.fought.action_since).is_equal(end)


# Criterion 1 (combate.md, "A direção e o corpo": "Em pé, nas três fases, o corpo anda a até
# 3 m/s, o andar devagar da guarda"; DEC-0052): from rest, a full push in any direction during the
# charged moves the body by the ground acceleration, 7 / 9 m/s per tick at 60, up to 3 m/s and
# never beyond, from the first tick of the windup to the last of the recovery; the end tick runs
# past 3 again.
func test_the_body_walks_up_to_3_mps_through_the_charged(
	tickrate: int,
	move: Vector2,
	_test_parameters := [[30, FORWARD], [60, FORWARD], [60, RIGHT], [60, BACK]],
) -> void:
	var fighter := _fighter(tickrate)
	var first := fighter.tick()
	var accel := RUN_SPEED_MPS / ACCEL_TICKS[tickrate]
	var direction := _world_direction(move, 0.0)
	var violations: Array[String] = []
	for offset: int in _swing_ticks(tickrate):
		var input := ChargedRig.press_charged(move) if offset == 0 else ChargedRig.walk(move)
		var plan := _step_checking_phase(fighter, input, first, violations)
		var expected := minf(SLOW_WALK_MPS, (offset + 1) * accel)
		var horizontal := _horizontal(plan.velocity)
		if horizontal.distance_to(direction * expected) > HAIR:
			violations.append(
				"tick %d of the swing: %s, expected %s" % [offset, horizontal, direction * expected]
			)
		if plan.velocity.y != 0.0:
			violations.append("tick %d of the swing: vertical %.3f" % [offset, plan.velocity.y])
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	assert_float(fighter.horizontal_speed()).is_equal_approx(SLOW_WALK_MPS, HAIR)
	var free := fighter.step(ChargedRig.walk(move))
	_assert_none(fighter.fought)
	assert_float(_horizontal(free.velocity).length()) \
			.override_failure_message("the end tick must run again") \
			.is_greater(SLOW_WALK_MPS)


# Criterion 1: from the run of 7 m/s, the charged brings the speed down to 3 by the ground
# acceleration and holds it there while the push goes on; released, the body runs again
# (combate.md, "A direção e o corpo"; movimento.md, "Chão": "Andar devagar").
func test_a_run_slows_to_3_mps_through_the_charged(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	for _tick: int in ACCEL_TICKS[tickrate] + 2:
		fighter.step(ChargedRig.walk(FORWARD))
	assert_float(fighter.horizontal_speed()).is_equal_approx(RUN_SPEED_MPS, HAIR)
	var first := fighter.tick()
	var accel := RUN_SPEED_MPS / ACCEL_TICKS[tickrate]
	var direction := _world_direction(FORWARD, 0.0)
	var violations: Array[String] = []
	for offset: int in _swing_ticks(tickrate):
		var input := (
			ChargedRig.press_charged(FORWARD) if offset == 0 else ChargedRig.walk(FORWARD)
		)
		var plan := _step_checking_phase(fighter, input, first, violations)
		var expected := maxf(SLOW_WALK_MPS, RUN_SPEED_MPS - (offset + 1) * accel)
		var horizontal := _horizontal(plan.velocity)
		if horizontal.distance_to(direction * expected) > HAIR:
			violations.append(
				"tick %d of the swing: %s, expected %s" % [offset, horizontal, direction * expected]
			)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	assert_float(fighter.horizontal_speed()).is_equal_approx(SLOW_WALK_MPS, HAIR)
	var free := fighter.step(ChargedRig.walk(FORWARD))
	_assert_none(fighter.fought)
	assert_float(_horizontal(free.velocity).length()).is_greater(SLOW_WALK_MPS)


# Criterion 1 (combate.md, "A direção e o corpo": "a direção segue a câmera em cada tick da
# preparação e fica fixa do primeiro tick ativo ao fim, como no leve"): the cut's direction and
# the body follow the camera through the windup, stay as the camera was on the last windup tick
# from the first active tick to the end of the recovery, and the body follows the camera again on
# the end tick.
func test_the_cut_direction_is_the_cameras_on_the_last_windup_tick_and_then_fixed(
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
			ChargedRig.press_charged(Vector2.ZERO, yaw)
			if offset == 0
			else ChargedRig.idle(yaw)
		)
		var plan := _step_checking_phase(fighter, input, first, violations)
		var state := plan.state
		if offset < windup:
			if absf(state.action_yaw - yaw) > HAIR or absf(state.facing_yaw - yaw) > HAIR:
				violations.append(
					"windup tick %d: cut %.3f, facing %.3f, camera %.3f"
					% [offset, state.action_yaw, state.facing_yaw, yaw]
				)
		elif offset < swing:
			if absf(state.action_yaw - fixed) > HAIR or absf(state.facing_yaw - fixed) > HAIR:
				violations.append(
					"tick %d: cut %.3f, facing %.3f, expected both fixed at %.3f (camera %.3f)"
					% [offset, state.action_yaw, state.facing_yaw, fixed, yaw]
				)
		elif absf(state.facing_yaw - yaw) > HAIR:
			violations.append(
				"tick %d: facing %.3f, camera %.3f after the swing"
				% [offset, state.facing_yaw, yaw]
			)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()


# The slot on one tick (combate.md, "A vaga": "o parry vence o carregado, que vence o leve";
# DEC-0056 §6): the winner fires on its tick and the losers are gone, not waiting: nothing else
# fires after the winner ends.
func test_on_one_tick_the_parry_beats_the_charged_which_beats_the_light(
	charged: bool,
	parry: bool,
	light: bool,
	winner: StringName,
	_test_parameters := [
		[true, false, true, FighterCommand.CHARGED_ATTACK],
		[true, true, false, FighterCommand.PARRY],
		[false, true, true, FighterCommand.PARRY],
		[true, true, true, FighterCommand.PARRY],
	],
) -> void:
	var tickrate := 60
	var fighter := _fighter(tickrate)
	var press_tick := fighter.tick()
	fighter.step(ChargedRig.press_many(charged, parry, light))
	var fought := fighter.fought
	_assert_empty_slot(fought)
	var busy_until := press_tick
	if winner == FighterCommand.CHARGED_ATTACK:
		_assert_phase(fought, FighterState.Action.WINDUP, press_tick)
		busy_until = press_tick + _swing_ticks(tickrate)
	else:
		assert_int(fought.action).override_failure_message(_phase_of(fought)).is_equal(
			FighterState.Action.PARRY
		)
		assert_int(fought.action_since).is_equal(press_tick)
		busy_until = press_tick + PARRY_WHIFF_TICKS[tickrate]
	while fighter.tick() < busy_until:
		fighter.step(ChargedRig.idle())
		assert_int(fighter.fought.action).override_failure_message("tick %d: %s"
		% [fighter.tick() - 1, _phase_of(fighter.fought)]) \
				.is_not_equal(FighterState.Action.NONE)
	for _offset: int in BUFFER_TICKS[tickrate] + 2:
		fighter.step(ChargedRig.idle())
		_assert_none(fighter.fought)
		_assert_empty_slot(fighter.fought)


# The slot on one tick: any movement key beats the charged and the parry (combate.md, "A vaga":
# "qualquer tecla de movimento vence os três"; DEC-0051 §4): the movement command fires as it
# would alone, nothing is paid for the loser, and the loser never fires later.
func test_on_one_tick_a_movement_key_beats_the_charged_and_the_parry(
	charged: bool,
	parry: bool,
	jump: bool,
	dash: bool,
	grapple: bool,
	winner: StringName,
	_test_parameters := [
		[true, false, true, false, false, FighterCommand.JUMP],
		[true, false, false, true, false, FighterCommand.DASH],
		[true, false, false, false, true, FighterCommand.GRAPPLE],
		[false, true, true, false, false, FighterCommand.JUMP],
		[false, true, false, true, false, FighterCommand.DASH],
		[false, true, false, false, true, FighterCommand.GRAPPLE],
		[true, true, true, true, true, FighterCommand.JUMP],
	],
) -> void:
	var fighter := _fighter(60)
	var press_tick := fighter.tick()
	var plan := fighter.step(ChargedRig.press_many(charged, parry, false, jump, dash, grapple))
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
		fighter.step(ChargedRig.idle())
		_assert_none(fighter.fought)


# Criterion 1 (combate.md, "Quando o carregado sai": "Sai da guarda também, que cai"): the charged
# fires from the guard and drops it; the swing runs with no guard in it, and with the button still
# held the guard rises again when the swing ends, on the end tick or the one after.
func test_the_charged_fires_from_the_guard_and_it_rises_again_when_the_swing_ends(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	var began := fighter.tick()
	for _tick: int in GUARD_RAISE_TICKS[tickrate] + SETTLE_TICKS:
		fighter.step(ChargedRig.hold_guard())
		assert_int(fighter.fought.action).is_equal(FighterState.Action.BLOCK)
		assert_int(fighter.fought.action_since).is_equal(began)
	var press_tick := fighter.tick()
	fighter.step(ChargedRig.guarding(ChargedRig.press_charged()))
	_assert_phase(fighter.fought, FighterState.Action.WINDUP, press_tick)
	var end := press_tick + _swing_ticks(tickrate)
	var violations: Array[String] = []
	while fighter.tick() < end:
		_step_checking_phase(fighter, ChargedRig.hold_guard(), press_tick, violations)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	fighter.step(ChargedRig.hold_guard())
	fighter.step(ChargedRig.hold_guard())
	var after := fighter.fought
	var message := "%s after the swing's end at %d, expected BLOCK since %d or %d" % [
		_phase_of(after),
		end,
		end,
		end + 1,
	]
	assert_int(after.action).override_failure_message(message).is_equal(FighterState.Action.BLOCK)
	assert_bool(after.action_since == end or after.action_since == end + 1) \
			.override_failure_message(message) \
			.is_true()


# The vertical cut (combate.md, "O corte do carregado" and "O toque do carregado"): a target dead
# ahead at 1,5 m is touched on the first active tick and one at 2,3 m on the third at 60 (the
# second at 30, by hand); the stamp names the target and the charged.
func test_the_cut_touches_1_5_m_ahead_on_the_first_active_tick_and_2_3_m_on_the_third(
	tickrate: int,
	target_feet: Vector3,
	active_tick: int,
	_test_parameters := [[60, CLOSE, 1], [30, CLOSE, 1], [60, AT_2_3_M, 3], [30, AT_2_3_M, 2]],
) -> void:
	var press := FIRST_TICK + PRESS_AFTER_START
	var contact := press + WINDUP_TICKS[tickrate] + active_tick - 1
	var duel := _duel(
		tickrate,
		target_feet,
		FACING_THE_ATTACKER,
		_idler(FACING_THE_ATTACKER),
		press,
	)
	duel.run_through(press + _swing_ticks(tickrate) + SPARE_TICKS)
	assert_int(duel.contact_tick_of(1)).override_failure_message("contact at %d, expected %d"
	% [duel.contact_tick_of(1), contact]) \
			.is_equal(contact)
	_assert_contact_stamped(duel, 1, contact, TARGET)
	var before := duel.row_at(contact - 1).fought[1]
	assert_int(before.contact_tick).override_failure_message("touched before %d" % contact) \
			.is_equal(FighterState.NEVER)


# None: a target 2,5 m ahead is never touched (combate.md, "O toque do carregado"), nor one behind
# the attacker; the target keeps its health and the attacker freezes on no tick.
func test_the_cut_never_touches_a_target_2_5_m_ahead_or_behind(
	tickrate: int,
	target_feet: Vector3,
	_test_parameters := [[60, AT_2_5_M], [30, AT_2_5_M], [60, BEHIND]],
) -> void:
	var press := FIRST_TICK + PRESS_AFTER_START
	var duel := _duel(
		tickrate,
		target_feet,
		FACING_THE_ATTACKER,
		_idler(FACING_THE_ATTACKER),
		press,
	)
	duel.run_through(press + _swing_ticks(tickrate) + SPARE_TICKS)
	assert_int(duel.contact_tick_of(1)).is_equal(FighterState.NEVER)
	for row: Duel.Row in duel.rows:
		assert_int(row.fought[0].health).override_failure_message("tick %d" % row.tick).is_equal(
			MAX_HEALTH
		)
		assert_int(row.fought[0].hurt_tick).is_equal(FighterState.NEVER)
		assert_bool(row.plans[1].frozen).is_false()
	assert_int(_acts_again(duel, 1, press + 1)).is_equal(press + _swing_ticks(tickrate))


# The part off the cut's plane (combate.md, "O toque do carregado": "a distância junta duas
# partes: a de lado, perpendicular ao plano, e a de dentro do plano"): 1,5 m ahead and 0,2 m to
# the side is touched on the first active tick; 0,45 m to the side, beyond the 0,43 of the touch,
# never, to either side.
func test_a_target_off_the_cuts_plane_is_touched_within_0_43_m_and_not_beyond(
	tickrate: int,
	side_m: float,
	touched: bool,
	_test_parameters := [
		[60, SIDE_TOUCH_M, true],
		[30, SIDE_TOUCH_M, true],
		[60, -SIDE_TOUCH_M, true],
		[60, SIDE_MISS_M, false],
		[60, -SIDE_MISS_M, false],
		[30, SIDE_MISS_M, false],
	],
) -> void:
	var press := FIRST_TICK + PRESS_AFTER_START
	var feet := CLOSE + Vector3(side_m, 0.0, 0.0)
	var duel := _duel(tickrate, feet, FACING_THE_ATTACKER, _idler(FACING_THE_ATTACKER), press)
	duel.run_through(press + _swing_ticks(tickrate) + SPARE_TICKS)
	var expected := press + WINDUP_TICKS[tickrate] if touched else FighterState.NEVER
	var message := "target %s: contact at %d, expected %d" % [
		feet,
		duel.contact_tick_of(1),
		expected,
	]
	assert_int(duel.contact_tick_of(1)).override_failure_message(message).is_equal(expected)


# Criterion 3: a charged that lands without a guard takes 30 on the tick after the contact and
# holds the target 42 ticks from the contact, plus the hitstop of 7; the target is frozen from
# the tick after the contact for 7 ticks, the attacker the same 7 one tick later, and the
# attacker's swing ends 7 ticks later than alone (combate.md, "O acerto e o bloqueio do
# carregado"; "O tranco e a vantagem": "Carregado acerta").
func test_a_charged_without_a_guard_takes_30_and_stuns_42_ticks_from_the_contact(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var press := FIRST_TICK + PRESS_AFTER_START
	var contact := press + WINDUP_TICKS[tickrate]
	var ends := contact + HITSTUN_TICKS[tickrate] + HITSTOP_HIT_TICKS[tickrate]
	var swing_end := press + _swing_ticks(tickrate) + HITSTOP_HIT_TICKS[tickrate]
	var duel := _duel(tickrate, CLOSE, FACING_THE_ATTACKER, _idler(FACING_THE_ATTACKER), press)
	duel.run_through(maxi(ends, swing_end) + SPARE_TICKS)
	_assert_contact_stamped(duel, 1, contact, TARGET)
	_assert_hit(duel, contact, tickrate, MAX_HEALTH)
	var before := duel.row_at(contact).fought[0]
	assert_int(before.health).is_equal(MAX_HEALTH)
	assert_int(before.action).is_equal(FighterState.Action.NONE)
	var violations: Array[String] = []
	for row: Duel.Row in duel.rows:
		var target := row.fought[0]
		if row.tick > contact and row.tick < ends and target.action != FighterState.Action.HITSTUN:
			violations.append(
				"tick %d: target %s, expected HITSTUN" % [row.tick, _action_line(target)]
			)
		if row.tick >= ends and target.action != FighterState.Action.NONE:
			violations.append(
				"tick %d: target %s, expected NONE" % [row.tick, _action_line(target)]
			)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	assert_int(_acts_again(duel, 0, contact + 1)).is_equal(ends)
	_assert_frozen_between(duel, 0, contact + 1, contact + HITSTOP_HIT_TICKS[tickrate])
	_assert_frozen_between(duel, 1, contact + 2, contact + 1 + HITSTOP_HIT_TICKS[tickrate])
	assert_int(_acts_again(duel, 1, contact + 1)).is_equal(swing_end)
	assert_int(duel.row_at(contact + 1).fought[0].stamina_spent_tick) \
			.override_failure_message("the hit paid stamina") \
			.is_equal(FighterState.NEVER)


# Criterion 3 (combate.md, "O tranco e a vantagem", the row "Carregado acerta": "quem bateu +8"):
# with the contact on the first active tick, the attacker acts again 8 ticks before the target,
# at 60.
func test_after_a_charged_hit_the_attacker_is_8_ticks_ahead() -> void:
	var tickrate := 60
	var press := FIRST_TICK + PRESS_AFTER_START
	var contact := press + WINDUP_TICKS[tickrate]
	var ends := contact + HITSTUN_TICKS[tickrate] + HITSTOP_HIT_TICKS[tickrate]
	var duel := _duel(tickrate, CLOSE, FACING_THE_ATTACKER, _idler(FACING_THE_ATTACKER), press)
	duel.run_through(ends + SPARE_TICKS)
	_assert_hit(duel, contact, tickrate, MAX_HEALTH)
	var target_free := _acts_again(duel, 0, contact + 1)
	var attacker_free := _acts_again(duel, 1, contact + 1)
	var message := "target acts at %d, attacker at %d" % [target_free, attacker_free]
	assert_int(target_free - attacker_free).override_failure_message(message).is_equal(
		HIT_ADVANTAGE
	)


# Criterion 3: with the guard up and the attacker in front, the charged is blocked: no damage, 15
# paid on the contact, the blockstun of 25 ticks from the contact plus the hitstop of 4, the
# target frozen 4 ticks and the attacker the same 4 one tick later; the target is in the blockstun
# until contact + 29, the guard already back since the button is still held (combate.md, "O acerto
# e o bloqueio do carregado": "Bloqueado: 15 de stamina, 25 ticks de blockstun e 4 de paradinha").
func test_a_charged_on_the_guard_up_costs_15_and_25_ticks_of_blockstun(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var press := FIRST_TICK + PRESS_AFTER_START
	var contact := press + WINDUP_TICKS[tickrate]
	var ends := contact + BLOCKSTUN_TICKS[tickrate] + HITSTOP_BLOCK_TICKS[tickrate]
	var swing_end := press + _swing_ticks(tickrate) + HITSTOP_BLOCK_TICKS[tickrate]
	var duel := _duel(
		tickrate,
		CLOSE,
		FACING_THE_ATTACKER,
		_idler(FACING_THE_ATTACKER, FIRST_TICK),
		press,
	)
	duel.run_through(maxi(ends, swing_end) + SPARE_TICKS)
	_assert_contact_stamped(duel, 1, contact, TARGET)
	assert_int(duel.row_at(contact).fought[0].action).is_equal(FighterState.Action.BLOCK)
	_assert_blocked(duel, contact, tickrate, STAMINA_MAX)
	var violations: Array[String] = []
	for row: Duel.Row in duel.rows:
		var target := row.fought[0]
		var in_stun := row.tick > contact and row.tick < ends
		if in_stun and target.action != FighterState.Action.BLOCKSTUN:
			violations.append(
				"tick %d: target %s, expected BLOCKSTUN" % [row.tick, _action_line(target)]
			)
		if row.tick >= ends and target.action != FighterState.Action.BLOCK:
			violations.append(
				"tick %d: target %s, expected BLOCK again" % [row.tick, _action_line(target)]
			)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	assert_int(_acts_again(duel, 0, contact + 1)).is_equal(ends)
	_assert_frozen_between(duel, 0, contact + 1, contact + HITSTOP_BLOCK_TICKS[tickrate])
	_assert_frozen_between(duel, 1, contact + 2, contact + 1 + HITSTOP_BLOCK_TICKS[tickrate])
	assert_int(_acts_again(duel, 1, contact + 1)).is_equal(swing_end)


# Criterion 3 (combate.md, "O tranco e a vantagem", the row "Carregado bloqueado": "quem bloqueou
# +9"; "O acerto e o bloqueio do carregado": "quem bateu fica 9 ticks atrás"): at 60, with the
# contact on the first active tick, the blocker acts again 9 ticks before the attacker.
func test_after_a_blocked_charged_the_blocker_is_9_ticks_ahead() -> void:
	var tickrate := 60
	var press := FIRST_TICK + PRESS_AFTER_START
	var contact := press + WINDUP_TICKS[tickrate]
	var last := press + _swing_ticks(tickrate) + HITSTOP_BLOCK_TICKS[tickrate] + SPARE_TICKS
	var duel := _duel(
		tickrate,
		CLOSE,
		FACING_THE_ATTACKER,
		_idler(FACING_THE_ATTACKER, FIRST_TICK),
		press,
	)
	duel.run_through(last)
	_assert_blocked(duel, contact, tickrate, STAMINA_MAX)
	var blocker_free := _acts_again(duel, 0, contact + 1)
	var attacker_free := _acts_again(duel, 1, contact + 1)
	var message := "blocker acts at %d, attacker at %d" % [blocker_free, attacker_free]
	assert_int(attacker_free - blocker_free).override_failure_message(message).is_equal(
		BLOCK_ADVANTAGE
	)


# Criterion 3, the failure: with less than 15 on the bar when the contact is applied the guard
# falls and the charged hits with the full stun, nothing paid; with exactly 15, the limit, it is
# blocked and the bar goes to 0 (combate.md, "O bloqueio, a guarda andando e a stamina": "Sem
# stamina para o custo, a guarda cai no golpe").
func test_with_less_than_15_stamina_the_guard_falls_to_the_charged_and_with_15_it_blocks(
	tickrate: int,
	bar: float,
	blocks: bool,
	_test_parameters := [
		[30, BELOW_BLOCK_COST, false],
		[60, BELOW_BLOCK_COST, false],
		[60, BLOCK_COST, true],
	],
) -> void:
	var press := FIRST_TICK + 1
	var contact := press + WINDUP_TICKS[tickrate]
	# The bar is stamped at the contact's eve, so it regains nothing before the contact is applied.
	var stamp := contact - 1
	var duel := _duel(
		tickrate,
		CLOSE,
		FACING_THE_ATTACKER,
		_idler(FACING_THE_ATTACKER, FIRST_TICK),
		press,
	)
	duel.run_through(stamp - 1)
	var target := duel.fighter(0)
	target.state().stamina_at_spend = bar
	target.state().stamina_spent_tick = stamp
	duel.run_through(contact + SPARE_TICKS)
	assert_int(duel.row_at(contact).fought[0].action).is_equal(FighterState.Action.BLOCK)
	assert_int(duel.contact_tick_of(1)).is_equal(contact)
	if blocks:
		_assert_blocked(duel, contact, tickrate, bar)
	else:
		_assert_hit(duel, contact, tickrate, MAX_HEALTH)
		var after := duel.row_at(contact + 1).fought[0]
		assert_int(after.stamina_spent_tick).override_failure_message("the fall paid stamina") \
				.is_equal(stamp)
		assert_float(Stamina.at(after, target.config(), contact + 1)).is_equal_approx(bar, HAIR)


# Criterion 3: from behind the guard the charged hits as without a guard (DEC-0054 §2: "pelas
# costas, o golpe pega como se não houvesse guarda"), by the light's path.
func test_a_charged_from_behind_the_guard_hits_as_without_a_guard() -> void:
	var tickrate := 60
	var press := FIRST_TICK + PRESS_AFTER_START
	var contact := press + WINDUP_TICKS[tickrate]
	var duel := _duel(tickrate, CLOSE, LOOKING_AWAY, _idler(LOOKING_AWAY, FIRST_TICK), press)
	duel.run_through(contact + SPARE_TICKS)
	assert_int(duel.row_at(contact).fought[0].action).is_equal(FighterState.Action.BLOCK)
	_assert_hit(duel, contact, tickrate, MAX_HEALTH)


# Criterion 3, many: two charged that touch on the same tick trade, both taking 30 on the next
# tick and both in the hitstun (combate.md, "O acerto e o bloqueio do carregado": "Dois carregados
# que tocam no mesmo tick trocam"; "O tranco e a vantagem": "Carregado contra carregado").
func test_two_charged_that_touch_on_the_same_tick_trade() -> void:
	var tickrate := 60
	var press := FIRST_TICK + PRESS_AFTER_START
	var contact := press + WINDUP_TICKS[tickrate]
	var combat := ChargedRig.load_combat(tickrate)
	var duel := Duel.new()
	duel.add(
		_named(TARGET, tickrate, CLOSE, FACING_THE_ATTACKER, combat),
		_charger(PackedInt32Array([press]), FACING_THE_ATTACKER),
	)
	duel.add(
		_named(ATTACKER, tickrate, Vector3.ZERO, 0.0, combat),
		_charger(PackedInt32Array([press]), 0.0),
	)
	duel.run_through(contact + HITSTOP_HIT_TICKS[tickrate] + SPARE_TICKS)
	assert_int(duel.contact_tick_of(0)).is_equal(contact)
	assert_int(duel.contact_tick_of(1)).is_equal(contact)
	for index: int in 2:
		var state := duel.row_at(contact + 1).fought[index]
		var message := "fighter %d at %d: %s" % [index, contact + 1, _action_line(state)]
		assert_int(state.health).override_failure_message(message).is_equal(
			MAX_HEALTH - CHARGED_DAMAGE
		)
		assert_int(state.hurt_tick).override_failure_message(message).is_equal(contact)
		assert_int(state.action).override_failure_message(message).is_equal(
			FighterState.Action.HITSTUN
		)
		assert_int(state.stun_until_tick).override_failure_message(message).is_equal(
			contact + HITSTUN_TICKS[tickrate] + HITSTOP_HIT_TICKS[tickrate]
		)
