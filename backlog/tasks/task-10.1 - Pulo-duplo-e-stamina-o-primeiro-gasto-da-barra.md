---
id: TASK-10.1
title: 'Pulo duplo e stamina: o primeiro gasto da barra'
status: Ready
assignee: []
created_date: '2026-10-19 13:45'
updated_date: '2026-10-19 13:47'
labels:
  - jogo
milestone: m-1
dependencies:
  - TASK-9
parent_task_id: TASK-10
ordinal: 12000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
O pulo duplo e a stamina são as primeiras manobras da fase 1 (`movimento.md`, "O que o esqueleto andante usa"); o pulo duplo abre o bloco de 2 m e, com as plataformas da TASK-10.2, o vão de 6 m ("Métricas de nível"); o custo é o limite que nasce junto com a manobra (`movimento.md`:33; F-001). Esta filha fixa a forma da interface da fase inteira: o buffer de uma vaga e o `before_move` recebendo a posição entram aqui para nenhum teste travado ser reescrito depois (DEC-0009; DEC-0039, a aceitar, que substitui a DEC-0022 só nisso), e a SyncTest passa a comparar o estado inteiro gravado, o instrumento que pega um campo novo esquecido antes de virar bug de rede (`rede.md` §8; DEC-0027). Nenhum contato novo com o motor.

### Perguntas em aberto
Nenhuma depois das escolhas.

### Escolhas confirmadas
Confirmadas pelo Arthur em 19/10/2026 com "Fechar com os padrões (Recomendado)" (F-100 §1).
1. O buffer vira uma vaga só (`buffered_command` mais `buffered_tick`, no lugar do `jump_pressed_tick`): o último aperto vence; a alternativa era um carimbo por comando. O papel diz "Um buffer só, para todo comando" (`movimento.md`, "Perdão"; DEC-0016). É arquitetura: a DEC-0039 substitui a DEC-0022 só na vaga, na assinatura do `before_move` com a posição e na janela inclusiva que o código já usa.
2. Um aperto no ar com o pulo duplo disponível sai na hora, mesmo a poucos ticks do pouso; o pulo guardado para o pouso só vale com o pulo duplo gasto ou sem stamina. É uma regra só, sem adivinhar o pouso; o Arthur julga jogando (DEC-0017).
3. A tela de opções (teclas remapeáveis e escala, DEC-0031 §8) é a TASK-10.9, antes da v0.2.0; esta filha e a TASK-10.2 trazem o Theme único e as chaves de tradução.

Detalhe do Claude, com o ok do Arthur no modo de plano desta filha: a stamina guardada como valor mais carimbo (DEC-0022); o `before_move` recebendo a posição já aqui; a SyncTest comparando todos os campos gravados, com a posição até 1e-6 (hoje 1 mm; `rede.md` §4), enquanto a conferência da rede continua em 1 mm.

### Números v0 do Claude
Fechados pelo Claude (DEC-0017), escritos no `movimento.md` com o seu ok antes do test-writer rodar; você julga jogando.
- O pulo duplo no tick: `sqrt(2 · g_tick · tickrate · h) − g_tick / 2`, 6,10 m/s a 60 (topo de 0,9999 m no 19º tick) e 5,68 a 30, a mesma conta que dá o `jump_speed` (`movement_config.gd`:70-75). Vai para "Pulo e ar".
- Sem direção apontada, o pulo duplo mantém direção e módulo ("sem ganhar"); um aperto depois do coyote é o pulo duplo ("um por voo"). Vai para "Pulo e ar".
- A stamina é o valor logo depois do último gasto mais o carimbo do gasto; a barra se calcula pelo tick: `min(100, valor + 0,5 · max(0, tick − carimbo − 48))` a 60, porque carimbo nunca é contador (DEC-0022). Sem stamina suficiente, nada é pago e o aperto espera na vaga. Vai para "Stamina".
- O tempo do portão é medido em silêncio na rodada A (61 a 114 s no fechamento da TASK-9, contra os 90 s da DEC-0027 §1); acima de 90 s, a divisão do CI da DEC-0027 §4 vira uma DEC nesta filha e você ouve. Vai para o `testes-e-entrega.md`.

