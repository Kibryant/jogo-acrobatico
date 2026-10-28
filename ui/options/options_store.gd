# The player's options (DEC-0031 §8; F-161; visual-e-audio.md, "A tela de opções"): the key of
# each of the eight actions, by physical position, the mouse's sensitivity and the interface's
# scale, kept in user://options.cfg, a ConfigFile, like a settings.json in a home folder. The
# defaults are the InputMap as project.godot loads it, camera_v0.tres's sensitivity and the scale
# 1.0. Reading checks every entry on its own: a bad one falls back to its default with a warning
# that names it, and a file that cannot be read falls back whole; a missing file is the first
# launch, and says nothing. Nothing here enters the simulation: the core only ever receives the
# translated input (DEC-0004), so a replay records actions, never keys.
# The path is a parameter, so the tests use a temporary file and never touch the player's own.
class_name OptionsStore
extends RefCounted

const DEFAULT_PATH := "user://options.cfg"
## The actions the player can remap, in the screen's order (visual-e-audio.md, "A tela de
## opções"; project.godot, [input]).
const ACTIONS: Array[StringName] = [
	&"move_forward",
	&"move_back",
	&"move_left",
	&"move_right",
	&"jump",
	&"dash",
	&"grapple",
	&"light_attack",
]
## The action the left mouse button may take: the light attack, its default (F-175 §2; TASK-12.1).
const LIGHT_ATTACK := &"light_attack"
## The mouse buttons any action may take: the middle one and the two side ones. The left one is the
## light attack's alone (LIGHT_ATTACK), and the right one stays free for the guard of TASK-12.2
## (F-161; visual-e-audio.md, "A tela de opções").
const MOUSE_BUTTONS: Array[MouseButton] = [
	MOUSE_BUTTON_MIDDLE,
	MOUSE_BUTTON_XBUTTON1,
	MOUSE_BUTTON_XBUTTON2,
]
## The interface's scale, by content_scale_factor (DEC-0031 §8; visual-e-audio.md, "A tela de
## opções").
const SCALE_MIN := 0.8
const SCALE_MAX := 1.5
const SCALE_STEP := 0.1
const SCALE_DEFAULT := 1.0
## Degrees per mouse pixel (F-161; movimento.md, "Câmera"); the default is camera_v0.tres's.
const SENSITIVITY_MIN := 0.02
const SENSITIVITY_MAX := 0.20
const SENSITIVITY_STEP := 0.005
const CAMERA_DATA_PATH := "res://data/camera_v0.tres"
const KEYS_SECTION := "keys"
const MOUSE_SECTION := "mouse"
const INTERFACE_SECTION := "interface"
const SENSITIVITY_KEY := "sensitivity"
const SCALE_KEY := "scale"
# A float read back from the file may sit a hair off the edge of its range.
const EDGE := 1e-6

var path: String
## Degrees per mouse pixel.
var sensitivity: float
## The interface's content_scale_factor.
var scale: float
## One line per bad entry the last load_file() fell back on, each naming the entry.
var warnings := PackedStringArray()

var _bindings: Dictionary[StringName, InputEvent] = { }


func _init(file_path := DEFAULT_PATH) -> void:
	path = file_path
	restore_defaults()


# Every option back to its default: the keys of project.godot, camera_v0.tres's sensitivity and
# the scale 1.0. Nothing is applied or saved here.
func restore_defaults() -> void:
	for action: StringName in ACTIONS:
		_bindings[action] = default_binding(action)
	sensitivity = default_sensitivity()
	scale = SCALE_DEFAULT


# Reads the file at path. A missing file keeps the defaults quietly; an unreadable one keeps them
# with one warning; otherwise each entry is checked on its own.
func load_file() -> void:
	warnings.clear()
	restore_defaults()
	if not FileAccess.file_exists(path):
		return
	var file := ConfigFile.new()
	var error := file.load(path)
	if error != OK:
		_warn(
			"%s cannot be read (%s): every option is back to its default"
			% [path, error_string(error)]
		)
		return
	for action: StringName in ACTIONS:
		_load_binding(file, action)
	_load_sensitivity(file)
	_load_scale(file)
	_load_conflicts()


# Writes every option to path.
func save_file() -> Error:
	var file := ConfigFile.new()
	for action: StringName in ACTIONS:
		file.set_value(KEYS_SECTION, action, binding_text(_bindings[action]))
	file.set_value(MOUSE_SECTION, SENSITIVITY_KEY, sensitivity)
	file.set_value(INTERFACE_SECTION, SCALE_KEY, scale)
	var error := file.save(path)
	if error != OK:
		push_warning("options: cannot write %s: %s" % [path, error_string(error)])
	return error


