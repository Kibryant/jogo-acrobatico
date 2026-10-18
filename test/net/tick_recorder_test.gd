# TASK-9, round C2: the recorder of --record (TickRecorder) writes down the state of each tick
# netfox simulated a fighter on, and only reads: the same bot on the same route ends in the same
# place with the recorder and without it. In Sozinho, with netfox's ticks advanced by hand
# (test/support/netfox_ticks.gd), nothing is resimulated, so the first and the last result of
# every tick are the same.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const MATCH_SCENE := preload("res://match/match.tscn")

## Loops of one tick: the bot's first leg, with its jump and its landing, and some more.
const LOOPS := 90


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	NetfoxTicks.reset()


func test_the_recorder_keeps_each_simulated_tick_and_changes_nothing() -> void:
	var with_recorders := await _play(true)
	var without := await _play(false)
	var first: TickRecord = with_recorders["first"]
	var last: TickRecord = with_recorders["last"]
	var fighter: String = with_recorders["fighter"]
	var start_tick: int = with_recorders["start_tick"]
	var expected_ticks: Array[int] = []
	expected_ticks.assign(range(start_tick, start_tick + LOOPS))
	assert_array(first.fighters()).is_equal([fighter])
	assert_array(first.ticks_of(fighter)).is_equal(expected_ticks)
	assert_str(last.to_text()).is_equal(first.to_text())
	# The body's last state is the last tick's result, and the run without the recorder ends there.
	var end: Vector3 = with_recorders["end"]
	var last_sample := first.sample_at(fighter, start_tick + LOOPS - 1)
	assert_vector(last_sample.position).is_equal_approx(end, Vector3.ONE * 1e-6)
	assert_vector(without["end"]).is_equal(end)
	# The bot jumped on its first tick, so the record holds the air as well as the floor.
	assert_bool(first.sample_at(fighter, start_tick).on_floor).is_false()


# The bot plays a fighter for LOOPS ticks, followed by a recorder of each kind when recording; the
# records outlive the recorders, which leave with the match.
func _play(recording: bool) -> Dictionary:
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	var game_match := node as Match
	add_child(game_match)
	var fighter := game_match.spawn_fighter(0, multiplayer.get_unique_id())
	await get_tree().process_frame
	await get_tree().physics_frame
	var bot := game_match.let_bot_play(fighter)
	var played := { "fighter": String(fighter.name), "start_tick": bot.start_tick }
	if recording:
		for keep: TickRecorder.Keep in [TickRecorder.Keep.FIRST, TickRecorder.Keep.LAST]:
			var recorder := TickRecorder.new("unused", keep)
			game_match.add_child(recorder)
			recorder.follow(fighter)
			played["first" if keep == TickRecorder.Keep.FIRST else "last"] = recorder.record
	NetfoxTicks.run_loops(LOOPS)
	played["end"] = fighter.position
	game_match.free()
	NetfoxTicks.reset()
	return played
