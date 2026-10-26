# Criteria 1 to 3 of TASK-10.2: the HUD shows the stamina as a bar and a number, and the mode as
# text, computed from the fighter's state and the tick, never from a timer (DEC-0031 §2); and from
# criterion 7 of TASK-10.4, the dash's cooldown as an arc with the tenths of a second left; below
# the cost of the double jump the number gains an underline, a shape and not a colour; its look
# comes from the one Theme and its words from translation keys (DEC-0031 §8); and a PC without a
# screen never makes one. TASK-10.6 adds the grapple's cooldown row and the reticle with its dot
# (visual-e-audio.md, "O gancho na tela"). The tests run headless, as the gate does, so they drive
# the HUD by hand with the tick they choose, the call its _process makes with netfox's tick on
# every frame.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const MATCH_SCENE := preload("res://match/match.tscn")
const AimAt := preload("res://test/support/aim_at.gd")

## px at the 1920 x 1080 base: the full bar (visual-e-audio.md, "O HUD"; TASK-10.2).
const FULL_BAR := Vector2(300, 12)
const GAME_THEME := "res://ui/theme/game_theme.tres"
const HAIR := 1e-4
## Any tick far from the start of netfox's clock: the stamina reads only the gap to the stamp.
const SPENT_AT := 5000
## Points left after the spend in the tests that read a bar mid-way.
const LEFT_AFTER_SPEND := 37.0

var _match: Match
var _fighter: Fighter
var _locale_before := ""


func before_test() -> void:
	NetfoxTicks.reset()
	_locale_before = TranslationServer.get_locale()
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	_match = auto_free(node)
	add_child(_match)
	# No tick runs here: the tests set the state by hand and pick the tick.
	_fighter = _match.spawn_fighter(0, multiplayer.get_unique_id())


func after_test() -> void:
	TranslationServer.set_locale(_locale_before)
	NetfoxTicks.reset()


func _hud() -> Hud:
	var hud: Hud = auto_free(Hud.new())
	add_child(hud)
	hud.follow(_fighter, _match.config)
	return hud


# The fighter's bar right after a spend at SPENT_AT that left points in it.
func _spent(points: float) -> void:
	_fighter.state.stamina_at_spend = points
	_fighter.state.stamina_spent_tick = SPENT_AT


func _expected_width(points: float) -> float:
	return FULL_BAR.x * points / _match.config.stamina_max


func test_a_fighter_that_never_spent_shows_a_full_bar_on_the_ground() -> void:
	var hud := _hud()
	hud.show_at(SPENT_AT)
	assert_float(hud.bar_width()).is_equal_approx(FULL_BAR.x, HAIR)
	assert_str(hud.shown_number()).is_equal(str(int(_match.config.stamina_max)))
	assert_bool(hud.shows_low_mark()).is_false()
	assert_str(hud.shown_mode_key()).is_equal(GameText.HUD_MODE_GROUND)


# The bar holds still through the wait, then regains on every tick, as Stamina.at says; the HUD
# only reads the stamp, so the same tick shows the same bar whatever came before, as after a
# rollback, and nothing counts on its own between two frames.
func test_after_a_spend_the_bar_and_the_number_follow_the_stamp() -> void:
	var config := _match.config
	_spent(LEFT_AFTER_SPEND)
	_fighter.state.mode = FighterState.Mode.AIR
	var hud := _hud()
	var end_of_wait := SPENT_AT + config.stamina_wait_ticks
	for tick: int in [SPENT_AT, end_of_wait]:
		hud.show_at(tick)
		assert_float(hud.bar_width()).is_equal_approx(_expected_width(LEFT_AFTER_SPEND), HAIR)
		assert_str(hud.shown_number()).is_equal("37")
	assert_str(hud.shown_mode_key()).is_equal(GameText.HUD_MODE_AIR)

	var regen_ticks := 20
	var regained := LEFT_AFTER_SPEND + regen_ticks * config.stamina_regen_per_tick
	hud.show_at(end_of_wait + regen_ticks)
	assert_float(hud.bar_width()).is_equal_approx(_expected_width(regained), HAIR)
	assert_str(hud.shown_number()).is_equal(str(floori(regained)))
	assert_float(hud.bar_width()).is_greater(_expected_width(LEFT_AFTER_SPEND))

	# Back to a tick inside the wait, as a rollback would show: the bar of that tick again.
	hud.show_at(SPENT_AT + 1)
	assert_float(hud.bar_width()).is_equal_approx(_expected_width(LEFT_AFTER_SPEND), HAIR)

	# Long after, the bar is full and never wider than full.
	hud.show_at(SPENT_AT + 100 * config.tickrate)
	assert_float(hud.bar_width()).is_equal_approx(FULL_BAR.x, HAIR)
	assert_str(hud.shown_number()).is_equal(str(int(config.stamina_max)))


