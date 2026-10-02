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

# Lists the project's own GDScript files, tracked or new, without third-party addons.
own_gd_files() {
	git ls-files --cached --others --exclude-standard -- '*.gd' ':!:addons/**'
}
