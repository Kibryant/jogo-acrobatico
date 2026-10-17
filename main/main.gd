# The entry scene (DEC-0026 §6; rede.md §9): it reads how the game was opened, like a main.ts
# reading process.argv, and starts that mode. Part 1 of TASK-9 knows one: with no argument,
# Sozinho, Godot's offline peer, where this PC is its own server (rede.md §8). The server and the
# client arrive in part 2, with their arguments.
class_name Main
extends Node

const MATCH_SCENE := preload("res://match/match.tscn")
## The arguments after "--" that this build knows, by name; part 2 adds the server and the client.
const KNOWN_ARGUMENTS: Array[String] = []
## The exit code of a launch with an argument this build does not know: a typo once left a
## fullscreen probe open for 300 s (F-056).
const EXIT_USAGE := 2
const USAGE := """Usage: open the game with no argument to play Sozinho (this PC is its own server).
This build knows no argument yet: the server and the client modes arrive in part 2 of TASK-9."""

## The match of the session; null when no session runs.
var current_match: Match


func _ready() -> void:
	var unknown := unknown_arguments(OS.get_cmdline_user_args())
	if not unknown.is_empty():
		printerr("Unknown argument: %s\n%s" % [", ".join(unknown), USAGE])
		get_tree().quit(EXIT_USAGE)
		return
	# Closing the window comes to _notification instead of quitting at once, so the session ends
	# cleanly first (DEC-0026 §6).
	get_tree().auto_accept_quit = false
	await start_solo()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_quit_cleanly()


# Each argument whose name (before any "=") this build does not know, in order.
static func unknown_arguments(arguments: PackedStringArray) -> PackedStringArray:
	var unknown := PackedStringArray()
	for argument: String in arguments:
		if not KNOWN_ARGUMENTS.has(argument.trim_prefix("--").get_slice("=", 0)):
			unknown.append(argument)
	return unknown


# Sozinho: Godot's default peer is an OfflineMultiplayerPeer with the server's id, 1, so this PC
# simulates and confirms its own fighter, with no network and nothing to redo. netfox's clock starts
# first, then the match (DEC-0026 §6). start() is a coroutine because a client waits for the
# server's clock; the server, Sozinho's role, does not wait.
func start_solo() -> void:
	var started: int = await NetworkTime.start()
	assert(started == OK, "netfox's clock did not start: %s" % error_string(started))
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	current_match = node as Match
	add_child(current_match)
	current_match.watch(current_match.spawn_fighter(0, multiplayer.get_unique_id()))


# The clean end of a session (DEC-0026 §6): stop netfox's clock, which also drops its history;
# close the connection, which Sozinho does not have (the offline peer stays); free the match.
func end_session() -> void:
	NetworkTime.stop()
	if current_match != null:
		current_match.queue_free()
		current_match = null


# The probe crashed on exit (F-026 §4): the match leaves while netfox is alive, then the game
# quits with 0.
func _quit_cleanly() -> void:
	end_session()
	await get_tree().process_frame
	get_tree().quit(0)
