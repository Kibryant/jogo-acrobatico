---
id: TASK-12.12
title: >-
  O log de crash e os testadores: as configurações do Godot, o passo a passo e o
  pedido ao SignPath
status: To Refine
assignee: []
created_date: '2026-10-27 22:02'
labels:
  - jogo
milestone: m-2
dependencies:
  - TASK-12.7
parent_task_id: TASK-12
ordinal: 39000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
Quando os amigos testarem, o jogo precisa deixar o log com a pilha no PC deles, e eles precisam saber como mandar (DEC-0034; `testes-e-entrega.md` §13). O `.exe` sem assinatura cai no SmartScreen, e o pedido ao SignPath espera desde a v0.1.0 (Q-20; DEC-0034).

### Perguntas em aberto
- O custo do `always_track_call_stacks` no PC mínimo: medir antes de manter (F-173 §3).

### Escolhas a confirmar
- O pedido ao SignPath: o Arthur abre a conta e faz o pedido, com o Claude ao lado (é dele, como o GitHub e a Edgegap).

### Fora do escopo
- O Sentry (fase 3). Qualquer serviço pago.

### O que você vai aprender
- O que uma build exportada do Godot escreve quando cai, e por que o template oficial não tem símbolos.
- Como se escreve um passo a passo para quem nunca abriu uma pasta do AppData.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando o jogo exportado roda no Windows, ele escreve o log em `%APPDATA%\Godot\app_userdata\Jogo Acrobático\logs`, guarda até 10 arquivos, e a primeira linha traz a versão e o commit.
- [ ] #2 Quando um erro de GDScript acontece na build exportada, o log traz a pilha de chamadas até a origem; quando o motor cai, o log traz a mensagem em português pedindo o envio do log.
- [ ] #3 Quando as seis configurações do §13 entram no project.godot, o `test/project_settings_test.gd` guarda cada uma, e a medição de fps com o rastreio da pilha ligado fica anotada.
- [ ] #4 Quando um testador lê o passo a passo público, em português, ele acha o log, o replay e o jeito de mandar os dois sem ajuda; uma pessoa de fora o segue antes de ele valer.
- [ ] #5 Quando o pedido ao SignPath é feito, a resposta fica anotada; se recusado, o passo a passo diz como passar pelo SmartScreen.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
