# The engine's slice of the tick sandwich, played by hand (visao-geral.md, "O tick por dentro: o
# sanduíche"): the core decides in Movement.before_move, this rig moves the body by
# plan.velocity / tickrate against a flat floor at y = 0 and reports the MoveFacts, and the core
# confers in Movement.after_move. No node and no physics engine (DEC-0004, rule 4): only the
# public interface of core/fighter agreed in the TASK-9 and TASK-10.1 plans (DEC-0039: the
# before_move receives the position, and the buffer is one slot). A ledge is the floor switched
# off: the body then falls into the void, as off the edge of the arena.
extends RefCounted

const MOVEMENT_V0 := "res://data/movement_v0.tres"

# A body heading down that would end the tick within this hair above the floor is on it: the
# stand-in for the engine's own floor snap. Far below the 1 cm tolerance of the jump height
# (movimento.md, "Pulo e ar"; visao-geral.md, "O tempo e a física no estado").
const LANDING_HAIR := 1e-6

var config: MovementConfig
var state: FighterState
var position := Vector3.ZERO
var velocity := Vector3.ZERO
var floor_on := true
var tick: int
var last_plan: MovePlan
var last_facts: MoveFacts


# A fighter at rest on the floor at first_tick, set field by field from the agreed interface:
# an empty slot, no jump used, a bar never spent (TASK-10.1 plan).
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


# move.x goes right and move.y forward, relative to yaw, length up to 1 (TASK-9 plan).
static func run(move: Vector2, yaw := 0.0) -> TickInput:
	var input := TickInput.new()
	input.move = move
	input.yaw = yaw
	input.jump = false
	return input


# One tick of the sandwich. Returns the core's plan, also kept in last_plan.
func step(input: TickInput) -> MovePlan:
	var plan := Movement.before_move(state, position, velocity, input, config, tick)
	var next := position + plan.velocity / float(config.tickrate)
	var facts := MoveFacts.new()
	if floor_on and plan.velocity.y <= 0.0 and next.y <= LANDING_HAIR:
		next.y = 0.0
		facts.on_floor = true
		facts.velocity = Vector3(plan.velocity.x, 0.0, plan.velocity.z)
	else:
		facts.on_floor = false
		facts.velocity = plan.velocity
	position = next
	velocity = facts.velocity
	state = Movement.after_move(plan.state, facts, config, tick)
	last_plan = plan
	last_facts = facts
	tick += 1
	return plan


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
