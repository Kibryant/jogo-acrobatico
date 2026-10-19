# The referee of the SyncTest (rede.md §4; DEC-0025), GGPO style, as in the netfox probe of
# Desenho 3 (netfox-sonda, sync_probe.gd): the first result of each fighter at each tick is the
# fresh one, and every resimulation of the same tick is compared with it. State the rollback does
# not restore, a field netfox does not record or a flag the engine keeps, makes a resimulation come
# out different: a divergence. It listens to netfox's after_process_tick, which comes after every
# fighter of the tick has moved, so the production code carries no hook for it.
#
# It compares the whole state (TASK-10.1, criterion 8; F-101 §1): the body's position and
# velocity and every field of FighterState, found by reflection on the class and not read from
# what netfox records, so a field taken out of the recording is still compared, and a field added
# to FighterState is compared from the day it exists.
#
# On the fresh results it also counts the paths the run went through, so its summary proves what
# the scenario exercised. Every fighter it watches must have input on every tick: without
# prediction, netfox simulates a fighter only on the ticks that have its input (rede.md §4).
extends RefCounted

## A float, a vector, the position or the velocity resimulated farther than this from the fresh
## one is a divergence: 1 µm for the position, in m (TASK-10.1, criterion 8; rede.md §4). Ints,
## bools, enums and names must be equal.
const TOLERANCE := 1e-6
# The arena's 45° ramp runs down from its crest at x = 6 to its foot at x = 7, across z -3..3
# (arena.tscn); a body on the floor with x in (6, 7.2) there is on the ramp or at its foot, the
# zone the probe counted.
const RAMP_FROM_X := 6.0
const RAMP_TO_X := 7.2
const RAMP_HALF_WIDTH := 3.0
# How many divergences the failure message describes.
const SHOWN_MISMATCHES := 5

## The name the summary and the failure messages carry.
var scenario: String
## Ticks simulated for the first time, and ticks simulated again by a rollback.
var fresh_ticks := 0
var resimulated_ticks := 0
## One check per fighter per resimulated tick.
var checks := 0
var mismatches := 0
## m: the largest distance between a resimulated position and the fresh one.
var max_error := 0.0
## m/s: the largest difference between a resimulated velocity and the fresh one.
var max_velocity_error := 0.0
## The paths of the fresh run, summed over the fighters: the floor gained and lost, ticks on the
## floor of the ramp, and ticks whose move hit another fighter.
var landings := 0
var takeoffs := 0
var ramp_ticks := 0
var collisions := 0
## The first divergences, one line each.
var shown: Array[String] = []
## ms of wall clock from the first loop to stop().
var elapsed_ms := 0
## Counters a scenario adds to the summary: the paths only its bots can tell.
var paths: Dictionary[String, int] = { }

var _fighters: Array[Fighter] = []
# The fields of FighterState the samples hold, by name.
var _state_fields: Array[String] = []
var _first: Dictionary[Vector2i, Sample] = { }
var _was_on_floor: Array[bool] = []
var _newest_tick: int
# The tick each rollback loop restored and resimulated from: the first one it simulates.
var _loop_from := 0
var _loop_starting := false
var _started_msec := 0


# Starts watching right before the first loop of a run: the tick of that loop is the first fresh
# one.
func _init(scenario_name: String, fighters: Array[Fighter]) -> void:
	scenario = scenario_name
	_fighters.assign(fighters)
	_state_fields = state_fields()
	for fighter: Fighter in fighters:
		_was_on_floor.append(fighter.state.on_floor)
	_newest_tick = NetworkTime.tick - 1
	_started_msec = Time.get_ticks_msec()
	NetworkRollback.before_loop.connect(_on_loop_start)
	NetworkRollback.after_process_tick.connect(_observe)


# The fields of FighterState, by name: its script variables, without the private ones, the way
# test/fighter/fighter_scene_test.gd finds them.
static func state_fields() -> Array[String]:
	var fields: Array[String] = []
	for property: Dictionary in FighterState.new().get_property_list():
		var usage: int = property["usage"]
		var field: String = property["name"]
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE and not field.begins_with("_"):
			fields.append(field)
	return fields


func stop() -> void:
	elapsed_ms = Time.get_ticks_msec() - _started_msec
	NetworkRollback.before_loop.disconnect(_on_loop_start)
	NetworkRollback.after_process_tick.disconnect(_observe)


