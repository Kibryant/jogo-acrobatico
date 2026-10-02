# Harness registry

| Date | Task | What happened | What repeated |
|---|---|---|---|
| 2026-10-02 | TASK-1 | Repository base created from a my-brain session: git, AGENTS.md, Backlog.md, gdUnit4, gate scripts, lefthook, CI, docs. Gate proved locally; CI not run yet (no remote). | — |
| 2026-10-02 | TASK-1 | Closed in session 2; first commit `0a37990`. A probe in `core/` passed pre-commit: lefthook's default glob dialect made `core/**/*.gd` skip files at the `core/` root. Fixed with `glob_matcher: doublestar`; the same probe was then blocked. The purity regex hole (`#` inside a string hides the rest of the line) went to TASK-6. | Two holes in the checks in one session, both on paths never run end to end: session 1 ran the scripts directly, without a commit. Promotion candidate for TASK-6: a self-test that pushes probes through the real hook and gate paths. |
