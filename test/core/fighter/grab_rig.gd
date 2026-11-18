# The ChargedRig of TASK-12.3 with the names of TASK-12.4 (DEC-0058 §1; combate.md, "A quebra, o
# tech e a esquiva no tick": "Os nomes no código"): the one-tick touch of the guard break
# (TickInput.guard_break), the command (FighterCommand.GUARD_BREAK), the two new actions
# (FighterState.Action.GRABBING and GRABBED) and the two new stamps of whoever was grabbed
# (FighterState.grabbed_tick and tech_tick). The sandwich is the GuardRig's, frozen path included.
# The new names are read by reflection, by the names the design fixes, so a suite of TASK-12.4
# loads before the rules exist and fails on what is missing, one assertion at a time, instead of
# failing to parse as a whole. Beside the names, this file reads a Duel: the ticks a fighter was
# frozen, the ticks it held an action and the first tick it was free, each as a list of violations
# a suite asserts empty.
extends "res://test/core/fighter/charged_rig.gd"

const Duel := preload("res://test/core/fighter/duel.gd")

## The move's ID and the command's (combate.md, "Os nomes no código").
const GUARD_BREAK := &"guard_break"
## The guard button going down: not a command of the slot, a touch a script may carry.
const GUARD_PRESS := &"guard_press"
## The touch and the stamps, by the names the design fixes.
const TOUCH := &"guard_break"
const GRABBED_TICK := &"grabbed_tick"
const TECH_TICK := &"tech_tick"
## The actions, by the names the design fixes.
const GRABBING := "GRABBING"
const GRABBED := "GRABBED"
## What a stamp or an action that does not exist yet reads as: no tick and no action of the game.
const NO_SUCH_FIELD := -424242
const NO_SUCH_ACTION := -424242
## How many violations a failure message lists.
const SHOWN_VIOLATIONS := 6


# The one-tick touch of the guard break, while pointing a direction and looking along yaw.
static func press_guard_break(move := Vector2.ZERO, yaw := 0.0) -> TickInput:
	return touching(walk(move, yaw), GUARD_BREAK)


# One more one-tick touch on an input, by its command; GUARD_PRESS is the guard button going down.
static func touching(input: TickInput, command: StringName) -> TickInput:
	match command:
		FighterCommand.JUMP:
			input.jump = true
		FighterCommand.DASH:
			input.dash = true
		FighterCommand.GRAPPLE:
			input.grapple = true
		FighterCommand.LIGHT_ATTACK:
			input.light_attack = true
		FighterCommand.CHARGED_ATTACK:
			input.charged_attack = true
		FighterCommand.PARRY:
			input.parry = true
		GUARD_PRESS:
			input.guard_press = true
			input.guard = true
		GUARD_BREAK:
			input.set(TOUCH, true)
		_:
			assert(false, "unknown touch %s" % command)
	return input


# Whether the input carries the guard break's touch; false while the touch does not exist.
static func touches_guard_break(input: TickInput) -> bool:
	var value: Variant = input.get(TOUCH)
	if value is bool:
		var touched: bool = value
		return touched
	return false


# Whether TickInput has the touch at all.
static func has_touch() -> bool:
	return TickInput.new().get(TOUCH) is bool


# FighterCommand.GUARD_BREAK, or an empty name while it does not exist.
static func command() -> StringName:
	var script: Script = FighterCommand
	var constants := script.get_script_constant_map()
	var value: Variant = constants.get("GUARD_BREAK")
	if value is StringName:
		var name: StringName = value
		return name
	return &""


# The contact of the last grab this fighter took, FighterState.grabbed_tick.
static func grabbed_tick(state: FighterState) -> int:
	return _stamp(state, GRABBED_TICK)


# The tick of this fighter's last tech, FighterState.tech_tick.
static func tech_tick(state: FighterState) -> int:
	return _stamp(state, TECH_TICK)


# FighterState.Action.GRABBING: whoever grabbed, held.
static func grabbing() -> int:
	return _action(GRABBING)


# FighterState.Action.GRABBED: whoever was grabbed, held and then unable to act.
static func grabbed() -> int:
	return _action(GRABBED)


static func is_grabbing(state: FighterState) -> bool:
	return state.action == grabbing()


