# The entry scene (DEC-0026 §6; rede.md §9): it reads how the game was opened, like a main.ts
# reading process.argv, and starts that mode:
# - no argument: Sozinho, Godot's offline peer, where this PC is its own server (rede.md §8), which
#   records the session as a replay (ReplayRecorder; TASK-10.3), and plays one with --watch;
# - --server, or the build exported as a dedicated server: the server, without a screen or a
#   fighter of its own, which gives a fighter to each player the handshake accepts;
# - --connect=host:port: a client, which plays its own fighter and mirrors the others; with --bot,
#   the bot plays it (BotPlayer).
# With a screen, --measure-fps=PATH measures the frame rate of Sozinho or of a client (FpsMeter).
# The same Match, fighters and core run in all three; only the peer around them changes
# (DEC-0026 §5; F-084 §3). When netfox's network simulator connects the game (SimulatorLink), the
# Main adopts the simulator's peer instead of opening its own, and the rest stays the same.
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
## An argument this build does not know: a typo once left a fullscreen probe open for up to
## 300 s (.claude/harness/registro.md, 2026-10-07).
const EXIT_USAGE := 2
## A client without a screen found no server that answered in time.
const EXIT_SERVER_NOT_RESPONDING := 3
## A client without a screen was refused: it is another build than the server's.
const EXIT_UPDATE_REQUIRED := 4
## A client without a screen was refused: the room was full.
const EXIT_ROOM_FULL := 5
## The server could not open its port, usually because another program holds it.
const EXIT_PORT_UNAVAILABLE := 6
## --watch cannot play its file: another format, tickrate or arena, a broken file, or another build
## without --force (ReplayFile; TASK-10.3).
const EXIT_REPLAY_REFUSED := 7
## Frames the Main waits for netfox's network simulator to connect the game: it does so one frame
## after it starts (network-simulator.gd), and the Main started in between.
const SIMULATOR_FRAMES := 10
## ms: beyond the simulator's latency, how long a server that netfox's network simulator connected
## stays up after closing. The simulator's proxy lives in the game that hosts and holds each packet
## for the latency, so the clients still hear the goodbye. Claude's v0: a margin over the proxy's
## loop of 1 ms (network-simulator.gd).
const PROXY_DRAIN_MARGIN_MS := 100
const USAGE := """Usage, with the game's arguments after "--":
  (no argument)            play Sozinho: this PC is its own server.
  --server                 run the dedicated server; open Godot with --headless, it has no screen.
    --port=N               the server's port, 7777/udp when not given.
    --stop-file=PATH       the server closes cleanly, with exit code 0, when PATH appears.
  --connect=HOST[:PORT]    join the server at HOST, on PORT or 7777.
    --bot                  the bot plays instead of the keyboard and the mouse, which it leaves
                           alone; it quits with the session, with or without a screen.
  --record=PATH            with --server or --connect: when the session ends, write to PATH the
                           state of the fighters tick by tick, the server's last result of every
                           fighter or a client's first one of its own (tools/net_run.sh reads it).
  --half=left|right        with a screen: the window takes that half of the screen.
  --measure-fps=PATH       with a screen, in Sozinho or with --connect: fullscreen, vsync off and
                           no frame limit; once this game's fighter plays, 2 s of warm-up, then
                           the frames are timed for 60 s, written to PATH as JSON, and the game
                           quits with 0 (tools/measure_fps.sh).
Sozinho records every session as a replay in user://replays/, keeping the newest 20, and says
where in its log:
  --replay=PATH            record the replay to PATH instead.
  --replay-dir=DIR         record it in DIR instead, keeping the newest 20 there.
  --no-replay              record none.
  --watch=FILE             with a screen: play the replay FILE in Sozinho, the camera on its
                           fighter, instead of the keyboard and the mouse; it records none.
    --force                play a replay of another build anyway.
    --trace=PATH           write the state of every tick it played to PATH, and the size of each
                           tick loop to PATH.loops, then quit (tools/replay.sh compares it).
The build exported as a dedicated server runs the server and takes --port, --stop-file and
--record. With netfox's network simulator on (netfox/autoconnect/enabled, from an override.cfg),
the simulator connects the game and the address in the arguments must be its own."""

