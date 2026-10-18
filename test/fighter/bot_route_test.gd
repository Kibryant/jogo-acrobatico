# TASK-9, round C2: the bot's route ("Números v0 do Claude"; rede.md §10) runs and jumps every 2 s,
# sideways along its own line: right for 2 s, left for 2 s, with a jump as each leg begins. A pure
# function of the steps since the route began, so every tick of two cycles is checked, at 60 and
# at 30 ticks, in one test case: gdUnit spends about 0.1 s on each, and the gate has a budget.
extends GdUnitTestSuite

const LEGS := 4


func test_the_bot_runs_right_then_left_and_jumps_as_each_2_s_leg_begins() -> void:
	for tickrate: int in [60, 30]:
		var route := BotRoute.new(tickrate)
		assert_int(route.leg_ticks).is_equal(2 * tickrate)
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
		assert_array(wrong).is_empty()
