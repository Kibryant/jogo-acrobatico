# The HUD of whoever plays on this PC (TASK-10.2): the stamina as a bar with its number beside
# it, the mode as text and, while the dash recharges, an arc with the tenths of a second left
# (TASK-10.4), in the bottom-left corner; above it, the grapple's own arc and time (TASK-10.6);
# and at the screen's centre the grapple's reticle, a ring that gains a dot when the Q would hook
# now (visual-e-audio.md, "O gancho na tela"). It keeps no time of its own, no Timer and no
# counter: every frame it reads the displayed state of the fighter it follows and netfox's tick,
# computes the bar with Stamina.at and the arcs from the stamps, so a rollback that rewrites the
# state rewrites the bar and the arcs with it (DEC-0031 §2; F-051 §3.4). The reticle's ray is the
# screen's only: cast from the displayed body along the camera, it never enters the state. Nothing
# shows by colour alone: below the cost of the double jump the number gains an underline, a shape
# (DEC-0031 §2); the reticle's dot is a shape too. Its
# look comes from the one Theme of the project (ui/theme/game_theme.tres, DEC-0031 §8): its nodes
# take type variations, the Theme's classes, and never a font, a size or a colour of their own.
# Only a PC with a screen has one: the Match creates it in watch().
class_name Hud
extends CanvasLayer

## px at the 1920 x 1080 base: the full bar (visual-e-audio.md, "O HUD"; TASK-10.2).
const BAR_SIZE := Vector2(300, 12)
## px at the 1080p base: the thickness of the underline below the number.
const MARK_HEIGHT := 2.0
## The Theme's type variations the HUD's nodes take, like CSS classes.
const MARGIN_TYPE := &"HudMargin"
const BAR_BACK_TYPE := &"StaminaBarBack"
const BAR_FILL_TYPE := &"StaminaBarFill"
const LOW_MARK_TYPE := &"StaminaLowMark"
const COOLDOWN_ARC_TYPE := &"DashCooldownArc"
const GRAPPLE_ARC_TYPE := &"GrappleCooldownArc"
const RETICLE_TYPE := &"Reticle"
## px at the 1080p base: the box of the dash's cooldown arc, twice the bar's height. Claude's v0
## reading (DEC-0017; TASK-10.4). The grapple's arc is the same ring.
const ARC_SIZE := Vector2(24, 24)
## px at the 1080p base: the reticle's ring and the dot it gains (visual-e-audio.md, "O gancho na
## tela"). Claude's v0 reading (DEC-0017; TASK-10.6).
const RETICLE_SIZE := Vector2(24, 24)
const RETICLE_DOT := 5.0
## The key of GameText each mode shows, by FighterState.Mode.
const MODE_KEYS: Dictionary[int, StringName] = {
	FighterState.Mode.GROUND: GameText.HUD_MODE_GROUND,
	FighterState.Mode.AIR: GameText.HUD_MODE_AIR,
	FighterState.Mode.DASH: GameText.HUD_MODE_DASH,
	FighterState.Mode.WALL_RUN: GameText.HUD_MODE_WALL_RUN,
	FighterState.Mode.GRAPPLE: GameText.HUD_MODE_GRAPPLE,
}

# The fighter whose displayed state the HUD shows, and the numbers of its match; null until
# follow().
var _fighter: Fighter
var _config: MovementConfig
var _mode := Label.new()
var _fill := Panel.new()
var _number := Label.new()
var _low_mark := Panel.new()
var _arc := CooldownArc.new()
var _cooldown := Label.new()
var _grapple_arc := CooldownArc.new()
var _grapple_cooldown := Label.new()
var _reticle := Reticle.new()
# The camera of whoever plays here: the reticle's ray goes along its yaw and pitch. Null without
# one, and then the reticle shows no dot.
var _camera: CameraRig


