# The --watch of a replay (TASK-10.3, criteria 5 and 8): Sozinho on the real clock, with the
# fighters fed by the file's rows (FighterInput.play_rows) instead of the keyboard, so Arthur sees
# his own session played again. It never writes netfox's clock: that is the tests' and the tools'
# exception (DEC-0027 §3), never the game's. The clock starts on its own tick, so the k-th tick
# from the fighters' first plays the k-th recorded row (ReplaySource.in_order).
# While it plays, it watches like the headless player does: the state trace of every tick, counted
# from its first (StateTrace), the size of each tick loop it ran, and, when the file carries the
# check column, the first tick whose state left the one the live game computed. Once every row has
# played it emits finished; the Main shows the end text.
class_name ReplayWatch
extends Node

## Every row has played.
signal finished

## The replay it plays.
var replay: ReplayFile
## The state of every tick it played, counted from its first.
var trace: StateTrace
## The size of the loop each tick ran in here, by tick counted from the first.
var loop_sizes: Dictionary[int, int] = { }
## The first tick, counted from the first, whose state differs from the recording's check; -1
## while none does, or when the file has no check column.
var first_apart := -1
## The fighter of first_apart.
var first_apart_fighter := -1
## Ticks played, and frames drawn, while the replay played.
var ticks_played := 0
var frames := 0
## True once every row has played.
var done := false
## The camera that follows the first fighter; it turns to where the fighter looks. Null without one.
var camera: CameraRig

var _fighters: Array[Fighter] = []
var _first_tick := 0
# Ticks in the file, and whether its rows carry the check.
var _length := 0
var _checked := false
var _loop_first_tick := 0
var _started_usec := 0
var _elapsed_usec := 0


func _init(replay_file: ReplayFile, fighters: Array[Fighter], first_tick: int) -> void:
	name = "ReplayWatch"
	replay = replay_file
	_fighters.assign(fighters)
	_first_tick = first_tick
	_length = replay.tick_count()
	_checked = replay.has_check()
	trace = StateTrace.new(first_tick)


func _enter_tree() -> void:
	NetworkTime.before_tick_loop.connect(_on_tick_loop_start)
	NetworkTime.after_tick_loop.connect(_on_tick_loop_end)
	NetworkRollback.after_process_tick.connect(_on_tick)


func _exit_tree() -> void:
	NetworkTime.before_tick_loop.disconnect(_on_tick_loop_start)
	NetworkTime.after_tick_loop.disconnect(_on_tick_loop_end)
	NetworkRollback.after_process_tick.disconnect(_on_tick)


func _ready() -> void:
	_started_usec = Time.get_ticks_usec()
	if _length == 0:
		_finish()


func _process(_delta: float) -> void:
	if not done:
		frames += 1
	if camera != null and not _fighters.is_empty():
		camera.yaw = _fighters[0].state.facing_yaw


# Writes the trace to path, and the size of each loop beside it, in path + ".loops": one line
# per tick, the tick counted from the first and the size of the loop it ran in here.
func save_trace(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(trace.text())
	file.close()
	var loops := FileAccess.open(path + ".loops", FileAccess.WRITE)
	if loops == null:
		return FileAccess.get_open_error()
	var lines := PackedStringArray()
	for tick: int in _length:
		lines.append("%d,%d" % [tick, loop_sizes.get(tick, 0)])
	loops.store_string("\n".join(lines) + "\n")
	loops.close()
	return OK


# What the window played, one line each, for the log.
func summary() -> PackedStringArray:
	var lines := PackedStringArray()
	var seconds := _elapsed_usec / 1_000_000.0
	var counts: Dictionary[int, int] = { }
	for tick: int in loop_sizes:
		var size: int = loop_sizes[tick]
		var seen: int = counts.get(size, 0)
		counts[size] = seen + 1
	var spread := PackedStringArray()
	var sizes := counts.keys()
	sizes.sort()
	for size: int in sizes:
		spread.append("%d ticks in loops of %d" % [counts[size], size])
	lines.append(
		"played %d ticks in %.1f s, %d frames, %.1f fps; %s"
		% [
			ticks_played,
			seconds,
			frames,
			frames / seconds if seconds > 0.0 else 0.0,
			", ".join(spread),
		],
	)
	lines.append("trace sha256 %s" % trace.sha256())
	if not _checked:
		lines.append("the file has no check column: nothing to compare with the live game")
	elif first_apart < 0:
		lines.append("against the live game: equal on every tick")
	else:
		var row := _row(first_apart, first_apart_fighter)
		lines.append(
			"against the live game: apart from tick %d (fighter %d); here it ran in a loop of"
			% [first_apart, first_apart_fighter]
			+ " %d ticks, live in one of %d" % [loop_sizes.get(first_apart, 0), row.loop],
		)
	return lines


func _on_tick_loop_start() -> void:
	_loop_first_tick = NetworkTime.tick


func _on_tick_loop_end() -> void:
	var size := NetworkTime.tick - _loop_first_tick
	for tick: int in range(_loop_first_tick, NetworkTime.tick):
		var index := tick - _first_tick
		if index >= 0 and index < _length:
			loop_sizes[index] = size
	if done and _elapsed_usec == 0:
		_elapsed_usec = Time.get_ticks_usec() - _started_usec
		finished.emit()


func _on_tick(tick: int) -> void:
	var index := tick - _first_tick
	if done or index < 0 or index >= _length or index < ticks_played:
		return
	for fighter_index: int in _fighters.size():
		var line := trace.add(tick, fighter_index, _fighters[fighter_index])
		if first_apart < 0 and _checked:
			if StateTrace.check_of(line) != _row(index, fighter_index).check:
				first_apart = index
				first_apart_fighter = fighter_index
	ticks_played = index + 1
	if ticks_played == _length:
		done = true


# The row of fighter on the tick-th tick from the first: the file's rows go by tick, then by
# fighter.
func _row(tick: int, fighter: int) -> ReplayFile.Row:
	return replay.rows[tick * replay.fighter_count() + fighter]


func _finish() -> void:
	done = true
	_elapsed_usec = maxi(1, Time.get_ticks_usec() - _started_usec)
	finished.emit.call_deferred()
