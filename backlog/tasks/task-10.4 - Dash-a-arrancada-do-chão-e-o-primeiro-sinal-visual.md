---
id: TASK-10.4
title: 'Dash: a arrancada do chão e o primeiro sinal visual'
status: Ready
assignee: []
created_date: '2026-10-19 13:46'
updated_date: '2026-10-23 12:49'
labels:
  - jogo
milestone: m-1
dependencies:
  - TASK-10.3
parent_task_id: TASK-10
ordinal: 15000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
O dash é a manobra do chão (`movimento.md`, "Dash") e a primeira que muda um contato com o motor: o snap do chão foi dimensionado para 7 m/s e precisa valer a 20 m/s descendo a rampa (DEC-0025; DEC-0037). Ele traz o segundo comando da vaga e a primeira regra de empate (pulo ganha do dash), a troca de modo por comando no `before_move` (DEC-0041, aceita no plano, F-122, que substitui a DEC-0022 só nisso) e o sistema de sinais por chave de evento, que toca uma vez e nunca na re-simulação (DEC-0031 §6). O replay da TASK-10.3 ganha a coluna `dash` e prova que o dash refaz o mesmo rastro.

### Perguntas em aberto
Nenhuma.

### Escolhas a confirmar
Confirmadas em 23/10/2026: a 2 e a 3 pelo Arthur (F-121), a 1 no plano aprovado (F-122).
1. O `before_move` passa a trocar o modo por comando (dash; depois o pulo da parede e o gancho), e o `after_move` continua trocando por contato: a DEC-0041 substitui a DEC-0022 só nisso, o `visao-geral.md` ganha a frase e o `mudancas.md` a linha. Padrão: sim, porque um modo comprometido só termina pela própria regra, e a regra mora onde o comando sai; é arquitetura e passa pelo modo de plano.
2. O dash vai no Shift esquerdo, por posição física (`physical_keycode`); o toque duplo na direção, como no GunZ, fica para depois se você pedir. Padrão: Shift, porque um toque duplo esconde um atraso de detecção que um jogo de 60 ticks sente, e os botões do mouse ficam para o combate (DEC-0031 §8).
3. Não existe pulo para cortar o dash no v0: um pulo apertado durante o dash sai no primeiro tick depois do fim. Padrão: sim, porque cortar seria um cancelamento novo, com preço, aviso e uma DEC (DEC-0016); se o dash parecer preso, você diz jogando e a regra volta à mesa.

### Números v0 do Claude
Fechados pelo Claude (DEC-0017); escritos em "Dash" no `movimento.md` com o plano aprovado (F-122), antes do test-writer.
- Sem direção apontada, o dash vai para onde o corpo olha, fixado no início (F-015 §1); o input de direção não muda nada nos 200 ms (DEC-0016; F-012 §1).
- Saindo da beirada, continua os 200 ms com a gravidade; descendo a rampa de 45°, fica no chão; contra uma parede, o tempo segue e o motor desliza, porque "só no chão" fala de onde começa.
- O snap do chão passa a cobrir a maior velocidade no chão: 0,338 m a 60 (contra 0,121 de hoje), cola de motor no `fighter.gd` e no `visao-geral.md`.
- Os sinais das manobras são só visuais no v0 (rastro do dash, baforada do pulo duplo); o som espera um pacote com licença (DEC-0029). O arco da recarga no HUD mostra os décimos de segundo. Vai para o `visual-e-audio.md`.
- O `physics/3d/run_on_separate_thread` fica em `false`, guardado pelo teste de configurações, porque o rollback refaz vários `move_and_slide()` por passo de física e uma thread separada só ajudaria com física pesada; volta na medição com 16 bots (F-122). O motivo antigo, o laço de ticks em `_process`, deixou de valer com a DEC-0040.

### Fora do escopo
- O dash no ar (`movimento.md`, "Fora do v0"). Pular para cortar o dash. Invulnerabilidade. Som. O empate com o gancho (TASK-10.6).

