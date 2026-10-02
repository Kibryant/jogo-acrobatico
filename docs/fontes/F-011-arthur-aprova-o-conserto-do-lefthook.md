---
id: F-011
titulo: O Arthur aprova o conserto do lefthook (sessão 2, 02/10/2026)
recebido_em: 2026-10-02
como: Mensagem enviada ao Claude Code na sessão 2. Texto como chegou, sem correção.
status: vigente
substituida_por:
---

## §1 — Resposta ao plano de conserto

> Contexto, escrito pelo agente: uma sonda em `core/probe.gd` passou pelo pre-commit, porque o glob `core/**/*.gd` do job `core-purity` não casava arquivo na raiz de `core/`. O Claude parou e propôs: (1) `glob_matcher: doublestar` no `lefthook.yml`, com o `format` em `**/*.gd`; (2) repetir a sonda, que desta vez tinha de ser barrada; (3) apagar a sonda e refazer o primeiro commit com `git commit --amend`; (4) registrar o achado em `docs/mudancas.md` e fechar a TASK-1.

pode seguir com o plano
