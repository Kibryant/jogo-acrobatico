# The replay summary (TASK-14; testes-e-entrega.md §4, "O resumo"): what the agent measured by
# hand after every session, counted from a replay played again headless (F-166 §7; F-178 §1;
# F-180 §1; F-202, contexto; F-204, contexto; F-205). The file keeps only the keys; what fired,
# landed or changed mode comes from the state trace, the state after every tick
# (replay/state_trace.gd).
# The caller gives it every tick of every fighter, the ticks ascending and the fighters ascending
# within one tick (add(), or feed() for a whole trace), then finish(); lines() is the summary in
# Portuguese, one block per fighter, and fighter() the numbers behind each block.
# On every tick of every fighter it reads three things: the state the tick started from, the
# tick's input and the state after the tick. The state a tick started from is the line of the
# tick before; on the first, the spawn's: a new FighterState, on the floor with no stamps, the
# health at the combat's max.
# It counts with the numbers of the replay's header, the ones the player played with, so a
# session recorded before a tuning of a .tres is still counted with its own numbers. It reads the
# core through its public functions only (Movement.stands, Stamina.at, Combat.swinging,
# Combat.stunned, Combat.held, Combat.in_stance).
# TASK-12.4 adds the guard break (testes-e-entrega.md §4, "Os golpes", "O resultado" and "O
# agarrão"; DEC-0058): its lines beside the sword's, its results (grabbed with or without the
# tech, missed, cut), the clicks lost in the grab, and, for whoever was grabbed, the grabs, the
# techs and the tech rate. The press of the guard break by whoever is GRABBED, after the contact
# and up to the last held tick, is the tech: no click, it counts only in the line "Agarrado:". A
# press of the guard break later in GRABBED, still unable to act, is a press like any other.
# A tool, out of both exports (export_presets.cfg leaves tools/ out): no class_name, preloaded.
extends RefCounted

## The maneuvers ("O movimento": "As manobras"), each counted on the tick it shows in the state
## after the tick: no stamp of a maneuver changes once written (DEC-0055 §5).
const JUMP := &"jump"
const DOUBLE_JUMP := &"double_jump"
const WALL_RUN := &"wall_run"
const WALL_JUMP := &"wall_jump"
const DASH := &"dash"
const GRAPPLE := &"grapple"
const HEAD_LANDING := &"head_landing"
## The maneuvers in the order they can happen inside one tick: before_move fires the jump, the
## double jump, the dash and the wall jump; after_move lands on a head, starts a wall run and
## fires the grapple (core/fighter/movement.gd). The last of a tick is the latest maneuver.
const MANEUVERS: Array[StringName] = [
	JUMP,
	DOUBLE_JUMP,
	DASH,
	WALL_JUMP,
	HEAD_LANDING,
	WALL_RUN,
	GRAPPLE,
]
## The order the lines print them in, F-166 §7's.
const SHOWN_MANEUVERS: Array[StringName] = [
	JUMP,
	DOUBLE_JUMP,
	WALL_RUN,
	WALL_JUMP,
	DASH,
	GRAPPLE,
	HEAD_LANDING,
]

## Why a click of a move never fired, the first reason that holds, in this order ("Os golpes":
## "Os cliques que não saíram"). A press that fired has none, and so has every press of the
## movement.
const SAME_TICK := &"same_tick"
const SWING := &"swing"
const STUN := &"stun"
## Held by a grab, GRABBING or GRABBED (TASK-12.4): "no agarrão".
const IN_GRAB := &"in_grab"
const STANCE := &"stance"
const OFF_FLOOR := &"off_floor"
const NO_STAMINA := &"no_stamina"
const OTHER := &"other"
const REASONS: Array[StringName] = [
	SAME_TICK,
	SWING,
	STUN,
	IN_GRAB,
	STANCE,
	OFF_FLOOR,
	NO_STAMINA,
	OTHER,
]

## What became of a swing ("Os golpes": "O resultado"). A guard break that grabbed did so with the
## tech of whoever it grabbed or without it (TASK-12.4); its miss and its cut are the others'.
const HIT := &"hit"
const BLOCKED := &"blocked"
const PARRIED := &"parried"
const GRABBED_TECH := &"grabbed_tech"
const GRABBED_NO_TECH := &"grabbed_no_tech"
const MISS := &"miss"
const CUT := &"cut"
const UNFINISHED := &"unfinished"
const RESULTS: Array[StringName] = [
	HIT,
	BLOCKED,
	PARRIED,
	GRABBED_TECH,
	GRABBED_NO_TECH,
	MISS,
	CUT,
	UNFINISHED,
]
## The result of a grab before the replay says whether the tech came: finish() turns it into one of
## the two above.
const GRABBED := &"grabbed"

## m: the two bands of the feet's height (F-166 §7: "a 3 m ou mais e a 10 m ou mais").
const HEIGHT_BANDS: Array[float] = [3.0, 10.0]

## The touches that take the slot, highest first (DEC-0039 §4; DEC-0051 §4; DEC-0056 §6;
## DEC-0058 §7): the core writes them the other way round, each over the one before, so on one
## tick the first of them here keeps the slot. Each is also the name of its touch in TickInput. The
## parry counts only for the priority: its presses stay out of the summary.
const PRIORITY: Array[StringName] = [
	FighterCommand.JUMP,
	FighterCommand.DASH,
	FighterCommand.GRAPPLE,
	FighterCommand.PARRY,
	FighterCommand.GUARD_BREAK,
	FighterCommand.CHARGED_ATTACK,
	FighterCommand.LIGHT_ATTACK,
]
## The moves, in the order their lines print: the sword's, then the guard break (TASK-12.4).
const MOVES: Array[StringName] = [
	FighterCommand.LIGHT_ATTACK,
	FighterCommand.CHARGED_ATTACK,
	FighterCommand.GUARD_BREAK,
]
## The presses of the movement, which the summary splits by the mode the tick started in.
const MOVEMENT_PRESSES: Array[StringName] = [
	FighterCommand.JUMP,
	FighterCommand.DASH,
	FighterCommand.GRAPPLE,
]
## The modes in the order the summary prints them ("chão, ar, parede, gancho e dash").
const MODES: Array[int] = [
	FighterState.Mode.GROUND,
	FighterState.Mode.AIR,
	FighterState.Mode.WALL_RUN,
	FighterState.Mode.GRAPPLE,
	FighterState.Mode.DASH,
]
## m/s: a float's slack around the slow walk, so a body walking at it on 32-bit vectors never
## reads as faster; not a design number, as Movement.TURN_HAIR is not.
const SPEED_HAIR := 0.001
## The block opened by each fighter (testes-e-entrega.md §4): the header of the file does not say
## who drove each fighter; in Sozinho, fighter 1 is the dummy.
const HEADER_YOU := "== Lutador 0, você"
const HEADER_OTHER := "== Lutador 1, o outro (o boneco ou o bot)"
const HEADER_MORE := "== Lutador %d, outro"


# One press of the jump, the dash, the grapple, the light or the charged (the parry's stay out):
# its tick, the mode of the state the tick started from, and the tick it fired on, -1 when it
# never did: beaten on its own tick, replaced by a newer press, expired, or still waiting when the
# replay ended. A click of a move that never fired says why, and, when it met a swing, the phase
# of that swing and the ticks from the swing's fire to the click.
class Press:
	var command: StringName = &""
	var tick := -1
	var mode: FighterState.Mode = FighterState.Mode.GROUND
	var fired_tick := -1
	var reason: StringName = &""
	var phase: FighterState.Action = FighterState.Action.NONE
	var into_swing := -1


