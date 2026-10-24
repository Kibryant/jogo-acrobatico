---
id: TASK-10.6
title: 'Gancho: a mira, o cabo e a puxada'
status: To Refine
assignee: []
created_date: '2026-10-19 13:47'
updated_date: '2026-10-24 17:29'
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
O gancho é a manobra de longo alcance (`movimento.md`, "Gancho") e a primeira consulta ao mundo de dentro do tick: um raio contra o cenário, só quando a regra pede. O `pitch` "nasce na fase 1" (`rede.md`:76) e entra no input com o `grapple`, o terceiro comando da vaga, fechando a ordem do empate (pulo > dash > gancho). A sonda B roda antes da regra e decide se o raio vive dentro do tick refeito como o jogo roda, em `_process` (DEC-0025; `rede.md` §4); se ela falhar, o raio sai do `_process` com o acerto no input, uma preocupação de confiança no servidor (DEC-0026 §1) que volta a você.

### Perguntas em aberto
Nenhuma; a sonda B decide se o raio vive dentro do tick.

### Escolhas a confirmar
1. O input ganha o `pitch` (última amostra, nunca média) e o `grapple` (um toque), e o gancho vai no Q, por posição física; os botões do mouse ficam para o combate. Padrão: sim, porque o Q fica sob o dedo que não corre e o mouse é a arma da fase 2 (DEC-0031 §8; DEC-0026 §1).
2. O raio da mira sai do nó só quando o núcleo pede (`MovePlan.aim_request`), depois do movimento, do pivô da câmera, só contra o cenário (`PhysicsLayers.WORLD`), e o `after_move` recebe o acerto nos fatos; o `before_move` passa a ler a posição que já recebe desde a TASK-10.1. Padrão: sim, porque mantém um sanduíche só (DEC-0004, regra 2) e uma consulta por aperto; é arquitetura e passa pelo modo de plano.
3. A altura da mira (`aim_height_m`, 1,6 m) fica no `MovementData` como cópia do pivô da câmera, com um teste de dados que exige igualdade com o `camera_v0.tres`; a alternativa é `MovementConfig.create(data, camera_data, tickrate)` derivar. Padrão: a cópia com o teste, porque o núcleo não lê o `CameraData` e um teste pega a divergência; é a regra 3 da DEC-0004 e passa pelo modo de plano.

### Números v0 do Claude
Fechados pelo Claude (DEC-0017); escritos em "Gancho" com o seu ok antes do test-writer rodar.
- A origem da mira é o pivô (posição + 1,6 m), pelo yaw e pelo pitch: com a câmera centralizada, o raio do pivô passa pelo centro da tela (`camera_rig.gd`:101-105).
- Prende em qualquer superfície parada do cenário; o erro (céu, além de 25 m, um lutador) não gasta a recarga e o aperto fica 150 ms na vaga.
- Dispara do chão, do ar e da parede (a corrida acaba); não no dash nem noutro gancho. O cabo voa 100 ms fixos; o ponto é fixado no disparo; o corpo segue as regras do seu modo enquanto o cabo voa.
- A puxada vai a 18 m/s rumo ao ponto, recalculada a cada tick, sem gravidade e sem input, a forma mais simples.
- Travado: solta abaixo de 50% da puxada (`grapple_block_pct`, 9 m/s) a partir do segundo tick de puxada, porque uma batida come mais da metade.
- O pulo solta conservando a velocidade, sem impulso nem custo, e o mesmo aperto vale como pulo no ar ("pular solta o gancho").
- A recarga de 6 s conta da soltura ("a mesma regra vale em todo lugar").
- A mira é um anel de 24 px na base de 1080p que ganha um ponto no centro quando um raio só de apresentação acha cenário a até 25 m (forma, não cor); o cabo é uma linha enquanto `grapple_fired_tick != NEVER`; o HUD mostra a recarga com arco e segundos. Vai para o `visual-e-audio.md`.
- Arena: `TorreA` e `TorreB` com 16 m entre as faces (mais que os ≈ 7 m do pulo duplo, dentro dos 25 m) e `Pilar10m` (de 8 m, o topo fica ≈ 11,6 m do pivô). Vai para "Métricas de nível".

