# Criterion 1 of TASK-14: the movement in the replay's summary (tools/replay_summary.gd), counted
# as testes-e-entrega.md §4 says ("O resumo": "O movimento"; F-166 §7): the time per mode and the
# still time, each maneuver on the tick it shows in the state, the walls and the returns to the
# same wall, the distance on the plane, the highest point and the two height bands, and the
# longest flight. The ticks are written by hand (replay_summary_puppet.gd), with the fields the
# movement rules write on each event, and the summary is read only through its public interface,
# agreed in the TASK-14 plan.
extends GdUnitTestSuite

const ReplaySummary := preload("res://tools/replay_summary.gd")
const Tape := preload("res://test/tools/replay_summary_tape.gd")
const Puppet := preload("res://test/tools/replay_summary_puppet.gd")

const KEYS: Array[StringName] = [
	ReplaySummary.JUMP,
	ReplaySummary.DOUBLE_JUMP,
	ReplaySummary.WALL_RUN,
	ReplaySummary.WALL_JUMP,
	ReplaySummary.DASH,
	ReplaySummary.GRAPPLE,
	ReplaySummary.HEAD_LANDING,
]
const NORTH := &"Walls/North"
const SOUTH := &"Walls/South"
# Feet and heights below are the tests' own geometry, not design numbers; the two bands are the
# summary's (F-166 §7: 3 m and 10 m).
const TOLERANCE := 1e-4

var tape: Tape


func before_test() -> void:
	# The v0 numbers at the game's 60 ticks (DEC-0003).
	tape = Tape.new(Tape.movement_v0(), Tape.combat_v0())


func _puppet(feet := Vector3.ZERO) -> Puppet:
	return Puppet.new(tape, 0, feet)


func _report() -> ReplaySummary.FighterReport:
	return tape.summarize().fighter(0)


# Every maneuver key is there, with the expected count, and 0 for the keys not named.
func _assert_counts(
	actual: Dictionary[StringName, int],
	expected: Dictionary[StringName, int],
) -> void:
	for key: StringName in KEYS:
		assert_bool(actual.has(key)).override_failure_message("no key %s" % key).is_true()
		var count: int = actual.get(key, -1)
		var wanted: int = expected.get(key, 0)
		var message := "%s: expected %d, got %d" % [key, wanted, count]
		assert_int(count).override_failure_message(message).is_equal(wanted)


func _mode_ticks(report: ReplaySummary.FighterReport, mode: FighterState.Mode) -> int:
	var message := "no mode %d in mode_ticks" % mode
	assert_bool(report.mode_ticks.has(mode)).override_failure_message(message).is_true()
	var ticks: int = report.mode_ticks.get(mode, -1)
	return ticks

# --- None ---


func test_a_fighter_that_only_stands_is_on_the_ground_every_tick_and_nothing_else() -> void:
	_puppet().rest(10)
	var report := _report()
	assert_int(report.ticks).is_equal(10)
	assert_int(_mode_ticks(report, FighterState.Mode.GROUND)).is_equal(10)
	assert_int(_mode_ticks(report, FighterState.Mode.AIR)).is_equal(0)
	assert_int(_mode_ticks(report, FighterState.Mode.DASH)).is_equal(0)
	assert_int(_mode_ticks(report, FighterState.Mode.WALL_RUN)).is_equal(0)
	assert_int(_mode_ticks(report, FighterState.Mode.GRAPPLE)).is_equal(0)
	assert_int(report.still_ticks).is_equal(10)
	assert_float(report.distance).is_equal(0.0)
	_assert_counts(report.maneuvers, { })
	assert_bool(report.walls.is_empty()).is_true()
	assert_int(report.same_wall_runs).is_equal(0)
	assert_float(report.max_height).is_equal(0.0)
	assert_str(report.max_height_after).is_empty()
	assert_array(report.ticks_above).is_equal([0, 0])
	assert_int(report.longest_flight).is_equal(0)
	assert_int(report.longest_flight_start).is_equal(-1)
	_assert_counts(report.longest_flight_maneuvers, { })
	assert_int(report.lowest_health).is_equal(tape.combat.max_health)
	assert_int(report.refills).is_equal(0)
	assert_int(report.presses.size()).is_equal(0)
	assert_int(report.swings.size()).is_equal(0)


func test_the_height_bands_are_three_and_ten_metres() -> void:
	# F-166 §7, as testes-e-entrega.md §4 says: "o tempo a 3 m ou mais e a 10 m ou mais".
	assert_array(ReplaySummary.HEIGHT_BANDS).is_equal([3.0, 10.0])

