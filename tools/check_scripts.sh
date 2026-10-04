#!/usr/bin/env bash
# Compiles every script of ours in one Godot run (DEC-0005; DEC-0022; TASK-6, criterion 4): the
# import step skips a script that nothing loads, so its type errors used to reach a green gate
# (F-021). The canaries in tools/canaries/compile/ run every time through the same check: each
# bad_*.gd must be rejected and each good_*.gd must compile (TASK-6, criterion 6).
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/lib.sh
godot_bin="$(resolve_godot)"
shopt -s nullglob

canary_dir=tools/canaries/compile
bad=("$canary_dir"/bad_*.gd)
good=("$canary_dir"/good_*.gd)
if [ "${#bad[@]}" -eq 0 ] || [ "${#good[@]}" -eq 0 ]; then
	echo "no bad_*.gd or good_*.gd in $canary_dir: the compile check lost its self-test (TASK-6)"
	exit 1
fi

args=()
mapfile -t own < <(own_gd_files)
for path in "${own[@]}"; do
	args+=("own:res://$path")
done
for path in "${bad[@]}"; do
	args+=("bad:res://$path")
done
for path in "${good[@]}"; do
	args+=("good:res://$path")
done

# The bad canaries print SCRIPT ERROR lines on purpose, and a green gate log must hold no error
# line (TASK-6, criterion 5), so Godot's output shows only when the check fails. The summary line
# proves that check_scripts.gd ran to the end.
status=0
output="$("$godot_bin" --headless --path . -s res://tools/check_scripts.gd -- "${args[@]}" 2>&1)" ||
	status=$?
output="${output//$'\r'/}"
summary="$(grep -E '^[0-9]+ scripts compile; canaries ok: ' <<<"$output" || true)"
if [ "$status" -eq 0 ] && [ -n "$summary" ]; then
	echo "$summary"
	exit 0
fi
echo "$output"
echo "the compile check failed (exit $status): fix the scripts above, or the canary that misbehaved"
exit 1
