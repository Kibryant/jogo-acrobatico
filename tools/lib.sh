#!/usr/bin/env bash
# Shared helpers for the tools scripts. Source it, do not run it.

# Prints the Godot 4.7.2 binary to use: $GODOT when it is executable, else the first of
# godot, godot4 or the Windows console build found on PATH.
resolve_godot() {
	if [ -n "${GODOT:-}" ] && [ -x "$GODOT" ]; then
		echo "$GODOT"
		return
	fi
	local candidate
	for candidate in godot godot4 Godot_v4.7.2-stable_win64_console.exe; do
		if command -v "$candidate" >/dev/null 2>&1; then
			command -v "$candidate"
			return
		fi
	done
	echo "Godot 4.7.2 not found: install it or set GODOT=/path/to/godot" >&2
	exit 1
}

# Stops the calling script while an override.cfg sits at the project root. tools/net_run.sh and
# tools/play_online.sh write one to turn on netfox's network simulator for one session (TASK-9,
# part 2), and a session that was killed can leave it behind: then every Godot run of this project
# hosts or joins by itself on port 7777, the tests' runner included. Call it from the project root.
refuse_override_cfg() {
	if [ -e override.cfg ]; then
		echo "override.cfg at the project root turns on netfox's network simulator in every Godot run here; tools/net_run.sh and tools/play_online.sh write it for one session: if none is running, delete it (rm override.cfg) and run again" >&2
		exit 1
	fi
}

# Paths for Godot: a Windows path on Git Bash, the same path elsewhere.
native_path() {
	if command -v cygpath >/dev/null 2>&1; then
		cygpath -m "$1"
	else
		echo "$1"
	fi
}

# Lists the project's own GDScript files, tracked or new, without third-party addons and without
# the gate's canaries, which are broken on purpose and checked by the gate itself (TASK-6).
own_gd_files() {
	git ls-files --cached --others --exclude-standard -- \
		'*.gd' ':!:addons/**' ':!:tools/canaries/**'
}
