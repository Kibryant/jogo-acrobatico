# Criterion 5 of TASK-12.15, the replay's header (F-219 §1: "O replay": "O cabeçalho já grava os
# números do movimento, então o replay centrado toca igual [...] Os replays de antes pedem
# --force, por causa do campo novo"): the header carries one typed line per field of
# MovementData, by reflection (testes-e-entrega.md §4; F-044 §2), so the aim's rise travels as
# config.aim_rise_m:f64 beside the side. A header with the centered camera's numbers, side 0 and
# rise 0,6 m (movimento.md, "Câmera": "Subida"), comes back with them and plays without --force;
# a file without the rise's line, as one recorded before this task, plays only with --force, the
# rise at the game's own 0. These files are written here, without a match.
extends GdUnitTestSuite

## netfox's tick of the files' first rows: not 0, as in a long session.
const FIRST_TICK := 500
# The names the plan fixes (F-219 §1: "Os dados").
const AIM_RISE := "aim_rise_m"
const AIM_SIDE := "aim_side_m"
# movimento.md, "Câmera": "Subida": "0 no padrão; 0,6 na câmera centrada"; "Ombro": 0,8 m in the
# default camera, 0 in the centered one.
const CENTER_RISE_M := 0.6
const CENTER_SIDE_M := 0.0
const V0_RISE_M := 0.0
const V0_SIDE_M := 0.8
# What a number that does not exist yet reads as: no length of the game.
const NO_SUCH_FIELD := -424242.0


# A file of this build with one fighter and a few rows from FIRST_TICK.
func _file() -> ReplayFile:
	var replay := ReplayFile.this_build()
	replay.header["first_tick"] = str(FIRST_TICK)
	for step: int in 4:
		var row := ReplayFile.Row.new()
		row.tick = FIRST_TICK + step
		row.loop = 1
		row.input.yaw = 0.1 * step
		row.check = "0123abcd"
		replay.rows.append(row)
	return replay


# The file of text, judged against this build.
static func _judged(text: String) -> ReplayFile:
	var replay := ReplayFile.parse(text)
	replay.judge(ReplayFile.this_build())
	return replay


# The header key of a float of the movement: config.<field>:f64.
static func _key(field: String) -> String:
	return "%s%s:%s" % [ReplayFile.CONFIG_PREFIX, field, ReplayFile.F64]


# Whether the text has a header line for this key.
static func _has_line(text: String, key: String) -> bool:
	for line: String in text.split("\n"):
		if line.begins_with(key + "="):
			return true
	return false


# text with the value of the header field key replaced.
static func _with_header(text: String, key: String, value: String) -> String:
	var lines := text.split("\n")
	for index: int in lines.size():
		if lines[index].begins_with(key + "="):
			lines[index] = "%s=%s" % [key, value]
	return "\n".join(lines)


# text without the header line that starts with prefix.
static func _without_line(text: String, prefix: String) -> String:
	var kept := PackedStringArray()
	for line: String in text.split("\n"):
		if not line.begins_with(prefix):
			kept.append(line)
	return "\n".join(kept)


static func _mentions(messages: PackedStringArray, word: String) -> bool:
	for message: String in messages:
		if message.contains(word):
			return true
	return false


# A float the object holds under this name; the case fails when it holds none.
func _float_of(object: Object, field: String) -> float:
	var value: Variant = object.get(field)
	var missing := "%s has no float %s" % [object, field]
	assert_bool(value is float).override_failure_message(missing).is_true()
	if value is float:
		var number: float = value
		return number
	return NO_SUCH_FIELD


# The header of this build has the rise's line, typed f64, with the game's own number, 0, beside
# the side's.
func test_the_header_carries_the_aim_rise_as_a_typed_line() -> void:
	var types := ReplayFile.movement_types()
	assert_str(types.get(AIM_RISE, "")) \
			.override_failure_message("the header has no type for %s" % AIM_RISE) \
			.is_equal(ReplayFile.F64)
	assert_str(types.get(AIM_SIDE, "")).is_equal(ReplayFile.F64)
	var text := _file().to_text()
	assert_bool(_has_line(text, _key(AIM_RISE))) \
			.override_failure_message("the header has no line %s" % _key(AIM_RISE)) \
			.is_true()
	var replay := _judged(text)
	assert_bool(replay.playable(false)).is_true()
	var data := replay.movement_data()
	assert_float(_float_of(data, AIM_RISE)).is_equal(V0_RISE_M)
	assert_float(data.aim_side_m).is_equal(V0_SIDE_M)


# Criterion 5: a header written with the centered camera's numbers, the side 0 and the rise
# 0,6 m, comes back with them, bit for bit, and plays without --force: the numbers of a replay
# are the header's, not the .tres's.
func test_a_header_with_the_centered_aim_comes_back_with_side_0_and_rise_0_6_m() -> void:
	var text := _file().to_text()
	assert_bool(_has_line(text, _key(AIM_RISE))) \
			.override_failure_message("the header has no line %s" % _key(AIM_RISE)) \
			.is_true()
	text = _with_header(text, _key(AIM_RISE), ReplayFile.f64_cell(CENTER_RISE_M))
	text = _with_header(text, _key(AIM_SIDE), ReplayFile.f64_cell(CENTER_SIDE_M))
	var replay := _judged(text)
	assert_array(replay.errors).is_empty()
	assert_array(replay.refusals).is_empty()
	assert_bool(replay.playable(false)).is_true()
	var data := replay.movement_data()
	var rise := _float_of(data, AIM_RISE)
	assert_bool(var_to_bytes(rise) == var_to_bytes(CENTER_RISE_M)) \
			.override_failure_message("the rise came back as %s" % rise) \
			.is_true()
	assert_float(data.aim_side_m).is_equal(CENTER_SIDE_M)
	# Every other number is the game's own.
	assert_float(data.aim_height_m).is_equal(1.6) # movimento.md, "Gancho": "De onde sai a mira"
	assert_float(data.grapple_range_m).is_equal(25.0) # movimento.md, "Gancho": "Alcance"
	# The configuration made from the header carries the rise to the rules.
	var config := MovementConfig.create(data, 60)
	assert_float(_float_of(config, "aim_rise")).is_equal(CENTER_RISE_M)
	assert_float(config.aim_side).is_equal(CENTER_SIDE_M)


# Criterion 5: a replay recorded before this task has no line for the rise: it is another build,
# which plays only with --force, the rise at the game's own number, 0.
func test_a_file_without_the_aim_rise_plays_only_with_force_the_rise_at_0() -> void:
	var text := _file().to_text()
	assert_bool(_has_line(text, _key(AIM_RISE))) \
			.override_failure_message("the header has no line %s" % _key(AIM_RISE)) \
			.is_true()
	var old := _judged(_without_line(text, "%s%s:" % [ReplayFile.CONFIG_PREFIX, AIM_RISE]))
	assert_array(old.errors).is_empty()
	assert_bool(_mentions(old.refusals, AIM_RISE)) \
			.override_failure_message("no refusal names %s: %s" % [AIM_RISE, old.refusals]) \
			.is_true()
	assert_bool(old.playable(false)).is_false()
	assert_bool(old.playable(true)).is_true()
	assert_float(_float_of(old.movement_data(), AIM_RISE)).is_equal(V0_RISE_M)
