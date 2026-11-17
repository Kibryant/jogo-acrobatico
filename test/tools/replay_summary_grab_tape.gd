# The tape of TASK-14 (replay_summary_tape.gd) with the touch of TASK-12.4: a feed's input also
# keeps TickInput.guard_break, which the tape's own copy, written before the touch existed, leaves
# out. Everything else is the tape's: the feeds, their order and summarize().
extends "res://test/tools/replay_summary_tape.gd"

const GrabRig := preload("res://test/core/fighter/grab_rig.gd")


func record(
	tick: int,
	fighter: int,
	input: TickInput,
	state: FighterState,
	position: Vector3,
	velocity: Vector3,
) -> void:
	super(tick, fighter, input, state, position, velocity)
	if GrabRig.touches_guard_break(input):
		GrabRig.touching(feeds[feeds.size() - 1].input, GrabRig.GUARD_BREAK)
