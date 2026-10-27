#!/usr/bin/env bash
# The 30 s networked run of TASK-9, criterion 12: a headless server and two headless clients that
# the bot plays, on this PC, with netfox's network simulator at ping 100 (rede.md §10). Each
# client records what it predicted for its own fighter, tick by tick, and the server what it
# confirmed for each fighter; tools/net_run_check.gd then holds them together and prints, per
# client, the ticks checked and corrected. It is not a gate step; run it by hand:
#   bash tools/net_run.sh [PING_MS]        (100 when not given; an even number of ms)
# It exits with 0 only when every process exited with 0, no tick was corrected or missing, every
# client has 25 s of checked ticks, every client's bot made at least one double jump and one dash
# (TASK-10.8) and no log holds an engine error.
# The simulator works only through its own autoconnect, so the run writes an override.cfg at the
# project root for its processes: it is removed once they have read it, and on any exit. Ports
# 7777 and 7778 must be free. The logs and the records stay in a temporary folder, printed at the
# end.
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/lib.sh
source tools/net_lib.sh
refuse_override_cfg
godot_bin="$(resolve_godot)"

ping_ms="${1:-100}"
if ! [[ "$ping_ms" =~ ^[0-9]+$ ]] || ((ping_ms % 2 != 0)); then
	echo "usage: bash tools/net_run.sh [PING_MS], an even number of ms like 100 or 220" >&2
	exit 2
fi
# The game's default port (LaunchOptions.DEFAULT_PORT); the simulator's proxy takes the next one.
port=7777
# s: how long the two fighters play once both exist (TASK-9, criterion 12).
play_seconds=30
# s: the bounds the run waits for. The clients take a few seconds to shake hands and sync.
start_timeout=20
end_timeout=20
# Three games on four cores: each draws at most 144 frames per second, as the probe's runs did
# (netfox-sonda, run_net.sh), so none starves the others; netfox's ticks stay at 60.
godot_options=(--max-fps 144)

logs="$(mktemp -d)"
started=$SECONDS
finish() {
	stop_started
	rm -f override.cfg
}
trap finish EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

echo "net run: Godot $("$godot_bin" --version | tr -d '\r'), ping $ping_ms ms, logs in $logs"
printf '%s\n' \
	"; Written by tools/net_run.sh for one run with netfox's network simulator; it removes it." \
	"; If no run is going, delete this file: it turns the simulator on for every Godot run here." \
	"[netfox]" \
	"autoconnect/enabled=true" \
	"autoconnect/port=$port" \
	"autoconnect/simulated_latency_ms=$((ping_ms / 2))" >override.cfg

stop="$logs/server.stop"
start server --server --stop-file="$(native_path "$stop")" \
	--record="$(native_path "$logs/server.record")"
if ! wait_for server "listening on port $port/udp" "$start_timeout"; then
	echo "the server did not start: see $logs/server.log" >&2
	exit 1
fi
for client in client1 client2; do
	start "$client" --connect=127.0.0.1:"$port" --bot \
		--record="$(native_path "$logs/$client.record")"
done
for client in client1 client2; do
	if ! wait_for "$client" "(mine, the bot plays it)" "$start_timeout"; then
		echo "$client got no fighter: see $logs/$client.log" >&2
		exit 1
	fi
done
# Every process has read it by now; no other Godot run of the project must see it.
rm -f override.cfg
echo "both fighters are in; the bots play for $play_seconds s"
sleep "$play_seconds"
touch "$stop"

failed=0
for name in server client1 client2; do
	wait_exit "$name" "$end_timeout"
	echo "$name exited with $exit_code"
	if [ "$exit_code" -ne 0 ]; then
		failed=1
	fi
done

echo
check_status=0
NETFOX_NO_AUTOCONNECT=1 "$godot_bin" --headless --path . -s res://tools/net_run_check.gd -- \
	"$logs/server.record" "$logs/client1.record" "$logs/client2.record" \
	>"$logs/check.log" 2>&1 || check_status=$?
grep -vE '^Godot Engine ' "$logs/check.log" || true
if [ "$check_status" -ne 0 ]; then
	failed=1
fi

# netfox's simulator tries to host before it joins (network-simulator.gd, _try_and_host), so Godot
# logs this one error in each client, whose port the server already holds; a server that cannot
# host exits with 6 and fails the run anyway.
errors="$(log_errors "$logs"/*.log | grep -vxF "ERROR: Couldn't create an ENet host." || true)"
warnings="$(log_warnings "$logs"/*.log)"
if [ -n "$errors" ]; then
	echo "the logs hold errors:"
	echo "$errors"
	failed=1
fi
if [ -n "$warnings" ]; then
	echo "warnings in the logs:"
	echo "$warnings"
fi

echo
echo "net run took $((SECONDS - started)) s; logs and records in $logs"
if [ "$failed" -ne 0 ]; then
	echo "net run FAILED"
	exit 1
fi
echo "net run passed"
