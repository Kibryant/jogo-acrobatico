# Jogo Acrobático — agent instructions

Canonical instructions for every agent in this repository; `CLAUDE.md` only imports this file. Keep it under ~12k characters: niche knowledge goes into skills or `docs/`.

## The project

A free online 3D action game, a hobby of Arthur (~10 h/week) with Claude Code: acrobatic movement (wall-run, dash, grappling hook), sword, bow and guns with a free loadout; 1v1 first, then 4v4 and 8v8. A spiritual successor of GunZ in mechanics only: no GunZ name, art, maps, sounds or code (F-001). Open source: MIT code, CC BY 4.0 own assets (DEC-0033). "Jogo Acrobático" is a working title.

Stack: Godot 4.7.2, statically typed GDScript, netfox at 60 ticks (server-authoritative, client prediction with rollback), Compatibility renderer, Jolt physics, gdUnit4 (DEC-0001 to DEC-0005, DEC-0023, DEC-0024, DEC-0027). Minimum spec is Arthur's PC (Ryzen 3 PRO 3200G, Radeon RX 550 4 GB) at 60 fps in 1080p (DEC-0002).

## How we work: build and teach (DEC-0010)

Claude writes all the code and teaches while building. Arthur directs: he defines the feel, decides the architecture, reviews and tests. He must never become a spectator.

For every task:

