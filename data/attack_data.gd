# The numbers of one sword move in the units of the paper: ms, stamina points, health points and
# degrees (combate.md, "Os golpes e as defesas" and "A lâmina e o contato"; DEC-0004, rule 3). A
# CombatData holds one per move, the light attack first and the charged attack second (TASK-12.3),
# so the guard break comes in the same way. CombatConfig.create turns it into an AttackConfig, in
# ticks and radians, once at load. The defaults are zero on purpose: the numbers live in the .tres.
class_name AttackData
extends Resource

## The preparation, from the press to the first active tick (combate.md, "Os golpes e as
## defesas").
@export var windup_ms: int
## The active window, the ticks the blade tests; the arc is split over them (combate.md, "O leve
## no tick": "O arco do leve").
@export var active_ms: int
## From the last active tick to the end of the swing.
@export var recovery_ms: int
## Stamina points, paid on the first tick of the windup (combate.md, "A stamina no combate"), or
## on the first active tick when pays_on_release; the bar needs them to begin either way.
@export var stamina_cost: float
## Health points the target loses on the contact.
@export var damage: int
## The arc of the swing, from this angle to the next, relative to the swing's direction; a positive
## angle turns left, like the yaw (combate.md, "O leve no tick": "O arco do leve").
@export var arc_from_deg: float
@export var arc_to_deg: float
## The stuns, counted from the contact (combate.md, "O tranco e a vantagem"): how long whoever took
## the hit, or blocked it, does not act. The hitstop comes on top (TASK-12.2).
@export var hitstun_ms: int
@export var blockstun_ms: int
## The hitstop of a hit and of a block (combate.md, "O hitstop e o tremor"): how long each fighter
## freezes, from the tick it knows the result (DEC-0055 §4). 0 freezes nobody.
@export var hitstop_hit_ms: int
@export var hitstop_block_ms: int
## Stamina points whoever blocks this move pays on the contact (combate.md, "Os golpes e as
## defesas", the row "Bloqueio").
@export var block_stamina_cost: float
## The camera's shake of whoever took the hit, or blocked it: presentation only, never in the
## state (combate.md, "O hitstop e o tremor"; visual-e-audio.md, "A guarda e o tranco na tela").
@export var hit_shake_ms: int
@export var hit_shake_deg: float
@export var block_shake_ms: int
@export var block_shake_deg: float
## The share of the hit's shake that the attacker's camera takes too, 0 to 1 (combate.md, "O
## hitstop e o tremor": "Carregado acerta [...] metade em quem bateu"): 0 shakes only the target.
@export var hit_shake_attacker_share: float

## The move pays stamina_cost on its first active tick, the release, instead of its first windup
## tick (combate.md, "Os golpes e as defesas": the charged's "25, pagos na soltura").
@export var pays_on_release: bool
## Its windup has armor: a contact of a move that does not break armor takes the damage with no
## stun and no freeze (combate.md, "A armadura do carregado").
@export var armor: bool
## Its contact stuns a windup with armor as any other (combate.md, "A armadura": "Contra o
## carregado, a armadura não vale").
@export var breaks_armor: bool
## A parry stance in its window parries it (combate.md, "O parry (Q-21)": "Só apara o carregado").
@export var parryable: bool
## The guard button going down early in its windup feints it (combate.md, "A finta").
@export var feintable: bool
## It cuts top to bottom in the vertical plane of its direction, from the tip's first height to
## its last, instead of sweeping the horizontal arc (combate.md, "O corte do carregado").
@export var vertical_cut: bool
## m above the feet: where the tip of a vertical cut begins and ends; the code turns them into
## elevations at load (combate.md, "O corte do carregado": "O dado guarda as duas alturas da
## ponta"). A CombatData checks that the blade reaches them.
@export var tip_from_height_m: float
@export var tip_to_height_m: float


# One message per impossible number, each naming its field after prefix ("light_attack." in a
# CombatData), so the gate's print says which number to fix. The active window must be at least
# one tick at every checked tickrate: the slice divides the arc by it. The arc may be anything;
# the tip's heights need the blade, so the CombatData checks them.
func validate(prefix := "") -> PackedStringArray:
	var checks: Array[String] = [
		_time_error(prefix + "windup_ms", windup_ms, false),
		_time_error(prefix + "active_ms", active_ms, true),
		_time_error(prefix + "recovery_ms", recovery_ms, false),
		_not_negative_error(prefix + "stamina_cost", stamina_cost, "a cost cannot be negative"),
		_not_negative_error(prefix + "damage", damage, "a hit cannot heal"),
		_time_error(prefix + "hitstun_ms", hitstun_ms, false),
		_time_error(prefix + "blockstun_ms", blockstun_ms, false),
		_time_error(prefix + "hitstop_hit_ms", hitstop_hit_ms, false),
		_time_error(prefix + "hitstop_block_ms", hitstop_block_ms, false),
		_not_negative_error(
			prefix + "block_stamina_cost",
			block_stamina_cost,
			"a cost cannot be negative",
		),
		_time_error(prefix + "hit_shake_ms", hit_shake_ms, false),
		_not_negative_error(prefix + "hit_shake_deg", hit_shake_deg, "a shake cannot be negative"),
		_time_error(prefix + "block_shake_ms", block_shake_ms, false),
		_not_negative_error(
			prefix + "block_shake_deg",
			block_shake_deg,
			"a shake cannot be negative",
		),
		_share_error(prefix + "hit_shake_attacker_share", hit_shake_attacker_share),
	]
	var errors := PackedStringArray()
	for message: String in checks:
		if not message.is_empty():
			errors.append(message)
	return errors


# A negative time is wrong on its own; a time the rules divide by is also wrong when it rounds to
# 0 ticks at any of MovementData.CHECKED_TICKRATES, the nearest tick with ties up (Ticks.from_ms).
static func _time_error(field: String, ms: int, divides: bool) -> String:
	if ms < 0:
		return "%s is %d ms: a time cannot be negative" % [field, ms]
	if not divides:
		return ""
	var zero_at: Array[String] = []
	for tickrate: int in MovementData.CHECKED_TICKRATES:
		if Ticks.from_ms(ms, tickrate) < 1:
			zero_at.append(str(tickrate))
	if zero_at.is_empty():
		return ""
	return (
		"%s is %d ms: it rounds to 0 ticks at %s ticks per second, and the arc is split over it"
		% [field, ms, " and ".join(zero_at)]
	)


static func _not_negative_error(field: String, value: float, why: String) -> String:
	if value < 0.0:
		return "%s is %s: %s" % [field, value, why]
	return ""


# A share goes from none, 0, to all, 1.
static func _share_error(field: String, share: float) -> String:
	if share < 0.0 or share > 1.0:
		return "%s is %s: a share goes from 0 to 1" % [field, share]
	return ""
