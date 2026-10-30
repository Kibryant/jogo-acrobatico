# The combat numbers of docs/design/combate.md and partida.md, in the units of the paper: metres,
# ms and points (DEC-0004, rule 3; DEC-0051 §6). A .tres of this class is design data, immutable
# at runtime; CombatConfig.create turns it into ticks once, at load, as MovementData is. The
# defaults are zero on purpose: the numbers live in the .tres (combat_v0.tres), never here.
class_name CombatData
extends Resource

@export_group("Moves")
## The light attack (combate.md, "Os golpes e as defesas": "Golpe leve").
@export var light_attack: AttackData
## The charged attack (combate.md, "Os golpes e as defesas": "Golpe carregado"; TASK-12.3).
@export var charged_attack: AttackData

@export_group("Blade")
## The hand, where the blade starts: this far off the body's axis (combate.md, "A lâmina e o
## contato": "A mão").
@export var hand_offset_m: float
## The hand's height above the feet: the plane the light sweeps.
@export var hand_height_m: float
## From the hand to the tip (combate.md, "A lâmina e o contato": "Comprimento da lâmina").
@export var blade_length_m: float
## The thickness of the contact (combate.md, "A lâmina e o contato": "Raio da lâmina").
@export var blade_radius_m: float

@export_group("Guard")
## The guard rises this long after the button goes down, and blocks from then on (combate.md, "O
## bloqueio, a guarda andando e a stamina": "Segurar a tecla levanta a guarda em 100 ms").
@export var guard_raise_ms: int
## The guard covers this much to each side of where the body looks, on the floor's plane, from
## the defender's axis to the attacker's (DEC-0054 §2).
@export var guard_half_angle_deg: float

@export_group("Parry")
## The parry's window, from the press (combate.md, "Os golpes e as defesas", the row "Parry").
@export var parry_window_ms: int
## The stance ends this long after the contact of a charged it parried.
@export var parry_recovery_ms: int
## The stance that parried nothing lasts this long after its window.
@export var parry_whiff_recovery_ms: int
## Stamina points, paid on the press.
@export var parry_stamina_cost: float
## Whoever was parried acts again this long after the contact, plus the hitstop (combate.md, "O
## tranco e a vantagem", the row "Carregado aparado").
@export var parried_stun_ms: int
## The hitstop of whoever was parried, alone (combate.md, "O hitstop e o tremor", the row "Parry").
@export var parried_hitstop_ms: int
## The camera's shake on both sides of a parry: presentation only, never in the state.
@export var parry_shake_ms: int
@export var parry_shake_deg: float

@export_group("Feint")
## The guard button feints the charged up to this far into its windup (combate.md, "A finta").
@export var feint_until_ms: int
## The feint's recovery.
@export var feint_recovery_ms: int
## Stamina points, paid on the feint.
@export var feint_stamina_cost: float

@export_group("Health")
## partida.md, "A vida sem partida": the health of every fighter.
@export var max_health: int
## The health returns to the max this long after the contact of the last hit taken (partida.md,
## "A vida sem partida"); 0 turns the refill off, for the match of TASK-12.7.
@export var health_refill_ms: int


# The move of an ID, FighterCommand's (FighterState.action_move): the light or the charged attack;
# null for a move this combat does not have. The screen reads the shakes this way; the core reads
# the CombatConfig, made from the same moves (CombatConfig.create).
func attack(move: StringName) -> AttackData:
	if move == FighterCommand.LIGHT_ATTACK:
		return light_attack
	if move == FighterCommand.CHARGED_ATTACK:
		return charged_attack
	return null


