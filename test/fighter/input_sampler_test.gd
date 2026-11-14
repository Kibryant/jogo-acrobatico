# Criterion 7 of TASK-9: how the frames become the input of a tick (DEC-0026 §1; rede.md §3).
# move is the mean of the frame samples, yaw is the last sample and jump is a one-touch command
# taken once. TASK-10.4 adds the dash, and TASK-10.6 the pitch, the last sample like the yaw, and
# the grapple, one more one-touch command (criterion 2). TASK-12.1 adds the light attack, a
# one-touch command too.
extends GdUnitTestSuite

const HAIR := 1e-9 # floating-point slack, not a design number
const FORWARD := Vector2(0, 1)


func test_move_is_the_mean_of_the_frame_samples() -> void:
	var sampler := InputSampler.new()
	sampler.add_frame(FORWARD, 0.0)
	sampler.add_frame(Vector2.ZERO, 0.0)
	assert_vector(sampler.take_move()).is_equal_approx(Vector2(0, 0.5), Vector2.ONE * HAIR)


# With the keyboard, move is below 1 only on the tick a key changes (TASK-9 plan): three frames
# with W held and one after it is released.
func test_a_key_released_between_frames_gives_a_partial_move() -> void:
	var sampler := InputSampler.new()
	for _frame: int in 3:
		sampler.add_frame(FORWARD, 0.0)
	sampler.add_frame(Vector2.ZERO, 0.0)
	assert_vector(sampler.take_move()).is_equal_approx(Vector2(0, 0.75), Vector2.ONE * HAIR)
	for _frame: int in 2:
		sampler.add_frame(FORWARD, 0.0)
	assert_vector(sampler.take_move()).is_equal_approx(FORWARD, Vector2.ONE * HAIR)


func test_each_tick_loop_starts_new_samples() -> void:
	var sampler := InputSampler.new()
	sampler.add_frame(FORWARD, 0.0)
	assert_vector(sampler.take_move()).is_equal(FORWARD)
	sampler.add_frame(Vector2(1, 0), 0.0)
	assert_vector(sampler.take_move()).is_equal(Vector2(1, 0))


func test_no_frame_means_no_push() -> void:
	var sampler := InputSampler.new()
	assert_vector(sampler.take_move()).is_equal(Vector2.ZERO)
	sampler.add_frame(FORWARD, 0.0)
	sampler.take_move()
	assert_vector(sampler.take_move()).is_equal(Vector2.ZERO)


# A sample longer than 1 counts as 1: move goes up to 1 (TickInput).
func test_a_frame_sample_counts_at_most_one() -> void:
	var sampler := InputSampler.new()
	sampler.add_frame(Vector2(3, 4), 0.0)
	assert_vector(sampler.take_move()).is_equal_approx(Vector2(0.6, 0.8), Vector2.ONE * HAIR)


# A mean of angles breaks where they wrap: 179° and -179° would average to 0°, the opposite way.
func test_yaw_is_the_last_sample() -> void:
	var sampler := InputSampler.new()
	sampler.add_frame(FORWARD, deg_to_rad(179.0))
	sampler.add_frame(FORWARD, deg_to_rad(-179.0))
	sampler.take_move()
	assert_float(sampler.last_yaw()).is_equal_approx(deg_to_rad(-179.0), HAIR)


func test_yaw_stays_until_a_new_sample() -> void:
	var sampler := InputSampler.new(1.5)
	assert_float(sampler.last_yaw()).is_equal(1.5)
	sampler.add_frame(Vector2.ZERO, -0.5)
	sampler.take_move()
	sampler.take_move()
	assert_float(sampler.last_yaw()).is_equal(-0.5)


func test_a_jump_press_is_taken_once() -> void:
	var sampler := InputSampler.new()
	sampler.press_jump()
	assert_bool(sampler.take_jump()).is_true()
	assert_bool(sampler.take_jump()).is_false()


func test_presses_before_one_take_are_one_jump() -> void:
	var sampler := InputSampler.new()
	sampler.press_jump()
	sampler.press_jump()
	assert_bool(sampler.take_jump()).is_true()
	assert_bool(sampler.take_jump()).is_false()


func test_no_press_is_no_jump() -> void:
	var sampler := InputSampler.new()
	sampler.add_frame(FORWARD, 0.0)
	assert_bool(sampler.take_jump()).is_false()


# The press waits between frames for the tick: samples and takes of move do not consume it.
func test_a_press_waits_across_frames_for_its_tick() -> void:
	var sampler := InputSampler.new()
	sampler.press_jump()
	sampler.add_frame(FORWARD, 0.0)
	sampler.take_move()
	sampler.add_frame(FORWARD, 0.0)
	assert_bool(sampler.take_jump()).is_true()


# TASK-10.4: the dash is a one-touch command like the jump, kept apart from it.
func test_a_dash_press_is_taken_once() -> void:
	var sampler := InputSampler.new()
	sampler.press_dash()
	sampler.press_dash()
	assert_bool(sampler.take_dash()).is_true()
	assert_bool(sampler.take_dash()).is_false()


func test_the_dash_and_the_jump_are_taken_apart() -> void:
	var sampler := InputSampler.new()
	sampler.press_dash()
	assert_bool(sampler.take_jump()).is_false()
	sampler.add_frame(FORWARD, 0.0)
	sampler.take_move()
	assert_bool(sampler.take_dash()).is_true()
	sampler.press_jump()
	assert_bool(sampler.take_dash()).is_false()
	assert_bool(sampler.take_jump()).is_true()


