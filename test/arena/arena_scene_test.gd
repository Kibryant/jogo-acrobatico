# Criterion 4 of TASK-10.2: the two platforms of the 6 m gap (movimento.md, "Métricas de nível"),
# 6 x 2 x 6 m with their tops at 2 m (F-109), stand on free floor of the arena: unique names
# under Arena, on the world's physics layer, a collision box equal to the mesh, and clear of the
# other bodies, of the reference route and of the SyncTest's scenarios, so neither the reference
# nor the SyncTest meets them. From TASK-10.4 (criterion 7), the dash's ruler: strips every 4 m,
# only seen, on free floor too. From TASK-10.5 (criterion 8), the wall run's pieces: the long wall,
# the corridor's two walls 3.5 m apart and the 3 m landing at the corridor's end (movimento.md,
# "Métricas de nível"), on free floor too, the wall scenario of the SyncTest's included.
extends GdUnitTestSuite

const ARENA_SCENE := preload("res://arena/arena.tscn")
const ReferenceRun := preload("res://test/reference/reference_run.gd")

## Where each platform's centre stands (TASK-10.2, "Números v0 do Claude").
const GAP_PLATFORMS: Dictionary[String, Vector3] = {
	"PlataformaVaoA": Vector3(-20, 1, 6),
	"PlataformaVaoB": Vector3(-20, 1, -6),
}
## m: each platform's box, and its top: 2 m, so a fall into the gap costs the climb back by the
## double jump (TASK-10.2; F-109).
const PLATFORM_SIZE := Vector3(6, 2, 6)
const PLATFORM_TOP := 2.0
## m: the gap between them, along z: above the ≈ 4.4 m of the jump and the coyote, below the
## ≈ 7 m of the double jump (movimento.md, "Métricas de nível").
const GAP := 6.0
## The 1 m block, whose grey the platforms share (arena.tscn).
const GREY_BLOCK := "Block1m"
## m: a fighter's feet are its centre, and its body reaches this far around them (movimento.md,
## "O corpo": the capsule's 0.35 m radius).
const BODY_RADIUS := 0.35

## The ground the reference route covers, on the floor plane: x across, z down. Its stored trace,
## route.trace (rastro 3a877934…, TASK-10.4, with the floor snap of the dash), puts the fighter's
## feet between x -7.27 and 4.88 and z -11.53 and 9.97; grown by 1 m and rounded out to whole
## meters, x -9..6 and z -13..11. The test below proves the stored trace still fits in it.
const REFERENCE_ROUTE_AREA := Rect2(Vector2(-9, -13), Vector2(15, 24))
## The ground the scenarios of the SyncTest cover (test/fighter/fighter_sync_test.gd), on the
## floor plane. Measured on 2026-10-19 over every fighter of every scenario on every tick: the
## feet between x -8.76 (empurrão) and 9.10 (rampa) and z -11.51 (pulo duplo, on Block2m) and
## 5.99 (empurrão); grown by 1 m and rounded out to whole meters, x -10..11 and z -13..7. The
## dash's scenario (TASK-10.4), measured on 2026-10-23, stays inside: x -8.23 to 9.03 and z -9.65
## to 1.5.
const SYNC_TEST_AREA := Rect2(Vector2(-10, -13), Vector2(21, 20))
## The ground of the SyncTest's wall scenario, parede (TASK-10.5), which builds its own walls in
## the north-west corner: walls over x -38 to -26.5 and z 13 to 39, the fighters' feet between
## them; grown by 1 m, x -39..-25 and z 12..40.
const PAREDE_SCENARIO_AREA := Rect2(Vector2(-39, 12), Vector2(14, 28))
const HAIR := 1e-4

## The dash's ruler (TASK-10.4, "Arena"): a strip every 4 m, the dash's distance (movimento.md,
## "Dash"), along x from -10 to 30, each 0.1 m across x, 0.01 m tall and 2 m along z, centred
## at y 0.01 and z 15, so it covers z 14..16.
const RULER := "RéguaDoDash"
const RULER_FROM_X := -10.0
const RULER_TO_X := 30.0
const RULER_STEP_M := 4.0
const RULER_STRIP := Vector3(0.1, 0.01, 2)
const RULER_Y := 0.01
const RULER_Z := 15.0

