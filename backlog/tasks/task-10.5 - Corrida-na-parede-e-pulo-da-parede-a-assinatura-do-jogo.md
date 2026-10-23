---
id: TASK-10.5
title: 'Corrida na parede e pulo da parede: a assinatura do jogo'
status: In Progress
assignee: []
created_date: '2026-10-19 13:46'
updated_date: '2026-10-23 14:55'
labels:
  - jogo
milestone: m-1
dependencies:
  - TASK-10.4
parent_task_id: TASK-10
ordinal: 16000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
A parede dá ao jogo a sua assinatura (`movimento.md`, "Corrida na parede"; F-012 §1) e é o primeiro fato do motor lido depois do movimento além do chão; a DEC-0025 achou estado escondido no chão, e a parede pode ter o seu. Por isso a sonda A roda antes de qualquer regra (`rede.md` §4; registro de 10/10/2026: toda sonda prova a precondição). A filha nasce inteira numa sessão, com a parede longa, o corredor e o patamar na arena e o primeiro ensaio cronometrado de 15 minutos no fim: as duas partes do rascunho viraram oito critérios e três rodadas, o teto da TASK-9; se a rodada C estourar, o percurso e o ensaio deslizam para uma filha de ajuste com uma linha no `mudancas.md`.

### Perguntas em aberto
Nenhuma; a sonda A responde pelo motor, a Q-07 se responde jogando.

### Escolhas a confirmar
Confirmadas em 23/10/2026: a 1 e a 3 pelo Arthur (F-127), a 2 no plano aprovado (F-128); os fatos da parede viram a DEC-0042.
1. A parede é reconhecida pelo caminho do nó do colisor relativo à `Arena` e pela normal (até 10°, inclusive), nunca pelo id ou RID do motor. Padrão: sim, porque um caminho é definido pela árvore e sai igual no servidor, no cliente, no SubViewport e no replay (`Node.xml`:523); a vida de um RID não está documentada, e a sonda A anota se ele muda entre execuções. É estado que viaja na rede: sua.
2. O nó acha a parede pelas colisões do próprio movimento na entrada e, durante a corrida, por uma sonda só de teste (`move_and_collide` com `test_only`, 5 cm para dentro), porque correndo paralelo o motor pode não colidir (`CharacterBody3D.xml`:86); se a sonda A mostrar que a emenda derruba o contato, entra um empurrão de 1 m/s para dentro, cola de motor. Padrão: a sonda só de teste, porque não move nada e não suja a velocidade; é contato com o motor e passa pelo modo de plano.
3. No ar, acima da velocidade de corrida, o input gira e freia a velocidade só pela aceleração do ar (0,194 m/s por tick a 60) e o excesso nunca é cortado; no chão, o excesso cai pela aceleração do chão. Padrão: sim, porque "a velocidade se conserva entre manobras" (`movimento.md`, "Princípios") e hoje o `move_toward` cortaria qualquer excesso acima de 7 m/s no primeiro tick com input; é a Q-07 e você decide jogando.

### Números v0 do Claude
Fechados pelo Claude (DEC-0017); escritos em "Corrida na parede" no `movimento.md` com o plano aprovado (F-128), antes do test-writer.
- Só a velocidade no plano da parede decide a entrada (≥ 4 m/s): de frente, a velocidade ao longo é quase zero e não entra.
- Parede válida: `|normal.y| ≤ cos 80°` (0,1736), a tradução dos 80° para a normal.
- A vertical zera na entrada ("altura mantida" desde o primeiro tick); o input não dirige nem freia; 8 m/s, ou a velocidade de entrada até 12, na direção da entrada.
- Descida: no k-ésimo tick de descida a vertical é `−k · 10% · g_tick`, aplicada antes do movimento como o `movement.gd`:98-112 já faz: 0,996 m a 60 e 0,922 m a 30 até os 2,5 s; outra ordem muda mais de 1 cm.
- Fins da corrida: tempo, borda, chão, trava abaixo de 4 m/s (o mínimo de entrada, sem número novo), pulo. O pulo da parede conta como o primeiro pulo do voo; não existe coyote da parede; um pulo guardado antes de encostar sai no primeiro tick da corrida (DEC-0016).
- Mesma parede: `wall_same_face_deg` = 10°, inclusive, porque 10° separa as faces de uma caixa e o papel só diz "mesma parede". A câmera não inclina no v0.
- Arena: `ParedeLonga` 24 m (≥ a corrida de ≈ 20 m), corredor com 3,5 m de vão interno (2,8 m de centro a centro a 5 m/s dá 0,56 s e chega ≈ 0,54 m acima), `PatamarDoCorredor` com 3 m de topo (pulo da parede +1,2 m e pulo duplo +1,0 m: "Com 3 m ou mais, só pela parede ou pelo gancho"). Vai para "Métricas de nível".

