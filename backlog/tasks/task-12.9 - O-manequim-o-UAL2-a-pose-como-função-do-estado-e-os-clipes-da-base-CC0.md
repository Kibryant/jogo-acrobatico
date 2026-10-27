---
id: TASK-12.9
title: 'O manequim: o UAL2, a pose como função do estado e os clipes da base CC0'
status: To Refine
assignee: []
created_date: '2026-10-27 22:02'
labels:
  - jogo
milestone: m-2
dependencies:
  - TASK-12.5
parent_task_id: TASK-12
ordinal: 36000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
A leitura da troca precisa da pose, o canal que a cápsula menos dá (F-063 §3; DEC-0031). Com as regras do duelo jogáveis e julgadas, o manequim CC0 do UAL2 entra pelo pipeline da DEC-0030: glTF, 1,8 m pela escala de import, um rig, uma Animation Library, a pose como função do estado, com os clipes da base CC0 para o movimento e os golpes que existirem lá (escolha do Arthur na rodada 2 do desenho do duelo, F-174 §2; DEC-0050).

### Perguntas em aberto
- Quais clipes da base cobrem o kit de hoje (correr, pular, cair, parede, dash, leve, carregado, guarda) e quais faltam, para a lista da TASK-12.10.

### Escolhas a confirmar
Nenhuma além da escolhida: o manequim entra depois das regras, antes dos amigos.

### Fora do escopo
- Os clipes de identidade à mão (TASK-12.10). A arte final (fase 5).

### O que você vai aprender
- A pose como função do estado, sem AnimationTree: qual clipe e em que ponto, a partir do modo, da ação e dos carimbos (DEC-0030 §4).
- O import do glTF e o que vai para o git e para o LFS (DEC-0029; DEC-0030).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando o manequim do UAL2 entra, ele fica em `assets/third_party/` com a licença ao lado e a linha no `CREDITS.md`, nos formatos do LFS, e o passo dos assets do portão passa (DEC-0029).
- [ ] #2 Quando o jogo abre, o lutador é o manequim com 1,8 m pela escala de import, o material toon e o contorno de 1,2 cm, no lugar da cápsula (DEC-0030).
- [ ] #3 Quando o estado do lutador muda de modo ou de ação, a pose a cada quadro vem de uma função do estado (modo, ação, carimbos, tick), com o mixer em modo manual, sem máquina de estados de animação; o rollback nunca a toca.
- [ ] #4 Quando um clipe de golpe toca, a preparação, o ativo e a recuperação são reajustados fase a fase pelos ticks do núcleo, e a marca do ativo do clipe cai dentro dos ticks ativos (DEC-0030 §4).
- [ ] #5 Quando 16 manequins ficam na arena, a medição de fps fica acima de 60 em 1080p na RX 550, com o MSAA 2x, a sombra e o contorno (DEC-0002; DEC-0030 §6).
- [ ] #6 Quando o Arthur joga contra o boneco com o manequim, ele diz se lê melhor o leve, o carregado e a quebra do que com a cápsula (F-063 §3).
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
