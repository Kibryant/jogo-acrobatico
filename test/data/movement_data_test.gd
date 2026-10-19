# Criterion 5 of TASK-9: the data check, layer 3 of DEC-0027 §2. A movement .tres with an
# impossible number must fail the gate: MovementData.validate() returns one message per
# impossible number, movement_v0.tres passes it, and the scan below runs it over every
# MovementData under res://data/, so a bad file committed later fails here. The baseline numbers
# come from docs/design/movimento.md, cited by section. TASK-10.1, criterion 7, adds the double
# jump and the stamina (movimento.md, "Pulo e ar" and "Stamina").
extends GdUnitTestSuite

const MOVEMENT_V0 := "res://data/movement_v0.tres"
const DATA_DIR := "res://data"
const HAIR := 1e-9 # floating-point slack, not a design number

# The six times of the skeleton (movimento.md, "Chão", "Pulo e ar" and "Perdão") and the wait
# of the stamina ("Stamina") as MovementData fields (TASK-9 and TASK-10.1 plans).
const TIME_FIELDS: Array[String] = [
	"accel_time_ms",
	"stop_time_ms",
	"jump_rise_ms",
	"jump_fall_ms",
	"coyote_ms",
	"buffer_ms",
	"stamina_wait_ms",
]

# The five numbers of TASK-10.1 (movimento.md, "Pulo e ar" and "Stamina"), each with one value
# that cannot be: a height of zero, a max of zero, a negative cost, a negative wait and a
# negative regen. The height, the max, the cost and the regen are floats; the wait is a time.
const NEW_IMPOSSIBLE: Dictionary[String, Variant] = {
	"double_jump_height_m": 0.0,
	"stamina_max": 0.0,
	"double_jump_cost": -10.0,
	"stamina_wait_ms": -1,
	"stamina_regen_per_s": -30.0,
}


# The numbers of movimento.md as a MovementData built in code: the baseline each failure case
# breaks one number of. The .tres is checked against the same numbers in its own test.
func _design_data() -> MovementData:
	var data := MovementData.new()
	data.capsule_height_m = 1.8 # "O corpo"
	data.capsule_radius_m = 0.35 # "O corpo"
	data.max_slope_deg = 45.0 # "O corpo": above it, it is not floor
	data.run_speed_mps = 7.0 # "Chão"
	data.accel_time_ms = 150 # "Chão"
	data.stop_time_ms = 100 # "Chão"
	data.jump_height_m = 1.2 # "Pulo e ar"
	data.jump_rise_ms = 350 # "Pulo e ar"
	data.jump_fall_ms = 280 # "Pulo e ar"
	data.air_control_pct = 25.0 # "Pulo e ar": 25 % of the ground acceleration
	data.max_fall_speed_mps = 30.0 # "Pulo e ar"
	data.coyote_ms = 100 # "Perdão"
	data.buffer_ms = 150 # "Perdão"
	data.double_jump_height_m = 1.0 # "Pulo e ar": "Altura do pulo duplo"
	data.double_jump_cost = 10.0 # "Pulo e ar": "Custo do pulo duplo"
	data.stamina_max = 100.0 # "Stamina": "Máximo"
	data.stamina_wait_ms = 800 # "Stamina": "Espera para recuperar"
	data.stamina_regen_per_s = 30.0 # "Stamina": "Recuperação"
	return data


func _load_v0() -> MovementData:
	var resource: Resource = load(MOVEMENT_V0)
	assert(
		resource is MovementData,
		"%s must load as a MovementData (TASK-9, part 1)" % MOVEMENT_V0,
	)
	return resource as MovementData


