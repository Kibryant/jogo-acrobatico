# Criterion 5 of TASK-12.14, the data half: the convergence is a number of the CombatData,
# aim_convergence_m, in metres, 2,0 in combat_v0.tres (combate.md, "A lâmina e o contato":
# "Convergência"; "A espada na mira": "Os nomes no código"; DEC-0057 §1). The data check refuses a
# convergence of zero or below and says why, naming the field; the configuration copies the
# number as aim_convergence; and the v0's convergence is greater than the shoulder of
# movement_v0.tres, as the shoulder equals the camera's (DEC-0045 §2): otherwise the blade would
# never reach the aim line. The numbers are read by their agreed names, so each case fails on its
# own while the data has no such number.
extends GdUnitTestSuite

const COMBAT_V0 := "res://data/combat_v0.tres"
const MOVEMENT_V0 := "res://data/movement_v0.tres"
const DATA_FIELD := &"aim_convergence_m"
const CONFIG_FIELD := &"aim_convergence"

const CONVERGENCE_M := 2.0 # combate.md, "A lâmina e o contato": "Convergência", 2,0 m
const SHOULDER_M := 0.8 # movimento.md, "Câmera": "Ombro", 0,8 m to the right
# combate.md, "A lâmina e o contato": "Comprimento da lâmina": "A ponta a 2,0 m do eixo"; the
# convergence is "onde chega a ponta da lâmina" (DEC-0057 §1): the hand's 0,6 m plus the 1,4 m.
const HAND_M := 0.6
const BLADE_M := 1.4
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


# A copy of the v0 with this convergence, in metres; the case stops being meaningful, and fails
# here, while the data has no such number.
func _v0_with_convergence(convergence_m: float) -> CombatData:
	var data := _v0_copy()
	data.set(DATA_FIELD, convergence_m)
	assert_that(data.get(DATA_FIELD)) \
			.override_failure_message("CombatData has no %s" % DATA_FIELD) \
			.is_equal(convergence_m)
	return data


func _assert_some_message_names(errors: PackedStringArray, field: String) -> void:
	var named := false
	for message: String in errors:
		if message.contains(field):
			named = true
	var unnamed := "no message names %s, got: %s" % [field, errors]
	assert_bool(named).override_failure_message(unnamed).is_true()


# combat_v0.tres holds the convergence of the design, 2,0 m, where the blade's tip reaches, and
# still passes the data check.
func test_combat_v0_holds_the_convergence_of_2_0_m_and_passes_the_data_check() -> void:
	var data := _load_v0()
	var convergence := _float_of(data, DATA_FIELD)
	assert_float(convergence).override_failure_message("CombatData has no %s" % DATA_FIELD) \
			.is_equal_approx(CONVERGENCE_M, HAIR)
	assert_float(convergence).is_equal_approx(HAND_M + BLADE_M, HAIR)
	assert_array(data.validate()).is_empty()
	assert_array(_v0_copy().validate()).is_empty()


# Criterion 5: the convergence of the v0 is greater than the shoulder of movement_v0.tres, the
# two files read side by side, as the shoulder's own equality with the camera's is (DEC-0045 §2;
# DEC-0057, "Consequências").
func test_the_convergence_of_the_v0_is_greater_than_the_shoulder_of_movement_v0() -> void:
	var convergence := _float_of(_load_v0(), DATA_FIELD)
	var movement := _load_movement_v0()
	assert_float(movement.aim_side_m).is_equal_approx(SHOULDER_M, HAIR)
	var message := "aim_convergence_m is %s and the shoulder, aim_side_m, is %s" % [
		convergence,
		movement.aim_side_m,
	]
	assert_bool(is_nan(convergence)).override_failure_message(message).is_false()
	assert_float(convergence).override_failure_message(message).is_greater(
		absf(movement.aim_side_m)
	)


# Failure: a convergence of zero or below is refused, and a message names the field.
func test_a_convergence_of_zero_or_below_is_rejected_naming_its_field(
	convergence_m: float,
	_test_parameters := [[0.0], [-1.0], [-2.0]],
) -> void:
	var data := _v0_with_convergence(convergence_m)
	var errors := data.validate()
	assert_array(errors).override_failure_message("%s must fail" % convergence_m) \
			.is_not_empty()
	_assert_some_message_names(errors, String(DATA_FIELD))


# One and limit: the design's 2,0 m passes, and so does any positive convergence above the
# shoulder: the field alone is checked for being positive.
func test_a_positive_convergence_passes_the_data_check(
	convergence_m: float,
	_test_parameters := [[2.0], [1.6], [5.0]],
) -> void:
	var data := _v0_with_convergence(convergence_m)
	assert_array(data.validate()) \
			.override_failure_message("%s = %s must pass, got %s"
	% [DATA_FIELD, convergence_m, data.validate()]) \
			.is_empty()


# The bad convergence is one more message beside any other bad number, not instead of it.
func test_a_bad_convergence_and_a_bad_health_name_both_fields() -> void:
	var data := _v0_with_convergence(0.0)
	data.max_health = 0
	var errors := data.validate()
	_assert_some_message_names(errors, String(DATA_FIELD))
	_assert_some_message_names(errors, "max_health")


# The configuration copies the metres as they are, at any tickrate: a length has no ticks.
func test_the_convergence_is_copied_to_the_combat_config(
	tickrate: int,
	convergence_m: float,
	_test_parameters := [[60, 2.0], [30, 2.0], [60, 1.6], [30, 3.25]],
) -> void:
	var config := CombatConfig.create(_v0_with_convergence(convergence_m), tickrate)
	assert_float(_float_of(config, CONFIG_FIELD)) \
			.override_failure_message("CombatConfig has no %s" % CONFIG_FIELD) \
			.is_equal_approx(convergence_m, HAIR)
