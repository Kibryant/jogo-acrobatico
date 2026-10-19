# Criterion 1 of TASK-9 through the configuration: MovementConfig.create turns every time of
# movement_v0.tres into ticks at load, the nearest tick with ties up, with an error never above
# half a tick, at 30 and at 60 ticks (DEC-0004, rule 3; visao-geral.md, "O tempo e a física no
# estado" and "A configuração nasce na carga"). It also carries the values criterion 3 reads from
# the config: the slope limit, the run speed, the fall cap and the capsule (movimento.md, "O
# corpo", "Chão" and "Pulo e ar").
extends GdUnitTestSuite

const MOVEMENT_V0 := "res://data/movement_v0.tres"

const RUN_SPEED_MPS := 7.0 # movimento.md, "Chão"
const MAX_FALL_SPEED_MPS := 30.0 # movimento.md, "Pulo e ar"
const MAX_SLOPE_DEG := 45.0 # movimento.md, "O corpo": above it, it is not floor
const CAPSULE_HEIGHT_M := 1.8 # movimento.md, "O corpo"
const CAPSULE_RADIUS_M := 0.35 # movimento.md, "O corpo"
const HAIR := 1e-9 # floating-point slack, not a design number
const HALF_TICK_IN_MS_TIMES_RATE := 500 # |ticks * 1000 - ms * rate| <= 500 is half a tick

# TASK-10.1, criterion 7 (movimento.md, "Pulo e ar" and "Stamina"). The double jump of 1.0 m
# leaves at 6.10 m/s at 60 ticks and 5.68 at 30, by the same tick formula as the jump
# (movimento.md, "No tick": sqrt(2 · g · tickrate · h) − g / 2; the plan's 6.096 and 5.678);
# 800 ms of wait is 24 ticks at 30 and 48 at 60; 30 points per second is 1.0 per tick at 30 and
# 0.5 at 60.
const DOUBLE_JUMP_COST := 10.0 # movimento.md, "Pulo e ar": "Custo do pulo duplo"
const STAMINA_MAX := 100.0 # movimento.md, "Stamina": "Máximo"
const STAMINA_WAIT_MS := 800 # movimento.md, "Stamina": "Espera para recuperar"
const STAMINA_REGEN_PER_S := 30.0 # movimento.md, "Stamina": "Recuperação"
const DOUBLE_JUMP_SPEED_MPS: Dictionary[int, float] = { 30: 5.678, 60: 6.096 }
const SPEED_TOLERANCE_MPS := 0.01 # the plan's tolerance for the derived speed, not a design number
const STAMINA_WAIT_TICKS: Dictionary[int, int] = { 30: 24, 60: 48 }
const STAMINA_REGEN_PER_TICK: Dictionary[int, float] = { 30: 1.0, 60: 0.5 }


func _data() -> MovementData:
	var resource: Resource = load(MOVEMENT_V0)
	assert(
		resource is MovementData,
		"%s must load as a MovementData (TASK-9, part 1)" % MOVEMENT_V0,
	)
	return resource as MovementData


# By hand from movimento.md. At 30 ticks (33.3 ms each): 150 ms until full speed is 4.5 -> 5
# (tie up) and 100 ms until stopped is 3 ("Chão"); 350 ms of rise is 10.5 -> 11 (tie up) and
# 280 ms of fall is 8.4 -> 8 ("Pulo e ar"); 100 ms of coyote is 3 and 150 ms of buffer is
# 4.5 -> 5 ("Perdão"). At 60 ticks (16.7 ms each): 9 and 6; 21 and 16.8 -> 17; 6 and 9. The
# coyote and buffer rows match the table of visao-geral.md, "O tempo e a física no estado".
func test_every_time_becomes_the_nearest_tick_with_ties_up(
	tickrate: int,
	accel: int,
	stop: int,
	rise: int,
	fall: int,
	coyote: int,
	buffer: int,
	_test_parameters := [[30, 5, 3, 11, 8, 3, 5], [60, 9, 6, 21, 17, 6, 9]],
) -> void:
	var config := MovementConfig.create(_data(), tickrate)
	_assert_ticks("accel_ticks", config.accel_ticks, accel, tickrate)
	_assert_ticks("stop_ticks", config.stop_ticks, stop, tickrate)
	_assert_ticks("rise_ticks", config.rise_ticks, rise, tickrate)
	_assert_ticks("fall_ticks", config.fall_ticks, fall, tickrate)
	_assert_ticks("coyote_ticks", config.coyote_ticks, coyote, tickrate)
	_assert_ticks("buffer_ticks", config.buffer_ticks, buffer, tickrate)


