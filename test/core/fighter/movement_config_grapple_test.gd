# The config rows of TASK-10.6: MovementConfig.create turns the grapple's two times into ticks
# at load, the nearest tick with ties up (Ticks.from_ms), within half a tick, at 30 and at 60
# ticks (DEC-0004, rule 3; visao-geral.md, "O tempo e a física no estado" and "A configuração
# nasce na carga"); derives the block speed from the pull and the percentage; and copies the
# range, the minimum, the pull, the release distance and the aim's height (movimento.md, "Gancho";
# TASK-10.6 notes, Config). TASK-10.11 adds the aim's side, the camera's shoulder copied as it is,
# sign included (movimento.md, "Gancho": "De onde sai a mira"; "Câmera": "Ombro"; DEC-0045 §2).
extends GdUnitTestSuite

const MOVEMENT_V0 := "res://data/movement_v0.tres"
const HAIR := 1e-9 # floating-point slack, not a design number
const HALF_TICK_IN_MS_TIMES_RATE := 500 # |ticks * 1000 - ms * rate| <= 500 is half a tick

# movimento.md, "Gancho". 100 ms of cable is 3 ticks at 30 and 6 at 60; 6 s of cooldown is 180
# and 360, exact multiples; the block speed is 50 % of 18 m/s, 9 m/s.
const GRAPPLE_RANGE_M := 25.0 # "Alcance"
const GRAPPLE_MIN_RANGE_M := 3.0 # "Alcance mínimo"
const GRAPPLE_ATTACH_MS := 100 # "Tempo até prender"
const GRAPPLE_PULL_SPEED_MPS := 18.0 # "Velocidade da puxada"
const GRAPPLE_RELEASE_DISTANCE_M := 1.5 # "Como solta"
const GRAPPLE_BLOCK_PCT := 50.0 # "Trava"
const GRAPPLE_BLOCK_SPEED_MPS := 9.0 # "Trava": "(9 m/s)"
const GRAPPLE_COOLDOWN_MS := 6000 # "Recarga"
const AIM_HEIGHT_M := 1.6 # "De onde sai a mira": 1,6 m up ("Câmera": "Altura do pivô")
const AIM_SIDE_M := 0.8 # "De onde sai a mira": 0,8 m to the right of the yaw ("Câmera": "Ombro")
const ATTACH_TICKS: Dictionary[int, int] = { 30: 3, 60: 6 }
const COOLDOWN_TICKS: Dictionary[int, int] = { 30: 180, 60: 360 }

# Other values for the rounding, arithmetic on the rule and not design numbers: 125 ms is
# 3.75 -> 4 at 30 and 7.5 -> 8 at 60 (tie up); 90 ms is 2.7 -> 3 at 30 and 5.4 -> 5 at 60;
# 6025 ms is 180.75 -> 181 and 361.5 -> 362 (tie up); 5990 ms is 179.7 -> 180 and 359.4 -> 359;
# 8 ms rounds to 0 at both rates and 17 ms is the smallest 1 tick at both.
const OTHER_PULL_MPS := 20.0
const OTHER_BLOCK_PCT := 25.0


func _data() -> MovementData:
	var resource: Resource = load(MOVEMENT_V0)
	assert(
		resource is MovementData,
		"%s must load as a MovementData (TASK-9, part 1)" % MOVEMENT_V0,
	)
	return resource as MovementData


# A copy of movement_v0.tres: load() caches the resource, so each case changes a duplicate.
func _v0_copy() -> MovementData:
	var copy: Resource = _data().duplicate()
	assert(copy is MovementData, "a duplicate of %s must still be a MovementData" % MOVEMENT_V0)
	return copy as MovementData


func _assert_ticks(field: String, actual: int, expected: int, tickrate: int) -> void:
	var message := "%s at %d ticks must be %d, found %d" % [field, tickrate, expected, actual]
	assert_int(actual).override_failure_message(message).is_equal(expected)


func _assert_half_tick(field: String, ticks: int, ms: int, tickrate: int) -> void:
	var error := absi(ticks * 1000 - ms * tickrate)
	var message := (
		"%s: %d ms at %d ticks became %d ticks, more than half a tick off"
		% [field, ms, tickrate, ticks]
	)
	assert_int(error).override_failure_message(message).is_less_equal(HALF_TICK_IN_MS_TIMES_RATE)


