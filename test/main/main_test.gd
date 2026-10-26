# Criterion 6 of TASK-9 and DEC-0026 §6: the Main reads how the game was opened. With no argument
# it plays Sozinho: netfox's clock starts on Godot's offline peer, then a match with this PC's
# fighter and its camera. An argument it does not know is refused (.claude/harness/registro.md,
# 2026-10-07). Ending the session stops the clock before the match goes, the clean exit the probe
# lacked (F-026 §4). The server and client modes need two processes; tools/net_check.sh runs them
# (TASK-9, part 2). Sozinho puts a still dummy at the second spawn point, in the other fighter's
# tone, with no camera, unless --dummy=off, and its replay records both (TASK-10.7, criterion 5).
# Sozinho records a replay of every session in user://replays/ (TASK-10.3; F-112 §2), and the gate
# never writes there: these tests open the Main with --no-replay, or with --replay-dir in a
# temporary folder, and tools/run_tests.sh checks the folder after the run.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const MAIN_SCENE := preload("res://main/main.tscn")
const ReplayRun := preload("res://tools/replay_run.gd")
const SPAWN_A := Vector3(-6, 0, 9) # arena.tscn: SpawnA
const SPAWN_B := Vector3(-6, 0, -1) # arena.tscn: SpawnB
const HAIR := 1e-4
## s of wall clock Sozinho plays before the session ends: netfox's real clock runs ticks in it.
const PLAY_S := 0.3

var _folder := ""
# The options file of the Main in these tests: a temporary one, never user://options.cfg
# (TASK-10.9), which tools/run_tests.sh checks after the run.
var _options_path := ""


func before_test() -> void:
	NetfoxTicks.reset()
	_options_path = OS.get_temp_dir().path_join(
		"jogo-acrobatico-main-options-%d.cfg" % Time.get_ticks_usec(),
	)


func after_test() -> void:
	NetfoxTicks.reset()
	get_tree().auto_accept_quit = true
	if FileAccess.file_exists(_options_path):
		DirAccess.remove_absolute(_options_path)
	InputMap.load_from_project_settings()
	get_tree().root.content_scale_factor = 1.0
	if not _folder.is_empty():
		for file: String in DirAccess.get_files_at(_folder):
			DirAccess.remove_absolute(_folder.path_join(file))
		DirAccess.remove_absolute(_folder)
		_folder = ""


# The Main as the game opens it, with these arguments after "--".
func _main(arguments: Array[String]) -> Main:
	var node: Node = auto_free(MAIN_SCENE.instantiate())
	assert(node is Main, "main.tscn must have a Main at its root")
	var main := node as Main
	main.arguments = PackedStringArray(arguments)
	main.options_path = _options_path
	add_child(main)
	return main


func test_no_argument_means_sozinho() -> void:
	var options := LaunchOptions.parse(PackedStringArray(), false, true)
	assert_array(options.errors).is_empty()
	assert_int(options.mode).is_equal(LaunchOptions.Mode.SOLO)


# Part 2 of TASK-9 knows --server, --port, --connect, --stop-file, --bot and --record; a typo of
# each is refused (test/main/launch_options_test.gd covers every form).
func test_every_argument_this_build_does_not_know_is_refused() -> void:
	var arguments := PackedStringArray(["--servr", "--prot=7777", "--conect=127.0.0.1:7777"])
	var options := LaunchOptions.parse(arguments, false, false)
	assert_int(options.errors.size()).is_equal(arguments.size())
	for argument: String in arguments:
		assert_bool(options.errors.has("Unknown argument: %s" % argument)).is_true()


func test_an_unknown_argument_exits_with_a_code_other_than_zero() -> void:
	assert_int(Main.EXIT_USAGE).is_not_equal(0)


