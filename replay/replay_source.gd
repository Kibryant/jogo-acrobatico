# The rows of one fighter of a replay, as the input of each tick (TASK-10.3): once
# FighterInput.play_rows() takes a source, the box takes each tick's input from it instead of the
# devices, a bot or the sampler.
# - By tick, the headless player's way (tools/replay_run.gd): netfox's clock runs the recorded
#   ticks themselves, from the first and through every jump, and each tick finds its own row.
# - In order, the --watch's way: the clock is the real one and starts on another tick, so the k-th
#   tick from the fighter's first plays the k-th row. A jump of the recorded clock, which the
#   watch cannot make without writing netfox's clock, plays there as ticks in a row.
# A tick without a row, after the end, has no input: the fighter stands.
class_name ReplaySource
extends RefCounted

var _inputs: Array[TickInput] = []
var _by_tick: Dictionary[int, TickInput] = { }
var _in_order := false
var _first_tick := 0


# The rows of fighter, each on its own recorded tick.
static func by_tick(replay: ReplayFile, fighter: int) -> ReplaySource:
	var source := ReplaySource.new()
	for row: ReplayFile.Row in replay.rows_of(fighter):
		source.add(row.tick, row.input)
	return source


# The rows of fighter one after the other, the first on first_tick.
static func in_order(replay: ReplayFile, fighter: int, first_tick: int) -> ReplaySource:
	var source := ReplaySource.new()
	source.play_in_order_from(first_tick)
	for row: ReplayFile.Row in replay.rows_of(fighter):
		source.add(row.tick, row.input)
	return source


# One more row, on tick when played by tick.
func add(tick: int, input: TickInput) -> void:
	_inputs.append(input)
	_by_tick[tick] = input


# From now on the rows play one after the other, the first on first_tick.
func play_in_order_from(first_tick: int) -> void:
	_in_order = true
	_first_tick = first_tick


# The input of tick; null when the replay has none for it.
func input_at(tick: int) -> TickInput:
	if _in_order:
		var index := tick - _first_tick
		return _inputs[index] if index >= 0 and index < _inputs.size() else null
	if _by_tick.has(tick):
		return _by_tick[tick]
	return null


# How many ticks the source holds.
func size() -> int:
	return _inputs.size()