### Fora do escopo
- Puxar outro jogador. Balançar no cabo. O gancho como opção do slot utilitário (F-001). Mirar com deslocamento de ombro. Som do cabo.
- O raio em ticks previstos online (fase 3: um tick previsto reaproveita o último input e um `grapple` de um toque dispararia de novo; nota ao lado da F-005 §4).

### O que você vai aprender
- Uma consulta ao mundo dentro do tick: o raio como um `SELECT` no cenário, e por que ele só roda quando a regra pede.
- O ângulo no input: por que o `pitch` não se tira pela média.
- Pitch e yaw virando uma direção 3D, como a mira do CoD.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando a sonda do motor lança um raio de 25 m de dentro do tick, só contra o cenário, o resultado (acertou, ponto, normal, caminho do colisor) sai igual no tick novo, no refeito e num quadro de processo, como o jogo roda; a sonda falha se não houver acerto e erro, e anota o tempo de 1000 raios (`rede.md` §4; DEC-0025; `PhysicsDirectSpaceState3D.xml`:62-74).
- [ ] #2 Quando o jogador mira, o input leva o `pitch` (a última amostra da câmera, de -80° a 80°, positivo para cima) e o `grapple` (um toque); a direção da mira é a do yaw e do pitch, e o raio sai 1,6 m acima dos pés (`aim_height_m`, igual ao pivô da câmera por teste), pela mira da tela, só contra o cenário; o netfox grava os dois e o replay ganha as duas colunas: um arquivo da TASK-10.3 ainda toca com `--force`, com as colunas que faltam no valor padrão (DEC-0026 §1; DEC-0027 §5).
- [ ] #3 Quando o lutador aperta o gancho com a recarga livre, fora do dash, e a mira acha uma superfície do cenário a até 25 m, o cabo voa 100 ms (6 ticks a 60, 3 a 30) e prende no ponto fixado no tick do disparo; a 25,01 m, contra o céu ou num lutador, nada acontece, a recarga não conta e o aperto fica na vaga (`movimento.md`, "Gancho").
- [ ] #4 Quando o cabo prende, o núcleo puxa o lutador a 18 m/s na direção do ponto, recalculada a cada tick, sem gravidade e sem input; ao chegar a 1,5 m do ponto, solta e conserva a velocidade; quando um obstáculo deixa a velocidade rumo ao ponto abaixo de 9 m/s (50% da puxada, `grapple_block_pct`), solta (`movimento.md`, "Gancho"; leitura v0).
- [ ] #5 Quando o lutador aperta o pulo durante o gancho, o gancho solta conservando a velocidade, sem impulso e sem custo, e o mesmo aperto vale como pulo no ar: o pulo duplo, se houver e com stamina; quando pulo, dash e gancho chegam no mesmo tick, vale o pulo, depois o dash, depois o gancho, e um aperto posterior substitui o guardado (`movimento.md`, "Princípios": "pular solta o gancho"; "Perdão", leitura v0 da ordem).
- [ ] #6 Quando o gancho solta, o próximo só sai 6 s depois (360 ticks a 60, 180 a 30); um aperto na recarga espera na vaga pelos 150 ms e some; o gancho sai do chão, do ar e da parede (a corrida acaba), e não durante o dash nem outro gancho (`movimento.md`, "Gancho"; DEC-0016).
- [ ] #7 Quando a SyncTest roda o cenário do gancho com o rollback de 7 ticks a cada tick, refazendo o raio em cada tick refeito, ela acha zero divergências no estado inteiro e esconder `:state:grapple_point` faz ela acusar; o cenário tem soltura pela distância, pelo pulo e pela trava, um erro e uma recusa na recarga; os sinais de prender e soltar tocam uma vez por chave; a gravação de um gancho refaz o mesmo rastro (`rede.md` §8; DEC-0031 §6; DEC-0027 §5).
- [ ] #8 Quando o Arthur aperta Q no Sozinho, ele se puxa até as torres e o pilar; a mira muda de forma (anel vazio, anel com ponto; 24 px, leitura v0) quando há superfície a até 25 m, o cabo aparece entre ele e o ponto, e o HUD mostra a recarga com um arco e os segundos, lidos do estado; o que ele sentiu vai para uma fonte (DEC-0031 §2; F-041).
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Rascunho do plano da fase 1 (19/10/2026), em inglês para os agentes; vira o plano em português quando a filha ficar Ready (F-100).

