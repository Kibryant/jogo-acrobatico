# TASK-10.9, criteria 1, 2, 3, 5 and 6: the player's options file (OptionsStore; DEC-0031 §8;
# F-161; visual-e-audio.md, "A tela de opções"). The keys by physical position, or the middle or a
# side mouse button, the sensitivity from 0.02 to 0.20 degrees per pixel and the scale from 0.8 to
# 1.5 come back on the next load; each bad entry falls back to its default, named in a warning, and
# an unreadable file falls back whole; a key another action has is refused with that action's
# name. TASK-12.1 adds the light attack, on the left mouse button, which no other action takes
# (F-175 §2). Every test writes a temporary file of its own and never touches
# user://options.cfg, which tools/run_tests.sh checks after the run.
extends GdUnitTestSuite

const CameraRigScene := preload("res://fighter/camera_rig.tscn")
const HAIR := 1e-6

var _path := ""


func before_test() -> void:
	_path = OS.get_temp_dir().path_join("jogo-acrobatico-options-%d.cfg" % Time.get_ticks_usec())


func after_test() -> void:
	Engine.print_error_messages = true
	if FileAccess.file_exists(_path):
		DirAccess.remove_absolute(_path)
	InputMap.load_from_project_settings()
	get_tree().root.content_scale_factor = 1.0