# --- The time per mode ---


func test_time_per_mode_counts_the_mode_the_state_is_in_after_each_tick() -> void:
	var walker := _puppet()
	var dash_ticks := tape.movement.dash_ticks
	var attach_ticks := tape.movement.grapple_attach_ticks
	walker.rest(3) # ground: 3
	walker.jump() # air: 1
	walker.rest(4) # air: 4
	walker.enter_wall(NORTH) # wall: 1
	walker.rest(5) # wall: 5
	walker.wall_jump() # air: 1
	walker.rest(2) # air: 2
	walker.land() # ground: 1
	walker.dash() # dash: 1
	walker.rest(dash_ticks - 1) # dash: the rest of it
	walker.end_dash() # ground: 1
	walker.fire_grapple(Vector3(0.0, 8.0, -12.0)) # ground: 1, the cable flies
	walker.rest(attach_ticks - 1) # ground: the rest of the cable's flight
	walker.start_pull() # grapple: 1
	walker.rest(3) # grapple: 3
	walker.release_grapple() # air: 1
	walker.land() # ground: 1
	var report := _report()
	assert_int(report.ticks).is_equal(25 + dash_ticks + attach_ticks)
	assert_int(_mode_ticks(report, FighterState.Mode.GROUND)).is_equal(6 + attach_ticks)
	assert_int(_mode_ticks(report, FighterState.Mode.AIR)).is_equal(9)
	assert_int(_mode_ticks(report, FighterState.Mode.WALL_RUN)).is_equal(6)
	assert_int(_mode_ticks(report, FighterState.Mode.DASH)).is_equal(dash_ticks)
	assert_int(_mode_ticks(report, FighterState.Mode.GRAPPLE)).is_equal(4)


func test_still_time_is_the_ground_with_the_plane_velocity_exactly_zero() -> void:
	var walker := _puppet()
	walker.rest(3) # still: 3
	walker.velocity = Vector3(0.001, 0.0, 0.0)
	walker.rest(2) # on the ground, barely moving: not still
	walker.velocity = Vector3(0.0, 0.0, -7.0)
	walker.rest(2) # running: not still
	walker.velocity = Vector3.ZERO
	walker.rest(1) # still: 1
	walker.jump()
	walker.rest(2) # in the air with no velocity on the plane: not the ground, not still
	var report := _report()
	assert_int(_mode_ticks(report, FighterState.Mode.GROUND)).is_equal(8)
	assert_int(report.still_ticks).is_equal(4)

# --- The maneuvers ---


func test_a_jump_from_the_floor_counts_as_one_jump_however_long_the_flight() -> void:
	var walker := _puppet()
	walker.rest(2)
	walker.jump()
	walker.rest(20)
	walker.land()
	walker.rest(3)
	_assert_counts(_report().maneuvers, { ReplaySummary.JUMP: 1 })


func test_a_coyote_jump_after_a_ledge_counts_as_a_jump() -> void:
	var walker := _puppet()
	walker.rest(2)
	walker.walk_off()
	walker.rest(2)
	walker.coyote_jump()
	walker.rest(5)
	_assert_counts(_report().maneuvers, { ReplaySummary.JUMP: 1 })


func test_many_jumps_are_counted_one_per_flight() -> void:
	var walker := _puppet()
	for _flight: int in 3:
		walker.jump()
		walker.rest(4)
		walker.land()
		walker.rest(2)
	_assert_counts(_report().maneuvers, { ReplaySummary.JUMP: 3 })


func test_a_double_jump_counts_by_its_stamp_beside_the_jump_before_it() -> void:
	var walker := _puppet()
	walker.jump()
	walker.rest(5)
	walker.double_jump()
	walker.rest(8)
	walker.land()
	_assert_counts(_report().maneuvers, { ReplaySummary.JUMP: 1, ReplaySummary.DOUBLE_JUMP: 1 })


func test_a_double_jump_past_the_coyote_without_a_jump_is_not_a_jump() -> void:
	var walker := _puppet()
	walker.walk_off()
	# Past the coyote window, the press in the air is the double jump: jumps_used goes 0 to 2.
	walker.rest(tape.movement.coyote_ticks + 1)
	walker.double_jump()
	walker.rest(5)
	_assert_counts(_report().maneuvers, { ReplaySummary.DOUBLE_JUMP: 1 })


