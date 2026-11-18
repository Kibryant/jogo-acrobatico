# Criterion 5 of TASK-12.14, the data half, per move since TASK-12.4: the convergence is a number of
# each move's AttackData, aim_convergence_m, in metres, 2,0 for the light and the charged, where the
# blade's tip reaches, and 1,2 for the guard break, where its hand reaches (combate.md, "A lâmina e
# o contato": "Convergência"; "A espada na mira": "Os nomes no código"; DEC-0057 §1; DEC-0058 §2).
# The data check refuses a convergence of zero or below and says why, naming the move's field; the
# configuration copies each number as the move's aim_convergence; and every convergence of the v0
# is greater than the shoulder of movement_v0.tres, as the shoulder equals the camera's (DEC-0045
# §2): otherwise the weapon would never reach the aim line. The numbers are read by their agreed
# names, so each case fails on its own while the data has no such number.
extends GdUnitTestSuite

const COMBAT_V0 := "res://data/combat_v0.tres"
const MOVEMENT_V0 := "res://data/movement_v0.tres"
const DATA_FIELD := &"aim_convergence_m"
const CONFIG_FIELD := &"aim_convergence"

const LIGHT := &"light_attack"
const CHARGED := &"charged_attack"
const GUARD_BREAK := &"guard_break"
# combate.md, "A lâmina e o contato": "Convergência: 2,0 na espada; 1,2 na quebra".
const CONVERGENCE_M: Dictionary[StringName, float] = { LIGHT: 2.0, CHARGED: 2.0, GUARD_BREAK: 1.2 }
const SHOULDER_M := 0.8 # movimento.md, "Câmera": "Ombro", 0,8 m to the right
# combate.md, "A lâmina e o contato": "Comprimento da lâmina": "A ponta a 2,0 m do eixo"; the
# sword's convergence is "onde chega a ponta da lâmina" (DEC-0057 §1): the hand's 0,6 m plus the
# 1,4 m. The guard break's is where the hand reaches, its 1,2 m ("A mão"; DEC-0058 §2).
const HAND_M := 0.6
const BLADE_M := 1.4
const GUARD_BREAK_HAND_M := 1.2
const HAIR := 1e-6 # floating-point slack, not a design number


func _load_v0() -> CombatData:
	var resource: Resource = load(COMBAT_V0)
	assert(resource is CombatData, "%s must load as a CombatData" % COMBAT_V0)
	return resource as CombatData


# A deep copy of combat_v0.tres: load() caches the resource, so each case changes a duplicate.
func _v0_copy() -> CombatData:
	var copy: Resource = _load_v0().duplicate(true)
	assert(copy is CombatData, "a duplicate of %s must still be a CombatData" % COMBAT_V0)
	return copy as CombatData


func _load_movement_v0() -> MovementData:
	var resource: Resource = load(MOVEMENT_V0)
	assert(resource is MovementData, "%s must load as a MovementData" % MOVEMENT_V0)
	return resource as MovementData


# A float the object holds under this name; the case fails when it holds none, and NAN comes back.
func _float_of(object: Object, field: StringName) -> float:
	var value: Variant = object.get(field)
	var missing := "%s has no float %s" % [object, field]
	assert_bool(value is float).override_failure_message(missing).is_true()
	if value is float:
		var number: float = value
		return number
	return NAN


# A copy of the v0 with this convergence on one move, in metres; the case stops being meaningful,
# and fails here, while the data has no such number.
func _v0_with_convergence(move: StringName, convergence_m: float) -> CombatData:
	var data := _v0_copy()
	var attack := data.attack(move)
	attack.set(DATA_FIELD, convergence_m)
	assert_that(attack.get(DATA_FIELD)) \
			.override_failure_message("AttackData has no %s" % DATA_FIELD) \
			.is_equal(convergence_m)
	return data


func _assert_some_message_names(errors: PackedStringArray, field: String) -> void:
	var named := false
	for message: String in errors:
		if message.contains(field):
			named = true
	var unnamed := "no message names %s, got: %s" % [field, errors]
	assert_bool(named).override_failure_message(unnamed).is_true()


