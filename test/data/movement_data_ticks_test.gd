# TASK-9, part 3, round D1 (finding 5 of the part 1 reviewer): the data check, layer 3 of
# DEC-0027 §2, must catch a time that rounds to 0 ticks. The rules divide by four of the times
# of movimento.md (acceleration is speed / time, and the jump's gravities and exit speed come
# from the rise and fall times: the "Deriva" notes of "Chão" and "Pulo e ar"), and today only an
# assert in MovementConfig.create() stops a 0-tick time; an assert disappears in a release
# build, so MovementData.validate() has to report it, naming the field, before any build. A time
# becomes the nearest tick, and a tie rounds up (visao-geral.md, "O tempo e a física no estado";
# core/time/ticks.gd), and the check must hold at 60 ticks, the game's rate (DEC-0024), and at
# 30, netfox's default (glossario.md, "Ticks por segundo"). The two windows of "Perdão" may
# round to 0 ticks: nothing divides by them. Every case changes one field of a copy of
# movement_v0.tres, the design numbers.
extends GdUnitTestSuite

const MOVEMENT_V0 := "res://data/movement_v0.tres"

# The four times the rules divide by (movimento.md, the "Deriva" notes of "Chão" and "Pulo e
# ar"), as MovementData fields (TASK-9 plan, part 1).
const DIVIDING_TIME_FIELDS: Array[String] = [
	"accel_time_ms",
	"stop_time_ms",
	"jump_rise_ms",
	"jump_fall_ms",
]

# The two forgiveness windows (movimento.md, "Perdão"): nothing divides by them.
const WINDOW_FIELDS: Array[String] = ["coyote_ms", "buffer_ms"]

# The boundaries below are arithmetic on the rounding rule, ticks = floor((ms * rate + 500) /
# 1000) (core/time/ticks.gd), and are not design numbers.
# At 60 ticks a tick is 16.7 ms and half a tick is 8.3 ms: 8 ms is (480 + 500) / 1000 = 0 ticks,
# the largest time that still rounds to 0; 9 ms is (540 + 500) / 1000 = 1 tick, the smallest
# that rounds to 1.
# At 30 ticks a tick is 33.3 ms and half a tick is 16.7 ms: 16 ms is (480 + 500) / 1000 = 0
# ticks, the largest that still rounds to 0; 17 ms is (510 + 500) / 1000 = 1 tick, the smallest
# that rounds to 1.
# Fewer ticks per second never give more ticks for the same time, so 30 is the rate that binds:
# 9 ms and 16 ms are 1 tick at 60 but 0 at 30 (770 / 1000 and 980 / 1000) and must fail; 17 ms
# is 1 tick at both (1010 / 1000 and 1520 / 1000) and is the smallest time that passes.
const LARGEST_ZERO_TICK_MS_AT_60 := 8
const SMALLEST_ONE_TICK_MS_AT_60 := 9
const LARGEST_ZERO_TICK_MS_AT_30 := 16
const SMALLEST_ONE_TICK_MS_AT_30 := 17


# A copy of movement_v0.tres: load() caches the resource, so each case changes a duplicate and
# the baseline stays intact for every other test of the run.
func _v0_copy() -> MovementData:
	var resource: Resource = load(MOVEMENT_V0)
	assert(
		resource is MovementData,
		"%s must load as a MovementData (TASK-9, part 1)" % MOVEMENT_V0,
	)
	var copy: Resource = resource.duplicate()
	assert(copy is MovementData, "a duplicate of %s must still be a MovementData" % MOVEMENT_V0)
	return copy as MovementData


# Sets one time of the copy, guarding against a typo in the field's name: a misspelt field would
# leave the baseline untouched and pass the check for the wrong reason.
func _v0_copy_with(field: String, ms: int) -> MovementData:
	var data := _v0_copy()
	data.set(field, ms)
	assert_int(data.get(field)).override_failure_message("%s is not a field" % field).is_equal(ms)
	return data