func test_a_wall_jump_is_counted_as_a_wall_jump_and_never_as_a_jump() -> void:
	var walker := _puppet()
	walker.jump()
	walker.rest(3)
	# Another wall renews the jumps, so the wall jump takes jumps_used from 0 to 1, as a jump does.
	walker.enter_wall(NORTH)
	walker.rest(4)
	walker.wall_jump()
	walker.rest(6)
	walker.land()
	_assert_counts(
		_report().maneuvers,
		{ ReplaySummary.JUMP: 1, ReplaySummary.WALL_RUN: 1, ReplaySummary.WALL_JUMP: 1 },
	)


func test_a_seam_that_changes_the_wall_id_inside_a_run_is_not_a_new_run() -> void:
	var walker := _puppet()
	walker.jump()
	walker.rest(2)
	walker.enter_wall(NORTH)
	walker.rest(2)
	walker.seam(SOUTH)
	walker.rest(2)
	walker.wall_jump()
	walker.rest(2)
	var report := _report()
	_assert_counts(
		report.maneuvers,
		{ ReplaySummary.JUMP: 1, ReplaySummary.WALL_RUN: 1, ReplaySummary.WALL_JUMP: 1 },
	)
	assert_int(_mode_ticks(report, FighterState.Mode.WALL_RUN)).is_equal(6)
	var north_runs: int = report.walls.get(NORTH, 0)
	var south_runs: int = report.walls.get(SOUTH, 0)
	assert_int(north_runs).is_equal(1)
	assert_int(south_runs).is_equal(0)
	assert_int(report.same_wall_runs).is_equal(0)


func test_a_dash_counts_once_though_its_stamp_stays_in_the_state() -> void:
	var walker := _puppet()
	walker.rest(2)
	walker.dash()
	walker.rest(tape.movement.dash_ticks - 1)
	walker.end_dash()
	walker.rest(30)
	_assert_counts(_report().maneuvers, { ReplaySummary.DASH: 1 })


func test_many_dashes_are_each_counted() -> void:
	var walker := _puppet()
	for _dash: int in 3:
		walker.dash()
		walker.rest(tape.movement.dash_ticks - 1)
		walker.end_dash()
		walker.rest(tape.movement.dash_cooldown_ticks)
	_assert_counts(_report().maneuvers, { ReplaySummary.DASH: 3 })


func test_a_grapple_counts_on_the_tick_its_hook_bites() -> void:
	var walker := _puppet()
	walker.rest(2)
	walker.fire_grapple(Vector3(0.0, 8.0, -12.0))
	walker.rest(tape.movement.grapple_attach_ticks - 1)
	walker.start_pull()
	walker.rest(10)
	walker.release_grapple()
	walker.rest(5)
	walker.land()
	_assert_counts(_report().maneuvers, { ReplaySummary.GRAPPLE: 1 })


func test_a_landing_on_a_head_counts_once_however_long_the_feet_stay_there() -> void:
	var walker := _puppet()
	walker.jump()
	walker.rest(3)
	walker.land_on_head()
	walker.rest(6)
	walker.slide_off_head()
	walker.rest(2)
	walker.land()
	_assert_counts(_report().maneuvers, { ReplaySummary.JUMP: 1, ReplaySummary.HEAD_LANDING: 1 })

# --- The walls ---


func test_walls_count_the_runs_started_on_each_and_the_returns_to_the_same_wall() -> void:
	var walker := _puppet()
	walker.jump()
	walker.rest(2)
	walker.enter_wall(NORTH)
	walker.rest(3)
	walker.wall_jump()
	walker.rest(2)
	walker.enter_wall(SOUTH)
	walker.rest(3)
	walker.wall_jump()
	walker.rest(2)
	# The state held SOUTH: NORTH is another wall, not a return.
	walker.enter_wall(NORTH)
	walker.rest(3)
	walker.wall_jump()
	walker.rest(2)
	# The state still holds NORTH from the run before: a return to the same wall, in the same
	# flight (DEC-0047; DEC-0048).
	walker.enter_wall(NORTH)
	walker.rest(3)
	walker.wall_jump()
	walker.rest(2)
	walker.land()
	var report := _report()
	var north_runs: int = report.walls.get(NORTH, 0)
	var south_runs: int = report.walls.get(SOUTH, 0)
	assert_int(north_runs).is_equal(3)
	assert_int(south_runs).is_equal(1)
	assert_int(report.walls.size()).is_equal(2)
	assert_int(report.same_wall_runs).is_equal(1)
	_assert_counts(
		report.maneuvers,
		{ ReplaySummary.JUMP: 1, ReplaySummary.WALL_RUN: 4, ReplaySummary.WALL_JUMP: 4 },
	)


