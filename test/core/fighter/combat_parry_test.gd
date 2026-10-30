# Criteria 4 and 5 of TASK-12.3: the parry (glossario.md, "Parry", "Postura do parry" and
# "Aparado"; combate.md, "O parry (Q-21)", "O tranco e a vantagem" and "O carregado, o parry e a
# finta no tick"; DEC-0056 §4), through the public interface of core/fighter, with the ChargedRig
# alone and with GuardRigs under a Duel with a TickPhoto taken by hand on every tick. The press
# makes the stance PARRY from its tick and pays 15; the window is the 12 first ticks, P to P + 11;
# the defender resolves a charged's contact on the tick after the touch, on its own state as the
# contact tick left it, and parries it when in the stance, with the contact in the window and the
# attacker in the front half: no damage, no stun, no freeze, the parry stamp on the contact and the
# stance over 12 ticks after it. Whoever was parried reads the stamp in the photo two ticks after
# the contact: PARRIED, frozen 9 ticks alone, acting again at contact + 54 + 9, while the parrier
# acts at contact + 12 and a charged begun there lands at contact + 54, before the other's guard
# could be up at contact + 69. Outside the window, from behind, or a light: the stance is hit as
# without a defense. A parry that meets nothing ends at P + 39. Every number comes from
# docs/design, cited by section; ticks by hand from the ms, nearest tick with ties up.
extends GdUnitTestSuite

