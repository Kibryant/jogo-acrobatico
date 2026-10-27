# Criteria 1 to 3 of TASK-10.15 (DEC-0049): the lid over the arena closes the exit over the
# border's top edge that the corner probe of TASK-10.8 measured (movimento.md, "A borda" and "O
# canto da borda, medido"). The probe, now in the gate: the real Match in Sozinho, the real arena
# and movement_v0.tres, netfox's ticks by hand (test/support/netfox_ticks.gd; DEC-0027 §3), a
# scripted controller that reads the state tick by tick in the north-east corner. Without the lid,
# the zigzag up the corner with the double jump at its top, or a grapple hooked as high as it
# reaches on the other border, put the round capsule on the border's top edge and out of the
# arena. With it, the head stops under the lid, 50 m up, and the feet 1.8 m lower, under the edge;
# the fighter comes down inside. The aim's ray, which is the grapple's, and the camera never see
# the lid: it sits on PhysicsLayers.BOUNDS, which only the fighter's body collides with
# (DEC-0049 §2). It prints the peaks for the docs.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const AimAt := preload("res://test/support/aim_at.gd")
const MATCH_SCENE := preload("res://match/match.tscn")
const ARENA_SCENE := preload("res://arena/arena.tscn")
const CAMERA_RIG_SCENE := preload("res://fighter/camera_rig.tscn")
const CAMERA_V0 := "res://data/camera_v0.tres"

# arena.tscn: the inner faces of BordaLeste and BordaNorte, the border's top, which is the lid's
# bottom face, and the lid's name.
const EAST_FACE := 40.0
const NORTH_FACE := -40.0
const BORDER_TOP := 50.0
const LID := "Tampa"
## m: the probe's start, on the floor against the north wall, 8 m short of the corner.
const START := Vector3(32.0, 0.0, -39.6)
## The probe's 30 s at 60 ticks, from the first entry on the north wall.
const CLIMB_TICKS := 1800
const APPROACH_TICKS := 120
## rad: the camera's limit up (movimento.md, "Câmera": "Inclinação máxima": 80°), and the probe's
## grapple pitch, a little under it.
const PITCH_LIMIT := deg_to_rad(80.0)
const AIM_PITCH := deg_to_rad(78.0)
## m: the first jump on the north wall, running east toward the corner, when the body is this far
## from the east wall's contact: 8 m/s times the 350 ms of the rise (the probe's number).
const FIRST_JUMP_GAP := 2.8
## The push into the corner, over both walls, of a player trying to get out.
const INTO_CORNER := Vector3(1.0, 0.0, -1.0)
## m: the probe's hook stays this far under the border's top, so the ray bites the face.
const HOOK_UNDER_TOP := 0.5
## m: the probe's hook as high as the 25 m range lets, from the point O: a little under it.
const HOOK_REACH := 23.9
## m: the shortest run along the north wall to the hook on the east wall, as the probe aimed.
const HOOK_RUN := 3.5
## m: the engine's contacts in 32-bit floats; not a design number.
const HAIR := 1e-3

var _game_match: Match
var _fighter: Fighter


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	if _game_match != null:
		_game_match.free()
		_game_match = null
	NetfoxTicks.reset()


# What a climb measured.
class Climb:
	var label := ""
	var max_feet := -INF
	var lid_ticks := 0 # ticks whose move hit the lid
	var double_jumps := 0
	var outside := false
	var landed_inside := false
	var hook := Vector3.ZERO
	var note := ""


	func summary(capsule: float) -> String:
		return (
			"Lid, %s: the feet peaked at %.2f m, the head at %.2f m, %.2f m under the %.0f m top;"
			% [label, max_feet, max_feet + capsule, BORDER_TOP - max_feet, BORDER_TOP]
			+ " the lid stopped the head on %d ticks; %d double jumps; hook %s; %s; %s"
			% [
				lid_ticks,
				double_jumps,
				hook,
				"came down inside" if landed_inside else "never came down inside",
				note,
			]
		)


func _setup(start := START) -> void:
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	_game_match = node as Match
	add_child(_game_match)
	_fighter = _game_match.spawn_fighter(0, multiplayer.get_unique_id())
	_fighter.position = start
	await get_tree().process_frame
	await get_tree().physics_frame
	for _tick: int in 3:
		_fighter.input.sample_frame(Vector2.ZERO, 0.0)
		NetfoxTicks.run_loop()


