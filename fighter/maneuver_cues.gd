# The cues of the maneuvers (DEC-0031 §6; TASK-10.4): a puff under the feet when a double jump
# comes out, a trail behind a dash, a mark on the wall a wall jump leaves (TASK-10.5), a short
# trail behind a wall run (TASK-10.10; movimento.md, "O que se vê na parede"), and the grapple's
# cable and the short trail of its pull (TASK-10.6; visual-e-audio.md, "O gancho na tela"), and
# the same short trail on a slide off another fighter's head (TASK-10.7; visual-e-audio.md, "A
# cabeça do outro na tela"), each played once per event, by its key: the fighter, the kind and the
# stamp, the tick the state carries for it. Like the `key` of a list in React, the key says "this
# one already showed": after every tick loop it reads the displayed state, and a
# key that already played never plays again, however many times a rollback runs its tick again.
# A cue never undoes either: a rollback that takes the event away leaves it showing (DEC-0031 §6).
# Only visual in the v0; the sound waits for a licensed pack (DEC-0029; Q-32). The cue wears the
# fighter's own neutral tone, never a colour of the combat tokens (DEC-0031; visual-e-audio.md),
# and its sizes and times come from the movement numbers: the capsule, the dash and the jump.
# The mark of the wall jump is the puff stood up against the wall: Claude's v0 reading (DEC-0017).
# The wall run's trail is the dash's, cut short to the body's last dash duration of path, with
# the same material: Claude's v0 reading of "um rastro curto" (DEC-0017; no new asset, DEC-0029).
# The grapple's pull and the slide off a head wear the same short trail. The grapple's cable is
# the one opaque cue: a line from the shoulder to the point, drawn by Godot's own shapes too
# (visual-e-audio.md, "O gancho na tela").
# The light attack adds two cues (visual-e-audio.md, "O leve na tela"; TASK-12.1): the arc's trail
# in vermilion, once per swing, keyed by the tick its active began; and the white flash of the body
# of whoever took a hit, 100 ms, once per hit, keyed by the tick of the hit's contact. That stamp
# is the attacker's tick, and the hit first shows in the target's state on the next one, the first
# whose photo shows the contact (DEC-0051 §3): the event says the tick it first shows on.
# It also counts, for the SyncTest, the events the simulation made on its fresh ticks: there,
# with the rollback forced on every tick, the cues presented must equal the events (DEC-0031 §6;
# rede.md §4).
class_name ManeuverCues
extends Node

## What a cue shows, part of its key.
enum Kind {
	DOUBLE_JUMP,
	DASH,
	WALL_JUMP,
	WALL_RUN,
	GRAPPLE_CABLE,
	GRAPPLE_PULL,
	HEAD_SLIDE,
	SWING,
	HIT,
}

## The cue's opacity when it appears; it fades to nothing. Claude's v0 reading (DEC-0017): seen
## through, so the cue never hides a body behind it.
const OPACITY := 0.4
## The puff grows from the capsule's radius to this many radii while it fades. Claude's v0
## reading (DEC-0017).
const PUFF_GROWTH := 3.0
## m: the puff is a disc this thin, as thin as the ruler's strips (TASK-10.4, "Arena").
const DISC_THICKNESS := 0.01
## m: the grapple's cable, a line this thick (visual-e-audio.md, "O gancho na tela").
const CABLE_THICKNESS := 0.03
## s: the white flash of a hit taken (visual-e-audio.md, "O leve na tela": "o flash branco do
## corpo de quem levou, 100 ms").
const FLASH_S := 0.1
## The active token's vermilion, on the arc's trail (visual-e-audio.md, "Os três canais por
## estado").
const SWING_COLOUR := Sword.ACTIVE_COLOUR

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