## The match of the session; null when no session runs.
var current_match: Match
## How the game was opened.
var options: LaunchOptions
## The arguments after "--" the Main reads when it enters the tree; a test sets them before.
var arguments := OS.get_cmdline_user_args()

var _status: StatusMessage
# Kept here: SceneMultiplayer holds their callbacks without keeping them alive.
var _handshake_server: HandshakeServer
var _handshake_client: HandshakeClient
# On the server, the peers whose fighter is in the match, in the order they joined.
var _players: Array[int] = []
var _client_phase := ClientPhase.CONNECTING
# The record of --record; null without it, and once written.
var _recorder: TickRecorder
# The frame rate measurement of --measure-fps; null without it, and once the session ends.
var _meter: FpsMeter
# Sozinho's replay recorder; null when it records none, and once the session ends.
var _replay: ReplayRecorder
# The replay a window plays with --watch; null without it.
var _watch: ReplayWatch


func _ready() -> void:
	options = LaunchOptions.parse(
		arguments,
		OS.has_feature("dedicated_server"),
		DisplayServer.get_name() != "headless",
		SimulatorLink.current(),
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
	if not options.half.is_empty():
		_place_window(options.half == "right")
	if not options.measure_fps.is_empty():
		_prepare_measurement()
	if not options.record.is_empty():
		_start_recording()
	match options.mode:
		LaunchOptions.Mode.SERVER:
			await start_server()
		LaunchOptions.Mode.CLIENT:
			await start_client()
		_:
			if options.watch.is_empty():
				await start_solo()
			else:
				await start_watch()


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
	var fighter := current_match.spawn_fighter(0, multiplayer.get_unique_id())
	current_match.watch(fighter)
	if options.records_replay():
		_start_replay(fighter)
	_measure_from_now()


# --watch (TASK-10.3): Sozinho on the real clock with the movement numbers of the file, its fighters
# fed by its rows instead of the keyboard, and a camera that follows the first one. A file this
# game cannot play is refused in the log, and the game quits.
func start_watch() -> void:
	var replay := ReplayFile.open(options.watch)
	if replay.errors.is_empty():
		replay.judge(ReplayFile.this_build())
	_log("sozinho: plays the replay %s" % ProjectSettings.globalize_path(options.watch))
	for message: String in replay.messages(options.force):
		_log("sozinho: replay: %s" % message)
	if not replay.playable(options.force):
		_quit(EXIT_REPLAY_REFUSED)
		return
	var started: int = await NetworkTime.start()
	assert(started == OK, "netfox's clock did not start: %s" % error_string(started))
	_start_match(replay.movement_data())
	var fighters: Array[Fighter] = []
	for slot: int in replay.fighter_count():
		var fighter := current_match.spawn_fighter(slot, multiplayer.get_unique_id())
		var first_tick: int = fighter.synchronizer.spawn_tick
		fighter.input.play_rows(ReplaySource.in_order(replay, slot, first_tick))
		fighters.append(fighter)
	var first: int = fighters[0].synchronizer.spawn_tick
	_watch = ReplayWatch.new(replay, fighters, first)
	_watch.camera = current_match.view(fighters[0])
	_watch.finished.connect(_on_replay_watched)
	add_child(_watch)
	_log(
		"sozinho: %d ticks to play, from tick %d of this clock (tick %d of the recording)"
		% [replay.tick_count(), first, replay.first_tick()],
	)


# The dedicated server (DEC-0026 §6): a match with the arena and no fighter until a player
# joins. Its log says each key event at once (application/run/flush_stdout_on_print; F-073 §1).
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
	if options.simulator != null:
		# The simulator hosts, or joins when its port is taken (network-simulator.gd): a server
		# that finds itself a client could not open its port.
		var adopted := await _simulator_peer()
		if adopted == null or not _hosts(adopted):
			_log(
				"server: cannot listen on port %d/udp: netfox's simulator did not host"
				% [options.port]
			)
			_quit(EXIT_PORT_UNAVAILABLE)
			return
		_log("server: %s" % options.simulator.describe())
	else:
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
	if options.simulator != null:
		_log("client: %s" % options.simulator.describe())
		# The simulator joins, or hosts when nobody holds its port (network-simulator.gd): a
		# client that finds itself hosting found no server.
		var adopted := await _simulator_peer()
		if adopted == null or _hosts(adopted):
			_log("client: no server on port %d: netfox's simulator hosted here" % options.port)
			_end_client(GameText.SERVER_NOT_RESPONDING, EXIT_SERVER_NOT_RESPONDING)
			return
	else:
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
	_close_replay()
	NetworkTime.stop()
	_save_record()
	_stop_measuring()
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
	if _recorder != null:
		_recorder.follow(fighter)
	# The others mirror the newcomer's fighter, and the newcomer mirrors every fighter, its own
	# included, under the server's node names, so netfox's routes match on every peer, and with
	# each fighter's first tick on the server. Each fighter's state goes to a peer only once the
	# peer was told the fighter exists.
	for other: int in _players:
		_add_fighter.rpc_id(other, slot, peer, String(fighter.name), _first_tick(fighter))
		fighter.send_state_to(other)
	_players.append(peer)
	for player: int in _players:
		var player_slot := _handshake_server.room.slot_of(player)
		var mirrored := current_match.fighter_at(player_slot)
		var first_tick := _first_tick(mirrored)
		_add_fighter.rpc_id(peer, player_slot, player, String(mirrored.name), first_tick)
		mirrored.send_state_to(peer)
	_log("server: peer %d joined the match as %s, seat %d" % [peer, fighter.name, slot])


func _on_player_left(peer: int, slot: int) -> void:
	if _players.has(peer):
		_players.erase(peer)
		if current_match != null:
			_log("server: %s leaves the match" % current_match.fighter_at(slot).name)
			_forget(current_match.fighter_at(slot))
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
# it and closes the window; without one, when the bot plays and nobody sits at the window, or when
# the window measured its frame rate in fullscreen, the game quits with exit_code. Deferred,
# because these calls come from inside SceneMultiplayer's poll, which must end before the
# connection closes.
func _end_client(key: StringName, exit_code: int) -> void:
	if _client_phase == ClientPhase.ENDED:
		return
	_client_phase = ClientPhase.ENDED
	_show(key)
	var unattended := options.bot or not options.measure_fps.is_empty()
	if DisplayServer.get_name() == "headless" or unattended:
		_quit.call_deferred(exit_code)
	else:
		end_session.call_deferred()


# The server tells a client that a fighter exists: in slot, driven by the input of input_owner,
# under the server's node name.
@rpc("authority", "call_remote", "reliable")
func _add_fighter(slot: int, input_owner: int, node_name: String, first_tick: int) -> void:
	if current_match == null or slot < 0 or slot >= current_match.arena.spawn_point_count():
		return
	var free_name := node_name == node_name.validate_node_name() and not node_name.is_empty()
	if current_match.fighter_at(slot) != null or not free_name or current_match.has_node(node_name):
		return
	var mine := input_owner == multiplayer.get_unique_id()
	# This client's own fighter starts on the server's first tick, so both simulate it from the
	# same tick and the same state; right after the clock syncs, this clock lags the server's by
	# about the one-way latency, and that tick may still be ahead here (TASK-9, round C2). A
	# mirrored fighter is never simulated here and starts on this clock's tick: one that spawned
	# long ago would otherwise ask netfox to redo ticks it no longer keeps.
	var start_tick := first_tick if mine else NetworkTime.tick
	var fighter := current_match.spawn_fighter(slot, input_owner, start_tick, node_name)
	# netfox learns a new fighter's route only at the end of the frame (RollbackSynchronizer._ready
	# defers process_settings()), and the server's first state for it can come in this same poll:
	# with no route yet, netfox would drop it with a warning. process_settings() is netfox's call
	# for "the configuration changed", safe to run again.
	fighter.synchronizer.process_settings()
	if mine and options.bot:
		current_match.let_bot_play(fighter)
	elif mine:
		current_match.watch(fighter)
	if mine and _recorder != null:
		_recorder.follow(fighter)
	var whose := " (mine)" if mine else ""
	if mine and options.bot:
		whose = " (mine, the bot plays it)"
	_log("client: %s joined, seat %d, peer %d%s" % [node_name, slot, input_owner, whose])
	if mine:
		_measure_from_now()


# The server tells a client that the fighter in slot left the match.
@rpc("authority", "call_remote", "reliable")
func _remove_fighter(slot: int) -> void:
	if current_match == null or current_match.fighter_at(slot) == null:
		return
	_log("client: %s left" % current_match.fighter_at(slot).name)
	_forget(current_match.fighter_at(slot))
	current_match.remove_fighter(slot)


# The match of the session; movement_data, when given, replaces movement_v0.tres, as a replay's
# numbers do.
func _start_match(movement_data: MovementData = null) -> void:
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	current_match = node as Match
	current_match.movement_data = movement_data
	add_child(current_match)


# Sozinho records the session as a replay (TASK-10.3; F-112 §2): in user://replays/, in
# --replay-dir, or in --replay's file, from the fighter's first tick; the log says where, with the
# whole path.
func _start_replay(fighter: Fighter) -> void:
	_replay = ReplayRecorder.new()
	if not options.replay_dir.is_empty():
		_replay.directory = options.replay_dir
	add_child(_replay)
	var error := _replay.start(current_match, [fighter], options.replay)
	if error != OK:
		var where := options.replay if not options.replay.is_empty() else _replay.directory
		push_error("cannot record the replay in %s: %s" % [where, error_string(error)])
		_replay.queue_free()
		_replay = null
		return
	var kept := ""
	if options.replay.is_empty():
		kept = " (the newest %d kept there)" % ReplayRecorder.KEEP
	_log(
		"sozinho: records the replay to %s%s" % [ProjectSettings.globalize_path(_replay.path), kept]
	)


# The session ends: the replay's last rows go to the disk.
func _close_replay() -> void:
	if _replay == null:
		return
	_replay.close()
	_log(
		"sozinho: replay of %d ticks saved to %s"
		% [_replay.rows_written, ProjectSettings.globalize_path(_replay.path)],
	)
	_replay.queue_free()
	_replay = null


# Every row of --watch has played: the window says so; with --trace, it writes what it played and
# the game quits, so tools/replay.sh can compare it.
func _on_replay_watched() -> void:
	for line: String in _watch.summary():
		_log("sozinho: watch: %s" % line)
	_status = StatusMessage.new()
	add_child(_status)
	_show(GameText.REPLAY_ENDED)
	if options.trace.is_empty():
		return
	var error := _watch.save_trace(options.trace)
	if error != OK:
		push_error("cannot write the trace to %s: %s" % [options.trace, error_string(error)])
		_quit(EXIT_REPLAY_REFUSED)
		return
	var written := ProjectSettings.globalize_path(options.trace)
	_log("sozinho: watch: trace written to %s, the loops to %s.loops" % [written, written])
	_quit(OK)


# --half: the window takes the left or the right half of its screen's usable area, the layout of
# netfox's WindowTiler for two windows (window-tiler.gd, _tile_window). The tiler itself waits for
# the other window for about 0.45 s, and two games started together on this PC open up to a second
# apart, so a window often found itself alone and filled the screen (TASK-9, round C2).
func _place_window(right: bool) -> void:
	var window := get_window()
	var area := DisplayServer.screen_get_usable_rect(window.current_screen)
	var width := floori(area.size.x / 2.0)
	window.mode = Window.MODE_WINDOWED
	window.size = Vector2i(width, area.size.y)
	window.position = area.position + Vector2i(width if right else 0, 0)
	_log("%s: the window takes the %s half of the screen" % [_role(), "right" if right else "left"])


# --record: the recorder follows the fighters this game computes, from the session's start. A
# client keeps its first result of each tick, what its player saw; the server its last one, what
# it confirmed (TickRecorder).
func _start_recording() -> void:
	var server := options.mode == LaunchOptions.Mode.SERVER
	var keep := TickRecorder.Keep.LAST if server else TickRecorder.Keep.FIRST
	_recorder = TickRecorder.new(options.record, keep)
	add_child(_recorder)
	_log("%s: records its fighters to %s" % [_role(), options.record])


func _forget(fighter: Fighter) -> void:
	if _recorder != null and fighter != null:
		_recorder.forget(fighter)


# --measure-fps (TASK-9, criterion 17): the screen as the assets probe measured it (F-056 §5),
# fullscreen with vsync off and no frame limit, and the meter, which begins once this game's own
# fighter plays (_measure_from_now).
func _prepare_measurement() -> void:
	var window := get_window()
	window.mode = Window.MODE_FULLSCREEN
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED, window.get_window_id())
	Engine.max_fps = 0
	_meter = FpsMeter.new(options.measure_fps)
	_meter.finished.connect(_on_measured)
	add_child(_meter)
	_log(
		"%s: measures the frame rate to %s once its fighter plays: %d s of warm-up, then %d s"
		% [_role(), options.measure_fps, FpsMeter.WARMUP_S, FpsMeter.MEASURE_S],
	)


