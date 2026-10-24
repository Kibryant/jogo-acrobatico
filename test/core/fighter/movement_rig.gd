# The engine's slice of the tick sandwich, played by hand (visao-geral.md, "O tick por dentro: o
# sanduíche"): the core decides in Movement.before_move, this rig moves the body by
# plan.velocity / tickrate against a flat floor at y = 0 and reports the MoveFacts, and the core
# confers in Movement.after_move. No node and no physics engine (DEC-0004, rule 4): only the
# public interface of core/fighter agreed in the TASK-9, TASK-10.1 and TASK-10.4 plans (DEC-0039:
# the before_move receives the position, and the buffer is one slot; DEC-0041: the dash). A
# ledge is the floor switched off: the body then falls into the void, as off the edge of the
# arena. TASK-10.4 adds two more contacts, each a fact the engine would report: a 45° ramp that
# descends toward +X, with the floor snap that covers the fastest ground speed (movimento.md,
# "Dash": "Descendo a rampa de 45°"), and a wall at x = wall_x that stops the body and slides it
# (movimento.md, "Dash": "Contra uma parede"). TASK-10.5 adds the walls that report the wall
# facts of DEC-0042 (add_wall): a fake plane, with or without an end, that clamps a crossing
# move, slides the velocity and reports its normal and id while the body is within the probe
# distance, even when it moves parallel to it, as the test-only probe of the adapter does
# (rede.md §4, "A sonda A da parede"). The wall of wall_x stays as it was: it reports no facts.
# TASK-10.6 adds the aim (DEC-0044): the test sets what the adapter's ray would find (aim_hit and
# aim_point), and step() copies them into the MoveFacts only on a tick whose plan asked
# (MovePlan.aim_request), with the position after the move on every tick (MoveFacts.position).
extends RefCounted

const MOVEMENT_V0 := "res://data/movement_v0.tres"

# How far from a wall the adapter's test-only probe still finds it: 5 cm inward (DEC-0042,
# "Opções consideradas" 2 and "Decisão" 1; rede.md §4: "move_and_collide(-normal * 0,05,
# true)"). An engine distance, not a design number.
const WALL_PROBE_DISTANCE := 0.05


# A fake wall: the plane normal · p = offset, with the body on the side normal · p >= offset.
# The normal is a unit vector pointing away from the wall, toward the body. A face may end:
# along_min and along_max bound it on its tangent, UP × normal (along_of gives the coordinate of
# a point); INF on both sides is an endless face. The id is what the adapter would report, the
# collider's path relative to the Arena (DEC-0042 §2).
class FakeWall:
	var normal := Vector3.ZERO
	var offset := 0.0
	var id: StringName = &""
	var along_min := -INF
	var along_max := INF


	func tangent() -> Vector3:
		return Vector3.UP.cross(normal).normalized()


	# Signed distance of a point to the plane: negative is behind the wall.
	func distance(point: Vector3) -> float:
		return normal.dot(point) - offset


	func along_of(point: Vector3) -> float:
		return tangent().dot(point)


	# The face exists where this point projects: between its ends, inclusive.
	func covers(point: Vector3) -> bool:
		var along := along_of(point)
		return along >= along_min and along <= along_max


# A body heading down that would end the tick within this hair above the floor is on it: the
# stand-in for the engine's own floor snap. Far below the 1 cm tolerance of the jump height
# (movimento.md, "Pulo e ar"; visao-geral.md, "O tempo e a física no estado").
const LANDING_HAIR := 1e-6

# The ramp of the rig is the steepest floor there is: 45° (movimento.md, "O corpo": "Rampa
# máxima"), the one the dash goes down in criterion 4 of TASK-10.4.
const RAMP_DEG := 45.0

var config: MovementConfig
var state: FighterState
var position := Vector3.ZERO
var velocity := Vector3.ZERO
var floor_on := true
# The floor as a 45° ramp descending toward +X: the surface is at y = -x * tan(45°). Off, the
# floor is flat at y = 0, as before TASK-10.4.
var ramp_on := false
# A wall facing -X at this x: the body never passes it, and the engine reports a velocity.x of
# 0 after the contact (it slides). INF is no wall, as before TASK-10.4.
var wall_x := INF
# The walls of TASK-10.5, in the order they were added (add_wall). Empty, the rig is as before.
var walls: Array[FakeWall] = []
# What the adapter's ray would find on a tick the core asks for the aim (TASK-10.6; DEC-0044): a
# hit and its point, set by the test as the scenery would answer. They reach the MoveFacts only
# when the plan asked; otherwise the facts say no hit and Vector3.ZERO.
var aim_hit := false
var aim_point := Vector3.ZERO
var tick: int
var last_plan: MovePlan
var last_facts: MoveFacts


