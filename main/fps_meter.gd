# Measures this game's frame rate in its window (TASK-9, criterion 17; --measure-fps=PATH) the way
# the assets probe did (F-056 §5): from begin_at(), it warms up for 2 s, then times every frame for
# 60 s with the microsecond clock, and save() writes PATH as JSON: the statistics of FrameStats,
# the window and the screen, the vsync, the GPU, the engine and the build. It also counts the
# frames in which two fighters' bodies were inside the camera's view, the condition of criterion
# 17. It only reads: the Main sets the screen up for the measurement and ends the session.
class_name FpsMeter
extends Node

## The measurement is over: stats holds it, and save() writes it.
signal finished

enum Phase {
	## Waiting for begin_at().
	IDLE,
	WARMING_UP,
	MEASURING,
	DONE,
}

## s: the warm-up before the measurement, the probe's (F-056 §5; ../assets-sonda/main.gd,
## WARMUP_S): the first frames of a scene are slower than the rest.
const WARMUP_S := 2
## s: TASK-9, criterion 17: "por 60 s".
const MEASURE_S := 60
const USEC_PER_SECOND := 1000000
## The fighters criterion 17 asks for on the screen: "com os dois lutadores na tela".
const FIGHTERS_TO_SEE := 2

## Where save() writes.
var path: String
var phase := Phase.IDLE
## The match whose fighters the meter looks for in the camera's view; null for none.
var watched_match: Match
## The statistics of the measured frames; null until the measurement is over.
var stats: FrameStats

# µs, on the clock of begin_at() and frame_at(): when the current phase ends, and when the last
# measured frame came.
var _phase_ends_usec := 0
var _last_frame_usec := 0
var _frame_times := PackedInt64Array()
# The measured frames in which FIGHTERS_TO_SEE fighters were in the camera's view.
var _frames_with_fighters_in_view := 0


func _init(file_path: String) -> void:
	name = "FpsMeter"
	path = file_path


func _process(_delta: float) -> void:
	if phase == Phase.WARMING_UP or phase == Phase.MEASURING:
		frame_at(Time.get_ticks_usec())


# The warm-up begins at now_usec, on the microsecond clock (Time.get_ticks_usec in the game).
func begin_at(now_usec: int) -> void:
	assert(phase == Phase.IDLE, "a meter measures once")
	phase = Phase.WARMING_UP
	_phase_ends_usec = now_usec + WARMUP_S * USEC_PER_SECOND


# A frame came at now_usec. The first frame at or after the end of the warm-up starts the
# measurement; each later one adds the time since the one before, and the first one at or after
# MEASURE_S more ends it and emits finished, once.
func frame_at(now_usec: int) -> void:
	match phase:
		Phase.WARMING_UP:
			if now_usec >= _phase_ends_usec:
				phase = Phase.MEASURING
				_last_frame_usec = now_usec
				_phase_ends_usec = now_usec + MEASURE_S * USEC_PER_SECOND
		Phase.MEASURING:
			_frame_times.append(now_usec - _last_frame_usec)
			_last_frame_usec = now_usec
			if _fighters_in_view() >= FIGHTERS_TO_SEE:
				_frames_with_fighters_in_view += 1
			if now_usec >= _phase_ends_usec:
				phase = Phase.DONE
				stats = FrameStats.from_frame_times(_frame_times)
				finished.emit()


# The share of the measured frames, in %, in which FIGHTERS_TO_SEE fighters were in the camera's
# view; 0 before any frame is measured.
func fighters_in_view_pct() -> float:
	if _frame_times.is_empty():
		return 0.0
	return 100.0 * _frames_with_fighters_in_view / _frame_times.size()


# The measurement and what it ran on, as save() writes it. The rates are rounded down to the
# hundredth, so a rounded rate never reaches a floor that the measured one missed (DEC-0002: 60
# fps); the frame times are in ms, to the µs the clock counts.
func report() -> Dictionary[String, Variant]:
	var measured := stats
	if measured == null:
		measured = FrameStats.from_frame_times(PackedInt64Array())
	var window := get_window()
	var screen := window.current_screen
	var build := BuildStamp.current()
	return {
		"frames": measured.frames,
		"measured_s": snappedf(measured.measured_s, 0.001),
		"average_fps": _hundredth_below(measured.average_fps),
		"average_frame_ms": snappedf(measured.average_frame_ms, 0.001),
		"p99_frame_ms": snappedf(measured.p99_frame_ms, 0.001),
		"one_percent_low_fps": _hundredth_below(measured.one_percent_low_fps),
		"worst_frame_ms": snappedf(measured.worst_frame_ms, 0.001),
		"two_fighters_in_view_pct": snappedf(fighters_in_view_pct(), 0.1),
		"window_size": _size_text(window.size),
		"screen_size": _size_text(DisplayServer.screen_get_size(screen)),
		"screen_refresh_hz": snappedf(DisplayServer.screen_get_refresh_rate(screen), 0.01),
		"vsync": _vsync_name(DisplayServer.window_get_vsync_mode(window.get_window_id())),
		"gpu": RenderingServer.get_video_adapter_name(),
		"gpu_api": RenderingServer.get_video_adapter_api_version(),
		"godot": str(Engine.get_version_info()["string"]),
		"version": build.version,
		"commit": build.commit,
	}


# Writes the report to path as JSON, one field per line; the error when the file cannot be written.
func save() -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(report(), "\t", false) + "\n")
	file.close()
	return OK


# How many of the watched match's fighters have the centre of their body inside the view of the
# camera that draws the screen.
func _fighters_in_view() -> int:
	if watched_match == null or not is_instance_valid(watched_match) or not is_inside_tree():
		return 0
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return 0
	var seen := 0
	for fighter: Fighter in watched_match.fighters:
		if camera.is_position_in_frustum(fighter.body_mesh.global_position):
			seen += 1
	return seen


static func _hundredth_below(rate: float) -> float:
	return floorf(rate * 100.0) / 100.0


static func _size_text(size: Vector2i) -> String:
	return "%dx%d" % [size.x, size.y]


static func _vsync_name(mode: DisplayServer.VSyncMode) -> String:
	match mode:
		DisplayServer.VSYNC_DISABLED:
			return "disabled"
		DisplayServer.VSYNC_ENABLED:
			return "enabled"
		DisplayServer.VSYNC_ADAPTIVE:
			return "adaptive"
		DisplayServer.VSYNC_MAILBOX:
			return "mailbox"
	return "unknown"
