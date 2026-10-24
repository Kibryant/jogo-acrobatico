# Criteria 2, 3 and 7 of TASK-10.3: the replay file, format 1 (replay/replay_file.gd;
# testes-e-entrega.md §4). The header says which game recorded it, with the whole movement
# configuration, one typed field per line, and the declared columns (F-044 §2); a float comes back
# with the same bits, and a float cell that is not exactly 16 hex digits is refused, never read as
# 0 (F-042 §3); a file of another format, tickrate, arena or physics and clock settings, or with a
# column, a line or a cell this build cannot read, cannot play, and one of another build plays only
# with --force (F-042 §4). These files are written here, without a match: the recorded ones are in
# replay_round_trip_test.gd.
extends GdUnitTestSuite

## netfox's tick of the files' first rows: not 0, as in a long session.
const FIRST_TICK := 500
const MOVEMENT_V0 := "res://data/movement_v0.tres"
const SHA256_LENGTH := 64


# A file of this build with one fighter and a row for every tick of these loops, from FIRST_TICK.
func _file(loops: Array[int] = [1, 2, 3, 1]) -> ReplayFile:
	var replay := ReplayFile.this_build()
	replay.header["first_tick"] = str(FIRST_TICK)
	var tick := FIRST_TICK
	for size: int in loops:
		for step: int in size:
			var row := ReplayFile.Row.new()
			row.tick = tick
			row.loop = size
			row.input.move = Vector2(0.25 * step, 1.0 / 3.0)
			row.input.yaw = 0.1 * tick
			row.input.jump = step == 0
			row.check = "0123abcd"
			replay.rows.append(row)
			tick += 1
	return replay


# The file of text, judged against this build.
static func _judged(text: String) -> ReplayFile:
	var replay := ReplayFile.parse(text)
	replay.judge(ReplayFile.this_build())
	return replay


# text with the value of the header field key replaced.
static func _with_header(text: String, key: String, value: String) -> String:
	var lines := text.split("\n")
	for index: int in lines.size():
		if lines[index].begins_with(key + "="):
			lines[index] = "%s=%s" % [key, value]
	return "\n".join(lines)


# text without the header line that starts with prefix.
static func _without_line(text: String, prefix: String) -> String:
	var lines := text.split("\n")
	var kept := PackedStringArray()
	for line: String in lines:
		if not line.begins_with(prefix):
			kept.append(line)
	return "\n".join(kept)


# text with column at of every row replaced by cell, from the row at index first_row on; -1 for
# every row.
static func _with_cell(text: String, row_index: int, at: int, cell: String) -> String:
	var lines := text.split("\n")
	var first_row := lines.find(ReplayFile.SEPARATOR) + 1
	for index: int in range(first_row, lines.size()):
		if lines[index].is_empty() or (row_index >= 0 and index - first_row != row_index):
			continue
		var cells := lines[index].split(ReplayFile.CELL_SEPARATOR)
		cells[at] = cell
		lines[index] = ReplayFile.CELL_SEPARATOR.join(cells)
	return "\n".join(lines)


static func _column(name: String) -> int:
	for index: int in ReplayFile.default_columns().size():
		if ReplayFile.default_columns()[index].name == name:
			return index
	return -1


static func _mentions(messages: PackedStringArray, word: String) -> bool:
	for message: String in messages:
		if message.contains(word):
			return true
	return false


