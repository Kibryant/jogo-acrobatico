---
id: TASK-10.15
title: 'A tampa da arena: ninguém sai por cima da borda'
status: Done
assignee: []
created_date: '2026-10-26 23:44'
updated_date: '2026-10-27 14:14'
labels: []
dependencies: []
parent_task_id: TASK-10
ordinal: 24000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
A sonda do canto da TASK-10.8 mediu a saída da arena: a cápsula sobe na quina de cima da borda de 50 m, com o pulo duplo no topo do Z num canto ou com um gancho preso a 42,8 m ou mais, e cai do lado de fora, sem chão (`movimento.md`, "O canto da borda, medido"). O Arthur escolheu fechar a saída com uma tampa invisível sobre a arena: "a cabeça bate na tampa antes dos pés chegarem na quina" (DEC-0049; F-170). O plano de morte fica para a fase 2 (Q-48).

### Perguntas em aberto
Nenhuma.

### Escolhas a confirmar
Confirmadas pelo Arthur em 27/10/2026 (F-170 §2; DEC-0049):
1. A tampa: uma caixa de 82 × 1 × 82 m com a face de baixo a 50 m, sem malha e sem sombra.
2. Numa camada própria: só o corpo do lutador colide com ela; a mira, o gancho, as sondas da parede e a câmera não a enxergam.
3. O plano de morte vai para a fase 2, com a regra do duelo para quem cai fora.

### Números v0 do Claude
Fechados pelo Claude (DEC-0017).
- A tampa mede o mesmo que a borda por fora, 82 m, e tem 1 m de espessura, como a borda. A altura é o topo da borda.
- Com a tampa, os pés param em uns 48,2 m, 1,8 m abaixo da quina.

### Fora do escopo
- O plano de morte e o que cair fora vale num duelo (Q-48, fase 2).
- Mudar a borda, o Z, o gancho ou qualquer número de movimento.

### O que você vai aprender
- Camadas de física: o mesmo objeto pode bloquear o corpo e ser invisível para os raios, como uma barreira de mapa no CoD que não para tiro.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Quando o lutador sobe o Z num canto da borda e dá o pulo duplo no topo, a cabeça bate na tampa, os pés não chegam à quina, e ele fica na arena; a sonda do canto da TASK-10.8 vira teste no portão (DEC-0049; `movimento.md`, "O canto da borda, medido")
- [x] #2 Quando o gancho prende na borda o mais alto que alcança, de qualquer altura do Z, o lutador fica na arena (DEC-0049)
- [x] #3 Quando a mira, o raio do gancho, as sondas da parede ou a câmera apontam para a tampa, elas não a enxergam; só o corpo do lutador colide com ela, numa camada própria (DEC-0049 §2)
- [x] #4 Quando a tampa entra, nada muda abaixo dela: os testes da arena e da borda, a SyncTest e o replay seguem verdes e sem divergência (DEC-0049)
- [x] #5 Quando o Arthur tenta sair pelo canto no Sozinho, ele bate na tampa e fica na arena, e o que ele sentiu vai para uma fonte (F-041)
- [x] #6 Quando a tampa entra, o `movimento.md` ("A borda" e "O canto da borda, medido"), o `visual-e-audio.md`, o glossário e o `mudancas.md` dizem o que ela é e por quê (DEC-0049)
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Critérios de aceite verificados
- [x] #2 Teste automatizado para toda regra do núcleo (core/)
- [x] #3 Diário da sessão escrito e glossário atualizado
- [x] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
A tampa da arena fecha a saída por cima da borda: uma caixa invisível a 50 m, na camada BOUNDS, que só o corpo do lutador enxerga (DEC-0049). A sonda do canto virou teste do portão: com a tampa, os pés param em 48,2 m no Z e no gancho. O Arthur jogou e fechou com a prova do portão (F-171). O plano de morte foi para a fase 2 (Q-48), e o Z flutuando sob a tampa virou a Q-49. O revisor aprovou, e o portão passou em 374 s com 1.514 testes.
<!-- SECTION:FINAL_SUMMARY:END -->
