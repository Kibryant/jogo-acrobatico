# Criterion 6 of TASK-10.7: a grapple from the top of Pilar10m up the north border does not take
# the body over it (movimento.md, "Métricas de nível": "A borda"). The worst case of the paper: the
# feet on the pillar's top 4,3 m south of BordaNorte's inner face, the camera at its 80° limit
# ("Câmera": "Inclinação máxima"), so the aim from the point O, 1,6 m above the feet, bites the face
# near the top of the 25 m range, about 36 m up. The pull at 18 m/s keeps its speed after the
# release ("Gancho": "Como solta"), and the double jump at the apex adds its metre: the paper's
# simulation took the feet to 43,6 m, 6,4 m under the 50 m top. The real Match plays it in
# Sozinho, the real arena and movement_v0.tres, with netfox's ticks by hand
# (test/support/netfox_ticks.gd; DEC-0027 §3). It prints the point and the peak for the docs.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const MATCH_SCENE := preload("res://match/match.tscn")

# arena.tscn: Pilar10m spans x 1..3 and z -37..-35, its top at 10 m; BordaNorte's inner face is at
# z = -40 and its top at 50 m.
const ON_THE_PILLAR := Vector3(2, 10, -35.7)
const NORTH_FACE_Z := -40.0
const BORDER_TOP := 50.0
const BORDER_INNER := 40.0
## rad: the camera's limit up (movimento.md, "Câmera": "Inclinação máxima": 80°).
const PITCH_LIMIT := deg_to_rad(80.0)
## m: below this, the hook bit near the top of the range, the paper's worst case (≈ 36 m).
const HIGH_POINT := 30.0
const STAND_TICKS := 3
const LIMIT_TICKS := 600
const HAIR := 1e-3


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	NetfoxTicks.reset()


func test_a_grapple_from_the_pillar_up_the_north_border_does_not_pass_it() -> void:
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	var game_match: Match = auto_free(node)
	add_child(game_match)
	var fighter := game_match.spawn_fighter(0, multiplayer.get_unique_id())
	fighter.position = ON_THE_PILLAR
	await get_tree().process_frame
	await get_tree().physics_frame
	for _tick: int in STAND_TICKS:
		fighter.input.sample_frame(Vector2.ZERO, 0.0, PITCH_LIMIT)
		NetfoxTicks.run_loop()
	assert_bool(fighter.state.on_floor).override_failure_message("not on the pillar").is_true()
	fighter.input.sample_frame(Vector2.ZERO, 0.0, PITCH_LIMIT)
	fighter.input.press_grapple()
	NetfoxTicks.run_loop()
	var point := fighter.state.grapple_point
	var message := "the hook did not bite the north border: %s" % point
	assert_int(fighter.state.grapple_fired_tick).override_failure_message(message).is_not_equal(
		FighterState.NEVER
	)
	assert_float(point.z).override_failure_message(message).is_equal_approx(NORTH_FACE_Z, HAIR)
	assert_float(point.y).override_failure_message(message).is_greater(HIGH_POINT)
	var peak := -INF
	var northmost := INF
	var double_jumped := false
	var double_jump_fired := false
	var landed := false
	for _tick: int in LIMIT_TICKS:
		var state := fighter.state
		var released := state.grapple_end_tick != FighterState.NEVER
		fighter.input.sample_frame(Vector2.ZERO, 0.0, PITCH_LIMIT)
		if released and not double_jumped and fighter.velocity.y <= 0.0:
			fighter.input.press_jump()
			double_jumped = true
		NetfoxTicks.run_loop()
		peak = maxf(peak, fighter.position.y)
		northmost = minf(northmost, fighter.position.z)
		if fighter.state.double_jump_tick != FighterState.NEVER:
			double_jump_fired = true
		if released and double_jumped and fighter.state.on_floor:
			landed = true
			break
	print(
		(
			"Border: from Pilar10m's top the hook bit BordaNorte at %.2f m; the feet peaked at"
			+ " %.2f m, %.2f m under its %.0f m top, and came down at %s"
		)
		% [point.y, peak, BORDER_TOP - peak, BORDER_TOP, fighter.position]
	)
	assert_bool(double_jump_fired).override_failure_message("no double jump").is_true()
	assert_bool(landed).override_failure_message("never came down").is_true()
	message = "the feet reached %.2f m, over the border's %.0f m" % [peak, BORDER_TOP]
	assert_float(peak).override_failure_message(message).is_less(BORDER_TOP)
	assert_float(northmost).is_greater(NORTH_FACE_Z)
	var where := fighter.position
	message = "came down outside the border, at %s" % where
	assert_float(absf(where.x)).override_failure_message(message).is_less(BORDER_INNER)
	assert_float(absf(where.z)).override_failure_message(message).is_less(BORDER_INNER)
