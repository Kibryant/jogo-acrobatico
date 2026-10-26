# The Aim.direction half of criterion 2 of TASK-10.6: the camera's yaw and pitch become the unit
# vector the ray of the grapple follows from the shoulder (movimento.md, "Gancho": "De onde sai a
# mira"; DEC-0044). Yaw 0 looks down -Z (TASK-9 plan), yaw turns about the vertical the way the
# move does (Basis(UP, yaw)), and the pitch is positive up and never beyond the camera's ±80°
# (movimento.md, "Câmera": "Inclinação máxima"). A pure function of core/fighter: no node, no
# camera (DEC-0004).
extends GdUnitTestSuite

const MAX_PITCH_DEG := 80.0 # movimento.md, "Câmera": "Inclinação máxima", 80° up and down
const QUARTER_TURN_DEG := 90.0 # the yaw of the right-hand check: arithmetic, not a design number
const HALF_TURN_DEG := 180.0
const DIAGONAL := 0.7071 # sin 45° = cos 45°, to the four decimals of the plan (TASK-10.6 notes)
const FOUR_DECIMALS := 1e-4 # the plan writes these to four decimals, not a design number
const HAIR := 1e-6 # floating-point slack, not a design number


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
