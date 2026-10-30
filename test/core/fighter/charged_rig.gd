# The GuardRig of TASK-12.2 with the touches of TASK-12.3 (DEC-0056 §1; combate.md, "O carregado,
# o parry e a finta no tick": "Os nomes no código"): the one-tick touches of the charged attack
# (TickInput.charged_attack), of the parry (TickInput.parry) and of the guard button going down
# (TickInput.guard_press, true only on that tick, beside the held TickInput.guard). The sandwich is
# the GuardRig's, frozen path included; this file only builds inputs, so the TASK-12.1 and
# TASK-12.2 suites keep their rigs untouched. Only the public interface agreed in the TASK-12.3
# plan is used.
extends "res://test/core/fighter/guard_rig.gd"


# The one-tick touch of the charged attack, while pointing a direction and looking along yaw.
static func press_charged(move := Vector2.ZERO, yaw := 0.0) -> TickInput:
	var input := walk(move, yaw)
	input.charged_attack = true
	return input


# The one-tick touch of the parry, while pointing a direction and looking along yaw.
static func press_parry(move := Vector2.ZERO, yaw := 0.0) -> TickInput:
	var input := walk(move, yaw)
	input.parry = true
	return input


# The guard button going down on this tick: the touch guard_press and the held guard, both true,
# on top of whatever else the input carries (combate.md, "A finta": "Só o aperto conta").
static func guard_going_down(input: TickInput) -> TickInput:
	input.guard_press = true
	input.guard = true
	return input


# The guard button going down while pointing a direction and looking along yaw, nothing else
# pressed: the feint when it lands in the charged's windup, the guard rising anywhere else.
static func press_guard(move := Vector2.ZERO, yaw := 0.0) -> TickInput:
	return guard_going_down(walk(move, yaw))


# Any set of one-tick touches on the same tick, the combat's and the movement's: the ties of the
# slot (combate.md, "O carregado, o parry e a finta no tick": "A vaga"; DEC-0056 §6).
static func press_many(
	charged: bool,
	parry: bool,
	light: bool,
	jump := false,
	dash := false,
	grapple := false,
	move := Vector2.ZERO,
	yaw := 0.0,
) -> TickInput:
	var input := MovementRig.press_together(jump, dash, grapple, move, yaw)
	input.charged_attack = charged
	input.parry = parry
	input.light_attack = light
	return input
