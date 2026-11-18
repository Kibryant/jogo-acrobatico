# Criterion 6 of TASK-9 and DEC-0026 §6: the Main reads how the game was opened. With no argument
# it plays Sozinho: netfox's clock starts on Godot's offline peer, then a match with this PC's
# fighter and its camera. An argument it does not know is refused (.claude/harness/registro.md,
# 2026-10-07). Ending the session stops the clock before the match goes, the clean exit the probe
# lacked (F-026 §4). The server and client modes need two processes; tools/net_check.sh runs them
# (TASK-9, part 2). Sozinho puts a dummy at the second spawn point, in the other fighter's tone,
# with no camera, unless --dummy=off, and its replay records both (TASK-10.7, criterion 5); since
# TASK-12.2 the dummy swings a light at the player every 3 s without walking (partida.md, "O boneco
# que ataca").
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
# movimento.md, "Câmera": "Altura do pivô", "Ombro" and "Subida" (0,6 m in the centered camera).
const AIM_HEIGHT_M := 1.6
const SHOULDER_M := 0.8
const CENTER_RISE_M := 0.6

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
# other fighter's tone, with no camera and no bot, and does not walk while the clock runs; TASK-12.2
# gives it the node that attacks every 3 s, turned toward the player (TASK-12.3 mixes the moves).
func test_sozinho_has_a_dummy_that_does_not_walk_at_the_second_spawn_point() -> void:
	var main := _main(["--no-replay"])
	await get_tree().process_frame
	var dummy := main.current_match.fighter_at(Match.DUMMY_SLOT)
	assert_object(dummy).is_not_null()
	assert_vector(dummy.position).is_equal_approx(SPAWN_B, Vector3.ONE * HAIR)
	assert_int(dummy.input.get_multiplayer_authority()).is_equal(multiplayer.get_unique_id())
	assert_str(str(dummy.tone)).is_equal(str(Fighter.OTHER_TONE))
	assert_object(main.current_match.bot).is_null()
	var attacking := main.current_match.attacking_dummy
	assert_object(attacking).override_failure_message("the dummy does not attack").is_not_null()
	assert_object(attacking.dummy).is_same(dummy)
	assert_object(attacking.target).is_same(main.current_match.fighter_at(Match.PLAYER_SLOT))
	assert_bool(attacking.only_guard_breaks).override_failure_message("no mix").is_false()
	assert_bool(attacking.holds_guard).override_failure_message("it blocks").is_false()
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


# TASK-12.4 (partida.md, "A mistura do boneco"; F-212): --dummy=guard_break puts the same dummy at
# the second spawn point, which throws only guard breaks to train the tech; the usage and Sozinho's
# log line name the guard breaks in the mix and the training mode.
func test_dummy_guard_break_gives_sozinho_a_dummy_that_throws_only_guard_breaks() -> void:
	var main := _main(["--no-replay", "--dummy=guard_break"])
	await get_tree().process_frame
	var dummy := main.current_match.fighter_at(Match.DUMMY_SLOT)
	assert_object(dummy).is_not_null()
	assert_vector(dummy.position).is_equal_approx(SPAWN_B, Vector3.ONE * HAIR)
	var attacking := main.current_match.attacking_dummy
	assert_object(attacking).override_failure_message("the dummy does not attack").is_not_null()
	assert_object(attacking.dummy).is_same(dummy)
	assert_bool(attacking.only_guard_breaks).is_true()
	assert_str(Main.USAGE).contains("--dummy=guard_break")
	assert_str(Main.USAGE).contains("guard")
	var mix := Main.solo_dummy_line(false)
	assert_str(mix).contains("guard breaks")
	assert_str(mix).contains("--dummy=guard_break")
	assert_str(Main.solo_dummy_line(true)).contains("only guard breaks")
	assert_bool(attacking.holds_guard).is_false()


