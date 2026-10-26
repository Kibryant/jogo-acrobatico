# Criterion 6 of TASK-9, the camera of movimento.md, "Câmera": 3.5 m behind a pivot 1.6 m above
# the feet, 70° of vertical view, pulled in by a wall in the way, and 0.06° per mouse pixel; the
# pitch stops at 80° (Claude's v0 reading, TASK-9 plan). The yaw it turns is what the body looks
# along. TASK-10.11 puts it over the right shoulder, 0.8 m to the right of the pivot, at its
# height, with the collision in two steps, back and then sideways, both only against the world and
# both stopping 0.3 m before the wall (movimento.md, "Câmera": "Ombro", "Colisão", "Margem da
# colisão"; DEC-0045 §1). Free, the camera looks along the view and its optical axis passes
# through the aim's point O of the same feet and yaw: the test that ties the camera to the core
# (DEC-0045 §2; criteria 1, 2 and 6 of TASK-10.11).
extends GdUnitTestSuite

const CAMERA_RIG_SCENE := preload("res://fighter/camera_rig.tscn")
const CAMERA_V0 := "res://data/camera_v0.tres"
const HAIR := 1e-6
const DEGREE := PI / 180.0
# m: the engine's ray and transforms in 32-bit floats, far below a pixel; not a design number.
const NEAR := 1e-4

# movimento.md, "Câmera".
const DISTANCE_M := 3.5 # "Distância"
const PIVOT_HEIGHT_M := 1.6 # "Altura do pivô"
const SHOULDER_M := 0.8 # "Ombro": to the right
const MARGIN_M := 0.3 # "Margem da colisão"

# The wall behind: a box 2 m behind the pivot, across the arm, its face toward the pivot at 1.9 m.
const BEHIND_CENTRE := Vector3(0, 1.6, 2.0)
const BEHIND_SIZE := Vector3(4, 4, 0.2)
const BEHIND_FACE_Z := 1.9


func _data() -> CameraData:
	var resource: Resource = load(CAMERA_V0)
	assert(resource is CameraData, "%s must load as a CameraData" % CAMERA_V0)
	return resource as CameraData


# A copy of camera_v0.tres with another shoulder: load() caches the resource.
func _data_with_shoulder(shoulder_m: float) -> CameraData:
	var copy: Resource = _data().duplicate()
	assert(copy is CameraData, "a duplicate of %s must still be a CameraData" % CAMERA_V0)
	var data := copy as CameraData
	data.shoulder_m = shoulder_m
	return data


func _rig(target: Node3D, start_yaw := 0.0, data: CameraData = null) -> CameraRig:
	var node: Node = auto_free(CAMERA_RIG_SCENE.instantiate())
	assert(node is CameraRig, "camera_rig.tscn must have a CameraRig at its root")
	var rig := node as CameraRig
	rig.setup(_data() if data == null else data, target, start_yaw)
	return rig


# A box on layer, as a wall of the world or a fighter's body.
func _box(parent: Node3D, layer: int, centre: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = layer
	body.position = centre
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	body.add_child(collision)
	parent.add_child(body)


# The rig in world, following a target at the origin, looking down -Z with no pitch, after the
# frames the bodies take to join the physics space and the two arms take to reach their ends.
func _settled_rig(world: Node3D, data: CameraData = null) -> CameraRig:
	var target := Node3D.new()
	world.add_child(target)
	var rig := _rig(target, 0.0, data)
	world.add_child(rig)
	for _frame: int in 3:
		await get_tree().physics_frame
	return rig


# The view of a yaw and a pitch, the basis the camera must look along: Basis(UP, yaw) turns, and
# Basis(RIGHT, pitch) tilts (TASK-9 plan; Aim.direction).
static func _view(yaw: float, pitch: float) -> Basis:
	return Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)


func _assert_basis(found: Basis, expected: Basis, why: String) -> void:
	for axis: int in 3:
		var message := "%s: axis %d is %s, expected %s" % [why, axis, found[axis], expected[axis]]
		assert_vector(found[axis]).override_failure_message(message).is_equal_approx(
			expected[axis],
			Vector3.ONE * NEAR,
		)


func test_a_mouse_pixel_turns_the_camera_six_hundredths_of_a_degree() -> void:
	var rig := _rig(null)
	rig.turn(Vector2(100, 0))
	assert_float(rig.yaw).is_equal_approx(-6.0 * DEGREE, HAIR) # right turns right: yaw goes down
	rig.turn(Vector2(0, -100))
	assert_float(rig.pitch).is_equal_approx(6.0 * DEGREE, HAIR) # up looks up


