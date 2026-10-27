# Criteria 4 and 5 of TASK-12.1: the blade as the core's own count (DEC-0026 §4; combate.md, "A
# lâmina e o contato" and "O leve no tick"): a segment with a radius, from the hand, 0,6 m off the
# attacker's axis and 1,3 m above its feet, to the tip at 2,0 m, swept over the slice of each active
# tick, against the target's capsule axis, the segment from 0,35 m to 1,45 m above its feet. The
# slice touches when the least distance between it and that axis is at most 0,43 m, the body's
# 0,35 plus the blade's 0,08. The count is exact, with no angle sampling: a target between the
# blades of two tick ends is touched. The tables below are written by hand from the design, one
# millimetre inside and outside every limit; the trigonometry is marked as arithmetic.
extends GdUnitTestSuite

const CombatRig := preload("res://test/core/fighter/combat_rig.gd")
const MovementRig := preload("res://test/core/fighter/movement_rig.gd")

const LIGHT := &"light_attack" # glossario.md, "Golpe leve"

# combate.md, "A lâmina e o contato": "A mão: 0,6 m do eixo do corpo, a 1,3 m de altura";
# "Comprimento da lâmina: 1,4", "A ponta a 2,0 m do eixo"; "Raio da lâmina: 0,08".
const HAND_OFFSET_M := 0.6
const HAND_HEIGHT_M := 1.3
const BLADE_LENGTH_M := 1.4
const TIP_M := 2.0
const BLADE_RADIUS_M := 0.08
# movimento.md, "O corpo": the capsule of 1,8 m by 0,35 m of radius; its axis runs from 0,35 m to
# 1,45 m above the feet (combate.md, "O leve no tick": "O toque").
const CAPSULE_RADIUS_M := 0.35
const AXIS_BOTTOM_M := 0.35
const AXIS_TOP_M := 1.45
# combate.md, "O leve no tick": "O toque": 0,35 + 0,08 = 0,43 m; "A lâmina e o contato": the reach
# of ≈ 2,4 m centre to centre is the tip plus both radii, 2,43 m.
const TOUCH_M := 0.43
const REACH_M := 2.43
# combate.md, "O leve no tick": "O arco do leve": -60° to +60°, 20° per active tick at 60 ticks
# (120° over 6 ticks), so 40° per tick at 30 (over 3 ticks); positive turns left, like the yaw.
const ARC_FROM_DEG := -60.0
const ARC_TO_DEG := 60.0
const SLICE_DEG: Dictionary[int, float] = { 30: 40.0, 60: 20.0 }
const ACTIVE_TICKS: Dictionary[int, int] = { 30: 3, 60: 6 }

const EPS_M := 0.001 # 1 mm either side of a limit: arithmetic, not a design number
const HAIR := 1e-6 # floating-point slack, not a design number
# The slice comes back as a Vector2, whose components are 32-bit floats: an angle near 1 rad
# carries about 1e-7 rad of rounding, 6e-6 degrees. Not a design number.
const ANGLE_HAIR_RAD := 1e-5
const ANGLE_HAIR_DEG := 1e-4
const DISTANCE_HAIR := 1e-4 # 0,1 mm: the slack of the distances written by hand below
const ORIGIN := Vector3.ZERO
const ELSEWHERE := Vector3(3.0, 0.0, -2.0) # any other feet: a translation, not a design number

