# Criteria 2, 3 and 5 of TASK-12.2: the block as the defender resolves it (DEC-0055 §3; DEC-0054;
# combate.md, "O bloqueio, a guarda andando e a stamina" and "O tranco e a vantagem"), through the
# public interface of core/fighter, with GuardRigs and a TickPhoto taken by hand on every tick
# (Duel). The defender applies a contact stamped on the tick before, on its own state as the
# contact tick left it: with the guard up for its 6 ticks, the attacker's feet within 90° of where
# it looks, flat, and 5 of stamina on the bar, the light is blocked: no damage, 5 paid, the
# blockstun of 15 ticks from the contact plus the hitstop, the attacker's recovery untouched and the
# blocker 3 ticks ahead. From beyond 90°, before the 6 ticks, or without the 5, the light hits as
# without a guard. Every number comes from docs/design, cited by section; ticks by hand from the
# ms, nearest tick with ties up.
extends GdUnitTestSuite

const GuardRig := preload("res://test/core/fighter/guard_rig.gd")
const MovementRig := preload("res://test/core/fighter/movement_rig.gd")
const Duel := preload("res://test/core/fighter/duel.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)
# The fighters by name, the photo's key (DEC-0051 §1). The target is first by name: a slice that
# touches two fighters on one tick gives the swing's one contact to the first by name (combate.md,
# "O leve no tick": "Os alvos são testados em ordem de nome"), so a second attacker whose blade
# also reaches the first attacker still hits the target.
const TARGET := &"A"
const ATTACKER := &"B"
const SECOND := &"C"

# combate.md, "Os golpes e as defesas", the row "Golpe leve": 250 / 100 / 200 ms, 12 de dano
# (DEC-0052); by hand 15 / 6 / 12 ticks at 60 and 8 / 3 / 6 at 30, a swing of 33 or 17 ticks.
const LIGHT_DAMAGE := 12
const WINDUP_TICKS: Dictionary[int, int] = { 30: 8, 60: 15 }
const SWING_TICKS: Dictionary[int, int] = { 30: 17, 60: 33 }
# combate.md, "O bloqueio, a guarda andando e a stamina": the guard rises in 100 ms, 6 ticks at 60
# and 3 at 30; it covers 90° to each side (DEC-0054 §2); it costs 5 per light blocked, paid on the
# contact, and with less than 5 on the bar it falls and the light hits with the full stun.
const GUARD_RAISE_TICKS: Dictionary[int, int] = { 30: 3, 60: 6 }
const HALF_ANGLE_DEG := 90.0
const BLOCK_COST := 5.0
const BELOW_COST := 4.5 # criterion 5: a bar of 4.5 cannot pay the 5
# combate.md, "O tranco e a vantagem": "Leve acerta: 400 ms, 24 ticks"; "Leve bloqueado: 250 ms,
# 15 ticks"; by hand 12 and 8 at 30 (250 ms the tie of 7.5 that goes up). The stun ends at
# contact + stun + hitstop (TASK-12.2 plan; combate.md, "O tranco no tick": "mais a paradinha").
const HITSTUN_TICKS: Dictionary[int, int] = { 30: 12, 60: 24 }
const BLOCKSTUN_TICKS: Dictionary[int, int] = { 30: 8, 60: 15 }
# combate.md, "O hitstop e o tremor": "Leve acerta: 67 ms, 4 ticks"; "Leve bloqueado: 33 ms, 2
# ticks"; by hand 2 and 1 at 30.
const HITSTOP_HIT_TICKS: Dictionary[int, int] = { 30: 2, 60: 4 }
const HITSTOP_BLOCK_TICKS: Dictionary[int, int] = { 30: 1, 60: 2 }
# combate.md, "O tranco e a vantagem", the row "Leve bloqueado": "quem bloqueou +3" at 60, the
# contact on the first active tick: the blockstun of 15 against the 18 the attacker still owes.
const BLOCK_ADVANTAGE := 3
# movimento.md, "Stamina": "Máximo: 100"; "Espera para recuperar: 800 ms", 48 ticks at 60 and 24
# at 30.
const STAMINA_MAX := 100.0
const STAMINA_WAIT_TICKS: Dictionary[int, int] = { 30: 24, 60: 48 }
const MAX_HEALTH := 100 # partida.md, "A vida sem partida"

# The target 2,0 m dead ahead of the attacker, who looks down -Z (yaw 0); its axis sits under the
# blade's tip at theta 0 (combate.md, "A lâmina e o contato"). By hand, the first active tick whose
# slice reaches theta 0 is the third at 60 and the second at 30 (test/core/fighter/
# combat_contact_test.gd), so the contact comes 17 or 9 ticks after the press.
const FACING := Vector3(0.0, 0.0, -2.0)
const CONTACT_OFFSET: Dictionary[int, int] = { 30: 9, 60: 17 }
# The target 0,5 m dead ahead: the blade is inside its body on every active tick (combat_contact_
# test.gd, the parked blade), so the contact is the first active tick, 15 or 8 ticks after the
# press: the contact the advantage table counts from (combate.md, "O tranco e a vantagem").
const PARKED := Vector3(0.0, 0.0, -0.5)
# A second attacker 1,5 m behind the first, 2,0 m from the parked target, looking down -Z too: its
# slice reaches the target, and the first attacker, on the same tick the FACING geometry gives.
const SECOND_FEET := Vector3(0.0, 0.0, 1.5)
# Looking back at the attacker: the direction from the target's feet to the attacker's is +Z, the
# yaw pi (Blade.direction: yaw 0 looks down -Z, a positive angle turns left). The guard's front is
# this yaw turned by up to 90° to either side.
const FACING_THE_ATTACKER := PI
# A contact 10 ticks after the hold began leaves the guard up for the FACING contact at both rates.
const PRESS_AFTER_HOLD := 10
const SPARE_TICKS := 6 # ticks a run keeps going past the last event: arithmetic
const HAIR := 1e-6 # floating-point slack, not a design number


func _fighter(
	name: StringName,
	tickrate: int,
	feet: Vector3,
	yaw: float,
	combat: CombatConfig,
) -> GuardRig:
	return GuardRig.new(name, MovementRig.load_config(tickrate), combat, FIRST_TICK, feet, yaw)


# A script that presses the light on the given ticks, the camera on yaw.
func _presser(presses: PackedInt32Array, yaw: float) -> Callable:
	return func(tick: int) -> TickInput:
		if presses.has(tick):
			return GuardRig.press_light(Vector2.ZERO, yaw)
		return GuardRig.idle(yaw)


# A script that holds the guard from `from` to `to`, inclusive, the camera on yaw, pressing nothing.
func _guarder(from: int, to: int, yaw: float) -> Callable:
	return func(tick: int) -> TickInput:
		var input := GuardRig.idle(yaw)
		input.guard = tick >= from and tick <= to
		return input


# The target at target_feet with its own script, index 0, and the attacker at the origin looking
# down -Z pressing the light on `presses`, index 1.
func _duel(
	tickrate: int,
	target_feet: Vector3,
	target_yaw: float,
	target_script: Callable,
	presses: PackedInt32Array,
	combat: CombatConfig = null,
) -> Duel:
	var config := combat if combat != null else GuardRig.load_combat(tickrate)
	var duel := Duel.new()
	duel.add(_fighter(TARGET, tickrate, target_feet, target_yaw, config), target_script)
	duel.add(_fighter(ATTACKER, tickrate, Vector3.ZERO, 0.0, config), _presser(presses, 0.0))
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


# The target's combat output on the tick after the contact shows the block: no damage, the
# block's stamp, the blockstun to contact + 15 + 2, the freeze to contact + 2, and 5 paid.
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


# The target's combat output on the tick after the contact shows the hit as without a guard: the
# damage, the hurt stamp, the hitstun to contact + 24 + 4, the freeze to contact + 4, nothing paid.
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
		maxi(0, health_before - LIGHT_DAMAGE)
	)
	assert_int(state.block_tick).override_failure_message(message).is_equal(FighterState.NEVER)
	assert_int(state.stun_until_tick).override_failure_message(message).is_equal(
		contact + HITSTUN_TICKS[tickrate] + HITSTOP_HIT_TICKS[tickrate]
	)
	assert_int(state.frozen_until_tick).override_failure_message(message).is_equal(
		contact + HITSTOP_HIT_TICKS[tickrate]
	)


