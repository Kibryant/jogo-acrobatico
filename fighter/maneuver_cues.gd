# The cues of the maneuvers (DEC-0031 §6; TASK-10.4): a puff under the feet when a double jump
# comes out and a trail behind a dash, each played once per event, by its key: the fighter, the
# kind and the stamp, the tick the state carries for it. Like the `key` of a list in React, the
# key says "this one already showed": after every tick loop it reads the displayed state, and a
# key that already played never plays again, however many times a rollback runs its tick again.
# A cue never undoes either: a rollback that takes the event away leaves it showing (DEC-0031 §6).
# Only visual in the v0; the sound waits for a licensed pack (DEC-0029; Q-32). The cue wears the
# fighter's own neutral tone, never a colour of the combat tokens (DEC-0031; visual-e-audio.md),
# and its sizes and times come from the movement numbers: the capsule, the dash and the jump.
# It also counts, for the SyncTest, the events the simulation made on its fresh ticks: there,
# with the rollback forced on every tick, the cues presented must equal the events (DEC-0031 §6;
# rede.md §4).
class_name ManeuverCues
extends Node

## What a cue shows, part of its key.
enum Kind {
	DOUBLE_JUMP,
	DASH,
}

## The cue's opacity when it appears; it fades to nothing. Claude's v0 reading (DEC-0017): seen
## through, so the cue never hides a body behind it.
const OPACITY := 0.4
## The puff grows from the capsule's radius to this many radii while it fades. Claude's v0
## reading (DEC-0017).
const PUFF_GROWTH := 3.0
## m: the puff is a disc this thin, as thin as the ruler's strips (TASK-10.4, "Arena").
const DISC_THICKNESS := 0.01

## Cues played: one per key, when its event first shows in the displayed state.
var presented := 0
## Events the simulation made on its fresh ticks, one per key. On a client it sees only the
## fighters this PC simulates; the SyncTest, in Sozinho, sees them all.
var events := 0

var _config: MovementConfig
# False without a screen, as on the dedicated server and in the headless runs: the cues still
# count, and nothing is drawn.
var _draws: bool
var _fighters: Array[Fighter] = []
# The keys that played, and those the fresh ticks made, each with its stamp, to forget it once
# no rollback can bring it back.
var _played: Dictionary[String, int] = { }
var _counted: Dictionary[String, int] = { }
# The newest tick the simulation ran: a tick newer than it is fresh.
var _newest_tick := FighterState.NEVER


func _init(config: MovementConfig, draws: bool) -> void:
	name = "ManeuverCues"
	_config = config
	_draws = draws


func _enter_tree() -> void:
	NetworkTime.after_tick_loop.connect(_present)
	NetworkRollback.after_process_tick.connect(_count)


func _exit_tree() -> void:
	NetworkTime.after_tick_loop.disconnect(_present)
	NetworkRollback.after_process_tick.disconnect(_count)


# From now on the maneuvers of fighter play their cues.
func watch(fighter: Fighter) -> void:
	_fighters.append(fighter)


func forget(fighter: Fighter) -> void:
	_fighters.erase(fighter)


# The events fighter's state shows now: the double jump of this flight, by its stamp, and the
# dash while it lasts, by the tick it began. A dash_tick that stays after the dash shows no cue,
# so a fighter seen for the first time long after its dash never plays an old trail.
static func shown_events(fighter: Fighter) -> Array[Event]:
	var shown: Array[Event] = []
	var state := fighter.state
	if state.double_jump_tick != FighterState.NEVER:
		shown.append(Event.new(fighter, Kind.DOUBLE_JUMP, state.double_jump_tick))
	if state.mode == FighterState.Mode.DASH:
		shown.append(Event.new(fighter, Kind.DASH, state.dash_tick))
	return shown


# After every tick loop, netfox's rollback included: the state on the fighters is the one the
# screen shows until the next loop.
func _present() -> void:
	for fighter: Fighter in _fighters:
		if not is_instance_valid(fighter):
			continue
		for event: Event in shown_events(fighter):
			if _played.has(event.key):
				continue
			_played[event.key] = event.stamp
			presented += 1
			if _draws:
				_draw(fighter, event.kind)
	_forget_old(_played)


# After every tick netfox simulates: on a fresh one, the events whose stamp is that tick.
func _count(tick: int) -> void:
	if tick <= _newest_tick:
		return
	_newest_tick = tick
	for fighter: Fighter in _fighters:
		if not is_instance_valid(fighter):
			continue
		for event: Event in shown_events(fighter):
			if event.stamp == tick and not _counted.has(event.key):
				_counted[event.key] = tick
				events += 1
	_forget_old(_counted)


