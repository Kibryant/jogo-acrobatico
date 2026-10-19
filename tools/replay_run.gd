# The headless replay player (TASK-10.3, criterion 4; DEC-0027 §5): plays a replay file through
# the real Match in Sozinho, with the movement numbers of its header, and returns the state trace
# of every tick (StateTrace) with its sha256. tools/replay_play.gd runs it from the command line,
# for tools/replay.sh, and test/replay/ runs it in the gate, the same way.
# The run is the reference's (test/reference/reference_run.gd): Godot's offline peer, a SubViewport
# with a physics world of its own, and netfox's ticks by hand, inside a physics frame
# (test/support/netfox_ticks.gd, the exception of DEC-0027 §3). It plays loop by loop, as recorded:
# each loop runs as many ticks as the recording's did, and the clock starts on the first recorded
# tick, so every tick and every stamp is the recorded one. A jump of the recorded clock plays as
# the same jump. Each fighter's box takes its rows tick by tick (FighterInput.play_rows), and when
# the file carries the check column, the run says the first tick whose state left the one the live
# game computed.
extends RefCounted

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const MATCH_SCENE := preload("res://match/match.tscn")


class Result:
	## The state after every tick, counted from the first recorded tick.
	var trace: StateTrace
	## µs of wall clock for the ticks, without the setup.
	var run_usec := 0
	## Ticks and loops played, and the jumps of the clock among them.
	var ticks := 0
	var loops := 0
	var jumps := 0
	## True when the file carries the check column.
	var checked := false
	## The first tick, counted from the first recorded one, whose state differs from the live
	## game's check; -1 when none does or nothing was checked.
	var first_apart := -1
	var first_apart_fighter := -1
	## The movement data the Match played.
	var movement_data: MovementData


	# One line, for the log.
	func describe() -> String:
		var apart := "none" if first_apart < 0 else str(first_apart)
		if not checked:
			apart = "unchecked (the file has no check column)"
		return (
			"played %d ticks in %d loops (%d jumps) in %.0f ms, sha256 %s, first divergent tick %s"
			% [ticks, loops, jumps, run_usec / 1000.0, trace.sha256(), apart]
		)


# Plays replay under host, which must be in the tree, with the movement numbers movement, and
# frees everything it made.
func play(host: Node, replay: ReplayFile, movement: MovementData) -> Result:
	assert(replay.errors.is_empty(), "play a file without errors: %s" % replay.errors)
	var first_tick := replay.first_tick()
	NetfoxTicks.reset()
	NetfoxTicks.set_tick(first_tick)
	var stage := SubViewport.new()
	stage.own_world_3d = true
	host.add_child(stage)
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	var game_match := node as Match
	game_match.movement_data = movement
	stage.add_child(game_match)
	var fighters: Array[Fighter] = []
	for slot: int in replay.fighter_count():
		var input_owner := host.multiplayer.get_unique_id()
		var fighter := game_match.spawn_fighter(slot, input_owner, first_tick)
		fighter.input.play_rows(ReplaySource.by_tick(replay, slot))
		fighters.append(fighter)
	var result := Result.new()
	result.trace = StateTrace.new(first_tick)
	result.trace.observe(fighters)
	result.checked = replay.has_check()
	result.jumps = replay.jumps
	result.movement_data = game_match.movement_data
	# netfox's synchronizer registers with call_deferred; the ticks then run inside a physics
	# frame (test/support/netfox_ticks.gd).
	await host.get_tree().process_frame
	await host.get_tree().physics_frame
	var started_usec := Time.get_ticks_usec()
	for loop: ReplayFile.Loop in replay.loops:
		if loop.first_tick != NetworkTime.tick:
			NetfoxTicks.set_tick(loop.first_tick)
		NetfoxTicks.run_loop(loop.size)
		result.ticks += loop.size
		result.loops += 1
	result.run_usec = Time.get_ticks_usec() - started_usec
	result.trace.stop()
	stage.free()
	NetfoxTicks.reset()
	if result.checked:
		_compare_checks(replay, result)
	return result


# The first line of the trace whose check differs from its row's.
static func _compare_checks(replay: ReplayFile, result: Result) -> void:
	var checks: Dictionary[Vector2i, String] = { }
	for row: ReplayFile.Row in replay.rows:
		checks[Vector2i(row.tick - replay.first_tick(), row.fighter)] = row.check
	for line: String in result.trace.lines():
		var cells := line.split(ReplayFile.CELL_SEPARATOR, true, 2)
		var key := Vector2i(cells[0].to_int(), cells[1].to_int())
		if checks.get(key, "") != StateTrace.check_of(line):
			result.first_apart = key.x
			result.first_apart_fighter = key.y
			return