func test_below_the_double_jump_cost_the_number_gains_an_underline() -> void:
	var cost := _match.config.double_jump_cost
	var hud := _hud()

	# Exactly the cost: the double jump can still be paid, so no mark.
	_spent(cost)
	hud.show_at(SPENT_AT)
	assert_bool(hud.shows_low_mark()).is_false()
	assert_str(hud.shown_number()).is_equal(str(int(cost)))

	# Half a point below it: the mark, and the number rounds down, so it reads below the cost too.
	_spent(cost - 0.5)
	hud.show_at(SPENT_AT)
	assert_bool(hud.shows_low_mark()).is_true()
	assert_str(hud.shown_number()).is_equal(str(int(cost) - 1))

	# Empty: the mark and an empty bar.
	_spent(0.0)
	hud.show_at(SPENT_AT)
	assert_bool(hud.shows_low_mark()).is_true()
	assert_float(hud.bar_width()).is_equal_approx(0.0, HAIR)
	assert_str(hud.shown_number()).is_equal("0")

	# Regained past the cost after the wait: the mark goes away by itself.
	var config := _match.config
	var ticks_to_cost := ceili(cost / config.stamina_regen_per_tick)
	hud.show_at(SPENT_AT + config.stamina_wait_ticks + ticks_to_cost)
	assert_bool(hud.shows_low_mark()).is_false()


# Criterion 3: the mode is shown by a key with a message in both languages, for every mode.
func test_every_mode_shows_a_key_of_game_text() -> void:
	var hud := _hud()
	var shown: Array[StringName] = []
	for mode: int in FighterState.Mode.values():
		_fighter.state.mode = mode as FighterState.Mode
		hud.show_at(SPENT_AT)
		var key := hud.shown_mode_key()
		var failure := "mode %d shows %s, not a key of GameText.KEYS" % [mode, key]
		assert_bool(GameText.KEYS.has(key)).override_failure_message(failure).is_true()
		assert_bool(shown.has(key)).override_failure_message("two modes show %s" % key).is_false()
		shown.append(key)