func _init() -> void:
	name = "Hud"
	var frame := MarginContainer.new()
	frame.name = "Frame"
	frame.theme_type_variation = MARGIN_TYPE
	frame.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	# Anchored to the bottom-left corner, it grows up and to the right as its content needs.
	frame.grow_horizontal = Control.GROW_DIRECTION_END
	frame.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(frame)
	var rows := VBoxContainer.new()
	rows.name = "Rows"
	frame.add_child(rows)

	# The grapple's row, above the dash's, the same ring: it keeps its height while hidden too.
	var grapple_row := HBoxContainer.new()
	grapple_row.name = "GrappleRow"
	grapple_row.custom_minimum_size = Vector2(0, ARC_SIZE.y)
	rows.add_child(grapple_row)
	_grapple_arc.name = "GrappleCooldownArc"
	_grapple_arc.theme_type_variation = GRAPPLE_ARC_TYPE
	_grapple_arc.custom_minimum_size = ARC_SIZE
	_grapple_arc.visible = false
	grapple_row.add_child(_grapple_arc)
	_grapple_cooldown.name = "GrappleCooldown"
	_grapple_cooldown.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_grapple_cooldown.visible = false
	grapple_row.add_child(_grapple_cooldown)

	# The row keeps its height while the arc is hidden, so the rows below never jump.
	var dash_row := HBoxContainer.new()
	dash_row.name = "DashRow"
	dash_row.custom_minimum_size = Vector2(0, ARC_SIZE.y)
	rows.add_child(dash_row)
	_arc.name = "DashCooldownArc"
	_arc.theme_type_variation = COOLDOWN_ARC_TYPE
	_arc.custom_minimum_size = ARC_SIZE
	_arc.visible = false
	dash_row.add_child(_arc)
	_cooldown.name = "DashCooldown"
	# The tenths come already in the player's language, from a key with the number filled in.
	_cooldown.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_cooldown.visible = false
	dash_row.add_child(_cooldown)

	_mode.name = "ModeLabel"
	rows.add_child(_mode)

	var bar_row := HBoxContainer.new()
	bar_row.name = "StaminaRow"
	rows.add_child(bar_row)
	var bar := Panel.new()
	bar.name = "StaminaBar"
	bar.theme_type_variation = BAR_BACK_TYPE
	bar.custom_minimum_size = BAR_SIZE
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar_row.add_child(bar)
	_fill.name = "StaminaFill"
	_fill.theme_type_variation = BAR_FILL_TYPE
	_fill.size = BAR_SIZE
	bar.add_child(_fill)

	var number_column := VBoxContainer.new()
	number_column.name = "StaminaNumberColumn"
	number_column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar_row.add_child(number_column)
	_number.name = "StaminaNumber"
	# A number, the same in every language: nothing to translate.
	_number.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	number_column.add_child(_number)
	# The slot keeps the underline's room while it is hidden, so the number never jumps.
	var mark_slot := Control.new()
	mark_slot.name = "LowMarkSlot"
	mark_slot.custom_minimum_size = Vector2(0, MARK_HEIGHT)
	number_column.add_child(mark_slot)
	_low_mark.name = "StaminaLowMark"
	_low_mark.theme_type_variation = LOW_MARK_TYPE
	_low_mark.set_anchors_preset(Control.PRESET_FULL_RECT)
	_low_mark.visible = false
	mark_slot.add_child(_low_mark)

	# The reticle at the screen's centre, where the ray from the shoulder goes with the camera
	# centred (DEC-0044 §2).
	_reticle.name = "Reticle"
	_reticle.theme_type_variation = RETICLE_TYPE
	_reticle.set_anchors_preset(Control.PRESET_CENTER)
	_reticle.offset_left = -RETICLE_SIZE.x / 2.0
	_reticle.offset_top = -RETICLE_SIZE.y / 2.0
	_reticle.offset_right = RETICLE_SIZE.x / 2.0
	_reticle.offset_bottom = RETICLE_SIZE.y / 2.0
	_reticle.dot_size = RETICLE_DOT
	_reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_reticle)


func _process(_delta: float) -> void:
	# Before follow(), or once the match has freed the fighter.
	if not is_instance_valid(_fighter):
		return
	show_at(NetworkTime.tick)


# Shows fighter's displayed state from now on, with the numbers of its match; the reticle aims
# along camera, the one the Match gave whoever plays here.
func follow(fighter: Fighter, config: MovementConfig, camera: CameraRig = null) -> void:
	_fighter = fighter
	_config = config
	_camera = camera