### O que você vai aprender
- O estado comprometido: o modo que só termina pela própria regra, como uma animação de ataque no LoL que não se cancela.
- Por que o snap do chão depende da velocidade: o que o motor "cola" em um tick.
- A chave do evento, a `key` de uma lista no React: o sinal toca uma vez por chave, nunca de novo na re-simulação.
- Uma ação nova no InputMap, por posição física.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando o lutador no chão aperta o dash, com a recarga livre e pelo menos 15 de stamina (`dash_cost`), o núcleo o leva 4 m em 200 ms (20 m/s; 12 ticks a 60 e 6 a 30), com tolerância de 1 cm, na direção apontada em relação à câmera, ou para onde ele olha sem direção, fixada no início; no fim ele sai a 7 m/s na mesma direção (`movimento.md`, "Dash").
- [ ] #2 Quando o dash começa, a stamina cai 15, e o próximo só sai 400 ms depois do fim (24 ticks a 60, 12 a 30); com 14,5 de stamina ele não sai e nada é pago; um aperto no ar, na recarga ou sem stamina espera na vaga pelos 150 ms e sai no primeiro tick em que fica legal; um tick além da janela, não sai (`movimento.md`, "Dash" e "Perdão"; DEC-0016).
- [ ] #3 Quando o lutador está no dash, o input de direção não muda nada, e um pulo apertado durante o dash sai no primeiro tick depois do fim, se ainda estiver nos 150 ms: o dash não se cancela; quando pulo e dash chegam no mesmo tick, o pulo vence, e um aperto depois substitui o guardado (DEC-0016; F-012 §1; `movimento.md`, "Perdão", leitura v0 da ordem).
- [ ] #4 Quando o dash sai da beirada, ele continua até o fim dos 200 ms, com a gravidade, e sai a 7 m/s; quando desce a rampa de 45°, o lutador fica no chão em todos os ticks, e um teste de cena prova que o snap da TASK-9 não bastaria; quando bate numa parede, o tempo segue e o motor desliza (leituras v0 do Claude; DEC-0025; DEC-0037).
- [ ] #5 Quando o pulo duplo e o dash aparecem pela primeira vez no estado exibido, cada um toca um sinal visual uma vez só, pela chave (lutador, tipo, tick), mesmo com o rollback forçado: na SyncTest, os sinais apresentados são iguais aos eventos (DEC-0031 §6).
- [ ] #6 Quando a SyncTest roda o cenário do dash com o rollback de 7 ticks a cada tick, ela acha zero divergências no estado inteiro e esconder `:state:dash_tick` faz ela acusar; o cenário tem dash no plano, na rampa (sem tick no ar), contra a parede, saindo da beirada, guardado no ar, guardado na recarga, uma recusa por stamina e um pulo no fim; a gravação de um dash refaz o mesmo rastro no teste do replay (`rede.md` §8; DEC-0027 §5).
- [ ] #7 Quando o Arthur aperta o Shift esquerdo (por posição física) no Sozinho, o lutador dá o dash sobre a régua de 4 m, e o HUD mostra a recarga como um arco com os décimos de segundo, lida do estado; o `tools/net_run.sh` passa a ping 100 com o bot dando um dash no meio de cada perna; o que ele sentiu vai para uma fonte (DEC-0031 §2 e §8; `rede.md` §8 e §10; F-041).
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

O dash é a manobra do chão (`movimento.md`, "Dash"): 4 m em 200 ms, custa 15 de stamina, 400 ms de recarga. É a primeira manobra que muda um contato com o motor, a 20 m/s, e traz o primeiro sinal visual (DEC-0031 §6). O plano da fase 1 já desenhou a task (TASK-10.4, notas). Você fechou as escolhas de hoje (F-121):
- a conferência certa: o dash vai até o fim, e o pulo sai depois;
- o Shift esquerdo, por posição física;
- nenhum corte pelo pulo no v0.

