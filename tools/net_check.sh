#!/usr/bin/env bash
# Checks the server and client modes of the Main with real Godot processes on this PC (TASK-9,
# part 2, criteria 9 to 11). netfox's singletons hold one peer per process, so two peers cannot
# share a test run: this script starts a headless server and headless clients on localhost and
# reads their exit codes and logs. It is not a gate step; run it by hand:
#   bash tools/net_check.sh
# It uses port 7777 (the default) and NET_CHECK_PORT (27777 when not set); both must be free.
# Every process it starts is stopped when it ends, even on failure; the logs stay in a temporary
# folder, printed at the end.
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/lib.sh
godot_bin="$(resolve_godot)"

default_port=7777
other_port="${NET_CHECK_PORT:-27777}"
# A port nobody listens on, for the client that finds no server.
silent_port=$((other_port + 1))
# s: the bounds the checks wait for. The client's own timeout is 5 s (Main.CONNECT_TIMEOUT_S);
# ENet notices a client that vanished after 5 to 30 s.
start_timeout=20
connect_timeout=15
leave_timeout=45
# ms: the stop file is checked once per second (TASK-9, choice 2); the process then quits.
stop_budget_ms=2500

logs="$(mktemp -d)"
declare -A pids=()
failures=0
summary=()

# Paths for Godot: a Windows path on Git Bash, the same path elsewhere.
native_path() {
	if command -v cygpath >/dev/null 2>&1; then
		cygpath -m "$1"
	else
		echo "$1"
	fi
}

cleanup() {
	local name
	for name in "${!pids[@]}"; do
		kill "${pids[$name]}" 2>/dev/null || true
	done
	wait 2>/dev/null || true
}
trap cleanup EXIT

now_ms() {
	date +%s%3N
}

pass() {
	summary+=("ok    $1")
}

fail() {
	summary+=("FAIL  $1")
	failures=$((failures + 1))
}

