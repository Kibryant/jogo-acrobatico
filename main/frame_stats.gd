# The frame rate of a measurement, from the time each frame took (TASK-9, criterion 17): the
# average, the 99th percentile of the frame time and the "1% low", the rate of that percentile, as
# the assets probe measured them (F-056 §5; ../assets-sonda/main.gd, _stats). Pure: a function of
# the frame times, so a test covers the math without a window.
class_name FrameStats
extends RefCounted

const USEC_PER_SECOND := 1000000.0
const USEC_PER_MS := 1000.0
## The percentile of the frame time whose rate is the "1% low".
const PERCENTILE := 99
const SUMMARY := (
	"%.2f fps on average, 1%% low %.2f fps (99th percentile %.3f ms), worst frame %.3f ms, %d"
	+ " frames in %.3f s"
)

## How many frames were timed.
var frames := 0
## s: the time the frames took together.
var measured_s := 0.0
var average_fps := 0.0
## ms: the average frame time, the inverse of the average rate.
var average_frame_ms := 0.0
## ms: the 99th percentile of the frame time: the slowest 1% of the frames took this long or more.
var p99_frame_ms := 0.0
## The rate of the 99th percentile, 1000 / p99_frame_ms: the "1% low".
var one_percent_low_fps := 0.0
## ms: the slowest frame.
var worst_frame_ms := 0.0


# The statistics of these frame times, in microseconds, in any order. With no frame, every number
# is 0. A rate over no time is 0 too, never infinite: JSON has no infinity.
static func from_frame_times(frame_times_usec: PackedInt64Array) -> FrameStats:
	var stats := FrameStats.new()
	stats.frames = frame_times_usec.size()
	if stats.frames == 0:
		return stats
	var sorted := frame_times_usec.duplicate()
	sorted.sort()
	var total_usec := 0
	for frame_usec: int in sorted:
		total_usec += frame_usec
	# The probe's rank (F-056 §5): the frame at floor(0.99 × n) of the sorted times, so the numbers
	# compare with the probe's. With 1000 frames, that is the slowest of the fastest 991, and with
	# 100, the slowest frame.
	@warning_ignore("integer_division")
	var p99_usec := sorted[mini(stats.frames - 1, stats.frames * PERCENTILE / 100)]
	stats.measured_s = total_usec / USEC_PER_SECOND
	stats.average_frame_ms = total_usec / USEC_PER_MS / stats.frames
	stats.average_fps = _rate(total_usec / float(stats.frames))
	stats.p99_frame_ms = p99_usec / USEC_PER_MS
	stats.one_percent_low_fps = _rate(p99_usec)
	stats.worst_frame_ms = sorted[stats.frames - 1] / USEC_PER_MS
	return stats


# One line for a log: the rates, the frame times and how much was measured.
func describe() -> String:
	return SUMMARY % [
		average_fps,
		one_percent_low_fps,
		p99_frame_ms,
		worst_frame_ms,
		frames,
		measured_s,
	]


# Frames per second when a frame takes frame_usec microseconds; 0 for a frame of no time.
static func _rate(frame_usec: float) -> float:
	if frame_usec <= 0.0:
		return 0.0
	return USEC_PER_SECOND / frame_usec