# What _process does on every frame with netfox's tick: the bar, the number and the mode of the
# followed fighter's state at tick.
func show_at(tick: int) -> void:
	assert(_fighter != null, "follow() a fighter first")
	var state := _fighter.state
	var stamina := Stamina.at(state, _config, tick)
	var share := clampf(stamina / _config.stamina_max, 0.0, 1.0)
	_fill.size = Vector2(BAR_SIZE.x * share, BAR_SIZE.y)
	# Whole points, rounded down: a bar of 9.5 reads 9, below the cost of 10, as the mark says.
	_number.text = str(floori(stamina))
	_low_mark.visible = stamina < _config.double_jump_cost
	_mode.text = mode_key(state.mode)
	_show_cooldown(tick)
	_show_grapple_cooldown(tick)
	_show_reticle(tick)


# The ticks until the next dash may start, counted from the stamp of the last one: its ticks and
# then the cooldown (movimento.md, "Dash": "Recarga"). Zero or less, or no dash ever, is ready.
func cooldown_ticks_at(tick: int) -> int:
	var state := _fighter.state
	if state.dash_tick == FighterState.NEVER:
		return 0
	return state.dash_tick + _config.dash_ticks + _config.dash_cooldown_ticks - tick


# The arc full when the dash starts and empty when the next may start; the text, the time left in
# tenths of a second, rounded up, so it never reads 0 while the dash still waits.
func _show_cooldown(tick: int) -> void:
	var left := cooldown_ticks_at(tick)
	var waiting := left > 0
	_arc.visible = waiting
	_cooldown.visible = waiting
	if not waiting:
		return
	_arc.share = float(left) / (_config.dash_ticks + _config.dash_cooldown_ticks)
	_arc.queue_redraw()
	var tenths := ceili(left * 10.0 / _config.tickrate)
	var whole := floori(tenths / 10.0)
	var pattern := GameText.text(GameText.HUD_DASH_COOLDOWN)
	_cooldown.text = pattern.format({ "whole": whole, "tenth": tenths % 10 })


# The ticks until the next grapple may fire, counted from its last release (movimento.md,
# "Gancho": "Recarga"). Zero or less, or no release ever, is ready.
func grapple_cooldown_ticks_at(tick: int) -> int:
	var state := _fighter.state
	if state.grapple_end_tick == FighterState.NEVER:
		return 0
	return state.grapple_end_tick + _config.grapple_cooldown_ticks - tick


# The grapple's arc, full on the release and empty when the next may fire, and "Gancho 5,9 s",
# the time left in tenths rounded up (visual-e-audio.md, "O gancho na tela").
func _show_grapple_cooldown(tick: int) -> void:
	var left := grapple_cooldown_ticks_at(tick)
	var waiting := left > 0
	_grapple_arc.visible = waiting
	_grapple_cooldown.visible = waiting
	if not waiting:
		return
	_grapple_arc.share = float(left) / _config.grapple_cooldown_ticks
	_grapple_arc.queue_redraw()
	var tenths := ceili(left * 10.0 / _config.tickrate)
	var whole := floori(tenths / 10.0)
	var pattern := GameText.text(GameText.HUD_GRAPPLE_COOLDOWN)
	_grapple_cooldown.text = pattern.format({ "whole": whole, "tenth": tenths % 10 })


# The dot shows when the Q would hook now (visual-e-audio.md, "O gancho na tela"): a press now,
# on netfox's next tick, could fire by the core's own rule, and the ray of the screen, from the
# displayed shoulder along the camera, finds the world within the grapple's reach. The ray only
# asks the physics space: nothing of it goes into the state.
func _show_reticle(tick: int) -> void:
	var dot := false
	if _camera != null and Movement.can_grapple(_fighter.state, tick, _config):
		var feet := _fighter.global_position
		var hit := _fighter.aim_ray(feet, _camera.yaw, _camera.pitch)
		if not hit.is_empty():
			var point: Vector3 = hit["position"]
			dot = Movement.in_reach(point, feet, _config)
	if _reticle.dotted != dot:
		_reticle.dotted = dot
		_reticle.queue_redraw()


