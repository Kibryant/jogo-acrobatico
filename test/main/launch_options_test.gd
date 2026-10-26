# Criteria 9 to 11 of TASK-9 and DEC-0026 §6: how the game was opened decides the mode. The mode
# is a pure function of the arguments after "--", of the dedicated server build and of the screen
# (LaunchOptions.parse), so every form runs here without opening the game. Each test walks a
# table of forms: gdUnit spends about 0.1 s on every test case, and the gate has a budget.
extends GdUnitTestSuite

const WITH_SCREEN := true
const HEADLESS := false
const EDITOR_BUILD := false
const DEDICATED_BUILD := true


func _parse(
	arguments: Array,
	dedicated := EDITOR_BUILD,
	screen := HEADLESS,
	simulator: SimulatorLink = null,
) -> LaunchOptions:
	return LaunchOptions.parse(PackedStringArray(arguments), dedicated, screen, simulator)


func _refused(arguments: Array, dedicated := EDITOR_BUILD, screen := HEADLESS) -> bool:
	return not _parse(arguments, dedicated, screen).errors.is_empty()


func test_no_argument_plays_sozinho() -> void:
	var options := _parse([], EDITOR_BUILD, WITH_SCREEN)
	assert_array(options.errors).is_empty()
	assert_int(options.mode).is_equal(LaunchOptions.Mode.SOLO)


# TASK-9, choices 2 and 9: the server listens on 7777/udp unless --port says otherwise, and takes
# the path of its stop file, in any order.
func test_the_server_takes_its_port_and_its_stop_file() -> void:
	var cases: Array[Array] = [
		[["--server"], 7777, ""],
		[["--server", "--port=9999", "--stop-file=/tmp/stop server"], 9999, "/tmp/stop server"],
		[["--stop-file=stop", "--port=9000", "--server"], 9000, "stop"],
		[["--server", "--port=1"], 1, ""],
		[["--server", "--port=65535"], 65535, ""],
	]
	for case: Array in cases:
		var arguments: Array = case[0]
		var options := _parse(arguments)
		var message := "%s" % [arguments]
		assert_array(options.errors).override_failure_message(message).is_empty()
		assert_int(options.mode).override_failure_message(message).is_equal(
			LaunchOptions.Mode.SERVER
		)
		assert_int(options.port).override_failure_message(message).is_equal(case[1])
		assert_str(options.stop_file).override_failure_message(message).is_equal(case[2])


# DEC-0026 §6: the build exported as a dedicated server runs the server with or without --server,
# takes a port and a stop file, and cannot be a client.
func test_the_dedicated_server_build_is_always_the_server() -> void:
	for arguments: Array in [[], ["--server"], ["--port=7000", "--stop-file=/stop"]]:
		var options := _parse(arguments, DEDICATED_BUILD)
		var message := "%s" % [arguments]
		assert_array(options.errors).override_failure_message(message).is_empty()
		assert_int(options.mode).override_failure_message(message).is_equal(
			LaunchOptions.Mode.SERVER
		)
	assert_int(_parse(["--port=7000"], DEDICATED_BUILD).port).is_equal(7000)
	assert_bool(_refused(["--connect=127.0.0.1:7777"], DEDICATED_BUILD)).is_true()


# Criterion 9: the server runs without a screen; opened with one, it says so and does not start.
func test_the_server_refuses_to_open_with_a_screen() -> void:
	var options := _parse(["--server"], EDITOR_BUILD, WITH_SCREEN)
	assert_int(options.errors.size()).is_equal(1)
	assert_str(options.errors[0]).contains("--headless")


func test_a_client_connects_to_host_and_port_with_or_without_a_screen() -> void:
	var cases: Array[Array] = [
		["--connect=192.168.0.10:9999", "192.168.0.10", 9999],
		["--connect=localhost", "localhost", 7777],
		["--connect=127.0.0.1:7777", "127.0.0.1", 7777],
	]
	for case: Array in cases:
		for screen: bool in [WITH_SCREEN, HEADLESS]:
			var options := _parse([case[0]], EDITOR_BUILD, screen)
			var message := "%s" % case[0]
			assert_array(options.errors).override_failure_message(message).is_empty()
			assert_int(options.mode).override_failure_message(message).is_equal(
				LaunchOptions.Mode.CLIENT
			)
			assert_str(options.host).override_failure_message(message).is_equal(case[1])
			assert_int(options.port).override_failure_message(message).is_equal(case[2])


