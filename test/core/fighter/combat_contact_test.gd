# Criteria 4, 6, 8 and 9 of TASK-12.1: the contact between two fighters as the core counts it
# (DEC-0026 §3 and §4; DEC-0051), through the public interface of core/fighter, with two or three
# CombatRigs and a TickPhoto built by hand on every tick, as the Match takes it after netfox
# restores the tick (DEC-0051 §1). The attacker stamps the contact on the tick its slice touches
# the target's axis; the target applies it on the next tick, the first whose photo shows it, and
# loses the move's damage, never below 0; a swing makes one contact only, even with the blade
# parked inside the body (Q-26); two lights that touch on the same tick damage both on the next,
# in either order of the fighters (the trade); and the health returns to 100 two seconds, 120
# ticks, after the last contact taken (partida.md, "A vida sem partida"). Every number comes from
# docs/design, cited by section; ticks by hand from the ms, nearest tick with ties up.
extends GdUnitTestSuite

const CombatRig := preload("res://test/core/fighter/combat_rig.gd")
const MovementRig := preload("res://test/core/fighter/movement_rig.gd")
const SyncObserver := preload("res://test/support/sync_observer.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)
const LIGHT := &"light_attack" # the move's ID (glossario.md, "Golpe leve"; TASK-12.1 plan)
# The fighters by name, the photo's key: the node's name in a match (DEC-0051 §1).
const ATTACKER := &"A"
const TARGET := &"B"
const OTHER := &"C"

# combate.md, "Os golpes e as defesas", the row "Golpe leve": 250 / 100 / 200 ms, 12 de dano
# (DEC-0052); by hand 15 / 6 / 12 ticks at 60 and 8 / 3 / 6 at 30 (the 250 ms a tie of 7.5 that
# rounds up), a swing of 33 or 17 ticks.
const LIGHT_DAMAGE := 12
const WINDUP_TICKS: Dictionary[int, int] = { 30: 8, 60: 15 }
const ACTIVE_TICKS: Dictionary[int, int] = { 30: 3, 60: 6 }
const RECOVERY_TICKS: Dictionary[int, int] = { 30: 6, 60: 12 }
# partida.md, "A vida sem partida": vida 100, de volta a 100 dois segundos, 120 ticks, depois do
# último golpe levado; by hand 60 ticks at 30.
const MAX_HEALTH := 100
const REFILL_TICKS: Dictionary[int, int] = { 30: 60, 60: 120 }
const NO_REFILL_MS := 0 # TASK-12.1 plan: a refill of 0 turns the refill off

# The target 2,0 m dead ahead of the attacker, who looks down -Z (yaw 0), looking back at it
# (yaw pi): its axis sits under the blade's tip at theta 0 (combate.md, "A lâmina e o contato").
# By hand, the active tick that first reaches theta 0: at 60 the slices are 20° wide and the third,
# [-20°, 0°], is the first (the second's end blade at -20° passes 2,0 · sin 20° = 0,684 m from the
# axis, beyond the 0,43 of the touch), so the contact comes 15 + 2 = 17 ticks into the swing; at
# 30 the slices are 40° wide and the second, [-20°, 20°], is the first, 8 + 1 = 9 ticks in.
const FACING := Vector3(0.0, 0.0, -2.0)
const TARGET_YAW := PI
const CONTACT_OFFSET: Dictionary[int, int] = { 30: 9, 60: 17 }
# Criterion 6, the parked blade: a target 0,5 m dead ahead is within 0,43 m of every slice of the
# swing, so the blade is inside its body on every active tick. By hand, the farthest slice is the
# first, [-60°, -40°] at 60: its nearest point is the hand on the blade at -40°, 0,6 m out, at
# √(0,5² + 0,6² - 2 · 0,5 · 0,6 · cos 40°) = 0,388 m; at 30 the first slice ends at -20°, 0,215 m.
const PARKED := Vector3(0.0, 0.0, -0.5)
# None: beyond the reach of 2,43 m, behind the attacker, and 2,0 m to either side, 1,0 m off the
# edge blades (test/core/fighter/blade_test.gd).
const OUT_OF_REACH: Array[Vector3] = [
	Vector3(0.0, 0.0, -2.5),
	Vector3(0.0, 0.0, 2.0),
	Vector3(2.0, 0.0, 0.0),
	Vector3(-2.0, 0.0, 0.0),
]
# Name order: two targets 2,0 m out, 5° to either side of theta 0, both touched on the same
# active tick at 60 (the third slice, [-20°, 0°], holds the one at -5° and passes 2,0 · sin 5° =
# 0,174 m from the one at +5°; the second slice passes 2,0 · sin 15° = 0,518 m from the one at
# -5°, beyond the touch). Positive angles turn left (combate.md, "O leve no tick").
const SIDE_DEG := 5.0
const SPARE_TICKS := 5 # ticks past the swing's end a run keeps going: arithmetic
const HAIR := 1e-6 # floating-point slack, not a design number


# One tick of a run, for every fighter: the states each fighter's Combat.step returned.
class Row:
	var tick: int
	var states: Array[FighterState] = []


func _swing_ticks(tickrate: int) -> int:
	return WINDUP_TICKS[tickrate] + ACTIVE_TICKS[tickrate] + RECOVERY_TICKS[tickrate]


static func _dir(angle_deg: float) -> Vector3:
	return Basis(Vector3.UP, deg_to_rad(angle_deg)) * Vector3.FORWARD


func _fighter(
	name: StringName,
	tickrate: int,
	feet: Vector3,
	yaw: float,
	combat: CombatConfig = null,
) -> CombatRig:
	var combat_config := combat if combat != null else CombatRig.load_combat(tickrate)
	return CombatRig.new(
		name,
		MovementRig.load_config(tickrate),
		combat_config,
		FIRST_TICK,
		feet,
		yaw,
	)


# The attacker at the origin looking down -Z and the target at target_feet looking back at it.
func _pair(tickrate: int, target_feet := FACING, combat: CombatConfig = null) -> Array[CombatRig]:
	return [
		_fighter(ATTACKER, tickrate, Vector3.ZERO, 0.0, combat),
		_fighter(TARGET, tickrate, target_feet, TARGET_YAW, combat),
	]


# One tick for every fighter: the photo of the tick first, every fighter in it in the order given,
# then each fighter's sandwich in `order`, all reading the same photo (DEC-0051 §1 and §2).
func _tick(fighters: Array[CombatRig], inputs: Array[TickInput], order: Array[int]) -> void:
	var photo := TickPhoto.new()
	for fighter: CombatRig in fighters:
		fighter.snapshot(photo)
	for index: int in order:
		fighters[index].step(inputs[index], photo)


# Runs `ticks` ticks from FIRST_TICK: fighter i looks along yaws[i] and presses the light on the
# ticks in presses[i]; the row of each tick holds what Combat.step returned for each fighter.
func _simulate(
	fighters: Array[CombatRig],
	yaws: Array[float],
	presses: Array[PackedInt32Array],
	ticks: int,
	order: Array[int] = [],
) -> Array[Row]:
	var sequence: Array[int] = order.duplicate()
	if sequence.is_empty():
		for index: int in fighters.size():
			sequence.append(index)
	var rows: Array[Row] = []
	for _step: int in ticks:
		var tick := fighters[0].tick()
		var inputs: Array[TickInput] = []
		for index: int in fighters.size():
			if presses[index].has(tick):
				inputs.append(CombatRig.press_light(Vector2.ZERO, yaws[index]))
			else:
				inputs.append(CombatRig.idle(yaws[index]))
		_tick(fighters, inputs, sequence)
		var row := Row.new()
		row.tick = tick
		for fighter: CombatRig in fighters:
			row.states.append(fighter.fought)
		rows.append(row)
	return rows


func _pair_run(
	pair: Array[CombatRig],
	attacker_presses: PackedInt32Array,
	target_presses: PackedInt32Array,
	ticks: int,
	order: Array[int] = [],
) -> Array[Row]:
	return _simulate(pair, [0.0, TARGET_YAW], [attacker_presses, target_presses], ticks, order)


func _expect(condition: bool, message: String, violations: Array[String]) -> void:
	if not condition:
		violations.append(message)


func _contact_line(state: FighterState) -> String:
	return "contact (%d, %s, %s)" % [state.contact_tick, state.contact_target, state.contact_move]


func _health_line(state: FighterState) -> String:
	return "health %d, hurt_tick %d" % [state.health, state.hurt_tick]


# The attacker's stamp and the target's health, tick by tick, for one swing fired at `first` that
# touches on `contact`: nothing before, the stamp from the touch tick on and never again, the
# health down by the damage from the next tick on and never again.
func _check_one_hit(
	rows: Array[Row],
	attacker: int,
	target: int,
	target_name: StringName,
	contact: int,
	health_before: int,
	violations: Array[String],
) -> void:
	var health_after := maxi(0, health_before - LIGHT_DAMAGE)
	for row: Row in rows:
		var a := row.states[attacker]
		var b := row.states[target]
		if row.tick < contact:
			_expect(
				a.contact_tick == FighterState.NEVER,
				"tick %d: %s before the touch" % [row.tick, _contact_line(a)],
				violations,
			)
		else:
			var stamped := (
				a.contact_tick == contact and a.contact_target == target_name
				and a.contact_move == LIGHT
			)
			_expect(
				stamped,
				"tick %d: %s, expected (%d, %s, %s)"
				% [row.tick, _contact_line(a), contact, target_name, LIGHT],
				violations,
			)
		if row.tick <= contact:
			_expect(
				b.health == health_before and b.hurt_tick == FighterState.NEVER,
				"tick %d: target %s before the contact is applied" % [row.tick, _health_line(b)],
				violations,
			)
		else:
			_expect(
				b.health == health_after and b.hurt_tick == contact,
				"tick %d: target %s, expected health %d, hurt_tick %d"
				% [row.tick, _health_line(b), health_after, contact],
				violations,
			)


func _assert_no_violations(violations: Array[String]) -> void:
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()


func _assert_untouched(
	rows: Array[Row],
	index: int,
	health: int,
	violations: Array[String],
) -> void:
	for row: Row in rows:
		var state := row.states[index]
		_expect(
			state.health == health and state.hurt_tick == FighterState.NEVER,
			"tick %d: fighter %d %s, expected untouched at %d"
			% [row.tick, index, _health_line(state), health],
			violations,
		)


# Criterion 4: the slice of an active tick touches the target's capsule, the attacker stamps the
# tick, the target's name and the move on its own state, on that tick, and on the next tick the
# target loses 12 (combate.md, "O leve no tick": "O contato" and "Quem levou"; DEC-0051 §3). The
# stamp stays and the damage is taken once, although the next slice touches the axis too.
func test_the_touch_stamps_the_contact_and_the_target_loses_12_on_the_next_tick(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var pair := _pair(tickrate)
	var contact := FIRST_TICK + CONTACT_OFFSET[tickrate]
	# The by-hand contact tick is an active tick of the swing.
	assert_int(CONTACT_OFFSET[tickrate]).is_greater_equal(WINDUP_TICKS[tickrate])
	assert_int(CONTACT_OFFSET[tickrate]).is_less(WINDUP_TICKS[tickrate] + ACTIVE_TICKS[tickrate])
	var rows := _pair_run(
		pair,
		PackedInt32Array([FIRST_TICK]),
		PackedInt32Array(),
		_swing_ticks(tickrate) + SPARE_TICKS,
	)
	var violations: Array[String] = []
	_check_one_hit(rows, 0, 1, TARGET, contact, MAX_HEALTH, violations)
	# The target swung nothing: the attacker is untouched.
	_assert_untouched(rows, 0, MAX_HEALTH, violations)
	for row: Row in rows:
		_expect(
			row.states[1].contact_tick == FighterState.NEVER,
			"tick %d: the idle target stamped %s" % [row.tick, _contact_line(row.states[1])],
			violations,
		)
	_assert_no_violations(violations)


# The contact is the first active tick whose slice touches, read from the blade itself: the slice
# of the tick before misses the axis and the slice of the contact tick reaches it.
func test_the_contact_tick_is_the_first_active_tick_whose_slice_touches(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var combat := CombatRig.load_combat(tickrate)
	var config := MovementRig.load_config(tickrate)
	var light: AttackConfig = combat.attacks[LIGHT]
	var k := CONTACT_OFFSET[tickrate] - WINDUP_TICKS[tickrate] + 1
	var slice := Blade.slice_of(light, k)
	assert_bool(Blade.slice_touches(Vector3.ZERO, 0.0, slice.x, slice.y, FACING, combat, config)) \
			.override_failure_message("slice %d must touch" % k).is_true()
	for earlier: int in range(1, k):
		var before := Blade.slice_of(light, earlier)
		assert_bool(
			Blade.slice_touches(Vector3.ZERO, 0.0, before.x, before.y, FACING, combat, config)
		) \
				.override_failure_message("slice %d must miss" % earlier) \
				.is_false()


# Criterion 6: with the blade parked inside the body for the whole active, the target loses 12
# once (Q-26; combate.md, "O leve no tick": "Um golpe faz um contato só"). The table proves every
# slice of the swing touches the target at 0,5 m, and the run proves one stamp and one damage.
func test_the_parked_blade_hits_once_per_swing(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var combat := CombatRig.load_combat(tickrate)
	var config := MovementRig.load_config(tickrate)
	var light: AttackConfig = combat.attacks[LIGHT]
	for k: int in range(1, ACTIVE_TICKS[tickrate] + 1):
		var slice := Blade.slice_of(light, k)
		var distance := Blade.slice_distance(
			Vector3.ZERO,
			0.0,
			slice.x,
			slice.y,
			PARKED,
			combat,
			config,
		)
		var message := "slice %d is %.3f m from the parked target: the blade must be inside it" % [
			k,
			distance,
		]
		assert_bool(
			Blade.slice_touches(Vector3.ZERO, 0.0, slice.x, slice.y, PARKED, combat, config)
		) \
				.override_failure_message(message).is_true()
	var pair := _pair(tickrate, PARKED)
	var contact := FIRST_TICK + WINDUP_TICKS[tickrate]
	var rows := _pair_run(
		pair,
		PackedInt32Array([FIRST_TICK]),
		PackedInt32Array(),
		_swing_ticks(tickrate) + SPARE_TICKS,
	)
	var violations: Array[String] = []
	_check_one_hit(rows, 0, 1, TARGET, contact, MAX_HEALTH, violations)
	_assert_no_violations(violations)


# Criterion 8: two lights that touch on the same tick take 12 from both on the next tick, the
# trade (combate.md, "A lâmina e o contato": "Dois golpes no mesmo tick: os dois pegam"), and the
# result is the same with the fighters in either order: each reads the other only in the photo.
func test_two_lights_touching_on_the_same_tick_damage_both_on_the_next_in_either_order(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var contact := FIRST_TICK + CONTACT_OFFSET[tickrate]
	var ticks := _swing_ticks(tickrate) + SPARE_TICKS
	var presses := PackedInt32Array([FIRST_TICK])
	var attacker_first := _pair_run(_pair(tickrate), presses, presses, ticks, [0, 1])
	var target_first := _pair_run(_pair(tickrate), presses, presses, ticks, [1, 0])
	var violations: Array[String] = []
	_check_one_hit(attacker_first, 0, 1, TARGET, contact, MAX_HEALTH, violations)
	_check_one_hit(attacker_first, 1, 0, ATTACKER, contact, MAX_HEALTH, violations)
	_check_one_hit(target_first, 0, 1, TARGET, contact, MAX_HEALTH, violations)
	_check_one_hit(target_first, 1, 0, ATTACKER, contact, MAX_HEALTH, violations)
	_assert_no_violations(violations)
	_assert_same_rows(attacker_first, target_first)


# Every field of every state, tick by tick, is the same in both orders; the fields come from the
# class by reflection, so the new ones are compared from the day they exist (SyncObserver).
func _assert_same_rows(first: Array[Row], second: Array[Row]) -> void:
	var fields := SyncObserver.state_fields()
	for field: String in [
		"action",
		"action_since",
		"contact_tick",
		"contact_target",
		"health",
		"hurt_tick",
	]:
		assert_array(fields).override_failure_message("%s is not a state field" % field).contains(
			[field]
		)
	assert_int(first.size()).is_equal(second.size())
	var differences: Array[String] = []
	for index: int in first.size():
		for fighter: int in first[index].states.size():
			var a := first[index].states[fighter]
			var b := second[index].states[fighter]
			for field: String in fields:
				if not SyncObserver.same(a.get(field), b.get(field)):
					differences.append(
						"tick %d, fighter %d: %s %s in one order, %s in the other"
						% [first[index].tick, fighter, field, a.get(field), b.get(field)]
					)
	assert_array(differences).override_failure_message("\n".join(differences)).is_empty()


# Criterion 9: 120 ticks after the contact of the last hit taken, the health is back at 100; on
# the tick before, it is still down (partida.md, "A vida sem partida").
func test_health_returns_to_100_120_ticks_after_the_last_contact(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var pair := _pair(tickrate)
	var contact := FIRST_TICK + CONTACT_OFFSET[tickrate]
	var refill := contact + REFILL_TICKS[tickrate]
	var rows := _pair_run(
		pair,
		PackedInt32Array([FIRST_TICK]),
		PackedInt32Array(),
		CONTACT_OFFSET[tickrate] + REFILL_TICKS[tickrate] + SPARE_TICKS,
	)
	var violations: Array[String] = []
	for row: Row in rows:
		var b := row.states[1]
		if row.tick > contact and row.tick < refill:
			_expect(
				b.health == MAX_HEALTH - LIGHT_DAMAGE,
				"tick %d: %s, expected %d until the refill"
				% [row.tick, _health_line(b), MAX_HEALTH - LIGHT_DAMAGE],
				violations,
			)
		elif row.tick >= refill:
			_expect(
				b.health == MAX_HEALTH,
				"tick %d: %s, expected 100 from tick %d" % [row.tick, _health_line(b), refill],
				violations,
			)
	_assert_no_violations(violations)


# Many: a second hit restarts the refill clock: 120 ticks after the first contact the health is
# still down by both, and it returns to 100 only 120 ticks after the second.
func test_a_second_hit_restarts_the_refill_clock() -> void:
	var tickrate := 60
	var pair := _pair(tickrate)
	var second_swing := FIRST_TICK + _swing_ticks(tickrate)
	var first_contact := FIRST_TICK + CONTACT_OFFSET[tickrate]
	var second_contact := second_swing + CONTACT_OFFSET[tickrate]
	var refill := second_contact + REFILL_TICKS[tickrate]
	var rows := _pair_run(
		pair,
		PackedInt32Array([FIRST_TICK, second_swing]),
		PackedInt32Array(),
		refill - FIRST_TICK + SPARE_TICKS,
	)
	var violations: Array[String] = []
	for row: Row in rows:
		var b := row.states[1]
		var expected := MAX_HEALTH
		if row.tick > first_contact and row.tick <= second_contact:
			expected = MAX_HEALTH - LIGHT_DAMAGE
		elif row.tick > second_contact and row.tick < refill:
			expected = MAX_HEALTH - 2 * LIGHT_DAMAGE
		_expect(
			b.health == expected,
			"tick %d: %s, expected %d" % [row.tick, _health_line(b), expected],
			violations,
		)
		if row.tick > second_contact:
			_expect(
				b.hurt_tick == second_contact,
				"tick %d: hurt_tick %d, expected the second contact %d"
				% [row.tick, b.hurt_tick, second_contact],
				violations,
			)
	# The first contact's refill tick comes while the second hit is still fresh: no refill there.
	assert_int(first_contact + REFILL_TICKS[tickrate]).is_less(refill)
	_assert_no_violations(violations)


# Criterion 9, the floor: a hit that would take the health below 0 leaves it at 0, and from 0 it
# returns to 100 after the 120 ticks like any other. The health is set by hand as a hit just
# applied would leave it, with the hurt stamp of that hit.
func test_health_never_goes_below_0(
	health_before: int,
	_test_parameters := [[12], [5], [0]],
) -> void:
	var tickrate := 60
	var pair := _pair(tickrate)
	pair[1].state().health = health_before
	pair[1].state().hurt_tick = FIRST_TICK - 1
	var contact := FIRST_TICK + CONTACT_OFFSET[tickrate]
	var refill := contact + REFILL_TICKS[tickrate]
	var rows := _pair_run(
		pair,
		PackedInt32Array([FIRST_TICK]),
		PackedInt32Array(),
		CONTACT_OFFSET[tickrate] + REFILL_TICKS[tickrate] + SPARE_TICKS,
	)
	var violations: Array[String] = []
	for row: Row in rows:
		var b := row.states[1]
		var expected := health_before
		if row.tick > contact and row.tick < refill:
			expected = 0
		elif row.tick >= refill:
			expected = MAX_HEALTH
		_expect(
			b.health == expected,
			"tick %d: %s, expected %d" % [row.tick, _health_line(b), expected],
			violations,
		)
		_expect(b.health >= 0, "tick %d: health below 0" % row.tick, violations)
	_assert_no_violations(violations)


# With the refill off in the data (0 ms, 0 ticks), the health stays down: the match of TASK-12.7
# will take the refill's place (partida.md, "A vida sem partida").
func test_with_the_refill_off_the_health_stays_down() -> void:
	var tickrate := 60
	var data := CombatRig.load_combat_data()
	data.health_refill_ms = NO_REFILL_MS
	var combat := CombatConfig.create(data, tickrate)
	assert_int(combat.health_refill_ticks).is_equal(0)
	var pair := _pair(tickrate, FACING, combat)
	var contact := FIRST_TICK + CONTACT_OFFSET[tickrate]
	var rows := _pair_run(
		pair,
		PackedInt32Array([FIRST_TICK]),
		PackedInt32Array(),
		CONTACT_OFFSET[tickrate] + REFILL_TICKS[tickrate] + SPARE_TICKS,
	)
	var violations: Array[String] = []
	for row: Row in rows:
		var b := row.states[1]
		if row.tick > contact:
			_expect(
				b.health == MAX_HEALTH - LIGHT_DAMAGE,
				"tick %d: %s, expected %d with the refill off"
				% [row.tick, _health_line(b), MAX_HEALTH - LIGHT_DAMAGE],
				violations,
			)
	_assert_no_violations(violations)


# None: a target beyond the reach, behind the attacker or at its side is never touched; nothing is
# stamped and nothing is lost.
func test_a_target_out_of_reach_or_behind_is_never_touched(
	target_feet: Vector3,
	_test_parameters := [
		[Vector3(0.0, 0.0, -2.5)],
		[Vector3(0.0, 0.0, 2.0)],
		[Vector3(2.0, 0.0, 0.0)],
		[Vector3(-2.0, 0.0, 0.0)],
	],
) -> void:
	var tickrate := 60
	var pair := _pair(tickrate, target_feet)
	var rows := _pair_run(
		pair,
		PackedInt32Array([FIRST_TICK]),
		PackedInt32Array(),
		_swing_ticks(tickrate) + SPARE_TICKS,
	)
	var violations: Array[String] = []
	for row: Row in rows:
		_expect(
			row.states[0].contact_tick == FighterState.NEVER,
			"tick %d: %s on a target at %s" % [row.tick, _contact_line(row.states[0]), target_feet],
			violations,
		)
	_assert_untouched(rows, 1, MAX_HEALTH, violations)
	_assert_no_violations(violations)


# None: alone in the photo, the attacker touches nothing, itself least of all.
func test_an_attacker_alone_in_the_photo_contacts_nothing() -> void:
	var tickrate := 60
	var fighters: Array[CombatRig] = [_fighter(ATTACKER, tickrate, Vector3.ZERO, 0.0)]
	var rows := _simulate(
		fighters,
		[0.0],
		[PackedInt32Array([FIRST_TICK])],
		_swing_ticks(tickrate) + SPARE_TICKS,
	)
	var violations: Array[String] = []
	for row: Row in rows:
		_expect(
			row.states[0].contact_tick == FighterState.NEVER,
			"tick %d: %s with nobody there" % [row.tick, _contact_line(row.states[0])],
			violations,
		)
	_assert_untouched(rows, 0, MAX_HEALTH, violations)
	_assert_no_violations(violations)


# Two targets touched on the same tick: the one first by name takes the swing's one contact,
# whatever the order the photo was filled in (combate.md, "O leve no tick": "Os alvos são testados
# em ordem de nome"); the other is untouched.
func test_targets_touched_on_the_same_tick_are_taken_in_name_order() -> void:
	var tickrate := 60
	var fighters: Array[CombatRig] = [
		_fighter(OTHER, tickrate, _dir(-SIDE_DEG) * 2.0, TARGET_YAW),
		_fighter(ATTACKER, tickrate, Vector3.ZERO, 0.0),
		_fighter(TARGET, tickrate, _dir(SIDE_DEG) * 2.0, TARGET_YAW),
	]
	var contact := FIRST_TICK + CONTACT_OFFSET[tickrate]
	var rows := _simulate(
		fighters,
		[TARGET_YAW, 0.0, TARGET_YAW],
		[PackedInt32Array(), PackedInt32Array([FIRST_TICK]), PackedInt32Array()],
		_swing_ticks(tickrate) + SPARE_TICKS,
	)
	var violations: Array[String] = []
	_check_one_hit(rows, 1, 2, TARGET, contact, MAX_HEALTH, violations)
	_assert_untouched(rows, 0, MAX_HEALTH, violations)
	_assert_no_violations(violations)
