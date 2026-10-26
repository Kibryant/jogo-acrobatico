# Reads the records of a networked run and says, per client, whether the server confirmed what the
# client predicted for its own fighter, tick by tick (TASK-9, criterion 12; PredictionCheck).
# tools/net_run.sh runs it after the run, headless, with the server's record first:
#   godot --headless --path . -s res://tools/net_run_check.gd -- SERVER_RECORD CLIENT_RECORD...
# It prints one summary per client, with the double jumps and the dashes its fighter made, then
# where each fighter went and how close the two came, and exits with 1 when a tick was corrected or
# missing, when a client has fewer than MIN_CHECKED_S seconds of checked ticks, or when a client's
# fighter made no double jump or no dash, in its own record or in the server's: the run must have
# played the maneuvers it checks (TASK-10.8, criterion 1); with 2 when it cannot read its
# arguments.
extends SceneTree

## s: the checked ticks each client needs out of the 30 s run (TASK-9, round C2).
const MIN_CHECKED_S := 25
## The game's tickrate, read as netfox reads it (network-time.gd); netfox's own default is 30.
const TICKRATE_SETTING := "netfox/time/tickrate"


func _initialize() -> void:
	var paths := OS.get_cmdline_user_args()
	if paths.size() < 2:
		print("usage: -- SERVER_RECORD CLIENT_RECORD...")
		quit(2)
		return
	var tickrate: int = ProjectSettings.get_setting(TICKRATE_SETTING, 30)
	var server := _read(paths[0])
	var failed := not server.errors.is_empty()
	for path: String in paths.slice(1):
		var client := _read(path)
		var check := PredictionCheck.compare(client, server)
		print("%s: %s" % [path.get_file(), check.summary(tickrate)])
		if not check.passed(MIN_CHECKED_S * tickrate):
			failed = true
		if not _made_the_maneuvers(path.get_file(), check.fighter, client, server):
			failed = true
	for fighter: String in server.fighters():
		var box := server.extent(fighter)
		print(
			"%s went over x %.2f to %.2f, y %.2f to %.2f, z %.2f to %.2f (the server's record)"
			% [
				fighter,
				box.position.x,
				box.end.x,
				box.position.y,
				box.end.y,
				box.position.z,
				box.end.z,
			],
		)
	print("closest approach between two fighters: %.2f m" % server.closest_approach())
	print("net run check %s" % ("FAILED" if failed else "passed"))
	quit(1 if failed else 0)


# Prints the double jumps and the dashes that came out for fighter, as its client predicted them
# and as the server confirmed them; false when any of the four is zero.
func _made_the_maneuvers(
	client_name: String,
	fighter: String,
	client: TickRecord,
	server: TickRecord,
) -> bool:
	if fighter.is_empty():
		return false
	var counts: Array[int] = [
		client.double_jumps(fighter),
		client.dashes(fighter),
		server.double_jumps(fighter),
		server.dashes(fighter),
	]
	print(
		(
			"%s: %s made %d double jumps and %d dashes in the client's record, %d and %d in the"
			+ " server's"
		)
		% [client_name, fighter, counts[0], counts[1], counts[2], counts[3]],
	)
	if counts.has(0):
		print(
			"%s: %s made no double jump or no dash: the run did not play its maneuvers"
			% [client_name, fighter]
		)
		return false
	return true


func _read(path: String) -> TickRecord:
	if not FileAccess.file_exists(path):
		var missing := TickRecord.new()
		missing.errors.append("no file %s" % path)
		return missing
	return TickRecord.from_text(FileAccess.get_file_as_string(path))