# Criterion 2: the project's Theme is the game's, every class the HUD's nodes take is in it, and
# no Control of the HUD or of the status line carries a theme, a font, a size or a colour of its
# own.
func test_the_hud_and_the_status_line_take_everything_from_the_one_theme() -> void:
	var project_theme := ThemeDB.get_project_theme()
	assert_object(project_theme).is_not_null()
	assert_str(project_theme.resource_path).is_equal(GAME_THEME)
	var hud := _hud()
	var status: StatusMessage = auto_free(StatusMessage.new())
	add_child(status)
	var controls: Array[Control] = []
	for layer: CanvasLayer in [hud, status]:
		for node: Node in layer.find_children("*", "Control", true, false):
			assert(node is Control, "find_children by Control returns Controls")
			controls.append(node as Control)
	assert_int(controls.size()).is_greater(1)
	for control: Control in controls:
		var where := "%s in %s" % [control.name, control.get_parent().name]
		assert_object(control.theme) \
				.override_failure_message("%s has its own Theme" % where) \
				.is_null()
		var own := (
			control.has_theme_font_override(&"font")
			or control.has_theme_font_size_override(&"font_size")
			or control.has_theme_color_override(&"font_color")
			or control.has_theme_color_override(&"font_outline_color")
			or control.has_theme_constant_override(&"outline_size")
			or control.has_theme_stylebox_override(&"panel")
		)
		var failure := "%s sets a font, a size or a colour of its own" % where
		assert_bool(own).override_failure_message(failure).is_false()
		var variation := control.theme_type_variation
		if not variation.is_empty():
			var missing := "%s takes %s, which game_theme.tres lacks" % [where, variation]
			var known := project_theme.get_type_variation_list(control.get_class()).has(variation)
			assert_bool(known).override_failure_message(missing).is_true()
		if control is Label:
			var label := control as Label
			var size := label.get_theme_font_size(&"font_size")
			assert_int(size).is_equal(project_theme.default_font_size)


# Criterion 1: the dedicated server and every headless run have no screen, so watch() gives the
# fighter a camera and no HUD.
func test_without_a_screen_watch_creates_no_hud() -> void:
	assert_str(DisplayServer.get_name()).is_equal("headless")
	assert_bool(Match.has_screen()).is_false()
	_match.watch(_fighter)
	assert_object(_match.camera_rig).is_not_null()
	assert_object(_match.hud).is_null()
	for node: Node in _match.find_children("*", "CanvasLayer", true, false):
		assert_bool(node is Hud).override_failure_message("a Hud under the Match").is_false()


# Criterion 7 of TASK-10.4: from the dash's start until the next may start, 200 ms of dash and
# 400 ms of cooldown (movimento.md, "Dash": "Recarga"), the arc shrinks from the full circle and
# the text counts the tenths of a second left, rounded up, in the decimals of each language; both
# come from the stamp and the tick, so an earlier tick shows its own value again, as after a
# rollback, and nothing shows before the first dash or once the next is ready.
func test_the_dash_cooldown_shows_as_an_arc_with_the_tenths_left() -> void:
	GameText.install()
	TranslationServer.set_locale("en")
	var config := _match.config
	var period := config.dash_ticks + config.dash_cooldown_ticks
	var hud := _hud()
	hud.show_at(SPENT_AT)
	assert_bool(hud.shows_dash_cooldown()).override_failure_message("before any dash").is_false()

	_fighter.state.dash_tick = SPENT_AT
	_fighter.state.mode = FighterState.Mode.DASH
	var cases: Dictionary[int, String] = {
		0: "0.6 s", # 36 ticks at 60: 600 ms
		1: "0.6 s", # 35 ticks: 583 ms, rounded up
		12: "0.4 s", # the dash is over, 24 ticks of cooldown left
		30: "0.1 s", # 6 ticks: 100 ms
		period - 1: "0.1 s", # 1 tick: 17 ms, still waiting
	}
	for after: int in cases:
		hud.show_at(SPENT_AT + after)
		var where := "%d ticks after the dash" % after
		assert_bool(hud.shows_dash_cooldown()).override_failure_message(where).is_true()
		assert_str(hud.shown_dash_cooldown()).override_failure_message(where).is_equal(cases[after])
		var share := float(period - after) / period
		assert_float(hud.dash_cooldown_share()).is_equal_approx(share, HAIR)
	TranslationServer.set_locale("pt_BR")
	hud.show_at(SPENT_AT + 12)
	assert_str(hud.shown_dash_cooldown()).is_equal("0,4 s")

	# Ready on the tick the next dash may start, and after it.
	_fighter.state.mode = FighterState.Mode.GROUND
	for after: int in [period, period + 100]:
		hud.show_at(SPENT_AT + after)
		assert_bool(hud.shows_dash_cooldown()).is_false()
	# Back to a tick of the cooldown, as a rollback would show it.
	hud.show_at(SPENT_AT + 30)
	assert_bool(hud.shows_dash_cooldown()).is_true()
	assert_str(hud.shown_dash_cooldown()).is_equal("0,1 s")