**State**: `Mode.GRAPPLE = 4`; `grapple_fired_tick: int = NEVER` (`:state:grapple_fired_tick`; set by `after_move` on a hit, NEVER on release), `grapple_point: Vector3 = ZERO` (`:state:grapple_point`), `grapple_end_tick: int = NEVER` (`:state:grapple_end_tick`; the cooldown counts from it); `FighterCommand.GRAPPLE := &"grapple"`. **Input**: `TickInput.pitch: float` (rad, positive up, ±80°, `Input:pitch`, last sample) and `grapple: bool` (one-touch, `Input:grapple`); `InputSampler.press_grapple()/take_grapple()` and a last-sample pitch; `FighterInput.press_grapple()`, reads `_camera.pitch`; `sample_frame(frame_move: Vector2, frame_yaw: float, frame_pitch := 0.0)`. InputMap `grapple` = `KEY_Q` physical (81). **Plan/Facts**: `MovePlan.aim_request: bool`; `MoveFacts.position: Vector3`, `aim_hit: bool`, `aim_point: Vector3`, `aim_normal: Vector3` (filled only on `aim_request`). `Movement.before_move(state, position, velocity, input, config, tick)` reads `position`. **Aim** (`core/fighter/aim.gd`): `class_name Aim`, `static func direction(yaw: float, pitch: float) -> Vector3` = `Basis(Vector3.UP, yaw) * Vector3(0, sin(pitch), -cos(pitch))`, unit. **Data**: `grapple_range_m = 25.0` (positive), `grapple_attach_ms = 100` (time, may be 0), `grapple_pull_speed_mps = 18.0` (positive), `grapple_release_distance_m = 1.5` (positive, < range), `grapple_cooldown_ms = 6000` (time), `grapple_block_pct = 50.0` (0..100), `aim_height_m = 1.6` (positive; `test/data/aim_height_test.gd` asserts equality with `camera_v0.tres` pivot). **Config**: `grapple_range`, `grapple_attach_ticks` (6 / 3), `grapple_pull_speed`, `grapple_release_distance`, `grapple_cooldown_ticks` (360 / 180), `grapple_block_speed = pull * pct / 100`, `aim_height`.

**Conventions**: a grapple press is legal outside DASH and GRAPPLE with `tick - grapple_end_tick >= grapple_cooldown_ticks` (NEVER counts as free): `before_move` sets `plan.aim_request = true` and keeps the press in the slot until the hit is confirmed or the window ends. `after_move` with `facts.aim_hit` inside `grapple_range`: `grapple_fired_tick = tick`, `grapple_point = facts.aim_point`, slot cleared; the WALL_RUN ends. The pull starts in `before_move` when `tick - grapple_fired_tick >= grapple_attach_ticks`: `mode = GRAPPLE`, `mode_since = tick`; each tick `velocity = (grapple_point - (position + UP * aim_height)).normalized() * grapple_pull_speed`, no gravity, no input. Release in `before_move`: distance ≤ `grapple_release_distance`; or, from the second pull tick, `velocity.dot(dir) < grapple_block_speed`; or a jump press (then the same press resolves as an air jump). On release: `grapple_end_tick = tick`, `grapple_fired_tick = NEVER`, mode AIR (or GROUND if `on_floor`), velocity kept. Slot order of writes: grapple, dash, jump (jump wins a tie).

