# The entry scene (DEC-0026 §6; rede.md §9): it reads how the game was opened, like a main.ts
# reading process.argv, and starts that mode:
# - no argument: Sozinho, Godot's offline peer, where this PC is its own server (rede.md §8);
# - --server, or the build exported as a dedicated server: the server, without a screen or a
#   fighter of its own, which gives a fighter to each player the handshake accepts;
# - --connect=host:port: a client, which plays its own fighter and mirrors the others.
# The same Match, fighters and core run in all three; only the peer around them changes
# (DEC-0026 §5; F-084 §3).
class_name Main
extends Node

enum ClientPhase {
	CONNECTING,
	PLAYING,
	ENDED,
}

const MATCH_SCENE := preload("res://match/match.tscn")
## TASK-9, choice 4: two players; a third one is refused with a message.
const MAX_PLAYERS := 2
## s: how long a client waits for the server to accept it before it says that the server does not
## answer. Claude's v0: on this PC, ENet alone gives up only after about 31 s.
const CONNECT_TIMEOUT_S := 5.0
# The exit codes. 0 is the clean end: the window closed, the stop file, or the server closing the
# session of a client without a screen. The others are Claude's v0, one per way a launch fails.
## An argument this build does not know: a typo once left a fullscreen probe open for 300 s
## (F-056).
const EXIT_USAGE := 2
## A client without a screen found no server that answered in time.
const EXIT_SERVER_NOT_RESPONDING := 3
## A client without a screen was refused: it is another build than the server's.
const EXIT_UPDATE_REQUIRED := 4
## A client without a screen was refused: the room was full.
const EXIT_ROOM_FULL := 5
## The server could not open its port, usually because another program holds it.
const EXIT_PORT_UNAVAILABLE := 6
const USAGE := """Usage, with the game's arguments after "--":
  (no argument)            play Sozinho: this PC is its own server.
  --server                 run the dedicated server; open Godot with --headless, it has no screen.
    --port=N               the server's port, 7777/udp when not given.
    --stop-file=PATH       the server closes cleanly, with exit code 0, when PATH appears.
  --connect=HOST[:PORT]    join the server at HOST, on PORT or 7777.
The build exported as a dedicated server runs the server and takes --port and --stop-file."""

## The match of the session; null when no session runs.
var current_match: Match
## How the game was opened.
var options: LaunchOptions

var _status: StatusMessage
# Kept here: SceneMultiplayer holds their callbacks without keeping them alive.
var _handshake_server: HandshakeServer
var _handshake_client: HandshakeClient
# On the server, the peers whose fighter is in the match, in the order they joined.
var _players: Array[int] = []
var _client_phase := ClientPhase.CONNECTING


func _ready() -> void:
	options = LaunchOptions.parse(
		OS.get_cmdline_user_args(),
		OS.has_feature("dedicated_server"),
		DisplayServer.get_name() != "headless",
	)
	if not options.errors.is_empty():
		printerr("%s\n%s" % ["\n".join(options.errors), USAGE])
		get_tree().quit(EXIT_USAGE)
		return
	# Closing the window comes to _notification instead of quitting at once, so the session ends
	# cleanly first (DEC-0026 §6).
	get_tree().auto_accept_quit = false
	# The server shows no text; its log is for whoever runs it.
	if options.mode != LaunchOptions.Mode.SERVER:
		GameText.install()
	match options.mode:
		LaunchOptions.Mode.SERVER:
			await start_server()
		LaunchOptions.Mode.CLIENT:
			start_client()
		_:
			await start_solo()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_quit(OK)


# Sozinho: Godot's default peer is an OfflineMultiplayerPeer with the server's id, 1, so this PC
# simulates and confirms its own fighter, with no network and nothing to redo. netfox's clock starts
# first, then the match (DEC-0026 §6). start() is a coroutine because a client waits for the
# server's clock; the server, Sozinho's role, does not wait.
func start_solo() -> void:
	var started: int = await NetworkTime.start()
	assert(started == OK, "netfox's clock did not start: %s" % error_string(started))
	_start_match()
	current_match.watch(current_match.spawn_fighter(0, multiplayer.get_unique_id()))


