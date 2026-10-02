---
name: adr
description: Records a decision as a DEC (ADR) in docs/decisoes, in Portuguese, in the project format, and updates the index. Use it when Arthur decides about architecture, dependencies, typing, tooling, design rules or process.
---

1. Find the last ID in `docs/decisoes/` and use the next one: `DEC-NNNN-short-slug.md`.
2. Frontmatter: `id`, `titulo`, `data` (YYYY-MM-DD), `status` (`proposta` until Arthur says yes, then `aceita`), `decidido_por`, `fontes`, `substitui`, `substituida_por`.
3. Sections, in Portuguese: `## Contexto`, `## Opções consideradas`, `## Decisão`, `## Consequências`, `## Revisitar se`. Quote Arthur's own words where he decided, citing the F-xxx that holds them. Every claim cites a source.
4. If a new F-xxx is needed for Arthur's words or a research result, create it first in `docs/fontes/`.
5. If the decision replaces another one, create the new DEC with `substitui`. In the old one change only `status` and `substituida_por`, and add at the top: "⚠️ Substituída por DEC-XXXX em AAAA-MM-DD — não é a regra atual".
6. Update `docs/decisoes/README.md` (Vigentes, Propostas, Histórico) and, if something changed state, add a row at the end of `docs/mudancas.md`.
7. Tell Arthur, in one short paragraph in Portuguese, what was recorded and what it changes.