# The Main opens as the game does with no argument but --no-replay, which only keeps the gate out
# of user://replays/.
func test_with_no_argument_the_main_plays_sozinho() -> void:
	var main := _main(["--no-replay"])
	await get_tree().process_frame
	assert_bool(multiplayer.multiplayer_peer is OfflineMultiplayerPeer).is_true()
	assert_bool(NetworkTime.is_initial_sync_done()).is_true()
	assert_object(main.current_match).is_not_null()
	assert_int(main.current_match.fighters.size()).is_equal(2)
	var fighter := main.current_match.fighter_at(Match.PLAYER_SLOT)
	assert_vector(fighter.position).is_equal_approx(SPAWN_A, Vector3.ONE * HAIR)
	assert_object(main.current_match.camera_rig).is_not_null()
	assert_str(str(fighter.tone)).is_equal(str(Fighter.OWN_TONE))
	# Closing the window must come to the Main first (DEC-0026 §6).
	assert_bool(get_tree().auto_accept_quit).is_false()


# TASK-10.7, criterion 5: the dummy stands at the second spawn point, driven by this PC, in the
# other fighter's tone, with no camera and no bot, and stays still while the clock runs.
func test_sozinho_has_a_still_dummy_at_the_second_spawn_point() -> void:
	var main := _main(["--no-replay"])
	await get_tree().process_frame
	var dummy := main.current_match.fighter_at(Match.DUMMY_SLOT)
	assert_object(dummy).is_not_null()
	assert_vector(dummy.position).is_equal_approx(SPAWN_B, Vector3.ONE * HAIR)
	assert_int(dummy.input.get_multiplayer_authority()).is_equal(multiplayer.get_unique_id())
	assert_str(str(dummy.tone)).is_equal(str(Fighter.OTHER_TONE))
	assert_object(main.current_match.bot).is_null()
	# One camera in the match, the player's.
	var cameras := 0
	for child: Node in main.current_match.get_children():
		if child is CameraRig:
			cameras += 1
	assert_int(cameras).is_equal(1)
	await get_tree().create_timer(PLAY_S).timeout
	assert_int(NetworkTime.tick).is_greater(0)
	assert_vector(dummy.position).is_equal_approx(SPAWN_B, Vector3.ONE * HAIR)
	assert_int(dummy.state.mode).is_equal(FighterState.Mode.GROUND)


func test_dummy_off_plays_sozinho_alone() -> void:
	var main := _main(["--no-replay", "--dummy=off"])
	await get_tree().process_frame
	assert_int(main.current_match.fighters.size()).is_equal(1)
	assert_object(main.current_match.fighter_at(Match.DUMMY_SLOT)).is_null()


func test_ending_the_session_stops_the_clock_and_frees_the_match() -> void:
	var main := _main(["--no-replay"])
	await get_tree().process_frame
	var game_match := main.current_match
	main.end_session()
	assert_bool(NetworkTime.is_initial_sync_done()).is_false()
	assert_object(main.current_match).is_null()
	await get_tree().process_frame
	assert_bool(is_instance_valid(game_match)).is_false()


# TASK-10.3, criterion 1: Sozinho records the session from its fighter's first tick, on netfox's
# real clock, in the folder --replay-dir names, and ending the session saves the file, a replay
# the player can read; the log names it with the whole path.
func test_sozinho_records_its_session_in_the_replay_folder() -> void:
	_folder = OS.get_temp_dir().path_join("jogo-acrobatico-main-test-%d" % Time.get_ticks_usec())
	var main := _main(["--replay-dir=%s" % _folder])
	await get_tree().process_frame
	var fighter := main.current_match.fighters[0]
	var first_tick: int = fighter.synchronizer.spawn_tick
	await get_tree().create_timer(PLAY_S).timeout
	main.end_session()
	var files := DirAccess.get_files_at(_folder)
	assert_int(files.size()).is_equal(1)
	assert_str(files[0]).starts_with(ReplayRecorder.FILE_PREFIX).ends_with(".replay")
	var replay := ReplayFile.open(_folder.path_join(files[0]))
	assert_array(replay.errors).is_empty()
	assert_array(replay.warnings).is_empty()
	assert_int(replay.first_tick()).is_equal(first_tick)
	# The player's fighter and the dummy (TASK-10.7, criterion 5).
	assert_int(replay.fighter_count()).is_equal(2)
	# netfox's real clock ran ticks in PLAY_S, and every one of them is in the file.
	assert_int(replay.tick_count()).is_greater(0)
	var last := replay.rows[replay.rows.size() - 1]
	assert_int(last.tick - first_tick + 1).is_equal(replay.tick_count())


