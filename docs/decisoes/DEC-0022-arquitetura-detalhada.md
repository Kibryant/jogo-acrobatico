---
id: DEC-0022
titulo: Arquitetura detalhada — o estado em quatro caixas, a máquina de estados no núcleo, o tick em sanduíche, as cenas, zero autoloads nossos, as pastas e o acesso inseguro como erro
data: 2026-10-02
status: aceita
decidido_por: Arthur
fontes: [F-005, F-007, F-018, F-020, F-021]
substitui: DEC-0004, só a frase sobre a RewindableStateMachine
substituida_por:
---

# DEC-0022 — Arquitetura detalhada: o estado em quatro caixas, a máquina de estados no núcleo, o tick em sanduíche, as cenas, zero autoloads nossos, as pastas e o acesso inseguro como erro

## Contexto

A DEC-0004 fixou as seis regras: núcleo puro, nós finos, dados imutáveis, testar a regra, DDD só estratégico e crescer por marcos. Faltava a forma concreta: o estado, o input, o encaixe do núcleo no netfox, as cenas e as pastas (TASK-4; DEC-0012).

O Desenho 2 teve duas rodadas, explicadas no mundo do Arthur e com trade-off em cada escolha (DEC-0021). O Arthur confirmou cada decisão depois de acertar as perguntas de conferência (F-020 §3 e §5; F-021 §1). O escopo foi o esqueleto andante em detalhe, a fase 1 esboçada e o combate só com nome, com a configuração imutável em ticks (F-018 §1).

O netfox foi lido no código-fonte, na `main`, commit `cf5189d` (26/09/2026), sem instalar. A prova com ele rodando é do Desenho 3 (Q-02). O que foi conferido:

- O netfox grava cada propriedade por valor, lendo com `get_indexed` e restaurando com `set_indexed` (`addons/netfox/servers/data/snapshot.gd`). O caminho `:state:mode` lê o campo `mode` do objeto `state` (`addons/netfox/servers/data/property-pool.gd`; `addons/netfox/properties/property-entry.gd`).
- O estado é restaurado antes de cada tick re-simulado e gravado depois dele (`addons/netfox/rollback/rollback-synchronizer.gd`). O `_rollback_tick(delta, tick, is_fresh)` é chamado na ordem da árvore de cena (`addons/netfox/servers/rollback-simulation-server.gd`).
- A `RewindableStateMachine` é plana, porque busca só os filhos diretos. Ela grava só o nome do estado, e a lógica fica num nó por estado. A troca de animação acontece depois do loop de ticks (`addons/netfox.extras/state-machine/rewindable-state-machine.gd`).
- Os padrões são 30 ticks por segundo, 64 ticks de histórico, até 8 ticks por frame e diff de estado ligado (`addons/netfox/netfox.gd`).
- O `is_on_floor()` fica velho depois do rollback, e a consulta de física contra corpo rebobinado vê a posição antiga (`docs/netfox/tutorials/rollback-caveats.md`).
- O input é capturado uma vez por loop de ticks, e o comando de um toque vale no máximo um tick (`docs/netfox/tutorials/input-gathering-tips-and-tricks.md`).

Dois achados de sonda entraram na conversa. Primeiro: a 30 ticks, o pulo de 1,2 m chega a 1,09 m se a gravidade vier da fórmula contínua. Segundo: o portão não compila um script que nenhum teste carrega (F-021, contexto).

## Opções consideradas

**Máquina de estados**

1. `RewindableStateMachine` do netfox: vem pronta, mas é plana, grava só o nome e põe a regra em nó.
2. Híbrido: os nós dela só chamam o núcleo. A transição passa a ser decidida em dois lugares.
3. **No núcleo, como dado:** a escolhida (F-020 §5).

**Forma do estado**

1. **Quatro caixas:** a escolhida (F-020 §5).
2. Tudo num objeto só: a posição teria que ser copiada à mão para o corpo a cada rollback.
3. Tudo em propriedades do nó: o núcleo perde o tipo que recebe e devolve.

**Autoloads**

1. **Zero nossos:** o escolhido (F-021 §1).
2. Um autoload `Game` com a configuração e a partida: estado global que não volta no tempo.

**Acesso inseguro**

