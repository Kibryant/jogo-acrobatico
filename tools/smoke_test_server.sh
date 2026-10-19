#!/usr/bin/env bash
# The smoke test of the exported server (DEC-0028, Consequences; F-045 §3; TASK-9, criterion 15):
# the Linux dedicated server build starts headless with a stop file, logs that it runs the version
# and the commit stamped in project.godot and that it listens on 7777/udp, exits with 0 once the
# stop file appears, and logs no engine error. The CI's export job runs it right after
# tools/export_builds.sh, with the stamp still in project.godot:
#   bash tools/smoke_test_server.sh [BUILD]      (the Linux server build by default)
# The build runs as it is, so the Linux one runs only on Linux. Port 7777/udp must be free. The
# log stays in a temporary folder, printed at the end.
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/lib.sh
source tools/net_lib.sh
source tools/build_lib.sh

if [ "$#" -gt 1 ]; then
	echo "usage: bash tools/smoke_test_server.sh [BUILD], the Linux server build by default" >&2
	exit 2
fi
build="${1:-$server_build}"
case "$build" in
*/*) ;;
*) build="./$build" ;;
esac
# s: the probe's server was ready in 1.2 to 1.6 s (F-073 §2); the stop file is checked once per
# second (TASK-9, choice 2).
start_timeout=20
stop_timeout=10

version="$(project_version)"
commit="$(project_commit)"
logs="$(mktemp -d)"
stop="$logs/server.stop"
trap stop_started EXIT

echo "smoke test of $build: version $version, commit \"$commit\"; log in $logs"
started=$(now_ms)
start_build server "$build" --stop-file="$(native_path "$stop")"
listening=false
if wait_for server "server: listening on port $server_port/udp" "$start_timeout"; then
	listening=true
	pass "the server starts headless and listens, $(($(now_ms) - started)) ms after its start"
else
	fail "the server did not listen on $server_port/udp within $start_timeout s"
fi
touch "$stop"
started=$(now_ms)
wait_exit server "$stop_timeout"
took=$(($(now_ms) - started))
if $listening && [ "$exit_code" -eq 0 ]; then
	pass "the stop file closes it with exit 0 in $took ms"
else
	fail "it exited with $exit_code, $took ms after the stop file appeared"
fi
check_server_log "$logs/server.log" "$version" "$commit"
check_clean_logs "$logs/server.log"

show_log "$logs/server.log"
printf '%s\n' "${summary[@]}"
if [ "$failures" -gt 0 ]; then
	echo "smoke test failed: $failures failures (log in $logs)"
	exit 1
fi
echo "smoke test passed (log in $logs)"