### Fora do escopo
- O HUD, o Theme e as plataformas do vão (TASK-10.2).
- Dash, parede e gancho (TASK-10.4 a TASK-10.6); o sinal visual do pulo duplo (TASK-10.4); a ordem do empate na vaga (TASK-10.4 e TASK-10.6); a cabeça do outro (TASK-10.7); a tela de opções (TASK-10.9).

### O que você vai aprender
- Por que o pulo duplo sai a 6,10 m/s e não a 6,26: a conta lisa contra a conta no tick.
- A stamina como carimbo mais valor: o "flash pronto às 12:30" do chat do LoL, uma barra que se calcula sozinha.
- O buffer de uma vaga: um debounce em que o último pedido vence.
- A SyncTest que compara o estado inteiro: o teste que pega o campo esquecido antes de virar bug de rede.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando o lutador aperta o pulo no ar, fora do coyote, com o pulo duplo ainda não usado no voo e pelo menos 10 de stamina (`double_jump_cost`), o núcleo faz o pulo duplo: o topo fica 1,0 m (`double_jump_height_m`) acima de onde ele apertou, com tolerância de 1 cm, a 30 e a 60 ticks; um segundo aperto no mesmo voo não pula de novo (`movimento.md`, "Pulo e ar"; leitura v0 do pulo duplo no tick).
- [ ] #2 Quando o lutador já usou o pulo duplo no voo, ou tem menos de 10 de stamina, um aperto no ar espera na vaga e vira o pulo do chão se o pouso vier em até 150 ms (9 ticks a 60, 5 a 30); um tick além da janela não pula; com o pulo duplo disponível, o aperto sai na hora, mesmo a poucos ticks do pouso (`movimento.md`, "Pulo e ar" e "Perdão"; DEC-0016; leitura v0).
- [ ] #3 Quando o lutador sai da beirada sem pular e aperta dentro dos 100 ms do coyote (6 ticks a 60, 3 a 30), sai o pulo cheio de 1,2 m e o pulo duplo continua disponível; quando aperta depois do coyote, sai o pulo duplo; tocar o chão renova o pulo duplo (`movimento.md`, "Pulo e ar": um por voo; "Perdão").
- [ ] #4 Quando o pulo duplo sai com uma direção apontada, a velocidade horizontal inteira vira para essa direção, relativa à câmera, com o mesmo módulo; sem direção, ela não muda (`movimento.md`, "Pulo e ar": "Mantém a velocidade horizontal, sem ganhar").
- [ ] #5 Quando o pulo duplo sai, a stamina cai 10; nos 800 ms seguintes (48 ticks a 60, 24 a 30) ela não recupera nada; depois recupera 30 por segundo (0,5 por tick a 60, 1,0 a 30) até 100, sem passar: vazia, ela enche em 200 ticks a 60 e 100 a 30 depois da espera (≈ 3,3 s de recuperação, 4,1 s contando a espera); com 9,5 de stamina o pulo duplo não sai, nada é pago e o aperto espera na vaga; com 10 exatos, sai e a barra fica em 0 (`movimento.md`, "Stamina").
- [ ] #6 Quando um novo aperto de pulo chega com um aperto ainda guardado, o novo substitui o antigo: a vaga é uma só e a janela conta do último aperto (`movimento.md`, "Perdão": "Um buffer só, para todo comando"; DEC-0016).
- [ ] #7 Quando um número novo do `movement_v0.tres` é impossível (altura do pulo duplo zero ou negativa, stamina máxima zero, custo maior que a máxima, espera ou recuperação negativas), a checagem dos dados reprova no portão com uma mensagem por número; quando a altura do pulo duplo muda numa cópia do Resource, o topo muda junto, sem tocar no código (TASK-10, critério 2; DEC-0004, regra 3).
- [ ] #8 Quando a SyncTest roda o cenário do pulo duplo e o do pouso com o rollback de 7 ticks a cada tick, ela compara todos os campos gravados (inteiros, booleanos e nomes exatos; floats, vetores e a posição até 1e-6) e acha zero divergências; o cenário conta pelo menos 3 pulos duplos, 1 depois da beirada, 1 recusado por stamina e os 2 pulos guardados do pouso; esconder `:state:stamina_at_spend` ou `:state:double_jump_tick` da gravação faz ela acusar; a referência da TASK-9 é regravada com o motivo no commit, porque o aperto no ar do passo 513 do percurso passa a ser um pulo duplo, e o `frozen_movement.tres` ganha os números novos de propósito; o tempo do portão em silêncio fica anotado contra os 90 s (`rede.md` §8; DEC-0027 §1 e §3; F-094 §2).
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