# The event that triggers action: a key by physical position or one of the accepted mouse buttons.
func binding(action: StringName) -> InputEvent:
	assert(_bindings.has(action), "%s is not an action of the options" % action)
	return _bindings[action]


# Gives event to action and returns &"", or, when another action already has it, changes nothing
# and returns that action (criterion 6). The event must be one accepts() takes.
func bind(action: StringName, event: InputEvent) -> StringName:
	assert(_bindings.has(action), "%s is not an action of the options" % action)
	assert(accepts(event, action), "%s cannot trigger %s" % [event, action])
	var holder := holder_of(event, action)
	if not holder.is_empty():
		return holder
	_bindings[action] = normalized(event)
	return &""


# The action other than except whose binding event would also trigger; &"" when none.
func holder_of(event: InputEvent, except: StringName = &"") -> StringName:
	for action: StringName in ACTIONS:
		if action != except and clashes(_bindings[action], event):
			return action
	return &""


# Puts every binding in the InputMap, the events the game reads its actions from: the change
# holds at once, with no restart and no edit to project.godot.
func apply_keys() -> void:
	for action: StringName in ACTIONS:
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, normalized(_bindings[action]))


# The scale multiplies the whole interface, like a browser's zoom (DEC-0031 §8).
func apply_scale(window: Window) -> void:
	window.content_scale_factor = scale


func apply_sensitivity(camera: CameraRig) -> void:
	camera.sensitivity_deg_per_px = sensitivity


# True when event may trigger action: a key known by its physical position, other than the Esc
# that opens and closes the screen, or the middle or a side mouse button; and the left mouse button
# for the light attack alone. Without an action, what any action may take.
static func accepts(event: InputEvent, action: StringName = &"") -> bool:
	if event is InputEventKey:
		var key := event as InputEventKey
		return key.physical_keycode != KEY_ESCAPE and is_key_code(key.physical_keycode)
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT:
			return action == LIGHT_ATTACK
		return MOUSE_BUTTONS.has(button.button_index)
	return false


# True for the physical code of a key the engine names: the name turns back into the same code.
# Codes outside the printable range and the engine's special keys are refused before the name is
# asked for, since the name of a code that is no character is not text.
static func is_key_code(code: int) -> bool:
	var printable := code >= KEY_SPACE and code < 0xD800
	var special := code > KEY_SPECIAL and code < KEY_SPECIAL + 0x200
	if not printable and not special:
		return false
	return OS.find_keycode_from_string(OS.get_keycode_string(code)) == code


# A fresh event with only what a binding keeps: a key's physical code and, for a key with a left
# and a right, its side, as the left Shift of the dash (project.godot); a mouse button's index.
static func normalized(event: InputEvent) -> InputEvent:
	if event is InputEventKey:
		var key := event as InputEventKey
		return key_event(key.physical_keycode, key.location)
	assert(event is InputEventMouseButton, "a binding is a key or a mouse button")
	var button := event as InputEventMouseButton
	return mouse_event(button.button_index)


static func key_event(code: Key, location := KEY_LOCATION_UNSPECIFIED) -> InputEventKey:
	var key := InputEventKey.new()
	key.physical_keycode = code
	key.location = location
	return key


static func mouse_event(button_index: MouseButton) -> InputEventMouseButton:
	var button := InputEventMouseButton.new()
	button.button_index = button_index
	return button


# True when one press would trigger both: the same mouse button, or the same physical key on the
# same side, a key with no side matching both.
static func clashes(one: InputEvent, other: InputEvent) -> bool:
	if one is InputEventMouseButton and other is InputEventMouseButton:
		var first := one as InputEventMouseButton
		var second := other as InputEventMouseButton
		return first.button_index == second.button_index
	if one is InputEventKey and other is InputEventKey:
		var first := one as InputEventKey
		var second := other as InputEventKey
		if first.physical_keycode != second.physical_keycode:
			return false
		var unspecified := KEY_LOCATION_UNSPECIFIED
		return (
			first.location == second.location or first.location == unspecified
			or second.location == unspecified
		)
	return false


# How the file writes a binding: "key:87", "key:4194325:left" or "mouse:8".
static func binding_text(event: InputEvent) -> String:
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		return "mouse:%d" % button.button_index
	assert(event is InputEventKey, "a binding is a key or a mouse button")
	var key := event as InputEventKey
	match key.location:
		KEY_LOCATION_LEFT:
			return "key:%d:left" % key.physical_keycode
		KEY_LOCATION_RIGHT:
			return "key:%d:right" % key.physical_keycode
		_:
			return "key:%d" % key.physical_keycode