# The events fighter's state shows now: the double jump of this flight, by its stamp; the dash
# while it lasts, by the tick it began; the wall jump during the flight it began, the air since
# its stamp; the wall run while it lasts, by the tick it began, so a seam, which keeps the run's
# clock, is the same run (F-129); the grapple's cable while it is in the air, flying or pulling,
# by the tick it was fired; the pull while it lasts, by the tick it began; and the slide off a
# head while it lasts, by the tick the contact with that head began, once per landing. A dash_tick
# or a wall_jump_tick that stays after its maneuver shows no cue, so a fighter seen for the first
# time long after never plays an old one; grapple_fired_tick goes back to NEVER on the release,
# and head_landing_tick off the head.
static func shown_events(fighter: Fighter) -> Array[Event]:
	var shown: Array[Event] = []
	var state := fighter.state
	if state.double_jump_tick != FighterState.NEVER:
		shown.append(Event.new(fighter, Kind.DOUBLE_JUMP, state.double_jump_tick))
	if state.mode == FighterState.Mode.DASH:
		shown.append(Event.new(fighter, Kind.DASH, state.dash_tick))
	var in_its_flight := state.mode == FighterState.Mode.AIR
	if in_its_flight and state.wall_jump_tick != FighterState.NEVER:
		if state.mode_since == state.wall_jump_tick:
			shown.append(Event.new(fighter, Kind.WALL_JUMP, state.wall_jump_tick))
	if state.mode == FighterState.Mode.WALL_RUN:
		shown.append(Event.new(fighter, Kind.WALL_RUN, state.mode_since))
	if state.grapple_fired_tick != FighterState.NEVER:
		shown.append(Event.new(fighter, Kind.GRAPPLE_CABLE, state.grapple_fired_tick))
	if state.mode == FighterState.Mode.GRAPPLE:
		shown.append(Event.new(fighter, Kind.GRAPPLE_PULL, state.mode_since))
	if state.slide_off_dir != Vector3.ZERO:
		shown.append(Event.new(fighter, Kind.HEAD_SLIDE, state.head_landing_tick))
	if state.action == FighterState.Action.ACTIVE:
		shown.append(Event.new(fighter, Kind.SWING, state.action_since))
	if state.hurt_tick != FighterState.NEVER:
		# The contact's tick, applied on the next one: like the double jump's stamp, it stays.
		shown.append(Event.new(fighter, Kind.HIT, state.hurt_tick, state.hurt_tick + 1))
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


# After every tick netfox simulates: on a fresh one, the events that first show on that tick.
func _count(tick: int) -> void:
	if tick <= _newest_tick:
		return
	_newest_tick = tick
	for fighter: Fighter in _fighters:
		if not is_instance_valid(fighter):
			continue
		for event: Event in shown_events(fighter):
			if event.shows == tick and not _counted.has(event.key):
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
	match kind:
		Kind.DASH:
			add_child(Trail.new(fighter, _config, Kind.DASH))
		Kind.WALL_RUN:
			add_child(Trail.new(fighter, _config, Kind.WALL_RUN))
		Kind.GRAPPLE_PULL:
			add_child(Trail.new(fighter, _config, Kind.GRAPPLE_PULL))
		Kind.HEAD_SLIDE:
			add_child(Trail.new(fighter, _config, Kind.HEAD_SLIDE))
		Kind.GRAPPLE_CABLE:
			add_child(Cable.new(fighter, _config))
		Kind.WALL_JUMP:
			add_child(Puff.new(fighter, _config, fighter.state.wall_normal))
		Kind.SWING:
			if fighter.combat != null:
				add_child(SwingTrail.new(fighter, fighter.combat))
		Kind.HIT:
			fighter.flash(FLASH_S)
		_:
			add_child(Puff.new(fighter, _config, Vector3.ZERO))


