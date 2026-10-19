# A scripted Sozinho session, recorded by the real ReplayRecorder (TASK-10.3, criteria 4 and 5):
# the gate's tests play it again, and `bash tools/replay.sh --sample=FILE` writes it for the
# --watch measurements. It records what makes a replay hard to get right: a yaw that turns by a
# number with many digits on every loop, moves that are the mean of 2 or 3 different frames, so
# never -1, 0 or 1, tick loops of 1, 2 and 3 ticks, as frames at 60, 30 and 20 fps, and jumps with
# a double jump at the top. Optionally the clock jumps once, as netfox's does after a stall.
# The run is the reference's (test/reference/reference_run.gd): the real Match in Sozinho, in a
# SubViewport with its own physics world, with netfox's ticks by hand inside a physics frame
# (test/support/netfox_ticks.gd), starting on FIRST_TICK.
extends RefCounted

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const MATCH_SCENE := preload("res://match/match.tscn")

## Ticks of the session: 10 s at 60 ticks per second.
const TICKS := 600
## netfox's clock on the first tick: not 0, so the file's absolute ticks and the trace's ticks,
## counted from the first, differ.
const FIRST_TICK := 1000
## The sizes of the tick loops, in turn.
const LOOPS: Array[int] = [1, 1, 2, 1, 3, 1, 2]
## What the keys push on each frame, in turn (x right, y forward): one loop samples 1 to 3 of
## them, and its move is their mean (InputSampler).
const MOVES: Array[Vector2] = [
	Vector2(0, 1),
	Vector2(0.6, 0.8),
	Vector2(0, 1),
	Vector2(-0.3, 0.9),
	Vector2(1, 0),
	Vector2(0, 1),
	Vector2.ZERO,
]
## rad the camera turns on each loop: a mouse never stops on a round number.
const TURN := 0.0123456789
## Every PRESS_EVERY loops a press on the floor, and DOUBLE_AFTER loops later a press in the air,
## about 14 ticks after the jump, before its apex: the double jump.
const PRESS_EVERY := 45
const DOUBLE_AFTER := 9
## Ticks the clock jumps by, when it jumps.
const CLOCK_JUMP := 30


class Result:
	## The file the recorder wrote, and its text.
	var path: String
	var text: String
	## The state after every tick, as the live run computed it.
	var trace: StateTrace
	## Double jumps the fighter made.
	var double_jumps := 0
	## Ticks and loops run, and µs of wall clock for them.
	var ticks := 0
	var loops := 0
	var record_usec := 0


# Records the session to path under host, which must be in the tree; with jump_before_loop, the
# clock jumps by CLOCK_JUMP ticks right before that loop. Frees everything it made.
func record(host: Node, path: String, ticks := TICKS, jump_before_loop := -1) -> Result:
	NetfoxTicks.reset()
	NetfoxTicks.set_tick(FIRST_TICK)
	var stage := SubViewport.new()
	stage.own_world_3d = true
	host.add_child(stage)
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	var game_match := node as Match
	stage.add_child(game_match)
	var fighter := game_match.spawn_fighter(0, host.multiplayer.get_unique_id())
	var recorder := ReplayRecorder.new()
	stage.add_child(recorder)
	var error := recorder.start(game_match, [fighter], path)
	assert(error == OK, "cannot record to %s: %s" % [path, error_string(error)])
	var result := Result.new()
	result.path = path
	result.trace = StateTrace.new(FIRST_TICK)
	result.trace.observe([fighter])
	await host.get_tree().process_frame
	await host.get_tree().physics_frame
	var started_usec := Time.get_ticks_usec()
	while result.ticks < ticks:
		var loop := result.loops
		if loop == jump_before_loop:
			NetfoxTicks.set_tick(NetworkTime.tick + CLOCK_JUMP)
		for move: Vector2 in frames_of(loop):
			fighter.input.sample_frame(move, yaw_of(loop))
		if presses_at(loop):
			fighter.input.press_jump()
		var size := mini(LOOPS[loop % LOOPS.size()], ticks - result.ticks)
		var stamp := fighter.state.double_jump_tick
		NetfoxTicks.run_loop(size)
		var stamped := fighter.state.double_jump_tick
		if stamped != stamp and stamped != FighterState.NEVER:
			result.double_jumps += 1
		result.ticks += size
		result.loops += 1
	result.record_usec = Time.get_ticks_usec() - started_usec
	recorder.close()
	result.trace.stop()
	stage.free()
	NetfoxTicks.reset()
	result.text = FileAccess.get_file_as_string(path)
	return result


# The frames sampled before loop: 1 to 3 of MOVES, in turn.
static func frames_of(loop: int) -> Array[Vector2]:
	var frames: Array[Vector2] = []
	for frame: int in 1 + loop % 3:
		frames.append(MOVES[(loop + frame) % MOVES.size()])
	return frames


# Where the camera looks on loop: TURN more on each one.
static func yaw_of(loop: int) -> float:
	return wrapf(loop * TURN, -PI, PI)


static func presses_at(loop: int) -> bool:
	var phase := loop % PRESS_EVERY
	return loop > 0 and (phase == 0 or phase == DOUBLE_AFTER)
