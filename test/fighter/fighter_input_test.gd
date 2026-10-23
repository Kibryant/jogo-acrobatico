# Criterion 7 of TASK-9, through netfox's real tick loop: the frames' samples become the input
# netfox records for each tick (DEC-0026 §1), and a jump press counts for at most one tick, even
# when a frame runs two ticks to catch the clock. Ticks run by hand (DEC-0027 §3), in Sozinho.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const MATCH_SCENE := preload("res://match/match.tscn")

const HAIR := 1e-9 # floating-point slack, not a design number
const FORWARD := Vector2(0, 1)

var _game_match: Match


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	NetfoxTicks.reset()


func _fighter_in_a_match() -> Fighter:
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	_game_match = auto_free(node)
	add_child(_game_match)
	var fighter := _game_match.spawn_fighter(0, multiplayer.get_unique_id())
	# netfox's deferred setup, then ticks inside a physics frame (test/support/netfox_ticks.gd).
	await get_tree().process_frame
	await get_tree().physics_frame
	return fighter


# The fighter this PC plays: the match puts its camera on it and the keyboard on its input
# (Match.watch), which is what makes FighterInput read the devices. Still inside the physics frame.
func _fighter_at_the_keyboard() -> Fighter:
	var fighter := await _fighter_in_a_match()
	_game_match.watch(fighter)
	return fighter


