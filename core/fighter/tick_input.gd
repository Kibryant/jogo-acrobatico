# What the owner of a fighter wants in one tick, the input box (visao-geral.md, "O estado em
# quatro caixas"). A player and a bot fill the same fields: the rules never know who presses
# (DEC-0004).
class_name TickInput
extends RefCounted

# x to the right, y forward, relative to yaw; length up to 1 (the rules clamp a longer one).
var move := Vector2.ZERO
# Where the camera looks, in rad; 0 looks down -Z.
var yaw := 0.0
# How far up the camera looks, in rad: positive up, 0 level, and never beyond the camera's 80°
# (movimento.md, "Câmera"). The grapple aims along yaw and pitch (Aim.direction; DEC-0044).
var pitch := 0.0
# A one-tick touch: true only on the tick of the press (DEC-0026 §1).
var jump := false
# A one-tick touch too, like the jump (TASK-10.4).
var dash := false
# A one-tick touch too: the grapple (TASK-10.6).
var grapple := false
# A one-tick touch too: the light attack (combate.md, "O leve no tick"; TASK-12.1).
var light_attack := false
# Held, not touched: true on every tick the guard button is down (combate.md, "O bloqueio, a guarda
# andando e a stamina"; DEC-0054 §1; TASK-12.2).
var guard := false
# One-tick touches too (combate.md, "O carregado, o parry e a finta no tick": "Os nomes no código";
# TASK-12.3): the charged attack and the parry.
var charged_attack := false
var parry := false
# A one-tick touch beside the held guard: true only on the tick the guard button goes down. In the
# charged's windup it is the feint (combate.md, "A finta"; DEC-0056 §5).
var guard_press := false