# The opened game's Main is ready before Godot's first frame, and that frame's physics step runs
# netfox's tick (DEC-0040) before Godot flushes the deferred calls where netfox registers a fighter
# (rollback-synchronizer.gd). Entering the tree right before a physics step's tick loop is the same
# order: Sozinho must still simulate its fighter from netfox's first tick and record that tick
# first, so the header tells the truth and the player replays the file as the live game played it
# (sozinho-20261023-091228.replay began on tick 2 under first_tick=0).
func test_sozinho_opened_before_a_physics_step_records_from_its_first_tick() -> void:
	_folder = OS.get_temp_dir().path_join("jogo-acrobatico-main-test-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(_folder)
	var path := _folder.path_join("opened.replay")
	await get_tree().physics_frame
	var main := _main(["--replay=%s" % path])
	await get_tree().create_timer(PLAY_S).timeout
	main.end_session()
	var replay := ReplayFile.open(path)
	assert_array(replay.errors).is_empty()
	replay.judge(ReplayFile.this_build())
	assert_bool(replay.playable(false)).override_failure_message("%s" % replay.errors).is_true()
	assert_int(replay.first_tick()).is_equal(0)
	assert_int(replay.tick_count()).is_greater(0)
	if not replay.playable(false) or replay.rows.is_empty():
		return
	assert_int(replay.rows[0].tick).is_equal(replay.first_tick())
	var played := await ReplayRun.new().play(self, replay, replay.movement_data())
	assert_int(played.ticks).is_equal(replay.tick_count())
	assert_bool(played.checked).is_true()
	assert_int(played.first_apart).is_equal(-1)


# TASK-10.9, criteria 1 to 3: before the match, the Main reads the player's options file and puts
# its keys in the InputMap and its scale on the window; the match's camera turns at its
# sensitivity, and the match keeps the same options for its screen.
func test_the_main_applies_the_options_file_before_the_match() -> void:
	var file := ConfigFile.new()
	file.set_value("keys", "dash", "mouse:%d" % MOUSE_BUTTON_XBUTTON2)
	file.set_value("keys", "grapple", "key:%d" % KEY_E)
	file.set_value("mouse", "sensitivity", 0.1)
	file.set_value("interface", "scale", 1.2)
	assert_int(file.save(_options_path)).is_equal(OK)
	var written := FileAccess.get_file_as_string(_options_path)
	var main := _main(["--no-replay"])
	await get_tree().process_frame
	assert_object(main.player_options).is_not_null()
	assert_array(main.player_options.warnings).is_empty()
	assert_object(main.current_match.options).is_same(main.player_options)
	var dash := InputMap.action_get_events(&"dash")
	assert_int(dash.size()).is_equal(1)
	assert_bool(dash[0] is InputEventMouseButton).is_true()
	var side := dash[0] as InputEventMouseButton
	assert_int(side.button_index).is_equal(MOUSE_BUTTON_XBUTTON2)
	var grapple := InputMap.action_get_events(&"grapple")
	assert_bool(grapple[0] is InputEventKey).is_true()
	var key := grapple[0] as InputEventKey
	assert_int(key.physical_keycode).is_equal(KEY_E)
	assert_float(get_tree().root.content_scale_factor).is_equal_approx(1.2, 1e-6)
	assert_float(main.current_match.camera_rig.sensitivity_deg_per_px).is_equal_approx(0.1, 1e-6)
	# Reading the file wrote nothing into it.
	assert_str(FileAccess.get_file_as_string(_options_path)).is_equal(written)
