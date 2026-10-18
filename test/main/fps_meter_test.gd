# Criterion 17 of TASK-9 and F-056 §5: once the Main begins it, the meter warms up for 2 s, then
# times every frame for 60 s, and writes what it measured with what it ran on. The frames come
# here at made-up times on the microsecond clock (FpsMeter.frame_at), so no test waits a minute.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const MATCH_SCENE := preload("res://match/match.tscn")

## µs: the clock when the warm-up begins; any time would do.
const BEGIN := 5_000_000
const USEC_PER_SECOND := 1_000_000
## µs: steady frames of 10 ms, 100 fps.
const FRAME := 10_000
const HAIR := 1e-9
## Every field of the report, in the order save() writes them.
const FIELDS: Array[String] = [
	"frames",
	"measured_s",
	"average_fps",
	"average_frame_ms",
	"p99_frame_ms",
	"one_percent_low_fps",
	"worst_frame_ms",
	"two_fighters_in_view_pct",
	"window_size",
	"screen_size",
	"screen_refresh_hz",
	"vsync",
	"gpu",
	"gpu_api",
	"godot",
	"version",
	"commit",
]

var _path := ""


func before_test() -> void:
	_path = "user://fps_meter_test_%d.json" % Time.get_ticks_usec()
	NetfoxTicks.reset()


func after_test() -> void:
	if FileAccess.file_exists(_path):
		DirAccess.remove_absolute(_path)
	NetfoxTicks.reset()


# A meter outside the tree: it times only the frames this test gives it.
func _meter() -> FpsMeter:
	var meter: FpsMeter = auto_free(FpsMeter.new(_path))
	return meter


# A meter in the tree, for what reads the window or the camera; its own clock is off, so it still
# times only the frames this test gives it.
func _meter_in_tree() -> FpsMeter:
	var meter := _meter()
	meter.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(meter)
	return meter


# A number of the report as JSON read it back.
static func _number(report: Dictionary, field: String) -> float:
	var value: Variant = report[field]
	assert(value is float or value is int, "%s is a number in the report" % field)
	var number: float = value
	return number


# Begins the warm-up and gives the first frame at its end, where the measurement starts.
func _warmed_up(meter: FpsMeter) -> int:
	meter.begin_at(BEGIN)
	var measured_from := BEGIN + FpsMeter.WARMUP_S * USEC_PER_SECOND
	meter.frame_at(measured_from)
	return measured_from


# Slow frames during the warm-up are not timed: 60 s of 10 ms frames after it give 100 fps, with
# no trace of the 50 ms frames before.
func test_the_frames_of_the_warm_up_are_not_timed() -> void:
	var meter := _meter()
	meter.begin_at(BEGIN)
	for warm_up_frame: int in range(1, 40):
		meter.frame_at(BEGIN + warm_up_frame * 50_000)
	assert_int(meter.phase).is_equal(FpsMeter.Phase.WARMING_UP)
	var measured_from := BEGIN + FpsMeter.WARMUP_S * USEC_PER_SECOND
	meter.frame_at(measured_from)
	assert_int(meter.phase).is_equal(FpsMeter.Phase.MEASURING)
	for frame: int in range(1, FpsMeter.MEASURE_S * 100 + 1):
		meter.frame_at(measured_from + frame * FRAME)
	assert_int(meter.phase).is_equal(FpsMeter.Phase.DONE)
	assert_int(meter.stats.frames).is_equal(6000)
	assert_float(meter.stats.measured_s).is_equal_approx(60.0, HAIR)
	assert_float(meter.stats.average_fps).is_equal_approx(100.0, HAIR)
	assert_float(meter.stats.worst_frame_ms).is_equal_approx(10.0, HAIR)


# The measurement ends with the first frame at or after 60 s, once: frames of 7 ms reach 60 s on
# the 8572nd, at 60.004 s, and the frames after it change nothing.
func test_the_measurement_ends_once_with_the_first_frame_at_or_after_60_s() -> void:
	var meter := _meter()
	var ends: Array[bool] = []
	meter.finished.connect(
		func() -> void:
			ends.append(true),
	)
	var measured_from := _warmed_up(meter)
	for frame: int in range(1, 8572):
		meter.frame_at(measured_from + frame * 7000)
	assert_int(meter.phase).is_equal(FpsMeter.Phase.MEASURING)
	assert_array(ends).is_empty()
	meter.frame_at(measured_from + 8572 * 7000)
	assert_array(ends).is_equal([true])
	for frame: int in range(8573, 8600):
		meter.frame_at(measured_from + frame * 7000)
	assert_array(ends).is_equal([true])
	assert_int(meter.stats.frames).is_equal(8572)
	assert_float(meter.stats.measured_s).is_equal_approx(60.004, HAIR)


# The JSON names the measurement, the window, the screen, the vsync, the GPU, the engine and the
# build; the rates are rounded down, so a rounded rate never passes a floor the measured one
# missed: 59.995 fps is written 59.99, not 60.0.
func test_the_report_names_the_measurement_the_screen_the_gpu_the_engine_and_the_build() -> void:
	var meter := _meter_in_tree()
	var measured_from := _warmed_up(meter)
	# Frames of 16 668 µs, 59.995 fps: the 3600th reaches 60 s, at 60.0048 s.
	for frame: int in range(1, 3601):
		meter.frame_at(measured_from + frame * 16_668)
	assert_int(meter.phase).is_equal(FpsMeter.Phase.DONE)
	assert_int(meter.save()).is_equal(OK)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_path))
	assert_bool(parsed is Dictionary).is_true()
	var report: Dictionary = parsed
	assert_array(report.keys()).contains_exactly(FIELDS)
	assert_float(_number(report, "frames")).is_equal(3600.0)
	assert_float(_number(report, "measured_s")).is_equal_approx(60.005, HAIR)
	assert_float(_number(report, "average_fps")).is_equal_approx(59.99, HAIR)
	assert_float(_number(report, "p99_frame_ms")).is_equal_approx(16.668, HAIR)
	assert_float(_number(report, "one_percent_low_fps")).is_equal_approx(59.99, HAIR)
	assert_float(_number(report, "two_fighters_in_view_pct")).is_equal(0.0)
	var build := BuildStamp.current()
	assert_str(str(report["version"])).is_equal(build.version)
	assert_str(str(report["commit"])).is_equal(build.commit)
	assert_str(str(report["godot"])).is_equal(str(Engine.get_version_info()["string"]))


# Criterion 17 asks for both fighters on the screen: the meter counts the measured frames in which
# the centres of two fighters' bodies are inside the view of the camera that draws the screen.
func test_the_meter_counts_the_frames_with_both_fighters_in_the_camera_view() -> void:
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	var game_match: Match = auto_free(node)
	add_child(game_match)
	var far := game_match.spawn_fighter(0, multiplayer.get_unique_id())
	# The camera follows the fighter of SpawnB, which looks at SpawnA's, 10 m ahead.
	game_match.watch(game_match.spawn_fighter(1, multiplayer.get_unique_id()))
	# The spring arm puts the camera behind its fighter in a physics frame.
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var meter := _meter_in_tree()
	meter.watched_match = game_match
	var measured_from := _warmed_up(meter)
	for frame: int in range(1, 4):
		meter.frame_at(measured_from + frame * FRAME)
	# 40 m to the side, the far fighter leaves the view.
	far.position.x += 40.0
	meter.frame_at(measured_from + 4 * FRAME)
	assert_float(meter.fighters_in_view_pct()).is_equal_approx(75.0, HAIR)
