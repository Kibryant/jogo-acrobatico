# The data rows of TASK-10.6: the eight numbers of the grapple as MovementData fields, group
# "Grapple" (movimento.md, "Gancho"; TASK-10.6 notes, Data), with the data check of DEC-0027 §2
# (layer 3): movement_v0.tres holds the design numbers, MovementData.validate() returns one
# message per impossible number, and the aim's height equals the camera's pivot in camera_v0.tres
# (DEC-0044, choice 2). TASK-10.11 adds the aim's side, the camera's shoulder copied with its
# sign, which has no impossible value (0 is the shoulder, negative the left one) and must equal
# the shoulder of camera_v0.tres (movimento.md, "Gancho": "De onde sai a mira"; "Câmera":
# "Ombro"; DEC-0045 §2). Each case changes one field of a copy of movement_v0.tres, the design
# numbers, as test/data/movement_data_ticks_test.gd does.
extends GdUnitTestSuite

const MOVEMENT_V0 := "res://data/movement_v0.tres"
const CAMERA_V0 := "res://data/camera_v0.tres"
const HAIR := 1e-9 # floating-point slack, not a design number

# movimento.md, "Gancho".
const GRAPPLE_RANGE_M := 25.0 # "Alcance"
const GRAPPLE_MIN_RANGE_M := 3.0 # "Alcance mínimo"
const GRAPPLE_ATTACH_MS := 100 # "Tempo até prender"
const GRAPPLE_PULL_SPEED_MPS := 18.0 # "Velocidade da puxada"
const GRAPPLE_RELEASE_DISTANCE_M := 1.5 # "Como solta": 1,5 m from the point
const GRAPPLE_BLOCK_PCT := 50.0 # "Trava": below 50 % of the pull
const GRAPPLE_COOLDOWN_MS := 6000 # "Recarga": 6 s
const AIM_HEIGHT_M := 1.6 # "De onde sai a mira": 1,6 m above the feet, the camera's pivot
const AIM_SIDE_M := 0.8 # "De onde sai a mira": 0,8 m to the right of the yaw, the camera's shoulder

# The eight numbers of the grapple with an impossible value (the aim's side has none, so it is
# not here), each with one value that cannot be, chosen so that each is
# wrong on its own and the two "below the range" checks still hold against a range of 0: a range
# of zero, a negative minimum, a negative cable time, a pull of zero, a negative release distance,
# a negative percentage, a negative cooldown and an aim without height. The times are ints; the
# rest are floats.
const GRAPPLE_IMPOSSIBLE: Dictionary[String, Variant] = {
	"grapple_range_m": 0.0,
	"grapple_min_range_m": -1.0,
	"grapple_attach_ms": -1,
	"grapple_pull_speed_mps": 0.0,
	"grapple_release_distance_m": -1.5,
	"grapple_block_pct": -1.0,
	"grapple_cooldown_ms": -1,
	"aim_height_m": 0.0,
}


func _load_v0() -> MovementData:
	var resource: Resource = load(MOVEMENT_V0)
	assert(
		resource is MovementData,
		"%s must load as a MovementData (TASK-9, part 1)" % MOVEMENT_V0,
	)
	return resource as MovementData


# A copy of movement_v0.tres: load() caches the resource, so each case changes a duplicate and
# the baseline stays intact for every other test of the run.
func _v0_copy() -> MovementData:
	var copy: Resource = _load_v0().duplicate()
	assert(copy is MovementData, "a duplicate of %s must still be a MovementData" % MOVEMENT_V0)
	return copy as MovementData


# Sets one field of the copy, guarding against a typo in the field's name: a misspelt field would
# leave the baseline untouched and pass the check for the wrong reason.
func _v0_copy_with(field: String, value: Variant) -> MovementData:
	var data := _v0_copy()
	data.set(field, value)
	var set_message := "%s is not a field" % field
	assert_bool(data.get(field) == value).override_failure_message(set_message).is_true()
	return data


func _load_camera_v0() -> CameraData:
	var resource: Resource = load(CAMERA_V0)
	assert(resource is CameraData, "%s must load as a CameraData (TASK-9, part 1)" % CAMERA_V0)
	return resource as CameraData


