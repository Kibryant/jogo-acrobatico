# What one game computed for its fighters, tick by tick (TASK-9, criterion 12): for each fighter,
# by its node name, which is its route in netfox on every peer, and for each tick, where the body
# ended the tick and what the rules said about the floor, the fields the SyncTest of TASK-9
# compared (rede.md §4). A client keeps its first result for its own fighter, what its player
# saw; the server keeps its last one, what it confirmed (TickRecorder); PredictionCheck compares
# the two.
# As text, a header and one line per state, so the record outlives the game that wrote it. It
# knows no node, so tools/net_run_check.gd reads it outside the game.
class_name TickRecord
extends RefCounted

const HEADER := "fighter,tick,x,y,z,on_floor,mode"
const SEPARATOR := ","
const FIELD_COUNT := 7

## The lines of a text that did not read as states, one message each.
var errors := PackedStringArray()

# The fighters' names, in the order they first appear: a fighter is known here by its index.
var _names: Array[String] = []
# The states by (fighter index, tick).
var _states: Dictionary[Vector2i, Sample] = { }


# The fields the check compares, at the end of one tick.
class Sample:
	var position: Vector3
	var on_floor: bool
	var mode: int


	func _init(at: Vector3, floor_verdict: bool, fighter_mode: int) -> void:
		position = at
		on_floor = floor_verdict
		mode = fighter_mode


# Keeps sample unless the fighter already has one at tick: the first result wins.
func keep_first(fighter: String, tick: int, sample: Sample) -> void:
	var key := Vector2i(_index(fighter), tick)
	if not _states.has(key):
		_states[key] = sample


# Keeps sample over any the fighter had at tick: the last result wins.
func keep_last(fighter: String, tick: int, sample: Sample) -> void:
	_states[Vector2i(_index(fighter), tick)] = sample


# The fighters with a state, by name, sorted.
func fighters() -> Array[String]:
	var names: Array[String] = []
	for key: Vector2i in _states:
		var fighter := _names[key.x]
		if not names.has(fighter):
			names.append(fighter)
	names.sort()
	return names


# The ticks where fighter has a state, in order.
func ticks_of(fighter: String) -> Array[int]:
	var ticks: Array[int] = []
	var index := _names.find(fighter)
	for key: Vector2i in _states:
		if key.x == index:
			ticks.append(key.y)
	ticks.sort()
	return ticks


# The state of fighter at tick; null when it has none.
func sample_at(fighter: String, tick: int) -> Sample:
	var key := Vector2i(_names.find(fighter), tick)
	if not _states.has(key):
		return null
	return _states[key]


func size() -> int:
	return _states.size()


# m: the shortest horizontal distance between two fighters at a tick where both have a state; INF
# when no tick has two. Two capsules closer than twice their radius touch.
func closest_approach() -> float:
	var closest := INF
	var names := fighters()
	for first: int in names.size():
		for second: int in range(first + 1, names.size()):
			for tick: int in ticks_of(names[first]):
				var other := sample_at(names[second], tick)
				if other != null:
					var gap := sample_at(names[first], tick).position - other.position
					closest = minf(closest, Vector2(gap.x, gap.z).length())
	return closest


# The box that holds every position of fighter: where it went.
func extent(fighter: String) -> AABB:
	var box := AABB()
	var first := true
	for tick: int in ticks_of(fighter):
		var at := sample_at(fighter, tick).position
		box = AABB(at, Vector3.ZERO) if first else box.expand(at)
		first = false
	return box


func to_text() -> String:
	var lines := PackedStringArray([HEADER])
	for fighter: String in fighters():
		for tick: int in ticks_of(fighter):
			var sample := sample_at(fighter, tick)
			lines.append(
				"%s,%d,%.6f,%.6f,%.6f,%d,%d"
				% [
					fighter,
					tick,
					sample.position.x,
					sample.position.y,
					sample.position.z,
					1 if sample.on_floor else 0,
					sample.mode,
				],
			)
	return "\n".join(lines) + "\n"


# The record a text holds. A line that does not read leaves a message in errors and no state.
static func from_text(text: String) -> TickRecord:
	var record := TickRecord.new()
	var lines := text.replace("\r", "").split("\n", false)
	if lines.is_empty() or lines[0] != HEADER:
		record.errors.append('the first line is not "%s"' % HEADER)
		return record
	for number: int in range(1, lines.size()):
		var fields := lines[number].split(SEPARATOR)
		if not _readable(fields):
			record.errors.append("line %d does not read: %s" % [number + 1, lines[number]])
			continue
		var position := Vector3(fields[2].to_float(), fields[3].to_float(), fields[4].to_float())
		var sample := Sample.new(position, fields[5] == "1", fields[6].to_int())
		record.keep_last(fields[0], fields[1].to_int(), sample)
	return record


static func _readable(fields: PackedStringArray) -> bool:
	if fields.size() != FIELD_COUNT or fields[0].is_empty():
		return false
	if not fields[1].is_valid_int() or not fields[6].is_valid_int():
		return false
	for coordinate: String in [fields[2], fields[3], fields[4]]:
		if not coordinate.is_valid_float():
			return false
	return fields[5] == "0" or fields[5] == "1"


func _index(fighter: String) -> int:
	var index := _names.find(fighter)
	if index == -1:
		_names.append(fighter)
		index = _names.size() - 1
	return index
