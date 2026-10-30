# The numbers of one sword move for one match, made once at load (visao-geral.md, "A configuração
# nasce na carga"): the times of its AttackData in integer ticks (DEC-0004, rule 3) and its arc in
# radians. It never changes during a match, so it stays out of the rollback state; the state names
# the move by its ID (FighterState.action_move) and the core finds it in CombatConfig.attacks.
class_name AttackConfig
extends RefCounted

var windup_ticks: int
var active_ticks: int
var recovery_ticks: int
# Stamina points, paid on the first tick of the windup, or on the first active tick when
# pays_on_release; the bar needs them to begin either way.
var stamina_cost: float
# Health points the target loses on the contact.
var damage: int
# rad. A flat sweep: relative to the swing's direction, positive turns left, like the yaw. A
# vertical cut: the tip's elevation over the hand's height, positive up (combate.md, "O corte do
# carregado"). Either way the slices split it evenly (Blade.slice_of).
var arc_from: float
var arc_to: float
# What sets the move apart (AttackData; DEC-0056): pays on release, armor in its windup, breaks
# armor, can be parried, can be feinted, cuts in the vertical plane.
var pays_on_release: bool
var armor: bool
var breaks_armor: bool
var parryable: bool
var feintable: bool
var vertical_cut: bool
# The stuns from the contact, and the hitstops of a hit and of a block (combate.md, "O tranco e a
# vantagem" and "O hitstop e o tremor"; DEC-0055). A hitstop of 0 freezes nobody.
var hitstun_ticks: int
var blockstun_ticks: int
var hitstop_hit_ticks: int
var hitstop_block_ticks: int
# Stamina points whoever blocks the move pays on the contact.
var block_stamina_cost: float


# hand_height and reach, the hand's height above the feet and the tip's distance from the attacker's
# axis, turn a vertical cut's tip heights into elevations: asin((height - hand_height) / reach).
static func create(
	data: AttackData,
	tickrate: int,
	hand_height := 0.0,
	reach := 1.0,
) -> AttackConfig:
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
	config.vertical_cut = data.vertical_cut
	if data.vertical_cut:
		config.arc_from = _elevation(data.tip_from_height_m, hand_height, reach)
		config.arc_to = _elevation(data.tip_to_height_m, hand_height, reach)
	config.pays_on_release = data.pays_on_release
	config.armor = data.armor
	config.breaks_armor = data.breaks_armor
	config.parryable = data.parryable
	config.feintable = data.feintable
	config.hitstun_ticks = Ticks.from_ms(data.hitstun_ms, tickrate)
	config.blockstun_ticks = Ticks.from_ms(data.blockstun_ms, tickrate)
	config.hitstop_hit_ticks = Ticks.from_ms(data.hitstop_hit_ms, tickrate)
	config.hitstop_block_ticks = Ticks.from_ms(data.hitstop_block_ms, tickrate)
	config.block_stamina_cost = data.block_stamina_cost
	return config


# The elevation of a tip at height, reach away from the hand's centre: the data check keeps the
# sine within -1..1; the clamp only guards data that skipped it.
static func _elevation(height: float, hand_height: float, reach: float) -> float:
	return asin(clampf((height - hand_height) / reach, -1.0, 1.0))
