#!/usr/bin/env bash
# Runs every gdUnit4 suite under test/ headless (DEC-0006). Extra arguments go to gdUnit4.
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/lib.sh
godot_bin="$(resolve_godot)"

# --remote-debug to a port that is never bound keeps Godot from opening its interactive
# debugger on a script error (the same trick gdUnit4's runtest.sh uses).
"$godot_bin" --headless --path . -s -d --remote-debug tcp://127.0.0.1:0 \
	res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://test --ignoreHeadlessMode "$@"
