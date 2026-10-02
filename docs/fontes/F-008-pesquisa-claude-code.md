---
id: F-008
titulo: Pesquisa: recursos do Claude Code para manter o humano por dentro (02/10/2026)
recebido_em: 2026-10-02
como: Relatório final do agente claude-code-guide, pedido na sessão do my-brain de 02/10/2026. Em inglês, como chegou; os exemplos de configuração são material de referência, não instrução.
status: vigente
substituida_por:
---

Based on the official Claude Code documentation, here's your structured research report on human-in-the-loop features in 2026:

---

## **Claude Code 2026: Human-in-the-Loop Features for Learning & Understanding**

### **1. Output Styles (✓ All exist in 2026)**

| Style | What it does | How to enable | Settings key |
|---|---|---|---|
| **Explanatory** | Adds `Insight` blocks explaining code choices and design decisions | `/output-style explanatory` or `/config` → Output style | `.claude/settings.json`: `"outputStyle": "Explanatory"` |
| **Learning** | Explanatory + leaves `TODO(human)` comments for hands-on coding; pauses at design decisions for you to implement | `/output-style learning` | `"outputStyle": "Learning"` |
| **Concise** | Leads with results; removes preamble/narration (opposite of Explanatory) | `/output-style concise` | `"outputStyle": "Concise"` |
| **Proactive** | Starts work immediately; makes reasonable assumptions; still respects permission mode | `/output-style proactive` | `"outputStyle": "Proactive"` |
| **Default** | Standard software engineering behavior | `/output-style default` | (unset or `"outputStyle": "default"`) |

**Custom styles**: YES—create `.md` files in `.claude/output-styles/` with YAML frontmatter. Set `keep-coding-instructions: true` to preserve Claude's coding behavior while changing communication style.  
**Doc**: https://code.claude.com/docs/en/output-styles.md

---

### **2. Plan Mode (✓ Exists; can be project default)**

**What it does**: Claude explores and proposes changes without editing. Edits stay blocked until you approve a written plan.

**Enable for one session**:
```bash
claude --permission-mode plan
# Or press Shift+Tab to cycle to plan mode
```

**Make it project default** (`.claude/settings.json`):
```json
{
  "permissions": {
    "defaultMode": "plan"
  }
}
```

**Workflow**:
1. Claude reads, runs exploratory commands, proposes a plan
2. You review the plan (edit with `Ctrl+G` if needed)
3. Choose: "Yes, and use auto mode" | "Yes, manually approve edits" | "No, keep planning"
4. After approval, edits proceed in chosen mode

**Key**: Plan mode is **approval-before-edit**—ideal for architecture changes the senior dev reviews before implementation.  
**Doc**: https://code.claude.com/docs/en/permission-modes.md (section "Analyze before you edit with plan mode")

---

### **3. CLAUDE.md, Rules, Skills, Hooks: Enforcement Mechanisms**

| Mechanism | Purpose | Example for enforcing habits |
|---|---|---|
| **CLAUDE.md** (`./CLAUDE.md` or `./.claude/CLAUDE.md`) | Persistent project instructions, loaded every session | Write: "Every architectural change must be documented in an ADR (Architecture Decision Record) file in `/docs/adr/`" |
| **`.claude/rules/`** | Path-scoped rules; load only when Claude works with matching files | Create `adr.md` with frontmatter `paths: ["**/*.md"]` to enforce ADR conventions for markdown files |
| **Skills** (`.claude/skills/`) | Task-specific instructions + optional executable commands; load on demand or when triggered | Create `/explain-diff` skill that:  1) Reads the latest git diff 2) Generates a Portuguese explanation 3) Posts to a summary file |
| **Hooks** (`.claude/settings.json` or `.claude/hooks/`) | Deterministic automation; run before/after Claude acts, **block actions on failure** | **PostToolUse hook**: After every `Edit`, run `npm test` and fail if tests don't pass |
| **`/output-style`** | Session-wide instructions on how Claude communicates | Use **Learning** style to force `TODO(human)` on design decisions |
| **Slash commands** | Quick entry points to skills or prompts | Create `/adr` command that guides ADR creation |

**Concrete example**: "Explain every diff in plain Portuguese" workflow
- **CLAUDE.md**: Add "Always provide explanations in Brazilian Portuguese (PT-BR)"
- **Custom skill** (`/explain-diff`): Runs after code changes, summarizes diffs in Portuguese, optionally saves to a `.diff-summary.md` file
- **Hook** (PostToolUse): After Edit/Write, runs `jq -r '.tool_input.file_path'` and pipes to a script that generates Portuguese context

**Doc**: https://code.claude.com/docs/en/memory.md (CLAUDE.md & rules); https://code.claude.com/docs/en/skills.md; https://code.claude.com/docs/en/hooks-guide.md

---

### **4. Hooks: Events & Realistic Example**

