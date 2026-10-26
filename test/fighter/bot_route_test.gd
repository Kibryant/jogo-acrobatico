# TASK-9, round C2: the bot's route ("Números v0 do Claude"; rede.md §10) runs and jumps every 2 s,
# sideways along its own line: right for 2 s, left for 2 s, with a jump as each leg begins; from
# TASK-10.4 a dash in each leg, and from TASK-10.8 a double jump at the top of each leg's jump,
# 350 ms in (F-165), with the dash moved to 1200 ms, after the flight lands (BotRoute.DASH_AT_MS).
# A pure function of the steps since the route began, so every tick of two cycles is checked, at
# 60 and at 30 ticks, in one test case: gdUnit spends about 0.1 s on each, and the gate has a
# budget.
extends GdUnitTestSuite

const LEGS := 4
## The ticks of the 350 ms of the double jump and the 1200 ms of the dash, by hand, a tie rounding
## up (visao-geral.md, "O tempo e a física no estado"): 10.5 -> 11 and 36 at 30, 21 and 72 at 60.
const DOUBLE_JUMP_TICKS: Dictionary[int, int] = { 30: 11, 60: 21 }
const DASH_TICKS: Dictionary[int, int] = { 30: 36, 60: 72 }


func test_the_bot_runs_both_ways_jumps_double_jumps_at_the_top_and_dashes_on_the_floor() -> void:
	for tickrate: int in [60, 30]:
		var route := BotRoute.new(tickrate)
		assert_int(route.leg_ticks).is_equal(2 * tickrate)
		assert_int(route.double_jump_at_ticks).is_equal(DOUBLE_JUMP_TICKS[tickrate])
		assert_int(route.dash_at_ticks).is_equal(DASH_TICKS[tickrate])
		var wrong: Array[String] = []
		for leg: int in LEGS:
			var expected := Vector2.RIGHT if leg % 2 == 0 else Vector2.LEFT
			for offset: int in route.leg_ticks:
				var step := leg * route.leg_ticks + offset
				if route.move_at(step) != expected:
					wrong.append(
						"%d ticks, step %d: move %s" % [tickrate, step, route.move_at(step)]
					)
				if route.jumps_at(step) != (offset == 0):
					wrong.append(
						"%d ticks, step %d: jump %s" % [tickrate, step, route.jumps_at(step)]
					)
				var double_jumps := route.double_jumps_at(step)
				if double_jumps != (offset == route.double_jump_at_ticks):
					wrong.append(
						"%d ticks, step %d: double jump %s" % [tickrate, step, double_jumps]
					)
				if route.dashes_at(step) != (offset == route.dash_at_ticks):
					wrong.append(
						"%d ticks, step %d: dash %s" % [tickrate, step, route.dashes_at(step)]
					)
		assert_array(wrong).is_empty()
	# Before the route begins, the bot presses nothing.
	var early := BotRoute.new(60)
	for step: int in [-1, -early.leg_ticks, -early.leg_ticks + early.double_jump_at_ticks]:
		assert_vector(early.move_at(step)).is_equal(Vector2.ZERO)
		assert_bool(early.jumps_at(step) or early.double_jumps_at(step)).is_false()
		assert_bool(early.dashes_at(step)).is_false()