# Exactly one message (one per impossible number, TASK-9 plan, part 1), and it names the field,
# so the gate's print says which number to fix. The wording beyond the name is the implementer's.
func _assert_one_message_naming(errors: PackedStringArray, field: String, why: String) -> void:
	assert_array(errors).override_failure_message("%s, got: %s" % [why, errors]).has_size(1)
	if errors.size() == 1:
		var unnamed := "the message must name %s, got: %s" % [field, errors[0]]
		assert_str(errors[0]).override_failure_message(unnamed).contains(field)


func _assert_some_message_names(errors: PackedStringArray, field: String) -> void:
	var named := false
	for message: String in errors:
		if message.contains(field):
			named = true
	var unnamed := "no message names %s, got: %s" % [field, errors]
	assert_bool(named).override_failure_message(unnamed).is_true()


func _assert_passes(data: MovementData, why: String) -> void:
	assert_array(data.validate()).override_failure_message(why).is_empty()


# One: movement_v0.tres holds the eight numbers of movimento.md, "Gancho".
func test_movement_v0_holds_the_grapple_numbers_of_movimento_md() -> void:
	var data := _load_v0()
	assert_float(data.grapple_range_m).is_equal_approx(GRAPPLE_RANGE_M, HAIR)
	assert_float(data.grapple_min_range_m).is_equal_approx(GRAPPLE_MIN_RANGE_M, HAIR)
	assert_int(data.grapple_attach_ms).is_equal(GRAPPLE_ATTACH_MS)
	assert_float(data.grapple_pull_speed_mps).is_equal_approx(GRAPPLE_PULL_SPEED_MPS, HAIR)
	assert_float(data.grapple_release_distance_m).is_equal_approx(GRAPPLE_RELEASE_DISTANCE_M, HAIR)
	assert_float(data.grapple_block_pct).is_equal_approx(GRAPPLE_BLOCK_PCT, HAIR)
	assert_int(data.grapple_cooldown_ms).is_equal(GRAPPLE_COOLDOWN_MS)
	assert_float(data.aim_height_m).is_equal_approx(AIM_HEIGHT_M, HAIR)
	assert_float(data.aim_side_m).is_equal_approx(AIM_SIDE_M, HAIR)


# None: the design numbers pass the data check, and so does the copy every case starts from.
func test_movement_v0_and_its_copy_pass_the_data_check() -> void:
	_assert_passes(_load_v0(), "movement_v0.tres has impossible numbers")
	_assert_passes(_v0_copy(), "the copy of movement_v0.tres has impossible numbers")


# DEC-0044, choice 2: the aim leaves the shoulder at the camera's pivot height. The number lives
# in two files, and this test catches the day they differ (movimento.md, "Gancho": "De onde sai a
# mira"; "Câmera": "Altura do pivô").
func test_the_aim_height_equals_the_camera_pivot_of_camera_v0() -> void:
	var movement := _load_v0()
	var camera := _load_camera_v0()
	var message := "aim_height_m is %s, the camera's pivot_height_m is %s: they must be equal" % [
		movement.aim_height_m,
		camera.pivot_height_m,
	]
	assert_float(movement.aim_height_m).override_failure_message(message).is_equal_approx(
		camera.pivot_height_m,
		HAIR,
	)
	assert_float(camera.pivot_height_m).is_equal_approx(AIM_HEIGHT_M, HAIR)


# DEC-0045 §2: the aim's side is a copy of the camera's shoulder, sign included, so O sits on
# the line of the screen's centre. Two files, one number: this test catches the day they differ
# (movimento.md, "Gancho": "De onde sai a mira"; "Câmera": "Ombro").
func test_the_aim_side_equals_the_camera_shoulder_of_camera_v0() -> void:
	var movement := _load_v0()
	var camera := _load_camera_v0()
	var message := "aim_side_m is %s, the camera's shoulder_m is %s: they must be equal" % [
		movement.aim_side_m,
		camera.shoulder_m,
	]
	assert_float(movement.aim_side_m).override_failure_message(message).is_equal_approx(
		camera.shoulder_m,
		HAIR,
	)
	assert_float(camera.shoulder_m).is_equal_approx(AIM_SIDE_M, HAIR)