# Every .tres under a folder, recursively.
func _tres_files_under(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open(dir_path)
	assert(dir != null, "%s must exist (TASK-9, part 1)" % dir_path)
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var path := dir_path.path_join(entry)
		if dir.current_is_dir():
			if not entry.begins_with("."):
				found.append_array(_tres_files_under(path))
		elif entry.get_extension() == "tres":
			found.append(path)
		entry = dir.get_next()
	dir.list_dir_end()
	return found


func test_movement_v0_holds_the_numbers_of_movimento_md() -> void:
	var data := _load_v0()
	var design := _design_data()
	assert_float(data.capsule_height_m).is_equal_approx(design.capsule_height_m, HAIR)
	assert_float(data.capsule_radius_m).is_equal_approx(design.capsule_radius_m, HAIR)
	assert_float(data.max_slope_deg).is_equal_approx(design.max_slope_deg, HAIR)
	assert_float(data.run_speed_mps).is_equal_approx(design.run_speed_mps, HAIR)
	assert_int(data.accel_time_ms).is_equal(design.accel_time_ms)
	assert_int(data.stop_time_ms).is_equal(design.stop_time_ms)
	assert_float(data.jump_height_m).is_equal_approx(design.jump_height_m, HAIR)
	assert_int(data.jump_rise_ms).is_equal(design.jump_rise_ms)
	assert_int(data.jump_fall_ms).is_equal(design.jump_fall_ms)
	assert_float(data.air_control_pct).is_equal_approx(design.air_control_pct, HAIR)
	assert_float(data.max_fall_speed_mps).is_equal_approx(design.max_fall_speed_mps, HAIR)
	assert_int(data.coyote_ms).is_equal(design.coyote_ms)
	assert_int(data.buffer_ms).is_equal(design.buffer_ms)
	assert_float(data.double_jump_height_m).is_equal_approx(design.double_jump_height_m, HAIR)
	assert_float(data.double_jump_cost).is_equal_approx(design.double_jump_cost, HAIR)
	assert_float(data.stamina_max).is_equal_approx(design.stamina_max, HAIR)
	assert_int(data.stamina_wait_ms).is_equal(design.stamina_wait_ms)
	assert_float(data.stamina_regen_per_s).is_equal_approx(design.stamina_regen_per_s, HAIR)


func test_movement_v0_passes_the_data_check() -> void:
	assert_array(_load_v0().validate()).is_empty()


func test_the_design_numbers_pass_the_data_check() -> void:
	assert_array(_design_data().validate()).is_empty()


# The gate's data check: a bad movement .tres committed anywhere under data/ fails here.
func test_every_movement_tres_under_data_passes_the_data_check() -> void:
	var checked := 0
	for path: String in _tres_files_under(DATA_DIR):
		var resource: Resource = load(path)
		assert_object(resource).override_failure_message("%s does not load" % path).is_not_null()
		if resource is MovementData:
			var data := resource as MovementData
			var errors := data.validate()
			var message := "%s has impossible numbers: %s" % [path, errors]
			assert_array(errors).override_failure_message(message).is_empty()
			checked += 1
	var none := "no MovementData under %s: the scan found nothing to check" % DATA_DIR
	assert_int(checked).override_failure_message(none).is_greater_equal(1)


func test_a_negative_time_is_rejected(
	field: String,
	_test_parameters := [
		["accel_time_ms"],
		["stop_time_ms"],
		["jump_rise_ms"],
		["jump_fall_ms"],
		["coyote_ms"],
		["buffer_ms"],
		["stamina_wait_ms"],
	],
) -> void:
	var data := _design_data()
	data.set(field, -1)
	assert_int(data.get(field)).override_failure_message("%s is not a field" % field).is_equal(-1)
	var errors := data.validate()
	assert_array(errors).override_failure_message("%s = -1 must be rejected" % field).has_size(1)
	_assert_one_readable_message(errors)


# Acceleration is speed / time, deceleration is speed / time, and the jump's gravity and exit
# speed come from the rise and fall times (movimento.md, the "Deriva" notes of "Chão" and "Pulo
# e ar"): zero there divides by zero.
func test_a_zero_time_where_the_rule_divides_is_rejected(
	field: String,
	_test_parameters := [["accel_time_ms"], ["stop_time_ms"], ["jump_rise_ms"], ["jump_fall_ms"]],
) -> void:
	var data := _design_data()
	data.set(field, 0)
	assert_int(data.get(field)).override_failure_message("%s is not a field" % field).is_equal(0)
	var errors := data.validate()
	assert_array(errors).override_failure_message("%s = 0 must be rejected" % field).has_size(1)
	_assert_one_readable_message(errors)


# Nothing divides by the windows ("Perdão"): zero is a legitimate "no forgiveness".
func test_a_zero_forgiveness_window_is_allowed(
	field: String,
	_test_parameters := [["coyote_ms"], ["buffer_ms"]],
) -> void:
	var data := _design_data()
	data.set(field, 0)
	assert_int(data.get(field)).override_failure_message("%s is not a field" % field).is_equal(0)
	assert_array(data.validate()).override_failure_message("%s = 0 must pass" % field).is_empty()


func test_a_slope_above_90_degrees_is_rejected(
	deg: float,
	_test_parameters := [[90.5], [91.0], [180.0]],
) -> void:
	var data := _design_data()
	data.max_slope_deg = deg
	var errors := data.validate()
	assert_array(errors).override_failure_message("slope %.1f° must be rejected" % deg).has_size(1)
	_assert_one_readable_message(errors)


func test_a_slope_up_to_90_degrees_is_allowed(
	deg: float,
	_test_parameters := [[0.0], [45.0], [90.0]],
) -> void:
	var data := _design_data()
	data.max_slope_deg = deg
	assert_array(data.validate()).override_failure_message("slope %.1f° must pass" % deg).is_empty()


func test_a_negative_slope_is_rejected() -> void:
	var data := _design_data()
	data.max_slope_deg = -1.0
	assert_array(data.validate()).has_size(1)


# The other numbers that cannot be: a negative speed, height, fall cap or air control, a
# capsule without height or radius (movimento.md, "O corpo", "Chão" and "Pulo e ar"), and from
# TASK-10.1 a double jump without height, a negative cost and a negative regen (movimento.md,
# "Pulo e ar" and "Stamina"; the double jump's exit speed comes from its height, so zero is
# no jump).
func test_other_impossible_numbers_are_rejected(
	field: String,
	value: float,
	_test_parameters := [
		["run_speed_mps", -7.0],
		["jump_height_m", -1.2],
		["max_fall_speed_mps", -30.0],
		["air_control_pct", -25.0],
		["capsule_height_m", 0.0],
		["capsule_height_m", -1.8],
		["capsule_radius_m", 0.0],
		["capsule_radius_m", -0.35],
		["double_jump_height_m", 0.0],
		["double_jump_height_m", -1.0],
		["double_jump_cost", -10.0],
		["stamina_regen_per_s", -30.0],
	],
) -> void:
	var data := _design_data()
	data.set(field, value)
	assert_float(data.get(field)).override_failure_message("%s is not a field" % field).is_equal(
		value
	)
	var errors := data.validate()
	var message := "%s = %s must be rejected" % [field, value]
	assert_array(errors).override_failure_message(message).has_size(1)
	_assert_one_readable_message(errors)


func test_every_impossible_number_gets_its_own_message() -> void:
	var data := _design_data()
	data.accel_time_ms = -150
	data.jump_rise_ms = 0
	data.max_slope_deg = 100.0
	assert_array(data.validate()).has_size(3)


func test_every_negative_time_gives_its_own_message() -> void:
	var data := _design_data()
	for field: String in TIME_FIELDS:
		data.set(field, -1)
	assert_array(data.validate()).has_size(TIME_FIELDS.size())


# TASK-10.1, criterion 7: the wait may be 0 ms (no wait; nothing divides by it) and the regen
# may be 0 points/s (the test fixtures freeze the bar that way, TASK-10.1 plan).
func test_a_zero_stamina_wait_or_regen_is_allowed(
	field: String,
	value: Variant,
	_test_parameters := [["stamina_wait_ms", 0], ["stamina_regen_per_s", 0.0]],
) -> void:
	var data := _design_data()
	data.set(field, value)
	assert_bool(data.get(field) == value).override_failure_message("%s is not a field" % field) \
			.is_true()
	assert_array(data.validate()).override_failure_message("%s = 0 must pass" % field).is_empty()


# The cost must fit the bar: above the max it is rejected with a message naming the cost; at
# the max (the limit) and at zero (none) it passes (TASK-10.1 plan: "não negativo e até
# stamina_max").
func test_a_double_jump_cost_above_the_stamina_max_is_rejected() -> void:
	var data := _design_data()
	data.double_jump_cost = data.stamina_max + 0.5
	var errors := data.validate()
	assert_array(errors).override_failure_message("cost above the max must be rejected") \
			.has_size(1)
	if errors.size() == 1:
		assert_str(errors[0]).contains("double_jump_cost")


func test_a_double_jump_cost_up_to_the_stamina_max_is_allowed(
	cost: float,
	_test_parameters := [[0.0], [10.0], [100.0]],
) -> void:
	var data := _design_data()
	data.double_jump_cost = cost
	assert_array(data.validate()).override_failure_message("cost %.1f must pass" % cost) \
			.is_empty()


# A bar with no points cannot pay anything: the max must be positive (movimento.md, "Stamina").
# The cost is set to 0 so that only the max is wrong: exactly one message, naming it.
func test_a_stamina_max_of_zero_is_rejected() -> void:
	var data := _design_data()
	data.double_jump_cost = 0.0
	data.stamina_max = 0.0
	var errors := data.validate()
	assert_array(errors).override_failure_message("stamina_max = 0 must be rejected").has_size(1)
	if errors.size() == 1:
		assert_str(errors[0]).contains("stamina_max")


# A negative max is rejected with a message naming it; whether a cost of 0 "above" a negative
# max adds a second message is the implementer's call, so only the max's message is required.
func test_a_negative_stamina_max_is_rejected() -> void:
	var data := _design_data()
	data.double_jump_cost = 0.0
	data.stamina_max = -100.0
	var errors := data.validate()
	var named := false
	for message: String in errors:
		if message.contains("stamina_max"):
			named = true
	var unnamed := "no message names stamina_max, got: %s" % [errors]
	assert_bool(named).override_failure_message(unnamed).is_true()


# Many: the five new numbers wrong at once give five messages, each naming its field; with the
# cost negative, no "cost above max" message can double up on the zero max.
func test_five_impossible_new_numbers_give_five_messages_each_naming_its_field() -> void:
	var data := _design_data()
	for field: String in NEW_IMPOSSIBLE:
		data.set(field, NEW_IMPOSSIBLE[field])
		var set_message := "%s is not a field" % field
		assert_bool(data.get(field) == NEW_IMPOSSIBLE[field]) \
				.override_failure_message(set_message) \
				.is_true()
	var errors := data.validate()
	assert_array(errors).has_size(NEW_IMPOSSIBLE.size())
	for field: String in NEW_IMPOSSIBLE:
		var named := false
		for message: String in errors:
			if message.contains(field):
				named = true
		var unnamed := "no message names %s, got: %s" % [field, errors]
		assert_bool(named).override_failure_message(unnamed).is_true()


# The gate prints the message: it must say something. Guarded, so a missing rejection fails on
# the size assertion above instead of on an index error here.
func _assert_one_readable_message(errors: PackedStringArray) -> void:
	if errors.size() == 1:
		assert_str(errors[0]).is_not_empty()
