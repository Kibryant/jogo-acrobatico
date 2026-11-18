# Criterion 5 of TASK-12.15, the window's half (F-219 §1: "O --watch monta a câmera com o ombro e a
# subida do cabeçalho"): --watch makes its camera from camera_v0.tres with the aim of the replay's
# header, the shoulder from aim_side_m, the rise from aim_rise_m and the pivot from aim_height_m,
# so the camera's optical axis passes through the point O the replay plays from: a centered session
# is watched with camera_center.tres's numbers, a session over the shoulder with camera_v0.tres's,
# and a file recorded before the rise, played with --force, with no rise. The camera is a copy:
# the loaded camera_v0.tres, which every match shares, is never written. These files are written
# here, without a match.
extends GdUnitTestSuite

const CAMERA_V0 := "res://data/camera_v0.tres"
const CAMERA_CENTER := "res://data/camera_center.tres"
## netfox's tick of the files' first rows: not 0, as in a long session.
const FIRST_TICK := 500
const AIM_RISE := "aim_rise_m"
const AIM_SIDE := "aim_side_m"
# movimento.md, "Câmera": "Ombro", 0,8 m, and "Subida", 0,6 m, in the centered camera.
const SHOULDER_M := 0.8
const CENTER_RISE_M := 0.6


# A file of this build with one fighter and a few rows from FIRST_TICK, as text.
static func _text() -> String:
	var replay := ReplayFile.this_build()
	replay.header["first_tick"] = str(FIRST_TICK)
	for step: int in 4:
		var row := ReplayFile.Row.new()
		row.tick = FIRST_TICK + step
		row.loop = 1
		row.input.yaw = 0.1 * step
		row.check = "0123abcd"
		replay.rows.append(row)
	return replay.to_text()


static func _judged(text: String) -> ReplayFile:
	var replay := ReplayFile.parse(text)
	replay.judge(ReplayFile.this_build())
	return replay


static func _key(field: String) -> String:
	return "%s%s:%s" % [ReplayFile.CONFIG_PREFIX, field, ReplayFile.F64]


# text with the value of the header field key replaced.
static func _with_header(text: String, key: String, value: String) -> String:
	var lines := text.split("\n")
	for index: int in lines.size():
		if lines[index].begins_with(key + "="):
			lines[index] = "%s=%s" % [key, value]
	return "\n".join(lines)


# The text of a file recorded with the centered camera: the side 0 and the rise 0,6 m.
static func _centered_text() -> String:
	var text := _with_header(_text(), _key(AIM_RISE), ReplayFile.f64_cell(CENTER_RISE_M))
	return _with_header(text, _key(AIM_SIDE), ReplayFile.f64_cell(0.0))


func _camera(path: String) -> CameraData:
	var resource: Resource = load(path)
	assert(resource is CameraData, "%s must load as a CameraData" % path)
	return resource as CameraData


# Every stored number of found equals expected's, by reflection, so a number added later is
# covered.
func _assert_same_numbers(found: CameraData, expected: CameraData, why: String) -> void:
	var differences: Array[String] = []
	var compared := 0
	for property: Dictionary in expected.get_property_list():
		var usage: int = property["usage"]
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE == 0 or usage & PROPERTY_USAGE_STORAGE == 0:
			continue
		var field: String = property["name"]
		compared += 1
		if found.get(field) != expected.get(field):
			differences.append(
				"%s is %s, expected %s" % [field, found.get(field), expected.get(field)]
			)
	assert_int(compared).override_failure_message("the reflection found nothing").is_greater(6)
	var message := "%s:\n%s" % [why, "\n".join(differences)]
	assert_array(differences).override_failure_message(message).is_empty()


# A session over the right shoulder is watched with camera_v0.tres's numbers, every one of them.
func test_a_session_over_the_shoulder_is_watched_with_camera_v0s_numbers() -> void:
	var replay := _judged(_text())
	assert_bool(replay.playable(false)).is_true()
	var camera := replay.camera_data()
	assert_float(camera.shoulder_m).is_equal_approx(SHOULDER_M, 1e-9)
	assert_float(camera.rise_m).is_equal(0.0)
	_assert_same_numbers(camera, _camera(CAMERA_V0), "the camera of a session over the shoulder")


# Criterion 5: a session recorded with the centered camera is watched centered: no shoulder and the
# rise of 0,6 m, the header's, and every other number camera_v0.tres's, which makes it
# camera_center.tres's numbers, one by one.
func test_a_centered_session_is_watched_with_the_centered_cameras_numbers() -> void:
	var replay := _judged(_centered_text())
	assert_array(replay.refusals).is_empty()
	assert_bool(replay.playable(false)).is_true()
	var camera := replay.camera_data()
	assert_float(camera.shoulder_m).is_equal(0.0)
	assert_float(camera.rise_m).is_equal(CENTER_RISE_M)
	assert_float(camera.pivot_height_m + camera.rise_m).is_equal_approx(2.2, 1e-9)
	_assert_same_numbers(camera, _camera(CAMERA_CENTER), "the camera of a centered session")


# The camera is a new copy each time, and making it never writes the loaded camera_v0.tres.
func test_the_watch_camera_is_a_copy_and_camera_v0_stays_as_it_was() -> void:
	var v0 := _camera(CAMERA_V0)
	var replay := _judged(_centered_text())
	var camera := replay.camera_data()
	assert_object(camera).is_not_same(v0)
	assert_object(replay.camera_data()).is_not_same(camera)
	assert_float(v0.shoulder_m).is_equal_approx(SHOULDER_M, 1e-9)
	assert_float(v0.rise_m).is_equal(0.0)
	assert_float(_camera(CAMERA_V0).shoulder_m).is_equal_approx(SHOULDER_M, 1e-9)


# A file recorded before the rise has no line for it and plays only with --force; its camera is
# the one over the shoulder, with no rise, as it was recorded.
func test_a_file_without_the_rise_is_watched_over_the_shoulder_with_no_rise() -> void:
	var kept := PackedStringArray()
	for line: String in _text().split("\n"):
		if not line.begins_with("%s%s:" % [ReplayFile.CONFIG_PREFIX, AIM_RISE]):
			kept.append(line)
	var old := _judged("\n".join(kept))
	assert_bool(old.playable(false)).is_false()
	assert_bool(old.playable(true)).is_true()
	var camera := old.camera_data()
	assert_float(camera.shoulder_m).is_equal_approx(SHOULDER_M, 1e-9)
	assert_float(camera.rise_m).is_equal(0.0)