# combat_v0.tres holds the convergences of the design, 2,0 m for the light and the charged, where
# the blade's tip reaches, and 1,2 m for the guard break, where the hand reaches, and still passes
# the data check; the combat itself no longer holds one (DEC-0058 §2).
func test_combat_v0_holds_the_convergence_of_each_move_and_passes_the_data_check() -> void:
	var data := _load_v0()
	for move: StringName in CONVERGENCE_M:
		var convergence := _float_of(data.attack(move), DATA_FIELD)
		assert_float(convergence).override_failure_message("%s.%s" % [move, DATA_FIELD]) \
				.is_equal_approx(CONVERGENCE_M[move], HAIR)
	assert_float(_float_of(data.light_attack, DATA_FIELD)).is_equal_approx(HAND_M + BLADE_M, HAIR)
	assert_float(_float_of(data.guard_break, DATA_FIELD)).is_equal_approx(GUARD_BREAK_HAND_M, HAIR)
	assert_float(data.guard_break.hand_reach_m).is_equal_approx(GUARD_BREAK_HAND_M, HAIR)
	assert_bool(data.get(DATA_FIELD) == null) \
			.override_failure_message("CombatData still holds a convergence of its own") \
			.is_true()
	assert_array(data.validate()).is_empty()
	assert_array(_v0_copy().validate()).is_empty()


# Criterion 5: every convergence of the v0 is greater than the shoulder of movement_v0.tres, the
# two files read side by side, as the shoulder's own equality with the camera's is (DEC-0045 §2;
# DEC-0057, "Consequências").
func test_every_convergence_of_the_v0_is_greater_than_the_shoulder_of_movement_v0() -> void:
	var movement := _load_movement_v0()
	assert_float(movement.aim_side_m).is_equal_approx(SHOULDER_M, HAIR)
	for move: StringName in CONVERGENCE_M:
		var convergence := _float_of(_load_v0().attack(move), DATA_FIELD)
		var message := "%s.aim_convergence_m is %s and the shoulder, aim_side_m, is %s" % [
			move,
			convergence,
			movement.aim_side_m,
		]
		assert_bool(is_nan(convergence)).override_failure_message(message).is_false()
		assert_float(convergence).override_failure_message(message).is_greater(
			absf(movement.aim_side_m)
		)


# Failure: a convergence of zero or below is refused, and a message names the move's field.
func test_a_convergence_of_zero_or_below_is_rejected_naming_its_field(
	move: StringName,
	convergence_m: float,
	_test_parameters := [
		[LIGHT, 0.0],
		[LIGHT, -1.0],
		[CHARGED, -2.0],
		[GUARD_BREAK, 0.0],
		[GUARD_BREAK, -1.2],
	],
) -> void:
	var data := _v0_with_convergence(move, convergence_m)
	var errors := data.validate()
	assert_array(errors).override_failure_message("%s.%s = %s must fail"
	% [move, DATA_FIELD, convergence_m]).is_not_empty()
	_assert_some_message_names(errors, "%s.%s" % [move, DATA_FIELD])


# One and limit: the design's numbers pass, and so does any positive convergence above the
# shoulder: the field alone is checked for being positive.
func test_a_positive_convergence_passes_the_data_check(
	move: StringName,
	convergence_m: float,
	_test_parameters := [[LIGHT, 2.0], [CHARGED, 1.6], [LIGHT, 5.0], [GUARD_BREAK, 1.2]],
) -> void:
	var data := _v0_with_convergence(move, convergence_m)
	assert_array(data.validate()) \
			.override_failure_message("%s.%s = %s must pass, got %s"
	% [move, DATA_FIELD, convergence_m, data.validate()]) \
			.is_empty()


# The bad convergence is one more message beside any other bad number, not instead of it.
func test_a_bad_convergence_and_a_bad_health_name_both_fields() -> void:
	var data := _v0_with_convergence(CHARGED, 0.0)
	data.max_health = 0
	var errors := data.validate()
	_assert_some_message_names(errors, "charged_attack.aim_convergence_m")
	_assert_some_message_names(errors, "max_health")


# The configuration copies each move's metres as they are, at any tickrate: a length has no ticks.
func test_the_convergence_is_copied_to_each_moves_config(
	move: StringName,
	tickrate: int,
	convergence_m: float,
	_test_parameters := [
		[LIGHT, 60, 2.0],
		[CHARGED, 30, 2.0],
		[LIGHT, 60, 1.6],
		[CHARGED, 30, 3.25],
		[GUARD_BREAK, 60, 1.2],
		[GUARD_BREAK, 30, 1.5],
	],
) -> void:
	var config := CombatConfig.create(_v0_with_convergence(move, convergence_m), tickrate)
	assert_bool(config.attacks.has(move)).override_failure_message("no %s" % move).is_true()
	if not config.attacks.has(move):
		return
	assert_float(_float_of(config.attacks[move], CONFIG_FIELD)) \
			.override_failure_message("AttackConfig has no %s" % CONFIG_FIELD) \
			.is_equal_approx(convergence_m, HAIR)
