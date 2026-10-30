# The input box of a fighter (visao-geral.md, "O estado em quatro caixas"): move, yaw, pitch,
# jump, dash, grapple, light_attack, guard, charged_attack, parry and guard_press, which netfox
# records for every tick through "Input:<field>", named as TickInput's. Whoever owns the fighter
# fills them through the same calls, sample_frame(), press_jump(), press_dash(), press_grapple(),
# press_light_attack(), hold_guard(), press_charged_attack(), press_parry() and press_guard():
# this PC's
# keyboard and mouse after use_devices(), or a bot, so the rules never know who presses
# (DEC-0004). How the frames become the input of a tick is the InputSampler's job (DEC-0026 §1).
# A replay takes the place of all of them through play_rows() (TASK-10.3): each tick's box is then
# the recorded row, and this script stays the only one that writes the box.
class_name FighterInput
extends BaseNetInput

# The fields netfox records and restores. The core reads them as a TickInput.
var move := Vector2.ZERO
var yaw := 0.0
var pitch := 0.0
var jump := false
var dash := false
var grapple := false
var light_attack := false
var guard := false
var charged_attack := false
var parry := false
var guard_press := false

var _sampler := InputSampler.new()
# The camera of whoever plays this fighter on this PC; null when nobody here does.
var _camera: CameraRig
# True while a screen over the game takes the keys (TASK-10.9): the devices feed neutral frames.
var _muted := false
# The replay's rows that fill the box instead of the sampler; null when nothing replays.
var _rows: ReplaySource
# The fields of the box, the TickInput's, by name: a replay row fills each of them.
var _fields := ReplayFile.input_fields()


func _ready() -> void:
	# BaseNetInput connects netfox's before_tick_loop to _gather(), on the owner's peer only.
	super()
	# netfox runs its tick loop in the physics step (DEC-0040), and Godot runs a frame's physics
	# steps before its _process: the devices are sampled in the physics step too, and a lower
	# priority goes first (NetworkTime, an autoload, has the default 0), so the keys of a step
	# count in that step's tick instead of a frame later. The mouse turns the camera in
	# _unhandled_input, which Godot dispatches before the physics steps.
	process_physics_priority = -1


# netfox emits after_tick and then records the input of that tick (NetworkTime._loop), so the
# jump, the dash and the grapple set in _on_after_tick are those of this tick, and the next tick
# of the same loop finds them taken.
func _enter_tree() -> void:
	NetworkTime.after_tick.connect(_on_after_tick)


func _exit_tree() -> void:
	NetworkTime.after_tick.disconnect(_on_after_tick)


# The yaw before any sample, at the spawn point; drops what was sampled before.
func face(start_yaw: float) -> void:
	yaw = start_yaw
	_sampler = InputSampler.new(start_yaw)


# From now on this PC's keyboard and mouse drive the fighter, with the yaw and the pitch of this
# camera: the body looks where the camera looks (movimento.md, "Princípios"), and the grapple aims
# where it aims (DEC-0044).
func use_devices(camera: CameraRig) -> void:
	_camera = camera


# While muted, as with the options screen open (TASK-10.9; F-161), the devices feed neutral frames:
# no move and no press, with the camera's yaw and pitch, which stand still meanwhile, so the
# fighter stands still while the game goes on. Unmuted, the keys and the mouse are back.
func mute_devices(muted: bool) -> void:
	_muted = muted


func devices_muted() -> bool:
	return _muted


# From now on the rows of a replay fill the box, tick by tick, instead of the sampler: the box of
# each tick is that tick's row exactly as it was recorded, without the sampler's mean or its
# limit_length, and the frames sampled meanwhile are left out. A tick without a row has the
# neutral input of a fresh TickInput.
func play_rows(source: ReplaySource) -> void:
	_rows = source


# One frame of input (x right, y forward, up to 1; yaw and pitch in rad, pitch positive up), from
# the devices or a bot. A frame without a pitch looks level.
func sample_frame(frame_move: Vector2, frame_yaw: float, frame_pitch := 0.0) -> void:
	_sampler.add_frame(frame_move, frame_yaw, frame_pitch)


# One press of the jump, a one-touch command (DEC-0026 §1).
func press_jump() -> void:
	_sampler.press_jump()


# One press of the dash, a one-touch command like the jump (DEC-0026 §1).
func press_dash() -> void:
	_sampler.press_dash()


# One press of the grapple, a one-touch command like the jump (DEC-0026 §1).
func press_grapple() -> void:
	_sampler.press_grapple()


# One press of the light attack, a one-touch command like the jump (DEC-0026 §1; TASK-12.1).
func press_light_attack() -> void:
	_sampler.press_light_attack()


