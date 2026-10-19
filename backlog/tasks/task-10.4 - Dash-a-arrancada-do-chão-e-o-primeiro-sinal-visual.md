---
id: TASK-10.4
title: 'Dash: a arrancada do chão e o primeiro sinal visual'
status: To Refine
assignee: []
created_date: '2026-10-19 13:46'
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
O dash é a manobra do chão (`movimento.md`, "Dash") e a primeira que muda um contato com o motor: o snap do chão foi dimensionado para 7 m/s e precisa valer a 20 m/s descendo a rampa (DEC-0025; DEC-0037). Ele traz o segundo comando da vaga e a primeira regra de empate (pulo ganha do dash), a troca de modo por comando no `before_move` (DEC-0040, a aceitar aqui, que substitui a DEC-0022 só nisso) e o sistema de sinais por chave de evento, que toca uma vez e nunca na re-simulação (DEC-0031 §6). O replay da TASK-10.3 ganha a coluna `dash` e prova que o dash refaz o mesmo rastro.

### Perguntas em aberto
Nenhuma.

### Escolhas a confirmar
1. O `before_move` passa a trocar o modo por comando (dash; depois o pulo da parede e o gancho), e o `after_move` continua trocando por contato: a DEC-0040 substitui a DEC-0022 só nisso, o `visao-geral.md` ganha a frase e o `mudancas.md` a linha. Padrão: sim, porque um modo comprometido só termina pela própria regra, e a regra mora onde o comando sai; é arquitetura e passa pelo modo de plano.
2. O dash vai no Shift esquerdo, por posição física (`physical_keycode`); o toque duplo na direção, como no GunZ, fica para depois se você pedir. Padrão: Shift, porque um toque duplo esconde um atraso de detecção que um jogo de 60 ticks sente, e os botões do mouse ficam para o combate (DEC-0031 §8).
3. Não existe pulo para cortar o dash no v0: um pulo apertado durante o dash sai no primeiro tick depois do fim. Padrão: sim, porque cortar seria um cancelamento novo, com preço, aviso e uma DEC (DEC-0016); se o dash parecer preso, você diz jogando e a regra volta à mesa.

### Números v0 do Claude
Fechados pelo Claude (DEC-0017); escritos em "Dash" com o seu ok antes do test-writer rodar.
- Sem direção apontada, o dash vai para onde o corpo olha, fixado no início (F-015 §1); o input de direção não muda nada nos 200 ms (DEC-0016; F-012 §1).
- Saindo da beirada, continua os 200 ms com a gravidade; descendo a rampa de 45°, fica no chão; contra uma parede, o tempo segue e o motor desliza, porque "só no chão" fala de onde começa.
- O snap do chão passa a cobrir a maior velocidade no chão: 0,338 m a 60 (contra 0,121 de hoje), cola de motor no `fighter.gd` e no `visao-geral.md`.
- Os sinais das manobras são só visuais no v0 (rastro do dash, baforada do pulo duplo); o som espera um pacote com licença (DEC-0029). O arco da recarga no HUD mostra os décimos de segundo. Vai para o `visual-e-audio.md`.
- O `physics/3d/run_on_separate_thread` fica em `false`, guardado pelo teste de configurações, porque um thread separado restringe a física ao `_physics_process` e quebraria o `move_and_slide()` no laço de ticks em `_process` (`ProjectSettings.xml`:2644-2645).

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

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Rascunho do plano da fase 1 (19/10/2026), em inglês para os agentes; vira o plano em português quando a filha ficar Ready (F-100).

**State**: `enum Mode { GROUND, AIR, DASH = 2 }`; `dash_tick: int = NEVER` (`:state:dash_tick`), `dash_direction: Vector3 = Vector3.ZERO` (`:state:dash_direction`); `FighterCommand.DASH := &"dash"`. **Input**: `TickInput.dash: bool` (one-touch, `Input:dash` in `fighter.tscn`:42), `InputSampler.press_dash()/take_dash()`, `FighterInput.press_dash()`, InputMap `dash` = `KEY_SHIFT` physical (4194325; `PHYSICAL_KEYS` in `project_settings_test.gd` gains it). **Data**: `dash_distance_m: float = 4.0` (positive), `dash_ms: int = 200` (divides: ≥ 1 tick at 30 and 60), `dash_exit_speed_mps: float = 7.0` (not negative), `dash_cooldown_ms: int = 400` (time, may be 0), `dash_cost: float = 15.0` (not negative, ≤ `stamina_max`). **Config**: `dash_ticks` (12 / 6), `dash_speed = dash_distance_m * tickrate / dash_ticks` (20 / 20), `dash_exit_speed`, `dash_cooldown_ticks` (24 / 12), `dash_cost`.