### Fora do escopo
- Escalar a parede na vertical e agarrar a borda ("Fora do v0"). Se a parede conta como ar no combate (Q-14). O coyote da parede. A câmera inclinada.
- A parede online no bot (fase 3).

### O que você vai aprender
- Os fatos que o motor devolve depois de mover: a normal da parede como a resposta de uma API.
- Estado escondido do motor: um cache que o rollback não limpa, como um `useMemo` que não sabe que o estado voltou no tempo, e a sonda com precondição que o pega.
- A projeção no plano: "ao longo" e "para dentro", o produto escalar na prática.
- Identidade estável em rede: o caminho do nó é a chave primária, o RID é um ponteiro.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando a sonda do motor força o rollback de 7 ticks com o lutador batendo e deslizando numa parede de teste, passando por uma emenda entre dois colisores e por um canto, e correndo paralelo a ela com a vertical zerada, os fatos da parede (encostou, a normal e o caminho do colisor relativo à arena) saem iguais no tick novo e no refeito; a sonda falha se não houver contato, emenda ou canto, e anota a taxa de ticks sem colisão na corrida paralela e se o id e o RID do colisor mudam entre execuções (DEC-0025; `rede.md` §4; `CharacterBody3D.xml`:80-93).
- [ ] #2 Quando o lutador no ar encosta numa parede de pelo menos 80°, com pelo menos 4 m/s ao longo dela (a velocidade horizontal no plano da parede), e ela não é a parede da última corrida desde o chão ou outra parede, o núcleo começa a corrida: zera a vertical, renova o pulo duplo e corre a 8 m/s, ou à velocidade de entrada até o teto de 12 (quem entra a 10 corre a 10; a 14, corre a 12); com 3,9 m/s, numa parede de 79°, de frente, a partir do chão ou na mesma parede, não entra; o input não vira nem freia (`movimento.md`, "Corrida na parede").
- [ ] #3 Quando a corrida dura, a altura fica igual por 1,5 s (90 ticks a 60, 45 a 30), com tolerância de 1 cm, qualquer que fosse a vertical na entrada; depois, no k-ésimo tick de descida a vertical é `-k` vezes 10% da gravidade de subida por tick (0,0327 m/s a 60; 0,0595 a 30), aplicada antes do movimento, e ele perde 0,996 m a 60 e 0,922 m a 30 até soltar aos 2,5 s (150 ticks a 60, 75 a 30), com tolerância de 1 cm (`movimento.md`, "Corrida na parede").
- [ ] #4 Quando a parede acaba, quando o lutador toca o chão ou quando ele trava num obstáculo (a velocidade ao longo cai abaixo de 4 m/s), a corrida termina no mesmo tick; ao fim por tempo ou por contato, ele cai no ar com o pulo duplo disponível (leituras v0 do Claude; `movimento.md`, "Corrida na parede").
- [ ] #5 Quando o lutador aperta o pulo na corrida, ou apertou até 150 ms antes de encostar, sai o pulo da parede: 1,2 m de altura, com tolerância de 1 cm, e 5 m/s para fora, mantendo a velocidade ao longo da parede; ele conta como o primeiro pulo do voo e o pulo duplo continua disponível; no ar, acima de 7 m/s, o input gira a velocidade só pela aceleração do ar (0,194 m/s por tick a 60) sem cortar o excesso, e o input contrário freia só por ela (`movimento.md`, "Corrida na parede", "Pulo e ar" e "Princípios"; leitura v0, Q-07).
- [ ] #6 Quando o lutador volta à mesma parede (o mesmo colisor, com a normal a até 10°, inclusive) sem ter tocado o chão ou outra parede, ela não aceita nova corrida, mas outra parede aceita, mesmo no mesmo plano: o corredor se sobe alternando (`movimento.md`: "Mesma parede"; `wall_same_face_deg`, leitura v0).
- [ ] #7 Quando um número da parede no `movement_v0.tres` é impossível (inclinação fora de 0 a 90° ou abaixo da rampa máxima, mínimo acima da velocidade na parede, teto abaixo dela, altura mantida maior que a duração, mesma face fora de 0 a 90°), a checagem dos dados reprova no portão; quando a SyncTest roda o cenário da parede com o rollback de 7 ticks a cada tick, ela acha zero divergências no estado inteiro e esconder `:state:wall_id` faz ela acusar; o cenário tem entrada, fim por tempo, fim na borda, pulo de uma parede para a outra, a recusa da mesma parede e um pulo duplo depois do pulo da parede; o sinal do pulo da parede toca uma vez por chave; a gravação de uma corrida na parede refaz o mesmo rastro (DEC-0004, regra 3; `rede.md` §8; DEC-0031 §6; DEC-0027 §5).
- [ ] #8 Quando a arena ganha a parede longa, o corredor e o patamar de 3 m (a referência segue verde, ou é regravada com o motivo no commit), o Arthur corre a parede longa, sobe o corredor alternando as paredes, chega ao patamar por pulo da parede mais pulo duplo, e depois joga 15 minutos cronometrados com o pulo duplo, o dash e a parede; o que ele sentiu vai para uma fonte (F-001; F-012 §1; F-041).
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
## Contexto

