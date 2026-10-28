# Criterion 4 of TASK-12.2: the hitstun (glossario.md, "Tranco"; combate.md, "O tranco e a
# vantagem": "O tranco no tick" and "O tranco e o corpo"; DEC-0055 §3), through the public
# interface of core/fighter, with GuardRigs and a TickPhoto taken by hand on every tick (Duel). A
# light that hits takes 12 and holds the target 24 ticks from the contact, plus the hitstop; in the
# stun the stick is ignored and the ground stops the body, gravity goes on, no command fires and
# the presses wait in the slot; the target's own swing in progress ends; a new hit in the stun
# restarts it from the new contact; the attacker is 6 ticks ahead. Every number comes from
# docs/design, cited by section; ticks by hand from the ms, nearest tick with ties up.
extends GdUnitTestSuite

const GuardRig := preload("res://test/core/fighter/guard_rig.gd")
const MovementRig := preload("res://test/core/fighter/movement_rig.gd")
const Duel := preload("res://test/core/fighter/duel.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)
# The target first by name: a slice touching two fighters on one tick gives its contact to the
# first by name (combate.md, "O leve no tick": "Os alvos são testados em ordem de nome").
const TARGET := &"A"
const ATTACKER := &"B"
const SECOND := &"C"
const LIGHT := &"light_attack" # the move's ID (glossario.md, "Golpe leve"; TASK-12.1 plan)

# combate.md, "Os golpes e as defesas", the row "Golpe leve": 250 / 100 / 200 ms, 12 de dano
# (DEC-0052); by hand 15 / 6 / 12 ticks at 60 and 8 / 3 / 6 at 30, a swing of 33 or 17 ticks.
const LIGHT_DAMAGE := 12
const WINDUP_TICKS: Dictionary[int, int] = { 30: 8, 60: 15 }
const SWING_TICKS: Dictionary[int, int] = { 30: 17, 60: 33 }
# combate.md, "O tranco e a vantagem": "Leve acerta: 400 ms, 24 ticks", 12 at 30; the stun ends at
# contact + stun + hitstop (TASK-12.2 plan; "O tranco no tick": "mais a paradinha").
const HITSTUN_TICKS: Dictionary[int, int] = { 30: 12, 60: 24 }
# combate.md, "O hitstop e o tremor": "Leve acerta: 67 ms, 4 ticks"; by hand 2 at 30.
const HITSTOP_HIT_TICKS: Dictionary[int, int] = { 30: 2, 60: 4 }
# combate.md, "O tranco e a vantagem", the row "Leve acerta": "quem bateu +6" at 60, with the
# contact on the first active tick: the hitstun of 24 against the 18 the attacker still owes.
const HIT_ADVANTAGE := 6
# combate.md, "O bloqueio, a guarda andando e a stamina": the guard rises in 100 ms, 6 ticks at 60
# and 3 at 30.
const GUARD_RAISE_TICKS: Dictionary[int, int] = { 30: 3, 60: 6 }
# movimento.md, "Chão": "Velocidade de corrida: 7 m/s"; "Tempo até a velocidade máxima: 150 ms", 9
# ticks at 60 and 5 at 30, 7 / 9 = 0,778 m/s per tick; "Tempo até parar: 100 ms", 6 ticks at 60
# and 3 at 30, 7 / 6 = 1,167 m/s less per tick ("Deriva a desaceleração").
const RUN_SPEED_MPS := 7.0
const ACCEL_TICKS: Dictionary[int, int] = { 30: 5, 60: 9 }
const STOP_TICKS: Dictionary[int, int] = { 30: 3, 60: 6 }
# movimento.md, "Perdão": the slot of the buffer keeps a press 150 ms, 9 ticks at 60 and 5 at 30
# (4,5, the tie up), inclusive (DEC-0039).
const BUFFER_TICKS: Dictionary[int, int] = { 30: 5, 60: 9 }
const MAX_HEALTH := 100 # partida.md, "A vida sem partida"

# The target 0,5 m dead ahead of the attacker, who looks down -Z: the blade is inside its body on
# every active tick (test/core/fighter/combat_contact_test.gd, the parked blade), so the contact is
# the first active tick, 15 or 8 ticks after the press, the contact the advantage table counts from.
const PARKED := Vector3(0.0, 0.0, -0.5)
# A second attacker 1,5 m behind the first, 2,0 m from the parked target, looking down -Z: its
# contact comes 17 ticks after its press at 60 and 9 at 30 (combat_contact_test.gd), and it goes
# to the target, first by name, although the slice reaches the first attacker too.
const SECOND_FEET := Vector3(0.0, 0.0, 1.5)
const SECOND_CONTACT_OFFSET: Dictionary[int, int] = { 30: 9, 60: 17 }
# A target 3,0 m ahead that runs at the attacker: from rest it is at the run of 7 m/s when the
# attacker presses, 9 ticks later at 60 (5 at 30), and reaches the blade during the active window.
# The contact tick is read from the attacker's own stamp, not computed by hand.
const RUNNING_FROM := Vector3(0.0, 0.0, -3.0)
# Looking back at the attacker: +Z, the yaw pi; looking away: yaw 0.
const FACING_THE_ATTACKER := PI
const LOOKING_AWAY := 0.0
const FORWARD := Vector2(0, 1) # move.y goes forward, relative to yaw (TASK-9 plan)
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


func _presser(presses: PackedInt32Array, yaw: float, move := Vector2.ZERO) -> Callable:
	return func(tick: int) -> TickInput:
		if presses.has(tick):
			return GuardRig.press_light(move, yaw)
		return GuardRig.walk(move, yaw)


# The idle target, the camera on yaw, holding the guard from `guard_from` on when given.
func _idler(yaw: float, guard_from: int = FighterState.NEVER) -> Callable:
	return func(tick: int) -> TickInput:
		var input := GuardRig.idle(yaw)
		input.guard = guard_from != FighterState.NEVER and tick >= guard_from
		return input


# The target, index 0, and the attacker at the origin looking down -Z, index 1, pressing at
# `press`.
func _duel(
	tickrate: int,
	target_feet: Vector3,
	target_yaw: float,
	target_script: Callable,
	press: int,
	combat: CombatConfig = null,
) -> Duel:
	var config := combat if combat != null else GuardRig.load_combat(tickrate)
	var duel := Duel.new()
	duel.add(_fighter(TARGET, tickrate, target_feet, target_yaw, config), target_script)
	duel.add(
		_fighter(ATTACKER, tickrate, Vector3.ZERO, 0.0, config),
		_presser(PackedInt32Array([press]), 0.0),
	)
	return duel


func _action_line(state: FighterState) -> String:
	return "%s since %d, stun_until %d, frozen_until %d, hurt %d, health %d" % [
		FighterState.Action.find_key(state.action),
		state.action_since,
		state.stun_until_tick,
		state.frozen_until_tick,
		state.hurt_tick,
		state.health,
	]


func _stun_ends(contact: int, tickrate: int) -> int:
	return contact + HITSTUN_TICKS[tickrate] + HITSTOP_HIT_TICKS[tickrate]


# The target's combat output on the tick after the contact shows the hit: the damage, the hurt
# stamp, the hitstun to contact + 24 + 4 and the freeze to contact + 4.
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
	assert_int(state.stun_until_tick).override_failure_message(message).is_equal(
		_stun_ends(contact, tickrate)
	)
	assert_int(state.frozen_until_tick).override_failure_message(message).is_equal(
		contact + HITSTOP_HIT_TICKS[tickrate]
	)


# Every row from `from` to `to`, inclusive, shows the target in the hitstun.
func _assert_stunned_between(duel: Duel, from: int, to: int) -> void:
	var violations: Array[String] = []
	for row: Duel.Row in duel.rows:
		if row.tick < from or row.tick > to:
			continue
		if row.fought[0].action != FighterState.Action.HITSTUN:
			violations.append(
				"tick %d: %s, expected HITSTUN" % [row.tick, _action_line(row.fought[0])]
			)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()


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


# Criterion 4: a light that hits takes 12 on the tick after the contact and holds the target in the
# hitstun from that tick to contact + 24 + 4, the hitstop included; on contact + 28 the target acts
# again, its action NONE (combate.md, "O tranco no tick": "quem levou um leve volta a agir no tick
# contato + 24 [...] mais a paradinha").
func test_a_hit_stuns_the_target_24_ticks_from_the_contact_plus_the_hitstop(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var press := FIRST_TICK + 1
	var contact := press + WINDUP_TICKS[tickrate]
	var ends := _stun_ends(contact, tickrate)
	var duel := _duel(tickrate, PARKED, FACING_THE_ATTACKER, _idler(FACING_THE_ATTACKER), press)
	duel.run_through(ends + SPARE_TICKS)
	assert_int(duel.contact_tick_of(1)).is_equal(contact)
	_assert_hit(duel, contact, tickrate, MAX_HEALTH)
	_assert_stunned_between(duel, contact + 1, ends - 1)
	var before := duel.row_at(contact).fought[0]
	assert_int(before.action).override_failure_message(_action_line(before)).is_equal(
		FighterState.Action.NONE
	)
	assert_int(before.health).is_equal(MAX_HEALTH)
	var after := duel.row_at(ends).fought[0]
	assert_int(after.action).override_failure_message(_action_line(after)).is_equal(
		FighterState.Action.NONE
	)
	assert_int(_acts_again(duel, 0, contact + 1)).is_equal(ends)


# Criterion 4: in the stun no command fires and no action comes out; the presses wait in the slot
# for their 150 ms (combate.md, "O tranco e o corpo": "No tranco não há input de movimento nem de
# ação"; DEC-0039). A jump or a light pressed one tick before the stun ends fires on the tick it
# ends, the tick the target acts again.
func test_a_press_during_the_hitstun_waits_in_the_slot_and_fires_when_the_stun_ends(
	tickrate: int,
	command: StringName,
	_test_parameters := [
		[30, FighterCommand.JUMP],
		[60, FighterCommand.JUMP],
		[30, FighterCommand.LIGHT_ATTACK],
		[60, FighterCommand.LIGHT_ATTACK],
	],
) -> void:
	var press := FIRST_TICK + 1
	var contact := press + WINDUP_TICKS[tickrate]
	var ends := _stun_ends(contact, tickrate)
	var press_tick := ends - 1
	var light := command == FighterCommand.LIGHT_ATTACK
	var script := func(tick: int) -> TickInput:
		if tick != press_tick:
			return GuardRig.idle(FACING_THE_ATTACKER)
		if light:
			return GuardRig.press_light(Vector2.ZERO, FACING_THE_ATTACKER)
		return MovementRig.press_jump_toward(Vector2.ZERO, FACING_THE_ATTACKER)
	var duel := _duel(tickrate, PARKED, FACING_THE_ATTACKER, script, press)
	duel.run_through(ends + SPARE_TICKS)
	_assert_hit(duel, contact, tickrate, MAX_HEALTH)
	var waiting := duel.row_at(press_tick)
	assert_int(waiting.fought[0].action).is_equal(FighterState.Action.HITSTUN)
	assert_str(String(waiting.ends[0].buffered_command)).is_equal(String(command))
	assert_int(waiting.ends[0].buffered_tick).is_equal(press_tick)
	assert_int(waiting.ends[0].jumps_used).override_failure_message("jumped in the stun").is_equal(
		0
	)
	var fired := duel.row_at(ends)
	if light:
		assert_int(fired.fought[0].action).override_failure_message(_action_line(fired.fought[0])) \
				.is_equal(FighterState.Action.WINDUP)
		assert_int(fired.fought[0].action_since).is_equal(ends)
		assert_str(String(fired.fought[0].action_move)).is_equal(String(LIGHT))
	else:
		assert_int(fired.fought[0].action).is_equal(FighterState.Action.NONE)
		assert_int(fired.plans[0].state.jumps_used).override_failure_message("no jump at the end") \
				.is_equal(1)
		assert_float(fired.plans[0].velocity.y).is_equal_approx(
			duel.fighter(0).config().jump_speed,
			HAIR,
		)
	assert_str(String(fired.ends[0].buffered_command)).is_equal(String(FighterCommand.NONE))


# Criterion 4: a jump pressed early in the stun never comes out while it lasts and leaves the slot
# when its window closes, long before the stun ends.
func test_a_jump_pressed_early_in_the_hitstun_is_dropped_when_its_window_closes(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var press := FIRST_TICK + 1
	var contact := press + WINDUP_TICKS[tickrate]
	var ends := _stun_ends(contact, tickrate)
	var press_tick := contact + HITSTOP_HIT_TICKS[tickrate] + 1
	var dropped_at := press_tick + BUFFER_TICKS[tickrate] + 1
	assert_int(dropped_at).is_less(ends)
	var script := func(tick: int) -> TickInput:
		if tick == press_tick:
			return MovementRig.press_jump_toward(Vector2.ZERO, FACING_THE_ATTACKER)
		return GuardRig.idle(FACING_THE_ATTACKER)
	var duel := _duel(tickrate, PARKED, FACING_THE_ATTACKER, script, press)
	duel.run_through(ends + SPARE_TICKS)
	_assert_hit(duel, contact, tickrate, MAX_HEALTH)
	var violations: Array[String] = []
	for row: Duel.Row in duel.rows:
		if row.tick <= contact or row.tick >= ends:
			continue
		var end := row.ends[0]
		if end.jumps_used != 0 or end.mode != FighterState.Mode.GROUND or not end.on_floor:
			violations.append("tick %d: jumped in the stun" % row.tick)
		if row.tick >= press_tick and row.tick < dropped_at:
			if end.buffered_command != FighterCommand.JUMP or end.buffered_tick != press_tick:
				violations.append(
					"tick %d: slot (%s, %d), expected the jump of %d"
					% [row.tick, end.buffered_command, end.buffered_tick, press_tick]
				)
		elif end.buffered_command != FighterCommand.NONE:
			violations.append(
				"tick %d: slot (%s, %d), expected empty"
				% [row.tick, end.buffered_command, end.buffered_tick]
			)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	var after := duel.row_at(ends)
	assert_int(after.plans[0].state.jumps_used).is_equal(0)
	assert_float(after.plans[0].velocity.y).is_equal(0.0)


# Criterion 4: in the stun the stick is ignored and the ground stops the body (combate.md, "O
# tranco e o corpo": "a velocidade horizontal cai pela desaceleração do chão"): a target that runs
# at the attacker at 7 m/s, the stick held the whole time, keeps its 7 through the frozen ticks and
# then loses 7 / 6 per tick to rest, stays at rest until the stun ends, and runs again on the tick
# it acts. The contact tick is read from the attacker's stamp.
func test_in_the_hitstun_the_stick_is_ignored_and_the_ground_stops_the_body(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var press := FIRST_TICK + ACCEL_TICKS[tickrate]
	var duel := _duel(
		tickrate,
		RUNNING_FROM,
		FACING_THE_ATTACKER,
		_presser(PackedInt32Array(), FACING_THE_ATTACKER, FORWARD),
		press,
	)
	duel.run_through(press + SWING_TICKS[tickrate])
	var contact := duel.contact_tick_of(1)
	assert_int(contact).override_failure_message("the running target was never touched") \
			.is_not_equal(FighterState.NEVER)
	var ends := _stun_ends(contact, tickrate)
	duel.run_through(ends + SPARE_TICKS)
	_assert_hit(duel, contact, tickrate, MAX_HEALTH)
	var thaw := contact + HITSTOP_HIT_TICKS[tickrate] + 1
	var decel := RUN_SPEED_MPS / STOP_TICKS[tickrate]
	var accel := RUN_SPEED_MPS / ACCEL_TICKS[tickrate]
	var violations: Array[String] = []
	for row: Duel.Row in duel.rows:
		var speed := Vector3(row.velocities[0].x, 0.0, row.velocities[0].z).length()
		var expected := RUN_SPEED_MPS
		if row.tick < press:
			continue
		if row.tick > contact and row.tick < thaw:
			expected = RUN_SPEED_MPS # frozen: the velocity kept in the body
			if not row.plans[0].frozen:
				violations.append("tick %d: not frozen" % row.tick)
		elif row.tick >= thaw and row.tick < ends:
			expected = maxf(0.0, RUN_SPEED_MPS - (row.tick - thaw + 1) * decel)
		elif row.tick >= ends:
			expected = minf(RUN_SPEED_MPS, (row.tick - ends + 1) * accel)
		if absf(speed - expected) > HAIR:
			violations.append("tick %d: %.3f m/s, expected %.3f" % [row.tick, speed, expected])
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	assert_int(_acts_again(duel, 0, contact + 1)).is_equal(ends)


# Criterion 4: gravity goes on in the stun (combate.md, "O tranco e o corpo": "a gravidade
# continua"): the floor taken away under the stunned target, after its freeze, the body falls into
# the void, in the air for the rules, the stun running on and the stick still ignored.
func test_gravity_continues_during_the_hitstun(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var press := FIRST_TICK + 1
	var contact := press + WINDUP_TICKS[tickrate]
	var ends := _stun_ends(contact, tickrate)
	var ledge_at := contact + HITSTOP_HIT_TICKS[tickrate] + 2
	# Still until the contact, so the blade finds it parked; then the stick is pushed through the
	# whole stun and the fall.
	var script := func(tick: int) -> TickInput:
		var move := FORWARD if tick > contact else Vector2.ZERO
		return GuardRig.walk(move, FACING_THE_ATTACKER)
	var duel := _duel(tickrate, PARKED, FACING_THE_ATTACKER, script, press)
	duel.run_through(ledge_at - 1)
	_assert_hit(duel, contact, tickrate, MAX_HEALTH)
	duel.fighter(0).rig.floor_on = false
	duel.run_through(ends - 1)
	_assert_stunned_between(duel, contact + 1, ends - 1)
	var last := duel.row_at(ends - 1)
	assert_int(last.ends[0].mode).override_failure_message("still on the ground in the void") \
			.is_equal(FighterState.Mode.AIR)
	assert_float(last.feet[0].y).override_failure_message("did not fall").is_less(0.0)
	assert_float(last.velocities[0].y).override_failure_message("no gravity").is_less(0.0)
	var horizontal := Vector3(last.velocities[0].x, 0.0, last.velocities[0].z)
	assert_float(horizontal.length()).override_failure_message("the stick moved the stunned body") \
			.is_equal_approx(0.0, HAIR)


# Criterion 4: the target's own swing in progress ends with the hit (combate.md, "O tranco no
# tick": "um golpe que ele começou nesse tick acaba quando o tranco chega"; DEC-0055 §3): a light
# in its windup when the contact is applied never reaches its active window, touches nobody, and
# does not resume when the stun ends.
func test_a_hit_ends_the_targets_swing_in_progress(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var press := FIRST_TICK + 1
	var contact := press + WINDUP_TICKS[tickrate]
	var ends := _stun_ends(contact, tickrate)
	var own_press := contact - 3
	var duel := _duel(
		tickrate,
		PARKED,
		FACING_THE_ATTACKER,
		_presser(PackedInt32Array([own_press]), FACING_THE_ATTACKER),
		press,
	)
	duel.run_through(ends + SPARE_TICKS)
	var swinging := duel.row_at(contact).fought[0]
	assert_int(swinging.action).override_failure_message(_action_line(swinging)).is_equal(
		FighterState.Action.WINDUP
	)
	assert_int(swinging.action_since).is_equal(own_press)
	_assert_hit(duel, contact, tickrate, MAX_HEALTH)
	_assert_stunned_between(duel, contact + 1, ends - 1)
	assert_int(duel.contact_tick_of(0)).override_failure_message("the ended swing touched") \
			.is_equal(FighterState.NEVER)
	for row: Duel.Row in duel.rows:
		var attacker := row.fought[1]
		assert_int(attacker.health).override_failure_message("tick %d" % row.tick).is_equal(
			MAX_HEALTH
		)
		assert_int(attacker.hurt_tick).is_equal(FighterState.NEVER)
		if row.tick > contact:
			assert_int(row.fought[0].action) \
					.override_failure_message("tick %d: %s"
			% [row.tick, _action_line(row.fought[0])]) \
					.is_not_equal(FighterState.Action.ACTIVE)
	var after := duel.row_at(ends).fought[0]
	assert_int(after.action).override_failure_message(_action_line(after)).is_equal(
		FighterState.Action.NONE
	)


# Criterion 4: a new hit in the middle of the stun restarts it from the new contact (combate.md, "O
# tranco no tick": "Um golpe novo no meio do tranco o recomeça do contato novo"): the second
# attacker's light takes 12 more, moves the hurt stamp, and the stun ends 24 + 4 after the second
# contact, the first end tick passing in the stun.
func test_a_new_hit_during_the_hitstun_restarts_it_from_the_new_contact(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var press := FIRST_TICK + 1
	var first_contact := press + WINDUP_TICKS[tickrate]
	var first_ends := _stun_ends(first_contact, tickrate)
	var second_contact := first_contact + HITSTOP_HIT_TICKS[tickrate] + 6
	assert_int(second_contact).is_less(first_ends)
	var second_press := second_contact - SECOND_CONTACT_OFFSET[tickrate]
	var second_ends := _stun_ends(second_contact, tickrate)
	var combat := GuardRig.load_combat(tickrate)
	var duel := _duel(
		tickrate,
		PARKED,
		FACING_THE_ATTACKER,
		_idler(FACING_THE_ATTACKER),
		press,
		combat,
	)
	duel.add(
		_fighter(SECOND, tickrate, SECOND_FEET, 0.0, combat),
		_presser(PackedInt32Array([second_press]), 0.0),
	)
	duel.run_through(second_ends + SPARE_TICKS)
	_assert_hit(duel, first_contact, tickrate, MAX_HEALTH)
	assert_int(duel.contact_tick_of(2)).is_equal(second_contact)
	assert_str(String(duel.row_at(second_contact).fought[2].contact_target)).is_equal(
		String(TARGET)
	)
	_assert_hit(duel, second_contact, tickrate, MAX_HEALTH - LIGHT_DAMAGE)
	_assert_stunned_between(duel, first_contact + 1, second_ends - 1)
	assert_int(_acts_again(duel, 0, first_contact + 1)).is_equal(second_ends)


# Criterion 1 and 4 together (combate.md, "A guarda andando": "com o botão ainda apertado, ela
# sobe sozinha de novo [...] sem golpe e sem tranco"): hit from behind with the button held, the
# guard is back once the stun ends, on the end tick or the one after, with that tick as its start.
func test_after_the_hitstun_with_the_button_held_the_guard_rises_again(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var press := FIRST_TICK + 1
	var contact := press + WINDUP_TICKS[tickrate]
	var ends := _stun_ends(contact, tickrate)
	var duel := _duel(tickrate, PARKED, LOOKING_AWAY, _idler(LOOKING_AWAY, FIRST_TICK), press)
	duel.run_through(ends + SPARE_TICKS)
	# Looking away, the guard up covers nothing behind: the light hits (DEC-0054 §2).
	assert_int(duel.row_at(contact).fought[0].action).is_equal(FighterState.Action.BLOCK)
	_assert_hit(duel, contact, tickrate, MAX_HEALTH)
	_assert_stunned_between(duel, contact + 1, ends - 1)
	var after := duel.row_at(ends + 1).fought[0]
	var message := "%s after the stun's end at %d, expected BLOCK since %d or %d" % [
		_action_line(after),
		ends,
		ends,
		ends + 1,
	]
	assert_int(after.action).override_failure_message(message).is_equal(FighterState.Action.BLOCK)
	assert_bool(after.action_since == ends or after.action_since == ends + 1) \
			.override_failure_message(message) \
			.is_true()


# Criterion 4 (DEC-0052 §4; combate.md, "O tranco e a vantagem", the row "Leve acerta"): with the
# contact on the first active tick, the attacker acts again 6 ticks before the target, at 60.
func test_after_a_hit_the_attacker_is_6_ticks_ahead() -> void:
	var tickrate := 60
	var press := FIRST_TICK + 1
	var contact := press + WINDUP_TICKS[tickrate]
	var ends := _stun_ends(contact, tickrate)
	var duel := _duel(tickrate, PARKED, FACING_THE_ATTACKER, _idler(FACING_THE_ATTACKER), press)
	duel.run_through(ends + SPARE_TICKS)
	_assert_hit(duel, contact, tickrate, MAX_HEALTH)
	var target_free := _acts_again(duel, 0, contact + 1)
	var attacker_free := _acts_again(duel, 1, contact + 1)
	var message := "target acts at %d, attacker at %d" % [target_free, attacker_free]
	assert_int(target_free - attacker_free).override_failure_message(message).is_equal(
		HIT_ADVANTAGE
	)
