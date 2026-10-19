# Plays the reference route (reference_route.gd) in the real arena and turns the path into the
# trace the reference compares (TASK-9, criterion 16; DEC-0027 §2, layer 4; F-044 §2). The test,
# test/reference/route_reference_test.gd, compares the trace with the stored one, and
# tools/record_reference.sh stores a new one; both play it through here, the same way.
#
# The run: the real Match in Sozinho, Godot's offline peer, with one fighter at spawn slot 0 and
# no camera rig. netfox's ticks run by hand, one per loop, with no forced rollback
# (test/support/netfox_ticks.gd): every tick runs once, through the same _rollback_tick, contours
# and core as in the game. The Match plays the frozen copy of the movement numbers,
# frozen_movement.tres, and never loads data/movement_v0.tres: tuning the game leaves the
# reference alone, and only a code change moves the path.
#
# The arena gets a physics world of its own, a SubViewport's: the gate runs every suite in one
# process, and a match another test forgot to free would put a second arena in the shared world,
# right where this one stands. Measured on 2026-10-18, the path came out the same after 0 to 12
# physics frames of setup and in a shared world where other bodies came and went.
#
# The trace has one line per tick: tick,x,y,z,on_floor, the position of the fighter's feet after
# the tick with 9 decimals and 1 or 0 for the floor, as in the replay probe (F-042 §2), which
# proved such a trace equal byte for byte on Windows and Linux (F-042 §5).
extends RefCounted

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const ReferenceRoute := preload("res://test/reference/reference_route.gd")
const MATCH_SCENE := preload("res://match/match.tscn")

const FROZEN_MOVEMENT_PATH := "res://test/reference/frozen_movement.tres"
const TRACE_PATH := "res://test/reference/route.trace"
## The spawn point the fighter starts at: SpawnA, at x -6, z 9, looking down -Z (arena.tscn).
const SLOT := 0


# Plays the whole route under host, which must be in the tree, and frees everything it made.
func play(host: Node) -> Result:
	NetfoxTicks.reset()
	var stage := SubViewport.new()
	stage.own_world_3d = true
	host.add_child(stage)
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	var game_match := node as Match
	game_match.movement_data = _frozen_movement()
	stage.add_child(game_match)
	var fighter := game_match.spawn_fighter(SLOT, host.multiplayer.get_unique_id())
	# netfox's synchronizer registers with call_deferred; the ticks then run inside a physics
	# frame (test/support/netfox_ticks.gd).
	await host.get_tree().process_frame
	await host.get_tree().physics_frame

	var result := Result.new()
	result.movement_path = game_match.movement_data.resource_path
	result.paths = Paths.new(game_match.config.run_speed)
	var rows := PackedStringArray()
	var started_usec := Time.get_ticks_usec()
	for step: int in ReferenceRoute.TICKS:
		var pressed := ReferenceRoute.jumps_at(step)
		# The calls of the bot and of the keyboard (fighter/bot_player.gd): one frame of input
		# before the loop, and the jump right before its tick.
		fighter.input.sample_frame(ReferenceRoute.move_at(step), ReferenceRoute.YAW)
		if pressed:
			fighter.input.press_jump()
		var before := fighter.state.copy()
		var speed_before := _horizontal_speed(fighter)
		NetfoxTicks.run_loop()
		rows.append(row(step, fighter.position, fighter.state.on_floor))
		result.paths.observe(fighter, before, speed_before, pressed)
	result.run_usec = Time.get_ticks_usec() - started_usec
	result.trace = "\n".join(rows) + "\n"

	stage.free()
	NetfoxTicks.reset()
	return result


# One line of the trace.
static func row(step: int, where: Vector3, on_floor: bool) -> String:
	return "%d,%.9f,%.9f,%.9f,%d" % [step, where.x, where.y, where.z, 1 if on_floor else 0]


static func _horizontal_speed(fighter: Fighter) -> float:
	return Vector2(fighter.velocity.x, fighter.velocity.z).length()


static func _frozen_movement() -> MovementData:
	var resource: Resource = load(FROZEN_MOVEMENT_PATH)
	assert(resource is MovementData, "%s must load as a MovementData" % FROZEN_MOVEMENT_PATH)
	return resource as MovementData


class Result:
	## The trace of the whole route, one line per tick.
	var trace: String
	## What the route went through, to prove it still covers what it claims.
	var paths: Paths
	## µs of wall clock for the ticks of the route, without the setup.
	var run_usec: int
	## The movement data the Match played.
	var movement_path: String