func _assert_contact_stamped(duel: Duel, index: int, contact: int, target_name: StringName) -> void:
	var row := duel.row_at(contact)
	var state := row.fought[index]
	var message := "tick %d: contact (%d, %s, %s), expected (%d, %s)" % [
		row.tick,
		state.contact_tick,
		state.contact_target,
		state.contact_move,
		contact,
		target_name,
	]
	assert_int(state.contact_tick).override_failure_message(message).is_equal(contact)
	assert_str(String(state.contact_target)).override_failure_message(message).is_equal(
		String(target_name)
	)


# The first tick after `from` on which the fighter acts again: its action NONE, or BLOCK with the
# button held (combate.md, "O tranco e a vantagem": "quem volta a agir primeiro").
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


# Criterion 2: with the guard up and the attacker within 90° of where the target looks, the light
# is blocked: the attacker stamps its contact as always, and on the next tick the target shows no
# damage, the block's stamp, 5 paid, the blockstun and the freeze (DEC-0055 §3; DEC-0054 §2). The
# limit is a hair inside 90° to either side.
func test_a_light_on_the_guard_up_from_the_front_is_blocked(
	tickrate: int,
	turned_deg: float,
	_test_parameters := [
		[30, 0.0],
		[60, 0.0],
		[60, 60.0],
		[60, -60.0],
		[60, HALF_ANGLE_DEG - 0.5],
		[60, -(HALF_ANGLE_DEG - 0.5)],
		[30, HALF_ANGLE_DEG - 0.5],
	],
) -> void:
	var press := FIRST_TICK + PRESS_AFTER_HOLD
	var contact := press + CONTACT_OFFSET[tickrate]
	var yaw := FACING_THE_ATTACKER + deg_to_rad(turned_deg)
	var duel := _duel(
		tickrate,
		FACING,
		yaw,
		_guarder(FIRST_TICK, contact + SPARE_TICKS, yaw),
		PackedInt32Array([press]),
	)
	duel.run_through(contact + SPARE_TICKS)
	_assert_contact_stamped(duel, 1, contact, TARGET)
	_assert_blocked(duel, contact, tickrate, STAMINA_MAX)
	# Before the contact is applied, nothing: the guard up and the bar full.
	var before := duel.row_at(contact).fought[0]
	assert_int(before.action).is_equal(FighterState.Action.BLOCK)
	assert_int(before.block_tick).is_equal(FighterState.NEVER)
	assert_float(Stamina.at(before, duel.fighter(0).config(), contact)).is_equal_approx(
		STAMINA_MAX,
		HAIR,
	)