# One swing that fired: the tick its state entered the windup, the tick of the click that fired
# it, whether it chained on the end of the swing before, its first active tick, its contact and
# its target (-1 when none) and its result. On its first active tick, the distance to the nearest
# other fighter, the side of the cut and the crosshair; over its whole active, the shortest
# distance. A distance of -1 is no other fighter to measure to.
class Swing:
	var move: StringName = &""
	var fire_tick := -1
	var press_tick := -1
	var chained := false
	var active_tick := -1
	var contact_tick := -1
	var target := -1
	var result: StringName = &""
	var first_active_distance := -1.0
	var nearest_distance := -1.0
	## m from the other's axis to the line of the swing (action_yaw), positive with the other to
	## the right of it.
	var side := 0.0
	## m from the other's axis to the aim line, positive with the line to the right of the other.
	var crosshair := 0.0


# Everything the summary counted of one fighter. Every mode and every maneuver has its key, 0
# when it never happened.
class FighterReport:
	var ticks := 0
	var mode_ticks: Dictionary[int, int] = { }
	## Ticks on the ground with the velocity on the plane exactly zero.
	var still_ticks := 0
	## m on the plane, from the second tick on.
	var distance := 0.0
	var maneuvers: Dictionary[StringName, int] = { }
	## The wall runs started on each wall_id, and the ones that started on the wall the state
	## still held from the run before.
	var walls: Dictionary[StringName, int] = { }
	var same_wall_runs := 0
	## The feet's highest point, the first tick it was reached and the last maneuver up to it.
	var max_height := 0.0
	var max_height_tick := -1
	var max_height_after: StringName = &""
	## The ticks with the feet at or above each of HEIGHT_BANDS.
	var ticks_above: Array[int] = []
	## The longest run of ticks not standing on a floor of its own, its first tick and the
	## maneuvers inside it.
	var longest_flight := 0
	var longest_flight_start := -1
	var longest_flight_maneuvers: Dictionary[StringName, int] = { }
	var lowest_health := 0
	## The times the health came back to the max, from the second tick on.
	var refills := 0
	var presses: Array[Press] = []
	var swings: Array[Swing] = []
	## The plane speed of every tick standing on the floor in a phase of a swing, by move.
	var swing_speeds: Dictionary[StringName, PackedFloat64Array] = { }
	## The times this fighter was grabbed, in order (TASK-12.4).
	var grabs: Array[Grab] = []


# One fighter's tick as the summary keeps it until every fighter of the tick has come: the
# presses of the input by priority and the camera's yaw, the state after the tick and the body.
class Feed:
	var tick: int
	var fighter: int
	var pressed: Array[StringName] = []
	var yaw: float
	var state: FighterState
	var position: Vector3
	var velocity: Vector3


# What the summary follows of one fighter from one tick to the next.
class Tracker:
	## The state the next tick starts from, and the feet after the last tick.
	var start: FighterState
	var position := Vector3.ZERO
	## The press of the summary waiting in the slot; null when the slot is empty or holds a parry.
	var slot: Press
	## The swing in progress, and the camera's yaw of its latest windup tick.
	var swing: Swing
	var windup_yaw := 0.0
	## The flight in progress: its first tick, its ticks so far and its maneuvers.
	var flight_start := -1
	var flight := 0
	var flight_maneuvers: Dictionary[StringName, int] = { }
	## The latest maneuver: the one the feet's highest point came after.
	var last_maneuver: StringName = &""
	## The speeds of the swings, by move.
	var speeds: Dictionary[StringName, Samples] = { }
	## The grab this fighter is held by, GRABBED; null when it is not.
	var grab: Grab


# A list of numbers that grows in place.
class Samples:
	var values := PackedFloat64Array()


	func add(value: float) -> void:
		values.append(value)


# A contact stamped on a tick, waiting for the next tick to show whom it landed on, and how.
class Contact:
	var attacker: int
	var tick: int
	var swing: Swing


# One time a fighter was grabbed ("O agarrão"): the contact, its grabbed_tick; the release, the
# tick both are let go of the hold, the contact plus the hold plus the grab's hitstop, so the last
# held tick is the one before it; whether its tech_tick took a tick after the contact; and the tick
# of the first press of the guard break after the contact and before the release, the tech's press,
# -1 when none came.
class Grab:
	var contact := -1
	var release := -1
	var teched := false
	var press_tick := -1


var _movement: MovementConfig
var _combat: CombatConfig
var _reports: Array[FighterReport] = []
var _trackers: Array[Tracker] = []
# The fighters of the tick being gathered: a tick is counted once all of them have come, since
# the distances need every body after it.
var _batch: Array[Feed] = []
var _batch_tick := 0
# The ticks counted: the replay's, one per tick whatever the fighters.
var _ticks := 0
var _contacts: Array[Contact] = []
var _finished := false


# movement and combat are the numbers the replay played with: its header's, at its tickrate.
func _init(movement: MovementConfig, combat: CombatConfig) -> void:
	_movement = movement
	_combat = combat


# One fighter's tick: the input it applied, its state after the tick and its feet and velocity
# after it, in the order of the contract: the ticks ascending, the fighters ascending within one
# tick. It copies what it keeps, so the caller may reuse its objects.
func add(
	tick: int,
	fighter: int,
	input: TickInput,
	state: FighterState,
	position: Vector3,
	velocity: Vector3,
) -> void:
	_take(tick, fighter, input, state.copy(), position, velocity)


# Every line of a trace the headless player made of replay (tools/replay_run.gd), parsed back
# (StateTrace.parse_line), with the input of the replay row of the same tick and fighter: a row's
# tick minus the replay's first tick is the trace's. One line at a time: a 15-minute session is
# about 112 000 lines. It does not finish().
func feed(replay: ReplayFile, trace: StateTrace) -> void:
	var first := replay.first_tick()
	var rows := replay.rows
	var neutral := TickInput.new()
	var at := 0
	for line: String in trace.lines():
		var row := StateTrace.parse_line(line)
		assert(row != null, "a trace line this build cannot read: %s" % line.left(40))
		if row == null:
			continue
		# The rows and the lines both go by tick, and by fighter within one tick.
		while at < rows.size() and _row_before(rows[at], first, row):
			at += 1
		var input := neutral
		if at < rows.size() and _row_at(rows[at], first, row):
			input = rows[at].input
		_take(row.tick, row.fighter, input, row.state, row.position, row.velocity)


# Counts the last tick and closes what is still open: the flight the end cuts counts up to the
# last tick, the press still waiting never fired, and the swing still going is unfinished,
# unless it landed.
func finish() -> void:
	if _finished:
		return
	if not _batch.is_empty():
		_count_batch()
	# The contacts of the last tick: no tick after it shows their stamps.
	_contacts.clear()
	for index: int in _reports.size():
		var report := _reports[index]
		var tracker := _trackers[index]
		_close_flight(report, tracker)
		for swing: Swing in report.swings:
			if swing.result.is_empty():
				swing.result = _end_result(swing, swing == tracker.swing)
			elif swing.result == GRABBED:
				swing.result = _grab_result(swing)
		for move: StringName in MOVES:
			report.swing_speeds[move] = PackedFloat64Array()
		for move: StringName in tracker.speeds:
			report.swing_speeds[move] = tracker.speeds[move].values
	_finished = true


func fighter_count() -> int:
	return _reports.size()


func fighter(index: int) -> FighterReport:
	return _reports[index]


# m, centre to centre: the hand, the blade, the blade's radius and the capsule's radius of the
# header, about 2,43 m with the v0 (combate.md, "A lâmina e o contato"). A miss is within reach
# when its shortest distance over the active is not beyond it, and far when it is.
func reach() -> float:
	return (
		_combat.hand_offset + _combat.blade_length + _combat.blade_radius + _movement.capsule_radius
	)


# m, centre to centre, the reach of one move: the sword's, or, for a move that grabs, the hand's
# length and the capsule's radius, 1,55 m with the v0 (testes-e-entrega.md §4, "As distâncias").
func reach_of(move: StringName) -> float:
	if not _grabs(move):
		return reach()
	var attack: AttackConfig = _combat.attacks[move]
	return attack.hand_reach + _movement.capsule_radius


