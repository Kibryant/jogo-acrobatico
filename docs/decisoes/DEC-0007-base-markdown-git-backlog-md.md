---
id: DEC-0007
titulo: Base de contexto e tasks — markdown e git, com tasks no Backlog.md, no padrão do SkinHub
data: 2026-10-02
status: aceita
decidido_por: Arthur
fontes: [F-003, F-009]
substitui:
substituida_por:
---

# DEC-0007 — Base de contexto e tasks: markdown e git, com tasks no Backlog.md, no padrão do SkinHub

## Contexto

O Arthur pediu que o projeto use tasks e backlog "que é o mesmo negócio do Skin Hub" (F-003 §4). No SkinHub, a base é markdown com git, as tasks ficam no Backlog.md e o conhecimento fica em `docs/`, com fontes, decisões, mudanças e pendências (F-009).

## Opções consideradas

1. **O padrão do SkinHub: markdown, git e Backlog.md**, a escolhida (F-003 §4).
2. **Tasks no Yabadoo ou no ClickUp**: o board ficaria fora do repositório, longe do código e do agente.

## Decisão

- **Conhecimento em `docs/`**, organizado assim:
  - `fontes/`: F-xxx imutáveis;
  - `decisoes/`: DEC-xxxx em formato ADR;
  - `design/` e `arquitetura/`: o estado atual;
  - `diario/`: uma entrada por sessão;
  - `mudancas.md`: só recebe acréscimo;
  - `pendencias.md`: as perguntas abertas.
- **Tasks no Backlog.md 1.53**, só pela CLI:
  - prefixo `TASK`;
  - estados To Refine, Ready, In Progress, Waiting, Parked e Done;
  - definição de pronto no `backlog/config.yml`.
  - Não se usa `backlog decision` nem `backlog doc`.
- **Repositório e Yabadoo:** a fonte de verdade do projeto é o repositório. O Yabadoo recebe uma linha por decisão aceita, pela skill `diario`.

## Consequências

- As relações entre documentos se fazem por citação de ID, como (DEC-0004) e (F-003 §2).
- O board é texto versionado no git e anda junto com o código.

## Revisitar se

- A base passar de ~150 documentos.
- O agente errar contexto por não achar a relação entre documentos.
