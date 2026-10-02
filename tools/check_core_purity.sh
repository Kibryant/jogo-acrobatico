#!/usr/bin/env bash
# DEC-0004 rule 1: core/ is pure simulation. No nodes, engine singletons, wall clock,
# timers, await or unseeded randomness. Text after '#' is ignored.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -d core ]; then
	echo "no core/ yet"
	exit 0
fi

mapfile -t files < <(find core -name '*.gd' -type f)
if [ "${#files[@]}" -eq 0 ]; then
	echo "core/ is pure (no scripts yet)"
	exit 0
fi

PAT='extends[[:space:]]+(Node|Node2D|Node3D|CharacterBody3D|RigidBody3D|Area3D|Control|Resource)([^A-Za-z0-9_]|$)'
PAT+='|get_tree\(|get_node\(|[$][A-Za-z_"]'
PAT+='|(^|[^A-Za-z0-9_])(Input|Engine|Time|OS|DisplayServer|ResourceLoader)[.]'
PAT+='|(^|[^A-Za-z0-9_])(pre)?load\('
PAT+='|(^|[^A-Za-z0-9_])(randi|randf|randf_range|randi_range|randomize)\('
PAT+='|(^|[^A-Za-z0-9_])Timer([^A-Za-z0-9_]|$)|(^|[^A-Za-z0-9_])await[[:space:]]|create_timer'
export PAT

violations=$(awk '{ code = $0; sub(/#.*/, "", code); if (code ~ ENVIRON["PAT"]) printf "%s:%d: %s\n", FILENAME, FNR, $0 }' "${files[@]}")
if [ -n "$violations" ]; then
	echo "$violations"
	echo "core/ must stay pure (DEC-0004 rule 1): the lines above use the engine, the clock or unseeded randomness."
	exit 1
fi
echo "core/ is pure (${#files[@]} files)"
