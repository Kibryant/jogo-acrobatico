#!/usr/bin/env bash
# Opens a networked session to play by hand (TASK-9, criterion 13): a headless server, a client
# that the bot plays in the right half of the screen and yours in the left half, with netfox's
# network simulator adding the ping (rede.md §10). In your window, the keys and the mouse play your
# capsule, the lighter one; the darker one is the bot's, which runs sideways and jumps every 2 s.
#   bash tools/play_online.sh [PING_MS]     (100 when not given; 220 is the limit of rede.md §10)
# Close your window to end: the script closes the server through its stop file, the bot quits
# with it, and the script prints the exit codes and where the logs are.
# The simulator works only through its own autoconnect, so the script writes an override.cfg at
# the project root for these games: it is removed once they have read it, and on any exit,
# Ctrl+C included. Ports 7777 and 7778 must be free.
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/lib.sh
source tools/net_lib.sh
refuse_override_cfg
godot_bin="$(resolve_godot)"

ping_ms="${1:-100}"
if ! [[ "$ping_ms" =~ ^[0-9]+$ ]] || ((ping_ms % 2 != 0)); then
	echo "usage: bash tools/play_online.sh [PING_MS], an even number of ms like 100 or 220" >&2
	exit 2
fi
# The game's default port (LaunchOptions.DEFAULT_PORT); the simulator's proxy takes the next one.
port=7777
# s: the bounds the script waits for: the start, and the server and the bot after the stop file.
start_timeout=20
end_timeout=15
# The headless server draws at most 144 frames per second, as the probe's did (netfox-sonda,
# play.sh), and leaves the cores to the two windows; netfox's ticks stay at 60.
godot_options=(--max-fps 144)

logs="$(mktemp -d)"
stop="$logs/server.stop"
# Ctrl+C or a failure: the server closes through its stop file, which also ends the bot, and
# whatever is still running after a few seconds is stopped.
finish() {
	local status=$?
	touch "$stop"
	local name
	for name in server bot; do
		if [ -n "${pids[$name]:-}" ]; then
			wait_exit "$name" 5
		fi
	done
	stop_started
	rm -f override.cfg
	echo "logs in $logs"
	exit "$status"
}
trap finish EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

echo "play online: Godot $("$godot_bin" --version | tr -d '\r'), ping $ping_ms ms, logs in $logs"
printf '%s\n' \
	"; Written by tools/play_online.sh for one session with netfox's network simulator; it" \
	"; removes it. If no session is going, delete this file: it turns the simulator on for every" \
	"; Godot run here." \
	"[netfox]" \
	"autoconnect/enabled=true" \
	"autoconnect/port=$port" \
	"autoconnect/simulated_latency_ms=$((ping_ms / 2))" >override.cfg

start server --server --stop-file="$(native_path "$stop")"
if ! wait_for server "listening on port $port/udp" "$start_timeout"; then
	echo "the server did not start: see $logs/server.log" >&2
	exit 1
fi
# One window after the other: a game's first frames in a window are slow, and two at once upset
# the clock sync of both (TASK-9, round C2). Yours opens once the bot plays.
start_window bot --connect=127.0.0.1:"$port" --bot --half=right
if ! wait_for bot "(mine, the bot plays it)" "$start_timeout"; then
	echo "the bot got no fighter: see $logs/bot.log" >&2
	exit 1
fi
start_window you --connect=127.0.0.1:"$port" --half=left
if ! wait_for you "client: connecting to" "$start_timeout"; then
	echo "your window did not start: see $logs/you.log" >&2
	exit 1
fi
# Both games have read it by now; no other Godot run of the project must see it.
rm -f override.cfg
echo "ping $ping_ms ms: your capsule is the lighter one in your window; close it to end"

wait_exit you 86400
you_code=$exit_code
touch "$stop"
wait_exit server "$end_timeout"
server_code=$exit_code
wait_exit bot "$end_timeout"
bot_code=$exit_code
echo "exit codes: your window $you_code, the server $server_code, the bot $bot_code"
if [ "$you_code" -ne 0 ] || [ "$server_code" -ne 0 ] || [ "$bot_code" -ne 0 ]; then
	exit 1
fi
