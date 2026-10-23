---
id: DEC-0040
titulo: O tick no passo de física — o sync_to_physics do netfox ligado
data: 2026-10-23
status: aceita
decidido_por: Arthur (F-117)
fontes: [F-116, F-117, F-042, F-044]
substitui:
substituida_por:
---

# DEC-0040 — O tick no passo de física: o `sync_to_physics` do netfox ligado

## Contexto

O replay por inputs (TASK-10.3) existe para o Claude refazer, sem tela, um bug que o Arthur achou jogando (F-044 §1; DEC-0027 §5). A medição do critério 5 achou um problema.

O tocador sem tela refaz o arquivo bit a bit, mas a janela e o jogo ao vivo se separam dele no último bit de um float (`testes-e-entrega.md` §4). A causa está no netfox:
- Com `netfox/time/sync_to_physics` desligado, o padrão dele, o tick roda no `_process`.
- Ali, o `physics_factor` vale `(1/60) ÷ delta do quadro`.
- O `fighter.gd` multiplica a velocidade por esse fator antes do `move_and_slide()` e divide depois. Cada quadro, com o seu tamanho, arredonda diferente.

A sonda de 23/10 mediu o replay de 11 180 ticks do Arthur (F-114; F-117, contexto):

| Modo | 30 fps | 60 fps | 144 fps |
|---|---|---|---|
| Desligado | separa no tick 398; até 7,6 µm | separa no 408; até 5,2 µm | separa no 342; até 13 µm |
| Ligado | igual byte a byte | igual byte a byte | igual byte a byte |

Desligado, só a posição e a velocidade diferem, e a diferença não cresce ao longo da partida. Mesmo assim, um micrômetro na beira de um contato pode decidir o tick de um pouso. O dash, a parede e o gancho (TASK-10.4 a 10.6) trazem contatos novos.

## Opções consideradas

1. **Ligar o `sync_to_physics`:** o tick roda no `_physics_process`, o passo fixo do Godot (1/60 s), e o `physics_factor` vale 1 exatamente. A janela, o jogo ao vivo e a refeita dão o mesmo número em qualquer fps. A escolhida.
2. **Deixar desligado:** nada muda, mas a refeita não reproduz o que o jogo calculou, e um bug de micrômetro pode sumir no replay.
3. **Tirar o `move_and_slide()` do caminho,** calculando o deslocamento do tick à mão: muda o contato com o motor do esqueleto andante (DEC-0025) para resolver o que uma configuração resolve.

## Decisão

Aceita pelo Arthur em 23/10/2026, no plan mode, depois de acertar a conferência "O fator muda a cada quadro" (F-117).

1. O `project.godot` ganha `netfox/time/sync_to_physics=true`, e o `test/project_settings_test.gd` guarda a configuração.
2. O `physics_ticks_per_second` do Godot fica no padrão, 60, igual ao `netfox/time/tickrate` (DEC-0024). O netfox passa a tirar o tickrate dele.
3. O `physics_factor` continua no `fighter.gd`: vale 1 com o modo ligado e protege um tick rodado fora do passo de física.
4. O cabeçalho do replay passa a dizer `sync_to_physics=1`. Um arquivo gravado com `0`, como o de 23/10, não toca mais, nem com `--force` (TASK-10.3, critério 7).

## Consequências

- **A 30 fps,** o Godot dá dois passos de física por quadro, cada um com um tick; quando o relógio do netfox fica para trás, um passo pode rodar mais de um tick, até o `max_ticks_per_frame` (`network-time.gd`, `_get_ticks_in_loop`). Abaixo disso, o Godot dá até 8 passos por quadro (`physics/common/max_physics_steps_per_frame`, o padrão do Godot).
- **O teclado** passa a ser lido no passo de física, antes do tick do netfox (`fighter/fighter_input.gd`). O Godot roda os passos de física de um quadro antes do `_process`, então lido no `_process` ele valeria só nos ticks do quadro seguinte: até 33 ms a mais a 30 fps, que o revisor apontou. O mouse gira a câmera no `_unhandled_input`, entregue antes dos passos, e o pulo também.
- **A interpolação** do netfox passa a usar a fração do passo de física do Godot (`network-time.gd`, `tick_factor`). A suavidade da câmera a 144 fps não foi vista na sonda: o Arthur confere jogando, e uma câmera que treme traz a escolha de volta.
- **O servidor sem tela** também roda a física, e o tick vai junto.
- **Os docs:** o `testes-e-entrega.md` §4 e §11 e o `rede.md` §8 trocam "a escolha volta ao Arthur" por esta DEC.

## Revisitar se

- Jogando a 144 fps, a câmera tremer ou o corpo andar aos trancos: a interpolação pela fração do passo de física volta à mesa.
- O Godot ou o netfox mudarem a ordem entre os passos de física e o `_process`, ou o `physics_factor`: a sonda de 23/10 roda de novo.
- Um dia o tick precisar de outro ritmo que não o da física do Godot (`physics_ticks_per_second`).
