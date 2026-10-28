# Several GuardRigs through the same ticks, as a Match runs them (DEC-0051 §1 and §2): on every
# tick the photo is taken of every fighter first, then each fighter's sandwich runs, all reading
# the same photo. Each fighter is driven by a script, a Callable from the tick to its TickInput,
# and every tick leaves a Row: what each fighter's Combat.step returned, the movement's plan, and
# the state, feet and velocity at the end of the tick. A test reads a field on the row of the slice
# that sets it (F-177): the combat's output in `fought`, the movement's in `plans` and `ends`.
extends RefCounted

const GuardRig := preload("res://test/core/fighter/guard_rig.gd")


# One tick of the run, for every fighter, in the order they were added.
class Row:
	var tick: int
	## What Combat.step returned, before the movement's slice.
	var fought: Array[FighterState] = []
	## What Movement.before_move planned.
	var plans: Array[MovePlan] = []
	## The state, the feet and the body's velocity at the end of the tick.
	var ends: Array[FighterState] = []
	var feet: Array[Vector3] = []
	var velocities: Array[Vector3] = []


var fighters: Array[GuardRig] = []
var scripts: Array[Callable] = []
var rows: Array[Row] = []
# A photo given for one tick only, in place of the one taken of the fighters: the test's own view
# of what the fighters would see (DEC-0051 §1). Used once and cleared.
var _staged_photo: TickPhoto


# Adds a fighter with its script: tick -> TickInput.
func add(fighter: GuardRig, script: Callable) -> void:
	fighters.append(fighter)
	scripts.append(script)


func fighter(index: int) -> GuardRig:
	return fighters[index]


# The next tick to simulate.
func tick() -> int:
	return fighters[0].tick()


# The next tick reads this photo instead of one taken of the fighters.
func stage_photo(photo: TickPhoto) -> void:
	_staged_photo = photo


# A photo of the fighters as the next tick would take it.
func photo_now() -> TickPhoto:
	var photo := TickPhoto.new()
	for one: GuardRig in fighters:
		one.snapshot(photo)
	return photo


func step() -> Row:
	var photo := _staged_photo if _staged_photo != null else photo_now()
	_staged_photo = null
	var row := Row.new()
	row.tick = tick()
	for index: int in fighters.size():
		var input: TickInput = scripts[index].call(row.tick)
		fighters[index].step(input, photo)
	for one: GuardRig in fighters:
		row.fought.append(one.fought)
		row.plans.append(one.last_plan)
		row.ends.append(one.state().copy())
		row.feet.append(one.feet())
		row.velocities.append(one.velocity())
	rows.append(row)
	return row


func run(ticks: int) -> void:
	for _step: int in ticks:
		step()


# Runs up to and including `last_tick`.
func run_through(last_tick: int) -> void:
	while tick() <= last_tick:
		step()


# The row of a tick already run, or null.
func row_at(wanted: int) -> Row:
	for row: Row in rows:
		if row.tick == wanted:
			return row
	return null


# The first tick, from `from` on, whose combat output for `index` satisfies the predicate
# (FighterState -> bool), or FighterState.NEVER when none does.
func first_tick(index: int, from: int, predicate: Callable) -> int:
	for row: Row in rows:
		if row.tick < from:
			continue
		var verdict: bool = predicate.call(row.fought[index])
		if verdict:
			return row.tick
	return FighterState.NEVER


# The tick of the swing's one contact stamped by `index`, read from its own state, the core's own
# predicate (combate.md, "O leve no tick": "O contato"); NEVER when the swing touched nobody.
func contact_tick_of(index: int) -> int:
	for row: Row in rows:
		if row.fought[index].contact_tick != FighterState.NEVER:
			return row.fought[index].contact_tick
	return FighterState.NEVER