# Exactly one message (one per impossible number, TASK-9 plan, part 1), and it names the field,
# so the gate's print says which number to fix. The wording beyond the name is the implementer's.
func _assert_one_message_naming(errors: PackedStringArray, field: String, why: String) -> void:
	assert_array(errors).override_failure_message(why).has_size(1)
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


# The boundaries of this suite tied to the tick conversion itself (core/time/ticks.gd): if the
# rounding rule ever changes, this table goes stale here, next to the arithmetic, and not only as
# a surprising pass or failure of the data check below.
func test_the_boundaries_of_this_suite_follow_the_tick_conversion(
	ms: int,
	tickrate: int,
	expected: int,
	_test_parameters := [
		[1, 30, 0],
		[1, 60, 0],
		[8, 30, 0],
		[8, 60, 0],
		[9, 30, 0],
		[9, 60, 1],
		[16, 30, 0],
		[16, 60, 1],
		[17, 30, 1],
		[17, 60, 1],
	],
) -> void:
	assert_int(Ticks.from_ms(ms, tickrate)).is_equal(expected)


# None: the design numbers (movimento.md, "Chão", "Pulo e ar" and "Perdão", through
# movement_v0.tres) pass, and so does the copy every case below starts from.
func test_the_copy_of_movement_v0_passes_the_data_check() -> void:
	assert_array(_v0_copy().validate()).is_empty()


# Failure, at both rates: 1 ms (the smallest positive time) and 8 ms (the largest time that still
# rounds to 0 at 60) are 0 ticks at 30 and at 60.
func test_a_dividing_time_below_half_a_tick_at_both_rates_is_rejected(
	field: String,
	ms: int,
	_test_parameters := [
		["accel_time_ms", 1],
		["accel_time_ms", 8],
		["stop_time_ms", 1],
		["stop_time_ms", 8],
		["jump_rise_ms", 1],
		["jump_rise_ms", 8],
		["jump_fall_ms", 1],
		["jump_fall_ms", 8],
	],
) -> void:
	var data := _v0_copy_with(field, ms)
	var why := "%s = %d ms rounds to 0 ticks at 30 and at 60 and must be rejected" % [field, ms]
	_assert_one_message_naming(data.validate(), field, why)


# Failure at 30 only: 9 ms (the smallest time that rounds to 1 tick at 60) and 16 ms (the
# largest that still rounds to 0 at 30) are 1 tick at 60 but 0 at 30. The check holds at both
# rates, so passing at 60 is not enough.
func test_a_dividing_time_of_one_tick_at_60_but_zero_at_30_is_rejected(
	field: String,
	ms: int,
	_test_parameters := [
		["accel_time_ms", 9],
		["accel_time_ms", 16],
		["stop_time_ms", 9],
		["stop_time_ms", 16],
		["jump_rise_ms", 9],
		["jump_rise_ms", 16],
		["jump_fall_ms", 9],
		["jump_fall_ms", 16],
	],
) -> void:
	var data := _v0_copy_with(field, ms)
	var why := "%s = %d ms rounds to 1 tick at 60 but 0 at 30 and must be rejected" % [field, ms]
	_assert_one_message_naming(data.validate(), field, why)


# Limit: 17 ms is 1 tick at 30 (1010 / 1000) and at 60 (1520 / 1000), the smallest time the
# rules can divide by at both rates.
func test_the_smallest_dividing_time_of_one_tick_at_both_rates_passes(
	field: String,
	_test_parameters := [["accel_time_ms"], ["stop_time_ms"], ["jump_rise_ms"], ["jump_fall_ms"]],
) -> void:
	var data := _v0_copy_with(field, SMALLEST_ONE_TICK_MS_AT_30)
	var why := "%s = %d ms is 1 tick at 30 and at 60 and must pass" % [field, data.get(field)]
	assert_array(data.validate()).override_failure_message(why).is_empty()


