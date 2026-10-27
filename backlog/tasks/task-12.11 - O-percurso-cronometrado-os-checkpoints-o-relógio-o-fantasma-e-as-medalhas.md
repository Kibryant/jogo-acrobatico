---
id: TASK-12.11
title: 'O percurso cronometrado: os checkpoints, o relógio, o fantasma e as medalhas'
status: To Refine
assignee: []
created_date: '2026-10-27 22:02'
labels:
  - jogo
milestone: m-2
dependencies:
  - TASK-12.7
parent_task_id: TASK-12
ordinal: 38000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
A rampa de aprendizado do estudo (F-001): um portão de partida, seis checkpoints em ordem fixa e a chegada, dentro da arena de hoje, com o relógio em ticks, a volta ao checkpoint ao cair e o fantasma da melhor volta por rastro de estado (`partida.md`, "O percurso cronometrado"; F-173 §3). O traçado v0 está na vitrine; esta filha o fecha com o Arthur correndo.

### Perguntas em aberto
- O traçado final, depois de o Arthur correr o rascunho.

### Escolhas a confirmar
- Os tempos das medalhas: nascem do tempo do Arthur, depois da primeira volta dele.

### Fora do escopo
- O fantasma de outra pessoa e o ranking (fase 4). Mais de um percurso.

### O que você vai aprender
- Cruzar um volume por segmento, e por que a posição do tick não basta a 0,33 m por tick.
- O fantasma como rastro de estado contra o replay por inputs, e o que cada um sobrevive.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando o jogador cruza o portão de partida, o relógio começa em ticks; quando cruza a chegada com os seis checkpoints na ordem, ele para, e a tela mostra o tempo em segundos e centésimos.
- [ ] #2 Quando o segmento entre a posição de um tick e a do seguinte toca a esfera de 3 m de um checkpoint na ordem certa, ele conta; fora da ordem, não conta; um dash de 0,33 m por tick e um gancho não furam a esfera.
- [ ] #3 Quando o jogador passa do plano de morte no percurso, ele volta ao último checkpoint depois de 30 ticks, com velocidade zero, e o relógio continua.
- [ ] #4 Quando o jogador aperta a tecla de recomeçar, a volta recomeça na hora, no portão de partida.
- [ ] #5 Quando uma volta termina com o melhor tempo, o rastro de posição, rotação e modo por tick dela fica salvo em `user://` com a impressão da arena; na volta seguinte, o fantasma translúcido e sem colisão a repete; outra arena, nenhum fantasma.
- [ ] #6 Quando o tempo de uma volta bate um dos três tempos do Resource das medalhas, a tela mostra a medalha; os tempos saem da primeira volta do Arthur.
- [ ] #7 Quando o Arthur corre o percurso três vezes, ele diz se o traçado pede as cinco manobras e se o fantasma ajuda.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
