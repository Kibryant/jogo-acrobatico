---
id: DEC-0008
titulo: Idioma — inglês no que é interno ao agente e ao código, português no que o Arthur lê
data: 2026-10-02
status: aceita
decidido_por: Arthur
fontes: [F-002, F-003, F-009]
substitui:
substituida_por:
---

# DEC-0008 — Idioma: inglês no que é interno ao agente e ao código, português no que o Arthur lê

## Contexto

O briefing recomendou código e arquivos do agente em inglês, e ADR, diário e explicações em português; o Arthur aceitou (F-002; F-003 §4). No SkinHub as tasks são em inglês, e no YabaBuss os cards são em português porque o Henrique lê (F-009).

## Opções consideradas

1. **Tudo que é interno em inglês, tudo que o Arthur lê em português, inclusive as tasks**: a escolhida.
2. Tasks em inglês, como no SkinHub.
3. Tudo em português.

## Decisão

- **Em inglês:** `AGENTS.md`, agentes, skills, scripts, código, comentários, testes e nomes de branch.
- **Em português:** `docs/` inteiro, as tasks do board (título e conteúdo), as mensagens de commit, o diário, as explicações e as perguntas para o Arthur.
- Citação literal fica no idioma original.

As tasks ficam em português porque o Arthur aprende pelas tasks (F-003 §4). Essa parte é leitura do agente, e o Arthur confirma na próxima sessão (Q-08).

## Consequências

- Os estados do Backlog.md ficam em inglês, como no SkinHub, porque são nomes da ferramenta.
- As seções da task, como "Por quê" e "Perguntas em aberto", ficam em português.

## Revisitar se

- O Arthur preferir as tasks em inglês, como no SkinHub (Q-08).
