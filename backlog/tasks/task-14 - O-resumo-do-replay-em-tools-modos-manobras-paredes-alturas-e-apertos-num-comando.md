---
id: TASK-14
title: >-
  O resumo do replay em tools/: modos, manobras, paredes, alturas e apertos, num
  comando
status: Ready
assignee: []
created_date: '2026-10-27 16:22'
updated_date: '2026-10-28 11:27'
labels:
  - base
dependencies: []
ordinal: 27000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
Depois de cada vez que o Arthur joga, o replay é medido à mão com um script descartável: modos, manobras, paredes, alturas, apertos recusados (F-144 §2; F-149 §2; F-156; F-166 §7; F-169; F-171). O registro da harness pediu a ferramenta em `tools/` quatro vezes (TASK-10.11, TASK-10.7, TASK-10.8, TASK-10.13): o que repete duas vezes vira script (DEC-0009). Na TASK-12.1, o combate foi medido à mão duas vezes do mesmo jeito: cliques, golpes, emendas, acertos, erros, cliques no ar e velocidade no golpe (F-178 §1; F-180 §1).

### Perguntas em aberto
Nenhuma.

### Escolhas a confirmar
Nenhuma: é ferramenta de leitura, sem regra de jogo.

### Fora do escopo
- Os golpes que ainda não existem: cada filha do duelo soma as colunas dela quando nascer.

### O que você vai aprender
- O que um replay por inputs guarda e o que o rastro de estado permite contar.
- Como os números do golpe saem do próprio cabeçalho do replay, e por que o resumo de uma sessão antiga continua certo depois de um número mudar.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando `bash tools/replay_summary.sh ARQUIVO` roda sobre um replay do Sozinho, ele imprime o tempo por modo, a contagem de cada manobra, as paredes usadas, a altura máxima e o voo mais longo, como a F-166 §7.
- [ ] #2 Quando o replay tem dois lutadores, o resumo separa o do Arthur do boneco ou do bot.
- [ ] #3 Quando o arquivo não é um replay válido, o script diz por quê e sai com código diferente de 0.
- [ ] #4 Quando o replay tem golpes leves, o resumo imprime os cliques, os golpes que saíram, os que esperaram na vaga, os cliques perdidos por fase do golpe e por motivo (no ar, sem stamina), os golpes emendados, os acertos, os erros com a distância mais curta ao alvo, a vida mínima do alvo e a velocidade durante o golpe, com os ticks do golpe lidos do cabeçalho do replay, como a F-178 §1 e a F-180 §1.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
