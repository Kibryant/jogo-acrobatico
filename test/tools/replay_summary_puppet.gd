# One fighter's movement written by hand on a tape for the summary of TASK-14, for what the fake
# floor of the rigs cannot reach at will: exact heights, walls, seams, the grapple and another
# fighter's head. Every method is one tick and writes the fields Movement writes on that event
# (core/fighter/movement.gd: before_move, after_move, _wall_run, _enter_wall, _read_wall, _fire,
# _onto_head), with the press that fires it in the tick's input, so the slot ends the tick empty
# as in a match. The fighter starts as the spawn leaves it: a new FighterState, on the floor,
# with the health at the combat's max. The feet and the velocity are the test's: set position and
# velocity before the tick they belong to; they are what the tick ended with.
extends RefCounted

const Tape := preload("res://test/tools/replay_summary_tape.gd")

var tape: Tape
var index: int
## The next tick to write; the first is 0.
var tick := 0
var state := FighterState.new()
var position := Vector3.ZERO
var velocity := Vector3.ZERO


func _init(the_tape: Tape, fighter: int, feet := Vector3.ZERO) -> void:
	tape = the_tape
	index = fighter
	position = feet
	state.health = tape.combat.max_health


# Ticks in which nothing happens: the state stays as it is.
func rest(ticks := 1) -> void:
	for _tick: int in ticks:
		_write(TickInput.new())


# One tick with nothing happening, ending with the feet at `feet`.
func rest_at(feet: Vector3) -> void:
	position = feet
	rest()


# The jump from the floor: it fires on the press tick, and the engine sees the body off the floor
# on that same tick.
func jump() -> void:
	assert(Movement.stands(state), "the jump of the floor starts standing")
	state.jumps_used = 1
	_leave_floor()
	_write(_pressing(FighterCommand.JUMP))


# The body walks off a ledge: in the air by contact, with the coyote's stamp.
func walk_off() -> void:
	assert(Movement.stands(state), "walking off starts standing")
	_leave_floor()
	_write(TickInput.new())


# The full jump within the coyote window after a ledge.
func coyote_jump() -> void:
	assert(state.mode == FighterState.Mode.AIR and state.jumps_used == 0)
	assert(tick - state.left_floor_tick <= tape.movement.coyote_ticks, "the coyote has closed")
	state.jumps_used = 1
	_write(_pressing(FighterCommand.JUMP))


# The double jump: after the jump, or past the coyote without one.
func double_jump() -> void:
	assert(not Movement.stands(state), "the double jump fires off the floor")
	state.jumps_used = 2
	state.double_jump_tick = tick
	Stamina.spend(state, tape.movement, tick, tape.movement.double_jump_cost)
	_write(_pressing(FighterCommand.JUMP))


# The landing on the floor: it renews the jumps and clears the last wall and the head.
func land() -> void:
	state.jumps_used = 0
	state.double_jump_tick = FighterState.NEVER
	state.wall_normal = Vector3.ZERO
	state.wall_id = &""
	state.slide_off_dir = Vector3.ZERO
	state.head_landing_tick = FighterState.NEVER
	state.on_floor = true
	if state.mode == FighterState.Mode.AIR or state.mode == FighterState.Mode.WALL_RUN:
		state.mode = FighterState.Mode.GROUND
		state.mode_since = tick
	_write(TickInput.new())


# The contact that starts a wall run, from the air. Back on the wall the state still holds, the
# run renews nothing and needs a flight that began with a wall jump; another wall renews the
# jumps.
func enter_wall(id: StringName, normal := Vector3.RIGHT) -> void:
	assert(state.mode == FighterState.Mode.AIR, "a wall run starts from the air")
	var same := id == state.wall_id
	assert(not same or state.mode_since == state.wall_jump_tick, "the same wall refuses")
	state.mode = FighterState.Mode.WALL_RUN
	state.mode_since = tick
	if not same:
		state.jumps_used = 0
		state.double_jump_tick = FighterState.NEVER
	state.left_floor_tick = FighterState.NEVER
	state.wall_id = id
	state.wall_normal = normal
	_write(TickInput.new())