func test_a_float_comes_back_with_the_same_bits() -> void:
	# The move of a tick is the mean of its frames, in the Vector2's 32 bits (InputSampler).
	var three_frames := (Vector2(1, 0) + Vector2(0.7071068, 0.7071068) + Vector2(0, 1)) / 3.0
	var two_frames := (Vector2(0.6, 0.8) + Vector2(0, 1)) / 2.0
	var values: Array[float] = [
		-2.9876543210123457, # a yaw of the mouse, with every digit
		1.0 / 3.0,
		-0.0,
		PI,
		1e-300,
		0.1 + 0.2,
		three_frames.x,
		two_frames.y,
		INF,
		-INF,
	]
	for value: float in values:
		var cell := ReplayFile.f64_cell(value)
		assert_int(cell.length()).is_equal(16)
		var back: Variant = ReplayFile.read_f64(cell)
		var same := back != null and var_to_bytes(back) == var_to_bytes(value)
		var message := "%s came back as %s from %s" % [value, back, cell]
		assert_bool(same).override_failure_message(message).is_true()
	# Through a whole file too: the yaw as a double, the move in the Vector2's 32 bits.
	var replay := _file([1])
	for value: float in values:
		var row := ReplayFile.Row.new()
		row.tick = replay.rows[replay.rows.size() - 1].tick + 1
		row.check = "00000000"
		row.input.yaw = value
		row.input.move = Vector2(three_frames.x, two_frames.y) if is_finite(value) else Vector2.ZERO
		replay.rows.append(row)
	var read := ReplayFile.parse(replay.to_text())
	assert_array(read.errors).is_empty()
	for index: int in replay.rows.size():
		var written := replay.rows[index].input
		var found := read.rows[index].input
		assert_bool(var_to_bytes(found.yaw) == var_to_bytes(written.yaw)).is_true()
		assert_bool(var_to_bytes(found.move) == var_to_bytes(written.move)).is_true()


func test_a_float_cell_that_is_not_16_hex_digits_is_refused_and_never_read_as_0() -> void:
	var malformed: Array[String] = [
		"",
		"0",
		"000000000000f03",
		"000000000000f03f0",
		"000000000000F03F",
		"0x0000000000f03f",
		"1.0",
		"zzzzzzzzzzzzzzzz",
		" 000000000000f03",
		"000000000000f03f ",
	]
	for cell: String in malformed:
		var message := '"%s" must be refused' % cell
		assert_bool(ReplayFile.read_f64(cell) == null).override_failure_message(message).is_true()
	# In a file, the line and the column are named, and no row is played.
	var text := _with_cell(_file().to_text(), 2, _column("yaw"), "000000000000f03")
	var replay := ReplayFile.parse(text)
	assert_bool(replay.playable(true)).is_false()
	assert_str(replay.errors[0]).contains("column yaw").contains("line")