Com o tick no passo de física (DEC-0040), o replay refaz o dash bit a bit, na janela também.

## O que você aprova aqui: três mudanças na arquitetura

1. **A troca de modo por comando (DEC-0041, substitui a DEC-0022 só nisso):** hoje o modo só muda por contato, no `after_move`, quando o corpo toca ou deixa o chão. O dash muda o modo por comando, no `before_move`, onde o aperto sai: `GROUND → DASH`. O `DASH` só termina pela própria regra, depois de 12 ticks. O `after_move` não mexe no modo durante o dash. O pulo da parede e o gancho seguem a mesma regra depois. A comparação: é o W da Tristana, que só termina no ponto escolhido.
2. **O snap do chão cobre a maior velocidade no chão:** passa de 0,121 m para **0,338 m** a 60 ticks. A conta: 20 m/s ÷ 60 × tan 45°, mais as margens do motor. Sem isso, o dash descendo a rampa de 45° descolaria do chão. O preço é que um degrau de até 0,338 m passa a ser "chão" e não beirada. A arena não tem nenhum degrau assim: a menor queda é de 1 m.
3. **Os sinais das manobras por chave de evento** (`fighter/maneuver_cues.gd`): cada sinal toca uma vez por chave (lutador, tipo, tick), lida do estado exibido. É como a `key` de uma lista no React: o rollback refaz o tick, mas a chave já tocou e não toca de novo. O rastro do dash e a baforada do pulo duplo são só visuais no v0, porque o som espera um pacote com licença (DEC-0029; Q-32).

Mais uma ação nova no InputMap (`dash`, Shift esquerdo físico) e o `TickInput.dash`, um toque, como o pulo.

## Os números v0 (meus, DEC-0017; você julga jogando)

| Número | Valor | Em ticks (60 / 30) |
|---|---|---|
| Distância e duração | 4 m em 200 ms | 12 / 6 ticks, 20 m/s |
| Saída | 7 m/s na mesma direção | — |
| Recarga, do fim | 400 ms | 24 / 12 |
| Custo | 15 de stamina | — |
| Sem direção apontada | para onde o corpo olha, fixado no início | — |
| Saindo da beirada | continua os 200 ms, com a gravidade | — |
| Contra a parede | o tempo segue e o motor desliza | — |
| Empate no mesmo tick | o pulo vence o dash | — |

O HUD ganha um arco da recarga com os décimos de segundo. O `run_on_separate_thread` fica em `false`, com o motivo novo: o rollback refaz vários `move_and_slide()` por passo, e a thread só ajudaria com física pesada (volta na medição com 16 bots).

## A ordem

0. Na main: a task vira Ready com DEC-0041 no lugar de DEC-0040 e o motivo novo do `run_on_separate_thread`; o `movimento.md` ganha as leituras v0; a DEC-0041 é escrita e aceita por este plano. Depois, a branch `task-10.4-dash`.
1. **test-writer** (Fable, high), cego ao código: os critérios 1 a 4 em `test/core/fighter/movement_dash_test.gd` e nas linhas de dados. Eu travo com o sha256.
2. **implementer, rodada A** (Opus 5.5, xhigh): o núcleo, os dados, a configuração, a tecla e o input.
3. **implementer, rodada B:** o snap, os sinais, o cenário da SyncTest (8 situações, veneno no `dash_tick`), o teste da rampa no motor, o arco no HUD, o bot com dash, a coluna `dash` do replay e a régua de 4 m na arena.
4. **reviewer** (Fable, high), de contexto limpo.
5. O portão e o `net_run.sh` a ping 100 com o bot dando dash, rodados por mim.
6. **Você joga:**
   - o dash sobre a régua;
   - apertar seguido até sentir a recarga e a stamina;
   - descer a rampa no dash;
   - sair da plataforma;
   - pulo no fim do dash.

   Aqui você também julga a Q-33: com o dash, a barra passa a pesar?
