# TASK-9, round C2: the record of a networked run (TickRecord) keeps a state per fighter and tick,
# the first or the last one, writes itself as text and reads itself back, and says where each
# fighter went and how close two came. Table-like cases share a test: gdUnit spends about 0.1 s on
# each test case, and the gate has a budget.
extends GdUnitTestSuite

const HAIR := 1e-6 # m: the text keeps six decimals


func _sample(x: float, on_floor := true, mode := FighterState.Mode.GROUND) -> TickRecord.Sample:
	return TickRecord.Sample.new(Vector3(x, 0.5, -1.0), on_floor, mode)


func test_the_record_keeps_the_first_or_the_last_state_and_reads_back_its_text() -> void:
	var record := TickRecord.new()
	record.keep_first("Fighter1", 11, _sample(1.0))
	record.keep_first("Fighter1", 11, _sample(2.0)) # a resimulation: the first stays
	record.keep_last("Fighter0", 10, _sample(3.0))
	record.keep_last("Fighter0", 10, _sample(4.0, false, FighterState.Mode.AIR)) # the last wins
	record.keep_last("Fighter0", 12, _sample(-5.25))
	assert_array(record.fighters()).is_equal(["Fighter0", "Fighter1"])
	assert_array(record.ticks_of("Fighter0")).is_equal([10, 12])
	assert_int(record.size()).is_equal(3)
	assert_float(record.sample_at("Fighter1", 11).position.x).is_equal(1.0)
	assert_object(record.sample_at("Fighter1", 12)).is_null()
	assert_object(record.sample_at("Fighter9", 11)).is_null()

	var again := TickRecord.from_text(record.to_text())
	assert_array(again.errors).is_empty()
	assert_int(again.size()).is_equal(3)
	for fighter: String in record.fighters():
		for tick: int in record.ticks_of(fighter):
			var written := record.sample_at(fighter, tick)
			var read := again.sample_at(fighter, tick)
			var where := "%s at %d" % [fighter, tick]
			assert_object(read).override_failure_message(where).is_not_null()
			var off := read.position.distance_to(written.position)
			assert_float(off).override_failure_message(where).is_less_equal(HAIR)
			assert_bool(read.on_floor).override_failure_message(where).is_equal(written.on_floor)
			assert_int(read.mode).override_failure_message(where).is_equal(written.mode)


# A line that does not read leaves a message and no state; a text without the header is no record.
func test_a_line_that_does_not_read_is_reported_and_skipped() -> void:
	var lines := PackedStringArray(
		[
			TickRecord.HEADER,
			"Fighter0,10,1.0,0.0,9.0,1,0",
			"Fighter0,11,1.0,0.0,9.0,1",
			"Fighter0,eleven,1.0,0.0,9.0,1,0",
			"Fighter0,12,1.0,zero,9.0,1,0",
			"Fighter0,13,1.0,0.0,9.0,2,0",
			",14,1.0,0.0,9.0,1,0",
		],
	)
	var record := TickRecord.from_text("\r\n".join(lines))
	assert_int(record.size()).is_equal(1)
	assert_int(record.errors.size()).is_equal(5)
	var headless := TickRecord.from_text("Fighter0,10,1.0,0.0,9.0,1,0\n")
	assert_int(headless.size()).is_equal(0)
	assert_int(headless.errors.size()).is_equal(1)


# Where each fighter went, and the closest two came on a tick both have, measured across the floor.
func test_the_record_says_where_each_fighter_went_and_how_close_two_came() -> void:
	var record := TickRecord.new()
	record.keep_last("Fighter0", 1, TickRecord.Sample.new(Vector3(-6, 0, 9), true, 0))
	record.keep_last("Fighter0", 2, TickRecord.Sample.new(Vector3(2, 1.2, 9), false, 1))
	record.keep_last("Fighter1", 2, TickRecord.Sample.new(Vector3(2, 0, -1), true, 0))
	record.keep_last("Fighter1", 3, TickRecord.Sample.new(Vector3(2, 0, 8.5), true, 0))
	# Tick 2 is the only one both have: 10 m apart across the floor, whatever the height.
	assert_float(record.closest_approach()).is_equal_approx(10.0, HAIR)
	var box := record.extent("Fighter0")
	assert_vector(box.position).is_equal_approx(Vector3(-6, 0, 9), Vector3.ONE * HAIR)
	assert_vector(box.end).is_equal_approx(Vector3(2, 1.2, 9), Vector3.ONE * HAIR)
	assert_float(TickRecord.new().closest_approach()).is_equal(INF)
