---
id: TASK-10.8
title: 'O teste dos 15 minutos: o bot com manobras, a Q-16 online e a versão 0.2.0'
status: To Refine
assignee: []
created_date: '2026-10-19 13:47'
updated_date: '2026-10-19 13:47'
labels:
  - jogo
milestone: m-1
dependencies:
  - TASK-10.7
  - TASK-10.9
parent_task_id: TASK-10
ordinal: 19000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
O teste da fase é "divertido sozinho por 15 min?" (`roteiro.md`:13; F-001), o critério 1 da TASK-10. Antes dele, a rede precisa conhecer as manobras novas: o bot da corrida de 30 s ganha o pulo duplo e o dash, e a ping 100 o servidor e os clientes têm de bater em todos os ticks (`rede.md` §8 e §10). A Q-16 se decide com você jogando online contra o bot, e vira DEC (DEC-0036; DEC-0015). O critério 2 da TASK-10 ganha o seu teste pela cópia do Resource (DEC-0017). Se os 15 minutos disserem "não", o motivo vira fonte e as filhas de ajuste nascem com `-p TASK-10`; se disserem "sim", esta filha fecha a TASK-10 e sobe a versão para 0.2.0 no mesmo PR (DEC-0028 §3 e §4.3).

### Perguntas em aberto
Nenhuma; a Q-16 e a Q-07 se respondem jogando aqui.

### Escolhas a confirmar
1. O bot da corrida em rede ganha o pulo duplo (350 ms depois do pulo de cada perna) e o dash (no meio de cada perna, já da TASK-10.4); a parede e o gancho online esperam a fase 3. Padrão: sim, porque as duas cabem na rota reta do bot sem geometria nova, e a parede e o gancho online dependem da pergunta do tick previsto (TASK-10.6, "Fora do escopo").
2. A TASK-10 fecha no PR desta filha, com a versão 0.2.0 e a tag `v0.2.0` como segunda release, com o seu ok. Padrão: sim, porque a fase termina quando o teste dela passa (DEC-0028 §3), e as filhas de ajuste, se houver, nascem antes do fechamento.

### Números v0 do Claude
Fechados pelo Claude (DEC-0017).
- A corrida de 30 s exige zero ticks corrigidos e zero faltando a ping 100, como na TASK-9, com o tempo do portão anotado contra os 90 s (`rede.md` §10).
- O teste do critério 2 da TASK-10 muda o pulo duplo de 1,0 para 1,5 m numa cópia do Resource e mede o topo pela simulação, sem tocar no código.
- O ajuste fino só por dados: o que você pedir muda no `.tres`, no `movimento.md` e na vitrine, no mesmo link (DEC-0019); nenhum número muda no código.
- Os 15 minutos são cronometrados, no Sozinho com o boneco, com o kit inteiro: pulo duplo, dash, parede e gancho.

### Fora do escopo
- O combate (fase 2). O bot que reage. O percurso cronometrado com fantasma (fase 2).
- A bancada do Mac (Q-24, task pequena separada). A Q-13, só se você falar dela.

