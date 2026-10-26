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
# Where the feet are after the move, on every tick (DEC-0044 §1).
var position := Vector3.ZERO
# The answer to the aim request (DEC-0044 §1), only on a tick whose plan asked: whether the ray
# from the point O along the aim found the world within the grapple's range, a point the shoulder
# also sees (DEC-0045 §2 and §3), and the point it found. Without a request, on a miss or on a
# point behind a corner, false and Vector3.ZERO.
var aim_hit := false
var aim_point := Vector3.ZERO
# Another fighter's head (TASK-10.7): the engine's floor this tick is only the head of another
# fighter, and the normal of that contact laid flat, away from the fighter below (it may be about
# zero at the very centre). Declared before their rule (TASK-10.7, round A): the adapter does not
# fill them yet, and the core does not read them yet.
var floor_is_fighter := false
var fighter_away := Vector3.ZERO