# start NAME ARGS...: one headless game with the game's arguments ARGS, logged to NAME.log.
start() {
	local name=$1
	shift
	"$godot_bin" --headless --path . -- "$@" >"$logs/$name.log" 2>&1 &
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

# check NAME TEXT WHAT: passes WHAT when NAME.log holds TEXT.
check() {
	if grep -qF -- "$2" "$logs/$1.log"; then
		pass "$3"
	else
		fail "$3: no \"$2\" in $1.log"
	fi
}

# The id the server gave a client, read from the client's own log.
peer_of() {
	sed -n 's/^client: handshake accepted, peer \([0-9]*\)$/\1/p' "$logs/$1.log" | head -n 1
}

echo "net check: Godot $("$godot_bin" --version | tr -d '\r'), logs in $logs"

# 1. An argument the game does not know ends it with the usage code (F-056).
start usage --servr
wait_exit usage "$start_timeout"
if [ "$exit_code" -eq 2 ]; then
	pass "an unknown argument exits with 2"
else
	fail "an unknown argument exited with $exit_code, not 2"
fi

# 2. A client that finds no server says so and, without a screen, exits with 3.
started=$(now_ms)
start lonely --connect=127.0.0.1:"$silent_port"
wait_exit lonely "$connect_timeout"
took=$(($(now_ms) - started))
if [ "$exit_code" -eq 3 ]; then
	pass "a client with no server exits with 3 after ${took} ms"
else
	fail "a client with no server exited with $exit_code, not 3"
fi
check lonely "NET_SERVER_NOT_RESPONDING" "it shows that the server does not respond"

# 3. The room: two players get fighters, a third hears that the room is full, a player who
# leaves takes the fighter with them, a new player takes the free seat under a new node name,
# and the stop file closes the server with its players.
room_stop="$logs/room.stop"
start server --server --stop-file="$(native_path "$room_stop")"
if wait_for server "listening on port $default_port/udp" "$start_timeout"; then
	pass "the server listens on the default port, $default_port/udp"
else
	fail "the server did not listen on $default_port/udp"
fi
first_peer=none
second_peer=none
start first --connect=127.0.0.1
if wait_for first "client: Fighter0 joined, seat 0" "$connect_timeout"; then
	first_peer=$(peer_of first)
	check server "peer $first_peer joined the match as Fighter0, seat 0" "the first player gets a fighter"
	check first "Fighter0 joined, seat 0, peer $first_peer (mine)" "the first player plays it"
else
	fail "the first player got no fighter"
fi
start second --connect=127.0.0.1:"$default_port"
if wait_for second "client: Fighter1 joined, seat 1" "$connect_timeout"; then
	second_peer=$(peer_of second)
	check server "peer $second_peer joined the match as Fighter1, seat 1" "the second player gets a fighter"
	check second "Fighter1 joined, seat 1, peer $second_peer (mine)" "the second player plays it"
	check second "Fighter0 joined, seat 0, peer $first_peer" "the second player mirrors the first one's fighter"
	if wait_for first "Fighter1 joined, seat 1, peer $second_peer" 5; then
		pass "the first player mirrors the second one's fighter"
	else
		fail "the first player did not mirror the second one's fighter"
	fi
else
	fail "the second player got no fighter"
fi
start third --connect=127.0.0.1:"$default_port"
wait_exit third "$connect_timeout"
if [ "$exit_code" -eq 5 ]; then
	pass "a third player exits with 5"
else
	fail "a third player exited with $exit_code, not 5"
fi
check third "NET_ROOM_FULL" "the third player hears that the room is full"
check server "handshake refused: room full" "the server refuses the third player"
# Killed, the second player leaves without a word, as when a game crashes: ENet notices it.
started=$(now_ms)
kill -9 "${pids[second]}"
wait "${pids[second]}" 2>/dev/null || true
unset "pids[second]"
if wait_for first "client: Fighter1 left" "$leave_timeout"; then
	pass "the fighter of a player who leaves disappears for the other, $(($(now_ms) - started)) ms later"
	check server "peer $second_peer left, seat 1 free" "the server frees the seat"
else
	fail "the second player's fighter did not leave the first player's match"
fi
start fourth --connect=127.0.0.1:"$default_port"
if wait_for first "client: Fighter2 joined, seat 1" "$connect_timeout"; then
	pass "a new player takes the free seat as Fighter2, mirrored by the first player"
else
	fail "the free seat did not take a new player"
fi
started=$(now_ms)
touch "$room_stop"
wait_exit server "$start_timeout"
took=$(($(now_ms) - started))
if [ "$exit_code" -eq 0 ] && [ "$took" -le "$stop_budget_ms" ]; then
	pass "the stop file closes the server with players in it: exit 0 in ${took} ms"
else
	fail "with players in, the server exited with $exit_code ${took} ms after the stop file"
fi
check server "stop file seen" "the server saw the stop file"
for player in first fourth; do
	wait_exit "$player" "$start_timeout"
	if [ "$exit_code" -eq 0 ]; then
		pass "the $player player exits with 0 when the server closes"
	else
		fail "the $player player exited with $exit_code, not 0"
	fi
	check "$player" "NET_SERVER_CLOSED" "the $player player shows that the server closed"
done

# 4. A second server on a port that is taken says so and exits with 6; the stop file also closes
# a server nobody joined.
empty_stop="$logs/empty.stop"
start empty --server --port="$other_port" --stop-file="$(native_path "$empty_stop")"
if wait_for empty "listening on port $other_port/udp" "$start_timeout"; then
	pass "the server listens on --port=$other_port"
	# Godot itself logs an error when ENet cannot open the port: twin.log is left out of the scan.
	start twin --server --port="$other_port"
	wait_exit twin "$start_timeout"
	if [ "$exit_code" -eq 6 ]; then
		pass "a second server on the same port exits with 6"
	else
		fail "a second server on the same port exited with $exit_code, not 6"
	fi
	started=$(now_ms)
	touch "$empty_stop"
	wait_exit empty "$start_timeout"
	took=$(($(now_ms) - started))
	if [ "$exit_code" -eq 0 ] && [ "$took" -le "$stop_budget_ms" ]; then
		pass "the stop file closes an empty server: exit 0 in ${took} ms"
	else
		fail "the empty server exited with $exit_code ${took} ms after the stop file"
	fi
else
	fail "the server did not listen on --port=$other_port"
fi

# Engine errors and warnings in the logs: errors fail the check, warnings are listed.
scanned=()
for log in "$logs"/*.log; do
	if [ "$log" != "$logs/twin.log" ]; then
		scanned+=("$log")
	fi
done
errors="$(grep -hE '^(ERROR|SCRIPT ERROR|USER ERROR):' "${scanned[@]}" || true)"
warnings="$(grep -hE '^(WARNING|USER WARNING):' "${scanned[@]}" || true)"
if [ -n "$errors" ]; then
	fail "the logs hold errors:"
	summary+=("$errors")
else
	pass "no error in the logs"
fi
if [ -n "$warnings" ]; then
	summary+=("note  warnings in the logs:" "$warnings")
fi

printf '%s\n' "${summary[@]}"
if [ "$failures" -gt 0 ]; then
	echo "net check failed: $failures failures (logs in $logs)"
	exit 1
fi
echo "net check passed (logs in $logs)"
