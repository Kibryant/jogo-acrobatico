# What Movement.before_move decides for one tick: the new state and the velocity the engine
# moves the body by, in the same tick (visao-geral.md, "O tick por dentro: o sanduíche").
class_name MovePlan
extends RefCounted

var state: FighterState
# m/s; the engine moves the body by velocity / tickrate.
var velocity := Vector3.ZERO
# The aim request (DEC-0044 §1): true on a tick whose slot holds a grapple press that can fire.
# The node then casts the aim's ray after the move and answers in MoveFacts.aim_hit and aim_point.
var aim_request := false
