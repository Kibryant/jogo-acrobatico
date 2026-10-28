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
## The walk with the guard up or during a swing, standing (movimento.md, "Chão": "Andar
## devagar"; F-175 §2): the target speed instead of the run's, by the same acceleration.
@export var slow_walk_speed_mps: float

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

@export_group("Dash")
## Covered over the dash's duration, from the floor (movimento.md, "Dash": "Distância").
@export var dash_distance_m: float
## From the press to the end; the speed derives from it (movimento.md, "Dash": "Duração").
@export var dash_ms: int
## The horizontal speed right after the dash, in its direction (movimento.md, "Dash").
@export var dash_exit_speed_mps: float
## From the end of a dash until the next may start (movimento.md, "Dash": "Recarga").
@export var dash_cooldown_ms: int
## Stamina points, paid when the dash starts (movimento.md, "Dash": "Custo").
@export var dash_cost: float

@export_group("Wall run")
## A face this steep or steeper is a wall, from the horizontal (movimento.md, "Corrida na parede":
## "Inclinação mínima da parede").
@export var wall_min_incline_deg: float
## The least speed along the wall that starts a run (movimento.md, "Corrida na parede").
@export var wall_entry_speed_mps: float
## The speed of the run, kept from a faster entry up to the ceiling (movimento.md, "Corrida na
## parede": "Velocidade na parede").
@export var wall_run_speed_mps: float
## movimento.md, "Corrida na parede": "Teto de velocidade na parede".
@export var wall_max_speed_mps: float
## The longest run, from the entry (movimento.md, "Corrida na parede": "Duração máxima").
@export var wall_run_max_ms: int
## The height holds this long from the entry, then the slide begins (movimento.md, "Corrida na
## parede": "Altura").
@export var wall_hold_ms: int
## Percent of the jump's rise gravity, added on every tick of the slide (movimento.md, "Corrida na
## parede": "Altura").
@export var wall_slide_gravity_pct: float
## Above the press, with the rise gravity of the jump (movimento.md, "Corrida na parede": "Pulo da
## parede").
@export var wall_jump_height_m: float
## Out of the wall, along its normal (movimento.md, "Corrida na parede": "Pulo da parede").
@export var wall_jump_push_mps: float
## The same collider with a normal this close is the same wall (movimento.md, "Corrida na
## parede": "Mesma parede, em números").
@export var wall_same_face_deg: float
## The wall must rise this far above the head: the ray that asks for it stands this far above
## the capsule's top, 2,1 m above the feet of the 1,8 m capsule (movimento.md, "Corrida na
## parede": "A parede passa da cabeça"; TASK-10.10).
@export var wall_clear_above_head_m: float
## The capsule's mesh leans this far away from the wall during a run, only on screen
## (movimento.md, "Corrida na parede": "O que se vê na parede").
@export var wall_lean_deg: float
## The lean comes in and goes out over this time, per displayed frame (movimento.md, "Corrida na
## parede": "O que se vê na parede").
@export var wall_lean_ms: int

