# The fighter node (visao-geral.md, "As cenas"; DEC-0022): a thin adapter between netfox, the
# engine and the pure core. In _rollback_tick it only calls Movement and mirrors the result: the
# core decides, move_and_slide() moves and collides, the core confers with the facts the engine
# gives back, the floor, the wall, another fighter's head under the feet and, when the core asks,
# what the aim finds (the tick sandwich; DEC-0042; DEC-0044; TASK-10.7). The two rollback contours
# of DEC-0025 live here because they touch the engine, never the core. The same code runs in
# Sozinho, on the server and on the clients (DEC-0026 §5).
class_name Fighter
extends CharacterBody3D

# Neutral tones, outside the colours of the combat tokens (visual-e-audio.md; DEC-0031): the
# fighter of whoever plays on this PC lighter than every surface of the arena, any other darker
# than every one, the floor and the border included (visual-e-audio.md, "A cara da arena";
# F-156 §3; F-158). The light grey stays short of white, the reaction token's flash, so it does
# not burn out under the sun and the Filmic tonemapping. The camera following one's own fighter
# tells them apart without relying on colour alone.
const OWN_TONE := Color(0.86, 0.86, 0.84)
const OTHER_TONE := Color(0.11, 0.11, 0.13)
# m/s: the probe move of contour D (DEC-0025 §2), the speed of the Desenho 3 probe whose SyncTest
# proved it (netfox-sonda, probe_fighter.gd; F-025 §4). For one tick it moves the body 0.83 mm at
# 60 ticks, and the body goes back right after.
const FLOOR_PROBE_SPEED := 0.05
# m: during a wall run, how far into the wall the test-only probe looks for it (DEC-0042 §1). It
# moves nothing; probe A measured it holding the contact on every tick beside the wall, a seam's
# included, from 0 to 4.5 cm off the face (rede.md §4, "A sonda A da parede").
const WALL_PROBE_DISTANCE := 0.05
# m: how far before the aim's point the shoulder's ray may stop and still see it (aim_ray). An
# engine tolerance, not a game number: that ray ends on the very face the first one found, and the
# engine may report the face there, a hair before the point; a corner stops it well before.
const SIGHT_TOLERANCE := 0.05
# m: when the engine's floor came only from its snap, with no collision of the move at a floor
# angle, how far down the test-only probe looks for what holds the feet. It moves nothing. Probe C
# measured such ticks on another fighter's head, 9 of 49 standing on it and 29 of 31 when the head
# walked away, and this probe named the fighter below on every one of them (rede.md §4, "A sonda
# C"). The wall run's distance.
const HEAD_PROBE_DISTANCE := 0.05
# rad: the slack the engine adds to floor_max_angle when it judges a floor (character_body_3d.cpp,
# FLOOR_ANGLE_THRESHOLD, Godot 4.7.2): a collision within it is a floor collision. An engine
# number, not a game one.
const FLOOR_ANGLE_THRESHOLD := 0.01

## The input box, recorded by netfox as Input:move, Input:yaw, Input:pitch, Input:jump,
## Input:dash and Input:grapple.
@export var input: FighterInput
## netfox's node that records the boxes on every tick and sends them over the network.
@export var synchronizer: RollbackSynchronizer
## The capsule the engine collides, shaped from the configuration at setup.
@export var collision: CollisionShape3D
## What the screen shows; it only reads the state.
@export var visual: Node3D
## The capsule the screen shows, inside the visual.
@export var body_mesh: MeshInstance3D

## The movement numbers of the match, in ticks; the Match passes them by hand (DEC-0022).
var config: MovementConfig
## The node a wall's identity is relative to (DEC-0042 §2): the Match gives its Arena, so a wall
## is ParedeLonga on the server, on a client and in a replay alike. Left null, the fighter's parent
## stands in, as in the tests that build a world of their own.
var arena: Node
## The rules box, recorded by netfox field by field (":state:mode" and the others; DEC-0022).
var state := FighterState.new()
## The neutral tone the body is painted in, OWN_TONE or OTHER_TONE; its maneuver cues take it too
## (ManeuverCues), so no cue wears a colour of the combat tokens (DEC-0031).
var tone := OTHER_TONE

