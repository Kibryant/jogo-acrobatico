# The route of the reference (TASK-9, criterion 16; DEC-0027 §2, layer 4): a fixed bot route of
# 1,200 ticks for one fighter, from spawn slot 0 of the arena (arena.tscn, SpawnA at x -6, z 9),
# only for this test. Like a replay (DEC-0027 §5) it holds what the bot presses on each tick and
# nothing of what happens: the path is the output the reference compares.
# The yaw stays 0 on every tick and the route never goes near the 45° ramp: sine and cosine may
# differ in the last bit between the Windows and the Linux C libraries, and the replay probe proved
# the two equal only on a path without them (F-042 §5, the limits; TASK-9 plan, round D1). With
# yaw 0, Basis(UP, yaw) takes the sine and cosine of 0, exact on both, so the route moves in the
# eight directions of the keyboard. The SyncTest keeps covering the ramp
# (test/fighter/fighter_sync_test.gd).
# The presses were placed by playing the route: a change in the movement can move a takeoff, and
# then a press may miss its window. The reference then fails twice, on the trace and on the paths
# the run must cover (reference_run.gd); fix the press here and record again.
extends RefCounted

const TICKS := 1200
const YAW := 0.0

# yaw 0 looks down -Z, so forward is -Z and right is +X (Movement._horizontal). A diagonal is two
# keys, as on the keyboard; the input box limits it to length 1.
const STAND := Vector2.ZERO
const FORWARD := Vector2(0, 1)
const BACK := Vector2(0, -1)
const RIGHT := Vector2(1, 0)
const LEFT := Vector2(-1, 0)
const FORWARD_LEFT := Vector2(-1, 1)
const FORWARD_RIGHT := Vector2(1, 1)
const BACK_LEFT := Vector2(-1, -1)
const BACK_RIGHT := Vector2(1, -1)

# From each step on, the move held until the next entry. The comments say what the body does, as
# recorded on 2026-10-18 with the frozen numbers (frozen_movement.tres).
const MOVES: Dictionary[int, Vector2] = {
	0: STAND, # rests at the spawn point
	20: FORWARD, # runs to 7 m/s
	92: STAND, # stops in 6 ticks and rests
	110: RIGHT, # runs toward the platform's west face; jumps onto it at 146 and lands at 173
	188: STAND, # stops on the platform
	205: LEFT, # runs off the west ledge: leaves the floor at 236, the coyote jump at 239
	270: FORWARD_LEFT, # lands on the floor at 282, running diagonally
	300: FORWARD, # toward the 1 m block; jumps at 360 and lands on it at 387
	390: STAND, # stops on the 1 m block
	405: RIGHT, # off its east edge at 421: the staircase jump at 425 lands on the 2 m block at 452
	466: STAND, # stops on the 2 m block; hops at 480, presses again in the air at 513, and the
	# buffer jumps at 519, on the first tick back on the block
	560: BACK, # runs off the 2 m block at 579, without a jump, and lands on the floor at 600
	600: BACK_LEFT,
	640: BACK, # west of the platform, to z 5.4
	715: RIGHT,
	785: LEFT, # turns around at full speed; jumps at 835 while running
	850: FORWARD_LEFT, # turns in the air, with air control; lands at 873
	885: BACK_RIGHT, # turns around again
	945: BACK,
	975: FORWARD_RIGHT,
	1030: STAND, # stops
	1045: FORWARD, # runs into the platform's +Z face and pushes against it
	1095: FORWARD_LEFT, # slides along the face, away from the ramp, and past its corner
	1160: STAND, # stops and rests to the end
}

# The steps that press jump, one tick each.
const JUMPS: Array[int] = [146, 239, 360, 425, 480, 513, 835]


# Where the bot pushes on step (x right, y forward): the move of the last entry at or before it.
static func move_at(step: int) -> Vector2:
	var move := STAND
	for first: int in MOVES:
		if first <= step:
			move = MOVES[first]
	return move


static func jumps_at(step: int) -> bool:
	return JUMPS.has(step)