# The windows may round to 0 ticks at either rate: 1 ms and 8 ms are 0 at both, 16 ms is 0 at 30.
# Zero forgiveness is legitimate, because nothing divides by a window (movimento.md, "Perdão").
func test_a_forgiveness_window_that_rounds_to_zero_ticks_is_allowed(
	field: String,
	ms: int,
	_test_parameters := [
		["coyote_ms", 1],
		["coyote_ms", 8],
		["coyote_ms", 16],
		["buffer_ms", 1],
		["buffer_ms", 8],
		["buffer_ms", 16],
	],
) -> void:
	var data := _v0_copy_with(field, ms)
	var why := "%s = %d ms rounds to 0 ticks but nothing divides by it: it must pass" % [field, ms]
	assert_array(data.validate()).override_failure_message(why).is_empty()


# Many: one message per field, each naming its own field.
func test_four_dividing_times_at_zero_ticks_give_four_messages_each_naming_its_field() -> void:
	var data := _v0_copy()
	for field: String in DIVIDING_TIME_FIELDS:
		data.set(field, LARGEST_ZERO_TICK_MS_AT_60)
	var errors := data.validate()
	assert_array(errors).has_size(DIVIDING_TIME_FIELDS.size())
	for field: String in DIVIDING_TIME_FIELDS:
		_assert_some_message_names(errors, field)


# The same four at 16 ms, 1 tick at 60 but 0 at 30: still one message each.
func test_four_dividing_times_at_zero_ticks_at_30_only_give_four_messages() -> void:
	var data := _v0_copy()
	for field: String in DIVIDING_TIME_FIELDS:
		data.set(field, LARGEST_ZERO_TICK_MS_AT_30)
	var errors := data.validate()
	assert_array(errors).has_size(DIVIDING_TIME_FIELDS.size())
	for field: String in DIVIDING_TIME_FIELDS:
		_assert_some_message_names(errors, field)


# TASK-10.1, criterion 7: the wait of the stamina (800 ms, movimento.md, "Stamina") becomes
# ticks at load with the same rule, nearest tick with ties up: 24 at 30 and 48 at 60, exact
# multiples. The other rows are arithmetic, not design numbers: 825 ms is 24.75 -> 25 at 30 and
# 49.5 -> 50 at 60 (tie up); 8 ms rounds to 0 at both rates; 17 ms is the smallest 1 tick at both.
func test_the_stamina_wait_becomes_the_nearest_tick_with_ties_up(
	ms: int,
	tickrate: int,
	expected: int,
	_test_parameters := [
		[800, 30, 24],
		[800, 60, 48],
		[825, 30, 25],
		[825, 60, 50],
		[8, 30, 0],
		[8, 60, 0],
		[17, 30, 1],
		[17, 60, 1],
	],
) -> void:
	var data := _v0_copy_with("stamina_wait_ms", ms)
	var config := MovementConfig.create(data, tickrate)
	var message := "stamina_wait_ticks for %d ms at %d ticks must be %d, found %d" % [
		ms,
		tickrate,
		expected,
		config.stamina_wait_ticks,
	]
	assert_int(config.stamina_wait_ticks).override_failure_message(message).is_equal(expected)
	assert_int(config.stamina_wait_ticks).is_equal(Ticks.from_ms(ms, tickrate))


# Nothing divides by the wait (movimento.md, "Stamina": a bar that waits 0 ticks just regains
# at once), so a wait that rounds to 0 ticks passes, like the two windows of "Perdão".
func test_a_stamina_wait_that_rounds_to_zero_ticks_is_allowed(
	ms: int,
	_test_parameters := [[1], [8], [16]],
) -> void:
	var data := _v0_copy_with("stamina_wait_ms", ms)
	var why := "stamina_wait_ms = %d ms rounds to 0 ticks but nothing divides by it" % ms
	assert_array(data.validate()).override_failure_message(why).is_empty()


func test_the_stamina_wait_at_zero_ticks_adds_no_message_to_the_four() -> void:
	var data := _v0_copy()
	for field: String in DIVIDING_TIME_FIELDS:
		data.set(field, LARGEST_ZERO_TICK_MS_AT_60)
	data.stamina_wait_ms = LARGEST_ZERO_TICK_MS_AT_60
	var errors := data.validate()
	assert_array(errors).has_size(DIVIDING_TIME_FIELDS.size())
	for message: String in errors:
		var why := "stamina_wait_ms must not be rejected, got: %s" % message
		assert_str(message).override_failure_message(why).not_contains("stamina_wait_ms")


