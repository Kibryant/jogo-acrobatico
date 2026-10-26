# How the game was opened (DEC-0026 §6; rede.md §9), read from the arguments after "--", like a
# main.ts reading process.argv. A pure function of the arguments, of the dedicated server build,
# of the screen and of netfox's network simulator, so a test covers every form without opening the
# game:
# - no argument: Sozinho, which records a replay of the session in user://replays/ (TASK-10.3;
#   F-112 §2), or in --replay=PATH, or in --replay-dir=DIR, or none with --no-replay;
# - --server [--port=N] [--stop-file=PATH] [--record=PATH], or the build exported as a dedicated
#   server: the server, which runs without a screen;
# - --connect=HOST[:PORT] [--bot] [--record=PATH]: a client, played by a person or by the bot.
# With a screen, --half=left or --half=right puts the window on that half of the screen, and
# --measure-fps=PATH measures the frame rate in fullscreen once the game's own fighter plays.
# With a screen, --watch=FILE [--force] [--trace=PATH] plays a replay in Sozinho instead of the
# keyboard, and records none.
# Sozinho puts a still dummy at the second spawn point to stand on and bump into (TASK-10.7);
# --dummy=off leaves it out.
# When netfox's network simulator connects the game (SimulatorLink), the address is its own: an
# address in the arguments that differs is refused, and so is Sozinho, which has no network.
# An argument this build does not know, or one that does not fit the mode, is an error: a typo
# once left a fullscreen probe open for up to 300 s (.claude/harness/registro.md, 2026-10-07).
class_name LaunchOptions
extends RefCounted

enum Mode {
	SOLO,
	SERVER,
	CLIENT,
}

## TASK-9, choice 9: the port of the probes (F-073), changed by --port or in --connect.
const DEFAULT_PORT := 7777
const LAST_PORT := 65535
const SERVER := "server"
const PORT := "port"
const CONNECT := "connect"
const STOP_FILE := "stop-file"
const BOT := "bot"
const RECORD := "record"
const HALF := "half"
const MEASURE_FPS := "measure-fps"
const REPLAY := "replay"
const REPLAY_DIR := "replay-dir"
const NO_REPLAY := "no-replay"
const WATCH := "watch"
const TRACE := "trace"
const FORCE := "force"
const DUMMY := "dummy"
## The arguments this build knows, by name.
const KNOWN: Array[String] = [
	SERVER,
	PORT,
	CONNECT,
	STOP_FILE,
	BOT,
	RECORD,
	HALF,
	MEASURE_FPS,
	REPLAY,
	REPLAY_DIR,
	NO_REPLAY,
	WATCH,
	TRACE,
	FORCE,
	DUMMY,
]
## The ones that take no value.
const FLAGS: Array[String] = [SERVER, BOT, NO_REPLAY, FORCE]
## The ones that only Sozinho takes (TASK-10.3): the server and the clients record no replay.
const SOLO_ONLY: Array[String] = [REPLAY, REPLAY_DIR, NO_REPLAY, WATCH, TRACE, FORCE]
## The values of --half.
const HALVES: Array[String] = ["left", "right"]
## The values of --dummy: Sozinho's dummy stands at the second spawn point, or not (TASK-10.7).
const DUMMY_ON := "on"
const DUMMY_OFF := "off"

var mode := Mode.SOLO
## The server listens on it; a client connects to it.
var port := DEFAULT_PORT
## The server a client connects to; empty in the other modes.
var host := ""
## The file whose appearance closes the server cleanly (DEC-0032 §2); empty when none.
var stop_file := ""
## A client played by the bot (BotPlayer) instead of the keyboard and the mouse (TASK-9, part 2).
var bot := false
## The file where the session writes, when it ends, the states it computed for its fighters, tick
## by tick (TickRecorder; TASK-9, criterion 12); empty when none.
var record := ""
## The half of the screen the window takes, "left" or "right", so tools/play_online.sh shows two
## games side by side; empty to leave the window where Godot opens it.
var half := ""
## The file where the game writes, as JSON, its frame rate over a minute in fullscreen (FpsMeter;
## TASK-9, criterion 17); empty when it does not measure.
var measure_fps := ""
## The file Sozinho records its replay to; empty for a new file in replay_dir (ReplayRecorder).
var replay := ""
## The folder of Sozinho's replays; empty for user://replays/ (TASK-10.3; F-112 §2).
var replay_dir := ""
## Sozinho records no replay, as the gate's tests of the Main (TASK-10.3, criterion 1).
var no_replay := false
## The replay file Sozinho plays in a window instead of the keyboard; empty when it plays.
var watch := ""
## With --watch: where the window writes the state trace of what it played (StateTrace).
var trace := ""
## With --watch: plays a replay of another build anyway (ReplayFile's refusals).
var force := false
## Sozinho's still dummy at the second spawn point (TASK-10.7); --dummy=off leaves it out. Only
## Sozinho's own play has one: a server, a client and --watch never do.
var dummy := false
## netfox's network simulator, when it connects the game; null otherwise.
var simulator: SimulatorLink
## One line per problem with the arguments; the game opens only when there is none.
var errors := PackedStringArray()


