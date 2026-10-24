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

# TASK-10.4 (movimento.md, "Dash").
const DASH_DISTANCE_M := 4.0 # "Distância"
const DASH_MS := 200 # "Duração"
const DASH_SPEED_MPS := 20.0 # "Deriva a velocidade: 20 m/s"
const DASH_EXIT_SPEED_MPS := 7.0 # "Velocidade na saída"
const DASH_COOLDOWN_MS := 400 # "Recarga"
const DASH_COST := 15.0 # "Custo"

# TASK-10.5 (movimento.md, "Corrida na parede"). 1,5 s of held height is 45 ticks at 30 and
# 90 at 60; 2,5 s of run is 75 and 150, exact multiples. The incline becomes the largest
# |normal.y| a wall may have, cos 80° = 0,1736 ("Parede válida"); the same-face angle becomes
# its cosine, cos 10° = 0,9848; the slide's gravity per tick is 10 % of the rise gravity per
# tick, 0,0595 m/s at 30 and 0,0327 at 60 (criterion 3); the wall jump of 1,2 m leaves at the
# jump's own speed, 6,25 m/s at 30 and 6,69 at 60 ("Pulo e ar", "No tick").
const WALL_MIN_INCLINE_DEG := 80.0 # "Inclinação mínima da parede"
const WALL_MAX_NORMAL_Y := 0.1736 # "Parede válida"
const WALL_ENTRY_SPEED_MPS := 4.0 # "Velocidade mínima para entrar"
const WALL_RUN_SPEED_MPS := 8.0 # "Velocidade na parede"
const WALL_MAX_SPEED_MPS := 12.0 # "Teto de velocidade na parede"
const WALL_RUN_MAX_MS := 2500 # "Duração máxima"
const WALL_HOLD_MS := 1500 # "Altura: mantida por 1,5 s"
const WALL_SLIDE_GRAVITY_PCT := 10.0 # "Altura: 10% da gravidade de subida"
const WALL_JUMP_HEIGHT_M := 1.2 # "Pulo da parede"
const WALL_JUMP_PUSH_MPS := 5.0 # "Pulo da parede: 5 m/s para fora"
const WALL_SAME_FACE_DEG := 10.0 # "Mesma parede, em números"
const WALL_SAME_FACE_COS := 0.9848 # cos 10°, arithmetic on the design's angle
const WALL_HOLD_TICKS: Dictionary[int, int] = { 30: 45, 60: 90 }
const WALL_RUN_MAX_TICKS: Dictionary[int, int] = { 30: 75, 60: 150 }
const WALL_SLIDE_GRAVITY_PER_TICK: Dictionary[int, float] = { 30: 0.0595, 60: 0.0327 }
const WALL_JUMP_SPEED_MPS: Dictionary[int, float] = { 30: 6.25, 60: 6.69 }
const FOUR_DECIMALS := 1e-4 # the design rounds these to four decimals, not a design number


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


# TASK-10.4 (movimento.md, "Dash"): 200 ms of dash is 6 ticks at 30 and 12 at 60, 400 ms of
# cooldown is 12 and 24, exact multiples by the same rule; the speed is the 4 m over the dash's
# ticks, 20 m/s at both rates; the exit speed (7 m/s) and the cost (15) are copied as they are.
func test_the_dash_times_become_ticks_and_the_speed_is_derived(
	tickrate: int,
	dash: int,
	cooldown: int,
	_test_parameters := [[30, 6, 12], [60, 12, 24]],
) -> void:
	var data := _data()
	var config := MovementConfig.create(data, tickrate)
	assert_int(data.dash_ms).is_equal(DASH_MS)
	assert_int(data.dash_cooldown_ms).is_equal(DASH_COOLDOWN_MS)
	_assert_ticks("dash_ticks", config.dash_ticks, dash, tickrate)
	_assert_ticks("dash_cooldown_ticks", config.dash_cooldown_ticks, cooldown, tickrate)
	assert_int(config.dash_ticks).is_equal(Ticks.from_ms(data.dash_ms, tickrate))
	assert_int(config.dash_cooldown_ticks).is_equal(Ticks.from_ms(data.dash_cooldown_ms, tickrate))
	_assert_half_tick("dash_ticks", config.dash_ticks, data.dash_ms, tickrate)
	_assert_half_tick(
		"dash_cooldown_ticks",
		config.dash_cooldown_ticks,
		data.dash_cooldown_ms,
		tickrate,
	)
	assert_float(data.dash_distance_m).is_equal_approx(DASH_DISTANCE_M, HAIR)
	assert_float(config.dash_speed).is_equal_approx(DASH_SPEED_MPS, HAIR)
	assert_float(config.dash_speed).is_equal_approx(
		data.dash_distance_m * tickrate / config.dash_ticks,
		HAIR,
	)
	assert_float(config.dash_exit_speed).is_equal_approx(DASH_EXIT_SPEED_MPS, HAIR)
	assert_float(config.dash_cost).is_equal_approx(DASH_COST, HAIR)


