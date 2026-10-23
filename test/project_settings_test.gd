# Guards the project settings decided in DEC-0002, DEC-0005, DEC-0022, DEC-0023, DEC-0024,
# DEC-0026 (and the Main scene of TASK-9), DEC-0028 (the version, and the commit stamped only at
# export), DEC-0030 (MSAA), DEC-0031 (the interface base, the one Theme and the physical keys) and
# DEC-0040 (the tick in the physics step), and the log flush of TASK-9 (F-073 §2). A failure here
# means project.godot changed: read the DEC before "fixing" the test.
extends GdUnitTestSuite

# DEC-0026 §6: the game opens on the Main, which picks the mode from the arguments.
const MAIN_SCENE := "res://main/main.tscn"
# DEC-0031 §8: the one Theme of the interface, born with its first scene, the HUD (TASK-10.2).
const GAME_THEME := "res://ui/theme/game_theme.tres"

# DEC-0031 §8: the movement keys by physical position, so WASD sits in the same place on ABNT2,
# AZERTY and Dvorak (TASK-9, criterion 7). The dash is the left Shift (TASK-10.4, choice 2, F-121;
# movimento.md, "Dash": "Tecla").
const PHYSICAL_KEYS: Dictionary[StringName, Key] = {
	&"move_forward": KEY_W,
	&"move_back": KEY_S,
	&"move_left": KEY_A,
	&"move_right": KEY_D,
	&"jump": KEY_SPACE,
	&"dash": KEY_SHIFT,
}

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
	"res://main",
	"res://net",
	"res://ui",
	"res://replay",
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


# DEC-0040: the tick runs in the fixed physics step, so physics_factor is exactly 1 and the window,
# the live game and the headless replay give the same bits at any frame rate. netfox's own default
# is false.
func test_netfox_ticks_in_the_physics_step() -> void:
	var sync_to_physics: bool = ProjectSettings.get_setting("netfox/time/sync_to_physics", false)
	assert_bool(sync_to_physics).is_true()


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


# Anything but digits and periods makes the .exe metadata fall back to 1.0.0.0 (F-047 §1.5).
func test_version_is_three_numbers_of_digits_only() -> void:
	var version: String = ProjectSettings.get_setting("application/config/version", "")
	var three_numbers := RegEx.create_from_string("^[0-9]+\\.[0-9]+\\.[0-9]+$")
	var message := 'version must be three numbers like "0.1.0", found "%s" (DEC-0028)' % version
	var is_three_numbers := three_numbers.search(version) != null
	assert_bool(is_three_numbers).override_failure_message(message).is_true()


# DEC-0028 §3: the CI stamps the commit into application/config/commit right before an export
# (tools/stamp_build.sh). The editor and the gate run without a stamp, so their empty commit
# matches only another empty one (TASK-9, choice 10). tools/server_image_check.sh stamps
# project.godot and restores it on exit; a run killed outright can leave the stamp behind.
func test_the_project_carries_no_stamped_commit() -> void:
	var stamped := ProjectSettings.has_setting(BuildStamp.COMMIT_SETTING)
	var commit := str(ProjectSettings.get_setting(BuildStamp.COMMIT_SETTING, ""))
	var message := (
		(
			'project.godot carries the stamp %s="%s", which only the CI writes, at export'
			+ " (DEC-0028 §3): remove that line"
		)
		% [BuildStamp.COMMIT_SETTING, commit]
	)
	assert_bool(stamped).override_failure_message(message).is_false()


# DEC-0031: the interface is drawn for 1920 x 1080 and stretched from there with canvas_items
# and expand. Godot's own default is 1152 x 648.
func test_interface_base_is_1920_by_1080() -> void:
	var width: int = ProjectSettings.get_setting("display/window/size/viewport_width")
	var height: int = ProjectSettings.get_setting("display/window/size/viewport_height")
	var base := Vector2i(width, height)
	var message := "the interface base must be 1920 x 1080, found %s (DEC-0031)" % base
	assert_vector(base).override_failure_message(message).is_equal(Vector2i(1920, 1080))


func test_stretch_mode_is_canvas_items() -> void:
	var mode: String = ProjectSettings.get_setting("display/window/stretch/mode")
	var message := 'stretch mode must be "canvas_items", found "%s" (DEC-0031)' % mode
	assert_str(mode).override_failure_message(message).is_equal("canvas_items")


func test_stretch_aspect_is_expand() -> void:
	var aspect: String = ProjectSettings.get_setting("display/window/stretch/aspect")
	var message := 'stretch aspect must be "expand", found "%s" (DEC-0031)' % aspect
	assert_str(aspect).override_failure_message(message).is_equal("expand")