# What the run went through, counted on every tick: the route claims to run, stop, turn, jump,
# double-jump, land, use the platform and its ledge with a coyote jump, climb the 1 m and the 2 m
# blocks, press into a wall and never go near the ramp (reference_route.gd). A trace equal to the
# stored one proves all of it again, but a trace recorded again after a code change must still
# cover it: missing() says what it lost.
class Paths:
	## m/s: below this the body is not at full speed (floating-point slack).
	const SPEED_SLACK := 0.001
	## m: how far the feet may be from the top of a surface to stand on it, as on its edge.
	const STANDING_SLACK := 0.1
	# The tops of the arena's surfaces as x, z rectangles, and their heights (arena.tscn).
	const PLATFORM_TOP := Rect2(0, -3, 6, 6)
	const PLATFORM_HEIGHT := 1.0
	const BLOCK_1M_TOP := Rect2(-10, -14, 4, 4)
	const BLOCK_1M_HEIGHT := 1.0
	const BLOCK_2M_TOP := Rect2(-2, -14, 4, 4)
	const BLOCK_2M_HEIGHT := 2.0
	# The 45° ramp runs down from x 6 to x 7.41 across z -3..3 (arena.tscn); with the capsule's
	# 0.35 m and a margin, no body outside this x, z rectangle can touch it.
	const RAMP_ZONE := Rect2(5.5, -3.5, 2.4, 7.0)
	# The least each counter must reach for the route to cover what it claims: one of each, but
	# full speed in all eight headings, the two turnarounds at full speed of steps 785 and 885, and
	# the two coyote jumps, off the platform's ledge and off the 1 m block onto the 2 m one (F-086).
	# The double jump spends the flight's one, so the press after it waits in the slot for the
	# buffered jump (TASK-10.1). ramp_ticks must stay at 0.
	const LEAST: Dictionary[String, int] = {
		"stops": 1,
		"headings": 8,
		"turnarounds": 2,
		"floor_jumps": 1,
		"coyote_jumps": 2,
		"double_jumps": 1,
		"buffered_jumps": 1,
		"landings": 1,
		"ledge_drops": 1,
		"platform_ticks": 1,
		"block_1m_ticks": 1,
		"block_2m_ticks": 1,
		"wall_ticks": 1,
	}

	## m/s: the fastest the body moved across the floor or the air.
	var top_speed := 0.0
	## The counters of the summary, by name.
	var counts: Dictionary[String, int] = {
		"stops": 0,
		"headings": 0,
		"turnarounds": 0,
		"floor_jumps": 0,
		"coyote_jumps": 0,
		"double_jumps": 0,
		"buffered_jumps": 0,
		"landings": 0,
		"ledge_drops": 0,
		"platform_ticks": 0,
		"block_1m_ticks": 0,
		"block_2m_ticks": 0,
		"wall_ticks": 0,
		"ramp_ticks": 0,
	}

	var _run_speed: float
	# The eight-way headings run at full speed, and the velocity of the last full-speed tick.
	var _headings: Dictionary[Vector2i, bool] = { }
	var _last_full_speed := Vector2.ZERO


	func _init(run_speed: float) -> void:
		_run_speed = run_speed


	# One tick: before is the state the tick started from, and the fighter holds its result.
	func observe(
		fighter: Fighter,
		before: FighterState,
		speed_before: float,
		pressed: bool,
	) -> void:
		var after := fighter.state
		var where := fighter.position
		var velocity := Vector2(fighter.velocity.x, fighter.velocity.z)
		var speed := velocity.length()
		top_speed = maxf(top_speed, speed)
		if after.on_floor and speed == 0.0 and speed_before > 0.0:
			counts["stops"] += 1
		if speed >= _run_speed - SPEED_SLACK:
			_headings[Vector2i(roundi(velocity.x / speed), roundi(velocity.y / speed))] = true
			if velocity.dot(_last_full_speed) < 0.0:
				counts["turnarounds"] += 1
			_last_full_speed = velocity
		counts["headings"] = _headings.size()
		# The double jump stamps its tick, and only the floor clears the stamp (DEC-0031: the key
		# of its event). It raises jumps_used too, but it is no jump of the floor or the coyote.
		var stamped := after.double_jump_tick != FighterState.NEVER
		if stamped and before.double_jump_tick == FighterState.NEVER:
			counts["double_jumps"] += 1
		elif after.jumps_used > before.jumps_used:
			if not before.on_floor:
				counts["coyote_jumps"] += 1
			else:
				counts["floor_jumps"] += 1
				# A jump on the floor without a press on its tick is the buffer's.
				if not pressed:
					counts["buffered_jumps"] += 1
		if after.on_floor and not before.on_floor:
			counts["landings"] += 1
		if before.on_floor and not after.on_floor and after.jumps_used == 0:
			counts["ledge_drops"] += 1
		if after.on_floor:
			counts["platform_ticks"] += _on_top(where, PLATFORM_TOP, PLATFORM_HEIGHT)
			counts["block_1m_ticks"] += _on_top(where, BLOCK_1M_TOP, BLOCK_1M_HEIGHT)
			counts["block_2m_ticks"] += _on_top(where, BLOCK_2M_TOP, BLOCK_2M_HEIGHT)
		if fighter.is_on_wall():
			counts["wall_ticks"] += 1
		if RAMP_ZONE.has_point(Vector2(where.x, where.z)):
			counts["ramp_ticks"] += 1


	# One line, for the gate's log.
	func summary() -> String:
		var line := "top_speed=%.3f" % top_speed
		for counter: String in counts:
			line += " %s=%d" % [counter, counts[counter]]
		return line


	# What the route no longer covers; empty when it covers everything it claims.
	func missing() -> PackedStringArray:
		var gaps := PackedStringArray()
		if top_speed < _run_speed - SPEED_SLACK:
			gaps.append("it never runs at full speed: top speed %.3f m/s" % top_speed)
		for counter: String in LEAST:
			if counts[counter] < LEAST[counter]:
				gaps.append("%s is %d, below %d" % [counter, counts[counter], LEAST[counter]])
		if counts["ramp_ticks"] > 0:
			gaps.append("it went near the ramp on %d ticks" % counts["ramp_ticks"])
		return gaps


	static func _on_top(where: Vector3, top: Rect2, height: float) -> int:
		var inside := top.has_point(Vector2(where.x, where.z))
		return 1 if inside and absf(where.y - height) < STANDING_SLACK else 0