# The stick for a world direction at yaw: the inverse of the fighter's turn of the stick by the
# yaw, Basis(UP, yaw) * (x, 0, -y).
static func _stick(world: Vector3, yaw: float) -> Vector2:
	if world == Vector3.ZERO:
		return Vector2.ZERO
	var local := Basis(Vector3.UP, -yaw) * world.normalized()
	return Vector2(local.x, -local.z)


func _tick(world: Vector3, jump: bool, yaw := 0.0, pitch := 0.0, grapple := false) -> void:
	_fighter.input.sample_frame(_stick(world, yaw), yaw, pitch)
	if jump:
		_fighter.input.press_jump()
	if grapple:
		_fighter.input.press_grapple()
	NetfoxTicks.run_loop()


# Toward the corner along the wall of the run: east on the north wall, north on the east wall.
static func _toward_corner(state: FighterState) -> Vector3:
	if absf(state.wall_normal.z) > 0.5:
		return Vector3.RIGHT
	return Vector3.FORWARD


# The probe's hook: from a run on the north wall, a point of the east wall's face as high as the
# 25 m range and the 50 m top let, at a pitch of 78°, under the camera's 80°.
func _hook_point(feet: Vector3) -> Vector3:
	var origin_y := feet.y + _game_match.config.aim_height
	var height := minf(BORDER_TOP - HOOK_UNDER_TOP, origin_y + HOOK_REACH)
	var run := maxf(HOOK_RUN, (height - origin_y) / tan(AIM_PITCH))
	return Vector3(EAST_FACE, height, feet.z + run)


func _hit_the_lid() -> bool:
	for slide: int in _fighter.get_slide_collision_count():
		var collision := _fighter.get_slide_collision(slide)
		for index: int in collision.get_collision_count():
			var collider := collision.get_collider(index)
			if collider is Node and (collider as Node).name == LID:
				return true
	return false


# The probe's zigzag up the north-east corner (TASK-10.8): the run east on the north wall, the
# wall jump, the entry on the east wall, the jump with the key back toward the corner, and so on,
# wait ticks on each wall after its first. With top, the double jump at the apex of the last wall
# jump, when the ray above the head is over the border's top, then the push into the corner. With
# grapple_from finite, from a run on the north wall with the feet that high, the grapple at the
# east wall as high as it reaches, the push east over it and the double jump once released.
func _climb(label: String, wait: int, top: bool, grapple_from := INF) -> Climb:
	await _setup()
	var climb := Climb.new()
	climb.label = label
	var config := _game_match.config
	var into := Vector3(1.0, 0.0, -0.3)
	var started := false
	for _tick: int in APPROACH_TICKS:
		var gap := (EAST_FACE - config.capsule_radius) - _fighter.position.x
		var go := _fighter.state.on_floor and gap <= FIRST_JUMP_GAP + 0.6
		_tick(into, go)
		if _fighter.state.mode == FighterState.Mode.WALL_RUN:
			started = true
			break
	if not started:
		climb.note = "never entered the north wall"
		return climb
	var first_run := true
	var double_jump_pending := false
	var grappled := false
	var released_double_jump := false
	var escaping := false
	for _tick: int in CLIMB_TICKS:
		var state := _fighter.state
		var tick := NetworkTime.tick
		var feet := _fighter.position
		var world := Vector3.ZERO
		var jump := false
		var yaw := 0.0
		var pitch := 0.0
		var grapple := false
		if escaping:
			world = INTO_CORNER
		elif state.mode == FighterState.Mode.WALL_RUN and not grappled:
			var age := tick - state.mode_since
			if first_run:
				jump = (EAST_FACE - config.capsule_radius) - feet.x <= FIRST_JUMP_GAP
			else:
				jump = age >= 1 + wait
			world = _toward_corner(state)
			var north_wall := state.wall_normal.z > 0.5
			if feet.y >= grapple_from and age >= 1 and north_wall:
				# The ray leaves from the feet after this tick's move along the wall.
				var flat := Vector3(_fighter.velocity.x, 0.0, _fighter.velocity.z)
				var moved := feet + flat / float(config.tickrate)
				var point := _hook_point(moved)
				yaw = AimAt.yaw_to(moved, point, config)
				pitch = minf(AimAt.pitch_to(moved, point, config), PITCH_LIMIT)
				grapple = true
				jump = false
				world = Vector3.ZERO
				grappled = true
				climb.note = "aimed from %.2f m at %.1f deg" % [feet.y, rad_to_deg(pitch)]
			if jump:
				first_run = false
				double_jump_pending = top
		elif state.mode == FighterState.Mode.AIR and not grappled:
			var falling := _fighter.velocity.y <= 0.0
			if double_jump_pending and state.jumps_used == 1 and falling:
				var paid := Stamina.at(state, config, tick) >= config.double_jump_cost
				if feet.y + config.wall_ray_height > BORDER_TOP and paid:
					jump = true
					double_jump_pending = false
					world = INTO_CORNER
					escaping = true
		elif grappled:
			world = Vector3.RIGHT
			var released := state.grapple_end_tick != FighterState.NEVER
			var falling := _fighter.velocity.y <= 0.0
			if released and not released_double_jump and falling:
				if state.mode == FighterState.Mode.AIR:
					jump = true
					released_double_jump = true
		_tick(world, jump, yaw, pitch, grapple)
		var after := _fighter.state
		if after.double_jump_tick == NetworkTime.tick - 1:
			climb.double_jumps += 1
		if after.grapple_point != Vector3.ZERO:
			climb.hook = after.grapple_point
		if _hit_the_lid():
			climb.lid_ticks += 1
		var p := _fighter.position
		climb.max_feet = maxf(climb.max_feet, p.y)
		if after.on_floor and p.y > 1.0:
			# On top of something high, as the border's edge was: push to get out.
			escaping = true
		if p.x > EAST_FACE or p.z < NORTH_FACE:
			climb.outside = true
			escaping = true
		if after.on_floor and p.y < 1.0 and absf(p.x) < EAST_FACE and absf(p.z) < EAST_FACE:
			climb.landed_inside = true
			break
	return climb