static func is_grabbed(state: FighterState) -> bool:
	return state.action == grabbed()


# The action's name, for a message.
static func action_name(action: int) -> String:
	var actions: Dictionary = FighterState.Action
	var key: Variant = actions.find_key(action)
	if key is String:
		var name: String = key
		return name
	return "action %d" % action


# One fighter's combat state as a line, for a message.
static func line(state: FighterState) -> String:
	return (
		"%s since %d with %s, grabbed %d, tech %d, frozen_until %d, hurt %d, health %d"
		% [
			action_name(state.action),
			state.action_since,
			state.action_move,
			grabbed_tick(state),
			tech_tick(state),
			state.frozen_until_tick,
			state.hurt_tick,
			state.health,
		]
	)


# The ticks of the run on which the fighter was frozen and should not be, or the other way round:
# frozen on every tick from `from` to `to`, inclusive, and on no other tick up to `last`, by the
# rig's own predicate and by the plan (DEC-0055 §5).
static func frozen_violations(
	duel: Duel,
	index: int,
	from: int,
	to: int,
	last: int,
) -> Array[String]:
	var violations: Array[String] = []
	for row: Duel.Row in duel.rows:
		if row.tick > last:
			break
		var frozen := row.tick >= from and row.tick <= to
		if row.plans[index].frozen != frozen:
			violations.append(
				"tick %d: fighter %d plan.frozen %s" % [row.tick, index, row.plans[index].frozen]
			)
		if frozen_at(row.ends[index], row.tick) != frozen:
			violations.append(
				"tick %d: fighter %d frozen_until %d"
				% [row.tick, index, row.ends[index].frozen_until_tick]
			)
	return violations


# The ticks from `from` to `to`, inclusive, whose combat output for the fighter is not in `action`.
static func action_violations(
	duel: Duel,
	index: int,
	from: int,
	to: int,
	action: int,
) -> Array[String]:
	var violations: Array[String] = []
	for tick: int in range(from, to + 1):
		var row := duel.row_at(tick)
		if row == null:
			violations.append("tick %d was not run" % tick)
			continue
		if row.fought[index].action != action:
			violations.append(
				"tick %d: fighter %d %s, expected %s"
				% [tick, index, line(row.fought[index]), action_name(action)]
			)
	return violations


# The ticks of the whole run whose combat output for the fighter is in `action`.
static func ticks_in(duel: Duel, index: int, action: int) -> Array[int]:
	var ticks: Array[int] = []
	for row: Duel.Row in duel.rows:
		if row.fought[index].action == action:
			ticks.append(row.tick)
	return ticks


# The first tick from `from` on whose combat output for the fighter has no action: it acts again.
static func free_tick(duel: Duel, index: int, from: int) -> int:
	return duel.first_tick(
		index,
		from,
		func(state: FighterState) -> bool:
			return state.action == FighterState.Action.NONE,
	)


# A list of violations as a failure message: the first few, and how many more there are.
static func brief(violations: Array[String]) -> String:
	if violations.size() <= SHOWN_VIOLATIONS:
		return "\n".join(violations)
	var shown := violations.slice(0, SHOWN_VIOLATIONS)
	return "%s\n... and %d more" % ["\n".join(shown), violations.size() - SHOWN_VIOLATIONS]


# The camera's yaw that sends a move along `direction` (combate.md, "A espada na mira" and "A
# quebra, o tech e a esquiva no tick": "A direção e o corpo"): the move turns
# asin(shoulder / convergence) to the right of the camera, so the camera looks that far to the
# left of it. The convergence is the move's: 2,0 m for the sword, 1,2 m for the guard break.
static func camera_for(direction: float, shoulder: float, convergence: float) -> float:
	return direction + asin(shoulder / convergence)


static func _stamp(state: FighterState, field: StringName) -> int:
	var value: Variant = state.get(field)
	if value is int:
		var tick: int = value
		return tick
	return NO_SUCH_FIELD


static func _action(name: String) -> int:
	var actions: Dictionary = FighterState.Action
	var value: Variant = actions.get(name, NO_SUCH_ACTION)
	if value is int:
		var action: int = value
		return action
	return NO_SUCH_ACTION