# Criterion 9 of TASK-10.6 (visual-e-audio.md, "O gancho na tela"): the grapple's row sits above
# the dash's, with the same ring and "Gancho 5,9 s", the tenths left rounded up, from the release
# to the next legal fire, 6 s (movimento.md, "Gancho": "Recarga"); all from the stamp and the
# tick, so an earlier tick shows its own value again, as after a rollback.
func test_the_grapple_cooldown_shows_above_the_dash_with_its_ring_and_the_tenths_left() -> void:
	GameText.install()
	TranslationServer.set_locale("pt_BR")
	var config := _match.config
	var cooldown := config.grapple_cooldown_ticks
	var hud := _hud()
	var rows := hud.row_names()
	assert_int(rows.find("GrappleRow")).is_equal(0)
	assert_int(rows.find("DashRow")).is_equal(1)
	hud.show_at(SPENT_AT)
	assert_bool(hud.shows_grapple_cooldown()).override_failure_message("before any release") \
			.is_false()

	_fighter.state.grapple_end_tick = SPENT_AT
	var cases: Dictionary[int, String] = {
		0: "Gancho 6,0 s", # 360 ticks at 60: 6 s
		1: "Gancho 6,0 s", # 359 ticks: 5,983 s, rounded up
		6: "Gancho 5,9 s", # 354 ticks: 5,9 s
		cooldown - 1: "Gancho 0,1 s", # 1 tick: 17 ms, still waiting
	}
	for after: int in cases:
		hud.show_at(SPENT_AT + after)
		var where := "%d ticks after the release" % after
		assert_bool(hud.shows_grapple_cooldown()).override_failure_message(where).is_true()
		assert_str(hud.shown_grapple_cooldown()).override_failure_message(where).is_equal(
			cases[after]
		)
		var share := float(cooldown - after) / cooldown
		assert_float(hud.grapple_cooldown_share()).is_equal_approx(share, HAIR)
		assert_bool(hud.shows_dash_cooldown()).override_failure_message("the dash's row").is_false()
	TranslationServer.set_locale("en")
	hud.show_at(SPENT_AT + 6)
	assert_str(hud.shown_grapple_cooldown()).is_equal("Grapple 5.9 s")

	# Ready on the tick the next grapple may fire, and after it.
	for after: int in [cooldown, cooldown + 100]:
		hud.show_at(SPENT_AT + after)
		assert_bool(hud.shows_grapple_cooldown()).is_false()
	# Back to a tick of the cooldown, as a rollback would show it.
	hud.show_at(SPENT_AT + 6)
	assert_bool(hud.shows_grapple_cooldown()).is_true()


# The target of the reticle: a wall of the test's own in the arena's empty south-east, 16 m wide
# and 10 m tall, its face looking south at z = 12. TASK-10.7 moved it, and the points below with
# it, 8 m north of z = 20: 27 m south of z = 20 stood at z = 47, outside the border's inner face at
# z = 40, where the ray met BordaSul's outer face first (movimento.md, "Métricas de nível": "A
# borda").
const TARGET_FACE_Z := 12.0
const TARGET_POINT := Vector3(28, 4, 12)
# Where the fighter stands: 12 m south of the face, 3 m less than the range would allow and far
# more than the minimum; 27 m south, beyond the 25 m of the ray, still inside the border; 1,5 m
# south, nearer than 3 m.
const BEFORE_THE_TARGET := Vector3(28, 0, 24)
const BEYOND_THE_RANGE := Vector3(28, 0, 39)
const TOO_NEAR := Vector3(28, 0, 13.5)