# A fighter at rest on the floor at first_tick, set field by field from the agreed interface:
# an empty slot, no jump used, a bar never spent (TASK-10.1 plan), no dash (TASK-10.4 plan), no
# grapple fired, no point and no release (TASK-10.6 plan).
func _init(movement_config: MovementConfig, first_tick: int) -> void:
	config = movement_config
	tick = first_tick
	state = FighterState.new()
	state.mode = FighterState.Mode.GROUND
	state.mode_since = first_tick
	state.on_floor = true
	state.left_floor_tick = FighterState.NEVER
	state.buffered_command = FighterCommand.NONE
	state.buffered_tick = FighterState.NEVER
	state.jumps_used = 0
	state.facing_yaw = 0.0
	state.stamina_at_spend = 0.0
	state.stamina_spent_tick = FighterState.NEVER
	state.double_jump_tick = FighterState.NEVER
	state.dash_tick = FighterState.NEVER
	state.dash_direction = Vector3.ZERO
	state.grapple_fired_tick = FighterState.NEVER
	state.grapple_point = Vector3.ZERO
	state.grapple_end_tick = FighterState.NEVER


# The numbers of movement_v0.tres as the configuration of one tickrate, the way the Match makes
# it once at load (visao-geral.md, "A configuração nasce na carga").
static func load_config(tickrate: int) -> MovementConfig:
	var resource: Resource = load(MOVEMENT_V0)
	assert(
		resource is MovementData,
		"%s must load as a MovementData (TASK-9, part 1)" % MOVEMENT_V0,
	)
	return MovementConfig.create(resource as MovementData, tickrate)


# A wall the engine would report (DEC-0042 §1): the plane normal · p = offset, the body on the
# side normal · p >= offset, with this id as the collider's path. The returned wall may be given
# ends (along_min, along_max) before the body reaches it. Contact and clamping follow the order
# of addition when two walls overlap.
func add_wall(normal: Vector3, offset: float, id: StringName) -> FakeWall:
	assert(is_equal_approx(normal.length(), 1.0), "a wall normal must be a unit vector")
	assert(not id.is_empty(), "a wall needs an id: the adapter reports the collider's path")
	var wall := FakeWall.new()
	wall.normal = normal
	wall.offset = offset
	wall.id = id
	walls.append(wall)
	return wall


# The fighter in the air by hand, as after a long fall: at this position, with this velocity,
# past the coyote window, no jump used in this flight and nothing in the slot. The wall and
# momentum tests start from it, the way the stamina tests set the bar by hand.
func airborne(at: Vector3, with_velocity: Vector3) -> void:
	position = at
	velocity = with_velocity
	state.mode = FighterState.Mode.AIR
	state.mode_since = tick - 1
	state.on_floor = false
	state.left_floor_tick = FighterState.NEVER
	state.buffered_command = FighterCommand.NONE
	state.buffered_tick = FighterState.NEVER
	state.jumps_used = 0
	state.double_jump_tick = FighterState.NEVER


static func idle() -> TickInput:
	return run(Vector2.ZERO)


# The one-tick touch of the jump (TickInput.jump), with no direction pointed.
static func press_jump() -> TickInput:
	return press_jump_toward(Vector2.ZERO)


# The one-tick touch of the jump while pointing a direction: move.x goes right and move.y
# forward, relative to yaw (TASK-9 plan).
static func press_jump_toward(move: Vector2, yaw := 0.0) -> TickInput:
	var input := run(move, yaw)
	input.jump = true
	return input


# The one-tick touch of the dash (TickInput.dash), with no direction pointed (TASK-10.4 plan).
static func press_dash() -> TickInput:
	return press_dash_toward(Vector2.ZERO)


# The one-tick touch of the dash while pointing a direction: move.x goes right and move.y
# forward, relative to yaw (TASK-9 plan).
static func press_dash_toward(move: Vector2, yaw := 0.0) -> TickInput:
	var input := run(move, yaw)
	input.dash = true
	return input


# The jump and the dash touched on the same tick: the tie of criterion 3 of TASK-10.4.
static func press_jump_and_dash(move := Vector2.ZERO, yaw := 0.0) -> TickInput:
	var input := run(move, yaw)
	input.jump = true
	input.dash = true
	return input


# The one-tick touch of the grapple (TickInput.grapple) while aiming: the camera's yaw and pitch
# of the tick, in rad, pitch positive up (TASK-10.6 plan). No direction pointed.
static func press_grapple(yaw := 0.0, pitch := 0.0) -> TickInput:
	return press_grapple_toward(Vector2.ZERO, yaw, pitch)


# The one-tick touch of the grapple while pointing a direction and aiming.
static func press_grapple_toward(move: Vector2, yaw := 0.0, pitch := 0.0) -> TickInput:
	var input := run(move, yaw, pitch)
	input.grapple = true
	return input


# Any set of one-tick touches on the same tick: the ties of criterion 5 of TASK-10.6 (jump, dash
# and grapple together, or any two of them).
static func press_together(
	jump: bool,
	dash: bool,
	grapple: bool,
	move := Vector2.ZERO,
	yaw := 0.0,
	pitch := 0.0,
) -> TickInput:
	var input := run(move, yaw, pitch)
	input.jump = jump
	input.dash = dash
	input.grapple = grapple
	return input


