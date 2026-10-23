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
# (movimento.md, "Dash": "Contra uma parede").
extends RefCounted

const MOVEMENT_V0 := "res://data/movement_v0.tres"

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
var tick: int
var last_plan: MovePlan
var last_facts: MoveFacts


# A fighter at rest on the floor at first_tick, set field by field from the agreed interface:
# an empty slot, no jump used, a bar never spent (TASK-10.1 plan), no dash (TASK-10.4 plan).
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


# The numbers of movement_v0.tres as the configuration of one tickrate, the way the Match makes
# it once at load (visao-geral.md, "A configuração nasce na carga").
static func load_config(tickrate: int) -> MovementConfig:
	var resource: Resource = load(MOVEMENT_V0)
	assert(
		resource is MovementData,
		"%s must load as a MovementData (TASK-9, part 1)" % MOVEMENT_V0,
	)
	return MovementConfig.create(resource as MovementData, tickrate)


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


# move.x goes right and move.y forward, relative to yaw, length up to 1 (TASK-9 plan).
static func run(move: Vector2, yaw := 0.0) -> TickInput:
	var input := TickInput.new()
	input.move = move
	input.yaw = yaw
	input.jump = false
	input.dash = false
	return input


# One tick of the sandwich. Returns the core's plan, also kept in last_plan.
func step(input: TickInput) -> MovePlan:
	var plan := Movement.before_move(state, position, velocity, input, config, tick)
	var next := position + plan.velocity / float(config.tickrate)
	var facts := MoveFacts.new()
	var blocked := next.x > wall_x
	if blocked:
		next.x = wall_x
	var floor_y := _floor_y(next.x)
	if floor_on and plan.velocity.y <= 0.0 and next.y <= floor_y + _floor_reach():
		next.y = floor_y
		facts.on_floor = true
		facts.velocity = Vector3(plan.velocity.x, 0.0, plan.velocity.z)
	else:
		facts.on_floor = false
		facts.velocity = plan.velocity
	if blocked:
		facts.velocity.x = 0.0
	position = next
	velocity = facts.velocity
	state = Movement.after_move(plan.state, facts, config, tick)
	last_plan = plan
	last_facts = facts
	tick += 1
	return plan


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