# The dedicated server (DEC-0026 §6): a match with the arena and no fighter until a player
# joins. Its log says each key event at once (application/run/flush_stdout_on_print; F-073 §2).
func start_server() -> void:
	var build := BuildStamp.current()
	_log("server: %s" % build.describe())
	_start_match()
	assert(MAX_PLAYERS <= current_match.arena.spawn_point_count(), "a spawn point per seat")
	_handshake_server = HandshakeServer.new(_scene_multiplayer(), build, MAX_PLAYERS)
	_handshake_server.accepted.connect(_on_player_accepted)
	_handshake_server.refused.connect(_on_player_refused)
	_handshake_server.left.connect(_on_player_left)
	NetworkTime.after_client_sync.connect(_on_player_clock_synced)
	# ENet's own limit stays at its default of 32 connections, above the two seats, so a third
	# player gets in far enough to hear that the room is full.
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(options.port)
	if error != OK:
		_log("server: cannot listen on port %d/udp: %s" % [options.port, error_string(error)])
		_quit(EXIT_PORT_UNAVAILABLE)
		return
	multiplayer.multiplayer_peer = peer
	# netfox's NetworkEvents starts and stops the clock by itself when it sees the server, on the
	# next frame (network-events.gd), so the Main does not start it twice. The server answers no
	# handshake before its clock runs, so every client syncs with a running clock (rede.md §9).
	if not NetworkTime.is_initial_sync_done():
		await NetworkTime.after_sync
	_handshake_server.open()
	_log("server: listening on port %d/udp, at most %d players" % [options.port, MAX_PLAYERS])
	if not options.stop_file.is_empty():
		var stop_file := StopFile.new(options.stop_file)
		stop_file.appeared.connect(_on_stop_file)
		add_child(stop_file)
		_log("server: closes when this file appears: %s" % options.stop_file)


# A client (DEC-0026 §6): it shakes hands with the server, then mirrors the fighters the server
# tells it about and plays its own.
func start_client() -> void:
	var build := BuildStamp.current()
	_log("client: connecting to %s:%d (%s)" % [options.host, options.port, build.describe()])
	_status = StatusMessage.new()
	add_child(_status)
	_show(GameText.CONNECTING)
	var api := _scene_multiplayer()
	_handshake_client = HandshakeClient.new(api, build)
	_handshake_client.refused.connect(_on_refused)
	api.connected_to_server.connect(_on_accepted)
	api.connection_failed.connect(_on_server_lost)
	api.server_disconnected.connect(_on_server_lost)
	api.peer_authentication_failed.connect(_on_server_lost.unbind(1))
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(options.host, options.port)
	if error != OK:
		_log("client: cannot connect to %s: %s" % [options.host, error_string(error)])
		_end_client(GameText.SERVER_NOT_RESPONDING, EXIT_SERVER_NOT_RESPONDING)
		return
	multiplayer.multiplayer_peer = peer
	get_tree().create_timer(CONNECT_TIMEOUT_S).timeout.connect(_on_connect_timeout)


# The clean end of a session (DEC-0026 §6): stop netfox's clock, which also drops its history;
# close the connection, which Sozinho does not have (the offline peer stays); free the match. A
# client that ends its own session is not told afterwards that the server closed it.
func end_session() -> void:
	_client_phase = ClientPhase.ENDED
	NetworkTime.stop()
	var peer := multiplayer.multiplayer_peer
	if peer != null and peer is not OfflineMultiplayerPeer:
		peer.close()
	if current_match != null:
		current_match.queue_free()
		current_match = null


func _on_player_accepted(peer: int, slot: int, client: BuildStamp) -> void:
	_log("server: peer %d handshake accepted (%s), seat %d" % [peer, client.describe(), slot])


func _on_player_refused(peer: int, verdict: Handshake.Verdict, client: BuildStamp) -> void:
	var said := "an unreadable hello" if client == null else client.describe()
	_log("server: peer %d handshake refused: %s (%s)" % [peer, _refusal_name(verdict), said])


# netfox emits after_client_sync on the server once a client's clock runs (network-time.gd): its
# fighter spawns then, on the ticks both clocks share.
func _on_player_clock_synced(peer: int) -> void:
	var slot := _handshake_server.room.slot_of(peer)
	if slot == Room.NO_SEAT or _players.has(peer) or current_match == null:
		return
	var fighter := current_match.spawn_fighter(slot, peer)
	# The others mirror the newcomer's fighter, and the newcomer mirrors every fighter, its own
	# included, under the server's node names, so netfox's routes match on every peer. Each
	# fighter's state goes to a peer only once the peer was told the fighter exists.
	for other: int in _players:
		_add_fighter.rpc_id(other, slot, peer, String(fighter.name))
		fighter.send_state_to(other)
	_players.append(peer)
	for player: int in _players:
		var player_slot := _handshake_server.room.slot_of(player)
		var mirrored := current_match.fighter_at(player_slot)
		_add_fighter.rpc_id(peer, player_slot, player, String(mirrored.name))
		mirrored.send_state_to(peer)
	_log("server: peer %d joined the match as %s, seat %d" % [peer, fighter.name, slot])


func _on_player_left(peer: int, slot: int) -> void:
	if _players.has(peer):
		_players.erase(peer)
		if current_match != null:
			_log("server: %s leaves the match" % current_match.fighter_at(slot).name)
			current_match.remove_fighter(slot)
		for other: int in _players:
			_remove_fighter.rpc_id(other, slot)
	_log("server: peer %d left, seat %d free" % [peer, slot])