@export_group("Grapple")
## The ray's length, measured from the point O along the aim (movimento.md, "Gancho": "Alcance";
## DEC-0045 §2).
@export var grapple_range_m: float
## A point nearer O than this is a miss (movimento.md, "Gancho": "Alcance mínimo").
@export var grapple_min_range_m: float
## The cable flies this long before the pull (movimento.md, "Gancho": "Tempo até prender").
@export var grapple_attach_ms: int
## The pull takes the feet toward the point at this speed (movimento.md, "Gancho": "Velocidade da
## puxada").
@export var grapple_pull_speed_mps: float
## The feet this close to the point release the hook (movimento.md, "Gancho": "Como solta").
@export var grapple_release_distance_m: float
## Percent of the pull: a speed toward the point below it releases the hook (movimento.md,
## "Gancho": "Trava").
@export var grapple_block_pct: float
## From a release until the next grapple may fire (movimento.md, "Gancho": "Recarga").
@export var grapple_cooldown_ms: int
## The aim's height above the feet, the shoulder: a copy of the camera's pivot height, which a
## data test keeps equal to camera_v0.tres (movimento.md, "Gancho": "De onde sai a mira";
## DEC-0044 §3).
@export var aim_height_m: float
## The point O, where the aim leaves from, this far to the right of the yaw from the shoulder: a
## copy of the camera's shoulder, sign included (negative is the left one, 0 the shoulder itself),
## which a data test keeps equal to camera_v0.tres (movimento.md, "Gancho": "De onde sai a mira";
## DEC-0045 §2). No value of it is impossible.
@export var aim_side_m: float
## Whoever lands on another fighter's head slides off it at least this fast (movimento.md, "O
## corpo": "Escorregar da cabeça"; TASK-10.7).
@export var head_slide_speed_mps: float


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
		_not_negative_error(
			"slow_walk_speed_mps",
			slow_walk_speed_mps,
			"a speed cannot be negative",
		),
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
		# The dash's speed is its distance over its duration (movimento.md, "Dash": "Deriva a
		# velocidade"), so both must be there; nothing divides by the cooldown, and zero is a
		# legitimate "no cooldown". An exit speed of zero stops the body dead, and a cost of zero
		# is a free dash.
		_positive_error("dash_distance_m", dash_distance_m, "the dash's speed derives from it"),
		_time_error("dash_ms", dash_ms, true),
		_not_negative_error(
			"dash_exit_speed_mps",
			dash_exit_speed_mps,
			"a speed cannot be negative",
		),
		_time_error("dash_cooldown_ms", dash_cooldown_ms, false),
		_cost_error("dash_cost", dash_cost),
		# The wall run (movimento.md, "Corrida na parede"). Nothing divides by its two times: a run
		# or a hold of 0 ticks is legal, the hold never longer than the run.
		_wall_incline_error(),
		_wall_entry_speed_error(),
		_positive_error("wall_run_speed_mps", wall_run_speed_mps, "a run needs a speed"),
		_wall_max_speed_error(),
		_time_error("wall_run_max_ms", wall_run_max_ms, false),
		_wall_hold_error(),
		_range_error("wall_slide_gravity_pct", wall_slide_gravity_pct, 100.0, "a percentage"),
		_positive_error("wall_jump_height_m", wall_jump_height_m, "its exit speed derives from it"),
		_not_negative_error(
			"wall_jump_push_mps",
			wall_jump_push_mps,
			"a negative push would throw the body into the wall",
		),
		_range_error("wall_same_face_deg", wall_same_face_deg, 90.0, "an angle between normals"),
		# The wall that rises above the head and the lean on screen (TASK-10.10). The ray is never
		# below the capsule's top; nothing divides by the lean's time: 0 leans at once.
		_not_negative_error(
			"wall_clear_above_head_m",
			wall_clear_above_head_m,
			"the ray would stand inside the capsule",
		),
		_range_error("wall_lean_deg", wall_lean_deg, 90.0, "a lean"),
		_time_error("wall_lean_ms", wall_lean_ms, false),
		# The grapple (movimento.md, "Gancho"). The minimum and the release distance live inside
		# the range; nothing divides by its two times, so the cable may bite at once and the
		# cooldown may be none.
		_positive_error("grapple_range_m", grapple_range_m, "the ray needs a length"),
		_grapple_min_range_error(),
		_time_error("grapple_attach_ms", grapple_attach_ms, false),
		_positive_error(
			"grapple_pull_speed_mps",
			grapple_pull_speed_mps,
			"a pull without speed never arrives",
		),
		_grapple_release_distance_error(),
		_range_error("grapple_block_pct", grapple_block_pct, 100.0, "a percentage"),
		_time_error("grapple_cooldown_ms", grapple_cooldown_ms, false),
		_positive_error("aim_height_m", aim_height_m, "the aim leaves from above the feet"),
		# Another fighter's head (TASK-10.7).
		_positive_error(
			"head_slide_speed_mps",
			head_slide_speed_mps,
			"whoever lands on a head would never leave it",
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


# A value from 0 to most, both inclusive.
static func _range_error(field: String, value: float, most: float, what: String) -> String:
	if value < 0.0 or value > most:
		return "%s is %s: %s goes from 0 to %s" % [field, value, what, most]
	return ""


# A wall is steeper than any floor and at most vertical: above max_slope_deg, up to 90°. A max
# slope that is not a slope has its own message, and at 90° every face is floor, a design that
# never runs on a wall but is no impossible number: against those the incline says nothing more.
func _wall_incline_error() -> String:
	var incline := wall_min_incline_deg
	if incline <= 0.0 or incline > 90.0:
		return "wall_min_incline_deg is %s: a wall goes up to 90 degrees" % incline
	var slope_leaves_room := max_slope_deg >= 0.0 and max_slope_deg < 90.0
	if slope_leaves_room and incline <= max_slope_deg:
		return (
			"wall_min_incline_deg is %s: at or below max_slope_deg, %s, it would be floor"
			% [incline, max_slope_deg]
		)
	return ""


# The entry speed is not negative and never above the run speed: a run slower than the entry
# speed ends (movimento.md, "Corrida na parede": "Fins da corrida"), so one at the run speed would
# end at once. A run speed that is not positive has its own message.
func _wall_entry_speed_error() -> String:
	var entry := wall_entry_speed_mps
	if entry < 0.0:
		return "wall_entry_speed_mps is %s: a speed cannot be negative" % entry
	if wall_run_speed_mps > 0.0 and entry > wall_run_speed_mps:
		return (
			"wall_entry_speed_mps is %s: above wall_run_speed_mps, %s, a run would end at once"
			% [entry, wall_run_speed_mps]
		)
	return ""


func _wall_max_speed_error() -> String:
	if wall_max_speed_mps < wall_run_speed_mps:
		return (
			"wall_max_speed_mps is %s: below wall_run_speed_mps, %s, no run could keep its speed"
			% [wall_max_speed_mps, wall_run_speed_mps]
		)
	return ""


# The held height is a time, and it cannot outlast the run. A negative run has its own message.
func _wall_hold_error() -> String:
	var negative := _time_error("wall_hold_ms", wall_hold_ms, false)
	if not negative.is_empty():
		return negative
	if wall_run_max_ms >= 0 and wall_hold_ms > wall_run_max_ms:
		return (
			"wall_hold_ms is %d ms: longer than wall_run_max_ms, %d ms, the run ends first"
			% [wall_hold_ms, wall_run_max_ms]
		)
	return ""


# The minimum range is not negative and below the range: at the range or beyond it, no point could
# ever be close enough and far enough at once. A range that is not positive has its own message,
# and against it the minimum says nothing more.
func _grapple_min_range_error() -> String:
	var least := grapple_min_range_m
	if least < 0.0:
		return "grapple_min_range_m is %s: a distance cannot be negative" % least
	if grapple_range_m > 0.0 and least >= grapple_range_m:
		return (
			"grapple_min_range_m is %s: at or beyond grapple_range_m, %s, nothing could ever fire"
			% [least, grapple_range_m]
		)
	return ""


# The release distance is positive and below the range: at the range or beyond it, every pull
# would release on its first tick. A range that is not positive has its own message.
func _grapple_release_distance_error() -> String:
	var release := grapple_release_distance_m
	if release <= 0.0:
		return "grapple_release_distance_m is %s: the feet never reach the point itself" % release
	if grapple_range_m > 0.0 and release >= grapple_range_m:
		return (
			"grapple_release_distance_m is %s: at or beyond grapple_range_m, %s, every pull would"
			% [release, grapple_range_m]
			+ " release at once"
		)
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
