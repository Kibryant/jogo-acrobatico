# Writes down, tick by tick, what this game computed for the fighters it follows (TASK-9, criterion
# 12; --record=PATH). It only reads: it listens to netfox's after_process_tick, which comes after
# every fighter of the tick has moved, like the SyncTest's referee, so neither the core nor the
# fighter's tick knows it is there, and the run it records is the run without it.
# netfox simulates a fighter only on a tick where it is alive, from its first tick on
# (Fighter._rollback_spawn), and, without prediction, has its input (rede.md §4;
# rollback-simulation-server.gd, _get_nodes_to_simulate): on any other tick the fighter kept a
# restored state, which is no result, so the recorder skips it. A client keeps its first result of
# each tick, what its player saw; the server keeps its last one, what it confirmed after every late
# input.
class_name TickRecorder
extends Node

## Which result of a tick the record keeps.
enum Keep {
	## The first one: what a client predicted.
	FIRST,
	## The last one: what the server confirmed.
	LAST,
}

## Where save() writes.
var path: String
var record := TickRecord.new()

var _keep: Keep
var _fighters: Array[Fighter] = []


func _init(file_path: String, keep: Keep) -> void:
	name = "TickRecorder"
	path = file_path
	_keep = keep


func _enter_tree() -> void:
	NetworkRollback.after_process_tick.connect(_observe)


func _exit_tree() -> void:
	NetworkRollback.after_process_tick.disconnect(_observe)


# From the next tick on, the record follows fighter.
func follow(fighter: Fighter) -> void:
	if not _fighters.has(fighter):
		_fighters.append(fighter)


# The record stops following fighter, before it leaves the match.
func forget(fighter: Fighter) -> void:
	_fighters.erase(fighter)


# Writes the record as text; the error when the file cannot be written.
func save() -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(record.to_text())
	file.close()
	return OK


func _observe(tick: int) -> void:
	for fighter: Fighter in _fighters:
		# Alive, with the input of this very tick: netfox simulated the fighter on it.
		var alive := RollbackLivenessServer.is_alive(fighter, tick)
		if not alive or fighter.synchronizer.get_input_age() != 0:
			continue
		var sample := TickRecord.Sample.new(
			fighter.position,
			fighter.state.on_floor,
			fighter.state.mode,
		)
		if _keep == Keep.FIRST:
			record.keep_first(String(fighter.name), tick, sample)
		else:
			record.keep_last(String(fighter.name), tick, sample)
