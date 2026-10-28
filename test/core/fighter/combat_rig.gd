# One named fighter through the whole tick sandwich of TASK-12.1 (visao-geral.md, "O tick por
# dentro: o sanduíche"; DEC-0051 §2): the core fights in Combat.step, then decides in
# Movement.before_move, the MovementRig moves the body by hand and the core confers in
# Movement.after_move. No node and no physics engine (DEC-0004, rule 4): only the public interface
# of core/fighter agreed in the TASK-12.1 plan. The fighter reads the others only in the TickPhoto
# the test builds (DEC-0051 §1); with no photo given, a step sees a photo with this fighter alone,
# as a match of one would take it.
extends RefCounted

const MovementRig := preload("res://test/core/fighter/movement_rig.gd")

const COMBAT_V0 := "res://data/combat_v0.tres"

## The name the photo knows this fighter by: the node's name in a match, unique (DEC-0051 §1).
var fighter_name: StringName
var combat: CombatConfig
var rig: MovementRig
## What Combat.step returned on the last tick, before the movement's slice: the phase of that
## tick, its contact and its health.
var fought: FighterState
## What Movement.before_move planned on the last tick.
var last_plan: MovePlan


# A fighter standing on the floor at feet, looking along yaw, with a full bar and full health
# (partida.md, "A vida sem partida": pure tests set the health themselves, TASK-12.1 plan).
func _init(
	name: StringName,
	movement_config: MovementConfig,
	combat_config: CombatConfig,
	first_tick: int,
	feet := Vector3.ZERO,
	yaw := 0.0,
) -> void:
	fighter_name = name
	combat = combat_config
	rig = MovementRig.new(movement_config, first_tick)
	rig.position = feet
	rig.state.facing_yaw = yaw
	rig.state.health = combat.max_health


# The numbers of combat_v0.tres as the configuration of one tickrate, the way the Match makes it
# once at load (visao-geral.md, "A configuração nasce na carga"; DEC-0051 §6).
static func load_combat(tickrate: int) -> CombatConfig:
	return CombatConfig.create(load_combat_data(), tickrate)


# A copy of combat_v0.tres: load() caches the resource, so a test that changes a number changes a
# duplicate and the baseline stays intact for every other test of the run.
static func load_combat_data() -> CombatData:
	var resource: Resource = load(COMBAT_V0)
	assert(resource is CombatData, "%s must load as a CombatData (TASK-12.1 plan)" % COMBAT_V0)
	var copy: Resource = resource.duplicate(true)
	assert(copy is CombatData, "a duplicate of %s must still be a CombatData" % COMBAT_V0)
	return copy as CombatData


func state() -> FighterState:
	return rig.state


func config() -> MovementConfig:
	return rig.config


# The next tick to simulate.
func tick() -> int:
	return rig.tick


func feet() -> Vector3:
	return rig.position


# This fighter as the photo of the next tick shows it: its name, its feet and a copy of its state
# as the last tick left them (DEC-0051 §1).
func snapshot(photo: TickPhoto) -> void:
	photo.add(fighter_name, rig.position, rig.state)


# One tick of the sandwich: Combat.step on the state as the last tick left it, against the photo,
# then the movement's slices on the state it returned. Returns the movement's plan.
func step(input: TickInput, photo: TickPhoto = null) -> MovePlan:
	var seen := photo
	if seen == null:
		seen = TickPhoto.new()
		snapshot(seen)
	fought = Combat.step(
		rig.state,
		fighter_name,
		rig.position,
		seen,
		input,
		combat,
		rig.config,
		rig.tick,
	)
	rig.state = fought
	last_plan = rig.step(input)
	return last_plan


func rest(ticks: int, yaw := 0.0) -> void:
	for _tick: int in ticks:
		step(idle(yaw))


# The bar as the next tick to simulate reads it (movimento.md, "Stamina").
func stamina() -> float:
	return Stamina.at(rig.state, rig.config, rig.tick)


func horizontal_speed() -> float:
	return rig.horizontal_speed()


# No push and no press, the camera at yaw.
static func idle(yaw := 0.0) -> TickInput:
	return MovementRig.run(Vector2.ZERO, yaw)


# A push without a press: move.x goes right and move.y forward, relative to yaw.
static func walk(move: Vector2, yaw := 0.0) -> TickInput:
	return MovementRig.run(move, yaw)


# The one-tick touch of the light attack (TickInput.light_attack), like the jump's, while
# pointing a direction and looking along yaw (TASK-12.1 plan).
static func press_light(move := Vector2.ZERO, yaw := 0.0) -> TickInput:
	var input := MovementRig.run(move, yaw)
	input.light_attack = true
	return input


# The light attack touched on the same tick as any set of movement commands: the ties of
# criterion 3 of TASK-12.1 (combate.md, "O leve no tick": "A vaga dividida").
static func press_light_with(
	jump: bool,
	dash: bool,
	grapple: bool,
	move := Vector2.ZERO,
	yaw := 0.0,
) -> TickInput:
	var input := MovementRig.press_together(jump, dash, grapple, move, yaw)
	input.light_attack = true
	return input
