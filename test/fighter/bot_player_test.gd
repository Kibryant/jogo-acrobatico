# TASK-9, round C2: the bot plays its fighter through the input box only (DEC-0022), tick by tick
# as its route says, and leaves the keyboard and the mouse alone; two bots at the arena's spawn
# points play their routes without touching each other or anything but the floor (criterion 12:
# "sem se encostar"). The real Match runs in Sozinho, Godot's offline peer, with netfox's ticks
# advanced by hand (test/support/netfox_ticks.gd; DEC-0027 §3).
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const MATCH_SCENE := preload("res://match/match.tscn")

## m: a hair, far below the SyncTest's 1 mm (rede.md §4).
const HAIR := 1e-4
## The legs the two bots run: after the first one the route repeats every two legs, one each way
## from full speed, so three reach both ends of where it goes.
const LEGS := 3


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	Input.action_release(&"move_forward")
	NetfoxTicks.reset()


# A match in the tree with a fighter at each of the first count spawn points, with netfox's deferred
# setup done; the ticks then run inside a physics frame (test/support/netfox_ticks.gd).
func _match_with_fighters(count: int) -> Match:
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	var game_match: Match = auto_free(node)
	add_child(game_match)
	for slot: int in count:
		game_match.spawn_fighter(slot, multiplayer.get_unique_id())
	await get_tree().process_frame
	await get_tree().physics_frame
	return game_match


# The keys held and pressed on the bot's window reach nothing: every tick takes the route's move,
# the move of its loop's first tick, as netfox gathers once per loop, and the route's jump on its
# own tick, even inside a loop of two ticks.
func test_the_bot_fills_the_input_tick_by_tick_and_leaves_the_keyboard_alone() -> void:
	var game_match := await _match_with_fighters(1)
	var fighter := game_match.fighters[0]
	var bot := game_match.let_bot_play(fighter)
	assert_object(game_match.bot).is_same(bot)
	assert_bool(game_match.camera_rig.takes_mouse).is_false()
	Input.action_press(&"move_forward")
	var space := InputEventKey.new()
	space.physical_keycode = KEY_SPACE
	space.pressed = true
	Input.parse_input_event(space)
	await get_tree().process_frame
	await get_tree().physics_frame

	var leg := bot.route.leg_ticks
	var seen := InputLog.new(fighter.input)
	NetworkTime.after_tick.connect(seen.note)
	# One tick per loop up to the last tick of the first leg, then one loop of two ticks that runs
	# it and the first tick of the second leg, then one tick per loop again.
	for _loop: int in leg - 1:
		seen.loop_starts(NetworkTime.tick)
		NetfoxTicks.run_loop()
		if NetworkTime.tick - bot.start_tick == 2:
			assert_int(fighter.state.jumps_used).is_equal(1) # the jump of step 0
	seen.loop_starts(NetworkTime.tick)
	NetfoxTicks.run_loop(2)
	assert_int(fighter.state.jumps_used).is_equal(1) # the jump of step leg, in the loop of two
	assert_int(fighter.state.mode).is_equal(FighterState.Mode.AIR)
	for _loop: int in 3:
		seen.loop_starts(NetworkTime.tick)
		NetfoxTicks.run_loop()
	NetworkTime.after_tick.disconnect(seen.note)

	var wrong: Array[String] = []
	for tick: int in seen.moves:
		var step := tick - bot.start_tick
		var loop_step := seen.loop_first[tick] - bot.start_tick
		if seen.moves[tick] != bot.route.move_at(loop_step):
			wrong.append("step %d: move %s" % [step, seen.moves[tick]])
		if seen.jumps[tick] != bot.route.jumps_at(step):
			wrong.append("step %d: jump %s" % [step, seen.jumps[tick]])
	assert_int(seen.moves.size()).is_equal(leg + 4)
	assert_array(wrong).is_empty()


# Each bot runs along its own line, the one through its spawn point across the line between the
# two, so they stay 10 m apart; each jumps once per leg, and the only thing either one touches is
# the floor.
func test_two_bots_play_their_routes_without_touching_anything_but_the_floor() -> void:
	var game_match := await _match_with_fighters(2)
	var first := game_match.fighters[0]
	var second := game_match.fighters[1]
	game_match.let_bot_play(first)
	var second_first_tick: int = second.synchronizer.spawn_tick
	var other_bot := BotPlayer.new(
		second.input,
		BotRoute.new(game_match.config.tickrate),
		second_first_tick,
		second.state.facing_yaw,
	)
	game_match.add_child(other_bot)
	var floor_body := game_match.arena.get_node(^"Floor")
	var lines: Array[float] = [first.position.z, second.position.z]
	var takeoffs: Array[int] = [0, 0]
	var was_on_floor: Array[bool] = [true, true]
	var closest := INF
	var wrong: Array[String] = []
	for step: int in LEGS * other_bot.route.leg_ticks:
		NetfoxTicks.run_loop()
		var gap := second.position - first.position
		closest = minf(closest, Vector2(gap.x, gap.z).length())
		for index: int in 2:
			var fighter := game_match.fighters[index]
			if absf(fighter.position.z - lines[index]) > HAIR:
				wrong.append(
					"step %d: %s left its line, at %s" % [step, fighter.name, fighter.position]
				)
			if was_on_floor[index] and not fighter.state.on_floor:
				takeoffs[index] += 1
			was_on_floor[index] = fighter.state.on_floor
			for slide: int in fighter.get_slide_collision_count():
				var collider := fighter.get_slide_collision(slide).get_collider()
				if collider != floor_body:
					wrong.append("step %d: %s touched %s" % [step, fighter.name, collider])
	print("Two bots, %d legs: closest approach %.3f m" % [LEGS, closest])
	assert_array(wrong).is_empty()
	assert_int(takeoffs[0]).is_equal(LEGS)
	assert_int(takeoffs[1]).is_equal(LEGS)
	assert_float(closest).is_greater(2.0 * game_match.config.capsule_radius)


# What FighterInput holds after each tick, by tick: netfox records it right after
# (NetworkTime._loop), so these are the inputs of the ticks. It also keeps, for each tick, the
# first tick of its loop.
class InputLog:
	var moves: Dictionary[int, Vector2] = { }
	var jumps: Dictionary[int, bool] = { }
	var loop_first: Dictionary[int, int] = { }

	var _input: FighterInput
	var _first := 0


	func _init(input: FighterInput) -> void:
		_input = input


	func loop_starts(tick: int) -> void:
		_first = tick


	func note(_delta: float, tick: int) -> void:
		moves[tick] = _input.move
		jumps[tick] = _input.jump
		loop_first[tick] = _first