A parede é a assinatura do jogo (`movimento.md`, "Corrida na parede"; F-012 §1). O plano da fase 1 já desenhou a task (TASK-10.5, notas). Hoje você fechou duas escolhas (F-127):
- a conferência certa: a sonda vem antes, porque o motor pode lembrar mais do que o rollback desfaz;
- conservar o momento no ar;
- reconhecer a parede pelo caminho do nó.

A parede é o primeiro fato do motor além do chão. No chão, a TASK-9 achou estado escondido (DEC-0025), e a sonda A verifica se a parede tem o seu antes de qualquer regra.

## O que você aprova aqui: quatro mudanças na arquitetura

1. **Os fatos da parede viajam como dado** (DEC-0042, nova). O motor devolve, depois de mover, "encostei, com esta normal, neste colisor", como a resposta de uma API. O núcleo recebe isso em `MoveFacts.wall_normal` e `MoveFacts.wall_id`. O estado guarda:
   - `wall_id`, o caminho do nó relativo à arena, como `ParedeLonga`, que é a chave primária que você escolheu;
   - `wall_normal`;
   - `wall_jump_tick`.

   Um RID do motor nunca entra no estado.
2. **Durante a corrida, uma sonda só de teste confere a parede.** Correndo paralelo, o motor pode não registrar colisão nenhuma. Então, a cada tick, o nó pergunta ao motor "se eu me movesse 5 cm para dentro, bateria?" (`move_and_collide` com `test_only`), sem mover nada. Se a sonda A mostrar que isso falha numa emenda, entra um empurrão de 1 m/s para dentro, e você ouve antes.
3. **Duas trocas de modo, pela DEC-0041:** a entrada na parede é por contato, no `after_move`, e o pulo da parede é por comando, no `before_move`. `WALL_RUN` é um modo comprometido, como o dash. O input não vira nem freia.
4. **O momento no ar se conserva** (F-127; a Q-07 se julga jogando). Hoje, o primeiro tick com input no ar corta qualquer excesso acima de 7 m/s. Passa a girar e frear só pela aceleração do ar (0,194 m/s por tick a 60), sem cortar. No chão, o excesso cai aos poucos. Isso muda o pulo de hoje só quando há excesso, e o dash sai a 7 m/s, então nada muda no que você já jogou.

