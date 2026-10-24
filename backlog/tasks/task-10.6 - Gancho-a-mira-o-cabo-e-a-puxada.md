---
id: TASK-10.6
title: 'Gancho: a mira, o cabo e a puxada'
status: In Progress
assignee: []
created_date: '2026-10-19 13:47'
updated_date: '2026-10-24 20:16'
labels:
  - jogo
milestone: m-1
dependencies:
  - TASK-10.5
  - TASK-10.10
parent_task_id: TASK-10
ordinal: 17000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
O gancho é a manobra de longo alcance (`movimento.md`, "Gancho") e a primeira regra que pergunta ao cenário de dentro do tick: um raio, só quando a regra pede (DEC-0044). O `pitch` entra no input junto com o `grapple`, e o empate do buffer fica completo: pulo, dash, gancho. A simulação da abertura mostrou que puxar o ombro faz a travessia bater na parede da torre; a v0 leva os pés ao ponto (vitrine "A puxada do gancho"; F-141). O gancho nasce com o seu sinal na tela (F-139), e a Q-35 entra junto.

### Perguntas em aberto
Nenhuma.

### Escolhas a confirmar
1. A tecla. Confirmada pelo Arthur em 24/10/2026 (F-140 §1): **o Q, por posição física**. Os botões do mouse ficam para o combate da fase 2.
2. O pedido de mira. Confirmado no plan mode (F-141; DEC-0044): no tick em que há um Q válido na vaga, o núcleo liga `aim_request`, e o nó lança o raio do ombro depois do movimento, só contra o cenário, com o acerto nos fatos.
3. A altura da mira. Confirmada no plan mode (F-141; DEC-0044): `aim_height_m` = 1,6 m no `MovementData`, cópia do pivô da câmera, com um teste de igualdade com o `camera_v0.tres`.

### Números v0 do Claude
Fechados pelo Claude (DEC-0017) e escritos no `movimento.md` ("Gancho", "Perdão", "Corrida na parede", "Métricas de nível") e no `visual-e-audio.md` ("O gancho na tela") com o plano aprovado (F-141). Mudaram do rascunho:
- os pés vão ao ponto, e a soltura a 1,5 m conta dos pés;
- o alcance vai de 3 a 25 m, medido do ombro;
- o pulo na puxada só solta, e o pulo duplo fica para o próximo aperto;
- sair do chão puxado não abre o coyote, e a parede ganha a mesma correção (Q-35);
- o dash espera na vaga com o cabo voando;
- o raio passa pelos lutadores e prende no cenário.

### Fora do escopo
- Puxar outro jogador, e o que um lutador na frente da mira faz: o raio passa por ele (combate, fase 2).
- Balançar no cabo. O gancho como opção do slot utilitário (F-001). Mirar com deslocamento de ombro. O som do cabo (Q-32).
- Agarrar a borda (mantle): continua fora do v0 (`movimento.md`), e volta se o protótipo mostrar o "quase subi".
- O raio em ticks previstos online (fase 3: um tick previsto reaproveita o último input, e um `grapple` de um toque dispararia de novo; DEC-0044).
- O bot que usa o gancho na rede (TASK-10.8).