# One event of a fighter, with its key: the fighter, the kind and the stamp; and the tick it first
# shows on, the stamp itself but for a hit.
class Event:
	var kind: Kind
	var stamp: int
	var shows: int
	var key: String


	func _init(
		fighter: Fighter,
		event_kind: Kind,
		event_stamp: int,
		first_shown := FighterState.NEVER,
	) -> void:
		kind = event_kind
		stamp = event_stamp
		shows = event_stamp if first_shown == FighterState.NEVER else first_shown
		key = "%d/%d/%d" % [fighter.get_instance_id(), event_kind, event_stamp]


# A see-through material in the fighter's tone, lit by nothing, so it reads the same anywhere.
static func material_of(fighter: Fighter) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(fighter.tone, OPACITY)
	return material


# The same tone, opaque: the cable is a line, and a line seen through would vanish against the sky.
static func solid_material_of(fighter: Fighter) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(fighter.tone, 1.0)
	return material


# The basis of a box of size thickness x height x length laid from from to to, its length along
# the segment: the trails and the cable stretch a unit box this way.
static func stretch(from: Vector3, to: Vector3, across: float, height: float) -> Transform3D:
	var along := to - from
	var length := along.length()
	var forward := along / length
	var up := Vector3.UP if absf(forward.dot(Vector3.UP)) < 0.99 else Vector3.BACK
	var turn := Basis.looking_at(forward, up)
	return Transform3D(turn.scaled_local(Vector3(across, height, length)), (from + to) / 2.0)


# The trail of a dash: the space the capsule swept, from where the dash first showed to where
# the body is, as wide and as tall as the capsule. It follows the body while that dash lasts,
# then fades over the dash's own duration. The trail of a wall run is the same box, short: it
# covers only the path of the body's last dash duration, so it follows the body along the wall
# instead of drawing the whole run, and fades the same way once the run ends. The grapple's pull
# wears the wall run's short trail, from where the body was 200 ms ago, and fades 200 ms after
# the release (visual-e-audio.md, "O gancho na tela"); so does the slide off a head, from its
# landing until the body leaves the head, and 200 ms after (visual-e-audio.md, "A cabeça do outro
# na tela").
class Trail:
	extends MeshInstance3D

	var _fighter: Fighter
	var _kind: Kind
	var _stamp: int
	var _from: Vector3
	var _height: float
	var _width: float
	var _fade_s: float
	var _left_s := -1.0
	var _material: StandardMaterial3D
	# The wall run's short tail: the body's feet on each displayed frame, with netfox's tick then,
	# back to the first one at least _tail_ticks old. The tick, not the frame's time, so the tail
	# is as long at any frame rate.
	var _tail_ticks: int
	var _seen_tick: Array[int] = []
	var _seen_at: Array[Vector3] = []


	func _init(fighter: Fighter, config: MovementConfig, kind: Kind) -> void:
		var trailed := kind == Kind.DASH or kind == Kind.WALL_RUN or kind == Kind.GRAPPLE_PULL
		trailed = trailed or kind == Kind.HEAD_SLIDE
		assert(trailed, "a trail follows a dash, a wall run, a grapple's pull or a head's slide")
		_kind = kind
		_fighter = fighter
		match kind:
			Kind.DASH:
				name = "DashTrail"
				_stamp = fighter.state.dash_tick
			Kind.WALL_RUN:
				name = "WallRunTrail"
				_stamp = fighter.state.mode_since
			Kind.HEAD_SLIDE:
				name = "HeadSlideTrail"
				_stamp = fighter.state.head_landing_tick
			_:
				name = "GrapplePullTrail"
				_stamp = fighter.state.mode_since
		_from = fighter.global_position
		_height = config.capsule_height
		_width = 2.0 * config.capsule_radius
		_fade_s = float(config.dash_ticks) / config.tickrate
		_tail_ticks = config.dash_ticks
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
			if is_instance_valid(_fighter) and _in_its_maneuver():
				var to := _fighter.global_position
				if _kind != Kind.DASH:
					_from = _tail(to)
				_reach(to)
				return
			_left_s = _fade_s
		_left_s -= delta
		if _left_s <= 0.0:
			queue_free()
			return
		_material.albedo_color.a = OPACITY * _left_s / _fade_s


	func _in_its_maneuver() -> bool:
		var state := _fighter.state
		match _kind:
			Kind.WALL_RUN:
				return state.mode == FighterState.Mode.WALL_RUN and state.mode_since == _stamp
			Kind.GRAPPLE_PULL:
				return state.mode == FighterState.Mode.GRAPPLE and state.mode_since == _stamp
			Kind.HEAD_SLIDE:
				return state.slide_off_dir != Vector3.ZERO and state.head_landing_tick == _stamp
		return state.mode == FighterState.Mode.DASH and state.dash_tick == _stamp


	# Where the body was the dash's duration ago, or where the run, the pull or the slide first
	# showed while it is younger.
	func _tail(to: Vector3) -> Vector3:
		var now := NetworkTime.tick
		_seen_tick.append(now)
		_seen_at.append(to)
		while _seen_tick.size() > 1 and now - _seen_tick[1] >= _tail_ticks:
			_seen_tick.pop_front()
			_seen_at.pop_front()
		return _seen_at[0]


	# Stretches the box from where the dash showed to the feet at to.
	func _reach(to: Vector3) -> void:
		visible = to != _from
		if not visible:
			return
		var lift := Vector3.UP * _height / 2.0
		global_transform = ManeuverCues.stretch(_from + lift, to + lift, _width, _height)