func test_the_config_keeps_the_tickrate_it_was_created_for(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	assert_int(MovementConfig.create(_data(), tickrate).tickrate).is_equal(tickrate)


# The config converts with the same rule as Ticks.from_ms, from the ms the .tres holds.
func test_the_time_fields_follow_ticks_from_ms(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var data := _data()
	var config := MovementConfig.create(data, tickrate)
	assert_int(config.accel_ticks).is_equal(Ticks.from_ms(data.accel_time_ms, tickrate))
	assert_int(config.stop_ticks).is_equal(Ticks.from_ms(data.stop_time_ms, tickrate))
	assert_int(config.rise_ticks).is_equal(Ticks.from_ms(data.jump_rise_ms, tickrate))
	assert_int(config.fall_ticks).is_equal(Ticks.from_ms(data.jump_fall_ms, tickrate))
	assert_int(config.coyote_ticks).is_equal(Ticks.from_ms(data.coyote_ms, tickrate))
	assert_int(config.buffer_ticks).is_equal(Ticks.from_ms(data.buffer_ms, tickrate))


func test_every_time_field_errs_by_half_a_tick_at_most(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var data := _data()
	var config := MovementConfig.create(data, tickrate)
	_assert_half_tick("accel_ticks", config.accel_ticks, data.accel_time_ms, tickrate)
	_assert_half_tick("stop_ticks", config.stop_ticks, data.stop_time_ms, tickrate)
	_assert_half_tick("rise_ticks", config.rise_ticks, data.jump_rise_ms, tickrate)
	_assert_half_tick("fall_ticks", config.fall_ticks, data.jump_fall_ms, tickrate)
	_assert_half_tick("coyote_ticks", config.coyote_ticks, data.coyote_ms, tickrate)
	_assert_half_tick("buffer_ticks", config.buffer_ticks, data.buffer_ms, tickrate)


func test_the_run_speed_is_7_mps(tickrate: int, _test_parameters := [[30], [60]]) -> void:
	var config := MovementConfig.create(_data(), tickrate)
	assert_float(config.run_speed).is_equal_approx(RUN_SPEED_MPS, HAIR)


func test_the_fall_speed_cap_is_30_mps(tickrate: int, _test_parameters := [[30], [60]]) -> void:
	var config := MovementConfig.create(_data(), tickrate)
	assert_float(config.max_fall_speed).is_equal_approx(MAX_FALL_SPEED_MPS, HAIR)


# The engine judges the floor with this angle (TASK-9 plan); Godot wants it in radians.
func test_the_slope_limit_is_45_degrees_in_radians(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var config := MovementConfig.create(_data(), tickrate)
	assert_float(config.floor_max_angle).is_equal_approx(deg_to_rad(MAX_SLOPE_DEG), HAIR)


func test_the_capsule_is_1_8_m_tall_with_a_0_35_m_radius(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var config := MovementConfig.create(_data(), tickrate)
	assert_float(config.capsule_height).is_equal_approx(CAPSULE_HEIGHT_M, HAIR)
	assert_float(config.capsule_radius).is_equal_approx(CAPSULE_RADIUS_M, HAIR)


# The exit speed of the double jump, derived for the tick like the jump's: lower than the
# jump's, because its apex is lower (1.0 m against 1.2 m, movimento.md, "Pulo e ar").
func test_the_double_jump_speed_is_derived_for_the_tick(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var config := MovementConfig.create(_data(), tickrate)
	var message := "double_jump_speed at %d ticks is %.4f m/s, the plan says %.3f within %.2f" % [
		tickrate,
		config.double_jump_speed,
		DOUBLE_JUMP_SPEED_MPS[tickrate],
		SPEED_TOLERANCE_MPS,
	]
	assert_float(config.double_jump_speed).override_failure_message(message).is_equal_approx(
		DOUBLE_JUMP_SPEED_MPS[tickrate],
		SPEED_TOLERANCE_MPS,
	)
	assert_float(config.double_jump_speed).is_less(config.jump_speed)


func test_the_double_jump_cost_and_the_stamina_max_are_copied(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var config := MovementConfig.create(_data(), tickrate)
	assert_float(config.double_jump_cost).is_equal_approx(DOUBLE_JUMP_COST, HAIR)
	assert_float(config.stamina_max).is_equal_approx(STAMINA_MAX, HAIR)


func test_the_stamina_wait_becomes_48_ticks_at_60_and_24_at_30(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var data := _data()
	var config := MovementConfig.create(data, tickrate)
	assert_int(data.stamina_wait_ms).is_equal(STAMINA_WAIT_MS)
	_assert_ticks(
		"stamina_wait_ticks",
		config.stamina_wait_ticks,
		STAMINA_WAIT_TICKS[tickrate],
		tickrate,
	)
	assert_int(config.stamina_wait_ticks).is_equal(Ticks.from_ms(data.stamina_wait_ms, tickrate))
	_assert_half_tick(
		"stamina_wait_ticks",
		config.stamina_wait_ticks,
		data.stamina_wait_ms,
		tickrate,
	)


func test_the_stamina_regen_is_0_5_per_tick_at_60_and_1_0_at_30(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var data := _data()
	var config := MovementConfig.create(data, tickrate)
	assert_float(data.stamina_regen_per_s).is_equal_approx(STAMINA_REGEN_PER_S, HAIR)
	assert_float(config.stamina_regen_per_tick).is_equal_approx(
		STAMINA_REGEN_PER_TICK[tickrate],
		HAIR,
	)
	assert_float(config.stamina_regen_per_tick).is_equal_approx(
		data.stamina_regen_per_s / tickrate,
		HAIR,
	)


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