# TASK-10.6: the pitch is the last sample, like the yaw (rede.md §3): the aim of a tick is where
# the camera looks now, not a mean of where it looked.
func test_pitch_is_the_last_sample() -> void:
	var sampler := InputSampler.new()
	sampler.add_frame(FORWARD, 0.0, deg_to_rad(80.0))
	sampler.add_frame(FORWARD, 0.0, deg_to_rad(-12.5))
	sampler.take_move()
	assert_float(sampler.last_pitch()).is_equal_approx(deg_to_rad(-12.5), HAIR)
	assert_float(sampler.last_yaw()).is_equal(0.0)


# Before any sample the camera looks level; a pitch stays until a new sample, and a frame sampled
# without one looks level again, as a bot that never aims does.
func test_pitch_stays_until_a_new_sample_and_a_frame_without_one_looks_level() -> void:
	var sampler := InputSampler.new(1.5)
	assert_float(sampler.last_pitch()).is_equal(0.0)
	sampler.add_frame(Vector2.ZERO, -0.5, 0.25)
	sampler.take_move()
	sampler.take_move()
	assert_float(sampler.last_pitch()).is_equal(0.25)
	assert_float(sampler.last_yaw()).is_equal(-0.5)
	sampler.add_frame(Vector2.ZERO, -0.5)
	assert_float(sampler.last_pitch()).is_equal(0.0)


# TASK-10.6: the grapple is a one-touch command like the jump: presses before one take are one.
func test_a_grapple_press_is_taken_once() -> void:
	var sampler := InputSampler.new()
	sampler.press_grapple()
	sampler.press_grapple()
	assert_bool(sampler.take_grapple()).is_true()
	assert_bool(sampler.take_grapple()).is_false()


func test_no_press_is_no_grapple() -> void:
	var sampler := InputSampler.new()
	sampler.add_frame(FORWARD, 0.0, 0.3)
	assert_bool(sampler.take_grapple()).is_false()


# The grapple, the dash and the jump are kept apart: taking one leaves the others, and the press
# waits across frames for its tick.
func test_the_grapple_the_dash_and_the_jump_are_taken_apart() -> void:
	var sampler := InputSampler.new()
	sampler.press_grapple()
	assert_bool(sampler.take_jump()).is_false()
	assert_bool(sampler.take_dash()).is_false()
	sampler.add_frame(FORWARD, 0.0, 0.3)
	sampler.take_move()
	assert_bool(sampler.take_grapple()).is_true()
	sampler.press_jump()
	sampler.press_dash()
	assert_bool(sampler.take_grapple()).is_false()
	assert_bool(sampler.take_jump()).is_true()
	assert_bool(sampler.take_dash()).is_true()


# TASK-12.1: the light attack is a one-touch command like the jump: presses before one take are
# one, and taking it leaves the other commands where they are.
func test_a_light_attack_press_is_taken_once_and_apart_from_the_others() -> void:
	var sampler := InputSampler.new()
	assert_bool(sampler.take_light_attack()).is_false()
	sampler.press_light_attack()
	sampler.press_light_attack()
	sampler.press_jump()
	assert_bool(sampler.take_light_attack()).is_true()
	assert_bool(sampler.take_light_attack()).is_false()
	assert_bool(sampler.take_jump()).is_true()
	sampler.press_dash()
	assert_bool(sampler.take_light_attack()).is_false()
	assert_bool(sampler.take_dash()).is_true()


# TASK-12.2 (DEC-0054 §1): the guard is held, not touched: it reads the last state the devices or
# a bot set, on every tick, until they set another; taking the move or the presses leaves it.
func test_the_guard_is_held_until_it_is_let_go() -> void:
	var sampler := InputSampler.new()
	assert_bool(sampler.guard_held()).is_false()
	sampler.hold_guard(true)
	sampler.take_move()
	sampler.take_light_attack()
	assert_bool(sampler.guard_held()).is_true()
	assert_bool(sampler.guard_held()).is_true()
	sampler.hold_guard(false)
	assert_bool(sampler.guard_held()).is_false()


# TASK-12.3 (DEC-0056 §1): the charged attack, the parry and the guard's press are one-touch
# commands like the light: presses before one take are one, and each is taken apart from the
# others; the guard's press leaves the held guard where it is.
func test_the_charged_the_parry_and_the_guard_press_are_taken_once_and_apart() -> void:
	var sampler := InputSampler.new()
	assert_bool(sampler.take_charged_attack()).is_false()
	assert_bool(sampler.take_parry()).is_false()
	assert_bool(sampler.take_guard_press()).is_false()
	sampler.press_charged_attack()
	sampler.press_charged_attack()
	sampler.press_parry()
	sampler.press_guard()
	assert_bool(sampler.take_charged_attack()).is_true()
	assert_bool(sampler.take_charged_attack()).is_false()
	assert_bool(sampler.take_light_attack()).is_false()
	assert_bool(sampler.take_parry()).is_true()
	assert_bool(sampler.take_parry()).is_false()
	assert_bool(sampler.guard_held()).override_failure_message("a press is no hold").is_false()
	assert_bool(sampler.take_guard_press()).is_true()
	assert_bool(sampler.take_guard_press()).is_false()
	sampler.hold_guard(true)
	assert_bool(sampler.take_guard_press()) \
			.override_failure_message("a hold is no press") \
			.is_false()
	assert_bool(sampler.guard_held()).is_true()
