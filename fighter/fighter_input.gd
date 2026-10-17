# The input box of a fighter (visao-geral.md, "O estado em quatro caixas"): move, yaw and jump,
# which netfox records for every tick through "Input:move", "Input:yaw" and "Input:jump". Whoever
# owns the fighter fills them through the same two calls, sample_frame() and press_jump(): this
# PC's keyboard and mouse after use_devices(), or a bot, so the rules never know who presses
# (DEC-0004). How the frames become the input of a tick is the InputSampler's job (DEC-0026 §1).
class_name FighterInput
extends BaseNetInput

# The three fields netfox records and restores. The core reads them as a TickInput.
var move := Vector2.ZERO
var yaw := 0.0
var jump := false

var _sampler := InputSampler.new()
# The camera of whoever plays this fighter on this PC; null when nobody here does.
var _camera: CameraRig


func _ready() -> void:
	# BaseNetInput connects netfox's before_tick_loop to _gather(), on the owner's peer only.
	super()
	# A lower priority processes first, so the devices are sampled before netfox's tick loop of
	# the same frame (NetworkTime, an autoload, processes with the default 0): the keys of a frame
	# count in that frame's ticks instead of a frame later.
	process_priority = -1


# netfox emits after_tick and then records the input of that tick (NetworkTime._loop), so the
# jump set in _on_after_tick is the jump of this tick, and the next tick of the same loop finds
# it taken.
func _enter_tree() -> void:
	NetworkTime.after_tick.connect(_on_after_tick)


func _exit_tree() -> void:
	NetworkTime.after_tick.disconnect(_on_after_tick)


# The yaw before any sample, at the spawn point; drops what was sampled before.
func face(start_yaw: float) -> void:
	yaw = start_yaw
	_sampler = InputSampler.new(start_yaw)


# From now on this PC's keyboard and mouse drive the fighter, with the yaw of this camera: the
# body looks where the camera looks (movimento.md, "Princípios").
func use_devices(camera: CameraRig) -> void:
	_camera = camera


# One frame of input (x right, y forward, up to 1; yaw in rad), from the devices or a bot.
func sample_frame(frame_move: Vector2, frame_yaw: float) -> void:
	_sampler.add_frame(frame_move, frame_yaw)


# One press of the jump, a one-touch command (DEC-0026 §1).
func press_jump() -> void:
	_sampler.press_jump()


# The input of the tick being simulated, as the core reads it.
func to_tick_input() -> TickInput:
	var tick_input := TickInput.new()
	tick_input.move = move
	tick_input.yaw = yaw
	tick_input.jump = jump
	return tick_input


func _process(_delta: float) -> void:
	if _camera == null:
		return
	# Keys by physical position (DEC-0031): the InputMap actions use physical_keycode.
	var keys := Input.get_vector(&"move_left", &"move_right", &"move_back", &"move_forward")
	sample_frame(keys, _camera.yaw)


func _unhandled_input(event: InputEvent) -> void:
	if _camera != null and event.is_action_pressed(&"jump"):
		press_jump()


# netfox calls this once per tick loop, before its ticks, on the owner's peer (BaseNetInput).
func _gather() -> void:
	move = _sampler.take_move()
	yaw = _sampler.last_yaw()


func _on_after_tick(_delta: float, _tick: int) -> void:
	if is_multiplayer_authority():
		jump = _sampler.take_jump()
