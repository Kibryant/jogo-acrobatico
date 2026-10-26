---
id: TASK-10.7
title: 'A cabeça do outro: a regra da Q-16, o boneco e a borda da arena'
status: To Refine
assignee: []
created_date: '2026-10-19 13:47'
updated_date: '2026-10-26 14:09'
labels:
  - jogo
milestone: m-1
dependencies:
  - TASK-10.11
parent_task_id: TASK-10
ordinal: 18000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
A Q-16 (ficar em pé na cabeça do outro) se decide na fase 1 jogando (DEC-0036; `pendencias.md`:26) e é a última divergência que a sonda do Desenho 2 achou: de 6 a 32 em 20 s, até 15 cm, com um lutador sobre o outro (F-025 §3; `rede.md` §4, hipótese 2). A sonda C mede antes da regra, com a velocidade de plataforma que o motor dá a quem está sobre outro corpo (`CharacterBody3D.xml`:135, :170, :173: um lutador sobre outro é um passageiro de plataforma móvel, e o contorno nunca restaura essa velocidade). Para você decidir jogando, o Sozinho ganha um boneco parado, e a borda da arena deixa de ser um precipício sem fim. Esta filha ficou com a regra e a arena; o bot com manobras, a decisão online e o teste da fase são a TASK-10.8.

### Perguntas em aberto
Nenhuma; a Q-16 se responde jogando, na TASK-10.8.

### Escolhas a confirmar
1. A Q-16 começa proibida: a cabeça do outro nunca é chão para as regras (`Movement.stands`), o `on_floor` segue sendo o veredito do motor (para o contorno D alinhar, DEC-0025 §2), e quem cai em cima escorrega para fora a 3 m/s. Padrão: proibir, a recomendação da `pendencias.md`, porque tira um estado escondido do motor da partida; é identidade e você decide jogando, na TASK-10.8.
2. O lutador deixa de tratar outro lutador como plataforma móvel: `platform_floor_layers = PhysicsLayers.WORLD` e `platform_on_leave = PLATFORM_ON_LEAVE_DO_NOTHING` no `Fighter.setup`, com a sonda C medindo antes e depois. Padrão: sim, porque a velocidade de plataforma é o mecanismo candidato das divergências da F-025 §3; é contato com o motor e passa pelo modo de plano.

### Números v0 do Claude
Fechados pelo Claude (DEC-0017); escritos em "O corpo" com o seu ok antes do test-writer rodar.
- `head_slide_speed_mps` = 3,0: com raios de 0,35 m, o domo deixa de ser chão além de 45°, a 0,495 m do eixo; a 0,05 m por tick são ≈ 10 ticks do centro, contados do tick seguinte ao pouso, e o critério diz 12. Vai para "O corpo".
- Quem está sobre uma cabeça fica no ar para as regras: sem pulo do chão nem dash, sem renovar o pulo duplo, sem coyote (o `left_floor_tick` não é carimbado) e com gravidade; o choque de lado segue como o empurrão da TASK-9.
- O boneco do Sozinho fica parado no segundo ponto de nascimento (`SpawnB`), desligável por `--dummy=off`; o replay grava o input dos dois.
- A borda: quatro paredes de 30 m de altura em x = ±40,5 e z = ±40,5 (acima dos ≈ 26,6 m de alcance de gancho mais pulo), porque hoje não existe plano de morte e um lutador que cai para fora cai para sempre; são também 80 m de parede corrível. Vai para "Métricas de nível".

### Fora do escopo
- O bot com manobras, a decisão da Q-16 online, o teste dos 15 minutos e a versão 0.2.0 (TASK-10.8).
- O combate. A Q-13 (só se você falar dela). O bot que reage. O plano de morte.

### O que você vai aprender
- A colisão entre dois corpos e o estado escondido que a sonda do Desenho 2 achou nela: a plataforma móvel que o motor vê num lutador.
- Como uma regra diz "não é chão" sem mentir para o contorno que alinha o motor: `stands` contra `on_floor`.
- Por que o Sozinho precisa de um segundo corpo para você julgar uma regra de dois.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando um lutador cai sobre a cabeça de outro, o núcleo não conta o topo da cápsula como chão: ele fica no ar, sem pulo do chão nem dash, sem renovar o pulo nem o pulo duplo e sem coyote, e escorrega para fora a 3 m/s (`head_slide_speed_mps`), saindo da cabeça em até 12 ticks a 60 contados do tick seguinte ao pouso; de lado, o choque segue como o empurrão da TASK-9 (leitura do Claude para a Q-16, a confirmar jogando; `pendencias.md`, Q-16).
- [ ] #2 Quando a sonda C roda o código de antes da regra com o rollback de 7 ticks e um lutador dando pulo duplo sobre a cabeça do outro, ela anota nas notas quantas divergências e o erro máximo, se o snap segura o de cima no domo, e a velocidade de plataforma antes e depois de `platform_floor_layers` só no cenário; a sonda falha se nenhum pouso na cabeça acontecer (F-025 §3; `rede.md` §4; `CharacterBody3D.xml`:135, :170).
- [ ] #3 Quando a SyncTest roda o cenário da cabeça (um parado, o outro pula e dá o pulo duplo sobre ele, duas vezes) com o rollback de 7 ticks a cada tick, ela acha zero divergências no estado inteiro, onde a sonda do Desenho 2 achava de 6 a 32; o cenário conta pelo menos 2 pousos na cabeça, 2 escorregões, 1 pulo recusado e zero ticks com a cabeça como chão para as regras; esconder `:state:slide_off_dir` faz ela acusar (F-025 §3; `rede.md` §8).
- [ ] #4 Quando o `Fighter` nasce, ele só aceita o cenário como plataforma (`platform_floor_layers`) e não herda velocidade ao sair de outro corpo, e um teste de cena prova os dois valores; a mudança leva uma linha no `mudancas.md` (DEC-0025; DEC-0037).
- [ ] #5 Quando o Arthur abre o Sozinho, um boneco parado espera no segundo ponto de nascimento, desligável por `--dummy=off`, e o replay grava o input dos dois lutadores; sem tela, no portão, o `main_test` segue verde (DEC-0027 §5).
- [ ] #6 Quando a arena ganha a borda de quatro paredes de 30 m, ninguém cai para fora, as paredes aceitam a corrida, a referência e os cenários seguem verdes (ou a referência é regravada com o motivo no commit), e o Arthur sobe na cabeça do boneco, escorrega em ≈ 0,2 s e não pula de cima dela; o que ele sentiu vai para uma fonte (`movimento.md`, "Métricas de nível"; F-041).
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