# A seam: the run passes to the next block of the same plane, and only the id changes (F-129).
func seam(id: StringName) -> void:
	assert(state.mode == FighterState.Mode.WALL_RUN, "a seam is inside a run")
	state.wall_id = id
	_write(TickInput.new())


# The wall jump: out of the run, in the air from this tick.
func wall_jump() -> void:
	assert(state.mode == FighterState.Mode.WALL_RUN, "the wall jump leaves a run")
	state.jumps_used = maxi(state.jumps_used, 1)
	state.wall_jump_tick = tick
	state.mode = FighterState.Mode.AIR
	state.mode_since = tick
	_write(_pressing(FighterCommand.JUMP))


# The run ends by its time or by the contact lost: in the air, with no wall jump.
func leave_wall() -> void:
	assert(state.mode == FighterState.Mode.WALL_RUN, "only a run ends")
	state.mode = FighterState.Mode.AIR
	state.mode_since = tick
	_write(TickInput.new())


# The dash, from the floor.
func dash(direction := Vector3.FORWARD) -> void:
	assert(state.mode == FighterState.Mode.GROUND and Movement.stands(state))
	state.mode = FighterState.Mode.DASH
	state.mode_since = tick
	state.dash_tick = tick
	state.dash_direction = direction
	Stamina.spend(state, tape.movement, tick, tape.movement.dash_cost)
	_write(_pressing(FighterCommand.DASH))


# The dash's own end, on the floor it ran on.
func end_dash() -> void:
	assert(state.mode == FighterState.Mode.DASH, "only a dash ends")
	state.mode = FighterState.Mode.GROUND if Movement.stands(state) else FighterState.Mode.AIR
	state.mode_since = tick
	_write(TickInput.new())


# The grapple's hook bites on the press tick: the cable flies from it.
func fire_grapple(point: Vector3) -> void:
	assert(state.grapple_fired_tick == FighterState.NEVER, "one cable at a time")
	state.grapple_fired_tick = tick
	state.grapple_point = point
	_write(_pressing(FighterCommand.GRAPPLE))


# The first tick of the pull: the cable has flown, the mode is the grapple's and the body leaves
# the floor with no coyote's stamp.
func start_pull() -> void:
	assert(state.grapple_fired_tick != FighterState.NEVER, "the pull needs a cable")
	state.mode = FighterState.Mode.GRAPPLE
	state.mode_since = tick
	state.on_floor = false
	_write(TickInput.new())


# The release of the pull, in the air: no cable any more, the end stamped for the cooldown.
func release_grapple() -> void:
	assert(state.mode == FighterState.Mode.GRAPPLE, "only a pull releases")
	state.grapple_end_tick = tick
	state.grapple_fired_tick = FighterState.NEVER
	state.mode = FighterState.Mode.AIR
	state.mode_since = tick
	_write(TickInput.new())


# The feet come down on another fighter's head: the engine says floor, the rules say air, and the
# landing is stamped once.
func land_on_head(away := Vector3.RIGHT) -> void:
	assert(state.mode == FighterState.Mode.AIR and not state.on_floor)
	state.on_floor = true
	state.slide_off_dir = away
	state.head_landing_tick = tick
	_write(TickInput.new())


# The body slides past the head's edge: off it, in the air as before.
func slide_off_head() -> void:
	assert(state.slide_off_dir != Vector3.ZERO, "only a body on a head slides off it")
	state.on_floor = false
	state.slide_off_dir = Vector3.ZERO
	state.head_landing_tick = FighterState.NEVER
	_write(TickInput.new())


func _leave_floor() -> void:
	state.mode = FighterState.Mode.AIR
	state.mode_since = tick
	state.on_floor = false
	state.left_floor_tick = tick


static func _pressing(command: StringName) -> TickInput:
	var input := TickInput.new()
	input.jump = command == FighterCommand.JUMP
	input.dash = command == FighterCommand.DASH
	input.grapple = command == FighterCommand.GRAPPLE
	return input


func _write(input: TickInput) -> void:
	tape.record(tick, index, input, state, position, velocity)
	tick += 1
