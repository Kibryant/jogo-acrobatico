# The Aim.direction half of criterion 2 of TASK-10.6: the camera's yaw and pitch become the unit
# vector the ray of the grapple follows (movimento.md, "Gancho": "De onde sai a mira"; DEC-0044).
# Yaw 0 looks down -Z (TASK-9 plan), yaw turns about the vertical the way the move does
# (Basis(UP, yaw)), and the pitch is positive up and never beyond the camera's ±80°
# (movimento.md, "Câmera": "Inclinação máxima"). TASK-10.11 adds Aim.origin, criterion 2: the
# ray leaves the point O, the feet plus the aim's height up plus the camera's shoulder to the
# right of the yaw, the line of the screen's centre at the body's depth, computed without a
# camera (movimento.md, "Gancho": "De onde sai a mira"; DEC-0045 §2). Pure functions of
# core/fighter: no node, no camera (DEC-0004).
extends GdUnitTestSuite

const MAX_PITCH_DEG := 80.0 # movimento.md, "Câmera": "Inclinação máxima", 80° up and down
const QUARTER_TURN_DEG := 90.0 # the yaw of the right-hand check: arithmetic, not a design number
const HALF_TURN_DEG := 180.0
const DIAGONAL := 0.7071 # sin 45° = cos 45°, to the four decimals of the plan (TASK-10.6 notes)
const FOUR_DECIMALS := 1e-4 # the plan writes these to four decimals, not a design number
const HAIR := 1e-6 # floating-point slack, not a design number

# The point O (movimento.md, "Gancho": "De onde sai a mira"): 1,6 m up, the camera's pivot
# ("Câmera": "Altura do pivô"), and 0,8 m to the right of the yaw, the camera's shoulder
# ("Câmera": "Ombro"; DEC-0045 §2).
const AIM_HEIGHT_M := 1.6
const AIM_SIDE_M := 0.8
# Any feet, off the axes so a wrong component shows: arithmetic, not a design number.
const FEET := Vector3(2.0, 0.5, -3.0)
# The right of each cardinal yaw (TASK-10.11 plan): yaw 0 looks down -Z and the right is +X;
# +90° looks down -X and the right is -Z; 180° looks down +Z and the right is -X; -90° looks
# down +X and the right is +Z.
const RIGHT_OF_YAW_0 := Vector3(1.0, 0.0, 0.0)
const RIGHT_OF_YAW_PLUS_90 := Vector3(0.0, 0.0, -1.0)
const RIGHT_OF_YAW_180 := Vector3(-1.0, 0.0, 0.0)
const RIGHT_OF_YAW_MINUS_90 := Vector3(0.0, 0.0, 1.0)


# None: no yaw and no pitch is the camera's forward, -Z.
func test_yaw_0_and_pitch_0_look_down_minus_z() -> void:
	var direction := Aim.direction(0.0, 0.0)
	assert_vector(direction).is_equal_approx(Vector3(0.0, 0.0, -1.0), Vector3.ONE * HAIR)


# One: a quarter turn to the left (yaw +90°) looks down -X, the same turn the move follows
# (TASK-9 plan: Basis(UP, yaw)).
func test_yaw_plus_90_degrees_looks_down_minus_x() -> void:
	var direction := Aim.direction(deg_to_rad(QUARTER_TURN_DEG), 0.0)
	assert_vector(direction).is_equal_approx(Vector3(-1.0, 0.0, 0.0), Vector3.ONE * HAIR)


func test_yaw_minus_90_degrees_looks_down_plus_x() -> void:
	var direction := Aim.direction(deg_to_rad(-QUARTER_TURN_DEG), 0.0)
	assert_vector(direction).is_equal_approx(Vector3(1.0, 0.0, 0.0), Vector3.ONE * HAIR)


func test_yaw_180_degrees_looks_down_plus_z() -> void:
	var direction := Aim.direction(deg_to_rad(HALF_TURN_DEG), 0.0)
	assert_vector(direction).is_equal_approx(Vector3(0.0, 0.0, 1.0), Vector3.ONE * HAIR)


# Pitch +45° is half way up: (0, 0.7071, -0.7071), positive up (TASK-10.6 notes).
func test_pitch_plus_45_degrees_looks_half_way_up() -> void:
	var direction := Aim.direction(0.0, deg_to_rad(45.0))
	assert_vector(direction).is_equal_approx(
		Vector3(0.0, DIAGONAL, -DIAGONAL),
		Vector3.ONE * FOUR_DECIMALS,
	)


func test_pitch_minus_45_degrees_looks_half_way_down() -> void:
	var direction := Aim.direction(0.0, deg_to_rad(-45.0))
	assert_vector(direction).is_equal_approx(
		Vector3(0.0, -DIAGONAL, -DIAGONAL),
		Vector3.ONE * FOUR_DECIMALS,
	)


# Many: yaw and pitch together. A quarter turn left and half way up points along -X and up.
func test_yaw_and_pitch_combine() -> void:
	var direction := Aim.direction(deg_to_rad(QUARTER_TURN_DEG), deg_to_rad(45.0))
	assert_vector(direction).is_equal_approx(
		Vector3(-DIAGONAL, DIAGONAL, 0.0),
		Vector3.ONE * FOUR_DECIMALS,
	)