## Os números v0 (meus, DEC-0017; você julga jogando)

| Número | Valor |
|---|---|
| Parede válida | 80° ou mais (`|normal.y| ≤ 0,1736`) |
| Entrada | 4 m/s ou mais ao longo da parede; de frente não entra |
| Velocidade na parede | 8 m/s, ou a de entrada até 12 |
| Altura mantida | 1,5 s (90 ticks a 60; 45 a 30) |
| Descida | 10% da gravidade, crescendo por tick: perde 0,996 m a 60 e 0,922 m a 30 até soltar |
| Solta | aos 2,5 s (150 / 75 ticks), na borda, no chão, ou travando abaixo de 4 m/s |
| Pulo da parede | 1,2 m para cima, 5 m/s para fora; conta como o primeiro pulo, e o pulo duplo fica disponível |
| Mesma parede | o mesmo colisor com a normal a até 10°; só vale de novo depois do chão ou de outra parede |

**Na arena:**
- a `ParedeLonga`, de 24 m;
- o corredor, com 3,5 m de vão interno, para subir alternando os lados;
- o `PatamarDoCorredor`, a 3 m de altura, que só se alcança com pulo da parede mais pulo duplo.

## A ordem

0. Na main: a task vira Ready; o `movimento.md` ganha as leituras v0, o momento e as métricas do corredor; a DEC-0042 é escrita e aceita por este plano. Depois, a branch `task-10.5-wall-run`.
1. **implementer, rodada A** (Opus 5.5, xhigh): **a sonda A**, antes de qualquer regra.
   - Uma parede de teste com emenda e canto.
   - O lutador bate, desliza e corre paralelo a ela com o rollback de 7 ticks.
   - Os fatos precisam sair iguais no tick novo e no refeito.
   - Ela anota se o id e o RID mudam entre execuções e quantos ticks da corrida paralela ficam sem colisão.

   O resultado vai para o `rede.md` §4. **Se ela achar estado escondido, eu paro e trago a você.**
2. **test-writer** (Fable, high), cego ao código: os critérios 2 a 6 e a metade dos dados do 7, contra uma parede falsa no rig. Eu travo.
3. **implementer, rodada B:** o núcleo, os dados, o adaptador, o sinal do pulo da parede, o cenário "parede" da SyncTest (veneno no `wall_id`) e o replay com corrida na parede.
4. **implementer, rodada C:** a arena, a referência e os docs.
5. **reviewer** (Fable, high), de contexto limpo. É o veredito mais difícil da fase: estado escondido.
6. O portão e o `net_run.sh` a ping 100.
7. **Você joga:**
   - a parede longa;
   - o corredor alternando os lados;
   - o patamar.

   Depois, **15 minutos cronometrados** com pulo duplo, dash e parede. O que você sentir vai para uma fonte.
8. Push, PR e merge, cada um com o seu ok.

Se a rodada C estourar, a arena e o ensaio passam para uma filha de ajuste, com uma linha no `mudancas.md` (o texto da task já prevê).

## Verificação

- A sonda A: fatos iguais no tick novo e no refeito, com precondição (houve contato, emenda e canto).
- `bash tools/gate.sh` verde; os testes travados passam sem edição.
- A SyncTest "parede" acha zero divergências, e o veneno no `wall_id` acusa. O sinal do pulo da parede toca uma vez por chave.
- O `net_run.sh` passa com zero ticks corrigidos.
- Um replay com corrida na parede toca com "equal on every tick".

## Riscos

- **Estado escondido na parede:** se a sonda achar, a regra espera um contorno, e a task pode dividir.
- **O tamanho:** são oito critérios e três rodadas, o teto da TASK-9. A sessão já é longa, e a task pode atravessar para a próxima sessão. Nada se perde: cada rodada termina em commit.
- **O portão** está em uns 110 s. A divisão do CI continua pendente como DEC sua.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Rascunho do plano da fase 1 (19/10/2026), em inglês para os agentes; vira o plano em português quando a filha ficar Ready (F-100).

