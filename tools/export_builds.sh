#!/usr/bin/env bash
# Exports the builds of export_presets.cfg with the release templates (DEC-0028 §1): the Windows
# client and the Linux dedicated server, into build/. The CI runs it right after
# tools/stamp_build.sh; here it needs the 4.7.2 templates for Windows and Linux (F-045 §1):
#   bash tools/export_builds.sh [client] [server]     (both when none is given)
# The project is imported first: with gdUnit4 installed, the first export made without the .godot
# folder crashes (gdUnit4 #1324; F-047 §1.6). Godot 4.7.2 may also crash on exit after an export
# that worked (#123712; F-047 §1.6), so its exit code is only logged, with a warning when it is not
# 0: each build is judged by its file, which must be new and whole (check_build), and the server
# then by the smoke test, tools/smoke_test_server.sh (DEC-0028, Consequences).
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/lib.sh
source tools/build_lib.sh
refuse_override_cfg
godot_bin="$(resolve_godot)"

declare -A presets=([client]="Cliente Windows" [server]="Servidor Linux")
declare -A files=([client]="$client_build" [server]="$server_build")
targets=("$@")
if [ "${#targets[@]}" -eq 0 ]; then
	targets=(client server)
fi
for target in "${targets[@]}"; do
	if [ -z "${presets[$target]:-}" ]; then
		echo "usage: bash tools/export_builds.sh [client] [server], both when none is given" >&2
		exit 2
	fi
done

echo "export: Godot $("$godot_bin" --version | tr -d '\r'), version $(project_version)," \
	"commit \"$(project_commit)\""

echo "import"
if ! import_log="$("$godot_bin" --headless --path . --import 2>&1)"; then
	echo "$import_log"
	echo "import failed" >&2
	exit 1
fi
if grep -E "SCRIPT ERROR|Parse Error|ERROR:" <<<"$import_log"; then
	echo "import reported errors" >&2
	exit 1
fi

# Godot's output of each export, which shows in GitHub Actions, folded, and here only when the
# export went wrong. It is not scanned for errors: the editor logs one at every exit, a resource
# still in use (TASK-9, round D2).
logs="$(mktemp -d)"
trap 'rm -rf "$logs"' EXIT
failed=0
for target in "${targets[@]}"; do
	preset="${presets[$target]}"
	file="${files[$target]}"
	log="$logs/$target.log"
	# A file left by an earlier export would pass for this one.
	rm -f "$file"
	# Godot exports only into a folder that exists (F-047 §1.6).
	mkdir -p "$(dirname "$file")"
	echo "export \"$preset\" to $file"
	status=0
	started=$SECONDS
	"$godot_bin" --headless --path . --export-release "$preset" "$file" >"$log" 2>&1 || status=$?
	whole=true
	reason="$(check_build "$file" 2>&1)" || whole=false
	if [ "${GITHUB_ACTIONS:-}" = true ] || [ "$status" -ne 0 ] || ! $whole; then
		show_log "$log" "Godot's output, exporting \"$preset\""
	fi
	echo "$target: Godot exited with $status after $((SECONDS - started)) s"
	if [ "$status" -ne 0 ]; then
		warn "Godot exited with $status after exporting \"$preset\": the build file decides, and \
for the server the smoke test, not the exit code (#123712; DEC-0028)"
	fi
	if $whole; then
		echo "$target: $file is whole, $(wc -c <"$file" | tr -d '[:space:]') bytes"
	else
		echo "$target: $reason" >&2
		failed=1
	fi
done
if [ "$failed" -ne 0 ]; then
	echo "export failed" >&2
	exit 1
fi
