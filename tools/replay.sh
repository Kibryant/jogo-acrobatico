#!/usr/bin/env bash
# Plays a replay file (TASK-10.3; DEC-0027 §5; testes-e-entrega.md §4). Sozinho records every
# session in user://replays/ and its log says where; give that path:
#   bash tools/replay.sh FILE [--force] [--readable=OUT] [--trace=OUT]
#     plays it headless, through the real Match (tools/replay_play.tscn): it prints the ticks, the
#     sha256 of the state trace and the first tick whose state left the one the live game
#     computed; --readable writes a copy in decimals, --trace the state trace.
#   bash tools/replay.sh FILE [--force] --watch [--max-fps N] [--trace=OUT]
#     plays it in a window, on the real clock (the game's --watch): you watch your session again.
#     --max-fps N caps the frames at N, with vsync off so the cap holds above the screen's rate.
#     With --trace, the window writes what it played and closes at the end, and the headless
#     player then plays the same file and compares the two traces.
#   bash tools/replay.sh --sample=OUT
#     records the scripted session of the gate's tests (test/replay/replay_session.gd) to OUT.
# --force plays a file of another build anyway. It exits with 0 once it played, 1 when the file
# is refused or the run fails, and 2 on a wrong argument.
set -euo pipefail
here="$PWD"
cd "$(dirname "$0")/.."
source tools/lib.sh
refuse_override_cfg
godot_bin="$(resolve_godot)"

usage() {
	sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//' >&2
	exit 2
}

# A path for Godot: user:// and res:// as they are, any other one from where the script was run.
godot_path() {
	case "$1" in
	user://* | res://*) echo "$1" ;;
	/* | [A-Za-z]:*) native_path "$1" ;;
	*) native_path "$here/$1" ;;
	esac
}

file=""
force=""
watch=""
max_fps=""
readable=""
trace=""
sample=""
while [ "$#" -gt 0 ]; do
	case "$1" in
	--force) force="--force" ;;
	--watch) watch=1 ;;
	--max-fps)
		[ "$#" -ge 2 ] || usage
		max_fps="$2"
		shift
		;;
	--max-fps=*) max_fps="${1#--max-fps=}" ;;
	--readable=*) readable="$(godot_path "${1#--readable=}")" ;;
	--trace=*) trace="$(godot_path "${1#--trace=}")" ;;
	--sample=*) sample="$(godot_path "${1#--sample=}")" ;;
	--*)
		echo "unknown argument: $1" >&2
		usage
		;;
	*)
		[ -z "$file" ] || usage
		file="$(godot_path "$1")"
		;;
	esac
	shift
done

esc="$(printf '\033')"
# run_headless ARGS...: the headless player with ARGS after "--"; prints its "replay: " lines and
# fails on any error line or exit code.
run_headless() {
	local status=0 output errors
	output="$("$godot_bin" --headless --path . --scene res://tools/replay_play.tscn -- "$@" 2>&1)" ||
		status=$?
	output="$(sed -e "s/${esc}\[[0-9;]*[A-Za-z]//g" -e 's/\r$//' <<<"$output")"
	errors="$(grep -E '^(ERROR|SCRIPT ERROR|USER ERROR):' <<<"$output" || true)"
	grep -E '^replay: ' <<<"$output" | sed -e 's/^replay: //' || true
	if [ "$status" -ne 0 ] || [ -n "$errors" ]; then
		[ -z "$errors" ] || echo "$output"
		echo "the headless player failed (exit $status)" >&2
		return "$((status == 0 ? 1 : status))"
	fi
}

if [ -n "$sample" ]; then
	if [ -n "$file$force$watch$max_fps$readable$trace" ]; then
		usage
	fi
	run_headless "--sample=$sample"
	exit 0
fi
[ -n "$file" ] || usage
if [ -n "$max_fps" ] && { [ -z "$watch" ] || ! [[ "$max_fps" =~ ^[0-9]+$ ]]; }; then
	echo "--max-fps N goes with --watch, N a whole number" >&2
	usage
fi
if [ -n "$watch" ] && [ -n "$readable" ]; then
	echo "--readable goes without --watch: the headless player writes it" >&2
	usage
fi

if [ -z "$watch" ]; then
	args=("$file")
	[ -z "$force" ] || args+=("$force")
	[ -z "$readable" ] || args+=("--readable=$readable")
	[ -z "$trace" ] || args+=("--trace=$trace")
	run_headless "${args[@]}"
	exit 0
fi

window=()
if [ -n "$max_fps" ]; then
	window+=(--max-fps "$max_fps" --disable-vsync)
fi
game=("--watch=$file")
[ -z "$force" ] || game+=("$force")
[ -z "$trace" ] || game+=("--trace=$trace")
status=0
output="$("$godot_bin" --path . "${window[@]}" -- "${game[@]}" 2>&1)" || status=$?
output="$(sed -e "s/${esc}\[[0-9;]*[A-Za-z]//g" -e 's/\r$//' <<<"$output")"
grep -E '^sozinho: ' <<<"$output" || true
errors="$(grep -E '^(ERROR|SCRIPT ERROR|USER ERROR):' <<<"$output" || true)"
if [ "$status" -ne 0 ] || [ -n "$errors" ]; then
	[ -z "$errors" ] || echo "$errors"
	echo "the window failed or refused the file (exit $status)" >&2
	exit "$((status == 0 ? 1 : status))"
fi
if [ -n "$trace" ]; then
	echo
	echo "The headless player plays the same file and compares:"
	args=("$file")
	[ -z "$force" ] || args+=("$force")
	run_headless "${args[@]}" "--against=$trace"
fi
