# The route of the bot that plays a client in the network runs (TASK-9, "Números v0 do Claude";
# rede.md §10): it runs and jumps every 2 s, like the bots of the Desenho 3 measurements
# (netfox-sonda, probe_input.gd, "wander"). The two spawn points face each other 10 m apart, so a
# bot that ran forward would meet the other one: it runs sideways instead, along its own line, to
# its right for one leg and to its left for the next, jumps as each leg begins, double jumps at
# the top of that jump (TASK-10.8; F-165) and dashes along its line once it is back on the floor
# (TASK-10.4: "o bot dando um dash no meio de cada perna").
# Pure: what it presses is a function of the steps since the route began, its first tick being
# step 0, so a test covers every tick, and the same steps give the same presses on any PC.
class_name BotRoute
extends RefCounted

## ms: one leg of the route, which is also the time between two jumps (TASK-9, "Números v0 do
## Claude": "corre e pula a cada 2 s").
const LEG_MS := 2000

## ms into each leg when the bot double jumps: the top of the leg's jump, its 350 ms of rise
## (movimento.md, "Pulo e ar": "Tempo de subida"; F-165: "no topo do pulo de cada perna").
const DOUBLE_JUMP_AT_MS := 350

## ms into each leg when the bot dashes, on the floor. With the double jump the flight lasts longer
## than the jump's 630 ms (movimento.md, "Pulo e ar"): measured in the engine at 60 ticks, it lands
## on step 63 of the leg, 1050 ms in, so the first tick that starts on the floor is 1067 ms in, and
## the dash of 1000 ms would be pressed in the air; the core lands it on step 31 at 30 ticks, and
## its first tick on the floor is 1067 ms in too.
## The dash and its cooldown take 600 ms (movimento.md, "Dash"), so a dash pressed by 1400 ms ends
## them before the next leg. 1200 ms sits in that window with 133 ms on the floor before it, room
## for a double jump the bar delays (the press waits in the buffer, "Stamina"), and both end by
## 1800 ms. The bar cannot pay 25 points every 2 s: from the seventh leg on, one leg in three goes
## without its dash (rede.md §10).
const DASH_AT_MS := 1200

## The ticks of one leg at the match's tickrate.
var leg_ticks: int
## The ticks into each leg of its double jump.
var double_jump_at_ticks: int
## The ticks into each leg of its dash.
var dash_at_ticks: int


func _init(tickrate: int) -> void:
	leg_ticks = Ticks.from_ms(LEG_MS, tickrate)
	double_jump_at_ticks = Ticks.from_ms(DOUBLE_JUMP_AT_MS, tickrate)
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
# since the flight with its double jump is over by the dash (DASH_AT_MS), so the press is never
# wasted.
func jumps_at(step: int) -> bool:
	return step >= 0 and posmod(step, leg_ticks) == 0


# True on the tick of each leg's double jump, the jump's second press: the body is at the top of
# the leg's jump, in the air with its double jump unspent (movimento.md, "Pulo e ar": "Pulo
# duplo"), and it goes on along the bot's line, where the bot pushes.
func double_jumps_at(step: int) -> bool:
	return step >= 0 and posmod(step, leg_ticks) == double_jump_at_ticks


# True on the tick of each leg's dash: the dash goes where the bot runs, along its line, and the
# body is on the floor then (movimento.md, "Dash").
func dashes_at(step: int) -> bool:
	return step >= 0 and posmod(step, leg_ticks) == dash_at_ticks
