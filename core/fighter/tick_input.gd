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
