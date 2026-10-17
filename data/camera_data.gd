# The camera numbers of docs/design/movimento.md, "Câmera", in the units of the paper: metres,
# degrees and degrees per mouse pixel. A .tres of this class is design data, immutable at runtime;
# the CameraRig reads it once, at setup. The camera is centred and collides with the world: those
# two lines of the table are not numbers, so they live in the CameraRig. The defaults are zero on
# purpose: the numbers live in the .tres (camera_v0.tres), never here.
class_name CameraData
extends Resource

## From the pivot back to the camera (movimento.md, "Câmera").
@export var distance_m: float
## The pivot above the feet, at the shoulder (movimento.md, "Câmera").
@export var pivot_height_m: float
## Godot measures the field of view vertically (movimento.md, "Câmera").
@export var vertical_fov_deg: float
## The default; a player setting later (movimento.md, "Câmera").
@export var sensitivity_deg_per_px: float
## How far the camera looks up or down. Not on the paper: Claude's v0 reading, so the camera never
## turns upside down (TASK-9 plan, round B).
@export var max_pitch_deg: float


# The data check, layer 3 of DEC-0027 §2: one message per impossible number, empty when every
# number can be. The gate runs it over every camera .tres under data/
# (test/data/camera_data_test.gd).
func validate() -> PackedStringArray:
	var checks: Array[String] = [
		_positive_error("distance_m", distance_m, "a third-person camera sits behind the pivot"),
		_not_negative_error("pivot_height_m", pivot_height_m, "the pivot sits on the body"),
		_fov_error(),
		_positive_error("sensitivity_deg_per_px", sensitivity_deg_per_px, "the mouse must turn"),
		_pitch_error(),
	]
	var errors := PackedStringArray()
	for message: String in checks:
		if not message.is_empty():
			errors.append(message)
	return errors


# A perspective camera sees more than nothing and less than a half turn.
func _fov_error() -> String:
	if vertical_fov_deg <= 0.0 or vertical_fov_deg >= 180.0:
		return (
			"vertical_fov_deg is %s: a field of view is above 0 and below 180 degrees"
			% vertical_fov_deg
		)
	return ""


# Past 90 degrees up or down the camera would turn upside down.
func _pitch_error() -> String:
	if max_pitch_deg < 0.0 or max_pitch_deg > 90.0:
		return "max_pitch_deg is %s: the camera tilts from 0 to 90 degrees" % max_pitch_deg
	return ""


static func _positive_error(field: String, value: float, why: String) -> String:
	if value <= 0.0:
		return "%s is %s: %s" % [field, value, why]
	return ""


static func _not_negative_error(field: String, value: float, why: String) -> String:
	if value < 0.0:
		return "%s is %s: %s" % [field, value, why]
	return ""
