---
id: TASK-12.16
title: 'A câmera centrada vira o padrão, e a mão do agarrão aparece'
status: To Refine
assignee: []
created_date: '2026-11-18 17:46'
labels: []
dependencies: []
parent_task_id: TASK-12
ordinal: 42000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
O Arthur jogou as duas câmeras da TASK-12.15 e ficou com a centrada como padrão, como no GunZ (F-220; DEC-0059). Com ela, a mira ficou a menos de 0,07 m do alvo nos três golpes, contra 0,18 a 0,34 m com o ombro. Esta task troca o padrão nos dados e no lançamento. Também resolve o que a câmera centrada esconde: a mão do agarrão some atrás do corpo, "não dava pra ver eu agarrando" (F-220).

### Perguntas em aberto
- Como deixar a mão do agarrão visível com a câmera centrada, antes do manequim (TASK-12.9)? Recomendação: desenhar a mão por cima do corpo, sem teste de profundidade, para a reta da mão continuar sendo a mesma conta do toque.

### Escolhas a confirmar
- O padrão nos dados (sugestão): `camera_v0.tres` e `movement_v0.tres` passam a ter ombro 0 e subida 0,6. Os números do ombro vão para `camera_shoulder.tres` e `movement_shoulder.tres`, com `--camera=shoulder` só no Sozinho.

### Fora do escopo
- O manequim e as animações (TASK-12.9; TASK-12.10).
- Ajustar a subida, a distância ou o campo de visão.
- A troca de ombro (Q-41).

### O que você vai aprender
- Como trocar um padrão sem quebrar os replays: o cabeçalho carrega os números do movimento, e o replay toca com os dele.
- Desenhar por cima do corpo (sem teste de profundidade) e por que isso não muda a regra do toque.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando o jogo abre sem `--camera`, no Sozinho, no servidor ou no cliente, a câmera é a centrada (ombro 0, subida 0,6 m, pivô a 2,2 m) e o ponto O fica no eixo do corpo; `--camera=shoulder` dá a câmera no ombro, só no Sozinho.
- [ ] #2 Quando a quebra sai com a câmera centrada, a mão do agarrão aparece na tela mesmo atrás do corpo de quem a solta, na mesma reta do toque.
- [ ] #3 Quando um replay gravado antes desta task é tocado, ele usa o ombro e a subida do próprio cabeçalho, e o `--watch` mostra a câmera com que ele foi gravado.
- [ ] #4 Quando o Arthur joga com a câmera centrada, ele vê o agarrão sair e pegar.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
