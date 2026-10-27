---
id: TASK-12.13
title: 'O teste da fase: os amigos jogam, e a versão 0.3.0'
status: To Refine
assignee: []
created_date: '2026-10-27 22:02'
labels:
  - jogo
milestone: m-2
dependencies:
  - TASK-12.8
  - TASK-12.6
  - TASK-12.10
  - TASK-12.11
  - TASK-12.12
parent_task_id: TASK-12
ordinal: 40000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
O portão da fase 2: "Amigos entendem cada troca?" (F-001; `roteiro.md`). Com o duelo contra o bot, o som, o manequim, o percurso e o log prontos, uma build vai para dois ou três amigos, e eles jogam contra o bot e um contra o outro no mesmo PC ou em sessões separadas; o que eles dizem de cada troca é a resposta. A fase fecha com a versão 0.3.0 (DEC-0028 §3), como a TASK-10.14 fechou a fase 1.

### Perguntas em aberto
- Quantos amigos, e se jogam no PC do Arthur ou nos deles com a build.

### Escolhas a confirmar
- O roteiro do teste: assistir sem explicar, perguntar "o que aconteceu?" depois de cada troca, gravar o replay. Padrão sugerido.

### Fora do escopo
- O 1v1 online (fase 3).

### O que você vai aprender
- Como se corre um teste de leitura sem induzir a resposta (F-041; F-055).
- O fechamento de uma fase: a versão, as notas da release e o roteiro.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando os amigos jogam o duelo contra o bot e um contra o outro, eles dizem, em cada troca, quem acertou, quem defendeu e por quê, e o Arthur anota o que eles leram e o que não leram.
- [ ] #2 Quando um amigo joga a build no PC dele, o passo a passo do log basta para ele instalar e, se cair, mandar o log.
- [ ] #3 Quando o teste termina, o diário diz se o portão passou e o que cada amigo não leu, e as pendências ganham o que apareceu.
- [ ] #4 Quando a TASK-12 fecha, a versão sobe para 0.3.0 no mesmo commit, com as notas da release tiradas dos diários, e o roteiro ganha a fase 2 em "Fases fechadas".
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
