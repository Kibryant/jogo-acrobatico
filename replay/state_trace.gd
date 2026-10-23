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
class_name StateTrace
extends RefCounted

## The body box's fields, on the Fighter node, before the state's (visao-geral.md, "O estado em
## quatro caixas").
const BODY: Array[String] = ["position", "velocity"]
## The fixed columns before the state's.
const TICK := "tick"
const FIGHTER := "fighter"

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
	var cells := PackedStringArray([str(tick - first), str(fighter_index)])
	for field: String in BODY:
		var vector: Vector3 = fighter.get(field)
		for axis: float in [vector.x, vector.y, vector.z]:
			cells.append(ReplayFile.f64_cell(axis))
	var state := fighter.state
	for field: String in ReplayFile.script_fields(state):
		cells.append(_cell(field, state.get(field), first))
	return ReplayFile.CELL_SEPARATOR.join(cells)


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