7. Push, PR e merge, cada um com o seu ok.

## Verificação

- `bash tools/gate.sh` verde; os testes travados do test-writer passam sem edição.
- A SyncTest do cenário do dash acha zero divergências, e o veneno no `dash_tick` acusa. Os sinais apresentados batem com os eventos.
- O teste da rampa prova que o snap da TASK-9 não bastaria e que o novo basta.
- O `net_run.sh` passa com zero ticks corrigidos.
- Um replay com dash toca com "equal on every tick" no `--watch`.

## Riscos

- **O snap maior** pode grudar o corpo numa queda pequena. Nenhuma existe na arena, mas as fases seguintes precisam saber disso.
- **O portão** já leva uns 140 s neste PC, acima dos 90 s do pre-push. O cenário novo soma alguns segundos. Se passar muito, a divisão do CI (DEC-0027 §4) volta a você como DEC.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Rascunho do plano da fase 1 (19/10/2026), em inglês para os agentes; vira o plano em português quando a filha ficar Ready (F-100).

**State**: `enum Mode { GROUND, AIR, DASH = 2 }`; `dash_tick: int = NEVER` (`:state:dash_tick`), `dash_direction: Vector3 = Vector3.ZERO` (`:state:dash_direction`); `FighterCommand.DASH := &"dash"`. **Input**: `TickInput.dash: bool` (one-touch, `Input:dash` in `fighter.tscn`:42), `InputSampler.press_dash()/take_dash()`, `FighterInput.press_dash()`, InputMap `dash` = `KEY_SHIFT` physical (4194325; `PHYSICAL_KEYS` in `project_settings_test.gd` gains it). **Data**: `dash_distance_m: float = 4.0` (positive), `dash_ms: int = 200` (divides: ≥ 1 tick at 30 and 60), `dash_exit_speed_mps: float = 7.0` (not negative), `dash_cooldown_ms: int = 400` (time, may be 0), `dash_cost: float = 15.0` (not negative, ≤ `stamina_max`). **Config**: `dash_ticks` (12 / 6), `dash_speed = dash_distance_m * tickrate / dash_ticks` (20 / 20), `dash_exit_speed`, `dash_cooldown_ticks` (24 / 12), `dash_cost`.

**Conventions**: the slot writes presses in the order dash, jump: a same-tick tie leaves `JUMP`. The dash starts in `before_move` when the slot holds `DASH` alive, `mode == GROUND`, `on_floor`, `tick - dash_tick >= dash_ticks + dash_cooldown_ticks` (NEVER counts as free), `Stamina.at >= dash_cost`: `mode = DASH`, `mode_since = tick`, `dash_tick = tick`, `dash_direction` = the input direction or `-Basis(UP, facing_yaw).z` (unit, horizontal); `Stamina.spend`. While `tick - dash_tick < dash_ticks`: horizontal `dash_direction * dash_speed`, vertical 0 on the floor, gravity otherwise; input ignored; the slot keeps a jump. At `tick - dash_tick >= dash_ticks`, `before_move` sets horizontal `dash_direction * dash_exit_speed`, `mode` GROUND if `state.on_floor` else AIR, `mode_since = tick`, then the slot may fire the same tick. `after_move` switches GROUND/AIR only outside DASH. The cooldown counts from the end.

**Adapter**: `Fighter.floor_snap_for(config)` uses `maxf(run_speed, dash_speed)` (`fighter.gd`:51-55). `fighter/maneuver_cues.gd` (`class_name ManeuverCues extends Node`): on `NetworkTime.after_tick_loop` reads the displayed state and plays once per key `(fighter, kind, stamp)` with `double_jump_tick` and `mode_since` while DASH; exposes `presented: int` and `events: int` for the SyncTest. `BotRoute.dashes_at(step)` (1000 ms into each leg). The replay columns gain `dash`. HUD: a cooldown arc with tenths, `dash_tick + dash_ticks + dash_cooldown_ticks - tick`.