func _init(
	arguments: PackedStringArray,
	dedicated_server: bool,
	has_screen: bool,
	network_simulator: SimulatorLink,
) -> void:
	simulator = network_simulator
	_read_mode(_read_names(arguments), dedicated_server, has_screen)


# The options of a launch with these arguments, in a build with or without the dedicated_server
# feature, with or without a screen, and with network_simulator when netfox's simulator connects
# the game.
static func parse(
	arguments: PackedStringArray,
	dedicated_server: bool,
	has_screen: bool,
	network_simulator: SimulatorLink = null,
) -> LaunchOptions:
	return LaunchOptions.new(arguments, dedicated_server, has_screen, network_simulator)


# Each known argument by name, with its value ("" for a flag); every other argument is an error.
func _read_names(arguments: PackedStringArray) -> Dictionary[String, String]:
	var given: Dictionary[String, String] = { }
	for argument: String in arguments:
		var parts := argument.trim_prefix("--").split("=", true, 1)
		var argument_name := parts[0]
		var has_value := parts.size() == 2
		var flag := FLAGS.has(argument_name)
		if not argument.begins_with("--") or not KNOWN.has(argument_name):
			errors.append("Unknown argument: %s" % argument)
		elif given.has(argument_name):
			errors.append("--%s is given twice" % argument_name)
		elif flag and has_value:
			errors.append("--%s takes no value: %s" % [argument_name, argument])
		elif not flag and (not has_value or parts[1].is_empty()):
			errors.append("--%s needs a value: --%s=..." % [argument_name, argument_name])
		else:
			given[argument_name] = parts[1] if has_value else ""
	return given


func _read_mode(
	given: Dictionary[String, String],
	dedicated_server: bool,
	has_screen: bool,
) -> void:
	var server := dedicated_server or given.has(SERVER)
	if given.has(CONNECT):
		if dedicated_server:
			errors.append("This build is a dedicated server: it cannot --connect")
		elif server:
			errors.append("--server and --connect do not go together")
		else:
			mode = Mode.CLIENT
			_read_address(given[CONNECT])
	elif server:
		mode = Mode.SERVER
		if has_screen:
			errors.append("The server runs without a screen: open Godot with --headless")
	if given.has(PORT):
		if mode == Mode.SERVER:
			port = _read_port(given[PORT])
		else:
			errors.append("--port goes with --server; a client takes it in --connect=HOST:PORT")
	if given.has(STOP_FILE):
		if mode == Mode.SERVER:
			stop_file = given[STOP_FILE]
		else:
			errors.append("--stop-file goes with --server")
	if given.has(BOT):
		if mode == Mode.CLIENT:
			bot = true
		else:
			errors.append("--bot goes with --connect: the bot plays a client")
	if given.has(RECORD):
		if mode == Mode.SOLO:
			errors.append("--record goes with --server or --connect")
		else:
			record = given[RECORD]
	if given.has(HALF):
		if not HALVES.has(given[HALF]):
			errors.append("--half is left or right, not %s" % given[HALF])
		elif not has_screen or mode == Mode.SERVER:
			errors.append("--half places a window: it needs a screen")
		else:
			half = given[HALF]
	if given.has(MEASURE_FPS):
		if not has_screen or mode == Mode.SERVER:
			errors.append("--measure-fps measures the frames of a window: it needs a screen")
		elif given.has(HALF):
			errors.append("--measure-fps takes the whole screen: it does not go with --half")
		else:
			measure_fps = given[MEASURE_FPS]
	_read_replay(given, has_screen)
	_read_dummy(given)
	if simulator != null:
		_check_simulator_address()


# True when this launch records a replay: Sozinho, unless --no-replay or --watch (TASK-10.3).
func records_replay() -> bool:
	return mode == Mode.SOLO and not no_replay and watch.is_empty()


