#!/usr/bin/env bash
# The summary of a replay (TASK-14; testes-e-entrega.md §4, "O resumo"). Sozinho records every
# session in user://replays/ and its log says where; give that path:
#   bash tools/replay_summary.sh FILE [--force]
#     plays it headless, through the real Match, as tools/replay.sh does, and prints, in
#     Portuguese, what used to be measured by hand after each session: the time per mode, the
#     maneuvers, the walls, the height, the longest flight and the health; the presses of the jump,
#     the dash and the grapple; and each sword move's clicks, swings, results, distances, aim and
#     speed. One block per fighter: in Sozinho, fighter 0 is the player and fighter 1 the dummy.
# --force summarizes a file of another build anyway, with this build's rules: the summary says the
# first tick its state left the live game's. It exits with 0 once it printed the summary, 1 when
# the file is refused or the run fails, and 2 on a wrong argument.
set -euo pipefail
here="$PWD"
cd "$(dirname "$0")/.."
source tools/lib.sh
refuse_override_cfg
godot_bin="$(resolve_godot)"

usage() {
	echo "uso: bash tools/replay_summary.sh ARQUIVO [--force]" >&2
	echo "  toca o replay sem tela e imprime o resumo da sessão;" >&2
	echo "  --force toca um arquivo de outra build" >&2
	exit 2
}

given=""
file=""
force=""
while [ "$#" -gt 0 ]; do
	case "$1" in
	--force) force="--force" ;;
	--*)
		echo "argumento desconhecido: $1" >&2
		usage
		;;
	*)
		if [ -n "$file" ]; then
			echo "um arquivo de cada vez: $given e $1" >&2
			usage
		fi
		given="$1"
		file="$(godot_path "$here" "$1")"
		;;
	esac
	shift
done
[ -n "$file" ] || usage

args=("$file" --summary)
[ -z "$force" ] || args+=("$force")
play_headless "$godot_bin" "${args[@]}"
# A refusal is the player's exit 1 with no error in its log: its lines already said why, in
# Portuguese, followed by the reader's messages.
if [ -z "$play_errors" ] && { [ "$play_status" -eq 0 ] || [ "$play_status" -eq 1 ]; }; then
	exit "$play_status"
fi
[ -z "$play_errors" ] || echo "$play_output"
echo "o tocador sem tela falhou (saída $play_status)" >&2
exit 1
