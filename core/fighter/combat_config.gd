# The combat numbers of one match, made once at load for one tickrate, like the MovementConfig
# (visao-geral.md, "A configuração nasce na carga"; DEC-0051 §6): every time of the CombatData in
# integer ticks, the arcs in radians, the metres and points as they are. The core reads it and
# never writes it, so it stays out of the rollback state.
class_name CombatConfig
extends RefCounted

## The moves of a combat by their IDs, in the order CombatData holds them (TASK-12.3; TASK-12.4).
const MOVES: Array[StringName] = [
	FighterCommand.LIGHT_ATTACK,
	FighterCommand.CHARGED_ATTACK,
	FighterCommand.GUARD_BREAK,
]

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
# The parry (combate.md, "O carregado, o parry e a finta no tick"; DEC-0056 §4): its window from
# the press, the stance's end after a parried contact or after a window that parried nothing, the
# cost paid on the press, and the stun and the hitstop of whoever was parried.
var parry_window_ticks: int
var parry_recovery_ticks: int
var parry_whiff_recovery_ticks: int
var parry_stamina_cost: float
var parried_stun_ticks: int
var parried_hitstop_ticks: int
# The feint (combate.md, "A finta"; DEC-0056 §5): the last tick of the windup it cuts, counted from
# the fire as 0, its recovery and its cost.
var feint_until_ticks: int
var feint_recovery_ticks: int
var feint_stamina_cost: float
# The grab (combate.md, "A quebra, o tech e a esquiva no tick"; DEC-0058 §4 and §5): both are held
# grab_hold_ticks plus the grab's hitstop from the contact; without the tech whoever was grabbed
# acts again grabbed_stun_ticks plus that hitstop after it; with the tech whoever grabbed lets go
# tech_advantage_ticks after whoever answered.
var grab_hold_ticks: int
var grab_hitstop_ticks: int
var grabbed_stun_ticks: int
var tech_advantage_ticks: int


static func create(data: CombatData, tickrate: int) -> CombatConfig:
	var config := CombatConfig.new()
	config.tickrate = tickrate
	var reach := data.hand_offset_m + data.blade_length_m
	for move: StringName in MOVES:
		config.attacks[move] = AttackConfig.create(
			data.attack(move),
			tickrate,
			data.hand_height_m,
			reach,
		)
	config.hand_offset = data.hand_offset_m
	config.hand_height = data.hand_height_m
	config.blade_length = data.blade_length_m
	config.blade_radius = data.blade_radius_m
	config.max_health = data.max_health
	config.health_refill_ticks = Ticks.from_ms(data.health_refill_ms, tickrate)
	config.guard_raise_ticks = Ticks.from_ms(data.guard_raise_ms, tickrate)
	config.guard_half_angle = deg_to_rad(data.guard_half_angle_deg)
	config.parry_window_ticks = Ticks.from_ms(data.parry_window_ms, tickrate)
	config.parry_recovery_ticks = Ticks.from_ms(data.parry_recovery_ms, tickrate)
	config.parry_whiff_recovery_ticks = Ticks.from_ms(data.parry_whiff_recovery_ms, tickrate)
	config.parry_stamina_cost = data.parry_stamina_cost
	config.parried_stun_ticks = Ticks.from_ms(data.parried_stun_ms, tickrate)
	config.parried_hitstop_ticks = Ticks.from_ms(data.parried_hitstop_ms, tickrate)
	config.feint_until_ticks = Ticks.from_ms(data.feint_until_ms, tickrate)
	config.feint_recovery_ticks = Ticks.from_ms(data.feint_recovery_ms, tickrate)
	config.feint_stamina_cost = data.feint_stamina_cost
	config.grab_hold_ticks = Ticks.from_ms(data.grab_hold_ms, tickrate)
	config.grab_hitstop_ticks = Ticks.from_ms(data.grab_hitstop_ms, tickrate)
	config.grabbed_stun_ticks = Ticks.from_ms(data.grabbed_stun_ms, tickrate)
	config.tech_advantage_ticks = Ticks.from_ms(data.tech_advantage_ms, tickrate)
	return config