# Criterion 2 (F-044 §2; DEC-0027 §5): the header of this build.
func test_the_header_says_which_game_recorded_it_with_the_whole_configuration() -> void:
	var text := ReplayFile.this_build().header_text()
	var lines := text.split("\n", false)
	var keys := PackedStringArray()
	var fields: Dictionary[String, String] = { }
	for line: String in lines.slice(0, lines.size() - 1):
		var parts := line.split("=", true, 1)
		keys.append(parts[0])
		fields[parts[0]] = parts[1]
	assert_str(lines[lines.size() - 1]).is_equal(ReplayFile.SEPARATOR)
	assert_str(fields["format"]).is_equal("1")
	assert_str(fields["version"]).is_equal(
		str(ProjectSettings.get_setting(BuildStamp.VERSION_SETTING))
	)
	assert_str(fields["commit"]).is_equal(BuildStamp.current().commit)
	# The gate runs from the source, so the rules' fingerprint is read from the scripts.
	assert_int(fields["rules"].length()).is_equal(SHA256_LENGTH)
	assert_str(fields["engine"]).starts_with(str(Engine.get_version_info()["string"]))
	assert_str(fields["platform"]).is_equal(OS.get_name())
	assert_str(fields["tickrate"]).is_equal("60")
	assert_str(fields["physics_ticks_per_second"]).is_equal("60")
	# DEC-0040: the game ticks in the physics step.
	assert_str(fields["sync_to_physics"]).is_equal("1")
	assert_str(fields["max_ticks_per_frame"]).is_equal(str(NetworkTime.max_ticks_per_frame))
	assert_str(fields["input_delay"]).is_equal("0")
	assert_str(fields["arena"]).is_equal("res://arena/arena.tscn")
	assert_int(fields["arena_sha256"].length()).is_equal(SHA256_LENGTH)
	assert_str(fields["seed"]).is_equal("0")
	assert_str(fields["config"]).is_equal(MOVEMENT_V0)
	# TASK-10.6 added pitch and grapple, by reflection over TickInput (criterion 2).
	assert_str(fields["columns"]).is_equal(
		"tick:int,loop:int,fighter:int,move.x:f64,move.y:f64,yaw:f64,pitch:f64,jump:bool,dash:bool,"
		+ "grapple:bool,check:hex8",
	)
	# One line per field of MovementData, typed, with the .tres's value in its cell.
	var resource: Resource = load(MOVEMENT_V0)
	assert_bool(resource is MovementData).is_true()
	var data := resource as MovementData
	var types := ReplayFile.movement_types()
	assert_int(types.size()).is_greater(0)
	for field: String in types:
		var key := "%s%s:%s" % [ReplayFile.CONFIG_PREFIX, field, types[field]]
		assert_bool(fields.has(key)).override_failure_message("no %s" % key).is_true()
		assert_str(fields[key]).is_equal(ReplayFile.write_cell(data.get(field), types[field]))
	# The fields in the order of the format, the configuration after "config".
	var order := PackedStringArray()
	for key: String in keys:
		if not key.begins_with(ReplayFile.CONFIG_PREFIX):
			order.append(key)
	assert_array(Array(order)).is_equal(Array(ReplayFile.KEYS))
	assert_int(keys.find("config.capsule_height_m:f64")).is_equal(keys.find("config") + 1)


# Criterion 2 of TASK-10.6: the pitch travels with every bit, like the yaw (a mouse never stops on
# a round angle), the 80° of the camera's limit and the negative zero included, and the grapple as
# 0 or 1.
func test_the_pitch_and_the_grapple_of_a_row_come_back_as_written() -> void:
	var pitches: Array[float] = [
		0.0,
		-0.0,
		deg_to_rad(80.0),
		-deg_to_rad(80.0),
		0.12345678901234567,
		-1.0 / 3.0,
	]
	var replay := _file([1])
	for index: int in pitches.size():
		var row := ReplayFile.Row.new()
		row.tick = FIRST_TICK + 1 + index
		row.check = "00000000"
		row.input.pitch = pitches[index]
		row.input.grapple = index % 2 == 1
		replay.rows.append(row)
	var read := ReplayFile.parse(replay.to_text())
	assert_array(read.errors).is_empty()
	assert_int(read.rows.size()).is_equal(replay.rows.size())
	for index: int in replay.rows.size():
		var written := replay.rows[index].input
		var found := read.rows[index].input
		var message := "row %d: pitch %s came back as %s" % [index, written.pitch, found.pitch]
		assert_bool(var_to_bytes(found.pitch) == var_to_bytes(written.pitch)) \
				.override_failure_message(message) \
				.is_true()
		assert_bool(found.grapple).is_equal(written.grapple)
	# A pitch cell that is not 16 hex digits is refused, as any float cell.
	var text := _with_cell(replay.to_text(), 1, _column("pitch"), "3fe0")
	var refused := ReplayFile.parse(text)
	assert_bool(refused.playable(true)).is_false()
	assert_str(refused.errors[0]).contains("column pitch")


# The player plays the numbers of the header, not the .tres's: a tuned .tres leaves an old replay
# as it was recorded.
func test_the_movement_numbers_come_from_the_header() -> void:
	var text := _file().to_text()
	var tuned := "%sjump_height_m:f64" % ReplayFile.CONFIG_PREFIX
	text = _with_header(text, tuned, ReplayFile.f64_cell(0.6))
	var replay := _judged(text)
	assert_bool(replay.playable(false)).is_true()
	var data := replay.movement_data()
	assert_float(data.jump_height_m).is_equal(0.6)
	assert_float(data.run_speed_mps).is_equal(7.0)
	assert_int(data.jump_rise_ms).is_equal(350)