# One press of the charged attack, a one-touch command like the light (TASK-12.3; DEC-0056 §1).
func press_charged_attack() -> void:
	_sampler.press_charged_attack()


# One press of the parry, a one-touch command like the light (TASK-12.3; DEC-0056 §1).
func press_parry() -> void:
	_sampler.press_parry()


# The guard button going down, a one-touch command beside the hold (TASK-12.3; DEC-0056 §5): in
# the charged's windup it feints. A device or a bot that presses the button calls this and
# hold_guard(true); a hold alone never feints.
func press_guard() -> void:
	_sampler.press_guard()


# The guard button held (true) or let go (false) from now on, from the devices or a bot: a hold,
# not a touch, so every tick reads it until it changes (TASK-12.2; DEC-0054 §1).
func hold_guard(held: bool) -> void:
	_sampler.hold_guard(held)


# The input of the tick being simulated, as the core reads it.
func to_tick_input() -> TickInput:
	var tick_input := TickInput.new()
	tick_input.move = move
	tick_input.yaw = yaw
	tick_input.pitch = pitch
	tick_input.jump = jump
	tick_input.dash = dash
	tick_input.grapple = grapple
	tick_input.light_attack = light_attack
	tick_input.guard = guard
	tick_input.charged_attack = charged_attack
	tick_input.parry = parry
	tick_input.guard_press = guard_press
	return tick_input


func _physics_process(_delta: float) -> void:
	if _camera == null:
		return
	if _muted:
		sample_frame(Vector2.ZERO, _camera.yaw, _camera.pitch)
		hold_guard(false)
		return
	# Keys by physical position (DEC-0031): the InputMap actions use physical_keycode, which the
	# options remap (OptionsStore).
	var keys := Input.get_vector(&"move_left", &"move_right", &"move_back", &"move_forward")
	sample_frame(keys, _camera.yaw, _camera.pitch)
	# The right mouse button by default (project.godot, [input]; F-182 §2), or the player's key or
	# mouse button (OptionsStore): held, read on every frame like the keys of the move.
	hold_guard(Input.is_action_pressed(&"guard"))


# A held key repeats as echo events, which is_action_pressed leaves out: a hold is one press.
func _unhandled_input(event: InputEvent) -> void:
	if _camera == null or _muted:
		return
	if event.is_action_pressed(&"jump"):
		press_jump()
	# The left Shift by default, by physical position (project.godot, [input]; movimento.md,
	# "Dash": "Tecla"), or the player's key or mouse button (OptionsStore).
	if event.is_action_pressed(&"dash"):
		press_dash()
	# The Q by default, by physical position (project.godot, [input]; movimento.md, "Gancho":
	# "Tecla"; F-140), or the player's key or mouse button (OptionsStore).
	if event.is_action_pressed(&"grapple"):
		press_grapple()
	# The left mouse button by default (project.godot, [input]; F-175 §2), or the player's key or
	# mouse button (OptionsStore).
	if event.is_action_pressed(&"light_attack"):
		press_light_attack()
	# The E and the F by default, by physical position (project.godot, [input]; combate.md, "As
	# teclas"; F-191 §2), or the player's key or mouse button (OptionsStore).
	if event.is_action_pressed(&"charged_attack"):
		press_charged_attack()
	if event.is_action_pressed(&"parry"):
		press_parry()
	# The guard button going down: the press, read here as an event, beside the hold the physics
	# step reads (DEC-0056 §5).
	if event.is_action_pressed(&"guard"):
		press_guard()


# netfox calls this once per tick loop, before its ticks, on the owner's peer (BaseNetInput). A
# replay fills the box tick by tick instead, in _on_after_tick.
func _gather() -> void:
	if _rows != null:
		return
	move = _sampler.take_move()
	yaw = _sampler.last_yaw()
	pitch = _sampler.last_pitch()
	guard = _sampler.guard_held()


# netfox records the box of tick right after this (NetworkTime._loop), so what is set here is the
# input of tick: the sampler's one-touch commands, or the whole row of a replay.
func _on_after_tick(_delta: float, tick: int) -> void:
	if not is_multiplayer_authority():
		return
	if _rows == null:
		jump = _sampler.take_jump()
		dash = _sampler.take_dash()
		grapple = _sampler.take_grapple()
		light_attack = _sampler.take_light_attack()
		charged_attack = _sampler.take_charged_attack()
		parry = _sampler.take_parry()
		guard_press = _sampler.take_guard_press()
		return
	var row := _rows.input_at(tick)
	if row == null:
		row = TickInput.new()
	for field: String in _fields:
		set(field, row.get(field))