**State**: `slide_off_dir: Vector3 = ZERO` (`:state:slide_off_dir`; horizontal unit away from the fighter below; ZERO = not on a head). **Facts**: `MoveFacts.floor_is_fighter: bool` (a floor-angle slide collision whose collider `is Fighter`), `fighter_away: Vector3` (the flattened `get_normal()` of that collision, never the other body's position, DEC-0026 §3; shorter than 1e-6: the back of `facing_yaw`). **Helper**: `static func Movement.stands(state: FighterState) -> bool` = `state.on_floor and state.slide_off_dir == Vector3.ZERO`; every rule that asked `on_floor` for a floor jump, a dash or a renewal asks `stands` from here. **Data**: `head_slide_speed_mps: float = 3.0` (positive); **Config**: `head_slide_speed`.

**Conventions**: `after_move` with `facts.floor_is_fighter`: `slide_off_dir = facts.fighter_away`; `mode = AIR` (from GROUND: `mode_since = tick`, `left_floor_tick` not stamped); no renewal of `jumps_used`/`double_jump_tick`; `on_floor` stays the engine's verdict. `after_move` without it: `slide_off_dir = ZERO`. `before_move` with `slide_off_dir != ZERO`: the horizontal component along `slide_off_dir` raised to at least `head_slide_speed`, gravity applied, `stands()` false, so the slot holds a jump or a dash. Side bumps unchanged (the TASK-9 push).

**Adapter**: `Fighter.setup` sets `platform_floor_layers = PhysicsLayers.WORLD` and `platform_on_leave = CharacterBody3D.PLATFORM_ON_LEAVE_DO_NOTHING`; `_fill_facts` scans the slide collisions for a `Fighter` collider at floor angle. **Dummy**: `BotRoute.still()`; `Main.start_solo` spawns slot 1 at `SpawnB` and calls `let_bot_play` (`match.gd`:141-151) unless `--dummy=off` (`LaunchOptions`); `ReplayRecorder` follows both slots. **Arena**: `BordaNorte`/`BordaSul` (0, 15, ±40.5) 82 × 30 × 1; `BordaLeste`/`BordaOeste` (±40.5, 15, 0) 1 × 30 × 82; WORLD layer; unique names; the scene test gains them.

**Who tests what**: the test-writer writes criterion 1 blind against the rig's `floor_is_fighter` and `fighter_away` (`movement_head_test.gd`, the data row); locked. The implementer writes 2 (probe C in `engine_probe_test.gd`, the measurement first with the current code, then with the layers), 3 (scenario "cabeça": B still, A runs, jumps and double-jumps onto B's head twice; counters `head_landings >= 2`, `slide_offs >= 2`, `head_jump_refusals >= 1`, `head_floor_ticks == 0`, `collisions >= 1`, mismatches 0; poison `:state:slide_off_dir`), 4 (the scene test), 5 (`main_test` with `--dummy=off` where it matters) and 6.

**Rounds**: A (probe C with the platform velocity, before the rule); B (core, facts, `stands`, the layers, scenario); C (dummy, perimeter, docs, playtest).

| Agent | Model | Effort | Why |
|---|---|---|---|
| test-writer | Fable | high | the head rule touches every floor check |
| implementer | Opus 5.5 | xhigh | a measurement, a core rule and an engine setting |
| reviewer | Fable | high | the "zero where 6 to 32" claim needs the probe's numbers |
| explorer | Sonnet | high | to map `let_bot_play` and the spawn points |

## SyncTest (en)
Scenario "cabeça", counters above, poison `:state:slide_off_dir`; the four TASK-9 scenarios and the four phase scenarios stay green with the perimeter in the tree.

## Arena (en)
The perimeter: four 30 m walls at ±40.5 on x and z; no kill plane. Scenario geometry stays run-time.

## Teste à mão e o que sentir
Subir na cabeça do boneco com pulo e pulo duplo: escorregar para fora em ≈ 0,2 s, sem conseguir pular de cima; bater de lado e sentir o empurrão de sempre; correr até a borda e ver que ela é uma parede corrível. O que sentir: se proibir a cabeça parece justo ou parece um bug; a decisão mesmo fica para a TASK-10.8, online contra o bot.

## Docs a atualizar
Com o seu ok e uma linha no `mudancas.md` cada: `movimento.md` ("O corpo" com a linha da Q-16 e a leitura do escorregão; "Métricas de nível" com a borda); `glossario.md` (Escorregar da cabeça, Plataforma móvel, Boneco de treino); `rede.md` §4 (a hipótese 2 com os números da sonda C e a velocidade de plataforma); `visao-geral.md` (`slide_off_dir`, `stands`, `platform_floor_layers`); `testes-e-entrega.md` (o cenário da cabeça; o `--dummy`); o diário e o `registro.md`.
<!-- SECTION:NOTES:END -->
