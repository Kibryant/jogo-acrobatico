# Criterion 6 of TASK-9, the camera of movimento.md, "Câmera": 3.5 m behind a pivot 1.6 m above
# the feet, centred, 70° of vertical view, pulled in by a wall in the way, and 0.06° per mouse
# pixel; the pitch stops at 80° (Claude's v0 reading, TASK-9 plan). The yaw it turns is what the
# body looks along.
extends GdUnitTestSuite

const CAMERA_RIG_SCENE := preload("res://fighter/camera_rig.tscn")
const CAMERA_V0 := "res://data/camera_v0.tres"
const HAIR := 1e-6
const DEGREE := PI / 180.0


func _data() -> CameraData:
	var resource: Resource = load(CAMERA_V0)
	assert(resource is CameraData, "%s must load as a CameraData" % CAMERA_V0)
	return resource as CameraData


func _rig(target: Node3D, start_yaw := 0.0) -> CameraRig:
	var node: Node = auto_free(CAMERA_RIG_SCENE.instantiate())
	assert(node is CameraRig, "camera_rig.tscn must have a CameraRig at its root")
	var rig := node as CameraRig
	rig.setup(_data(), target, start_yaw)
	return rig


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


func test_the_camera_sits_behind_the_pivot_with_the_numbers_of_movimento_md() -> void:
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
	assert_float(rig.arm.spring_length).is_equal_approx(3.5, HAIR)
	# Nothing in the way: the camera is 3.5 m behind the pivot, centred, looking at it.
	var behind := rig.camera.global_position - rig.global_position
	assert_vector(behind).is_equal_approx(Vector3(0, 0, 3.5), Vector3.ONE * 1e-3)


# A wall between the pivot and the camera pulls it in; a fighter there does not (PhysicsLayers).
func test_a_wall_in_the_way_pulls_the_camera_in_and_a_fighter_does_not(
	layer: int,
	pulls_in: bool,
	_test_parameters := [[PhysicsLayers.WORLD, true], [PhysicsLayers.FIGHTERS, false]],
) -> void:
	var world: Node3D = auto_free(Node3D.new())
	add_child(world)
	var obstacle := StaticBody3D.new()
	obstacle.collision_layer = layer
	obstacle.position = Vector3(0, 1.6, 2.0) # 2 m behind the pivot, across the arm
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 4, 0.2)
	collision.shape = box
	obstacle.add_child(collision)
	world.add_child(obstacle)
	var target := Node3D.new()
	world.add_child(target)
	var rig := _rig(target, 0.0)
	world.add_child(rig)
	for _frame: int in 3:
		await get_tree().physics_frame
	var distance := rig.camera.global_position.distance_to(rig.global_position)
	if pulls_in:
		assert_float(distance).is_less(2.0)
	else:
		assert_float(distance).is_equal_approx(3.5, 1e-3)