# move.x goes right and move.y forward, relative to yaw, length up to 1 (TASK-9 plan). The pitch
# is the camera's, in rad, positive up (TASK-10.6 plan); every one-tick touch is off.
static func run(move: Vector2, yaw := 0.0, pitch := 0.0) -> TickInput:
	var input := TickInput.new()
	input.move = move
	input.yaw = yaw
	input.pitch = pitch
	input.jump = false
	input.dash = false
	input.grapple = false
	return input


# One tick of the sandwich. Returns the core's plan, also kept in last_plan.
func step(input: TickInput) -> MovePlan:
	var plan := Movement.before_move(state, position, velocity, input, config, tick)
	var next := position + plan.velocity / float(config.tickrate)
	var facts := MoveFacts.new()
	var blocked := next.x > wall_x
	if blocked:
		next.x = wall_x
	# A move that crosses a wall ends on it, and the velocity loses its part into the wall: the
	# engine's slide (rede.md §4). With no walls, slid is the plan's velocity, as before.
	var slid := plan.velocity
	for wall: FakeWall in walls:
		var depth := wall.distance(next)
		if depth < 0.0 and wall.covers(next):
			next -= wall.normal * depth
			var into := wall.normal.dot(slid)
			if into < 0.0:
				slid -= wall.normal * into
	var floor_y := _floor_y(next.x)
	if floor_on and plan.velocity.y <= 0.0 and next.y <= floor_y + _floor_reach():
		next.y = floor_y
		facts.on_floor = true
		facts.velocity = Vector3(slid.x, 0.0, slid.z)
	else:
		facts.on_floor = false
		facts.velocity = slid
	if blocked:
		facts.velocity.x = 0.0
	var contact := _wall_in_contact(next, plan.state)
	if contact != null:
		facts.wall_normal = contact.normal
		facts.wall_id = contact.id
	# The feet after the move, on every tick, and the aim only on a tick whose plan asked for it:
	# the adapter casts the ray from the shoulder after move_and_slide() (TASK-10.6 plan; DEC-0044).
	facts.position = next
	if plan.aim_request:
		facts.aim_hit = aim_hit
		facts.aim_point = aim_point
	else:
		facts.aim_hit = false
		facts.aim_point = Vector3.ZERO
	position = next
	velocity = facts.velocity
	state = Movement.after_move(plan.state, facts, config, tick)
	last_plan = plan
	last_facts = facts
	tick += 1
	return plan


# The wall the adapter would report for a body ending the tick at this point (DEC-0042 §1;
# rede.md §4): a face the point is in front of, within the probe distance, and between its ends.
# During a wall run the adapter probes toward the wall of the state, so the wall most aligned
# with that normal wins; otherwise the first wall added. Null is no contact.
func _wall_in_contact(point: Vector3, prior: FighterState) -> FakeWall:
	var found: FakeWall = null
	var best_alignment := -INF
	for wall: FakeWall in walls:
		var depth := wall.distance(point)
		if depth < -LANDING_HAIR or depth > WALL_PROBE_DISTANCE + LANDING_HAIR:
			continue
		if not wall.covers(point):
			continue
		if prior.mode == FighterState.Mode.WALL_RUN:
			var alignment := wall.normal.dot(prior.wall_normal)
			if alignment > best_alignment:
				best_alignment = alignment
				found = wall
		elif found == null:
			found = wall
	return found


# The height of the floor under x: 0 on the flat floor, -x * tan(45°) on the ramp.
func _floor_y(x: float) -> float:
	if ramp_on:
		return -x * tan(deg_to_rad(RAMP_DEG))
	return 0.0


# How far above the floor a body heading down still counts as on it. On the flat floor, the
# hair of before. On the ramp, the engine's floor snap sized for the fastest ground speed: one
# tick of it down a 45° slope, speed / tickrate * tan(45°), plus the hair as the engine's margin
# (movimento.md, "Dash": "O snap do chão cobre a maior velocidade no chão: 0,338 m a 60 ticks
# (20 m/s ÷ 60 × tan 45°, mais as margens do motor)"). The scene test of criterion 4 of TASK-10.4
# proves the real snap; here it is a fact the engine would report.
func _floor_reach() -> float:
	if not ramp_on:
		return LANDING_HAIR
	var fastest := maxf(config.run_speed, config.dash_speed)
	return fastest / float(config.tickrate) * tan(deg_to_rad(RAMP_DEG)) + LANDING_HAIR


func rest(ticks: int) -> void:
	for _tick: int in ticks:
		step(idle())


func horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func horizontal_velocity() -> Vector3:
	return Vector3(velocity.x, 0.0, velocity.z)


# The bar as the next tick to simulate reads it (movimento.md, "Stamina": the bar is computed
# from the tick, never counted).
func stamina() -> float:
	return Stamina.at(state, config, tick)
