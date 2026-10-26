# The match (visao-geral.md, "As cenas"): it loads the design data, makes the movement
# configuration once for netfox's tickrate (visao-geral.md, "A configuração nasce na carga"),
# builds the arena and creates the fighters and the camera, passing the configuration to each by
# hand, like props in React: no autoload of ours (DEC-0022).
class_name Match
extends Node3D

const ARENA_SCENE := preload("res://arena/arena.tscn")
const FIGHTER_SCENE := preload("res://fighter/fighter.tscn")
const CAMERA_RIG_SCENE := preload("res://fighter/camera_rig.tscn")
const OPTIONS_SCREEN_SCENE := preload("res://ui/options/options_screen.tscn")
const MOVEMENT_DATA_PATH := "res://data/movement_v0.tres"
const CAMERA_DATA_PATH := "res://data/camera_v0.tres"
## spawn_fighter() without a first tick: netfox picks it.
const NO_TICK := -1
## spawn_fighter() without a node name: the match names the fighter.
const ANY_NAME := ""
## In Sozinho, the slot of the player's fighter; the dummy (TASK-10.7) takes the next one.
const PLAYER_SLOT := 0
const DUMMY_SLOT := 1

## The movement numbers in the units of the paper. Set before the match enters the tree, they
## replace movement_v0.tres, which is then never loaded: the reference test plays its frozen copy
## this way (TASK-9, part 3). Left null, the match loads movement_v0.tres.
var movement_data: MovementData
## The movement numbers in ticks, shared by every fighter of the match.
var config: MovementConfig
var camera_data: CameraData
var arena: Arena
var fighters: Array[Fighter] = []
## The camera of whoever plays on this PC, a person or the bot; null until watch() or
## let_bot_play().
var camera_rig: CameraRig
## The HUD of whoever plays on this PC; null until watch(), and always null without a screen, as
## on the dedicated server and in headless runs (TASK-10.2).
var hud: Hud
## The player's options: the keys, the mouse's sensitivity and the interface's scale (TASK-10.9).
## The Main sets the ones it read from the player's file before the match enters the tree; left
## null, the match takes the defaults, and an options screen would save them to user://options.cfg.
var options: OptionsStore
## The options screen of whoever plays on this PC, created with the HUD; null until watch(), and
## always null without a screen (TASK-10.9).
var options_screen: OptionsScreen
## The bot that plays on this PC; null unless let_bot_play().
var bot: BotPlayer
## The cues of every fighter's maneuvers, played once per event (DEC-0031 §6; TASK-10.4). They
## draw only with a screen, and count everywhere.
var cues: ManeuverCues

# The first tick of netfox's current tick loop.
var _loop_first_tick := 0
# The fighters by slot, the seat of their player and the spawn point they start at.
var _by_slot: Dictionary[int, Fighter] = { }
# How many fighters the match has named: the next one is FighterN, with N this count.
var _named := 0
# The fighter the camera follows; null until watch().
var _watched: Fighter


func _ready() -> void:
	if movement_data == null:
		movement_data = _load_movement_data()
	assert(
		movement_data.validate().is_empty(),
		"%s: %s" % [movement_data.resource_path, movement_data.validate()],
	)
	config = MovementConfig.create(movement_data, NetworkTime.tickrate)
	camera_data = _load_camera_data()
	if options == null:
		options = OptionsStore.new()
	var node := ARENA_SCENE.instantiate()
	assert(node is Arena, "arena.tscn must have an Arena at its root")
	arena = node as Arena
	add_child(arena)
	cues = ManeuverCues.new(config, has_screen())
	add_child(cues)


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
# first_tick is the fighter's first tick: netfox starts its history there and neither simulates
# nor records it before (Fighter._rollback_spawn). By default it is the clock's tick, the tick the
# next loop runs first. netfox's own default, the tick after its last rollback, is stale on a client
# whose clock has just synced and has run no tick loop yet: netfox would then try to redo every
# tick since 1. A client's own fighter takes the server's first tick (Main._add_fighter), so both
# start it on the same tick (TASK-9, round C2).
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
	fighter.arena = arena
	fighter.input.set_multiplayer_authority(input_owner)
	fighter.synchronizer.spawn_tick = NetworkTime.tick if first_tick == NO_TICK else first_tick
	add_child(fighter)
	fighters.append(fighter)
	_by_slot[slot] = fighter
	cues.watch(fighter)
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
	cues.forget(fighter)
	if fighter == _watched:
		camera_rig.queue_free()
		camera_rig = null
		_watched = null
		if hud != null:
			hud.queue_free()
			hud = null
		if options_screen != null:
			options_screen.queue_free()
			options_screen = null
		if bot != null:
			bot.queue_free()
			bot = null
	fighter.queue_free()


