# The state trace (TASK-10.3): one line per tick and fighter with the whole state after the tick,
# the body's position and velocity and every field of FighterState, found by reflection the way
# the SyncTest's referee finds them (test/support/sync_observer.gd), so a field a later task adds
# joins the trace by itself. Two runs that computed the same thing give the same text byte for
# byte, and its sha256 says so in one word.
# The ticks count from the first recorded tick, and so does every stamp of the state (a field
# named *_tick or *_since; glossario.md, "Carimbo de tick"); NEVER stays NEVER. The --watch runs on
# the real clock and starts on another tick than the recording: counted from the first tick, its
# trace compares with the headless player's.
# Floats are the 16 hex digits of the double (ReplayFile.f64_cell): equal text, equal bits.
# check_of() takes 8 hex digits of a line's sha256, the check a replay row carries: the
# fingerprint of the state the live game computed, which a player compares with its own.
# line_from() writes a line and parse_line() reads it back, a pair like JSON.stringify beside
# JSON.parse (TASK-14): the replay summary (tools/replay_summary.gd) counts from the lines, so a
# field of a type the trace does not know yet breaks the writer and the reader together.
class_name StateTrace
extends RefCounted

## The body box's fields, on the Fighter node, before the state's (visao-geral.md, "O estado em
## quatro caixas").
const BODY: Array[String] = ["position", "velocity"]
## The fixed columns before the state's.
const TICK := "tick"
const FIGHTER := "fighter"

## The shape of an int cell and of a bool cell, as _cell writes them; ReplayFile has the f64's
## and the text's.
const INT_PATTERN := "-?[0-9]+"
const BOOL_PATTERN := "[01]"

# FighterState's fields and the Variant type of each, by reflection, in the order _cell writes
# them, and the shape of a whole line, every cell by its type: parse_line reads them back the same
# way. Learned once per run.
static var _state_fields: Array[StringName] = []
static var _state_types: Array[int] = []
static var _line_shape: RegEx

## netfox's tick the trace counts from.
var first_tick: int

var _lines := PackedStringArray()
var _fighters: Array[Fighter] = []
# The newest tick traced: a tick at or before it is a resimulation, not a fresh result.
var _newest := 0
var _observing := false


func _init(trace_first_tick: int) -> void:
	first_tick = trace_first_tick
	_newest = trace_first_tick - 1


# The names of the columns, after tick and fighter: the body's vectors as .x, .y and .z, then
# every field of FighterState, a vector of the state as .x, .y and .z too (dash_direction,
# TASK-10.4), one name per cell _cell writes.
static func state_columns() -> PackedStringArray:
	var names := PackedStringArray()
	for field: String in BODY:
		for axis: String in ["x", "y", "z"]:
			names.append("%s.%s" % [field, axis])
	var state := FighterState.new()
	for field: String in ReplayFile.script_fields(state):
		if typeof(state.get(field)) == TYPE_VECTOR3:
			for axis: String in ["x", "y", "z"]:
				names.append("%s.%s" % [field, axis])
		else:
			names.append(field)
	return names


# The first line of a trace: the columns' names.
static func header() -> String:
	var names := PackedStringArray([TICK, FIGHTER])
	names.append_array(state_columns())
	return ReplayFile.CELL_SEPARATOR.join(names)


# True for a stamp of the state, the tick something happened (glossario.md, "Carimbo de tick").
static func is_stamp(field: String) -> bool:
	return field.ends_with("_tick") or field.ends_with("_since")


# The line of fighter after tick, the ticks and the stamps counted from first.
static func line_of(fighter: Fighter, fighter_index: int, tick: int, first: int) -> String:
	return line_from(tick, fighter_index, fighter.position, fighter.velocity, fighter.state, first)


# The line of one fighter's body and state after tick, the ticks and the stamps counted from
# first: the writer of the pair parse_line() reads back. The body's two vectors go in BODY's
# order, then every field of the state, by reflection.
static func line_from(
	tick: int,
	fighter_index: int,
	position: Vector3,
	velocity: Vector3,
	state: FighterState,
	first: int,
) -> String:
	var cells := PackedStringArray([str(tick - first), str(fighter_index)])
	for vector: Vector3 in [position, velocity]:
		for axis: float in [vector.x, vector.y, vector.z]:
			cells.append(ReplayFile.f64_cell(axis))
	for field: String in ReplayFile.script_fields(state):
		cells.append(_cell(field, state.get(field), first))
	return ReplayFile.CELL_SEPARATOR.join(cells)


