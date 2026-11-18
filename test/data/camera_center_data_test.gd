# Criterion 5 of TASK-12.15, the data part (F-219 §1: "Os dados"): the centered camera is two
# files, data/camera_center.tres and data/movement_center.tres, each equal to its v0 except the
# numbers of the aim: the shoulder, 0, and the rise, 0,6 m (movimento.md, "Câmera": "Ombro" and
# "Subida": "A câmera centrada [...] tem ombro 0 e subida 0,6 m, com o pivô a 2,2 m dos pés";
# glossario.md, "Ombro da câmera" and "Subida da câmera"). The movement's aim_side_m and
# aim_rise_m are the copies of the camera's shoulder_m and rise_m, in the centered pair and in
# the v0 pair (DEC-0045 §2; "Gancho": "De onde sai a mira"), and both new files pass the data
# check. The fields are compared by reflection over each script's stored variables, so a number
# added later is covered. The new names are read by name, so the suite loads before they exist and
# fails on what is missing, one assertion at a time.
extends GdUnitTestSuite

const CAMERA_V0 := "res://data/camera_v0.tres"
const CAMERA_CENTER := "res://data/camera_center.tres"
const MOVEMENT_V0 := "res://data/movement_v0.tres"
const MOVEMENT_CENTER := "res://data/movement_center.tres"
const HAIR := 1e-9 # floating-point slack, not a design number

# The names the plan fixes (F-219 §1; glossario.md, "Ombro da câmera" and "Subida da câmera").
const SHOULDER := "shoulder_m"
const RISE := "rise_m"
const AIM_SIDE := "aim_side_m"
const AIM_RISE := "aim_rise_m"
const CAMERA_DIFFERS: Array[String] = [SHOULDER, RISE]
const MOVEMENT_DIFFERS: Array[String] = [AIM_SIDE, AIM_RISE]

# movimento.md, "Câmera".
const V0_SHOULDER_M := 0.8 # "Ombro": 0,8 m to the right
const V0_RISE_M := 0.0 # "Subida": "0 no padrão"
const CENTER_SHOULDER_M := 0.0 # "Subida": "A câmera centrada [...] tem ombro 0"
const CENTER_RISE_M := 0.6 # "Subida": "0,6 na câmera centrada"
const PIVOT_HEIGHT_M := 1.6 # "Altura do pivô"
const CENTER_PIVOT_M := 2.2 # "Subida": "com o pivô a 2,2 m dos pés"
# What a number that does not exist yet reads as: no length of the game.
const NO_SUCH_FIELD := -424242.0


# The resource of a file, or null, with the case failed, while the file does not exist.
func _loaded(path: String) -> Resource:
	var exists := ResourceLoader.exists(path)
	assert_bool(exists).override_failure_message("%s does not exist" % path).is_true()
	if not exists:
		return null
	var resource: Resource = load(path)
	assert_object(resource).override_failure_message("%s does not load" % path).is_not_null()
	return resource


func _camera(path: String) -> CameraData:
	var resource := _loaded(path)
	var typed := resource is CameraData
	assert_bool(typed).override_failure_message("%s is not a CameraData" % path).is_true()
	if not typed:
		return null
	return resource as CameraData


func _movement(path: String) -> MovementData:
	var resource := _loaded(path)
	var typed := resource is MovementData
	assert_bool(typed).override_failure_message("%s is not a MovementData" % path).is_true()
	if not typed:
		return null
	return resource as MovementData


# The variables the object's script declares and the .tres stores, in the script's order.
func _stored_fields(object: Object) -> Array[String]:
	var fields: Array[String] = []
	for property: Dictionary in object.get_property_list():
		var usage: int = property["usage"]
		var is_script_variable := usage & PROPERTY_USAGE_SCRIPT_VARIABLE != 0
		var is_stored := usage & PROPERTY_USAGE_STORAGE != 0
		if is_script_variable and is_stored:
			fields.append(str(property["name"]))
	return fields


# A float the object holds under this name; the case fails when it holds none.
func _float_of(object: Object, field: String) -> float:
	var value: Variant = object.get(field)
	var missing := "%s has no float %s" % [object, field]
	assert_bool(value is float).override_failure_message(missing).is_true()
	if value is float:
		var number: float = value
		return number
	return NO_SUCH_FIELD