# The summary in Portuguese, the numbers with the decimal comma and the thousands dot: the line
# of the ticks, then one block per fighter, opened by its exact header (testes-e-entrega.md §4).
func lines() -> PackedStringArray:
	var out := PackedStringArray()
	var fighters := _reports.size()
	var count := "1 lutador" if fighters == 1 else "%s lutadores" % whole(fighters)
	out.append(
		"%s ticks a %d por segundo, %s, %s"
		% [whole(_ticks), _movement.tickrate, duration(_ticks, _movement.tickrate), count],
	)
	for index: int in fighters:
		out.append(_block_header(index))
		out.append_array(_movement_lines(_reports[index]))
		out.append_array(_press_lines(_reports[index]))
		for move: StringName in MOVES:
			out.append_array(_move_lines(_reports[index], move))
		out.append("  %s" % _grabbed_text(_reports[index]))
	return out


# A whole number with the thousands dot: 56.297.
static func whole(value: int) -> String:
	var digits := str(absi(value))
	var grouped := ""
	while digits.length() > 3:
		grouped = "." + digits.right(3) + grouped
		digits = digits.left(digits.length() - 3)
	return ("-" if value < 0 else "") + digits + grouped


# A number with places decimals, the decimal comma and the thousands dot: 1.234,5. A value that
# rounds to zero has no sign.
static func decimal(value: float, places: int) -> String:
	var text := ("%." + str(places) + "f") % absf(value)
	var parts := text.split(".")
	var shown := whole(parts[0].to_int())
	if parts.size() > 1:
		shown += "," + parts[1]
	var zero := text.replace("0", "").replace(".", "").is_empty()
	return ("-" if value < 0.0 and not zero else "") + shown


# ticks at tickrate as a time to the nearest whole second, a tie up: "1 min 54 s" from 60 s,
# "54 s" below (testes-e-entrega.md §4).
@warning_ignore("integer_division")
static func duration(ticks: int, tickrate: int) -> String:
	var seconds := (2 * ticks + tickrate) / (2 * tickrate)
	if seconds < 60:
		return "%d s" % seconds
	return "%s min %d s" % [whole(seconds / 60), seconds % 60]


# ticks at tickrate in ms, to the nearest whole ms, a tie up: 7 ticks at 60 are 117 ms.
@warning_ignore("integer_division")
static func ms(ticks: int, tickrate: int) -> int:
	return (2000 * ticks + tickrate) / (2 * tickrate)


func _take(
	tick: int,
	fighter_index: int,
	input: TickInput,
	state: FighterState,
	position: Vector3,
	velocity: Vector3,
) -> void:
	assert(not _finished, "every tick comes before finish()")
	assert(fighter_index >= 0, "a fighter's index is never negative")
	if not _batch.is_empty() and tick != _batch_tick:
		assert(tick > _batch_tick, "the ticks come ascending")
		_count_batch()
	assert(
		_batch.is_empty() or _batch[_batch.size() - 1].fighter < fighter_index,
		"the fighters come ascending within one tick",
	)
	_batch_tick = tick
	var fed := Feed.new()
	fed.tick = tick
	fed.fighter = fighter_index
	for command: StringName in PRIORITY:
		var touched: bool = input.get(command)
		if touched:
			fed.pressed.append(command)
	fed.yaw = input.yaw
	fed.state = state
	fed.position = position
	fed.velocity = velocity
	_batch.append(fed)
	while _reports.size() <= fighter_index:
		_reports.append(_new_report())
		_trackers.append(_new_tracker())


static func _row_before(record: ReplayFile.Row, first: int, row: StateTrace.Row) -> bool:
	var tick := record.tick - first
	return tick < row.tick or (tick == row.tick and record.fighter < row.fighter)


static func _row_at(record: ReplayFile.Row, first: int, row: StateTrace.Row) -> bool:
	return record.tick - first == row.tick and record.fighter == row.fighter


# One tick of every fighter: first the contacts of the tick before, which this tick's states
# resolve, then each fighter, in order.
func _count_batch() -> void:
	_resolve_contacts()
	for fed: Feed in _batch:
		_count(fed)
	_batch.clear()
	_ticks += 1


func _count(fed: Feed) -> void:
	var report := _reports[fed.fighter]
	var tracker := _trackers[fed.fighter]
	var start := tracker.start
	var end := fed.state
	var first := report.ticks == 0
	report.ticks += 1
	_count_mode(report, end, fed.velocity)
	var maneuvers := _maneuvers_of(start, end, fed.tick)
	_count_maneuvers(report, start, end, maneuvers)
	if not maneuvers.is_empty():
		tracker.last_maneuver = maneuvers[maneuvers.size() - 1]
	_follow_height(report, tracker, fed, first)
	_follow_flight(report, tracker, end, fed.tick, maneuvers)
	_follow_health(report, start, end, first)
	# The distance counts from the second tick on: the first has no feet before it.
	if not first:
		report.distance += _plane_distance(tracker.position, fed.position)
	tracker.position = fed.position
	_follow_grab(report, tracker, end, start, _combat.grab_hold_ticks + _combat.grab_hitstop_ticks)
	var fresh := _take_presses(report, tracker, fed, start)
	var used := _empty_slot(tracker, fed)
	_follow_swing(report, tracker, fed, start, used)
	_judge_clicks(tracker, fed, start, fresh)
	_sample_speed(tracker, fed)
	tracker.start = end


# "O tempo por modo": the mode of the state after the tick; "parado" is the ground with the
# velocity on the plane exactly zero.
static func _count_mode(report: FighterReport, end: FighterState, velocity: Vector3) -> void:
	var mode: int = end.mode
	var ticks: int = report.mode_ticks.get(mode, 0)
	report.mode_ticks[mode] = ticks + 1
	if end.mode == FighterState.Mode.GROUND and velocity.x == 0.0 and velocity.z == 0.0:
		report.still_ticks += 1


# "As manobras", each on the tick it shows in the state after the tick. The jump is jumps_used
# going from 0 to 1 with no wall jump on the tick: the floor's and the coyote's. A wall run is the
# state entering the mode, or, already in it, starting again with another mode_since, as at a
# corner; a seam changes only the wall_id and starts nothing (F-129).
static func _maneuvers_of(start: FighterState, end: FighterState, tick: int) -> Array[StringName]:
	var found: Array[StringName] = []
	if start.jumps_used == 0 and end.jumps_used == 1 and end.wall_jump_tick != tick:
		found.append(JUMP)
	if end.double_jump_tick == tick:
		found.append(DOUBLE_JUMP)
	if end.dash_tick == tick:
		found.append(DASH)
	if end.wall_jump_tick == tick:
		found.append(WALL_JUMP)
	if end.head_landing_tick == tick:
		found.append(HEAD_LANDING)
	var running := end.mode == FighterState.Mode.WALL_RUN
	var was_running := start.mode == FighterState.Mode.WALL_RUN
	if running and (not was_running or start.mode_since != end.mode_since):
		found.append(WALL_RUN)
	if end.grapple_fired_tick == tick:
		found.append(GRAPPLE)
	return found


# "As paredes": the run counts on its wall_id, and it returns to the same wall when the state the
# tick started from still held that wall from the run before; the floor clears it, so a return is
# always in the same flight (DEC-0047; DEC-0048).
static func _count_maneuvers(
	report: FighterReport,
	start: FighterState,
	end: FighterState,
	maneuvers: Array[StringName],
) -> void:
	for maneuver: StringName in maneuvers:
		report.maneuvers[maneuver] += 1
	if not maneuvers.has(WALL_RUN):
		return
	var runs: int = report.walls.get(end.wall_id, 0)
	report.walls[end.wall_id] = runs + 1
	if not start.wall_id.is_empty() and start.wall_id == end.wall_id:
		report.same_wall_runs += 1