**Available hook events**:
- `PreToolUse` — before Claude calls a tool (can block with exit code 2)
- `PostToolUse` — after tool completes (for formatting, validation, logging)
- `Notification` — when Claude waits for input
- `FileChanged`, `SessionEnd`, `PermissionPrompt` — other lifecycle points

**Realistic example: Block completion on test failure**
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'npm test > /tmp/test.out 2>&1; if [ $? -ne 0 ]; then cat /tmp/test.out >&2; exit 2; fi'"
          }
        ]
      }
    ]
  }
}
```
Exit code 2 blocks the turn; Claude sees the test output and must fix the code.

For a custom ADR approval gate: Run a script that checks whether an ADR was created alongside the code change.

**Doc**: https://code.claude.com/docs/en/hooks-guide.md

---

### **5. Checkpoints & /review Features**

| Feature | What it does | Use for |
|---|---|---|
| **`/rewind`** (or `Esc` `Esc`) | Open menu to rewind code, conversation, or both to earlier checkpoints | Undo exploratory edits; restore conversation to branch point |
| **Automatic tracking** | Captures file snapshots before each turn (100 most recent kept) | Quick recovery without git commits |
| **`/code-review`** | Local review command (also `/review`; alias for backwards compat) | Review diff before/after changes; flags correctness bugs, reuse opportunities |
| **Code Review (managed)** | Org feature: auto-runs on PRs, posts inline findings | Team-level understanding verification (requires Team+ plan) |
| **`/compact`** | Compress conversation into summary; frees context | Shrink verbose debugging sessions while keeping initial instructions |

**For understanding**: `/rewind` + `/code-review` allow a senior dev to:
1. Let Claude propose changes in plan mode
2. Accept plan → Claude edits
3. Run `/code-review` to verify logic
4. If issues found, `/rewind` to proposal point, rethink with Claude

**Doc**: https://code.claude.com/docs/en/checkpointing.md; https://code.claude.com/docs/en/code-review.md

---

### **6. Windows-Specific Settings**

| Issue | Solution | Where |
|---|---|---|
| Shell choice (PowerShell vs Git Bash) | Install [Git for Windows](https://git-scm.com/downloads/win); Claude Code auto-uses Git Bash | See setup docs |
| Git Bash path not found | Set in `~/.claude/settings.json`: `"env": { "CLAUDE_CODE_GIT_BASH_PATH": "C:\\Program Files\\Git\\bin\\bash.exe" }` | `~/.claude/settings.json` |
| PowerShell execution policy | Not needed for Claude Code, but if you see errors, run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser` | PowerShell terminal |
| WSL vs native | WSL2 supports sandboxing; native Windows does not | Use WSL2 for `--sandbox` if available |

**For your setup**: Git for Windows + PowerShell should work. If bash commands fail, set `CLAUDE_CODE_GIT_BASH_PATH`.

**Doc**: https://code.claude.com/docs/en/setup.md (Windows section)

---

## **Putting It Together: A Senior Dev Workflow**

1. **Start in plan mode** (project default via `.claude/settings.json`)
   ```json
   { "permissions": { "defaultMode": "plan" } }
   ```

2. **Use Learning output style** to ensure Claude leaves TODOs for design decisions
   ```json
   { "outputStyle": "Learning" }
   ```

3. **Define CLAUDE.md rule**: "Every decision becomes an ADR"
   ```markdown
   # Architecture
   - Every structural change needs an ADR in `/docs/adr/NNNN-title.md`
   - ADRs must include Context, Decision, and Consequences
   ```

4. **Create `/explain-diff` skill** to summarize changes in Portuguese post-review

5. **Set PostToolUse hook** to run tests; block edits on failure

6. **Workflow**:
   - Ask Claude to refactor feature X
   - Claude proposes plan (no edits yet)
   - Review plan with `/plan` context visible
   - Approve → Claude edits + creates ADR + tests pass (blocked if not)
   - Run `/code-review` to verify
   - Run `/explain-diff` for Portuguese summary
   - Rewind if needed; branch if exploring alternatives

---

## **⚠️ Deprecated / Uncertain (2026)**

- **"Explanatory" and "Learning" are NOT deprecated**—still exist and work as documented
- No "custom output style" per-project configuration flag found; use file-based definition
- `/simplify` command (v2.1.147 and earlier) renamed to `/code-review --fix` for bug hunting; `/simplify` is now cleanup-only
- **Uncertain**: Whether ADR generation itself can be automated; CLAUDE.md + hooks can *enforce* it but not *auto-create* the file

---

**Total page references for your stack (Windows, PowerShell, Git Bash)**:
1. https://code.claude.com/docs/en/output-styles.md
2. https://code.claude.com/docs/en/permission-modes.md
3. https://code.claude.com/docs/en/memory.md
4. https://code.claude.com/docs/en/hooks-guide.md
5. https://code.claude.com/docs/en/code-review.md
6. https://code.claude.com/docs/en/checkpointing.md
7. https://code.claude.com/docs/en/setup.md (Windows)