# Every stored field of `other` equals the baseline's, except the listed ones, which the script
# must declare; a field one of the two lacks is a difference.
func _assert_equal_except(baseline: Resource, other: Resource, differs: Array[String]) -> void:
	var fields := _stored_fields(baseline)
	assert_int(fields.size()).override_failure_message("the reflection found no stored field") \
			.is_greater(differs.size())
	assert_array(_stored_fields(other)).is_equal(fields)
	for field: String in differs:
		assert_bool(fields.has(field)).override_failure_message("the data has no %s" % field) \
				.is_true()
	var differences: Array[String] = []
	var compared := 0
	for field: String in fields:
		if differs.has(field):
			continue
		compared += 1
		var expected: Variant = baseline.get(field)
		var found: Variant = other.get(field)
		if typeof(found) != typeof(expected) or found != expected:
			differences.append("%s is %s, the v0 has %s" % [field, found, expected])
	assert_array(differences).override_failure_message("\n".join(differences)).is_empty()
	assert_int(compared).is_equal(fields.size() - differs.size())


# The reflection itself: it finds the numbers this suite knows by name, so an empty or a wrong
# list would not make the comparisons below pass for nothing.
func test_the_reflection_finds_the_stored_numbers_of_both_scripts() -> void:
	var camera := _stored_fields(_camera(CAMERA_V0))
	for field: String in ["distance_m", "pivot_height_m", SHOULDER, "vertical_fov_deg", RISE]:
		assert_bool(camera.has(field)).override_failure_message("CameraData has no %s" % field) \
				.is_true()
	var movement := _stored_fields(_movement(MOVEMENT_V0))
	for field: String in ["run_speed_mps", "aim_height_m", AIM_SIDE, "jump_rise_ms", AIM_RISE]:
		assert_bool(movement.has(field)) \
				.override_failure_message("MovementData has no %s" % field) \
				.is_true()
	assert_bool(camera.has("script")).is_false()
	assert_bool(movement.has("resource_path")).is_false()


# The v0 pair still holds: no rise in the camera nor in the movement, the copy equal to the
# camera's, beside the shoulder of 0,8 m ("Subida": "0 no padrão").
func test_the_v0_camera_and_movement_have_no_rise_and_the_copy_equals_the_cameras() -> void:
	var camera := _camera(CAMERA_V0)
	var movement := _movement(MOVEMENT_V0)
	var rise := _float_of(camera, RISE)
	var aim_rise := _float_of(movement, AIM_RISE)
	assert_float(rise).is_equal_approx(V0_RISE_M, HAIR)
	assert_float(aim_rise).is_equal_approx(V0_RISE_M, HAIR)
	var copied := "aim_rise_m is %s, the camera's rise_m is %s: they must be equal" % [
		aim_rise,
		rise,
	]
	assert_float(aim_rise).override_failure_message(copied).is_equal(rise)
	assert_float(camera.shoulder_m).is_equal_approx(V0_SHOULDER_M, HAIR)
	assert_float(movement.aim_side_m).is_equal(camera.shoulder_m)
	assert_array(camera.validate()).is_empty()
	assert_array(movement.validate()).is_empty()


# Criterion 5: camera_center.tres is camera_v0.tres except the shoulder and the rise: the
# distance, the pivot, the field of view, the sensitivity and whatever comes later are the same.
func test_camera_center_equals_camera_v0_except_the_shoulder_and_the_rise() -> void:
	var center := _camera(CAMERA_CENTER)
	if center == null:
		return
	_assert_equal_except(_camera(CAMERA_V0), center, CAMERA_DIFFERS)


# The centered camera's two numbers: no shoulder and a rise of 0,6 m, which puts the camera's
# pivot 2,2 m above the feet.
func test_camera_center_has_no_shoulder_and_a_rise_of_0_6_m() -> void:
	var center := _camera(CAMERA_CENTER)
	if center == null:
		return
	assert_float(center.shoulder_m).is_equal_approx(CENTER_SHOULDER_M, HAIR)
	var rise := _float_of(center, RISE)
	assert_float(rise).is_equal_approx(CENTER_RISE_M, HAIR)
	assert_float(center.pivot_height_m).is_equal_approx(PIVOT_HEIGHT_M, HAIR)
	assert_float(center.pivot_height_m + rise).is_equal_approx(CENTER_PIVOT_M, HAIR)


