---
id: TASK-10.12
title: 'O visual da arena: o jogo bonito de ver, sem ativo novo'
status: To Refine
assignee: []
created_date: '2026-10-26 19:31'
labels:
  - jogo
milestone: m-1
dependencies:
  - TASK-10.7
parent_task_id: TASK-10
ordinal: 18500
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
O Arthur jogou a cabeça do outro e achou o jogo "muito branco", "tudo muito pálido", e quer deixá-lo "mais instagramável": ele posta o projeto no Instagram como diário visual e quer mostrar as atualizações (F-156 §1). A arena ainda é cinza de protótipo, e a borda de 50 m, num cinza muito claro e sem sombra, piorou o quadro: ela toma o lugar do céu, e a cápsula branca do jogador some contra ela (F-156 §3; o print). Ele escolheu uma task própria, a próxima, antes da tela de opções (F-157).

### Perguntas em aberto
- Que cara a arena ganha? O Claude mostra 2 ou 3 caras numa vitrine, com o mesmo quadro do print, e o Arthur escolhe (DEC-0019).
- O céu: o procedural do Godot, com que cor e que horário de sol?
- Os tons dos lutadores: o seu, claro, e o do outro, escuro, seguem, ou mudam para destacar contra a arena nova?

### Escolhas a confirmar
1. Nenhum ativo novo: só o céu procedural, a luz, o ambiente e as cores dos materiais do próprio Godot (DEC-0029). Padrão: sim.
2. A paleta do combate (DEC-0031; `visual-e-audio.md`, "A paleta") não muda: o cenário fica atrás dos tokens, com contraste mínimo de 3:1 contra os sinais. Padrão: sim.
3. Os 60 fps em 1080p na máquina mínima seguem valendo, medidos com o `--measure-fps` (DEC-0002). Padrão: sim.

### Fora do escopo
- Modelos, texturas, animação e som: a fase de arte, com as licenças da DEC-0029.
- O HUD e a tela de opções (TASK-10.9).
- Mudar a geometria da arena.

### O que você vai aprender
- Por que um jogo cinza parece pálido: brilho, contraste e saturação, e como um céu e uma luz de cor mudam tudo sem um ativo novo.
- O tonemapping: o que ele faz com a luz forte antes de chegar à tela.
- Ler um quadro como o jogador: o corpo que se destaca contra o fundo.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando o Arthur abre o Sozinho, a arena tem céu, luz e uma paleta com contraste entre o chão, as paredes, as peças e a borda, na cara que ele escolheu numa vitrine (F-156; F-157)
- [ ] #2 Quando a cápsula do jogador fica na frente de qualquer peça da arena ou da borda, ela se destaca do fundo, com contraste conferido no quadro (F-156 §3)
- [ ] #3 Quando o visual novo roda na máquina mínima, o Sozinho segue a 60 fps em 1080p, medido com o --measure-fps, e nenhum ativo novo entra (DEC-0002; DEC-0029)
- [ ] #4 Quando o Arthur joga e grava um vídeo, o que ele sentiu vai para uma fonte (F-041)
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