# A stamp older than netfox's history can come back from no rollback, so its key may go, unless
# a fighter still shows it: the double jump's stamp stays for the whole flight.
func _forget_old(keys: Dictionary[String, int]) -> void:
	var oldest := NetworkRollback.history_start
	var shown: Dictionary[String, bool] = { }
	for fighter: Fighter in _fighters:
		if is_instance_valid(fighter):
			for event: Event in shown_events(fighter):
				shown[event.key] = true
	for key: String in keys.keys():
		if keys[key] < oldest and not shown.has(key):
			keys.erase(key)


func _draw(fighter: Fighter, kind: Kind) -> void:
	if kind == Kind.DASH:
		add_child(Trail.new(fighter, _config))
	else:
		add_child(Puff.new(fighter, _config))


# One event of a fighter, with its key: the fighter, the kind and the stamp.
class Event:
	var kind: Kind
	var stamp: int
	var key: String


	func _init(fighter: Fighter, event_kind: Kind, event_stamp: int) -> void:
		kind = event_kind
		stamp = event_stamp
		key = "%d/%d/%d" % [fighter.get_instance_id(), event_kind, event_stamp]


# A see-through material in the fighter's tone, lit by nothing, so it reads the same anywhere.
static func material_of(fighter: Fighter) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(fighter.tone, OPACITY)
	return material


# The trail of a dash: the space the capsule swept, from where the dash first showed to where
# the body is, as wide and as tall as the capsule. It follows the body while that dash lasts,
# then fades over the dash's own duration.
class Trail:
	extends MeshInstance3D

	var _fighter: Fighter
	var _stamp: int
	var _from: Vector3
	var _height: float
	var _width: float
	var _fade_s: float
	var _left_s := -1.0
	var _material: StandardMaterial3D


	func _init(fighter: Fighter, config: MovementConfig) -> void:
		name = "DashTrail"
		_fighter = fighter
		_stamp = fighter.state.dash_tick
		_from = fighter.global_position
		_height = config.capsule_height
		_width = 2.0 * config.capsule_radius
		_fade_s = float(config.dash_ticks) / config.tickrate
		var box := BoxMesh.new()
		box.size = Vector3.ONE
		_material = ManeuverCues.material_of(fighter)
		box.material = _material
		mesh = box
		cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		top_level = true
		visible = false


	func _process(delta: float) -> void:
		if _left_s < 0.0:
			if is_instance_valid(_fighter) and _in_its_dash():
				_reach(_fighter.global_position)
				return
			_left_s = _fade_s
		_left_s -= delta
		if _left_s <= 0.0:
			queue_free()
			return
		_material.albedo_color.a = OPACITY * _left_s / _fade_s


	func _in_its_dash() -> bool:
		var state := _fighter.state
		return state.mode == FighterState.Mode.DASH and state.dash_tick == _stamp


	# Stretches the box from where the dash showed to the feet at to.
	func _reach(to: Vector3) -> void:
		var along := to - _from
		var length := along.length()
		visible = length > 0.0
		if not visible:
			return
		var middle := (_from + to) / 2.0 + Vector3.UP * _height / 2.0
		var forward := along / length
		var up := Vector3.UP if absf(forward.dot(Vector3.UP)) < 0.99 else Vector3.BACK
		var turn := Basis.looking_at(forward, up)
		global_transform = Transform3D(turn.scaled_local(Vector3(_width, _height, length)), middle)


# The puff of a double jump: a flat disc under the feet where the jump came out, growing from the
# capsule's radius while it fades, over the jump's rise.
class Puff:
	extends MeshInstance3D

	var _radius: float
	var _life_s: float
	var _age_s := 0.0
	var _material: StandardMaterial3D


	func _init(fighter: Fighter, config: MovementConfig) -> void:
		name = "DoubleJumpPuff"
		_radius = config.capsule_radius
		_life_s = float(config.rise_ticks) / config.tickrate
		var disc := CylinderMesh.new()
		disc.top_radius = 1.0
		disc.bottom_radius = 1.0
		disc.height = DISC_THICKNESS
		_material = ManeuverCues.material_of(fighter)
		disc.material = _material
		mesh = disc
		cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		top_level = true
		position = fighter.global_position
		_grow(0.0)


	func _process(delta: float) -> void:
		_age_s += delta
		if _age_s >= _life_s:
			queue_free()
			return
		var share := _age_s / _life_s
		_grow(share)
		_material.albedo_color.a = OPACITY * (1.0 - share)


	func _grow(share: float) -> void:
		var radius := _radius * lerpf(1.0, PUFF_GROWTH, share)
		scale = Vector3(radius, 1.0, radius)