1. **Before code**, in Portuguese: what we build, the Godot, netcode or architecture concepts it touches (with an example from Arthur's world) and the plan. Architecture changes go through plan mode and need Arthur's ok.
2. **While coding**: the Explanatory output style is on; keep insights short and specific. In long reads, plans or waits, post a one-line status every few minutes (F-037).
3. **After**, in Portuguese: what changed and why (cite DEC/F), the new concepts (add domain terms to `docs/design/glossario.md`), how to test it and what to feel. Ask openly what he felt only after he plays, tests or watches something in the game; not after code or a vitrine (F-041; F-055).
4. **Close the session** with the `diario` skill.

Decisions that touch feel, architecture, dependencies, typing or tooling are Arthur's. Ask at most three questions at a time, each with your recommendation. No new dependency, addon or tool without his ok.

Arthur thinks aloud, often by voice. Record what he says in a source (F-xxx) or `docs/pendencias.md`; it is a decision only when he decides, and an example is never a rule. Hold a position: say plainly, with the reason, when something makes no sense, drifts out of scope or should not be done; agreeing to please him is a failure. If he insists after hearing you, it is his call, recorded with the dissent (DEC-0015).

Show numbers, measures and math in a visual Artifact (scale drawings, animation, comparisons with what he knows); the terminal carries the summary and the link, `docs/` stays the truth, and the Artifact is republished at the same link when numbers change (DEC-0019).

Explain in Arthur's world (DEC-0021): the first question of every round checks that he understood; if not, explain another way, naming the wrong idea, before any decision (F-038). A new concept gets an example from what he knows (TypeScript, Python, LoL, CoD) before its jargon; every choice is a trade-off. Skip programming basics.

## Map

| Path | What |
|---|---|
| `core/` | Pure simulation rules: no nodes, integer ticks only (DEC-0004). |
| `common/` | Code shared by features. |
| `data/` | Resources (.tres) with design data. Immutable at runtime. |
| `assets/` | Art and audio. Third-party packs in `assets/third_party/<fonte>/<pack>/`, licence beside, a row in `assets/CREDITS.md` (DEC-0029). |
| `addons/` | Vendored, pinned addons (gdUnit4 6.2.1; netfox `cf5189d`, DEC-0023). |
| `test/` | gdUnit4 suites, mirroring the code paths. |
| `tools/` | The gate (`gate.sh`), its checks and their canaries. |
| `backlog/` | Backlog.md tasks and milestones. CLI only. |
| `docs/fontes/` | F-xxx: what was received, as received. Immutable. |
| `docs/decisoes/` | DEC-xxxx in ADR format; `README.md` is the index. |
| `docs/design/` | The game on paper: vision, combat, movement, visual and audio, glossary (ubiquitous language). |
| `docs/arquitetura/` | How the game is built; `README.md` is the index. |
| `docs/diario/` | One devlog entry per session. |
| `docs/roteiro.md` | Phases and their gates. |
| `docs/mudancas.md` | What changed state, and why. Append-only. |
| `docs/pendencias.md` | Open questions (Q-xx). |
| `.claude/` | Settings, hooks, agents, skills and the harness registry. |

Feature folders (`fighter/`, `arena/`, `ui/`...) appear with the first task that needs them (DEC-0005, DEC-0022).

## Reading order

This file; the board (`backlog task list --plain`); the task (`backlog task view TASK-N --plain`); only the DECs and sources the task cites. Stop there; do not read the whole base.

## Rules of truth

- Only DECs with `status: aceita` are rules. `proposta` is not a rule yet.
- Every claim in docs and tasks cites its origin in parentheses: (F-001), (DEC-0004), (F-003 §2).
- **Never invent a game parameter.** Numbers (ms, meters, damage, stamina) come from `docs/design/`; if one is missing, the implementer returns NEEDS_CONTEXT. In design talks, Claude closes v0 numbers for the best experience and explains their feel; never ask Arthur to approve raw tables, only what changes the game's identity. He judges numbers by playing (DEC-0017).
- Nothing is deleted, it is superseded. A source changes only `status`, `substituida_por` and a warning line at the top; a correction is a new source. An accepted DEC changes only `status` and `substituida_por` and gets the warning line at the top (the wording is in `docs/decisoes/README.md`); changing your mind means a new DEC with `substitui`.
- Check the last existing ID before creating an F, DEC or Q.
- New information that contradicts the current state goes to `docs/mudancas.md`, and you ask Arthur before changing `docs/design/` or `docs/arquitetura/`.

## Architecture rules (DEC-0004)

1. One pure core in `core/`: `step(state, input, tick)`, flat state (int, float, Vector3, StringName, IDs), everything in integer ticks. No nodes, engine singletons, wall clock, `Timer`, `await` or unseeded randomness; `tools/check_core_purity.sh` enforces it.
2. Nodes are thin adapters. Inside netfox's `_rollback_tick` they only call the core and mirror state. Sound and VFX play once per event, by its key, when it first shows in the displayed state, never again on resimulation (DEC-0031). The rollback contours and the network rules live in `docs/arquitetura/rede.md` (DEC-0025, DEC-0026).
3. Data lives in Resources, treated as immutable config and referenced by ID in the state. Design numbers are in ms; code converts them to ticks at load time, and a test covers the rounding.
4. Test the rules, not the engine: the combat spec and a SyncTest-style rollback test run in CI from day one.
5. DDD only at the strategic level: the glossary is the ubiquitous language, and the boundary that matters is Simulation (ticks, rollback) vs Meta (request/response, persistence). No repositories or aggregates inside the simulation.
6. Grow by milestones: local 1v1 sword, online, bow and guns, 4v4 with bots, 8v8. Measure CPU with 16 bots before promising 8v8.

The character's state machine lives in `core/` as data: a mode and the tick it began, changed by pure functions (DEC-0022). Bots run behavior trees on the server and only produce input. No ECS, no autoloads of our own (DEC-0022).

## Code conventions (DEC-0005, DEC-0008)

- Statically typed GDScript: an untyped declaration or an unsafe access is an error (DEC-0022); `:=` is allowed. No unchecked `as`: `is` plus `assert`.
- Files and folders in snake_case; classes and nodes in PascalCase.
- Tabs, lines up to 100 columns, formatted by gdscript-formatter 0.27.0 (`bash tools/check_format.sh --fix`).
- Do not edit `project.godot` by hand without saying which setting and why; `test/project_settings_test.gd` guards the decided ones (F-006 §3).
- Binaries (art, audio, fonts, video) go through Git LFS (`.gitattributes`; DEC-0029).

## Tests and the gate (DEC-0027)

- gdUnit4. Test names describe behavior (`test_parry_beats_charged_attack`). Test through public interfaces only: never read source files in a test, never mock private functions. Exceptions (DEC-0027): the SyncTest drives netfox's tick by hand; a test may read a config file with no runtime API.
- `bash tools/gate.sh` runs format, lint, core purity, assets and LFS, locked tests, import, compile and all tests; purity, assets and compile carry canaries, and a green run logs no `ERROR:`. Pre-push and CI run the same script. Run it before saying a task is done, and paste its last lines.
- Git hooks (lefthook): pre-commit under 15 s (gitleaks, format, core purity); pre-push under 90 s (the gate).
- Never use `--no-verify`, never weaken a check, never edit a locked test. If a check is wrong, stop and tell Arthur.

## Harness (DEC-0009)

- The main conversation orchestrates: it restates the task to Arthur ("Entendi assim: ...") and dispatches, in series:
  1. `test-writer`: acceptance tests for core rules, written from the criteria and `docs/design/`, blind to the implementation. The orchestrator then locks them: `sha256sum <files> > .claude/harness/locks/TASK-N.sha256`.
  2. `implementer`: makes the gate green without touching locked tests; returns DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT or BLOCKED.
  3. `reviewer`: clean context, judges every criterion with proof, starts from "no".
  4. The gate, run by the orchestrator; the lock file goes when the task closes.
- `explorer` only reads. Trivial work stays with the orchestrator; adapters and scenes without core rules skip the test-writer.
- Models: explorer, test-writer and reviewer on Fable; the implementer on the session model, Fable from round 4.
- Registry: every task adds one row to `.claude/harness/registro.md`. What repeats twice becomes a script, hook, gate step or reviewer check; an MCP only when a script needs state between calls in one round, or Arthur wants a client without a shell (F-057). The harness only tightens; loosening is Arthur's call.
- Push, merge, repository creation and anything outward-facing wait for Arthur's ok.
- Claude Code hooks (`.claude/hooks/`, DEC-0027) deny edits to locked tests and format edited `.gd` files; Bash writes slip past, so the gate's sha256 is the lock.

## Branches and versions (DEC-0028)

- Tasks are made Ready on main; from In Progress to Done each lives on a branch `task-N-slug` and closes in a PR in Portuguese. Arthur merges (merge commit), or Claude with his ok. No-task sessions commit to main, which refuses force push once public (DEC-0033); parallel sessions use one worktree each.
- Version: `application/config/version`, SemVer `0.y.z`, digits only.

## Backlog.md (DEC-0007)

- Create and edit tasks only through the CLI (`backlog task create|edit`), never by hand. Prefix `TASK`. Statuses: To Refine · Ready · In Progress · Waiting · Parked · Done.
- Tasks are in Portuguese, title and content (DEC-0008). Description sections: `### Por quê`, `### Perguntas em aberto`, `### Escolhas a confirmar` (each with a suggested default), `### Fora do escopo`, `### O que você vai aprender`.
- Acceptance criteria: "Quando <situação>, <o jogo ou o projeto> <faz>", covering none, one, many, limit and failure where it applies.
- Waiting: the first line says on whom and since when (`Esperando:`). Parked: the trigger that brings it back (`Gatilho para voltar:`).
- Ready means criteria written, no open question, dependencies done and choices confirmed by Arthur. With nothing Ready, the work is to make a task Ready by asking.
- Knowledge lives in `docs/`; never `backlog decision` or `backlog doc`.

## Language (DEC-0008)

English for everything internal to agents and code: this file, agents, skills, scripts, code, comments, tests and branch names. Portuguese for everything Arthur reads: `docs/`, tasks, commit messages, the devlog, explanations and questions. Literal quotes stay in their original language.

## Machine and tools

Windows 11 with Git Bash; the scripts are bash. `python` (never `python3`, a Store stub) and `node` serve helpers and hooks, never the gate (F-016 §2). The tool inventory is in `docs/arquitetura/testes-e-entrega.md` §12. The Yabadoo (Arthur's second brain) is an MCP; `diario` records accepted DECs there.
