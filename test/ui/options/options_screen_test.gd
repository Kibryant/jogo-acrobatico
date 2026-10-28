# TASK-10.9, criteria 1 to 6: the options screen (OptionsScreen; visual-e-audio.md, "A tela de
# opções"; DEC-0031 §8; F-161). The Esc opens and closes it; open, the game goes on, the player's
# fighter gets neutral frames and the mouse is the screen's; a key clicked takes the next key or
# the middle or a side mouse button, applied to the InputMap and saved at once, unless another
# action has it; the labels are the active keyboard's; the scale reaches content_scale_factor and
# the sensitivity the camera. TASK-12.1 adds the row "Golpe leve", on the left mouse button, the
# one action that button takes (F-175 §2). TASK-12.2 adds the row "Guarda", on the right mouse
# button, the one action that button takes (F-182 §2), and the toggle "Tremor da câmera", on by
# default (combate.md, "O hitstop e o tremor"). The tests run headless, as the gate does, where the
# Match creates no screen (Match.has_screen), so they make the screen themselves and give it the
# fighter, the camera and a store on a temporary file, never user://options.cfg. The events go
# through the viewport, the way the window delivers them.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const MATCH_SCENE := preload("res://match/match.tscn")
const OPTIONS_SCENE := preload("res://ui/options/options_screen.tscn")
const GAME_THEME := "res://ui/theme/game_theme.tres"
const HAIR := 1e-6
const KEYS_PATH := "Backdrop/Panel/Content/Keys/"

var _match: Match
var _fighter: Fighter
var _store: OptionsStore
var _path := ""
var _locale_before := ""


func before_test() -> void:
	NetfoxTicks.reset()
	_locale_before = TranslationServer.get_locale()
	GameText.install()
	TranslationServer.set_locale("pt_BR")
	_path = OS.get_temp_dir().path_join("jogo-acrobatico-screen-%d.cfg" % Time.get_ticks_usec())
	_store = OptionsStore.new(_path)


func after_test() -> void:
	for action: StringName in OptionsStore.ACTIONS:
		Input.action_release(action)
	InputMap.load_from_project_settings()
	get_tree().root.content_scale_factor = 1.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	TranslationServer.set_locale(_locale_before)
	if FileAccess.file_exists(_path):
		DirAccess.remove_absolute(_path)
	NetfoxTicks.reset()


# The fighter this PC plays, with its camera and the keyboard on its input (Match.watch), once
# netfox's deferred setup is done; still inside a physics frame.
func _watched() -> void:
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	_match = auto_free(node)
	_match.options = _store
	add_child(_match)
	_fighter = _match.spawn_fighter(Match.PLAYER_SLOT, multiplayer.get_unique_id())
	_match.watch(_fighter)
	await get_tree().process_frame
	await get_tree().physics_frame


func _screen() -> OptionsScreen:
	var node := OPTIONS_SCENE.instantiate()
	assert(node is OptionsScreen, "options_screen.tscn must have an OptionsScreen at its root")
	var screen: OptionsScreen = auto_free(node)
	add_child(screen)
	screen.follow(_fighter.input, _match.camera_rig, _store)
	return screen


static func _key(code: Key, pressed := true, location := KEY_LOCATION_UNSPECIFIED) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.location = location
	event.pressed = pressed
	return event


