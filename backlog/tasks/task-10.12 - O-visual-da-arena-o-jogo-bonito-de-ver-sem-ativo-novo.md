---
id: TASK-10.12
title: 'O visual da arena: o jogo bonito de ver, sem ativo novo'
status: Ready
assignee: []
created_date: '2026-10-26 19:31'
updated_date: '2026-10-26 20:03'
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
Nenhuma. O Arthur escolheu a cara "Dia claro" na vitrine "A cara da arena" (https://claude.ai/artifact/MAbArQTm8dNrmKcbartwBp), contra a recomendação do Claude (o fim de tarde), e a conferência acertou (F-158). O Claude fechou o "Dia claro ajustado" como v0: o céu procedural azul, o sol a 50° um pouco quente, a luz do céu mais fraca, as peças num concreto neutro, as torres e o pilar num cinza-azulado, a borda escura, a cápsula de quem joga em 0,86 e a do outro em 0,11. Os números vão para o `visual-e-audio.md` antes do código.

### Escolhas a confirmar
Confirmadas: nenhum ativo novo, só o céu procedural, a luz, a neblina e as cores dos materiais do Godot (F-157; DEC-0029); a paleta do combate não muda, e o cenário fica atrás dos sinais (DEC-0031); os 60 fps em 1080p na máquina mínima seguem valendo, medidos com o `tools/measure_fps.sh` (DEC-0002).

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
- [ ] #1 Quando o Arthur abre o Sozinho, a arena tem a cara "Dia claro" da vitrine: o céu procedural, o sol, a luz do céu, o tonemapping, a neblina, os ajustes de cor e as cores do chão, das peças, das torres e do pilar e da borda com os números do `visual-e-audio.md`, e um teste de cena confere cada um (F-158)
- [ ] #2 Quando dois lutadores estão na arena, o tom de quem joga fica mais claro que toda superfície do cenário e o do outro mais escuro que toda superfície, e um teste confere os tons contra as cores dos materiais (F-156 §3; F-158)
- [ ] #3 Quando o visual novo roda no PC do Arthur, o `tools/measure_fps.sh` dá 60 fps de média em 1080p, e nenhum ativo novo entra no repositório (DEC-0002; DEC-0029)
- [ ] #4 Quando o Arthur joga e grava um vídeo, o que ele sentiu vai para uma fonte (F-041)
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
