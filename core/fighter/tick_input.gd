# What the owner of a fighter wants in one tick, the input box (visao-geral.md, "O estado em
# quatro caixas"). A player and a bot fill the same three fields: the rules never know who
# presses (DEC-0004).
class_name TickInput
extends RefCounted

# x to the right, y forward, relative to yaw; length up to 1 (the rules clamp a longer one).
var move := Vector2.ZERO
# Where the camera looks, in rad; 0 looks down -Z.
var yaw := 0.0
# A one-tick touch: true only on the tick of the press (DEC-0026 §1).
var jump := false