# Criterion 3: from beyond 90° of where the target looks, up to its very back, the light hits as
# without a guard: the damage, the hitstun and nothing paid (DEC-0054 §2: "pelas costas, o golpe
# pega como se não houvesse guarda"). The limit is a hair beyond 90° to either side.
func test_a_light_from_beyond_90_degrees_hits_as_without_a_guard(
	tickrate: int,
	turned_deg: float,
	_test_parameters := [
		[60, HALF_ANGLE_DEG + 0.5],
		[60, -(HALF_ANGLE_DEG + 0.5)],
		[60, 135.0],
		[60, 180.0],
		[30, 180.0],
		[30, -(HALF_ANGLE_DEG + 0.5)],
	],
) -> void:
	var press := FIRST_TICK + PRESS_AFTER_HOLD
	var contact := press + CONTACT_OFFSET[tickrate]
	var yaw := FACING_THE_ATTACKER + deg_to_rad(turned_deg)
	var duel := _duel(
		tickrate,
		FACING,
		yaw,
		_guarder(FIRST_TICK, contact + SPARE_TICKS, yaw),
		PackedInt32Array([press]),
	)
	duel.run_through(contact + SPARE_TICKS)
	_assert_contact_stamped(duel, 1, contact, TARGET)
	_assert_hit(duel, contact, tickrate, MAX_HEALTH)
	var after := duel.row_at(contact + 1).fought[0]
	assert_int(after.stamina_spent_tick).override_failure_message("the hit paid stamina") \
			.is_equal(FighterState.NEVER)


