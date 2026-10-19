#!/usr/bin/env bash
# Records the reference's trace again (TASK-9, criterion 16; DEC-0027 §2, layer 4; F-044 §2): the
# path of the fixed bot route, test/reference/route.trace, which the gate compares byte for byte
# on Windows and in the CI on Linux, like a Jest snapshot. This is the `jest -u` of it. Run it only
# when a code change moves the path on purpose, after finding out why it moved:
#   bash tools/record_reference.sh
# It plays the route headless, as the test does, through tools/record_reference.tscn, and leaves
# the stored trace untouched when the route no longer covers what it claims or the run logs an
# error.
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/lib.sh
refuse_override_cfg
godot_bin="$(resolve_godot)"

trace=test/reference/route.trace
fresh="$(mktemp)"
trap 'rm -f "$fresh"' EXIT

status=0
output="$("$godot_bin" --headless --path . --scene res://tools/record_reference.tscn -- \
	"$(native_path "$fresh")" 2>&1)" || status=$?
esc="$(printf '\033')"
output="$(sed -e "s/${esc}\[[0-9;]*[A-Za-z]//g" -e 's/\r$//' <<<"$output")"
errors="$(grep -E '^(ERROR|SCRIPT ERROR|USER ERROR):' <<<"$output" || true)"
played="$(grep -E '^reference: played ' <<<"$output" || true)"
if [ "$status" -ne 0 ] || [ -n "$errors" ] || [ -z "$played" ]; then
	echo "$output"
	echo "the reference was not recorded (exit $status): $trace is untouched"
	exit 1
fi
grep -E '^reference: ' <<<"$output" | sed -e 's/^reference: //'

new_sha="$(sha256sum "$fresh" | cut -d ' ' -f 1)"
if ! grep -qF "sha256 $new_sha" <<<"$played"; then
	echo "the file Godot wrote has sha256 $new_sha, not the one it printed: $trace is untouched" >&2
	exit 1
fi
old_sha=none
if [ -f "$trace" ]; then
	old_sha="$(sha256sum "$trace" | cut -d ' ' -f 1)"
fi
if [ "$new_sha" = "$old_sha" ]; then
	echo
	echo "The path did not change: $trace keeps sha256 $new_sha."
	exit 0
fi
cp "$fresh" "$trace"
echo
echo "Recorded $trace"
echo "  sha256 before: $old_sha"
echo "  sha256 now:    $new_sha"
echo "Commit it with a message that says why the path moved: which change moved it, and why the"
echo "new path is the right one. The CI compares it on Linux after the push."