# One line read back: the reader of the pair line_from() writes. The columns are this build's
# (header()), and each field of the state takes its cells by its type, found by reflection the way
# _cell writes it. The ticks and the stamps stay as the line has them, counted from the first tick,
# and NEVER stays NEVER, so line_from(row..., 0) gives the line again. Null for a line that is not
# one of this build's: another count of cells, or a cell not of its column's type. The whole line
# is checked in one search before any cell is decoded, as ReplayFile.read_cell checks a cell: a
# check per cell made the reader the slowest part of the replay summary (TASK-14).
static func parse_line(line: String) -> Row:
	_learn_state()
	if _line_shape.search(line) == null:
		return null
	var cells := line.split(ReplayFile.CELL_SEPARATOR)
	var row := Row.new()
	row.tick = cells[0].to_int()
	row.fighter = cells[1].to_int()
	row.position = _vector_at(cells, 2)
	row.velocity = _vector_at(cells, 5)
	var state := FighterState.new()
	var at := 2 + 3 * BODY.size()
	for index: int in _state_fields.size():
		var kind := _state_types[index]
		state.set(_state_fields[index], _value_at(cells, at, kind))
		at += 3 if kind == TYPE_VECTOR3 else 1
	row.state = state
	return row


# 8 hex digits of the sha256 of a line: the check of a replay row.
static func check_of(line: String) -> String:
	return line.sha256_text().left(8)


# Appends the line of fighter after tick and returns it.
func add(tick: int, fighter_index: int, fighter: Fighter) -> String:
	var line := line_of(fighter, fighter_index, tick, first_tick)
	_lines.append(line)
	return line


# From the next tick on, traces fighters after every fresh tick where netfox simulated them:
# alive, with the input of that very tick (net/tick_recorder.gd).
func observe(fighters: Array[Fighter]) -> void:
	_fighters.assign(fighters)
	if not _observing:
		NetworkRollback.after_process_tick.connect(_on_tick)
		_observing = true


func stop() -> void:
	if _observing:
		NetworkRollback.after_process_tick.disconnect(_on_tick)
		_observing = false


func lines() -> PackedStringArray:
	return _lines


# The whole trace: the header, then one line per tick and fighter, each ended by "\n".
func text() -> String:
	var body := "\n".join(_lines) + "\n" if not _lines.is_empty() else ""
	return header() + "\n" + body


func sha256() -> String:
	return text().sha256_text()


# Where two traces first differ: the tick, the fighter, the column and the two values; null when
# they are equal.
static func first_difference(first: String, second: String) -> Difference:
	if first == second:
		return null
	var mine := first.split("\n", false)
	var theirs := second.split("\n", false)
	var common := mini(mine.size(), theirs.size())
	for index: int in common:
		if mine[index] == theirs[index]:
			continue
		if index == 0:
			return Difference.new(-1, -1, "columns", mine[0], theirs[0])
		var names := mine[0].split(ReplayFile.CELL_SEPARATOR)
		var a := mine[index].split(ReplayFile.CELL_SEPARATOR)
		var b := theirs[index].split(ReplayFile.CELL_SEPARATOR)
		for at: int in mini(a.size(), b.size()):
			if a[at] != b[at]:
				var column := names[at] if at < names.size() else "#%d" % at
				return Difference.new(a[0].to_int(), a[1].to_int(), column, a[at], b[at])
		return Difference.new(a[0].to_int(), a[1].to_int(), "length", mine[index], theirs[index])
	var longer := mine if mine.size() > theirs.size() else theirs
	var extra := longer[common].split(ReplayFile.CELL_SEPARATOR)
	return Difference.new(
		extra[0].to_int(),
		extra[1].to_int() if extra.size() > 1 else -1,
		"lines",
		"%d lines" % mine.size(),
		"%d lines" % theirs.size(),
	)


static func _cell(field: String, value: Variant, first: int) -> String:
	match typeof(value):
		TYPE_INT:
			var whole: int = value
			if is_stamp(field) and whole != FighterState.NEVER:
				whole -= first
			return str(whole)
		TYPE_FLOAT:
			var number: float = value
			return ReplayFile.f64_cell(number)
		TYPE_BOOL:
			var flag: bool = value
			return "1" if flag else "0"
		TYPE_STRING, TYPE_STRING_NAME:
			return ReplayFile.write_cell(value, ReplayFile.STR)
		TYPE_VECTOR3:
			var vector: Vector3 = value
			return ReplayFile.CELL_SEPARATOR.join(
				[
					ReplayFile.f64_cell(vector.x),
					ReplayFile.f64_cell(vector.y),
					ReplayFile.f64_cell(vector.z),
				],
			)
	assert(false, "FighterState.%s has a type the trace does not write yet" % field)
	return str(value)


