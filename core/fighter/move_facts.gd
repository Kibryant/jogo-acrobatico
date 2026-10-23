# What the engine reports after it moved the body, for Movement.after_move (visao-geral.md, "O
# tick por dentro: o sanduíche"). The engine judges the floor, slope limit included; the core
# only reads the verdict.
class_name MoveFacts
extends RefCounted

# The body ended the tick on the floor.
var on_floor := false
# m/s, after the collision.
var velocity := Vector3.ZERO
# The wall the body touches after the move (DEC-0042 §1): the normal the engine reports and the
# collider's node path relative to the Arena; Vector3.ZERO and &"" without one. The adapter reads
# them from the move's own collisions, and during a wall run from its test-only probe.
var wall_normal := Vector3.ZERO
var wall_id: StringName = &""