# Contour D waits for the first tick of each rollback loop (DEC-0025 §2).
var _engine_floor_pending := false
# The lean on screen during a wall run (lean): how far it has come in, from 0 to 1, and the flat
# normal of the wall it leans away from, kept while it goes out. Only the screen reads them: they
# are never in the state, so no rollback, replay or SyncTest sees them (DEC-0031 §6).
var _lean_share := 0.0
var _lean_normal := Vector3.ZERO


# The engine's floor snap must catch a body at the fastest ground speed down the steepest floor:
# the dash, 20 m/s, faster than the run's 7 (movimento.md, "Dash": "Descendo a rampa de 45°";
# TASK-10.4). In one tick the body moves speed / tickrate across, and a slope of floor_max_angle
# falls tan(angle) times that: 20 / 60 * tan(45°) = 0.3333 m at 60 ticks and 0.6667 m at 30. On
# top of the drop, the engine keeps a body up to one safe margin off the floor and its downward
# cast stops one margin short, both along the floor's normal: two margins / cos(angle) upright,
# and a third keeps the worst case off the edge. At 60 ticks on 45° that is 0.3333 + 0.0042 =
# 0.338 m, against the 0.121 m the run alone needed (TASK-9). For the run, measured by hand on the
# crest of a 45° ramp with the rig of test/fighter/fighter_slope_test.gd, 0.1187 m lost the floor
# and 0.1197 m held; that test runs the dash down the ramp with this snap and with the run's. A
# shorter snap throws the body off the ramp; a longer one glues it to drops that should be ledges:
# a step down of up to 0.338 m is now floor, and the arena's only drop, the 1 m ledge, is far
# longer (F-122).
static func floor_snap_for(movement_config: MovementConfig, margin: float) -> float:
	var fastest := maxf(movement_config.run_speed, movement_config.dash_speed)
	return snap_for_speed(movement_config, margin, fastest)


# The snap that catches a body crossing the steepest floor at speed m/s, as above.
static func snap_for_speed(movement_config: MovementConfig, margin: float, speed: float) -> float:
	var angle := movement_config.floor_max_angle
	assert(angle < PI / 2.0, "a floor of 90 degrees has no snap: it is a wall")
	var across_per_tick := speed / movement_config.tickrate
	return across_per_tick * tan(angle) + 3.0 * margin / cos(angle)


# Puts the fighter at its spawn point, its feet on the floor and its body looking along
# spawn_yaw. The Match calls it before the fighter enters the tree, so netfox records this as the
# first state. A fresh FighterState stands on the floor, so the body must too: spawned in the
# air, it would leave the floor on its first tick and open a coyote window.
func setup(
	movement_config: MovementConfig,
	spawn_position: Vector3,
	spawn_yaw: float,
	own: bool,
) -> void:
	config = movement_config
	collision_layer = PhysicsLayers.FIGHTERS
	# The lid over the arena stops the body only (DEC-0049 §2): the rays of the aim, the grapple
	# and the wall ask PhysicsLayers.WORLD alone, and the wall facts skip it (_is_bounds).
	collision_mask = PhysicsLayers.WORLD | PhysicsLayers.FIGHTERS | PhysicsLayers.BOUNDS
	# The engine judges the floor with the design's slope (movimento.md, "O corpo"); the core
	# reads its verdict in MoveFacts.on_floor.
	floor_max_angle = config.floor_max_angle
	floor_snap_length = floor_snap_for(config, safe_margin)
	# Only the scenery carries a body standing on it, and leaving a body adds nothing: another
	# fighter's head is not floor for the rules (movimento.md, "O corpo": "A cabeça do outro"), so
	# it is no moving platform either (TASK-10.7, choice 2; F-152). Probe C measured no platform
	# velocity on a head either way, a still head or a walking one (rede.md §4, "A sonda C"): the
	# setting writes the rule down rather than curing anything.
	platform_floor_layers = PhysicsLayers.WORLD
	platform_on_leave = CharacterBody3D.PLATFORM_ON_LEAVE_DO_NOTHING
	position = spawn_position
	state = FighterState.new()
	state.facing_yaw = spawn_yaw
	input.face(spawn_yaw)
	# Only the server sends a fighter's state, and only to the peers it told that the fighter
	# exists (send_state_to): a state for a node a client does not have yet is dropped with a
	# warning (netfox's dense-snapshot-serializer.gd).
	synchronizer.visibility_filter.default_visibility = false
	_shape_capsule()
	tone = OWN_TONE if own else OTHER_TONE
	_paint(tone)


