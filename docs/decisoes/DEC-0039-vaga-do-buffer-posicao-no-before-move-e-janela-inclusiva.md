---
id: DEC-0039
titulo: A vaga do buffer, a posição no before_move e a janela inclusiva — a DEC-0022 muda só nisso
data: 2026-10-19
status: aceita
decidido_por: Arthur (F-100 §1)
fontes: [F-084, F-100]
substitui: DEC-0022, só o jump_pressed_tick como carimbo do buffer, a assinatura before_move(state, velocity, input, config, tick) e a janela estrita tick − carimbo < buffer_ticks
substituida_por:
---

# DEC-0039 — A vaga do buffer, a posição no `before_move` e a janela inclusiva: a DEC-0022 muda só nisso

## Contexto

A DEC-0022 deu ao estado do lutador o `jump_pressed_tick`, o carimbo do aperto do pulo, com a regra `tick - jump_pressed_tick < buffer_ticks`, e fixou a assinatura `before_move(state, velocity, input, config, tick)`. O esqueleto andante (TASK-9) já implementou a janela inclusiva, `tick − carimbo ≤ janela`, como o plano da TASK-9 combinou para as duas janelas, o buffer e o coyote (`core/fighter/movement.gd`, `_within`); o texto da DEC e o código divergiam desde então.

A fase 1 traz o dash e o gancho, e o papel diz "Um buffer só, para todo comando" (`movimento.md`, "Perdão"; DEC-0016). Um carimbo só do pulo não serve para três comandos. O gancho precisa da posição do corpo dentro do `before_move` (a mira sai do pivô; TASK-10.6), e introduzir a posição na assinatura só lá reescreveria testes de aceite travados nas filhas anteriores (DEC-0009).

O blueprint da fase 1, feito pelo único workflow da TASK-10 e refutado por cinco verificadores, propôs as três mudanças juntas na primeira filha (TASK-10.1), para a interface da fase ser combinada uma vez.

## Opções consideradas

1. **Um carimbo por comando** (`jump_pressed_tick`, `dash_pressed_tick`, `grapple_pressed_tick`): guarda um pulo e um gancho apertados juntos; três campos a mais no estado; lê "um buffer só" como "uma janela só".
2. **Uma vaga só** (`buffered_command` e `buffered_tick`): o último aperto vence; menos estado; lê "um buffer só" ao pé da letra. A escolhida.
3. **Deixar a assinatura como está** e introduzir a posição na TASK-10.6: os testes travados da TASK-10.1 à TASK-10.5 seriam reescritos.

## Decisão

Aceita pelo Arthur em 19/10/2026: "Fechar com os padrões (Recomendado)" (F-100 §1). A pergunta dizia: "(1) o buffer vira uma vaga só, o último aperto vence, e a DEC-0039 substitui a DEC-0022 só nisso, na assinatura com a posição e na janela inclusiva".

1. **A vaga do buffer.** O `FighterState` troca o `jump_pressed_tick` por `buffered_command` (um `StringName`: `&"jump"`, depois `&"dash"` e `&"grapple"`; vazio quando não há aperto) e `buffered_tick` (o tick do aperto). Um aperto novo ocupa a vaga, substituindo o anterior. O aperto vale enquanto `tick − buffered_tick ≤ buffer_ticks`; quando sai, a vaga esvazia; quando ainda não pode sair, espera até a janela fechar.
2. **A posição no `before_move`.** A assinatura passa a ser `before_move(state, position, velocity, input, config, tick)`. A posição entra na TASK-10.1 e fica sem uso até o gancho (TASK-10.6).
3. **A janela inclusiva.** Um aperto vale no tick `t` enquanto `t − carimbo ≤ janela`, para o buffer e para o coyote, como o código da TASK-9 já faz. A DEC-0022 dizia `<`.
4. **O empate no mesmo tick:** o pulo vence o dash, que vence o gancho (leitura v0 do Claude, `movimento.md`, "Perdão"; vale quando eles existirem).

## Consequências

- A DEC-0022 ganha o aviso de substituição parcial no topo e continua valendo no resto.
- O `visao-geral.md` ("O estado em quatro caixas") passa a listar a vaga, a stamina como valor mais carimbo e o `double_jump_tick`, e a assinatura nova; o `rede.md` §3 continua: o buffer não mora no input.
- Os testes da TASK-9 que leem o `jump_pressed_tick` ou esperam que um aperto no ar não faça nada são reescritos pelo test-writer da TASK-10.1 e travados com os novos; o `fighter.tscn` troca o caminho `:state:jump_pressed_tick` pelos dois da vaga.
- O netfox grava a vaga como grava o resto do estado; a SyncTest da TASK-10.1 compara o estado inteiro.

## Revisitar se

- Jogando, dois comandos apertados dentro de 150 ms se perderem com frequência: a opção 1 volta, com uma DEC que substitui esta.
- O gancho não precisar da posição no `before_move`: a assinatura pode voltar, por DEC, antes da fase 2.
