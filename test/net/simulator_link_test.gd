# TASK-9, round C2: whether netfox's network simulator connects the game is decided by its own
# checks (addons/netfox.extras/network-simulator.gd, _ready), mirrored by SimulatorLink.connects():
# an editor build, autoconnect on, and none of CI, NETFOX_CI and NETFOX_NO_AUTOCONNECT holding a
# value. The project keeps autoconnect off (DEC-0023), so in this run no game is connected by it.
extends GdUnitTestSuite

const EDITOR := true
const EXPORTED := false
const ON := true
const OFF := false


func test_the_simulator_connects_an_editor_build_with_autoconnect_on_and_no_switch_set() -> void:
	var none: Dictionary[String, String] = { }
	var empty: Dictionary[String, String] = {
		"CI": "",
		"NETFOX_CI": "",
		"NETFOX_NO_AUTOCONNECT": "",
	}
	var cases: Array[Array] = [
		[EDITOR, ON, none, true],
		[EDITOR, ON, empty, true],
		[EDITOR, OFF, none, false],
		[EXPORTED, ON, none, false],
		[EXPORTED, OFF, none, false],
	]
	for switch: String in SimulatorLink.OFF_SWITCHES:
		var environment: Dictionary[String, String] = { switch: "1" }
		cases.append([EDITOR, ON, environment, false])
	for case: Array in cases:
		var editor: bool = case[0]
		var enabled: bool = case[1]
		var environment: Dictionary[String, String] = case[2]
		var expected: bool = case[3]
		var connects := SimulatorLink.connects(editor, enabled, environment)
		var message := "editor %s, autoconnect %s, %s" % [editor, enabled, environment]
		assert_bool(connects).override_failure_message(message).is_equal(expected)
	# DEC-0023: here autoconnect is off, so the simulator connects nothing and the Main opens its
	# own connection.
	assert_object(SimulatorLink.current()).is_null()


# The clients join through the simulator's proxy, on the next port, only when it delays or drops
# packets (network-simulator.gd, _is_proxy_required).
func test_the_clients_join_through_the_proxy_only_when_it_delays_or_drops() -> void:
	assert_int(SimulatorLink.new("127.0.0.1", 7777, 50).join_port()).is_equal(7778)
	assert_int(SimulatorLink.new("127.0.0.1", 7777, 0, 5.0).join_port()).is_equal(7778)
	assert_int(SimulatorLink.new("127.0.0.1", 7777, 0).join_port()).is_equal(7777)
