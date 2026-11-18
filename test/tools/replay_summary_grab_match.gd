# A match played by the core's own rules, recorded on a tape for the summary, as
# replay_summary_match.gd plays it, with the guard break of TASK-12.4: every fighter is a GrabRig
# in a Duel (test/core/fighter), driven by a script (grab_player.gd) that may press the guard
# break, the tech's key too, and turn its camera from a tick on. Every fighter starts as the spawn
# leaves it, standing on the floor at tick 0 with the health at the combat's max, and nothing sets
# a state by hand afterwards.
extends RefCounted

const ReplaySummary := preload("res://tools/replay_summary.gd")
const Tape := preload("res://test/tools/replay_summary_grab_tape.gd")
const GrabRig := preload("res://test/core/fighter/grab_rig.gd")
const Player := preload("res://test/core/fighter/grab_player.gd")
const Duel := preload("res://test/core/fighter/duel.gd")

const NAMES: Array[StringName] = [&"fighter_0", &"fighter_1", &"fighter_2", &"fighter_3"]

var tape: Tape
var duel := Duel.new()
var _players: Array[Player] = []


func _init(movement_config: MovementConfig, combat_config: CombatConfig) -> void:
	tape = Tape.new(movement_config, combat_config)


# A fighter standing at feet with the camera along yaw. Returns its index, the summary's.
func add_fighter(feet := Vector3.ZERO, yaw := 0.0) -> int:
	var index := _players.size()
	var player := Player.new(yaw)
	_players.append(player)
	duel.add(GrabRig.new(NAMES[index], tape.movement, tape.combat, 0, feet, yaw), player.input)
	return index


# One touch of a tick still to run: FighterCommand's keys, GrabRig.GUARD_BREAK and
# GrabRig.GUARD_PRESS.
func press(fighter: int, tick: int, command: StringName) -> void:
	assert(tick >= next_tick(), "a press is planned before its tick runs")
	_players[fighter].press(tick, command)


# From this tick on, the fighter's camera looks along yaw.
func look_from(fighter: int, tick: int, yaw: float) -> void:
	assert(tick >= next_tick(), "a turn is planned before its tick runs")
	_players[fighter].look_from(tick, yaw)


# The next tick to run; the first is 0.
func next_tick() -> int:
	if _players.is_empty():
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


func summarize() -> ReplaySummary:
	return tape.summarize()


func _step_once() -> void:
	var row := duel.step()
	for index: int in _players.size():
		tape.record(
			row.tick,
			index,
			_players[index].input(row.tick),
			row.ends[index],
			row.feet[index],
			row.velocities[index],
		)
