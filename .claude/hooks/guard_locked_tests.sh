#!/usr/bin/env bash
# Claude Code PreToolUse hook for Edit, Write, MultiEdit and NotebookEdit (DEC-0009; TASK-6): denies
# the edit when its file is listed in .claude/harness/locks/*.sha256, the acceptance tests locked
# while their task is open. It reads the hook's JSON from stdin with python (never python3, the
# Microsoft Store stub on Arthur's PC). Any problem lets the tool run: a hook bug must never block
# normal work, and the gate's sha256 check stays the real lock. Writes through Bash are not guarded.
cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 0
shopt -s nullglob
locks=(.claude/harness/locks/*.sha256)
if [ "${#locks[@]}" -eq 0 ]; then
	# No locked test, so nothing to guard and no Python to start. The input is still read, so
	# Claude Code never writes into a closed pipe.
	cat >/dev/null
	exit 0
fi
root="$(pwd -W 2>/dev/null || pwd)"

# MSYS2_ARG_CONV_EXCL keeps Git Bash from rewriting the Python program as if it held paths.
MSYS2_ARG_CONV_EXCL='*' HOOK_ROOT="$root" python -c '
import glob
import json
import os
import re
import sys


def normalized(path, base):
    """The path, absolute, with one separator and, on Windows, one case."""
    path = re.sub(r"^/([A-Za-z])(/|$)", r"\1:/", path)  # Git Bash /c/... is C:/...
    if not os.path.isabs(path):
        path = os.path.join(base, path)
    return os.path.normcase(os.path.normpath(path))


def main():
    root = os.environ["HOOK_ROOT"]
    data = json.loads(sys.stdin.buffer.read().decode("utf-8", "replace"))
    tool_input = data.get("tool_input") or {}
    target = tool_input.get("file_path") or tool_input.get("notebook_path")
    if not isinstance(target, str) or not target:
        return
    target = normalized(target, data.get("cwd") or root)
    for lock in sorted(glob.glob(os.path.join(root, ".claude", "harness", "locks", "*.sha256"))):
        with open(lock, encoding="utf-8", errors="replace") as lines:
            for line in lines:
                # sha256sum writes "<hash> *<path>" (binary mode) or "<hash>  <path>".
                match = re.match(r"^\\?[0-9a-fA-F]{64} [ *](.+)$", line.rstrip("\r\n"))
                if not match or normalized(match.group(1), root) != target:
                    continue
                locked = match.group(1)
                lock_name = os.path.relpath(lock, root).replace(os.sep, "/")
                reason = (
                    f"{locked} is a locked acceptance test ({lock_name}). Do not change it: "
                    "stop and report BLOCKED; only Arthur unlocks it (DEC-0009)."
                )
                decision = {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": reason,
                }
                print(json.dumps({"hookSpecificOutput": decision}))
                return


try:
    main()
except Exception:
    pass
' 2>/dev/null
exit 0