# Criterion 3, the limit of the rise: the guard is up on the contact tick when the hold began 6
# ticks before it (3 at 30), and the light is blocked; begun one tick later, the 6 ticks are not
# complete at the contact, and the light hits (combate.md, "Quando o bloqueio vale": "com os 6
# ticks completos [...] no tick do contato").
func test_a_light_landing_before_the_guards_6_ticks_complete_hits_and_on_the_6th_is_blocked(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var press := FIRST_TICK + PRESS_AFTER_HOLD
	var contact := press + CONTACT_OFFSET[tickrate]
	var raise := GUARD_RAISE_TICKS[tickrate]
	var in_time := _duel(
		tickrate,
		FACING,
		FACING_THE_ATTACKER,
		_guarder(contact - raise, contact + SPARE_TICKS, FACING_THE_ATTACKER),
		PackedInt32Array([press]),
	)
	in_time.run_through(contact + SPARE_TICKS)
	assert_int(in_time.row_at(contact - raise).fought[0].action).is_equal(FighterState.Action.BLOCK)
	_assert_blocked(in_time, contact, tickrate, STAMINA_MAX)
	var late := _duel(
		tickrate,
		FACING,
		FACING_THE_ATTACKER,
		_guarder(contact - raise + 1, contact + SPARE_TICKS, FACING_THE_ATTACKER),
		PackedInt32Array([press]),
	)
	late.run_through(contact + SPARE_TICKS)
	assert_int(late.row_at(contact).fought[0].action).is_equal(FighterState.Action.BLOCK)
	_assert_hit(late, contact, tickrate, MAX_HEALTH)


# DEC-0055 §3: the defender resolves the contact on its own state as the contact tick left it.
# The button released on the contact tick leaves no guard at the end of that tick, and the light
# hits; released on the tick after, the guard was still up when the contact tick ended, and the
# light is blocked.
func test_the_block_reads_the_guard_as_the_contact_tick_left_it(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var press := FIRST_TICK + PRESS_AFTER_HOLD
	var contact := press + CONTACT_OFFSET[tickrate]
	var released_on_contact := _duel(
		tickrate,
		FACING,
		FACING_THE_ATTACKER,
		_guarder(FIRST_TICK, contact - 1, FACING_THE_ATTACKER),
		PackedInt32Array([press]),
	)
	released_on_contact.run_through(contact + SPARE_TICKS)
	assert_int(released_on_contact.row_at(contact).fought[0].action).is_equal(
		FighterState.Action.NONE
	)
	_assert_hit(released_on_contact, contact, tickrate, MAX_HEALTH)
	var released_after := _duel(
		tickrate,
		FACING,
		FACING_THE_ATTACKER,
		_guarder(FIRST_TICK, contact, FACING_THE_ATTACKER),
		PackedInt32Array([press]),
	)
	released_after.run_through(contact + SPARE_TICKS)
	_assert_blocked(released_after, contact, tickrate, STAMINA_MAX)


# Criterion 5: with less than 5 on the bar when the contact is applied, the guard falls and the
# light hits with the full stun, and nothing is paid; with exactly 5, the limit, it is blocked and
# the bar goes to 0 (combate.md, "Sem stamina para o custo, a guarda cai no golpe"). The bar is set
# by hand, stamped at the first tick so it regains nothing before the contact (the wait of 800 ms).
func test_with_less_than_5_stamina_the_guard_falls_and_with_exactly_5_it_blocks(
	tickrate: int,
	bar: float,
	blocks: bool,
	_test_parameters := [[30, BELOW_COST, false], [60, BELOW_COST, false], [60, BLOCK_COST, true]],
) -> void:
	var press := FIRST_TICK + PRESS_AFTER_HOLD
	var contact := press + CONTACT_OFFSET[tickrate]
	assert_int(contact + 1 - FIRST_TICK).override_failure_message("the bar would regain") \
			.is_less(STAMINA_WAIT_TICKS[tickrate])
	var duel := _duel(
		tickrate,
		FACING,
		FACING_THE_ATTACKER,
		_guarder(FIRST_TICK, contact + SPARE_TICKS, FACING_THE_ATTACKER),
		PackedInt32Array([press]),
	)
	var target := duel.fighter(0)
	target.state().stamina_at_spend = bar
	target.state().stamina_spent_tick = FIRST_TICK
	assert_float(target.stamina()).is_equal_approx(bar, HAIR)
	duel.run_through(contact + SPARE_TICKS)
	assert_int(duel.row_at(contact).fought[0].action).is_equal(FighterState.Action.BLOCK)
	if blocks:
		_assert_blocked(duel, contact, tickrate, bar)
	else:
		_assert_hit(duel, contact, tickrate, MAX_HEALTH)
		var after := duel.row_at(contact + 1).fought[0]
		assert_int(after.stamina_spent_tick).override_failure_message("the fall paid stamina") \
				.is_equal(FIRST_TICK)
		assert_float(Stamina.at(after, target.config(), contact + 1)).is_equal_approx(bar, HAIR)


# Criterion 2: the 5 are paid on the contact, so the wait of 800 ms runs from there: the bar reads
# 95 when the contact is applied, still 95 a wait later, and regains after it (movimento.md,
# "Stamina").
func test_the_block_costs_5_stamina_paid_on_the_contact(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var press := FIRST_TICK + PRESS_AFTER_HOLD
	var contact := press + CONTACT_OFFSET[tickrate]
	var wait := STAMINA_WAIT_TICKS[tickrate]
	var duel := _duel(
		tickrate,
		FACING,
		FACING_THE_ATTACKER,
		_guarder(FIRST_TICK, contact + wait + SPARE_TICKS, FACING_THE_ATTACKER),
		PackedInt32Array([press]),
	)
	duel.run_through(contact + wait + SPARE_TICKS)
	var config := duel.fighter(0).config()
	var paid := duel.row_at(contact + 1).fought[0]
	assert_float(Stamina.at(paid, config, contact + 1)).is_equal_approx(
		STAMINA_MAX - BLOCK_COST,
		HAIR,
	)
	assert_bool(paid.stamina_spent_tick == contact or paid.stamina_spent_tick == contact + 1) \
			.override_failure_message("paid at %d, expected the contact %d or the tick after"
	% [paid.stamina_spent_tick, contact]) \
			.is_true()
	var waiting := duel.row_at(contact + wait).fought[0]
	assert_float(Stamina.at(waiting, config, contact + wait)).is_equal_approx(
		STAMINA_MAX - BLOCK_COST,
		HAIR,
	)
	var regained := duel.row_at(contact + wait + 3).fought[0]
	assert_float(Stamina.at(regained, config, contact + wait + 3)).is_greater(
		STAMINA_MAX - BLOCK_COST
	)


# Criterion 2: the blockstun holds the target from the tick after the contact until contact + 15
# plus the hitstop of 2, when it acts again, the guard already back since the button is still
# held; the attacker keeps its recovery, never stunned, never hurt, its swing ending 2 ticks later
# than alone, the hitstop (combate.md, "O tranco e a vantagem": "quem bateu segue a recuperação").
func test_the_blockstun_lasts_15_ticks_from_the_contact_plus_the_hitstop_and_the_attacker_recovers(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var press := FIRST_TICK + PRESS_AFTER_HOLD
	var contact := press + CONTACT_OFFSET[tickrate]
	var ends := contact + BLOCKSTUN_TICKS[tickrate] + HITSTOP_BLOCK_TICKS[tickrate]
	var swing_end := press + SWING_TICKS[tickrate] + HITSTOP_BLOCK_TICKS[tickrate]
	var last := maxi(ends, swing_end) + SPARE_TICKS
	var duel := _duel(
		tickrate,
		FACING,
		FACING_THE_ATTACKER,
		_guarder(FIRST_TICK, last, FACING_THE_ATTACKER),
		PackedInt32Array([press]),
	)
	duel.run_through(last)
	_assert_blocked(duel, contact, tickrate, STAMINA_MAX)
	var violations: Array[String] = []
	for row: Duel.Row in duel.rows:
		var target := row.fought[0]
		var attacker := row.fought[1]
		var in_stun := row.tick > contact and row.tick < ends
		if in_stun and target.action != FighterState.Action.BLOCKSTUN:
			violations.append(
				"tick %d: target %s, expected BLOCKSTUN" % [row.tick, _action_line(target)]
			)
		if row.tick >= ends and target.action != FighterState.Action.BLOCK:
			violations.append(
				"tick %d: target %s, expected BLOCK again" % [row.tick, _action_line(target)]
			)
		var stunned := (
			attacker.action == FighterState.Action.HITSTUN
			or attacker.action == FighterState.Action.BLOCKSTUN
		)
		if stunned or attacker.health != MAX_HEALTH or attacker.hurt_tick != FighterState.NEVER:
			violations.append("tick %d: attacker %s" % [row.tick, _action_line(attacker)])
		if (
			row.tick >= press and row.tick < swing_end
			and attacker.action == FighterState.Action.NONE
		):
			violations.append(
				"tick %d: the attacker's swing ended before %d" % [row.tick, swing_end]
			)
		if row.tick >= swing_end and attacker.action != FighterState.Action.NONE:
			violations.append(
				"tick %d: attacker %s, expected NONE from %d"
				% [row.tick, _action_line(attacker), swing_end]
			)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	assert_int(_acts_again(duel, 0, contact + 1)).is_equal(ends)


# Criterion 2 (DEC-0052 §4; combate.md, "O tranco e a vantagem", the row "Leve bloqueado"): with
# the contact on the first active tick, the blocker acts again 3 ticks before the attacker, at 60.
func test_after_a_block_the_blocker_is_3_ticks_ahead() -> void:
	var tickrate := 60
	var press := FIRST_TICK + PRESS_AFTER_HOLD
	var contact := press + WINDUP_TICKS[tickrate]
	var last := press + SWING_TICKS[tickrate] + HITSTOP_BLOCK_TICKS[tickrate] + SPARE_TICKS
	var duel := _duel(
		tickrate,
		PARKED,
		FACING_THE_ATTACKER,
		_guarder(FIRST_TICK, last, FACING_THE_ATTACKER),
		PackedInt32Array([press]),
	)
	duel.run_through(last)
	_assert_contact_stamped(duel, 1, contact, TARGET)
	_assert_blocked(duel, contact, tickrate, STAMINA_MAX)
	var blocker_free := _acts_again(duel, 0, contact + 1)
	var attacker_free := _acts_again(duel, 1, contact + 1)
	var message := "blocker acts at %d, attacker at %d" % [blocker_free, attacker_free]
	assert_int(attacker_free - blocker_free).override_failure_message(message).is_equal(
		BLOCK_ADVANTAGE
	)


# combate.md, "O tranco no tick": "Depois do blockstun, com o botão ainda segurado, a guarda já
# está alta, sem subir de novo": a second light whose contact lands one tick after the blockstun
# ends, before 6 ticks could pass, is blocked too.
func test_after_the_blockstun_with_the_button_held_the_guard_is_already_up(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var press := FIRST_TICK + PRESS_AFTER_HOLD
	var first_contact := press + WINDUP_TICKS[tickrate]
	var ends := first_contact + BLOCKSTUN_TICKS[tickrate] + HITSTOP_BLOCK_TICKS[tickrate]
	var second_contact := ends + 1
	assert_int(second_contact - ends).is_less(GUARD_RAISE_TICKS[tickrate])
	var second_press := second_contact - CONTACT_OFFSET[tickrate]
	var last := second_contact + SPARE_TICKS
	var combat := GuardRig.load_combat(tickrate)
	var duel := _duel(
		tickrate,
		PARKED,
		FACING_THE_ATTACKER,
		_guarder(FIRST_TICK, last, FACING_THE_ATTACKER),
		PackedInt32Array([press]),
		combat,
	)
	duel.add(
		_fighter(SECOND, tickrate, SECOND_FEET, 0.0, combat),
		_presser(PackedInt32Array([second_press]), 0.0),
	)
	duel.run_through(last)
	_assert_blocked(duel, first_contact, tickrate, STAMINA_MAX)
	_assert_contact_stamped(duel, 2, second_contact, TARGET)
	_assert_blocked(duel, second_contact, tickrate, STAMINA_MAX - BLOCK_COST)


# combate.md, "O tranco no tick": "Um golpe novo no meio do tranco o recomeça do contato novo", and
# the blockstun counts as the guard up (TASK-12.2 plan): a second light that lands during the
# blockstun is blocked too, costs 5 more, and the blockstun runs from the second contact.
func test_a_light_blocked_during_the_blockstun_restarts_it_from_the_new_contact(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var press := FIRST_TICK + PRESS_AFTER_HOLD
	var first_contact := press + WINDUP_TICKS[tickrate]
	var first_ends := first_contact + BLOCKSTUN_TICKS[tickrate] + HITSTOP_BLOCK_TICKS[tickrate]
	var second_contact := first_contact + HITSTOP_BLOCK_TICKS[tickrate] + 3
	assert_int(second_contact).is_less(first_ends)
	var second_press := second_contact - CONTACT_OFFSET[tickrate]
	var second_ends := second_contact + BLOCKSTUN_TICKS[tickrate] + HITSTOP_BLOCK_TICKS[tickrate]
	var last := second_ends + SPARE_TICKS
	var combat := GuardRig.load_combat(tickrate)
	var duel := _duel(
		tickrate,
		PARKED,
		FACING_THE_ATTACKER,
		_guarder(FIRST_TICK, last, FACING_THE_ATTACKER),
		PackedInt32Array([press]),
		combat,
	)
	duel.add(
		_fighter(SECOND, tickrate, SECOND_FEET, 0.0, combat),
		_presser(PackedInt32Array([second_press]), 0.0),
	)
	duel.run_through(last)
	_assert_blocked(duel, first_contact, tickrate, STAMINA_MAX)
	_assert_contact_stamped(duel, 2, second_contact, TARGET)
	_assert_blocked(duel, second_contact, tickrate, STAMINA_MAX - BLOCK_COST)
	var at_first_end := duel.row_at(first_ends).fought[0]
	assert_int(at_first_end.action).override_failure_message(_action_line(at_first_end)).is_equal(
		FighterState.Action.BLOCKSTUN
	)
	assert_int(_acts_again(duel, 0, second_contact + 1)).is_equal(second_ends)


# The button released during the blockstun: when it ends, no guard is up.
func test_released_during_the_blockstun_the_guard_is_down_when_it_ends() -> void:
	var tickrate := 60
	var press := FIRST_TICK + PRESS_AFTER_HOLD
	var contact := press + CONTACT_OFFSET[tickrate]
	var ends := contact + BLOCKSTUN_TICKS[tickrate] + HITSTOP_BLOCK_TICKS[tickrate]
	var duel := _duel(
		tickrate,
		FACING,
		FACING_THE_ATTACKER,
		_guarder(FIRST_TICK, ends - 2, FACING_THE_ATTACKER),
		PackedInt32Array([press]),
	)
	duel.run_through(ends + SPARE_TICKS)
	_assert_blocked(duel, contact, tickrate, STAMINA_MAX)
	var before := duel.row_at(ends - 1).fought[0]
	assert_int(before.action).override_failure_message(_action_line(before)).is_equal(
		FighterState.Action.BLOCKSTUN
	)
	var after := duel.row_at(ends).fought[0]
	assert_int(after.action).override_failure_message(_action_line(after)).is_equal(
		FighterState.Action.NONE
	)
	assert_int(_acts_again(duel, 0, contact + 1)).is_equal(ends)


# None: a light that touches nobody blocks nothing: the target with the guard up beyond the reach
# of 2,43 m (combate.md, "A lâmina e o contato": "Alcance efetivo") keeps its bar, its health and
# its guard.
func test_a_light_that_touches_nobody_blocks_nothing() -> void:
	var tickrate := 60
	var press := FIRST_TICK + PRESS_AFTER_HOLD
	var last := press + SWING_TICKS[tickrate] + SPARE_TICKS
	var duel := _duel(
		tickrate,
		Vector3(0.0, 0.0, -2.5),
		FACING_THE_ATTACKER,
		_guarder(FIRST_TICK, last, FACING_THE_ATTACKER),
		PackedInt32Array([press]),
	)
	duel.run_through(last)
	assert_int(duel.contact_tick_of(1)).is_equal(FighterState.NEVER)
	for row: Duel.Row in duel.rows:
		var target := row.fought[0]
		assert_int(target.block_tick).override_failure_message("tick %d" % row.tick).is_equal(
			FighterState.NEVER
		)
		assert_int(target.hurt_tick).is_equal(FighterState.NEVER)
		assert_int(target.stamina_spent_tick).is_equal(FighterState.NEVER)
		assert_int(target.action).is_equal(FighterState.Action.BLOCK)
