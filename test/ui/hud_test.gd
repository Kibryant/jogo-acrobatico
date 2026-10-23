# Criteria 1 to 3 of TASK-10.2: the HUD shows the stamina as a bar and a number, and the mode as
# text, computed from the fighter's state and the tick, never from a timer (DEC-0031 §2); and from
# criterion 7 of TASK-10.4, the dash's cooldown as an arc with the tenths of a second left; below
# the cost of the double jump the number gains an underline, a shape and not a colour; its look
# comes from the one Theme and its words from translation keys (DEC-0031 §8); and a PC without a
# screen never makes one. The tests run headless, as the gate does, so they drive the HUD by hand
# with the tick they choose, the call its _process makes with netfox's tick on every frame.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const MATCH_SCENE := preload("res://match/match.tscn")

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
