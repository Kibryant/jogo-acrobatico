#!/usr/bin/env bash
# DEC-0004 rule 1: core/ is pure simulation. No nodes, engine singletons, wall clock,
# timers, await or unseeded randomness. A '#' outside a string starts a comment, which is
# ignored; text inside strings is still checked, the safe side (TASK-6, criterion 3).
# The canaries in tools/canaries/purity/ run on every call: each bad_*.gd must be flagged and
# each good_*.gd must stay clean, or this check has lost a rule (TASK-6, criterion 6).
set -euo pipefail
cd "$(dirname "$0")/.."
shopt -s nullglob

PAT='extends[[:space:]]+(Node|Node2D|Node3D|CharacterBody3D|RigidBody3D|Area3D|Control|Resource)([^A-Za-z0-9_]|$)'
PAT+='|get_tree\(|get_node\(|[$][A-Za-z_"]'
PAT+='|(^|[^A-Za-z0-9_])(Input|Engine|Time|OS|DisplayServer|ResourceLoader)[.]'
PAT+='|(^|[^A-Za-z0-9_])(pre)?load\('
PAT+='|(^|[^A-Za-z0-9_])(randi|randf|randf_range|randi_range|randomize)\('
PAT+='|(^|[^A-Za-z0-9_])Timer([^A-Za-z0-9_]|$)|(^|[^A-Za-z0-9_])await[[:space:]]|create_timer'
export PAT

# Prints "file:line: text" for every line of the given files whose code matches PAT. A small
# lexer walks each line so that a '#' inside a string never hides the rest of it: a string ends
# at the quote that opened it (three quotes for a triple-quoted one), and a backslash escapes
# the next character. Strings may span lines in GDScript, the triple-quoted ones and, in Godot
# 4.7.2, the quoted ones too, so the open string carries to the next line and resets when a new
# file starts. Plain POSIX awk: CI may run mawk.
scan() {
	awk '
	BEGIN { sq = "\047"; dq = "\"" }
	FNR == 1 { quote = "" }
	{
		line = $0
		sub(/\r$/, "", line)
		code = ""
		i = 1
		while (i <= length(line)) {
			c = substr(line, i, 1)
			if (quote != "") {
				if (c == "\\") {
					code = code substr(line, i, 2)
					i += 2
				} else if (substr(line, i, length(quote)) == quote) {
					code = code quote
					i += length(quote)
					quote = ""
				} else {
					code = code c
					i++
				}
			} else if (c == "#") {
				break
			} else if (c == dq || c == sq) {
				quote = (substr(line, i, 3) == (c c c)) ? (c c c) : c
				code = code quote
				i += length(quote)
			} else {
				code = code c
				i++
			}
		}
		if (code ~ ENVIRON["PAT"]) printf "%s:%d: %s\n", FILENAME, FNR, line
	}' "$@"
}

status=0

core_files=()
if [ -d core ]; then
	mapfile -t core_files < <(find core -name '*.gd' -type f)
fi
if [ "${#core_files[@]}" -gt 0 ]; then
	violations="$(scan "${core_files[@]}")"
	if [ -n "$violations" ]; then
		echo "$violations"
		echo "core/ must stay pure (DEC-0004 rule 1): the lines above use the engine, the clock or unseeded randomness."
		status=1
	fi
fi

canary_dir=tools/canaries/purity
bad=("$canary_dir"/bad_*.gd)
good=("$canary_dir"/good_*.gd)
if [ "${#bad[@]}" -eq 0 ] || [ "${#good[@]}" -eq 0 ]; then
	echo "no bad_*.gd or good_*.gd in $canary_dir: the purity check lost its self-test (TASK-6)"
	exit 1
fi
canary_hits="$(scan "${bad[@]}" "${good[@]}")"
flagged() { [[ $'\n'"$canary_hits" == *$'\n'"$1":* ]]; }
for canary in "${bad[@]}"; do
	if ! flagged "$canary"; then
		echo "canary $canary: expected flagged, got clean: the purity check lost a rule (TASK-6)"
		status=1
	fi
done
for canary in "${good[@]}"; do
	if flagged "$canary"; then
		echo "canary $canary: expected clean, got flagged: the purity check lost a rule (TASK-6)"
		grep -F "$canary:" <<<"$canary_hits" | sed 's/^/  /'
		status=1
	fi
done

if [ "$status" -ne 0 ]; then
	exit "$status"
fi
canaries="canaries ok: ${#bad[@]} bad flagged, ${#good[@]} good clean"
if [ ! -d core ]; then
	echo "no core/ yet ($canaries)"
elif [ "${#core_files[@]}" -eq 0 ]; then
	echo "core/ is pure (no scripts yet; $canaries)"
else
	echo "core/ is pure (${#core_files[@]} files; $canaries)"
fi
