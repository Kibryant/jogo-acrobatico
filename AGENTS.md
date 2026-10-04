# Jogo Acrobático — agent instructions

Canonical instructions for every agent in this repository; `CLAUDE.md` only imports this file. Keep it under ~12k characters: niche knowledge goes into skills or `docs/`.

## The project

A free, online 3D action game, built as a hobby by Arthur (~10 h/week) with Claude Code. Acrobatic movement is the identity (wall-run, dash, grappling hook); sword, bow and firearms with a free loadout; 1v1 duels first, then 4v4 and 8v8. A spiritual successor of GunZ in mechanics only: no GunZ name, art, maps, sounds or code (F-001). "Jogo Acrobático" is a working title.

Stack: Godot 4.7.2, statically typed GDScript, netfox at 60 ticks (server-authoritative, client prediction with rollback), Compatibility renderer, Jolt physics, gdUnit4 (DEC-0001 to DEC-0006, DEC-0023, DEC-0024). Minimum spec is Arthur's PC (Ryzen 3 PRO 3200G, Radeon RX 550 4 GB) at 60 fps in 1080p (DEC-0002).

## How we work: build and teach (DEC-0010)

Claude writes all the code and teaches while building. Arthur directs: he defines the feel, decides the architecture, reviews and tests. He must never become a spectator.

For every task:

