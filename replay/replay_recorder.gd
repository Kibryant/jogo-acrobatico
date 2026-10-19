# The replay recorder (TASK-10.3; DEC-0027 §5; F-044 §1): Sozinho records every session, always, so
# when Arthur finds a bug playing, its file already exists (F-112 §2). It writes a ReplayFile: the
# header when it starts, then, tick by tick, the input netfox applied to each fighter it follows
# and the check of the state that came out of it.
# It only reads, like the TickRecorder (net/tick_recorder.gd): it listens to netfox's
# after_process_tick, which comes after every fighter of the tick has moved, and there each
# fighter's box still holds the input netfox restored for that tick. It writes a fighter only on a
# tick netfox simulated it on: alive, with the input of that very tick. In Sozinho every tick of a
# loop runs once, fresh (Match._simulate_every_tick_of_the_loop); a tick older than its loop would
# be a resimulation, and the recorder keeps the first result.
# The file is saved every second (FLUSH_MS): a game closed abruptly loses at most the last second,
# and a reader drops the line it cut (ReplayFile). In its own folder it keeps the newest KEEP
# files it named, and never touches another file there.
class_name ReplayRecorder
extends Node

## Where Sozinho records (F-112 §2). The gate never writes here: tools/run_tests.sh checks it.
const DEFAULT_DIRECTORY := "user://replays/"
## The newest files kept in the folder (F-112 §2: about 4 MB each 15 minutes, under 100 MB).
const KEEP := 20
## ms between two saves to the disk (Claude's v0 reading, testes-e-entrega.md §4).
const FLUSH_MS := 1000
## The files it names: sozinho-AAAAMMDD-HHMMSS.replay, -2, -3... when a second already has one.
const FILE_PREFIX := "sozinho-"
const EXTENSION := "replay"

## The folder of the files it names; start() with a path writes that file instead.
@export var directory := DEFAULT_DIRECTORY
## The file it writes; empty until start().
var path := ""
## The rows written so far, one per tick and fighter.
var rows_written := 0

var _file: FileAccess
var _replay: ReplayFile
var _fighters: Array[Fighter] = []
var _first_tick := 0
var _loop_first_tick := 0
var _newest_tick := 0
var _flush_ticks := 1
var _ticks_since_flush := 0


func _init() -> void:
	name = "ReplayRecorder"


func _exit_tree() -> void:
	close()


# Starts the file of a match whose fighters are in it already: their first tick is the file's.
# file_path names the file; empty, the recorder names a new one in its folder and keeps the newest
# KEEP there. The error when the file cannot be written.
func start(game_match: Match, fighters: Array[Fighter], file_path := "") -> Error:
	assert(_file == null, "the recorder records one file")
	assert(not fighters.is_empty(), "a replay records at least one fighter")
	_fighters.assign(fighters)
	_first_tick = fighters[0].synchronizer.spawn_tick
	for fighter: Fighter in fighters:
		var first: int = fighter.synchronizer.spawn_tick
		_first_tick = mini(_first_tick, first)
	path = file_path
	if path.is_empty():
		var made := DirAccess.make_dir_recursive_absolute(directory)
		if made != OK:
			return made
		path = directory.path_join(_new_file_name())
	_file = FileAccess.open(path, FileAccess.WRITE)
	if _file == null:
		return FileAccess.get_open_error()
	_replay = ReplayFile.for_match(game_match, fighters.size(), _first_tick)
	_file.store_string(_replay.header_text())
	_file.flush()
	_flush_ticks = maxi(1, Ticks.from_ms(FLUSH_MS, NetworkTime.tickrate))
	_newest_tick = _first_tick - 1
	_loop_first_tick = NetworkTime.tick
	NetworkTime.before_tick_loop.connect(_on_tick_loop_start)
	NetworkRollback.after_process_tick.connect(_on_tick)
	if file_path.is_empty():
		prune(directory, KEEP)
	return OK


# Saves what is left and closes the file; the recorder writes nothing more.
func close() -> void:
	if _file == null:
		return
	NetworkTime.before_tick_loop.disconnect(_on_tick_loop_start)
	NetworkRollback.after_process_tick.disconnect(_on_tick)
	_file.flush()
	_file.close()
	_file = null


# True while a file is open.
func is_recording() -> bool:
	return _file != null


# Deletes the oldest files the recorder named in folder, so that keep remain; any other file stays.
# The names sort by their date and time.
static func prune(folder: String, keep: int) -> PackedStringArray:
	var names: Array[String] = []
	for file: String in DirAccess.get_files_at(folder):
		if file.begins_with(FILE_PREFIX) and file.get_extension() == EXTENSION:
			names.append(file)
	names.sort_custom(
		func(a: String, b: String) -> bool:
			return a.get_basename() < b.get_basename(),
	)
	var removed := PackedStringArray()
	for index: int in maxi(0, names.size() - keep):
		var old := folder.path_join(names[index])
		if DirAccess.remove_absolute(old) == OK:
			removed.append(old)
	return removed


func _new_file_name() -> String:
	var now := Time.get_datetime_dict_from_system()
	var stem := (
		"%s%04d%02d%02d-%02d%02d%02d"
		% [
			FILE_PREFIX,
			now["year"],
			now["month"],
			now["day"],
			now["hour"],
			now["minute"],
			now["second"],
		]
	)
	var file_name := "%s.%s" % [stem, EXTENSION]
	var copy := 2
	while FileAccess.file_exists(directory.path_join(file_name)):
		file_name = "%s-%d.%s" % [stem, copy, EXTENSION]
		copy += 1
	return file_name


func _on_tick_loop_start() -> void:
	_loop_first_tick = NetworkTime.tick


func _on_tick(tick: int) -> void:
	if tick <= _newest_tick or tick < _loop_first_tick:
		return
	# netfox's clock is at the loop's end while the rollback runs its ticks.
	var loop := NetworkTime.tick - _loop_first_tick
	var row := ReplayFile.Row.new()
	row.tick = tick
	row.loop = loop
	var wrote := false
	for index: int in _fighters.size():
		var fighter := _fighters[index]
		if not RollbackLivenessServer.is_alive(fighter, tick):
			continue
		if fighter.synchronizer.get_input_age() != 0:
			continue
		row.fighter = index
		for field: String in ReplayFile.input_fields():
			row.input.set(field, fighter.input.get(field))
		row.check = StateTrace.check_of(StateTrace.line_of(fighter, index, tick, _first_tick))
		_file.store_string(_replay.row_text(row) + "\n")
		rows_written += 1
		wrote = true
	if not wrote:
		return
	_newest_tick = tick
	_ticks_since_flush += 1
	if _ticks_since_flush >= _flush_ticks:
		_file.flush()
		_ticks_since_flush = 0