**State**: `Mode.WALL_RUN = 3`; `wall_normal: Vector3 = ZERO` (`:state:wall_normal`; flattened unit normal of the current or last run wall; ZERO after the floor or another wall), `wall_id: StringName = &""` (`:state:wall_id`; `StringName(str(arena.get_path_to(collider)))`), `wall_jump_tick: int = NEVER` (`:state:wall_jump_tick`). **Facts**: `MoveFacts.velocity` (read by the core from here), `wall_normal: Vector3`, `wall_id: StringName` (ZERO/`&""` when no wall). **Data**: `wall_min_incline_deg = 80.0` (`max_slope_deg < it <= 90`), `wall_entry_speed_mps = 4.0` (not negative, ≤ run), `wall_run_speed_mps = 8.0` (positive), `wall_max_speed_mps = 12.0` (≥ run), `wall_run_max_ms = 2500` (time), `wall_hold_ms = 1500` (time, ≤ max), `wall_slide_gravity_pct = 10.0` (0..100), `wall_jump_height_m = 1.2` (positive), `wall_jump_push_mps = 5.0` (not negative), `wall_same_face_deg = 10.0` (0..90). **Config**: `wall_max_normal_y = cos(deg_to_rad(80))`, `wall_entry_speed`, `wall_run_speed`, `wall_max_speed`, `wall_run_max_ticks` (150 / 75), `wall_hold_ticks` (90 / 45), `wall_slide_gravity_per_tick = rise_gravity_per_tick * pct / 100`, `wall_jump_speed` (same formula as `jump_speed`), `wall_jump_push`, `wall_same_face_cos`.

**Conventions**: entry in `after_move` when not on floor, `abs(n.y) <= wall_max_normal_y`, not the same wall (`wall_id` equal and `wall_normal.dot(n) >= wall_same_face_cos`), and the horizontal speed projected on the wall plane ≥ `wall_entry_speed`: `mode = WALL_RUN`, `mode_since = tick`, `jumps_used = 0`, `double_jump_tick = NEVER`, velocity.y = 0, along speed clamped to `wall_run_speed..wall_max_speed` in the entry direction. Motion in `before_move`: along velocity kept; vertical 0 while `tick - mode_since < wall_hold_ticks`, then on slide tick `k = tick - mode_since - wall_hold_ticks + 1` vertical `-k * wall_slide_gravity_per_tick`, before the move; input ignored. Ends: `before_move` by `tick - mode_since >= wall_run_max_ticks` or the wall jump (`velocity.y = wall_jump_speed`, plus `wall_normal * wall_jump_push`, along kept, `jumps_used = 1`, `wall_jump_tick = tick`, mode AIR); `after_move` by lost contact, another `wall_id` (a new run may start the same tick), the floor, or along speed after the collision < `wall_entry_speed`; `wall_normal`/`wall_id` keep the last wall until the floor or another wall. Momentum: in AIR with `|v_h| > run_speed`, the `move_toward` target (`movement.gd`:93-95) becomes `direction * maxf(run_speed, |v_h|)` with `air_accel_per_tick`; on the ground the excess decays by the ground acceleration.

**Adapter**: `Fighter._wall_contact(prior: FighterState, facts: MoveFacts) -> void`: at entry from `get_slide_collision(i)` (colliders not `Fighter`, the most horizontal normal); during WALL_RUN `move_and_collide(-wall_normal * WALL_PROBE_DISTANCE, true)`, `const WALL_PROBE_DISTANCE := 0.05`. `MovementRig.add_wall(normal: Vector3, offset: float, id: StringName)`: a fake vertical plane that clamps a crossing move, slides the velocity and reports the facts. `ManeuverCues` key `wall_jump_tick`.

**Who tests what**: the test-writer writes criteria 2 to 6 and the data half of 7 blind against the rig's fake wall (`movement_wall_test.gd`, `movement_momentum_test.gd`, data rows); locked. The implementer writes 1 (`test/fighter/engine_probe_test.gd`, test-built `_box` geometry, `notify_resimulation_start(tick - 7)`, records ids/RIDs, compares the probe against the stick alternative), the SyncTest half of 7 (scenario "parede" on a 24 m run-time corridor; counters `wall_entries >= 3`, `wall_timeouts >= 1`, `edge_exits >= 1`, `wall_jumps >= 2`, `wall_to_wall >= 1`, `same_wall_refusals >= 1`, `double_jumps_after_wall >= 1`, `cues_presented == cue_events`, mismatches 0; poison `:state:wall_id`; the replay session gains a wall run) and 8.

