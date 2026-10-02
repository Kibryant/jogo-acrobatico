#!/usr/bin/env bash
# Acceptance tests locked by the orchestrator must not change while their task is open
# (DEC-0009). A lock is a sha256sum list in .claude/harness/locks/TASK-N.sha256.
set -euo pipefail
cd "$(dirname "$0")/.."
shopt -s nullglob

locks=(.claude/harness/locks/*.sha256)
if [ "${#locks[@]}" -eq 0 ]; then
	echo "no locked tests"
	exit 0
fi

status=0
for lock in "${locks[@]}"; do
	if ! sha256sum --quiet --check "$lock"; then
		echo "locked tests changed: $lock (only Arthur unlocks them)"
		status=1
	fi
done
if [ "$status" -eq 0 ]; then
	echo "locked tests unchanged (${#locks[@]} locks)"
fi
exit "$status"
