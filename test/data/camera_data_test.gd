# Criterion 6 of TASK-9, the camera's numbers as data, with the data check of DEC-0027 §2 (layer
# 3): camera_v0.tres holds the numbers of movimento.md, "Câmera", CameraData.validate() returns
# one message per impossible number, and the scan below runs it over every CameraData under
# res://data/, so a bad file committed later fails here.
extends GdUnitTestSuite

const CAMERA_V0 := "res://data/camera_v0.tres"
const DATA_DIR := "res://data"
const HAIR := 1e-9 # floating-point slack, not a design number


# The numbers of movimento.md, "Câmera", as a CameraData built in code: the baseline each
# failure case breaks one number of.
func _design_data() -> CameraData:
	var data := CameraData.new()
	data.distance_m = 3.5 # "Distância"
	data.pivot_height_m = 1.6 # "Altura do pivô"
	data.vertical_fov_deg = 70.0 # "Campo de visão", vertical
	data.sensitivity_deg_per_px = 0.06 # "Sensibilidade padrão"
	data.max_pitch_deg = 80.0 # Claude's v0 reading (TASK-9 plan, round B)
	return data


func _load_v0() -> CameraData:
	var resource: Resource = load(CAMERA_V0)
	assert(resource is CameraData, "%s must load as a CameraData (TASK-9, part 1)" % CAMERA_V0)
	return resource as CameraData


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


func test_camera_v0_holds_the_numbers_of_movimento_md() -> void:
	var data := _load_v0()
	var design := _design_data()
	assert_float(data.distance_m).is_equal_approx(design.distance_m, HAIR)
	assert_float(data.pivot_height_m).is_equal_approx(design.pivot_height_m, HAIR)
	assert_float(data.vertical_fov_deg).is_equal_approx(design.vertical_fov_deg, HAIR)
	assert_float(data.sensitivity_deg_per_px).is_equal_approx(design.sensitivity_deg_per_px, HAIR)
	assert_float(data.max_pitch_deg).is_equal_approx(design.max_pitch_deg, HAIR)


func test_camera_v0_passes_the_data_check() -> void:
	assert_array(_load_v0().validate()).is_empty()


# The gate's data check: a bad camera .tres committed anywhere under data/ fails here.
func test_every_camera_tres_under_data_passes_the_data_check() -> void:
	var checked := 0
	for path: String in _tres_files_under(DATA_DIR):
		var resource: Resource = load(path)
		assert_object(resource).override_failure_message("%s does not load" % path).is_not_null()
		if resource is CameraData:
			var data := resource as CameraData
			var errors := data.validate()
			var message := "%s has impossible numbers: %s" % [path, errors]
			assert_array(errors).override_failure_message(message).is_empty()
			checked += 1
	var none := "no CameraData under %s: the scan found nothing to check" % DATA_DIR
	assert_int(checked).override_failure_message(none).is_greater_equal(1)


func test_an_impossible_number_is_rejected(
	field: String,
	value: float,
	_test_parameters := [
		["distance_m", 0.0],
		["distance_m", -3.5],
		["pivot_height_m", -0.1],
		["vertical_fov_deg", 0.0],
		["vertical_fov_deg", -70.0],
		["vertical_fov_deg", 180.0],
		["vertical_fov_deg", 200.0],
		["sensitivity_deg_per_px", 0.0],
		["sensitivity_deg_per_px", -0.06],
		["max_pitch_deg", -1.0],
		["max_pitch_deg", 90.5],
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
	if errors.size() == 1:
		assert_str(errors[0]).is_not_empty()


func test_a_possible_edge_is_allowed(
	field: String,
	value: float,
	_test_parameters := [
		["pivot_height_m", 0.0],
		["vertical_fov_deg", 1.0],
		["vertical_fov_deg", 179.0],
		["max_pitch_deg", 0.0],
		["max_pitch_deg", 90.0],
	],
) -> void:
	var data := _design_data()
	data.set(field, value)
	var message := "%s = %s must pass" % [field, value]
	assert_array(data.validate()).override_failure_message(message).is_empty()


func test_every_impossible_number_gets_its_own_message() -> void:
	var data := _design_data()
	data.distance_m = -1.0
	data.vertical_fov_deg = 0.0
	data.max_pitch_deg = 120.0
	assert_array(data.validate()).has_size(3)