# Arithmetic for the tables, at swing yaw 0 (looking down -Z), the attacker's feet at the origin:
# - a target dead ahead at 2,0 m sits under the blade's tip at theta 0: distance 0 for the slices
#   that reach theta 0 (k = 3 and 4 at 60; k = 2 at 30);
# - the same target against the end blade at -20° (k = 2 at 60): the nearest point of that blade
#   is at 2,0 · cos 20° = 1,88 m along it, within the blade, so the distance is 2,0 · sin 20° =
#   0,684 m, beyond the touch;
# - a target at REACH ± 1 mm dead ahead: 0,429 and 0,431 m from the tip;
# - a target nearer than the hand: dead ahead at 0,17 m ± 1 mm it is 0,431 and 0,429 m from the
#   hand at theta 0, the nearest point of the annulus; at 0,1 m it is 0,5 m from the hand;
# - the arc's right edge, the blade at -60° (k = 1): a target 1,5 m along it, pushed 0,43 ∓ 1 mm
#   to the right (the direction at -150°, perpendicular to the blade and away from the arc): the
#   nearest point is on the edge blade at 1,5 m, within 0,6..2,0; the left edge at +60° (k = 6)
#   and +150° mirrors it;
# - the height: a target 1,5 m dead ahead whose axis top (feet.y + 1,45) is 0,43 ∓ 1 mm below the
#   blade's plane at 1,3: feet.y = -0,579 touches, -0,581 does not; its axis bottom (feet.y + 0,35)
#   0,43 ∓ 1 mm above it: feet.y = 1,379 touches, 1,381 does not;
# - the diagonal: 0,3 m beyond the tip and the axis top 0,3 m below the plane is √(0,09 + 0,09) =
#   0,424 m, a touch; 0,31 m each is 0,438 m, no touch;
# - between two tick-end blades (criterion 5): a target at -30°, the middle of the slice
#   [-40°, -20°] (k = 2 at 60), at 2,429 m: 0,429 m beyond the tip of the swept slice, a touch;
#   at 2,431 m, no touch. Against the blade at -40° alone (or -20°), 10° off, the nearest point is
#   the tip (2,429 · cos 10° = 2,39 > 2,0), at √(2,429² + 2,0² - 2 · 2,429 · 2,0 · cos 10°) = 0,576
#   m: a count that sampled only the tick ends would miss this target;
# - behind the attacker, 1,5 m along +Z (theta 180°): the nearest point of the arc is the hand
#   at ±60°, 120° off, √(1,5² + 0,6² - 2 · 1,5 · 0,6 · cos 120°) = 1,873 m, for k = 1 and k = 6;
# - 2,0 m to a side (theta ±90°): the nearest point is on the edge blade 30° off, 2,0 · cos 30° =
#   1,73 m along it, at 2,0 · sin 30° = 1,0 m.
const DEAD_AHEAD_2_M := Vector3(0.0, 0.0, -2.0)
const DISTANCE_TO_THE_MINUS_20_BLADE := 0.6840402866513374 # 2,0 · sin 20°
const INSIDE_THE_HAND_M := 0.17 # 0,6 - 0,43: the hand's own touch distance
const DISTANCE_FROM_0_1_M_TO_THE_HAND := 0.5
const EDGE_ALONG_M := 1.5
const BETWEEN_DEG := -30.0
const BETWEEN_END_BLADE_DISTANCE := 0.57589 # √(2,429² + 4 - 9,716 · cos 10°) = √0,33165
const BEHIND := Vector3(0.0, 0.0, 1.5)
const BEHIND_DISTANCE := 1.8734993995195193 # √3,51
const SIDE_DISTANCE := 1.0
const DIAGONAL_TOUCH := 0.3 # √0,18 = 0,424 < 0,43
const DIAGONAL_MISS := 0.31 # √0,1922 = 0,438 > 0,43


func _combat(tickrate: int) -> CombatConfig:
	return CombatRig.load_combat(tickrate)


func _config(tickrate: int) -> MovementConfig:
	return MovementRig.load_config(tickrate)


func _light(combat: CombatConfig) -> AttackConfig:
	assert_bool(combat.attacks.has(LIGHT)).override_failure_message("no light attack").is_true()
	return combat.attacks[LIGHT]


# The horizontal direction at an angle, in degrees: yaw 0 looks down -Z and a positive angle
# turns left, like the yaw (TickInput.yaw; combate.md, "O leve no tick").
static func _dir(angle_deg: float) -> Vector3:
	return Basis(Vector3.UP, deg_to_rad(angle_deg)) * Vector3.FORWARD


# The distance of the slice of tick k, swung from feet along swing_yaw, to a target's axis.
func _distance(feet: Vector3, swing_yaw: float, k: int, target: Vector3, tickrate: int) -> float:
	var combat := _combat(tickrate)
	var slice := Blade.slice_of(_light(combat), k)
	return Blade.slice_distance(
		feet,
		swing_yaw,
		slice.x,
		slice.y,
		target,
		combat,
		_config(tickrate),
	)