# The cable: 100 ms is 3 ticks at 30 and 6 at 60, by the rule of Ticks.from_ms, within half a
# tick.
func test_the_cable_time_becomes_3_ticks_at_30_and_6_at_60(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var data := _data()
	var config := MovementConfig.create(data, tickrate)
	assert_int(data.grapple_attach_ms).is_equal(GRAPPLE_ATTACH_MS)
	_assert_ticks(
		"grapple_attach_ticks",
		config.grapple_attach_ticks,
		ATTACH_TICKS[tickrate],
		tickrate,
	)
	assert_int(config.grapple_attach_ticks).is_equal(
		Ticks.from_ms(data.grapple_attach_ms, tickrate)
	)
	_assert_half_tick(
		"grapple_attach_ticks",
		config.grapple_attach_ticks,
		data.grapple_attach_ms,
		tickrate,
	)


# The cooldown: 6000 ms is 180 ticks at 30 and 360 at 60, by the same rule, within half a tick.
func test_the_cooldown_becomes_180_ticks_at_30_and_360_at_60(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var data := _data()
	var config := MovementConfig.create(data, tickrate)
	assert_int(data.grapple_cooldown_ms).is_equal(GRAPPLE_COOLDOWN_MS)
	_assert_ticks(
		"grapple_cooldown_ticks",
		config.grapple_cooldown_ticks,
		COOLDOWN_TICKS[tickrate],
		tickrate,
	)
	assert_int(config.grapple_cooldown_ticks).is_equal(
		Ticks.from_ms(data.grapple_cooldown_ms, tickrate)
	)
	_assert_half_tick(
		"grapple_cooldown_ticks",
		config.grapple_cooldown_ticks,
		data.grapple_cooldown_ms,
		tickrate,
	)


# The block speed is the pull times the percentage: 18 × 50 / 100 = 9 m/s (movimento.md,
# "Gancho": "Trava").
func test_the_block_speed_is_9_mps_half_of_the_pull(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var data := _data()
	var config := MovementConfig.create(data, tickrate)
	assert_float(data.grapple_block_pct).is_equal_approx(GRAPPLE_BLOCK_PCT, HAIR)
	assert_float(config.grapple_block_speed).is_equal_approx(GRAPPLE_BLOCK_SPEED_MPS, HAIR)
	assert_float(config.grapple_block_speed).is_equal_approx(
		data.grapple_pull_speed_mps * data.grapple_block_pct / 100.0,
		HAIR,
	)
	assert_float(config.grapple_block_speed).is_less(config.grapple_pull_speed)


# The block speed follows the Resource: another pull or another percentage change it.
func test_the_block_speed_follows_a_duplicated_resource(
	tickrate: int,
	pull_mps: float,
	pct: float,
	expected_mps: float,
	_test_parameters := [
		[30, OTHER_PULL_MPS, GRAPPLE_BLOCK_PCT, 10.0],
		[60, OTHER_PULL_MPS, GRAPPLE_BLOCK_PCT, 10.0],
		[30, GRAPPLE_PULL_SPEED_MPS, OTHER_BLOCK_PCT, 4.5],
		[60, GRAPPLE_PULL_SPEED_MPS, OTHER_BLOCK_PCT, 4.5],
		[30, GRAPPLE_PULL_SPEED_MPS, 0.0, 0.0],
		[60, GRAPPLE_PULL_SPEED_MPS, 100.0, GRAPPLE_PULL_SPEED_MPS],
	],
) -> void:
	var data := _v0_copy()
	data.grapple_pull_speed_mps = pull_mps
	data.grapple_block_pct = pct
	assert_array(data.validate()).is_empty()
	var config := MovementConfig.create(data, tickrate)
	assert_float(config.grapple_block_speed).is_equal_approx(expected_mps, HAIR)
	assert_float(config.grapple_pull_speed).is_equal_approx(pull_mps, HAIR)


# The five copied numbers: the range, the minimum, the pull, the release distance and the aim's
# height, as they are.
func test_the_range_the_minimum_the_pull_the_release_and_the_aim_height_are_copied(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var config := MovementConfig.create(_data(), tickrate)
	assert_float(config.grapple_range).is_equal_approx(GRAPPLE_RANGE_M, HAIR)
	assert_float(config.grapple_min_range).is_equal_approx(GRAPPLE_MIN_RANGE_M, HAIR)
	assert_float(config.grapple_pull_speed).is_equal_approx(GRAPPLE_PULL_SPEED_MPS, HAIR)
	assert_float(config.grapple_release_distance).is_equal_approx(GRAPPLE_RELEASE_DISTANCE_M, HAIR)
	assert_float(config.aim_height).is_equal_approx(AIM_HEIGHT_M, HAIR)
	assert_float(config.aim_side).is_equal_approx(AIM_SIDE_M, HAIR)
	assert_float(config.grapple_min_range).is_less(config.grapple_range)
	assert_float(config.grapple_release_distance).is_less(config.grapple_range)


# The aim's side is copied as it is, sign included: 0,8 is the right shoulder, 0 the shoulder
# itself and a negative value the left one (movimento.md, "Câmera": "Ombro": "Com sinal";
# DEC-0045 §2). A metre, not a time: no tick conversion, the same at 30 and at 60.
func test_the_aim_side_is_copied_as_is_with_its_sign(
	tickrate: int,
	side_m: float,
	_test_parameters := [
		[30, AIM_SIDE_M],
		[60, AIM_SIDE_M],
		[30, 0.0],
		[60, 0.0],
		[30, -AIM_SIDE_M],
		[60, -AIM_SIDE_M],
		[30, 0.35],
		[60, -0.35],
	],
) -> void:
	var data := _v0_copy()
	data.aim_side_m = side_m
	assert_array(data.validate()).override_failure_message("a side of %s must pass" % side_m) \
			.is_empty()
	var config := MovementConfig.create(data, tickrate)
	var message := "aim_side for aim_side_m = %s at %d ticks is %s" % [
		side_m,
		tickrate,
		config.aim_side,
	]
	assert_float(config.aim_side).override_failure_message(message).is_equal_approx(side_m, HAIR)
	assert_float(config.aim_height).is_equal_approx(AIM_HEIGHT_M, HAIR)


func test_the_config_keeps_the_tickrate_it_was_created_for(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	assert_int(MovementConfig.create(_data(), tickrate).tickrate).is_equal(tickrate)


# The cable's time becomes the nearest tick with ties up for other values too: 125 ms is 4 at 30
# and 8 at 60 (both ties, up); 90 ms is 3 and 5; 17 ms is 1 at both; 8 ms is 0 at both and passes
# the data check, because nothing divides by it (TASK-10.6 notes: "a time, may be 0").
func test_the_cable_time_becomes_the_nearest_tick_with_ties_up(
	ms: int,
	tickrate: int,
	expected: int,
	_test_parameters := [
		[100, 30, 3],
		[100, 60, 6],
		[125, 30, 4],
		[125, 60, 8],
		[90, 30, 3],
		[90, 60, 5],
		[17, 30, 1],
		[17, 60, 1],
		[8, 30, 0],
		[8, 60, 0],
		[0, 30, 0],
		[0, 60, 0],
	],
) -> void:
	var data := _v0_copy()
	data.grapple_attach_ms = ms
	assert_array(data.validate()).is_empty()
	var config := MovementConfig.create(data, tickrate)
	var message := "grapple_attach_ticks for %d ms at %d ticks must be %d, found %d" % [
		ms,
		tickrate,
		expected,
		config.grapple_attach_ticks,
	]
	assert_int(config.grapple_attach_ticks).override_failure_message(message).is_equal(expected)
	assert_int(config.grapple_attach_ticks).is_equal(Ticks.from_ms(ms, tickrate))


# The cooldown by the same rule: 6025 ms is 181 at 30 and 362 at 60 (ties, up); 5990 ms is 180
# and 359; 8 ms is 0 at both and passes, because nothing divides by it.
func test_the_cooldown_becomes_the_nearest_tick_with_ties_up(
	ms: int,
	tickrate: int,
	expected: int,
	_test_parameters := [
		[6000, 30, 180],
		[6000, 60, 360],
		[6025, 30, 181],
		[6025, 60, 362],
		[5990, 30, 180],
		[5990, 60, 359],
		[17, 30, 1],
		[17, 60, 1],
		[8, 30, 0],
		[8, 60, 0],
		[0, 30, 0],
		[0, 60, 0],
	],
) -> void:
	var data := _v0_copy()
	data.grapple_cooldown_ms = ms
	assert_array(data.validate()).is_empty()
	var config := MovementConfig.create(data, tickrate)
	var message := "grapple_cooldown_ticks for %d ms at %d ticks must be %d, found %d" % [
		ms,
		tickrate,
		expected,
		config.grapple_cooldown_ticks,
	]
	assert_int(config.grapple_cooldown_ticks).override_failure_message(message).is_equal(expected)
	assert_int(config.grapple_cooldown_ticks).is_equal(Ticks.from_ms(ms, tickrate))
