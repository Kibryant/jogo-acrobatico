# The route of the bot that plays a client in the network runs (TASK-9, "Números v0 do Claude";
# rede.md §10): it runs and jumps every 2 s, like the bots of the Desenho 3 measurements
# (netfox-sonda, probe_input.gd, "wander"). The two spawn points face each other 10 m apart, so a
# bot that ran forward would meet the other one: it runs sideways instead, along its own line, to
# its right for one leg and to its left for the next, jumps as each leg begins and dashes along
# its line in the middle of each leg (TASK-10.4: "o bot dando um dash no meio de cada perna").
# Pure: what it presses is a function of the steps since the route began, its first tick being
# step 0, so a test covers every tick, and the same steps give the same presses on any PC.
class_name BotRoute
extends RefCounted

## ms: one leg of the route, which is also the time between two jumps (TASK-9, "Números v0 do
## Claude": "corre e pula a cada 2 s").
const LEG_MS := 2000

## ms into each leg when the bot dashes, at full speed on the floor: the jump of the leg's start
## is over in 630 ms (movimento.md, "Pulo e ar"), and the dash and its cooldown, 600 ms, end
## before the next leg (TASK-10.4, "SyncTest": "1000 ms into each leg").
const DASH_AT_MS := 1000

## The ticks of one leg at the match's tickrate.
var leg_ticks: int
## The ticks into each leg of its dash.
var dash_at_ticks: int


func _init(tickrate: int) -> void:
	leg_ticks = Ticks.from_ms(LEG_MS, tickrate)
	dash_at_ticks = Ticks.from_ms(DASH_AT_MS, tickrate)


# Where the bot pushes on the step-th tick of its route, as TickInput.move (x right, y forward):
# fully to its right on the even legs and to its left on the odd ones, never forward or back.
# Before the route begins, at a negative step, it pushes nothing.
func move_at(step: int) -> Vector2:
	if step < 0:
		return Vector2.ZERO
	if posmod(step, 2 * leg_ticks) < leg_ticks:
		return Vector2.RIGHT
	return Vector2.LEFT


# True on the first tick of each leg: the bot jumps as it turns. It stands on the floor then,
# since a jump is over in 630 ms (movimento.md, "Pulo e ar"), so the press is never wasted.
func jumps_at(step: int) -> bool:
	return step >= 0 and posmod(step, leg_ticks) == 0


# True on the tick of each leg's dash: the dash goes where the bot runs, along its line, and the
# body is on the floor then, with the bar full again since the last one (movimento.md, "Dash").
func dashes_at(step: int) -> bool:
	return step >= 0 and posmod(step, leg_ticks) == dash_at_ticks
