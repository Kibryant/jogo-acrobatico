---
name: diario
description: Closes a work session with a devlog entry in Portuguese for Arthur (docs/diario/YYYY-MM-DD.md), one row in the harness registry and the accepted decisions mirrored to the Yabadoo. Use it at the end of every session.
---

1. Write `docs/diario/YYYY-MM-DD.md`, or add a new `## Sessão N` if the file exists, with these sections in Portuguese:
   - `### O que fizemos`: the tasks, with IDs.
   - `### O que mudou e por quê`: cite the DECs.
   - `### Conceitos novos`: each one in one or two sentences, with a web analogy when it helps. Add domain terms to `docs/design/glossario.md`.
   - `### Como testar e o que sentir`.
   - `### O que ficou em aberto`: and the next task.
2. Add one row at the end of `.claude/harness/registro.md`: date | task | what happened | what repeated (candidate for promotion).
3. For each DEC accepted in the session, record it in the Yabadoo with `registrar_decisao`. Use one sentence that starts with "Jogo acrobático:" and cites the DEC id. Read `consultar_decisoes` first to avoid duplicates.
4. Keep it short: sentences under 25 words, no filler, no recap of what is already in the DECs.