func test_a_written_file_reads_back_with_its_loops() -> void:
	var replay := _judged(_file().to_text())
	assert_array(replay.errors).is_empty()
	assert_array(replay.refusals).is_empty()
	assert_array(replay.warnings).is_empty()
	assert_int(replay.first_tick()).is_equal(FIRST_TICK)
	assert_int(replay.tick_count()).is_equal(7)
	assert_int(replay.loops.size()).is_equal(4)
	assert_int(replay.jumps).is_equal(0)
	assert_int(replay.loops[2].first_tick).is_equal(FIRST_TICK + 3)
	assert_int(replay.loops[2].size).is_equal(3)
	assert_bool(replay.has_check()).is_true()
	assert_str(replay.rows[6].check).is_equal("0123abcd")


# Criterion 7: another format, tickrate, arena, physics or clock settings cannot play, not even
# with --force, and the message names the field.
func test_another_format_tickrate_arena_or_settings_cannot_play() -> void:
	var text := _file().to_text()
	var cases: Dictionary[String, String] = {
		"format": "2",
		"tickrate": "30",
		"physics_ticks_per_second": "120",
		"sync_to_physics": "0",
		"max_ticks_per_frame": "4",
		"input_delay": "2",
		"arena": "res://arena/other_arena.tscn",
	}
	for key: String in cases:
		var replay := _judged(_with_header(text, key, cases[key]))
		var message := "%s=%s must not play: %s" % [key, cases[key], replay.messages(true)]
		assert_bool(replay.playable(true)).override_failure_message(message).is_false()
		assert_bool(_mentions(replay.errors, key)).override_failure_message(message).is_true()


func test_a_column_a_line_or_a_cell_this_build_cannot_read_cannot_play() -> void:
	var text := _file().to_text()
	var columns := ReplayFile.this_build().header["columns"]
	# A command no build has: grapple was the unknown one until TASK-10.6 made it a column.
	var unknown := _with_header(text, "columns", columns + ",teleport:bool")
	unknown = unknown.replace("0123abcd\n", "0123abcd,0\n")
	var retyped := _with_header(text, "columns", columns.replace("yaw:f64", "yaw:int"))
	var lines := text.split("\n")
	var broken_at := lines.find(ReplayFile.SEPARATOR) + 2
	var cells := lines[broken_at].split(ReplayFile.CELL_SEPARATOR)
	cells.remove_at(cells.size() - 1)
	lines[broken_at] = ReplayFile.CELL_SEPARATOR.join(cells)
	var broken := "\n".join(lines)
	var cases: Dictionary[String, String] = {
		"column teleport": unknown,
		"column yaw": retyped,
		"line %d is broken" % (broken_at + 1): broken,
		"column jump": _with_cell(text, 1, _column("jump"), "2"),
		"column check": _with_cell(text, 1, _column("check"), "0123abc"),
		"column tick": _with_cell(text, 1, _column("tick"), "50l"),
		"column loop": _with_cell(text, 0, _column("loop"), "x"),
		"CR line endings": text.replace("\n", "\r\n"),
		"go forward": _with_cell(text, 3, _column("tick"), str(FIRST_TICK)),
		"of the loop of 3": _with_cell(text, 5, _column("loop"), "1"),
		"first_tick": _with_header(text, "first_tick", str(FIRST_TICK + 1)),
		"header field fighters": _with_header(text, "fighters", "0"),
		"header field seed": _without_line(text, "seed="),
	}
	for word: String in cases:
		var replay := _judged(cases[word])
		var message := "%s must not play: %s" % [word, replay.messages(true)]
		assert_bool(replay.playable(true)).override_failure_message(message).is_false()
		assert_bool(_mentions(replay.errors, word)).override_failure_message(message).is_true()