# "A altura", the feet's: the highest point, the first tick it was reached and the latest
# maneuver up to it, a maneuver on that very tick included; and the ticks at or above each band.
static func _follow_height(report: FighterReport, tracker: Tracker, fed: Feed, first: bool) -> void:
	var height := fed.position.y
	if first or height > report.max_height:
		report.max_height = height
		report.max_height_tick = fed.tick
		report.max_height_after = tracker.last_maneuver
	for band: int in HEIGHT_BANDS.size():
		if height >= HEIGHT_BANDS[band]:
			report.ticks_above[band] += 1


# "O voo mais longo": the ticks whose state after the tick does not stand on a floor of its own
# (Movement.stands; another fighter's head is flight too), in a row, with the maneuvers on them.
static func _follow_flight(
	report: FighterReport,
	tracker: Tracker,
	end: FighterState,
	tick: int,
	maneuvers: Array[StringName],
) -> void:
	if Movement.stands(end):
		_close_flight(report, tracker)
		return
	if tracker.flight == 0:
		tracker.flight_start = tick
		tracker.flight_maneuvers = _no_maneuvers()
	tracker.flight += 1
	for maneuver: StringName in maneuvers:
		tracker.flight_maneuvers[maneuver] += 1


static func _close_flight(report: FighterReport, tracker: Tracker) -> void:
	if tracker.flight > report.longest_flight:
		report.longest_flight = tracker.flight
		report.longest_flight_start = tracker.flight_start
		report.longest_flight_maneuvers = tracker.flight_maneuvers
	tracker.flight = 0


# "A vida": the lowest, and the returns to the max from the second tick on.
func _follow_health(
	report: FighterReport,
	start: FighterState,
	end: FighterState,
	first: bool,
) -> void:
	report.lowest_health = mini(report.lowest_health, end.health)
	if first:
		return
	if end.health >= _combat.max_health and start.health < _combat.max_health:
		report.refills += 1


# "Os apertos": every touch of the tick by priority. The first takes the slot and replaces the
# press waiting there, whatever its key: the core writes every press of a tick before anything
# fires from the slot. The others never enter it, and a click of a move among them was replaced
# on its own tick. The guard break of a fighter GRABBED after the tick, after the contact and before
# the release, is the tech: no press, only the first noted on the grab; one later in GRABBED is a
# press like any other ("Os apertos"; TASK-12.4). Returns the presses of the tick.
static func _take_presses(
	report: FighterReport,
	tracker: Tracker,
	fed: Feed,
	start: FighterState,
) -> Array[Press]:
	var fresh: Array[Press] = []
	if fed.pressed.is_empty():
		return fresh
	tracker.slot = null
	var winner := fed.pressed[0]
	for command: StringName in fed.pressed:
		if command == FighterCommand.PARRY:
			continue
		if command == FighterCommand.GUARD_BREAK and _tech_press(tracker.grab, fed):
			if tracker.grab.press_tick < 0:
				tracker.grab.press_tick = fed.tick
			continue
		var press := Press.new()
		press.command = command
		press.tick = fed.tick
		press.mode = start.mode
		report.presses.append(press)
		fresh.append(press)
		if command == winner:
			tracker.slot = press
		elif MOVES.has(command):
			press.reason = SAME_TICK
	return fresh


# The slot after the tick (DEC-0039): when it is empty, the press that waited there left it,
# used when within buffer_ticks of its tick, inclusive as Movement's window, and expired when
# later. Returns the press used on this tick, or null.
func _empty_slot(tracker: Tracker, fed: Feed) -> Press:
	var waiting := tracker.slot
	if waiting == null:
		return null
	var end := fed.state
	if end.buffered_command == FighterCommand.NONE:
		tracker.slot = null
		if fed.tick - waiting.tick > _movement.buffer_ticks:
			return null
		waiting.fired_tick = fed.tick
		waiting.reason = &""
		waiting.phase = FighterState.Action.NONE
		waiting.into_swing = -1
		return waiting
	if end.buffered_command != waiting.command or end.buffered_tick != waiting.tick:
		# Another press than the one followed: the summary lets the slot go rather than guess.
		tracker.slot = null
	return null


# "Os golpes": a swing fires when the state enters the windup, from a state not in it; it chains
# when the state the tick started from was in the recovery; it ends on the first tick whose state
# is in no phase of it, or enters the windup of another. Its first active tick takes the
# distance, the side and the crosshair; every active tick, the shortest distance and the contact.
func _follow_swing(
	report: FighterReport,
	tracker: Tracker,
	fed: Feed,
	start: FighterState,
	used: Press,
) -> void:
	var end := fed.state
	var fired := end.action == FighterState.Action.WINDUP
	fired = fired and start.action != FighterState.Action.WINDUP
	if tracker.swing != null and (fired or not Combat.swinging(end)):
		tracker.swing = null
	if fired:
		var born := Swing.new()
		born.move = end.action_move
		born.fire_tick = fed.tick
		born.press_tick = fed.tick
		if used != null and used.command == born.move:
			born.press_tick = used.tick
		born.chained = start.action == FighterState.Action.RECOVERY
		report.swings.append(born)
		tracker.swing = born
	var swing := tracker.swing
	if swing == null:
		return
	if end.action == FighterState.Action.WINDUP:
		tracker.windup_yaw = fed.yaw
		return
	if end.action != FighterState.Action.ACTIVE:
		return
	var other := _nearest_other(fed)
	if swing.active_tick < 0:
		swing.active_tick = fed.tick
		if other != null:
			swing.first_active_distance = _plane_distance(fed.position, other.position)
			swing.side = _to_the_right(fed.position, other.position, end.action_yaw)
			# The aim line runs aim_side to the right of the axis, along the camera's yaw of the
			# last windup tick, the input's (DEC-0045; DEC-0057).
			var aim := _to_the_right(fed.position, other.position, tracker.windup_yaw)
			swing.crosshair = _movement.aim_side - aim
	if other != null:
		var distance := _plane_distance(fed.position, other.position)
		if swing.nearest_distance < 0.0 or distance < swing.nearest_distance:
			swing.nearest_distance = distance
	if swing.contact_tick < 0 and end.contact_tick == fed.tick and end.contact_move == swing.move:
		swing.contact_tick = fed.tick
		var contact := Contact.new()
		contact.attacker = fed.fighter
		contact.tick = fed.tick
		contact.swing = swing
		_contacts.append(contact)


# The contacts of the tick before (testes-e-entrega.md §4, "O resultado"): the target is the first
# other fighter whose state on this tick shows the contact's stamp, read in the order the core's
# attacker reads it (combat.gd, step 1, the attacker's side): for a move that grabs, grabbed, the
# grabbed_tick, and nothing else; parried, for a move that can be parried; hit, with or without
# armor; blocked. A contact no fighter shows on the very next tick, as after a jump of the
# recorded clock, keeps no target, and a guard break whose contact nobody shows grabbed missed.
func _resolve_contacts() -> void:
	for contact: Contact in _contacts:
		if contact.tick + 1 != _batch_tick:
			continue
		var parryable := false
		if _combat.attacks.has(contact.swing.move):
			parryable = _combat.attacks[contact.swing.move].parryable
		var grabs := _grabs(contact.swing.move)
		for fed: Feed in _batch:
			if fed.fighter == contact.attacker:
				continue
			var result := _contact_result(fed.state, contact.tick, parryable, grabs)
			if result.is_empty():
				continue
			contact.swing.target = fed.fighter
			contact.swing.result = result
			break
	_contacts.clear()


static func _contact_result(
	state: FighterState,
	tick: int,
	parryable: bool,
	grabs: bool,
) -> StringName:
	if grabs:
		return GRABBED if state.grabbed_tick == tick else &""
	if parryable and state.parry_tick == tick:
		return PARRIED
	if state.hurt_tick == tick:
		return HIT
	if state.block_tick == tick:
		return BLOCKED
	return &""