**Adapter**: `Fighter._cast_aim(origin: Vector3, direction: Vector3, length: float) -> Dictionary` via `get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin, origin + direction * length, PhysicsLayers.WORLD))`, only on `plan.aim_request`, re-cast on every resimulated tick. `MovementRig` gains `aim_hit`, `aim_point`, `aim_normal` set by the test. `ManeuverCues` keys `grapple_fired_tick`, `grapple_end_tick`. `BotPlayer.aim_at(point: Vector3)`. HUD: ring 24 px, dot from a presentation-only ray; cooldown arc `grapple_end_tick + grapple_cooldown_ticks - tick`; cable line.

**Who tests what**: the test-writer writes criteria 3 to 6 and the `Aim.direction` half of 2 blind against the rig's aim fields (`movement_grapple_test.gd`, `aim_test.gd`, data rows); locked. The implementer writes 1 (probe B: from an `after_process_tick` hook inside the rollback loop, toward a test wall and the sky, fresh vs resimulated vs after `await process_frame`, 1000 rays timed), the adapter half of 2, 7 (scenario "gancho" on run-time geometry, a 10 m block 15 m away, fixture cooldown 500 ms; counters `grapple_fires >= 4`, `attaches >= 3`, `releases_by_distance >= 1`, `releases_by_jump >= 1`, `releases_by_block >= 1`, `misses >= 1`, `refused_grapples >= 1`, `cues_presented == cue_events`, mismatches 0; poison `:state:grapple_point`; the replay session gains `pitch` and `grapple`) and 8.

**Rounds**: A (probe B, the inputs, the key, the readings); B (core, data, adapter, cues, HUD, scenario); C (towers, pillar, docs, `net_run`, playtest). Can slide to TASK-10.7 if round C overflows: the cable line and the pillar.

| Agent | Model | Effort | Why |
|---|---|---|---|
| test-writer | Fable | high | release rules by distance, block and jump in exact ticks |
| implementer | Opus 5.5 | xhigh | a world query inside the rollback plus two inputs |
| reviewer | Fable | high | the ray-in-tick claim needs the probe as proof |
| explorer | Sonnet | high | to map the camera pitch and the sampler before round A |

## SyncTest (en)
Scenario "gancho", counters above, the ray re-cast every resimulated tick, poison `:state:grapple_point`; `tools/net_run.sh` at the close (the bot does not grapple online yet).

## Arena (en)
`TorreA` (−8, 3, −30) 4 × 6 × 4; `TorreB` (12, 3, −30) 4 × 6 × 4 (16 m between faces); `Pilar10m` (2, 5, −36) 2 × 10 × 2, top 10 m.

## Teste à mão e o que sentir
Prender no topo de uma torre a menos de 25 m; cruzar os 16 m entre as torres; soltar com pulo mais pulo duplo sobre a borda; subir o pilar; ver a mira mudar de forma e o cabo aparecer; esperar os 6 s. O que sentir: se a puxada a 18 m/s tem peso; se os 6 s frustram; se o Q cai na mão.

## Docs a atualizar
Com o seu ok e uma linha no `mudancas.md` cada: `movimento.md` ("Gancho" com as leituras v0; "Perdão" com a ordem completa; "Métricas de nível" com as torres e o pilar); `glossario.md` (Mira, Cabo, Ponto do gancho, Puxada, Pedido de mira); `rede.md` (tabela de input com `pitch` e `grapple`; o resultado da sonda B; a nota do tick previsto para a fase 3); `visao-geral.md` (`Mode.GRAPPLE`, os carimbos, `aim_request`, `aim_hit`); `testes-e-entrega.md` (o cenário, as colunas do replay, o `--force`); `visual-e-audio.md` (a tecla, a mira em px, o arco); a vitrine (25 m, 18 m/s, as torres); o diário e o `registro.md`.

Q-35 (review of TASK-10.5): a wall run that starts and ends inside the floor coyote window leaves left_floor_tick live (movement.gd _enter_wall); fix with a new test (zero the coyote on wall entry).
<!-- SECTION:NOTES:END -->