func _touches(feet: Vector3, swing_yaw: float, k: int, target: Vector3, tickrate: int) -> bool:
	var combat := _combat(tickrate)
	var slice := Blade.slice_of(_light(combat), k)
	return Blade.slice_touches(feet, swing_yaw, slice.x, slice.y, target, combat, _config(tickrate))


func _assert_distance(
	feet: Vector3,
	swing_yaw: float,
	k: int,
	target: Vector3,
	expected: float,
	tickrate := 60,
) -> void:
	var distance := _distance(feet, swing_yaw, k, target, tickrate)
	var message := "slice %d at %d ticks to target %s: %.4f m, expected %.4f m" % [
		k,
		tickrate,
		target,
		distance,
		expected,
	]
	assert_float(distance).override_failure_message(message).is_equal_approx(
		expected,
		DISTANCE_HAIR,
	)


func _assert_touch(
	feet: Vector3,
	swing_yaw: float,
	k: int,
	target: Vector3,
	expected: bool,
	tickrate := 60,
) -> void:
	var touched := _touches(feet, swing_yaw, k, target, tickrate)
	var distance := _distance(feet, swing_yaw, k, target, tickrate)
	var message := "slice %d at %d ticks to target %s: %s (%.4f m), expected %s" % [
		k,
		tickrate,
		target,
		touched,
		distance,
		expected,
	]
	assert_bool(touched).override_failure_message(message).is_equal(expected)
	# The touch is the distance against the two radii, nothing else.
	assert_bool(distance <= TOUCH_M + HAIR).override_failure_message(message).is_equal(expected)


# The target that sits on the edge blade of the arc, pushed off it, away from the arc, by `off`
# metres: the blade at the edge angle, the push perpendicular to it (edge - 90° for the right
# edge, edge + 90° for the left one).
static func _off_the_edge(edge_deg: float, off: float) -> Vector3:
	var away := -90.0 if edge_deg < 0.0 else 90.0
	return _dir(edge_deg) * EDGE_ALONG_M + _dir(edge_deg + away) * off


# The touch distance is the two radii of the design, read from the configs: 0,35 + 0,08.
func test_the_touch_distance_is_the_capsule_radius_plus_the_blade_radius() -> void:
	var combat := _combat(60)
	var config := _config(60)
	assert_float(config.capsule_radius).is_equal_approx(CAPSULE_RADIUS_M, HAIR)
	assert_float(combat.blade_radius).is_equal_approx(BLADE_RADIUS_M, HAIR)
	assert_float(config.capsule_radius + combat.blade_radius).is_equal_approx(TOUCH_M, HAIR)
	assert_float(combat.hand_offset + combat.blade_length).is_equal_approx(TIP_M, HAIR)
	assert_float(TIP_M + TOUCH_M).is_equal_approx(REACH_M, HAIR)
	# The axis of the target's capsule, from the movement numbers (combate.md, "O toque").
	assert_float(config.capsule_radius).is_equal_approx(AXIS_BOTTOM_M, HAIR)
	assert_float(config.capsule_height - config.capsule_radius).is_equal_approx(AXIS_TOP_M, HAIR)


# The blade at theta runs from the hand to the tip along swing_yaw + theta, at the hand's height
# above the feet: 0,6 m to 2,0 m off the axis (combate.md, "A lâmina e o contato").
func test_the_segment_runs_from_the_hand_to_the_tip_along_the_swing_yaw_plus_theta(
	feet: Vector3,
	yaw_deg: float,
	theta_deg: float,
	_test_parameters := [
		[ORIGIN, 0.0, 0.0],
		[ORIGIN, 0.0, 60.0],
		[ORIGIN, 0.0, -60.0],
		[ORIGIN, 90.0, 0.0],
		[ELSEWHERE, 30.0, -20.0],
		[ELSEWHERE, -135.0, 45.0],
	],
) -> void:
	var combat := _combat(60)
	var segment := Blade.segment(feet, deg_to_rad(yaw_deg), deg_to_rad(theta_deg), combat)
	assert_int(segment.size()).is_equal(2)
	var along := _dir(yaw_deg + theta_deg)
	var height := Vector3.UP * HAND_HEIGHT_M
	var hand := feet + height + along * HAND_OFFSET_M
	var tip := feet + height + along * TIP_M
	var hand_message := "hand %s, expected %s" % [segment[0], hand]
	assert_vector(segment[0]).override_failure_message(hand_message) \
			.is_equal_approx(hand, Vector3.ONE * HAIR)
	assert_vector(segment[1]).override_failure_message("tip %s, expected %s" % [segment[1], tip]) \
			.is_equal_approx(tip, Vector3.ONE * HAIR)
	assert_float(segment[0].distance_to(segment[1])).is_equal_approx(BLADE_LENGTH_M, HAIR)
	assert_float(segment[0].y - feet.y).is_equal_approx(HAND_HEIGHT_M, HAIR)
	assert_float(segment[1].y - feet.y).is_equal_approx(HAND_HEIGHT_M, HAIR)


