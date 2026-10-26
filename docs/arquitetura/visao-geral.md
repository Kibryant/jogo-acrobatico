---
revisado_em: 2026-10-26
fontes: [F-002, F-005, F-006, F-007, F-018, F-020, F-021, F-022, F-024, F-025, F-026, F-030, F-032, F-033, F-039, F-049, F-100, F-121, F-122, F-127, F-129, F-140, F-141]
---

# Visão geral

Estado atual: as DECs aceitas até 24/10/2026, a DEC-0044 incluída. O Desenho 2 (TASK-4) está detalhado na DEC-0022, e o Desenho 3 (TASK-5) nas DEC-0023 a DEC-0026, com o detalhe da rede no [`rede.md`](rede.md). O esqueleto andante (TASK-9) existe desde a v0.1.0, e a fase 1 começa pela TASK-10.1, com a interface da fase combinada na DEC-0039. A versão visual e interativa deste documento é o artefato [O tick por dentro](https://claude.ai/artifact/EJCYbVj6oCZcim765nDH8B), privado (DEC-0019); a da rede é a vitrine [A rede por dentro](https://claude.ai/artifact/Sb4Q5e4M16UymdoaR9UAzp).

## As camadas

```mermaid
flowchart TB
  dados["Dados (.tres)<br/>tempos, stamina, armas"]
  subgraph cliente["PC do jogador (cliente)"]
    input["Input<br/>teclas viram ações; buffer de pulo e dash"]
    nucleoC["Núcleo puro (core/)<br/>prevê e corrige"]
    nos["Nós do Godot<br/>CharacterBody3D + Jolt: colisão"]
    apres["Apresentação<br/>animação, VFX, som, HUD: só lê o estado"]
  end
  subgraph servidor["Servidor dedicado (São Paulo)"]
    nucleoS["Núcleo puro (core/)<br/>o mesmo código; decide"]
    partida["Partida e sala"]
  end
  supabase["Supabase<br/>contas e ranking, fora do tick"]
  dados --> nucleoC
  dados --> nucleoS
  input --> nucleoC
  nucleoC <--> nos
  nucleoC --> apres
  input -- "input com o tick (netfox)" --> nucleoS
  nucleoS -- "estado confirmado (netfox)" --> nucleoC
  nucleoS --> partida
  partida -- "fim de partida" --> supabase
```

O mesmo núcleo roda dos dois lados: no cliente ele prevê, e no servidor ele decide (DEC-0003, DEC-0004). Entre o núcleo e a tela ficam os nós do Godot, que fazem a colisão.

## Os contextos (DDD estratégico)

| Contexto | Onde roda | Tratamento |
|---|---|---|
| Simulação: combate e movimento | No servidor e, como previsão, no cliente, a cada tick | Domínio central: glossário e núcleo puro, sem aggregate nem repository |
| Partida e round | Servidor | Máquina de estados pequena e pura |
| Sala e lobby | Servidor, por RPC | Máquina de estados e CRUD |
| Progressão e estatísticas | Supabase | Aqui aggregate e o evento "partida terminou" fazem sentido |
| Contas | Supabase Auth | Pronto, sem modelar |

(F-007 §1)

A fronteira que importa é Simulação (tick e rollback) contra Meta (request, response e banco). As duas se ligam pelo evento de fim de partida.

## As seis regras (DEC-0004)

1. Um único núcleo puro em `core/`, em ticks inteiros.
2. Os nós são adaptadores finos, e som e efeito tocam uma vez por evento, pela chave (DEC-0031).
3. Os dados ficam em Resources imutáveis, referenciados por ID, com a conversão de ms para ticks testada.
4. Testar a regra, não a engine.
5. DDD só estratégico.
6. Crescer por marcos e medir a CPU com 16 bots antes de prometer o 8v8.

Duas frases da DEC-0004 mudaram: a máquina de estados não usa mais a `RewindableStateMachine` do netfox (DEC-0022; veja abaixo), e som e efeito tocam pela chave do evento, não pelo tick novo (DEC-0031).

## O tick

Um tick é uma rodada de atualização do jogo. Em cada uma, o jogo lê o que cada lutador apertou, aplica as regras e anota a nova situação, sempre no mesmo ritmo. Quando dizem que o Valorant tem servidor de 128 ticks, é isso: 128 rodadas por segundo. No TypeScript, seria um `setInterval(atualizarJogo, 33)`.

- O jogo roda a 60 ticks por segundo, um a cada 16,7 ms (DEC-0024). O padrão do netfox é 30 (`netfox/time/tickrate` em `addons/netfox/netfox.gd`, commit `cf5189d`); o `project.godot` guarda o 60, e o teste de configurações vigia.
- O tick decide; o frame só desenha. Um PC a 144 FPS e outro a 40 pulam igual, porque a regra roda no tick.
- O netfox guarda 64 ticks de histórico para o rollback, que dão 1,07 s a 60 por segundo, e roda até 8 ticks num frame quando precisa alcançar o relógio (`addons/netfox/netfox.gd`, commit `cf5189d`). A ordem do loop está no `rede.md`.

## O estado em quatro caixas (DEC-0022)

Tudo o que a regra lê ou escreve num tick precisa estar numa caixa que o netfox grava. O que ficar fora é estado escondido: o rollback volta no tempo e o esquece (F-007 §6).

```mermaid
flowchart LR
  subgraph fighter["Nó Fighter (CharacterBody3D)"]
    corpo["Corpo<br/>position, velocity"]
    regras["Regras: FighterState<br/>mode, mode_since, on_floor,<br/>left_floor_tick, buffered_command, buffered_tick,<br/>stamina_at_spend, stamina_spent_tick, double_jump_tick,<br/>jumps_used, facing_yaw,<br/>dash_tick, dash_direction,<br/>wall_normal, wall_id, wall_jump_tick,<br/>grapple_fired_tick, grapple_point, grapple_end_tick"]
  end
  input["Nó Input (do dono: jogador ou bot)<br/>move, yaw, pitch, jump, dash, grapple"]
  config["MovementConfig<br/>imutável, em ticks"]
  rbs["RollbackSynchronizer<br/>(netfox)"]
  rbs -- ":position, :velocity" --> corpo
  rbs -- ":state:mode, ..." --> regras
  rbs -- "Input:move, Input:yaw, Input:pitch,<br/>Input:jump, Input:dash, Input:grapple" --> input
  config -. "só leitura" .-> regras
```

| Caixa | Onde mora | O que guarda no esqueleto andante | Por que ali |
|---|---|---|---|
| Corpo | Nó `Fighter` | `position` (Vector3), `velocity` (Vector3, m/s) | O netfox restaura todos os corpos juntos antes de cada tick re-simulado, e um lutador colide com o outro na posição daquele tick |
| Regras | `FighterState`, um objeto só de valores | `mode`, `mode_since` (tick), `on_floor`, `left_floor_tick`, `buffered_command` e `buffered_tick` (a vaga do buffer, DEC-0039), `stamina_at_spend` e `stamina_spent_tick` (a stamina como valor mais carimbo), `double_jump_tick`, `jumps_used`, `facing_yaw` (rad), `dash_tick` e `dash_direction` (o tick em que o último dash começou e a direção fixada nele, um vetor horizontal unitário; TASK-10.4), `wall_normal`, `wall_id` e `wall_jump_tick` (a normal achatada e o caminho do colisor, relativo à `Arena`, da parede da corrida atual ou da última, que ficam até o chão, e o tick do último pulo da parede; DEC-0042; TASK-10.5), `grapple_fired_tick`, `grapple_point` e `grapple_end_tick` (o tick do disparo enquanto um cabo está no ar, voando ou puxando, o ponto fixado nele e a última soltura, de onde a recarga conta; TASK-10.6) | O núcleo puro recebe e devolve esse tipo; o netfox grava campo a campo, por valor |
| Input | Nó `Input` (script `FighterInput`) | `move` (Vector2, relativo à câmera, até 1), `yaw` (rad), `pitch` (rad, positivo para cima, a última amostra da câmera; TASK-10.6), `jump` (um toque), `dash` (um toque, o Shift esquerdo; TASK-10.4), `grapple` (um toque, o Q; TASK-10.6) | O bot preenche os mesmos campos; a regra não sabe quem aperta (DEC-0004) |
| Configuração | `MovementConfig`, fora do estado | Os números do `movimento.md` em ticks e a física derivada para o tick | Nunca muda na partida, então não precisa voltar no tempo |

- **Fase 1, esboçado nas filhas da TASK-10 (a ordem das filhas é a F-100; os campos, as descrições da TASK-10.1 à TASK-10.7):** a vaga do buffer, a stamina como valor mais carimbo e o `double_jump_tick` (TASK-10.1); `dash_tick` e `dash_direction` com o modo DASH (TASK-10.4, já no estado); `wall_normal`, `wall_id` (o caminho do colisor relativo à arena, nunca um id do motor) e `wall_jump_tick` com o modo WALL_RUN (TASK-10.5, já no estado); `grapple_fired_tick`, `grapple_point` e `grapple_end_tick` com o modo GRAPPLE (TASK-10.6, já no estado); `slide_off_dir` (TASK-10.7). No input, `dash` (TASK-10.4) e, desde a TASK-10.6, `pitch` e `grapple`. Os carimbos de fim substituem os `*_ready_tick` do esboço antigo: a recarga conta do fim da manobra.
- **Fase 2, só o nome:** `action`, `action_since` e o golpe por ID, nunca o Resource (F-007 §5).

## O tick por dentro: o sanduíche (DEC-0022; contornos da DEC-0025)

```mermaid
flowchart LR
  r["1. netfox restaura<br/>o estado do tick e o input"] --> t["2. contorno do transform<br/>(todo tick refeito)"]
  t --> d["3. contorno D<br/>(primeiro tick do rollback)"]
  d --> b["4. núcleo decide<br/>before_move()"]
  b --> m["5. motor move<br/>move_and_slide()"]
  m --> raio["5b. raio da mira<br/>(só com o pedido; DEC-0044)"]
  raio --> a["6. núcleo confere<br/>after_move()"]
  a --> g["7. netfox grava<br/>no histórico"]
```

Os dois contornos são código do nó, porque tocam o motor, e foram provados pela SyncTest do Desenho 3 (F-025; DEC-0025):

- **O contorno do transform** empurra a posição restaurada de cada lutador para a física (estático, transform, cinemático). Sem ele, o Jolt colide com o outro lutador onde ele estava no presente.
- **O contorno D** alinha o "estava no chão" que o `move_and_slide()` guarda sozinho, com um micro-movimento de sonda no primeiro tick de cada rollback. Sem ele, o pouso e a rampa saem diferentes ao refazer.

```
before_move(state, position, velocity, input, config, tick) -> MovePlan    # puro: decide; aim_request pede o raio
move_and_slide()                                                  # motor: move e colide
aim_ray(feet, yaw, pitch)                                         # nó: só com o pedido, o raio do ombro
after_move(state, facts, config, tick) -> FighterState            # puro: confere; dispara o gancho
```

- `before_move` carimba o input, aplica buffer, coyote, pulo, aceleração e gravidade, e devolve o estado novo e a velocidade pedida.
- **A troca por comando** (DEC-0041): o `before_move` também troca o modo quando a vaga guarda um comando vivo e legal. O primeiro é o dash, `GROUND → DASH`, com o `mode_since` carimbado no tick do aperto. Um modo comprometido só termina pela própria regra, no mesmo `before_move`: o `DASH` acaba quando os 12 ticks passam, sai na velocidade desenhada, 7 m/s na mesma direção, em `GROUND` ou `AIR` conforme o `on_floor` do estado, e no mesmo tick um aperto guardado pode sair (a saída desenhada; `movimento.md`, "Dash").
- O nó multiplica a velocidade pelo `physics_factor`, move e divide de volta (`docs/netfox/tutorials/rollback-caveats.md`, commit `cf5189d`).
- `after_move` recebe os fatos do movimento (`MoveFacts`): se terminou no chão, a velocidade depois da colisão, desde a TASK-10.5 a parede, em `wall_normal` e `wall_id` (DEC-0042), e desde a TASK-10.6 a posição dos pés em todo tick (`position`) e a resposta da mira, só quando o plano pediu (`aim_hit` e `aim_point`; DEC-0044). Com eles, troca o modo por contato, entre `GROUND` e `AIR`, só fora de um modo comprometido, e atualiza em todo tick o `on_floor`, o carimbo de saída do chão e os pulos usados (DEC-0041 §3). Por isso o dash que sai da beirada continua `DASH` até o fim, e a puxada do gancho continua `GRAPPLE` ao longo do chão ou saindo dele.
- **Os fatos da parede** (DEC-0042 §1): o nó os lê depois de mover, no `Fighter._wall_contact`. Fora da corrida, pelas colisões do próprio movimento: o colisor que não é lutador com a normal mais horizontal, o primeiro na ordem do motor num empate. Durante a corrida, pela sonda só de teste, `move_and_collide(-wall_normal * 0,05, true)`, porque correndo paralelo o movimento quase nunca colide (`rede.md` §4, "A sonda A da parede"). O `wall_id` é o caminho do colisor relativo à `Arena`, que o `Match` entrega ao lutador (`Fighter.arena`).
- **A corrida na parede** (TASK-10.5; `movimento.md`, "Corrida na parede"): a entrada é por contato, no `after_move`, no ar, com uma parede válida que não é a última e ao menos 4 m/s ao longo dela; ela renova o pulo duplo. Do tick seguinte em diante, o `before_move` zera a vertical, leva a velocidade ao longo a 8 m/s, ou mantém a de entrada até 12, e ignora o input; depois da altura mantida, a descida cresce tick a tick. O fim por tempo e o pulo da parede são do `before_move`; a borda, o chão, a trava abaixo de 4 m/s e outro colisor a mais de 10° são do `after_move`, que pode começar uma corrida nova no mesmo tick. Um colisor novo no mesmo plano, a até 10°, sem perder o contato, é a emenda: a mesma corrida segue no bloco novo (F-129). O mesmo colisor segue a corrida qualquer que seja a normal lida, como na quina arredondada antes do canto, e o estado guarda a normal da face.
- **O pedido de mira** (DEC-0044): enquanto a vaga guarda um aperto de gancho que pode sair, o `before_move` liga o `MovePlan.aim_request`. Depois de mover, o nó lança o raio do ombro, 1,6 m acima dos pés, pela mira do tick, só contra o cenário (`Fighter.aim_ray`). A direção é `Aim.direction(yaw, pitch)` (`core/fighter/aim.gd`), uma função pura do núcleo: a mesma do raio do nó e do raio da mira da tela (DEC-0044 §2). O `after_move` dispara se o ponto está de 3 a 25 m do ombro. As duas regras que decidem, `Movement.can_grapple` (pode sair agora) e `Movement.in_reach` (o alcance), são públicas: o núcleo as lê no pedido e no disparo, e a mira do HUD lê as mesmas, para nunca prometer o que a regra recusa.
- **O gancho** (TASK-10.6; `movimento.md`, "Gancho"): o disparo fixa o ponto e carimba o `grapple_fired_tick`; numa corrida na parede, a corrida acaba ali. O cabo voa 100 ms, e o corpo segue as regras do seu modo; o dash espera na vaga. Depois, o `before_move` começa a puxada, que encerra o modo em que o corpo estiver: os pés vão ao ponto a 18 m/s, a direção refeita a cada tick, sem gravidade e sem input. Três solturas, nesta ordem, no começo de cada tick: um pulo apertado desde o primeiro tick da puxada, os pés a 1,5 m do ponto e, do segundo tick em diante, menos de 9 m/s rumo ao ponto. O tick da soltura corre livre sobre a velocidade que chegou, e a recarga conta dele. Sair do chão puxado não abre o coyote, e entrar numa corrida na parede apaga o coyote do chão (Q-35).
- **O momento no ar** (F-127): no ar, acima de 7 m/s, o alvo do input mantém a velocidade que o corpo tem, então o input só gira e freia pela aceleração do ar e nunca corta o excesso; no chão, o excesso cai pela aceleração do chão.
- **O snap do chão** cobre a maior velocidade no chão, a do dash: 20 m/s ÷ 60 × tan 45°, mais três margens do motor, dá 0,338 m a 60 ticks, contra 0,121 m da corrida (`Fighter.floor_snap_for`; F-122). Sem ele, o dash descendo a rampa de 45° descola do chão em 9 dos 12 ticks (`test/fighter/fighter_slope_test.gd`). O preço é que um degrau de até 0,338 m vira chão; a menor queda da arena é de 1 m.
- As duas fatias de pão são funções puras em `core/`, testadas com tabela, sem cena. O recheio é a única linha que toca a física do Godot.

## A máquina de estados (DEC-0022)

O lutador está sempre num modo. O modo é um dado no estado (`mode` e `mode_since`), e a troca é uma função pura.

```mermaid
stateDiagram-v2
  direction LR
  state "Movimento (esqueleto andante e TASK-10.4 a TASK-10.6)" as mov {
    GROUND --> AIR: pulou ou saiu da beirada
    AIR --> GROUND: pousou
    GROUND --> DASH: apertou o dash (comando)
    DASH --> GROUND: fim dos 12 ticks, no chão
    DASH --> AIR: fim dos 12 ticks, no ar
    AIR --> WALL_RUN: encostou numa parede (contato)
    WALL_RUN --> AIR: tempo, pulo da parede, borda, trava ou disparo do gancho
    WALL_RUN --> GROUND: tocou o chão
    WALL_RUN --> WALL_RUN: outra face a mais de 10°
    GROUND --> GRAPPLE: o cabo voou 100 ms
    AIR --> GRAPPLE: o cabo voou 100 ms
    WALL_RUN --> GRAPPLE: o cabo voou 100 ms
    GRAPPLE --> AIR: soltura no ar
    GRAPPLE --> GROUND: soltura no chão
  }
```

- **Fase 1:** o DASH entrou na TASK-10.4, o primeiro modo comprometido: um comando o começa no `before_move`, e só a própria regra o termina (DEC-0041). O WALL_RUN entrou na TASK-10.5, também comprometido, mas começado por contato, no `after_move`; o tempo e o pulo da parede o terminam no `before_move`, e o contato perdido, no `after_move` (DEC-0041). O GRAPPLE entrou na TASK-10.6, comprometido também: o disparo acontece no `after_move`, a puxada começa no `before_move` quando o cabo voou, de qualquer modo, e só as três solturas a terminam, no `before_move`. O contato não troca o modo durante a puxada (DEC-0041 §3).
- **Hierarquia como função:** `is_grounded(mode)` e `is_airborne(mode)`.
- **Combate em paralelo (fase 2):** um segundo modo, `action`, com NONE, WINDUP, ACTIVE, RECOVERY, BLOCK e PARRY. Correr enquanto golpeia não multiplica estados. "No ar ninguém se defende" vira uma regra entre os dois modos, e é ali que a matriz de posição da Q-14 vai morar.
- **Animação e efeito:** trocam no `NetworkTime.after_tick_loop`, comparando o modo desenhado com o do estado. Assim nunca tocam duas vezes num rollback. É o mesmo sinal que a `RewindableStateMachine` usa por dentro (`addons/netfox/network-time.gd`; `addons/netfox.extras/state-machine/rewindable-state-machine.gd`, commit `cf5189d`). Não existe barramento de eventos (F-007 §8).
- **Os sinais das manobras** são os primeiros assim (TASK-10.4): o `ManeuverCues` (`fighter/maneuver_cues.gd`), criado pelo `Match`, lê o estado exibido depois de cada laço de ticks e toca a baforada do pulo duplo e o rastro do dash uma vez por chave (lutador, tipo, carimbo): o `double_jump_tick`, e o `dash_tick` enquanto o modo é `DASH`. Desde a TASK-10.5, a marca do pulo da parede, um disco em pé na parede, pelo `wall_jump_tick`, durante o voo que ele começou (`AIR` desde o carimbo). Desde a TASK-10.6, o cabo do gancho, uma linha opaca de 3 cm do ombro exibido à ponta, pelo `grapple_fired_tick` enquanto o cabo está no ar, e o rastro curto da puxada, pelo `mode_since` enquanto o modo é `GRAPPLE` (`visual-e-audio.md`, "O gancho na tela"). A chave que já tocou não toca de novo quando o rollback refaz o tick, e o sinal nunca se desfaz (DEC-0031 §6). Ele também conta os eventos que os ticks novos produzem, e a SyncTest exige que os sinais apresentados sejam iguais aos eventos (`rede.md` §4).
- **Por que não a `RewindableStateMachine`:** ela é plana, grava só o nome do estado e põe a regra num nó por estado (`addons/netfox.extras/state-machine/rewindable-state-machine.gd`, commit `cf5189d`). A regra presa em nó também não acompanharia o núcleo se ele mudasse de linguagem (DEC-0020).

## O tempo e a física no estado (DEC-0022)

- **Carimbo, não contagem:** o estado guarda o tick em que algo aconteceu (`buffered_tick = 1040`), como o "flash 12:30" no chat do LoL. A regra calcula `tick - buffered_tick <= buffer_ticks` (a janela é inclusiva, DEC-0039). O netfox só manda o que mudou, porque o diff de estado vem ligado (`netfox/rollback/enable_diff_states` em `addons/netfox/netfox.gd`, commit `cf5189d`), e o carimbo muda uma vez.
- **Ms para tick:** o tick mais próximo, e o empate sobe. Um teste falha se o erro passar de meio tick.

| Tempo do design | A 30 ticks | A 60 ticks |
|---|---|---|
| Coyote, 100 ms | 3 ticks (100 ms) | 6 ticks (100 ms) |
| Buffer, 150 ms | 5 ticks (167 ms, +11 %) | 9 ticks (150 ms) |
| Janela de parry, 80 ms (leitura do v0) | 2 ticks (67 ms, −17 %) | 5 ticks (83 ms, +4 %) |
| Esquiva invulnerável, 250 ms | 8 ticks (267 ms, +7 %) | 15 ticks (250 ms) |

- **Física derivada para o tick:** a configuração calcula velocidade e gravidade já sabendo o tamanho do tick. Com a fórmula contínua, o pulo de 1,2 m chegaria a 1,09 m a 30 ticks e a 1,14 m a 60. Um teste garante 1,2 m, com tolerância de 1 cm, nas duas taxas.
- **A configuração nasce na carga:** o `Match` carrega o `.tres`, em ms e metros, e cria o `MovementConfig` uma vez, com o tickrate como parâmetro (F-018 §1). O núcleo nunca carrega arquivo.

## As cenas (DEC-0022; aprovadas no plano, F-022)

```
Fighter                    o lutador (CharacterBody3D, script fino)
├── Collision              a cápsula de 1,8 m × 0,35 m
├── Input                  o input do dono (FighterInput)
├── RollbackSynchronizer   do netfox: grava as caixas a cada tick
├── TickInterpolator       do netfox: suaviza o desenho entre ticks
└── Visual                 o boneco; só lê o estado
```

```mermaid
flowchart TB
  main["Main<br/>a entrada: servidor dedicado, cliente ou sozinho (DEC-0026)"] --> match["Match<br/>carrega a configuração e cria tudo"]
  match --> arena["Arena<br/>blocos de 1, 2 e 3 m; pontos de nascimento;<br/>a régua do dash; as torres e o pilar do gancho"]
  match --> fighters["Fighter × N<br/>2 no 1v1, 16 no 8v8"]
  match --> cam["CameraRig<br/>só para o lutador de quem joga"]
  match --> hud["Hud<br/>só com tela: a stamina, o modo, as recargas<br/>do dash e do gancho e a mira"]
  match --> cues["ManeuverCues<br/>os sinais das manobras; desenham só com tela"]
```

O **HUD** só existe com tela. O `Match.watch` o cria para o lutador de quem joga quando o `DisplayServer` não é o `headless`, a mesma conferência da `Main`; o servidor dedicado e as rodadas sem tela, como o portão, nunca o criam. A cada quadro ele lê o estado exibido e o tick do netfox e calcula a barra pelo `Stamina.at`, sem timer próprio, então um rollback que reescreve o estado reescreve a barra junto (F-051 §3.4; TASK-10.2). Desde a TASK-10.4, ele mostra também o arco da recarga do dash, com os décimos de segundo que faltam, calculados do `dash_tick` e do tick (`visual-e-audio.md`). Na TASK-10.5, o modo ganhou o texto da corrida na parede, "Na parede" (`HUD_MODE_WALL_RUN`). Na TASK-10.6, ganhou o da puxada, "No gancho" (`HUD_MODE_GRAPPLE`), a linha da recarga do gancho acima da do dash, com o mesmo anel e os décimos calculados do `grapple_end_tick`, e a mira no centro da tela. A mira lança um raio só da tela, do ombro exibido, pela câmera que o `Match` entrega ao HUD no `watch` e no `view`, e ganha o ponto quando o Q prenderia agora. Ela lê `Movement.can_grapple` e `Movement.in_reach` e nunca escreve o estado (`visual-e-audio.md`, "O gancho na tela").

Os caminhos do netfox, como `Input:jump` e `:state:mode`, seguem a árvore de cena, como as rotas de uma API. Mudar a árvore depois quebra todas as rotas juntas; por isso a árvore se decide agora.

## Os autoloads (DEC-0022)

Nenhum nosso; só os 14 que o netfox traz, como o `NetworkTime` (`AUTOLOADS` em `addons/netfox/netfox.gd` e em `addons/netfox.extras/netfox-extras.gd`, commit `cf5189d`). Eles ficam listados à mão no `project.godot`, com caminho `res://`, porque o plugin os registraria com `uid://` e quebraria o primeiro import (#659). O teste de configurações guarda o mapa exato, e falha também se aparecer um autoload nosso (DEC-0023). Uma variável global fica fora das caixas e não volta no tempo no rollback. A configuração é passada à mão, como prop drilling no React. Um autoload futuro, como as preferências do jogador, só entra com DEC própria e se nunca for lido dentro do tick.

## As pastas (DEC-0005; nomes da DEC-0022, aprovados no plano, F-022)

```
core/fighter/   estado, input do tick, fatos, regras e a configuração do lutador
core/time/      ms para tick
common/         código compartilhado
data/           os .tres e as classes deles (movement_data.gd e movement_v0.tres)
assets/         arte e áudio, no LFS, com CREDITS.md
addons/         gdUnit4 e o netfox (core, extras e internals; DEC-0023)
fighter/        a cena do lutador, o FighterInput, o CameraRig, os sinais das manobras e o bot de teste
arena/          a arena e os blocos
match/          a partida
main/           a Main, os argumentos, o arquivo de parada e a medição de fps
net/            o aperto de mão, a sala e o gravador da corrida de 30 s
ui/             o HUD, o Theme único e os textos da tela, por chave de tradução
test/           espelha o código: test/core/fighter/...; a referência em test/reference/
tools/          o portão, as checagens e os scripts de rede, de build e de release
```

Na raiz, o `Dockerfile` é a receita da imagem do servidor (DEC-0032 §1; `rede.md` §10).

O **jogador** é a pessoa; o **lutador** é o boneco, que também pode ser de um bot. É a diferença entre o invocador e o campeão no LoL.

## A tipagem (DEC-0005, DEC-0022)

- Declaração sem tipo e acesso inseguro são erro no projeto todo. É o `strict` do TypeScript. Os addons ficam de fora pelo `directory_rules`.
- **O furo do portão fechou:** antes, ele só pegava esses erros num script que algum teste carregasse. Desde a TASK-6, o passo "compilar tudo" carrega todos os nossos scripts numa execução só do Godot, em uns 4 s (F-049 §5), e os canários provam a cada rodada que ele ainda barra (F-039; DEC-0027).

## O que o Desenho 3 provou (TASK-5)

O Desenho 2 leu o netfox no código-fonte, na `main`, commit `cf5189d` (26/09/2026), sem instalar. O Desenho 3 o rodou no 4.7.2 e o pôs em `addons/` (DEC-0023).

| O que se apoia no netfox | Arquivo que confirma (commit `cf5189d`) | Situação |
|---|---|---|
| Cada propriedade é gravada por valor: lê com `get_indexed`, restaura com `set_indexed` | `addons/netfox/servers/data/snapshot.gd` | Confirmado no código |
| O caminho `:state:mode` lê o campo de dentro do objeto `state` | `addons/netfox/servers/data/property-pool.gd`; `addons/netfox/properties/property-entry.gd` | Confirmado no código |
| O estado é restaurado antes de cada tick re-simulado e gravado depois | `addons/netfox/rollback/rollback-synchronizer.gd` | Confirmado no código |
| `_rollback_tick(delta, tick, is_fresh)`, na ordem da árvore de cena | `addons/netfox/servers/rollback-simulation-server.gd` | Confirmado no código |
| O input é capturado uma vez por loop de ticks; o toque vale um tick | `docs/netfox/tutorials/input-gathering-tips-and-tricks.md` | Confirmado na documentação |
| A `RewindableStateMachine` é plana e grava só o nome | `addons/netfox.extras/state-machine/rewindable-state-machine.gd` | Confirmado no código |

**As três hipóteses do Desenho 2, testadas com o netfox rodando no 4.7.2.** O método, os números e o que sobrou estão no `rede.md` §4.

| Hipótese | Resultado |
|---|---|
| 1. O caminho aninhado `:state:mode` grava, restaura e vai pela rede | **Provada:** 0 divergências na SyncTest com os campos envenenados, e 349 de 349 pulos pela rede (F-025 §2; F-026 §3) |
| 2. O contorno do transform deixa um lutador colidir com o outro na posição certa ao refazer | **Provada, com o contorno:** de 786 para 6 divergências a 30 ticks, e de 1.897 para 32 a 60. As que sobram são de um lutador em pé na cabeça do outro (F-025 §3; Q-16) |
| 3. Guardar `on_floor` no estado substitui o movimento extra de velocidade zero | **Derrubada:** o `move_and_slide()` guarda o próprio "estava no chão". O contorno D zera as divergências e substitui essa hipótese (F-025 §4; DEC-0025) |