# A grab with the tech when its target's grab of that contact had one, and without it otherwise
# ("O resultado": "com tech quando o alvo mostra depois um tech_tick maior que o contato").
func _grab_result(swing: Swing) -> StringName:
	if swing.target < 0 or swing.target >= _reports.size():
		return GRABBED_NO_TECH
	for grab: Grab in _reports[swing.target].grabs:
		if grab.contact == swing.contact_tick:
			return GRABBED_TECH if grab.teched else GRABBED_NO_TECH
	return GRABBED_NO_TECH


# Whether a move grabs: the guard break's hand.
func _grabs(move: StringName) -> bool:
	if not _combat.attacks.has(move):
		return false
	var attack: AttackConfig = _combat.attacks[move]
	return attack.grab


# "O agarrão": the state entering GRABBED is one more grab of this fighter, its contact the
# grabbed_tick and its release hold ticks later, the hold plus the grab's hitstop of the header;
# while it holds, the tech_tick taking a tick after the contact is the tech, until the fighter acts
# again.
static func _follow_grab(
	report: FighterReport,
	tracker: Tracker,
	end: FighterState,
	start: FighterState,
	hold: int,
) -> void:
	if end.action != FighterState.Action.GRABBED:
		tracker.grab = null
		return
	if start.action != FighterState.Action.GRABBED:
		var grab := Grab.new()
		grab.contact = end.grabbed_tick
		grab.release = grab.contact + hold
		report.grabs.append(grab)
		tracker.grab = grab
	var held := tracker.grab
	if held != null and end.tech_tick != start.tech_tick and end.tech_tick > held.contact:
		held.teched = true


# Whether a press of the guard break on this tick is the tech ("Os apertos"): its fighter GRABBED
# after the tick, by a grab whose contact came before it and whose release has not come yet, the
# window the core counts the tech in, up to the last held tick.
static func _tech_press(grab: Grab, fed: Feed) -> bool:
	if grab == null or fed.state.action != FighterState.Action.GRABBED:
		return false
	return fed.tick > grab.contact and fed.tick < grab.release


# A swing with no contact resolved: unfinished when the replay ends in it, a miss when it reached
# the active, cut when it ended before (by a hit taken or the feint).
static func _end_result(swing: Swing, still_going: bool) -> StringName:
	if still_going:
		return UNFINISHED
	if swing.active_tick >= 0:
		return MISS
	return CUT


# "Os cliques que não saíram": the reason of a click of a move, read on its own tick, the first
# that holds. The action comes from the state after the tick, the mode from the state the tick
# started from: the combat's step runs before the movement (DEC-0051 §2). A click that fires later
# loses its reason then.
func _judge_clicks(tracker: Tracker, fed: Feed, start: FighterState, fresh: Array[Press]) -> void:
	var end := fed.state
	for press: Press in fresh:
		if not MOVES.has(press.command) or not press.reason.is_empty() or press.fired_tick >= 0:
			continue
		if Combat.swinging(end):
			press.reason = SWING
			press.phase = end.action
			if tracker.swing != null:
				press.into_swing = fed.tick - tracker.swing.fire_tick
		elif Combat.stunned(end):
			press.reason = STUN
		elif Combat.held(end):
			press.reason = IN_GRAB
		elif Combat.in_stance(end):
			press.reason = STANCE
		elif start.mode != FighterState.Mode.GROUND or not Movement.stands(start):
			press.reason = OFF_FLOOR
		elif Stamina.at(start, _movement, fed.tick) < _cost(press.command):
			press.reason = NO_STAMINA
		else:
			press.reason = OTHER


func _cost(move: StringName) -> float:
	if not _combat.attacks.has(move):
		return 0.0
	return _combat.attacks[move].stamina_cost


# "A velocidade no golpe": the plane speed of a tick standing on the floor in a phase of a swing.
static func _sample_speed(tracker: Tracker, fed: Feed) -> void:
	var end := fed.state
	if not Combat.swinging(end) or not Movement.stands(end):
		return
	if not tracker.speeds.has(end.action_move):
		tracker.speeds[end.action_move] = Samples.new()
	var speed := Vector2(fed.velocity.x, fed.velocity.z).length()
	tracker.speeds[end.action_move].add(speed)


# The other fighter of the tick nearest on the plane, the first on a tie; null when alone.
func _nearest_other(fed: Feed) -> Feed:
	var nearest: Feed = null
	var best := INF
	for other: Feed in _batch:
		if other.fighter == fed.fighter:
			continue
		var distance := _plane_distance(fed.position, other.position)
		if distance < best:
			best = distance
			nearest = other
	return nearest


# m, centre to centre on the floor's plane (x and z).
static func _plane_distance(a: Vector3, b: Vector3) -> float:
	var dx := a.x - b.x
	var dz := a.z - b.z
	return sqrt(dx * dx + dz * dz)


# m point is to the right of the line through origin along yaw, on the floor's plane: yaw 0 looks
# down -Z with +X to the right, and a positive yaw turns left (Aim.direction).
static func _to_the_right(origin: Vector3, point: Vector3, yaw: float) -> float:
	return (point.x - origin.x) * cos(yaw) - (point.z - origin.z) * sin(yaw)


func _new_report() -> FighterReport:
	var report := FighterReport.new()
	for mode: int in MODES:
		report.mode_ticks[mode] = 0
	report.maneuvers = _no_maneuvers()
	report.longest_flight_maneuvers = _no_maneuvers()
	for _band: float in HEIGHT_BANDS:
		report.ticks_above.append(0)
	report.lowest_health = _combat.max_health
	return report


# A fighter before its first tick: the spawn's state, a new FighterState on the floor with no
# stamps and the health at the combat's max.
func _new_tracker() -> Tracker:
	var tracker := Tracker.new()
	tracker.start = FighterState.new()
	tracker.start.health = _combat.max_health
	tracker.flight_maneuvers = _no_maneuvers()
	return tracker


static func _no_maneuvers() -> Dictionary[StringName, int]:
	var counts: Dictionary[StringName, int] = { }
	for maneuver: StringName in MANEUVERS:
		counts[maneuver] = 0
	return counts


static func _block_header(index: int) -> String:
	if index == 0:
		return HEADER_YOU
	if index == 1:
		return HEADER_OTHER
	return HEADER_MORE % index

# --- The lines of a block ---


func _movement_lines(report: FighterReport) -> PackedStringArray:
	var out := PackedStringArray()
	out.append("  O movimento")
	out.append("    Tempo por modo: %s" % _modes_text(report))
	out.append("    Manobras: %s" % _maneuvers_text(report.maneuvers, true))
	out.append("    Distância no plano: %s" % _far_text(report.distance))
	out.append("    Paredes: %s" % _walls_text(report))
	out.append("    Altura: %s" % _height_text(report))
	out.append("    Voo mais longo: %s" % _flight_text(report))
	out.append("    Vida: %s" % _health_text(report.lowest_health, report.refills))
	return out


func _modes_text(report: FighterReport) -> String:
	var parts := PackedStringArray()
	for mode: int in MODES:
		var ticks: int = report.mode_ticks.get(mode, 0)
		var part := "%s %s" % [_mode_name(mode), _time(ticks)]
		if mode == FighterState.Mode.GROUND:
			part += ", dos quais %s parado" % _time(report.still_ticks)
		parts.append(part)
	return "; ".join(parts)


# The maneuvers with their counts, every one when all, else only the ones that happened.
static func _maneuvers_text(counts: Dictionary[StringName, int], all: bool) -> String:
	var parts := PackedStringArray()
	for maneuver: StringName in SHOWN_MANEUVERS:
		var count: int = counts.get(maneuver, 0)
		if count > 0 or all:
			parts.append(_maneuver_count(maneuver, count))
	if parts.is_empty():
		return "sem manobra"
	return _listed(parts)