func test_a_run_on_the_same_wall_after_the_floor_is_not_a_return() -> void:
	var walker := _puppet()
	for _flight: int in 2:
		walker.jump()
		walker.rest(2)
		walker.enter_wall(NORTH)
		walker.rest(3)
		walker.wall_jump()
		walker.rest(2)
		# The floor clears the wall of the state.
		walker.land()
		walker.rest(2)
	var report := _report()
	var north_runs: int = report.walls.get(NORTH, 0)
	assert_int(north_runs).is_equal(2)
	assert_int(report.same_wall_runs).is_equal(0)

# --- The distance on the plane ---


func test_one_tick_alone_travels_nothing() -> void:
	_puppet(Vector3(10.0, 0.0, 10.0)).rest(1)
	assert_float(_report().distance).is_equal(0.0)


func test_distance_sums_the_plane_displacement_from_the_second_tick_on() -> void:
	# The spawn far from the origin: the first tick has no tick before it, so it adds nothing.
	var walker := _puppet(Vector3(10.0, 0.0, 10.0))
	walker.rest(1)
	walker.rest_at(Vector3(13.0, 0.0, 14.0)) # 3 and 4 on the plane: 5 m
	walker.rest_at(Vector3(13.0, 2.0, 14.0)) # straight up: nothing on the plane
	walker.rest_at(Vector3(7.0, 2.5, 6.0)) # 6 and 8 on the plane: 10 m
	walker.rest(3) # standing still: nothing
	assert_float(_report().distance).is_equal_approx(15.0, TOLERANCE)

# --- The height ---


func test_a_high_spawn_is_the_highest_point_on_the_first_tick_with_no_maneuver() -> void:
	_puppet(Vector3(0.0, 5.0, 0.0)).rest(4)
	var report := _report()
	assert_float(report.max_height).is_equal_approx(5.0, TOLERANCE)
	assert_int(report.max_height_tick).is_equal(0)
	assert_str(report.max_height_after).is_empty()


func test_highest_point_keeps_the_first_tick_it_was_reached_and_the_jump_before_it() -> void:
	var walker := _puppet()
	walker.rest(2) # ticks 0 and 1
	walker.position.y = 0.4
	walker.jump() # tick 2
	walker.rest_at(Vector3(0.0, 0.9, 0.0)) # tick 3
	walker.rest_at(Vector3(0.0, 1.2, 0.0)) # tick 4: the top
	walker.rest_at(Vector3(0.0, 1.2, 0.0)) # tick 5: the same height again
	walker.rest_at(Vector3(0.0, 0.7, 0.0)) # tick 6
	walker.position.y = 0.0
	walker.land() # tick 7
	# A maneuver after the top is not the one that took the feet there.
	walker.dash() # tick 8
	walker.rest(3)
	var report := _report()
	assert_float(report.max_height).is_equal_approx(1.2, TOLERANCE)
	assert_int(report.max_height_tick).is_equal(4)
	assert_str(report.max_height_after).is_equal(ReplaySummary.JUMP)


func test_a_maneuver_on_the_very_tick_of_the_highest_point_is_the_last_before_it() -> void:
	var walker := _puppet()
	walker.position.y = 0.3
	walker.jump() # tick 0
	walker.rest_at(Vector3(0.0, 0.8, 0.0)) # tick 1
	walker.position.y = 1.0
	walker.double_jump() # tick 2
	walker.rest_at(Vector3(0.0, 1.6, 0.0)) # tick 3
	walker.position.y = 2.0
	walker.enter_wall(NORTH) # tick 4: the top, and the run starts on it
	walker.rest_at(Vector3(0.0, 1.9, 0.0)) # tick 5
	walker.position.y = 1.8
	walker.wall_jump() # tick 6: lower, after the top
	walker.rest_at(Vector3(0.0, 1.5, 0.0))
	var report := _report()
	assert_float(report.max_height).is_equal_approx(2.0, TOLERANCE)
	assert_int(report.max_height_tick).is_equal(4)
	assert_str(report.max_height_after).is_equal(ReplaySummary.WALL_RUN)