**State** (`core/fighter/fighter_state.gd`): remove `jump_pressed_tick`; add `buffered_command: StringName = &""`, `buffered_tick: int = NEVER`, `stamina_at_spend: float = 0.0`, `stamina_spent_tick: int = NEVER`, `double_jump_tick: int = NEVER`; `jumps_used` runs 0..2. Each new field: a line in `copy()`, a path in `fighter.tscn` `state_properties` (`:state:buffered_command`, `:state:buffered_tick`, `:state:stamina_at_spend`, `:state:stamina_spent_tick`, `:state:double_jump_tick`), a start value in `MovementRig._init`.

**Commands** (`core/fighter/fighter_command.gd`): `class_name FighterCommand`, `const NONE := &""`, `const JUMP := &"jump"`.

**Stamina** (`core/fighter/stamina.gd`, `class_name Stamina`): `static func at(state: FighterState, config: MovementConfig, tick: int) -> float` = `config.stamina_max` while `stamina_spent_tick == NEVER`, else `minf(config.stamina_max, state.stamina_at_spend + maxi(0, tick - state.stamina_spent_tick - config.stamina_wait_ticks) * config.stamina_regen_per_tick)`; `static func spend(next: FighterState, config: MovementConfig, tick: int, cost: float) -> void` sets `stamina_at_spend = at(next, config, tick) - cost`, `stamina_spent_tick = tick`.

**Data** (`MovementData`, `movement_v0.tres`, `frozen_movement.tres`): `double_jump_height_m: float = 1.0` (positive), `double_jump_cost: float = 10.0` (not negative, `<= stamina_max`), `stamina_max: float = 100.0` (positive), `stamina_wait_ms: int = 800` (time, may be 0), `stamina_regen_per_s: float = 30.0` (not negative; 0 in fixtures); one `validate()` message per bad number. **Config**: `double_jump_speed` by the `jump_speed` formula (6.096 / 5.678 m/s), `double_jump_cost`, `stamina_max` copied, `stamina_wait_ticks` (48 / 24), `stamina_regen_per_tick = stamina_regen_per_s / tickrate` (0.5 / 1.0).

**Movement**: `static func before_move(state: FighterState, _position: Vector3, velocity: Vector3, input: TickInput, config: MovementConfig, tick: int) -> MovePlan`; `after_move` unchanged; `Fighter` passes `global_position`.

**Conventions**: inside `before_move`: copy; `facing_yaw = input.yaw`; a press writes the slot (`JUMP`, `tick`), overwriting; motion by mode; then the slot fires if alive (`tick - buffered_tick <= config.buffer_ticks`, inclusive) and legal, and clears to `NONE`/`NEVER`; an alive, illegal press stays. Floor jump: `jumps_used == 0` and (`mode == GROUND` and `on_floor`, or `tick - left_floor_tick <= coyote_ticks`); `velocity.y = jump_speed`, `jumps_used = 1`. Double jump: `jumps_used == 1`, or `jumps_used == 0` in the air past the coyote, and `Stamina.at(...) >= double_jump_cost`; `velocity.y = double_jump_speed` (the press tick is step 1, apex at step `rise_ticks`), `jumps_used = 2`, `double_jump_tick = tick`, `Stamina.spend(...)`; horizontal with input `direction * horizontal.length()` where `direction = (Basis(Vector3.UP, input.yaw) * Vector3(input.move.x, 0, -input.move.y)).normalized()`, without input unchanged. `after_move` on the floor: `jumps_used = 0`, `double_jump_tick = NEVER`. Yaw 0 looks down −Z; stamps, never counters; every literal names its config field.