# Criterion 5: movement_center.tres is movement_v0.tres except the aim's side and rise: every
# other number of the movement, the grapple's reach and the aim's height included, is the same.
func test_movement_center_equals_movement_v0_except_the_aim_side_and_the_aim_rise() -> void:
	var center := _movement(MOVEMENT_CENTER)
	if center == null:
		return
	_assert_equal_except(_movement(MOVEMENT_V0), center, MOVEMENT_DIFFERS)


# The centered movement's two numbers: no side and a rise of 0,6 m, which puts the point O 2,2 m
# above the feet with the body's shoulder still at 1,6 m.
func test_movement_center_has_no_aim_side_and_an_aim_rise_of_0_6_m() -> void:
	var center := _movement(MOVEMENT_CENTER)
	if center == null:
		return
	assert_float(center.aim_side_m).is_equal_approx(CENTER_SHOULDER_M, HAIR)
	var rise := _float_of(center, AIM_RISE)
	assert_float(rise).is_equal_approx(CENTER_RISE_M, HAIR)
	assert_float(center.aim_height_m).is_equal_approx(PIVOT_HEIGHT_M, HAIR)
	assert_float(center.aim_height_m + rise).is_equal_approx(CENTER_PIVOT_M, HAIR)


# Criterion 5: the centered movement's copies equal the centered camera's numbers, bit for bit:
# the core's point O is the camera's (DEC-0045 §2).
func test_the_centered_movement_copies_the_centered_cameras_shoulder_and_rise() -> void:
	var camera := _camera(CAMERA_CENTER)
	var movement := _movement(MOVEMENT_CENTER)
	if camera == null or movement == null:
		return
	var side := "aim_side_m is %s, the camera's shoulder_m is %s: they must be equal" % [
		movement.aim_side_m,
		camera.shoulder_m,
	]
	assert_float(movement.aim_side_m).override_failure_message(side).is_equal(camera.shoulder_m)
	var rise := _float_of(camera, RISE)
	var aim_rise := _float_of(movement, AIM_RISE)
	var copied := "aim_rise_m is %s, the camera's rise_m is %s: they must be equal" % [
		aim_rise,
		rise,
	]
	assert_float(aim_rise).override_failure_message(copied).is_equal(rise)
	assert_float(movement.aim_height_m).is_equal(camera.pivot_height_m)


# Criterion 5: both new files pass the data check.
func test_both_centered_files_pass_the_data_check() -> void:
	var camera := _camera(CAMERA_CENTER)
	if camera != null:
		var errors := camera.validate()
		assert_array(errors).override_failure_message("%s: %s" % [CAMERA_CENTER, errors]).is_empty()
	var movement := _movement(MOVEMENT_CENTER)
	if movement != null:
		var errors := movement.validate()
		assert_array(errors).override_failure_message("%s: %s" % [MOVEMENT_CENTER, errors]) \
				.is_empty()


# The data check takes the centered numbers set in code too: a shoulder of 0 with a rise of
# 0,6 m on the camera, and a side of 0 with a rise of 0,6 m on the movement.
func test_the_centered_numbers_set_on_a_copy_of_the_v0_pass_the_data_check() -> void:
	var camera: Resource = _camera(CAMERA_V0).duplicate()
	camera.set(SHOULDER, CENTER_SHOULDER_M)
	camera.set(RISE, CENTER_RISE_M)
	assert_float(_float_of(camera, RISE)).is_equal_approx(CENTER_RISE_M, HAIR)
	assert_bool(camera is CameraData).is_true()
	if camera is CameraData:
		assert_array((camera as CameraData).validate()).is_empty()
	var movement: Resource = _movement(MOVEMENT_V0).duplicate()
	movement.set(AIM_SIDE, CENTER_SHOULDER_M)
	movement.set(AIM_RISE, CENTER_RISE_M)
	assert_float(_float_of(movement, AIM_RISE)).is_equal_approx(CENTER_RISE_M, HAIR)
	assert_bool(movement is MovementData).is_true()
	if movement is MovementData:
		assert_array((movement as MovementData).validate()).is_empty()
