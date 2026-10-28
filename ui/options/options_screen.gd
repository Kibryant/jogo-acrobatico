# The options screen (TASK-10.9; visual-e-audio.md, "A tela de opções"; DEC-0031 §8): the Esc
# opens it over the game and the HUD, and the Esc or "Fechar (Esc)" closes it. It lists the nine
# actions with the label of their key on the active keyboard, the mouse's sensitivity with the
# centimetres of a full turn, the interface's scale, the camera's shake (TASK-12.2), and "Voltar
# ao padrão". Every change applies
# at once and is saved in the player's options file (OptionsStore).
# Open, the game does not pause, as online, where nothing can (F-161): netfox's clock goes on, the
# fighter of whoever plays receives neutral frames, so it stands still, and the mouse shows.
# Closed, the mouse turns the camera again and the keys drive the fighter.
# Its look is the one Theme's (ui/theme/game_theme.tres): its nodes take the Theme's classes and
# never a font, a size or a colour of their own; its words are keys of GameText.
# Only a PC with a screen has one: the Match creates it with the HUD, in watch().
class_name OptionsScreen
extends CanvasLayer

## The layer above the HUD's, the default 1.
const LAYER := 2
## px at the 1080p base: the width of each slider, the stamina bar's (Hud.BAR_SIZE). Claude's v0
## reading (DEC-0017).
const SLIDER_WIDTH := 300.0
## The mouse of the turn's centimetres (visual-e-audio.md, "A tela de opções").
const TURN_DPI := 800.0
const CM_PER_INCH := 2.54
## The text of each action, in the screen's order (OptionsStore.ACTIONS).
const ACTION_TEXTS: Dictionary[StringName, StringName] = {
	&"move_forward": GameText.OPTIONS_ACTION_MOVE_FORWARD,
	&"move_back": GameText.OPTIONS_ACTION_MOVE_BACK,
	&"move_left": GameText.OPTIONS_ACTION_MOVE_LEFT,
	&"move_right": GameText.OPTIONS_ACTION_MOVE_RIGHT,
	&"jump": GameText.OPTIONS_ACTION_JUMP,
	&"dash": GameText.OPTIONS_ACTION_DASH,
	&"grapple": GameText.OPTIONS_ACTION_GRAPPLE,
	&"light_attack": GameText.OPTIONS_ACTION_LIGHT_ATTACK,
	&"guard": GameText.OPTIONS_ACTION_GUARD,
}
## The number each accepted mouse button shows: "Mouse 3", "Mouse 4" and "Mouse 5".
const MOUSE_NUMBERS: Dictionary[MouseButton, int] = {
	MOUSE_BUTTON_MIDDLE: 3,
	MOUSE_BUTTON_XBUTTON1: 4,
	MOUSE_BUTTON_XBUTTON2: 5,
}

## The grid of the nine actions: a name and the button of its key on each row.
@export var keys: GridContainer
## The line below the keys: the wait for a new key, or the action that already has it.
@export var prompt: Label
@export var sensitivity_slider: HSlider
@export var turn_label: Label
@export var scale_slider: HSlider
@export var scale_label: Label
## "Tremor da câmera": on, the camera shakes on a hit or a block (TASK-12.2).
@export var camera_shake_toggle: CheckButton
@export var restore_button: Button
@export var close_button: Button

## How the key at a physical position reads on the active keyboard: the W's place reads "Z" on a
## French one. With a screen it is DisplayServer.keyboard_get_label_from_physical; a headless run
## has no keyboard, and its DisplayServer refuses that call with an error, so there a key reads by
## its position. A test puts a layout of its own here.
var keyboard_label: Callable = _layout_of_this_pc()

var _store: OptionsStore
var _fighter_input: FighterInput
var _camera: CameraRig
# The button of each action's key.
var _buttons: Dictionary[StringName, Button] = { }
# The action that waits for its new key; empty when none does.
var _waiting: StringName = &""
# True while the scale's slider is held: a scale that changed under the pointer would move the
# slider away from it, so a drag applies on release.
var _dragging_scale := false