# TASK-10.5 (movimento.md, "Corrida na parede"): 1500 ms of held height is 45 ticks at 30 and
# 90 at 60, 2500 ms of run is 75 and 150, exact multiples by the same rule, within half a tick.
func test_the_wall_times_become_ticks(
	tickrate: int,
	hold: int,
	run_max: int,
	_test_parameters := [[30, 45, 75], [60, 90, 150]],
) -> void:
	var data := _data()
	var config := MovementConfig.create(data, tickrate)
	assert_int(data.wall_hold_ms).is_equal(WALL_HOLD_MS)
	assert_int(data.wall_run_max_ms).is_equal(WALL_RUN_MAX_MS)
	_assert_ticks("wall_hold_ticks", config.wall_hold_ticks, hold, tickrate)
	_assert_ticks("wall_run_max_ticks", config.wall_run_max_ticks, run_max, tickrate)
	assert_int(config.wall_hold_ticks).is_equal(WALL_HOLD_TICKS[tickrate])
	assert_int(config.wall_run_max_ticks).is_equal(WALL_RUN_MAX_TICKS[tickrate])
	assert_int(config.wall_hold_ticks).is_equal(Ticks.from_ms(data.wall_hold_ms, tickrate))
	assert_int(config.wall_run_max_ticks).is_equal(Ticks.from_ms(data.wall_run_max_ms, tickrate))
	_assert_half_tick("wall_hold_ticks", config.wall_hold_ticks, data.wall_hold_ms, tickrate)
	_assert_half_tick(
		"wall_run_max_ticks",
		config.wall_run_max_ticks,
		data.wall_run_max_ms,
		tickrate,
	)


# The three speeds and the push are copied as they are: 4, 8, 12 and 5 m/s.
func test_the_wall_speeds_and_the_push_are_copied(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var config := MovementConfig.create(_data(), tickrate)
	assert_float(config.wall_entry_speed).is_equal_approx(WALL_ENTRY_SPEED_MPS, HAIR)
	assert_float(config.wall_run_speed).is_equal_approx(WALL_RUN_SPEED_MPS, HAIR)
	assert_float(config.wall_max_speed).is_equal_approx(WALL_MAX_SPEED_MPS, HAIR)
	assert_float(config.wall_jump_push).is_equal_approx(WALL_JUMP_PUSH_MPS, HAIR)


# The incline of 80° becomes the largest |normal.y| a wall may have: cos 80° = 0,1736
# (movimento.md, "Corrida na parede": "Parede válida").
func test_the_wall_incline_becomes_the_max_normal_y_of_cos_80_degrees(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var data := _data()
	var config := MovementConfig.create(data, tickrate)
	assert_float(data.wall_min_incline_deg).is_equal_approx(WALL_MIN_INCLINE_DEG, HAIR)
	assert_float(config.wall_max_normal_y).is_equal_approx(WALL_MAX_NORMAL_Y, FOUR_DECIMALS)
	assert_float(config.wall_max_normal_y).is_equal_approx(
		cos(deg_to_rad(data.wall_min_incline_deg)),
		HAIR,
	)


# The same-face angle of 10° becomes its cosine, so the rule compares a dot product
# (movimento.md, "Corrida na parede": "Mesma parede, em números").
func test_the_wall_same_face_angle_becomes_its_cosine(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var data := _data()
	var config := MovementConfig.create(data, tickrate)
	assert_float(data.wall_same_face_deg).is_equal_approx(WALL_SAME_FACE_DEG, HAIR)
	assert_float(config.wall_same_face_cos).is_equal_approx(WALL_SAME_FACE_COS, FOUR_DECIMALS)
	assert_float(config.wall_same_face_cos).is_equal_approx(
		cos(deg_to_rad(data.wall_same_face_deg)),
		HAIR,
	)


# The slide's gravity per tick is 10 % of the rise gravity per tick: 0,0595 m/s at 30 and
# 0,0327 at 60 (TASK-10.5, criterion 3; movimento.md, "Corrida na parede": "Altura").
func test_the_wall_slide_gravity_is_10_percent_of_the_rise_gravity_per_tick(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var data := _data()
	var config := MovementConfig.create(data, tickrate)
	assert_float(data.wall_slide_gravity_pct).is_equal_approx(WALL_SLIDE_GRAVITY_PCT, HAIR)
	assert_float(config.wall_slide_gravity_per_tick).is_equal_approx(
		config.rise_gravity_per_tick * data.wall_slide_gravity_pct / 100.0,
		HAIR,
	)
	assert_float(config.wall_slide_gravity_per_tick).is_equal_approx(
		WALL_SLIDE_GRAVITY_PER_TICK[tickrate],
		FOUR_DECIMALS,
	)


# The wall jump's exit speed is derived for the tick from its own height, like the double
# jump's; for the design's 1,2 m it is the jump's own speed, 6,69 m/s at 60 and 6,25 at 30
# (movimento.md, "Pulo e ar", "No tick"; "Corrida na parede": "Pulo da parede").
func test_the_wall_jump_speed_is_derived_for_the_tick_from_its_height(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var data := _data()
	var config := MovementConfig.create(data, tickrate)
	assert_float(data.wall_jump_height_m).is_equal_approx(WALL_JUMP_HEIGHT_M, HAIR)
	assert_float(config.wall_jump_speed).is_equal_approx(
		WALL_JUMP_SPEED_MPS[tickrate],
		SPEED_TOLERANCE_MPS,
	)
	assert_float(config.wall_jump_speed).is_equal_approx(config.jump_speed, HAIR)
	var rise := config.rise_gravity_per_tick
	assert_float(config.wall_jump_speed).is_equal_approx(
		sqrt(2.0 * rise * tickrate * data.wall_jump_height_m) - rise / 2.0,
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