# The camera of whoever plays fighter on this PC, turning at the player's sensitivity, this PC's
# keyboard and mouse on its input, and, with a screen, the HUD of its stamina and mode (TASK-10.2)
# and the options screen the Esc opens (TASK-10.9). Without one nobody would see them.
func watch(fighter: Fighter) -> CameraRig:
	_follow(fighter, true)
	options.apply_sensitivity(camera_rig)
	fighter.input.use_devices(camera_rig)
	_show_hud(fighter)
	_show_options(fighter)
	return camera_rig


# A camera that only follows fighter, with the HUD when there is a screen, for a replay that plays
# it instead of this PC's keyboard and mouse (TASK-10.3): the mouse stays free, and whoever plays
# the replay turns the camera to where the fighter looks.
func view(fighter: Fighter) -> CameraRig:
	_follow(fighter, false)
	_show_hud(fighter)
	return camera_rig


# Sozinho's tones (visual-e-audio.md, "A cabeça do outro na tela": "O boneco"): this PC drives
# every fighter there, but only the player's, in PLAYER_SLOT, wears the own tone; the dummy, and
# any other slot of a replay, wears the other's, live and in --watch alike (Fighter.wear).
static func solo_tone(slot: int) -> Color:
	return Fighter.OWN_TONE if slot == PLAYER_SLOT else Fighter.OTHER_TONE


# True when this PC draws to a screen; the dedicated server and the headless runs have none,
# the same check the Main makes.
static func has_screen() -> bool:
	return DisplayServer.get_name() != "headless"


# The bot plays fighter on this PC instead of the keyboard and the mouse (TASK-9, part 2), its route
# starting on the fighter's first tick. A camera follows the fighter without taking the mouse, so a
# player can use another window beside this one.
func let_bot_play(fighter: Fighter) -> BotPlayer:
	_follow(fighter, false)
	var first_tick: int = fighter.synchronizer.spawn_tick
	bot = BotPlayer.new(
		fighter.input,
		BotRoute.new(config.tickrate),
		first_tick,
		fighter.state.facing_yaw,
	)
	add_child(bot)
	return bot


func _on_tick_loop_start() -> void:
	_loop_first_tick = NetworkTime.tick


func _show_hud(fighter: Fighter) -> void:
	if hud == null and has_screen():
		hud = Hud.new()
		add_child(hud)
	if hud != null:
		hud.follow(fighter, config, camera_rig)


func _show_options(fighter: Fighter) -> void:
	if options_screen == null and has_screen():
		var node := OPTIONS_SCREEN_SCENE.instantiate()
		assert(node is OptionsScreen, "options_screen.tscn must have an OptionsScreen at its root")
		options_screen = node as OptionsScreen
		add_child(options_screen)
	if options_screen != null:
		options_screen.follow(fighter.input, camera_rig, options)


# A camera on fighter, looking where it looks; with takes_mouse, the mouse turns it.
func _follow(fighter: Fighter, takes_mouse: bool) -> void:
	var node := CAMERA_RIG_SCENE.instantiate()
	assert(node is CameraRig, "camera_rig.tscn must have a CameraRig at its root")
	camera_rig = node as CameraRig
	camera_rig.setup(camera_data, fighter, fighter.state.facing_yaw, takes_mouse)
	add_child(camera_rig)
	_watched = fighter


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
	return resource as MovementData


static func _load_camera_data() -> CameraData:
	var resource: Resource = load(CAMERA_DATA_PATH)
	assert(resource is CameraData, "%s must load as a CameraData" % CAMERA_DATA_PATH)
	var data := resource as CameraData
	assert(data.validate().is_empty(), "%s: %s" % [CAMERA_DATA_PATH, data.validate()])
	return data