# The jump key as the operating system reports it: the InputMap's jump action is the physical
# space key, keycode 32 (project.godot, [input]); echo marks the key repeat of a held key.
static func _jump_key(echo: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_SPACE
	event.pressed = true
	event.echo = echo
	return event


# DEC-0040: netfox ticks in the physics step, so the keyboard is read in the physics step before
# netfox's own (review of the sync_to_physics change): the keys of a step count in its tick.
func test_the_keyboard_is_read_in_the_physics_step_before_netfox_ticks() -> void:
	var fighter := await _fighter_at_the_keyboard()
	var input := fighter.input
	assert_bool(input.is_physics_processing()).is_true()
	assert_int(input.process_physics_priority).is_less(NetworkTime.process_physics_priority)


func test_the_tick_input_is_the_mean_move_and_the_last_yaw_of_the_frames() -> void:
	var fighter := await _fighter_in_a_match()
	fighter.input.sample_frame(FORWARD, 0.25)
	fighter.input.sample_frame(Vector2.ZERO, 0.5)
	NetfoxTicks.run_loop()
	var tick_input := fighter.input.to_tick_input()
	assert_vector(tick_input.move).is_equal_approx(Vector2(0, 0.5), Vector2.ONE * HAIR)
	assert_float(tick_input.yaw).is_equal_approx(0.5, HAIR)
	assert_bool(tick_input.jump).is_false()
	# The body looks where the camera looked last (movimento.md, "Princípios").
	assert_float(fighter.state.facing_yaw).is_equal_approx(0.5, HAIR)


# Pressed once, the jump leaves the floor on the first tick of the frame, and the second tick of
# the same frame finds it taken: a press left over there would take the slot of the buffer as a
# new one and fire the double jump (Movement.before_move; DEC-0039).
func test_a_jump_press_counts_for_one_tick_when_a_frame_runs_two() -> void:
	var fighter := await _fighter_in_a_match()
	NetfoxTicks.run_loops(3)
	fighter.input.press_jump()
	NetfoxTicks.run_loop(2)
	assert_int(fighter.state.jumps_used).is_equal(1)
	assert_int(fighter.state.mode).is_equal(FighterState.Mode.AIR)
	assert_str(String(fighter.state.buffered_command)).is_equal(String(FighterCommand.NONE))
	assert_int(fighter.state.buffered_tick).is_equal(FighterState.NEVER)
	assert_float(fighter.position.y).is_greater(0.0)


func test_a_jump_press_counts_for_one_tick_in_frames_of_one_tick() -> void:
	var fighter := await _fighter_in_a_match()
	NetfoxTicks.run_loops(3)
	fighter.input.press_jump()
	NetfoxTicks.run_loop()
	assert_int(fighter.state.jumps_used).is_equal(1)
	NetfoxTicks.run_loop()
	assert_str(String(fighter.state.buffered_command)).is_equal(String(FighterCommand.NONE))
	assert_int(fighter.state.buffered_tick).is_equal(FighterState.NEVER)
	assert_bool(fighter.input.to_tick_input().jump).is_false()


# Holding the jump key is one press (F-102 §1): the operating system repeats a held key as
# InputEventKey events with echo = true, and those echoes are not new presses, so a press followed
# by its echoes is one jump and no double jump. The events go through the viewport, the way the
# window delivers them; a second real press in the air is the double jump (movimento.md, "Pulo e
# ar"), which proves the path reaches the fighter and only the echo is ignored.
func test_the_key_repeat_of_a_held_jump_key_is_not_a_second_press() -> void:
	var fighter := await _fighter_at_the_keyboard()
	NetfoxTicks.run_loops(3)
	get_viewport().push_input(_jump_key(false))
	NetfoxTicks.run_loop()
	assert_int(fighter.state.jumps_used) \
			.override_failure_message("the press through the viewport did not jump") \
			.is_equal(1)
	for _echo: int in 5:
		get_viewport().push_input(_jump_key(true))
		NetfoxTicks.run_loop()
	assert_int(fighter.state.jumps_used) \
			.override_failure_message("a key repeat counted as a second press") \
			.is_equal(1)
	assert_int(fighter.state.double_jump_tick).is_equal(FighterState.NEVER)
	assert_str(String(fighter.state.buffered_command)).is_equal(String(FighterCommand.NONE))
	assert_int(fighter.state.buffered_tick).is_equal(FighterState.NEVER)
	assert_bool(fighter.input.to_tick_input().jump).is_false()
	get_viewport().push_input(_jump_key(false))
	NetfoxTicks.run_loop()
	assert_int(fighter.state.jumps_used) \
			.override_failure_message("a second real press in the air must be the double jump") \
			.is_equal(2)


# No press, no jump: the fighter stays on the floor through frames of two ticks.
func test_without_a_press_the_fighter_never_jumps() -> void:
	var fighter := await _fighter_in_a_match()
	NetfoxTicks.run_loops(30, 2)
	assert_int(fighter.state.jumps_used).is_equal(0)
	assert_bool(fighter.state.on_floor).is_true()


# The dash key as the operating system reports it: the InputMap's dash action is the physical
# left Shift (project.godot, [input]; movimento.md, "Dash": "Tecla"), and the right Shift has the
# same physical keycode at another location.
static func _shift_key(location: KeyLocation, echo: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_SHIFT
	event.location = location
	event.shift_pressed = true
	event.pressed = true
	event.echo = echo
	return event


# TASK-10.4: pressed once, the dash starts on the first tick of the frame, and the second tick of
# the same frame finds it taken, so the slot of the buffer stays empty (DEC-0039).
func test_a_dash_press_counts_for_one_tick_when_a_frame_runs_two() -> void:
	var fighter := await _fighter_in_a_match()
	NetfoxTicks.run_loops(3)
	var press_tick := NetworkTime.tick
	fighter.input.press_dash()
	NetfoxTicks.run_loop(2)
	assert_int(fighter.state.mode).is_equal(FighterState.Mode.DASH)
	assert_int(fighter.state.dash_tick).is_equal(press_tick)
	assert_str(String(fighter.state.buffered_command)).is_equal(String(FighterCommand.NONE))
	assert_bool(fighter.input.to_tick_input().dash).is_false()


# The left Shift through the viewport starts the dash; its key repeat is no second press, so
# nothing waits in the slot, and the right Shift does nothing (TASK-10.4, choice 2, F-121).
func test_the_left_shift_dashes_once_and_its_key_repeat_is_not_a_second_press() -> void:
	var fighter := await _fighter_at_the_keyboard()
	NetfoxTicks.run_loops(3)
	get_viewport().push_input(_shift_key(KEY_LOCATION_RIGHT, false))
	NetfoxTicks.run_loop()
	assert_int(fighter.state.dash_tick) \
			.override_failure_message("the right Shift dashed") \
			.is_equal(FighterState.NEVER)
	var press_tick := NetworkTime.tick
	get_viewport().push_input(_shift_key(KEY_LOCATION_LEFT, false))
	NetfoxTicks.run_loop()
	assert_int(fighter.state.dash_tick) \
			.override_failure_message("the left Shift through the viewport did not dash") \
			.is_equal(press_tick)
	for _echo: int in 5:
		get_viewport().push_input(_shift_key(KEY_LOCATION_LEFT, true))
		NetfoxTicks.run_loop()
	assert_str(String(fighter.state.buffered_command)) \
			.override_failure_message("a key repeat counted as a second press") \
			.is_equal(String(FighterCommand.NONE))
	assert_int(fighter.state.dash_tick).is_equal(press_tick)