## Paints the body, and the cues it plays from now on, in tone (OWN_TONE or OTHER_TONE). setup()
## picks it by who drives the fighter; Sozinho's dummy, driven by this PC but not the player's,
## wears the other's (Match.solo_tone).
func wear(new_tone: Color) -> void:
	tone = new_tone
	_paint(tone)


# From now on the server sends this fighter's state to peer, which mirrors the fighter.
func send_state_to(peer: int) -> void:
	synchronizer.visibility_filter.set_visibility_for(peer, true)
	synchronizer.visibility_filter.update_visibility()


func _enter_tree() -> void:
	NetworkRollback.before_loop.connect(_on_rollback_loop_start)
	NetworkRollback.after_prepare_tick.connect(_push_transform_to_physics)
	NetworkRollback.on_process_tick.connect(_align_engine_floor_once)


func _exit_tree() -> void:
	NetworkRollback.before_loop.disconnect(_on_rollback_loop_start)
	NetworkRollback.after_prepare_tick.disconnect(_push_transform_to_physics)
	NetworkRollback.on_process_tick.disconnect(_align_engine_floor_once)


func _process(delta: float) -> void:
	lean(delta)


# What the screen shows of the state, once per displayed frame: the body looks where the state
# says (the capsule is round, the visor shows the facing), and during a wall run the capsule and
# its visor lean away from the wall, pivoting on the feet, coming in and going out linearly over
# the lean's time (movimento.md, "Corrida na parede": "O que se vê na parede"; Q-37). It reads the
# state and writes only the visual node: the simulation never sees the lean (DEC-0004, rule 2).
func lean(delta: float) -> void:
	if config == null:
		# Not set up yet: there is no lean to read, only the facing.
		visual.basis = Basis(Vector3.UP, state.facing_yaw)
		return
	var running := state.mode == FighterState.Mode.WALL_RUN
	var wall := _flat(state.wall_normal)
	if running and wall != Vector3.ZERO:
		_lean_normal = wall
	var target := 1.0 if running and _lean_normal != Vector3.ZERO else 0.0
	var step := INF if config.wall_lean_s <= 0.0 else delta / config.wall_lean_s
	_lean_share = move_toward(_lean_share, target, step)
	var facing := Basis(Vector3.UP, state.facing_yaw)
	if _lean_share <= 0.0:
		visual.basis = facing
		return
	# A turn about the wall's tangent, UP x normal, takes the top toward the normal: away.
	var tangent := Vector3.UP.cross(_lean_normal).normalized()
	visual.basis = Basis(tangent, config.wall_lean * _lean_share) * facing


## The visual's lean away from the last wall, in rad: 0 at rest, the full lean on a wall run.
func lean_angle() -> float:
	return config.wall_lean * _lean_share


# The tick sandwich (visao-geral.md, "O tick por dentro"): netfox has restored the state and the
# input of this tick, and the contours have run.
func _rollback_tick(_delta: float, tick: int, _is_fresh: bool) -> void:
	var tick_input := input.to_tick_input()
	var plan := Movement.before_move(state, global_position, velocity, tick_input, config, tick)
	# move_and_slide() moves by velocity times the frame's delta, and a tick is not a frame:
	# physics_factor turns the move into exactly one tick (netfox's rollback-caveats.md). The
	# velocity is divided back, so the state keeps m/s. With the tick in the physics step it is
	# exactly 1 (DEC-0040); it stays so a tick run outside the physics step still moves one tick.
	velocity = plan.velocity * NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor
	var facts := MoveFacts.new()
	facts.on_floor = is_on_floor()
	facts.velocity = velocity
	_wall_contact(plan.state, facts)
	_head_contact(facts)
	facts.position = global_position
	# The aim request (DEC-0044 §1): a grapple press that can fire waits, so the ray leaves the
	# point O after the move, along this tick's yaw and pitch, the yaw before_move copied into
	# facing_yaw (DEC-0045 §2). A resimulated tick casts it again from the restored body and input:
	# probe B measured the same answer there (rede.md §4).
	if plan.aim_request:
		var hit := aim_ray(global_position, tick_input.yaw, tick_input.pitch)
		facts.aim_hit = not hit.is_empty()
		if facts.aim_hit:
			var point: Vector3 = hit["position"]
			facts.aim_point = point
	state = Movement.after_move(plan.state, facts, config, tick)


