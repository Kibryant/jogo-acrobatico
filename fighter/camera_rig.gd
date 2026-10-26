# The third-person camera of whoever plays on this PC (DEC-0013; movimento.md, "Câmera"), only
# for their own fighter: a pivot on the fighter's interpolated position, an arm behind it, a
# shoulder from the arm's end to the right, and the camera at the shoulder's end, over the right
# shoulder, the body in the bottom-left corner and the screen's centre free (DEC-0045 §1). The
# mouse turns the yaw and the pitch; the yaw is what FighterInput samples, so the body looks where
# the camera looks (movimento.md, "Princípios").
#
# The collision comes in two steps, both the engine's SpringArm3D and both only against the world,
# so a fighter pushes nothing: the arm pulls the camera in when a wall is behind, and the shoulder,
# cast from wherever the arm stopped, slides it toward the centre when a wall is beside, as in a
# wall run with the wall on the right; each stops collision_margin_m before the wall. A SpringArm3D
# moves its children to its end keeping their global rotation, and with a Camera3D as its direct
# child it casts the camera's near-plane pyramid instead of a ray, so each arm moves an "End" node
# of identity rotation: both cast a ray, and the turns of the shoulder and of the camera are
# never rewritten by the engine. Free, the camera sits shoulder_m to the right of the pivot and
# distance_m behind it, looking along the view, so its optical axis passes through the aim's
# point O, Aim.origin of the same feet and yaw (DEC-0045 §2).
#
# CameraRig (pivot; rotation.y = yaw)
# └ Arm (SpringArm3D; rotation.x = pitch; casts along its +Z, behind)
#   └ ArmEnd (Node3D; the arm moves it to its end)
#     └ Shoulder (SpringArm3D; a quarter turn about Y, so its +Z is the rig's right)
#       └ ShoulderEnd (Node3D; the shoulder moves it to its end)
#         └ Camera3D (the quarter turn undone: it looks along the view)
class_name CameraRig
extends Node3D

## Where the camera looks, in rad: 0 looks down -Z and a positive turn goes left, the core's
## convention for the yaw (TickInput.yaw).
var yaw := 0.0
## Up and down, in rad: positive looks up. Only the camera tilts, never the body.
var pitch := 0.0
## False for a rig that only follows, as the camera of a bot (BotPlayer): it neither captures the
## mouse nor turns with it, so a player can use another window beside this one (TASK-9, part 2).
var takes_mouse := true
## Degrees per screen pixel of the mouse: camera_v0.tres's at setup(), then the player's, from the
## options, at any moment (F-161; movimento.md, "Câmera").
var sensitivity_deg_per_px := 0.0:
	set(value):
		sensitivity_deg_per_px = value
		_turn_per_pixel = deg_to_rad(value)
## True while a screen over the game holds the mouse, as the options screen does (TASK-10.9): the
## mouse shows, a click does not capture it and a motion does not turn the camera.
var mouse_free := false

## Rotates with the pitch and pulls the camera in when a wall is behind: the first step.
@export var arm: SpringArm3D
## At the arm's end, turned to the shoulder's side: slides the camera toward the centre when a
## wall is beside it, the second step.
@export var shoulder: SpringArm3D
@export var camera: Camera3D

# What the rig follows: the fighter of whoever plays here.
var _target: Node3D
var _pivot_height := 0.0
var _turn_per_pixel := 0.0 # rad per screen pixel
var _max_pitch := 0.0 # rad


# Takes the numbers of movimento.md from the data and starts looking along start_yaw. Called by
# the Match before the rig enters the tree; mouse false makes a rig that only follows.
func setup(data: CameraData, target: Node3D, start_yaw: float, mouse := true) -> void:
	takes_mouse = mouse
	_target = target
	_pivot_height = data.pivot_height_m
	sensitivity_deg_per_px = data.sensitivity_deg_per_px
	_max_pitch = deg_to_rad(data.max_pitch_deg)
	yaw = start_yaw
	pitch = 0.0
	arm.spring_length = data.distance_m
	arm.margin = data.collision_margin_m
	arm.collision_mask = PhysicsLayers.WORLD
	# A quarter turn toward the shoulder's side: +90° about Y points the shoulder's +Z, where a
	# SpringArm3D casts, to the rig's right (+X), and -90° to its left for a negative shoulder_m.
	# The camera turns back by as much, so it looks along the view.
	var quarter := -PI / 2.0 if data.shoulder_m < 0.0 else PI / 2.0
	shoulder.rotation = Vector3(0.0, quarter, 0.0)
	shoulder.spring_length = absf(data.shoulder_m)
	shoulder.margin = data.collision_margin_m
	shoulder.collision_mask = PhysicsLayers.WORLD
	camera.rotation = Vector3(0.0, -quarter, 0.0)
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.fov = data.vertical_fov_deg


func _ready() -> void:
	camera.make_current()
	if takes_mouse:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_follow()


# The rig leaves with its fighter or its match, as when the server closes: the mouse comes back,
# so the player can use the window again.
func _exit_tree() -> void:
	if takes_mouse:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# After netfox's tick loop of the frame, which interpolates the fighter between two ticks
# (TickInterpolator): the camera follows what the screen shows.
func _process(_delta: float) -> void:
	_follow()


# One mouse motion, in screen pixels: right turns right and up looks up. The pitch stops at the
# limit of the data.
func turn(screen_pixels: Vector2) -> void:
	yaw = wrapf(yaw - screen_pixels.x * _turn_per_pixel, -PI, PI)
	pitch = clampf(pitch - screen_pixels.y * _turn_per_pixel, -_max_pitch, _max_pitch)


# A screen over the game takes the mouse: it shows, and the camera stands still (TASK-10.9).
func free_mouse() -> void:
	mouse_free = true
	if takes_mouse:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# The screen over the game gives the mouse back: captured, it turns the camera again.
func take_mouse() -> void:
	mouse_free = false
	if takes_mouse:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# The mouse is captured while playing. The options screen opens and closes with the Esc and holds
# the mouse meanwhile (OptionsScreen); with it closed, a click captures a mouse that got away, as
# after switching windows.
func _unhandled_input(event: InputEvent) -> void:
	if not takes_mouse or mouse_free:
		return
	if _is_left_click(event) and not _is_captured():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _is_captured():
		var motion := event as InputEventMouseMotion
		# screen_relative is in the screen's pixels, unscaled by the 1920 x 1080 base of the
		# interface and by its scale (content_scale_factor), so the degrees per pixel hold at any
		# window size and any scale of the options.
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
