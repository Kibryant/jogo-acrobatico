#!/usr/bin/env bash
# The server image check (DEC-0032 §1; TASK-9, criterion 15 and choice 3): a CI job on every push
# to main and every PR, outside the gate and the pre-push. It also runs here, with Docker up:
#   bash tools/server_image_check.sh [COMMIT]     (the first 7 characters of HEAD by default)
# 1. It stamps COMMIT into project.godot, exports the Linux server (tools/export_builds.sh) and
#    builds the image of the Dockerfile.
# 2. It runs the container with 7777/udp published on 127.0.0.1 and waits for the server to listen.
# 3. A headless client from the source, with the same stamp, must pass the handshake and get its
#    fighter: no Linux client is exported (TASK-9, choice 3).
# 4. With another commit stamped, a second client must be refused with exit 4 and
#    NET_UPDATE_REQUIRED; then the first stamp goes back.
# 5. A `docker exec … touch` of the stop file must close the server with exit 0, read by
#    `docker wait`, and the first client must then exit with 0 and NET_SERVER_CLOSED.
# 6. No log may hold an engine error.
# The container and the image are removed at the end: the image is never pushed. project.godot is
# backed up first and restored on any exit, so a run here leaves it as it was. Port 7777/udp must
# be free on this machine; the logs stay in a temporary folder, printed at the end.
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/lib.sh
source tools/net_lib.sh
source tools/build_lib.sh
refuse_override_cfg
godot_bin="$(resolve_godot)"

commit="${1:-$(git rev-parse HEAD | cut -c 1-7)}"
if [ "$#" -gt 1 ] || ! [[ "$commit" =~ ^[0-9a-f]{7,40}$ ]]; then
	echo "usage: bash tools/server_image_check.sh [COMMIT], 7 to 40 lowercase hex digits; the" \
		"first 7 characters of HEAD by default" >&2
	exit 2
fi
# The commit of another build, for the client that must be refused.
other_commit=0000000
if [ "$commit" = "$other_commit" ]; then
	other_commit=fffffff
fi
image="jogo-acrobatico-servidor:check-$commit"
# A name of its own, so that a container that failed to start is removed too.
container_name="jogo-acrobatico-servidor-check-$$"
# The stop file that the Dockerfile's ENTRYPOINT gives the server.
container_stop_file=/home/jogo/stop
# s: the bounds the check waits for. The probe's container was ready in 1.2 to 1.6 s (F-073 §2);
# a client takes a few seconds to shake hands and sync; the stop file is checked once per second
# (TASK-9, choice 2); ENet notices a server that vanished after 5 to 30 s.
start_timeout=30
connect_timeout=20
stop_timeout=20
leave_timeout=45

# Docker on Windows is a native program, and Git Bash would turn /home/jogo/stop into a Windows
# path on its way there.
docker_cli() {
	MSYS_NO_PATHCONV=1 docker "$@"
}

if ! docker_server="$(docker_cli version --format '{{.Server.Version}}' 2>&1)"; then
	echo "$docker_server" >&2
	echo "Docker does not answer: start it (Docker Desktop on Windows) and run again" >&2
	exit 1
fi

logs="$(mktemp -d)"
backup="$(mktemp)"
cp project.godot "$backup"
container=""
started=$SECONDS
reported=false

# The container's log, saved from Docker to server.log.
save_server_log() {
	docker_cli logs "$container" >"$logs/server.log" 2>&1 || true
}

# The logs of the run, the summary of its checks and the verdict.
report() {
	reported=true
	local name
	for name in server first second; do
		if [ -f "$logs/$name.log" ]; then
			show_log "$logs/$name.log"
		fi
	done
	printf '%s\n' "${summary[@]}"
	echo "server image check took $((SECONDS - started)) s; logs in $logs"
	if [ "$failures" -gt 0 ]; then
		echo "server image check FAILED: $failures failures"
	else
		echo "server image check passed"
	fi
}

# abort WHAT: a step the rest of the check needs failed; the report still comes out.
abort() {
	fail "$1"
	exit 1
}