func test_the_pitch_stops_at_80_degrees_up_and_down() -> void:
	var rig := _rig(null)
	rig.turn(Vector2(0, -100000))
	assert_float(rig.pitch).is_equal_approx(80.0 * DEGREE, HAIR)
	rig.turn(Vector2(0, 100000))
	assert_float(rig.pitch).is_equal_approx(-80.0 * DEGREE, HAIR)


# The yaw goes all the way around and stays a plain angle, from -180° to 180°.
func test_the_yaw_turns_all_the_way_around() -> void:
	var rig := _rig(null, 0.5)
	rig.turn(Vector2(6000, 0)) # 360°
	assert_float(rig.yaw).is_equal_approx(0.5, 1e-4)
	assert_float(absf(rig.yaw)).is_less_equal(PI)


# Nothing in the way: the pivot 1.6 m above the feet, and the camera 3.5 m behind it and 0.8 m to
# its right, at its height, looking along the view (movimento.md, "Câmera"; DEC-0045 §1).
func test_the_camera_sits_behind_the_pivot_over_the_right_shoulder() -> void:
	var target: Node3D = auto_free(Node3D.new())
	add_child(target)
	target.position = Vector3(2, 0, -3)
	var rig := _rig(target, 0.0)
	add_child(rig)
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_vector(rig.global_position).is_equal_approx(Vector3(2, 1.6, -3), Vector3.ONE * HAIR)
	assert_float(rig.camera.fov).is_equal_approx(70.0, HAIR)
	assert_int(rig.camera.keep_aspect).is_equal(Camera3D.KEEP_HEIGHT)
	assert_float(rig.arm.spring_length).is_equal_approx(DISTANCE_M, HAIR)
	assert_float(rig.shoulder.spring_length).is_equal_approx(SHOULDER_M, HAIR)
	assert_float(rig.arm.margin).is_equal_approx(MARGIN_M, HAIR)
	assert_float(rig.shoulder.margin).is_equal_approx(MARGIN_M, HAIR)
	assert_int(rig.arm.collision_mask).is_equal(PhysicsLayers.WORLD)
	assert_int(rig.shoulder.collision_mask).is_equal(PhysicsLayers.WORLD)
	var behind := rig.camera.global_position - rig.global_position
	assert_vector(behind).is_equal_approx(Vector3(SHOULDER_M, 0, DISTANCE_M), Vector3.ONE * NEAR)
	_assert_basis(rig.camera.global_basis, Basis.IDENTITY, "the camera looks down -Z")


# Criteria 1 and 2 of TASK-10.11: for any yaw and pitch, with nothing in the way, the camera
# looks along the view basis, sits at (0.8, 0, 3.5) in it from the pivot, and its optical axis,
# 3.5 m ahead, reaches the point O the core computes for the same feet and yaw: the line of the
# screen's centre is the aim's ray (DEC-0045 §2; Aim.origin).
func test_the_free_cameras_optical_axis_passes_through_the_point_o(
	yaw_deg: float,
	pitch_deg: float,
	_test_parameters := [[0.0, 0.0], [37.0, 12.5], [-120.0, -60.0], [180.0, 80.0], [90.0, -80.0]],
) -> void:
	var target: Node3D = auto_free(Node3D.new())
	add_child(target)
	target.position = Vector3(2, 0.5, -3)
	var yaw := yaw_deg * DEGREE
	var pitch := pitch_deg * DEGREE
	var rig := _rig(target, yaw)
	rig.pitch = pitch
	add_child(rig)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var view := _view(yaw, pitch)
	var camera := rig.camera
	var why := "yaw %.1f°, pitch %.1f°" % [yaw_deg, pitch_deg]
	_assert_basis(camera.global_basis, view, why)
	var pivot := target.position + Vector3.UP * PIVOT_HEIGHT_M
	var expected_camera := pivot + view * Vector3(SHOULDER_M, 0, DISTANCE_M)
	assert_vector(camera.global_position).override_failure_message(why).is_equal_approx(
		expected_camera,
		Vector3.ONE * NEAR,
	)
	var on_the_axis := camera.global_position + camera.global_basis * Vector3(0, 0, -DISTANCE_M)
	var origin := Aim.origin(target.position, yaw, PIVOT_HEIGHT_M, SHOULDER_M)
	var message := "%s: the axis reaches %s, O is %s" % [why, on_the_axis, origin]
	assert_vector(on_the_axis).override_failure_message(message).is_equal_approx(
		origin,
		Vector3.ONE * NEAR,
	)
	# And the ray of the aim leaves O along the camera's forward.
	var forward := -camera.global_basis.z
	assert_vector(forward).override_failure_message(why).is_equal_approx(
		Aim.direction(yaw, pitch),
		Vector3.ONE * NEAR,
	)


