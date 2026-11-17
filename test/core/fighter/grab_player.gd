# The script of one fighter of a Duel for the suites of TASK-12.4: what it holds (the stick, the
# camera's yaw, the guard button), each changed from a tick on, and its one-tick touches by tick.
# A test may add a touch or a change for any tick still to run, so a scene can be planned around a
# contact tick read from the run itself. input() is what Duel.add takes: tick -> TickInput.
extends RefCounted

const GrabRig := preload("res://test/core/fighter/grab_rig.gd")

var _yaws: Dictionary[int, float] = { }
var _moves: Dictionary[int, Vector2] = { }
var _guards: Dictionary[int, bool] = { }
var _touches: Dictionary[int, Array] = { }
var _first_yaw: float


# A fighter that holds nothing and looks along camera_yaw.
func _init(camera_yaw := 0.0) -> void:
	_first_yaw = camera_yaw


# One touch on one tick, by its command (GrabRig.touching).
func press(tick: int, command: StringName) -> void:
	if not _touches.has(tick):
		_touches[tick] = []
	_touches[tick].append(command)


# The same touch on every tick from `from` to `to`, inclusive.
func press_every_tick(from: int, to: int, command: StringName) -> void:
	for tick: int in range(from, to + 1):
		press(tick, command)


# From this tick on, the camera looks along yaw.
func look_from(tick: int, yaw: float) -> void:
	_yaws[tick] = yaw


# From this tick on, the stick is pushed: x to the right, y forward.
func push_from(tick: int, move: Vector2) -> void:
	_moves[tick] = move


# From this tick on, the guard button is held, or let go.
func guard_from(tick: int, held: bool) -> void:
	_guards[tick] = held


# The camera's yaw on a tick.
func yaw_at(tick: int) -> float:
	var latest := -1
	var yaw := _first_yaw
	for from: int in _yaws:
		if from <= tick and from > latest:
			latest = from
			yaw = _yaws[from]
	return yaw


func input(tick: int) -> TickInput:
	var made := GrabRig.walk(_move_at(tick), yaw_at(tick))
	made.guard = _guard_at(tick)
	if _touches.has(tick):
		var commands: Array = _touches[tick]
		for command: StringName in commands:
			GrabRig.touching(made, command)
	return made


func _move_at(tick: int) -> Vector2:
	var latest := -1
	var move := Vector2.ZERO
	for from: int in _moves:
		if from <= tick and from > latest:
			latest = from
			move = _moves[from]
	return move


func _guard_at(tick: int) -> bool:
	var latest := -1
	var held := false
	for from: int in _guards:
		if from <= tick and from > latest:
			latest = from
			held = _guards[from]
	return held
