# The combat numbers of one match, made once at load for one tickrate, like the MovementConfig
# (visao-geral.md, "A configuração nasce na carga"; DEC-0051 §6): every time of the CombatData in
# integer ticks, the arcs in radians, the metres and points as they are. The core reads it and
# never writes it, so it stays out of the rollback state.
class_name CombatConfig
extends RefCounted

var tickrate: int
# The moves by their ID, the StringName the slot holds and the state carries (FighterCommand;
# FighterState.action_move).
var attacks: Dictionary[StringName, AttackConfig] = { }
# m: the hand off the attacker's axis and above its feet, and the blade from the hand to the tip.
var hand_offset: float
var hand_height: float
var blade_length: float
var blade_radius: float
var max_health: int
# The health returns to max_health this many ticks after the last hit's contact; 0 turns the
# refill off (partida.md, "A vida sem partida").
var health_refill_ticks: int
# The guard is up this many ticks after it began to rise (combate.md, "O bloqueio, a guarda andando
# e a stamina"), and covers this many radians to each side of the facing (DEC-0054 §2).
var guard_raise_ticks: int
var guard_half_angle: float


static func create(data: CombatData, tickrate: int) -> CombatConfig:
	var config := CombatConfig.new()
	config.tickrate = tickrate
	config.attacks[FighterCommand.LIGHT_ATTACK] = AttackConfig.create(data.light_attack, tickrate)
	config.hand_offset = data.hand_offset_m
	config.hand_height = data.hand_height_m
	config.blade_length = data.blade_length_m
	config.blade_radius = data.blade_radius_m
	config.max_health = data.max_health
	config.health_refill_ticks = Ticks.from_ms(data.health_refill_ms, tickrate)
	config.guard_raise_ticks = Ticks.from_ms(data.guard_raise_ms, tickrate)
	config.guard_half_angle = deg_to_rad(data.guard_half_angle_deg)
	return config