func _write(text: String) -> void:
	var file := FileAccess.open(_path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _loaded() -> OptionsStore:
	var store := OptionsStore.new(_path)
	store.load_file()
	return store


static func _code(event: InputEvent) -> int:
	if event is InputEventKey:
		var key := event as InputEventKey
		return key.physical_keycode
	assert(event is InputEventMouseButton, "a binding is a key or a mouse button")
	var button := event as InputEventMouseButton
	return button.button_index


static func _location(event: InputEvent) -> KeyLocation:
	assert(event is InputEventKey, "only a key has a side")
	var key := event as InputEventKey
	return key.location


func _assert_defaults(store: OptionsStore) -> void:
	var expected: Dictionary[StringName, Key] = {
		&"move_forward": KEY_W,
		&"move_back": KEY_S,
		&"move_left": KEY_A,
		&"move_right": KEY_D,
		&"jump": KEY_SPACE,
		&"dash": KEY_SHIFT,
		&"grapple": KEY_Q,
	}
	for action: StringName in expected:
		var event := store.binding(action)
		assert_bool(event is InputEventKey).override_failure_message(action).is_true()
		assert_int(_code(event)).override_failure_message(action).is_equal(expected[action])
	# The light attack is the left mouse button (F-175 §2), and the guard the right one (F-182 §2).
	var light := store.binding(&"light_attack")
	assert_bool(light is InputEventMouseButton).override_failure_message("light_attack").is_true()
	assert_int(_code(light)).is_equal(MOUSE_BUTTON_LEFT)
	var guard := store.binding(&"guard")
	assert_bool(guard is InputEventMouseButton).override_failure_message("guard").is_true()
	assert_int(_code(guard)).is_equal(MOUSE_BUTTON_RIGHT)
	assert_bool(store.camera_shake).override_failure_message("the shake is off").is_true()
	# The dash is the left Shift, not either (TASK-10.4, choice 2).
	assert_int(_location(store.binding(&"dash"))).is_equal(KEY_LOCATION_LEFT)
	assert_float(store.sensitivity).is_equal_approx(0.06, HAIR)
	assert_float(store.scale).is_equal_approx(1.0, HAIR)


func _assert_warned_about(store: OptionsStore, entry: String) -> void:
	var found := false
	for line: String in store.warnings:
		found = found or line.contains(entry)
	var failure := "no warning names %s: %s" % [entry, store.warnings]
	assert_bool(found).override_failure_message(failure).is_true()


# TASK-12.2 adds the guard after the light attack (visual-e-audio.md, "A tela de opções").
func test_the_nine_actions_are_the_ones_of_project_godot_in_the_screens_order() -> void:
	assert_array(OptionsStore.ACTIONS).is_equal(
		[
			&"move_forward",
			&"move_back",
			&"move_left",
			&"move_right",
			&"jump",
			&"dash",
			&"grapple",
			&"light_attack",
			&"guard",
		],
	)
	for action: StringName in OptionsStore.ACTIONS:
		assert_bool(InputMap.has_action(action)).override_failure_message(action).is_true()


func test_the_ranges_and_steps_are_the_papers() -> void:
	assert_str(OptionsStore.DEFAULT_PATH).is_equal("user://options.cfg")
	assert_float(OptionsStore.SCALE_MIN).is_equal(0.8)
	assert_float(OptionsStore.SCALE_MAX).is_equal(1.5)
	assert_float(OptionsStore.SCALE_STEP).is_equal(0.1)
	assert_float(OptionsStore.SENSITIVITY_MIN).is_equal(0.02)
	assert_float(OptionsStore.SENSITIVITY_MAX).is_equal(0.20)
	assert_float(OptionsStore.SENSITIVITY_STEP).is_equal(0.005)
	assert_array(OptionsStore.MOUSE_BUTTONS).is_equal(
		[MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_XBUTTON1, MOUSE_BUTTON_XBUTTON2],
	)


# The first launch: no file, the defaults, and nothing in the log.
func test_without_a_file_every_option_is_its_default_and_nothing_is_warned() -> void:
	var store := _loaded()
	_assert_defaults(store)
	assert_array(store.warnings).is_empty()
	assert_bool(FileAccess.file_exists(_path)).is_false()


# Criteria 1 to 3: what was saved comes back on the next start of the game.
func test_saved_options_come_back_on_the_next_load() -> void:
	var store := OptionsStore.new(_path)
	assert_str(String(store.bind(&"dash", OptionsStore.mouse_event(MOUSE_BUTTON_XBUTTON1)))) \
			.is_empty()
	assert_str(String(store.bind(&"grapple", OptionsStore.key_event(KEY_E)))).is_empty()
	assert_str(String(store.bind(&"jump", OptionsStore.key_event(KEY_CTRL, KEY_LOCATION_RIGHT)))) \
			.is_empty()
	store.sensitivity = 0.1
	store.scale = 1.3
	assert_int(store.save_file()).is_equal(OK)

	var again := _loaded()
	assert_array(again.warnings).is_empty()
	assert_bool(again.binding(&"dash") is InputEventMouseButton).is_true()
	assert_int(_code(again.binding(&"dash"))).is_equal(MOUSE_BUTTON_XBUTTON1)
	assert_int(_code(again.binding(&"grapple"))).is_equal(KEY_E)
	assert_int(_location(again.binding(&"grapple"))).is_equal(KEY_LOCATION_UNSPECIFIED)
	assert_int(_code(again.binding(&"jump"))).is_equal(KEY_CTRL)
	assert_int(_location(again.binding(&"jump"))).is_equal(KEY_LOCATION_RIGHT)
	assert_int(_code(again.binding(&"move_forward"))).is_equal(KEY_W)
	assert_float(again.sensitivity).is_equal_approx(0.1, HAIR)
	assert_float(again.scale).is_equal_approx(1.3, HAIR)


# Criterion 5: a file that is not a ConfigFile is set aside whole, with one warning, and the game
# goes on.
func test_an_unreadable_file_falls_back_whole_with_a_warning() -> void:
	_write("[keys\njump = = \"key:32\nthis is not a config file {{{\n")
	# ConfigFile reports its own parse error as an engine ERROR, which a green gate must not log
	# (tools/run_tests.sh): this test provokes it on purpose, so it keeps it out of the log, and
	# only for this load. The store's own warning is what the player's log shows.
	Engine.print_error_messages = false
	var store := _loaded()
	Engine.print_error_messages = true
	_assert_defaults(store)
	assert_int(store.warnings.size()).is_equal(1)
	_assert_warned_about(store, "cannot be read")


# Criterion 5: each bad key falls back alone, named in the log; the good ones stay.
func test_an_invalid_key_falls_back_to_its_default_alone_and_is_named() -> void:
	_write(
		"\n".join(
			[
				"[keys]",
				"move_forward=42",
				"move_back=\"key:69\"",
				"move_left=\"key:99999\"",
				"move_right=\"key:abc\"",
				"jump=\"key:%d\"" % KEY_ESCAPE,
				"dash=\"key:%d:middle\"" % KEY_SHIFT,
				"grapple=\"pedal:3\"",
			],
		),
	)
	var store := _loaded()
	assert_int(_code(store.binding(&"move_back"))).is_equal(KEY_E)
	assert_int(store.warnings.size()).is_equal(6)
	for action: String in ["move_forward", "move_left", "move_right", "jump", "dash", "grapple"]:
		_assert_warned_about(store, action)
	assert_int(_code(store.binding(&"move_forward"))).is_equal(KEY_W)
	assert_int(_code(store.binding(&"move_left"))).is_equal(KEY_A)
	assert_int(_code(store.binding(&"move_right"))).is_equal(KEY_D)
	assert_int(_code(store.binding(&"jump"))).is_equal(KEY_SPACE)
	assert_int(_code(store.binding(&"dash"))).is_equal(KEY_SHIFT)
	assert_int(_code(store.binding(&"grapple"))).is_equal(KEY_Q)


# Criterion 5 and F-161: the left button is the light attack's alone (F-175 §2), the right one
# stays for the guard of TASK-12.2, and the wheel is no button to hold; the middle and the side
# ones are taken.
func test_the_left_and_right_mouse_buttons_and_the_wheel_are_refused() -> void:
	_write(
		"\n".join(
			[
				"[keys]",
				"dash=\"mouse:%d\"" % MOUSE_BUTTON_LEFT,
				"grapple=\"mouse:%d\"" % MOUSE_BUTTON_RIGHT,
				"jump=\"mouse:%d\"" % MOUSE_BUTTON_WHEEL_UP,
				"move_left=\"mouse:%d\"" % MOUSE_BUTTON_MIDDLE,
				"move_right=\"mouse:%d\"" % MOUSE_BUTTON_XBUTTON2,
			],
		),
	)
	var store := _loaded()
	assert_int(store.warnings.size()).is_equal(3)
	for action: String in ["dash", "grapple", "jump"]:
		_assert_warned_about(store, action)
	assert_int(_code(store.binding(&"dash"))).is_equal(KEY_SHIFT)
	assert_int(_code(store.binding(&"grapple"))).is_equal(KEY_Q)
	assert_int(_code(store.binding(&"jump"))).is_equal(KEY_SPACE)
	assert_int(_code(store.binding(&"move_left"))).is_equal(MOUSE_BUTTON_MIDDLE)
	assert_int(_code(store.binding(&"move_right"))).is_equal(MOUSE_BUTTON_XBUTTON2)
	assert_bool(OptionsStore.accepts(OptionsStore.mouse_event(MOUSE_BUTTON_LEFT))).is_false()
	assert_bool(OptionsStore.accepts(OptionsStore.mouse_event(MOUSE_BUTTON_RIGHT))).is_false()
	assert_bool(OptionsStore.accepts(OptionsStore.mouse_event(MOUSE_BUTTON_XBUTTON1))).is_true()
	assert_bool(OptionsStore.accepts(OptionsStore.key_event(KEY_ESCAPE))).is_false()
	assert_bool(OptionsStore.accepts(InputEventMouseMotion.new())).is_false()


# TASK-12.1: the left button is the light attack's, for no other action; since TASK-12.2 the right
# one is the guard's alone (F-182 §2); the light attack takes a key or the middle or a side button
# too.
func test_the_left_mouse_button_is_the_light_attacks_alone() -> void:
	var left := OptionsStore.mouse_event(MOUSE_BUTTON_LEFT)
	var right := OptionsStore.mouse_event(MOUSE_BUTTON_RIGHT)
	for action: StringName in OptionsStore.ACTIONS:
		var light := action == &"light_attack"
		assert_bool(OptionsStore.accepts(left, action)).override_failure_message(action) \
				.is_equal(light)
		assert_bool(OptionsStore.accepts(right, action)).override_failure_message(action) \
				.is_equal(action == &"guard")
	var store := OptionsStore.new(_path)
	assert_str(String(store.bind(&"light_attack", OptionsStore.key_event(KEY_F)))).is_empty()
	assert_int(_code(store.binding(&"light_attack"))).is_equal(KEY_F)
	assert_str(String(store.bind(&"light_attack", left))).is_empty()
	assert_int(_code(store.binding(&"light_attack"))).is_equal(MOUSE_BUTTON_LEFT)
	# Saved and loaded back, the left button stays the light attack's.
	store.bind(&"light_attack", OptionsStore.mouse_event(MOUSE_BUTTON_XBUTTON1))
	assert_int(store.save_file()).is_equal(OK)
	var loaded := _loaded()
	assert_array(loaded.warnings).is_empty()
	assert_int(_code(loaded.binding(&"light_attack"))).is_equal(MOUSE_BUTTON_XBUTTON1)
	_write("[keys]\nlight_attack=\"mouse:%d\"\n" % MOUSE_BUTTON_LEFT)
	loaded = _loaded()
	assert_array(loaded.warnings).is_empty()
	assert_int(_code(loaded.binding(&"light_attack"))).is_equal(MOUSE_BUTTON_LEFT)
	_write("[keys]\nlight_attack=\"mouse:%d\"\n" % MOUSE_BUTTON_RIGHT)
	loaded = _loaded()
	_assert_warned_about(loaded, "light_attack")
	assert_int(_code(loaded.binding(&"light_attack"))).is_equal(MOUSE_BUTTON_LEFT)


# Criterion 5: a scale or a sensitivity outside its range, or no number at all, falls back to its
# default, named in the log.
func test_a_scale_or_a_sensitivity_out_of_range_falls_back_and_is_named() -> void:
	for case: Array in [[2.0, 0.5], [0.7, 0.0], ["\"big\"", "-0.06"], [1.6, 0.21]]:
		_write("[mouse]\nsensitivity=%s\n[interface]\nscale=%s\n" % [case[1], case[0]])
		var store := _loaded()
		var why := "scale %s, sensitivity %s" % [case[0], case[1]]
		assert_float(store.scale).override_failure_message(why).is_equal_approx(1.0, HAIR)
		assert_float(store.sensitivity).override_failure_message(why).is_equal_approx(0.06, HAIR)
		assert_int(store.warnings.size()).override_failure_message(why).is_equal(2)
		_assert_warned_about(store, "scale")
		_assert_warned_about(store, "sensitivity")


# The edges of each range are inside it, and a number between two steps reads on the nearest one.
func test_the_edges_of_the_ranges_are_taken_and_a_value_snaps_to_its_step() -> void:
	_write("[mouse]\nsensitivity=0.02\n[interface]\nscale=1.5\n")
	var store := _loaded()
	assert_array(store.warnings).is_empty()
	assert_float(store.sensitivity).is_equal_approx(0.02, HAIR)
	assert_float(store.scale).is_equal_approx(1.5, HAIR)
	_write("[mouse]\nsensitivity=0.2\n[interface]\nscale=0.8\n")
	store = _loaded()
	assert_float(store.sensitivity).is_equal_approx(0.2, HAIR)
	assert_float(store.scale).is_equal_approx(0.8, HAIR)
	_write("[mouse]\nsensitivity=0.0612\n[interface]\nscale=1.26\n")
	store = _loaded()
	assert_array(store.warnings).is_empty()
	assert_float(store.sensitivity).is_equal_approx(0.06, HAIR)
	assert_float(store.scale).is_equal_approx(1.3, HAIR)


# Criterion 6: a key another action has is refused, and the answer names that action.
func test_a_key_another_action_has_is_refused_and_names_it() -> void:
	var store := OptionsStore.new(_path)
	assert_str(String(store.bind(&"dash", OptionsStore.key_event(KEY_W)))).is_equal("move_forward")
	assert_int(_code(store.binding(&"dash"))).is_equal(KEY_SHIFT)
	var middle := OptionsStore.mouse_event(MOUSE_BUTTON_MIDDLE)
	assert_str(String(store.bind(&"grapple", middle))).is_empty()
	assert_str(String(store.bind(&"jump", middle))).is_equal("grapple")
	assert_int(_code(store.binding(&"jump"))).is_equal(KEY_SPACE)
	# The dash's left Shift and any Shift clash; the right Shift is another key.
	var any_shift := OptionsStore.key_event(KEY_SHIFT)
	assert_str(String(store.bind(&"jump", any_shift))).is_equal("dash")
	var right_shift := OptionsStore.key_event(KEY_SHIFT, KEY_LOCATION_RIGHT)
	assert_str(String(store.bind(&"jump", right_shift))).is_empty()
	# An action's own key is no conflict.
	assert_str(String(store.bind(&"move_back", OptionsStore.key_event(KEY_S)))).is_empty()


# Two actions of a file on one key: the later one goes back to its default, named.
func test_two_actions_of_the_file_on_one_key_put_the_later_back_to_its_default() -> void:
	_write("[keys]\ngrapple=\"key:%d\"\n" % KEY_W)
	var store := _loaded()
	assert_int(_code(store.binding(&"move_forward"))).is_equal(KEY_W)
	assert_int(_code(store.binding(&"grapple"))).is_equal(KEY_Q)
	assert_int(store.warnings.size()).is_equal(1)
	_assert_warned_about(store, "grapple")


func test_restore_defaults_puts_every_option_back() -> void:
	var store := OptionsStore.new(_path)
	store.bind(&"dash", OptionsStore.mouse_event(MOUSE_BUTTON_XBUTTON2))
	store.bind(&"grapple", OptionsStore.key_event(KEY_E))
	store.sensitivity = 0.15
	store.scale = 0.8
	store.restore_defaults()
	_assert_defaults(store)


# Criterion 1: applied, the binding is the InputMap's, so the action follows the new key at once,
# and the old one no longer triggers it.
func test_applied_keys_drive_the_actions_at_once() -> void:
	var store := OptionsStore.new(_path)
	store.bind(&"dash", OptionsStore.mouse_event(MOUSE_BUTTON_XBUTTON1))
	store.bind(&"grapple", OptionsStore.key_event(KEY_E))
	store.apply_keys()
	var side := InputEventMouseButton.new()
	side.button_index = MOUSE_BUTTON_XBUTTON1
	side.pressed = true
	assert_bool(side.is_action_pressed(&"dash")).is_true()
	var e_key := InputEventKey.new()
	e_key.physical_keycode = KEY_E
	e_key.pressed = true
	assert_bool(e_key.is_action_pressed(&"grapple")).is_true()
	var q_key := InputEventKey.new()
	q_key.physical_keycode = KEY_Q
	q_key.pressed = true
	assert_bool(q_key.is_action_pressed(&"grapple")).is_false()
	assert_int(InputMap.action_get_events(&"grapple").size()).is_equal(1)
	# The defaults are project.godot's, whatever the InputMap holds now.
	assert_int(_code(OptionsStore.default_binding(&"grapple"))).is_equal(KEY_Q)


func test_the_scale_goes_to_the_windows_content_scale_factor() -> void:
	var store := OptionsStore.new(_path)
	store.scale = 1.5
	store.apply_scale(get_tree().root)
	assert_float(get_tree().root.content_scale_factor).is_equal_approx(1.5, HAIR)


func test_the_sensitivity_goes_to_the_camera() -> void:
	var node: Node = auto_free(CameraRigScene.instantiate())
	assert(node is CameraRig, "camera_rig.tscn must have a CameraRig at its root")
	var rig := node as CameraRig
	var store := OptionsStore.new(_path)
	store.sensitivity = 0.1
	store.apply_sensitivity(rig)
	assert_float(rig.sensitivity_deg_per_px).is_equal_approx(0.1, HAIR)
	rig.turn(Vector2(100, 0))
	assert_float(rig.yaw).is_equal_approx(deg_to_rad(-10.0), HAIR)


# tools/run_tests.sh reads the line this test prints to know where user://options.cfg is on this
# machine, and fails the run when that file is newer than the run: the tests never write there.
func test_the_player_keeps_the_options_in_user_options_cfg() -> void:
	var store := OptionsStore.new()
	assert_str(store.path).is_equal("user://options.cfg")
	print("options: user://options.cfg is %s" % ProjectSettings.globalize_path(store.path))


# TASK-12.2 (F-182 §2; DEC-0054 §1): the right button is the guard's, for no other action; the
# guard takes a key or the middle or a side button too, and the right one back; a file that puts
# the right button on another action falls back, named.
func test_the_right_mouse_button_is_the_guards_alone() -> void:
	var right := OptionsStore.mouse_event(MOUSE_BUTTON_RIGHT)
	var store := OptionsStore.new(_path)
	assert_str(String(store.bind(&"guard", OptionsStore.key_event(KEY_C)))).is_empty()
	assert_int(_code(store.binding(&"guard"))).is_equal(KEY_C)
	assert_str(String(store.bind(&"guard", right))).is_empty()
	assert_int(_code(store.binding(&"guard"))).is_equal(MOUSE_BUTTON_RIGHT)
	store.bind(&"guard", OptionsStore.mouse_event(MOUSE_BUTTON_XBUTTON2))
	assert_int(store.save_file()).is_equal(OK)
	var loaded := _loaded()
	assert_array(loaded.warnings).is_empty()
	assert_int(_code(loaded.binding(&"guard"))).is_equal(MOUSE_BUTTON_XBUTTON2)
	_write("[keys]\njump=\"mouse:%d\"\n" % MOUSE_BUTTON_RIGHT)
	loaded = _loaded()
	_assert_warned_about(loaded, "jump")
	assert_int(_code(loaded.binding(&"jump"))).is_equal(KEY_SPACE)
	assert_int(_code(loaded.binding(&"guard"))).is_equal(MOUSE_BUTTON_RIGHT)


# TASK-12.2 (combate.md, "O hitstop e o tremor": "tem opção para desligar"): the camera's shake is
# on by default, saved and read back off, back on with the defaults, and a value that is not a
# boolean falls back to on, named; applied, it turns the camera's shake on or off.
func test_the_camera_shake_is_on_by_default_and_saved_off() -> void:
	var store := OptionsStore.new(_path)
	assert_bool(store.camera_shake).is_true()
	store.camera_shake = false
	assert_int(store.save_file()).is_equal(OK)
	var loaded := _loaded()
	assert_array(loaded.warnings).is_empty()
	assert_bool(loaded.camera_shake).is_false()
	loaded.restore_defaults()
	assert_bool(loaded.camera_shake).is_true()
	_write("[interface]\ncamera_shake=\"yes\"\n")
	loaded = _loaded()
	_assert_warned_about(loaded, "camera_shake")
	assert_bool(loaded.camera_shake).is_true()
	var node: Node = auto_free(CameraRigScene.instantiate())
	assert(node is CameraRig, "camera_rig.tscn must have a CameraRig at its root")
	var rig := node as CameraRig
	loaded.camera_shake = false
	loaded.apply_camera_shake(rig)
	assert_bool(rig.shake_enabled).is_false()
	loaded.camera_shake = true
	loaded.apply_camera_shake(rig)
	assert_bool(rig.shake_enabled).is_true()
