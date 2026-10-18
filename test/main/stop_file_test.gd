# Criterion 11 of TASK-9 and DEC-0032 §2: the server's stop file (choice 2). The watcher looks for
# the file once per second, says once that it appeared and leaves it where it is.
extends GdUnitTestSuite

## ms: the check runs once per second; a frame of slack on top.
const SEEN_WITHIN_MS := 1500

var _path := ""


func before_test() -> void:
	_path = "user://stop_file_test_%d" % Time.get_ticks_usec()


func after_test() -> void:
	if FileAccess.file_exists(_path):
		DirAccess.remove_absolute(_path)


func _watcher() -> StopFile:
	var watcher: StopFile = auto_free(StopFile.new(_path))
	add_child(watcher)
	return watcher


func _make_the_file_appear() -> void:
	var file := FileAccess.open(_path, FileAccess.WRITE)
	assert(file != null, "the test writes %s" % _path)
	file.close()


func test_the_file_appearing_is_said_once_and_the_file_stays() -> void:
	var watcher := _watcher()
	var seen: Array[bool] = []
	watcher.appeared.connect(
		func() -> void:
			seen.append(true),
	)
	assert_bool(watcher.check()).is_false()
	assert_array(seen).is_empty()
	_make_the_file_appear()
	assert_bool(watcher.check()).is_true()
	assert_bool(watcher.check()).is_true()
	assert_array(seen).is_equal([true])
	assert_bool(FileAccess.file_exists(_path)).is_true()


# The watcher checks on its own, once per second: a file that appears is seen within a second.
func test_the_watcher_sees_the_file_within_a_second() -> void:
	var watcher := _watcher()
	monitor_signals(watcher, false)
	_make_the_file_appear()
	await assert_signal(watcher).wait_until(SEEN_WITHIN_MS).is_emitted("appeared")