# The grapple's cable (visual-e-audio.md, "O gancho na tela"): a line CABLE_THICKNESS thick, opaque
# and unlit in the fighter's tone, from the displayed shoulder, aim_height above the feet, to its
# tip. While the cable flies, the tip goes from the shoulder to the point over grapple_attach_ticks,
# counted in netfox's ticks from the fire, so it reaches the point on the pull's first tick at any
# frame rate; during the pull it stays on the point; on the release the cable goes at once.
class Cable:
	extends MeshInstance3D

	var _fighter: Fighter
	var _stamp: int
	var _point: Vector3
	var _shoulder: float
	var _attach_ticks: int


	func _init(fighter: Fighter, config: MovementConfig) -> void:
		name = "GrappleCable"
		_fighter = fighter
		_stamp = fighter.state.grapple_fired_tick
		_point = fighter.state.grapple_point
		_shoulder = config.aim_height
		_attach_ticks = config.grapple_attach_ticks
		var box := BoxMesh.new()
		box.size = Vector3.ONE
		box.material = ManeuverCues.solid_material_of(fighter)
		mesh = box
		cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		top_level = true
		visible = false


	func _process(_delta: float) -> void:
		var out := is_instance_valid(_fighter) and _fighter.state.grapple_fired_tick == _stamp
		if not out:
			queue_free()
			return
		_follow()


	# How far the tip has gone from the shoulder to the point, 0 to 1: the ticks the state on
	# screen has run since the fire, over the cable's ticks. The state on screen is the one of the
	# tick before netfox's clock.
	func reach() -> float:
		if _attach_ticks <= 0:
			return 1.0
		var flown := NetworkTime.tick - 1 - _stamp
		return clampf(float(flown) / _attach_ticks, 0.0, 1.0)


	func tip() -> Vector3:
		return shoulder().lerp(_point, reach())


	func shoulder() -> Vector3:
		return _fighter.global_position + Vector3.UP * _shoulder


	func _follow() -> void:
		var from := shoulder()
		var to := tip()
		visible = from.distance_to(to) > CABLE_THICKNESS
		if visible:
			global_transform = ManeuverCues.stretch(from, to, CABLE_THICKNESS, CABLE_THICKNESS)


