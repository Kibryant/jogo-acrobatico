#!/usr/bin/env bash
# Helpers for the scripts that run the game as several Godot processes on this PC: the checks of
# the server and client modes (tools/net_check.sh), the 30 s run (tools/net_run.sh) and the
# session to play by hand (tools/play_online.sh). Source it after tools/lib.sh, from the project
# root, then set godot_bin and logs. Every process it starts is kept in pids, by name.

declare -A pids=()
# Options for Godot itself on every headless start, after --headless; none by default.
godot_options=()

now_ms() {
	date +%s%3N
}

# start NAME ARGS...: one headless game with the game's arguments ARGS, logged to NAME.log.
start() {
	local name=$1
	shift
	"$godot_bin" --headless "${godot_options[@]}" --path . -- "$@" >"$logs/$name.log" 2>&1 &
	pids[$name]=$!
}

# start_window NAME ARGS...: one game in a window, with the game's arguments ARGS, logged to
# NAME.log.
start_window() {
	local name=$1
	shift
	"$godot_bin" --path . -- "$@" >"$logs/$name.log" 2>&1 &
	pids[$name]=$!
}

# wait_for NAME TEXT SECONDS: true once NAME.log holds TEXT, false after SECONDS.
wait_for() {
	local deadline=$((SECONDS + $3))
	until grep -qF -- "$2" "$logs/$1.log" 2>/dev/null; do
		if ((SECONDS >= deadline)); then
			return 1
		fi
		sleep 0.1
	done
}

# wait_exit NAME SECONDS: waits for NAME to end and leaves its exit code in exit_code; 124 when
# it is still running after SECONDS, and then it is stopped.
wait_exit() {
	local pid=${pids[$1]} deadline=$((SECONDS + $2))
	while kill -0 "$pid" 2>/dev/null; do
		if ((SECONDS >= deadline)); then
			kill "$pid" 2>/dev/null || true
			wait "$pid" 2>/dev/null || true
			unset "pids[$1]"
			exit_code=124
			return
		fi
		sleep 0.05
	done
	exit_code=0
	wait "$pid" || exit_code=$?
	unset "pids[$1]"
}

# Stops every started process that is still running.
stop_started() {
	local name
	for name in "${!pids[@]}"; do
		kill "${pids[$name]}" 2>/dev/null || true
	done
	wait 2>/dev/null || true
}

# The engine's errors in the logs given, one per line; empty when there is none.
log_errors() {
	grep -hE '^(ERROR|SCRIPT ERROR|USER ERROR):' "$@" || true
}

# The engine's warnings in the logs given, one per line; empty when there is none.
log_warnings() {
	grep -hE '^(WARNING|USER WARNING):' "$@" || true
}