### O que você vai aprender
- O pedido de mira: o núcleo puro pede o raio, e o nó, que conhece o motor, pergunta ao cenário (DEC-0044).
- O ângulo no input: por que o `pitch` entra pela última amostra, como o `yaw`.
- Pitch e yaw virando uma direção 3D, como a mira do CoD.
- Por que o ponto do corpo que a puxada leva decide onde você termina.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando a sonda do motor lança o raio de 25 m de dentro do tick, só contra o cenário, o resultado (acertou, ponto, normal, caminho do colisor) sai igual no tick novo, no refeito pelo rollback de 7 ticks e num quadro de processo, contra uma parede de teste e contra o céu; a sonda falha se não houver um acerto e um erro, e anota o tempo de 1000 raios (DEC-0044 §4; `rede.md` §4; DEC-0025)
- [ ] #2 Quando o jogador mira, o input leva o `pitch` (a última amostra da câmera, de −80° a 80°, positivo para cima) e o `grapple` (um toque, no Q por posição física); a direção da mira é `Aim.direction(yaw, pitch)`, e o raio sai do ombro, 1,6 m acima dos pés (`aim_height_m`, igual ao pivô do `camera_v0.tres` por teste), só contra o cenário; o netfox grava os dois, e o replay ganha as duas colunas: um arquivo da TASK-10.3 ainda toca com `--force`, com as colunas que faltam no valor padrão (F-140 §1; DEC-0044; DEC-0026 §1; DEC-0027 §5)
- [ ] #3 Quando o lutador aperta o gancho com a recarga livre, fora do dash e sem outro gancho no ar, e a mira acha o cenário de 3 a 25 m do ombro, o cabo voa 100 ms (6 ticks a 60, 3 a 30) e prende no ponto fixado no tick do disparo; a 2,99 m, a 25,01 m ou contra o céu, nada acontece, a recarga não conta, e o aperto fica na vaga, com a mira refeita a cada tick, até a janela de 150 ms fechar (`movimento.md`, "Gancho"; DEC-0039)
- [ ] #4 Quando o cabo prende, o núcleo puxa o lutador a 18 m/s com os pés rumo ao ponto, recalculado a cada tick, sem gravidade e sem input; com os pés a 1,5 m do ponto, solta e conserva a velocidade; a partir do segundo tick da puxada, quando a velocidade rumo ao ponto fica abaixo de 9 m/s (50% da puxada, `grapple_block_pct`), solta (`movimento.md`, "Gancho")
- [ ] #5 Quando o lutador aperta o pulo durante a puxada, o gancho solta conservando a velocidade, sem impulso e sem custo, e o aperto se gasta na soltura: o próximo aperto no ar é o pulo duplo, se houver e com stamina; um pulo apertado enquanto o cabo voa segue as regras do modo e não solta; quando pulo, dash e gancho chegam no mesmo tick, vale o pulo, depois o dash, depois o gancho, e um aperto posterior substitui o guardado (`movimento.md`, "Gancho" e "Perdão"; DEC-0039 §4)
- [ ] #6 Quando o gancho solta, o próximo só sai 6 s depois (360 ticks a 60, 180 a 30), e um aperto na recarga espera na vaga pelos 150 ms e some; o gancho sai do chão, do ar e da parede, onde a corrida acaba no disparo, e não sai no dash, com o cabo voando nem na puxada; o dash espera na vaga enquanto o cabo voa; sair do chão puxado não abre o coyote (`movimento.md`, "Gancho"; DEC-0016; DEC-0041)
- [ ] #7 Quando uma corrida na parede começa dentro dos 100 ms do coyote do chão e termina, o primeiro aperto no ar é o pulo duplo, não o pulo cheio: entrar na corrida zera o coyote do chão (`movimento.md`, "Corrida na parede": "O coyote do chão na entrada"; Q-35)
- [ ] #8 Quando a SyncTest roda o cenário do gancho com o rollback de 7 ticks a cada tick, refazendo o raio em cada tick refeito, ela acha zero divergências no estado inteiro, e esconder `:state:grapple_point` do netfox faz ela acusar; o cenário tem soltura pela distância, pelo pulo e pela trava, um erro e uma recusa na recarga; o sinal do cabo e o da puxada tocam uma vez por chave; a gravação de um gancho refaz o mesmo rastro de estado (`rede.md` §8; DEC-0031 §6; DEC-0027 §5)
- [ ] #9 Quando o Arthur aperta Q no Sozinho, ele se puxa até as torres e o pilar; a mira ganha o ponto quando o Q prenderia agora, o cabo aparece do ombro ao ponto, o rastro curto acompanha a puxada, e o HUD mostra "No gancho" e a recarga com o anel e os décimos, tudo lido do estado ou só da tela; as torres e o pilar ficam longe da referência e da SyncTest; o que ele sentiu vai para uma fonte (`visual-e-audio.md`, "O gancho na tela"; DEC-0031 §2; F-139; F-041)
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
# TASK-10.6 — O gancho: o plano para o seu ok

## Contexto

