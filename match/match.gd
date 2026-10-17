# The match (visao-geral.md, "As cenas"): it loads the design data, makes the movement
# configuration once for netfox's tickrate (visao-geral.md, "A configuração nasce na carga"),
# builds the arena and creates the fighters and the camera, passing the configuration to each by
# hand, like props in React: no autoload of ours (DEC-0022).
class_name Match
extends Node3D

const ARENA_SCENE := preload("res://arena/arena.tscn")
const FIGHTER_SCENE := preload("res://fighter/fighter.tscn")
const CAMERA_RIG_SCENE := preload("res://fighter/camera_rig.tscn")
const MOVEMENT_DATA_PATH := "res://data/movement_v0.tres"
const CAMERA_DATA_PATH := "res://data/camera_v0.tres"

## The movement numbers in ticks, shared by every fighter of the match.
var config: MovementConfig
var camera_data: CameraData
var arena: Arena
var fighters: Array[Fighter] = []
## The camera of whoever plays on this PC; null until watch().
var camera_rig: CameraRig

# The first tick of netfox's current tick loop.
var _loop_first_tick := 0


func _ready() -> void:
	var movement_data := _load_movement_data()
	config = MovementConfig.create(movement_data, NetworkTime.tickrate)
	camera_data = _load_camera_data()
	var node := ARENA_SCENE.instantiate()
	assert(node is Arena, "arena.tscn must have an Arena at its root")
	arena = node as Arena
	add_child(arena)


func _enter_tree() -> void:
	NetworkTime.before_tick_loop.connect(_on_tick_loop_start)
	NetworkRollback.before_loop.connect(_simulate_every_tick_of_the_loop)


func _exit_tree() -> void:
	NetworkTime.before_tick_loop.disconnect(_on_tick_loop_start)
	NetworkRollback.before_loop.disconnect(_simulate_every_tick_of_the_loop)


# A fighter at the spawn point of slot, driven by the input of the peer input_owner. The body is
# the server's (peer 1); in Sozinho this PC is that server.
func spawn_fighter(slot: int, input_owner: int) -> Fighter:
	var point := arena.spawn_point(slot)
	var node := FIGHTER_SCENE.instantiate()
	assert(node is Fighter, "fighter.tscn must have a Fighter at its root")
	var fighter := node as Fighter
	fighter.name = "Fighter%d" % slot
	var own := input_owner == multiplayer.get_unique_id()
	# The match is never turned, so the spawn point's yaw in the world is its yaw in the match.
	fighter.setup(config, to_local(point.global_position), point.global_rotation.y, own)
	fighter.input.set_multiplayer_authority(input_owner)
	add_child(fighter)
	fighters.append(fighter)
	return fighter


# The camera of whoever plays fighter on this PC, and this PC's keyboard and mouse on its input.
func watch(fighter: Fighter) -> CameraRig:
	var node := CAMERA_RIG_SCENE.instantiate()
	assert(node is CameraRig, "camera_rig.tscn must have a CameraRig at its root")
	camera_rig = node as CameraRig
	camera_rig.setup(camera_data, fighter, fighter.state.facing_yaw)
	add_child(camera_rig)
	fighter.input.use_devices(camera_rig)
	return camera_rig


func _on_tick_loop_start() -> void:
	_loop_first_tick = NetworkTime.tick


# netfox simulates from the oldest tick that has news from the network, and with no news only the
# loop's last tick (NetworkRollback._rollback). With nothing coming from the network, as in
# Sozinho, a frame that runs two ticks to catch the clock would simulate only the second, and the
# first tick's movement and jump would be lost. Asking for the loop's first tick makes every tick
# of the loop run once, fresh; when the network asks for older ticks, theirs wins.
func _simulate_every_tick_of_the_loop() -> void:
	NetworkRollback.notify_resimulation_start(_loop_first_tick)


static func _load_movement_data() -> MovementData:
	var resource: Resource = load(MOVEMENT_DATA_PATH)
	assert(resource is MovementData, "%s must load as a MovementData" % MOVEMENT_DATA_PATH)
	var data := resource as MovementData
	assert(data.validate().is_empty(), "%s: %s" % [MOVEMENT_DATA_PATH, data.validate()])
	return data


static func _load_camera_data() -> CameraData:
	var resource: Resource = load(CAMERA_DATA_PATH)
	assert(resource is CameraData, "%s must load as a CameraData" % CAMERA_DATA_PATH)
	var data := resource as CameraData
	assert(data.validate().is_empty(), "%s: %s" % [CAMERA_DATA_PATH, data.validate()])
	return data
