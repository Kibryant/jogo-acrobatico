# A bot that plays a fighter on this PC instead of the keyboard and the mouse (TASK-9, part 2): the
# test player of the network runs, launched with --bot, not the game's bots of later phases, which
# run on the server (DEC-0022). It only produces input, through the two calls the devices use too
# (FighterInput.sample_frame and press_jump), and never writes state: what it presses comes from
# its BotRoute, counted from the tick it began. It reads neither the keyboard nor the mouse, so a
# player can use another window beside its own.
class_name BotPlayer
extends Node

## What it presses, step by step.
var route: BotRoute
## The tick of the route's step 0.
var start_tick: int
## The input box it fills.
var input: FighterInput

# rad: where it looks, the yaw of its spawn point, toward the other one.
var _yaw: float


func _init(fighter_input: FighterInput, bot_route: BotRoute, first_tick: int, yaw: float) -> void:
	name = "BotPlayer"
	input = fighter_input
	route = bot_route
	start_tick = first_tick
	_yaw = yaw


func _enter_tree() -> void:
	NetworkTime.before_tick.connect(_press_on_its_tick)
	NetworkTime.after_tick_loop.connect(_push_for_the_next_loop)


func _exit_tree() -> void:
	NetworkTime.before_tick.disconnect(_press_on_its_tick)
	NetworkTime.after_tick_loop.disconnect(_push_for_the_next_loop)


func _ready() -> void:
	_push_for_the_next_loop()


# netfox gathers the input once per tick loop, before its ticks (rede.md §2), so every tick of a
# loop takes the move of the loop's first tick, as with the keyboard. Right after a loop, the
# clock's tick is the next loop's first one, and the bot pushes the route's move for it.
func _push_for_the_next_loop() -> void:
	input.sample_frame(route.move_at(NetworkTime.tick - start_tick), _yaw)


# The jump is a one-touch command (DEC-0026 §1): pressed right before its own tick, it counts on
# that tick only, even in a loop of several ticks, since FighterInput takes it after the tick.
func _press_on_its_tick(_delta: float, tick: int) -> void:
	if route.jumps_at(tick - start_tick):
		input.press_jump()
