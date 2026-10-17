# Criterion 1 of TASK-9: the design writes times in ms and the core works in ticks (DEC-0004,
# rule 3). Ticks.from_ms gives the nearest tick, and a tie rounds up (visao-geral.md, "O tempo e
# a física no estado"). Every game time below comes from docs/design/movimento.md, cited by
# section; the arithmetic examples are marked as such and are not design numbers.
extends GdUnitTestSuite

# The game runs at 60 ticks (DEC-0024); 30 is netfox's default and the second column of the
# design's conversion table (visao-geral.md, "O tempo e a física no estado").
const TICKRATES: Array[int] = [30, 60]

# Every time of movimento.md, in ms: "Chão" (150 until full speed, 100 until stopped); "Pulo e
# ar" (350 of rise, 280 of fall); "Perdão" (100 of coyote, 150 of buffer); "Corrida na parede"
# (2500 at most, 1500 holding the height); "Dash" (200 of duration, 400 of cooldown); "Gancho"
# (100 until it grabs, 6000 of cooldown); "Stamina" (800 before recovering).
const DESIGN_TIMES_MS: Array[int] = [
	150,
	100,
	350,
	280,
	100,
	150,
	2500,
	1500,
	200,
	400,
	100,
	6000,
	800,
]

# |ticks * 1000 - ms * tickrate| <= 500 is |ticks - ms * tickrate / 1000| <= 0.5 in integers,
# with the tie sitting exactly at 500 (the 150 ms buffer at 30: 5 ticks are 166.7 ms, +16.7 ms).
const HALF_TICK_IN_MS_TIMES_RATE := 500


func test_zero_ms_is_zero_ticks(tickrate: int, _test_parameters := [[30], [60]]) -> void:
	assert_int(Ticks.from_ms(0, tickrate)).is_equal(0)


# Exact multiples of the tick convert without error: 100 ms of coyote ("Perdão") is 3 ticks of
# 33.3 ms and 6 of 16.7 ms; 150 ms until full speed ("Chão") is 9 at 60; 350 ms of rise ("Pulo e
# ar") is 21 at 60; one second (arithmetic) is the tickrate itself.
func test_an_exact_multiple_of_the_tick_converts_without_error(
	ms: int,
	tickrate: int,
	expected: int,
	_test_parameters := [
		[100, 30, 3],
		[100, 60, 6],
		[150, 60, 9],
		[350, 60, 21],
		[1000, 30, 30],
		[1000, 60, 60],
	],
) -> void:
	assert_int(Ticks.from_ms(ms, tickrate)).is_equal(expected)


# Off the grid, the nearest tick wins: 280 ms of fall ("Pulo e ar") is 8.4 ticks at 30 and 16.8
# at 60. Below half a tick it is zero (8 ms at 60 and 16 ms at 30 are 0.48 of a tick), just above
# half it is one (9 ms at 60 is 0.54, 17 ms at 30 is 0.51); those four are arithmetic examples.
func test_a_time_off_the_grid_becomes_the_nearest_tick(
	ms: int,
	tickrate: int,
	expected: int,
	_test_parameters := [
		[280, 30, 8],
		[280, 60, 17],
		[8, 60, 0],
		[16, 30, 0],
		[9, 60, 1],
		[17, 30, 1],
	],
) -> void:
	assert_int(Ticks.from_ms(ms, tickrate)).is_equal(expected)


# A tie rounds up: 350 ms of rise ("Pulo e ar") is 10.5 ticks at 30 and becomes 11; 150 ms until
# full speed ("Chão") and of buffer ("Perdão") is 4.5 at 30 and becomes 5. The other rows are
# arithmetic: 50 ms at 30 is 1.5; at 60 a tie needs 50k + 25 ms, so 25 ms is 1.5 and 75 ms is 4.5.
func test_a_tie_rounds_up(
	ms: int,
	tickrate: int,
	expected: int,
	_test_parameters := [[350, 30, 11], [150, 30, 5], [50, 30, 2], [25, 60, 2], [75, 60, 5]],
) -> void:
	assert_int(Ticks.from_ms(ms, tickrate)).is_equal(expected)


func test_every_design_time_errs_by_half_a_tick_at_most() -> void:
	var violations: Array[String] = []
	for tickrate: int in TICKRATES:
		for ms: int in DESIGN_TIMES_MS:
			var ticks := Ticks.from_ms(ms, tickrate)
			var error := absi(ticks * 1000 - ms * tickrate)
			if error > HALF_TICK_IN_MS_TIMES_RATE:
				violations.append(
					"%d ms at %d ticks became %d ticks, more than half a tick off"
					% [ms, tickrate, ticks]
				)
	assert_array(violations).is_empty()


# Rounding never goes backwards: a longer time never gives fewer ticks (arithmetic, every ms of
# the first two seconds at both rates).
func test_a_longer_time_never_gives_fewer_ticks() -> void:
	var violations: Array[String] = []
	for tickrate: int in TICKRATES:
		var previous := Ticks.from_ms(0, tickrate)
		for ms: int in range(1, 2001):
			var ticks := Ticks.from_ms(ms, tickrate)
			if ticks < previous:
				violations.append(
					"%d ms gave %d ticks after %d ms gave %d, at %d ticks"
					% [ms, ticks, ms - 1, previous, tickrate]
				)
			previous = ticks
	assert_array(violations).is_empty()