const ChargedRig := preload("res://test/core/fighter/charged_rig.gd")
const MovementRig := preload("res://test/core/fighter/movement_rig.gd")
const Duel := preload("res://test/core/fighter/duel.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)
const CHARGED := &"charged_attack" # glossario.md, "Golpe carregado"
const LIGHT := &"light_attack" # glossario.md, "Golpe leve"
# The defender first by name, the attacker second (DEC-0051 §1).
const DEFENDER := &"A"
const ATTACKER := &"B"

# combate.md, "Os golpes e as defesas", the row "Parry": "janela de 200 desde o aperto; recupera
# 200 se aparou, 450 se não"; "12; 12 ou 27" at 60; "15, no aperto". By hand at 30: 6, 6 and
# 13,5, the tie that goes up to 14. The stance of a parry that meets nothing runs from P to
# P + 38 and the body acts again on P + 39 ("O parry no vazio").
const PARRY_WINDOW_TICKS: Dictionary[int, int] = { 30: 6, 60: 12 }
const PARRY_RECOVERY_TICKS: Dictionary[int, int] = { 30: 6, 60: 12 }
const PARRY_WHIFF_TICKS: Dictionary[int, int] = { 30: 14, 60: 27 }
const PARRY_COST := 15.0
const BELOW_PARRY_COST := 14.5
# combate.md, "O tranco e a vantagem", the row "Carregado aparado": "quem foi aparado: 900 ms, 54
# ticks, mais 9 ticks de hitstop sozinho"; "O hitstop e o tremor": "Parry: só quem foi aparado,
# 150 ms, 9 ticks". By hand at 30: 27, and 150 ms are 4,5 ticks, the tie that goes up to 5.
# Whoever was parried freezes from contact + 2 to contact + 2 + 9 - 1 and acts again at
# contact + 54 + 9 ("Quem foi aparado").
const PARRIED_STUN_TICKS: Dictionary[int, int] = { 30: 27, 60: 54 }
const PARRIED_HITSTOP_TICKS: Dictionary[int, int] = { 30: 5, 60: 9 }
# combate.md, "Os golpes e as defesas", the row "Golpe carregado": 42 / 7 / 27 ticks at 60 and
# 21 / 4 / 14 at 30, 30 de dano, 25 de stamina na soltura.
const WINDUP_TICKS: Dictionary[int, int] = { 30: 21, 60: 42 }
const SWING_TICKS: Dictionary[int, int] = { 30: 39, 60: 76 }
const CHARGED_DAMAGE := 30
# combate.md, "O tranco e a vantagem": "Carregado acerta: 700 ms, 42 ticks"; "O hitstop e o
# tremor": "Carregado acerta: 117 ms, 7 ticks"; by hand 21 and 4 at 30.
const HITSTUN_TICKS: Dictionary[int, int] = { 30: 21, 60: 42 }
const HITSTOP_HIT_TICKS: Dictionary[int, int] = { 30: 4, 60: 7 }
# combate.md, "Os golpes e as defesas", the row "Golpe leve": 15 / 6 / 12 ticks at 60, 12 de dano
# (DEC-0052); "O tranco e a vantagem": "Leve acerta: 24 ticks", 12 at 30; "O hitstop e o tremor":
# "Leve acerta: 4 ticks", 2 at 30.
const LIGHT_DAMAGE := 12
const LIGHT_HITSTUN_TICKS: Dictionary[int, int] = { 30: 12, 60: 24 }
const LIGHT_HITSTOP_TICKS: Dictionary[int, int] = { 30: 2, 60: 4 }
# combate.md, "O bloqueio, a guarda andando e a stamina": the guard rises in 6 ticks at 60, 3 at
# 30; it covers 90° to each side (DEC-0054 §2), as the parry does ("O parry certo": "medido como
# na guarda").
const GUARD_RAISE_TICKS: Dictionary[int, int] = { 30: 3, 60: 6 }
const HALF_ANGLE_DEG := 90.0
# movimento.md, "Stamina": "Máximo: 100"; "Espera para recuperar: 800 ms", 48 ticks at 60.
const STAMINA_MAX := 100.0
# movimento.md, "Perdão": the slot keeps a press 150 ms, 9 ticks at 60 and 5 at 30, inclusive.
const BUFFER_TICKS: Dictionary[int, int] = { 30: 5, 60: 9 }
const MAX_HEALTH := 100 # partida.md, "A vida sem partida"

# The defender 1,5 m dead ahead of the attacker, who looks down -Z from the origin: the cut
# touches it on the first active tick at both rates (combate.md, "O toque do carregado"; test/core/
# fighter/combat_charged_test.gd), so the contact is the press plus the windup. A light from the
# attacker reaches it on the third slice at 60 and the second at 30, 17 or 9 ticks after the press
# (test/core/fighter/combat_contact_test.gd: the slice before passes 1,5 · sin 20° = 0,51 m off).
const CLOSE := Vector3(0.0, 0.0, -1.5)
const LIGHT_CONTACT_OFFSET: Dictionary[int, int] = { 30: 9, 60: 17 }
# Looking back at the attacker: +Z, the yaw pi; looking away: yaw 0.
const FACING_THE_ATTACKER := PI
const LOOKING_AWAY := 0.0

const HAIR := 1e-6 # floating-point slack, not a design number
const SPARE_TICKS := 6 # ticks a run keeps going past the last event: arithmetic
const PRESS_AFTER_START := 10 # ticks after FIRST_TICK the charged is pressed: arithmetic
const SETTLE_TICKS := 10 # ticks of guard before the parry drops it: arithmetic
const MID_WINDOW: Dictionary[int, int] = { 30: 3, 60: 6 } # ticks into the window: arithmetic


func _alone(tickrate: int) -> ChargedRig:
	return ChargedRig.new(
		&"A",
		MovementRig.load_config(tickrate),
		ChargedRig.load_combat(tickrate),
		FIRST_TICK,
	)


func _fighter(
	name: StringName,
	tickrate: int,
	feet: Vector3,
	yaw: float,
	combat: CombatConfig,
) -> ChargedRig:
	return ChargedRig.new(name, MovementRig.load_config(tickrate), combat, FIRST_TICK, feet, yaw)


# A script from a table of presses by tick, idle with the camera on yaw otherwise, the guard held
# from `guard_from` on when given.
func _scripted(
	presses: Dictionary[int, TickInput],
	yaw: float,
	guard_from := FighterState.NEVER,
) -> Callable:
	return func(tick: int) -> TickInput:
		var input: TickInput = presses[tick] if presses.has(tick) else ChargedRig.idle(yaw)
		if guard_from != FighterState.NEVER and tick >= guard_from:
			input.guard = true
		return input


# The defender at CLOSE, index 0, with its script; the attacker at the origin looking down -Z,
# index 1, pressing the charged at `press`, the guard held from `attacker_guard_from` when given.
func _duel(
	tickrate: int,
	defender_yaw: float,
	defender_script: Callable,
	press: int,
	attacker_guard_from := FighterState.NEVER,
) -> Duel:
	var combat := ChargedRig.load_combat(tickrate)
	var duel := Duel.new()
	duel.add(_fighter(DEFENDER, tickrate, CLOSE, defender_yaw, combat), defender_script)
	var attacker_presses: Dictionary[int, TickInput] = {
		press: ChargedRig.press_charged(Vector2.ZERO, 0.0),
	}
	duel.add(
		_fighter(ATTACKER, tickrate, Vector3.ZERO, 0.0, combat),
		_scripted(attacker_presses, 0.0, attacker_guard_from),
	)
	return duel


func _action_line(state: FighterState) -> String:
	return (
		(
			"%s since %d with %s, stun_until %d, frozen_until %d, hurt %d, block %d, parry %d,"
			+ " parried %d, health %d"
		)
		% [
			FighterState.Action.find_key(state.action),
			state.action_since,
			state.action_move,
			state.stun_until_tick,
			state.frozen_until_tick,
			state.hurt_tick,
			state.block_tick,
			state.parry_tick,
			state.parried_tick,
			state.health,
		]
	)


func _assert_action(state: FighterState, action: FighterState.Action, since: int) -> void:
	var message := "%s, expected %s since %d" % [
		_action_line(state),
		FighterState.Action.find_key(action),
		since,
	]
	assert_int(state.action).override_failure_message(message).is_equal(action)
	assert_int(state.action_since).override_failure_message(message).is_equal(since)


func _assert_none(state: FighterState) -> void:
	assert_int(state.action).override_failure_message(_action_line(state)).is_equal(
		FighterState.Action.NONE
	)


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
# of the run, by the rig's own predicate and the plan; NEVER twice means never frozen.
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


# The defender's combat output on the tick after the contact shows the parry: the stamp on the
# contact, no damage, no hurt, no block, no stun, no freeze, still in the stance.
func _assert_parried(duel: Duel, contact: int) -> void:
	var row := duel.row_at(contact + 1)
	assert_object(row).override_failure_message("tick %d was not run" % (contact + 1)).is_not_null()
	var state := row.fought[0]
	var message := "tick %d: %s, expected the parry of the contact at %d" % [
		row.tick,
		_action_line(state),
		contact,
	]
	assert_int(state.parry_tick).override_failure_message(message).is_equal(contact)
	assert_int(state.action).override_failure_message(message).is_equal(FighterState.Action.PARRY)
	assert_int(state.health).override_failure_message(message).is_equal(MAX_HEALTH)
	assert_int(state.hurt_tick).override_failure_message(message).is_equal(FighterState.NEVER)
	assert_int(state.block_tick).override_failure_message(message).is_equal(FighterState.NEVER)
	assert_int(state.stun_until_tick).override_failure_message(message).is_equal(FighterState.NEVER)
	assert_int(state.frozen_until_tick).override_failure_message(message).is_equal(
		FighterState.NEVER
	)


# The defender's combat output on the tick after the contact shows the charged's hit as without a
# defense: 30 gone, the hitstun of 42 plus 7, the freeze of 7, and no parry stamp.
func _assert_hit(duel: Duel, contact: int, tickrate: int) -> void:
	var row := duel.row_at(contact + 1)
	assert_object(row).override_failure_message("tick %d was not run" % (contact + 1)).is_not_null()
	var state := row.fought[0]
	var message := "tick %d: %s, expected the hit of the contact at %d" % [
		row.tick,
		_action_line(state),
		contact,
	]
	assert_int(state.action).override_failure_message(message).is_equal(FighterState.Action.HITSTUN)
	assert_int(state.hurt_tick).override_failure_message(message).is_equal(contact)
	assert_int(state.health).override_failure_message(message).is_equal(MAX_HEALTH - CHARGED_DAMAGE)
	assert_int(state.parry_tick).override_failure_message(message).is_equal(FighterState.NEVER)
	assert_int(state.stun_until_tick).override_failure_message(message).is_equal(
		contact + HITSTUN_TICKS[tickrate] + HITSTOP_HIT_TICKS[tickrate]
	)
	assert_int(state.frozen_until_tick).override_failure_message(message).is_equal(
		contact + HITSTOP_HIT_TICKS[tickrate]
	)


# The attacker's combat output two ticks after the contact shows it parried: PARRIED, the parried
# stamp on the contact, the stun to contact + 54 + 9, the freeze to contact + 2 + 9 - 1, stunned
# for the rules, no damage taken; one tick before, it was still in its active, reading nothing yet
# (combate.md, "Quem foi aparado"; DEC-0055 §4).
func _assert_attacker_parried(duel: Duel, contact: int, tickrate: int) -> void:
	var before := duel.row_at(contact + 1).fought[1]
	assert_int(before.action).override_failure_message(_action_line(before)).is_equal(
		FighterState.Action.ACTIVE
	)
	assert_int(before.parried_tick).override_failure_message(_action_line(before)).is_equal(
		FighterState.NEVER
	)
	var row := duel.row_at(contact + 2)
	assert_object(row).override_failure_message("tick %d was not run" % (contact + 2)).is_not_null()
	var state := row.fought[1]
	var message := "tick %d: %s, expected PARRIED by the contact at %d" % [
		row.tick,
		_action_line(state),
		contact,
	]
	assert_int(state.action).override_failure_message(message).is_equal(FighterState.Action.PARRIED)
	assert_int(state.parried_tick).override_failure_message(message).is_equal(contact)
	assert_int(state.stun_until_tick).override_failure_message(message).is_equal(
		contact + PARRIED_STUN_TICKS[tickrate] + PARRIED_HITSTOP_TICKS[tickrate]
	)
	assert_int(state.frozen_until_tick).override_failure_message(message).is_equal(
		contact + 2 + PARRIED_HITSTOP_TICKS[tickrate] - 1
	)
	assert_bool(Combat.stunned(state)).override_failure_message(message).is_true()
	assert_int(state.health).override_failure_message(message).is_equal(MAX_HEALTH)
	assert_int(state.hurt_tick).override_failure_message(message).is_equal(FighterState.NEVER)
	assert_int(state.contact_tick).override_failure_message(message).is_equal(contact)


# Criterion 4: pressed standing on the floor with a full bar, the parry is the stance PARRY from
# its tick, pays 15 on that tick, freezes nothing and carries no parry stamp yet (combate.md,
# "Quando o parry sai" and "A postura do parry").
func test_pressing_the_parry_standing_makes_the_stance_parry_from_that_tick_and_pays_15(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _alone(tickrate)
	fighter.step(ChargedRig.idle())
	_assert_none(fighter.fought)
	var press := fighter.tick()
	fighter.step(ChargedRig.press_parry())
	var state := fighter.fought
	_assert_action(state, FighterState.Action.PARRY, press)
	assert_int(state.stamina_spent_tick).override_failure_message("not paid on the press tick") \
			.is_equal(press)
	assert_float(Stamina.at(state, fighter.config(), press)).is_equal_approx(
		STAMINA_MAX - PARRY_COST,
		HAIR,
	)
	assert_int(state.parry_tick).is_equal(FighterState.NEVER)
	assert_int(state.frozen_until_tick).is_equal(FighterState.NEVER)
	assert_bool(fighter.last_plan.frozen).is_false()
	assert_int(state.mode).is_equal(FighterState.Mode.GROUND)


# Criterion 4, the failure: without 15 on the bar the parry does not come out and nothing is paid;
# the press waits in the slot and goes when its window closes. With exactly 15, the limit, it
# fires and the bar goes to 0 (combate.md, "A stamina no combate"; movimento.md, "Stamina").
func test_a_parry_without_15_stamina_waits_in_the_slot_and_with_exactly_15_it_fires(
	bar: float,
	fires: bool,
	_test_parameters := [[BELOW_PARRY_COST, false], [PARRY_COST, true]],
) -> void:
	var tickrate := 60
	var fighter := _alone(tickrate)
	fighter.state().stamina_at_spend = bar
	fighter.state().stamina_spent_tick = FIRST_TICK
	fighter.step(ChargedRig.idle())
	var press := fighter.tick()
	fighter.step(ChargedRig.press_parry())
	if fires:
		_assert_action(fighter.fought, FighterState.Action.PARRY, press)
		assert_int(fighter.fought.stamina_spent_tick).is_equal(press)
		assert_float(Stamina.at(fighter.fought, fighter.config(), press)).is_equal_approx(0.0, HAIR)
		return
	_assert_none(fighter.fought)
	_assert_slot(fighter.fought, FighterCommand.PARRY, press)
	for offset: int in range(1, BUFFER_TICKS[tickrate] + 1):
		fighter.step(ChargedRig.idle())
		_assert_none(fighter.fought)
		_assert_slot(fighter.fought, FighterCommand.PARRY, press)
		assert_int(fighter.fought.stamina_spent_tick).override_failure_message("paid with 14.5") \
				.is_equal(FIRST_TICK)
	for _offset: int in 5:
		fighter.step(ChargedRig.idle())
		_assert_none(fighter.fought)
		_assert_slot(fighter.fought, FighterCommand.NONE, FighterState.NEVER)


# Criterion 4: in the air there is no parry (combate.md, "Quando o parry sai": "No ar não há
# parry"): the press waits in the slot and fires on the first tick that starts on the floor, when
# pressed within the 150 ms before it; pressed early in the flight, it is gone before the landing.
func test_a_parry_pressed_in_the_air_waits_and_fires_on_the_first_tick_on_the_floor(
	tickrate: int,
	ticks_before_the_first_floor_tick: int,
	fires: bool,
	_test_parameters := [
		[30, 1, true],
		[60, 1, true],
		[60, 9, true],
		[60, 10, false],
		[60, 20, false],
	],
) -> void:
	var probe := _alone(tickrate)
	probe.step(MovementRig.press_jump())
	var landing_tick := FighterState.NEVER
	for _step: int in range(1, 5 * tickrate + 1):
		probe.step(ChargedRig.idle())
		if probe.state().on_floor:
			landing_tick = probe.tick() - 1
			break
	assert_int(landing_tick).override_failure_message("never landed").is_not_equal(
		FighterState.NEVER
	)
	var fighter := _alone(tickrate)
	fighter.step(MovementRig.press_jump())
	var first_floor_tick := landing_tick + 1
	var press_tick := first_floor_tick - ticks_before_the_first_floor_tick
	assert_int(press_tick).is_greater(FIRST_TICK)
	while fighter.tick() < first_floor_tick:
		var tick := fighter.tick()
		var input := ChargedRig.press_parry() if tick == press_tick else ChargedRig.idle()
		fighter.step(input)
		_assert_none(fighter.fought)
		assert_int(fighter.fought.stamina_spent_tick).override_failure_message("paid in the air") \
				.is_equal(FighterState.NEVER)
	assert_bool(fighter.state().on_floor).override_failure_message("not landed yet").is_true()
	fighter.step(ChargedRig.idle())
	if fires:
		_assert_action(fighter.fought, FighterState.Action.PARRY, first_floor_tick)
		assert_int(fighter.fought.stamina_spent_tick).is_equal(first_floor_tick)
	else:
		_assert_none(fighter.fought)
		assert_int(fighter.fought.stamina_spent_tick).is_equal(FighterState.NEVER)
	_assert_slot(fighter.fought, FighterCommand.NONE, FighterState.NEVER)


# Criterion 5, none: a parry that meets no charged holds the stance from P to P + 38, the window
# plus 27 more ticks after it, and the body acts again on P + 39, nothing else paid (combate.md,
# "O parry no vazio": "a postura dura mais 27 ticks depois dela e acaba em P + 39").
func test_a_parry_that_meets_no_charged_ends_at_p_plus_39(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _alone(tickrate)
	var press := fighter.tick()
	var ends := press + PARRY_WINDOW_TICKS[tickrate] + PARRY_WHIFF_TICKS[tickrate]
	fighter.step(ChargedRig.press_parry())
	_assert_action(fighter.fought, FighterState.Action.PARRY, press)
	var violations: Array[String] = []
	while fighter.tick() < ends:
		var tick := fighter.tick()
		fighter.step(ChargedRig.idle())
		var state := fighter.fought
		if state.action != FighterState.Action.PARRY or state.action_since != press:
			violations.append(
				"tick %d: %s, expected PARRY since %d" % [tick, _action_line(state), press]
			)
		if state.stamina_spent_tick != press:
			violations.append("tick %d: paid again at %d" % [tick, state.stamina_spent_tick])
		if state.parry_tick != FighterState.NEVER:
			violations.append("tick %d: a parry stamp with nothing parried" % tick)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	fighter.step(ChargedRig.idle())
	_assert_none(fighter.fought)
	assert_int(fighter.fought.stamina_spent_tick).is_equal(press)


# Criterion 4: a charged whose contact falls in the window, at its very first tick or its very
# last, is parried: the defender keeps its health, stamps the parry and leaves the stance 12 ticks
# after the contact, never frozen; the attacker is PARRIED from contact + 2, frozen 9 ticks alone,
# its swing over, acting again at contact + 54 + 9 (combate.md, "O parry certo" and "Quem foi
# aparado"; "O tranco e a vantagem": "Carregado aparado").
func test_a_charged_touching_in_the_window_is_parried(
	tickrate: int,
	ticks_into_the_window: int,
	_test_parameters := [[60, 0], [60, 6], [60, 11], [30, 0], [30, 5]],
) -> void:
	var press := FIRST_TICK + PRESS_AFTER_START
	var contact := press + WINDUP_TICKS[tickrate]
	var parry_press := contact - ticks_into_the_window
	var stance_ends := contact + PARRY_RECOVERY_TICKS[tickrate]
	var attacker_free := contact + PARRIED_STUN_TICKS[tickrate] + PARRIED_HITSTOP_TICKS[tickrate]
	var presses: Dictionary[int, TickInput] = {
		parry_press: ChargedRig.press_parry(Vector2.ZERO, FACING_THE_ATTACKER),
	}
	var duel := _duel(tickrate, FACING_THE_ATTACKER, _scripted(presses, FACING_THE_ATTACKER), press)
	duel.run_through(attacker_free + SPARE_TICKS)
	assert_int(duel.contact_tick_of(1)).override_failure_message("contact at %d, expected %d"
	% [duel.contact_tick_of(1), contact]) \
			.is_equal(contact)
	_assert_action(duel.row_at(parry_press).fought[0], FighterState.Action.PARRY, parry_press)
	_assert_parried(duel, contact)
	_assert_attacker_parried(duel, contact, tickrate)
	var violations: Array[String] = []
	for row: Duel.Row in duel.rows:
		var defender := row.fought[0]
		var attacker := row.fought[1]
		if row.tick >= parry_press and row.tick < stance_ends:
			if defender.action != FighterState.Action.PARRY:
				violations.append(
					"tick %d: defender %s, expected PARRY" % [row.tick, _action_line(defender)]
				)
		elif defender.action != FighterState.Action.NONE:
			violations.append(
				"tick %d: defender %s, expected NONE" % [row.tick, _action_line(defender)]
			)
		if defender.health != MAX_HEALTH or defender.hurt_tick != FighterState.NEVER:
			violations.append(
				"tick %d: the defender was hit, %s" % [row.tick, _action_line(defender)]
			)
		if row.tick >= contact + 2 and row.tick < attacker_free:
			if attacker.action != FighterState.Action.PARRIED:
				violations.append(
					"tick %d: attacker %s, expected PARRIED" % [row.tick, _action_line(attacker)]
				)
		if row.tick >= attacker_free and attacker.action != FighterState.Action.NONE:
			violations.append(
				"tick %d: attacker %s, expected NONE" % [row.tick, _action_line(attacker)]
			)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	assert_int(_acts_again(duel, 0, contact + 1)).is_equal(stance_ends)
	assert_int(_acts_again(duel, 1, contact + 2)).is_equal(attacker_free)
	# Only whoever was parried freezes (combate.md, "O hitstop e o tremor": "Parry: só quem foi
	# aparado"), from contact + 2 for 9 ticks.
	_assert_frozen_between(duel, 0, FighterState.NEVER, FighterState.NEVER)
	_assert_frozen_between(duel, 1, contact + 2, contact + 1 + PARRIED_HITSTOP_TICKS[tickrate])


# Criterion 4, the limit of the window: a charged whose contact comes one tick after the window
# closed hits the stance as without a defense, and one that touched the tick before the press was
# already applied on a defender with no stance (combate.md, "O parry certo": "O carregado que toca
# fora da janela [...] também pega"). The attacker is never PARRIED.
func test_a_charged_touching_outside_the_window_hits_the_stance(
	tickrate: int,
	ticks_into_the_window: int,
	_test_parameters := [[60, 12], [60, -1], [30, 6], [30, -1]],
) -> void:
	var press := FIRST_TICK + PRESS_AFTER_START
	var contact := press + WINDUP_TICKS[tickrate]
	var parry_press := contact - ticks_into_the_window
	var presses: Dictionary[int, TickInput] = {
		parry_press: ChargedRig.press_parry(Vector2.ZERO, FACING_THE_ATTACKER),
	}
	var duel := _duel(tickrate, FACING_THE_ATTACKER, _scripted(presses, FACING_THE_ATTACKER), press)
	duel.run_through(contact + HITSTOP_HIT_TICKS[tickrate] + SPARE_TICKS)
	assert_int(duel.contact_tick_of(1)).is_equal(contact)
	if ticks_into_the_window > 0:
		_assert_action(duel.row_at(contact).fought[0], FighterState.Action.PARRY, parry_press)
	else:
		_assert_none(duel.row_at(contact).fought[0])
	_assert_hit(duel, contact, tickrate)
	for row: Duel.Row in duel.rows:
		var attacker := row.fought[1]
		assert_int(attacker.action).override_failure_message("tick %d: %s"
		% [row.tick, _action_line(attacker)]) \
				.is_not_equal(FighterState.Action.PARRIED)
		assert_int(attacker.parried_tick).is_equal(FighterState.NEVER)


# Criterion 4: the parry covers the front half, like the guard (DEC-0056, "Para a direção do
# parry"; combate.md, "O parry certo": "quem bate está na metade da frente, a até 90° de onde o
# corpo olha"): a hair inside 90° to either side it parries; a hair beyond, and from the back, the
# charged hits.
func test_the_parry_covers_the_front_half_only(
	turned_deg: float,
	parries: bool,
	_test_parameters := [
		[0.0, true],
		[HALF_ANGLE_DEG - 0.5, true],
		[-(HALF_ANGLE_DEG - 0.5), true],
		[HALF_ANGLE_DEG + 0.5, false],
		[-(HALF_ANGLE_DEG + 0.5), false],
		[180.0, false],
	],
) -> void:
	var tickrate := 60
	var press := FIRST_TICK + PRESS_AFTER_START
	var contact := press + WINDUP_TICKS[tickrate]
	var parry_press := contact - MID_WINDOW[tickrate]
	var yaw := FACING_THE_ATTACKER + deg_to_rad(turned_deg)
	var presses: Dictionary[int, TickInput] = {
		parry_press: ChargedRig.press_parry(Vector2.ZERO, yaw)
	}
	var duel := _duel(tickrate, yaw, _scripted(presses, yaw), press)
	duel.run_through(contact + HITSTOP_HIT_TICKS[tickrate] + SPARE_TICKS)
	assert_int(duel.contact_tick_of(1)).is_equal(contact)
	_assert_action(duel.row_at(contact).fought[0], FighterState.Action.PARRY, parry_press)
	if parries:
		_assert_parried(duel, contact)
		_assert_attacker_parried(duel, contact, tickrate)
	else:
		_assert_hit(duel, contact, tickrate)
		assert_int(duel.row_at(contact + 2).fought[1].parried_tick).is_equal(FighterState.NEVER)


# Criterion 5: the light is not parried (combate.md, "O parry": "O leve pega na postura do parry e
# dá o tranco"): a light whose contact falls in the window hits the stance as without a defense,
# the 12 gone, the hitstun of 24 plus 4, and the stun ends the stance; the light's attacker is
# never PARRIED.
func test_a_light_touching_the_parry_stance_hits_as_without_a_defense(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var press := FIRST_TICK + PRESS_AFTER_START
	var contact := press + LIGHT_CONTACT_OFFSET[tickrate]
	var parry_press := contact - MID_WINDOW[tickrate]
	var stun_ends := contact + LIGHT_HITSTUN_TICKS[tickrate] + LIGHT_HITSTOP_TICKS[tickrate]
	var combat := ChargedRig.load_combat(tickrate)
	var duel := Duel.new()
	var defender_presses: Dictionary[int, TickInput] = {
		parry_press: ChargedRig.press_parry(Vector2.ZERO, FACING_THE_ATTACKER),
	}
	duel.add(
		_fighter(DEFENDER, tickrate, CLOSE, FACING_THE_ATTACKER, combat),
		_scripted(defender_presses, FACING_THE_ATTACKER),
	)
	var attacker_presses: Dictionary[int, TickInput] = { press: ChargedRig.press_light() }
	duel.add(
		_fighter(ATTACKER, tickrate, Vector3.ZERO, 0.0, combat),
		_scripted(attacker_presses, 0.0),
	)
	duel.run_through(stun_ends + SPARE_TICKS)
	assert_int(duel.contact_tick_of(1)).is_equal(contact)
	assert_str(String(duel.row_at(contact).fought[1].contact_move)).is_equal(String(LIGHT))
	_assert_action(duel.row_at(contact).fought[0], FighterState.Action.PARRY, parry_press)
	var hit := duel.row_at(contact + 1).fought[0]
	var message := "tick %d: %s" % [contact + 1, _action_line(hit)]
	assert_int(hit.action).override_failure_message(message).is_equal(FighterState.Action.HITSTUN)
	assert_int(hit.health).override_failure_message(message).is_equal(MAX_HEALTH - LIGHT_DAMAGE)
	assert_int(hit.hurt_tick).override_failure_message(message).is_equal(contact)
	assert_int(hit.parry_tick).override_failure_message(message).is_equal(FighterState.NEVER)
	assert_int(hit.stun_until_tick).override_failure_message(message).is_equal(stun_ends)
	for row: Duel.Row in duel.rows:
		if row.tick > contact:
			assert_int(row.fought[0].action) \
					.override_failure_message("tick %d: %s"
			% [row.tick, _action_line(row.fought[0])]) \
					.is_not_equal(FighterState.Action.PARRY)
		assert_int(row.fought[1].parried_tick).is_equal(FighterState.NEVER)
	assert_int(_acts_again(duel, 0, contact + 1)).is_equal(stun_ends)


# Criterion 4: the parry fires from the guard and drops it (combate.md, "Quando o parry sai": "e
# da guarda também, que cai"); with the button still held, the guard rises again when the stance
# ends, on the end tick or the one after ("Depois da postura").
func test_the_parry_fires_from_the_guard_and_the_guard_rises_after_the_stance(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _alone(tickrate)
	var began := fighter.tick()
	for _tick: int in GUARD_RAISE_TICKS[tickrate] + SETTLE_TICKS:
		fighter.step(ChargedRig.hold_guard())
		_assert_action(fighter.fought, FighterState.Action.BLOCK, began)
	var press := fighter.tick()
	fighter.step(ChargedRig.guarding(ChargedRig.press_parry()))
	_assert_action(fighter.fought, FighterState.Action.PARRY, press)
	assert_int(fighter.fought.stamina_spent_tick).is_equal(press)
	var ends := press + PARRY_WINDOW_TICKS[tickrate] + PARRY_WHIFF_TICKS[tickrate]
	while fighter.tick() < ends:
		fighter.step(ChargedRig.hold_guard())
		_assert_action(fighter.fought, FighterState.Action.PARRY, press)
	fighter.step(ChargedRig.hold_guard())
	fighter.step(ChargedRig.hold_guard())
	var after := fighter.fought
	var message := "%s after the stance's end at %d, expected BLOCK since %d or %d" % [
		_action_line(after),
		ends,
		ends,
		ends + 1,
	]
	assert_int(after.action).override_failure_message(message).is_equal(FighterState.Action.BLOCK)
	assert_bool(after.action_since == ends or after.action_since == ends + 1) \
			.override_failure_message(message) \
			.is_true()


# Criterion 4, the guaranteed punish (combate.md, "O tranco e a vantagem", the row "Carregado
# aparado": "Um carregado garantido: começa no tick 12, pega no 54; a guarda do outro só subiria
# no 60"; "Quem foi aparado": "Quem aparou volta a agir no contato + 12. Um carregado que ele
# começa ali pega no contato + 54, e a guarda de quem foi aparado só estaria alta no contato +
# 69"): the parrier presses the charged on contact + 12 and it fires there; its cut touches on
# contact + 54 and the parried one, still in its stun and holding the guard button the whole time,
# takes the 30 with no block: its guard never rose before the cut.
func test_the_parrier_acts_at_contact_plus_12_and_its_charged_lands_before_the_guard_can_rise(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var press := FIRST_TICK + PRESS_AFTER_START
	var contact := press + WINDUP_TICKS[tickrate]
	var parry_press := contact - MID_WINDOW[tickrate]
	var punish_press := contact + PARRY_RECOVERY_TICKS[tickrate]
	var punish_contact := punish_press + WINDUP_TICKS[tickrate]
	var attacker_free := contact + PARRIED_STUN_TICKS[tickrate] + PARRIED_HITSTOP_TICKS[tickrate]
	assert_int(punish_contact).override_failure_message("the numbers do not guarantee the punish") \
			.is_less(attacker_free)
	var presses: Dictionary[int, TickInput] = {
		parry_press: ChargedRig.press_parry(Vector2.ZERO, FACING_THE_ATTACKER),
		punish_press: ChargedRig.press_charged(Vector2.ZERO, FACING_THE_ATTACKER),
	}
	var duel := _duel(
		tickrate,
		FACING_THE_ATTACKER,
		_scripted(presses, FACING_THE_ATTACKER),
		press,
		FIRST_TICK,
	)
	duel.run_through(punish_contact + HITSTOP_HIT_TICKS[tickrate] + SPARE_TICKS)
	assert_int(duel.contact_tick_of(1)).is_equal(contact)
	_assert_parried(duel, contact)
	_assert_attacker_parried(duel, contact, tickrate)
	# The parrier acts again on contact + 12 and the charged fires right there.
	assert_int(_acts_again(duel, 0, contact + 1)).is_equal(punish_press)
	var punish := duel.row_at(punish_press).fought[0]
	_assert_action(punish, FighterState.Action.WINDUP, punish_press)
	assert_str(String(punish.action_move)).is_equal(String(CHARGED))
	assert_int(duel.contact_tick_of(0)).override_failure_message("punish contact at %d, expected %d"
	% [duel.contact_tick_of(0), punish_contact]) \
			.is_equal(punish_contact)
	# The parried one, the guard button held the whole time, never raised it before the cut, and
	# takes the 30 without a block.
	var violations: Array[String] = []
	for row: Duel.Row in duel.rows:
		var attacker := row.fought[1]
		if (
			row.tick > contact and row.tick <= punish_contact
			and attacker.action == FighterState.Action.BLOCK
		):
			violations.append(
				"tick %d: the parried one's guard rose, %s" % [row.tick, _action_line(attacker)]
			)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	var punished := duel.row_at(punish_contact + 1).fought[1]
	var message := "tick %d: %s" % [punish_contact + 1, _action_line(punished)]
	assert_int(punished.action).override_failure_message(message).is_equal(
		FighterState.Action.HITSTUN
	)
	assert_int(punished.health).override_failure_message(message).is_equal(
		MAX_HEALTH - CHARGED_DAMAGE
	)
	assert_int(punished.hurt_tick).override_failure_message(message).is_equal(punish_contact)
	assert_int(punished.block_tick).override_failure_message(message).is_equal(FighterState.NEVER)


# Criterion 5: in the stance the presses wait in the slot (combate.md, "O corpo na postura, na
# finta e em quem foi aparado": "os comandos esperam na vaga"): a light pressed one tick before a
# whiffed stance ends fires on the end tick; nothing fires inside the stance.
func test_a_press_during_the_parry_stance_waits_in_the_slot_and_fires_when_it_ends(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _alone(tickrate)
	var press := fighter.tick()
	var ends := press + PARRY_WINDOW_TICKS[tickrate] + PARRY_WHIFF_TICKS[tickrate]
	var light_press := ends - 1
	fighter.step(ChargedRig.press_parry())
	while fighter.tick() < ends:
		var tick := fighter.tick()
		var input := ChargedRig.press_light() if tick == light_press else ChargedRig.idle()
		fighter.step(input)
		_assert_action(fighter.fought, FighterState.Action.PARRY, press)
		if tick >= light_press:
			_assert_slot(fighter.fought, FighterCommand.LIGHT_ATTACK, light_press)
	fighter.step(ChargedRig.idle())
	_assert_action(fighter.fought, FighterState.Action.WINDUP, ends)
	assert_str(String(fighter.fought.action_move)).is_equal(String(LIGHT))
	_assert_slot(fighter.fought, FighterCommand.NONE, FighterState.NEVER)