# TASK-12.4 (partida.md, "A mistura do boneco"; F-213): --dummy=block puts the same dummy at the
# second spawn point, holding its guard and never attacking; the usage names the mode, and
# Sozinho's log line says what the dummy does, that the sword stops on its guard, which costs it
# stamina and falls when the stamina runs out, that the guard break breaks it and a charged thrown
# the moment the player goes dark lands while the dummy still glows, and the other modes.
func test_dummy_block_gives_sozinho_a_dummy_that_holds_its_guard() -> void:
	var main := _main(["--no-replay", "--dummy=block"])
	await get_tree().process_frame
	var dummy := main.current_match.fighter_at(Match.DUMMY_SLOT)
	assert_object(dummy).is_not_null()
	assert_vector(dummy.position).is_equal_approx(SPAWN_B, Vector3.ONE * HAIR)
	var attacking := main.current_match.attacking_dummy
	assert_object(attacking).override_failure_message("no node drives the dummy").is_not_null()
	assert_object(attacking.dummy).is_same(dummy)
	assert_bool(attacking.holds_guard).is_true()
	assert_bool(attacking.only_guard_breaks).is_false()
	assert_str(Main.USAGE).contains("--dummy=block")
	var line := Main.solo_dummy_line(false, true)
	for said: String in [
		"holds its guard",
		"never attacks",
		"the sword stops on its guard",
		"stamina",
		"falls when the stamina runs out",
		"guard break",
		"charged",
		"glows",
		"--dummy=on",
		"--dummy=guard_break",
		"--dummy=off",
	]:
		assert_str(line).override_failure_message("the line leaves out: %s" % said).contains(said)
	assert_str(Main.solo_dummy_line(false)).contains("--dummy=block")
	assert_str(Main.solo_dummy_line(true)).contains("--dummy=block")


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
	file.set_value("keys", "grapple", "key:%d" % KEY_G)
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
	assert_int(key.physical_keycode).is_equal(KEY_G)
	assert_float(get_tree().root.content_scale_factor).is_equal_approx(1.2, 1e-6)
	assert_float(main.current_match.camera_rig.sensitivity_deg_per_px).is_equal_approx(0.1, 1e-6)
	# Reading the file wrote nothing into it.
	assert_str(FileAccess.get_file_as_string(_options_path)).is_equal(written)


# Criteria 1 and 2 of TASK-12.15 (F-219 §1): --camera=center opens Sozinho with the centered
# camera, camera_center.tres, and the movement numbers whose point O rises with it,
# movement_center.tres, for every fighter of the match, the dummy's aim included: the camera's
# pivot 2,2 m above the player's feet, with no shoulder. The usage names the option, and Sozinho's
# log line names the centered camera with its numbers, read from its data.
func test_camera_center_plays_sozinho_with_the_centered_camera_and_its_aim() -> void:
	var main := _main(["--no-replay", "--camera=center"])
	await get_tree().process_frame
	var game_match := main.current_match
	assert_object(game_match).is_not_null()
	assert_str(game_match.camera_data.resource_path).is_equal(Main.CAMERA_CENTER_PATH)
	assert_str(game_match.movement_data.resource_path).is_equal(Main.MOVEMENT_CENTER_PATH)
	assert_float(game_match.camera_data.shoulder_m).is_equal(0.0)
	assert_float(game_match.camera_data.rise_m).is_equal_approx(CENTER_RISE_M, 1e-9)
	assert_float(game_match.config.aim_side).is_equal(0.0)
	assert_float(game_match.config.aim_rise).is_equal_approx(CENTER_RISE_M, 1e-9)
	assert_float(game_match.config.aim_height).is_equal_approx(AIM_HEIGHT_M, 1e-9)
	var fighter := game_match.fighter_at(Match.PLAYER_SLOT)
	var rig := game_match.camera_rig
	assert_float(rig.global_position.y - fighter.global_position.y).is_equal_approx(
		AIM_HEIGHT_M + CENTER_RISE_M,
		HAIR,
	)
	assert_float(rig.shoulder.spring_length).is_equal(0.0)
	var dummy := game_match.fighter_at(Match.DUMMY_SLOT)
	assert_object(dummy).is_not_null()
	assert_object(dummy.config).is_same(game_match.config)
	assert_str(Main.USAGE).contains("--camera=center")
	assert_str(Main.USAGE).contains("--camera=shoulder")
	var line := Main.solo_camera_line(game_match.camera_data, game_match.movement_data)
	for said: String in [
		"sozinho: the centered camera (--camera=center)",
		"no shoulder and 0.6 m higher",
		"2.2 m above the feet",
		"the body's shoulder, 1.6 m up",
		"--camera=shoulder",
	]:
		assert_str(line).override_failure_message("the line leaves out: %s" % said).contains(said)


