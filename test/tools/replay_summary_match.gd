# A match played by the core's own rules, recorded on a tape for the summary of TASK-14: every
# fighter is a ChargedRig in a Duel (test/core/fighter), so the slot, the phases, the contacts, the
# stuns and the hitstop are the ones a real match writes, never states made up by hand. Every
# fighter starts as the spawn leaves it, standing on the floor at tick 0 with the health at the
# combat's max, and nothing sets a state by hand afterwards: the state a tick started from is
# always the one the tick before left, as in a replay.
# A fighter is driven by what it holds (the stick, the camera's yaw, the guard button), changed
# between runs, and by its presses, planned by tick before the tick runs.
extends RefCounted

const Tape := preload("res://test/tools/replay_summary_tape.gd")
const ChargedRig := preload("res://test/core/fighter/charged_rig.gd")
const Duel := preload("res://test/core/fighter/duel.gd")

## The guard button going down (TickInput.guard_press and guard): beside the five commands and the
## parry, a press() may carry it; in the charged's windup it is the feint.
const GUARD_PRESS := &"guard_press"

const NAMES: Array[StringName] = [&"fighter_0", &"fighter_1", &"fighter_2", &"fighter_3"]


# What one fighter holds, and its presses by tick.
class Seat:
	var held := TickInput.new()
	var presses: Dictionary[int, Array] = { }


var tape: Tape
var duel := Duel.new()
var _seats: Array[Seat] = []


func _init(movement_config: MovementConfig, combat_config: CombatConfig) -> void:
	tape = Tape.new(movement_config, combat_config)


# A fighter standing at feet with the camera along yaw. Returns its index, the summary's.
func add_fighter(feet := Vector3.ZERO, yaw := 0.0) -> int:
	var index := _seats.size()
	var seat := Seat.new()
	seat.held.yaw = yaw
	_seats.append(seat)
	var rig := ChargedRig.new(NAMES[index], tape.movement, tape.combat, 0, feet, yaw)
	duel.add(rig, _input_of.bind(index))
	return index


# From the next tick on, the fighter pushes the stick: x to the right, y forward.
func push(fighter: int, move: Vector2) -> void:
	_seats[fighter].held.move = move


# From the next tick on, the fighter's camera looks along yaw.
func look(fighter: int, yaw: float) -> void:
	_seats[fighter].held.yaw = yaw


# From the next tick on, the fighter holds the guard button, or lets it go.
func hold_guard(fighter: int, held: bool) -> void:
	_seats[fighter].held.guard = held


# The one-tick touches of a tick still to run: FighterCommand's keys and GUARD_PRESS.
func press(fighter: int, tick: int, commands: Array[StringName]) -> void:
	assert(tick >= next_tick(), "a press is planned before its tick runs")
	_seats[fighter].presses[tick] = commands


# The floor under one fighter, switched off as past a ledge, or on again (MovementRig.floor_on).
func set_floor(fighter: int, on: bool) -> void:
	duel.fighter(fighter).rig.floor_on = on


# The next tick to run; the first is 0.
func next_tick() -> int:
	if _seats.is_empty():
		return 0
	return duel.tick()


func run(ticks: int) -> void:
	for _step: int in ticks:
		_step_once()


# Runs up to and including last_tick.
func run_through(last_tick: int) -> void:
	while next_tick() <= last_tick:
		_step_once()


# The state one fighter ended a tick already run with.
func state(fighter: int, tick: int) -> FighterState:
	return tape.feed_at(fighter, tick).state


# The feet of one fighter after a tick already run.
func feet(fighter: int, tick: int) -> Vector3:
	return tape.feed_at(fighter, tick).position


# The velocity of one fighter after a tick already run.
func velocity(fighter: int, tick: int) -> Vector3:
	return tape.feed_at(fighter, tick).velocity


# The first tick already run, from `from` on, whose end state for the fighter satisfies the
# predicate (FighterState, tick -> bool); -1 when none does.
func first_tick(fighter: int, from: int, predicate: Callable) -> int:
	for feed: Tape.Feed in tape.feeds:
		if feed.fighter != fighter or feed.tick < from:
			continue
		var verdict: bool = predicate.call(feed.state, feed.tick)
		if verdict:
			return feed.tick
	return -1


func summarize() -> Tape.ReplaySummary:
	return tape.summarize()


func _step_once() -> void:
	var row := duel.step()
	for index: int in _seats.size():
		tape.record(
			row.tick,
			index,
			_input_of(row.tick, index),
			row.ends[index],
			row.feet[index],
			row.velocities[index],
		)


# What the fighter applies on a tick: what it holds, plus the presses planned for the tick.
func _input_of(tick: int, index: int) -> TickInput:
	var seat := _seats[index]
	var input := Tape.copy_input(seat.held)
	if not seat.presses.has(tick):
		return input
	var commands: Array = seat.presses[tick]
	for command: StringName in commands:
		match command:
			FighterCommand.JUMP:
				input.jump = true
			FighterCommand.DASH:
				input.dash = true
			FighterCommand.GRAPPLE:
				input.grapple = true
			FighterCommand.LIGHT_ATTACK:
				input.light_attack = true
			FighterCommand.CHARGED_ATTACK:
				input.charged_attack = true
			FighterCommand.PARRY:
				input.parry = true
			GUARD_PRESS:
				input.guard_press = true
				input.guard = true
			_:
				assert(false, "unknown press %s" % command)
	return input