# The value of a field of type kind from its cells, at on: what _cell wrote for it, in a line
# whose shape parse_line has checked already.
static func _value_at(cells: PackedStringArray, at: int, kind: int) -> Variant:
	match kind:
		TYPE_INT:
			return cells[at].to_int()
		TYPE_FLOAT:
			return _f64_at(cells, at)
		TYPE_BOOL:
			return cells[at] == "1"
		TYPE_STRING:
			return cells[at].hex_decode().get_string_from_utf8()
		TYPE_STRING_NAME:
			return StringName(cells[at].hex_decode().get_string_from_utf8())
		TYPE_VECTOR3:
			return _vector_at(cells, at)
	assert(false, "a FighterState field of type %d has no reader yet" % kind)
	return null


# The vector of three f64 cells from at on.
static func _vector_at(cells: PackedStringArray, at: int) -> Vector3:
	return Vector3(_f64_at(cells, at), _f64_at(cells, at + 1), _f64_at(cells, at + 2))


# The double of the 16 hex digits of one cell, the 8 bytes of ReplayFile.f64_cell.
static func _f64_at(cells: PackedStringArray, at: int) -> float:
	return cells[at].hex_decode().decode_double(0)


# FighterState's fields and their types, and the shape of a line: every cell by its type, as _cell
# writes it, with the tick and the fighter first and the body's vectors after them. Once:
# get_property_list on every line would cost more than the line itself.
static func _learn_state() -> void:
	if _line_shape != null:
		return
	var shapes := PackedStringArray([INT_PATTERN, INT_PATTERN])
	for _axis: int in 3 * BODY.size():
		shapes.append(ReplayFile.F64_PATTERN)
	var state := FighterState.new()
	for field: String in ReplayFile.script_fields(state):
		var kind := typeof(state.get(field))
		_state_fields.append(StringName(field))
		_state_types.append(kind)
		match kind:
			TYPE_INT:
				shapes.append(INT_PATTERN)
			TYPE_FLOAT:
				shapes.append(ReplayFile.F64_PATTERN)
			TYPE_BOOL:
				shapes.append(BOOL_PATTERN)
			TYPE_STRING, TYPE_STRING_NAME:
				shapes.append(ReplayFile.STR_PATTERN)
			TYPE_VECTOR3:
				for _axis: int in 3:
					shapes.append(ReplayFile.F64_PATTERN)
			_:
				assert(false, "FighterState.%s has a type the trace does not read yet" % field)
	_line_shape = RegEx.create_from_string("^%s$" % ReplayFile.CELL_SEPARATOR.join(shapes))


func _on_tick(tick: int) -> void:
	if tick <= _newest:
		return
	_newest = tick
	for index: int in _fighters.size():
		var fighter := _fighters[index]
		if not RollbackLivenessServer.is_alive(fighter, tick):
			continue
		if fighter.synchronizer.get_input_age() != 0:
			continue
		add(tick, index, fighter)


# One line read back (parse_line): the tick and the fighter, the body after the tick and the
# whole state, with the ticks and the stamps as the line has them, counted from the first tick.
class Row:
	var tick: int
	var fighter: int
	var position: Vector3
	var velocity: Vector3
	var state: FighterState


# Where two traces part.
class Difference:
	## The tick counted from the first, and the fighter; -1 when the columns differ.
	var tick: int
	var fighter: int
	## The column whose values differ: "columns" for the header, "lines" when one trace is longer.
	var column: String
	var first: String
	var second: String


	func _init(at_tick: int, at_fighter: int, at_column: String, a: String, b: String) -> void:
		tick = at_tick
		fighter = at_fighter
		column = at_column
		first = a
		second = b


	# One line: where, and the two values, a float also as a decimal.
	func describe() -> String:
		if column == "columns":
			return "the columns differ: %s / %s" % [first, second]
		if column == "lines":
			return "equal up to tick %d, then one trace ends: %s / %s" % [tick, first, second]
		return "tick %d, fighter %d, column %s: %s / %s" % [
			tick,
			fighter,
			column,
			_shown(first),
			_shown(second),
		]


	static func _shown(cell: String) -> String:
		var number: Variant = ReplayFile.read_f64(cell)
		if number == null:
			return cell
		var value: float = number
		return "%s (%s)" % [String.num_scientific(value), cell]
