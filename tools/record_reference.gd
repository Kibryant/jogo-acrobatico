# Records the reference's trace again (TASK-9, criterion 16; DEC-0027 §2, layer 4): plays the
# route through test/reference/reference_run.gd, exactly as the test does, and writes the trace to
# the file named after "--". tools/record_reference.sh runs it as the scene of a headless game, with
# a temporary file it moves into test/reference/route.trace after a clean run: a scene loads after
# netfox's autoloads, while a -s script compiles before them and cannot name them
# (tools/check_scripts.gd).
# It writes nothing when the route no longer covers what it claims: then the route needs a fix in
# test/reference/reference_route.gd, not a new trace. Every line it prints for the shell script
# starts with "reference: ".
extends Node

const ReferenceRun := preload("res://test/reference/reference_run.gd")


func _ready() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() != 1:
		print("reference: run it through tools/record_reference.sh, which names the file to write")
		get_tree().quit(2)
		return
	var result := await ReferenceRun.new().play(self)
	print("reference: paths %s" % result.paths.summary())
	var gaps := result.paths.missing()
	if not gaps.is_empty():
		print("reference: not recorded, the route no longer covers what it claims:")
		for gap: String in gaps:
			print("reference:   %s" % gap)
		print("reference: fix the route in test/reference/reference_route.gd and run this again")
		get_tree().quit(1)
		return
	var file := FileAccess.open(arguments[0], FileAccess.WRITE)
	if file == null:
		var why := error_string(FileAccess.get_open_error())
		print("reference: not recorded, %s cannot be written: %s" % [arguments[0], why])
		get_tree().quit(1)
		return
	file.store_string(result.trace)
	file.close()
	print(
		(
			"reference: played %d ticks in %.0f ms, sha256 %s"
			% [result.trace.count("\n"), result.run_usec / 1000.0, result.trace.sha256_text()]
		)
	)
	get_tree().quit(0)