# One line, for the gate's log.
func summary() -> String:
	# In full, so the summary tells an exact 0 from an error far below TOLERANCE.
	var line := (
		"SyncTest %s: %d ms, fresh_ticks=%d resimulated_ticks=%d checks=%d mismatches=%d"
		+ " max_err_m=%s max_vel_err_mps=%s landings=%d takeoffs=%d ramp_ticks=%d"
		+ " collisions=%d"
	) % [
		scenario,
		elapsed_ms,
		fresh_ticks,
		resimulated_ticks,
		checks,
		mismatches,
		String.num_scientific(max_error),
		String.num_scientific(max_velocity_error),
		landings,
		takeoffs,
		ramp_ticks,
		collisions,
	]
	for path: String in paths:
		line += " %s=%d" % [path, paths[path]]
	return line


func _on_loop_start() -> void:
	_loop_starting = true


# netfox simulates a tick for the first time as the last tick of its loop, so a tick newer than
# every tick seen is fresh and any other is a resimulation.
func _observe(tick: int) -> void:
	if _loop_starting:
		_loop_starting = false
		_loop_from = tick
	if tick > _newest_tick:
		_newest_tick = tick
		fresh_ticks += 1
	else:
		resimulated_ticks += 1
	for index: int in _fighters.size():
		var fighter := _fighters[index]
		var key := Vector2i(index, tick)
		var result := Sample.new(fighter, _state_fields)
		if _first.has(key):
			_check(_first[key], result, index, tick)
		else:
			_first[key] = result
			_cover(index, fighter)


func _check(fresh: Sample, again: Sample, index: int, tick: int) -> void:
	checks += 1
	var error := again.position.distance_to(fresh.position)
	max_error = maxf(max_error, error)
	var velocity_error := again.velocity.distance_to(fresh.velocity)
	max_velocity_error = maxf(max_velocity_error, velocity_error)
	var differences: Array[String] = []
	if error > TOLERANCE:
		differences.append(
			"position %s then %s, %.9f m off" % [fresh.position, again.position, error]
		)
	if velocity_error > TOLERANCE:
		differences.append(
			"velocity %s then %s, %.9f m/s off" % [fresh.velocity, again.velocity, velocity_error],
		)
	for field: String in fresh.fields:
		var before: Variant = fresh.fields[field]
		var after: Variant = again.fields[field]
		if not same(before, after):
			differences.append("state.%s %s then %s" % [field, before, after])
	if differences.is_empty():
		return
	mismatches += 1
	if shown.size() < SHOWN_MISMATCHES:
		shown.append(
			(
				"fighter %d at tick %d, rolled back to tick %d: %s"
				% [index, tick, _loop_from, "; ".join(differences)]
			),
		)


# The verdict on one field: floats and vectors within TOLERANCE; everything else, ints, bools,
# enums and names, equal and of the same type.
static func same(fresh: Variant, again: Variant) -> bool:
	if typeof(fresh) != typeof(again):
		return false
	if fresh is float:
		var first: float = fresh
		var second: float = again
		return absf(second - first) <= TOLERANCE
	if fresh is Vector3:
		var first: Vector3 = fresh
		var second: Vector3 = again
		return second.distance_to(first) <= TOLERANCE
	return fresh == again


func _cover(index: int, fighter: Fighter) -> void:
	var on_floor := fighter.state.on_floor
	if on_floor and not _was_on_floor[index]:
		landings += 1
	elif _was_on_floor[index] and not on_floor:
		takeoffs += 1
	_was_on_floor[index] = on_floor
	var where := fighter.position
	var on_ramp := where.x > RAMP_FROM_X and where.x < RAMP_TO_X
	if on_floor and on_ramp and absf(where.z) < RAMP_HALF_WIDTH:
		ramp_ticks += 1
	# The fresh tick's move is the body's last one: its slide collisions are still there.
	for slide: int in fighter.get_slide_collision_count():
		if fighter.get_slide_collision(slide).get_collider() is Fighter:
			collisions += 1
			return


# What the SyncTest compares: the body box, position and velocity, and the value of every field
# of the fighter's state.
class Sample:
	var position: Vector3
	var velocity: Vector3
	## The fields of FighterState, by name.
	var fields: Dictionary[String, Variant] = { }


	func _init(fighter: Fighter, state_fields: Array[String]) -> void:
		position = fighter.position
		velocity = fighter.velocity
		for field: String in state_fields:
			fields[field] = fighter.state.get(field)