static func _far_text(metres: float) -> String:
	if metres < 1000.0:
		return "%s m" % whole(roundi(metres))
	return "%s km" % decimal(metres / 1000.0, 1)


static func _walls_text(report: FighterReport) -> String:
	if report.walls.is_empty():
		return "nenhuma corrida na parede"
	var ids: Array[StringName] = []
	ids.assign(report.walls.keys())
	ids.sort_custom(
		func(a: StringName, b: StringName) -> bool:
			var runs_a: int = report.walls[a]
			var runs_b: int = report.walls[b]
			return runs_a > runs_b or (runs_a == runs_b and String(a) < String(b)),
	)
	var parts := PackedStringArray()
	for id: StringName in ids:
		var runs: int = report.walls[id]
		parts.append("%s %s" % [id, whole(runs)])
	var returns := _counted(report.same_wall_runs, "volta à mesma parede", "voltas à mesma parede")
	return "%s; %s" % [_listed(parts), returns]


func _height_text(report: FighterReport) -> String:
	var bands := PackedStringArray()
	for band: int in HEIGHT_BANDS.size():
		var above := report.ticks_above[band] if band < report.ticks_above.size() else 0
		bands.append("%s a %s m ou mais" % [_time(above), _short(HEIGHT_BANDS[band])])
	# Below 0,05 m the height prints as 0,0, and the tick of that highest point is only the float
	# noise of the feet on the floor: session 22 read "0,0 m ... after a dash" with no jump at all.
	if decimal(report.max_height, 1) == decimal(0.0, 1):
		return "o ponto mais alto não passou de 0,0 m; %s" % _listed(bands)
	var after := "sem manobra antes dele"
	if not report.max_height_after.is_empty():
		after = "depois de %s" % _maneuver_one(report.max_height_after)
	return (
		"o ponto mais alto, %s m, %s, %s; %s"
		% [decimal(report.max_height, 1), _moment(report.max_height_tick), after, _listed(bands)]
	)


func _flight_text(report: FighterReport) -> String:
	if report.longest_flight == 0:
		return "nenhum voo"
	var inside := _maneuvers_text(report.longest_flight_maneuvers, false)
	if inside != "sem manobra":
		inside = "com " + inside
	return (
		"%s, que começou %s, %s"
		% [_tenths(report.longest_flight), _moment(report.longest_flight_start), inside]
	)


func _health_text(lowest: int, refills: int) -> String:
	if lowest >= _combat.max_health and refills == 0:
		return "sempre em %s" % whole(_combat.max_health)
	var back := "%s a %s" % [_counted(refills, "volta", "voltas"), whole(_combat.max_health)]
	return "a mínima em %s, e %s" % [whole(lowest), back]


func _press_lines(report: FighterReport) -> PackedStringArray:
	var out := PackedStringArray()
	out.append("  Os apertos, pelo modo em que o tick começou")
	for command: StringName in MOVEMENT_PRESSES:
		out.append("    %s: %s" % [_command_name(command), _presses_text(report, command)])
	return out


# "Para o pulo, o dash e o gancho": in each mode, the presses that fired at once, the ones that
# waited in the slot and the ones that never fired.
static func _presses_text(report: FighterReport, command: StringName) -> String:
	var total := 0
	var parts := PackedStringArray()
	for mode: int in MODES:
		var at_once := 0
		var waited := 0
		var never := 0
		for press: Press in report.presses:
			if press.command != command or press.mode != mode:
				continue
			if press.fired_tick < 0:
				never += 1
			elif press.fired_tick == press.tick:
				at_once += 1
			else:
				waited += 1
		var pressed := at_once + waited + never
		if pressed == 0:
			continue
		total += pressed
		parts.append(
			"%s %s: %s na hora, %s, %s"
			% [
				_mode_place(mode),
				whole(pressed),
				whole(at_once),
				_counted(waited, "esperou", "esperaram"),
				_counted(never, "não saiu", "não saíram"),
			]
		)
	if total == 0:
		return "nenhum aperto"
	return "%s; %s" % [_counted(total, "aperto", "apertos"), "; ".join(parts)]


func _move_lines(report: FighterReport, move: StringName) -> PackedStringArray:
	var out := PackedStringArray()
	var clicks: Array[Press] = []
	for press: Press in report.presses:
		if press.command == move:
			clicks.append(press)
	if clicks.is_empty():
		out.append("  %s: nenhum clique" % _move_name(move))
		return out
	out.append("  %s: %s" % [_move_name(move), _phases_text(move)])
	var swings: Array[Swing] = []
	for swing: Swing in report.swings:
		if swing.move == move:
			swings.append(swing)
	out.append("    %s" % _clicks_text(clicks, swings))
	var lost: Array[Press] = []
	for press: Press in clicks:
		if press.fired_tick < 0:
			lost.append(press)
	if not lost.is_empty():
		out.append("    %s" % _lost_text(lost))
		var in_swing := _in_swing_text(lost)
		if not in_swing.is_empty():
			out.append("    %s" % in_swing)
	if swings.is_empty():
		out.append("    Nenhum golpe saiu")
		return out
	out.append("    %s" % _results_text(swings, move))
	var misses := _misses_text(swings, move)
	if not misses.is_empty():
		out.append("    %s" % misses)
	out.append_array(_distance_lines(swings, move))
	var targets := _targets_text(swings)
	if not targets.is_empty():
		out.append("    %s" % targets)
	out.append("    %s" % _speed_text(report, move))
	return out


# "Leve: preparação 15 ticks (250 ms), ativo 6 ticks (100 ms), recuperação 12 ticks (200 ms)":
# the phases of the header, the ms back from the ticks.
func _phases_text(move: StringName) -> String:
	if not _combat.attacks.has(move):
		return "o cabeçalho não tem as fases dele"
	var attack: AttackConfig = _combat.attacks[move]
	return (
		"preparação %s, ativo %s, recuperação %s"
		% [
			_ticks_and_ms(attack.windup_ticks),
			_ticks_and_ms(attack.active_ticks),
			_ticks_and_ms(attack.recovery_ticks),
		]
	)


static func _clicks_text(clicks: Array[Press], swings: Array[Swing]) -> String:
	var waited := 0
	var chained := 0
	for swing: Swing in swings:
		waited += 1 if swing.fire_tick > swing.press_tick else 0
		chained += 1 if swing.chained else 0
	return (
		"Cliques: %s; golpes que saíram: %s, dos quais %s na vaga; %s no fim do anterior"
		% [
			whole(clicks.size()),
			whole(swings.size()),
			_counted(waited, "esperou", "esperaram"),
			_counted(chained, "emendado", "emendados"),
		]
	)


static func _lost_text(lost: Array[Press]) -> String:
	var parts := PackedStringArray()
	for reason: StringName in REASONS:
		var count := 0
		for press: Press in lost:
			count += 1 if press.reason == reason else 0
		if count > 0:
			parts.append(_reason_count(reason, count))
	return "Cliques que não saíram: %s: %s" % [whole(lost.size()), _listed(parts)]


# The clicks a swing held, by the phase of the swing they met, and the median of the ticks from
# that swing's fire to them (F-178 §1).
func _in_swing_text(lost: Array[Press]) -> String:
	var phases: Array[int] = [
		FighterState.Action.WINDUP,
		FighterState.Action.ACTIVE,
		FighterState.Action.RECOVERY,
	]
	var names: Array[String] = ["na preparação", "no ativo", "na recuperação"]
	var counts: Array[int] = [0, 0, 0]
	var held := 0
	var into := PackedFloat64Array()
	for press: Press in lost:
		if press.reason != SWING:
			continue
		held += 1
		var phase := phases.find(press.phase)
		if phase >= 0:
			counts[phase] += 1
		if press.into_swing >= 0:
			into.append(press.into_swing)
	if held == 0:
		return ""
	var parts := PackedStringArray()
	for index: int in phases.size():
		parts.append("%s %s" % [whole(counts[index]), names[index]])
	var text := "Durante um golpe: %s" % _listed(parts)
	if not into.is_empty():
		# ticks × 1000 ÷ ticks per second, to the nearest ms; a median between two ticks keeps its
		# half tick.
		var median := _median(into)
		var at := roundi(median * 1000.0 / _movement.tickrate)
		var ticks := whole(roundi(median)) if median == roundf(median) else decimal(median, 1)
		text += "; mediana de %s ticks (%s ms) depois do começo do golpe" % [ticks, whole(at)]
	return text