# A negative shoulder is the left one (movimento.md, "Câmera": "Ombro": "Com sinal"): the camera
# sits 0.8 m to the left, still looking along the view, and its axis passes through the left O.
func test_a_negative_shoulder_puts_the_camera_over_the_left_shoulder() -> void:
	var target: Node3D = auto_free(Node3D.new())
	add_child(target)
	var yaw := 30.0 * DEGREE
	var rig := _rig(target, yaw, _data_with_shoulder(-SHOULDER_M))
	add_child(rig)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var view := _view(yaw, 0.0)
	_assert_basis(rig.camera.global_basis, view, "the left shoulder")
	assert_float(rig.shoulder.spring_length).is_equal_approx(SHOULDER_M, HAIR)
	var pivot := Vector3.UP * PIVOT_HEIGHT_M
	assert_vector(rig.camera.global_position).is_equal_approx(
		pivot + view * Vector3(-SHOULDER_M, 0, DISTANCE_M),
		Vector3.ONE * NEAR,
	)
	var on_the_axis := rig.camera.global_position + view * Vector3(0, 0, -DISTANCE_M)
	assert_vector(on_the_axis).is_equal_approx(
		Aim.origin(Vector3.ZERO, yaw, PIVOT_HEIGHT_M, -SHOULDER_M),
		Vector3.ONE * NEAR,
	)


# The first step: a wall between the pivot and the camera pulls the camera in, and it stops 0.3 m
# before the wall, still over the shoulder; a fighter there does not (PhysicsLayers).
func test_a_wall_behind_pulls_the_camera_in_to_0_3_m_before_it_and_a_fighter_does_not(
	layer: int,
	pulls_in: bool,
	_test_parameters := [[PhysicsLayers.WORLD, true], [PhysicsLayers.FIGHTERS, false]],
) -> void:
	var world: Node3D = auto_free(Node3D.new())
	add_child(world)
	_box(world, layer, BEHIND_CENTRE, BEHIND_SIZE)
	var rig := await _settled_rig(world)
	var behind := rig.camera.global_position - rig.global_position
	if pulls_in:
		var stop := BEHIND_FACE_Z - MARGIN_M
		assert_vector(behind).is_equal_approx(Vector3(SHOULDER_M, 0, stop), Vector3.ONE * NEAR)
		assert_float(BEHIND_FACE_Z - rig.camera.global_position.z).is_equal_approx(MARGIN_M, NEAR)
	else:
		assert_vector(behind).is_equal_approx(
			Vector3(SHOULDER_M, 0, DISTANCE_M),
			Vector3.ONE * NEAR,
		)


# The second step (criterion 6 of TASK-10.11): a wall to the right of the body, along the view, as
# in a wall run with the wall on the right, leaves the arm free, so the camera stays 3.5 m back,
# and pushes the shoulder in: the camera stops 0.3 m before that wall, sliding toward the centre,
# 0.05 m right of it for a wall 0.35 m away. A wall farther than the shoulder's 0.8 m pushes
# nothing, and neither does a fighter.
func test_a_wall_to_the_right_slides_the_shoulder_toward_the_centre(
	layer: int,
	face_x: float,
	camera_x: float,
	_test_parameters := [
		[PhysicsLayers.WORLD, 0.35, 0.05],
		[PhysicsLayers.WORLD, 0.6, 0.3],
		[PhysicsLayers.WORLD, 1.5, SHOULDER_M],
		[PhysicsLayers.FIGHTERS, 0.35, SHOULDER_M],
	],
) -> void:
	var world: Node3D = auto_free(Node3D.new())
	add_child(world)
	_box(world, layer, Vector3(face_x + 0.5, 1.6, 0), Vector3(1, 4, 20))
	var rig := await _settled_rig(world)
	var behind := rig.camera.global_position - rig.global_position
	var message := "a wall at x = %.2f left the camera at %s" % [face_x, behind]
	assert_vector(behind).override_failure_message(message).is_equal_approx(
		Vector3(camera_x, 0, DISTANCE_M),
		Vector3.ONE * NEAR,
	)
	_assert_basis(rig.camera.global_basis, Basis.IDENTITY, "pushed, it still looks down -Z")
	if layer == PhysicsLayers.WORLD and face_x < SHOULDER_M:
		assert_float(face_x - rig.camera.global_position.x).is_equal_approx(MARGIN_M, NEAR)