# Yaw 0 looks down -Z; +60° turns left, to -X; -60° turns right, to +X (combate.md, "O leve no
# tick": "com o ângulo positivo girando para a esquerda, como o yaw").
func test_a_positive_theta_turns_the_blade_left_and_a_negative_one_right() -> void:
	var combat := _combat(60)
	var ahead := Blade.segment(ORIGIN, 0.0, 0.0, combat)
	assert_vector(ahead[1]).is_equal_approx(Vector3(0.0, HAND_HEIGHT_M, -TIP_M), Vector3.ONE * HAIR)
	var left := Blade.segment(ORIGIN, 0.0, deg_to_rad(60.0), combat)
	assert_float(left[1].x).override_failure_message("+60° must point to -X").is_less(0.0)
	var right := Blade.segment(ORIGIN, 0.0, deg_to_rad(-60.0), combat)
	assert_float(right[1].x).override_failure_message("-60° must point to +X").is_greater(0.0)
	assert_float(left[1].x).is_equal_approx(-right[1].x, HAIR)
	assert_float(left[1].z).is_equal_approx(right[1].z, HAIR)
	assert_float(left[1].z).is_equal_approx(-TIP_M * cos(deg_to_rad(60.0)), HAIR)


# The slice of the k-th active tick, k from 1: from -60° + 20°·(k - 1) to -60° + 20°·k at 60
# ticks, 40° per tick at 30 (combate.md, "O leve no tick": "O arco do leve").
func test_slice_of_splits_the_arc_into_one_slice_per_active_tick(
	tickrate: int,
	k: int,
	from_deg: float,
	to_deg: float,
	_test_parameters := [
		[60, 1, -60.0, -40.0],
		[60, 2, -40.0, -20.0],
		[60, 3, -20.0, 0.0],
		[60, 4, 0.0, 20.0],
		[60, 5, 20.0, 40.0],
		[60, 6, 40.0, 60.0],
		[30, 1, -60.0, -20.0],
		[30, 2, -20.0, 20.0],
		[30, 3, 20.0, 60.0],
	],
) -> void:
	var slice := Blade.slice_of(_light(_combat(tickrate)), k)
	assert_float(rad_to_deg(slice.x)).is_equal_approx(from_deg, ANGLE_HAIR_DEG)
	assert_float(rad_to_deg(slice.y)).is_equal_approx(to_deg, ANGLE_HAIR_DEG)
	assert_float(rad_to_deg(slice.y - slice.x)).is_equal_approx(SLICE_DEG[tickrate], ANGLE_HAIR_DEG)


