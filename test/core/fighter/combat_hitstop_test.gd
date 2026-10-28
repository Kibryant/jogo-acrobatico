# Criterion 6 of TASK-12.2: the hitstop as a state of the core (glossario.md, "Hitstop"; combate.md,
# "O hitstop e o tremor": "A paradinha no tick"; DEC-0055 §4 and §5), through the public interface
# of core/fighter, with GuardRigs and a TickPhoto taken by hand on every tick (Duel). Whoever is
# hit or blocks freezes 4 or 2 ticks from the tick after the contact, the tick it resolves it;
# whoever hit freezes the same ticks from the tick after that, when the photo shows the target's
# hurt or block stamp on its contact; frozen, the body neither moves nor falls and keeps its
# velocity for after; the swing's clock and the stun's move the freeze forward, so the advantage
# measured with the hitstop is the one measured without; a contact without a result freezes nobody.
# Every number comes from docs/design, cited by section; ticks by hand from the ms, nearest tick
# with ties up.
extends GdUnitTestSuite

const GuardRig := preload("res://test/core/fighter/guard_rig.gd")
const MovementRig := preload("res://test/core/fighter/movement_rig.gd")
const Duel := preload("res://test/core/fighter/duel.gd")
const SyncObserver := preload("res://test/support/sync_observer.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)
const TARGET := &"A"
const ATTACKER := &"B"

# combate.md, "Os golpes e as defesas", the row "Golpe leve": 250 / 100 / 200 ms (DEC-0052); by
# hand 15 / 6 / 12 ticks at 60 and 8 / 3 / 6 at 30, a swing of 33 or 17 ticks.
const WINDUP_TICKS: Dictionary[int, int] = { 30: 8, 60: 15 }
const SWING_TICKS: Dictionary[int, int] = { 30: 17, 60: 33 }
# combate.md, "O hitstop e o tremor": "Leve acerta: os dois, 67 ms, 4 ticks"; "Leve bloqueado: os
# dois, 33 ms, 2 ticks"; by hand 2 and 1 at 30.
const HITSTOP_HIT_TICKS: Dictionary[int, int] = { 30: 2, 60: 4 }
const HITSTOP_BLOCK_TICKS: Dictionary[int, int] = { 30: 1, 60: 2 }
# combate.md, "O tranco e a vantagem": "Leve acerta: 400 ms, 24 ticks"; "Leve bloqueado: 250 ms,
# 15 ticks"; 12 and 8 at 30.
const HITSTUN_TICKS: Dictionary[int, int] = { 30: 12, 60: 24 }
const BLOCKSTUN_TICKS: Dictionary[int, int] = { 30: 8, 60: 15 }
# combate.md, "O tranco e a vantagem", the rows "Leve acerta: quem bateu +6" and "Leve bloqueado:
# quem bloqueou +3", at 60 with the contact on the first active tick; "O hitstop e o tremor": "a
# vantagem não muda".
const HIT_ADVANTAGE := 6
const BLOCK_ADVANTAGE := 3
const NO_HITSTOP_MS := 0 # a light that freezes nobody: the exchange measured without the hitstop
# movimento.md, "Chão": "Velocidade de corrida: 7 m/s"; "Tempo até a velocidade máxima: 150 ms", 9
# ticks at 60 and 5 at 30.
const RUN_SPEED_MPS := 7.0
const ACCEL_TICKS: Dictionary[int, int] = { 30: 5, 60: 9 }
const MAX_HEALTH := 100 # partida.md, "A vida sem partida"
const LIGHT_DAMAGE := 12 # combate.md, "Os golpes e as defesas"

# The target 0,5 m dead ahead of the attacker, who looks down -Z: the blade is inside its body on
# every active tick (test/core/fighter/combat_contact_test.gd, the parked blade), so the contact is
# the first active tick, 15 or 8 ticks after the press.
const PARKED := Vector3(0.0, 0.0, -0.5)
# A target 4,5 m ahead of an attacker that runs at it: at 7 m/s the attacker covers 1,75 m in the
# windup and reaches the target in the active window; the contact tick is read from the stamp.
const FAR := Vector3(0.0, 0.0, -4.5)
# A falling target set in the air by hand on the tick before the contact, 0,6 m up and coming
# down at 1 m/s: the hand's plane, 1,3 m up, still crosses its axis, from 0,35 to 1,45 m above its
# feet (combate.md, "O leve no tick": "O toque"), and it is in the air, with no guard there, when
# the contact is applied.
const AIRBORNE_AT := Vector3(0.0, 0.6, -0.5)
const FALLING := Vector3(0.0, -1.0, 0.0)
const FACING_THE_ATTACKER := PI # looking back at the attacker, +Z
const FORWARD := Vector2(0, 1) # move.y goes forward, relative to yaw (TASK-9 plan)
const SPARE_TICKS := 6 # ticks a run keeps going past the last event: arithmetic
const HAIR := 1e-6 # floating-point slack, not a design number
# The fields the slot writes, the one thing a frozen tick may change (DEC-0055 §5).
const SLOT_FIELDS: Array[String] = ["buffered_command", "buffered_tick"]


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


func _idler(yaw: float, guard: bool) -> Callable:
	return func(_tick: int) -> TickInput:
		var input := GuardRig.idle(yaw)
		input.guard = guard
		return input


# The target, index 0, and the attacker at attacker_feet looking down -Z, index 1, pressing at
# `press`.
func _duel(
	tickrate: int,
	target_feet: Vector3,
	target_script: Callable,
	press: int,
	combat: CombatConfig = null,
	attacker_feet := Vector3.ZERO,
	attacker_move := Vector2.ZERO,
) -> Duel:
	var config := combat if combat != null else GuardRig.load_combat(tickrate)
	var duel := Duel.new()
	duel.add(_fighter(TARGET, tickrate, target_feet, FACING_THE_ATTACKER, config), target_script)
	duel.add(
		_fighter(ATTACKER, tickrate, attacker_feet, 0.0, config),
		_presser(PackedInt32Array([press]), 0.0, attacker_move),
	)
	return duel


func _line(state: FighterState) -> String:
	return "%s since %d, stun_until %d, frozen_until %d, hurt %d, block %d" % [
		FighterState.Action.find_key(state.action),
		state.action_since,
		state.stun_until_tick,
		state.frozen_until_tick,
		state.hurt_tick,
		state.block_tick,
	]


# The fields in which two states differ, the slot's aside.
func _differences(before: FighterState, after: FighterState) -> Array[String]:
	var found: Array[String] = []
	for field: String in SyncObserver.state_fields():
		if SLOT_FIELDS.has(field):
			continue
		if not SyncObserver.same(before.get(field), after.get(field)):
			found.append("%s %s -> %s" % [field, before.get(field), after.get(field)])
	return found


# The fighter `index` is frozen on every tick from `from` to `to`, inclusive, and on no other tick
# of the run: its plan says so, its state says so (frozen_until_tick == to), the body stays where
# the tick before left it with the velocity it had, and the state leaves the tick as it entered,
# the slot aside; the tick after `to` is not frozen and moves the body again.
func _assert_frozen_between(duel: Duel, index: int, from: int, to: int) -> void:
	var violations: Array[String] = []
	var previous: Duel.Row = null
	for row: Duel.Row in duel.rows:
		var frozen := row.tick >= from and row.tick <= to
		var plan := row.plans[index]
		if plan.frozen != frozen:
			violations.append("tick %d: plan.frozen %s" % [row.tick, plan.frozen])
		var state := row.ends[index]
		if GuardRig.frozen_at(state, row.tick) != frozen:
			violations.append("tick %d: frozen_until %d" % [row.tick, state.frozen_until_tick])
		if frozen and state.frozen_until_tick != to:
			violations.append(
				"tick %d: frozen_until %d, expected %d" % [row.tick, state.frozen_until_tick, to]
			)
		if frozen and previous != null:
			if row.feet[index].distance_to(previous.feet[index]) > HAIR:
				violations.append(
					"tick %d: moved from %s to %s"
					% [row.tick, previous.feet[index], row.feet[index]]
				)
			if row.velocities[index].distance_to(previous.velocities[index]) > HAIR:
				violations.append(
					"tick %d: velocity %s -> %s"
					% [row.tick, previous.velocities[index], row.velocities[index]]
				)
			if row.tick > from:
				var changed := _differences(previous.ends[index], state)
				if not changed.is_empty():
					violations.append(
						"tick %d: the frozen state changed: %s" % [row.tick, ", ".join(changed)]
					)
				var in_plan := _differences(row.fought[index], plan.state)
				if not in_plan.is_empty():
					violations.append(
						"tick %d: before_move changed a frozen state: %s"
						% [row.tick, ", ".join(in_plan)]
					)
		previous = row
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()


# The first tick after `from` on which the fighter acts again: NONE, or BLOCK with the button held.
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


# Criterion 6: hit, the target freezes from the tick after the contact, when it resolves it, for 4
# ticks (2 when it blocks), and no other tick; its stun already counts the freeze (DEC-0055 §4 and
# §5).
func test_whoever_is_hit_or_blocks_freezes_from_the_tick_after_the_contact(
	tickrate: int,
	blocks: bool,
	_test_parameters := [[30, false], [60, false], [30, true], [60, true]],
) -> void:
	var press := FIRST_TICK + 10
	var contact := press + WINDUP_TICKS[tickrate]
	var hitstop := HITSTOP_BLOCK_TICKS[tickrate] if blocks else HITSTOP_HIT_TICKS[tickrate]
	var stun := BLOCKSTUN_TICKS[tickrate] if blocks else HITSTUN_TICKS[tickrate]
	var duel := _duel(tickrate, PARKED, _idler(FACING_THE_ATTACKER, blocks), press)
	duel.run_through(contact + stun + hitstop + SPARE_TICKS)
	assert_int(duel.contact_tick_of(1)).is_equal(contact)
	var resolved := duel.row_at(contact + 1).fought[0]
	var expected := FighterState.Action.BLOCKSTUN if blocks else FighterState.Action.HITSTUN
	assert_int(resolved.action).override_failure_message(_line(resolved)).is_equal(expected)
	_assert_frozen_between(duel, 0, contact + 1, contact + hitstop)
	assert_int(resolved.stun_until_tick).is_equal(contact + stun + hitstop)
	assert_int(_acts_again(duel, 0, contact + 1)).is_equal(contact + stun + hitstop)


# Criterion 6: whoever hit freezes the same ticks one tick later, from contact + 2, when the photo
# shows the target with its hurt stamp (or its block stamp) on that contact; its swing's clock
# moves the freeze forward: the swing ends 4 (or 2) ticks later than alone (DEC-0055 §4 and §5).
func test_whoever_hit_freezes_one_tick_later_and_its_swing_ends_that_much_later(
	tickrate: int,
	blocks: bool,
	_test_parameters := [[30, false], [60, false], [30, true], [60, true]],
) -> void:
	var press := FIRST_TICK + 10
	var contact := press + WINDUP_TICKS[tickrate]
	var hitstop := HITSTOP_BLOCK_TICKS[tickrate] if blocks else HITSTOP_HIT_TICKS[tickrate]
	var swing_end := press + SWING_TICKS[tickrate] + hitstop
	var duel := _duel(tickrate, PARKED, _idler(FACING_THE_ATTACKER, blocks), press)
	duel.run_through(swing_end + SPARE_TICKS)
	assert_int(duel.contact_tick_of(1)).is_equal(contact)
	_assert_frozen_between(duel, 1, contact + 2, contact + 1 + hitstop)
	# The clock: active since the contact before the freeze, since contact + hitstop from it.
	var before := duel.row_at(contact + 1).fought[1]
	assert_int(before.action).override_failure_message(_line(before)).is_equal(
		FighterState.Action.ACTIVE
	)
	assert_int(before.action_since).is_equal(contact)
	var shifted := duel.row_at(contact + 2).fought[1]
	assert_int(shifted.action).override_failure_message(_line(shifted)).is_equal(
		FighterState.Action.ACTIVE
	)
	assert_int(shifted.action_since).override_failure_message(_line(shifted)).is_equal(
		contact + hitstop
	)
	var last_recovery := duel.row_at(swing_end - 1).fought[1]
	assert_int(last_recovery.action).override_failure_message(_line(last_recovery)).is_equal(
		FighterState.Action.RECOVERY
	)
	assert_int(_acts_again(duel, 1, contact + 1)).is_equal(swing_end)


# Criterion 6: frozen, the body neither moves nor falls, and afterwards goes on with the velocity
# it had (combate.md, "A paradinha no tick": "o corpo não anda nem cai, e a velocidade que ele
# tinha volta depois"): a target falling in the air when hit keeps its height and its fall speed
# through the 4 frozen ticks, then falls again with gravity from that speed.
func test_a_frozen_body_does_not_fall_and_keeps_its_velocity_for_after(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var press := FIRST_TICK + 10
	var contact := press + WINDUP_TICKS[tickrate]
	var hitstop := HITSTOP_HIT_TICKS[tickrate]
	var duel := _duel(tickrate, PARKED, _idler(FACING_THE_ATTACKER, false), press)
	duel.run_through(contact - 2)
	duel.fighter(0).rig.airborne(AIRBORNE_AT, FALLING)
	duel.run_through(contact + hitstop + 2)
	assert_int(duel.contact_tick_of(1)).override_failure_message("the falling target was missed") \
			.is_equal(contact)
	var resolved := duel.row_at(contact + 1).fought[0]
	assert_int(resolved.action).override_failure_message(_line(resolved)).is_equal(
		FighterState.Action.HITSTUN
	)
	assert_int(resolved.mode).is_equal(FighterState.Mode.AIR)
	_assert_frozen_between(duel, 0, contact + 1, contact + hitstop)
	var kept := duel.row_at(contact).velocities[0]
	assert_float(kept.y).override_failure_message("not falling at the contact").is_less(0.0)
	var frozen := duel.row_at(contact + hitstop)
	assert_vector(frozen.velocities[0]).is_equal_approx(kept, Vector3.ONE * HAIR)
	assert_vector(frozen.feet[0]).is_equal_approx(duel.row_at(contact).feet[0], Vector3.ONE * HAIR)
	var thawed := duel.row_at(contact + hitstop + 1)
	assert_bool(thawed.plans[0].frozen).is_false()
	assert_float(thawed.plans[0].velocity.y).override_failure_message("gravity did not resume") \
			.is_less(kept.y)
	var expected_feet := frozen.feet[0] + thawed.plans[0].velocity / float(tickrate)
	assert_vector(thawed.feet[0]).is_equal_approx(expected_feet, Vector3.ONE * HAIR)


# Criterion 6, the attacker's body: running at 7 m/s through its swing (DEC-0052), it stops where
# it is for its frozen ticks, keeps the 7 in the body, and runs on at 7 from the tick after. The
# contact tick is read from its own stamp.
func test_a_frozen_attacker_stops_where_it_is_and_runs_on_with_its_speed(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var press := FIRST_TICK + ACCEL_TICKS[tickrate] + 2
	var hitstop := HITSTOP_HIT_TICKS[tickrate]
	var duel := _duel(
		tickrate,
		FAR,
		_idler(FACING_THE_ATTACKER, false),
		press,
		null,
		Vector3.ZERO,
		FORWARD,
	)
	duel.run_through(press + SWING_TICKS[tickrate])
	var contact := duel.contact_tick_of(1)
	assert_int(contact).override_failure_message("the running attacker touched nobody") \
			.is_not_equal(FighterState.NEVER)
	duel.run_through(press + SWING_TICKS[tickrate] + hitstop + SPARE_TICKS)
	_assert_frozen_between(duel, 1, contact + 2, contact + 1 + hitstop)
	var step := RUN_SPEED_MPS / float(tickrate)
	var violations: Array[String] = []
	var previous: Duel.Row = null
	for row: Duel.Row in duel.rows:
		if previous != null and row.tick >= press:
			var moved := row.feet[1].distance_to(previous.feet[1])
			var frozen := row.tick >= contact + 2 and row.tick <= contact + 1 + hitstop
			var expected := 0.0 if frozen else step
			if absf(moved - expected) > HAIR:
				violations.append(
					"tick %d: moved %.4f m, expected %.4f" % [row.tick, moved, expected]
				)
			var speed := Vector3(row.velocities[1].x, 0.0, row.velocities[1].z).length()
			if absf(speed - RUN_SPEED_MPS) > HAIR:
				violations.append("tick %d: %.3f m/s, expected the run of 7" % [row.tick, speed])
		previous = row
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()


# Criterion 6: the advantage measured with the hitstop is the one measured without it (combate.md,
# "O hitstop e o tremor": "a vantagem não muda"): +6 for the hit and +3 for the block, at 60, with
# the contact on the first active tick, with the design's hitstop and with a light of 0 ms of
# hitstop, which freezes nobody.
func test_the_advantage_is_the_same_with_and_without_the_hitstop(
	blocks: bool,
	with_hitstop: bool,
	_test_parameters := [[false, true], [false, false], [true, true], [true, false]],
) -> void:
	var tickrate := 60
	var combat := (
		GuardRig.load_combat(tickrate)
		if with_hitstop
		else GuardRig.combat_with_hitstop(NO_HITSTOP_MS, NO_HITSTOP_MS, tickrate)
	)
	var light: AttackConfig = combat.attacks[FighterCommand.LIGHT_ATTACK]
	var hitstop := 0
	if with_hitstop:
		hitstop = HITSTOP_BLOCK_TICKS[tickrate] if blocks else HITSTOP_HIT_TICKS[tickrate]
	assert_int(light.hitstop_hit_ticks if not blocks else light.hitstop_block_ticks).is_equal(
		hitstop
	)
	var press := FIRST_TICK + 10
	var contact := press + WINDUP_TICKS[tickrate]
	var duel := _duel(tickrate, PARKED, _idler(FACING_THE_ATTACKER, blocks), press, combat)
	duel.run_through(press + SWING_TICKS[tickrate] + HITSTUN_TICKS[tickrate] + SPARE_TICKS)
	assert_int(duel.contact_tick_of(1)).is_equal(contact)
	var resolved := duel.row_at(contact + 1).fought[0]
	var expected := FighterState.Action.BLOCKSTUN if blocks else FighterState.Action.HITSTUN
	assert_int(resolved.action).override_failure_message(_line(resolved)).is_equal(expected)
	var frozen_ticks := 0
	for row: Duel.Row in duel.rows:
		for index: int in 2:
			if row.plans[index].frozen:
				frozen_ticks += 1
	assert_int(frozen_ticks).override_failure_message("%d frozen ticks" % frozen_ticks).is_equal(
		2 * hitstop
	)
	var target_free := _acts_again(duel, 0, contact + 1)
	var attacker_free := _acts_again(duel, 1, contact + 1)
	var message := "target acts at %d, attacker at %d, hitstop %d" % [
		target_free,
		attacker_free,
		hitstop,
	]
	if blocks:
		assert_int(attacker_free - target_free).override_failure_message(message).is_equal(
			BLOCK_ADVANTAGE
		)
	else:
		assert_int(target_free - attacker_free).override_failure_message(message).is_equal(
			HIT_ADVANTAGE
		)


# Criterion 6: a contact without a result freezes nobody (combate.md, "A paradinha no tick": "Um
# golpe sem resultado, como o esquivado, não congela ninguém"; DEC-0055 §4): on the tick the
# attacker would read the result, the photo shows the target as the contact tick left it, with no
# hurt and no block stamp on this contact, and the attacker does not freeze then or ever; its swing
# ends as alone.
func test_a_contact_without_a_result_in_the_photo_freezes_nobody(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var press := FIRST_TICK + 10
	var contact := press + WINDUP_TICKS[tickrate]
	var swing_end := press + SWING_TICKS[tickrate]
	var duel := _duel(tickrate, PARKED, _idler(FACING_THE_ATTACKER, false), press)
	duel.run_through(contact)
	# The photo of the target as the contact tick left it, before it resolves anything.
	var unresolved := duel.photo_now()
	duel.run_through(contact + 1)
	duel.stage_photo(unresolved)
	duel.run_through(swing_end + SPARE_TICKS)
	assert_int(duel.contact_tick_of(1)).is_equal(contact)
	var violations: Array[String] = []
	for row: Duel.Row in duel.rows:
		if row.plans[1].frozen or GuardRig.frozen_at(row.ends[1], row.tick):
			violations.append("tick %d: the attacker froze, %s" % [row.tick, _line(row.ends[1])])
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	assert_int(_acts_again(duel, 1, contact + 1)).is_equal(swing_end)


# None: a swing that touches nobody freezes nobody.
func test_a_swing_that_touches_nobody_freezes_nobody() -> void:
	var tickrate := 60
	var press := FIRST_TICK + 10
	var duel := _duel(tickrate, Vector3(0.0, 0.0, -2.5), _idler(FACING_THE_ATTACKER, true), press)
	duel.run_through(press + SWING_TICKS[tickrate] + SPARE_TICKS)
	assert_int(duel.contact_tick_of(1)).is_equal(FighterState.NEVER)
	for row: Duel.Row in duel.rows:
		for index: int in 2:
			assert_bool(row.plans[index].frozen).override_failure_message("tick %d" % row.tick) \
					.is_false()
			assert_int(row.ends[index].frozen_until_tick).is_equal(FighterState.NEVER)
	assert_int(_acts_again(duel, 1, press + 1)).is_equal(press + SWING_TICKS[tickrate])