func _assert_kept_inside(climb: Climb) -> void:
	var capsule := _game_match.config.capsule_height
	print(climb.summary(capsule))
	var why := "%s: %s" % [climb.label, climb.note]
	assert_bool(climb.lid_ticks > 0).override_failure_message("%s: no head on the lid" % why) \
			.is_true()
	var high := "%s: the feet reached %.2f m" % [why, climb.max_feet]
	assert_float(climb.max_feet).override_failure_message(high).is_less(BORDER_TOP - capsule + HAIR)
	assert_bool(climb.outside).override_failure_message("%s: got out" % why).is_false()
	assert_bool(climb.landed_inside).override_failure_message("%s: never came down" % why) \
			.is_true()


# Criterion 1 (DEC-0049): the zigzag up the corner with the double jump at its top. The probe got
# out with 0 and 4 ticks on each wall, on the border's edge at 7.6 s and at 14.2 s.
func test_the_corner_zigzag_with_the_double_jump_at_the_top_stays_under_the_lid(
	wait: int,
	_test_parameters := [[0], [4]],
) -> void:
	var climb := await _climb("zigzag, %d ticks on each wall" % wait, wait, true)
	assert_int(climb.double_jumps).override_failure_message("no double jump at the top") \
			.is_greater(0)
	_assert_kept_inside(climb)


# Criterion 2 (DEC-0049): the grapple hooked on the east border as high as it reaches, from a run
# on the north wall of the Z at the probe's heights. Without the lid, from 16.9 m up the feet went
# over the 50 m: hooked at 42.8 m they reached the edge, at 49.8 m up to 56 m.
func test_the_grapple_hooked_high_on_the_other_border_stays_under_the_lid(
	from: float,
	_test_parameters := [[18.0], [25.0], [30.0], [40.0]],
) -> void:
	var climb := await _climb("grapple from %.0f m" % from, 8, false, from)
	var hooked := "no hook on the east border: %s" % climb.hook
	assert_float(climb.hook.x).override_failure_message(hooked).is_equal_approx(EAST_FACE, HAIR)
	_assert_kept_inside(climb)