# The replay's arguments, Sozinho's only (TASK-10.3): where it records, or none, or the replay a
# window plays instead of the keyboard.
func _read_replay(given: Dictionary[String, String], has_screen: bool) -> void:
	for argument_name: String in SOLO_ONLY:
		if given.has(argument_name) and mode != Mode.SOLO:
			errors.append(
				"--%s goes with Sozinho: the server and the clients record no replay"
				% argument_name,
			)
	if mode != Mode.SOLO:
		return
	var recording := given.has(REPLAY) or given.has(REPLAY_DIR)
	if given.has(REPLAY) and given.has(REPLAY_DIR):
		errors.append("--replay names the file and --replay-dir its folder: give one of them")
	if given.has(NO_REPLAY) and recording:
		errors.append("--no-replay records nothing: it goes without --replay and --replay-dir")
	if given.has(WATCH):
		if not has_screen:
			errors.append(
				"--watch plays a replay in a window: it needs a screen (tools/replay.sh plays one"
				+ " without)",
			)
		elif recording or given.has(NO_REPLAY):
			errors.append(
				"--watch records no replay: it goes without --replay, --replay-dir and --no-replay",
			)
		elif given.has(MEASURE_FPS):
			errors.append("--watch and --measure-fps do not go together")
		else:
			watch = given[WATCH]
	else:
		for argument_name: String in [TRACE, FORCE]:
			if given.has(argument_name):
				errors.append("--%s goes with --watch" % argument_name)
	replay = given.get(REPLAY, "")
	replay_dir = given.get(REPLAY_DIR, "")
	no_replay = given.has(NO_REPLAY)
	if not watch.is_empty():
		trace = given.get(TRACE, "")
		force = given.has(FORCE)


# Sozinho's dummy (TASK-10.7): on unless --dummy=off, and only in Sozinho's own play; --watch
# plays the fighters of its file.
func _read_dummy(given: Dictionary[String, String]) -> void:
	var playing := mode == Mode.SOLO and watch.is_empty() and not given.has(WATCH)
	if not given.has(DUMMY):
		dummy = playing
		return
	var value := given[DUMMY]
	if value != DUMMY_ON and value != DUMMY_OFF:
		errors.append("--dummy is on or off, not %s" % value)
	elif mode != Mode.SOLO:
		errors.append("--dummy goes with Sozinho: the server and the clients have no dummy")
	elif given.has(WATCH):
		errors.append(
			"--dummy goes with Sozinho's own play: --watch plays the fighters of its file"
		)
	else:
		dummy = value == DUMMY_ON


# HOST or HOST:PORT. An IPv6 address, with its own colons, is not read here.
func _read_address(address: String) -> void:
	var colon := address.rfind(":")
	host = address if colon == -1 else address.left(colon)
	if host.is_empty():
		errors.append("--connect needs a host: --connect=HOST[:PORT], like 127.0.0.1:7777")
	if colon != -1:
		port = _read_port(address.substr(colon + 1))


func _read_port(text: String) -> int:
	if not text.is_valid_int() or text.to_int() < 1 or text.to_int() > LAST_PORT:
		errors.append("A port is a number from 1 to %d, not %s" % [LAST_PORT, text])
		return DEFAULT_PORT
	return text.to_int()


# netfox's network simulator hosts on its own port, or joins its own host through its proxy, and
# reads no argument (network-simulator.gd). An address in the arguments that is not its own would
# be silently ignored, so it is refused, like any argument that does not fit.
func _check_simulator_address() -> void:
	var own_port := "%s=%d" % [SimulatorLink.PORT_SETTING, simulator.port]
	match mode:
		Mode.SOLO:
			errors.append(
				(
					"netfox's network simulator is on (%s, likely from an override.cfg) and"
					+ " Sozinho has no network: open the game with --server or --connect"
				)
				% SimulatorLink.ENABLED_SETTING,
			)
		Mode.SERVER:
			if port != simulator.port:
				errors.append(
					"netfox's network simulator hosts on port %d (%s), not %d"
					% [simulator.port, own_port, port],
				)
		Mode.CLIENT:
			if host != simulator.host or port != simulator.port:
				errors.append(
					"netfox's network simulator joins %s:%d (%s, %s), not %s:%d"
					% [
						simulator.host,
						simulator.port,
						"%s=%s" % [SimulatorLink.HOST_SETTING, simulator.host],
						own_port,
						host,
						port,
					],
				)