func _add_target() -> void:
	var wall := StaticBody3D.new()
	wall.name = "AlvoDaMira"
	wall.position = Vector3(TARGET_POINT.x, 5, TARGET_FACE_Z - 0.5)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(16, 10, 1)
	collision.shape = box
	wall.add_child(collision)
	_match.arena.add_child(wall)


# Turns the camera so the aim's ray, leaving the fighter's point O, goes through point (DEC-0045 §2;
# test/support/aim_at.gd).
func _aim(camera: CameraRig, point: Vector3) -> void:
	var feet := _fighter.global_position
	camera.yaw = AimAt.yaw_to(feet, point, _match.config)
	camera.pitch = AimAt.pitch_to(feet, point, _match.config)


# The reticle (visual-e-audio.md, "O gancho na tela"): a 24 px ring that gains its dot when the Q
# would hook now: the screen's own ray, from the displayed point O along the camera the Match gave,
# finds the world from 3 to 25 m of O, and the grapple can fire by the core's rule, out of the
# dash, with no cable in the air and the cooldown over. The ray never touches the state.
func test_the_reticle_gains_its_dot_when_the_q_would_hook_now() -> void:
	_add_target()
	_fighter.position = BEFORE_THE_TARGET
	var camera := _match.watch(_fighter)
	# The wall and the body join the physics space on the next physics step.
	await get_tree().physics_frame
	var hud: Hud = auto_free(Hud.new())
	add_child(hud)
	hud.follow(_fighter, _match.config, camera)
	var reticle_node := hud.get_node(^"Reticle")
	assert(reticle_node is Control, "the reticle is a Control")
	var reticle := reticle_node as Control
	assert_float(reticle.anchor_left).is_equal(0.5)
	assert_float(reticle.anchor_top).is_equal(0.5)
	assert_vector(reticle.size).is_equal(Hud.RETICLE_SIZE)
	assert_vector(Hud.RETICLE_SIZE).is_equal(Vector2(24, 24))
	var state_before := _fighter.state.copy()

	_aim(camera, TARGET_POINT)
	hud.show_at(SPENT_AT)
	assert_bool(hud.shows_reticle_dot()).override_failure_message("aimed at the wall").is_true()

	camera.pitch = deg_to_rad(80.0)
	hud.show_at(SPENT_AT)
	assert_bool(hud.shows_reticle_dot()).override_failure_message("aimed at the sky").is_false()

	_aim(camera, TARGET_POINT)
	var cooldown := _match.config.grapple_cooldown_ticks
	_fighter.state.grapple_end_tick = SPENT_AT
	hud.show_at(SPENT_AT + cooldown - 1)
	assert_bool(hud.shows_reticle_dot()).override_failure_message("in the cooldown").is_false()
	hud.show_at(SPENT_AT + cooldown)
	assert_bool(hud.shows_reticle_dot()).override_failure_message("the cooldown over").is_true()

	_fighter.state.grapple_fired_tick = SPENT_AT + cooldown
	hud.show_at(SPENT_AT + cooldown + 1)
	assert_bool(hud.shows_reticle_dot()).override_failure_message("with a cable out").is_false()
	_fighter.state.grapple_fired_tick = FighterState.NEVER
	_fighter.state.mode = FighterState.Mode.DASH
	hud.show_at(SPENT_AT + cooldown + 1)
	assert_bool(hud.shows_reticle_dot()).override_failure_message("in the dash").is_false()
	_fighter.state.mode = FighterState.Mode.GROUND
	hud.show_at(SPENT_AT + cooldown + 1)
	assert_bool(hud.shows_reticle_dot()).is_true()

	_fighter.position = BEYOND_THE_RANGE
	_aim(camera, TARGET_POINT)
	hud.show_at(SPENT_AT + cooldown + 1)
	assert_bool(hud.shows_reticle_dot()).override_failure_message("beyond 25 m").is_false()
	_fighter.position = TOO_NEAR
	_aim(camera, Vector3(TARGET_POINT.x, _match.config.aim_height, TARGET_FACE_Z))
	hud.show_at(SPENT_AT + cooldown + 1)
	assert_bool(hud.shows_reticle_dot()).override_failure_message("nearer than 3 m").is_false()

	# The ray of the screen never wrote the state.
	assert_int(_fighter.state.buffered_tick).is_equal(state_before.buffered_tick)
	assert_vector(_fighter.state.grapple_point).is_equal(state_before.grapple_point)
	assert_int(_fighter.state.grapple_fired_tick).is_equal(state_before.grapple_fired_tick)

	# Without a camera there is no aim, so no dot.
	_fighter.position = BEFORE_THE_TARGET
	hud.follow(_fighter, _match.config)
	hud.show_at(SPENT_AT + cooldown + 1)
	assert_bool(hud.shows_reticle_dot()).is_false()