func _results_text(swings: Array[Swing], move: StringName) -> String:
	if _grabs(move):
		return _grab_results_text(swings)
	var parts := PackedStringArray()
	for result: StringName in RESULTS:
		var count := 0
		for swing: Swing in swings:
			count += 1 if swing.result == result else 0
		if count == 0:
			continue
		parts.append(_result_count(result, count))
	return "Resultado: %s" % _listed(parts)


# The guard break's result line ("O resultado"): "Resultado: 6 agarraram (4 com tech e 2 sem
# tech), 3 erros e 1 cortada", each part only when it happened, the grabs first.
static func _grab_results_text(swings: Array[Swing]) -> String:
	var counts: Dictionary[StringName, int] = { }
	for result: StringName in RESULTS:
		counts[result] = 0
	for swing: Swing in swings:
		if counts.has(swing.result):
			counts[swing.result] += 1
	var parts := PackedStringArray()
	var teched := counts[GRABBED_TECH]
	var untouched := counts[GRABBED_NO_TECH]
	if teched + untouched > 0:
		parts.append(
			"%s (%s com tech e %s sem tech)"
			% [
				_counted(teched + untouched, "agarrou", "agarraram"),
				whole(teched),
				whole(untouched),
			]
		)
	if counts[MISS] > 0:
		parts.append(_counted(counts[MISS], "erro", "erros"))
	if counts[CUT] > 0:
		parts.append(_counted(counts[CUT], "cortada", "cortadas"))
	if counts[UNFINISHED] > 0:
		parts.append(_counted(counts[UNFINISHED], "inacabada", "inacabadas"))
	return "Resultado: %s" % _listed(parts)


# The misses split by the shortest distance over the active against the move's reach of the
# header: "longe" beyond it, "ao alcance" not beyond it, and alone with nobody to measure to. Empty
# when no swing missed.
func _misses_text(swings: Array[Swing], move: StringName) -> String:
	var limit := reach_of(move)
	var far := PackedFloat64Array()
	var near := PackedFloat64Array()
	var alone := 0
	for swing: Swing in swings:
		if swing.result != MISS:
			continue
		if swing.nearest_distance < 0.0:
			alone += 1
		elif swing.nearest_distance <= limit:
			near.append(swing.nearest_distance)
		else:
			far.append(swing.nearest_distance)
	if far.is_empty() and near.is_empty() and alone == 0:
		return ""
	var parts := PackedStringArray()
	if not far.is_empty():
		parts.append("%s longe, %s" % [whole(far.size()), _span(far)])
	if not near.is_empty():
		parts.append("%s ao alcance, %s" % [whole(near.size()), _span(near)])
	if alone > 0:
		parts.append("%s sem outro lutador" % whole(alone))
	return (
		"Os erros, pela distância mais curta no ativo, contra o alcance de %s m: %s"
		% [decimal(limit, 2), "; ".join(parts)]
	)


# "a 2,24 m" for one distance, "de 2,51 a 7,10 m" for several.
static func _span(metres: PackedFloat64Array) -> String:
	var sorted := metres.duplicate()
	sorted.sort()
	var low := decimal(sorted[0], 2)
	var high := decimal(sorted[sorted.size() - 1], 2)
	if low == high:
		return "a %s m" % low
	return "de %s a %s m" % [low, high]


# The distances on the first active tick: from how near to how far the swings that landed were,
# and the nearest of all; each miss within reach with its tick and its three numbers; and the
# crosshair on average over the swings that landed. A swing landed ("pegou") when it had a
# contact: a hit, a block or a parry ("O resultado": "houve contato"); a guard break, when it
# grabbed ("na quebra, as que agarraram").
func _distance_lines(swings: Array[Swing], move: StringName) -> PackedStringArray:
	var out := PackedStringArray()
	var grabs := _grabs(move)
	var limit := reach_of(move)
	var landed := PackedFloat64Array()
	var crosshairs := PackedFloat64Array()
	var nearest := -1.0
	var near_misses: Array[Swing] = []
	for swing: Swing in swings:
		if swing.first_active_distance < 0.0:
			continue
		if nearest < 0.0 or swing.first_active_distance < nearest:
			nearest = swing.first_active_distance
		if swing.target >= 0:
			landed.append(swing.first_active_distance)
			crosshairs.append(swing.crosshair)
		if swing.result == MISS and swing.nearest_distance <= limit:
			near_misses.append(swing)
	if nearest < 0.0:
		return out
	var span := "nenhuma agarrou" if grabs else "nenhum pegou"
	if not landed.is_empty():
		landed.sort()
		var which := "as que agarraram" if grabs else "os que pegaram (acerto, bloqueio ou aparo)"
		span = (
			"%s, de %s a %s m"
			% [which, decimal(landed[0], 2), decimal(landed[landed.size() - 1], 2)]
		)
	out.append(
		"    No primeiro tick ativo: %s; o mais perto de todos, %s m" % [span, decimal(nearest, 2)]
	)
	if not near_misses.is_empty():
		out.append("    Erros ao alcance, no primeiro tick ativo (a distância, o corte e a mira):")
		for swing: Swing in near_misses:
			out.append(
				"      tick %s (%s): %s m; %s; %s"
				% [
					whole(swing.active_tick),
					duration(swing.active_tick, _movement.tickrate),
					decimal(swing.first_active_distance, 2),
					_side_text(swing.side),
					_crosshair_text(swing.crosshair, "dele"),
				]
			)
	if not crosshairs.is_empty():
		var sum := 0.0
		for value: float in crosshairs:
			sum += value
		var mean := sum / crosshairs.size()
		var those := "Nas que agarraram" if grabs else "Nos que pegaram"
		out.append("    %s, em média, %s" % [those, _crosshair_text(mean, "do alvo")])
	return out


# "O agarrão": "Agarrado: nenhuma vez"; "Agarrado: 1 vez; o tech em 0 (0 %)"; with a tech or more,
# the median of the ticks from the contact to the tech's press, the first press of the guard break
# after the contact and up to the last held tick, and its ms: "Agarrado: 6 vezes; o tech em 4
# (67 %); o aperto do tech, em mediana, 15 ticks (250 ms) depois do contato". The rate rounds like
# the share of the speed's ticks.
func _grabbed_text(report: FighterReport) -> String:
	var grabs := report.grabs.size()
	if grabs == 0:
		return "Agarrado: nenhuma vez"
	var techs := 0
	var presses := PackedFloat64Array()
	for grab: Grab in report.grabs:
		if not grab.teched:
			continue
		techs += 1
		if grab.press_tick >= 0:
			presses.append(grab.press_tick - grab.contact)
	var text := (
		"Agarrado: %s; o tech em %s (%d %%)"
		% [_counted(grabs, "vez", "vezes"), whole(techs), roundi(100.0 * techs / grabs)]
	)
	if presses.is_empty():
		return text
	# ticks × 1000 ÷ ticks per second, to the nearest ms; a median between two ticks keeps its half.
	var median := _median(presses)
	var at := roundi(median * 1000.0 / _movement.tickrate)
	var ticks := whole(roundi(median)) if median == roundf(median) else decimal(median, 1)
	return (
		"%s; o aperto do tech, em mediana, %s ticks (%s ms) depois do contato"
		% [text, ticks, whole(at)]
	)