# The windows add nothing: all six times at 8 ms still give the four messages of the dividing
# times, none for coyote or buffer.
func test_the_windows_at_zero_ticks_add_no_message_to_the_four() -> void:
	var data := _v0_copy()
	for field: String in DIVIDING_TIME_FIELDS:
		data.set(field, LARGEST_ZERO_TICK_MS_AT_60)
	for field: String in WINDOW_FIELDS:
		data.set(field, LARGEST_ZERO_TICK_MS_AT_60)
	var errors := data.validate()
	assert_array(errors).has_size(DIVIDING_TIME_FIELDS.size())
	for field: String in WINDOW_FIELDS:
		for message: String in errors:
			var why := "%s must not be rejected, got: %s" % [field, message]
			assert_str(message).override_failure_message(why).not_contains(field)


# TASK-10.4: the duration of the dash (200 ms, movimento.md, "Dash") becomes ticks at load with
# the same rule, nearest tick with ties up: 6 at 30 and 12 at 60, exact multiples. The other
# rows are arithmetic, not design numbers: 225 ms is 6.75 -> 7 at 30 and 13.5 -> 14 at 60 (tie
# up); 190 ms is 5.7 -> 6 at 30 and 11.4 -> 11 at 60; 17 ms is the smallest 1 tick at both.
func test_the_dash_duration_becomes_the_nearest_tick_with_ties_up(
	ms: int,
	tickrate: int,
	expected: int,
	_test_parameters := [
		[200, 30, 6],
		[200, 60, 12],
		[225, 30, 7],
		[225, 60, 14],
		[190, 30, 6],
		[190, 60, 11],
		[17, 30, 1],
		[17, 60, 1],
	],
) -> void:
	var data := _v0_copy_with("dash_ms", ms)
	assert_array(data.validate()).is_empty()
	var config := MovementConfig.create(data, tickrate)
	var message := "dash_ticks for %d ms at %d ticks must be %d, found %d" % [
		ms,
		tickrate,
		expected,
		config.dash_ticks,
	]
	assert_int(config.dash_ticks).override_failure_message(message).is_equal(expected)
	assert_int(config.dash_ticks).is_equal(Ticks.from_ms(ms, tickrate))


# TASK-10.4: the cooldown of the dash (400 ms, movimento.md, "Dash": "Recarga") by the same
# rule: 12 at 30 and 24 at 60, exact. 425 ms is 12.75 -> 13 at 30 and 25.5 -> 26 at 60 (tie
# up); 8 ms rounds to 0 at both rates and passes, because nothing divides by the cooldown.
func test_the_dash_cooldown_becomes_the_nearest_tick_with_ties_up(
	ms: int,
	tickrate: int,
	expected: int,
	_test_parameters := [
		[400, 30, 12],
		[400, 60, 24],
		[425, 30, 13],
		[425, 60, 26],
		[8, 30, 0],
		[8, 60, 0],
		[17, 30, 1],
		[17, 60, 1],
	],
) -> void:
	var data := _v0_copy_with("dash_cooldown_ms", ms)
	assert_array(data.validate()).is_empty()
	var config := MovementConfig.create(data, tickrate)
	var message := "dash_cooldown_ticks for %d ms at %d ticks must be %d, found %d" % [
		ms,
		tickrate,
		expected,
		config.dash_cooldown_ticks,
	]
	assert_int(config.dash_cooldown_ticks).override_failure_message(message).is_equal(expected)
	assert_int(config.dash_cooldown_ticks).is_equal(Ticks.from_ms(ms, tickrate))