# A wall to the right of the fighter standing before the target, behind it, along the camera's
# arm: its face 0,6 m right of the feet, from 1 m behind them to 8 m, 4 m tall. The arm stays free
# and the shoulder stops 0,3 m before the face, about 0,73 m left of the free camera, so the aim's
# ray from O shows right of the screen's centre. Behind the body, it is out of both rays' paths.
const RIGHT_WALL_CENTRE := Vector3(29.1, 2, 28.5)
const RIGHT_WALL_SIZE := Vector3(1, 4, 7)
# The corner: a fin 0,2 m thick on the shoulder's line to the target, from z = 16 to 22, that the
# ray from O, 0,8 m to the right at the body and closing in on the point, passes beside.
const FIN_CENTRE := Vector3(28, 2.5, 19)
const FIN_SIZE := Vector3(0.2, 5, 6)
## px at the base: the ring's centre is within a pixel of where it should be.
const PIXEL := 1.0


func _add_box(box_name: String, centre: Vector3, size: Vector3) -> void:
	var wall := StaticBody3D.new()
	wall.name = box_name
	wall.position = centre
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	wall.add_child(collision)
	_match.arena.add_child(wall)


# The HUD of the fighter standing before the target, with the camera the Match gave it, once the
# walls and the body joined the physics space.
func _hud_before_the_target() -> Hud:
	_add_target()
	_fighter.position = BEFORE_THE_TARGET
	var camera := _match.watch(_fighter)
	await get_tree().physics_frame
	var hud: Hud = auto_free(Hud.new())
	add_child(hud)
	hud.follow(_fighter, _match.config, camera)
	return hud


# The camera follows the aim: the rig turns in its _process and the two arms reach their ends in
# the physics step that comes after.
func _settle() -> void:
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame


# The ring's centre, in the HUD's pixels.
func _ring_centre(hud: Hud) -> Vector2:
	var node := hud.get_node(^"Reticle")
	assert(node is Control, "the reticle is a Control")
	var ring := node as Control
	return ring.position + ring.size / 2.0


# The centre of the screen, in the HUD's pixels: the viewport's visible rect, the 1920 x 1080 base
# with the canvas_items stretch, whatever the window (project.godot).
func _screen_centre(hud: Hud) -> Vector2:
	return hud.get_viewport().get_visible_rect().size / 2.0


func _assert_near(found: Vector2, expected: Vector2, why: String) -> void:
	var message := "%s: the ring at %s, expected %s" % [why, found, expected]
	assert_float(found.distance_to(expected)).override_failure_message(message).is_less_equal(PIXEL)


