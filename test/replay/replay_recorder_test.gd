# Criterion 1 of TASK-10.3 (F-112 §2; testes-e-entrega.md §4): Sozinho records in user://replays/,
# keeping the newest 20 files it named there and leaving every other file alone; the file is saved
# every second, so an abrupt close loses at most the last second, and what is on the disk still
# plays. These tests record in a temporary folder: the gate never writes in user://replays/, and
# tools/run_tests.sh proves it after every run from the folder the first test names.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const MATCH_SCENE := preload("res://match/match.tscn")
## Ticks recorded before the abrupt close: well over a second, and not a multiple of it.
const TICKS := 150
## The older replays already in the folder: more than the KEEP that stay.
const OLDER := 25

var _folder := ""
var _stage: SubViewport


func before_test() -> void:
	NetfoxTicks.reset()
	_folder = OS.get_temp_dir().path_join("jogo-acrobatico-replay-test-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(_folder)


func after_test() -> void:
	if _stage != null:
		_stage.free()
		_stage = null
	NetfoxTicks.reset()
	for file: String in DirAccess.get_files_at(_folder):
		DirAccess.remove_absolute(_folder.path_join(file))
	DirAccess.remove_absolute(_folder)


# A match in Sozinho with its fighter and a recorder that has not started, in a world of its own.
func _match() -> Match:
	_stage = SubViewport.new()
	_stage.own_world_3d = true
	add_child(_stage)
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	var game_match := node as Match
	_stage.add_child(game_match)
	game_match.spawn_fighter(0, multiplayer.get_unique_id())
	return game_match


func _recorder() -> ReplayRecorder:
	var recorder := ReplayRecorder.new()
	_stage.add_child(recorder)
	return recorder


func _touch(file: String) -> void:
	var handle := FileAccess.open(_folder.path_join(file), FileAccess.WRITE)
	handle.store_string("not a replay of this test\n")
	handle.close()


# tools/run_tests.sh reads the line this test prints to know where user://replays/ is on this
# machine, and fails the run when a file there is newer than the run.
func test_sozinho_records_in_user_replays() -> void:
	assert_str(ReplayRecorder.DEFAULT_DIRECTORY).is_equal("user://replays/")
	var recorder: ReplayRecorder = auto_free(ReplayRecorder.new())
	assert_str(recorder.directory).is_equal(ReplayRecorder.DEFAULT_DIRECTORY)
	assert_int(ReplayRecorder.KEEP).is_equal(20)
	print(
		"replay: user://replays/ is %s"
		% ProjectSettings.globalize_path(ReplayRecorder.DEFAULT_DIRECTORY)
	)


func test_the_folder_keeps_the_newest_20_files_it_named_and_no_other_file_is_touched() -> void:
	for index: int in OLDER:
		_touch("%s20250101-0000%02d.replay" % [ReplayRecorder.FILE_PREFIX, index])
	_touch("notes.txt")
	_touch("someone-else.replay")
	var game_match := _match()
	var recorder := _recorder()
	recorder.directory = _folder
	var error := recorder.start(game_match, game_match.fighters)
	assert_int(error).is_equal(OK)
	recorder.close()
	var named: Array[String] = []
	for file: String in DirAccess.get_files_at(_folder):
		if file.begins_with(ReplayRecorder.FILE_PREFIX):
			named.append(file)
	assert_int(named.size()).is_equal(ReplayRecorder.KEEP)
	# The session's own file is the newest, and the oldest went.
	assert_bool(named.has(recorder.path.get_file())).is_true()
	assert_str(recorder.path.get_file()).starts_with(ReplayRecorder.FILE_PREFIX + "20")
	for index: int in OLDER + 1 - ReplayRecorder.KEEP:
		var oldest := "%s20250101-0000%02d.replay" % [ReplayRecorder.FILE_PREFIX, index]
		assert_bool(named.has(oldest)).override_failure_message("%s stayed" % oldest).is_false()
	assert_bool(FileAccess.file_exists(_folder.path_join("notes.txt"))).is_true()
	assert_bool(FileAccess.file_exists(_folder.path_join("someone-else.replay"))).is_true()


# An abrupt close leaves on the disk what the recorder saved: reading the file while the recorder
# still holds it open sees exactly that. It is at most one second, FLUSH_MS, behind, and it plays.
func test_an_abrupt_close_loses_at_most_the_last_second() -> void:
	var game_match := _match()
	var fighter := game_match.fighters[0]
	var recorder := _recorder()
	var path := _folder.path_join("abrupt.replay")
	assert_int(recorder.start(game_match, game_match.fighters, path)).is_equal(OK)
	assert_str(recorder.path).is_equal(path)
	await get_tree().process_frame
	await get_tree().physics_frame
	for _tick: int in TICKS:
		fighter.input.sample_frame(Vector2(0, 1), 0.25)
		NetfoxTicks.run_loop()
	var second := Ticks.from_ms(ReplayRecorder.FLUSH_MS, NetworkTime.tickrate)
	var on_disk := ReplayFile.parse(FileAccess.get_file_as_string(path))
	assert_array(on_disk.errors).is_empty()
	assert_int(on_disk.tick_count()).is_between(TICKS - second, TICKS)
	recorder.close()
	var saved := ReplayFile.parse(FileAccess.get_file_as_string(path))
	assert_array(saved.errors).is_empty()
	assert_array(saved.warnings).is_empty()
	assert_int(saved.tick_count()).is_equal(TICKS)
	assert_int(recorder.rows_written).is_equal(TICKS)
