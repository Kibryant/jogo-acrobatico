# The edges of Aim.swing_yaw that the locked suite of TASK-12.14 leaves out (the review's second
# finding): a convergence of exactly 0, where side / 0 has no finite ratio, and 0 over 0, which has
# no ratio at all. The rule holds the ratio between -1 and 1 and never lets a NaN into the state
# (combate.md, "A espada na mira": "A conta"; DEC-0057, "Consequências"): x / 0 turns the full 90°
# toward the shoulder's side, and 0 / 0 turns nothing, like no shoulder.
extends GdUnitTestSuite

const YAW := 1.0 # any camera yaw
const SHOULDER_M := 0.8 # movimento.md, "Câmera": "Ombro", 0,8 m to the right
const HAIR := 1e-9 # floating-point slack, not a design number


func test_a_zero_convergence_with_a_right_shoulder_turns_90_degrees_right() -> void:
	var swing := Aim.swing_yaw(YAW, SHOULDER_M, 0.0)
	assert_bool(is_finite(swing)).is_true()
	assert_float(swing).is_equal_approx(YAW - PI / 2.0, HAIR)


func test_a_zero_convergence_with_a_left_shoulder_turns_90_degrees_left() -> void:
	var swing := Aim.swing_yaw(YAW, -SHOULDER_M, 0.0)
	assert_bool(is_finite(swing)).is_true()
	assert_float(swing).is_equal_approx(YAW + PI / 2.0, HAIR)


func test_no_shoulder_and_no_convergence_turns_nothing() -> void:
	var swing := Aim.swing_yaw(YAW, 0.0, 0.0)
	assert_bool(is_finite(swing)).is_true()
	assert_float(swing).is_equal_approx(YAW, HAIR)


func test_a_negative_convergence_never_gives_nan() -> void:
	var sides: Array[float] = [SHOULDER_M, -SHOULDER_M, 0.0]
	for side: float in sides:
		assert_bool(is_finite(Aim.swing_yaw(YAW, side, -2.0))).is_true()
