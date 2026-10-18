#!/usr/bin/env bash
# Shared pieces of the delivery scripts (TASK-9, part 3): where the two builds go, the stamp that
# project.godot carries, the check that a build file is whole, and the checks of a server run that
# the smoke test and the server image check share. Source it after tools/lib.sh, from the project
# root; the server checks also need tools/net_lib.sh.

# The builds, at the export paths of export_presets.cfg (test/export_presets_test.gd; DEC-0028 §1).
client_build=build/windows/jogo-acrobatico.exe
server_build=build/linux/jogo-acrobatico-servidor.x86_64
# The server's default port (LaunchOptions.DEFAULT_PORT; TASK-9, choice 9).
server_port=7777
# bytes: a build is its export template with the game's pack appended. The 4.7.2 release templates
# have 73.5 MB for Linux and 109 MB for Windows (F-045 §1), so a smaller file was cut short.
build_floor_bytes=50000000

# application_setting KEY: the value of KEY in the [application] section of project.godot, without
# its quotes; empty when the key is not there.
application_setting() {
	awk -v key="$1" '
		/^\[/ { in_application = ($0 ~ /^\[application\][ \t\r]*$/) }
		in_application && index($0, key "=") == 1 {
			value = substr($0, length(key) + 2)
			sub(/[ \t\r]+$/, "", value)
			gsub(/^"|"$/, "", value)
			print value
			exit
		}
	' project.godot
}

# The project's version, application/config/version (DEC-0028 §3).
project_version() {
	application_setting config/version
}

# The commit stamped in project.godot, application/config/commit; empty without a stamp, as in the
# editor and in the gate (DEC-0028 §3).
project_commit() {
	application_setting config/commit
}

# check_build FILE: true when FILE is a whole build with the game's pack inside
# (binary_format/embed_pck): at least build_floor_bytes, ending with the pack's footer, the "GDPC"
# magic that Godot writes last. An export cut short leaves no footer. Says what is wrong on stderr.
check_build() {
	local file=$1 size footer
	if [ ! -f "$file" ]; then
		echo "$file is missing" >&2
		return 1
	fi
	size="$(wc -c <"$file" | tr -d '[:space:]')"
	if [ "$size" -lt "$build_floor_bytes" ]; then
		echo "$file has $size bytes, fewer than the $build_floor_bytes of a whole build" >&2
		return 1
	fi
	# "GDPC" in hex, read as bytes: the template alone ends with zeros.
	footer="$(tail -c 4 "$file" | od -An -tx1 | tr -d '[:space:]')"
	if [ "$footer" != 47445043 ]; then
		echo "$file does not end with the pack's footer (GDPC): its export did not finish" >&2
		return 1
	fi
}

# warn TEXT: a warning, which GitHub Actions also shows on the run's summary.
warn() {
	if [ "${GITHUB_ACTIONS:-}" = true ]; then
		echo "::warning::$1"
	else
		echo "warning: $1" >&2
	fi
}

# show_log FILE [TITLE]: prints a log under TITLE, its file name by default, folded in GitHub
# Actions.
show_log() {
	local title="${2:-$(basename "$1")}"
	if [ "${GITHUB_ACTIONS:-}" = true ]; then
		echo "::group::$title"
		cat "$1"
		echo "::endgroup::"
	else
		echo "---- $title"
		cat "$1"
	fi
}

# The report of a run with checks, as in tools/net_check.sh: pass and fail add a line to the
# summary, and failures counts the failed ones.
failures=0
summary=()

pass() {
	summary+=("ok    $1")
}

fail() {
	summary+=("FAIL  $1")
	failures=$((failures + 1))
}

# check_log LOG TEXT WHAT: passes WHAT when the file LOG holds TEXT.
check_log() {
	if grep -qF -- "$2" "$1"; then
		pass "$3"
	else
		fail "$3: no \"$2\" in $(basename "$1")"
	fi
}

# start_build NAME BUILD ARGS...: an exported build, headless, with the game's arguments ARGS,
# logged to NAME.log and kept in pids, like the start of tools/net_lib.sh.
start_build() {
	local name=$1 build=$2
	shift 2
	"$build" --headless -- "$@" >"$logs/$name.log" 2>&1 &
	pids[$name]=$!
}

# check_server_log LOG VERSION COMMIT: the lines of a server that ran until its stop file appeared
# (rede.md §9): the build it runs, with VERSION and the stamped COMMIT; the port it listened on;
# the stop file it saw; and its clean exit.
check_server_log() {
	local log=$1 version=$2 commit=$3
	check_log "$log" "server: version $version, commit \"$commit\"" \
		"the server runs version $version with the commit \"$commit\""
	check_log "$log" "server: listening on port $server_port/udp" \
		"it listens on port $server_port/udp"
	check_log "$log" "server: stop file seen" "it sees the stop file"
	check_log "$log" "server: exiting with 0" "it says it exits with 0"
}

# check_clean_logs LOG...: fails when the logs hold an engine error (log_errors of
# tools/net_lib.sh) and notes their warnings.
check_clean_logs() {
	local errors warnings
	errors="$(log_errors "$@")"
	warnings="$(log_warnings "$@")"
	if [ -n "$errors" ]; then
		fail "the logs hold errors:"
		summary+=("$errors")
	else
		pass "no error in the logs"
	fi
	if [ -n "$warnings" ]; then
		summary+=("note  warnings in the logs:" "$warnings")
	fi
}
