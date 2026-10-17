# What the engine reports after it moved the body, for Movement.after_move (visao-geral.md, "O
# tick por dentro: o sanduíche"). The engine judges the floor, slope limit included; the core
# only reads the verdict.
class_name MoveFacts
extends RefCounted

# The body ended the tick on the floor.
var on_floor := false
# m/s, after the collision.
var velocity := Vector3.ZERO
