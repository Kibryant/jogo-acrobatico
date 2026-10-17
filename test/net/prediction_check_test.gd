# Criterion 12 of TASK-9: a client's first result for its own fighter is held against the server's
# last one, tick by tick, with the SyncTest's tolerance (rede.md §4): the position within 1 mm,
# on_floor and mode equal. A tick that differs is corrected; a tick one side lacks inside the run
# is missing; the client's last ticks, whose input the server never received before it closed, are
# unconfirmed. Table-like cases share a test: gdUnit spends about 0.1 s on each test case.
extends GdUnitTestSuite

const FIGHTER := "Fighter0"
const FIRST := 100
## The server confirms FIRST..LAST_CONFIRMED; the client predicted FIRST..LAST_PREDICTED.
const LAST_CONFIRMED := 199
const LAST_PREDICTED := 205
const NONE := -1


func _sample(tick: int) -> TickRecord.Sample:
	return TickRecord.Sample.new(Vector3(0.01 * tick, 0.0, 9.0), true, FighterState.Mode.GROUND)


# The client's record of its fighter, without the tick client_skips.
func _client(client_skips := NONE) -> TickRecord:
	var client := TickRecord.new()
	for tick: int in range(FIRST, LAST_PREDICTED + 1):
		if tick != client_skips:
			client.keep_first(FIGHTER, tick, _sample(tick))
	return client


# The server's record of both fighters, without the tick server_skips and with server_adds, equal
# to the client's on every tick both have.
func _server(server_skips := NONE, server_adds := NONE) -> TickRecord:
	var server := TickRecord.new()
	for tick: int in range(FIRST, LAST_CONFIRMED + 1):
		if tick != server_skips:
			server.keep_last(FIGHTER, tick, _sample(tick))
		server.keep_last("Fighter1", tick, _sample(tick)) # the other client's fighter
	if server_adds != NONE:
		server.keep_last(FIGHTER, server_adds, _sample(server_adds))
	return server


func test_equal_records_pass_with_the_last_ticks_unconfirmed() -> void:
	var check := PredictionCheck.compare(_client(), _server())
	assert_array(check.problems).is_empty()
	assert_str(check.fighter).is_equal(FIGHTER)
	assert_int(check.checked).is_equal(LAST_CONFIRMED - FIRST + 1)
	assert_int(check.corrected).is_equal(0)
	assert_int(check.unconfirmed).is_equal(LAST_PREDICTED - LAST_CONFIRMED)
	assert_int(check.missing).is_equal(0)
	assert_int(check.first_tick).is_equal(FIRST)
	assert_int(check.last_tick).is_equal(LAST_PREDICTED)
	assert_bool(check.passed(check.checked)).is_true()
	# Fewer checked ticks than the run asks for fail it (TASK-9: 25 s of the 30).
	assert_bool(check.passed(check.checked + 1)).is_false()
	assert_str(check.summary(60)).contains("0 corrected")


# Each change below is made on the server's side of one tick; only the ones the SyncTest calls a
# divergence count as corrected.
func test_a_tick_is_corrected_beyond_1_mm_or_with_another_floor_or_mode() -> void:
	var cases: Array[Array] = [
		[Vector3(0.0015, 0, 0), true, FighterState.Mode.GROUND, true],
		[Vector3(0, -0.0011, 0), true, FighterState.Mode.GROUND, true],
		[Vector3(0.0009, 0, 0), true, FighterState.Mode.GROUND, false],
		[Vector3.ZERO, false, FighterState.Mode.GROUND, true],
		[Vector3.ZERO, true, FighterState.Mode.AIR, true],
	]
	for case: Array in cases:
		var server := _server()
		var shift: Vector3 = case[0]
		var on_floor: bool = case[1]
		var mode: int = case[2]
		var corrected: bool = case[3]
		server.keep_last(
			FIGHTER,
			150,
			TickRecord.Sample.new(_sample(150).position + shift, on_floor, mode),
		)
		var check := PredictionCheck.compare(_client(), server)
		var message := "%s, on_floor %s, mode %d" % [shift, on_floor, mode]
		assert_int(check.corrected).override_failure_message(message).is_equal(
			1 if corrected else 0
		)
		assert_int(check.checked).override_failure_message(message).is_equal(100)
		assert_bool(check.passed(1)).override_failure_message(message).is_equal(not corrected)
		if corrected:
			assert_str(check.summary(60)).override_failure_message(message).contains("tick 150")


# A hole in the client's ticks, a tick the server never confirmed before its last confirmation and
# a tick it confirmed that the client never predicted each fail the run; so do records that cannot
# be compared at all.
func test_missing_ticks_and_records_that_do_not_compare_fail() -> void:
	var holes: Array[Array] = [
		[_client(150), _server()],
		[_client(), _server(160)],
		[_client(), _server(NONE, FIRST - 1)],
	]
	for index: int in holes.size():
		var client: TickRecord = holes[index][0]
		var server: TickRecord = holes[index][1]
		var check := PredictionCheck.compare(client, server)
		var message := "hole %d" % index
		assert_int(check.missing).override_failure_message(message).is_equal(1)
		assert_bool(check.passed(1)).override_failure_message(message).is_false()
		assert_str(check.summary(60)).override_failure_message(message).contains("missing")

	var two_fighters := PredictionCheck.compare(_server(), _server())
	var no_fighter := PredictionCheck.compare(_client(), TickRecord.new())
	var unreadable := PredictionCheck.compare(TickRecord.from_text("garbage"), _server())
	for check: PredictionCheck in [two_fighters, no_fighter, unreadable]:
		assert_array(check.problems).is_not_empty()
		assert_bool(check.passed(0)).is_false()
		assert_str(check.summary(60)).contains("cannot compare")