func _ready() -> void:
	layer = LAYER
	visible = false
	for action: StringName in OptionsStore.ACTIONS:
		var name_label := Label.new()
		name_label.name = "%sName" % action.to_pascal_case()
		name_label.text = ACTION_TEXTS[action]
		keys.add_child(name_label)
		var button := Button.new()
		button.name = "%sKey" % action.to_pascal_case()
		# The label of a key is already what the player reads.
		button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		button.pressed.connect(_wait_for_key.bind(action))
		keys.add_child(button)
		_buttons[action] = button
	_set_range(sensitivity_slider, OptionsStore.SENSITIVITY_MIN, OptionsStore.SENSITIVITY_MAX)
	sensitivity_slider.step = OptionsStore.SENSITIVITY_STEP
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	_set_range(scale_slider, OptionsStore.SCALE_MIN, OptionsStore.SCALE_MAX)
	scale_slider.step = OptionsStore.SCALE_STEP
	scale_slider.value_changed.connect(_on_scale_changed)
	scale_slider.drag_started.connect(_on_scale_drag_started)
	scale_slider.drag_ended.connect(_on_scale_drag_ended)
	camera_shake_toggle.toggled.connect(_on_camera_shake_toggled)
	# The names a screen reader says for the sliders (DEC-0031 §8: "nomes de acessibilidade").
	sensitivity_slider.accessibility_name = GameText.text(GameText.OPTIONS_SENSITIVITY)
	scale_slider.accessibility_name = GameText.text(GameText.OPTIONS_SCALE)
	restore_button.pressed.connect(restore_defaults)
	close_button.pressed.connect(close)
	prompt.text = ""


# The options it shows and changes, the input of the fighter it stills and the camera that gives
# the mouse up while it is open.
func follow(input: FighterInput, camera: CameraRig, store: OptionsStore) -> void:
	_fighter_input = input
	_camera = camera
	_store = store
	_refresh()


func is_open() -> bool:
	return visible


func open() -> void:
	if _store == null or visible:
		return
	visible = true
	_refresh()
	if _camera != null:
		_camera.free_mouse()
	if _fighter_input != null:
		_fighter_input.mute_devices(true)


func close() -> void:
	if not visible:
		return
	_stop_waiting()
	visible = false
	# A button that kept the focus would take the Space, the GUI's ui_accept, before the fighter.
	get_viewport().gui_release_focus()
	if _fighter_input != null:
		_fighter_input.mute_devices(false)
	if _camera != null:
		_camera.take_mouse()


# Every option back to its default, applied and saved at once.
func restore_defaults() -> void:
	_stop_waiting()
	_store.restore_defaults()
	_store.apply_keys()
	_store.apply_scale(get_window())
	if _camera != null:
		_store.apply_sensitivity(_camera)
		_store.apply_camera_shake(_camera)
	_store.save_file()
	_refresh()


# The action that waits for its new key; empty when none does.
func waiting_for() -> StringName:
	return _waiting


# What the screen shows for an action's key: the label of the physical key on the active keyboard,
# "Mouse esquerdo" for the left button, "Mouse direito" for the right one, or "Mouse 3", "Mouse 4"
# or "Mouse 5".
func binding_label(event: InputEvent) -> String:
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT:
			return GameText.text(GameText.OPTIONS_MOUSE_LEFT)
		if button.button_index == MOUSE_BUTTON_RIGHT:
			return GameText.text(GameText.OPTIONS_MOUSE_RIGHT)
		assert(MOUSE_NUMBERS.has(button.button_index), "%s is no accepted button" % event)
		var pattern := GameText.text(GameText.OPTIONS_MOUSE_BUTTON)
		return pattern.format({ "number": MOUSE_NUMBERS[button.button_index] })
	assert(event is InputEventKey, "a binding is a key or a mouse button")
	var key := event as InputEventKey
	var shown: Variant = keyboard_label.call(key.physical_keycode)
	assert(shown is int, "keyboard_label must give a key")
	var label: Key = shown
	return OS.get_keycode_string(label)


# The text of an action's key button, as the screen shows it now.
func shown_key(action: StringName) -> String:
	return _buttons[action].text


# The centimetres of mouse a full turn takes at 800 DPI: 360 degrees over the sensitivity are the
# pixels, rounded to whole centimetres (visual-e-audio.md, "A tela de opções").
static func turn_cm(sensitivity_deg_per_px: float) -> int:
	return roundi(360.0 / sensitivity_deg_per_px / TURN_DPI * CM_PER_INCH)


