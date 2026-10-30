# Criterion 7 of TASK-9, through netfox's real tick loop: the frames' samples become the input
# netfox records for each tick (DEC-0026 §1), and a jump press counts for at most one tick, even
# when a frame runs two ticks to catch the clock. Ticks run by hand (DEC-0027 §3), in Sozinho.
# TASK-10.4 adds the dash on the left Shift; TASK-10.6, criterion 2, the camera's pitch, the last
# sample like the yaw, and the grapple on the Q, a one-touch command like the others; TASK-12.1,
# the light attack on the left mouse button, one more (F-175 §2); TASK-12.2, the guard on the right
# mouse button, held rather than touched (F-182 §2; DEC-0054 §1); TASK-12.3, the charged attack on
# the E, the parry on the F and the guard button's press beside its hold (F-191 §2; DEC-0056 §1).
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const MATCH_SCENE := preload("res://match/match.tscn")

const HAIR := 1e-9 # floating-point slack, not a design number
const FORWARD := Vector2(0, 1)

var _game_match: Match
# The box of every tick the run simulated, by tick, as netfox restored it (_watch_boxes).
var _boxes: Dictionary[int, TickInput] = { }
var _watched: Fighter


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	Input.action_release(&"guard")
	if NetworkRollback.after_process_tick.is_connected(_keep_box):
		NetworkRollback.after_process_tick.disconnect(_keep_box)
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


# From now on, keeps the box of fighter on every tick netfox simulates, on its after_process_tick:
# the input netfox restored for that very tick (replay/replay_recorder.gd reads it there too).
func _watch_boxes(fighter: Fighter) -> void:
	_watched = fighter
	_boxes.clear()
	NetworkRollback.after_process_tick.connect(_keep_box)


func _keep_box(tick: int) -> void:
	_boxes[tick] = _watched.input.to_tick_input()


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


# TASK-10.6: the box carries the last pitch of the frames, like the yaw (rede.md §3). The pitch
# aims the grapple and tilts only the camera: the body keeps facing the yaw.
func test_the_tick_input_carries_the_last_pitch_of_the_frames() -> void:
	var fighter := await _fighter_in_a_match()
	fighter.input.sample_frame(FORWARD, 0.25, 0.5)
	fighter.input.sample_frame(Vector2.ZERO, 0.5, -0.125)
	NetfoxTicks.run_loop()
	var tick_input := fighter.input.to_tick_input()
	assert_float(tick_input.pitch).is_equal_approx(-0.125, HAIR)
	assert_float(tick_input.yaw).is_equal_approx(0.5, HAIR)
	assert_float(fighter.state.facing_yaw).is_equal_approx(0.5, HAIR)
	# The next tick without a frame keeps the last sample, as the yaw does.
	NetfoxTicks.run_loop()
	assert_float(fighter.input.to_tick_input().pitch).is_equal_approx(-0.125, HAIR)


# TASK-10.6 (DEC-0044): at the keyboard, the input samples the camera's pitch with its yaw. It
# samples the devices in its own _physics_process, which runs after the physics frame the test
# resumes in, so one whole physics frame passes before the tick reads them.
func test_at_the_keyboard_the_box_takes_the_camera_pitch_with_its_yaw() -> void:
	var fighter := await _fighter_at_the_keyboard()
	var camera := _game_match.camera_rig
	camera.yaw = 0.75
	camera.pitch = -0.3
	await get_tree().physics_frame
	await get_tree().physics_frame
	NetfoxTicks.run_loop()
	var tick_input := fighter.input.to_tick_input()
	assert_float(tick_input.yaw).is_equal_approx(0.75, HAIR)
	assert_float(tick_input.pitch).is_equal_approx(-0.3, HAIR)


# TASK-10.6: pressed once, the grapple is in the box of the first tick of a frame that runs two,
# and the second tick finds it taken: a one-touch command counts for one tick (DEC-0026 §1).
func test_a_grapple_press_counts_for_one_tick_when_a_frame_runs_two() -> void:
	var fighter := await _fighter_in_a_match()
	NetfoxTicks.run_loops(3)
	_watch_boxes(fighter)
	var press_tick := NetworkTime.tick
	fighter.input.press_grapple()
	NetfoxTicks.run_loop(2)
	assert_bool(_boxes[press_tick].grapple).is_true()
	assert_bool(_boxes[press_tick + 1].grapple).is_false()
	assert_bool(fighter.input.to_tick_input().grapple).is_false()
	# The grapple is not the jump or the dash.
	assert_bool(_boxes[press_tick].jump).is_false()
	assert_bool(_boxes[press_tick].dash).is_false()


