---
id: TASK-10.2
title: 'A barra na tela e o vão de 6 m: o HUD, o Theme e as plataformas'
status: Done
assignee: []
created_date: '2026-10-19 13:46'
updated_date: '2026-10-19 18:15'
labels:
  - jogo
milestone: m-1
dependencies:
  - TASK-10.1
parent_task_id: TASK-10
ordinal: 13000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
A stamina da TASK-10.1 existe só no estado; o jogador precisa vê-la para decidir o próximo pulo, e o HUD é lido do estado, nunca de um timer (F-051 §3.4), sem informação só por cor (DEC-0031 §2). A primeira cena de interface traz o Theme único e as chaves de tradução (DEC-0031 §8), que a TASK-9 adiou de propósito; a tela de opções é a TASK-10.9, antes da v0.2.0 (F-100 §1). As duas plataformas abrem o vão de 6 m, que só o pulo duplo cruza ("Métricas de nível": acima dos ≈ 4,4 m do pulo, mais o coyote, e abaixo dos ≈ 7 m do pulo duplo). Esta filha saiu da TASK-10.1 para cada sessão caber no tamanho da TASK-9: lá as regras e a SyncTest, aqui a tela e a arena. A referência já ganhou o pulo duplo na TASK-10.1. Nenhuma regra nova do núcleo: o test-writer não roda (DEC-0009).

### Perguntas em aberto
Nenhuma.

### Escolhas confirmadas
Confirmadas pelo Arthur em 19/10/2026 (F-100 §1): o HUD traz o Theme único em `ui/theme/game_theme.tres`, apontado por `gui/theme/custom` no `project.godot` e guardado pelo teste de configurações, e as chaves de tradução; a tela de opções, com as teclas remapeáveis e a escala, é a TASK-10.9. Na pergunta, o Theme vinha com a TASK-10.1; ele passou para esta filha junto com o HUD, na divisão das filhas.

### Números v0 do Claude
Fechados pelo Claude (DEC-0017); você julga jogando.
- A barra tem 300 × 12 px na base de 1080p, no canto inferior esquerdo, com o número ao lado e o modo em texto, porque o papel não tem pixel e a DEC-0031 §2 pede texto e forma além da cor; sem stamina para o pulo duplo, o número ganha um traço embaixo (forma, não cor). Vai para o `visual-e-audio.md`.
- As plataformas: `PlataformaVaoA` em (−20; 0,5; 6) e `PlataformaVaoB` em (−20; 0,5; −6), de 6 × 2 × 6 m, topo a 2 m (F-109: com 1 m, cair no vão não custava nada e o Arthur não o achou, F-108), com o vão de 6 m entre z = 3 e z = −3, em chão livre, longe dos cenários da SyncTest e do percurso da referência. O vão fica acima do pulo com coyote (≈ 4,4 + 0,7 m) e abaixo do pulo duplo (≈ 7 m). Vai para "Métricas de nível".
- O HUD só existe com tela: o servidor sem tela não o cria. Vai para a `visao-geral.md`.

### Fora do escopo
- A tela de opções e o remapeamento das teclas (TASK-10.9).
- A recarga do dash e a mira do gancho no HUD (TASK-10.4 e TASK-10.6). Som (Q-32; DEC-0029). Qualquer regra do núcleo.

### O que você vai aprender
- Um HUD que não mente: a barra se calcula do estado exibido a cada quadro, e um timer próprio se perderia num rollback.
- O Theme do Godot como as variáveis de CSS de um site: um lugar para a fonte e as cores, e nenhuma cena com número solto.
- As chaves de tradução: o texto da tela mora num arquivo por idioma, como o i18n de um app web.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Quando o Sozinho abre com tela, o HUD mostra a stamina como barra (300 × 12 px na base de 1080p, leitura v0 do Claude) e número, e o modo em texto, lidos do estado exibido a cada quadro por `Stamina.at` e nunca de um timer, nada só por cor; com menos de 10 de stamina, o custo do pulo duplo, o número muda de forma; sem tela, nenhum HUD é criado (F-051 §3.4; DEC-0031 §2 e §8; DEC-0022).
- [x] #2 Quando a primeira cena de interface nasce, ela usa o Theme único `ui/theme/game_theme.tres`, apontado por `gui/theme/custom` e guardado pelo teste de configurações; os textos da TASK-9 passam a usar o Theme; nenhuma cena de interface carrega fonte ou cor própria (DEC-0031 §8; F-006 §3).
- [x] #3 Quando o HUD mostra um texto, ele vem de uma chave de tradução, com pt-BR e en; uma chave sem tradução num dos dois idiomas reprova um teste (DEC-0031 §8).
- [x] #4 Quando a arena ganha `PlataformaVaoA` e `PlataformaVaoB` (6 × 2 × 6 m, topo a 2 m, vão de 6 m entre elas; F-109), elas ficam em chão livre, fora do percurso da referência e das áreas dos cenários, com nomes únicos sob `Arena` e colisão e malha do mesmo tamanho, e um teste de cena prova isso; os cinco cenários da SyncTest seguem verdes, e a referência mantém o hash `d53a533c…`, ou é regravada com o motivo no commit (F-086 §1; `movimento.md`, "Métricas de nível"; DEC-0027 §2, camada 4).
- [x] #5 Quando o Arthur joga no Sozinho, ele cruza o vão de 6 m só com o pulo duplo, vê a barra cair 10 e encher de novo depois de 0,8 s, e o que ele sentiu vai para uma fonte (F-041; `movimento.md`, "Stamina").
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Critérios de aceite verificados
- [x] #2 Teste automatizado para toda regra do núcleo (core/)
- [x] #3 Diário da sessão escrito e glossário atualizado
- [x] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## O plano (para o implementer; sem test-writer, DEC-0009)

