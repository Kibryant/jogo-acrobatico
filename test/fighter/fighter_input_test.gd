# Criterion 7 of TASK-9, through netfox's real tick loop: the frames' samples become the input
# netfox records for each tick (DEC-0026 §1), and a jump press counts for at most one tick, even
# when a frame runs two ticks to catch the clock. Ticks run by hand (DEC-0027 §3), in Sozinho.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const MATCH_SCENE := preload("res://match/match.tscn")

const HAIR := 1e-9 # floating-point slack, not a design number
const FORWARD := Vector2(0, 1)


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	NetfoxTicks.reset()


func _fighter_in_a_match() -> Fighter:
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	var game_match: Match = auto_free(node)
	add_child(game_match)
	var fighter := game_match.spawn_fighter(0, multiplayer.get_unique_id())
	# netfox's deferred setup, then ticks inside a physics frame (test/support/netfox_ticks.gd).
	await get_tree().process_frame
	await get_tree().physics_frame
	return fighter


func test_the_tick_input_is_the_mean_move_and_the_last_yaw_of_the_frames() -> void:
	var fighter := await _fighter_in_a_match()
	fighter.input.sample_frame(FORWARD, 0.25)
	fighter.input.sample_frame(Vector2.ZERO, 0.5)
	NetfoxTicks.run_loop()
	var tick_input := fighter.input.to_tick_input()
	assert_vector(tick_input.move).is_equal_approx(Vector2(0, 0.5), Vector2.ONE * HAIR)
	assert_float(tick_input.yaw).is_equal_approx(0.5, HAIR)
	assert_bool(tick_input.jump).is_false()
	# The body looks where the camera looked last (movimento.md, "Princípios").
	assert_float(fighter.state.facing_yaw).is_equal_approx(0.5, HAIR)


# Pressed once, the jump leaves the floor on the first tick of the frame, and the second tick of
# the same frame finds it taken: a press left over there would be stamped as a new one, waiting
# in the buffer (Movement.before_move).
func test_a_jump_press_counts_for_one_tick_when_a_frame_runs_two() -> void:
	var fighter := await _fighter_in_a_match()
	NetfoxTicks.run_loops(3)
	fighter.input.press_jump()
	NetfoxTicks.run_loop(2)
	assert_int(fighter.state.jumps_used).is_equal(1)
	assert_int(fighter.state.mode).is_equal(FighterState.Mode.AIR)
	assert_int(fighter.state.jump_pressed_tick).is_equal(FighterState.NEVER)
	assert_float(fighter.position.y).is_greater(0.0)


func test_a_jump_press_counts_for_one_tick_in_frames_of_one_tick() -> void:
	var fighter := await _fighter_in_a_match()
	NetfoxTicks.run_loops(3)
	fighter.input.press_jump()
	NetfoxTicks.run_loop()
	assert_int(fighter.state.jumps_used).is_equal(1)
	NetfoxTicks.run_loop()
	assert_int(fighter.state.jump_pressed_tick).is_equal(FighterState.NEVER)
	assert_bool(fighter.input.to_tick_input().jump).is_false()


# No press, no jump: the fighter stays on the floor through frames of two ticks.
func test_without_a_press_the_fighter_never_jumps() -> void:
	var fighter := await _fighter_in_a_match()
	NetfoxTicks.run_loops(30, 2)
	assert_int(fighter.state.jumps_used).is_equal(0)
	assert_bool(fighter.state.on_floor).is_true()