### O que você vai aprender
- Decidir uma regra jogando: o que muda entre "achei estranho" e "é assim".
- O que o teste da fase mede, e o que fazer quando ele diz "não".
- O netcode com manobras: por que um bot que dá dash a ping 100 prova mais que mil testes do núcleo.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando o `tools/net_run.sh` roda 30 s com os bots dando pulo duplo e dash, a corrida passa a ping 100 com zero ticks corrigidos e zero faltando, e o tempo do portão fica anotado contra o limite de 90 s (`rede.md` §8 e §10; DEC-0027 §1).
- [ ] #2 Quando um número de movimento muda numa cópia do Resource (o pulo duplo de 1,0 para 1,5 m), o jogo muda sem tocar no código, e um teste prova isso pela cópia (TASK-10, critério 2; DEC-0017; DEC-0004, regra 3).
- [ ] #3 Quando o Arthur sobe na cabeça do boneco e joga online contra o bot pelo `tools/play_online.sh 100`, o que ele sentiu sobre a Q-16 vai para uma fonte e a decisão vira DEC, com a pendência datada; se ele decidir o contrário da regra, a filha de ajuste nasce com `-p TASK-10` (DEC-0036; DEC-0015).
- [ ] #4 Quando o Arthur joga 15 minutos cronometrados sozinho na arena com o kit inteiro, ele quer continuar; o que ele sentiu e as técnicas que achou vão para uma fonte (Q-07), e os números que ele pedir mudam no `.tres`, no `movimento.md` e na vitrine, no mesmo link, sem tocar no código; quando ele não quer continuar, o motivo vira fonte e as filhas de ajuste nascem com `-p TASK-10` (F-001; TASK-10, critério 1; DEC-0017; DEC-0019).
- [ ] #5 Quando os 15 minutos passam e o Arthur dá o ok, o PR marca os critérios 1 e 2 da TASK-10, fecha a TASK-10, sobe a versão para 0.2.0 no mesmo commit, e a tag `v0.2.0` vira a segunda release com notas em português tiradas do diário (DEC-0028 §3 e §4.3; DEC-0033).
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

**Bot**: `BotRoute` gains `double_jumps_at(step)` (a jump press 350 ms after each leg's jump, the apex) beside `dashes_at(step)` from TASK-10.4; `BotPlayer` presses through `FighterInput.press_jump()/press_dash()`; the net-run CSV gains the counters `double_jumps` and `dashes` per client, asserted > 0 (the precondition of the run). **The TASK-10 #2 test**: `test/data/movement_tuning_test.gd`: `duplicate()` `movement_v0.tres`, set `double_jump_height_m = 1.5`, `validate()` empty, `MovementConfig.create` and a `MovementRig` flight: apex 1.5 m within 1 cm at 60; the cached resource untouched (DEC-0004 rule 3). **Version**: `application/config/version = "0.2.0"` in the closing commit; `docs/releases/v0.2.0.md`. **Sources**: one F for the Q-16 session, one F for the 15 minutes; the Q-16 DEC with `pendencias.md` dated.

**Who tests what**: no test-writer (no new core rule). The implementer writes the tuning test, the bot presses and the CSV counters. The reviewer checks all five, including that the F sources exist and the DEC is indexed before the close.

**Rounds**: A (bot, net_run, tuning test); B (the Q-16 session online and its DEC; the 15 minutes; tuning by data only); C (close: docs, release notes, version, PR, with Arthur's ok).

| Agent | Model | Effort | Why |
|---|---|---|---|
| implementer | Opus 5.5 | xhigh | netcode with new maneuvers, tuning by data |
| reviewer | Fable | high | the close of the mother task: every criterion with proof |
| explorer | Sonnet | high | to list the open Qs and the release notes format |

## SyncTest (en)
None new; the eight scenarios stay green; `tools/net_run.sh` at ping 100 is the proof of this child.

## Arena (en)
None new; tuning may move a body only with a re-recorded reference and the reason in the commit.

## Teste à mão e o que sentir
Primeiro a Q-16: `bash tools/play_online.sh 100`, subir na cabeça do bot, decidir. Depois os 15 minutos cronometrados no Sozinho com o boneco e o kit inteiro: o vão, o corredor, as torres, o pilar. O que sentir: se você quer continuar (F-001); as técnicas que você descobriu (Q-07); os números que você quer mudar, dito como sensação ("o gancho demora") antes do número.

## Docs a atualizar
Com o seu ok e uma linha no `mudancas.md` cada: `movimento.md` (os números ajustados e o resultado do teste da fase); `rede.md` §10 (as manobras do bot e os números da corrida); `pendencias.md` (Q-16 e Q-07 datadas); a DEC da Q-16 e o índice; `roteiro.md` (a fase 1 fechada e o portão da fase 2); `docs/releases/v0.2.0.md`; a vitrine com os números finais, no mesmo link (DEC-0019); o diário e o `registro.md`; a TASK-10 fechada com os dois critérios marcados.
<!-- SECTION:NOTES:END -->
