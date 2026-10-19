# The movement numbers of docs/design/movimento.md, in the units of the paper: metres, m/s,
# degrees, percent and ms (DEC-0004, rule 3). A .tres of this class is design data, immutable at
# runtime; MovementConfig.create turns it into ticks once, at load. The defaults are zero on
# purpose: the numbers live in the .tres (movement_v0.tres), never here.
class_name MovementData
extends Resource

## The tickrates a time the rules divide by must hold at: 60, the game's (DEC-0024), and 30,
## netfox's default (glossario.md, "Ticks por segundo"), the two of criterion 1 of TASK-9. Fewer
## ticks per second never give more ticks for the same time, so 30 is the one that binds first.
const CHECKED_TICKRATES: Array[int] = [30, 60]

@export_group("Body")
## movimento.md, "O corpo".
@export var capsule_height_m: float
## movimento.md, "O corpo".
@export var capsule_radius_m: float
## Steeper than this is not floor (movimento.md, "O corpo").
@export var max_slope_deg: float

@export_group("Ground")
## The same forward, sideways and back (movimento.md, "Chão").
@export var run_speed_mps: float
## From rest to full speed with full input (movimento.md, "Chão").
@export var accel_time_ms: int
## From full speed to rest without input (movimento.md, "Chão").
@export var stop_time_ms: int

@export_group("Jump and air")
## movimento.md, "Pulo e ar".
@export var jump_height_m: float
## From the press to the apex (movimento.md, "Pulo e ar").
@export var jump_rise_ms: int
## From the apex back to the floor (movimento.md, "Pulo e ar").
@export var jump_fall_ms: int
## Percent of the ground acceleration (movimento.md, "Pulo e ar").
@export var air_control_pct: float
## movimento.md, "Pulo e ar".
@export var max_fall_speed_mps: float

@export_group("Forgiveness")
## A jump still counts this long after leaving a ledge (movimento.md, "Perdão").
@export var coyote_ms: int
## A press in the air is kept this long before landing (movimento.md, "Perdão").
@export var buffer_ms: int

@export_group("Double jump and stamina")
## Above the press, with the rise gravity of the jump (movimento.md, "Pulo e ar").
@export var double_jump_height_m: float
## Stamina points (movimento.md, "Pulo e ar": "Custo do pulo duplo").
@export var double_jump_cost: float
## Stamina points of a full bar (movimento.md, "Stamina").
@export var stamina_max: float
## After a spend, the bar regains nothing this long (movimento.md, "Stamina").
@export var stamina_wait_ms: int
## Points per second after the wait (movimento.md, "Stamina").
@export var stamina_regen_per_s: float


# The data check, layer 3 of DEC-0027 §2: one message per impossible number, empty when every
# number can be. The gate runs it over every movement .tres under data/
# (test/data/movement_data_test.gd), so a time that would break the rules fails before any build:
# the assert of MovementConfig.create() is gone from a release build (TASK-9, part 3).
func validate() -> PackedStringArray:
	var checks: Array[String] = [
		# The rules divide by these four, in ticks: acceleration is speed / time, and the jump's
		# gravities and exit speed come from the rise and fall times (movimento.md, the "Deriva"
		# notes). Each must be at least 1 tick at every checked tickrate.
		_time_error("accel_time_ms", accel_time_ms, true),
		_time_error("stop_time_ms", stop_time_ms, true),
		_time_error("jump_rise_ms", jump_rise_ms, true),
		_time_error("jump_fall_ms", jump_fall_ms, true),
		# Nothing divides by the windows: zero is a legitimate "no forgiveness".
		_time_error("coyote_ms", coyote_ms, false),
		_time_error("buffer_ms", buffer_ms, false),
		_slope_error(),
		_positive_error("capsule_height_m", capsule_height_m, "the capsule needs a height"),
		_positive_error("capsule_radius_m", capsule_radius_m, "the capsule needs a radius"),
		# Both gravities derive from the jump height, so without it nothing would fall; without a
		# fall speed, nothing could.
		_positive_error("jump_height_m", jump_height_m, "the gravities derive from it"),
		_positive_error("max_fall_speed_mps", max_fall_speed_mps, "nothing could fall"),
		_not_negative_error("run_speed_mps", run_speed_mps, "a speed cannot be negative"),
		_not_negative_error("air_control_pct", air_control_pct, "air control cannot be negative"),
		# The double jump's exit speed derives from its height, so zero is no jump; a bar
		# without points pays nothing (movimento.md, "Pulo e ar" and "Stamina").
		_positive_error(
			"double_jump_height_m",
			double_jump_height_m,
			"its exit speed derives from it",
		),
		_positive_error("stamina_max", stamina_max, "a bar without points pays nothing"),
		_cost_error("double_jump_cost", double_jump_cost),
		# Nothing divides by the wait: zero regains at once. A regen of zero freezes the bar, as
		# the test fixtures do.
		_time_error("stamina_wait_ms", stamina_wait_ms, false),
		_not_negative_error(
			"stamina_regen_per_s",
			stamina_regen_per_s,
			"a regen cannot be negative",
		),
	]
	var errors := PackedStringArray()
	for message: String in checks:
		if not message.is_empty():
			errors.append(message)
	return errors


# A negative time is wrong on its own, and only that is said of it. A time the rules divide by is
# also wrong when it rounds to 0 ticks, the nearest tick with ties up (Ticks.from_ms), at any of
# CHECKED_TICKRATES: the message names the rates where it does, 30 alone for 9 to 16 ms.
static func _time_error(field: String, ms: int, divides: bool) -> String:
	if ms < 0:
		return "%s is %d ms: a time cannot be negative" % [field, ms]
	if not divides:
		return ""
	var zero_at: Array[String] = []
	for tickrate: int in CHECKED_TICKRATES:
		if Ticks.from_ms(ms, tickrate) < 1:
			zero_at.append(str(tickrate))
	if zero_at.is_empty():
		return ""
	return (
		"%s is %d ms: it rounds to 0 ticks at %s ticks per second, and the rules divide by it"
		% [field, ms, " and ".join(zero_at)]
	)


func _slope_error() -> String:
	if max_slope_deg < 0.0 or max_slope_deg > 90.0:
		return "max_slope_deg is %s: a floor slope goes from 0 to 90 degrees" % max_slope_deg
	return ""


static func _positive_error(field: String, value: float, why: String) -> String:
	if value <= 0.0:
		return "%s is %s: %s" % [field, value, why]
	return ""


static func _not_negative_error(field: String, value: float, why: String) -> String:
	if value < 0.0:
		return "%s is %s: %s" % [field, value, why]
	return ""


# A cost is not negative and fits a full bar: above stamina_max the maneuver could never come
# out. A max that is not positive has its own message, and against it the cost says nothing more.
func _cost_error(field: String, cost: float) -> String:
	if cost < 0.0:
		return "%s is %s: a cost cannot be negative" % [field, cost]
	if stamina_max > 0.0 and cost > stamina_max:
		return (
			"%s is %s: above stamina_max, %s, a full bar could never pay it"
			% [field, cost, stamina_max]
		)
	return ""
