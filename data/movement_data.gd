# The movement numbers of docs/design/movimento.md, in the units of the paper: metres, m/s,
# degrees, percent and ms (DEC-0004, rule 3). A .tres of this class is design data, immutable at
# runtime; MovementConfig.create turns it into ticks once, at load. The defaults are zero on
# purpose: the numbers live in the .tres (movement_v0.tres), never here.
class_name MovementData
extends Resource

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


# The data check, layer 3 of DEC-0027 §2: one message per impossible number, empty when every
# number can be. The gate runs it over every movement .tres under data/
# (test/data/movement_data_test.gd).
func validate() -> PackedStringArray:
	var checks: Array[String] = [
		# The rules divide by these four: acceleration is speed / time, and the jump's gravities
		# and exit speed come from the rise and fall times (movimento.md, the "Deriva" notes).
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
	]
	var errors := PackedStringArray()
	for message: String in checks:
		if not message.is_empty():
			errors.append(message)
	return errors


static func _time_error(field: String, ms: int, divides: bool) -> String:
	if ms < 0:
		return "%s is %d ms: a time cannot be negative" % [field, ms]
	if ms == 0 and divides:
		return "%s is 0 ms: the rules divide by it" % field
	return ""


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