# Before the GUI: the Esc opens and closes the screen, and a key that waits takes the next key or
# accepted mouse button, even the Space that would press a focused button.
func _input(event: InputEvent) -> void:
	if _store == null:
		return
	if not _waiting.is_empty():
		if _take(event):
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"ui_cancel"):
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


# While a key waits: the Esc cancels, a key or a mouse button the action accepts is offered (the
# middle or a side one, the left one for the light attack and the right one for the guard), and
# every other press is kept from the screen's buttons. True when the event was the wait's.
func _take(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key := event as InputEventKey
		if not key.pressed or key.echo:
			return true
		if key.physical_keycode == KEY_ESCAPE or key.keycode == KEY_ESCAPE:
			_stop_waiting()
			return true
		_offer(OptionsStore.key_event(key.physical_keycode, key.location))
		return true
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		var offered := OptionsStore.mouse_event(button.button_index)
		if button.pressed and OptionsStore.accepts(offered, _waiting):
			_offer(offered)
		return true
	return false


# The new key of the action that waits: it takes it, applied and saved at once, unless another
# action has it, and then the screen names that action and goes on waiting (criterion 6).
func _offer(event: InputEvent) -> void:
	if not OptionsStore.accepts(event, _waiting):
		return
	var holder := _store.bind(_waiting, event)
	if not holder.is_empty():
		var pattern := GameText.text(GameText.OPTIONS_TAKEN)
		var action := GameText.text(ACTION_TEXTS[holder])
		prompt.text = pattern.format({ "key": binding_label(event), "action": action })
		return
	_store.apply_keys()
	_store.save_file()
	_stop_waiting()
	_refresh()


func _wait_for_key(action: StringName) -> void:
	_waiting = action
	var pattern := GameText.text(GameText.OPTIONS_WAITING)
	prompt.text = pattern.format({ "action": GameText.text(ACTION_TEXTS[action]) })


func _stop_waiting() -> void:
	_waiting = &""
	prompt.text = ""


func _on_sensitivity_changed(value: float) -> void:
	_store.sensitivity = snappedf(value, OptionsStore.SENSITIVITY_STEP)
	if _camera != null:
		_store.apply_sensitivity(_camera)
	_store.save_file()
	_show_turn()


func _on_scale_changed(value: float) -> void:
	_store.scale = snappedf(value, OptionsStore.SCALE_STEP)
	_show_scale()
	if not _dragging_scale:
		_apply_scale()


func _on_camera_shake_toggled(on: bool) -> void:
	_store.camera_shake = on
	if _camera != null:
		_store.apply_camera_shake(_camera)
	_store.save_file()


func _on_scale_drag_started() -> void:
	_dragging_scale = true


func _on_scale_drag_ended(_value_changed: bool) -> void:
	_dragging_scale = false
	_apply_scale()


func _apply_scale() -> void:
	_store.apply_scale(get_window())
	_store.save_file()


func _refresh() -> void:
	if _store == null:
		return
	for action: StringName in OptionsStore.ACTIONS:
		var button := _buttons[action]
		button.text = binding_label(_store.binding(action))
		var action_text := GameText.text(ACTION_TEXTS[action])
		button.accessibility_name = "%s: %s" % [action_text, button.text]
	sensitivity_slider.set_value_no_signal(_store.sensitivity)
	scale_slider.set_value_no_signal(_store.scale)
	camera_shake_toggle.set_pressed_no_signal(_store.camera_shake)
	_show_turn()
	_show_scale()


func _show_turn() -> void:
	var pattern := GameText.text(GameText.OPTIONS_SENSITIVITY_TURN)
	turn_label.text = pattern.format({ "cm": turn_cm(_store.sensitivity) })


func _show_scale() -> void:
	var tenths := roundi(_store.scale * 10.0)
	var pattern := GameText.text(GameText.OPTIONS_SCALE_VALUE)
	scale_label.text = pattern.format({ "whole": floori(tenths / 10.0), "tenth": tenths % 10 })


static func _set_range(slider: HSlider, low: float, high: float) -> void:
	slider.min_value = low
	slider.max_value = high
	slider.custom_minimum_size = Vector2(SLIDER_WIDTH, 0.0)


static func _layout_of_this_pc() -> Callable:
	if DisplayServer.get_name() == "headless":
		return func(code: Key) -> Key:
			return code
	return func(code: Key) -> Key:
		return DisplayServer.keyboard_get_label_from_physical(code)