# This game's own fighter plays: the warm-up begins, and the meter looks for the match's fighters
# in the camera's view.
func _measure_from_now() -> void:
	if _meter == null or _meter.phase != FpsMeter.Phase.IDLE:
		return
	_meter.watched_match = current_match
	_meter.begin_at(Time.get_ticks_usec())
	_log("%s: its fighter plays; the frames are timed after the warm-up" % _role())


# The measurement is over: it is written, and the session ends cleanly with 0. A file that cannot
# be written is an error in the log, as with --record.
func _on_measured() -> void:
	var error := _meter.save()
	if error == OK:
		_log("%s: %s; written to %s" % [_role(), _meter.stats.describe(), options.measure_fps])
	else:
		push_error(
			"cannot write the measurement to %s: %s" % [options.measure_fps, error_string(error)],
		)
	_quit(OK)


# The session ends: the meter stops, and a measurement it had not finished is not written.
func _stop_measuring() -> void:
	if _meter == null:
		return
	if _meter.phase != FpsMeter.Phase.DONE:
		_log(
			"%s: the session ended before the measurement did; nothing written to %s"
			% [_role(), options.measure_fps],
		)
	_meter.queue_free()
	_meter = null


# The tick netfox starts the fighter's history on, here on the server.
static func _first_tick(fighter: Fighter) -> int:
	var first_tick: int = fighter.synchronizer.spawn_tick
	return first_tick