## The wall run's pieces (TASK-10.5, "Arena"; movimento.md, "Métricas de nível"), each one
## collider: where its centre stands and its box. The long wall is 24 m, more than the ≈ 20 m of a
## run (2.5 s at 8 m/s); the corridor's walls are 5 m tall, 24 m long and 3.5 m apart inside; the
## landing is 3 m tall, as wide as the corridor's gap, right past its south end.
const WALL_PIECES: Dictionary[String, Vector3] = {
	"ParedeLonga": Vector3(14.5, 2, -8),
	"CorredorOeste": Vector3(22.5, 2.5, -8),
	"CorredorLeste": Vector3(27, 2.5, -8),
	"PatamarDoCorredor": Vector3(24.75, 1.5, -22),
}
const WALL_PIECE_SIZES: Dictionary[String, Vector3] = {
	"ParedeLonga": Vector3(1, 4, 24),
	"CorredorOeste": Vector3(1, 5, 24),
	"CorredorLeste": Vector3(1, 5, 24),
	"PatamarDoCorredor": Vector3(3.5, 3, 4),
}
## m: a run of 2.5 s at 8 m/s (movimento.md, "Corrida na parede"), which the long wall outlasts.
const WALL_RUN_LENGTH := 20.0
const CORRIDOR_GAP := 3.5
const LANDING_TOP := 3.0


func _arena() -> Arena:
	var node := ARENA_SCENE.instantiate()
	assert(node is Arena, "arena.tscn must have an Arena at its root")
	var arena: Arena = auto_free(node)
	add_child(arena)
	return arena


func _body(arena: Arena, body_name: String) -> StaticBody3D:
	var node := arena.get_node_or_null(NodePath(body_name))
	assert_object(node).override_failure_message("no %s under Arena" % body_name).is_not_null()
	assert_bool(node is StaticBody3D) \
			.override_failure_message("%s is not a StaticBody3D" % body_name) \
			.is_true()
	return node as StaticBody3D


# The box of body's collision in the arena's space; the arena stands at the origin.
func _box(body: StaticBody3D) -> AABB:
	var collision := body.get_node(^"Collision")
	assert(collision is CollisionShape3D, "%s/Collision is a CollisionShape3D" % body.name)
	var shape := (collision as CollisionShape3D).shape
	assert(shape is BoxShape3D, "%s/Collision is a box" % body.name)
	var size := (shape as BoxShape3D).size
	var transform := (collision as CollisionShape3D).global_transform
	return transform * AABB(-size / 2, size)


# A box seen from above, on the floor plane: x across, z down.
static func _footprint(box: AABB) -> Rect2:
	return Rect2(Vector2(box.position.x, box.position.z), Vector2(box.size.x, box.size.z))


func test_each_gap_platform_has_a_unique_name_under_the_arena() -> void:
	var arena := _arena()
	for platform_name: String in GAP_PLATFORMS:
		var found := arena.find_children(platform_name, "", true, false)
		var failure := "%s is named %d times under Arena" % [platform_name, found.size()]
		assert_int(found.size()).override_failure_message(failure).is_equal(1)
		assert_object(_body(arena, platform_name).get_parent()).is_same(arena)


func test_each_gap_platform_is_a_world_box_whose_collision_matches_its_mesh() -> void:
	var arena := _arena()
	var grey := _grey_of(_body(arena, GREY_BLOCK))
	for platform_name: String in GAP_PLATFORMS:
		var body := _body(arena, platform_name)
		assert_int(body.collision_layer).is_equal(PhysicsLayers.WORLD)
		assert_vector(body.position).is_equal_approx(
			GAP_PLATFORMS[platform_name],
			Vector3.ONE * HAIR,
		)
		assert_bool(body.basis.is_equal_approx(Basis.IDENTITY)).is_true()

		var collision := body.get_node(^"Collision")
		assert_bool(collision is CollisionShape3D).is_true()
		var shape := (collision as CollisionShape3D).shape
		assert_bool(shape is BoxShape3D).is_true()
		assert_vector((shape as BoxShape3D).size).is_equal(PLATFORM_SIZE)
		var mesh_node := body.get_node(^"Mesh")
		assert_bool(mesh_node is MeshInstance3D).is_true()
		var mesh := (mesh_node as MeshInstance3D).mesh
		assert_bool(mesh is BoxMesh).is_true()
		assert_vector((mesh as BoxMesh).size).is_equal(PLATFORM_SIZE)
		# The box and the mesh sit at the body's centre, so what is seen is what collides.
		var collision_at := (collision as CollisionShape3D).transform
		var mesh_at := (mesh_node as MeshInstance3D).transform
		assert_bool(collision_at.is_equal_approx(Transform3D.IDENTITY)).is_true()
		assert_bool(mesh_at.is_equal_approx(Transform3D.IDENTITY)).is_true()
		assert_object(_grey_of(body)).is_same(grey)


