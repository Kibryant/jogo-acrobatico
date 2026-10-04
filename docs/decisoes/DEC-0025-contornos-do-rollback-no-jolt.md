---
id: DEC-0025
titulo: Os contornos do rollback no Jolt — o do transform em todo tick refeito e o contorno D no começo de cada rollback
data: 2026-10-04
status: aceita
decidido_por: Arthur
fontes: [F-025, F-026, F-029, F-030, F-033]
substitui: DEC-0022, só a hipótese 3 (o on_floor no estado no lugar do movimento extra de velocidade zero)
substituida_por:
---

# DEC-0025 — Os contornos do rollback no Jolt: o do transform em todo tick refeito e o contorno D no começo de cada rollback

## Contexto

O Desenho 2 deixou três hipóteses sobre o netfox para o Desenho 3 provar com ele rodando no 4.7.2 (DEC-0022):

1. o caminho aninhado `:state:mode` grava, restaura e vai pela rede;
2. o contorno do transform (estático, transform, cinemático) faz um lutador colidir com o outro na posição certa ao refazer um tick;
3. guardar o `on_floor` no estado substitui o movimento extra de velocidade zero que o guia do netfox sugere.

A sonda as testou com uma SyncTest no estilo do GGPO, num processo só (F-025 §1). A cada loop, o netfox volta a profundidade de um ping de 220 ms, 4 ticks a 30 e 7 a 60, refaz, e cada tick refeito é comparado com o primeiro resultado daquele tick. O teste é mais duro que a rede, porque força o rollback a cada tick (F-033, contexto).

**Hipótese 1, provada:**

- os campos aninhados, envenenados depois de cada loop, voltaram todos: 0 divergências em 1.776 conferências a 30 ticks e em 7.134 a 60 (F-025 §2);
- pela rede, em 349 de 349 pulos, o tick lido no estado aninhado do outro lado bateu com o do aperto (F-026 §3);
- depois, em 747 de 747 e em 764 de 764, com 8 clientes (F-029 §1).

**Hipótese 2, provada com o contorno:**

- sem o contorno, o Jolt usa a posição velha do outro lutador: 786 divergências a 30 ticks, até 55 cm, e 1.897 a 60, até 1,56 m;
- com o contorno no `after_prepare_tick`, sobram 6 e 32, todas com um lutador em pé na cabeça do outro (F-025 §3). Esse caso virou a Q-16.

**Hipótese 3, derrubada** (F-025 §4). O `move_and_slide()` do Godot 4.7.2 guarda o próprio "estava no chão" do movimento anterior (`character_body_3d.cpp:95`) e o usa no snap (linhas 394 e 495). Depois de um rollback, esse valor é do presente, não do tick restaurado.

| Variante | 30 ticks | 60 ticks |
|---|---|---|
| A: só o `on_floor` no estado (a DEC-0022) | 61 divergências, até 28,7 cm | 71, até 51,7 cm |
| B: o movimento de velocidade zero do netfox, a cada tick | 11, até 18,2 cm | 175, até 20,6 cm |
| C: snap desligado, a regra empurra contra o chão | 0, mas não sobe a rampa de 45° | — |
| D: o flag do motor alinhado no começo de cada rollback | 0 | 0 |

As medições com servidor e clientes rodaram com os dois contornos ligados. Com 8 clientes a 30 ticks, eles custaram uns 6 pontos dos 62 % de um núcleo do servidor (F-029 §3).

## Opções consideradas

**Choque entre lutadores ao refazer**

1. **O contorno do transform em todo tick refeito:** o escolhido.
2. **Sem contorno:** o lutador refeito colide com o outro onde ele estava no presente.

**O "estava no chão" do motor**

1. **A:** só o `on_floor` no estado.
2. **B:** o movimento extra do netfox, a cada tick refeito.
3. **C:** o snap desligado.
4. **D:** o flag alinhado no começo de cada rollback. O escolhido (F-030 §1).

## Decisão

1. **O contorno do transform é obrigatório.** Todo corpo que o rollback move tem o transform empurrado para a física no `NetworkRollback.after_prepare_tick`, a cada tick refeito: modo estático, transform e cinemático, pelo `PhysicsServer3D` (`docs/netfox/tutorials/rollback-caveats.md`, commit `cf5189d`).
2. **O contorno D substitui a hipótese 3.**
   - O `on_floor` continua no estado do lutador (DEC-0022).
   - No primeiro tick preparado de cada rollback, cada lutador faz um micro-movimento de sonda: para baixo se o estado diz chão, para cima se diz ar.
   - Isso alinha o "estava no chão" do motor com o estado, e a posição e a velocidade voltam ao que eram (F-025 §4).
   - Na pergunta, o Arthur escolheu "D, flag alinhado (Recomendado)", cuja descrição dizia: "Zero divergências a 30 e a 60, com um movimento extra por rollback. A SyncTest no CI vigia se o Godot mudar." (F-030 §1).
3. **Os dois contornos são código de nó, não do núcleo,** porque tocam o motor. Eles moram no adaptador do lutador, fora do sanduíche: o núcleo continua puro (DEC-0004, regra 1).

## Consequências

- A DEC-0022 continua valendo, menos a hipótese 3. Ela ganha o aviso de substituição parcial no topo.
- O tick do lutador fica assim:
  1. o netfox restaura o estado;
  2. o contorno do transform, em todo tick;
  3. o contorno D, no primeiro tick do rollback;
  4. o sanduíche: `before_move`, `move_and_slide`, `after_move`;
  5. o netfox grava.
- A `visao-geral.md` e o `rede.md` mostram essa ordem.
- **O custo:** o contorno D faz um movimento extra por lutador por loop de rollback; o B faria um por tick refeito. O do transform troca o modo do corpo três vezes por tick refeito.
- **A SyncTest vira teste permanente no esqueleto andante** (TASK-9; DEC-0004, regra 4). Ela cobre rampa de 45°, beirada, pouso e dois lutadores se empurrando, e falha se uma versão nova do Godot ou do Jolt mudar o comportamento do motor.
- **O que sobra:**
  - o caso de um lutador em pé na cabeça do outro (Q-16, fase 1);
  - num duelo de 60 ticks, um flag de chão trocado com a posição idêntica até o micrômetro: 1 em 14.268 conferências (F-025 §4).

## Revisitar se

- O Godot ganhar passo manual de física ou um jeito de definir o estado de chão do `CharacterBody3D`. O contorno D poderia sair.
- A SyncTest acusar divergência depois de atualizar o Godot, o Jolt ou o netfox.
- As manobras da fase 1 (parede, gancho, dash) mostrarem outro estado escondido do motor.
