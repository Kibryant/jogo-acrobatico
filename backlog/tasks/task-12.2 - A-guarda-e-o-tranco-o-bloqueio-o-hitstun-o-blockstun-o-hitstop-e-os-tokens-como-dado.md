---
id: TASK-12.2
title: >-
  A guarda e o tranco: o bloqueio, o hitstun, o blockstun, o hitstop e os tokens
  como dado
status: To Refine
assignee: []
created_date: '2026-10-27 22:02'
labels:
  - jogo
milestone: m-2
dependencies:
  - TASK-12.1
parent_task_id: TASK-12
ordinal: 29000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
Sem o tranco, nenhuma troca tem conta (Q-10). Esta filha põe a guarda (sobe em 6 ticks, anda a 3 m/s, custa 5 por leve), o hitstun de 24 e o blockstun de 15 do leve, o hitstop simulado de 4 e 2 ticks com o tremor da câmera, e os tokens de leitura como Resource em `data/`, lidos pela chave do evento (DEC-0031 §5 e §6). O boneco passa a atacar com leves a cada 3 s, para o Arthur bloquear e sentir a vantagem (`combate.md`, "O tranco e a vantagem").

### Perguntas em aberto
Nenhuma: os números estão no `combate.md` ("O tranco e a vantagem", "O bloqueio, a guarda andando e a stamina", "O hitstop e o tremor") e os tokens no `visual-e-audio.md`.

### Escolhas a confirmar
- A tecla da guarda: o botão direito do mouse, segurado. Padrão sugerido.
- O hitstop como estado do núcleo (`frozen_until_tick`), que pausa o relógio do golpe dos dois: é a leitura do desenho (`combate.md`); confirmar que o Arthur a entendeu antes do test-writer.

### Fora do escopo
- O carregado e o parry (TASK-12.3); a quebra (TASK-12.4); o som dos tokens (TASK-12.6).

### O que você vai aprender
- A vantagem como subtração: o tranco de quem leva menos o que falta a quem bateu, e por que o bloqueio de 6 ticks muda o que é "seguro".
- Um congelamento que é estado: o rollback refaz o hitstop igual, e a animação nunca descola.
- O apresentador que compara o estado exibido com o último apresentado, o `present()` da sonda (F-061 §1).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando o jogador segura a guarda no chão, ela sobe em 6 ticks, o corpo anda a até 3 m/s, e correr, pular ou dar o dash a derruba.
- [ ] #2 Quando um leve toca a cápsula com a guarda alta, o golpe não tira vida, quem bloqueou paga 5 de stamina e fica 15 ticks no blockstun, quem bateu segue a recuperação, e a vantagem de quem bloqueou é de 6 ticks (`combate.md`).
- [ ] #3 Quando um leve toca a cápsula sem guarda, o alvo perde 12, fica 24 ticks sem input de movimento nem de ação, e a gravidade segue; quem bateu fica 3 ticks à frente.
- [ ] #4 Quando quem bloqueia tem menos de 5 de stamina, a guarda cai no contato e o golpe pega com o tranco cheio.
- [ ] #5 Quando um leve pega ou é bloqueado, os dois congelam 4 ou 2 ticks, o relógio da ação dos dois para junto, e a vantagem medida depois do congelamento é a mesma de antes dele.
- [ ] #6 Quando um golpe pega, a câmera de quem levou treme por 100 ms com até 0,5°, uma vez por evento, nunca de novo na re-simulação; a tela de opções desliga o tremor.
- [ ] #7 Quando a cena da guarda roda na SyncTest com o rollback de 7 ticks, nenhum campo diverge, e o veneno no campo do congelamento a faz acusar.
- [ ] #8 Quando o Arthur joga contra o boneco que ataca com leves a cada 3 s, ele bloqueia, leva, e vê a cor, a pose e a forma do HUD de cada estado dos tokens, lidos de um Resource em `data/`.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