# The speed of the dash divides by its duration (movimento.md, "Dash": "Deriva a velocidade:
# 20 m/s"), so a duration that rounds to 0 ticks at 30 or at 60 is rejected, naming the field:
# 1 and 8 ms are 0 at both rates, 9 and 16 ms are 1 tick at 60 but 0 at 30.
func test_a_dash_duration_that_rounds_to_zero_ticks_is_rejected(
	ms: int,
	_test_parameters := [[1], [8], [9], [16]],
) -> void:
	var data := _v0_copy_with("dash_ms", ms)
	var why := "dash_ms = %d ms rounds to 0 ticks at 30 or at 60 and must be rejected" % ms
	_assert_one_message_naming(data.validate(), "dash_ms", why)


func test_the_smallest_dash_duration_of_one_tick_at_both_rates_passes() -> void:
	var data := _v0_copy_with("dash_ms", SMALLEST_ONE_TICK_MS_AT_30)
	var why := "dash_ms = %d ms is 1 tick at 30 and at 60 and must pass" % data.dash_ms
	assert_array(data.validate()).override_failure_message(why).is_empty()


# Nothing divides by the cooldown (movimento.md, "Dash": "Recarga": a dash that waits 0 ticks
# may just come out again), so a cooldown that rounds to 0 ticks passes, like the windows.
func test_a_dash_cooldown_that_rounds_to_zero_ticks_is_allowed(
	ms: int,
	_test_parameters := [[1], [8], [16]],
) -> void:
	var data := _v0_copy_with("dash_cooldown_ms", ms)
	var why := "dash_cooldown_ms = %d ms rounds to 0 ticks but nothing divides by it" % ms
	assert_array(data.validate()).override_failure_message(why).is_empty()


# Many: the dash's duration at 0 ticks is a fifth message next to the four dividing times.
func test_the_dash_duration_at_zero_ticks_adds_a_fifth_message_to_the_four() -> void:
	var data := _v0_copy()
	for field: String in DIVIDING_TIME_FIELDS:
		data.set(field, LARGEST_ZERO_TICK_MS_AT_60)
	data.dash_ms = LARGEST_ZERO_TICK_MS_AT_60
	var errors := data.validate()
	assert_array(errors).has_size(DIVIDING_TIME_FIELDS.size() + 1)
	for field: String in DIVIDING_TIME_FIELDS:
		_assert_some_message_names(errors, field)
	_assert_some_message_names(errors, "dash_ms")


func test_the_dash_cooldown_at_zero_ticks_adds_no_message_to_the_four() -> void:
	var data := _v0_copy()
	for field: String in DIVIDING_TIME_FIELDS:
		data.set(field, LARGEST_ZERO_TICK_MS_AT_60)
	data.dash_cooldown_ms = LARGEST_ZERO_TICK_MS_AT_60
	var errors := data.validate()
	assert_array(errors).has_size(DIVIDING_TIME_FIELDS.size())
	for message: String in errors:
		var why := "dash_cooldown_ms must not be rejected, got: %s" % message
		assert_str(message).override_failure_message(why).not_contains("dash_cooldown_ms")


# TASK-10.5, criterion 7: the run's duration (2500 ms, movimento.md, "Corrida na parede":
# "Duração máxima") becomes ticks at load with the same rule, nearest tick with ties up: 75 at
# 30 and 150 at 60, exact. The other rows are arithmetic, not design numbers: 2525 ms is
# 75.75 -> 76 at 30 and 151.5 -> 152 at 60 (tie up); 2490 ms is 74.7 -> 75 at 30 and
# 149.4 -> 149 at 60. The hold (1500 ms) stays below every value here.
func test_the_wall_run_max_becomes_the_nearest_tick_with_ties_up(
	ms: int,
	tickrate: int,
	expected: int,
	_test_parameters := [
		[2500, 30, 75],
		[2500, 60, 150],
		[2525, 30, 76],
		[2525, 60, 152],
		[2490, 30, 75],
		[2490, 60, 149],
	],
) -> void:
	var data := _v0_copy_with("wall_run_max_ms", ms)
	assert_array(data.validate()).is_empty()
	var config := MovementConfig.create(data, tickrate)
	var message := "wall_run_max_ticks for %d ms at %d ticks must be %d, found %d" % [
		ms,
		tickrate,
		expected,
		config.wall_run_max_ticks,
	]
	assert_int(config.wall_run_max_ticks).override_failure_message(message).is_equal(expected)
	assert_int(config.wall_run_max_ticks).is_equal(Ticks.from_ms(ms, tickrate))


