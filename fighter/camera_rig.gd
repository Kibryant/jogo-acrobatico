# The third-person camera of whoever plays on this PC (DEC-0013; movimento.md, "Câmera"), only
# for their own fighter: a pivot on the fighter's interpolated position, an arm behind it that
# collides with the world, and the camera at its end. The mouse turns the yaw and the pitch; the
# yaw is what FighterInput samples, so the body looks where the camera looks (movimento.md,
# "Princípios"). The camera is centred: the shoulder offset arrives with the ranged weapons.
class_name CameraRig
extends Node3D

## Where the camera looks, in rad: 0 looks down -Z and a positive turn goes left, the core's
## convention for the yaw (TickInput.yaw).
var yaw := 0.0
## Up and down, in rad: positive looks up. Only the camera tilts, never the body.
var pitch := 0.0

## Rotates with the pitch and pulls the camera in when a wall is in the way.
@export var arm: SpringArm3D
@export var camera: Camera3D

# What the rig follows: the fighter of whoever plays here.
var _target: Node3D
var _pivot_height := 0.0
var _turn_per_pixel := 0.0 # rad per screen pixel
var _max_pitch := 0.0 # rad


# Takes the numbers of movimento.md from the data and starts looking along start_yaw. Called by
# the Match before the rig enters the tree.
func setup(data: CameraData, target: Node3D, start_yaw: float) -> void:
	_target = target
	_pivot_height = data.pivot_height_m
	_turn_per_pixel = deg_to_rad(data.sensitivity_deg_per_px)
	_max_pitch = deg_to_rad(data.max_pitch_deg)
	yaw = start_yaw
	pitch = 0.0
	arm.spring_length = data.distance_m
	arm.collision_mask = PhysicsLayers.WORLD
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.fov = data.vertical_fov_deg


func _ready() -> void:
	camera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_follow()


# After netfox's tick loop of the frame, which interpolates the fighter between two ticks
# (TickInterpolator): the camera follows what the screen shows.
func _process(_delta: float) -> void:
	_follow()


# One mouse motion, in screen pixels: right turns right and up looks up. The pitch stops at the
# limit of the data.
func turn(screen_pixels: Vector2) -> void:
	yaw = wrapf(yaw - screen_pixels.x * _turn_per_pixel, -PI, PI)
	pitch = clampf(pitch - screen_pixels.y * _turn_per_pixel, -_max_pitch, _max_pitch)


# The mouse is captured while playing; Esc releases it and a click captures it again.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
	elif _is_left_click(event) and not _is_captured():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _is_captured():
		var motion := event as InputEventMouseMotion
		# screen_relative is in the screen's pixels, unscaled by the 1920 x 1080 base of the
		# interface, so the 0.06 degrees per pixel hold at any window size.
		turn(motion.screen_relative)


func _is_captured() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


# The wheel also sends mouse buttons; only a press of the left button is a click.
static func _is_left_click(event: InputEvent) -> bool:
	if not event is InputEventMouseButton or not event.is_pressed():
		return false
	var button := event as InputEventMouseButton
	return button.button_index == MOUSE_BUTTON_LEFT


func _follow() -> void:
	if _target != null:
		global_position = _target.global_position + Vector3.UP * _pivot_height
	rotation = Vector3(0.0, yaw, 0.0)
	arm.rotation = Vector3(pitch, 0.0, 0.0)