1. **Before code**, in Portuguese: what we will build, which Godot, netcode or architecture concepts it touches (one or two sentences each, with an example from Arthur's world, DEC-0021) and the plan. Architecture changes go through plan mode and need Arthur's ok.
2. **While coding**: the Explanatory output style is on; keep insights short and specific. In long reads, plans or waits, post a one-line status every few minutes (F-037).
3. **After**, in Portuguese: what changed and why (cite DEC/F), the new concepts (add domain terms to `docs/design/glossario.md`), how to test it and what to feel.
4. **Close the session** with the `diario` skill.

Decisions that touch feel, architecture, dependencies, typing or tooling are Arthur's. Ask at most three questions at a time, each with your recommendation. Never add a dependency, addon or tool without his ok.

Arthur thinks aloud, often by transcribed voice. Record what he says in a source (F-xxx) or in `docs/pendencias.md`; it becomes a decision only when he decides, and an example is never a rule. Hold a position: say plainly when something makes no sense, drifts out of scope or should not be done, and why. Agreeing to please him is a failure. On his topics you argue and may push back; if he insists after hearing you, it is his call, recorded with the dissent (DEC-0015).

Show numbers, measures, physics and math to Arthur in a visual Artifact, as illustrative as possible: scale drawings, real-time animation, comparisons with things he knows. The terminal carries the summary and the link; `docs/` stays the source of truth, and the Artifact is republished at the same link when its numbers change (DEC-0019).

Explain in Arthur's world (DEC-0021). The first question of every round checks that he understood the problem and what we are doing; if not, explain another way before any decision. A new concept gets an example from what he knows (TypeScript, Python, LoL, Call of Duty) before its jargon, and every choice is a trade-off: what he gains and what he loses. Skip programming basics; raise the level if he says it is too basic.

## Map

| Path | What |
|---|---|
| `core/` | Pure simulation rules: no nodes, integer ticks only (DEC-0004). |
| `common/` | Code shared by features. |
| `data/` | Resources (.tres) with design data. Immutable at runtime. |
| `assets/` | Art and audio. Every third-party asset is listed in `assets/CREDITS.md`. |
| `addons/` | Third-party Godot addons, vendored and pinned (gdUnit4 6.2.1; netfox main `cf5189d`, DEC-0023). |
| `test/` | gdUnit4 suites, mirroring the code paths. |
| `tools/` | Bash scripts: `gate.sh` and its checks. |
| `backlog/` | Backlog.md tasks and milestones. CLI only. |
| `docs/fontes/` | F-xxx: what was received, as received. Immutable. |
| `docs/decisoes/` | DEC-xxxx in ADR format; `README.md` is the index. |
| `docs/design/` | The game on paper: vision, combat, movement and the glossary (ubiquitous language). |
| `docs/arquitetura/` | How the game is built; `README.md` is the index. |
| `docs/diario/` | One devlog entry per session, for Arthur. |
| `docs/roteiro.md` | Phases and their gates. |
| `docs/mudancas.md` | What changed state, and why. Append-only. |
| `docs/pendencias.md` | Open questions (Q-xx). |
| `.claude/` | Settings, agents, skills and the harness registry. |

Feature folders (`fighter/`, `arena/`, `match/`, `net/`, `ui/`...) are created by the first task that needs them (DEC-0005, DEC-0022).

## Reading order

1. This file.
2. The board: `backlog task list --plain`.
3. The task: `backlog task view TASK-N --plain`.
4. Only the DECs and sources the task cites. Stop there; do not read the whole base.

## Rules of truth

- Only DECs with `status: aceita` are rules. `proposta` is not a rule yet.
- Every claim in docs and tasks cites its origin in parentheses: (F-001), (DEC-0004), (F-003 §2).
- **Never invent a game parameter.** Numbers (ms, meters, damage, stamina) come from `docs/design/`. If one is missing, the implementer returns NEEDS_CONTEXT. In design conversations, Claude closes v0 numbers for the player's best experience and explains the feel they create, comparing with games Arthur knows; never ask him to approve raw tables. Ask him only what changes the game's identity; he judges numbers by playing (DEC-0017).
- Nothing is deleted, it is superseded. A source changes only `status`, `substituida_por` and a warning line at the top; a correction is a new source. An accepted DEC changes only `status` and `substituida_por` and gets the warning "⚠️ Substituída por DEC-XXXX em AAAA-MM-DD — não é a regra atual"; changing your mind means a new DEC with `substitui`.
- Check the last existing ID before creating an F, DEC or Q.
- New information that contradicts the current state goes to `docs/mudancas.md`, and you ask Arthur before changing `docs/design/` or `docs/arquitetura/`.

## Architecture rules (DEC-0004)

1. One pure core in `core/`: `step(state, input, tick)`, flat state (int, float, Vector3, StringName, IDs), everything in integer ticks. No nodes, engine singletons, wall clock, `Timer`, `await` or unseeded randomness; `tools/check_core_purity.sh` enforces it.
2. Nodes are thin adapters. Inside netfox's `_rollback_tick` they only call the core and mirror state. Sound and VFX play only on fresh ticks (`is_fresh`), never on resimulation. The rollback contours and the network rules live in `docs/arquitetura/rede.md` (DEC-0025, DEC-0026).
3. Data lives in Resources, treated as immutable config and referenced by ID in the state. Design numbers are in ms; code converts them to ticks at load time, and a test covers the rounding.
4. Test the rules, not the engine: the combat spec and a SyncTest-style rollback test run in CI from day one.
5. DDD only at the strategic level: the glossary is the ubiquitous language, and the boundary that matters is Simulation (ticks, rollback) vs Meta (request/response, persistence). No repositories or aggregates inside the simulation.
6. Grow by milestones: local 1v1 sword, online, bow and guns, 4v4 with bots, 8v8. Measure CPU with 16 bots before promising 8v8.

The character's state machine lives in `core/` as data: a mode and the tick it began, changed by pure functions (DEC-0022). Bots run behavior trees on the server and only produce input. No ECS, and no autoloads of our own (DEC-0022).

## Code conventions (DEC-0005, DEC-0008)

- Statically typed GDScript: an untyped declaration or an unsafe access is an error (DEC-0022); `:=` is allowed. No unchecked `as`: use `is` plus `assert`.
- English identifiers, comments, tests, scripts and branch names. Files and folders in snake_case; classes and nodes in PascalCase.
- Tabs, lines up to 100 columns, formatted by gdscript-formatter 0.27.0 (`bash tools/check_format.sh --fix`).
- Do not edit `project.godot` by hand without saying which setting and why; `test/project_settings_test.gd` guards the decided ones. Jolt must stay explicit there: the engine default is still Godot Physics (F-006 §3).
- Binaries (art, audio, fonts, video) go through Git LFS (`.gitattributes`).

## Tests and the gate (DEC-0006)

- gdUnit4. Test names describe behavior (`test_parry_beats_charged_attack`). Test through public interfaces only: never read source files in a test, never mock private functions.
- `bash tools/gate.sh` runs format, lint, core purity, locked tests, import, compile and all tests. Pre-push and CI run the same script. Run it before saying a task is done, and paste its last lines.
- Git hooks (lefthook): pre-commit under 15 s (gitleaks, format, core purity); pre-push under 90 s (the gate).
- Never use `--no-verify`, never weaken a check, never edit a locked test. If a check is wrong, stop and tell Arthur.

## Harness (DEC-0009)

- The main conversation orchestrates. It restates the task to Arthur ("Entendi assim: ...") and then dispatches, in series:
  1. `test-writer`: acceptance tests for core rules, written from the criteria and `docs/design/`, blind to the implementation. The orchestrator then locks them: `sha256sum <files> > .claude/harness/locks/TASK-N.sha256`.
  2. `implementer`: makes the gate green without touching locked tests; returns DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT or BLOCKED.
  3. `reviewer`: clean context, judges every criterion with proof, starts from "no".
  4. The gate, run by the orchestrator. The lock file is removed when the task closes.
- `explorer` only reads. Trivial work stays with the orchestrator; adapters and scenes without core rules skip the test-writer.
- Models: explorer, test-writer and reviewer on Fable; implementer on the session model, switching to Fable from the 4th round.
- Registry: every task adds one row to `.claude/harness/registro.md`. Something that repeats twice is proposed as a script, hook, gate step or reviewer check. The harness only tightens; loosening anything is Arthur's call.
- Push, merge, repository creation and anything outward-facing stop for Arthur's permission.

## Backlog.md (DEC-0007)

- Create and edit tasks only through the CLI (`backlog task create`, `backlog task edit`), never by hand. Prefix `TASK`. Statuses: To Refine · Ready · In Progress · Waiting · Parked · Done.
- Tasks are in Portuguese, title and content (DEC-0008). Description sections: `### Por quê`, `### Perguntas em aberto`, `### Escolhas a confirmar` (each with a suggested default), `### Fora do escopo`, `### O que você vai aprender`.
- Acceptance criteria: "Quando <situação>, <o jogo ou o projeto> <faz>", covering none, one, many, limit and failure where it applies.
- Waiting: the first line says on whom and since when (`Esperando:`). Parked: the trigger that brings it back (`Gatilho para voltar:`).
- Ready means criteria written, no open question, dependencies done and choices confirmed by Arthur. With nothing Ready, the work is to make a task Ready by asking.
- Knowledge lives in `docs/`; do not use `backlog decision` or `backlog doc`.

## Language (DEC-0008)

English for everything internal to agents and code: this file, agents, skills, scripts, code, comments, tests and branch names. Portuguese for everything Arthur reads: `docs/`, tasks, commit messages, the devlog, explanations and questions. Literal quotes stay in their original language.

## Machine and tools

Windows 11 with Git Bash; the scripts are bash. On PATH (`~/.local/bin`): `godot` (4.7.2 console), `backlog`, `gdscript-formatter`, `lefthook`, `gitleaks` and `gh`; `git-lfs` comes with Git. clumsy 0.3 (`~/.local/opt/clumsy-0.3`, WinDivert, run as admin) simulates lag for 4+ clients (F-023 §2). `node` 24 (portable, in `~/.local/opt`) and `python` 3.14 (per user) are on the user PATH for helper scripts; the gate uses neither (F-016 §2). The Yabadoo, Arthur's second brain, is an MCP: when a DEC is accepted, the `diario` skill also records a one-line decision there, citing the DEC id.