func test_the_two_platforms_open_a_6_m_gap_with_their_tops_at_2_m() -> void:
	var arena := _arena()
	var a := _box(_body(arena, "PlataformaVaoA"))
	var b := _box(_body(arena, "PlataformaVaoB"))
	for box: AABB in [a, b]:
		assert_float(box.end.y).is_equal_approx(PLATFORM_TOP, HAIR)
		assert_float(box.position.y).is_equal_approx(0.0, HAIR) # on the floor's top
	assert_float(a.position.z - b.end.z).is_equal_approx(GAP, HAIR)
	# Face to face across the gap, over the same x.
	assert_float(a.position.x).is_equal_approx(b.position.x, HAIR)
	assert_float(a.end.x).is_equal_approx(b.end.x, HAIR)


func test_the_gap_platforms_stay_clear_of_the_reference_route_and_the_sync_test() -> void:
	var arena := _arena()
	for platform_name: String in GAP_PLATFORMS:
		var reach := _footprint(_box(_body(arena, platform_name))).grow(BODY_RADIUS)
		var on_route := "%s is on the reference route's ground" % platform_name
		assert_bool(reach.intersects(REFERENCE_ROUTE_AREA)) \
				.override_failure_message(on_route) \
				.is_false()
		var on_scenarios := "%s is on the SyncTest's ground" % platform_name
		assert_bool(reach.intersects(SYNC_TEST_AREA)) \
				.override_failure_message(on_scenarios) \
				.is_false()


# REFERENCE_ROUTE_AREA holds every tick of the stored trace, so a route recorded again that went
# farther fails here before a platform could stand on it.
func test_the_reference_route_stays_inside_its_ground() -> void:
	var trace := FileAccess.get_file_as_string(ReferenceRun.TRACE_PATH)
	assert_str(trace).is_not_empty()
	var outside: Array[String] = []
	var rows := 0
	for line: String in trace.split("\n", false):
		var columns := line.split(",")
		var feet := Vector2(columns[1].to_float(), columns[3].to_float())
		rows += 1
		if not REFERENCE_ROUTE_AREA.has_point(feet):
			outside.append(line)
	assert_int(rows).is_greater(0)
	assert_array(outside).is_empty()


# Every other body of the arena, the floor below them included, at most touches a platform.
func test_the_gap_platforms_overlap_no_other_body_of_the_arena() -> void:
	var arena := _arena()
	for platform_name: String in GAP_PLATFORMS:
		var box := _box(_body(arena, platform_name))
		for node: Node in arena.find_children("*", "StaticBody3D", true, false):
			if node.name == platform_name:
				continue
			assert(node is StaticBody3D, "find_children by StaticBody3D returns StaticBody3Ds")
			var other := _box(node as StaticBody3D)
			var failure := "%s overlaps %s" % [platform_name, node.name]
			assert_bool(box.intersects(other)).override_failure_message(failure).is_false()


# The material of body's mesh: the blocks' grey is one shared material.
func _grey_of(body: StaticBody3D) -> Material:
	var mesh_node := body.get_node(^"Mesh")
	assert(mesh_node is MeshInstance3D, "%s/Mesh is a MeshInstance3D" % body.name)
	var mesh := (mesh_node as MeshInstance3D).mesh
	assert(mesh is PrimitiveMesh, "%s/Mesh is a primitive" % body.name)
	return (mesh as PrimitiveMesh).material