func _on_stop_file() -> void:
	_log("server: stop file seen: %s" % options.stop_file)
	_quit(OK)


# The handshake passed: SceneMultiplayer admits the server, and netfox's NetworkEvents starts this
# client's clock, which syncs with the server's (network-events.gd; rede.md §9). The match waits
# for the fighters, which the server sends once the clock runs.
func _on_accepted() -> void:
	if _client_phase != ClientPhase.CONNECTING:
		return
	_client_phase = ClientPhase.PLAYING
	_status.clear()
	_log("client: handshake accepted, peer %d" % multiplayer.get_unique_id())
	_start_match()


func _on_refused(verdict: Handshake.Verdict) -> void:
	if verdict == Handshake.Verdict.ROOM_FULL:
		_end_client(GameText.ROOM_FULL, EXIT_ROOM_FULL)
	else:
		_end_client(GameText.UPDATE_REQUIRED, EXIT_UPDATE_REQUIRED)


# The connection failed or closed: before the handshake passed, the server did not answer; after
# it, the server ended the session.
func _on_server_lost() -> void:
	if _client_phase == ClientPhase.PLAYING:
		_end_client(GameText.SERVER_CLOSED, OK)
	else:
		_end_client(GameText.SERVER_NOT_RESPONDING, EXIT_SERVER_NOT_RESPONDING)


func _on_connect_timeout() -> void:
	if _client_phase == ClientPhase.CONNECTING:
		_end_client(GameText.SERVER_NOT_RESPONDING, EXIT_SERVER_NOT_RESPONDING)


# The client's session is over and its message stays on screen. With a screen, the player reads
# it and closes the window; without one, the game quits with exit_code. Deferred, because these
# calls come from inside SceneMultiplayer's poll, which must end before the connection closes.
func _end_client(key: StringName, exit_code: int) -> void:
	if _client_phase == ClientPhase.ENDED:
		return
	_client_phase = ClientPhase.ENDED
	_show(key)
	if DisplayServer.get_name() == "headless":
		_quit.call_deferred(exit_code)
	else:
		end_session.call_deferred()


# The server tells a client that a fighter exists: in slot, driven by the input of input_owner,
# under the server's node name.
@rpc("authority", "call_remote", "reliable")
func _add_fighter(slot: int, input_owner: int, node_name: String) -> void:
	if current_match == null or slot < 0 or slot >= current_match.arena.spawn_point_count():
		return
	var free_name := node_name == node_name.validate_node_name() and not node_name.is_empty()
	if current_match.fighter_at(slot) != null or not free_name or current_match.has_node(node_name):
		return
	var fighter := current_match.spawn_fighter(slot, input_owner, NetworkTime.tick, node_name)
	# netfox learns a new fighter's route only at the end of the frame (RollbackSynchronizer._ready
	# defers process_settings()), and the server's first state for it can come in this same poll:
	# with no route yet, netfox would drop it with a warning. process_settings() is netfox's call
	# for "the configuration changed", safe to run again.
	fighter.synchronizer.process_settings()
	var mine := input_owner == multiplayer.get_unique_id()
	if mine:
		current_match.watch(fighter)
	var whose := " (mine)" if mine else ""
	_log("client: %s joined, seat %d, peer %d%s" % [node_name, slot, input_owner, whose])


# The server tells a client that the fighter in slot left the match.
@rpc("authority", "call_remote", "reliable")
func _remove_fighter(slot: int) -> void:
	if current_match == null or current_match.fighter_at(slot) == null:
		return
	_log("client: %s left" % current_match.fighter_at(slot).name)
	current_match.remove_fighter(slot)


func _start_match() -> void:
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	current_match = node as Match
	add_child(current_match)


# The probe crashed on exit (F-026 §4): the session ends while netfox is alive, then the game
# quits with exit_code.
func _quit(exit_code: int) -> void:
	end_session()
	await get_tree().process_frame
	_log("%s: exiting with %d" % [_role(), exit_code])
	get_tree().quit(exit_code)


func _show(key: StringName) -> void:
	_status.show_key(key)
	_log("%s: %s: %s" % [_role(), key, GameText.text(key)])


func _scene_multiplayer() -> SceneMultiplayer:
	var api := multiplayer
	assert(api is SceneMultiplayer, "the handshake runs in Godot's SceneMultiplayer")
	return api as SceneMultiplayer


func _role() -> String:
	match options.mode:
		LaunchOptions.Mode.SERVER:
			return "server"
		LaunchOptions.Mode.CLIENT:
			return "client"
		_:
			return "sozinho"


static func _refusal_name(verdict: Handshake.Verdict) -> String:
	if verdict == Handshake.Verdict.ROOM_FULL:
		return "room full"
	return "update required"


static func _log(line: String) -> void:
	print(line)
