# Compiles every script named on the command line in one Godot run (TASK-6, criterion 4). The
# import step does not parse a script that nothing loads, so an untyped declaration or an unsafe
# access in such a script used to reach a green gate (F-021). tools/check_scripts.sh passes, after
# "--", one argument per script:
# - "own:res://..." is one of our scripts, and it must compile;
# - "bad:res://..." is a canary that must not compile, and "good:res://..." one that must. They
#   prove that this check still bars what it bars (TASK-6, criterion 6).
extends SceneTree

const MUST_COMPILE: Dictionary[String, bool] = { "own": true, "bad": false, "good": true }


# _initialize(), not _init(): Godot 4.7.2 runs a script's _init() before it registers the
# autoloads, so a script naming netfox's NetworkTime failed here with "Identifier not found" while
# it compiles in the editor and in the game (TASK-9, part 1).
func _initialize() -> void:
	var counts: Dictionary[String, int] = { "own": 0, "bad": 0, "good": 0 }
	var failures := 0
	for argument: String in OS.get_cmdline_user_args():
		var parts := argument.split(":", true, 1)
		if parts.size() != 2 or not MUST_COMPILE.has(parts[0]):
			print("FAIL %s: expected own:, bad: or good: before a res:// path" % argument)
			failures += 1
			continue
		var kind := parts[0]
		var path := parts[1]
		if kind != "own" and counts["bad"] + counts["good"] == 0:
			print("Canaries from here on: their errors are expected (TASK-6, criterion 6).")
		counts[kind] += 1
		var compiles := _compiles(path)
		if compiles != MUST_COMPILE[kind]:
			print("FAIL %s: %s" % [path, _failure_reason(kind, compiles)])
			failures += 1
	if failures > 0:
		print(
			"%d of %d scripts failed the compile check"
			% [failures, OS.get_cmdline_user_args().size()]
		)
		quit(1)
		return
	print(
		"%d scripts compile; canaries ok: %d bad rejected, %d good compiled"
		% [counts["own"], counts["bad"], counts["good"]],
	)
	quit(0)


# True when the script at path compiles. In Godot 4.7.2 a script that does not compile still loads
# as a Script, so a load that returns one proves nothing: such a script can be neither instantiated
# nor abstract. An abstract script is legal, whether or not Godot calls it instantiable (TASK-6).
func _compiles(path: String) -> bool:
	# This script compiled, or it would not be running. Loading it again while it runs crashes
	# Godot 4.7.2 (signal 11).
	var running: Script = get_script()
	if path == running.resource_path:
		return true
	var resource := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if resource is not Script:
		return false
	var script: Script = resource
	return script.can_instantiate() or script.is_abstract()


func _failure_reason(kind: String, compiles: bool) -> String:
	if kind == "own":
		return "does not compile (the errors above say why)"
	var expected := "compiled" if MUST_COMPILE[kind] else "rejected"
	var got := "compiled" if compiles else "rejected"
	return "canary expected %s, got %s: the compile check lost a rule (TASK-6)" % [expected, got]