# TASK-9, round C2: the bot plays a client, with or without a screen, and --record goes with the
# server and the client, whose sessions compute the fighters' states.
func test_the_bot_plays_a_client_and_the_record_goes_with_a_session() -> void:
	var cases: Array[Array] = [
		[["--connect=127.0.0.1:7777", "--bot"], EDITOR_BUILD, LaunchOptions.Mode.CLIENT, true, ""],
		[
			["--bot", "--connect=127.0.0.1", "--record=c.rec"],
			EDITOR_BUILD,
			LaunchOptions.Mode.CLIENT,
			true,
			"c.rec",
		],
		[
			["--connect=127.0.0.1", "--record=/tmp/a b.rec"],
			EDITOR_BUILD,
			LaunchOptions.Mode.CLIENT,
			false,
			"/tmp/a b.rec",
		],
		[["--server", "--record=s.rec"], EDITOR_BUILD, LaunchOptions.Mode.SERVER, false, "s.rec"],
		[["--record=s.rec"], DEDICATED_BUILD, LaunchOptions.Mode.SERVER, false, "s.rec"],
	]
	for case: Array in cases:
		var arguments: Array = case[0]
		var dedicated: bool = case[1]
		var mode: LaunchOptions.Mode = case[2]
		for screen: bool in [WITH_SCREEN, HEADLESS]:
			if mode == LaunchOptions.Mode.SERVER and screen == WITH_SCREEN:
				continue # the server runs without a screen
			var options := _parse(arguments, dedicated, screen)
			var message := "%s, screen %s" % [arguments, screen]
			assert_array(options.errors).override_failure_message(message).is_empty()
			assert_int(options.mode).override_failure_message(message).is_equal(mode)
			assert_bool(options.bot).override_failure_message(message).is_equal(case[3])
			assert_str(options.record).override_failure_message(message).is_equal(case[4])


# TASK-9, round C2: --half puts a window on the left or the right half of the screen, so the play
# command shows two games side by side; a game without a screen has no window to place.
func test_a_window_takes_the_half_of_the_screen_it_is_given() -> void:
	var cases: Array[Array] = [
		[["--connect=127.0.0.1", "--half=left"], "left"],
		[["--connect=127.0.0.1", "--bot", "--half=right"], "right"],
		[["--half=right"], "right"],
	]
	for case: Array in cases:
		var arguments: Array = case[0]
		var options := _parse(arguments, EDITOR_BUILD, WITH_SCREEN)
		var message := "%s" % [arguments]
		assert_array(options.errors).override_failure_message(message).is_empty()
		assert_str(options.half).override_failure_message(message).is_equal(case[1])
	assert_str(_parse(["--connect=127.0.0.1"], EDITOR_BUILD, WITH_SCREEN).half).is_empty()


# TASK-9, criterion 17: --measure-fps measures the frame rate of a window, Sozinho or a client,
# played by a person or by the bot.
func test_a_window_measures_its_frame_rate_in_sozinho_or_as_a_client() -> void:
	var cases: Array[Array] = [
		[["--measure-fps=fps.json"], LaunchOptions.Mode.SOLO, "fps.json"],
		[
			["--connect=127.0.0.1", "--bot", "--measure-fps=C:/a b/fps.json"],
			LaunchOptions.Mode.CLIENT,
			"C:/a b/fps.json",
		],
		[
			["--measure-fps=/tmp/fps.json", "--connect=127.0.0.1"],
			LaunchOptions.Mode.CLIENT,
			"/tmp/fps.json",
		],
	]
	for case: Array in cases:
		var arguments: Array = case[0]
		var options := _parse(arguments, EDITOR_BUILD, WITH_SCREEN)
		var message := "%s" % [arguments]
		assert_array(options.errors).override_failure_message(message).is_empty()
		assert_int(options.mode).override_failure_message(message).is_equal(case[1])
		assert_str(options.measure_fps).override_failure_message(message).is_equal(case[2])
	assert_str(_parse(["--connect=127.0.0.1"], EDITOR_BUILD, WITH_SCREEN).measure_fps).is_empty()


# A measurement times the frames of a window that takes the whole screen: without a screen, on the
# server or with --half, --measure-fps is refused with one message, and the game does not open.
func test_the_frame_rate_is_measured_only_in_a_window_that_takes_the_whole_screen() -> void:
	var cases: Array[Array] = [
		[["--measure-fps=fps.json"], HEADLESS],
		[["--connect=127.0.0.1", "--bot", "--measure-fps=fps.json"], HEADLESS],
		[["--server", "--measure-fps=fps.json"], HEADLESS],
		[["--connect=127.0.0.1", "--half=left", "--measure-fps=fps.json"], WITH_SCREEN],
		[["--connect=127.0.0.1", "--measure-fps"], WITH_SCREEN],
		[["--measure-fps="], WITH_SCREEN],
	]
	for case: Array in cases:
		var arguments: Array = case[0]
		var screen: bool = case[1]
		var options := _parse(arguments, EDITOR_BUILD, screen)
		var message := "%s, screen %s, must be refused with one message" % [arguments, screen]
		assert_int(options.errors.size()).override_failure_message(message).is_equal(1)
		assert_str(options.measure_fps).override_failure_message(message).is_empty()
	assert_str(_parse(["--measure-fps=fps.json"]).errors[0]).contains("it needs a screen")
	assert_bool(_refused(["--measure-fps=fps.json"], DEDICATED_BUILD)).is_true()