O gancho é a manobra de longo alcance do `movimento.md` e a primeira consulta ao cenário feita de dentro do tick: um raio, só quando a regra pede. O rascunho de 19/10 puxava o **ombro** até o ponto. A simulação de hoje mostrou que, assim, a travessia de torre para torre bate na parede da torre B, com os pés a 4,5 m, e que do chão quase nunca se sobe numa torre de 6 m a partir de 10 m de distância. A v0 nova leva os **pés** ao ponto: você cai onde mira. Vitrine: [A puxada do gancho](https://claude.ai/artifact/GF5agTV2hMTxLvyz6HKSJa).

Já decidido nesta sessão: o gancho no **Q**, por posição física (F-140 §1); a conferência aberta (DEC-0043). Você acertou que o núcleo pede o raio porque é puro e não enxerga o cenário.

## As duas escolhas de arquitetura (para o seu ok)

| Escolha | O que se ganha | O que se perde | A alternativa |
|---|---|---|---|
| **1. O pedido de mira.** No tick em que há um Q válido na vaga, o `before_move` liga `MovePlan.aim_request`. Depois do movimento, o nó lança o raio do ombro, só contra o cenário, e devolve `aim_hit`, `aim_point` e `position` no `MoveFacts`. O `after_move` decide se prende | Um sanduíche só (DEC-0004, regra 2). O servidor refaz o raio ele mesmo, sem confiar num ponto mandado pelo cliente. Um raio só por aperto válido | O núcleo depende de o nó fazer a pergunta certa: a sonda B e a SyncTest provam | O raio no `_process`, com o acerto no input: o servidor teria que confiar no cliente (DEC-0026 §1). É a reserva, se a sonda B falhar, e volta para você antes |
| **2. A altura da mira.** `aim_height_m` = 1,6 m fica no `MovementData`, cópia do pivô da câmera, com um teste que exige a igualdade com o `camera_v0.tres` | O núcleo e o servidor, que não tem câmera, leem a altura junto dos outros números do movimento | O número mora em dois arquivos; o teste pega a diferença | O `MovementConfig.create` derivar do `CameraData`: uma fonte só, mas o movimento passa a depender da câmera |

Com o seu ok, as duas viram a **DEC-0044** ("O pedido de mira e a altura da mira"), com a sonda B antes de qualquer regra, como a sonda A da parede (DEC-0042 §4). A TASK-10.10 já mediu o raio da cabeça com 0 divergência no rollback; a sonda B confirma para o raio longo, de 25 m, e mede o custo.

## Os números v0 do Claude (vão para o `movimento.md` antes do test-writer)

Não mudam: 25 m, o cabo de 100 ms (6 ticks a 60, 3 a 30), 18 m/s sem gravidade e sem input, a soltura a 1,5 m, a trava abaixo de 9 m/s (50%) a partir do 2º tick da puxada, a recarga de 6 s contada da soltura (360 ticks a 60), sem custo, do chão, do ar e da parede (a corrida acaba no disparo), velocidade conservada.

| O que muda | Rascunho | Leitura v0 | Por quê |
|---|---|---|---|
| O que vai ao ponto | o ombro | **os pés** (a soltura a 1,5 m conta dos pés) | Você cai onde mira; com o ombro, a travessia bate na parede |
| Alcance | até 25 m | **de 3 a 25 m**, medido do ombro | Encostado numa parede, mirando reto, os pés subiriam 8 m. Mais perto que 3 m é erro: nada acontece e a recarga não conta |
| O pulo na puxada | solta e já sai o pulo duplo | **só solta**, conservando a velocidade; o pulo duplo fica para o próximo aperto. Um pulo apertado enquanto o cabo voa não solta | O pulo duplo troca a vertical por 6,1 m/s: puxado para cima a 12,7 m/s, subiria 1,0 m em vez de 4,1 + 1,0 |
| Coyote | não dito | **não existe**: sair do chão puxado não abre o coyote | "A mesma regra vale em todo lugar"; a parede ganha a mesma correção (Q-35) |
| O dash com o cabo voando | não dito | **espera na vaga** | Um modo comprometido por vez (DEC-0041) |
| Lutador na mira | "nada acontece" | **o raio passa por ele** e prende no cenário | O raio só pergunta ao cenário, como o da parede; puxar gente fica para o combate |

O erro (céu, além de 25 m, aquém de 3 m) não gasta a recarga: o aperto espera na vaga pelos 150 ms, e o raio é refeito a cada tick, com a mira daquele tick. No mesmo tick, o pulo vence o dash, que vence o gancho.

## O sinal na tela (F-139; vai para o `visual-e-audio.md`)

- **A mira:** um anel de 24 px na base de 1080p, no centro, branco com contorno escuro. Ganha um ponto de 5 px quando o Q prenderia agora: um raio só da tela acha cenário de 3 a 25 m, e o gancho está livre.
- **O cabo:** uma linha de 3 cm no tom do lutador, do ombro à ponta. Nos 100 ms de voo, a ponta vai do ombro ao ponto; na puxada, fica esticada; na soltura, some.
- **A puxada:** o rastro curto da corrida na parede acompanha o corpo e some em 200 ms depois da soltura.
- **O HUD:** "No gancho" ("Grappling") na puxada; uma linha acima da do dash com um anel igual ao dele e "Gancho 5,9 s", em décimos, cheio na soltura e vazio quando volta.
- Tudo só na tela, fora do estado, uma vez por chave (DEC-0031 §6), sem arte nova (DEC-0029).

## A arena ("Métricas de nível")

`TorreA` (−8, 3, −30) e `TorreB` (12, 3, −30), de 4 × 6 × 4 m, com 16 m entre as faces (mais que os ≈ 7 m do pulo duplo); `Pilar10m` (2, 5, −36), de 2 × 10 × 2 m. Em chão livre, longe da referência e da SyncTest, com teste de cena. O pilar pode escorregar para a TASK-10.7 se a rodada C estourar; o cabo não, porque é o sinal.

## Os critérios de aceite (reescritos na task)

1. **A sonda B:** o raio de 25 m de dentro do tick sai igual no tick novo, no refeito e num quadro de processo; falha sem um acerto e um erro; anota o tempo de 1000 raios.
2. **A mira no input:** `pitch` (última amostra, ±80°, positivo para cima) e `grapple` (um toque, Q físico); `Aim.direction(yaw, pitch)`; o raio do ombro (`aim_height_m`, igual ao pivô por teste); o netfox grava os dois; o replay ganha as colunas, e um arquivo da TASK-10.3 toca com `--force`.
3. **O disparo e o erro:** de 3 a 25 m, com a recarga livre, fora do dash e sem outro gancho, o cabo voa 100 ms e prende no ponto fixo; a 2,99 m, a 25,01 m ou no céu, nada acontece e o aperto espera na vaga.
4. **A puxada e a soltura:** os pés rumo ao ponto a 18 m/s; solta com os pés a 1,5 m, ou abaixo de 9 m/s a partir do 2º tick, conservando a velocidade.
5. **O pulo e o empate:** o pulo na puxada só solta; o próximo aperto no ar é o pulo duplo; o pulo com o cabo voando não solta; pulo > dash > gancho no mesmo tick.
6. **Recarga, modos e coyote:** 6 s da soltura; o aperto na recarga espera 150 ms e some; sai do chão, do ar e da parede; não no dash nem com outro gancho; o dash espera com o cabo voando; sem coyote da puxada.
7. **A Q-35:** entrar na parede zera o coyote do chão; depois de uma corrida curta, o aperto no ar é o pulo duplo.
8. **A SyncTest:** cenário "gancho" com 0 divergência, o raio refeito em cada tick refeito, soltura pela distância, pelo pulo e pela trava, um erro e uma recusa; esconder `:state:grapple_point` acusa; o cabo e a puxada tocam uma vez por chave; a gravação de um gancho refaz o mesmo rastro.
9. **Na tela e no jogo:** você se puxa até as torres e o pilar no Sozinho, vê a mira, o cabo, o rastro e o HUD, e o que sentir vai para uma fonte.

## Os arquivos

- **Núcleo (`core/fighter/`):** `movement.gd` (o pedido, a puxada, a soltura, sem coyote do gancho, a Q-35 em `_enter_wall`), `fighter_state.gd` (`Mode.GRAPPLE`, `grapple_fired_tick`, `grapple_point`, `grapple_end_tick`), `tick_input.gd`, `move_plan.gd`, `move_facts.gd`, `fighter_command.gd`, `movement_config.gd`, `aim.gd` (novo).
- **Dados:** `data/movement_data.gd` e `movement_v0.tres` (7 campos do gancho e o `aim_height_m`), `test/reference/frozen_movement.tres` (os mesmos, sem mudar o rastro da referência).
- **Adaptador:** `fighter/fighter.gd` (o raio no pedido; `Fighter.covers_body` é o modelo), `fighter.tscn` (os caminhos do netfox), `input_sampler.gd`, `fighter_input.gd`, `maneuver_cues.gd` (o cabo e a puxada; o `Trail` curto reaproveitado), `bot_player.gd` (`aim_at`).
- **Tela:** `ui/hud.gd` (a mira, a linha da recarga, o modo), o Theme, as traduções pt-BR e en.
- **Projeto:** `project.godot`, `[input]`: a ação `grapple` no Q físico (81), porque as teclas são físicas (DEC-0031 §8) e você escolheu o Q; o `project_settings_test.gd` ganha a linha.
- **Arena:** `arena/arena.tscn` (as torres e o pilar).
- **Testes:** `movement_grapple_test.gd` e `aim_test.gd` (test-writer, travados); a sonda B em `engine_probe_test.gd`; o cenário "gancho" na `fighter_sync_test.gd`; o replay; o HUD e os sinais.
- **Docs:** antes do test-writer, `movimento.md` ("Gancho", "Perdão", "Corrida na parede", "Métricas de nível"), `visual-e-audio.md` ("O gancho na tela"), `glossario.md` (Mira, Cabo, Ponto do gancho, Puxada, Pedido de mira, Alcance mínimo), `pendencias.md` (Q-35) e `mudancas.md`. No fechamento: `rede.md` §3, §4 e §8, `visao-geral.md`, `testes-e-entrega.md`, a vitrine "Kit de movimento v0".

## A ordem e os agentes

1. Na main: a DEC-0044, a fonte do seu ok, os docs de desenho e a task em português, Ready. Depois a branch `task-10.6-grapple`.
2. O test-writer escreve os critérios 3 a 7 e a metade do `Aim` do 2, cego ao código; eu travo.
3. O implementer: rodada A (a sonda B, os inputs, o Q, os dados); se a sonda falhar, paro e trago a você. Rodada B (o núcleo, o adaptador, os sinais, o HUD, a SyncTest). Rodada C (a arena, os docs, o `net_run.sh`).
4. O revisor, o portão e você jogando. Push, PR e merge, cada um com o seu ok.

| Agente | Modelo | Effort | Por quê |
|---|---|---|---|
| test-writer | Fable | high | as regras de soltura e o empate em ticks exatos, cego ao código |
| implementer | Opus 5.5 | xhigh | um raio dentro do rollback, dois inputs, a mira e a SyncTest; Fable a partir da rodada 4 |
| reviewer | Fable | high | o raio dentro do tick precisa da sonda como prova |

Sem explorer: já mapeei a câmera, o sampler e o sanduíche.

## Como verificar

- `bash tools/gate.sh` verde, com a sonda B, os testes travados e o cenário "gancho" com 0 divergência e o veneno acusando.
- `tools/net_run.sh` no fechamento (o bot ainda não usa o gancho online).
- Você no Sozinho: prender no topo de uma torre a menos de 25 m; cruzar os 16 m mirando o topo da torre B; subir do chão mirando a face logo abaixo da borda; soltar cedo com o pulo e dar o pulo duplo; subir o pilar; ver a mira ganhar o ponto e o cabo aparecer; esperar os 6 s.
- O que sentir: se a puxada a 18 m/s tem peso; se cair onde mira parece certo; se os 6 s frustram; se o Q cai na mão.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Contract for the agents, from the approved plan (F-141; DEC-0044). It supersedes the draft of 19/10/2026, which pulled the shoulder to the point and fired the double jump on the release.

**State** (`FighterState`): `Mode.GRAPPLE = 4`, a committed mode (DEC-0041). `grapple_fired_tick: int = NEVER`: the tick the hook bit, NEVER while no grapple is in the air (`:state:grapple_fired_tick`). `grapple_point: Vector3 = ZERO`: fixed on the fire (`:state:grapple_point`). `grapple_end_tick: int = NEVER`: the last release; the cooldown counts from it (`:state:grapple_end_tick`). `copy()` copies the three. `FighterCommand.GRAPPLE := &"grapple"`.

**Input** (`TickInput`): `pitch: float` (rad, positive up; the camera clamps it to ±80°; the last sample, `Input:pitch`) and `grapple: bool` (one touch, `Input:grapple`). `InputSampler.add_frame(move, yaw, pitch := 0.0)` keeps the last pitch; `press_grapple()` and `take_grapple()`. `FighterInput.sample_frame(frame_move, frame_yaw, frame_pitch := 0.0)` and `press_grapple()`; it samples `_camera.pitch`. The InputMap action `grapple` is the physical Q (81), guarded by `test/project_settings_test.gd`.

**Aim** (`core/fighter/aim.gd`): `class_name Aim`; `static func direction(yaw: float, pitch: float) -> Vector3` returns `Basis(Vector3.UP, yaw) * Vector3(0.0, sin(pitch), -cos(pitch))`, a unit vector: yaw 0 and pitch 0 give (0, 0, -1); yaw +90° gives (-1, 0, 0); pitch +45° gives (0, 0.7071, -0.7071).

**Plan and facts**: `MovePlan.aim_request: bool`, false by default. `MoveFacts.position: Vector3` (the feet after the move, always filled), `aim_hit: bool` and `aim_point: Vector3` (filled only when the plan asked; otherwise false and ZERO).

**Data** (`MovementData`, group "Grapple"): `grapple_range_m = 25.0` (positive); `grapple_min_range_m = 3.0` (not negative, below the range); `grapple_attach_ms = 100` (a time, may be 0); `grapple_pull_speed_mps = 18.0` (positive); `grapple_release_distance_m = 1.5` (positive, below the range); `grapple_block_pct = 50.0` (0 to 100); `grapple_cooldown_ms = 6000` (a time, may be 0); `aim_height_m = 1.6` (positive; a data test asserts it equals `camera_v0.tres` `pivot_height_m`). The same fields go into `test/reference/frozen_movement.tres` without changing the reference trace.

**Config** (`MovementConfig`): `grapple_range`, `grapple_min_range`, `grapple_attach_ticks` (6 at 60, 3 at 30), `grapple_pull_speed`, `grapple_release_distance`, `grapple_block_speed` (pull × pct / 100 = 9 m/s), `grapple_cooldown_ticks` (360 at 60, 180 at 30), `aim_height`.

**Rules** (`movimento.md`, "Gancho"):
- The slot is written in the order grapple, dash, jump, so a tie leaves the jump, then the dash, then the grapple (DEC-0039 §4).
- A grapple press can fire when the mode is neither DASH nor GRAPPLE, `grapple_fired_tick == NEVER` (no cable in the air) and `tick - grapple_end_tick >= grapple_cooldown_ticks` (NEVER counts as free). Then `before_move` sets `plan.aim_request = true` on every tick the press waits in the slot (DEC-0039's 150 ms, inclusive), a wall run included.
- `after_move` fires on a tick whose plan asked, when `facts.aim_hit` and `grapple_min_range <= |facts.aim_point - (facts.position + UP * aim_height)| <= grapple_range`: `grapple_fired_tick = tick`, `grapple_point = facts.aim_point`, the slot clears, and a WALL_RUN ends (mode AIR, `mode_since = tick`). A miss (no hit, or a distance outside 3 to 25 m) changes nothing: the press stays while its window lives, and the cooldown does not count.
- The cable flies `grapple_attach_ticks`. Meanwhile the body follows its mode's rules: a jump fires as usual, and a dash press waits in the slot (`_can_dash` also needs `grapple_fired_tick == NEVER`).
- The pull starts in `before_move` on the first tick with `tick - grapple_fired_tick >= grapple_attach_ticks`, ending whatever mode the body is in: mode GRAPPLE, `mode_since = tick`. On every pull tick, `velocity = (grapple_point - position).normalized() * grapple_pull_speed`: the feet go to the point, with no gravity and no input.
- The release is checked in `before_move` at the start of every attached tick, the pull's first included: (a) a jump in the slot pressed on or after the pull's first tick (`buffered_tick >= mode_since`) releases and is spent there (the slot clears, and no jump comes out); (b) `position.distance_to(grapple_point) <= grapple_release_distance`; (c) from the pull's second tick (`tick - mode_since >= 1`), `velocity.dot((grapple_point - position).normalized()) < grapple_block_speed`, with the incoming velocity (the previous tick's, after the slide). Feet already within the release distance on the tick the pull would start release it without a pull tick.
- On the release: `grapple_end_tick = tick`, `grapple_fired_tick = NEVER`, mode GROUND if `state.on_floor` else AIR, `mode_since = tick`, and the same tick runs as a free tick on the incoming velocity (gravity in the air and the air control; the velocity is kept). A jump pressed while the cable flew that still waits does not release, by (a), and dies with its window.
- No coyote from the pull: `after_move` does not stamp `left_floor_tick` while the mode is GRAPPLE, and the contact never changes the mode during the pull (`by_contact` is false for DASH and GRAPPLE). Q-35: `_enter_wall` sets `left_floor_tick = NEVER`. The floor still renews the jumps during the pull.

**Adapter** (`Fighter`): after `move_and_slide()` and the wall contact, `facts.position = global_position`. When `plan.aim_request`, `intersect_ray` from `global_position + UP * config.aim_height` to that origin plus `Aim.direction(tick_input.yaw, tick_input.pitch) * config.grapple_range`, with the mask `PhysicsLayers.WORLD` and the own RID excluded (`covers_body` is the model), fills `aim_hit` and `aim_point`. It is cast again on every resimulated tick. `fighter.tscn` records the three state paths, `Input:pitch` and `Input:grapple`.

**Cues** (`ManeuverCues`): `Kind.GRAPPLE_CABLE`, keyed by `grapple_fired_tick` while it is not NEVER: the cable, 3 cm thick, opaque, unshaded, in the fighter's tone, from the displayed shoulder to a tip that reaches the point over `grapple_attach_ticks` counted in netfox ticks and stays there until the release. `Kind.GRAPPLE_PULL`, keyed by `mode_since` while the mode is GRAPPLE: the wall run's short `Trail`, at 40 %, fading 200 ms after the release.

**HUD**: the mode text `HUD_MODE_GRAPPLE` ("No gancho" / "Grappling"). A grapple cooldown row above the dash row: a 24 × 24 px arc like the dash's and "Gancho 5,9 s" (`HUD_GRAPPLE_COOLDOWN`, tenths rounded up), from `grapple_end_tick + grapple_cooldown_ticks - tick`; the row keeps its height while hidden. The reticle: a 24 px ring at the screen centre, 2 px stroke, white with a dark translucent outline, from the Theme; a 5 px dot when a presentation-only ray from the displayed shoulder, along the camera's yaw and pitch, finds the world from 3 to 25 m and the grapple can fire now (not DASH or GRAPPLE, no cable in the air, the cooldown over). Never in the state.

**Bot**: `BotPlayer.aim_at(point)` for the SyncTest scenario; the network route does not grapple yet.

**Arena**: `TorreA` (-8, 3, -30) 4 × 6 × 4; `TorreB` (12, 3, -30) 4 × 6 × 4, 16 m between the faces; `Pilar10m` (2, 5, -36) 2 × 10 × 2. A scene test keeps them off the reference route and the SyncTest scenarios.

**Who tests what**: the test-writer writes criteria 3 to 7 and the `Aim.direction` half of 2, blind, against `test/core/fighter/movement_rig.gd` extended with test-set aim facts (`aim_hit` and `aim_point`, reported only when `plan.aim_request`, with `facts.position`), plus the data rows (the new fields' checks and `aim_height_m` equal to `camera_v0.tres`); locked. The implementer writes 1 (probe B in `test/fighter/engine_probe_test.gd`: a test wall and the sky, fresh against resimulated with the 7-tick rollback against after a process frame; the result, hit, point, normal and collider path, equal; it fails without a hit and a miss; 1000 rays timed), the adapter half of 2 (the input, the key, the replay columns: a TASK-10.3 file plays with `--force`), 8 (the SyncTest scenario "gancho" on run-time geometry, fixture cooldown 500 ms; counters `grapple_fires >= 4`, `attaches >= 3`, `releases_by_distance >= 1`, `releases_by_jump >= 1`, `releases_by_block >= 1`, `misses >= 1`, `refused_grapples >= 1`, `cues_presented == cue_events`, 0 mismatches; poison `:state:grapple_point`; the replay session gains `pitch` and `grapple`) and 9 (the screen and the arena).

**Rounds**: A (probe B, the inputs, the key, the data and the config; stop and report if probe B finds a divergence); B (the core, the adapter, the cues, the HUD, the reticle, the SyncTest); C (the arena, the docs: `rede.md` §3, §4 and §8, `visao-geral.md`, `testes-e-entrega.md`; `net_run`). The pillar may slide to TASK-10.7; the cable may not (F-139).
<!-- SECTION:NOTES:END -->
