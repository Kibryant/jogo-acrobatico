# Criteria 2 and 5 of TASK-10.11, the adapter's half of the aim (DEC-0045 §2 and §3; movimento.md,
# "Gancho": "De onde sai a mira", "A quina"): Fighter.aim_ray casts the first ray from the point
# O, the feet plus 1,6 m up plus 0,8 m to the right of the yaw, along Aim.direction, and, when it
# finds the world, a second ray from the shoulder, 1,6 m above the feet, to the point. A point the
# shoulder does not see, a corner between the body and it, is no point: the aim finds nothing.
# Both rays ask only the world, so a fighter in the way blocks neither. A fighter of fighter.tscn,
# with the game's numbers, stands in a room built here: four walls 15 m off, a fin of the test's
# own between the shoulder and the point for the corner. The geometry is the test's own, so the
# arena never changes what this proves. TASK-12.15 adds the centered camera's numbers,
# movement_center.tres: the first ray leaves O on the body's axis, 2,2 m above the feet, and the
# second still leaves the body's shoulder, 1,6 m up, without the camera's rise (movimento.md,
# "Gancho": "De onde sai a mira", "A quina"; criterion 2 of TASK-12.15).
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const FIGHTER_SCENE := preload("res://fighter/fighter.tscn")
const MOVEMENT_V0 := "res://data/movement_v0.tres"
const MOVEMENT_CENTER := "res://data/movement_center.tres"

# movimento.md, "Gancho": "De onde sai a mira": O is 1,6 m above the feet and 0,8 m to the right
# of the yaw ("Câmera": "Altura do pivô", "Ombro").
const AIM_HEIGHT_M := 1.6
const AIM_SIDE_M := 0.8
# m: the engine's ray in 32-bit floats; not a design number.
const NEAR := 1e-4

# The room: the feet in the air at FEET, and a wall 15 m off in each of the four directions, 40 m
# wide and 20 m tall, its face toward the feet. The geometry of the test, not design numbers.
const FEET := Vector3(0.0, 1.0, 0.0)
const ROOM_HALF := 15.0
const WALL_SIZE := Vector3(40.0, 20.0, 1.0)
# The fin of the corner, looking along X, from x = 0,3 to 0,4 and from z = -12 to -1, as tall as
# the room: the first ray, at yaw 0, runs from O at x = 0,8 to the north wall and never meets it;
# the shoulder's ray, from x = 0 to the point at x = 0,8, z = -15, crosses x = 0,3 at z = -5,6.
const FIN_CENTRE := Vector3(0.35, 1.0, -6.5)
const FIN_SIZE := Vector3(0.1, 20.0, 11.0)
# movimento.md, "Câmera": "Subida": the centered camera's O, 2,2 m above the feet, on the axis.
const CENTER_O_HEIGHT_M := 2.2
# The ledge of the centered corner, from z = -10 to -5 and up to y = 3,1: the first ray, level at
# y = 3,2 from the raised O to the north wall, passes over it; the shoulder's ray, from y = 2,6 to
# the point at y = 3,2, z = -15, is at y = 2,8 when it reaches the ledge at z = -5.
const LEDGE_CENTRE := Vector3(0.0, 2.5, -7.5)
const LEDGE_SIZE := Vector3(4.0, 1.2, 5.0)


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	NetfoxTicks.reset()


func _config(path := MOVEMENT_V0) -> MovementConfig:
	var resource: Resource = load(path)
	assert(resource is MovementData, "%s must load as a MovementData" % path)
	return MovementConfig.create(resource as MovementData, NetworkTime.tickrate)


func _box(parent: Node3D, layer: int, centre: Vector3, size: Vector3, box_name: String) -> void:
	var body := StaticBody3D.new()
	body.name = box_name
	body.collision_layer = layer
	body.position = centre
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)


# The room with a fighter at FEET, with the numbers of path, once the bodies joined the physics
# space.
func _room(path := MOVEMENT_V0) -> Fighter:
	var world: Node3D = auto_free(Node3D.new())
	add_child(world)
	var away := ROOM_HALF + WALL_SIZE.z / 2.0
	var across := Vector3(WALL_SIZE.z, WALL_SIZE.y, WALL_SIZE.x)
	_box(world, PhysicsLayers.WORLD, Vector3(0.0, 1.0, -away), WALL_SIZE, "North")
	_box(world, PhysicsLayers.WORLD, Vector3(0.0, 1.0, away), WALL_SIZE, "South")
	_box(world, PhysicsLayers.WORLD, Vector3(-away, 1.0, 0.0), across, "West")
	_box(world, PhysicsLayers.WORLD, Vector3(away, 1.0, 0.0), across, "East")
	var node := FIGHTER_SCENE.instantiate()
	assert(node is Fighter, "fighter.tscn must have a Fighter at its root")
	var fighter := node as Fighter
	fighter.setup(_config(path), FEET, 0.0, true)
	world.add_child(fighter)
	await get_tree().process_frame
	await get_tree().physics_frame
	return fighter