# With netfox's network simulator on, the simulator connects the game to its own address and reads
# no argument (network-simulator.gd): an address in the arguments that differs is refused, and so
# is Sozinho, which has no network (TASK-9, round C2).
func test_with_netfox_simulator_on_the_address_must_be_its_own() -> void:
	var simulator := SimulatorLink.new("127.0.0.1", 7777, 50)
	var accepted: Array[Array] = [
		["--server"],
		["--server", "--port=7777", "--stop-file=stop"],
		["--connect=127.0.0.1:7777"],
		["--connect=127.0.0.1", "--bot"],
	]
	for arguments: Array in accepted:
		var options := _parse(arguments, EDITOR_BUILD, HEADLESS, simulator)
		var message := "%s with the simulator on 127.0.0.1:7777" % [arguments]
		assert_array(options.errors).override_failure_message(message).is_empty()
		assert_object(options.simulator).override_failure_message(message).is_same(simulator)
	var refused: Array[Array] = [
		[],
		["--server", "--port=7000"],
		["--connect=127.0.0.1:7000"],
		["--connect=localhost:7777"],
	]
	for arguments: Array in refused:
		var errors := _parse(arguments, EDITOR_BUILD, HEADLESS, simulator).errors
		var message := "%s with the simulator on 127.0.0.1:7777 must be refused once" % [arguments]
		assert_int(errors.size()).override_failure_message(message).is_equal(1)
	# netfox's own port is 9999: the game's 7777 does not match it.
	var netfox_default := SimulatorLink.new("127.0.0.1", 9999, 0)
	var on_its_default := _parse(["--server"], EDITOR_BUILD, HEADLESS, netfox_default)
	assert_int(on_its_default.errors.size()).is_equal(1)


# A typo once left a fullscreen probe open for up to 300 s (.claude/harness/registro.md,
# 2026-10-07).
func test_every_unknown_argument_is_an_error() -> void:
	var arguments: Array[String] = ["--servr", "server", "-server", "--bots", "--port7777"]
	var options := _parse(arguments)
	assert_int(options.errors.size()).is_equal(arguments.size())
	for argument: String in arguments:
		assert_bool(options.errors.has("Unknown argument: %s" % argument)).is_true()


func test_a_port_is_a_number_from_1_to_65535() -> void:
	for port: String in ["0", "65536", "-1", "77a7", "7777.0", " 7777"]:
		var message := "port %s must be refused" % port
		var refused := _refused(["--server", "--port=%s" % port])
		assert_bool(refused).override_failure_message(message).is_true()
		refused = _refused(["--connect=127.0.0.1:%s" % port])
		assert_bool(refused).override_failure_message(message).is_true()


# Each form here is refused with one message.
func test_arguments_that_do_not_fit_together_are_errors() -> void:
	var cases: Array[Array] = [
		["--server", "--port"],
		["--server", "--port="],
		["--server", "--stop-file"],
		["--server", "--stop-file="],
		["--connect"],
		["--connect="],
		["--connect=:7777"],
		["--server=yes"],
		["--server", "--port=7000", "--port=7001"],
		["--server", "--connect=127.0.0.1:7777"],
		["--port=7000"],
		["--stop-file=stop"],
		["--connect=127.0.0.1:7777", "--port=7000"],
		["--connect=127.0.0.1:7777", "--stop-file=stop"],
		["--bot"],
		["--server", "--bot"],
		["--connect=127.0.0.1", "--bot=yes"],
		["--connect=127.0.0.1", "--bot", "--bot"],
		["--record=run.rec"],
		["--server", "--record"],
		["--connect=127.0.0.1", "--record="],
		["--connect=127.0.0.1", "--half=left"],
		["--connect=127.0.0.1", "--half=middle"],
		["--connect=127.0.0.1", "--half"],
		["--server", "--half=left"],
	]
	for arguments: Array in cases:
		var message := "%s must be refused with one message" % [arguments]
		var errors := _parse(arguments).errors
		assert_int(errors.size()).override_failure_message(message).is_equal(1)