**Rounds**: A (probe A, high effort, before any rule; its result into `rede.md` §4); B (core, data, adapter, cues, scenario); C (arena, reference, docs, the rehearsal). Ultracode, if still unspent, on this child's review.

| Agent | Model | Effort | Why |
|---|---|---|---|
| test-writer | Fable | high | the slide order and the same-wall rule are exact tick math |
| implementer | Opus 5.5 | xhigh | the probe and a new engine contact |
| reviewer | Fable | high | the hardest verdict of the phase: hidden state |
| explorer | Sonnet | high | to map the slide-collision getters and the rig before round A |

## SyncTest (en)
Scenario "parede" on run-time geometry away from the other shapes; counters above; poison `:state:wall_id`; `tools/net_run.sh` at ping 100 at the close.

## Arena (en)
`ParedeLonga` (14.5, 2, −8) 1 × 4 × 24; `CorredorOeste` (22.5, 2.5, −8) 1 × 5 × 24; `CorredorLeste` (27, 2.5, −8) 1 × 5 × 24 (inner gap 3.5 m); `PatamarDoCorredor` (24.75, 1.5, −22) 3.5 × 3 × 4, top 3 m. Bonus to play, not promised: Block3m's east face and ParedeLonga's west face form a 4 m pair.

## Teste à mão e o que sentir
Correr a parede longa: altura mantida, a descida, a queda aos 2,5 s; subir o corredor alternando as paredes (Q-07); chegar ao patamar por pulo da parede mais pulo duplo; depois 15 minutos cronometrados com tudo. O que sentir: se 8 m/s na parede parece rápido; se o pulo da parede abre o pulo duplo com naturalidade; se a parede "entrega uma verdade" (F-012 §1); e se você quer continuar depois dos 15 minutos. O que você descobrir vira fonte: técnica descoberta ganha ferramenta, nunca nerf (`movimento.md`:33).

## Docs a atualizar
Com o seu ok e uma linha no `mudancas.md` cada: `movimento.md` ("Corrida na parede" com as leituras v0; "Princípios" e "Pulo e ar" com a leitura do momento; "Métricas de nível" com o corredor e o patamar); `glossario.md` (Normal da parede, Velocidade ao longo da parede, Inclinação mínima da parede, Velocidade mínima para entrar, Teto de velocidade, Mesma parede, Sonda da parede, Sonda do motor); `rede.md` §4 (o resultado da sonda A: contatos, ids, emenda; a regra dos fatos da parede); `visao-geral.md` (`Mode.WALL_RUN`, os campos, `MoveFacts.wall_*`); `testes-e-entrega.md` (a sonda e o cenário); a F do ensaio; a vitrine (altura mantida, 0,996 m, corredor de 3,5 m); o diário e o `registro.md`.

## Since the plan (23/10/2026, en)
- The tick runs in the physics step (DEC-0040); device sampling is in _physics_process; Sozinho starts after one process frame. The wall probe (move_and_collide test_only) runs inside the physics step, inside _rollback_tick.
- DEC-0041: wall entry is a contact switch (after_move); the wall jump is a command switch (before_move); WALL_RUN is committed.
- DEC-0042 (F-128) fixes the wall facts: MoveFacts.wall_normal/wall_id, wall_id = arena-relative node path, never a RID.
- Ultracode is spent for TASK-10 (one workflow, at the phase plan); review is a plain reviewer.
- From the TASK-10.4 review: the dash SyncTest never fires a cooldown-buffered dash (stamina_max 20). The wall scenario's data copy may carry a bar >= 30 so a cooldown-kept dash fires under rollback, if it fits without bloating the scenario.
<!-- SECTION:NOTES:END -->
