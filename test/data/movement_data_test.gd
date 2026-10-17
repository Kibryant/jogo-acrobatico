# Criterion 5 of TASK-9: the data check, layer 3 of DEC-0027 §2. A movement .tres with an
# impossible number must fail the gate: MovementData.validate() returns one message per
# impossible number, movement_v0.tres passes it, and the scan below runs it over every
# MovementData under res://data/, so a bad file committed later fails here. The baseline numbers
# come from docs/design/movimento.md, cited by section.
extends GdUnitTestSuite

const MOVEMENT_V0 := "res://data/movement_v0.tres"
const DATA_DIR := "res://data"
const HAIR := 1e-9 # floating-point slack, not a design number

# The six times of the skeleton (movimento.md, "Chão", "Pulo e ar" and "Perdão") as MovementData
# fields (TASK-9 plan).
const TIME_FIELDS: Array[String] = [
	"accel_time_ms",
	"stop_time_ms",
	"jump_rise_ms",
	"jump_fall_ms",
	"coyote_ms",
	"buffer_ms",
]


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


# The other numbers that cannot be: a negative speed, height, fall cap or air control, and a
# capsule without height or radius (movimento.md, "O corpo", "Chão" and "Pulo e ar").
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


func test_six_negative_times_give_six_messages() -> void:
	var data := _design_data()
	for field: String in TIME_FIELDS:
		data.set(field, -1)
	assert_array(data.validate()).has_size(TIME_FIELDS.size())


# The gate prints the message: it must say something. Guarded, so a missing rejection fails on
# the size assertion above instead of on an index error here.
func _assert_one_readable_message(errors: PackedStringArray) -> void:
	if errors.size() == 1:
		assert_str(errors[0]).is_not_empty()