# The record of --record is written once, when the session ends.
func _save_record() -> void:
	if _recorder == null:
		return
	var error := _recorder.save()
	if error == OK:
		_log("%s: wrote %d states to %s" % [_role(), _recorder.record.size(), options.record])
	else:
		push_error("cannot write the record to %s: %s" % [options.record, error_string(error)])
	_recorder.queue_free()
	_recorder = null


# netfox's network simulator sets its peer one frame after it starts (network-simulator.gd), and
# the Main started in between, so the handshake was in place before any connection could open. The
# peer the simulator set; null when it set none.
func _simulator_peer() -> MultiplayerPeer:
	for _frame: int in SIMULATOR_FRAMES:
		if multiplayer.multiplayer_peer is not OfflineMultiplayerPeer:
			break
		await get_tree().process_frame
	var peer := multiplayer.multiplayer_peer
	var connected := peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED
	if peer is OfflineMultiplayerPeer or not connected:
		return null
	return peer


# True when peer hosts: the server is peer 1 (MultiplayerPeer.TARGET_PEER_SERVER).
static func _hosts(peer: MultiplayerPeer) -> bool:
	return peer.get_unique_id() == MultiplayerPeer.TARGET_PEER_SERVER


# The probe crashed on exit (F-026 §4): the session ends while netfox is alive, then the game
# quits with exit_code. A server that netfox's network simulator connected also runs the
# simulator's proxy, which holds every packet for the simulated latency: it stays up that long, so
# the clients hear the goodbye instead of waiting 5 to 30 s for ENet to give up on a silent server.
# The wait is on the wall clock: a SceneTreeTimer counts frames' deltas, and the frame after
# end_session(), which may write a record, is long enough to eat most of a short timer at once
# (measured in TASK-9, round C2: the server left 43 ms after its goodbye, with the goodbye still
# in the proxy).
func _quit(exit_code: int) -> void:
	end_session()
	var leave_at := Time.get_ticks_msec()
	if options.mode == LaunchOptions.Mode.SERVER and options.simulator != null:
		leave_at += options.simulator.latency_ms + PROXY_DRAIN_MARGIN_MS
	await get_tree().process_frame
	while Time.get_ticks_msec() < leave_at:
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