# The key of the text that names mode.
static func mode_key(mode: FighterState.Mode) -> StringName:
	assert(MODE_KEYS.has(mode), "mode %d has no text in the HUD" % mode)
	return MODE_KEYS[mode]


# px at the 1080p base: the width of the filled part of the bar.
func bar_width() -> float:
	return _fill.size.x


# The number beside the bar.
func shown_number() -> String:
	return _number.text


# True when the number has its underline: the bar cannot pay the double jump.
func shows_low_mark() -> bool:
	return _low_mark.visible


# The key of GameText the mode shows.
func shown_mode_key() -> StringName:
	return StringName(_mode.text)


# True while the dash's cooldown arc shows.
func shows_dash_cooldown() -> bool:
	return _arc.visible and _cooldown.visible


# The share of the circle the arc covers: 1 when the dash starts, 0 when the next may.
func dash_cooldown_share() -> float:
	return _arc.share


# The tenths of a second left, as the screen shows them.
func shown_dash_cooldown() -> String:
	return _cooldown.text


# True while the grapple's cooldown arc shows.
func shows_grapple_cooldown() -> bool:
	return _grapple_arc.visible and _grapple_cooldown.visible


# The share of the circle the grapple's arc covers: 1 on the release, 0 when the next may fire.
func grapple_cooldown_share() -> float:
	return _grapple_arc.share


# The grapple's time left, as the screen shows it.
func shown_grapple_cooldown() -> String:
	return _grapple_cooldown.text


# True when the reticle shows its dot: the Q would hook now.
func shows_reticle_dot() -> bool:
	return _reticle.visible and _reticle.dotted


# The rows of the bottom-left corner, top to bottom, by name.
func row_names() -> PackedStringArray:
	var names := PackedStringArray()
	for row: Node in get_node(^"Frame/Rows").get_children():
		names.append(row.name)
	return names


# The arc of a cooldown: a ring in the track colour, and over it the arc from the top, clockwise,
# over the share of the circle still to wait. Its colours and thickness come from the Theme's
# DashCooldownArc or GrappleCooldownArc (DEC-0031 §8).
class CooldownArc:
	extends Control

	## Points of the drawn arc on a full circle; fewer on a shorter arc.
	const POINTS := 48

	var share := 0.0


	func _draw() -> void:
		var thickness := float(get_theme_constant(&"thickness"))
		var center := size / 2.0
		var radius := minf(size.x, size.y) / 2.0 - thickness / 2.0
		var top := -PI / 2.0
		draw_arc(center, radius, 0.0, TAU, POINTS, get_theme_color(&"track_color"), thickness, true)
		if share <= 0.0:
			return
		var points := maxi(2, ceili(POINTS * share))
		var end := top + TAU * share
		draw_arc(center, radius, top, end, points, get_theme_color(&"arc_color"), thickness, true)


# The grapple's reticle (visual-e-audio.md, "O gancho na tela"): a ring at the screen's centre in
# the HUD's white over a dark translucent outline, and, when the Q would hook now, a dot in its
# middle: a shape, not a colour (DEC-0031 §2). Its colours and stroke come from the Theme's
# Reticle (DEC-0031 §8).
class Reticle:
	extends Control

	## Points of the drawn ring.
	const POINTS := 48

	var dotted := false
	## px: the dot's diameter.
	var dot_size := 0.0


	func _draw() -> void:
		var thickness := float(get_theme_constant(&"thickness"))
		var outline := float(get_theme_constant(&"outline_size"))
		var ring := get_theme_color(&"ring_color")
		var dark := get_theme_color(&"outline_color")
		var center := size / 2.0
		var radius := minf(size.x, size.y) / 2.0 - thickness / 2.0 - outline
		draw_arc(center, radius, 0.0, TAU, POINTS, dark, thickness + 2.0 * outline, true)
		draw_arc(center, radius, 0.0, TAU, POINTS, ring, thickness, true)
		if not dotted:
			return
		draw_circle(center, dot_size / 2.0 + outline, dark)
		draw_circle(center, dot_size / 2.0, ring)
