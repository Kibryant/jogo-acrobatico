#!/usr/bin/env bash
# The frame rate of the client build on this PC (TASK-9, criterion 17; DEC-0002: 60 fps in 1080p
# on this PC). It exports the Windows client here, starts a headless server and a headless client
# from the source, and opens the build in fullscreen with the bot playing its fighter, at ping 0:
# no netfox simulator and no override.cfg. The build measures itself (--measure-fps; FpsMeter):
# once its fighter plays, 2 s of warm-up, then 60 s frame by frame, written as JSON. The script
# then closes the server through its stop file and prints the average, the 1% low and the
# resolution, with the verdict against 60 fps on average. It is not a gate step; run it by hand:
#   bash tools/measure_fps.sh
# It takes about 2 minutes, close to one of them for the export. Leave the PC alone while it runs:
# the window takes the whole screen, and every other program running here weighs on the frames.
# The other client is not a bot: its fighter stands at its spawn point, ahead of the window's
# camera, so both fighters stay on the screen. Two bots that run sideways drift apart, about 17 m
# on average, and the other one would leave the view for half the time or more (TASK-9, round D3).
# The export has no stamp, so its empty commit matches the server's from the source (DEC-0028 §3).
# Port 7777/udp must be free. The logs and the JSON stay in a temporary folder, printed at the end.
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/lib.sh
source tools/net_lib.sh
source tools/build_lib.sh
refuse_override_cfg
godot_bin="$(resolve_godot)"

if [ "$#" -ne 0 ]; then
	echo "usage: bash tools/measure_fps.sh, with no argument" >&2
	exit 2
fi
# DEC-0002: 60 fps in 1080p on this PC.
floor_fps=60
floor_screen=1920x1080
# s: the bounds the script waits for. Once its fighter plays, the window measures for 62 s
# (FpsMeter: 2 s of warm-up, then 60 s), after its own start and its handshake.
start_timeout=20
measure_timeout=120
end_timeout=15
# The headless games draw at most 144 frames per second, as in the other network scripts
# (rede.md §9), and leave the cores to the window; netfox's ticks stay at 60.
godot_options=(--max-fps 144)

logs="$(mktemp -d)"
result="$logs/fps.json"
stop="$logs/server.stop"
started=$SECONDS
# Ctrl+C or a failure: the server closes through its stop file, which also ends both clients, and
# whatever is still running after a few seconds is stopped.
finish() {
	local status=$?
	touch "$stop"
	local name
	for name in window other server; do
		if [ -n "${pids[$name]:-}" ]; then
			wait_exit "$name" 5
		fi
	done
	stop_started
	echo "logs in $logs"
	exit "$status"
}
trap finish EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# field NAME: the value of NAME in the result, which FpsMeter writes one field per line, without
# its quotes; empty when the result has no such field.
field() {
	awk -v key="\"$1\":" '
		{ sub(/\r$/, "") }
		$1 == key {
			value = substr($0, index($0, key) + length(key))
			sub(/^[ \t]+/, "", value)
			sub(/,$/, "", value)
			gsub(/^"|"$/, "", value)
			print value
			exit
		}
	' "$result"
}

echo "measure fps: Godot $("$godot_bin" --version | tr -d '\r'), logs in $logs"
bash tools/export_builds.sh client

start server --server --stop-file="$(native_path "$stop")"
if ! wait_for server "listening on port $server_port/udp" "$start_timeout"; then
	echo "the server did not start: see $logs/server.log" >&2
	exit 1
fi
# The other fighter, standing at its spawn point in front of the window's camera.
start other --connect=127.0.0.1:"$server_port"
if ! wait_for other " (mine)" "$start_timeout"; then
	echo "the other client got no fighter: see $logs/other.log" >&2
	exit 1
fi
echo "the build opens in fullscreen and measures for about a minute: leave the PC alone"
"./$client_build" -- --connect=127.0.0.1:"$server_port" --bot \
	--measure-fps="$(native_path "$result")" >"$logs/window.log" 2>&1 &
pids[window]=$!
wait_exit window "$measure_timeout"
window_code=$exit_code
touch "$stop"
wait_exit server "$end_timeout"
server_code=$exit_code
wait_exit other "$end_timeout"
other_code=$exit_code

echo
echo "exit codes: the window $window_code, the server $server_code, the other client $other_code"
failed=0
if [ "$window_code" -ne 0 ] || [ "$server_code" -ne 0 ] || [ "$other_code" -ne 0 ]; then
	failed=1
fi
errors="$(log_errors "$logs"/*.log)"
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
average="$(field average_fps 2>/dev/null || true)"
if [ -z "$average" ]; then
	echo "no measurement: the window wrote no result to $result; see $logs/window.log" >&2
	exit 1
fi

echo
cat "$result"
screen="$(field screen_size)"
in_view="$(field two_fighters_in_view_pct)"
vsync="$(field vsync)"
echo
echo "$average fps on average, 1% low $(field one_percent_low_fps) fps" \
	"(99th percentile $(field p99_frame_ms) ms), worst frame $(field worst_frame_ms) ms"
echo "window $(field window_size) on a $screen screen at $(field screen_refresh_hz) Hz," \
	"vsync $vsync, $(field gpu); both fighters in view in $in_view% of the frames"
if [ "$screen" != "$floor_screen" ]; then
	warn "the screen is $screen, not the $floor_screen of DEC-0002: this is not the floor's \
measurement"
fi
if [ "$vsync" != disabled ]; then
	warn "vsync was $vsync, not disabled: the screen's refresh rate may have capped the frames"
fi
if ! awk -v share="$in_view" 'BEGIN { exit !(share + 0 >= 100) }'; then
	warn "both fighters were in view in $in_view% of the frames, not all of them: criterion 17 \
asks for both on the screen"
fi
echo "measure fps took $((SECONDS - started)) s"
if awk -v fps="$average" -v floor="$floor_fps" 'BEGIN { exit !(fps + 0 >= floor + 0) }'; then
	echo "PASS: $average fps on average, at or above the $floor_fps fps of DEC-0002"
else
	echo "FAIL: $average fps on average, below the $floor_fps fps of DEC-0002"
	failed=1
fi
if [ "$failed" -ne 0 ]; then
	echo "measure fps FAILED: see the exit codes, the logs and the verdict above"
	exit 1
fi