# DEC-0031 §8: every Control of the game takes its fonts, sizes and colours from this one Theme,
# and Godot's built-in theme only fills what it leaves out. The editor may write it as a uid://
# path, the same file.
func test_the_interface_takes_the_one_game_theme() -> void:
	var theme: String = ProjectSettings.get_setting("gui/theme/custom", "")
	if theme.begins_with("uid://"):
		theme = ResourceUID.uid_to_path(theme)
	var message := 'gui/theme/custom must be "%s", found "%s" (DEC-0031 §8)' % [GAME_THEME, theme]
	assert_str(theme).override_failure_message(message).is_equal(GAME_THEME)


# DEC-0030: MSAA 2x is value 1 of msaa_3d (0 off, 1 2x, 2 4x, 3 8x), about 0.8 ms with 16
# fighters on the RX 550 (F-056 §5 and §6).
func test_msaa_3d_is_2x() -> void:
	var msaa: int = ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d")
	var message := "MSAA 3D must be 2x (1), found %d (DEC-0030)" % msaa
	assert_int(msaa).override_failure_message(message).is_equal(1)


# TASK-9, criterion 6. The editor may write the scene as a uid:// path, the same scene.
func test_the_game_opens_on_the_main_scene() -> void:
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene", "")
	if main_scene.begins_with("uid://"):
		main_scene = ResourceUID.uid_to_path(main_scene)
	var message := 'the main scene must be "%s", found "%s" (DEC-0026 §6)' % [
		MAIN_SCENE,
		main_scene,
	]
	assert_str(main_scene).override_failure_message(message).is_equal(MAIN_SCENE)


# TASK-9, criterion 9 and choice 8: a release build writes print() out only when its buffer
# fills, and the probe's server log came out 26 s late (F-073 §1 and §2). Flushed on every print,
# the server's log says each event at once.
func test_the_log_is_written_out_at_every_print() -> void:
	var flush: bool = ProjectSettings.get_setting("application/run/flush_stdout_on_print", false)
	var message := "application/run/flush_stdout_on_print must stay on (F-073 §1)"
	assert_bool(flush).override_failure_message(message).is_true()


# TASK-9, part 2: in the server and client modes, netfox's NetworkEvents starts and stops the
# clock as the connection opens and closes (network-events.gd), and the Main waits for it instead
# of starting the clock a second time. netfox's own default is on.
func test_netfox_events_start_the_clock_of_the_server_and_the_client() -> void:
	var events: bool = ProjectSettings.get_setting("netfox/events/enabled", true)
	var message := "netfox/events/enabled must stay on: the Main relies on it (rede.md §9)"
	assert_bool(events).override_failure_message(message).is_true()


# TASK-9, criterion 7: each movement action has its key by position, and no key by label, which
# would move with the keyboard layout.
func test_the_movement_keys_are_bound_by_physical_position() -> void:
	for action: StringName in PHYSICAL_KEYS:
		var has_action := InputMap.has_action(action)
		assert_bool(has_action).override_failure_message("missing action %s" % action).is_true()
		if not has_action:
			continue
		var bound: Array[Key] = []
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey:
				var key := event as InputEventKey
				var by_label := "%s binds keycode %d by label (DEC-0031)" % [action, key.keycode]
				assert_int(key.keycode).override_failure_message(by_label).is_equal(KEY_NONE)
				bound.append(key.physical_keycode)
		var expected: Key = PHYSICAL_KEYS[action]
		var message := (
			"%s must have the physical key %s, found %s (DEC-0031)"
			% [action, OS.get_keycode_string(expected), bound]
		)
		assert_bool(bound.has(expected)).override_failure_message(message).is_true()


# TASK-10.4, choice 2 (F-121): the dash is the left Shift, not either Shift. The keyboard reports
# both Shifts with the same physical keycode and tells them apart by location, and the binding's
# location leaves the right one out.
func test_the_dash_is_the_left_shift_and_not_the_right_one() -> void:
	var left := _key_event(KEY_SHIFT, KEY_LOCATION_LEFT)
	var right := _key_event(KEY_SHIFT, KEY_LOCATION_RIGHT)
	assert_bool(left.is_action_pressed(&"dash")).override_failure_message("left Shift").is_true()
	assert_bool(right.is_action_pressed(&"dash")).override_failure_message("right Shift").is_false()


# A key pressed as the operating system reports it: by physical position, with its location.
func _key_event(physical: Key, location: KeyLocation) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = physical
	event.location = location
	event.pressed = true
	return event


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