# The wall facts of DEC-0042 §1, read right after the move. During a wall run, parallel to the
# wall, the move itself collides with nothing on almost every tick (rede.md §4: 100 % of the
# ticks beside the wall), so a test-only probe asks the engine whether a move WALL_PROBE_DISTANCE
# into the wall of the state would hit, and moves nothing. Out of a run, the move's own
# collisions tell the entry: of the colliders that are not a fighter nor the arena's lid
# (_is_bounds), the one with the most horizontal normal, the first in the engine's order on a tie.
# The core judges whether it is a wall at all. A wall must also rise above the head
# (covers_body): when the ray above the head finds no face, the node reports no wall, so the
# entry is refused and a run ends as at the edge (movimento.md, "Corrida na parede": "A parede
# passa da cabeça"; TASK-10.10).
func _wall_contact(prior: FighterState, facts: MoveFacts) -> void:
	if prior.mode == FighterState.Mode.WALL_RUN:
		var hit := move_and_collide(-prior.wall_normal * WALL_PROBE_DISTANCE, true)
		if hit == null or hit.get_collider() is Fighter or _is_bounds(hit.get_collider()):
			return
		var id := _wall_id_of(hit.get_collider())
		# The run's own face while the probe reads it (the same collider, or a seam within the
		# same-face angle, F-129): the state keeps the face's normal, so a rounded edge's slanted
		# reading never aims the head ray off the face. Another face aims it along its own normal.
		var face := _flat(hit.get_normal())
		if id == prior.wall_id or face.dot(prior.wall_normal) >= config.wall_same_face_cos:
			face = prior.wall_normal
		if covers_body(face):
			facts.wall_normal = hit.get_normal()
			facts.wall_id = id
		return
	_read_slide_contact(facts)
	# Only a face steep enough to be a wall asks the head ray; the core turns the rest away.
	var steep := absf(facts.wall_normal.y) <= config.wall_max_normal_y
	if not facts.wall_id.is_empty() and steep and not covers_body(_flat(facts.wall_normal)):
		facts.wall_normal = Vector3.ZERO
		facts.wall_id = &""


## Whether the wall covers the body and rises above the head (movimento.md, "Corrida na parede":
## "A parede passa da cabeça"): a ray wall_ray_height above the feet, 30 cm above the head, from
## the capsule's axis toward
## the face, as far as the capsule's radius plus WALL_PROBE_DISTANCE, hits a face of the world
## whose flat normal is within the same-face angle of face_normal. Any collider counts, so a stack
## of blocks in one plane is one wall. A query of the physics space: it moves nothing and changes
## no flag of the engine, the fighters are not on its mask, and the world it reads never moves,
## so a resimulated tick asks the same question at the same position and gets the same answer
## (rede.md §4; DEC-0042).
func covers_body(face_normal: Vector3) -> bool:
	var face := _flat(face_normal)
	if face == Vector3.ZERO:
		return false
	var head := global_position + Vector3.UP * config.wall_ray_height
	var reach := config.capsule_radius + WALL_PROBE_DISTANCE
	var query := PhysicsRayQueryParameters3D.create(
		head,
		head - face * reach,
		PhysicsLayers.WORLD,
		[get_rid()],
	)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return false
	var normal: Vector3 = hit["normal"]
	return _flat(normal).dot(face) >= config.wall_same_face_cos