static func _mouse(button_index: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	event.pressed = true
	return event


# One tap of a key, its press and its release.
func _tap(code: Key) -> void:
	get_viewport().push_input(_key(code))
	get_viewport().push_input(_key(code, false))


func _key_button(screen: OptionsScreen, action: StringName) -> Button:
	var node := screen.get_node(NodePath(KEYS_PATH + "%sKey" % action.to_pascal_case()))
	assert(node is Button, "each action has a button for its key")
	return node as Button


func _prompt(screen: OptionsScreen) -> String:
	return screen.prompt.text


func _saved(section: String, key: String) -> Variant:
	var file := ConfigFile.new()
	assert_int(file.load(_path)).is_equal(OK)
	return file.get_value(section, key)


func _first_event(action: StringName) -> InputEvent:
	var events := InputMap.action_get_events(action)
	assert_int(events.size()).is_equal(1)
	return events[0]


func _assert_physical(action: StringName, code: Key) -> void:
	var event := _first_event(action)
	assert_bool(event is InputEventKey).override_failure_message(action).is_true()
	var key := event as InputEventKey
	assert_int(key.physical_keycode).override_failure_message(action).is_equal(code)


# The samples of the frames go into the box of the next tick: one physics step samples, the next
# one's tick loop takes them (FighterInput, process_physics_priority).
func _a_tick_of_sampled_frames() -> TickInput:
	await get_tree().physics_frame
	await get_tree().physics_frame
	NetfoxTicks.run_loop()
	return _fighter.input.to_tick_input()


func test_the_screen_starts_closed_above_the_hud() -> void:
	await _watched()
	var screen := _screen()
	assert_bool(screen.is_open()).is_false()
	assert_bool(screen.visible).is_false()
	var hud: Hud = auto_free(Hud.new())
	assert_int(screen.layer).is_greater(hud.layer)
	assert_bool(_match.camera_rig.mouse_free).is_false()
	assert_bool(_fighter.input.devices_muted()).is_false()


# Criterion 4: the Esc opens it, the mouse shows and the fighter's devices are muted; the Esc again
# closes it, and the camera takes the mouse back.
func test_the_esc_opens_and_closes_the_screen() -> void:
	await _watched()
	var screen := _screen()
	_tap(KEY_ESCAPE)
	assert_bool(screen.is_open()).is_true()
	assert_bool(_match.camera_rig.mouse_free).is_true()
	assert_int(Input.mouse_mode).is_equal(Input.MOUSE_MODE_VISIBLE)
	assert_bool(_fighter.input.devices_muted()).is_true()
	_tap(KEY_ESCAPE)
	assert_bool(screen.is_open()).is_false()
	assert_bool(_match.camera_rig.mouse_free).is_false()
	assert_bool(_fighter.input.devices_muted()).is_false()
	# The close button closes it too.
	screen.open()
	screen.close_button.pressed.emit()
	assert_bool(screen.is_open()).is_false()


# Criterion 4 (F-161): open, the game does not pause, and the fighter's box has no move and no
# press while W is held and the Space is pressed; closed, the held W walks again.
func test_while_open_the_fighter_gets_neutral_frames_and_the_game_goes_on() -> void:
	await _watched()
	var screen := _screen()
	NetfoxTicks.run_loops(3)
	var spawn := _fighter.position
	var yaw := _match.camera_rig.yaw
	_tap(KEY_ESCAPE)
	Input.action_press(&"move_forward")
	get_viewport().push_input(_key(KEY_SPACE))
	var tick_before := NetworkTime.tick
	var box := await _a_tick_of_sampled_frames()
	assert_int(NetworkTime.tick).is_greater(tick_before)
	assert_vector(box.move).is_equal(Vector2.ZERO)
	assert_bool(box.jump).is_false()
	assert_bool(box.dash).is_false()
	assert_bool(box.grapple).is_false()
	assert_float(box.yaw).is_equal_approx(yaw, HAIR)
	assert_vector(_fighter.position).is_equal_approx(spawn, Vector3.ONE * 1e-4)
	assert_int(_fighter.state.jumps_used).is_equal(0)

	# A button of the screen with the focus as it closes keeps no key from the fighter.
	screen.close_button.grab_focus()
	_tap(KEY_ESCAPE)
	assert_bool(screen.is_open()).is_false()
	get_viewport().push_input(_key(KEY_SPACE, false))
	get_viewport().push_input(_key(KEY_SPACE))
	box = await _a_tick_of_sampled_frames()
	assert_float(box.move.y).is_greater(0.0)
	assert_bool(box.jump).override_failure_message("the Space did not reach the fighter").is_true()


# Criterion 1: a key clicked waits for the next key, which takes the action's place in the InputMap
# at once and in the file; the button shows the new key.
func test_a_remap_changes_the_input_map_and_is_saved_at_once() -> void:
	await _watched()
	var screen := _screen()
	screen.open()
	assert_str(screen.shown_key(&"dash")).is_equal("Shift")
	_key_button(screen, &"dash").pressed.emit()
	assert_str(String(screen.waiting_for())).is_equal("dash")
	assert_str(_prompt(screen)).is_equal("Aperte a nova tecla para Dash. O Esc cancela.")
	_tap(KEY_E)
	assert_str(String(screen.waiting_for())).is_empty()
	assert_str(_prompt(screen)).is_empty()
	_assert_physical(&"dash", KEY_E)
	assert_str(screen.shown_key(&"dash")).is_equal("E")
	assert_str(str(_saved("keys", "dash"))).is_equal("key:%d" % KEY_E)
	assert_bool(screen.is_open()).is_true()


# Criterion 1 (F-161): the middle and the side mouse buttons take an action; the left and the
# right do not, and the screen goes on waiting.
func test_a_side_mouse_button_takes_an_action_and_the_left_one_does_not() -> void:
	await _watched()
	var screen := _screen()
	screen.open()
	_key_button(screen, &"grapple").pressed.emit()
	get_viewport().push_input(_mouse(MOUSE_BUTTON_LEFT))
	get_viewport().push_input(_mouse(MOUSE_BUTTON_RIGHT))
	assert_str(String(screen.waiting_for())).is_equal("grapple")
	_assert_physical(&"grapple", KEY_Q)
	get_viewport().push_input(_mouse(MOUSE_BUTTON_XBUTTON2))
	assert_str(String(screen.waiting_for())).is_empty()
	var event := _first_event(&"grapple")
	assert_bool(event is InputEventMouseButton).is_true()
	var button := event as InputEventMouseButton
	assert_int(button.button_index).is_equal(MOUSE_BUTTON_XBUTTON2)
	assert_str(screen.shown_key(&"grapple")).is_equal("Mouse 5")
	assert_str(str(_saved("keys", "grapple"))).is_equal("mouse:%d" % MOUSE_BUTTON_XBUTTON2)
	_key_button(screen, &"jump").pressed.emit()
	get_viewport().push_input(_mouse(MOUSE_BUTTON_MIDDLE))
	assert_str(screen.shown_key(&"jump")).is_equal("Mouse 3")


# TASK-12.1 (F-175 §2; visual-e-audio.md, "A tela de opções"): the row "Golpe leve" shows the left
# mouse button as "Mouse esquerdo", "Left mouse" in English; it takes a key, and the left button
# back, and the right button never; no other row takes the left button.
func test_the_light_attack_row_takes_a_key_and_the_left_button_back() -> void:
	await _watched()
	var screen := _screen()
	screen.open()
	var name_node := screen.get_node(NodePath(KEYS_PATH + "LightAttackName"))
	assert(name_node is Label, "each action has a label for its name")
	assert_str((name_node as Label).text).is_equal(String(GameText.OPTIONS_ACTION_LIGHT_ATTACK))
	assert_str(GameText.text(GameText.OPTIONS_ACTION_LIGHT_ATTACK)).is_equal("Golpe leve")
	assert_str(screen.shown_key(&"light_attack")).is_equal("Mouse esquerdo")
	TranslationServer.set_locale("en")
	assert_str(screen.binding_label(_store.binding(&"light_attack"))).is_equal("Left mouse")
	assert_str(GameText.text(GameText.OPTIONS_ACTION_LIGHT_ATTACK)).is_equal("Light attack")
	TranslationServer.set_locale("pt_BR")
	_key_button(screen, &"light_attack").pressed.emit()
	get_viewport().push_input(_mouse(MOUSE_BUTTON_RIGHT))
	assert_str(String(screen.waiting_for())).is_equal("light_attack")
	_tap(KEY_F)
	assert_str(String(screen.waiting_for())).is_empty()
	_assert_physical(&"light_attack", KEY_F)
	assert_str(str(_saved("keys", "light_attack"))).is_equal("key:%d" % KEY_F)
	_key_button(screen, &"light_attack").pressed.emit()
	get_viewport().push_input(_mouse(MOUSE_BUTTON_LEFT))
	assert_str(String(screen.waiting_for())).is_empty()
	var event := _first_event(&"light_attack")
	assert_bool(event is InputEventMouseButton).is_true()
	assert_int((event as InputEventMouseButton).button_index).is_equal(MOUSE_BUTTON_LEFT)
	assert_str(screen.shown_key(&"light_attack")).is_equal("Mouse esquerdo")
	assert_str(str(_saved("keys", "light_attack"))).is_equal("mouse:%d" % MOUSE_BUTTON_LEFT)
	# Another row waits on through a left click.
	_key_button(screen, &"jump").pressed.emit()
	get_viewport().push_input(_mouse(MOUSE_BUTTON_LEFT))
	assert_str(String(screen.waiting_for())).is_equal("jump")
	_assert_physical(&"jump", KEY_SPACE)


# The Esc while a key waits cancels the wait and leaves the screen open.
func test_the_esc_cancels_the_wait_without_closing_the_screen() -> void:
	await _watched()
	var screen := _screen()
	screen.open()
	_key_button(screen, &"jump").pressed.emit()
	_tap(KEY_ESCAPE)
	assert_str(String(screen.waiting_for())).is_empty()
	assert_str(_prompt(screen)).is_empty()
	assert_bool(screen.is_open()).is_true()
	_assert_physical(&"jump", KEY_SPACE)
	assert_bool(FileAccess.file_exists(_path)).is_false()


# Criterion 6: a key another action has does not change, the screen names that action, and the
# wait goes on until another key comes.
func test_a_key_of_another_action_is_refused_with_its_name_until_another_key_comes() -> void:
	await _watched()
	var screen := _screen()
	screen.open()
	_key_button(screen, &"dash").pressed.emit()
	_tap(KEY_W)
	var expected := (
		"W já é de Andar para a frente. Escolha outra tecla ou troque Andar para a frente primeiro."
	)
	assert_str(_prompt(screen)).is_equal(expected)
	assert_str(String(screen.waiting_for())).is_equal("dash")
	_assert_physical(&"dash", KEY_SHIFT)
	_assert_physical(&"move_forward", KEY_W)
	assert_bool(FileAccess.file_exists(_path)).is_false()
	_tap(KEY_R)
	_assert_physical(&"dash", KEY_R)
	assert_str(_prompt(screen)).is_empty()


# DEC-0031 §8: the label is the active keyboard's, from keyboard_get_label_from_physical. A headless
# run has no keyboard and its DisplayServer refuses that call, so the test gives the screen a
# French layout, where the W's place reads "Z" and the Q's "A"; the action stays on the physical
# key.
func test_the_labels_come_from_the_active_keyboard_layout() -> void:
	await _watched()
	var screen := _screen()
	assert_str(screen.shown_key(&"move_forward")).is_equal("W")
	var french: Dictionary[Key, Key] = { KEY_W: KEY_Z, KEY_Q: KEY_A, KEY_A: KEY_Q }
	screen.keyboard_label = func(code: Key) -> Key:
		return french[code] if french.has(code) else code
	screen.follow(_fighter.input, _match.camera_rig, _store)
	assert_str(screen.shown_key(&"move_forward")).is_equal("Z")
	assert_str(screen.shown_key(&"grapple")).is_equal("A")
	assert_str(screen.shown_key(&"move_left")).is_equal("Q")
	assert_str(screen.shown_key(&"jump")).is_equal("Space")
	_assert_physical(&"move_forward", KEY_W)


# Criterion 2: the scale goes to content_scale_factor at once and to the file; a drag applies on
# release, so the slider never moves away from the pointer that holds it.
func test_the_scale_reaches_the_content_scale_factor_and_is_saved() -> void:
	await _watched()
	var screen := _screen()
	screen.open()
	assert_float(screen.scale_slider.min_value).is_equal_approx(0.8, HAIR)
	assert_float(screen.scale_slider.max_value).is_equal_approx(1.5, HAIR)
	assert_float(screen.scale_slider.step).is_equal_approx(0.1, HAIR)
	screen.scale_slider.value = 1.5
	assert_float(get_tree().root.content_scale_factor).is_equal_approx(1.5, HAIR)
	assert_float(float(str(_saved("interface", "scale")))).is_equal_approx(1.5, HAIR)
	assert_str(screen.scale_label.text).is_equal("1,5")
	screen.scale_slider.drag_started.emit()
	screen.scale_slider.value = 1.2
	assert_float(get_tree().root.content_scale_factor).is_equal_approx(1.5, HAIR)
	screen.scale_slider.drag_ended.emit(true)
	assert_float(get_tree().root.content_scale_factor).is_equal_approx(1.2, HAIR)
	assert_float(float(str(_saved("interface", "scale")))).is_equal_approx(1.2, HAIR)


# Criterion 3: the sensitivity goes to the camera at once and to the file, and the screen shows the
# centimetres of a full turn at 800 DPI: 360 / s / 800 x 2.54, rounded.
func test_the_sensitivity_reaches_the_camera_with_the_turn_in_cm() -> void:
	await _watched()
	var screen := _screen()
	screen.open()
	var camera := _match.camera_rig
	assert_float(camera.sensitivity_deg_per_px).is_equal_approx(0.06, HAIR)
	assert_str(screen.turn_label.text).is_equal(
		"Uma volta inteira com uns 19 cm de mouse, a 800 DPI"
	)
	assert_float(screen.sensitivity_slider.min_value).is_equal_approx(0.02, HAIR)
	assert_float(screen.sensitivity_slider.max_value).is_equal_approx(0.20, HAIR)
	assert_float(screen.sensitivity_slider.step).is_equal_approx(0.005, HAIR)
	screen.sensitivity_slider.value = 0.1
	assert_float(camera.sensitivity_deg_per_px).is_equal_approx(0.1, HAIR)
	assert_str(screen.turn_label.text).is_equal(
		"Uma volta inteira com uns 11 cm de mouse, a 800 DPI"
	)
	assert_float(float(str(_saved("mouse", "sensitivity")))).is_equal_approx(0.1, HAIR)
	assert_int(OptionsScreen.turn_cm(0.02)).is_equal(57)
	assert_int(OptionsScreen.turn_cm(0.06)).is_equal(19)
	assert_int(OptionsScreen.turn_cm(0.20)).is_equal(6)


# The Match gives the camera the sensitivity of the options it was given.
func test_the_match_gives_the_camera_the_options_sensitivity() -> void:
	_store.sensitivity = 0.15
	await _watched()
	assert_float(_match.camera_rig.sensitivity_deg_per_px).is_equal_approx(0.15, HAIR)


# Criterion 5: "Voltar ao padrão" puts every option back, applied and saved.
func test_restore_defaults_puts_every_option_back_applied_and_saved() -> void:
	await _watched()
	var screen := _screen()
	screen.open()
	_key_button(screen, &"dash").pressed.emit()
	get_viewport().push_input(_mouse(MOUSE_BUTTON_XBUTTON1))
	screen.sensitivity_slider.value = 0.15
	screen.scale_slider.value = 0.8
	screen.restore_button.pressed.emit()
	_assert_physical(&"dash", KEY_SHIFT)
	assert_str(screen.shown_key(&"dash")).is_equal("Shift")
	assert_float(get_tree().root.content_scale_factor).is_equal_approx(1.0, HAIR)
	assert_float(_match.camera_rig.sensitivity_deg_per_px).is_equal_approx(0.06, HAIR)
	assert_float(screen.sensitivity_slider.value).is_equal_approx(0.06, HAIR)
	assert_float(screen.scale_slider.value).is_equal_approx(1.0, HAIR)
	assert_str(str(_saved("keys", "dash"))).is_equal("key:%d:left" % KEY_SHIFT)
	assert_float(float(str(_saved("interface", "scale")))).is_equal_approx(1.0, HAIR)


# The one Theme (DEC-0031 §8): no Control of the screen carries a theme, a font, a size or a
# colour of its own, every class it takes is in game_theme.tres, and every fixed text is a key.
func test_the_screen_takes_everything_from_the_one_theme_and_its_words_from_keys() -> void:
	await _watched()
	var screen := _screen()
	var project_theme := ThemeDB.get_project_theme()
	assert_str(project_theme.resource_path).is_equal(GAME_THEME)
	var controls := screen.find_children("*", "Control", true, false)
	assert_int(controls.size()).is_greater(20)
	for node: Node in controls:
		assert(node is Control, "find_children by Control returns Controls")
		var control := node as Control
		var where := "%s in %s" % [control.name, control.get_parent().name]
		assert_object(control.theme).override_failure_message("%s has its own Theme" % where) \
				.is_null()
		var own := (
			control.has_theme_font_override(&"font")
			or control.has_theme_font_size_override(&"font_size")
			or control.has_theme_color_override(&"font_color")
			or control.has_theme_color_override(&"font_outline_color")
			or control.has_theme_constant_override(&"outline_size")
			or control.has_theme_stylebox_override(&"panel")
		)
		assert_bool(own).override_failure_message("%s styles itself" % where).is_false()
		var variation := control.theme_type_variation
		if not variation.is_empty():
			var known := project_theme.get_type_variation_list(control.get_class()).has(variation)
			assert_bool(known).override_failure_message("%s: no %s" % [where, variation]).is_true()
		var translated := control.auto_translate_mode != Node.AUTO_TRANSLATE_MODE_DISABLED
		if translated and (control is Label or control is Button):
			var text := str(control.get(&"text"))
			var failure := "%s shows %s, not a key of GameText" % [where, text]
			assert_bool(GameText.KEYS.has(StringName(text))).override_failure_message(failure) \
					.is_true()


# The panel fits the screen at the largest scale on a 1080p window, with every row inside it.
func test_at_the_largest_scale_the_panel_fits_the_screen() -> void:
	var size_before := get_tree().root.size
	get_tree().root.size = Vector2i(1920, 1080)
	await _watched()
	var screen := _screen()
	screen.open()
	screen.scale_slider.value = OptionsStore.SCALE_MAX
	await get_tree().process_frame
	await get_tree().process_frame
	var node := screen.get_node(^"Backdrop/Panel")
	assert(node is Control, "the panel is a Control")
	var panel := node as Control
	var screen_rect := screen.get_viewport().get_visible_rect()
	var where := "the panel at %s in %s" % [panel.get_global_rect(), screen_rect]
	assert_bool(screen_rect.encloses(panel.get_global_rect())) \
			.override_failure_message(where) \
			.is_true()
	get_tree().root.size = size_before


# TASK-12.2 (F-182 §2; DEC-0054 §1): the row "Guarda" shows "Mouse direito", takes a key and the
# right button back, and the right button is no other row's.
func test_the_guard_row_takes_a_key_and_the_right_button_back() -> void:
	await _watched()
	var screen := _screen()
	screen.open()
	assert_str(screen.shown_key(&"guard")).is_equal("Mouse direito")
	TranslationServer.set_locale("en")
	assert_str(screen.binding_label(_store.binding(&"guard"))).is_equal("Right mouse")
	assert_str(GameText.text(GameText.OPTIONS_ACTION_GUARD)).is_equal("Guard")
	TranslationServer.set_locale("pt_BR")
	assert_str(GameText.text(GameText.OPTIONS_ACTION_GUARD)).is_equal("Guarda")
	_key_button(screen, &"guard").pressed.emit()
	get_viewport().push_input(_mouse(MOUSE_BUTTON_LEFT))
	assert_str(String(screen.waiting_for())).is_equal("guard")
	_tap(KEY_C)
	assert_str(String(screen.waiting_for())).is_empty()
	_assert_physical(&"guard", KEY_C)
	assert_str(str(_saved("keys", "guard"))).is_equal("key:%d" % KEY_C)
	_key_button(screen, &"guard").pressed.emit()
	get_viewport().push_input(_mouse(MOUSE_BUTTON_RIGHT))
	assert_str(String(screen.waiting_for())).is_empty()
	var event := _first_event(&"guard")
	assert_bool(event is InputEventMouseButton).is_true()
	assert_int((event as InputEventMouseButton).button_index).is_equal(MOUSE_BUTTON_RIGHT)
	assert_str(screen.shown_key(&"guard")).is_equal("Mouse direito")
	assert_str(str(_saved("keys", "guard"))).is_equal("mouse:%d" % MOUSE_BUTTON_RIGHT)


# TASK-12.2 (combate.md, "O hitstop e o tremor": "tem opção para desligar"): "Tremor da câmera" is
# on by default; turned off, it reaches the camera at once and is saved; "Voltar ao padrão" turns
# it back on.
func test_the_camera_shake_toggle_reaches_the_camera_and_is_saved() -> void:
	await _watched()
	var screen := _screen()
	screen.open()
	var camera := _match.camera_rig
	assert_bool(screen.camera_shake_toggle.button_pressed).is_true()
	assert_bool(camera.shake_enabled).is_true()
	assert_str(screen.camera_shake_toggle.text).is_equal(String(GameText.OPTIONS_CAMERA_SHAKE))
	assert_str(GameText.text(GameText.OPTIONS_CAMERA_SHAKE)).is_equal("Tremor da câmera")
	screen.camera_shake_toggle.button_pressed = false
	assert_bool(_store.camera_shake).is_false()
	assert_bool(camera.shake_enabled).is_false()
	assert_bool(_saved("interface", "camera_shake")).is_false()
	camera.shake(0.1, 0.5)
	assert_bool(camera.shaking()).is_false()
	screen.restore_defaults()
	assert_bool(screen.camera_shake_toggle.button_pressed).is_true()
	assert_bool(camera.shake_enabled).is_true()
	assert_bool(_saved("interface", "camera_shake")).is_true()