# Criterion 1 of TASK-10.11: with the camera free, the ring sits at the screen's centre, within a
# pixel, and that is where the camera sees the point the aim's ray finds: the centre of the screen
# shows the point the ray will find (DEC-0045 §2 and §4).
func test_with_the_camera_free_the_ring_sits_at_the_screens_centre_on_the_rays_point() -> void:
	var hud := await _hud_before_the_target()
	var camera := _match.camera_rig
	_aim(camera, TARGET_POINT)
	await _settle()
	hud.show_at(SPENT_AT)
	assert_bool(hud.shows_reticle_dot()).override_failure_message("aimed at the wall").is_true()
	var ring := _ring_centre(hud)
	_assert_near(ring, _screen_centre(hud), "the camera free")
	_assert_near(ring, camera.camera.unproject_position(TARGET_POINT), "the ray's point")


# Criterion 6 of TASK-10.11: a wall to the right of the body pushes the shoulder in, the camera
# slides toward the centre, and the ring follows the ray instead of the centre: it sits where the
# camera sees the ray's point, more than 10 px right of the centre and level with it, and the dot
# still says the Q would hook (DEC-0045 §4: the ray always leaves O).
func test_when_a_wall_pushes_the_camera_in_the_ring_follows_the_ray() -> void:
	var hud := await _hud_before_the_target()
	_add_box("ParedeDaDireita", RIGHT_WALL_CENTRE, RIGHT_WALL_SIZE)
	var camera := _match.camera_rig
	_aim(camera, TARGET_POINT)
	await _settle()
	hud.show_at(SPENT_AT)
	var data := _match.camera_data
	var view := Basis(Vector3.UP, camera.yaw) * Basis(Vector3.RIGHT, camera.pitch)
	var pivot := _fighter.global_position + Vector3.UP * data.pivot_height_m
	var free_camera := pivot + view * Vector3(data.shoulder_m, 0, data.distance_m)
	var pushed := (free_camera - camera.camera.global_position).dot(view.x)
	var message := "the shoulder slid %.3f m toward the centre" % pushed
	assert_float(pushed).override_failure_message(message).is_greater(0.5)
	assert_bool(hud.shows_reticle_dot()).override_failure_message("aimed at the wall").is_true()
	var ring := _ring_centre(hud)
	_assert_near(ring, camera.camera.unproject_position(TARGET_POINT), "pushed, the ray's point")
	var centre := _screen_centre(hud)
	var right := "the ring is %.1f px right of the centre" % (ring.x - centre.x)
	print("Reticle, a wall at the right: the shoulder slid %.3f m, %s" % [pushed, right])
	assert_float(ring.x - centre.x).override_failure_message(right).is_greater(10.0)
	assert_float(absf(ring.y - centre.y)).is_less_equal(PIXEL)


# Criterion 5 of TASK-10.11: a point the shoulder does not see is no point. The ray from O finds the
# target, but the fin stands between the shoulder and it, so the ring shows no dot: the reticle
# never promises a hook the rule refuses (DEC-0045 §3).
func test_on_a_corner_the_shoulder_does_not_see_the_ring_shows_no_dot() -> void:
	var hud := await _hud_before_the_target()
	_add_box("Quina", FIN_CENTRE, FIN_SIZE)
	await get_tree().physics_frame
	var camera := _match.camera_rig
	_aim(camera, TARGET_POINT)
	var config := _match.config
	var feet := _fighter.global_position
	var origin := Aim.origin(feet, camera.yaw, config.aim_height, config.aim_side)
	var reach := Aim.direction(camera.yaw, camera.pitch) * config.grapple_range
	var query := PhysicsRayQueryParameters3D.create(
		origin,
		origin + reach,
		PhysicsLayers.WORLD,
		[_fighter.get_rid()],
	)
	var first := _fighter.get_world_3d().direct_space_state.intersect_ray(query)
	assert_bool(first.is_empty()).override_failure_message("the ray from O found nothing") \
			.is_false()
	if not first.is_empty():
		var point: Vector3 = first["position"]
		assert_vector(point).is_equal_approx(TARGET_POINT, Vector3.ONE * 1e-3)
	hud.show_at(SPENT_AT)
	assert_bool(hud.shows_reticle_dot()).override_failure_message("the corner showed a dot") \
			.is_false()
