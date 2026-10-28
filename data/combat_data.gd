# The combat numbers of docs/design/combate.md and partida.md, in the units of the paper: metres,
# ms and points (DEC-0004, rule 3; DEC-0051 §6). A .tres of this class is design data, immutable
# at runtime; CombatConfig.create turns it into ticks once, at load, as MovementData is. The
# defaults are zero on purpose: the numbers live in the .tres (combat_v0.tres), never here.
class_name CombatData
extends Resource

@export_group("Moves")
## The light attack (combate.md, "Os golpes e as defesas": "Golpe leve").
@export var light_attack: AttackData

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

@export_group("Health")
## partida.md, "A vida sem partida": the health of every fighter.
@export var max_health: int
## The health returns to the max this long after the contact of the last hit taken (partida.md,
## "A vida sem partida"); 0 turns the refill off, for the match of TASK-12.7.
@export var health_refill_ms: int


# The move of an ID, FighterCommand's (FighterState.action_move): the light attack so far; null
# for a move this combat does not have. The screen reads the shakes this way; the core reads the
# CombatConfig, made from the same moves (CombatConfig.create).
func attack(move: StringName) -> AttackData:
	if move == FighterCommand.LIGHT_ATTACK:
		return light_attack
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
	var checks: Array[String] = [
		_positive_error("hand_offset_m", hand_offset_m, "the hand sits off the body's axis"),
		_positive_error("hand_height_m", hand_height_m, "the hand sits above the feet"),
		_positive_error("blade_length_m", blade_length_m, "a blade needs a length"),
		_not_negative_error("blade_radius_m", blade_radius_m, "a radius cannot be negative"),
		_positive_error("max_health", max_health, "a fighter needs some health"),
		_not_negative_refill_error(),
		_guard_raise_error(),
		_half_angle_error(),
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