# A raw ray of the world, to prove what each of the two rays alone would find.
static func _raw(fighter: Fighter, from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(
		from,
		to,
		PhysicsLayers.WORLD,
		[fighter.get_rid()],
	)
	return fighter.get_world_3d().direct_space_state.intersect_ray(query)


static func _name_of(hit: Dictionary) -> String:
	var collider: Object = hit["collider"]
	assert(collider is Node, "every collider of the room is a node")
	return str((collider as Node).name)


# One: a clean hit. For every yaw the ray leaves O, 0,8 m to the right of the shoulder and at its
# height, and finds the wall ahead on its own line: the point is on the ray from O, 0,8 m to the
# right of the shoulder's line along the aim, and as far ahead of O as the wall is.
func test_a_clean_hit_lies_on_the_ray_from_o_0_8_m_right_of_the_shoulder(
	yaw_deg: float,
	wall: String,
	_test_parameters := [[0.0, "North"], [90.0, "West"], [180.0, "South"], [-90.0, "East"]],
) -> void:
	var fighter := await _room()
	var yaw := deg_to_rad(yaw_deg)
	var hit := fighter.aim_ray(fighter.global_position, yaw, 0.0)
	assert_bool(hit.is_empty()).override_failure_message("yaw %.0f° found nothing" % yaw_deg) \
			.is_false()
	if hit.is_empty():
		return
	assert_str(_name_of(hit)).is_equal(wall)
	var point: Vector3 = hit["position"]
	var shoulder := FEET + Vector3.UP * AIM_HEIGHT_M
	var origin := Aim.origin(FEET, yaw, AIM_HEIGHT_M, AIM_SIDE_M)
	var forward := Aim.direction(yaw, 0.0)
	var right := forward.cross(Vector3.UP)
	assert_vector(origin - shoulder).is_equal_approx(right * AIM_SIDE_M, Vector3.ONE * NEAR)
	var message := "yaw %.0f°: the point %s, O %s" % [yaw_deg, point, origin]
	assert_vector(point).override_failure_message(message).is_equal_approx(
		origin + forward * ROOM_HALF,
		Vector3.ONE * NEAR,
	)
	assert_float((point - shoulder).dot(right)).override_failure_message(message) \
			.is_equal_approx(AIM_SIDE_M, NEAR)


# None: the ray at the sky, 80° up, the camera's limit, finds nothing within the 25 m.
func test_a_ray_at_the_sky_finds_nothing() -> void:
	var fighter := await _room()
	var hit := fighter.aim_ray(fighter.global_position, 0.0, deg_to_rad(80.0))
	assert_bool(hit.is_empty()).override_failure_message("the sky found %s" % [hit]).is_true()


# Criterion 5 of TASK-10.11, the corner: a fin between the shoulder and the point, outside the
# first ray's path. Alone, the first ray finds the north wall and the shoulder's ray stops at the
# fin, far before the point, so the aim finds nothing. A fighter's body there, off the world's
# mask, blocks nothing, and the aim finds the wall.
func test_a_corner_between_the_shoulder_and_the_point_refuses_it(
	fin_layer: int,
	refused: bool,
	_test_parameters := [[PhysicsLayers.WORLD, true], [PhysicsLayers.FIGHTERS, false]],
) -> void:
	var fighter := await _room()
	var parent := fighter.get_parent()
	assert(parent is Node3D, "the room is a Node3D")
	_box(parent as Node3D, fin_layer, FIN_CENTRE, FIN_SIZE, "Fin")
	await get_tree().physics_frame
	var origin := Aim.origin(FEET, 0.0, AIM_HEIGHT_M, AIM_SIDE_M)
	var first := _raw(fighter, origin, origin + Aim.direction(0.0, 0.0) * 25.0)
	assert_bool(first.is_empty()).override_failure_message("the first ray found nothing") \
			.is_false()
	if first.is_empty():
		return
	assert_str(_name_of(first)).is_equal("North")
	var point: Vector3 = first["position"]
	var sight := _raw(fighter, FEET + Vector3.UP * AIM_HEIGHT_M, point)
	var hit := fighter.aim_ray(fighter.global_position, 0.0, 0.0)
	if refused:
		assert_bool(sight.is_empty()).override_failure_message("the fin hid nothing").is_false()
		if not sight.is_empty():
			assert_str(_name_of(sight)).is_equal("Fin")
			var stop: Vector3 = sight["position"]
			assert_float(stop.distance_to(point)).is_greater(Fighter.SIGHT_TOLERANCE)
		assert_bool(hit.is_empty()).override_failure_message("the corner was not refused") \
				.is_true()
	else:
		assert_bool(hit.is_empty()).override_failure_message("a fighter blocked the aim") \
				.is_false()
		if not hit.is_empty():
			assert_str(_name_of(hit)).is_equal("North")
			var found: Vector3 = hit["position"]
			assert_vector(found).is_equal_approx(point, Vector3.ONE * NEAR)


# Criterion 2 of TASK-12.15: with the centered camera's numbers the first ray leaves O on the body's
# axis, 2,2 m above the feet, for every yaw: the point is straight ahead of it, level with it, as
# far as the wall, with nothing to the side.
func test_the_centered_first_ray_leaves_o_on_the_bodys_axis_2_2_m_up(
	yaw_deg: float,
	wall: String,
	_test_parameters := [[0.0, "North"], [90.0, "West"], [180.0, "South"], [-90.0, "East"]],
) -> void:
	var fighter := await _room(MOVEMENT_CENTER)
	var yaw := deg_to_rad(yaw_deg)
	var hit := fighter.aim_ray(fighter.global_position, yaw, 0.0)
	assert_bool(hit.is_empty()).override_failure_message("yaw %.0f° found nothing" % yaw_deg) \
			.is_false()
	if hit.is_empty():
		return
	assert_str(_name_of(hit)).is_equal(wall)
	var point: Vector3 = hit["position"]
	var origin := FEET + Vector3.UP * CENTER_O_HEIGHT_M
	assert_vector(Movement.aim_origin(FEET, yaw, fighter.config)).is_equal_approx(
		origin,
		Vector3.ONE * NEAR,
	)
	var message := "yaw %.0f°: the point %s, O %s" % [yaw_deg, point, origin]
	assert_vector(point).override_failure_message(message).is_equal_approx(
		origin + Aim.direction(yaw, 0.0) * ROOM_HALF,
		Vector3.ONE * NEAR,
	)


# Criterion 2 of TASK-12.15, the corner: the second ray still leaves the body's shoulder, 1,6 m
# above the feet, not the raised O. A ledge below the first ray, level at 2,2 m, cuts the line
# from the shoulder to the point: the first ray alone finds the north wall, a ray from O to the
# point passes over the ledge, and the shoulder's ray stops on it, so the aim finds nothing.
func test_the_centered_second_ray_leaves_the_bodys_shoulder_not_the_raised_o() -> void:
	var fighter := await _room(MOVEMENT_CENTER)
	var parent := fighter.get_parent()
	assert(parent is Node3D, "the room is a Node3D")
	_box(parent as Node3D, PhysicsLayers.WORLD, LEDGE_CENTRE, LEDGE_SIZE, "Ledge")
	await get_tree().physics_frame
	var origin := FEET + Vector3.UP * CENTER_O_HEIGHT_M
	var first := _raw(fighter, origin, origin + Aim.direction(0.0, 0.0) * 25.0)
	assert_bool(first.is_empty()).override_failure_message("the first ray found nothing") \
			.is_false()
	if first.is_empty():
		return
	assert_str(_name_of(first)).is_equal("North")
	var point: Vector3 = first["position"]
	var from_o := _raw(fighter, origin, point)
	if not from_o.is_empty():
		var reached: Vector3 = from_o["position"]
		assert_float(reached.distance_to(point)).override_failure_message("O does not see it") \
				.is_less_equal(Fighter.SIGHT_TOLERANCE)
	var sight := _raw(fighter, FEET + Vector3.UP * AIM_HEIGHT_M, point)
	assert_bool(sight.is_empty()).override_failure_message("the ledge hid nothing").is_false()
	if not sight.is_empty():
		assert_str(_name_of(sight)).is_equal("Ledge")
	var hit := fighter.aim_ray(fighter.global_position, 0.0, 0.0)
	assert_bool(hit.is_empty()).override_failure_message("the ledge was not refused: %s" % [hit]) \
			.is_true()
