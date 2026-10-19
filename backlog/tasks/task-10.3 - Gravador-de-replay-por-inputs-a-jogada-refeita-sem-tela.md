---
id: TASK-10.3
title: 'Gravador de replay por inputs: a jogada refeita sem tela'
status: In Progress
assignee: []
created_date: '2026-10-19 13:46'
updated_date: '2026-10-19 19:02'
labels:
  - jogo
milestone: m-1
dependencies:
  - TASK-10.2
parent_task_id: TASK-10
ordinal: 14000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
A gravação do replay por inputs começa na fase 1 (F-044 §1; `roteiro.md`:24) e é o instrumento que reproduz uma divergência (DEC-0027 §5): quando você achar um bug jogando, o arquivo de teclas vai junto e o Claude refaz sem tela. Ela vem antes da primeira filha que muda um contato com o motor (o dash, TASK-10.4), porque a DEC-0025 localiza as divergências no contato com o motor e o replay é quem as reproduz. A F-042 §3 provou rastros iguais byte a byte só sem netfox e em `_physics_process`; o jogo roda os ticks em `_process`, e esta filha mede se o ao vivo e o sem tela ainda batem. Nenhuma regra nova do núcleo: o test-writer não roda.

### Perguntas em aberto
Nenhuma; a medição do critério 5 decide se o `sync_to_physics` volta a você.

### Escolhas confirmadas
Confirmada pelo Arthur em 19/10/2026 (F-112 §2): o Sozinho grava sempre, em `user://replays/`, guardando os 20 arquivos mais novos; os testes gravam numa pasta temporária, e o portão nunca escreve em `user://replays/`.

A outra escolha do rascunho, o `netfox/time/sync_to_physics`, não se decide nesta filha: se a medição do critério 5 mostrar diferença entre o ao vivo e o sem tela, o Claude volta ao Arthur com os números antes da TASK-10.4, e a mudança, se vier, é uma DEC nova no modo de plano (F-112, contexto; F-025 §5).

### Números v0 do Claude
Fechados pelo Claude (DEC-0017); escritos no `testes-e-entrega.md` §4 nesta filha.
- Os floats vão como os 8 bytes do double em hexadecimal (16 dígitos), e `--readable` escreve uma cópia em decimal, porque `%.9f` perde bits perto de π e um yaw de mouse nunca é redondo (F-042 §3).
- O cabeçalho leva todos os números do movimento, tipados, e o tocador toca com eles mesmo depois de um ajuste no `.tres`; formato, ticks por segundo, arena e configurações de física e relógio recusam sem apelo; versão, commit, impressão das regras e da arena recusam e passam com `--force` (F-042 §4).
- Uma coluna `check` opcional guarda a impressão do estado depois de cada tick ao vivo, para o tocador dizer o primeiro tick em que se separa.
- Salva a cada segundo (`FileAccess.flush` a cada 60 ticks): um fechamento brusco perde no máximo o último segundo. O cliente e o servidor não gravam na v1.
- A impressão das regras é o sha256 dos scripts que movem o corpo, calculado dos arquivos quando o jogo roda do código-fonte, como o Arthur joga; na build exportada ela fica vazia, porque o commit já identifica a build, e o tocador só compara quando as duas existem.
- O rastro conta os ticks a partir do primeiro tick gravado, e os carimbos do estado também, para a janela do `--watch`, que roda com o relógio de verdade e começa noutro tick, ser comparável ao tocador sem tela.

### Fora do escopo
- O fantasma do percurso cronometrado (fase 2; DEC-0036). A gravação no cliente e no servidor. Refazer em outra build ou plataforma (F-042 §4 e §5). Comprimir o arquivo. Qualquer regra do núcleo.