Nenhuma regra nova do núcleo: tudo aqui é cena, interface e arena. Nomes de código em inglês (DEC-0008).

**O HUD** (`ui/hud.gd`, `class_name Hud extends CanvasLayer`, montado em código como o `StatusMessage`, ou numa cena `ui/hud.tscn`):
- `func follow(fighter: Fighter, config: MovementConfig) -> void`; no `_process`, lê o `fighter.state` exibido e o `NetworkTime.tick`, calcula `Stamina.at(state, config, tick)` e ajusta a largura da barra, o número e o modo. Sem `Timer`, sem contador próprio (DEC-0031 §2; F-106).
- A barra: 300 × 12 px na base de 1920 × 1080 (a escala `canvas_items` já está no `project.godot`), no canto inferior esquerdo; o número ao lado, inteiro; o modo em texto (`GROUND`/`AIR` viram chaves de tradução, por exemplo `HUD_MODE_GROUND` e `HUD_MODE_AIR`).
- Abaixo do custo do pulo duplo (`config.double_jump_cost`), o número ganha um traço embaixo: forma, não cor (DEC-0031 §2).
- Quem cria: o `Match.watch(fighter)`, só com tela (`DisplayServer.get_name() != "headless"`, como a `Main` já faz); o servidor sem tela nunca cria o HUD.

**O Theme** (`ui/theme/game_theme.tres`): a fonte e os tamanhos dos textos da tela; o `StatusMessage` e o HUD passam a usá-lo; nenhuma cena de interface carrega fonte ou cor própria. O `project.godot` ganha `gui/theme/custom = "res://ui/theme/game_theme.tres"`, com o motivo no commit (DEC-0031 §8), e o `test/project_settings_test.gd` ganha a linha que o guarda.

**As chaves de tradução**: cada texto novo vira uma constante e entra em `GameText.KEYS`, com a mensagem em `ui/translations/pt_BR.po` e `ui/translations/en.po`; um teste reprova uma chave de `KEYS` sem mensagem num dos dois idiomas.

**As plataformas** (`arena/arena.tscn`): `PlataformaVaoA` em (−20; 1; 6) e `PlataformaVaoB` em (−20; 1; −6), dois `StaticBody3D` na camada `PhysicsLayers.WORLD`, com `BoxShape3D` de 6 × 2 × 6 m (o topo a 2 m, F-109) e malha do mesmo tamanho, no material cinza dos blocos. Um teste de cena prova os nomes únicos sob `Arena`, a colisão igual à malha e que elas ficam longe do percurso da referência e das áreas dos cenários da SyncTest (as coordenadas estão em `test/fighter/fighter_sync_test.gd` e `test/reference/reference_route.gd`).

**Os testes do implementer:**
- `test/ui/hud_test.gd`: um estado com `stamina_spent_tick` marcado mostra a largura e o número certos; abaixo do custo, o traço aparece; o `Match.watch` sem tela não cria HUD.
- A linha do `gui/theme/custom` no teste de configurações.
- O teste das chaves nos dois idiomas.
- O teste de cena das plataformas.
- A SyncTest e a referência seguem verdes; se o hash `d53a533c…` mudar, a referência é regravada com o motivo no commit.

**Os docs** (com o plano aprovado, uma linha no `mudancas.md`): `visual-e-audio.md` (a barra em px; o Theme como o lugar das fontes); `movimento.md`, "Métricas de nível" (o vão de 6 m e as plataformas); `glossario.md` (HUD; Theme); `visao-geral.md` (o HUD só com tela).

**Rodadas:** A (o HUD, o Theme, as chaves e os testes); B (as plataformas, os docs e o teste à mão).

