# Criterion 12 of TASK-9: whether the server confirmed what a client predicted for its own fighter
# (DEC-0026 §2; rede.md §5). For each tick both computed, the client's first result is held
# against the server's last one with the SyncTest's tolerance (rede.md §4): the position within
# 1 mm, on_floor and mode equal. A tick that differs is one the server corrected: the player saw
# the fighter in one place, and then the rollback moved it to another.
# Every tick from the client's first to its last counts; none is left out as a warm-up.
class_name PredictionCheck
extends RefCounted

## m: the SyncTest's tolerance (rede.md §4).
const TOLERANCE := 0.001
## How many corrected or missing ticks the summary describes.
const SHOWN := 5

## The client's fighter, by node name.
var fighter := ""
## The ticks both sides computed, and how many of them the server corrected.
var checked := 0
var corrected := 0
## The first and last tick the client predicted.
var first_tick := -1
var last_tick := -1
## The ticks the client predicted after the server's last confirmation: the session ended before
## their input reached the server.
var unconfirmed := 0
## The ticks inside the run that one side lacks: a hole in the client's ticks, a tick the server
## never confirmed before its last confirmation, or a tick it confirmed that the client never
## predicted.
var missing := 0
## The first corrected and missing ticks, one line each.
var shown: Array[String] = []
## What keeps the two records from being compared at all.
var problems: Array[String] = []


# The check of a client's record, prediction, against the server's, confirmation.
static func compare(prediction: TickRecord, confirmation: TickRecord) -> PredictionCheck:
	return PredictionCheck.new(prediction, confirmation)


func _init(prediction: TickRecord, confirmation: TickRecord) -> void:
	for error: String in prediction.errors:
		problems.append("the client's record: %s" % error)
	for error: String in confirmation.errors:
		problems.append("the server's record: %s" % error)
	var own := prediction.fighters()
	if own.size() != 1:
		problems.append("the client's record holds %d fighters, not 1: %s" % [own.size(), own])
		return
	fighter = own[0]
	var predicted := prediction.ticks_of(fighter)
	var confirmed := confirmation.ticks_of(fighter)
	if confirmed.is_empty():
		problems.append("the server's record has no %s" % fighter)
		return
	first_tick = predicted[0]
	last_tick = predicted[predicted.size() - 1]
	var last_confirmed := confirmed[confirmed.size() - 1]
	for tick: int in range(first_tick, last_tick + 1):
		var mine := prediction.sample_at(fighter, tick)
		var theirs := confirmation.sample_at(fighter, tick)
		if mine == null:
			_miss(tick, "the client has no state")
		elif theirs == null and tick > last_confirmed:
			unconfirmed += 1
		elif theirs == null:
			_miss(tick, "the server never confirmed it")
		else:
			checked += 1
			if not same(mine, theirs):
				corrected += 1
				_show(_describe_correction(tick, mine, theirs))
	for tick: int in confirmed:
		if tick < first_tick or tick > last_tick:
			_miss(tick, "the server confirmed a tick the client never predicted")


# The SyncTest's verdict (rede.md §4): the same position within 1 mm, the same floor and mode.
static func same(first: TickRecord.Sample, second: TickRecord.Sample) -> bool:
	var close := first.position.distance_to(second.position) <= TOLERANCE
	return close and first.on_floor == second.on_floor and first.mode == second.mode


# True when the records compare, no tick was corrected or missing, and at least min_checked
# ticks were checked.
func passed(min_checked: int) -> bool:
	return problems.is_empty() and corrected == 0 and missing == 0 and checked >= min_checked


# One paragraph: the totals, then the first corrected and missing ticks.
func summary(tickrate: int) -> String:
	if not problems.is_empty():
		return "cannot compare: %s" % "; ".join(problems)
	var lines := PackedStringArray(
		[
			(
				"%s: %d ticks checked (%.1f s, ticks %d to %d), %d corrected,"
				+ " %d unconfirmed at the end, %d missing"
			)
			% [
				fighter,
				checked,
				float(checked) / tickrate,
				first_tick,
				last_tick,
				corrected,
				unconfirmed,
				missing,
			],
		],
	)
	for line: String in shown:
		lines.append("  " + line)
	return "\n".join(lines)


static func _describe_correction(
	tick: int,
	mine: TickRecord.Sample,
	theirs: TickRecord.Sample,
) -> String:
	return (
		"tick %d corrected: predicted %s on_floor=%s mode=%d, confirmed %s on_floor=%s mode=%d,"
		+ " %.6f m apart"
	) % [
		tick,
		mine.position,
		mine.on_floor,
		mine.mode,
		theirs.position,
		theirs.on_floor,
		theirs.mode,
		mine.position.distance_to(theirs.position),
	]


func _miss(tick: int, why: String) -> void:
	missing += 1
	_show("tick %d missing: %s" % [tick, why])


func _show(line: String) -> void:
	if shown.size() < SHOWN:
		shown.append(line)
