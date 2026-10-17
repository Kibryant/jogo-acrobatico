# What Movement.before_move decides for one tick: the new state and the velocity the engine
# moves the body by, in the same tick (visao-geral.md, "O tick por dentro: o sanduíche").
class_name MovePlan
extends RefCounted

var state: FighterState
# m/s; the engine moves the body by velocity / tickrate.
var velocity := Vector3.ZERO