# Criterion 7: another version, commit, engine, rules or arena fingerprint is another build: it
# is refused, the message says which, and it plays only with --force (F-042 §4).
func test_another_build_plays_only_with_force() -> void:
	var text := _file().to_text()
	var other_sha := "ab".repeat(32)
	var cases: Dictionary[String, String] = {
		"version": "9.9.9",
		"commit": "abc1234",
		"engine": "4.8.0-stable (official) 0000000",
		"rules": other_sha,
		"arena_sha256": other_sha,
	}
	for key: String in cases:
		var replay := _judged(_with_header(text, key, cases[key]))
		var message := "%s=%s: %s" % [key, cases[key], replay.messages(false)]
		assert_array(replay.errors).override_failure_message(message).is_empty()
		assert_bool(_mentions(replay.refusals, key)).override_failure_message(message).is_true()
		assert_bool(replay.playable(false)).override_failure_message(message).is_false()
		assert_bool(replay.playable(true)).override_failure_message(message).is_true()
		assert_bool(_mentions(replay.messages(true), "played anyway (--force)")).is_true()


# An exported build leaves its rules' fingerprint empty, and its commit says which build it is: the
# rules are compared only when both exist.
func test_the_rules_are_compared_only_when_the_file_has_them() -> void:
	var replay := _judged(_with_header(_file().to_text(), "rules", ""))
	assert_array(replay.errors).is_empty()
	assert_array(replay.refusals).is_empty()


# Criterion 7: with --force, a missing input column plays with TickInput's default, and the
# message names it.
func test_a_missing_input_column_plays_with_the_default_only_with_force() -> void:
	var replay := _file()
	var at := _column("yaw")
	var lines := replay.to_text().split("\n")
	var separator := lines.find(ReplayFile.SEPARATOR)
	for index: int in lines.size():
		if index > separator and not lines[index].is_empty():
			var cells := lines[index].split(ReplayFile.CELL_SEPARATOR)
			cells.remove_at(at)
			lines[index] = ReplayFile.CELL_SEPARATOR.join(cells)
	var text := "\n".join(lines)
	var declared := PackedStringArray()
	for column: ReplayFile.Column in ReplayFile.default_columns():
		if column.name != "yaw":
			declared.append(column.declared())
	text = _with_header(text, "columns", ",".join(declared))
	var read := _judged(text)
	assert_array(read.errors).is_empty()
	assert_bool(_mentions(read.refusals, "column yaw")).is_true()
	assert_bool(read.playable(false)).is_false()
	assert_bool(read.playable(true)).is_true()
	var neutral := TickInput.new()
	for row: ReplayFile.Row in read.rows:
		assert_float(row.input.yaw).is_equal(neutral.yaw)
	assert_vector(read.rows[1].input.move).is_equal(replay.rows[1].input.move)


# A field of the configuration the file lacks, or one this build does not know, is another build:
# it plays only with --force, the missing one with the game's own number.
func test_a_missing_or_unknown_configuration_field_plays_only_with_force() -> void:
	var text := _file().to_text()
	var missing := _judged(_without_line(text, "%sjump_height_m:" % ReplayFile.CONFIG_PREFIX))
	assert_array(missing.errors).is_empty()
	assert_bool(_mentions(missing.refusals, "jump_height_m")).is_true()
	assert_bool(missing.playable(false)).is_false()
	assert_float(missing.movement_data().jump_height_m).is_equal(1.2) # movement_v0.tres
	var cell := ReplayFile.f64_cell(9.0)
	var extra := text.replace(
		"fighters=",
		"%sdash_speed_mps:f64=%s\nfighters=" % [ReplayFile.CONFIG_PREFIX, cell],
	)
	var unknown := _judged(extra)
	assert_array(unknown.errors).is_empty()
	assert_bool(_mentions(unknown.refusals, "dash_speed_mps")).is_true()
	assert_bool(unknown.playable(true)).is_true()


