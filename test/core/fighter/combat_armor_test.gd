# Criterion 2 of TASK-12.3: the armor of the charged (glossario.md, "Armadura"; combate.md, "A
# armadura do carregado" and "O carregado, o parry e a finta no tick": "A armadura"; DEC-0056 §3),
# through the public interface of core/fighter, with GuardRigs and a TickPhoto taken by hand on
# every tick (Duel). A light that touches whoever is in the charged's windup takes its 12 and stamps
# the hurt tick on the tick after the touch, but gives no stun and no freeze: the windup goes on and
# the charged comes down on its usual tick; the light's attacker reads the hurt stamp in the photo
# and freezes the 4 ticks of a hit. A light that touches on the last windup tick still meets the
# armor; one that touches on the first active tick, or in the recovery, stuns as always and ends
# the swing. Against a charged the armor is worth nothing. Every number comes from docs/design,
# cited by section; ticks by hand from the ms, nearest tick with ties up.
extends GdUnitTestSuite

const ChargedRig := preload("res://test/core/fighter/charged_rig.gd")
const MovementRig := preload("res://test/core/fighter/movement_rig.gd")
const Duel := preload("res://test/core/fighter/duel.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)
const CHARGED := &"charged_attack" # glossario.md, "Golpe carregado"
const LIGHT := &"light_attack" # glossario.md, "Golpe leve"
# The charger is first by name, the light's attacker second (DEC-0051 §1).
const CHARGER := &"A"
const OTHER := &"B"

# combate.md, "Os golpes e as defesas", the row "Golpe carregado": 42 / 7 / 27 ticks at 60, 21 / 4 /
# 14 at 30 ("As fases do carregado"), 25 de stamina pagos na soltura, 30 de dano.
const WINDUP_TICKS: Dictionary[int, int] = { 30: 21, 60: 42 }
const ACTIVE_TICKS: Dictionary[int, int] = { 30: 4, 60: 7 }
const RECOVERY_TICKS: Dictionary[int, int] = { 30: 14, 60: 27 }
const CHARGED_COST := 25.0
const CHARGED_DAMAGE := 30
# combate.md, "Os golpes e as defesas", the row "Golpe leve": 15 / 6 / 12 ticks at 60, 8 / 3 / 6 at
# 30, a swing of 33 or 17 ticks, 12 de dano (DEC-0052).
const LIGHT_SWING_TICKS: Dictionary[int, int] = { 30: 17, 60: 33 }
const LIGHT_DAMAGE := 12
# combate.md, "O tranco e a vantagem": "Leve acerta: 400 ms, 24 ticks", 12 at 30; "O hitstop e o
# tremor": "Leve acerta: 67 ms, 4 ticks", 2 at 30. The stun ends at contact + stun + hitstop
# (DEC-0055 §5).
const LIGHT_HITSTUN_TICKS: Dictionary[int, int] = { 30: 12, 60: 24 }
const LIGHT_HITSTOP_TICKS: Dictionary[int, int] = { 30: 2, 60: 4 }
# combate.md, "O hitstop e o tremor": "Carregado acerta: 117 ms, 7 ticks", 4 at 30 (3,51 up).
const CHARGED_HITSTOP_TICKS: Dictionary[int, int] = { 30: 4, 60: 7 }
# combate.md, "O tranco e a vantagem": "Carregado acerta: 700 ms, 42 ticks"; 21 at 30.
const HITSTUN_TICKS_OF_THE_CHARGED: Dictionary[int, int] = { 30: 21, 60: 42 }
const STAMINA_MAX := 100.0 # movimento.md, "Stamina": "Máximo"
const MAX_HEALTH := 100 # partida.md, "A vida sem partida"

# The light's attacker 2,3 m ahead of the charger, who looks down -Z from the origin, looking back
# at it (yaw pi). Its light reaches the charger's axis on the third slice at 60 (0,3 m beyond the
# tip at theta 0; the second slice's end blade at -20° passes 0,8 m from it) and on the second at
# 30, so its contact comes 17 or 9 ticks after its press (test/core/fighter/combat_contact_test.gd:
# the same slices reach 2,0 m). The charger's cut touches it on the third active tick at 60 and the
# second at 30 (combate.md, "O toque do carregado": "um a 2,3 m no terceiro";
# test/core/fighter/combat_charged_test.gd).
const AT_2_3_M := Vector3(0.0, 0.0, -2.3)
const LIGHT_CONTACT_OFFSET: Dictionary[int, int] = { 30: 9, 60: 17 }
const CHARGED_ACTIVE_TICK_AT_2_3_M: Dictionary[int, int] = { 30: 2, 60: 3 }
# A second charger 1,5 m ahead: the cut touches it on the first active tick ("um alvo de frente a
# 1,5 m é tocado no primeiro tick ativo").
const CLOSE := Vector3(0.0, 0.0, -1.5)
const FACING_THE_OTHER := PI
# The charger looking sideways, so its cut meets nobody while the light lands in its recovery.
const SIDEWAYS := PI / 2.0
# How far into the windup the early light lands: arithmetic, well before the last windup tick and
# with its attacker's freeze over before the cut comes down.
const EARLY_IN_THE_WINDUP := 5
# Ticks after FIRST_TICK the charged of the early case is pressed, so the light's press that lands
# 5 ticks into its windup, 17 ticks after its own press, comes after FIRST_TICK: arithmetic.
const PRESS_AFTER_START := 20
const SPARE_TICKS := 6 # ticks a run keeps going past the last event: arithmetic
const HAIR := 1e-6 # floating-point slack, not a design number


func _fighter(
	name: StringName,
	tickrate: int,
	feet: Vector3,
	yaw: float,
	combat: CombatConfig,
) -> ChargedRig:
	return ChargedRig.new(name, MovementRig.load_config(tickrate), combat, FIRST_TICK, feet, yaw)


func _charger(presses: PackedInt32Array, yaw: float) -> Callable:
	return func(tick: int) -> TickInput:
		if presses.has(tick):
			return ChargedRig.press_charged(Vector2.ZERO, yaw)
		return ChargedRig.idle(yaw)


func _light_presser(presses: PackedInt32Array, yaw: float) -> Callable:
	return func(tick: int) -> TickInput:
		if presses.has(tick):
			return ChargedRig.press_light(Vector2.ZERO, yaw)
		return ChargedRig.idle(yaw)


# The charger at the origin, index 0, pressing the charged at `charged_press` with the camera on
# charger_yaw; the other at other_feet looking back, index 1, pressing the light at `light_press`.
func _duel(
	tickrate: int,
	charged_press: int,
	light_press: int,
	charger_yaw := 0.0,
	other_feet := AT_2_3_M,
) -> Duel:
	var combat := ChargedRig.load_combat(tickrate)
	var duel := Duel.new()
	duel.add(
		_fighter(CHARGER, tickrate, Vector3.ZERO, charger_yaw, combat),
		_charger(PackedInt32Array([charged_press]), charger_yaw),
	)
	duel.add(
		_fighter(OTHER, tickrate, other_feet, FACING_THE_OTHER, combat),
		_light_presser(PackedInt32Array([light_press]), FACING_THE_OTHER),
	)
	return duel


func _action_line(state: FighterState) -> String:
	return "%s since %d with %s, stun_until %d, frozen_until %d, hurt %d, health %d" % [
		FighterState.Action.find_key(state.action),
		state.action_since,
		state.action_move,
		state.stun_until_tick,
		state.frozen_until_tick,
		state.hurt_tick,
		state.health,
	]


func _swing_ticks(tickrate: int) -> int:
	return WINDUP_TICKS[tickrate] + ACTIVE_TICKS[tickrate] + RECOVERY_TICKS[tickrate]


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


func _assert_never_frozen(duel: Duel, index: int) -> void:
	_assert_frozen_between(duel, index, FighterState.NEVER, FighterState.NEVER)


# The charger's combat output on the tick after the light's touch shows the armor: the 12 gone,
# the hurt stamp on the contact, no stun, no freeze, no block, and the charged still its action.
func _assert_armored(duel: Duel, contact: int, health_before: int) -> void:
	var row := duel.row_at(contact + 1)
	assert_object(row).override_failure_message("tick %d was not run" % (contact + 1)).is_not_null()
	var state := row.fought[0]
	var message := "tick %d: %s, expected the armor against the contact at %d" % [
		row.tick,
		_action_line(state),
		contact,
	]
	assert_int(state.health).override_failure_message(message).is_equal(
		health_before - LIGHT_DAMAGE
	)
	assert_int(state.hurt_tick).override_failure_message(message).is_equal(contact)
	assert_int(state.stun_until_tick).override_failure_message(message).is_equal(FighterState.NEVER)
	assert_int(state.frozen_until_tick).override_failure_message(message).is_equal(
		FighterState.NEVER
	)
	assert_int(state.block_tick).override_failure_message(message).is_equal(FighterState.NEVER)
	assert_str(String(state.action_move)).override_failure_message(message).is_equal(
		String(CHARGED)
	)
	assert_bool(Combat.stunned(state)).override_failure_message(message).is_false()
	assert_bool(row.plans[0].frozen).override_failure_message(message).is_false()


# The charger's combat output on the tick after the light's touch shows the hit as always: the 12
# gone, the hitstun to contact + 24 + 4, the freeze to contact + 4, and the swing over.
func _assert_stunned_as_always(duel: Duel, contact: int, tickrate: int) -> void:
	var row := duel.row_at(contact + 1)
	assert_object(row).override_failure_message("tick %d was not run" % (contact + 1)).is_not_null()
	var state := row.fought[0]
	var message := "tick %d: %s, expected the hitstun of the contact at %d" % [
		row.tick,
		_action_line(state),
		contact,
	]
	assert_int(state.action).override_failure_message(message).is_equal(FighterState.Action.HITSTUN)
	assert_int(state.health).override_failure_message(message).is_equal(MAX_HEALTH - LIGHT_DAMAGE)
	assert_int(state.hurt_tick).override_failure_message(message).is_equal(contact)
	assert_int(state.stun_until_tick).override_failure_message(message).is_equal(
		contact + LIGHT_HITSTUN_TICKS[tickrate] + LIGHT_HITSTOP_TICKS[tickrate]
	)
	assert_int(state.frozen_until_tick).override_failure_message(message).is_equal(
		contact + LIGHT_HITSTOP_TICKS[tickrate]
	)


# The phases of a charged fired at `first` run untouched on every tick of the run from `first` to
# `last`, inclusive: the windup since first, the active since first + 42, the recovery since
# first + 49 (combate.md, "A armadura": "a preparação segue, e o carregado desce no tick de
# sempre").
func _assert_phases_untouched(duel: Duel, first: int, last: int, tickrate: int) -> void:
	var active_from := first + WINDUP_TICKS[tickrate]
	var recovery_from := active_from + ACTIVE_TICKS[tickrate]
	var end := recovery_from + RECOVERY_TICKS[tickrate]
	var violations: Array[String] = []
	for row: Duel.Row in duel.rows:
		if row.tick < first or row.tick > last:
			continue
		var state := row.fought[0]
		var expected_action := FighterState.Action.NONE
		var expected_since := FighterState.NEVER
		if row.tick < active_from:
			expected_action = FighterState.Action.WINDUP
			expected_since = first
		elif row.tick < recovery_from:
			expected_action = FighterState.Action.ACTIVE
			expected_since = active_from
		elif row.tick < end:
			expected_action = FighterState.Action.RECOVERY
			expected_since = recovery_from
		if state.action != expected_action:
			violations.append(
				"tick %d: %s, expected %s"
				% [row.tick, _action_line(state), FighterState.Action.find_key(expected_action)]
			)
		elif expected_action != FighterState.Action.NONE and state.action_since != expected_since:
			violations.append(
				"tick %d: %s, expected since %d" % [row.tick, _action_line(state), expected_since]
			)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()


# Criterion 2: a light that touches the charger early in the windup takes 12 and gives no stun and
# no freeze; the windup goes on, the 25 are paid on the first active tick, the cut comes down on
# its usual tick and hits the light's attacker for 30; the light's attacker reads the hurt stamp
# and freezes the 4 ticks of a hit, its swing ending that much later (combate.md, "A armadura";
# DEC-0056 §3: "Quem bateu congela pela foto, como num acerto").
func test_a_light_on_the_charged_windup_takes_12_without_a_stun_and_the_windup_goes_on(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var charged_press := FIRST_TICK + PRESS_AFTER_START
	var light_contact := charged_press + EARLY_IN_THE_WINDUP
	var light_press := light_contact - LIGHT_CONTACT_OFFSET[tickrate]
	assert_int(light_press).is_greater_equal(FIRST_TICK)
	var light_end := light_press + LIGHT_SWING_TICKS[tickrate] + LIGHT_HITSTOP_TICKS[tickrate]
	var active_from := charged_press + WINDUP_TICKS[tickrate]
	var cut_contact := active_from + CHARGED_ACTIVE_TICK_AT_2_3_M[tickrate] - 1
	var duel := _duel(tickrate, charged_press, light_press)
	# The light's press comes before the charged's: the charger's script fires on charged_press
	# whatever the other does, and the other's light is in the air when the charged begins.
	duel.run_through(charged_press + _swing_ticks(tickrate) + SPARE_TICKS)
	assert_int(duel.contact_tick_of(1)).override_failure_message("the light missed").is_equal(
		light_contact
	)
	assert_str(String(duel.row_at(light_contact).fought[1].contact_target)).is_equal(
		String(CHARGER)
	)
	_assert_armored(duel, light_contact, MAX_HEALTH)
	# The armor never freezes the charger nor moves its phases; only its own cut landing does, from
	# the tick the photo shows the hit (DEC-0055 §4; released by Arthur, F-195).
	_assert_phases_untouched(duel, charged_press, cut_contact + 1, tickrate)
	_assert_frozen_between(
		duel,
		0,
		cut_contact + 2,
		cut_contact + 1 + CHARGED_HITSTOP_TICKS[tickrate],
	)
	var released := duel.row_at(active_from).fought[0]
	assert_int(released.stamina_spent_tick).override_failure_message(_action_line(released)) \
			.is_equal(active_from)
	assert_float(Stamina.at(released, duel.fighter(0).config(), active_from)).is_equal_approx(
		STAMINA_MAX - CHARGED_COST,
		HAIR,
	)
	# The cut comes down on its usual tick and the light's attacker, in its recovery, takes it.
	assert_int(duel.contact_tick_of(0)).override_failure_message("the cut missed or moved") \
			.is_equal(cut_contact)
	var cut := duel.row_at(cut_contact + 1).fought[1]
	assert_int(cut.health).override_failure_message(_action_line(cut)).is_equal(
		MAX_HEALTH - CHARGED_DAMAGE
	)
	assert_int(cut.hurt_tick).is_equal(cut_contact)
	assert_int(cut.action).is_equal(FighterState.Action.HITSTUN)
	# The light's attacker: frozen 4 ticks from light_contact + 2, the freeze of a hit, then the
	# 7 of the charged it takes.
	var violations: Array[String] = []
	for row: Duel.Row in duel.rows:
		var frozen := (
			(
				row.tick >= light_contact + 2
				and row.tick <= light_contact + 1 + LIGHT_HITSTOP_TICKS[tickrate]
			)
			or (
				row.tick >= cut_contact + 1
				and row.tick <= cut_contact + CHARGED_HITSTOP_TICKS[tickrate]
			)
		)
		if row.plans[1].frozen != frozen:
			violations.append(
				"tick %d: the light's attacker frozen %s" % [row.tick, row.plans[1].frozen]
			)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	assert_int(light_end).is_less(cut_contact)
	var light_over := duel.row_at(light_end).fought[1]
	assert_int(light_over.action).override_failure_message(_action_line(light_over)).is_equal(
		FighterState.Action.NONE
	)
	assert_int(duel.row_at(light_end - 1).fought[1].action).is_equal(FighterState.Action.RECOVERY)


# Criterion 2, the limit: a light that touches on the last windup tick still meets the armor: the
# charger takes 12 on the first active tick, its active since that tick, and pays the 25 there;
# the cut comes down on its usual tick and hits the light's attacker (combate.md, "A armadura":
# "Um leve que toca no último tick da preparação ainda bate na armadura").
func test_a_light_touching_on_the_last_windup_tick_still_meets_the_armor(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var charged_press := FIRST_TICK + 1
	var active_from := charged_press + WINDUP_TICKS[tickrate]
	var light_contact := active_from - 1
	var light_press := light_contact - LIGHT_CONTACT_OFFSET[tickrate]
	var cut_contact := active_from + CHARGED_ACTIVE_TICK_AT_2_3_M[tickrate] - 1
	var duel := _duel(tickrate, charged_press, light_press)
	duel.run_through(charged_press + _swing_ticks(tickrate) + SPARE_TICKS)
	assert_int(duel.contact_tick_of(1)).is_equal(light_contact)
	_assert_armored(duel, light_contact, MAX_HEALTH)
	var released := duel.row_at(active_from).fought[0]
	assert_int(released.action).override_failure_message(_action_line(released)).is_equal(
		FighterState.Action.ACTIVE
	)
	assert_int(released.action_since).is_equal(active_from)
	assert_int(released.stamina_spent_tick).is_equal(active_from)
	# The armor never freezes the charger nor moves its phases; only its own cut landing does, from
	# the tick the photo shows the hit (DEC-0055 §4; released by Arthur, F-195).
	_assert_phases_untouched(duel, charged_press, cut_contact + 1, tickrate)
	_assert_frozen_between(
		duel,
		0,
		cut_contact + 2,
		cut_contact + 1 + CHARGED_HITSTOP_TICKS[tickrate],
	)
	assert_int(duel.contact_tick_of(0)).is_equal(cut_contact)
	var cut := duel.row_at(cut_contact + 1).fought[1]
	assert_int(cut.health).override_failure_message(_action_line(cut)).is_equal(
		MAX_HEALTH - CHARGED_DAMAGE
	)
	assert_int(cut.hurt_tick).is_equal(cut_contact)
	assert_int(cut.action).is_equal(FighterState.Action.HITSTUN)
	# The light's attacker froze on light_contact + 2, reading the armor's hurt stamp.
	assert_bool(duel.row_at(light_contact + 2).plans[1].frozen).is_true()
	assert_bool(duel.row_at(light_contact + 1).plans[1].frozen).is_false()


# Criterion 2, the other side of the limit: a light that touches on the first active tick stuns as
# always and ends the charged: the hitstun of 24 plus 4, the cut never comes down, the light's
# attacker keeps its health, and the charger acts again when the stun ends (combate.md, "A
# armadura": "Um que toca no primeiro tick ativo [...] pega como sempre: o tranco, e o golpe
# acaba").
func test_a_light_touching_on_the_first_active_tick_stuns_and_ends_the_charged(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var charged_press := FIRST_TICK + 1
	var active_from := charged_press + WINDUP_TICKS[tickrate]
	var light_contact := active_from
	var light_press := light_contact - LIGHT_CONTACT_OFFSET[tickrate]
	var stun_ends := light_contact + LIGHT_HITSTUN_TICKS[tickrate] + LIGHT_HITSTOP_TICKS[tickrate]
	var duel := _duel(tickrate, charged_press, light_press)
	duel.run_through(maxi(stun_ends, charged_press + _swing_ticks(tickrate)) + SPARE_TICKS)
	assert_int(duel.contact_tick_of(1)).is_equal(light_contact)
	var on_contact := duel.row_at(light_contact).fought[0]
	assert_int(on_contact.action).override_failure_message(_action_line(on_contact)).is_equal(
		FighterState.Action.ACTIVE
	)
	_assert_stunned_as_always(duel, light_contact, tickrate)
	assert_int(duel.contact_tick_of(0)).override_failure_message("the ended charged touched") \
			.is_equal(FighterState.NEVER)
	var violations: Array[String] = []
	for row: Duel.Row in duel.rows:
		var other := row.fought[1]
		if other.health != MAX_HEALTH or other.hurt_tick != FighterState.NEVER:
			violations.append(
				"tick %d: the light's attacker was hit, %s" % [row.tick, _action_line(other)]
			)
		var charger := row.fought[0]
		if (
			row.tick > light_contact and row.tick < stun_ends
			and charger.action != FighterState.Action.HITSTUN
		):
			violations.append(
				"tick %d: charger %s, expected HITSTUN" % [row.tick, _action_line(charger)]
			)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	assert_int(_acts_again(duel, 0, light_contact + 1)).is_equal(stun_ends)
	_assert_frozen_between(
		duel,
		0,
		light_contact + 1,
		light_contact + LIGHT_HITSTOP_TICKS[tickrate],
	)


# Criterion 2: in the recovery the light interrupts as always (combate.md, "A armadura do
# carregado": "A recuperação do carregado não tem armadura"). The charger looks sideways, so its
# cut meets nobody; the light lands in its recovery and the charger is stunned, its swing over.
func test_a_light_on_the_charged_recovery_stuns_as_always(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var charged_press := FIRST_TICK + 1
	var recovery_from := charged_press + WINDUP_TICKS[tickrate] + ACTIVE_TICKS[tickrate]
	var light_contact := recovery_from + 3
	var light_press := light_contact - LIGHT_CONTACT_OFFSET[tickrate]
	var stun_ends := light_contact + LIGHT_HITSTUN_TICKS[tickrate] + LIGHT_HITSTOP_TICKS[tickrate]
	var duel := _duel(tickrate, charged_press, light_press, SIDEWAYS)
	duel.run_through(maxi(stun_ends, charged_press + _swing_ticks(tickrate)) + SPARE_TICKS)
	assert_int(duel.contact_tick_of(0)).override_failure_message("the sideways cut touched") \
			.is_equal(FighterState.NEVER)
	assert_int(duel.contact_tick_of(1)).is_equal(light_contact)
	var on_contact := duel.row_at(light_contact).fought[0]
	assert_int(on_contact.action).override_failure_message(_action_line(on_contact)).is_equal(
		FighterState.Action.RECOVERY
	)
	_assert_stunned_as_always(duel, light_contact, tickrate)
	for row: Duel.Row in duel.rows:
		if row.tick > light_contact:
			assert_int(row.fought[0].action) \
					.override_failure_message("tick %d: %s"
			% [row.tick, _action_line(row.fought[0])]) \
					.is_not_equal(FighterState.Action.RECOVERY)
	assert_int(_acts_again(duel, 0, light_contact + 1)).is_equal(stun_ends)


# Criterion 2, the failure of the armor: against a charged it is worth nothing (combate.md, "A
# armadura": "Contra o carregado, a armadura não vale"). A second charger in its windup, 1,5 m
# ahead, takes the first one's cut with the 30, the hitstun of 42 plus 7, and its own charged ends
# before its active: it touches nobody, and the first charger keeps its health.
func test_the_armor_is_worth_nothing_against_a_charged(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var first_press := FIRST_TICK + 1
	var second_press := first_press + EARLY_IN_THE_WINDUP
	var contact := first_press + WINDUP_TICKS[tickrate]
	var stun_ends := contact + HITSTUN_TICKS_OF_THE_CHARGED[tickrate] + CHARGED_HITSTOP_TICKS[
		tickrate
	]
	assert_int(contact).is_less(second_press + WINDUP_TICKS[tickrate])
	var combat := ChargedRig.load_combat(tickrate)
	var duel := Duel.new()
	duel.add(
		_fighter(CHARGER, tickrate, Vector3.ZERO, 0.0, combat),
		_charger(PackedInt32Array([first_press]), 0.0),
	)
	duel.add(
		_fighter(OTHER, tickrate, CLOSE, FACING_THE_OTHER, combat),
		_charger(PackedInt32Array([second_press]), FACING_THE_OTHER),
	)
	duel.run_through(maxi(stun_ends, second_press + _swing_ticks(tickrate)) + SPARE_TICKS)
	assert_int(duel.contact_tick_of(0)).is_equal(contact)
	var on_contact := duel.row_at(contact).fought[1]
	assert_int(on_contact.action).override_failure_message(_action_line(on_contact)).is_equal(
		FighterState.Action.WINDUP
	)
	assert_str(String(on_contact.action_move)).is_equal(String(CHARGED))
	var hit := duel.row_at(contact + 1).fought[1]
	var message := "tick %d: %s" % [contact + 1, _action_line(hit)]
	assert_int(hit.action).override_failure_message(message).is_equal(FighterState.Action.HITSTUN)
	assert_int(hit.health).override_failure_message(message).is_equal(MAX_HEALTH - CHARGED_DAMAGE)
	assert_int(hit.hurt_tick).override_failure_message(message).is_equal(contact)
	assert_int(hit.stun_until_tick).override_failure_message(message).is_equal(stun_ends)
	assert_int(duel.contact_tick_of(1)).override_failure_message("the ended charged touched") \
			.is_equal(FighterState.NEVER)
	for row: Duel.Row in duel.rows:
		assert_int(row.fought[0].health).override_failure_message("tick %d" % row.tick).is_equal(
			MAX_HEALTH
		)
		if row.tick > contact:
			assert_int(row.fought[1].action) \
					.override_failure_message("tick %d: %s"
			% [row.tick, _action_line(row.fought[1])]) \
					.is_not_equal(FighterState.Action.ACTIVE)
	assert_int(_acts_again(duel, 1, contact + 1)).is_equal(stun_ends)
