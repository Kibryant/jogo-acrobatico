# Harness

How the agent workflow of this repository evolves (DEC-0009). It follows the SkinHub and YabaBuss pattern: the same agent names, skill names and registry format.

- `registro.md`: one row per task or session: date, task, what happened, what repeated.
- `locks/`: `sha256sum` lists of acceptance tests locked during an open task. The orchestrator writes them after the test-writer, `tools/check_test_locks.sh` checks them inside the gate, and they are removed when the task closes.
- `../hooks/`: the Claude Code hooks, declared in `../settings.json` (DEC-0027). `guard_locked_tests.sh` (PreToolUse) denies an Edit, Write, MultiEdit or NotebookEdit on a file listed in `locks/`, for subagents too; `format_gd.sh` (PostToolUse) formats our `.gd` files after each edit. Both read the hook JSON with `python` (never `python3`, a Store stub on Arthur's PC) and let the tool run if they break. Writes through Bash are not guarded: the gate's sha256 check is the real lock. Proven in two real sessions (F-040).
- Promotion: when the same problem shows up twice, propose turning it into a script, a hook, a gate step or a reviewer check.
- The harness only tightens. Loosening anything, from a check to a lock, is Arthur's call.
- Monthly review: on the first Monday of the month, inside the /revisao mensal ritual, Arthur decides what to add, adjust or remove.