# Criterion 3 (DEC-0049 §2): the aim's ray, the grapple's, cast up under the lid from where its
# 25 m reach passes it, at the camera's 80° and straight up, finds nothing: no hook point in the
# sky. The same ray at the north border, from the same height, finds the face, so the ray works
# there; and a grapple pressed up in the air never fires.
func test_the_aim_and_the_grapple_never_see_the_lid() -> void:
	var feet := Vector3(0.0, 40.0, -30.0)
	await _setup(feet)
	var config := _game_match.config
	assert_float(feet.y + config.aim_height + config.grapple_range).is_greater(BORDER_TOP + 1.0)
	for pitch: float in [PITCH_LIMIT, PI / 2.0]:
		for yaw: float in [0.0, PI / 2.0, PI]:
			var hit := _fighter.aim_ray(feet, yaw, pitch)
			var sky := "the aim at %.0f deg found %s" % [rad_to_deg(pitch), hit]
			assert_bool(hit.is_empty()).override_failure_message(sky).is_true()
	var wall := _fighter.aim_ray(feet, 0.0, deg_to_rad(20.0))
	assert_bool(wall.is_empty()).override_failure_message("no north border ahead").is_false()
	if not wall.is_empty():
		var point: Vector3 = wall["position"]
		assert_float(point.z).is_equal_approx(NORTH_FACE, HAIR)
	# The body itself, in the air under the lid, presses the grapple at the camera's limit up.
	for tick: int in 6:
		_fighter.input.sample_frame(Vector2.ZERO, 0.0, PITCH_LIMIT)
		if tick == 0:
			_fighter.input.press_grapple()
		NetfoxTicks.run_loop()
		assert_int(_fighter.state.grapple_fired_tick).is_equal(FighterState.NEVER)
		assert_vector(_fighter.state.grapple_point).is_equal(Vector3.ZERO)


func _camera_data() -> CameraData:
	var resource: Resource = load(CAMERA_V0)
	assert(resource is CameraData, "%s must load as a CameraData" % CAMERA_V0)
	return resource as CameraData


# Moves the rig's target and lets the rig follow it, on process frames, and the arms cast, on
# physics frames: headless, several physics frames may run within one process frame.
func _settle(rig: CameraRig, target: Node3D, feet: Vector3, yaw: float, pitch: float) -> void:
	target.position = feet
	rig.yaw = yaw
	rig.pitch = pitch
	for _frame: int in 4:
		await get_tree().process_frame
		await get_tree().physics_frame


# Criterion 3 (DEC-0049 §2): the camera over a fighter half a metre under the lid, looking down at
# the camera's limit so the arm rises behind it, through the lid, keeps its whole length and goes
# above the lid. First, from the same height, 2 m in front of the north border and looking away
# from it, the arm behind is pulled in: the camera collides in this arena, and the arm then
# comes back to its length under the lid.
func test_the_camera_is_not_pushed_by_the_lid() -> void:
	var node := ARENA_SCENE.instantiate()
	assert(node is Arena, "arena.tscn must have an Arena at its root")
	var arena: Arena = auto_free(node)
	add_child(arena)
	var data := _camera_data()
	var target := Node3D.new()
	arena.add_child(target)
	var under := BORDER_TOP - 0.5 - data.pivot_height_m
	var rig_node: Node = CAMERA_RIG_SCENE.instantiate()
	assert(rig_node is CameraRig, "camera_rig.tscn must have a CameraRig at its root")
	var rig := rig_node as CameraRig
	rig.setup(data, target, 0.0, false)
	arena.add_child(rig)
	await _settle(rig, target, Vector3(0.0, under, NORTH_FACE + 2.0), PI, 0.0)
	var wall := "the north border did not pull the arm in: %.3f m" % rig.arm.get_hit_length()
	assert_float(rig.arm.get_hit_length()).override_failure_message(wall).is_less(
		data.distance_m - 1.0
	)
	await _settle(rig, target, Vector3(0.0, under, 0.0), 0.0, -deg_to_rad(data.max_pitch_deg))
	var pushed := "the arm stopped at %.3f m of %.3f m" % [
		rig.arm.get_hit_length(),
		data.distance_m,
	]
	assert_float(rig.arm.get_hit_length()).override_failure_message(pushed).is_equal_approx(
		data.distance_m,
		HAIR,
	)
	var above := "the camera is at %s" % rig.camera.global_position
	assert_float(rig.camera.global_position.y).override_failure_message(above).is_greater(
		BORDER_TOP + 1.0
	)