| Agente | Modelo | Effort | Por quê |
|---|---|---|---|
| implementer | Opus 5.5 | high | cena e interface, sem regra do núcleo |
| reviewer | Fable | high | a DEC-0031 §2 e §8 se quebram em silêncio |
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Rascunho do plano da fase 1 (19/10/2026), em inglês para os agentes; vira o plano em português quando a filha ficar Ready (F-100).

**HUD** (`ui/hud.gd`, `ui/hud.tscn`): `class_name Hud extends CanvasLayer`; `func follow(fighter: Fighter, config: MovementConfig) -> void`; in `_process` it reads `fighter.state` (the displayed state) and `NetworkTime.tick`, computes `Stamina.at(state, config, tick)` and sets the bar width, the number label and the mode label; no `Timer`, no own counter. Nodes `StaminaBar` (sized by code, 300 × 12 at the 1080p base, stretch `canvas_items`), `StaminaLabel`, `ModeLabel`. Created by `Match.watch(fighter)` only when `DisplayServer.get_name() != "headless"`; the server path never instantiates it.

**Theme** (`ui/theme/game_theme.tres`): the font and sizes of `GameText` move into it; `project.godot` `gui/theme/custom = "res://ui/theme/game_theme.tres"` (named with its reason in the commit; `test/project_settings_test.gd` gains the row).

**Arena** (`arena/arena.tscn`): two `StaticBody3D` on `PhysicsLayers.WORLD` with a `BoxShape3D` 6 × 1 × 6 and a mesh of the same size, unique names `PlataformaVaoA`/`PlataformaVaoB` under `Arena`; `test/arena/arena_scene_test.gd` asserts unique names, matching sizes and no overlap with the reference route's bounds or the scenario areas (`fighter_sync_test.gd`:23-60; `sync_observer.gd`:18-20).

**Reference** (`test/reference/reference_route.gd`): an apex press at :62 (a jump press 350 ms after a floor jump); `LEAST` gains `double_jumps: 1`; `route.trace` re-recorded.

**Who tests what**: no test-writer (adapters and scenes, DEC-0009). The implementer writes `test/ui/hud_test.gd` (the bar reads a state with `stamina_spent_tick` set and shows the right width and text; headless `Match.watch` creates no HUD), the settings row, the arena scene test and the re-record. The reviewer checks the re-record commit message and that no scene carries a loose font or colour.

**Rounds**: A (HUD, Theme, settings test); B (platforms, reference, docs, playtest).

| Agent | Model | Effort | Why |
|---|---|---|---|
| implementer | Opus 5.5 | xhigh | scene work under the Theme rule, plus the re-record |
| reviewer | Fable | high | DEC-0031 §2 and §8 are easy to break quietly |
| explorer | Sonnet | high | only to locate `GameText` and the route bounds |

## SyncTest (en)
No new scenario; the five existing ones stay green with the new bodies in the tree, mismatches 0.

## Arena (en)
`PlataformaVaoA` (−20, 0.5, 6) and `PlataformaVaoB` (−20, 0.5, −6), 6 × 1 × 6 m, tops at 1 m, a 6 m gap across z −3..3; extents x −23..−17.

## Teste à mão e o que sentir
Cruzar o vão só com o pulo: não chega. Com pulo e pulo duplo: chega com folga de ≈ 1 m. Olhar a barra: cai 10 no aperto, fica parada 0,8 s, enche em ≈ 3,3 s quando vazia. O que sentir: se a barra chama a atenção na hora certa, se o número é legível em 1080p, e se o vão parece "quase" ou "fácil". Perguntar só depois de jogar (F-041).

## Docs a atualizar
Com o seu ok e uma linha no `mudancas.md` cada: `visual-e-audio.md` (a barra em px; o Theme como o lugar das fontes); `movimento.md` "Métricas de nível" (o vão e as plataformas); `glossario.md` (HUD); `visao-geral.md` (o HUD só com tela); `pendencias.md` (Q-32); `testes-e-entrega.md` §3 (a referência com o pulo duplo); a vitrine com o vão (DEC-0019); o diário e o `registro.md`.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
O HUD mostra a stamina no canto inferior esquerdo (a barra de 300 × 12 px, o número e o modo), calculado do estado exibido a cada quadro, sem timer (F-051 §3.4), com o traço de 2 px abaixo de 10 (DEC-0031 §2). O Theme único em gui/theme/custom e as chaves de tradução do HUD, com pt-BR e en (DEC-0031 §8). As plataformas do vão de 6 m subiram para 2 m depois do primeiro teste à mão (F-108; F-109). A referência manteve o hash d53a533c. O revisor pediu duas correções de citação, feitas. O Arthur gostou da barra e achou o vão massa, sem novidade (F-110). Sem regra nova do núcleo: o item 2 da DoD não se aplica. PR #10.
<!-- SECTION:FINAL_SUMMARY:END -->