# Criterion 1 of TASK-12.15: without --camera, or with --camera=shoulder, Sozinho keeps
# camera_v0.tres and movement_v0.tres, the camera over the right shoulder.
func test_without_camera_center_sozinho_keeps_the_camera_over_the_shoulder(
	argument: String,
	_test_parameters := [[""], ["--camera=shoulder"]],
) -> void:
	var arguments: Array[String] = ["--no-replay"]
	if not argument.is_empty():
		arguments.append(argument)
	var main := _main(arguments)
	await get_tree().process_frame
	var game_match := main.current_match
	assert_str(game_match.camera_data.resource_path).is_equal(Match.CAMERA_DATA_PATH)
	assert_str(game_match.movement_data.resource_path).is_equal(Match.MOVEMENT_DATA_PATH)
	assert_float(game_match.config.aim_side).is_equal_approx(SHOULDER_M, 1e-9)
	assert_float(game_match.config.aim_rise).is_equal(0.0)
	var fighter := game_match.fighter_at(Match.PLAYER_SLOT)
	var rig := game_match.camera_rig
	assert_float(rig.global_position.y - fighter.global_position.y).is_equal_approx(
		AIM_HEIGHT_M,
		HAIR,
	)
	assert_float(rig.shoulder.spring_length).is_equal_approx(SHOULDER_M, 1e-6)


# Criterion 1 of TASK-12.15: the player's sensitivity, from the options file, applies with the
# centered camera too.
func test_the_players_sensitivity_applies_with_the_centered_camera() -> void:
	var file := ConfigFile.new()
	file.set_value("mouse", "sensitivity", 0.1)
	assert_int(file.save(_options_path)).is_equal(OK)
	var main := _main(["--no-replay", "--camera=center"])
	await get_tree().process_frame
	assert_str(main.current_match.camera_data.resource_path).is_equal(Main.CAMERA_CENTER_PATH)
	assert_float(main.current_match.camera_rig.sensitivity_deg_per_px).is_equal_approx(0.1, 1e-6)


# Without an options file the centered camera turns at the default, camera_v0.tres's, which is
# camera_center.tres's too: the sensitivity is today's (criterion 1 of TASK-12.15).
func test_without_options_the_centered_camera_turns_at_the_default_sensitivity() -> void:
	var main := _main(["--no-replay", "--camera=center"])
	await get_tree().process_frame
	var default := OptionsStore.default_sensitivity()
	assert_float(main.current_match.camera_data.sensitivity_deg_per_px).is_equal(default)
	var rig := main.current_match.camera_rig
	assert_float(rig.sensitivity_deg_per_px).is_equal_approx(default, 1e-9)


# Criterion 5 of TASK-12.15: a session played with --camera=center records the centered aim in the
# replay's header, the side 0 and the rise 0,6 m, and the file plays without --force, the same on
# every tick; the camera --watch makes from it is the centered one, and its log line says so.
func test_a_centered_session_records_its_aim_and_replays_the_same_without_force() -> void:
	_folder = OS.get_temp_dir().path_join("jogo-acrobatico-main-test-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(_folder)
	var path := _folder.path_join("centered.replay")
	var main := _main(["--replay=%s" % path, "--camera=center"])
	await get_tree().create_timer(PLAY_S).timeout
	main.end_session()
	var replay := ReplayFile.open(path)
	assert_array(replay.errors).is_empty()
	replay.judge(ReplayFile.this_build())
	assert_array(replay.refusals).override_failure_message("%s" % replay.refusals).is_empty()
	assert_bool(replay.playable(false)).is_true()
	var data := replay.movement_data()
	assert_float(data.aim_side_m).is_equal(0.0)
	assert_float(data.aim_rise_m).is_equal_approx(CENTER_RISE_M, 1e-9)
	assert_int(replay.tick_count()).is_greater(0)
	if not replay.playable(false):
		return
	var played := await ReplayRun.new().play(self, replay, data)
	assert_int(played.ticks).is_equal(replay.tick_count())
	assert_bool(played.checked).is_true()
	assert_int(played.first_apart).is_equal(-1)
	var camera := replay.camera_data()
	assert_float(camera.shoulder_m).is_equal(0.0)
	assert_float(camera.rise_m).is_equal_approx(CENTER_RISE_M, 1e-9)
	assert_str(Main.watch_camera_line(camera)).contains("the centered camera")
	assert_str(Main.watch_camera_line(ReplayFile.this_build().camera_data())).is_equal(
		"sozinho: the replay's camera, from its header: shoulder 0.8 m, rise 0.0 m"
	)
