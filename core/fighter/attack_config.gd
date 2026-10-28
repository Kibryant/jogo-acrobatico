# The numbers of one sword move for one match, made once at load (visao-geral.md, "A configuração
# nasce na carga"): the times of its AttackData in integer ticks (DEC-0004, rule 3) and its arc in
# radians. It never changes during a match, so it stays out of the rollback state; the state names
# the move by its ID (FighterState.action_move) and the core finds it in CombatConfig.attacks.
class_name AttackConfig
extends RefCounted

var windup_ticks: int
var active_ticks: int
var recovery_ticks: int
# Stamina points, paid on the first tick of the windup.
var stamina_cost: float
# Health points the target loses on the contact.
var damage: int
# rad, relative to the swing's direction; positive turns left, like the yaw.
var arc_from: float
var arc_to: float


static func create(data: AttackData, tickrate: int) -> AttackConfig:
	var config := AttackConfig.new()
	config.windup_ticks = Ticks.from_ms(data.windup_ms, tickrate)
	config.active_ticks = Ticks.from_ms(data.active_ms, tickrate)
	config.recovery_ticks = Ticks.from_ms(data.recovery_ms, tickrate)
	# The data check rejects an active window that rounds to 0 ticks at 30 or 60; this assert,
	# gone from a release build, only guards data that skipped it, or another tickrate.
	assert(config.active_ticks > 0, "the active window became 0 ticks at %d ticks" % tickrate)
	config.stamina_cost = data.stamina_cost
	config.damage = data.damage
	config.arc_from = deg_to_rad(data.arc_from_deg)
	config.arc_to = deg_to_rad(data.arc_to_deg)
	return config
