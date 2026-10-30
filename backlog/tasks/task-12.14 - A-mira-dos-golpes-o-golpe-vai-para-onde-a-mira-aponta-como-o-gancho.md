---
id: TASK-12.14
title: 'A mira dos golpes: o golpe vai para onde a mira aponta, como o gancho'
status: To Refine
assignee: []
created_date: '2026-10-30 14:43'
labels:
  - jogo
milestone: m-2
dependencies:
  - TASK-12.3
parent_task_id: TASK-12
ordinal: 30500
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
Jogando a TASK-12.3, o Arthur errou 11 carregados de lado. Em todos, o boneco estava à direita do corte, em média 0,57 m (F-196 §1). Nas palavras dele: "Eu tive que compensar a mira pra eu acertar o golpe" (F-196 §2).

É a paralaxe da mira da DEC-0045. A câmera fica 0,8 m à direita do corpo, e o golpe sai do eixo do corpo na direção da câmera, paralelo à linha da mira. O leve, com 120° de arco, esconde o erro; o carregado, que corta reto com 0,43 m de folga para o lado, passa ao lado.

O gancho já foi corrigido: o raio dele sai da linha da mira (DEC-0045). A espada não foi. O `combate.md` já diz que "o golpe sai para onde a câmera olha, como o gancho" ("A lâmina e o contato", linha "Direção"). O Arthur mandou a correção para esta task, antes da quebra de guarda (F-197).

### Perguntas em aberto
- A direção do golpe aponta para o ponto da linha da mira a 2,0 m, a ponta da lâmina? Ou para o ponto que o raio da mira acerta, como no gancho? Sugestão: 2,0 m, uma conta pura no núcleo, sem raio do motor. O erro de lado fica abaixo dos 0,43 m de 1 m a 2,4 m.
- O corpo vira para esse ponto na preparação, uns 22° a 2 m? Sugestão: sim, como hoje ele já vira para a câmera.

### Escolhas a confirmar
- A regra vale para o leve e para o carregado (sugestão), ou só para o carregado.
- O boneco, e depois o bot da TASK-12.8, mira como gente: põe a linha da mira em quem joga.

### Fora do escopo
- A tecla do carregado no mouse (Q-56).
- O castigo do parry (Q-55), que se julga de novo depois desta task.

### O que você vai aprender
- A paralaxe outra vez: a regra do núcleo e a mira da tela precisam falar do mesmo ponto, e um teste de núcleo não vê a câmera.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando o jogador põe a mira no boneco, de 1 m a 2,4 m, e dá o carregado, o corte pega sem compensar a mira; fora desse alcance, ele erra como hoje.
- [ ] #2 Quando o jogador dá o leve com a mira no boneco, o arco pega como antes, e o golpe vai para o mesmo ponto que o carregado.
- [ ] #3 Quando o boneco dá o carregado contra quem está parado à frente dele, o corte pega.
- [ ] #4 Quando a cena roda na SyncTest com o rollback de 7 ticks, nenhum campo diverge.
- [ ] #5 Quando o Arthur joga, os carregados que erram não erram mais de um lado só, e o replay mede o lado, como na F-196 §1.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