### O que você vai aprender
- Event sourcing: guardar a ação de cada tick, não o estado, como o Redux DevTools refaz a tela pelas actions.
- Os bits de um float: o `0.1 + 0.2` do JavaScript, e por que o yaw do mouse nunca é redondo.
- Onde o determinismo vaza: o mesmo código com outro tamanho de quadro (`physics_factor`), como um teste que lê `Date.now()`.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando o Arthur joga no Sozinho, o jogo grava sozinho um arquivo `.replay` em `user://replays/`, mostra o caminho completo no log, guarda os 20 mais novos, grava em `--replay=CAMINHO` quando ele vem e desliga com `--no-replay`; salva a cada segundo, e um fechamento brusco perde no máximo o último segundo; o portão nunca escreve em `user://replays/` (leituras v0 do Claude no `testes-e-entrega.md` §4; F-044 §1).
- [ ] #2 Quando o arquivo é gravado, o cabeçalho traz formato, versão, commit, impressão das regras, motor, plataforma, ticks por segundo, `physics_ticks_per_second`, `sync_to_physics`, `max_ticks_per_frame`, `input_delay`, arena e sua impressão, semente e a configuração inteira (um campo do `MovementData` por linha, tipado), e as colunas declaradas por nome e tipo; cada linha tem o tick absoluto do netfox, o tamanho do laço e o input que o Sozinho aplicou naquele tick, por lutador (F-044 §2; DEC-0027 §5).
- [ ] #3 Quando um float do input é gravado e lido de volta, ele volta com os mesmos bits: o teste usa yaw com muitos dígitos, `1.0/3.0`, médias de 2 a 3 frames no move, `-0.0`, `PI` e `1e-300`; uma célula de float que não tem exatamente 16 dígitos hexadecimais é recusada, nunca lida como 0 (F-042 §3; `PackedByteArray.xml`:104-110).
- [ ] #4 Quando o tocador sem tela refaz um arquivo, ele roda a partida de verdade pelo `Match`, laço a laço, com o relógio começando no primeiro tick gravado, reconstrói o `MovementData` do cabeçalho e emite o rastro de estado inteiro e o seu sha256; refazer duas vezes dá o mesmo sha256; um teste no portão grava uma corrida com yaw e move fracionários, pulos duplos e laços de 2 ou mais ticks, prova a precondição (yaw diferente de zero, moves fora de {-1, 0, 1}, um laço com 2 ticks) e prova que a refeita dá o mesmo rastro byte a byte; quando não dá, diz o tick, o lutador e a coluna com os dois valores (F-042 §3; DEC-0027 §5).
- [ ] #5 Quando a mesma gravação toca com janela pelo `--watch --trace` a 30, 60 e 144 quadros por segundo (`--max-fps`) e sem janela pelo `replay.sh`, os rastros, contados a partir do primeiro tick gravado, com os carimbos do estado também, saem iguais byte a byte; o `--watch` anota o tamanho de cada laço que rodou; se os rastros não saírem iguais, o resumo diz o primeiro tick que difere e se o laço ali tinha o mesmo tamanho do gravado, os números vão ao Arthur e a escolha do `sync_to_physics` volta a ele antes da TASK-10.4 (`testes-e-entrega.md` §4; F-025 §5; F-042 §3).
- [ ] #6 Quando o arquivo traz a coluna de conferência, o tocador diz o primeiro tick em que a refeita se separa do que o jogo calculou ao vivo, ou que não se separa (DEC-0027 §5).
- [ ] #7 Quando o arquivo é de outro formato, outros ticks por segundo, outra arena ou outras configurações de física e de relógio, tem uma coluna desconhecida, uma linha quebrada ou uma célula malformada, o tocador recusa e diz o campo; de outra versão, commit, impressão das regras ou da arena, recusa, diz qual e só toca com `--force`; com `--force`, uma coluna que falta recebe o valor padrão do `TickInput` com um aviso que a nomeia; um salto de tick do netfox é tocado como salto; uma última linha cortada é descartada com aviso (`testes-e-entrega.md` §4; F-042 §4).
- [ ] #8 Quando o Arthur joga uns minutos e roda `bash tools/replay.sh <arquivo> --watch`, ele vê a própria jogada refeita na tela; o que ele sentiu vai para uma fonte (F-043; F-041).
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
## O plano (para o implementer; sem test-writer, DEC-0009)