## The aim's ray (DEC-0044 §1; DEC-0045 §2 and §3; movimento.md, "Gancho": "De onde sai a mira",
## "A quina"): from the point O of feet and yaw (Aim.origin), on the line of the screen's centre,
## along Aim.direction(yaw, pitch), as far as the grapple's range. When it finds the world, a
## second ray goes from the shoulder, aim_height above feet, to the point: stopped by anything
## more than SIGHT_TOLERANCE before it, the shoulder does not see the point, a corner between the
## body and it, and the aim finds nothing. Both rays ask only the world: the fighters are not on
## their mask, so they pass through them, and the body's own RID is excluded too. Queries of the
## physics space, like covers_body: they move nothing, and the world they read never moves, so a
## resimulated tick gets the same answer (probe B, rede.md §4). The first ray's intersect_ray
## result, empty on a miss or a corner: the tick casts it when the core asks, and the reticle on
## screen from the displayed body, along the camera (Hud).
func aim_ray(feet: Vector3, yaw: float, pitch: float) -> Dictionary:
	var origin := Aim.origin(feet, yaw, config.aim_height, config.aim_side)
	var hit := _world_ray(origin, origin + Aim.direction(yaw, pitch) * config.grapple_range)
	if hit.is_empty():
		return hit
	var point: Vector3 = hit["position"]
	var sight := _world_ray(feet + Vector3.UP * config.aim_height, point)
	if not sight.is_empty():
		var stop: Vector3 = sight["position"]
		if stop.distance_to(point) > SIGHT_TOLERANCE:
			return { }
	return hit


