#!/usr/bin/env bash
# Claude Code PostToolUse hook for Edit, Write and MultiEdit (DEC-0005; TASK-6): formats a .gd file
# of ours right after it is saved, with the gate's formatter. Third-party addons and the gate's
# canaries keep their text. It reads the hook's JSON from stdin with python (never python3, the
# Microsoft Store stub on Arthur's PC). A formatter failure goes back to Claude: exit 2 shows
# stderr to it. Any other problem stays silent, so a hook bug never blocks normal work.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && { pwd -W 2>/dev/null || pwd; })" || exit 0
input="$(cat)"
shopt -s nocasematch
if [[ "$input" != *'.gd"'* ]]; then
	exit 0 # no .gd path in the input, so no Python to start
fi

# Prints the file's path relative to the repository when it is one of our .gd files.
# MSYS2_ARG_CONV_EXCL keeps Git Bash from rewriting the Python program as if it held paths.
relative="$(MSYS2_ARG_CONV_EXCL='*' HOOK_ROOT="$root" python -c '
import json
import os
import re
import sys


def main():
    root = os.path.normpath(os.environ["HOOK_ROOT"])
    data = json.loads(sys.stdin.buffer.read().decode("utf-8", "replace"))
    target = (data.get("tool_input") or {}).get("file_path")
    if not isinstance(target, str) or not target:
        return
    target = re.sub(r"^/([A-Za-z])(/|$)", r"\1:/", target)  # Git Bash /c/... is C:/...
    if not os.path.isabs(target):
        target = os.path.join(data.get("cwd") or root, target)
    target = os.path.normpath(target)
    if not os.path.normcase(target).startswith(os.path.normcase(root) + os.sep):
        return
    relative = target[len(root) + 1 :].replace(os.sep, "/")
    folded = os.path.normcase(relative.replace("/", os.sep)).replace(os.sep, "/")
    if folded.endswith(".gd") and not folded.startswith(("addons/", "tools/canaries/")):
        print(relative)


try:
    main()
except Exception:
    pass
' 2>/dev/null <<<"$input")" || exit 0
if [ -z "$relative" ]; then
	exit 0
fi

cd "$root" || exit 0
if ! message="$(gdscript-formatter "$relative" 2>&1)"; then
	echo "gdscript-formatter could not format $relative (DEC-0005): $message" >&2
	exit 2
fi
exit 0
