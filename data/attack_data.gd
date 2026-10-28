# The numbers of one sword move in the units of the paper: ms, stamina points, health points and
# degrees (combate.md, "Os golpes e as defesas" and "A lâmina e o contato"; DEC-0004, rule 3). A
# CombatData holds one per move, the light attack first, so the charged attack and the guard break
# come in the same way. CombatConfig.create turns it into an AttackConfig, in ticks and radians,
# once at load. The defaults are zero on purpose: the numbers live in the .tres.
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
## Stamina points, paid on the first tick of the windup (combate.md, "A stamina no combate").
@export var stamina_cost: float
## Health points the target loses on the contact.
@export var damage: int
## The arc of the swing, from this angle to the next, relative to the swing's direction; a positive
## angle turns left, like the yaw (combate.md, "O leve no tick": "O arco do leve").
@export var arc_from_deg: float
@export var arc_to_deg: float


# One message per impossible number, each naming its field after prefix ("light_attack." in a
# CombatData), so the gate's print says which number to fix. The active window must be at least
# one tick at every checked tickrate: the slice divides the arc by it. The arc may be anything.
func validate(prefix := "") -> PackedStringArray:
	var checks: Array[String] = [
		_time_error(prefix + "windup_ms", windup_ms, false),
		_time_error(prefix + "active_ms", active_ms, true),
		_time_error(prefix + "recovery_ms", recovery_ms, false),
		_not_negative_error(prefix + "stamina_cost", stamina_cost, "a cost cannot be negative"),
		_not_negative_error(prefix + "damage", damage, "a hit cannot heal"),
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
