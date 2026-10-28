# Turns the frames between two tick loops into the input of a tick (DEC-0026 §1; rede.md §3). The
# screen runs at its own rate and the game at 60 ticks, so a tick can see several frames, or a
# frame can run several ticks; this object keeps what the frames said until the tick asks:
# - move is the mean of the frame samples since the last tick loop, netfox's pattern for
#   continuous input (continuous-sampled-input.gd). With the keyboard it is below 1 only on the
#   tick a key changes (TASK-9 plan, Claude's v0 readings);
# - yaw is the last sample: a mean of angles breaks where they wrap at 180 degrees, and the last
#   sample is where the camera looks now (TASK-9, choice 1); pitch is the last sample too, for the
#   same reasons (rede.md §3; TASK-10.6);
# - jump, dash, grapple and the light attack are one-touch commands kept between frames and taken
#   once, so a press counts for at most one tick even when a frame runs two (netfox's
#   one-off-input.gd);
# - the guard is held, not touched (TASK-12.2): the state the devices or a bot last set, kept until
#   they set another, and read by every tick.
# No node and no engine input here: FighterInput feeds it, from the devices or from a bot.
class_name InputSampler
extends RefCounted

var _move_sum := Vector2.ZERO
var _move_samples := 0
var _yaw: float
var _pitch := 0.0
var _jump_pressed := false
var _dash_pressed := false
var _grapple_pressed := false
var _light_attack_pressed := false
var _guard_held := false


# start_yaw is the yaw before any sample: where the fighter looks at its spawn point.
func _init(start_yaw := 0.0) -> void:
	_yaw = start_yaw


# One frame of input: where the player pushes (x right, y forward, up to 1) and where the camera
# looks, in rad: yaw about the vertical, and pitch up from the horizontal, positive up. A frame
# without a pitch looks level.
func add_frame(move: Vector2, yaw: float, pitch := 0.0) -> void:
	_move_sum += move.limit_length(1.0)
	_move_samples += 1
	_yaw = yaw
	_pitch = pitch


# One press of the jump, kept until take_jump().
func press_jump() -> void:
	_jump_pressed = true


# One press of the dash, kept until take_dash().
func press_dash() -> void:
	_dash_pressed = true


# One press of the grapple, kept until take_grapple().
func press_grapple() -> void:
	_grapple_pressed = true


# One press of the light attack, kept until take_light_attack() (TASK-12.1).
func press_light_attack() -> void:
	_light_attack_pressed = true


# The guard button down or up from now on (TASK-12.2; DEC-0054 §1), until the next call.
func hold_guard(held: bool) -> void:
	_guard_held = held


# Whether the guard is held now: it stays until hold_guard() says otherwise.
func guard_held() -> bool:
	return _guard_held


# The mean of the move samples since the last call, which starts a new tick's samples. Zero when
# no frame was sampled: no frame, no push.
func take_move() -> Vector2:
	var mean := Vector2.ZERO
	if _move_samples > 0:
		mean = _move_sum / _move_samples
	_move_sum = Vector2.ZERO
	_move_samples = 0
	return mean


# The yaw of the last sample; it stays until a new sample comes.
func last_yaw() -> float:
	return _yaw


# The pitch of the last sample, like the yaw; 0 before any sample.
func last_pitch() -> float:
	return _pitch


# True once per press: the press is consumed, and the next call is false until a new press.
func take_jump() -> bool:
	var pressed := _jump_pressed
	_jump_pressed = false
	return pressed


# True once per press, like take_jump().
func take_dash() -> bool:
	var pressed := _dash_pressed
	_dash_pressed = false
	return pressed


# True once per press, like take_jump().
func take_grapple() -> bool:
	var pressed := _grapple_pressed
	_grapple_pressed = false
	return pressed


# True once per press, like take_jump().
func take_light_attack() -> bool:
	var pressed := _light_attack_pressed
	_light_attack_pressed = false
	return pressed
