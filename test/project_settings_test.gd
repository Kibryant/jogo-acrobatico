# Guards the project settings decided in DEC-0002, DEC-0005, DEC-0022, DEC-0023, DEC-0024 and
# DEC-0026. A failure here means project.godot changed: read the DEC before "fixing" the test.
extends GdUnitTestSuite

const UNSAFE_ACCESS_WARNINGS: Array[String] = [
	"unsafe_property_access",
	"unsafe_method_access",
	"unsafe_cast",
	"unsafe_call_argument",
]

# DEC-0023: netfox's 14 autoloads, by res:// path. With uid:// a fresh import breaks (netfox
# #659); the "*" makes each one a global singleton. DEC-0022: no autoload of our own.
const NETFOX_CORE := "*res://addons/netfox/"
const NETFOX_EXTRAS := "*res://addons/netfox.extras/"
const NETFOX_AUTOLOADS: Dictionary[String, String] = {
	"WindowTiler": NETFOX_EXTRAS + "window-tiler.gd",
	"NetworkSimulator": NETFOX_EXTRAS + "network-simulator.gd",
	"NetworkTime": NETFOX_CORE + "network-time.gd",
	"NetworkTimeSynchronizer": NETFOX_CORE + "network-time-synchronizer.gd",
	"NetworkRollback": NETFOX_CORE + "rollback/network-rollback.gd",
	"NetworkEvents": NETFOX_CORE + "network-events.gd",
	"NetworkPerformance": NETFOX_CORE + "network-performance.gd",
	"RollbackSimulationServer": NETFOX_CORE + "servers/rollback-simulation-server.gd",
	"NetworkHistoryServer": NETFOX_CORE + "servers/network-history-server.gd",
	"NetworkSynchronizationServer": NETFOX_CORE + "servers/network-synchronization-server.gd",
	"NetworkIdentityServer": NETFOX_CORE + "servers/network-identity-server.gd",
	"NetworkCommandServer": NETFOX_CORE + "servers/network-command-server.gd",
	"RollbackLivenessServer": NETFOX_CORE + "servers/rollback-liveness-server.gd",
	"InterpolationServer": NETFOX_CORE + "servers/interpolation-server.gd",
}

# DEC-0023 §6: netfox's three plugins stay on. Turning one off in the editor runs its _exit_tree,
# which removes the netfox autoloads from project.godot (addons/netfox/netfox.gd).
const NETFOX_PLUGINS: Array[String] = [
	"res://addons/netfox/plugin.cfg",
	"res://addons/netfox.extras/plugin.cfg",
	"res://addons/netfox.internals/plugin.cfg",
]

# Godot 4.7.2 maps a folder to "Exclude" (0) or "Include" (1) its scripts' warnings. The most
# specific folder wins, and a folder without a rule keeps its warnings.
const DIRECTORY_RULES := "debug/gdscript/warnings/directory_rules"
const WARNINGS_EXCLUDED := 0
const WARNINGS_INCLUDED := 1
const OWN_FOLDERS: Array[String] = [
	"res://core",
	"res://common",
	"res://data",
	"res://test",
	"res://fighter",
	"res://arena",
	"res://match",
	"res://net",
	"res://ui",
	"res://tools",
]


func test_physics_engine_is_jolt() -> void:
	var physics_engine: String = ProjectSettings.get_setting("physics/3d/physics_engine")
	assert_str(physics_engine).is_equal("Jolt Physics")


func test_renderer_is_compatibility() -> void:
	var method: String = ProjectSettings.get_setting("rendering/renderer/rendering_method")
	assert_str(method).is_equal("gl_compatibility")


func test_untyped_declaration_is_an_error() -> void:
	var level: int = ProjectSettings.get_setting("debug/gdscript/warnings/untyped_declaration")
	assert_int(level).is_equal(2)


func test_unsafe_access_is_an_error() -> void:
	for warning: String in UNSAFE_ACCESS_WARNINGS:
		var level: int = ProjectSettings.get_setting("debug/gdscript/warnings/" + warning)
		assert_int(level).override_failure_message("%s must be an error (2)" % warning).is_equal(2)


func test_physics_jitter_fix_is_off_for_netcode() -> void:
	var jitter_fix: float = ProjectSettings.get_setting("physics/common/physics_jitter_fix")
	assert_float(jitter_fix).is_equal(0.0)


func test_every_netfox_autoload_is_a_singleton_by_res_path() -> void:
	var autoloads := _autoloads()
	for autoload_name: String in NETFOX_AUTOLOADS:
		var expected: String = NETFOX_AUTOLOADS[autoload_name]
		var found: String = autoloads.get(autoload_name, "")
		var message := (
			'autoload %s must be "%s", found "%s" (DEC-0023, netfox #659)'
			% [autoload_name, expected, found]
		)
		assert_str(found).override_failure_message(message).is_equal(expected)


func test_no_autoload_besides_netfox() -> void:
	for autoload_name: String in _autoloads():
		var message := "autoload %s is not netfox's (DEC-0022: none of our own)" % autoload_name
		var is_netfox := NETFOX_AUTOLOADS.has(autoload_name)
		assert_bool(is_netfox).override_failure_message(message).is_true()


