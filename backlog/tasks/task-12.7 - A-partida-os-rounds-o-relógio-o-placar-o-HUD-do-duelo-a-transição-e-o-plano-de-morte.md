---
id: TASK-12.7
title: >-
  A partida: os rounds, o relógio, o placar, o HUD do duelo, a transição e o
  plano de morte
status: To Refine
assignee: []
created_date: '2026-10-27 22:02'
labels:
  - jogo
milestone: m-2
dependencies:
  - TASK-12.5
parent_task_id: TASK-12
ordinal: 34000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
O duelo como partida: vida 100, vence quem ganha 3 rounds de até 90 s, tempo esgotado pela vida, round sem ponto no vazio e no Double KO, a transição de 5,2 s, os lados que trocam (`partida.md`, "O duelo"; escolha do Arthur, F-172 §2; DEC-0050; Q-29). O plano de morte entra como regra do núcleo, 5 m abaixo do chão, pronta para o primeiro mapa com vão (Q-48). E a Main ganha a escolha do que jogar dentro do Sozinho.

### Perguntas em aberto
Nenhuma: os números estão no `partida.md`.

### Escolhas a confirmar
- O HUD do duelo: a vida dos dois no topo, o placar e o relógio no centro, a stamina onde já está. Padrão sugerido; o Arthur vê um mock antes.

### Fora do escopo
- O bot que luta (TASK-12.8): aqui o oponente é o boneco que ataca. O anti-fuga (Q-50). A arena de duelo própria (Q-51).

### O que você vai aprender
- A máquina de estados da partida, pura e no servidor: contagem, luta, fim de round, fim de partida, com carimbos (DEC-0022).
- Por que o tempo esgotado decide pela vida em toda a tribo, e o que isso faz com a fuga.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando o duelo começa, os dois lutadores nascem a 10 m um do outro, de frente, com vida 100 e stamina 100, e a contagem de 180 ticks trava as teclas e deixa a câmera livre.
- [ ] #2 Quando a vida de um lutador chega a zero, os dois congelam 12 ticks, o round acaba, o ponto vai para o outro, e por 120 ticks a simulação segue com as teclas ignoradas; depois, o reset troca os lados e começa a contagem.
- [ ] #3 Quando os 5.400 ticks do round acabam com os dois vivos, vence quem tem mais vida; com vida igual, quem acertou primeiro; sem golpe algum, ou com os dois mortos no mesmo tick, o round não dá ponto.
- [ ] #4 Quando alguém chega a 3 rounds, a partida acaba e a tela diz quem venceu e por quê; quando o nono round acaba sem vencedor, a partida é empate.
- [ ] #5 Quando um lutador passa de 5 m abaixo do chão mais baixo, ele morre: no duelo, o round acaba como no KO; no Sozinho livre, ele volta ao ponto de nascimento depois de 30 ticks. Um teste da arena prova que nenhum chão fica abaixo do plano.
- [ ] #6 Quando um número da partida muda no Resource (a vida, o tempo do round, os rounds para vencer), o jogo muda sem tocar no código (DEC-0004, regra 3).
- [ ] #7 Quando a cena da partida roda na SyncTest com o rollback de 7 ticks, um KO e um fim por tempo, nenhum campo diverge.
- [ ] #8 Quando o Arthur joga um duelo inteiro contra o boneco que ataca, ele vê o placar, o relógio e a transição, e diz o que sentiu do ritmo.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
