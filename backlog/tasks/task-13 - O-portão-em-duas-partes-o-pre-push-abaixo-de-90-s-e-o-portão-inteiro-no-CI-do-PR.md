---
id: TASK-13
title: >-
  O portão em duas partes: o pre-push abaixo de 90 s e o portão inteiro no CI do
  PR
status: To Refine
assignee: []
created_date: '2026-10-27 16:22'
labels:
  - base
dependencies: []
ordinal: 26000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
O portão levou 369 s na TASK-10.8 com o PC quieto, quatro vezes os 90 s do pre-push (DEC-0027 §1; `testes-e-entrega.md` §11; Q-46). A DEC-0027 §4 manda o que não cabe para um job do CI fora do pre-push, com uma DEC nova. Antes de a fase 2 somar as suítes do combate, o portão precisa caber de novo no pre-push.

### Perguntas em aberto
- Que passos saem do pre-push e vão só para o CI do PR: a SyncTest inteira, as sondas do motor, o replay do portão, os testes de cena? Medir o peso de cada passo antes de decidir.

### Escolhas a confirmar
- A divisão (padrão sugerido: o pre-push fica com formato, lint, pureza, travas, compilar tudo e os testes do núcleo, abaixo de 90 s; o CI do PR roda o portão inteiro, e o merge espera o CI verde).
- Uma DEC nova que completa a DEC-0027 §4.

### Fora do escopo
- Acelerar os testes em si; trocar o gdUnit4.

### O que você vai aprender
- Por que um portão lento vira um portão pulado, e como a DEC-0027 previu a divisão.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando o pre-push roda com o PC quieto, ele termina em menos de 90 s (DEC-0027 §1).
- [ ] #2 Quando um PR abre, o CI roda o portão inteiro, e uma falha em qualquer passo deixa o PR vermelho.
- [ ] #3 Quando a divisão entra, uma DEC nova a registra, completando a DEC-0027 §4, e o testes-e-entrega.md §2 diz o que roda onde.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