# DEC-0023: the engine creates the autoloads in this order, and they call each other in _ready.
# A missing or extra autoload fails the two tests above, so this one only judges the order.
func test_netfox_autoloads_load_in_the_proven_order() -> void:
	var loaded: Array[String] = []
	for autoload_name: String in _autoloads_in_load_order():
		if NETFOX_AUTOLOADS.has(autoload_name):
			loaded.append(autoload_name)
	var proven: Array[String] = []
	for autoload_name: String in NETFOX_AUTOLOADS:
		if loaded.has(autoload_name):
			proven.append(autoload_name)
	var message := "netfox autoloads must load as %s (DEC-0023), found %s" % [proven, loaded]
	assert_array(loaded).override_failure_message(message).is_equal(proven)


func test_netfox_plugins_are_enabled() -> void:
	var enabled: PackedStringArray = ProjectSettings.get_setting(
		"editor_plugins/enabled",
		PackedStringArray(),
	)
	for plugin: String in NETFOX_PLUGINS:
		var message := "plugin %s must stay enabled (DEC-0023)" % plugin
		assert_bool(enabled.has(plugin)).override_failure_message(message).is_true()


# DEC-0024 (Q-01). netfox's own default is 30.
func test_netfox_ticks_60_times_per_second() -> void:
	var tickrate: int = ProjectSettings.get_setting("netfox/time/tickrate", 30)
	assert_int(tickrate).is_equal(60)


# The netfox settings below are read with netfox's own default as the fallback, because the editor
# drops a setting equal to its default from project.godot (DEC-0026).
func test_input_applies_without_delay() -> void:
	var input_delay: int = ProjectSettings.get_setting("netfox/rollback/input_delay", 0)
	assert_int(input_delay).is_equal(0)


func test_input_goes_only_to_the_server() -> void:
	var broadcast: bool = ProjectSettings.get_setting(
		"netfox/rollback/enable_input_broadcast",
		false,
	)
	assert_bool(broadcast).is_false()


func test_each_input_packet_repeats_the_last_3_ticks() -> void:
	var redundancy: int = ProjectSettings.get_setting("netfox/rollback/input_redundancy", 3)
	assert_int(redundancy).is_equal(3)


func test_rollback_history_keeps_64_ticks() -> void:
	var history_limit: int = ProjectSettings.get_setting("netfox/rollback/history_limit", 64)
	assert_int(history_limit).is_equal(64)


# DEC-0023 §7: the Main connects (DEC-0026). With autoconnect on, the NetworkSimulator autoload
# would host or join by itself whenever the game runs on an editor build.
func test_netfox_does_not_connect_by_itself() -> void:
	var autoconnect: bool = ProjectSettings.get_setting("netfox/autoconnect/enabled", false)
	assert_bool(autoconnect).is_false()


func test_warnings_skip_third_party_addons() -> void:
	var rules: Dictionary = ProjectSettings.get_setting(DIRECTORY_RULES)
	var message := "res://addons must stay excluded: netfox's code is untyped (DEC-0023)"
	var rule := _warning_rule(rules, "res://addons")
	assert_int(rule).override_failure_message(message).is_equal(WARNINGS_EXCLUDED)


# Our folders, and any folder inside them with a rule of its own, keep their warnings.
func test_warnings_stay_on_in_our_folders() -> void:
	var rules: Dictionary = ProjectSettings.get_setting(DIRECTORY_RULES)
	var folders: Array[String] = []
	folders.append_array(OWN_FOLDERS)
	for rule_path: String in rules:
		if _is_inside_own_folder(_rule_folder(rule_path)):
			folders.append(_rule_folder(rule_path))
	for folder: String in folders:
		var message := "warnings must stay on in %s (DEC-0005, DEC-0022)" % folder
		var rule := _warning_rule(rules, folder)
		assert_int(rule).override_failure_message(message).is_equal(WARNINGS_INCLUDED)


# Every autoload in ProjectSettings, by name, with its path as written in project.godot.
func _autoloads() -> Dictionary[String, String]:
	var autoloads: Dictionary[String, String] = { }
	for property: Dictionary in ProjectSettings.get_property_list():
		var setting: String = property["name"]
		if setting.begins_with("autoload/"):
			var path: String = ProjectSettings.get_setting(setting)
			autoloads[setting.trim_prefix("autoload/")] = path
	return autoloads


# Every autoload name, in the order the engine creates them: their order in ProjectSettings.
func _autoloads_in_load_order() -> Array[String]:
	var names: Array[String] = []
	names.assign(_autoloads().keys())
	names.sort_custom(_loads_earlier)
	return names


func _loads_earlier(first: String, second: String) -> bool:
	var first_order := ProjectSettings.get_order("autoload/" + first)
	return first_order < ProjectSettings.get_order("autoload/" + second)


# The warning rule Godot applies to a folder: the rule of the most specific folder that holds it.
func _warning_rule(rules: Dictionary, folder: String) -> int:
	var rule := WARNINGS_INCLUDED
	var matched_length := -1
	for rule_path: String in rules:
		var rule_folder := _rule_folder(rule_path)
		var holds := folder == rule_folder or folder.begins_with(rule_folder + "/")
		if holds and rule_folder.length() > matched_length:
			matched_length = rule_folder.length()
			rule = rules[rule_path]
	return rule


# A rule's folder without the trailing slash, so "res://a/" and "res://a" are the same folder.
func _rule_folder(rule_path: String) -> String:
	return rule_path.trim_suffix("/")


func _is_inside_own_folder(folder: String) -> bool:
	for own_folder: String in OWN_FOLDERS:
		if folder.begins_with(own_folder + "/"):
			return true
	return false