# Limit: the camera's pitch stops at ±80° (movimento.md, "Câmera"), so the steepest aim still
# keeps a forward part: y is sin 80° and the horizontal part is cos 80°, never straight up or
# straight down.
func test_the_pitch_limits_of_80_degrees_keep_a_forward_part(
	sign_of_pitch: float,
	_test_parameters := [[1.0], [-1.0]],
) -> void:
	var pitch := sign_of_pitch * deg_to_rad(MAX_PITCH_DEG)
	var direction := Aim.direction(0.0, pitch)
	assert_vector(direction).is_equal_approx(
		Vector3(
			0.0,
			sign_of_pitch * sin(deg_to_rad(MAX_PITCH_DEG)),
			-cos(deg_to_rad(MAX_PITCH_DEG)),
		),
		Vector3.ONE * HAIR,
	)
	assert_float(direction.z).override_failure_message("lost the forward part").is_less(0.0)
	assert_float(absf(direction.y)).is_less(1.0)


# The direction is a unit vector for every yaw and every pitch within the camera's limits: the
# ray's length is grapple_range alone (TASK-10.6 notes: "a unit vector").
func test_the_direction_has_unit_length_for_every_yaw_and_pitch(
	yaw_deg: float,
	pitch_deg: float,
	_test_parameters := [
		[0.0, 0.0],
		[37.0, 12.5],
		[-120.0, -80.0],
		[270.0, 80.0],
		[359.0, -33.3],
		[720.0, 0.0],
	],
) -> void:
	var direction := Aim.direction(deg_to_rad(yaw_deg), deg_to_rad(pitch_deg))
	var message := "|direction| for yaw %.1f°, pitch %.1f° is %.6f" % [
		yaw_deg,
		pitch_deg,
		direction.length(),
	]
	assert_float(direction.length()).override_failure_message(message).is_equal_approx(1.0, HAIR)


# The pitch alone sets the height: y is sin(pitch), whatever the yaw.
func test_the_vertical_part_is_the_sine_of_the_pitch_whatever_the_yaw(
	yaw_deg: float,
	pitch_deg: float,
	_test_parameters := [[0.0, 30.0], [90.0, 30.0], [200.0, -60.0], [-45.0, 80.0]],
) -> void:
	var direction := Aim.direction(deg_to_rad(yaw_deg), deg_to_rad(pitch_deg))
	assert_float(direction.y).is_equal_approx(sin(deg_to_rad(pitch_deg)), HAIR)


# The yaw alone turns the horizontal part: it is the move's forward of that yaw, scaled by
# cos(pitch) (TASK-9 plan: the forward of yaw is Basis(UP, yaw) * -Z).
func test_the_horizontal_part_is_the_forward_of_the_yaw_scaled_by_the_cosine_of_the_pitch(
	yaw_deg: float,
	pitch_deg: float,
	_test_parameters := [[0.0, 0.0], [60.0, 20.0], [-135.0, -50.0], [180.0, 80.0]],
) -> void:
	var yaw := deg_to_rad(yaw_deg)
	var pitch := deg_to_rad(pitch_deg)
	var direction := Aim.direction(yaw, pitch)
	var forward: Vector3 = Basis(Vector3.UP, yaw) * Vector3(0.0, 0.0, -1.0)
	var horizontal := Vector3(direction.x, 0.0, direction.z)
	assert_vector(horizontal).is_equal_approx(forward * cos(pitch), Vector3.ONE * HAIR)


# None of the two offsets: height 0 and side 0 give the feet themselves, whatever the yaw.
func test_the_origin_with_no_height_and_no_side_is_the_feet(
	yaw_deg: float,
	_test_parameters := [[0.0], [QUARTER_TURN_DEG], [HALF_TURN_DEG], [-QUARTER_TURN_DEG], [37.0]],
) -> void:
	var origin := Aim.origin(FEET, deg_to_rad(yaw_deg), 0.0, 0.0)
	assert_vector(origin).is_equal_approx(FEET, Vector3.ONE * HAIR)


# One: at yaw 0 the right is +X, so O is the feet plus (0,8, 1,6, 0): (2,8, 2,1, -3) for the
# feet at (2, 0,5, -3) (movimento.md, "Gancho": "De onde sai a mira").
func test_the_origin_at_yaw_0_is_the_feet_plus_1_6_m_up_and_0_8_m_to_plus_x() -> void:
	var origin := Aim.origin(FEET, 0.0, AIM_HEIGHT_M, AIM_SIDE_M)
	assert_vector(origin).is_equal_approx(Vector3(2.8, 2.1, -3.0), Vector3.ONE * HAIR)


