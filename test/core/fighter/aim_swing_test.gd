# Criteria 2 and 5 of TASK-12.14, the pure half: Aim.swing_yaw(yaw, side, convergence), the yaw of
# a swing that leaves the body's axis toward the point of the aim line `convergence` metres from
# that axis (combate.md, "A espada na mira": "A conta"; DEC-0057 §2). The aim line runs `side`
# metres to the right of the body, parallel to the camera's yaw (DEC-0045 §2), so the swing turns
# asin(side / convergence) to the right of the camera; a positive yaw turns left (aim_test.gd), so
# the turn is subtracted. The ratio is held between -1 and 1: with a convergence not greater than
# the shoulder the turn stops at 90° and nothing is NaN. A pure function of core/fighter: no node,
# no camera (DEC-0004).
extends GdUnitTestSuite

const SHOULDER_M := 0.8 # movimento.md, "Câmera": "Ombro", 0,8 m to the right
const CONVERGENCE_M := 2.0 # combate.md, "A lâmina e o contato": "Convergência", 2,0 m
# combate.md, "A lâmina e o contato": "Direção": "o golpe gira ≈ 23,58° para a direita"; DEC-0057,
# "Opções consideradas" 1: asen(0,8 / 2,0) ≈ 23,58°, 0,411517 rad.
const TURN_RAD := 0.411517
const TURN_DEG := 23.578
const SIX_DECIMALS := 1e-6 # the turn above is written to six decimals
const THREE_DECIMALS := 1e-3 # the degrees above are written to three decimals
const HAIR := 1e-9 # floating-point slack, not a design number
# Positions are single-precision vectors: 10 µm of slack on a distance worked out from them.
const LINE_HAIR := 1e-5
# The point the blade's tip reaches from the axis, at the hand's height: arithmetic for the
# geometric check, any feet off the axes.
const FEET := Vector3(2.0, 0.5, -3.0)
const AIM_HEIGHT_M := 1.6 # movimento.md, "Câmera": "Altura do pivô"; any height serves here


# One: with the v0 numbers the swing turns 23,578° to the right of the camera, a negative offset.
func test_the_v0_swing_turns_23_578_degrees_to_the_right_of_the_camera() -> void:
	var swing := Aim.swing_yaw(0.0, SHOULDER_M, CONVERGENCE_M)
	assert_float(swing).is_equal_approx(-TURN_RAD, SIX_DECIMALS)
	assert_float(rad_to_deg(swing)).is_equal_approx(-TURN_DEG, THREE_DECIMALS)
	assert_float(swing).is_equal_approx(-asin(SHOULDER_M / CONVERGENCE_M), HAIR)


# Many: the turn is the same whatever the camera's yaw: the swing is the yaw minus the turn.
func test_the_swing_is_the_yaw_minus_the_turn_for_any_yaw(
	yaw: float,
	_test_parameters := [[0.0], [0.3], [-0.3], [1.1], [-2.0], [2.5]],
) -> void:
	var swing := Aim.swing_yaw(yaw, SHOULDER_M, CONVERGENCE_M)
	assert_float(swing).override_failure_message("yaw %s: swing %s" % [yaw, swing]) \
			.is_equal_approx(yaw - TURN_RAD, SIX_DECIMALS)


# The reason of the rule: the swing's direction, from the body's axis, crosses the aim line, which
# leaves the point O along the camera's direction, exactly `convergence` metres from the axis on
# the floor's plane. Aim.origin and Aim.direction are the aim line of DEC-0045 §2.
func test_the_swing_meets_the_aim_line_at_the_convergence(
	yaw: float,
	convergence: float,
	_test_parameters := [[0.0, 2.0], [1.1, 2.0], [-2.0, 2.0], [0.4, 1.6], [0.4, 1.0], [2.5, 5.0]],
) -> void:
	var swing := Aim.swing_yaw(yaw, SHOULDER_M, convergence)
	var point := FEET + Aim.direction(swing, 0.0) * convergence
	var origin := Aim.origin(FEET, yaw, AIM_HEIGHT_M, SHOULDER_M)
	var forward := Aim.direction(yaw, 0.0)
	var from_origin := Vector3(point.x - origin.x, 0.0, point.z - origin.z)
	# The distance from the point to the aim line on the floor's plane, and how far ahead of O.
	var off_the_line := absf(from_origin.cross(forward).y)
	var message := "yaw %s, convergence %s: the swing's point is %s m off the aim line" % [
		yaw,
		convergence,
		off_the_line,
	]
	assert_float(off_the_line).override_failure_message(message).is_equal_approx(0.0, LINE_HAIR)
	assert_float(from_origin.dot(forward)).override_failure_message("the point is behind O") \
			.is_greater(0.0)


# The data changes the turn: a convergence of 1,6 m with the shoulder of 0,8 m is asin(0,5), 30°;
# half the shoulder with 2,0 m is asin(0,2).
func test_the_turn_follows_the_side_and_the_convergence() -> void:
	assert_float(Aim.swing_yaw(0.0, SHOULDER_M, 1.6)).is_equal_approx(-deg_to_rad(30.0), HAIR)
	assert_float(Aim.swing_yaw(0.7, 0.4, CONVERGENCE_M)).is_equal_approx(0.7 - asin(0.2), HAIR)


# None: with no shoulder the aim line leaves the body's axis and the swing is the camera's yaw.
func test_no_shoulder_is_no_turn() -> void:
	assert_float(Aim.swing_yaw(0.9, 0.0, CONVERGENCE_M)).is_equal_approx(0.9, HAIR)


# The side carries its sign (movimento.md, "Câmera": "Ombro": "negativo seria o ombro esquerdo"):
# a left shoulder turns the swing to the left by the same angle.
func test_a_left_shoulder_turns_the_swing_left() -> void:
	var swing := Aim.swing_yaw(0.0, -SHOULDER_M, CONVERGENCE_M)
	assert_float(swing).is_equal_approx(TURN_RAD, SIX_DECIMALS)


# Limit: the side equal to the convergence is a ratio of 1, a turn of exactly 90°.
func test_a_side_equal_to_the_convergence_turns_90_degrees() -> void:
	var swing := Aim.swing_yaw(0.25, SHOULDER_M, SHOULDER_M)
	assert_float(swing).is_equal_approx(0.25 - PI / 2.0, HAIR)


# Failure (combate.md, "A espada na mira": "se não for, a razão fica presa em 1 e o giro para em
# 90°, sem NaN"): a side greater than the convergence, to either side, stops at 90° and is finite.
func test_a_side_beyond_the_convergence_stops_at_90_degrees_and_is_never_nan(
	side: float,
	convergence: float,
	quarter_turns: float,
	_test_parameters := [[0.8, 0.5, 1.0], [5.0, 2.0, 1.0], [-0.8, 0.5, -1.0], [-5.0, 2.0, -1.0]],
) -> void:
	var swing := Aim.swing_yaw(0.25, side, convergence)
	var message := "side %s, convergence %s: swing %s" % [side, convergence, swing]
	assert_bool(is_nan(swing)).override_failure_message(message).is_false()
	assert_bool(is_finite(swing)).override_failure_message(message).is_true()
	assert_float(swing).override_failure_message(message).is_equal_approx(
		0.25 - quarter_turns * PI / 2.0,
		HAIR,
	)
