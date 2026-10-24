# A scripted Sozinho session, recorded by the real ReplayRecorder (TASK-10.3, criteria 4 and 5):
# the gate's tests play it again, and `bash tools/replay.sh --sample=FILE` writes it for the
# --watch measurements. It records what makes a replay hard to get right: a yaw that turns by a
# number with many digits on every loop, moves that are the mean of 2 or 3 different frames, so
# never -1, 0 or 1, tick loops of 1, 2 and 3 ticks, as frames at 60, 30 and 20 fps, jumps with a
# double jump at the top and, from TASK-10.4, a dash between two jumps, so the file's dash column
# holds presses (criterion 6). From TASK-10.5 it opens with a wall run and a wall jump (WallPhase),
# so the trace holds the wall's fields with a wall in them: on ParedeLonga's east face since
# TASK-10.10, because PlataformaVaoA, 2 m tall, no longer covers the body (movimento.md, "Corrida
# na parede": "A parede cobre o corpo"). Optionally the clock jumps once, as netfox's does after
# a stall.
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
## DASH_AFTER loops after each jump, about 47 ticks, a press of the dash: on the floor again after
## the double jump's landing, or kept in the slot for it.
const DASH_AFTER := 30
## Ticks the clock jumps by, when it jumps.
const CLOCK_JUMP := 30
## The wall phase (TASK-10.5; TASK-10.10): from the spawn point the fighter runs to WALL_FROM,
## north-east of ParedeLonga, whose east face looks east from x = 15 over z -20 to 4, 4 m tall
## (arena.tscn); the straight line there passes north of the wall's end. From there it runs south
## with a quarter of its speed into the face, about 14°, jumps JUMP_BEFORE_FACE before the capsule
## would touch it, runs on the wall WALL_RUN_TICKS ticks and wall-jumps away.
const WALL_FROM := Vector3(16.6, 0, 5)
const INTO_WALL := Vector3(-0.25, 0, -1)
const WALL_FACE_X := 15.0
const JUMP_BEFORE_FACE := 0.6
const WALL_RUN_TICKS := 4
## m: WALL_FROM counts as reached this close.
const NEAR := 0.5


class Result:
	## The file the recorder wrote, and its text.
	var path: String
	var text: String
	## The state after every tick, as the live run computed it.
	var trace: StateTrace
	## Double jumps the fighter made.
	var double_jumps := 0
	## Dashes the fighter made.
	var dashes := 0
	## Wall runs the fighter started and wall jumps it made.
	var wall_runs := 0
	var wall_jumps := 0
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
	var wall_phase := WallPhase.new(fighter, game_match.config.capsule_radius)
	# The loop the script starts on, once the wall phase is over.
	var script_from := -1
	var started_usec := Time.get_ticks_usec()
	while result.ticks < ticks:
		var loop := result.loops
		if loop == jump_before_loop:
			NetfoxTicks.set_tick(NetworkTime.tick + CLOCK_JUMP)
		if script_from < 0 and wall_phase.done():
			script_from = loop
		if script_from < 0:
			wall_phase.drive()
		else:
			var step := loop - script_from
			for move: Vector2 in frames_of(step):
				fighter.input.sample_frame(move, yaw_of(step))
			if presses_at(step):
				fighter.input.press_jump()
			if dashes_at(step):
				fighter.input.press_dash()
		var size := mini(LOOPS[loop % LOOPS.size()], ticks - result.ticks)
		var stamp := fighter.state.double_jump_tick
		var dash_stamp := fighter.state.dash_tick
		var wall_stamp := fighter.state.wall_jump_tick
		var run_stamp := _run_stamp(fighter.state)
		NetfoxTicks.run_loop(size)
		var stamped := fighter.state.double_jump_tick
		if stamped != stamp and stamped != FighterState.NEVER:
			result.double_jumps += 1
		if fighter.state.dash_tick != dash_stamp:
			result.dashes += 1
		if fighter.state.wall_jump_tick != wall_stamp:
			result.wall_jumps += 1
		var run_now := _run_stamp(fighter.state)
		if run_now != run_stamp and run_now != FighterState.NEVER:
			result.wall_runs += 1
		result.ticks += size
		result.loops += 1
	result.record_usec = Time.get_ticks_usec() - started_usec
	recorder.close()
	result.trace.stop()
	stage.free()
	NetfoxTicks.reset()
	result.text = FileAccess.get_file_as_string(path)
	return result


# The tick the wall run on screen began, or NEVER off the wall.
static func _run_stamp(state: FighterState) -> int:
	if state.mode == FighterState.Mode.WALL_RUN:
		return state.mode_since
	return FighterState.NEVER


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


static func dashes_at(loop: int) -> bool:
	return loop > 0 and loop % PRESS_EVERY == DASH_AFTER


# The opening of the session (TASK-10.5): a scripted player, reading the state on screen before
# each loop as a player reads the game, runs to WALL_FROM, into ParedeLonga's east face with a
# jump just before it, rides the wall run for WALL_RUN_TICKS ticks and wall-jumps; it is done once
# the body lands. Each loop it samples one frame, the yaw of where it runs.
class WallPhase:
	enum Step {
		TO_START,
		INTO_WALL,
		ON_WALL,
		FLYING,
		DONE,
	}

	var _fighter: Fighter
	var _radius: float
	var _step := Step.TO_START


	func _init(played: Fighter, capsule_radius: float) -> void:
		_fighter = played
		_radius = capsule_radius


	func done() -> bool:
		return _step == Step.DONE


	func drive() -> void:
		var state := _fighter.state
		var where := _fighter.position
		var heading := Vector3.ZERO
		match _step:
			Step.TO_START:
				heading = Vector3(WALL_FROM.x - where.x, 0.0, WALL_FROM.z - where.z)
				if heading.length() < NEAR:
					_step = Step.INTO_WALL
			Step.INTO_WALL:
				heading = INTO_WALL
				var touch_x := WALL_FACE_X + _radius
				if state.on_floor and where.x <= touch_x + JUMP_BEFORE_FACE:
					_fighter.input.press_jump()
				if state.mode == FighterState.Mode.WALL_RUN:
					_step = Step.ON_WALL
			Step.ON_WALL:
				var running := state.mode == FighterState.Mode.WALL_RUN
				if running and NetworkTime.tick - state.mode_since >= WALL_RUN_TICKS:
					_fighter.input.press_jump()
					_step = Step.FLYING
				elif not running:
					_step = Step.FLYING
			Step.FLYING:
				if state.on_floor:
					_step = Step.DONE
		_run(heading)


	# Full input along a horizontal direction, the body looking where it runs; none stands, looking
	# where it looked. yaw 0 looks down -Z.
	func _run(direction: Vector3) -> void:
		if direction == Vector3.ZERO:
			_fighter.input.sample_frame(Vector2.ZERO, _fighter.state.facing_yaw)
			return
		var flat := direction.normalized()
		_fighter.input.sample_frame(Vector2(0, 1), atan2(-flat.x, -flat.z))