**Conventions**: the slot writes presses in the order dash, jump: a same-tick tie leaves `JUMP`. The dash starts in `before_move` when the slot holds `DASH` alive, `mode == GROUND`, `on_floor`, `tick - dash_tick >= dash_ticks + dash_cooldown_ticks` (NEVER counts as free), `Stamina.at >= dash_cost`: `mode = DASH`, `mode_since = tick`, `dash_tick = tick`, `dash_direction` = the input direction or `-Basis(UP, facing_yaw).z` (unit, horizontal); `Stamina.spend`. While `tick - dash_tick < dash_ticks`: horizontal `dash_direction * dash_speed`, vertical 0 on the floor, gravity otherwise; input ignored; the slot keeps a jump. At `tick - dash_tick >= dash_ticks`, `before_move` sets horizontal `dash_direction * dash_exit_speed`, `mode` GROUND if `state.on_floor` else AIR, `mode_since = tick`, then the slot may fire the same tick. `after_move` switches GROUND/AIR only outside DASH. The cooldown counts from the end.

**Adapter**: `Fighter.floor_snap_for(config)` uses `maxf(run_speed, dash_speed)` (`fighter.gd`:51-55). `fighter/maneuver_cues.gd` (`class_name ManeuverCues extends Node`): on `NetworkTime.after_tick_loop` reads the displayed state and plays once per key `(fighter, kind, stamp)` with `double_jump_tick` and `mode_since` while DASH; exposes `presented: int` and `events: int` for the SyncTest. `BotRoute.dashes_at(step)` (1000 ms into each leg). The replay columns gain `dash`. HUD: a cooldown arc with tenths, `dash_tick + dash_ticks + dash_cooldown_ticks - tick`.

**Who tests what**: the test-writer writes criteria 1 to 4 blind (`test/core/fighter/movement_dash_test.gd`, data rows) through `MovementRig` on flat floor, a ledge and a 45° fake floor; locked. The implementer writes 5 to 7: the cue system and its SyncTest check; the "dash" scenario on a `duplicate()`d copy (`stamina_max = 20.0`), counters `dashes >= 5`, `ramp_dash_ticks > 0`, `ramp_dash_air_ticks == 0`, `ledge_dashes >= 1`, `blocked_dashes >= 1`, `buffered_dashes >= 2`, `refused_cooldown >= 1`, `refused_stamina >= 1`, `jumps_after_dash >= 1`, `cues_presented == cue_events`, mismatches 0, poison `:state:dash_tick`; the engine test in `fighter_slope_test.gd` style ("a dash down the 45° ramp stays on the floor every tick" and "with the TASK-9 snap it leaves"); the replay session gains a dash; the ruler mesh; the InputMap and settings rows.

**Rounds**: A (core, data, DEC-0040, the readings, the key); B (snap, cues, scenario, engine test, HUD arc, bot, replay column); C (review fixes, `net_run`, playtest).

| Agent | Model | Effort | Why |
|---|---|---|---|
| test-writer | Fable | high | the committed mode and the tie need exact tick tests |
| implementer | Opus 5.5 | xhigh | a core rule, an engine contact and the cue system |
| reviewer | Fable | high | DEC-0040 and the snap are architecture verdicts |
| explorer | Sonnet | high | to confirm `KEY_SHIFT` and the snap lines before editing |

## SyncTest (en)
Scenario "dash", counters above, cues checked, poison on `:state:dash_tick`; `tools/net_run.sh` at ping 100 at the close with the bot dashing.

## Arena (en)
`RéguaDoDash`: mesh-only strips 0.1 × 0.01 × 2 m every 4 m along x −10..30 at z 14..16, y 0.01; no collision.

## Teste à mão e o que sentir
Dash sobre a régua e contar os 4 m; apertar seguido até sentir a recarga e a stamina; descer a rampa no dash e ver o corpo colado; sair da plataforma no dash; apertar o pulo no fim do dash e ver sair no tick seguinte; o rastro e a baforada uma vez cada. O que sentir: se a arrancada parece uma decisão ou um spam; se o Shift cai na mão; se o dash preso incomoda.

## Docs a atualizar
Com o seu ok e uma linha no `mudancas.md` cada: `movimento.md` ("Dash" com as leituras v0; "Perdão" com a ordem do empate); `glossario.md` (Troca por comando, Troca por contato, Saída desenhada, Sinal da manobra); `rede.md` (tabela de input com `dash`; o sinal sob rollback); `visao-geral.md` (`Mode.DASH`, os campos, a troca por comando); `testes-e-entrega.md` (o cenário, o teste da rampa, o `run_on_separate_thread`); `visual-e-audio.md` (a tecla, o arco, os sinais); DEC-0040 com `substitui: DEC-0022`; a vitrine (4 m, 12 ticks, snap de 0,338 m); o diário e o `registro.md`.
<!-- SECTION:NOTES:END -->
