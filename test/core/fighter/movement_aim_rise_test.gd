# Criterion 2 of TASK-12.15, the core part: the camera's rise lifts the point O (movimento.md,
# "Gancho": "De onde sai a mira": "os pés, mais 1,6 m para cima e a subida da câmera, mais o ombro
# para a direita do yaw [...] na câmera centrada, 2,2 m e 0, no eixo do corpo"; "Câmera": "Subida";
# glossario.md, "Ponto O" and "Subida da câmera"; F-219 §1). MovementData.aim_rise_m is the copy of
# the camera's rise, as aim_side_m copies the shoulder, and MovementConfig.aim_rise its copy; the
# grapple's reach, 3 to 25 m, is measured from O at aim_height + aim_rise above the feet, and the
# body's shoulder, from where the cable and the second ray of the corner rule leave, stays at
# aim_height ("A quina": "do ombro do corpo (1,6 m acima dos pés, sem a subida da câmera)").
# Through the public interface of core/fighter: Movement.in_reach, the fire rule played by the
# MovementRig, MovementConfig and Aim.origin. The new names are read by reflection, by the names
# the plan fixes, so the suite loads before they exist and fails on what is missing, one assertion
# at a time. Every number comes from docs/design/movimento.md, cited by section.
extends GdUnitTestSuite