Nenhuma regra nova do núcleo. O rascunho em inglês das notas desta task é o detalhe; aqui ficam as decisões e os dois consertos da crítica de completude.

**O arquivo, formato v1** (`replay/replay_file.gd`, `ReplayFile`, `FORMAT := 1`): texto UTF-8 com `\n`. O cabeçalho em `chave=valor`: formato, versão e commit (`BuildStamp`), a impressão das regras, o motor, a plataforma, os ticks por segundo, `physics_ticks_per_second`, `sync_to_physics`, `max_ticks_per_frame`, `input_delay`, a arena e a impressão dela, a semente (0), a configuração inteira (um campo do `MovementData` por linha, tipado), os lutadores, o primeiro tick e as colunas declaradas por nome e tipo; depois `---` e uma linha por tick e lutador: o tick absoluto, o tamanho do laço, o lutador, o input (os floats como os 8 bytes do double em 16 dígitos hexadecimais) e a coluna `check`.

**A impressão das regras** (conserto): o sha256 do texto dos scripts que movem o corpo (`core/`, `fighter/`, `match/`, `arena/`, `data/*.gd`, em ordem de caminho) mais a fixação do netfox `cf5189d`, calculado dos arquivos quando o jogo roda do código-fonte; vazio na build exportada, onde o commit identifica a build. O tocador só compara quando as duas existem. Nada muda no `tools/stamp_build.sh` nem no CI.

**O gravador** (`replay/replay_recorder.gd`, `ReplayRecorder`, um Node): no `NetworkRollback.after_process_tick`, para cada lutador vivo com o input daquele tick, anota o input; `FileAccess.flush()` a cada 60 ticks; o arquivo `sozinho-AAAAMMDD-HHMMSS.replay` em `user://replays/`, os 20 mais novos guardados, o caminho completo no log (F-112 §2). O `LaunchOptions` ganha `--replay=`, `--replay-dir=`, `--no-replay`, `--watch=` e `--trace=`, só no Sozinho; o `test/main/main_test.gd` passa `--no-replay`, e o portão nunca escreve em `user://replays/`.

**A entrada na reprodução**: o `FighterInput` continua o único que escreve a caixa de input; `FighterInput.play_rows(source)` faz o `_on_after_tick` tomar a linha gravada no lugar do amostrador, sem passar pelo `limit_length` nem pela média; um teste prova que a caixa sai igual à linha.

**O tocador sem tela** (`tools/replay_play.tscn`, `ReplayRun`, no molde do `ReferenceRun`): a partida de verdade pelo `Match`, com o `MovementData` do cabeçalho, laço a laço como foi gravado, com o relógio começando no primeiro tick gravado pelo ajudante dos testes (a exceção da DEC-0027); emite o rastro do estado inteiro e o sha256; `bash tools/replay.sh ARQUIVO [--force] [--watch [--max-fps N]] [--readable=SAÍDA] [--trace=SAÍDA]`.

**O rastro** (conserto; `replay/state_trace.gd`, `StateTrace`): uma linha por tick e lutador, com os ticks e os carimbos do estado contados a partir do primeiro tick gravado (o `NEVER` fica `NEVER`), para o `--watch`, que roda com o relógio de verdade e começa noutro tick, ser comparável; `first_difference(a, b)` diz o tick, o lutador, a coluna e os dois valores.

**O `--watch`**: um Sozinho com o relógio de verdade, o input do arquivo, a câmera no lutador e o texto de fim por chave de tradução; ele não escreve no relógio do netfox (código do jogo, fora da exceção da DEC-0027) e anota o tamanho de cada laço que rodou, para o resumo dizer se uma diferença caiu num laço de tamanho diferente do gravado.