finish() {
	local status=$?
	stop_started
	if [ -n "$container" ]; then
		save_server_log
		docker_cli rm --force "$container" >/dev/null 2>&1 || true
	fi
	docker_cli image rm --force "$image" >/dev/null 2>&1 || true
	cat "$backup" >project.godot
	rm -f "$backup"
	if ! $reported; then
		if [ "$status" -ne 0 ] && [ "$failures" -eq 0 ]; then
			fail "the check stopped early, with exit $status"
		fi
		report
	fi
}
trap finish EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

echo "server image check: commit $commit, Docker $(tr -d '\r' <<<"$docker_server"), logs in $logs"

# 1. The build and the image.
bash tools/stamp_build.sh "$commit"
version="$(project_version)"
bash tools/export_builds.sh server
echo "build the image $image"
if ! docker_cli build --tag "$image" . >"$logs/build.log" 2>&1; then
	show_log "$logs/build.log"
	abort "the image did not build"
fi
image_bytes="$(docker_cli image inspect --format '{{.Size}}' "$image" | tr -d '\r')"
pass "the image builds: $image, $((image_bytes / 1000000)) MB"

# 2. The container.
container="$container_name"
run_started=$(now_ms)
if ! docker_cli run --detach --name "$container" \
	--publish "127.0.0.1:$server_port:$server_port/udp" "$image" >/dev/null; then
	abort "the container did not start"
fi
listening=false
deadline=$((SECONDS + start_timeout))
while ((SECONDS < deadline)); do
	save_server_log
	if grep -qF "server: listening on port $server_port/udp" "$logs/server.log"; then
		listening=true
		break
	fi
	running="$(docker_cli inspect --format '{{.State.Running}}' "$container" | tr -d '\r')" ||
		running=false
	if [ "$running" != true ]; then
		break
	fi
	sleep 0.2
done
if ! $listening; then
	abort "the server in the container did not listen on $server_port/udp"
fi
pass "the container's server listens, $(($(now_ms) - run_started)) ms after docker run"

# 3. A client of the same build.
start first --connect=127.0.0.1:"$server_port"
if wait_for first " (mine)" "$connect_timeout"; then
	pass "a client from the source, with the same stamp, gets its fighter"
else
	fail "the client from the source got no fighter"
fi
check_log "$logs/first.log" "client: handshake accepted" "the client passes the handshake"

# 4. A client of another build.
bash tools/stamp_build.sh "$other_commit"
start second --connect=127.0.0.1:"$server_port"
wait_exit second "$connect_timeout"
bash tools/stamp_build.sh "$commit"
if [ "$exit_code" -eq 4 ]; then
	pass "a client with the commit $other_commit is refused with exit 4"
else
	fail "a client with the commit $other_commit exited with $exit_code, not 4"
fi
check_log "$logs/second.log" "NET_UPDATE_REQUIRED" "it shows the request to update the game"

# 5. The stop file. docker wait also reads the exit code of a server that ended before it.
stop_at=$(now_ms)
server_exit="no exit within $stop_timeout s"
if ! docker_cli exec "$container" touch "$container_stop_file"; then
	fail "docker exec could not touch the stop file $container_stop_file"
fi
if waited="$(timeout "$stop_timeout" docker wait "$container")"; then
	server_exit="$(tr -d '\r' <<<"$waited")"
fi
took=$(($(now_ms) - stop_at))
if [ "$server_exit" = 0 ]; then
	pass "the stop file closes the container's server with exit 0, $took ms after docker exec"
else
	fail "the container's server exited with $server_exit, $took ms after the stop file"
fi
wait_exit first "$leave_timeout"
if [ "$exit_code" -eq 0 ]; then
	pass "the first client exits with 0 when the server closes"
else
	fail "the first client exited with $exit_code, not 0"
fi
check_log "$logs/first.log" "NET_SERVER_CLOSED" "it shows that the server closed"

# 6. The logs.
save_server_log
check_server_log "$logs/server.log" "$version" "$commit"
check_log "$logs/server.log" "joined the match as Fighter0" "the server gives the client a fighter"
check_log "$logs/server.log" "handshake refused: update required" \
	"the server refuses the other build"
# The server sent RPCs to its client, so the known engine error of its release build is set
# aside here, and only here (tools/build_lib.sh, known_engine_error; F-097).
check_clean_logs --set-aside-known "$logs/server.log" "$logs/first.log" "$logs/second.log"

report
if [ "$failures" -gt 0 ]; then
	exit 1
fi