**Who tests what**: the test-writer writes criteria 1 to 7 blind (`test/core/fighter/movement_double_jump_test.gd`, `stamina_test.gd`, the `movement_data_test.gd` rows) and rewrites the six TASK-9 jump tests whose expectation changes (`movement_jump_test.gd` :342, :377, :398, :409, :418, :435: the air press now double-jumps; `jump_pressed_tick` reads become the slot); all locked. The implementer writes criterion 8: `SyncObserver.Sample` over every `state_properties` path by `get_indexed`, exact for int/bool/StringName, 1e-6 for float/Vector3 (`sync_observer.gd`:14; `net/prediction_check.gd` keeps 1 mm); the "pulo duplo" scenario on a `duplicate()`d, validated fixture (`stamina_max = 25.0`, `stamina_regen_per_s = 0.0`: 25 → 15 → 5 → refused; jump plus double jump onto Block2m; a double jump on the tick after a jump; one after the ledge); counters `double_jumps >= 3`, `ledge_double_jumps >= 1`, `refused_double_jumps >= 1`, `landings >= 3`, mismatches 0; the pouso HopBot keeps `buffered_jumps == 2`, gains `double_jumps >= 2`; two poison tests in the `_stop_recording` pattern (`fighter_sync_test.gd`:233-242); `fighter_scene_test.gd`:60-69 the paths.

**Rounds**: A (core, data, DEC-0039 in plan mode, the readings, the quiet gate measurement); B (observer, scenario, poison, TASK-9 artefacts, docs); C (review fixes, playtest).

| Agent | Model | Effort | Why |
|---|---|---|---|
| test-writer | Fable | high | blind rules with tick math at 30 and 60 |
| implementer | Opus 5.5 | xhigh | core plus the observer in one session |
| reviewer | Fable | high | every criterion with proof, the six reworked tests |
| explorer | Sonnet | high | only if the TASK-9 line numbers drifted |

## SyncTest (en)
"pulo duplo" and the adapted "pouso", forced 7-tick rollback every tick, whole-state compare, counters above, two poison tests; the six scenarios together under 5 s (DEC-0027 §3); suite time printed.

## Arena (en)
No change; Block2m is the target.

## Teste à mão e o que sentir
Subir o bloco de 2 m direto, com pulo e pulo duplo; apertar a poucos ticks do pouso e ver o pulo duplo sair na hora; gastar três pulos duplos seguidos e sentir a recusa (sem HUD ainda, só pelo corpo). O que sentir: o segundo pulo vira sem ganhar velocidade e tem o topo mais baixo; se a recusa parece injusta ou o aperto perto do chão parece errado, vira fonte. Perguntar o que ele sentiu só depois de jogar (F-041; F-055).

## Docs a atualizar
Com o seu ok em modo de plano e uma linha no `mudancas.md` cada: `movimento.md` (as linhas do pulo duplo e da stamina; as leituras v0 em "Pulo e ar", "Stamina" e "Perdão"); `glossario.md` (Voo, Custo, Espera para recuperar, Recuperação, Stamina no último gasto, Vaga do buffer); `rede.md` §4 e §8 (estado inteiro até 1e-6; a rede em 1 mm); `visao-geral.md` (a vaga, o par da stamina, `double_jump_tick`, `before_move(position)`); `testes-e-entrega.md` (o observador, o tempo do portão); DEC-0039 com `substitui: DEC-0022` e a linha de aviso na DEC-0022; a vitrine "pulo duplo em ticks" (DEC-0019); o diário e o `registro.md`.
<!-- SECTION:NOTES:END -->
