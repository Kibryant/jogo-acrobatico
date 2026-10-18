# Criterion 17 of TASK-9 and DEC-0002: the frame rate of a measurement comes from the time each
# frame took, as the assets probe measured it (F-056 §5): the average rate, the 99th percentile of
# the frame time and the "1% low", the rate of that percentile. FrameStats is pure, so the math
# runs here on made-up frame times, without a window.
extends GdUnitTestSuite

const HAIR := 1e-9


func _times(groups: Array[Vector2i]) -> PackedInt64Array:
	var times := PackedInt64Array()
	for group: Vector2i in groups:
		for _frame: int in group.x:
			times.append(group.y)
	return times


func test_no_frame_gives_zeros_and_never_an_infinite_rate() -> void:
	var stats := FrameStats.from_frame_times(PackedInt64Array())
	assert_int(stats.frames).is_equal(0)
	assert_float(stats.measured_s).is_equal(0.0)
	assert_float(stats.average_fps).is_equal(0.0)
	assert_float(stats.average_frame_ms).is_equal(0.0)
	assert_float(stats.p99_frame_ms).is_equal(0.0)
	assert_float(stats.one_percent_low_fps).is_equal(0.0)
	assert_float(stats.worst_frame_ms).is_equal(0.0)
	# Frames that took no time at all have no finite rate either.
	var instant := FrameStats.from_frame_times(PackedInt64Array([0, 0]))
	assert_float(instant.average_fps).is_equal(0.0)
	assert_float(instant.one_percent_low_fps).is_equal(0.0)


# One frame of 16 667 µs is every statistic at once: a frame of a 60 Hz screen.
func test_one_frame_is_its_own_average_percentile_and_worst() -> void:
	var stats := FrameStats.from_frame_times(PackedInt64Array([16667]))
	assert_int(stats.frames).is_equal(1)
	assert_float(stats.measured_s).is_equal_approx(0.016667, HAIR)
	assert_float(stats.average_fps).is_equal_approx(1e6 / 16667.0, HAIR)
	assert_float(stats.average_frame_ms).is_equal_approx(16.667, HAIR)
	assert_float(stats.p99_frame_ms).is_equal_approx(16.667, HAIR)
	assert_float(stats.one_percent_low_fps).is_equal_approx(1e6 / 16667.0, HAIR)
	assert_float(stats.worst_frame_ms).is_equal_approx(16.667, HAIR)


# 60 s of steady 8 ms frames: 125 fps on average and in the 1% low.
func test_many_equal_frames_give_the_same_average_and_1_percent_low() -> void:
	var stats := FrameStats.from_frame_times(_times([Vector2i(7500, 8000)]))
	assert_int(stats.frames).is_equal(7500)
	assert_float(stats.measured_s).is_equal_approx(60.0, HAIR)
	assert_float(stats.average_fps).is_equal_approx(125.0, HAIR)
	assert_float(stats.average_frame_ms).is_equal_approx(8.0, HAIR)
	assert_float(stats.p99_frame_ms).is_equal_approx(8.0, HAIR)
	assert_float(stats.one_percent_low_fps).is_equal_approx(125.0, HAIR)
	assert_float(stats.worst_frame_ms).is_equal_approx(8.0, HAIR)


# 1000 frames: 990 of 4 ms and, in any order, 10 hitches of 40 ms, exactly 1% of them. The average
# hides the hitches; the 1% low shows them.
func test_hitches_in_1_percent_of_frames_pull_the_1_percent_low_below_the_average() -> void:
	var times := _times([Vector2i(500, 4000), Vector2i(10, 40000), Vector2i(490, 4000)])
	var stats := FrameStats.from_frame_times(times)
	assert_int(stats.frames).is_equal(1000)
	# 990 × 4 ms + 10 × 40 ms = 4.36 s.
	assert_float(stats.measured_s).is_equal_approx(4.36, HAIR)
	assert_float(stats.average_frame_ms).is_equal_approx(4.36, HAIR)
	assert_float(stats.average_fps).is_equal_approx(1000.0 / 4.36, HAIR)
	assert_float(stats.p99_frame_ms).is_equal_approx(40.0, HAIR)
	assert_float(stats.one_percent_low_fps).is_equal_approx(25.0, HAIR)
	assert_float(stats.worst_frame_ms).is_equal_approx(40.0, HAIR)
	# The order of the frames does not matter.
	var first := _times([Vector2i(10, 40000), Vector2i(990, 4000)])
	assert_float(FrameStats.from_frame_times(first).one_percent_low_fps).is_equal_approx(25.0, HAIR)


# The probe's rank: the frame at floor(0.99 × n) of the sorted times. With 5 hitches in 1000
# frames, fewer than 1%, the 1% low stays on the steady frames and only the worst frame shows them.
func test_hitches_rarer_than_1_percent_show_only_in_the_worst_frame() -> void:
	var stats := FrameStats.from_frame_times(_times([Vector2i(995, 4000), Vector2i(5, 40000)]))
	assert_float(stats.p99_frame_ms).is_equal_approx(4.0, HAIR)
	assert_float(stats.one_percent_low_fps).is_equal_approx(250.0, HAIR)
	assert_float(stats.worst_frame_ms).is_equal_approx(40.0, HAIR)
	# One hitch in 100 frames is the frame at floor(0.99 × 100), the slowest one.
	var hundred := FrameStats.from_frame_times(_times([Vector2i(99, 4000), Vector2i(1, 40000)]))
	assert_float(hundred.p99_frame_ms).is_equal_approx(40.0, HAIR)
	assert_str(hundred.describe()).contains("1% low 25.00 fps")