# Criterion 7: an abrupt close can cut the last line, and the last loop with it; the cut is
# dropped with a warning, and the rest plays.
func test_a_cut_last_line_is_dropped_with_a_warning() -> void:
	var text := _file([1, 2, 1]).to_text()
	var cut := _judged(text.left(text.length() - 12))
	assert_array(cut.errors).is_empty()
	assert_bool(_mentions(cut.warnings, "cut")).is_true()
	assert_bool(cut.playable(false)).is_true()
	assert_int(cut.tick_count()).is_equal(3)
	assert_int(cut.loops.size()).is_equal(2)
	# Cut in the middle of a loop of 3: the loop's first two ticks go with it.
	var long := _file([1, 3]).to_text()
	var in_loop := _judged(long.left(long.length() - 12))
	assert_array(in_loop.errors).is_empty()
	assert_bool(_mentions(in_loop.warnings, "the last loop")).is_true()
	assert_int(in_loop.tick_count()).is_equal(1)
	assert_int(in_loop.loops.size()).is_equal(1)


# Criterion 7: netfox's clock jumps after a stall of over a second (NetworkTime._loop), and the
# file keeps the jump between two loops for the player to make.
func test_a_jump_of_the_recorded_clock_stays_a_jump() -> void:
	var replay := _file([1, 2])
	for step: int in 2:
		var row := ReplayFile.Row.new()
		row.tick = FIRST_TICK + 30 + step
		row.loop = 2
		row.check = "89abcdef"
		replay.rows.append(row)
	var read := _judged(replay.to_text())
	assert_array(read.errors).is_empty()
	assert_int(read.jumps).is_equal(1)
	assert_int(read.loops.size()).is_equal(3)
	assert_int(read.loops[2].first_tick).is_equal(FIRST_TICK + 30)


# --readable writes the same file in decimals for reading; no player plays it.
func test_the_readable_copy_shows_decimals_and_does_not_play() -> void:
	var replay := _file([1])
	replay.rows[0].input.yaw = 1.0 / 3.0
	var readable := replay.to_text(true)
	assert_str(readable).contains("format=%s" % ReplayFile.READABLE_FORMAT)
	assert_str(readable).contains(",0.3333333333333333,")
	assert_str(readable).contains("%sjump_height_m:f64=1.2\n" % ReplayFile.CONFIG_PREFIX)
	var read := _judged(readable)
	assert_bool(read.playable(true)).is_false()
	assert_bool(_mentions(read.errors, "format")).is_true()


# The arena's fingerprint takes every box the body collides with and every spawn point, so a
# moved box makes another arena; a shape it does not know yet leaves it empty, and refused.
func test_the_arena_fingerprint_follows_its_boxes_and_knows_every_shape() -> void:
	var arena: Node = auto_free(Match.ARENA_SCENE.instantiate())
	assert_array(Array(ReplayFile.unknown_arena_shapes(arena))).is_empty()
	var fingerprint := ReplayFile.arena_fingerprint(arena)
	assert_int(fingerprint.length()).is_equal(SHA256_LENGTH)
	assert_str(ReplayFile.arena_fingerprint(arena)).is_equal(fingerprint)
	var block_node := arena.get_node(^"Block1m")
	assert(block_node is Node3D, "arena.tscn must have a Block1m")
	var block := block_node as Node3D
	block.position.x += 0.001
	assert_str(ReplayFile.arena_fingerprint(arena)).is_not_equal(fingerprint)
	var collision_node := arena.get_node(^"Block2m/Collision")
	assert(collision_node is CollisionShape3D, "arena.tscn must have a Block2m/Collision")
	var collision := collision_node as CollisionShape3D
	collision.shape = SphereShape3D.new()
	assert_str(ReplayFile.arena_fingerprint(arena)).is_empty()
	assert_array(Array(ReplayFile.unknown_arena_shapes(arena))).has_size(1)