1. **Erro no projeto todo, com o furo do portão na TASK-6:** a escolhida (F-021 §1).
2. Erro, com o portão consertado já.
3. Continuar como aviso.

## Decisão

### 1. O estado em quatro caixas

| Caixa | Onde mora | O que guarda (esqueleto andante) | Como o netfox grava |
|---|---|---|---|
| Corpo | O nó `Fighter` (CharacterBody3D) | `position`, `velocity` | `:position`, `:velocity` |
| Regras | O `FighterState`, um objeto só de valores dentro do nó | `mode`, `mode_since`, `on_floor`, `left_floor_tick`, `jump_pressed_tick`, `jumps_used`, `facing_yaw` | `:state:mode` e assim por diante, campo a campo |
| Input | O nó `Input`, do dono do lutador: um jogador ou um bot | `move` (Vector2, relativo à câmera), `yaw`, `jump` (um toque) | `Input:move`, `Input:yaw`, `Input:jump` |
| Configuração | O `MovementConfig`, fora do estado | Os números do `movimento.md` em ticks e a física derivada para o tick | Não grava: nunca muda na partida |

- O corpo fica no nó para o netfox restaurar todos os corpos juntos antes de cada tick re-simulado. Assim, um lutador colide com o outro na posição daquele tick.
- Tudo o que a regra lê ou escreve num tick está numa das três primeiras caixas. O que ficar fora é estado escondido e quebra o rollback (F-007 §6).
- **Fase 1, esboçado:** `stamina`, `stamina_spent_tick`, `dash_ready_tick`, `grapple_ready_tick`, `grapple_point`, `wall_normal` e a última parede; os modos WALL_RUN, DASH e GRAPPLE; no input, `dash` e `grapple`.
- **Fase 2, só o nome:** `action`, `action_since` e o golpe por ID, nunca o Resource (F-007 §5).

### 2. O tick em sanduíche

```
before_move(state, velocity, input, config, tick) -> MovePlan    # puro: decide
move_and_slide()                                                  # motor: move e colide
after_move(state, facts, config, tick) -> FighterState            # puro: confere
```

- `before_move` registra o carimbo do input, aplica buffer, coyote, pulo, aceleração e gravidade, e devolve o estado novo e a velocidade pedida.
- O nó multiplica a velocidade pelo `physics_factor` do netfox, move e divide de volta (`rollback-caveats.md`).
- `after_move` recebe os fatos do movimento (`MoveFacts`: no chão, velocidade depois da colisão; na fase 1, a parede) e atualiza o modo, o `on_floor`, o carimbo de saída do chão e os pulos usados.
- As duas fatias são funções puras em `core/`, testadas com tabela, sem cena. O `step` da DEC-0004 vira esse par em volta do motor, como a consequência "sanduíche" da própria DEC-0004 já previa.

### 3. A máquina de estados mora no núcleo, como dado

- O modo é um campo (`mode`) com o tick em que começou (`mode_since`). A transição é uma função pura.
- A hierarquia é uma função sobre o modo: `is_grounded(mode)` e `is_airborne(mode)`.
- O combate será um segundo modo, paralelo ao do movimento (`action`). "No ar ninguém se defende" vira uma regra entre os dois. É ali que a matriz de posição da Q-14 vai morar.
- A animação e o efeito trocam no `NetworkTime.after_tick_loop`, comparando o modo desenhado com o do estado, como a `RewindableStateMachine` faz por dentro. Não existe barramento de eventos (F-007 §8).
- A `RewindableStateMachine` não entra. Isso substitui a frase da DEC-0004 que a citava.

### 4. Tempo e física

- **Tempo como carimbo:** o estado guarda o tick em que algo aconteceu (`jump_pressed_tick = 1040`), e não uma contagem regressiva. A regra calcula: `tick - jump_pressed_tick < buffer_ticks`. O carimbo muda uma vez e só vai pela rede quando muda.
- **Ms para tick:** o tick mais próximo, e o empate sobe. Um teste falha se o erro passar de meio tick (DEC-0004, regra 3). A 30 ticks, o buffer de 150 ms vira 5 ticks (167 ms), e a janela de parry de 80 ms vira 2 ticks (67 ms, −17 %), o que é evidência para a Q-01.
- **Física derivada para o tick:** a configuração deriva velocidade e gravidade já sabendo o tamanho do tick. Um teste garante que o pulo simulado chega a 1,2 m, com tolerância de 1 cm, a 30 e a 60 ticks. A fórmula contínua daria 1,09 m a 30 ticks.
- **A configuração:** o `Match` carrega o `.tres`, em ms e metros, e cria o `MovementConfig` uma vez, com o tickrate como parâmetro. O núcleo só lê; `load()` segue proibido em `core/`.

