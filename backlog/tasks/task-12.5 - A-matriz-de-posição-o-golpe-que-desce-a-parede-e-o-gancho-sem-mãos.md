---
id: TASK-12.5
title: 'A matriz de posição: o golpe que desce, a parede e o gancho sem mãos'
status: To Refine
assignee: []
created_date: '2026-10-27 22:02'
labels:
  - jogo
milestone: m-2
dependencies:
  - TASK-12.4
parent_task_id: TASK-12
ordinal: 32000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
Cada lugar com uma força e uma fraqueza (pilar 2): no ar, só o leve, que desce em 45°, e nenhuma defesa; na parede e na puxada do gancho, nada, porque as mãos estão ocupadas; um golpe derruba da parede e solta o gancho (`combate.md`, "A matriz de posição"; Q-14; escolha do Arthur na rodada 2 do desenho do duelo, F-174 §2; DEC-0050). É a acrobacia virando jogada no combate (pilar 3).

### Perguntas em aberto
Nenhuma: a matriz está no `combate.md`.

### Escolhas a confirmar
Nenhuma além da matriz, já escolhida.

### Fora do escopo
- O bot que usa a parede e o gancho (outra filha, depois do duelo sentido). O gancho em gente.

### O que você vai aprender
- "No ar ninguém se defende" como regra entre os dois modos, não como caso especial de cada defesa.
- Um modo comprometido (parede, gancho) terminado por um fato de fora dele: o golpe que chega.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando o jogador aperta o leve no ar, o golpe sai com o arco inclinado 45° para baixo, e pousar durante o ativo ou a recuperação não o corta.
- [ ] #2 Quando o jogador aperta o carregado, a quebra, a guarda ou o parry no ar, nada sai, e o aperto espera na vaga do buffer pelos 150 ms.
- [ ] #3 Quando um golpe toca quem está no ar, ele pega sem defesa possível, o tranco começa e o corpo segue a trajetória; a quebra não agarra quem está no ar.
- [ ] #4 Quando o jogador está na corrida na parede ou na puxada do gancho, nenhum ataque nem defesa sai, e o aperto espera na vaga.
- [ ] #5 Quando um golpe toca quem está na corrida na parede, a corrida acaba e o corpo cai no ar com o tranco; quando toca quem está na puxada, o gancho solta com o tranco e a recarga conta da soltura.
- [ ] #6 Quando a cena da matriz roda na SyncTest com o rollback de 7 ticks, com um golpe no ar, um na parede e um na puxada, nenhum campo diverge.
- [ ] #7 Quando o Arthur joga, ele pula da parede e dá o golpe que desce no boneco, e leva um golpe na parede e na puxada para sentir o preço.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