# The slices of a swing tile the arc exactly, the first starting at -60° and the last ending at
# +60°, each beginning where the one before ended.
func test_the_slices_tile_the_arc_from_minus_60_to_plus_60(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var light := _light(_combat(tickrate))
	assert_int(light.active_ticks).is_equal(ACTIVE_TICKS[tickrate])
	var previous_end := deg_to_rad(ARC_FROM_DEG)
	for k: int in range(1, light.active_ticks + 1):
		var slice := Blade.slice_of(light, k)
		assert_float(slice.x).override_failure_message("slice %d starts off" % k).is_equal_approx(
			previous_end,
			ANGLE_HAIR_RAD,
		)
		previous_end = slice.y
	assert_float(previous_end).is_equal_approx(deg_to_rad(ARC_TO_DEG), ANGLE_HAIR_RAD)


# Criterion 5, the reach: the tip touches a target dead ahead up to 2,43 m centre to centre, and
# not a millimetre beyond.
func test_the_reach_is_2_43_m_dead_ahead_and_not_a_millimetre_more() -> void:
	_assert_distance(ORIGIN, 0.0, 3, DEAD_AHEAD_2_M, 0.0)
	_assert_distance(ORIGIN, 0.0, 4, DEAD_AHEAD_2_M, 0.0)
	_assert_touch(ORIGIN, 0.0, 3, DEAD_AHEAD_2_M, true)
	var inside := _dir(0.0) * (REACH_M - EPS_M)
	var outside := _dir(0.0) * (REACH_M + EPS_M)
	_assert_distance(ORIGIN, 0.0, 3, inside, TOUCH_M - EPS_M)
	_assert_distance(ORIGIN, 0.0, 3, outside, TOUCH_M + EPS_M)
	_assert_touch(ORIGIN, 0.0, 3, inside, true)
	_assert_touch(ORIGIN, 0.0, 3, outside, false)
	_assert_touch(ORIGIN, 0.0, 4, inside, true)
	_assert_touch(ORIGIN, 0.0, 4, outside, false)


# The blade starts at the hand, 0,6 m off the axis: the slice is the ring between 0,6 and 2,0 m
# (combate.md, "O leve no tick": "a coroa de círculo entre 0,6 m e 2,0 m"). A target within the
# ring is touched; one hugging the attacker, nearer than 0,17 m, is beyond the hand's reach.
func test_the_slice_is_the_ring_between_the_hand_and_the_tip() -> void:
	_assert_distance(ORIGIN, 0.0, 3, _dir(0.0) * 0.7, 0.0)
	_assert_touch(ORIGIN, 0.0, 3, _dir(0.0) * 0.7, true)
	_assert_distance(ORIGIN, 0.0, 3, _dir(0.0) * 0.1, DISTANCE_FROM_0_1_M_TO_THE_HAND)
	_assert_touch(ORIGIN, 0.0, 3, _dir(0.0) * 0.1, false)
	_assert_distance(ORIGIN, 0.0, 3, _dir(0.0) * (INSIDE_THE_HAND_M + EPS_M), TOUCH_M - EPS_M)
	_assert_distance(ORIGIN, 0.0, 3, _dir(0.0) * (INSIDE_THE_HAND_M - EPS_M), TOUCH_M + EPS_M)
	_assert_touch(ORIGIN, 0.0, 3, _dir(0.0) * (INSIDE_THE_HAND_M + EPS_M), true)
	_assert_touch(ORIGIN, 0.0, 3, _dir(0.0) * (INSIDE_THE_HAND_M - EPS_M), false)


# A slice whose end blade passes 2,0 · sin 20° = 0,684 m from a target dead ahead does not touch
# it: the slice before the one that reaches theta 0.
func test_the_slice_before_the_target_angle_misses_a_target_at_the_tip() -> void:
	_assert_distance(ORIGIN, 0.0, 2, DEAD_AHEAD_2_M, DISTANCE_TO_THE_MINUS_20_BLADE)
	_assert_touch(ORIGIN, 0.0, 2, DEAD_AHEAD_2_M, false)
	_assert_distance(ORIGIN, 0.0, 5, DEAD_AHEAD_2_M, DISTANCE_TO_THE_MINUS_20_BLADE)
	_assert_touch(ORIGIN, 0.0, 5, DEAD_AHEAD_2_M, false)
	_assert_touch(ORIGIN, 0.0, 1, DEAD_AHEAD_2_M, false)
	_assert_touch(ORIGIN, 0.0, 6, DEAD_AHEAD_2_M, false)


# Criterion 5, the arc's edges: on the first slice the right edge is the blade at -60°, and a
# target 0,43 m off it, away from the arc, is touched, a millimetre farther is not; the left edge
# at +60°, on the last slice, mirrors it. The slices that do not hold the edge miss both.
func test_the_edges_of_the_arc_touch_up_to_0_43_m_off_the_edge_blade(
	edge_deg: float,
	k: int,
	other_k: int,
	_test_parameters := [[-60.0, 1, 2], [60.0, 6, 5]],
) -> void:
	var on_the_edge := _dir(edge_deg) * EDGE_ALONG_M
	_assert_distance(ORIGIN, 0.0, k, on_the_edge, 0.0)
	_assert_touch(ORIGIN, 0.0, k, on_the_edge, true)
	var inside := _off_the_edge(edge_deg, TOUCH_M - EPS_M)
	var outside := _off_the_edge(edge_deg, TOUCH_M + EPS_M)
	_assert_distance(ORIGIN, 0.0, k, inside, TOUCH_M - EPS_M)
	_assert_distance(ORIGIN, 0.0, k, outside, TOUCH_M + EPS_M)
	_assert_touch(ORIGIN, 0.0, k, inside, true)
	_assert_touch(ORIGIN, 0.0, k, outside, false)
	_assert_touch(ORIGIN, 0.0, other_k, inside, false)
	_assert_touch(ORIGIN, 0.0, other_k, outside, false)


# Criterion 5, the height: the blade sweeps the plane 1,3 m above the attacker's feet, and the
# target's axis runs from 0,35 to 1,45 m above its own. A target standing lower is touched while
# its axis top is within 0,43 m of the plane: feet 0,579 m lower yes, 0,581 m no. One standing
# higher, while its axis bottom is: 1,379 m higher yes, 1,381 m no. Dead ahead at 1,5 m.
func test_a_target_whose_axis_misses_the_blades_plane_is_touched_only_within_0_43_m(
	feet_y: float,
	expected: float,
	touches: bool,
	_test_parameters := [
		[0.0, 0.0, true],
		[0.5, 0.0, true],
		[-0.5, 0.35, true],
		[-0.579, 0.429, true],
		[-0.581, 0.431, false],
		[-1.0, 0.85, false],
		[1.379, 0.429, true],
		[1.381, 0.431, false],
		[2.0, 1.05, false],
	],
) -> void:
	var target := _dir(0.0) * 1.5 + Vector3.UP * feet_y
	_assert_distance(ORIGIN, 0.0, 3, target, expected)
	_assert_touch(ORIGIN, 0.0, 3, target, touches)


# The distance is a true distance in space: a target 0,3 m beyond the tip and 0,3 m below the
# plane is √(0,3² + 0,3²) = 0,424 m away, a touch; 0,31 m each is 0,438 m, no touch.
func test_the_distance_beyond_the_tip_and_below_the_plane_is_the_diagonal(
	gap: float,
	touches: bool,
	_test_parameters := [[DIAGONAL_TOUCH, true], [DIAGONAL_MISS, false]],
) -> void:
	var feet_y := HAND_HEIGHT_M - gap - AXIS_TOP_M
	var target := _dir(0.0) * (TIP_M + gap) + Vector3.UP * feet_y
	_assert_distance(ORIGIN, 0.0, 3, target, sqrt(2.0) * gap)
	_assert_touch(ORIGIN, 0.0, 3, target, touches)


# Criterion 5, the in-between case: a target at -30°, between the blades of -40° and -20°, the two
# ends of the second slice, 0,429 m beyond the tip. The swept slice touches it; either end blade
# alone, taken as a slice of no width, passes 0,576 m from it. A millimetre farther, no touch.
func test_a_target_between_two_tick_end_blades_is_touched_by_the_swept_slice() -> void:
	var combat := _combat(60)
	var config := _config(60)
	var inside := _dir(BETWEEN_DEG) * (REACH_M - EPS_M)
	var outside := _dir(BETWEEN_DEG) * (REACH_M + EPS_M)
	_assert_distance(ORIGIN, 0.0, 2, inside, TOUCH_M - EPS_M)
	_assert_distance(ORIGIN, 0.0, 2, outside, TOUCH_M + EPS_M)
	_assert_touch(ORIGIN, 0.0, 2, inside, true)
	_assert_touch(ORIGIN, 0.0, 2, outside, false)
	for end_deg: float in [-40.0, -20.0]:
		var end := deg_to_rad(end_deg)
		var distance := Blade.slice_distance(ORIGIN, 0.0, end, end, inside, combat, config)
		var message := "the end blade at %.0f° alone: %.4f m, expected %.4f m" % [
			end_deg,
			distance,
			BETWEEN_END_BLADE_DISTANCE,
		]
		assert_float(distance).override_failure_message(message).is_equal_approx(
			BETWEEN_END_BLADE_DISTANCE,
			DISTANCE_HAIR,
		)
		assert_bool(Blade.slice_touches(ORIGIN, 0.0, end, end, inside, combat, config)) \
				.override_failure_message("the end blade alone must miss it").is_false()
	# The slices on either side of the second miss it too: the target is this slice's alone.
	_assert_touch(ORIGIN, 0.0, 1, inside, false)
	_assert_touch(ORIGIN, 0.0, 3, inside, false)


# A target behind the attacker is never touched: the nearest point of any slice is a hand, over
# 1,8 m away; nor is one 2,0 m to either side, 1,0 m off the edge blades.
func test_a_target_behind_or_beside_the_attacker_is_never_touched(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var sides: Array[Vector3] = [_dir(90.0) * 2.0, _dir(-90.0) * 2.0]
	for k: int in range(1, ACTIVE_TICKS[tickrate] + 1):
		_assert_touch(ORIGIN, 0.0, k, BEHIND, false, tickrate)
		for side: Vector3 in sides:
			_assert_touch(ORIGIN, 0.0, k, side, false, tickrate)
	_assert_distance(ORIGIN, 0.0, 1, BEHIND, BEHIND_DISTANCE, tickrate)
	_assert_distance(ORIGIN, 0.0, ACTIVE_TICKS[tickrate], BEHIND, BEHIND_DISTANCE, tickrate)
	_assert_distance(ORIGIN, 0.0, ACTIVE_TICKS[tickrate], _dir(90.0) * 2.0, SIDE_DISTANCE, tickrate)
	_assert_distance(ORIGIN, 0.0, 1, _dir(-90.0) * 2.0, SIDE_DISTANCE, tickrate)


# The count moves with the attacker and turns with the swing: the same table from other feet and
# another yaw. Facing -X from (3, 0, -2), a target 2,0 m along -X is under the tip at theta 0, and
# one 2,0 m along -Z, on the attacker's right at -90°, is never touched.
func test_the_slice_moves_with_the_feet_and_turns_with_the_swing_yaw(
	tickrate: int,
	k_ahead: int,
	_test_parameters := [[30, 2], [60, 3]],
) -> void:
	var yaw := deg_to_rad(90.0)
	var ahead := ELSEWHERE + _dir(90.0) * TIP_M
	assert_vector(ahead).is_equal_approx(ELSEWHERE + Vector3(-TIP_M, 0.0, 0.0), Vector3.ONE * HAIR)
	_assert_distance(ELSEWHERE, yaw, k_ahead, ahead, 0.0, tickrate)
	_assert_touch(ELSEWHERE, yaw, k_ahead, ahead, true, tickrate)
	var at_the_right := ELSEWHERE + _dir(0.0) * TIP_M
	for k: int in range(1, ACTIVE_TICKS[tickrate] + 1):
		_assert_touch(ELSEWHERE, yaw, k, at_the_right, false, tickrate)
	# The reach is the same from there: 2,43 m along the swing, not a millimetre more.
	_assert_touch(
		ELSEWHERE,
		yaw,
		k_ahead,
		ELSEWHERE + _dir(90.0) * (REACH_M - EPS_M),
		true,
		tickrate,
	)
	_assert_touch(
		ELSEWHERE,
		yaw,
		k_ahead,
		ELSEWHERE + _dir(90.0) * (REACH_M + EPS_M),
		false,
		tickrate,
	)


# At 30 ticks the three slices of 40° reach a target dead ahead on the second, and the first and
# third miss it: the arc is the same, cut coarser.
func test_at_30_ticks_the_three_slices_cover_the_same_arc() -> void:
	_assert_distance(ORIGIN, 0.0, 2, DEAD_AHEAD_2_M, 0.0, 30)
	_assert_touch(ORIGIN, 0.0, 2, DEAD_AHEAD_2_M, true, 30)
	_assert_touch(ORIGIN, 0.0, 1, DEAD_AHEAD_2_M, false, 30)
	_assert_touch(ORIGIN, 0.0, 3, DEAD_AHEAD_2_M, false, 30)
	_assert_touch(ORIGIN, 0.0, 1, _dir(-60.0) * EDGE_ALONG_M, true, 30)
	_assert_touch(ORIGIN, 0.0, 3, _dir(60.0) * EDGE_ALONG_M, true, 30)