# Many: the four cardinal yaws. The side goes to the right of the yaw, turned by the same
# Basis(UP, yaw) the move and the direction use (TASK-9 plan; TASK-10.11 plan).
func test_the_origin_is_the_feet_up_1_6_m_and_0_8_m_to_the_right_of_the_yaw(
	yaw_deg: float,
	right: Vector3,
	_test_parameters := [
		[0.0, RIGHT_OF_YAW_0],
		[QUARTER_TURN_DEG, RIGHT_OF_YAW_PLUS_90],
		[HALF_TURN_DEG, RIGHT_OF_YAW_180],
		[-QUARTER_TURN_DEG, RIGHT_OF_YAW_MINUS_90],
	],
) -> void:
	var origin := Aim.origin(FEET, deg_to_rad(yaw_deg), AIM_HEIGHT_M, AIM_SIDE_M)
	var expected := FEET + Vector3.UP * AIM_HEIGHT_M + right * AIM_SIDE_M
	var message := "O for yaw %.0f° is %s, expected %s" % [yaw_deg, origin, expected]
	assert_vector(origin).override_failure_message(message).is_equal_approx(
		expected,
		Vector3.ONE * HAIR,
	)


# Limit: side 0 is the shoulder itself, the feet plus the height, whatever the yaw (DEC-0044 §2
# before the shoulder; DEC-0045: "side 0 is the shoulder").
func test_a_side_of_zero_gives_the_shoulder_whatever_the_yaw(
	yaw_deg: float,
	_test_parameters := [[0.0], [QUARTER_TURN_DEG], [HALF_TURN_DEG], [-QUARTER_TURN_DEG], [123.0]],
) -> void:
	var origin := Aim.origin(FEET, deg_to_rad(yaw_deg), AIM_HEIGHT_M, 0.0)
	assert_vector(origin).is_equal_approx(FEET + Vector3.UP * AIM_HEIGHT_M, Vector3.ONE * HAIR)


# A negative side is the left shoulder: the mirror of the right one across the shoulder
# (movimento.md, "Câmera": "Ombro": "negativo seria o ombro esquerdo").
func test_a_negative_side_mirrors_the_origin_across_the_shoulder(
	yaw_deg: float,
	right: Vector3,
	_test_parameters := [
		[0.0, RIGHT_OF_YAW_0],
		[QUARTER_TURN_DEG, RIGHT_OF_YAW_PLUS_90],
		[HALF_TURN_DEG, RIGHT_OF_YAW_180],
		[-QUARTER_TURN_DEG, RIGHT_OF_YAW_MINUS_90],
	],
) -> void:
	var yaw := deg_to_rad(yaw_deg)
	var shoulder := FEET + Vector3.UP * AIM_HEIGHT_M
	var left := Aim.origin(FEET, yaw, AIM_HEIGHT_M, -AIM_SIDE_M)
	assert_vector(left).is_equal_approx(shoulder - right * AIM_SIDE_M, Vector3.ONE * HAIR)
	var right_origin := Aim.origin(FEET, yaw, AIM_HEIGHT_M, AIM_SIDE_M)
	assert_vector(left - shoulder).is_equal_approx(-(right_origin - shoulder), Vector3.ONE * HAIR)


# For every yaw, O sits beside the shoulder: horizontal, |side| away, square to the forward of
# that yaw and on its right (forward × UP is the right of a yaw: at yaw 0, -Z × +Y = +X).
func test_the_origin_sits_beside_the_shoulder_on_the_right_of_the_yaw_for_every_yaw(
	yaw_deg: float,
	side: float,
	_test_parameters := [
		[0.0, AIM_SIDE_M],
		[37.0, AIM_SIDE_M],
		[-120.0, AIM_SIDE_M],
		[270.0, AIM_SIDE_M],
		[359.0, -AIM_SIDE_M],
		[720.0, 0.35],
	],
) -> void:
	var yaw := deg_to_rad(yaw_deg)
	var shoulder := FEET + Vector3.UP * AIM_HEIGHT_M
	var beside := Aim.origin(FEET, yaw, AIM_HEIGHT_M, side) - shoulder
	var forward := Aim.direction(yaw, 0.0)
	assert_float(beside.y).override_failure_message("O left the pivot's height").is_equal_approx(
		0.0,
		HAIR,
	)
	assert_float(beside.length()).is_equal_approx(absf(side), HAIR)
	assert_float(beside.dot(forward)).override_failure_message("O is not square to the aim") \
			.is_equal_approx(0.0, HAIR)
	assert_float(beside.dot(forward.cross(Vector3.UP))).is_equal_approx(side, HAIR)


# The formula of the plan, for any numbers: feet + UP * height + Basis(UP, yaw) * (side, 0, 0).
func test_the_origin_follows_the_formula_of_the_plan_for_any_height_and_side(
	yaw_deg: float,
	height: float,
	side: float,
	_test_parameters := [[0.0, 1.6, 0.8], [60.0, 2.0, -0.5], [-135.0, 0.0, 1.0], [200.0, 1.0, 0.0]],
) -> void:
	var yaw := deg_to_rad(yaw_deg)
	var origin := Aim.origin(FEET, yaw, height, side)
	var expected: Vector3 = FEET + Vector3.UP * height + Basis(Vector3.UP, yaw) * Vector3(
		side,
		0.0,
		0.0,
	)
	assert_vector(origin).is_equal_approx(expected, Vector3.ONE * HAIR)
