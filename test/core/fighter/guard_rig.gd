# The CombatRig of TASK-12.1 with the frozen tick of TASK-12.2 (DEC-0055 §5; combate.md, "O hitstop
# e o tremor": "A paradinha no tick"): the same sandwich, Combat.step then Movement.before_move,
# but on a tick whose plan is frozen (MovePlan.frozen) the node skips move_and_slide() and
# Movement.after_move, so the body stays where it is and keeps the velocity it had; this rig does
# the same by hand. On every other tick the MovementRig moves the body as before. Only the public
# interface agreed in the TASK-12.2 plan is used: TickInput.guard, the held guard button, and
# MovePlan.frozen. The TASK-12.1 suites keep their CombatRig untouched; the TASK-12.2 suites use
# this one.
extends "res://test/core/fighter/combat_rig.gd"


# One tick of the sandwich with the frozen path. Combat.step runs on the state the last tick left,
# against the photo; the movement's plan is read first, and when it is frozen the state it returns
# is the end of the tick, the body does not move and after_move is not called (DEC-0055 §5).
# before_move is pure, so reading the plan here and again in MovementRig.step gives the same plan.
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
	var plan := Movement.before_move(
		rig.state,
		rig.position,
		rig.velocity,
		input,
		rig.config,
		rig.tick,
	)
	if plan.frozen:
		rig.state = plan.state
		rig.last_plan = plan
		rig.tick += 1
		last_plan = plan
		return plan
	last_plan = rig.step(input)
	return last_plan


# The body's velocity as the engine keeps it between ticks.
func velocity() -> Vector3:
	return rig.velocity


# The guard button held on this tick (TickInput.guard; DEC-0054 §1: "o botão direito do mouse,
# segurado"), on top of whatever else the input carries.
static func guarding(input: TickInput) -> TickInput:
	input.guard = true
	return input


# The guard held while pushing move and looking along yaw, nothing pressed.
static func hold_guard(move := Vector2.ZERO, yaw := 0.0) -> TickInput:
	return guarding(walk(move, yaw))


# Whether the fighter is frozen on this tick: the hitstop runs to and including frozen_until_tick
# (TASK-12.2 plan: "Frozen ticks (tick <= frozen_until_tick)").
static func frozen_at(state: FighterState, tick: int) -> bool:
	return tick <= state.frozen_until_tick


# combat_v0.tres with another hitstop for the light, in ms, as a configuration of one tickrate:
# the way to measure an exchange without the hitstop (combate.md, "O hitstop e o tremor": "a
# vantagem não muda").
static func combat_with_hitstop(hit_ms: int, block_ms: int, tickrate: int) -> CombatConfig:
	var data := load_combat_data()
	data.light_attack.hitstop_hit_ms = hit_ms
	data.light_attack.hitstop_block_ms = block_ms
	return CombatConfig.create(data, tickrate)