# The aim's side has no impossible value: 0 is the shoulder itself and a negative value the left
# shoulder (movimento.md, "Câmera": "Ombro": "Com sinal: negativo seria o ombro esquerdo").
func test_an_aim_side_of_zero_or_negative_is_allowed(
	side_m: float,
	_test_parameters := [[0.0], [-AIM_SIDE_M], [-0.01], [AIM_SIDE_M], [1.5]],
) -> void:
	var data := _v0_copy_with("aim_side_m", side_m)
	_assert_passes(data, "an aim side of %.2f must pass" % side_m)


# The range is positive: the ray's length (TASK-10.6 notes: "positive").
func test_a_range_that_is_not_positive_is_rejected(
	range_m: float,
	_test_parameters := [[0.0], [-25.0]],
) -> void:
	# The minimum and the release distance are kept below the range, so the range's own message is
	# there whatever the two cross-checks say about them.
	var data := _v0_copy_with("grapple_range_m", range_m)
	data.grapple_min_range_m = -1.0 + range_m
	data.grapple_release_distance_m = -1.5 + range_m
	var errors := data.validate()
	_assert_some_message_names(errors, "grapple_range_m")


# The minimum range is not negative and below the range: at the range or above, nothing could
# ever fire (TASK-10.6 notes: "not negative, below the range"). 0 (no minimum) and 24,9 pass.
func test_a_minimum_range_that_is_negative_or_not_below_the_range_is_rejected(
	min_range_m: float,
	_test_parameters := [[-0.1], [-3.0], [GRAPPLE_RANGE_M], [GRAPPLE_RANGE_M + 1.0]],
) -> void:
	var data := _v0_copy_with("grapple_min_range_m", min_range_m)
	_assert_one_message_naming(
		data.validate(),
		"grapple_min_range_m",
		"a minimum range of %.1f must be rejected" % min_range_m,
	)


func test_a_minimum_range_from_zero_up_to_below_the_range_is_allowed(
	min_range_m: float,
	_test_parameters := [[0.0], [GRAPPLE_MIN_RANGE_M], [GRAPPLE_RANGE_M - 0.1]],
) -> void:
	var data := _v0_copy_with("grapple_min_range_m", min_range_m)
	_assert_passes(data, "a minimum range of %.1f must pass" % min_range_m)


# The cable's time is a time: negative is rejected, and nothing divides by it, so 0 (the hook
# bites at once) and times that round to 0 ticks pass (TASK-10.6 notes: "a time, may be 0").
func test_a_negative_cable_time_is_rejected() -> void:
	var data := _v0_copy_with("grapple_attach_ms", -1)
	_assert_one_message_naming(data.validate(), "grapple_attach_ms", "-1 ms must be rejected")


func test_a_cable_time_of_zero_or_below_a_tick_is_allowed(
	ms: int,
	_test_parameters := [[0], [1], [8], [16]],
) -> void:
	var data := _v0_copy_with("grapple_attach_ms", ms)
	_assert_passes(
		data,
		"grapple_attach_ms = %d ms rounds to 0 ticks but nothing divides by it" % ms,
	)


# The pull's speed is positive: a pull of 0 would never arrive (TASK-10.6 notes: "positive").
func test_a_pull_speed_that_is_not_positive_is_rejected(
	mps: float,
	_test_parameters := [[0.0], [-18.0]],
) -> void:
	var data := _v0_copy_with("grapple_pull_speed_mps", mps)
	_assert_one_message_naming(
		data.validate(),
		"grapple_pull_speed_mps",
		"a pull of %.1f m/s must be rejected" % mps,
	)


# The release distance is positive and below the range: at the range or above, every pull would
# release at once (TASK-10.6 notes: "positive, below the range"). 0,01 and 24,9 pass.
func test_a_release_distance_that_is_not_positive_or_not_below_the_range_is_rejected(
	distance_m: float,
	_test_parameters := [[0.0], [-1.5], [GRAPPLE_RANGE_M], [GRAPPLE_RANGE_M + 1.0]],
) -> void:
	var data := _v0_copy_with("grapple_release_distance_m", distance_m)
	_assert_one_message_naming(
		data.validate(),
		"grapple_release_distance_m",
		"a release distance of %.2f must be rejected" % distance_m,
	)


