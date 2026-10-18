# Criterion 16 of TASK-9: the reference, layer 4 of DEC-0027 §2 (F-044 §2). A fixed bot route of
# 1,200 ticks (reference_route.gd) plays in the real arena with a frozen copy of the movement
# numbers, only for this test (frozen_movement.tres), and its path must match the stored trace,
# test/reference/route.trace, byte for byte, like a Jest snapshot: a code change that moves the
# path fails the gate, and tuning data/movement_v0.tres does not. The CI runs the same test on
# Linux, against the same stored trace (F-042 §5).
# When a change moves the path on purpose, record again with `bash tools/record_reference.sh` and
# say why in the commit message.
extends GdUnitTestSuite

const ReferenceRun := preload("res://test/reference/reference_run.gd")

const RECORD_COMMAND := "bash tools/record_reference.sh"
# How many differing ticks the failure message lists.
const SHOWN_DIFFERENCES := 5


func test_the_route_follows_the_stored_trace() -> void:
	# A setting another test left behind would move every tick (move_and_slide scales by it).
	assert_float(Engine.time_scale).override_failure_message("Engine.time_scale is not 1").is_equal(
		1.0
	)
	var started := Time.get_ticks_msec()
	var result := await ReferenceRun.new().play(self)
	var spent := Time.get_ticks_msec() - started
	var produced_sha := result.trace.sha256_text()
	var stored := _stored_trace()
	var stored_sha := "none" if stored.is_empty() else stored.sha256_text()
	print(
		(
			"Reference: %d ticks in %.0f ms (%d ms with the setup); sha256 produced %s, stored %s"
			% [
				ReferenceRun.ReferenceRoute.TICKS,
				result.run_usec / 1000.0,
				spent,
				produced_sha,
				stored_sha,
			]
		)
	)
	print("Reference paths: %s" % result.paths.summary())

	# The Match played the frozen copy, never data/movement_v0.tres.
	assert_str(result.movement_path).is_equal(ReferenceRun.FROZEN_MOVEMENT_PATH)
	var gaps := "\n".join(result.paths.missing())
	var lost := "the route no longer covers what it claims (reference_route.gd):\n%s" % gaps
	assert_array(result.paths.missing()).override_failure_message(lost).is_empty()

	if stored.is_empty():
		var none := (
			"no stored trace at %s: record one with `%s`, and say why in the commit message"
			% [ReferenceRun.TRACE_PATH, RECORD_COMMAND]
		)
		fail(none)
		return
	if stored.contains("\r"):
		fail(
			"%s has CR line endings: .gitattributes keeps it LF, check it out again"
			% ReferenceRun.TRACE_PATH
		)
		return
	if produced_sha != stored_sha:
		fail(_difference(result.trace, stored))


# The frozen copy is design data like any other: it passes the data check (DEC-0027 §2, layer 3).
func test_the_frozen_movement_numbers_pass_the_data_check() -> void:
	var resource: Resource = load(ReferenceRun.FROZEN_MOVEMENT_PATH)
	assert_bool(resource is MovementData).is_true()
	if resource is MovementData:
		var data := resource as MovementData
		assert_array(data.validate()).is_empty()


func _stored_trace() -> String:
	if not FileAccess.file_exists(ReferenceRun.TRACE_PATH):
		return ""
	return FileAccess.get_file_as_string(ReferenceRun.TRACE_PATH)


# Where the two paths part: the first differing ticks and the largest distance between the two
# positions of the same tick, over the whole route.
func _difference(produced: String, stored: String) -> String:
	var mine := produced.split("\n", false)
	var theirs := stored.split("\n", false)
	var first_ticks := PackedStringArray()
	var first_tick := -1
	var largest := 0.0
	var largest_tick := -1
	var common := mini(mine.size(), theirs.size())
	for index: int in common:
		if mine[index] == theirs[index]:
			continue
		if first_tick < 0:
			first_tick = index
		if first_ticks.size() < SHOWN_DIFFERENCES:
			first_ticks.append("  produced %s, stored %s" % [mine[index], theirs[index]])
		var distance := _position(mine[index]).distance_to(_position(theirs[index]))
		if distance > largest:
			largest = distance
			largest_tick = index
	var lines := PackedStringArray()
	lines.append(
		"the path differs from %s (%d lines produced, %d stored)"
		% [ReferenceRun.TRACE_PATH, mine.size(), theirs.size()],
	)
	if first_tick < 0:
		lines.append("the first %d ticks are equal; the two traces differ in length" % common)
	else:
		lines.append("first differing tick: %d" % first_tick)
		lines.append(
			"largest distance between the two paths: %.9f m, at tick %d" % [largest, largest_tick],
		)
		lines.append("first differing ticks:")
		lines.append_array(first_ticks)
	lines.append(
		(
			"a change moved the path: find out why; if it is intended, record again with `%s`"
			+ " and say why in the commit message"
		)
		% RECORD_COMMAND
	)
	return "\n".join(lines)


# The position of a trace line, tick,x,y,z,on_floor.
static func _position(line: String) -> Vector3:
	var fields := line.split(",")
	if fields.size() < 4:
		return Vector3.INF
	return Vector3(fields[1].to_float(), fields[2].to_float(), fields[3].to_float())