# The Q key as the operating system reports it: the InputMap's grapple action is the physical Q,
# keycode 81 (project.godot, [input]; F-140 §1); echo marks the key repeat of a held key.
static func _q_key(echo: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_Q
	event.pressed = true
	event.echo = echo
	return event


# TASK-10.6, choice 1 (F-140 §1): the Q through the viewport presses the grapple on its tick, and
# its key repeat is no second press: a held Q is one grapple.
func test_the_q_key_presses_the_grapple_once_and_its_key_repeat_is_not_a_second_press() -> void:
	var fighter := await _fighter_at_the_keyboard()
	NetfoxTicks.run_loops(3)
	_watch_boxes(fighter)
	var press_tick := NetworkTime.tick
	get_viewport().push_input(_q_key(false))
	NetfoxTicks.run_loop()
	for _echo: int in 5:
		get_viewport().push_input(_q_key(true))
		NetfoxTicks.run_loop()
	assert_bool(_boxes[press_tick].grapple) \
			.override_failure_message("the Q through the viewport did not press the grapple") \
			.is_true()
	for tick: int in range(press_tick + 1, NetworkTime.tick):
		assert_bool(_boxes[tick].grapple) \
				.override_failure_message("a key repeat counted as a press on tick %d" % tick) \
				.is_false()


# TASK-12.1: pressed once, the light attack is in the box of the first tick of a frame that runs
# two, and only there; it is no jump, dash or grapple.
func test_a_light_attack_press_counts_for_one_tick_when_a_frame_runs_two() -> void:
	var fighter := await _fighter_in_a_match()
	NetfoxTicks.run_loops(3)
	_watch_boxes(fighter)
	var press_tick := NetworkTime.tick
	fighter.input.press_light_attack()
	NetfoxTicks.run_loop(2)
	assert_bool(_boxes[press_tick].light_attack).is_true()
	assert_bool(_boxes[press_tick + 1].light_attack).is_false()
	assert_bool(fighter.input.to_tick_input().light_attack).is_false()
	assert_bool(_boxes[press_tick].jump).is_false()
	assert_bool(_boxes[press_tick].dash).is_false()
	assert_bool(_boxes[press_tick].grapple).is_false()


# The left mouse button as the operating system reports it: the InputMap's light_attack action
# (project.godot, [input]; F-175 §2).
static func _left_click(pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	return event


# TASK-12.1 (F-175 §2): a click of the left button through the viewport presses the light attack
# on its tick; holding it is one press. A headless run cannot capture the mouse, and the camera
# spends a click on a mouse that got away to capture it (CameraRig): with the camera's mouse set
# free, the click reaches the fighter's input as a captured one would.
func test_the_left_click_presses_the_light_attack_once() -> void:
	var fighter := await _fighter_at_the_keyboard()
	_game_match.camera_rig.free_mouse()
	NetfoxTicks.run_loops(3)
	_watch_boxes(fighter)
	var press_tick := NetworkTime.tick
	get_viewport().push_input(_left_click(true))
	NetfoxTicks.run_loop()
	NetfoxTicks.run_loops(3)
	get_viewport().push_input(_left_click(false))
	NetfoxTicks.run_loop()
	assert_bool(_boxes[press_tick].light_attack) \
			.override_failure_message("the left click did not press the light attack") \
			.is_true()
	for tick: int in range(press_tick + 1, NetworkTime.tick):
		assert_bool(_boxes[tick].light_attack) \
				.override_failure_message("a held button counted again on tick %d" % tick) \
				.is_false()


# TASK-12.2: the guard is held: once hold_guard(true), every tick's box has it, the two ticks of a
# frame that runs two included, until hold_guard(false); it presses nothing else.
func test_a_held_guard_is_in_every_box_until_it_is_let_go() -> void:
	var fighter := await _fighter_in_a_match()
	NetfoxTicks.run_loops(3)
	_watch_boxes(fighter)
	var from := NetworkTime.tick
	fighter.input.hold_guard(true)
	NetfoxTicks.run_loop(2)
	NetfoxTicks.run_loops(2)
	var let_go := NetworkTime.tick
	fighter.input.hold_guard(false)
	NetfoxTicks.run_loops(2)
	for tick: int in range(from, NetworkTime.tick):
		assert_bool(_boxes[tick].guard).override_failure_message("tick %d" % tick).is_equal(
			tick < let_go
		)
		assert_bool(_boxes[tick].light_attack).is_false()
		assert_bool(_boxes[tick].jump).is_false()


# TASK-12.2 (F-182 §2): at the keyboard, the guard action held, the right mouse button by default,
# is read on every physics step like the keys of the move, and let go it drops from the next box.
func test_at_the_keyboard_the_guard_action_held_is_in_the_box() -> void:
	var fighter := await _fighter_at_the_keyboard()
	NetfoxTicks.run_loops(2)
	_watch_boxes(fighter)
	Input.action_press(&"guard")
	await get_tree().physics_frame
	var held := NetworkTime.tick
	NetfoxTicks.run_loop()
	Input.action_release(&"guard")
	await get_tree().physics_frame
	var released := NetworkTime.tick
	NetfoxTicks.run_loop()
	assert_bool(_boxes[held].guard).override_failure_message("the held guard was not read") \
			.is_true()
	assert_bool(_boxes[released].guard).override_failure_message("the guard stayed up").is_false()


# TASK-12.3: pressed once, the charged attack, the parry and the guard's press are in the box of
# the first tick of a frame that runs two, and only there; none presses another.
func test_the_charged_the_parry_and_the_guard_press_count_for_one_tick() -> void:
	var fighter := await _fighter_in_a_match()
	NetfoxTicks.run_loops(3)
	_watch_boxes(fighter)
	var press_tick := NetworkTime.tick
	fighter.input.press_charged_attack()
	fighter.input.press_parry()
	fighter.input.press_guard()
	NetfoxTicks.run_loop(2)
	var pressed := _boxes[press_tick]
	assert_bool(pressed.charged_attack).is_true()
	assert_bool(pressed.parry).is_true()
	assert_bool(pressed.guard_press).is_true()
	assert_bool(pressed.guard).override_failure_message("a press is no hold").is_false()
	assert_bool(pressed.light_attack).is_false()
	assert_bool(pressed.jump).is_false()
	var after := _boxes[press_tick + 1]
	assert_bool(after.charged_attack).is_false()
	assert_bool(after.parry).is_false()
	assert_bool(after.guard_press).is_false()
	var now := fighter.input.to_tick_input()
	assert_bool(now.charged_attack or now.parry or now.guard_press).is_false()


# A key as the operating system reports it, by its physical position.
static func _key(physical: Key, pressed: bool, echo := false) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = physical
	event.pressed = pressed
	event.echo = echo
	return event


# The right mouse button, the guard's (project.godot, [input]; F-182 §2).
static func _right_click(pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = pressed
	return event


# TASK-12.3 (F-191 §2; combate.md, "As teclas"): at the keyboard, the E presses the charged attack
# and the F the parry, once each on their tick, by physical position; the key repeat of a held key
# is no second press.
func test_the_e_and_the_f_press_the_charged_and_the_parry_once() -> void:
	var fighter := await _fighter_at_the_keyboard()
	_game_match.camera_rig.free_mouse()
	NetfoxTicks.run_loops(3)
	_watch_boxes(fighter)
	var charged_tick := NetworkTime.tick
	get_viewport().push_input(_key(KEY_E, true))
	NetfoxTicks.run_loop()
	get_viewport().push_input(_key(KEY_E, true, true))
	NetfoxTicks.run_loop()
	get_viewport().push_input(_key(KEY_E, false))
	var parry_tick := NetworkTime.tick
	get_viewport().push_input(_key(KEY_F, true))
	NetfoxTicks.run_loop()
	get_viewport().push_input(_key(KEY_F, true, true))
	NetfoxTicks.run_loop()
	get_viewport().push_input(_key(KEY_F, false))
	for tick: int in range(charged_tick, NetworkTime.tick):
		var box := _boxes[tick]
		var where := "tick %d" % tick
		assert_bool(box.charged_attack).override_failure_message(where).is_equal(
			tick == charged_tick
		)
		assert_bool(box.parry).override_failure_message(where).is_equal(tick == parry_tick)
		assert_bool(box.light_attack).override_failure_message(where).is_false()


# TASK-12.3 (DEC-0056 §5): the right button going down presses the guard once, on its tick, beside
# the hold, which stays in every box while the button is down; holding it is one press.
func test_the_right_click_presses_the_guard_once_beside_its_hold() -> void:
	var fighter := await _fighter_at_the_keyboard()
	_game_match.camera_rig.free_mouse()
	NetfoxTicks.run_loops(3)
	_watch_boxes(fighter)
	var press_tick := NetworkTime.tick
	get_viewport().push_input(_right_click(true))
	Input.action_press(&"guard")
	await get_tree().physics_frame
	NetfoxTicks.run_loop()
	NetfoxTicks.run_loops(3)
	assert_bool(_boxes[press_tick].guard_press) \
			.override_failure_message("the right click did not press the guard") \
			.is_true()
	for tick: int in range(press_tick + 1, NetworkTime.tick):
		assert_bool(_boxes[tick].guard_press) \
				.override_failure_message("a held button pressed again on tick %d" % tick) \
				.is_false()
		assert_bool(_boxes[tick].guard).override_failure_message("tick %d" % tick).is_true()


# TASK-12.3: muted, as with the options open, the E, the F and the right button press nothing.
func test_muted_the_e_the_f_and_the_right_click_press_nothing() -> void:
	var fighter := await _fighter_at_the_keyboard()
	_game_match.camera_rig.free_mouse()
	fighter.input.mute_devices(true)
	NetfoxTicks.run_loops(3)
	_watch_boxes(fighter)
	var from := NetworkTime.tick
	get_viewport().push_input(_key(KEY_E, true))
	get_viewport().push_input(_key(KEY_F, true))
	get_viewport().push_input(_right_click(true))
	NetfoxTicks.run_loops(2)
	get_viewport().push_input(_key(KEY_E, false))
	get_viewport().push_input(_key(KEY_F, false))
	for tick: int in range(from, NetworkTime.tick):
		var box := _boxes[tick]
		var where := "tick %d" % tick
		assert_bool(box.charged_attack).override_failure_message(where).is_false()
		assert_bool(box.parry).override_failure_message(where).is_false()
		assert_bool(box.guard_press).override_failure_message(where).is_false()
