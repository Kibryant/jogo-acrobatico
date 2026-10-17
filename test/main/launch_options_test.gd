# Criteria 9 to 11 of TASK-9 and DEC-0026 §6: how the game was opened decides the mode. The mode
# is a pure function of the arguments after "--", of the dedicated server build and of the screen
# (LaunchOptions.parse), so every form runs here without opening the game. Each test walks a
# table of forms: gdUnit spends about 0.1 s on every test case, and the gate has a budget.
extends GdUnitTestSuite

const WITH_SCREEN := true
const HEADLESS := false
const EDITOR_BUILD := false
const DEDICATED_BUILD := true


func _parse(arguments: Array, dedicated := EDITOR_BUILD, screen := HEADLESS) -> LaunchOptions:
	return LaunchOptions.parse(PackedStringArray(arguments), dedicated, screen)


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


# F-056: a typo once left a fullscreen probe open for 300 s.
func test_every_unknown_argument_is_an_error() -> void:
	var arguments: Array[String] = ["--servr", "server", "-server", "--bot", "--port7777"]
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
	]
	for arguments: Array in cases:
		var message := "%s must be refused with one message" % [arguments]
		var errors := _parse(arguments).errors
		assert_int(errors.size()).override_failure_message(message).is_equal(1)