const MovementRig := preload("res://test/core/fighter/movement_rig.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)
# The names the plan fixes (F-219 §1: "Os dados"; glossario.md, "Subida da câmera").
const RISE_DATA_FIELD := &"aim_rise_m"
const RISE_CONFIG_FIELD := &"aim_rise"

# movimento.md, "Gancho".
const GRAPPLE_RANGE_M := 25.0 # "Alcance": 25 m, measured from the point O
const GRAPPLE_MIN_RANGE_M := 3.0 # "Alcance mínimo": 3 m, measured from the point O
const AIM_HEIGHT_M := 1.6 # "De onde sai a mira": 1,6 m up; "Câmera": "Altura do pivô"
const AIM_SIDE_M := 0.8 # "Câmera": "Ombro", 0,8 m to the right, the default camera
# movimento.md, "Câmera": "Subida": "0 no padrão; 0,6 na câmera centrada".
const CENTER_RISE_M := 0.6
const DEFAULT_RISE_M := 0.0
# "De onde sai a mira": "na câmera centrada, 2,2 m e 0": O's height and side.
const CENTER_O_HEIGHT_M := 2.2
const CENTER_SIDE_M := 0.0

# A hair on each side of each limit: arithmetic, not design numbers.
const A_HAIR_BELOW_MIN_M := 2.999
const A_HAIR_ABOVE_MIN_M := 3.001
const A_HAIR_BELOW_RANGE_M := 24.999
const A_HAIR_ABOVE_RANGE_M := 25.001
# Just inside the range, with a margin a rounding of O's height cannot cross: arithmetic.
const NEAR_THE_RANGE_M := 24.9
const HAIR := 1e-6 # floating-point slack, not a design number
# Any feet off the axes, so a wrong component shows: arithmetic.
const FEET := Vector3(3.0, 1.0, -2.0)
# What a field that does not exist yet reads as: no length of the game.
const NO_SUCH_FIELD := -424242.0


# A float the object holds under this name; the case fails when it holds none.
func _float_of(object: Object, field: StringName) -> float:
	var value: Variant = object.get(field)
	var missing := "%s has no float %s" % [object, field]
	assert_bool(value is float).override_failure_message(missing).is_true()
	if value is float:
		var number: float = value
		return number
	return NO_SUCH_FIELD


# A copy of movement_v0.tres with another side and another rise, as the configuration of one
# tickrate: the numbers are set by their agreed names, and the case fails here when the data has
# no rise.
func _config(side_m: float, rise_m: float, tickrate: int) -> MovementConfig:
	var resource: Resource = load(MovementRig.MOVEMENT_V0)
	assert(resource is MovementData, "%s must load as a MovementData" % MovementRig.MOVEMENT_V0)
	var copy: Resource = resource.duplicate()
	assert(copy is MovementData, "a duplicate must still be a MovementData")
	var data := copy as MovementData
	data.aim_side_m = side_m
	data.set(RISE_DATA_FIELD, rise_m)
	assert_that(data.get(RISE_DATA_FIELD)) \
			.override_failure_message("MovementData has no %s" % RISE_DATA_FIELD) \
			.is_equal(rise_m)
	var refused := "a side of %s and a rise of %s must pass" % [side_m, rise_m]
	assert_array(data.validate()).override_failure_message(refused).is_empty()
	return MovementConfig.create(data, tickrate)


# The centered camera's numbers: side 0 and rise 0,6 m.
func _center(tickrate: int) -> MovementConfig:
	return _config(CENTER_SIDE_M, CENTER_RISE_M, tickrate)


# The point O by hand, from the paper and not through Aim.origin: the feet, plus the height up,
# plus the side to the right of the yaw, (cos θ, 0, -sin θ) (TASK-10.11 plan).
func _origin(feet: Vector3, yaw: float, height: float, side: float) -> Vector3:
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	return feet + Vector3.UP * height + right * side


func _assert_reach(
	point: Vector3,
	yaw: float,
	config: MovementConfig,
	expected: bool,
	what: String,
) -> void:
	assert_bool(Movement.in_reach(point, FEET, yaw, config)) \
			.override_failure_message("%s at %d ticks" % [what, config.tickrate]) \
			.is_equal(expected)


# The config copies the rise as it copies the side: 0,6 in, 0,6 out, and the body's shoulder
# stays at 1,6 m, the rise not folded into it ("A quina"; glossario.md, "Subida da câmera": "O
# corpo [...] não sobe").
func test_the_config_copies_the_rise_and_keeps_the_aim_height_at_1_6_m(
	tickrate: int,
	rise_m: float,
	_test_parameters := [[30, 0.6], [60, 0.6], [30, 0.0], [60, 0.0], [60, 0.25]],
) -> void:
	var config := _config(CENTER_SIDE_M, rise_m, tickrate)
	assert_float(_float_of(config, RISE_CONFIG_FIELD)).is_equal_approx(rise_m, HAIR)
	var folded := "aim_height is %s with a rise of %s: the body's shoulder stays at 1,6 m" % [
		config.aim_height,
		rise_m,
	]
	assert_float(config.aim_height).override_failure_message(folded).is_equal_approx(
		AIM_HEIGHT_M,
		HAIR,
	)
	assert_float(config.aim_side).is_equal_approx(CENTER_SIDE_M, HAIR)


# The default: movement_v0.tres has no rise, in the data and in the config ("Subida": "0 no
# padrão"), and its O is where it was, 1,6 m up and 0,8 m to the right.
func test_movement_v0_has_no_rise(tickrate: int, _test_parameters := [[30], [60]]) -> void:
	var resource: Resource = load(MovementRig.MOVEMENT_V0)
	assert_bool(resource is MovementData).is_true()
	assert_float(_float_of(resource, RISE_DATA_FIELD)).is_equal_approx(DEFAULT_RISE_M, HAIR)
	var config := MovementRig.load_config(tickrate)
	assert_float(_float_of(config, RISE_CONFIG_FIELD)).is_equal_approx(DEFAULT_RISE_M, HAIR)
	assert_float(config.aim_height).is_equal_approx(AIM_HEIGHT_M, HAIR)
	assert_float(config.aim_side).is_equal_approx(AIM_SIDE_M, HAIR)


# The centered O is on the body's axis, 2,2 m above the feet, whatever the yaw: 1,6 + 0,6, with
# Aim.origin's signature as it was, and the body's shoulder 0,6 m below it.
func test_the_centered_point_o_is_on_the_bodys_axis_2_2_m_above_the_feet(
	yaw_deg: float,
	_test_parameters := [[0.0], [90.0], [-135.0]],
) -> void:
	var config := _center(60)
	var rise := _float_of(config, RISE_CONFIG_FIELD)
	assert_float(config.aim_height + rise).is_equal_approx(CENTER_O_HEIGHT_M, HAIR)
	var yaw := deg_to_rad(yaw_deg)
	var origin := Aim.origin(FEET, yaw, config.aim_height + rise, config.aim_side)
	assert_vector(origin).is_equal_approx(FEET + Vector3.UP * CENTER_O_HEIGHT_M, Vector3.ONE * HAIR)
	var shoulder := Aim.origin(FEET, yaw, config.aim_height, 0.0)
	assert_vector(shoulder).is_equal_approx(FEET + Vector3.UP * AIM_HEIGHT_M, Vector3.ONE * HAIR)
	assert_float(origin.y - shoulder.y).is_equal_approx(CENTER_RISE_M, HAIR)


# Criterion 2, the limits: with the centered camera the 3 and the 25 m are measured from O 2,2 m
# above the feet, inclusive at both, and a hair past either is out. The points sit straight ahead
# of O, at its height, so only one coordinate differs and the limits are exact in 32-bit floats;
# with no side O does not move with the yaw, so the same world point reads the same at any yaw.
func test_the_centered_reach_is_3_to_25_m_from_o_2_2_m_above_the_feet(
	distance: float,
	expected: bool,
	_test_parameters := [
		[GRAPPLE_MIN_RANGE_M, true],
		[A_HAIR_ABOVE_MIN_M, true],
		[A_HAIR_BELOW_MIN_M, false],
		[GRAPPLE_RANGE_M, true],
		[A_HAIR_BELOW_RANGE_M, true],
		[A_HAIR_ABOVE_RANGE_M, false],
		[0.0, false],
		[10.0, true],
	],
) -> void:
	var origin := _origin(FEET, 0.0, CENTER_O_HEIGHT_M, CENTER_SIDE_M)
	var point := origin + Vector3.FORWARD * distance
	for tickrate: int in [30, 60]:
		var config := _center(tickrate)
		for yaw_deg: float in [0.0, 90.0, 180.0]:
			_assert_reach(
				point,
				deg_to_rad(yaw_deg),
				config,
				expected,
				"%.3f m ahead of the centered O, yaw %.0f°" % [distance, yaw_deg],
			)


# Criterion 2, raised against unraised: points the raised O and the body's shoulder judge
# differently are judged by the raised O. Straight up and down the body's axis the two distances
# differ by the whole rise, 0,6 m; straight ahead of the shoulder at 25 m, the raised O is
# sqrt(25² + 0,6²) = 25,0072 m away.
func test_a_point_the_raised_o_and_the_shoulder_judge_differently_follows_the_raised_o(
	from_the_feet: Vector3,
	from_raised_m: float,
	from_shoulder_m: float,
	expected: bool,
	_test_parameters := [
		# 24,9 m above the raised O: 25,5 m from the shoulder.
		[Vector3(0.0, CENTER_O_HEIGHT_M + NEAR_THE_RANGE_M, 0.0), 24.9, 25.5, true],
		# 25 m above the shoulder: 24,4 m from the raised O, in reach of both.
		[Vector3(0.0, AIM_HEIGHT_M + GRAPPLE_RANGE_M, 0.0), 24.4, 25.0, true],
		# 25,3 m above the shoulder: out for the shoulder, 24,7 m from the raised O.
		[Vector3(0.0, AIM_HEIGHT_M + 25.3, 0.0), 24.7, 25.3, true],
		# 3,3 m above the shoulder: in for the shoulder, 2,7 m from the raised O.
		[Vector3(0.0, AIM_HEIGHT_M + 3.3, 0.0), 2.7, 3.3, false],
		# 3,3 m below the raised O: 2,7 m from the shoulder, out for it.
		[Vector3(0.0, CENTER_O_HEIGHT_M - 3.3, 0.0), 3.3, 2.7, true],
		# 25 m straight ahead of the shoulder: 25,0072 m from the raised O.
		[Vector3(0.0, AIM_HEIGHT_M, -GRAPPLE_RANGE_M), 25.0072, 25.0, false],
	],
) -> void:
	var point := FEET + from_the_feet
	var raised := _origin(FEET, 0.0, CENTER_O_HEIGHT_M, CENTER_SIDE_M)
	var shoulder := _origin(FEET, 0.0, AIM_HEIGHT_M, CENTER_SIDE_M)
	# The scene itself: the two distances are the ones the case says, by hand.
	assert_float(point.distance_to(raised)).is_equal_approx(from_raised_m, 1e-4)
	assert_float(point.distance_to(shoulder)).is_equal_approx(from_shoulder_m, 1e-4)
	for tickrate: int in [30, 60]:
		_assert_reach(
			point,
			0.0,
			_center(tickrate),
			expected,
			"a point %.4f m from the raised O and %.4f m from the shoulder"
			% [from_raised_m, from_shoulder_m],
		)


# Criterion 2, the rise alone: with the side at 0 and no rise, O is the body's shoulder, the old
# behaviour, and each point above flips: what the raised O reaches and the shoulder does not is
# out, and the other way round.
func test_without_a_rise_the_reach_is_measured_from_1_6_m_as_before(
	from_the_feet: Vector3,
	expected: bool,
	_test_parameters := [
		[Vector3(0.0, CENTER_O_HEIGHT_M + NEAR_THE_RANGE_M, 0.0), false],
		[Vector3(0.0, AIM_HEIGHT_M + 25.3, 0.0), false],
		[Vector3(0.0, AIM_HEIGHT_M + 3.3, 0.0), true],
		[Vector3(0.0, CENTER_O_HEIGHT_M - 3.3, 0.0), false],
		[Vector3(0.0, AIM_HEIGHT_M, -GRAPPLE_RANGE_M), true],
		[Vector3(0.0, AIM_HEIGHT_M, -A_HAIR_ABOVE_RANGE_M), false],
		[Vector3(0.0, AIM_HEIGHT_M, -GRAPPLE_MIN_RANGE_M), true],
		[Vector3(0.0, AIM_HEIGHT_M, -A_HAIR_BELOW_MIN_M), false],
	],
) -> void:
	for tickrate: int in [30, 60]:
		_assert_reach(
			FEET + from_the_feet,
			0.0,
			_config(CENTER_SIDE_M, DEFAULT_RISE_M, tickrate),
			expected,
			"a point %s from the feet, side 0 and no rise" % from_the_feet,
		)


# The default camera is untouched: with movement_v0.tres the limits sit 3 and 25 m straight ahead
# of O 1,6 m up and 0,8 m to the right of the yaw, as before the rise existed.
func test_the_default_reach_is_still_measured_from_o_at_1_6_m_and_0_8_m_to_the_right(
	distance: float,
	expected: bool,
	_test_parameters := [
		[GRAPPLE_MIN_RANGE_M, true],
		[A_HAIR_BELOW_MIN_M, false],
		[GRAPPLE_RANGE_M, true],
		[A_HAIR_ABOVE_RANGE_M, false],
	],
) -> void:
	var point := _origin(FEET, 0.0, AIM_HEIGHT_M, AIM_SIDE_M) + Vector3.FORWARD * distance
	for tickrate: int in [30, 60]:
		_assert_reach(
			point,
			0.0,
			MovementRig.load_config(tickrate),
			expected,
			"%.3f m ahead of the default O" % distance,
		)


# The rise and the side add up: a right shoulder of 0,8 m with a rise of 0,6 m measures from O
# 2,2 m up and 0,8 m to the right of the yaw, turned with it.
func test_the_rise_adds_to_the_height_and_the_side_still_turns_with_the_yaw(
	yaw_deg: float,
	_test_parameters := [[0.0], [90.0]],
) -> void:
	var yaw := deg_to_rad(yaw_deg)
	var origin := _origin(FEET, yaw, CENTER_O_HEIGHT_M, AIM_SIDE_M)
	var config := _config(AIM_SIDE_M, CENTER_RISE_M, 60)
	_assert_reach(origin + Vector3.UP * 24.9, yaw, config, true, "24,9 m above the raised right O")
	_assert_reach(origin + Vector3.UP * 25.1, yaw, config, false, "25,1 m above the raised right O")
	_assert_reach(origin + Vector3.DOWN * 3.1, yaw, config, true, "3,1 m below the raised right O")
	_assert_reach(origin + Vector3.DOWN * 2.9, yaw, config, false, "2,9 m below the raised right O")


# Criterion 2 through the fire rule: with the centered camera, a press with the aim on a point
# 24,9 m above O at 2,2 m (25,5 m from the body's shoulder) fires on that tick, and one on the point
# 3,3 m above the shoulder (2,7 m from O) does not and waits in the slot; with no rise, the same
# two presses end the other way round.
func test_the_grapple_fires_by_the_reach_of_the_raised_o(
	tickrate: int,
	rise_m: float,
	above_the_feet_m: float,
	fires: bool,
	_test_parameters := [
		[30, CENTER_RISE_M, CENTER_O_HEIGHT_M + NEAR_THE_RANGE_M, true],
		[60, CENTER_RISE_M, CENTER_O_HEIGHT_M + NEAR_THE_RANGE_M, true],
		[30, CENTER_RISE_M, AIM_HEIGHT_M + 3.3, false],
		[60, CENTER_RISE_M, AIM_HEIGHT_M + 3.3, false],
		[30, DEFAULT_RISE_M, CENTER_O_HEIGHT_M + NEAR_THE_RANGE_M, false],
		[60, DEFAULT_RISE_M, CENTER_O_HEIGHT_M + NEAR_THE_RANGE_M, false],
		[30, DEFAULT_RISE_M, AIM_HEIGHT_M + 3.3, true],
		[60, DEFAULT_RISE_M, AIM_HEIGHT_M + 3.3, true],
	],
) -> void:
	var rig := MovementRig.new(_config(CENTER_SIDE_M, rise_m, tickrate), FIRST_TICK)
	var point := rig.position + Vector3.UP * above_the_feet_m
	rig.aim_hit = true
	rig.aim_point = point
	var press_tick := rig.tick
	var plan := rig.step(MovementRig.press_grapple())
	assert_bool(plan.aim_request).override_failure_message("the plan did not ask for the aim") \
			.is_true()
	var where := "rise %.1f, the point %.1f m above the feet: fired at %d, slot (%s, %d)" % [
		rise_m,
		above_the_feet_m,
		rig.state.grapple_fired_tick,
		rig.state.buffered_command,
		rig.state.buffered_tick,
	]
	if fires:
		assert_int(rig.state.grapple_fired_tick).override_failure_message(where).is_equal(
			press_tick
		)
		assert_vector(rig.state.grapple_point).override_failure_message(where).is_equal_approx(
			point,
			Vector3.ONE * HAIR,
		)
	else:
		assert_int(rig.state.grapple_fired_tick).override_failure_message(where).is_equal(
			FighterState.NEVER
		)
		assert_str(String(rig.state.buffered_command)).override_failure_message(where).is_equal(
			String(FighterCommand.GRAPPLE)
		)
		assert_int(rig.state.buffered_tick).override_failure_message(where).is_equal(press_tick)