**Os testes** (`test/replay/`, uns 600 ticks, com o tempo impresso): a ida e volta com precondição (yaw diferente de zero, moves fora de {-1, 0, 1}, um laço de 2 ticks, pulos duplos); o float bit a bit (`1.0/3.0`, `-0.0`, `PI`, `1e-300`, uma média de float32); a célula malformada recusada, nunca lida como 0; o cabeçalho; as recusas que dizem o campo; a coluna que falta só com `--force`; a última linha cortada; o salto de tick; a rotação dos 20 numa pasta temporária; as guardas do `Engine.time_scale` e do CR da referência.

**A medição** (critério 5): uma gravação tocada pelo `--watch --trace` a 30, 60 e 144 quadros por segundo contra o `replay.sh`. Se os rastros diferirem, os números vão ao Arthur antes da TASK-10.4, e o `sync_to_physics` só muda numa DEC nova, no modo de plano.

**Os docs** (uma linha no `mudancas.md`): o `testes-e-entrega.md` §4 reescrito (o formato, o tocador, os limites, `user://replays/`, o tamanho) e o §12 com o `tools/replay.sh`; o `rede.md` §8 ("todo replay de bug vai com o arquivo"); o glossário (gravador, arquivo, laço de ticks, tocador, rastro, impressão do estado, impressão das regras, colunas declaradas).

**Rodadas:** A (o arquivo, o gravador, o tocador e os testes); B (o `--watch`, a medição, o script e os docs); C (o teste à mão).

| Agente | Modelo | Effort | Por quê |
|---|---|---|---|
| implementer | Opus 5.5 | xhigh | o formato, a entrada e o tocador numa sessão |
| reviewer | Fable | high | determinismo pede prova, não leitura |
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Rascunho do plano da fase 1 (19/10/2026), em inglês para os agentes; vira o plano em português quando a filha ficar Ready (F-100).

**Format v1** (`replay/replay_file.gd`, `class_name ReplayFile`, `const FORMAT := 1`): text, UTF-8, `\n`. Header `key=value` lines: `format`, `version`, `commit` (`BuildStamp.current()`), `rules` (sha256 over the text of `core/**`, `fighter/**`, `match/**`, `arena/**`, `data/*.gd` sorted by path plus the netfox pin `cf5189d`; computed at build time beside `commit`, from the files in the editor; compared only when both non-empty), `engine`, `platform`, `tickrate`, `physics_ticks_per_second`, `sync_to_physics`, `max_ticks_per_frame`, `input_delay`, `arena` (`Match.ARENA_SCENE.resource_path`), `arena_sha256` (over every `CollisionShape3D` under the arena: relative path, shape type, size, transform relative to `Arena`, f64 hex; a non-`BoxShape3D` is refused until named), `seed=0`, `config=res://data/movement_v0.tres`, `config.<prop>:<type>=<cell>` per exported property, `fighters`, `first_tick`, `columns=tick:int,loop:int,fighter:int,move.x:f64,move.y:f64,yaw:f64,jump:bool,check:hex8`, then `---`. Rows: one per (tick, fighter), `tick` absolute, `loop` the ticks in that loop; bools `0`/`1`; `f64` = 16 lowercase hex digits of a `PackedByteArray` after `resize(8)` and `encode_double(0, v)`, read by `hex_decode()` then `decode_double(0)`, length checked first; `str` cells hex-encoded UTF-8. Columns by reflection over `TickInput` (`fighter_scene_test.gd`:72-81), a `Vector2` as `.x`/`.y`; readers map by name.

**Recorder** (`replay/replay_recorder.gd`, `class_name ReplayRecorder extends Node`, `@export var directory: String`): on `NetworkRollback.after_process_tick`, for each followed alive fighter with `get_input_age() == 0`, appends that tick's input from `fighter.input` (pattern `net/tick_recorder.gd`:14-20, :65-79), last write per tick wins; `FileAccess.flush()` every 60 ticks; file `<dir>/sozinho-AAAAMMDD-HHMMSS.replay`; keeps the newest 20.