func test_a_release_distance_above_zero_and_below_the_range_is_allowed(
	distance_m: float,
	_test_parameters := [[0.01], [GRAPPLE_RELEASE_DISTANCE_M], [GRAPPLE_RANGE_M - 0.1]],
) -> void:
	var data := _v0_copy_with("grapple_release_distance_m", distance_m)
	_assert_passes(data, "a release distance of %.2f must pass" % distance_m)


# The block is a percentage of the pull, 0 to 100 inclusive (TASK-10.6 notes: "0 to 100").
func test_a_block_percentage_outside_0_to_100_is_rejected(
	pct: float,
	_test_parameters := [[-0.1], [-50.0], [100.5], [200.0]],
) -> void:
	var data := _v0_copy_with("grapple_block_pct", pct)
	_assert_one_message_naming(
		data.validate(),
		"grapple_block_pct",
		"%.1f %% must be rejected" % pct,
	)


func test_a_block_percentage_from_0_to_100_is_allowed(
	pct: float,
	_test_parameters := [[0.0], [GRAPPLE_BLOCK_PCT], [100.0]],
) -> void:
	var data := _v0_copy_with("grapple_block_pct", pct)
	_assert_passes(data, "%.1f %% must pass" % pct)


# The cooldown is a time: negative is rejected; nothing divides by it, so 0 (no cooldown) and
# times that round to 0 ticks pass (TASK-10.6 notes: "a time, may be 0").
func test_a_negative_cooldown_is_rejected() -> void:
	var data := _v0_copy_with("grapple_cooldown_ms", -1)
	_assert_one_message_naming(data.validate(), "grapple_cooldown_ms", "-1 ms must be rejected")


func test_a_cooldown_of_zero_or_below_a_tick_is_allowed(
	ms: int,
	_test_parameters := [[0], [1], [8], [16]],
) -> void:
	var data := _v0_copy_with("grapple_cooldown_ms", ms)
	_assert_passes(
		data,
		"grapple_cooldown_ms = %d ms rounds to 0 ticks but nothing divides by it" % ms,
	)


# The aim's height is positive: the ray leaves the shoulder, above the feet (TASK-10.6 notes:
# "positive").
func test_an_aim_height_that_is_not_positive_is_rejected(
	height_m: float,
	_test_parameters := [[0.0], [-1.6]],
) -> void:
	var data := _v0_copy_with("aim_height_m", height_m)
	_assert_one_message_naming(
		data.validate(),
		"aim_height_m",
		"an aim height of %.1f must be rejected" % height_m,
	)


# Many: the eight grapple numbers wrong at once give eight messages, each naming its field.
func test_every_impossible_grapple_number_gives_its_own_message_naming_its_field() -> void:
	var data := _v0_copy()
	for field: String in GRAPPLE_IMPOSSIBLE:
		data.set(field, GRAPPLE_IMPOSSIBLE[field])
		var set_message := "%s is not a field" % field
		assert_bool(data.get(field) == GRAPPLE_IMPOSSIBLE[field]) \
				.override_failure_message(set_message) \
				.is_true()
	var errors := data.validate()
	assert_array(errors).override_failure_message("%s" % [errors]).has_size(
		GRAPPLE_IMPOSSIBLE.size()
	)
	for field: String in GRAPPLE_IMPOSSIBLE:
		_assert_some_message_names(errors, field)


# Both grapple times negative at once: one message each, naming its own field.
func test_negative_grapple_times_give_one_message_each() -> void:
	var data := _v0_copy_with("grapple_attach_ms", -1)
	data.grapple_cooldown_ms = -1
	var errors := data.validate()
	assert_array(errors).has_size(2)
	_assert_some_message_names(errors, "grapple_attach_ms")
	_assert_some_message_names(errors, "grapple_cooldown_ms")