# TASK-10.3, criterion 1 (F-112 §2): Sozinho records a replay, always, in user://replays/ unless
# --replay names the file, --replay-dir the folder, or --no-replay turns it off; --watch plays one
# in a window instead and records none. The server and the clients record no replay.
func test_sozinho_records_a_replay_unless_told_where_or_not_to() -> void:
	var always := _parse([], EDITOR_BUILD, WITH_SCREEN)
	assert_bool(always.records_replay()).is_true()
	assert_str(always.replay).is_empty()
	assert_str(always.replay_dir).is_empty()
	var named := _parse(["--replay=bug.replay"], EDITOR_BUILD, WITH_SCREEN)
	assert_array(named.errors).is_empty()
	assert_bool(named.records_replay()).is_true()
	assert_str(named.replay).is_equal("bug.replay")
	var folder := _parse(["--replay-dir=replays"])
	assert_array(folder.errors).is_empty()
	assert_bool(folder.records_replay()).is_true()
	assert_str(folder.replay_dir).is_equal("replays")
	var off := _parse(["--no-replay"])
	assert_array(off.errors).is_empty()
	assert_bool(off.no_replay).is_true()
	assert_bool(off.records_replay()).is_false()
	var watched := _parse(
		["--watch=bug.replay", "--force", "--trace=bug.trace"],
		EDITOR_BUILD,
		WITH_SCREEN,
	)
	assert_array(watched.errors).is_empty()
	assert_str(watched.watch).is_equal("bug.replay")
	assert_bool(watched.force).is_true()
	assert_str(watched.trace).is_equal("bug.trace")
	assert_bool(watched.records_replay()).is_false()
	for arguments: Array in [["--server"], ["--connect=127.0.0.1"]]:
		assert_bool(_parse(arguments).records_replay()).is_false()


# TASK-10.3: the replay's arguments that do not fit are refused with one message each, and the
# Main exits with 2 on them (Main.EXIT_USAGE).
func test_replay_arguments_that_do_not_fit_are_errors() -> void:
	var cases: Array[Array] = [
		["--server", "--no-replay"],
		["--server", "--replay=x.replay"],
		["--connect=127.0.0.1", "--replay-dir=replays"],
		["--connect=127.0.0.1", "--watch=x.replay"],
		["--replay=x.replay", "--replay-dir=replays"],
		["--no-replay", "--replay=x.replay"],
		["--no-replay", "--replay-dir=replays"],
		["--no-replay=yes"],
		["--replay"],
		["--replay-dir="],
		["--watch=x.replay"],
		["--trace=x.trace"],
		["--force"],
	]
	for arguments: Array in cases:
		var message := "%s must be refused with one message" % [arguments]
		var errors := _parse(arguments).errors
		assert_int(errors.size()).override_failure_message(message).is_equal(1)
	var windowed: Array[Array] = [
		["--watch=x.replay", "--replay=y.replay"],
		["--watch=x.replay", "--no-replay"],
		["--watch=x.replay", "--measure-fps=fps.json"],
		["--watch"],
		["--trace=x.trace", "--force"],
	]
	for arguments: Array in windowed:
		var message := "%s must be refused, with a screen too" % [arguments]
		var errors := _parse(arguments, EDITOR_BUILD, WITH_SCREEN).errors
		assert_array(errors).override_failure_message(message).is_not_empty()
	assert_str(_parse(["--watch=x.replay"]).errors[0]).contains("it needs a screen")


# TASK-10.7, criterion 5: Sozinho's own play has a still dummy unless --dummy=off; the server, a
# client and --watch, which plays the fighters of its file, have none.
func test_sozinho_has_a_dummy_unless_told_off() -> void:
	assert_bool(_parse([], EDITOR_BUILD, WITH_SCREEN).dummy).is_true()
	assert_bool(_parse([]).dummy).is_true()
	assert_bool(_parse(["--dummy=on"]).dummy).is_true()
	var off := _parse(["--dummy=off", "--no-replay"])
	assert_array(off.errors).is_empty()
	assert_bool(off.dummy).is_false()
	assert_bool(_parse(["--server"]).dummy).is_false()
	assert_bool(_parse(["--connect=127.0.0.1"]).dummy).is_false()
	assert_bool(_parse(["--watch=x.replay"], EDITOR_BUILD, WITH_SCREEN).dummy).is_false()


func test_dummy_arguments_that_do_not_fit_are_errors() -> void:
	var cases: Array[Array] = [
		["--dummy"],
		["--dummy="],
		["--dummy=no"],
		["--dummy=off", "--dummy=on"],
		["--server", "--dummy=off"],
		["--connect=127.0.0.1", "--dummy=on"],
	]
	for arguments: Array in cases:
		var message := "%s must be refused with one message" % [arguments]
		var errors := _parse(arguments).errors
		assert_int(errors.size()).override_failure_message(message).is_equal(1)
	var watched := _parse(["--watch=x.replay", "--dummy=off"], EDITOR_BUILD, WITH_SCREEN)
	assert_int(watched.errors.size()).is_equal(1)
	assert_str(watched.errors[0]).contains("--watch")
