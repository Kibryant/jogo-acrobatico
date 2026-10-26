---
id: TASK-10.9
title: 'A tela de opções: as teclas remapeáveis e a escala da interface'
status: In Progress
assignee: []
created_date: '2026-10-19 13:47'
updated_date: '2026-10-26 21:31'
labels:
  - jogo
milestone: m-1
dependencies:
  - TASK-10.2
parent_task_id: TASK-10
ordinal: 18700
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
A DEC-0031 §8 pede teclas por posição física, remapeáveis e salvas em `user://`, mostradas com o rótulo do teclado ativo, e a escala da interface (`content_scale_factor`, de 0,8 a 1,5) exposta nas opções. A TASK-9 adiou a tela para a primeira cena de interface, e o Arthur escolheu que ela venha como filha própria, depois do HUD (TASK-10.2) e antes da v0.2.0, a primeira release com o kit da fase (F-100 §1). O `movimento.md` chama a sensibilidade do mouse de "ajuste do jogador" ("Câmera"), e ela entra na mesma tela (F-161). Vitrine "A tela de opções": https://claude.ai/artifact/5qsxUQ4t9sbyYXD9XG6aNR.

### Perguntas em aberto
Nenhuma. O Arthur respondeu em 26/10/2026 (F-161): a sensibilidade entra; o Sozinho não pausa com a tela aberta; o botão do meio e os laterais do mouse valem para uma ação.

### Escolhas a confirmar
Confirmadas:
1. A tela abre com o Esc, no Sozinho e online, onde quem joga tem tela; lista as sete ações do `InputMap` (andar nas quatro direções, pular, dash, gancho) com o rótulo da tecla física no teclado ativo; apertar outra tecla, ou o botão do meio ou um lateral do mouse, remapeia na hora; o arquivo é `user://options.cfg` (F-161; DEC-0031 §8).
2. A escala vai de 0,8 a 1,5 por `content_scale_factor`, de 0,1 em 0,1, salva no mesmo arquivo (DEC-0031 §8).
3. A sensibilidade vai de 0,02 a 0,20 grau por pixel, de 0,005 em 0,005, com o padrão 0,06, salva no mesmo arquivo, e a tela mostra a volta em cm a 800 DPI (F-161).
4. Com a tela aberta, o jogo não pausa: o lutador de quem joga fica parado, porque as teclas vão para a tela, e o mouse aparece; ao fechar, o mouse volta para a câmera (F-161).
5. A tela usa o Theme único da TASK-10.2 e as chaves de tradução, com pt-BR e en, e tem o botão "Voltar ao padrão".

### Números v0 do Claude
- Os passos da escala: 0,8, 0,9, 1,0, 1,1, 1,2, 1,3, 1,4 e 1,5 (a sonda do Desenho 5 subiu até 1,2; F-051 §4.4).
- A sensibilidade: de 0,02 a 0,20 grau por pixel, de 0,005 em 0,005: uma volta de 57 cm a 5,7 cm a 800 DPI.

### Fora do escopo
- Gamepad (Q-31). Menus além desta tela. O leitor de tela na partida (DEC-0031 §8). Som. O campo de visão.
- O botão esquerdo e o direito do mouse numa ação: ficam livres para o combate da fase 2.

### O que você vai aprender
- O `InputMap` em tempo de execução: trocar a tecla de uma ação sem tocar no `project.godot`.
- O rótulo de uma tecla física: por que "W" vira "Z" num teclado francês, e `keyboard_get_label_from_physical`.
- A escala da interface: um número que multiplica a tela inteira, como o zoom do navegador.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Quando o jogador abre as opções com o Esc, no Sozinho ou online, cada uma das sete ações aparece com o rótulo da tecla física no teclado ativo, e apertar outra tecla, ou o botão do meio ou um lateral do mouse, a remapeia; a mudança vale na hora e sobrevive ao fechar e abrir o jogo, salva em `user://options.cfg` (DEC-0031 §8; F-161)
- [x] #2 Quando o jogador muda a escala, a interface escala de 0,8 a 1,5 sem cortar a barra de stamina, as recargas nem a mira, a mira segue no centro da tela com a câmera livre, e o valor sobrevive ao reiniciar (DEC-0031 §8)
- [x] #3 Quando o jogador muda a sensibilidade, de 0,02 a 0,20 grau por pixel, a câmera gira com ela na hora, a tela mostra a volta em cm a 800 DPI, e o valor sobrevive ao reiniciar (F-161; `movimento.md`, "Câmera")
- [x] #4 Quando a tela está aberta, o jogo não pausa, o lutador de quem joga fica parado e o mouse aparece; ao fechar, o mouse volta para a câmera e as teclas voltam ao lutador (F-161)
- [x] #5 Quando o arquivo de opções está corrompido, tem uma tecla inválida, uma escala ou uma sensibilidade fora da faixa, o jogo volta ao padrão de cada entrada ruim, avisa no log e não trava; "Voltar ao padrão" restaura tudo
- [x] #6 Quando duas ações recebem a mesma tecla, a tela diz de qual ação ela já é, e a troca não vale até o conflito sumir
- [ ] #7 Quando o Arthur remapeia o dash e o gancho, muda a escala e a sensibilidade e joga, o que ele sentiu vai para uma fonte (F-041)
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [x] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [x] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Rascunho do plano da fase 1 (19/10/2026), em inglês para os agentes; vira o plano em português quando a filha ficar Ready (F-100).

`ui/options/options_screen.tscn` and `options_screen.gd` (`OptionsScreen`, CanvasLayer, opened by `ui_cancel` in Sozinho); `ui/options/options_store.gd` (`OptionsStore`, RefCounted: `load()`, `save()`, `apply()` over `InputMap` and `get_tree().root.content_scale_factor`; file `user://options.cfg` via `ConfigFile`; a `validate()` that names each bad entry and falls back to the defaults); the labels through `DisplayServer.keyboard_get_label_from_physical`; translation keys for every string (`GameText`); a test for the store (round trip, corrupted file, conflict). No core rule: adapters and scenes only, so no test-writer. Rounds: A (store and test), B (screen and playtest).

| Agent | Model | Effort | Why |
|---|---|---|---|
| implementer | Opus 5.5 | high | scenes and a store, no core rule |
| reviewer | Fable | high | DEC-0031 §8 line by line |

## SyncTest (en)
None: nothing in the tick changes.

## Arena (en)
None.

## Teste à mão e o que sentir
Abrir as opções, trocar o dash e o gancho de tecla, mudar a escala, fechar e abrir o jogo: tudo ficou. O que sentir: se a tela se explica sozinha e se a escala máxima ainda deixa a barra e a mira no lugar.

## Docs a atualizar
`visual-e-audio.md` (a tela e os passos da escala); `glossario.md` (Tela de opções); `testes-e-entrega.md` (o arquivo em `user://`); `mudancas.md` (a tela como filha própria antes da v0.2.0, F-100 §1).
<!-- SECTION:NOTES:END -->
