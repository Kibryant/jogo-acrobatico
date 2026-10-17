# The fighter node (visao-geral.md, "As cenas"; DEC-0022): a thin adapter between netfox, the
# engine and the pure core. In _rollback_tick it only calls Movement and mirrors the result: the
# core decides, move_and_slide() moves and collides, the core confers (the tick sandwich). The two
# rollback contours of DEC-0025 live here because they touch the engine, never the core. The same
# code runs in Sozinho, on the server and on the clients (DEC-0026 §5).
class_name Fighter
extends CharacterBody3D

# Neutral tones, outside the colours of the combat tokens (visual-e-audio.md; DEC-0031): the
# fighter of whoever plays on this PC lighter, any other darker (TASK-9, "Números v0 do Claude").
# The light grey stays short of white, the reaction token's flash, and shows its roundness under
# the arena's light; the dark one is darker than the floor. The camera following one's own
# fighter tells them apart without relying on colour alone.
const OWN_TONE := Color(0.62, 0.62, 0.6)
const OTHER_TONE := Color(0.16, 0.16, 0.18)
# m/s: the probe move of contour D (DEC-0025 §2), the speed of the Desenho 3 probe whose SyncTest
# proved it (netfox-sonda, probe_fighter.gd; F-025 §4). For one tick it moves the body 0.83 mm at
# 60 ticks, and the body goes back right after.
const FLOOR_PROBE_SPEED := 0.05

## The input box, recorded by netfox as Input:move, Input:yaw and Input:jump.
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
## The rules box, recorded by netfox field by field (":state:mode" and the others; DEC-0022).
var state := FighterState.new()

# Contour D waits for the first tick of each rollback loop (DEC-0025 §2).
var _engine_floor_pending := false


# The engine's floor snap must catch a body running at full speed down the steepest floor: in one
# tick it moves run_speed / tickrate across, and a slope of floor_max_angle falls tan(angle) times
# that, 7 / 60 * tan(45°) = 0.1167 m at 60 ticks and 0.2333 m at 30. On top of the drop, the
# engine keeps a body up to one safe margin off the floor and its downward cast stops one margin
# short, both along the floor's normal: two margins / cos(angle) upright, and a third keeps the
# worst case off the edge. At 60 ticks on 45° that is 0.1167 + 0.0042 = 0.121 m. Measured by hand
# on the crest of a 45° ramp with the rig of test/fighter/fighter_slope_test.gd, 0.1187 m loses
# the floor and 0.1197 m holds; the test itself runs the full snap and half of it. A shorter snap
# throws the body off the ramp; a longer one would glue it to drops that should be ledges, and the
# arena's only drop, the 1 m ledge, is far longer.
static func floor_snap_for(movement_config: MovementConfig, margin: float) -> float:
	var angle := movement_config.floor_max_angle
	assert(angle < PI / 2.0, "a floor of 90 degrees has no snap: it is a wall")
	var across_per_tick := movement_config.run_speed / movement_config.tickrate
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
	collision_mask = PhysicsLayers.WORLD | PhysicsLayers.FIGHTERS
	# The engine judges the floor with the design's slope (movimento.md, "O corpo"); the core
	# reads its verdict in MoveFacts.on_floor.
	floor_max_angle = config.floor_max_angle
	floor_snap_length = floor_snap_for(config, safe_margin)
	position = spawn_position
	state = FighterState.new()
	state.facing_yaw = spawn_yaw
	input.face(spawn_yaw)
	# Only the server sends a fighter's state, and only to the peers it told that the fighter
	# exists (send_state_to): a state for a node a client does not have yet is dropped with a
	# warning (netfox's dense-snapshot-serializer.gd).
	synchronizer.visibility_filter.default_visibility = false
	_shape_capsule()
	_paint(OWN_TONE if own else OTHER_TONE)


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


func _process(_delta: float) -> void:
	# The body looks where the state says; the capsule is round, the visor shows the facing.
	visual.rotation = Vector3(0.0, state.facing_yaw, 0.0)


# The tick sandwich (visao-geral.md, "O tick por dentro"): netfox has restored the state and the
# input of this tick, and the contours have run.
func _rollback_tick(_delta: float, tick: int, _is_fresh: bool) -> void:
	var plan := Movement.before_move(state, velocity, input.to_tick_input(), config, tick)
	# move_and_slide() moves by velocity times the frame's delta, and a tick is not a frame:
	# physics_factor turns the move into exactly one tick (netfox's rollback-caveats.md). The
	# velocity is divided back, so the state keeps m/s.
	velocity = plan.velocity * NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor
	var facts := MoveFacts.new()
	facts.on_floor = is_on_floor()
	facts.velocity = velocity
	state = Movement.after_move(plan.state, facts, config, tick)


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