# The puff of a double jump: a flat disc under the feet where the jump came out, growing from the
# capsule's radius while it fades, over the jump's rise. Given a wall's normal, it is the mark of
# a wall jump instead: the same disc stood up on the wall, beside the body's middle.
class Puff:
	extends MeshInstance3D

	var _radius: float
	var _life_s: float
	var _age_s := 0.0
	var _material: StandardMaterial3D


	func _init(fighter: Fighter, config: MovementConfig, wall_normal: Vector3) -> void:
		name = "DoubleJumpPuff" if wall_normal == Vector3.ZERO else "WallJumpMark"
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
		if wall_normal != Vector3.ZERO:
			# The disc's axis along the normal, its face on the wall where the body touched it.
			var side := Vector3.UP.cross(wall_normal).normalized()
			basis = Basis(side, wall_normal, side.cross(wall_normal))
			position += Vector3.UP * config.capsule_height / 2.0 - wall_normal * _radius
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
		basis = basis.orthonormalized().scaled_local(Vector3(radius, 1.0, radius))


# The arc's trail of a swing (visual-e-audio.md, "O leve na tela"): the ring the blade swept, from
# the hand's 0,6 m to the tip's 2,0 m off the attacker's axis at the hand's height, from the arc's
# start to the end of the displayed tick's slice, in vermilion and seen through. It follows the
# body while that swing's active lasts, then fades over FADE_S. Claude's v0 reading of "o rastro
# do arco" (DEC-0017): Godot's own triangles, no new asset (DEC-0029).
class SwingTrail:
	extends MeshInstance3D

	## s: the fade after the active. Claude's v0 reading (DEC-0017).
	const FADE_S := 0.2
	## Steps of the ring per radian of arc: two triangles each.
	const STEPS_PER_RAD := 12.0

	var _fighter: Fighter
	var _combat: CombatConfig
	var _attack: AttackConfig
	var _stamp: int
	var _yaw: float
	var _left_s := -1.0
	var _material := StandardMaterial3D.new()
	var _mesh := ImmediateMesh.new()


	func _init(fighter: Fighter, combat: CombatConfig) -> void:
		name = "SwingTrail"
		_fighter = fighter
		_combat = combat
		_stamp = fighter.state.action_since
		_yaw = fighter.state.action_yaw
		_attack = combat.attacks[fighter.state.action_move]
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_material.albedo_color = Color(SWING_COLOUR, OPACITY)
		mesh = _mesh
		material_override = _material
		cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		top_level = true
		# Top level, its position is the world's once in the tree.
		position = fighter.global_position
		_sweep(1)


	func _process(delta: float) -> void:
		if _left_s < 0.0:
			var state := _fighter.state if is_instance_valid(_fighter) else null
			var swinging := state != null and state.action == FighterState.Action.ACTIVE
			if swinging and state.action_since == _stamp:
				global_position = _fighter.global_position
				_sweep(NetworkTime.tick - 1 - _stamp + 1)
				return
			_sweep(_attack.active_ticks)
			_left_s = FADE_S
		_left_s -= delta
		if _left_s <= 0.0:
			queue_free()
			return
		_material.albedo_color.a = OPACITY * _left_s / FADE_S


	## The ring from the arc's start to the end of the k-th slice, around the node's origin, the
	## attacker's feet.
	func _sweep(k: int) -> void:
		var to := Blade.slice_of(_attack, clampi(k, 1, _attack.active_ticks)).y
		var from := _attack.arc_from
		var steps := maxi(1, ceili(absf(to - from) * STEPS_PER_RAD))
		var inner := _combat.hand_offset
		var outer := _combat.hand_offset + _combat.blade_length
		var up := Vector3.UP * _combat.hand_height
		_mesh.clear_surfaces()
		_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _material)
		for step: int in steps:
			var a := Blade.direction(_yaw + lerpf(from, to, float(step) / steps))
			var b := Blade.direction(_yaw + lerpf(from, to, float(step + 1) / steps))
			for corner: Vector3 in [
				a * inner,
				a * outer,
				b * outer,
				a * inner,
				b * outer,
				b * inner,
			]:
				_mesh.surface_add_vertex(up + corner)
		_mesh.surface_end()