**Who tests what**: the test-writer writes criteria 1 to 4 blind (`test/core/fighter/movement_dash_test.gd`, data rows) through `MovementRig` on flat floor, a ledge and a 45° fake floor; locked. The implementer writes 5 to 7: the cue system and its SyncTest check; the "dash" scenario on a `duplicate()`d copy (`stamina_max = 20.0`), counters `dashes >= 5`, `ramp_dash_ticks > 0`, `ramp_dash_air_ticks == 0`, `ledge_dashes >= 1`, `blocked_dashes >= 1`, `buffered_dashes >= 2`, `refused_cooldown >= 1`, `refused_stamina >= 1`, `jumps_after_dash >= 1`, `cues_presented == cue_events`, mismatches 0, poison `:state:dash_tick`; the engine test in `fighter_slope_test.gd` style ("a dash down the 45° ramp stays on the floor every tick" and "with the TASK-9 snap it leaves"); the replay session gains a dash; the ruler mesh; the InputMap and settings rows.

**Rounds**: A (core, data, DEC-0041, the readings, the key); B (snap, cues, scenario, engine test, HUD arc, bot, replay column); C (review fixes, `net_run`, playtest).

| Agent | Model | Effort | Why |
|---|---|---|---|
| test-writer | Fable | high | the committed mode and the tie need exact tick tests |
| implementer | Opus 5.5 | xhigh | a core rule, an engine contact and the cue system |
| reviewer | Fable | high | DEC-0041 and the snap are architecture verdicts |
| explorer | Sonnet | high | to confirm `KEY_SHIFT` and the snap lines before editing |

## SyncTest (en)
Scenario "dash", counters above, cues checked, poison on `:state:dash_tick`; `tools/net_run.sh` at ping 100 at the close with the bot dashing.

## Arena (en)
`RéguaDoDash`: mesh-only strips 0.1 × 0.01 × 2 m every 4 m along x −10..30 at z 14..16, y 0.01; no collision.

## Teste à mão e o que sentir
Dash sobre a régua e contar os 4 m; apertar seguido até sentir a recarga e a stamina; descer a rampa no dash e ver o corpo colado; sair da plataforma no dash; apertar o pulo no fim do dash e ver sair no tick seguinte; o rastro e a baforada uma vez cada. O que sentir: se a arrancada parece uma decisão ou um spam; se o Shift cai na mão; se o dash preso incomoda.

## Docs a atualizar
Com o seu ok e uma linha no `mudancas.md` cada: `movimento.md` ("Dash" com as leituras v0; "Perdão" com a ordem do empate); `glossario.md` (Troca por comando, Troca por contato, Saída desenhada, Sinal da manobra); `rede.md` (tabela de input com `dash`; o sinal sob rollback); `visao-geral.md` (`Mode.DASH`, os campos, a troca por comando); `testes-e-entrega.md` (o cenário, o teste da rampa, o `run_on_separate_thread`); `visual-e-audio.md` (a tecla, o arco, os sinais); DEC-0041 com `substitui: DEC-0022` (escrita no plano, F-122); a vitrine (4 m, 12 ticks, snap de 0,338 m); o diário e o `registro.md`.

## Since the plan (23/10/2026, en)
The tick now runs in the physics step (DEC-0040, sync_to_physics on; was numbered as this task's DEC before, now DEC-0041). Device sampling in `fighter_input.gd` is in `_physics_process` with `process_physics_priority = -1`: the dash key follows the jump's path (`_unhandled_input` → `press_dash()`). Sozinho and `--watch` start after one process frame (`Main._first_frame`). Q-33 (double jump feels infinite) is judged in this task's playtest.
<!-- SECTION:NOTES:END -->
