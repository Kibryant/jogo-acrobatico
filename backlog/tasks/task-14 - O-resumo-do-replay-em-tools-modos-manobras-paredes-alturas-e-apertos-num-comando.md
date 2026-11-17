---
id: TASK-14
title: >-
  O resumo do replay em tools/: modos, manobras, paredes, alturas e apertos, num
  comando
status: Done
assignee: []
created_date: '2026-10-27 16:22'
updated_date: '2026-11-17 14:53'
labels:
  - base
dependencies: []
ordinal: 27000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
Depois de cada vez que o Arthur joga, o replay é medido à mão com um script descartável: modos, manobras, paredes, alturas, apertos recusados (F-144 §2; F-149 §2; F-156; F-166 §7; F-169; F-171). O registro da harness pediu a ferramenta em `tools/` quatro vezes (TASK-10.11, TASK-10.7, TASK-10.8, TASK-10.13): o que repete duas vezes vira script (DEC-0009). Na TASK-12.1, o combate foi medido à mão duas vezes do mesmo jeito: cliques, golpes, emendas, acertos, erros, cliques no ar e velocidade no golpe (F-178 §1; F-180 §1). Nas sessões 22 e 23, o carregado e a mira foram medidos à mão três vezes: os carregados que pegaram até 2,6 m, o lado do corte nos erros e onde estava a mira (F-202, contexto; F-204, contexto); o Arthur somou o critério 5 (F-205).

### Perguntas em aberto
Nenhuma.

### Escolhas a confirmar
Nenhuma: é ferramenta de leitura, sem regra de jogo. O critério 5 foi somado pelo Arthur (F-205).

### Fora do escopo
- A guarda, o parry e a finta: entram no resumo quando alguém os medir à mão duas vezes (DEC-0009; F-205).
- Os golpes que ainda não existem: cada filha do duelo soma as linhas dela quando nascer.

### O que você vai aprender
- O que um replay por inputs guarda e o que o rastro de estado permite contar.
- Como os números do golpe saem do próprio cabeçalho do replay, e por que o resumo de uma sessão antiga continua certo depois de um número mudar.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Quando `bash tools/replay_summary.sh ARQUIVO` roda sobre um replay do Sozinho, ele imprime o tempo por modo, a contagem de cada manobra, as paredes usadas, a altura máxima e o voo mais longo, como a F-166 §7.
- [x] #2 Quando o replay tem dois lutadores, o resumo separa o do Arthur do boneco ou do bot.
- [x] #3 Quando o arquivo não é um replay válido, o script diz por quê e sai com código diferente de 0.
- [x] #4 Quando o replay tem golpes leves, o resumo imprime os cliques, os golpes que saíram, os que esperaram na vaga, os cliques perdidos por fase do golpe e por motivo (no ar, sem stamina), os golpes emendados, os acertos, os erros com a distância mais curta ao alvo, a vida mínima do alvo e a velocidade durante o golpe, com os ticks do golpe lidos do cabeçalho do replay, como a F-178 §1 e a F-180 §1.
- [x] #5 Quando o replay tem golpes carregados, o resumo imprime para eles as mesmas linhas do leve e, nos dois golpes, a distância ao alvo no primeiro tick ativo, o lado do alvo em relação ao corte nos erros ao alcance e a distância da mira ao alvo, como medido à mão na F-202 e na F-204 (F-205).
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Critérios de aceite verificados
- [x] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [x] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Fechada em 17/11/2026 (F-206). Gate verde: 2307 casos, 0 erros, 0 falhas, 608 s; o reviewer aprovou os critérios 1 a 5. Nos replays das sessões 22 e 23, a lista de golpes do resumo deu todos os números medidos à mão na F-202 e na F-204, conferidos pela sonda do implementer e por um script do reviewer sobre o rastro bruto (vitrine "O resumo do replay"). A régua "ao alcance" do resumo é o alcance de 2,43 m na distância mais curta do ativo, não os 2,6 m do primeiro tick ativo da medida à mão: dois dos quatro erros da sessão 23 saem como longe (testes-e-entrega.md §4, "Os limites"). O Arthur rodou o comando no replay da sessão 23. Depois da revisão, o motivo do limite com três lutadores foi corrigido no §4: o estado guarda o nome do alvo (`contact_target`), e o resumo casa o contato pelo carimbo do tick seguinte. O DoD 3 se fecha com o diário da sessão.
<!-- SECTION:NOTES:END -->