### 5. As cenas

```
Fighter                    o lutador (CharacterBody3D, script fino)
├── Collision              a cápsula de 1,8 m × 0,35 m
├── Input                  o input do dono (FighterInput)
├── RollbackSynchronizer   do netfox: grava as caixas a cada tick
├── TickInterpolator       do netfox: suaviza o desenho entre ticks
└── Visual                 o boneco; só lê o estado
```

- `CameraRig`: cena separada, só para o lutador de quem joga. O mouse gira a câmera na hora, e a direção vai para o input como `yaw`.
- `Arena`: os blocos de 1, 2 e 3 m e os pontos de nascimento.
- `Match`: a partida. Carrega a configuração, cria a arena e os lutadores e entrega a configuração a cada um.
- `Main`: a entrada, que decide entre servidor e cliente. O detalhe é do Desenho 3.

### 6. Zero autoloads nossos

Só os do netfox, que vêm com ele. A configuração é passada à mão, como prop drilling. Um autoload futuro, como as preferências do jogador, só entra com DEC própria e se nunca for lido dentro do tick.

### 7. As pastas, por feature (DEC-0005)

```
core/fighter/   estado, input do tick, fatos, regras e a configuração do lutador
core/time/      ms para tick
data/           os .tres e as classes deles (movement_data.gd e movement_v0.tres)
fighter/        a cena do lutador, o FighterInput e o CameraRig
arena/          a arena e os blocos
match/          a partida
net/, ui/       quando a primeira task precisar
test/           espelha o código: test/core/fighter/...
```

O nome é `fighter/`, e não `player/`. O **jogador** é a pessoa; o **lutador** é o boneco, que também pode ser de um bot. É a diferença entre o invocador e o campeão no LoL.

### 8. Acesso inseguro é erro

Os avisos `unsafe_property_access`, `unsafe_method_access`, `unsafe_cast` e `unsafe_call_argument` passam a erro (nível 2) no projeto todo. Os addons ficam de fora pelo `directory_rules`. O Godot 4.7.2 não regula o nível de aviso por pasta, por isso não existe a opção "erro só em `core/`" que a DEC-0005 imaginou. Isso completa a DEC-0005. O teste de configurações guarda os quatro valores.

## Consequências

- A DEC-0004 continua valendo, menos a frase sobre a `RewindableStateMachine`. Ela ganha o aviso de substituição parcial no topo.
- `docs/arquitetura/visao-geral.md`, o glossário e o `AGENTS.md` passam a refletir esta DEC.
- O `project.godot` muda os quatro avisos, e o `test/project_settings_test.gd` os guarda.
- **O furo do portão vai para a TASK-6:** um script nosso com erro de tipo, que nenhum teste carrega, passa verde. Compilar todos numa execução só do Godot levou 1,3 s numa sonda. Um `--check-only` por arquivo leva 1,2 s cada e não escala. Como nenhum código de jogo nasce antes da TASK-6, o risco até lá é zero.
- **Hipóteses que o Desenho 3 prova com o netfox rodando (TASK-5):**
  - o caminho aninhado `:state:mode` de ponta a ponta: gravar, restaurar e mandar pela rede;
  - o contorno do transform (estático, transform, cinemático) no Jolt, para um lutador colidir com o outro na re-simulação;
  - `on_floor` como estado, no lugar do movimento extra de velocidade zero que o guia do netfox sugere.

## Revisitar se

- O Desenho 3 derrubar uma das três hipóteses.
- A medição de CPU com 16 bots (DEC-0004, regra 6) mostrar que alocar um `FighterState` novo por tick pesa. A saída seria mutar no lugar, com o mesmo teste.
- A fase 2 mostrar que o combate não cabe numa segunda região.
