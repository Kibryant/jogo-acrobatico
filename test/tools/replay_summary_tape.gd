# What a replay gives the summary of TASK-14 (tools/replay_summary.gd), kept as a list: one Feed
# per fighter per tick, the input the fighter applied and its state, feet and velocity after the
# tick. The suites fill a tape, by hand (replay_summary_puppet.gd) or with the core's own rules
# (replay_summary_match.gd), and summarize() feeds it the way the contract asks: ticks ascending,
# the fighters ascending within one tick, then finish(). Only the summary's public interface,
# agreed in the TASK-14 plan, is used.
extends RefCounted

const ReplaySummary := preload("res://tools/replay_summary.gd")
const ChargedRig := preload("res://test/core/fighter/charged_rig.gd")
const MovementRig := preload("res://test/core/fighter/movement_rig.gd")


# One call of ReplaySummary.add().
class Feed:
	var tick: int
	var fighter: int
	var input: TickInput
	var state: FighterState
	var position: Vector3
	var velocity: Vector3


var movement: MovementConfig
var combat: CombatConfig
var feeds: Array[Feed] = []


# The numbers the replay played with, the header's: the summary is made with the same two.
func _init(movement_config: MovementConfig, combat_config: CombatConfig) -> void:
	movement = movement_config
	combat = combat_config


# movement_v0.tres as the configuration of one tickrate.
static func movement_v0(tickrate := 60) -> MovementConfig:
	return MovementRig.load_config(tickrate)


# combat_v0.tres as the configuration of one tickrate.
static func combat_v0(tickrate := 60) -> CombatConfig:
	return ChargedRig.load_combat(tickrate)


# A copy of combat_v0.tres a test may change before making its configuration: a replay recorded
# with other numbers.
static func combat_data_v0() -> CombatData:
	return ChargedRig.load_combat_data()


# Keeps one tick of one fighter. The state and the input are copied, so the caller may go on
# changing its own.
func record(
	tick: int,
	fighter: int,
	input: TickInput,
	state: FighterState,
	position: Vector3,
	velocity: Vector3,
) -> void:
	var feed := Feed.new()
	feed.tick = tick
	feed.fighter = fighter
	feed.input = copy_input(input)
	feed.state = state.copy()
	feed.position = position
	feed.velocity = velocity
	feeds.append(feed)


# The summary of the tape: every feed in the contract's order, then finish().
func summarize() -> ReplaySummary:
	var ordered := feeds.duplicate()
	ordered.sort_custom(_before)
	var summary := ReplaySummary.new(movement, combat)
	for feed: Feed in ordered:
		summary.add(feed.tick, feed.fighter, feed.input, feed.state, feed.position, feed.velocity)
	summary.finish()
	return summary


# The feed of one fighter on one tick, or null.
func feed_at(fighter: int, tick: int) -> Feed:
	for feed: Feed in feeds:
		if feed.fighter == fighter and feed.tick == tick:
			return feed
	return null


static func copy_input(input: TickInput) -> TickInput:
	var other := TickInput.new()
	other.move = input.move
	other.yaw = input.yaw
	other.pitch = input.pitch
	other.jump = input.jump
	other.dash = input.dash
	other.grapple = input.grapple
	other.light_attack = input.light_attack
	other.guard = input.guard
	other.charged_attack = input.charged_attack
	other.parry = input.parry
	other.guard_press = input.guard_press
	return other


static func _before(a: Feed, b: Feed) -> bool:
	if a.tick != b.tick:
		return a.tick < b.tick
	return a.fighter < b.fighter