# Criterion 7 of TASK-10.4: the ruler is one node under the arena, with a strip every 4 m from
# x -10 to 30, each a box of 0.1 x 0.01 x 2 m, and nothing to collide with.
func test_the_dash_ruler_marks_every_4_m_and_collides_with_nothing() -> void:
	var arena := _arena()
	var found := arena.find_children(RULER, "", true, false)
	assert_int(found.size()).override_failure_message("%s is not one node" % RULER).is_equal(1)
	var ruler := arena.get_node_or_null(NodePath(RULER))
	assert_object(ruler).override_failure_message("no %s under Arena" % RULER).is_not_null()
	if ruler == null:
		return
	assert_bool(ruler is Node3D).is_true()
	var bodies := ruler.find_children("*", "CollisionObject3D", true, false)
	bodies.append_array(ruler.find_children("*", "CollisionShape3D", true, false))
	assert_array(bodies).override_failure_message("the ruler has something to collide with") \
			.is_empty()
	var xs: Array[float] = []
	for strip: Node in ruler.get_children():
		assert(strip is MeshInstance3D, "every strip of the ruler is a MeshInstance3D")
		var mesh_node := strip as MeshInstance3D
		assert(mesh_node.mesh is BoxMesh, "every strip of the ruler is a BoxMesh")
		assert_vector((mesh_node.mesh as BoxMesh).size).is_equal_approx(
			RULER_STRIP,
			Vector3.ONE * HAIR,
		)
		var at := mesh_node.global_position
		assert_float(at.y).is_equal_approx(RULER_Y, HAIR)
		assert_float(at.z).is_equal_approx(RULER_Z, HAIR)
		xs.append(at.x)
	xs.sort()
	var expected: Array[float] = []
	var x := RULER_FROM_X
	while x <= RULER_TO_X + HAIR:
		expected.append(x)
		x += RULER_STEP_M
	assert_array(xs).is_equal(expected)


# The ruler's strips stand on free floor: off the reference route's ground and the SyncTest's,
# as the gap platforms do.
func test_the_dash_ruler_stays_clear_of_the_reference_route_and_the_sync_test() -> void:
	var arena := _arena()
	var ruler := arena.get_node_or_null(NodePath(RULER))
	assert_object(ruler).is_not_null()
	if ruler == null:
		return
	for strip: Node in ruler.get_children():
		assert(strip is MeshInstance3D, "every strip of the ruler is a MeshInstance3D")
		var mesh_node := strip as MeshInstance3D
		var box := mesh_node.global_transform * mesh_node.get_aabb()
		var reach := _footprint(box).grow(BODY_RADIUS)
		var where := "%s/%s" % [RULER, strip.name]
		assert_bool(reach.intersects(REFERENCE_ROUTE_AREA)) \
				.override_failure_message("%s is on the reference route's ground" % where) \
				.is_false()
		assert_bool(reach.intersects(SYNC_TEST_AREA)) \
				.override_failure_message("%s is on the SyncTest's ground" % where) \
				.is_false()


# Criterion 8 of TASK-10.5: each wall-run piece has one name under the arena, is a box on the
# world's layer whose collision is its mesh, in the blocks' grey.
func test_each_wall_run_piece_is_one_named_world_box_whose_collision_matches_its_mesh() -> void:
	var arena := _arena()
	var grey := _grey_of(_body(arena, GREY_BLOCK))
	for piece: String in WALL_PIECES:
		var found := arena.find_children(piece, "", true, false)
		var failure := "%s is named %d times under Arena" % [piece, found.size()]
		assert_int(found.size()).override_failure_message(failure).is_equal(1)
		var body := _body(arena, piece)
		assert_object(body.get_parent()).is_same(arena)
		assert_int(body.collision_layer).is_equal(PhysicsLayers.WORLD)
		assert_vector(body.position).is_equal_approx(WALL_PIECES[piece], Vector3.ONE * HAIR)
		assert_bool(body.basis.is_equal_approx(Basis.IDENTITY)).is_true()
		var collision := body.get_node(^"Collision")
		assert_bool(collision is CollisionShape3D).is_true()
		var shape := (collision as CollisionShape3D).shape
		assert_bool(shape is BoxShape3D).is_true()
		assert_vector((shape as BoxShape3D).size).is_equal(WALL_PIECE_SIZES[piece])
		var mesh_node := body.get_node(^"Mesh")
		assert_bool(mesh_node is MeshInstance3D).is_true()
		var mesh := (mesh_node as MeshInstance3D).mesh
		assert_bool(mesh is BoxMesh).is_true()
		assert_vector((mesh as BoxMesh).size).is_equal(WALL_PIECE_SIZES[piece])
		var collision_at := (collision as CollisionShape3D).transform
		var mesh_at := (mesh_node as MeshInstance3D).transform
		assert_bool(collision_at.is_equal_approx(Transform3D.IDENTITY)).is_true()
		assert_bool(mesh_at.is_equal_approx(Transform3D.IDENTITY)).is_true()
		assert_object(_grey_of(body)).is_same(grey)
		# On the floor's top.
		assert_float(_box(body).position.y).is_equal_approx(0.0, HAIR)