# The data check, layer 3 of DEC-0027 §2: one message per impossible number, each naming its
# field, empty when every number can be. The gate runs it over every combat .tres under data/
# (test/data/combat_data_test.gd).
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if light_attack == null:
		errors.append("light_attack is missing: a combat needs its light attack")
	else:
		errors.append_array(light_attack.validate("light_attack."))
	if charged_attack == null:
		errors.append("charged_attack is missing: a combat needs its charged attack")
	else:
		errors.append_array(charged_attack.validate("charged_attack."))
		errors.append_array(_tip_errors("charged_attack.", charged_attack))
	var checks: Array[String] = [
		_positive_error("hand_offset_m", hand_offset_m, "the hand sits off the body's axis"),
		_positive_error("hand_height_m", hand_height_m, "the hand sits above the feet"),
		_positive_error("blade_length_m", blade_length_m, "a blade needs a length"),
		_not_negative_error("blade_radius_m", blade_radius_m, "a radius cannot be negative"),
		_positive_error("max_health", max_health, "a fighter needs some health"),
		_not_negative_refill_error(),
		_guard_raise_error(),
		_half_angle_error(),
		_time_error("parry_window_ms", parry_window_ms),
		_time_error("parry_recovery_ms", parry_recovery_ms),
		_time_error("parry_whiff_recovery_ms", parry_whiff_recovery_ms),
		_not_negative_error("parry_stamina_cost", parry_stamina_cost, "a cost cannot be negative"),
		_time_error("parried_stun_ms", parried_stun_ms),
		_time_error("parried_hitstop_ms", parried_hitstop_ms),
		_time_error("parry_shake_ms", parry_shake_ms),
		_not_negative_error("parry_shake_deg", parry_shake_deg, "a shake cannot be negative"),
		_time_error("feint_until_ms", feint_until_ms),
		_time_error("feint_recovery_ms", feint_recovery_ms),
		_not_negative_error("feint_stamina_cost", feint_stamina_cost, "a cost cannot be negative"),
	]
	for message: String in checks:
		if not message.is_empty():
			errors.append(message)
	return errors


static func _positive_error(field: String, value: float, why: String) -> String:
	if value <= 0.0:
		return "%s is %s: %s" % [field, value, why]
	return ""


static func _not_negative_error(field: String, value: float, why: String) -> String:
	if value < 0.0:
		return "%s is %s: %s" % [field, value, why]
	return ""


# Nothing divides by the refill: 0 is a legitimate "no refill".
func _not_negative_refill_error() -> String:
	if health_refill_ms < 0:
		return "health_refill_ms is %d ms: a time cannot be negative" % health_refill_ms
	return ""


# 0 is a guard up at once: nothing divides by it.
func _guard_raise_error() -> String:
	if guard_raise_ms < 0:
		return "guard_raise_ms is %d ms: a time cannot be negative" % guard_raise_ms
	return ""


# From nothing covered to every side: half a turn each way is the whole circle.
func _half_angle_error() -> String:
	if guard_half_angle_deg < 0.0 or guard_half_angle_deg > 180.0:
		return (
			"guard_half_angle_deg is %s: a half angle goes from 0 to 180 degrees"
			% guard_half_angle_deg
		)
	return ""


static func _time_error(field: String, ms: int) -> String:
	if ms < 0:
		return "%s is %d ms: a time cannot be negative" % [field, ms]
	return ""


# A vertical cut's tip must be where the blade reaches: its height off the hand's no farther than
# the hand's offset plus the blade, above or below, or the elevation has no sine (combate.md, "O
# corte do carregado"). A move that sweeps flat does not read them.
func _tip_errors(prefix: String, move: AttackData) -> PackedStringArray:
	var errors := PackedStringArray()
	if not move.vertical_cut:
		return errors
	var reach := hand_offset_m + blade_length_m
	var heights: Dictionary[String, float] = {
		"tip_from_height_m": move.tip_from_height_m,
		"tip_to_height_m": move.tip_to_height_m,
	}
	for field: String in heights:
		var height := heights[field]
		if absf(height - hand_height_m) > reach:
			errors.append(
				(
					"%s%s is %s m: the blade reaches from %s to %s m above the feet"
					% [prefix, field, height, hand_height_m - reach, hand_height_m + reach]
				),
			)
	return errors