# TASK-10.5, criterion 7: the held height (1500 ms, movimento.md, "Corrida na parede":
# "Altura: mantida por 1,5 s") by the same rule: 45 at 30 and 90 at 60, exact. 1525 ms is
# 45.75 -> 46 at 30 and 91.5 -> 92 at 60 (tie up); 1490 ms is 44.7 -> 45 at 30 and
# 89.4 -> 89 at 60; 8 ms rounds to 0 at both rates and 17 ms is the smallest 1 tick at both:
# nothing divides by the hold (the slide's gravity is a product), so both pass the check.
func test_the_wall_hold_becomes_the_nearest_tick_with_ties_up(
	ms: int,
	tickrate: int,
	expected: int,
	_test_parameters := [
		[1500, 30, 45],
		[1500, 60, 90],
		[1525, 30, 46],
		[1525, 60, 92],
		[1490, 30, 45],
		[1490, 60, 89],
		[8, 30, 0],
		[8, 60, 0],
		[17, 30, 1],
		[17, 60, 1],
	],
) -> void:
	var data := _v0_copy_with("wall_hold_ms", ms)
	assert_array(data.validate()).is_empty()
	var config := MovementConfig.create(data, tickrate)
	var message := "wall_hold_ticks for %d ms at %d ticks must be %d, found %d" % [
		ms,
		tickrate,
		expected,
		config.wall_hold_ticks,
	]
	assert_int(config.wall_hold_ticks).override_failure_message(message).is_equal(expected)
	assert_int(config.wall_hold_ticks).is_equal(Ticks.from_ms(ms, tickrate))


# The slide fills the run after the hold: the two conversions round on their own, so the slide
# has 30 ticks at 30 and 60 at 60 for the design's times, and 76 - 46 = 30 and 152 - 92 = 60
# for the tie-up pair, never a negative count.
func test_the_slide_ticks_are_the_run_max_minus_the_hold(
	run_max_ms: int,
	hold_ms: int,
	tickrate: int,
	expected: int,
	_test_parameters := [
		[2500, 1500, 30, 30],
		[2500, 1500, 60, 60],
		[2525, 1525, 30, 30],
		[2525, 1525, 60, 60],
	],
) -> void:
	var data := _v0_copy_with("wall_run_max_ms", run_max_ms)
	data.wall_hold_ms = hold_ms
	assert_array(data.validate()).is_empty()
	var config := MovementConfig.create(data, tickrate)
	assert_int(config.wall_run_max_ticks - config.wall_hold_ticks).is_equal(expected)


# Nothing divides by the wall times: a hold or a run that rounds to 0 ticks passes the check,
# like the windows of "Perdão", with the hold kept at or below the run max.
func test_wall_times_that_round_to_zero_ticks_are_allowed(
	ms: int,
	_test_parameters := [[1], [8], [16]],
) -> void:
	var data := _v0_copy_with("wall_run_max_ms", ms)
	data.wall_hold_ms = ms
	var why := "wall times of %d ms round to 0 ticks but nothing divides by them" % ms
	assert_array(data.validate()).override_failure_message(why).is_empty()


func test_the_wall_times_at_zero_ticks_add_no_message_to_the_four() -> void:
	var data := _v0_copy()
	for field: String in DIVIDING_TIME_FIELDS:
		data.set(field, LARGEST_ZERO_TICK_MS_AT_60)
	data.wall_run_max_ms = LARGEST_ZERO_TICK_MS_AT_60
	data.wall_hold_ms = LARGEST_ZERO_TICK_MS_AT_60
	var errors := data.validate()
	assert_array(errors).has_size(DIVIDING_TIME_FIELDS.size())
	for field: String in ["wall_run_max_ms", "wall_hold_ms"]:
		for message: String in errors:
			var why := "%s must not be rejected, got: %s" % [field, message]
			assert_str(message).override_failure_message(why).not_contains(field)