**Feeding** (`ReplaySource`, `FighterInput.play_rows(source: ReplaySource) -> void`): `_on_after_tick` takes the row instead of the sampler, just before `NetworkRollback._after_tick` records it; `FighterInput` stays the only writer of its box; a test asserts the box equals the row.

**Player**: `tools/replay_play.tscn/.gd` (`ReplayRun`, copying `ReferenceRun`, `reference_run.gd`:34-72): `NetfoxTicks.reset()`, the clock at `first_tick` (the `netfox_ticks.gd`:28-29 exception), a `SubViewport` with its own world, the real `Match` with `movement_data` from the header, `spawn_fighter` per slot, per loop `source.load_rows()` and `NetfoxTicks.run_loop(n)`; prints `replay: played N ticks in X ms, sha256 H, first divergent tick K|none`; fails on any `ERROR:`. `bash tools/replay.sh FILE [--force] [--watch [--max-fps N]] [--readable=OUT] [--trace=OUT]`. `StateTrace` (`replay/state_trace.gd`): one line per (tick, fighter), columns from `state_properties`, f64 hex; `sha256()`, `first_difference(a, b)`. `LaunchOptions` gains `--replay=`, `--replay-dir=`, `--no-replay`, `--watch=`, `--trace=`, Sozinho only, exit 2 on misuse; `Main.start_solo` starts the recorder, `end_session` closes it; `test/main/main_test.gd` passes `--no-replay`. Watch: a Sozinho match with the real clock, inputs from the file, the camera on slot 0, `GameText` "fim do replay".

**Who tests what**: no test-writer. The implementer writes `test/replay/` (≈ 600 ticks, time printed): round trip with precondition, f64 bit-for-bit, malformed cell refused, header contents, hard refusals naming the field, missing column only with `--force`, cut last line, tick gap, newest-20 rotation in a temp dir; the `Engine.time_scale` and CR guards of `route_reference_test.gd`:19-22, :56-61 copied. The reviewer checks the precondition and that the gate never writes in `user://replays/`.

**Rounds**: A (file, recorder, player, tests); B (watch, the fps sweep, the script, docs); C (playtest).

| Agent | Model | Effort | Why |
|---|---|---|---|
| implementer | Opus 5.5 | xhigh | file format, feeding and the player in one session |
| reviewer | Fable | high | determinism claims need proof, not reading |
| explorer | Sonnet | high | to map `tick_recorder.gd` and `reference_run.gd` before round A |

## SyncTest (en)
None new. Each later child adds its maneuver to the recorded test session.

## Arena (en)
None.

## Teste à mão e o que sentir
Jogar 2 a 3 minutos no Sozinho, fechar o jogo, rodar `bash tools/replay.sh <arquivo> --watch` e se ver jogando; o Claude refaz sem tela e diz o primeiro tick divergente, se houver. O que sentir: "ele lembrou exatamente o que eu fiz" (F-043), e qualquer desvio que você veja na tela vai para uma fonte antes do número.

## Docs a atualizar
Com o seu ok e uma linha no `mudancas.md` cada: `testes-e-entrega.md` §4 reescrito (formato v1, tocador, limites, `user://replays/`, tamanho em hexadecimal; §12 ganha `tools/replay.sh`; a linha :94 refeita) e §3 (a medição); `rede.md` §8 ("todo replay de bug vai com o arquivo"); `glossario.md` (Gravador de replay, Arquivo de replay, Laço de ticks, Tocador de replay, Rastro de estado, Impressão do estado, Impressão das regras, Colunas declaradas); a vitrine com o painel do replay; a DEC do `sync_to_physics` só se a medição pedir; o diário e o `registro.md`.
<!-- SECTION:NOTES:END -->