# The long wall outlasts a run; the corridor's walls face each other 3.5 m apart over the same
# 24 m; the landing is 3 m tall, fills the gap and starts where the walls end, so the corridor
# climbs to it.
func test_the_long_wall_outlasts_a_run_and_the_corridor_climbs_to_a_3_m_landing() -> void:
	var arena := _arena()
	var long_wall := _box(_body(arena, "ParedeLonga"))
	assert_float(long_wall.size.z).is_greater(WALL_RUN_LENGTH)
	var west := _box(_body(arena, "CorredorOeste"))
	var east := _box(_body(arena, "CorredorLeste"))
	assert_float(east.position.x - west.end.x).is_equal_approx(CORRIDOR_GAP, HAIR)
	assert_float(west.position.z).is_equal_approx(east.position.z, HAIR)
	assert_float(west.end.z).is_equal_approx(east.end.z, HAIR)
	assert_float(west.size.z).is_greater(WALL_RUN_LENGTH)
	var landing := _box(_body(arena, "PatamarDoCorredor"))
	assert_float(landing.end.y).is_equal_approx(LANDING_TOP, HAIR)
	assert_float(landing.position.x).is_equal_approx(west.end.x, HAIR)
	assert_float(landing.end.x).is_equal_approx(east.position.x, HAIR)
	assert_float(landing.end.z).is_equal_approx(west.position.z, HAIR)


# Clear of the reference route's ground, the SyncTest's and its wall scenario's, as the gap
# platforms are, and at most touching any other body of the arena.
func test_the_wall_run_pieces_stay_clear_of_the_routes_and_of_every_other_body() -> void:
	var arena := _arena()
	var grounds: Dictionary[String, Rect2] = {
		"the reference route's ground": REFERENCE_ROUTE_AREA,
		"the SyncTest's ground": SYNC_TEST_AREA,
		"the wall scenario's ground": PAREDE_SCENARIO_AREA,
	}
	for piece: String in WALL_PIECES:
		var box := _box(_body(arena, piece))
		var reach := _footprint(box).grow(BODY_RADIUS)
		for ground: String in grounds:
			var failure := "%s is on %s" % [piece, ground]
			assert_bool(reach.intersects(grounds[ground])).override_failure_message(failure) \
					.is_false()
		for node: Node in arena.find_children("*", "StaticBody3D", true, false):
			if node.name == piece:
				continue
			assert(node is StaticBody3D, "find_children by StaticBody3D returns StaticBody3Ds")
			var other := _box(node as StaticBody3D)
			var overlap := "%s overlaps %s" % [piece, node.name]
			assert_bool(box.intersects(other)).override_failure_message(overlap).is_false()


# The gap platforms and the ruler stay off the wall scenario's ground too.
func test_the_gap_platforms_and_the_ruler_stay_clear_of_the_wall_scenario() -> void:
	var arena := _arena()
	for platform_name: String in GAP_PLATFORMS:
		var reach := _footprint(_box(_body(arena, platform_name))).grow(BODY_RADIUS)
		assert_bool(reach.intersects(PAREDE_SCENARIO_AREA)).is_false()
	var ruler := arena.get_node_or_null(NodePath(RULER))
	assert_object(ruler).is_not_null()
	if ruler == null:
		return
	for strip: Node in ruler.get_children():
		assert(strip is MeshInstance3D, "every strip of the ruler is a MeshInstance3D")
		var mesh_node := strip as MeshInstance3D
		var box := mesh_node.global_transform * mesh_node.get_aabb()
		assert_bool(_footprint(box).grow(BODY_RADIUS).intersects(PAREDE_SCENARIO_AREA)).is_false()
