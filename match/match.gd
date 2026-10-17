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
## spawn_fighter() without a first tick: netfox picks it.
const NO_TICK := -1
## spawn_fighter() without a node name: the match names the fighter.
const ANY_NAME := ""

## The movement numbers in ticks, shared by every fighter of the match.
var config: MovementConfig
var camera_data: CameraData
var arena: Arena
var fighters: Array[Fighter] = []
## The camera of whoever plays on this PC; null until watch().
var camera_rig: CameraRig

# The first tick of netfox's current tick loop.
var _loop_first_tick := 0
# The fighters by slot, the seat of their player and the spawn point they start at.
var _by_slot: Dictionary[int, Fighter] = { }
# How many fighters the match has named: the next one is FighterN, with N this count.
var _named := 0
# The fighter the camera follows; null until watch().
var _watched: Fighter


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
# The node's name is its route in netfox's packets (visao-geral.md, "As cenas"), so a mirrored
# fighter takes node_name from the server, and the server names each new fighter Fighter0,
# Fighter1, Fighter2... in the order they spawn, never twice in a match: a player who joins
# where another left never meets the leaving node's route, which netfox drops only when the node
# is freed (network-identity-server.gd).
# first_tick is where netfox starts the fighter's history. By default netfox takes the tick after
# its last rollback, which is stale on a client whose clock has just synced and has run no tick
# loop yet: netfox would then try to redo every tick since 1 (Main._add_fighter passes the clock's
# tick).
func spawn_fighter(
	slot: int,
	input_owner: int,
	first_tick := NO_TICK,
	node_name := ANY_NAME,
) -> Fighter:
	assert(not _by_slot.has(slot), "slot %d already has a fighter" % slot)
	var point := arena.spawn_point(slot)
	var node := FIGHTER_SCENE.instantiate()
	assert(node is Fighter, "fighter.tscn must have a Fighter at its root")
	var fighter := node as Fighter
	fighter.name = "Fighter%d" % _named if node_name == ANY_NAME else node_name
	_named += 1
	var own := input_owner == multiplayer.get_unique_id()
	# The match is never turned, so the spawn point's yaw in the world is its yaw in the match.
	fighter.setup(config, to_local(point.global_position), point.global_rotation.y, own)
	fighter.input.set_multiplayer_authority(input_owner)
	if first_tick != NO_TICK:
		fighter.synchronizer.spawn_tick = first_tick
	add_child(fighter)
	fighters.append(fighter)
	_by_slot[slot] = fighter
	return fighter


# The fighter in slot; null when the slot is free.
func fighter_at(slot: int) -> Fighter:
	if not _by_slot.has(slot):
		return null
	return _by_slot[slot]


# Takes the fighter of slot out of the match, with its camera when this PC watches it, and frees
# the seat's spawn point for the next fighter. The node stays in the tree until the frame ends,
# as netfox expects: its handlers still run on it in this frame (base-net-input.gd).
func remove_fighter(slot: int) -> void:
	var fighter := fighter_at(slot)
	if fighter == null:
		return
	_by_slot.erase(slot)
	fighters.erase(fighter)
	if fighter == _watched:
		camera_rig.queue_free()
		camera_rig = null
		_watched = null
	fighter.queue_free()


# The camera of whoever plays fighter on this PC, and this PC's keyboard and mouse on its input.
func watch(fighter: Fighter) -> CameraRig:
	var node := CAMERA_RIG_SCENE.instantiate()
	assert(node is CameraRig, "camera_rig.tscn must have a CameraRig at its root")
	camera_rig = node as CameraRig
	camera_rig.setup(camera_data, fighter, fighter.state.facing_yaw)
	add_child(camera_rig)
	fighter.input.use_devices(camera_rig)
	_watched = fighter
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
