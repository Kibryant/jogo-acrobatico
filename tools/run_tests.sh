#!/usr/bin/env bash
# Runs every gdUnit4 suite under test/ headless (DEC-0027). Extra arguments go to gdUnit4.
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/lib.sh
godot_bin="$(resolve_godot)"

# No -d: without a local debugger, a script error ends the run with an exit code instead of
# stopping at a "debug>" prompt (a test file that does not parse exits with 105), and assertion
# failures and runtime errors are reported as before. The old --remote-debug trick printed two
# ERROR: lines in every run, right next to the real failures (TASK-6).
# -c (--continue): gdUnit4 runs every test instead of stopping at the first failure, so a red
# run shows all of its failures at once (TASK-6, criterion 5).
log="$(mktemp)"
# Sozinho keeps the player's own replays in user://replays/ (TASK-10.3; F-112 §2), and the gate
# never writes there: a file there newer than this stamp fails the run.
stamp="$(mktemp)"
trap 'rm -f "$log" "$stamp"' EXIT
set +e
"$godot_bin" --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd \
	-a res://test --ignoreHeadlessMode -c "$@" 2>&1 | tee "$log"
status="${PIPESTATUS[0]}"
set -e

# A green run must log no error: an engine or script error that fails no test still means that
# something broke (TASK-6, criterion 5). Colors are stripped before matching.
if [ "$status" -eq 0 ]; then
	esc="$(printf '\033')"
	errors="$(sed -e "s/${esc}\[[0-9;]*[A-Za-z]//g" -e 's/\r$//' "$log" |
		grep -E '^(ERROR|SCRIPT ERROR|USER ERROR):' || true)"
	if [ -n "$errors" ]; then
		echo "$errors"
		echo "tests passed but the log has errors: a green run must log none (TASK-6)"
		exit 1
	fi
	# test/replay/replay_recorder_test.gd prints where user://replays/ is on this machine. With no
	# extra argument every suite ran, so that line must be there (TASK-10.3, criterion 1).
	anchor='replay: user://replays/ is '
	replays="$(sed -e "s/${esc}\[[0-9;]*[A-Za-z]//g" -e 's/\r$//' "$log" |
		grep -m 1 -F "$anchor" | sed -e "s|^.*${anchor}||" || true)"
	if [ -z "$replays" ] && [ "$#" -eq 0 ]; then
		echo "no test said where user://replays/ is (test/replay/replay_recorder_test.gd): the"
		echo "check that the gate never writes there has no folder to check (TASK-10.3)"
		exit 1
	fi
	if [ -n "$replays" ] && [ -d "$replays" ]; then
		fresh=()
		for file in "$replays"*; do
			if [ -e "$file" ] && [ "$file" -nt "$stamp" ]; then
				fresh+=("$file")
			fi
		done
		if [ "${#fresh[@]}" -gt 0 ]; then
			printf '%s\n' "${fresh[@]}"
			echo "the tests wrote into user://replays/, where Sozinho keeps the player's own replays"
			echo "(TASK-10.3): record in a temporary folder, or pass --no-replay to the Main. If the"
			echo "game ran in Sozinho on this PC during the run, run the gate again."
			exit 1
		fi
	fi
	echo "user://replays/ untouched by the tests: ${replays:-not checked}"
fi
exit "$status"
