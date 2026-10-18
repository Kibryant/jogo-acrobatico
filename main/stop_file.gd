# The server's stop file (DEC-0032 §2; TASK-9, choice 2): the clean way to close a dedicated
# server from outside, the same on Windows and in Docker, where a `docker exec … touch` makes the
# file appear. Godot does not handle SIGTERM, so `docker stop` kills it with 143 (F-073 §2). The
# watcher checks once per second whether the file exists, says so once and leaves the file alone.
class_name StopFile
extends Node

## The file appeared: the server must close.
signal appeared

## s: the check's period (TASK-9, choice 2).
const CHECK_INTERVAL_S := 1.0

## Where the file appears; the Main takes it from --stop-file.
var path: String

var _seen := false


func _init(file_path: String) -> void:
	path = file_path
	name = "StopFile"


func _ready() -> void:
	var timer := Timer.new()
	timer.wait_time = CHECK_INTERVAL_S
	timer.timeout.connect(check)
	add_child(timer)
	timer.start()


# True once the file has appeared; the first time, it also emits appeared.
func check() -> bool:
	if not _seen and FileAccess.file_exists(path):
		_seen = true
		appeared.emit()
	return _seen