func test_time_at_height_counts_a_tick_exactly_on_each_band_and_not_one_just_below() -> void:
	var walker := _puppet()
	walker.jump()
	# Feet just below 3 m, exactly 3 m, just below 10 m, exactly 10 m, above, and back down.
	for height: float in [2.99, 3.0, 9.99, 10.0, 12.0, 3.0, 2.0]:
		walker.rest_at(Vector3(0.0, height, 0.0))
	var report := _report()
	# At 3 m or more: 3.0, 9.99, 10.0, 12.0 and 3.0 again. At 10 m or more: 10.0 and 12.0.
	assert_array(report.ticks_above).is_equal([5, 2])
	assert_float(report.max_height).is_equal_approx(12.0, TOLERANCE)

# --- The longest flight ---


func test_one_flight_runs_from_the_jump_tick_to_the_last_tick_off_the_floor() -> void:
	var walker := _puppet()
	walker.rest(3) # ticks 0 to 2
	walker.jump() # tick 3
	walker.rest(5) # ticks 4 to 8
	walker.land() # tick 9: standing again
	walker.rest(4)
	var report := _report()
	assert_int(report.longest_flight).is_equal(6)
	assert_int(report.longest_flight_start).is_equal(3)
	_assert_counts(report.longest_flight_maneuvers, { ReplaySummary.JUMP: 1 })


func test_longest_flight_is_the_longest_of_many_with_only_its_own_maneuvers() -> void:
	var walker := _puppet()
	walker.rest(2) # ticks 0 and 1
	walker.jump() # tick 2: a flight of 4 ticks
	walker.rest(3) # ticks 3 to 5
	walker.land() # tick 6
	walker.dash() # tick 7: on the floor, in no flight
	walker.rest(tape.movement.dash_ticks - 1)
	walker.end_dash()
	var start := walker.tick
	walker.jump() # a flight of 11 ticks
	walker.rest(2)
	walker.double_jump()
	walker.rest(2)
	walker.enter_wall(NORTH)
	walker.rest(2)
	walker.wall_jump()
	walker.rest(1)
	walker.land()
	walker.rest(2)
	walker.jump() # a later, shorter flight of 3 ticks
	walker.rest(2)
	walker.land()
	var report := _report()
	assert_int(report.longest_flight).is_equal(11)
	assert_int(report.longest_flight_start).is_equal(start)
	_assert_counts(
		report.longest_flight_maneuvers,
		{
			ReplaySummary.JUMP: 1,
			ReplaySummary.DOUBLE_JUMP: 1,
			ReplaySummary.WALL_RUN: 1,
			ReplaySummary.WALL_JUMP: 1,
		},
	)
	_assert_counts(
		report.maneuvers,
		{
			ReplaySummary.JUMP: 3,
			ReplaySummary.DOUBLE_JUMP: 1,
			ReplaySummary.WALL_RUN: 1,
			ReplaySummary.WALL_JUMP: 1,
			ReplaySummary.DASH: 1,
		},
	)


func test_a_dash_on_the_floor_is_no_flight() -> void:
	var walker := _puppet()
	walker.rest(2)
	walker.dash()
	walker.rest(tape.movement.dash_ticks - 1)
	walker.end_dash()
	walker.rest(2)
	var report := _report()
	assert_int(report.longest_flight).is_equal(0)
	assert_int(report.longest_flight_start).is_equal(-1)


func test_standing_on_a_head_is_still_the_flight() -> void:
	var walker := _puppet()
	walker.rest(1) # tick 0
	walker.jump() # tick 1
	walker.rest(3) # ticks 2 to 4
	walker.land_on_head() # tick 5: the engine says floor, the rules say air
	walker.rest(4) # ticks 6 to 9
	walker.slide_off_head() # tick 10
	walker.rest(2) # ticks 11 and 12
	walker.land() # tick 13
	walker.rest(2)
	var report := _report()
	assert_int(report.longest_flight).is_equal(12)
	assert_int(report.longest_flight_start).is_equal(1)
	_assert_counts(
		report.longest_flight_maneuvers,
		{ ReplaySummary.JUMP: 1, ReplaySummary.HEAD_LANDING: 1 },
	)


func test_a_flight_cut_by_the_end_of_the_replay_counts_up_to_the_last_tick() -> void:
	var walker := _puppet()
	walker.rest(2) # ticks 0 and 1
	walker.jump() # tick 2
	walker.rest(7) # ticks 3 to 9, the last of the replay
	var report := _report()
	assert_int(report.longest_flight).is_equal(8)
	assert_int(report.longest_flight_start).is_equal(2)
	_assert_counts(report.longest_flight_maneuvers, { ReplaySummary.JUMP: 1 })
