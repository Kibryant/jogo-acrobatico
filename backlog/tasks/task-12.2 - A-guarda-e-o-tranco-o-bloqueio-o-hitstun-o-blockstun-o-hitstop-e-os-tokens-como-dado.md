---
id: TASK-12.2
title: >-
  A guarda e o tranco: o bloqueio, o hitstun, o blockstun, o hitstop e os tokens
  como dado
status: In Progress
assignee: []
created_date: '2026-10-27 22:02'
updated_date: '2026-10-28 12:17'
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
Sem o tranco, nenhuma troca tem conta (Q-10). Esta filha põe a guarda no botão direito, cobrindo a metade da frente (DEC-0054), que sobe em 6 ticks, anda a 3 m/s e custa 5 por leve; o hitstun de 24 e o blockstun de 15 do leve, contados do tick do contato; a paradinha simulada de 4 e 2 ticks, dos dois a partir do tick seguinte ao contato, com o tremor da câmera; e os tokens de leitura como Resource em `data/`, lidos pela chave do evento (DEC-0031 §5 e §6). Com o leve rápido, quem acerta fica 6 ticks à frente e quem bloqueia, 3 (DEC-0052). O boneco do Sozinho passa a dar um leve a cada 3 s, virado para quem joga, para o Arthur bloquear de frente, levar pelas costas e sentir a vez (`combate.md`, "O tranco e a vantagem"; `partida.md`, "O boneco que ataca").

### Perguntas em aberto
Nenhuma: os números e as regras do tick estão no `combate.md` ("O bloqueio, a guarda andando e a stamina", "O tranco e a vantagem", "O hitstop e o tremor"), no `partida.md` ("O boneco que ataca") e no `visual-e-audio.md` (os tokens e a tela de opções).

### Escolhas a confirmar
Nenhuma: a guarda no botão direito segurado e cobrindo a metade da frente são escolhas do Arthur (F-182 §2; DEC-0054). A paradinha como estado do núcleo é a leitura do desenho (`combate.md`, "O hitstop e o tremor"); a conferência dela ficou sem resposta na F-182 e volta no modo de plano.

### Fora do escopo
- O carregado, a armadura e o parry (TASK-12.3); a quebra e o tech (TASK-12.4); o som dos tokens (TASK-12.6); o bot que luta (TASK-12.8). A paradinha do golpe que mata (TASK-12.7).

### O que você vai aprender
- A vantagem como subtração: o tranco de quem leva menos o que falta a quem bateu, e por que a guarda de 6 ticks muda o que é "seguro".
- Um congelamento que é estado: o rollback refaz a paradinha igual, e a animação nunca descola.
- A guarda pela frente: um ângulo no plano do chão decidindo o bloqueio, e por que ele dá uso à acrobacia no duelo.
- O apresentador que compara o estado exibido com o último apresentado, o `present()` da sonda (F-061 §1).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando o jogador segura o botão direito em pé no chão, a guarda sobe em 6 ticks, e com ela alta o corpo anda a até 3 m/s; soltar a derruba na hora; pular, dar o dash ou golpear a derrubam, e com o botão ainda apertado ela sobe sozinha de novo em 6 ticks assim que o corpo está em pé no chão, sem golpe e sem tranco; no ar não há guarda (DEC-0054).
- [ ] #2 Quando um leve toca quem tem a guarda alta, com o atacante a até 90° de onde o corpo de quem defende olha, o golpe não tira vida, quem bloqueou paga 5 de stamina e fica 15 ticks no blockstun contados do contato, quem bateu segue a recuperação, e quem bloqueou fica 3 ticks à frente (DEC-0052).
- [ ] #3 Quando o leve vem de mais de 90° de onde a guarda olha, pelas costas, ou chega antes de os 6 ticks da guarda se completarem, ele pega como sem guarda (DEC-0054).
- [ ] #4 Quando um leve pega sem guarda, o alvo perde 12, fica 24 ticks sem input de movimento nem de ação contados do contato, o golpe dele em curso acaba, e a gravidade segue; quem bateu fica 6 ticks à frente; um golpe novo no meio do tranco o recomeça do contato novo.
- [ ] #5 Quando quem bloqueia tem menos de 5 de stamina, a guarda cai no contato e o golpe pega com o tranco cheio.
- [ ] #6 Quando um leve pega ou é bloqueado, quem levou ou bloqueou congela 4 ou 2 ticks a partir do tick seguinte ao contato, e quem bateu congela a mesma duração a partir do tick seguinte a esse, quando a foto mostra o resultado; congelados, os corpos não se movem nem caem e depois seguem com a velocidade que tinham; o relógio do golpe e o do tranco andam a duração para a frente, e a vantagem medida depois é a mesma de antes; um contato sem resultado não congela ninguém (DEC-0055).
- [ ] #7 Quando um leve pega, a câmera de quem levou treme por 100 ms com até 0,5°, e no bloqueio a de quem bloqueou, com até 0,3°, uma vez por evento, nunca de novo na re-simulação; a linha "Tremor da câmera" da tela de opções desliga o tremor.
- [ ] #8 Quando a cena da guarda roda na SyncTest com o rollback de 7 ticks, com acertos, bloqueios e paradinhas, nenhum campo diverge, e o veneno no campo do congelamento a faz acusar.
- [ ] #9 Quando o Arthur joga contra o boneco que dá um leve a cada 3 s virado para ele, ele bloqueia de frente, leva pelas costas, sente a paradinha e o tremor, troca a tecla da guarda nas opções, e vê a cor, a pose e a forma do HUD de cada estado dos tokens, lidos de um Resource em `data/`.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