static func _side_text(side: float) -> String:
	var shown := decimal(absf(side), 2)
	if shown == "0,00":
		return "o outro em cima do corte"
	var where := "à direita" if side > 0.0 else "à esquerda"
	return "o outro %s m %s do corte" % [shown, where]


static func _crosshair_text(crosshair: float, of_whom: String) -> String:
	var shown := decimal(absf(crosshair), 2)
	if shown == "0,00":
		return "a mira em cima %s" % of_whom
	var where := "à direita" if crosshair > 0.0 else "à esquerda"
	return "a mira %s m %s %s" % [shown, where, of_whom]


# "A vida do alvo": the lowest health of each fighter the move hit, and its returns to the max.
func _targets_text(swings: Array[Swing]) -> String:
	var targets: Array[int] = []
	for swing: Swing in swings:
		if swing.result == HIT and not targets.has(swing.target):
			targets.append(swing.target)
	if targets.is_empty():
		return ""
	targets.sort()
	var parts := PackedStringArray()
	for target: int in targets:
		var report := _reports[target]
		parts.append(
			"o lutador %d, %s" % [target, _health_text(report.lowest_health, report.refills)]
		)
	return "A vida do alvo: %s" % "; ".join(parts)


# "A velocidade no golpe": the median, the highest and the share of the ticks above the slow walk
# of the header (DEC-0052).
func _speed_text(report: FighterReport, move: StringName) -> String:
	var speeds: PackedFloat64Array = report.swing_speeds.get(move, PackedFloat64Array())
	if speeds.is_empty():
		return "A velocidade em pé no golpe: nenhum tick em pé"
	var highest := 0.0
	var above := 0
	for speed: float in speeds:
		highest = maxf(highest, speed)
		above += 1 if speed > _movement.slow_walk_speed + SPEED_HAIR else 0
	return (
		"A velocidade em pé no golpe: mediana %s m/s, máxima %s m/s; %d %% dos %s acima de %s m/s"
		% [
			decimal(_median(speeds), 2),
			decimal(highest, 2),
			roundi(100.0 * above / speeds.size()),
			_counted(speeds.size(), "tick", "ticks"),
			_short(_movement.slow_walk_speed),
		]
	)

# --- Words and numbers ---


func _time(ticks: int) -> String:
	return duration(ticks, _movement.tickrate)


# "aos 3 min 56 s (tick 14.160)": a tick counted from the first, as a time and as itself.
func _moment(tick: int) -> String:
	return "aos %s (tick %s)" % [duration(tick, _movement.tickrate), whole(tick)]


# A flight's time, with one decimal: "7,6 s", "1 min 3,4 s".
func _tenths(ticks: int) -> String:
	var seconds := float(ticks) / _movement.tickrate
	if seconds < 60.0:
		return "%s s" % decimal(seconds, 1)
	var minutes := floori(seconds / 60.0)
	return "%s min %s s" % [whole(minutes), decimal(seconds - 60.0 * minutes, 1)]


func _ticks_and_ms(ticks: int) -> String:
	return "%s (%s ms)" % [_counted(ticks, "tick", "ticks"), whole(ms(ticks, _movement.tickrate))]


# A number without decimals when it is whole, with two otherwise: 3, 2,43.
static func _short(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return whole(roundi(value))
	return decimal(value, 2)


static func _median(values: PackedFloat64Array) -> float:
	var sorted := values.duplicate()
	sorted.sort()
	var middle := sorted.size() / 2.0
	if sorted.size() % 2 == 1:
		return sorted[floori(middle)]
	return (sorted[floori(middle) - 1] + sorted[floori(middle)]) / 2.0


static func _counted(count: int, one: String, many: String) -> String:
	return "%s %s" % [whole(count), one if count == 1 else many]


# "a, b e c".
static func _listed(parts: PackedStringArray) -> String:
	if parts.size() <= 1:
		return "".join(parts)
	return "%s e %s" % [", ".join(parts.slice(0, parts.size() - 1)), parts[parts.size() - 1]]


static func _mode_name(mode: int) -> String:
	match mode:
		FighterState.Mode.GROUND:
			return "chão"
		FighterState.Mode.AIR:
			return "ar"
		FighterState.Mode.WALL_RUN:
			return "parede"
		FighterState.Mode.GRAPPLE:
			return "gancho"
		FighterState.Mode.DASH:
			return "dash"
	return "modo %d" % mode


static func _mode_place(mode: int) -> String:
	match mode:
		FighterState.Mode.GROUND:
			return "no chão"
		FighterState.Mode.AIR:
			return "no ar"
		FighterState.Mode.WALL_RUN:
			return "na parede"
		FighterState.Mode.GRAPPLE:
			return "no gancho"
		FighterState.Mode.DASH:
			return "no dash"
	return "no modo %d" % mode


static func _command_name(command: StringName) -> String:
	match command:
		FighterCommand.JUMP:
			return "Pulo"
		FighterCommand.DASH:
			return "Dash"
		FighterCommand.GRAPPLE:
			return "Gancho"
	return String(command)


static func _move_name(move: StringName) -> String:
	match move:
		FighterCommand.LIGHT_ATTACK:
			return "Leve"
		FighterCommand.CHARGED_ATTACK:
			return "Carregado"
		FighterCommand.GUARD_BREAK:
			return "Quebra"
	return String(move)


static func _maneuver_count(maneuver: StringName, count: int) -> String:
	match maneuver:
		JUMP:
			return _counted(count, "pulo", "pulos")
		DOUBLE_JUMP:
			return _counted(count, "pulo duplo", "pulos duplos")
		WALL_RUN:
			return _counted(count, "corrida na parede", "corridas na parede")
		WALL_JUMP:
			return _counted(count, "pulo da parede", "pulos da parede")
		DASH:
			return _counted(count, "dash", "dashes")
		GRAPPLE:
			return _counted(count, "gancho", "ganchos")
		HEAD_LANDING:
			return _counted(count, "pouso na cabeça", "pousos na cabeça")
	return _counted(count, String(maneuver), String(maneuver))


static func _maneuver_one(maneuver: StringName) -> String:
	match maneuver:
		JUMP:
			return "um pulo"
		DOUBLE_JUMP:
			return "um pulo duplo"
		WALL_RUN:
			return "uma corrida na parede"
		WALL_JUMP:
			return "um pulo da parede"
		DASH:
			return "um dash"
		GRAPPLE:
			return "um gancho"
		HEAD_LANDING:
			return "um pouso na cabeça"
	return String(maneuver)


static func _reason_count(reason: StringName, count: int) -> String:
	match reason:
		SAME_TICK:
			return _counted(count, "trocado no mesmo tick", "trocados no mesmo tick")
		SWING:
			return "%s durante um golpe" % whole(count)
		STUN:
			return "%s no tranco" % whole(count)
		IN_GRAB:
			return "%s no agarrão" % whole(count)
		STANCE:
			return "%s na postura" % whole(count)
		OFF_FLOOR:
			return "%s fora do chão" % whole(count)
		NO_STAMINA:
			return "%s sem stamina" % whole(count)
	return "%s por outro motivo" % whole(count)


static func _result_count(result: StringName, count: int) -> String:
	match result:
		HIT:
			return _counted(count, "acerto", "acertos")
		BLOCKED:
			return _counted(count, "bloqueado", "bloqueados")
		PARRIED:
			return _counted(count, "aparado", "aparados")
		GRABBED_TECH:
			return "%s com tech" % _counted(count, "agarrou", "agarraram")
		GRABBED_NO_TECH, GRABBED:
			return "%s sem tech" % _counted(count, "agarrou", "agarraram")
		MISS:
			return _counted(count, "erro", "erros")
		CUT:
			return _counted(count, "cortado", "cortados")
	return _counted(count, "inacabado", "inacabados")