# The binding a text of the file names; null when it names none this game accepts for action.
static func parse_binding(text: String, action: StringName = &"") -> InputEvent:
	var parts := text.split(":")
	if parts.size() < 2 or not parts[1].is_valid_int():
		return null
	var code := parts[1].to_int()
	var event: InputEvent = null
	if parts[0] == "mouse" and parts.size() == 2:
		event = mouse_event(code as MouseButton)
	elif parts[0] == "key" and parts.size() == 2:
		event = key_event(code as Key)
	elif parts[0] == "key" and parts.size() == 3 and parts[2] in ["left", "right"]:
		var side := KEY_LOCATION_LEFT if parts[2] == "left" else KEY_LOCATION_RIGHT
		event = key_event(code as Key, side)
	if event == null or not accepts(event, action):
		return null
	return event


# The binding of action as project.godot loads it, whatever the InputMap holds now.
static func default_binding(action: StringName) -> InputEvent:
	var setting: Variant = ProjectSettings.get_setting("input/%s" % action)
	assert(setting is Dictionary, "project.godot has no action %s" % action)
	var entry: Dictionary = setting
	var events: Variant = entry.get("events")
	assert(events is Array, "project.godot's %s has no events" % action)
	var list: Array = events
	assert(list.size() == 1, "project.godot's %s must have one event" % action)
	var first: Variant = list[0]
	assert(first is InputEvent, "project.godot's %s is no input event" % action)
	var event: InputEvent = first
	assert(accepts(event, action), "project.godot's %s is no binding" % action)
	return normalized(event)


static func default_sensitivity() -> float:
	var resource: Resource = load(CAMERA_DATA_PATH)
	assert(resource is CameraData, "%s must load as a CameraData" % CAMERA_DATA_PATH)
	var data := resource as CameraData
	return data.sensitivity_deg_per_px


func _load_binding(file: ConfigFile, action: StringName) -> void:
	if not file.has_section_key(KEYS_SECTION, action):
		return
	var value: Variant = file.get_value(KEYS_SECTION, action)
	var event: InputEvent = null
	if value is String:
		var text: String = value
		event = parse_binding(text, action)
	if event == null:
		_warn(
			"[%s] %s = %s is not a key or an accepted mouse button: back to %s"
			% [KEYS_SECTION, action, var_to_str(value), binding_text(_bindings[action])]
		)
		return
	_bindings[action] = event


# Two actions of the file on one key: the later one in the screen's order goes back to its
# default, unless that clashes too, and then every action goes back to its default.
func _load_conflicts() -> void:
	for action: StringName in ACTIONS:
		var holder := holder_of(_bindings[action], action)
		if holder.is_empty() or ACTIONS.find(holder) > ACTIONS.find(action):
			continue
		var fallback := default_binding(action)
		_warn(
			"[%s] %s = %s is already %s's: back to %s"
			% [
				KEYS_SECTION,
				action,
				binding_text(_bindings[action]),
				holder,
				binding_text(fallback),
			]
		)
		_bindings[action] = fallback
		if not holder_of(fallback, action).is_empty():
			_warn("[%s] the keys still clash: every key is back to its default" % KEYS_SECTION)
			for each: StringName in ACTIONS:
				_bindings[each] = default_binding(each)
			return


# A number of the file on its step: 0.0612 reads 0.06, the slider's own value.
func _load_sensitivity(file: ConfigFile) -> void:
	var value := _number(file, MOUSE_SECTION, SENSITIVITY_KEY, SENSITIVITY_MIN, SENSITIVITY_MAX)
	if not is_nan(value):
		sensitivity = snappedf(value, SENSITIVITY_STEP)


func _load_scale(file: ConfigFile) -> void:
	var value := _number(file, INTERFACE_SECTION, SCALE_KEY, SCALE_MIN, SCALE_MAX)
	if not is_nan(value):
		scale = snappedf(value, SCALE_STEP)


# The number of an entry when it is one from low to high; NAN, with a warning, when it is not,
# and NAN quietly when the entry is missing. The warning names the default the entry keeps.
func _number(file: ConfigFile, section: String, key: String, low: float, high: float) -> float:
	if not file.has_section_key(section, key):
		return NAN
	var value: Variant = file.get_value(section, key)
	if value is int or value is float:
		var number: float = value
		if is_finite(number) and number >= low - EDGE and number <= high + EDGE:
			return number
	var default := sensitivity if key == SENSITIVITY_KEY else scale
	_warn(
		"[%s] %s = %s is not a number from %s to %s: back to %s"
		% [section, key, var_to_str(value), low, high, default]
	)
	return NAN


func _warn(line: String) -> void:
	warnings.append(line)
	push_warning("options: %s" % line)
