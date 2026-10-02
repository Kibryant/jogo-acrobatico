#!/usr/bin/env bash
# Format and lint check of our GDScript (DEC-0005). With --fix, formats in place instead.
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/lib.sh

mapfile -t files < <(own_gd_files)
if [ "${#files[@]}" -eq 0 ]; then
	echo "no GDScript files yet"
	exit 0
fi

if [ "${1:-}" = "--fix" ]; then
	gdscript-formatter "${files[@]}"
	echo "formatted ${#files[@]} files"
	exit 0
fi

gdscript-formatter --check "${files[@]}"
gdscript-formatter lint "${files[@]}"
echo "format and lint ok (${#files[@]} files)"
