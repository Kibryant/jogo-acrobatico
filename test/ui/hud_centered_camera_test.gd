# Criteria 1 and 2 of TASK-12.15, the screen's half: in a match given the centered camera,
# camera_center.tres, and the movement numbers whose point O rises with it, movement_center.tres
# (movimento.md, "Câmera": "Subida"), the reticle's ray leaves the displayed body's O, on its axis
# 2,2 m above the feet, and with the camera free the ring sits at the screen's centre, on the point
# the ray finds, with its dot (visual-e-audio.md, "O gancho na tela"). The geometry is
# test/ui/hud_test.gd's: a wall of the test's own in the arena's empty south-east. The tests run
# headless, as the gate does, and drive the HUD by hand with the tick they choose.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const MATCH_SCENE := preload("res://match/match.tscn")
const AimAt := preload("res://test/support/aim_at.gd")

const CAMERA_CENTER := "res://data/camera_center.tres"
const MOVEMENT_CENTER := "res://data/movement_center.tres"
## Any tick far from the start of netfox's clock.
const SPENT_AT := 5000
# movimento.md, "Câmera": "Subida": the centered camera's O, 2,2 m above the feet, on the axis.
const CENTER_O_HEIGHT_M := 2.2
## m: the engine's transforms in 32-bit floats; not a design number.
const NEAR := 1e-4
## px at the base: the ring's centre is within a pixel of where it should be.
const PIXEL := 1.0
# The target (test/ui/hud_test.gd): its face looks south at z = 12, and the fighter stands 12 m
# south of it, within the 3 to 25 m of O.
const TARGET_FACE_Z := 12.0
const TARGET_POINT := Vector3(28, 4, 12)
const BEFORE_THE_TARGET := Vector3(28, 0, 24)

var _match: Match
var _fighter: Fighter


func before_test() -> void:
	NetfoxTicks.reset()
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	_match = auto_free(node)
	var movement: Resource = load(MOVEMENT_CENTER)
	assert(movement is MovementData, "%s must load as a MovementData" % MOVEMENT_CENTER)
	_match.movement_data = movement as MovementData
	var camera: Resource = load(CAMERA_CENTER)
	assert(camera is CameraData, "%s must load as a CameraData" % CAMERA_CENTER)
	_match.camera_data = camera as CameraData
	add_child(_match)
	_fighter = _match.spawn_fighter(0, multiplayer.get_unique_id())


func after_test() -> void:
	NetfoxTicks.reset()


func _add_target() -> void:
	var wall := StaticBody3D.new()
	wall.name = "AlvoDaMira"
	wall.position = Vector3(TARGET_POINT.x, 5, TARGET_FACE_Z - 0.5)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(16, 10, 1)
	collision.shape = box
	wall.add_child(collision)
	_match.arena.add_child(wall)


# The camera follows the aim: the rig turns in its _process and the two arms reach their ends in
# the physics step that comes after.
func _settle() -> void:
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame


func _ring_centre(hud: Hud) -> Vector2:
	var node := hud.get_node(^"Reticle")
	assert(node is Control, "the reticle is a Control")
	var ring := node as Control
	return ring.position + ring.size / 2.0


func _assert_near(found: Vector2, expected: Vector2, why: String) -> void:
	var message := "%s: the ring at %s, expected %s" % [why, found, expected]
	assert_float(found.distance_to(expected)).override_failure_message(message).is_less_equal(PIXEL)


# The match took the centered numbers: no shoulder and the rise in both, and its O on the body's
# axis 2,2 m above the feet.
func test_the_match_plays_with_the_centered_camera_and_its_raised_o() -> void:
	assert_float(_match.camera_data.shoulder_m).is_equal(0.0)
	assert_float(_match.camera_data.rise_m).is_equal(_match.config.aim_rise)
	assert_float(_match.config.aim_side).is_equal(0.0)
	var feet := BEFORE_THE_TARGET
	assert_vector(Movement.aim_origin(feet, 0.7, _match.config)).is_equal_approx(
		feet + Vector3.UP * CENTER_O_HEIGHT_M,
		Vector3.ONE * NEAR,
	)


# Criterion 2 of TASK-12.15: with the centered camera free, the ring sits at the screen's centre,
# within a pixel, on the point the ray from the raised O finds, and its dot says the Q would hook;
# at the sky, with no point, it stays at the centre, on the end of the ray from the raised O.
func test_with_the_centered_camera_the_ring_sits_at_the_screens_centre_on_the_rays_point() -> void:
	_add_target()
	_fighter.position = BEFORE_THE_TARGET
	var camera := _match.watch(_fighter)
	await get_tree().physics_frame
	var hud: Hud = auto_free(Hud.new())
	add_child(hud)
	hud.follow(_fighter, _match.config, camera)
	var feet := _fighter.global_position
	camera.yaw = AimAt.yaw_to(feet, TARGET_POINT, _match.config)
	camera.pitch = AimAt.pitch_to(feet, TARGET_POINT, _match.config)
	await _settle()
	hud.show_at(SPENT_AT)
	assert_bool(hud.shows_reticle_dot()).override_failure_message("aimed at the wall").is_true()
	var hit := _fighter.aim_ray(feet, camera.yaw, camera.pitch)
	assert_bool(hit.is_empty()).override_failure_message("the ray found nothing").is_false()
	if not hit.is_empty():
		var point: Vector3 = hit["position"]
		assert_vector(point).is_equal_approx(TARGET_POINT, Vector3.ONE * 1e-3)
	var ring := _ring_centre(hud)
	var centre := hud.get_viewport().get_visible_rect().size / 2.0
	_assert_near(ring, centre, "the centered camera free")
	_assert_near(ring, camera.camera.unproject_position(TARGET_POINT), "the ray's point")
	# At the sky the ray finds nothing, and the ring sits on the end of the 25 m from the raised O,
	# still the screen's centre, with no dot.
	camera.pitch = deg_to_rad(80.0)
	await _settle()
	hud.show_at(SPENT_AT)
	assert_bool(hud.shows_reticle_dot()).override_failure_message("aimed at the sky").is_false()
	assert_bool(_fighter.aim_ray(feet, camera.yaw, camera.pitch).is_empty()).is_true()
	_assert_near(_ring_centre(hud), centre, "the centered camera at the sky")