# A ray of the physics space from from to to, only against the world, the body's own RID excluded.
func _world_ray(from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, PhysicsLayers.WORLD, [get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query)


# The move's own collisions (DEC-0042 §1): of the colliders that are not a fighter nor the arena's
# lid, the one with the most horizontal normal, the first in the engine's order on a tie.
func _read_slide_contact(facts: MoveFacts) -> void:
	var flattest := INF
	for slide: int in get_slide_collision_count():
		var collision := get_slide_collision(slide)
		for index: int in collision.get_collision_count():
			var collider := collision.get_collider(index)
			var normal := collision.get_normal(index)
			if collider is Fighter or _is_bounds(collider) or absf(normal.y) >= flattest:
				continue
			flattest = absf(normal.y)
			facts.wall_normal = normal
			facts.wall_id = _wall_id_of(collider)


# The head facts (TASK-10.7 plan, "Os fatos da cabeça"), read right after the move: whether the
# engine's floor this tick is only another fighter's head, and the normal of that contact laid
# flat, away from the fighter below. Of the move's collisions at a floor angle, one with the
# scenery wins: that is real floor. With only fighters there, the first one's normal. With the
# engine on the floor and no collision of the move at a floor angle, the floor came from the snap,
# and the test-only probe HEAD_PROBE_DISTANCE down names it. The probe moves nothing and changes no
# flag of the CharacterBody3D (physics_body_3d.cpp, move_and_collide), and probe C measured its
# answer equal on every resimulated tick (rede.md §4, "A sonda C").
func _head_contact(facts: MoveFacts) -> void:
	if not facts.on_floor:
		return
	var floor_angle := floor_max_angle + FLOOR_ANGLE_THRESHOLD
	var found := false
	var normal := Vector3.ZERO
	for slide: int in get_slide_collision_count():
		var collision := get_slide_collision(slide)
		for index: int in collision.get_collision_count():
			var contact := collision.get_normal(index)
			if contact.angle_to(up_direction) > floor_angle:
				continue
			if not (collision.get_collider(index) is Fighter):
				return
			if not found:
				found = true
				normal = contact
	if not found:
		var hit := move_and_collide(Vector3.DOWN * HEAD_PROBE_DISTANCE, true)
		if hit == null or not (hit.get_collider() is Fighter):
			return
		normal = hit.get_normal()
	facts.floor_is_fighter = true
	facts.fighter_away = Vector3(normal.x, 0.0, normal.z)


# Whether collider is one of the arena's bounds, the lid over the border (DEC-0049 §2): it stops
# the body and is never a wall for the rules, so the wall facts skip it like a fighter.
static func _is_bounds(collider: Object) -> bool:
	if not (collider is CollisionObject3D):
		return false
	return ((collider as CollisionObject3D).collision_layer & PhysicsLayers.BOUNDS) != 0


# A normal laid flat: the horizontal unit vector a wall faces; zero for a floor or a ceiling.
static func _flat(normal: Vector3) -> Vector3:
	return Vector3(normal.x, 0.0, normal.z).normalized()


# A wall's identity (DEC-0042 §2): the collider's node path relative to the arena, never the
# engine's instance id or RID, which probe A saw change on every build (rede.md §4).
func _wall_id_of(collider: Object) -> StringName:
	assert(collider is Node, "a collider of the arena is a node")
	var root := arena if arena != null else get_parent()
	return StringName(str(root.get_path_to(collider as Node)))


# netfox's liveness (rollback-liveness-server.gd): with these two callbacks the fighter exists only
# from its first tick, the synchronizer's spawn_tick. netfox neither simulates it nor records its
# state on an earlier tick, even when its owner sent input for one, so a client and the server
# start it on the same tick from the same state (TASK-9, round C2: a client whose clock lagged the
# server's predicted its fighter one tick before the server's spawn, and the server's spawn state
# then overwrote that prediction). netfox calls them when the tick it runs or restores crosses the
# first tick; they do nothing, and the body stays in the physics world on both sides of it.
func _rollback_spawn() -> void:
	pass


func _rollback_despawn() -> void:
	pass


func _on_rollback_loop_start() -> void:
	_engine_floor_pending = true


# The transform contour (DEC-0025 §1), on every tick of a rollback loop, after netfox restored the
# position: the physics engine still has the body where it was in the present, and Jolt would
# collide the other fighter with that. Static, transform, kinematic pushes the restored position
# into the physics server at once (netfox's rollback-caveats.md).
func _push_transform_to_physics(_tick: int) -> void:
	var body := get_rid()
	PhysicsServer3D.body_set_mode(body, PhysicsServer3D.BODY_MODE_STATIC)
	PhysicsServer3D.body_set_state(body, PhysicsServer3D.BODY_STATE_TRANSFORM, global_transform)
	PhysicsServer3D.body_set_mode(body, PhysicsServer3D.BODY_MODE_KINEMATIC)


# Contour D (DEC-0025 §2), on the first tick of each rollback loop. netfox emits on_process_tick
# after every body's after_prepare_tick, so all the transforms are in the physics server before
# any fighter probes, the order the SyncTest of Desenho 3 proved (F-025 §4).
func _align_engine_floor_once(_tick: int) -> void:
	if not _engine_floor_pending:
		return
	_engine_floor_pending = false
	# move_and_slide() keeps its own "was on the floor" from the last move and snaps with it
	# (character_body_3d.cpp in Godot 4.7.2); after a rollback that flag belongs to the present.
	# A tiny probe, down when the state says floor and up when it says air, aligns it; the body
	# and its velocity then go back to what they were. Like the sandwich, the probe is scaled to
	# one tick by physics_factor, so the game probes at any frame rate the distance the SyncTest
	# proves (review of TASK-9, part 1).
	var kept_velocity := velocity
	var kept_position := global_position
	var probe := Vector3.DOWN if state.on_floor else Vector3.UP
	velocity = probe * FLOOR_PROBE_SPEED * NetworkTime.physics_factor
	move_and_slide()
	# The snap in reserve (DEC-0037): a body resting on a ledge's edge by its round bottom touches
	# it at a slant, farther than the probe reaches, and the probe's own snap skipped because the
	# engine's flag still said air. The snap the first run made puts the flag back on the floor.
	if state.on_floor and not is_on_floor():
		apply_floor_snap()
	global_position = kept_position
	velocity = kept_velocity


# The capsule of movimento.md, "O corpo", with its bottom at the body's origin: the origin is
# the feet, on the floor.
func _shape_capsule() -> void:
	var shape := CapsuleShape3D.new()
	shape.height = config.capsule_height
	shape.radius = config.capsule_radius
	collision.shape = shape
	collision.position = Vector3.UP * config.capsule_height / 2.0
	var mesh := CapsuleMesh.new()
	mesh.height = config.capsule_height
	mesh.radius = config.capsule_radius
	body_mesh.mesh = mesh
	body_mesh.position = collision.position


func _paint(tone: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = tone
	body_mesh.material_override = material
