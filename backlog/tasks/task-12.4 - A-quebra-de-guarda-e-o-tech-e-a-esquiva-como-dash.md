---
id: TASK-12.4
title: 'A quebra de guarda e o tech, e a esquiva como dash'
status: Done
assignee: []
created_date: '2026-10-27 22:02'
updated_date: '2026-11-18 14:55'
labels:
  - jogo
milestone: m-2
dependencies:
  - TASK-12.3
  - TASK-12.14
parent_task_id: TASK-12
ordinal: 31000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
A ferramenta contra quem só bloqueia, com a defesa onde a reação cabe: o tech, 333 ms depois do contato (Q-25; `combate.md`, "A quebra de guarda e o tech"). E a esquiva do combate: o dash ganha a invulnerabilidade dos ticks 3 a 10 e segue só no chão, dando de graça o "no ar ninguém se defende" (`combate.md`, "A esquiva e o dash"; escolha do Arthur na rodada 2 do desenho do duelo, F-174 §2; DEC-0050). No refino de 17/11/2026, o tranco da quebra sem tech passou de 1.000 para 1.200 ms: com 1.000, o parry ou o dash do tick 60 escapavam do carregado garantido (F-208; vitrine "A quebra sem tech"). As regras no tick estão na DEC-0058 e em `combate.md`, "A quebra, o tech e a esquiva no tick".

### Perguntas em aberto
Nenhuma: os números estão no `combate.md`.

### Escolhas a confirmar
Confirmadas pelo Arthur em 17/11/2026:
- A tecla da quebra e do tech: o aperto do botão do meio do mouse, como no For Honor; o E é do carregado (F-191 §2; F-207).
- O tranco da quebra sem tech: 1.200 ms, 72 ticks (F-208).
- A direção da mão: o ponto da linha da mira a 1,2 m, onde a mão chega (F-209).
- As leituras v0 do plano: quem a quebra agarra, a vaga, o tech de graça, o relógio do agarrão, a esquiva conferida por quem bate e o boneco (F-210; DEC-0058).

### Fora do escopo
- O que a quebra faz no ar (ela não agarra quem está no ar: TASK-12.5).
- A guarda, o parry e a finta no resumo do replay: entram quando alguém os medir à mão duas vezes (TASK-14, "Fora do escopo").

### O que você vai aprender
- Reação simples contra reação de escolha, e por que mover a defesa para depois do contato resolve a Q-25.
- Invulnerabilidade como janela em ticks dentro de uma manobra que já existia.
- Quando um castigo é garantido: o primeiro tick em que o outro pode agir vem depois do contato, contra toda resposta dele, e não só contra a guarda.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Quando o jogador aperta a quebra (o botão do meio do mouse por padrão, remapeável na tela de opções), a preparação dura 21 ticks, o ativo 6 e a recuperação 24, por 15 de stamina; a mão, a 1,3 m de altura, vai até 1,2 m rumo ao ponto da linha da mira a 1,2 m (F-209): com a mira no eixo do boneco parado no mesmo chão, de 0,95 a 1,4 m de centro a centro, ela agarra; a 0,85 m ou a 1,55 m, erra.
- [x] #2 Quando a quebra toca quem está no chão sem bater (parado ou andando, bloqueando, na postura do parry, na preparação ou na recuperação de um golpe, no blockstun, na finta ou nos ticks do dash que não são invulneráveis), os dois ficam presos 20 ticks, mais os 4 da paradinha, sem input; quem está no ativo de um golpe, no tranco de um golpe levado, aparado, no ar, na parede, no gancho ou já preso não é agarrado, e duas quebras que tocam no mesmo tick erram as duas.
- [x] #3 Quando quem foi agarrado aperta a quebra depois do contato, até o último tick preso, os dois se soltam no fim do agarrão (o contato + 20 + os 4 da paradinha) e ele fica 2 ticks à frente; quando não aperta, só volta a agir no contato + 72 + 4, e um carregado começado por quem agarrou ao se soltar pega no contato + 66 (no + 75, se começado no + 33), antes que a guarda, o parry ou o dash de quem foi agarrado saiam (F-208); um aperto de antes do contato não conta como tech.
- [x] #4 Quando um leve pega quem está na preparação da quebra, a quebra para e quem a tentou leva o tranco: a quebra não tem armadura.
- [x] #5 Quando o dash sai, os ticks 3 a 10 dos seus 12 são invulneráveis: um golpe que tocaria a cápsula ali não pega; nos ticks 1, 2, 11 e 12, pega e interrompe o dash.
- [x] #6 Quando a quebra toca quem está nos ticks invulneráveis do dash, ela erra, e quem a tentou recupera em 24 ticks.
- [x] #7 Quando a cena da quebra roda na SyncTest com o rollback de 7 ticks, nenhum campo diverge, e o veneno no carimbo do agarrão a faz acusar.
- [x] #8 Quando o Arthur joga contra o boneco de treino que só dá quebras (`--dummy=guard_break`), ele responde à quebra com o tech e esquiva com o dash; a taxa de tech dele sai do resumo do replay e fica anotada. O tech contra o boneco que mistura leves, carregados e quebras fica para a Q-58 (F-216).
- [x] #9 Quando o replay tem quebras, o resumo do replay imprime, por lutador, as quebras que saíram e o que houve com cada uma (agarrou com tech, agarrou sem tech, errou, cortada) e, de quem foi agarrado, os techs e a taxa de tech.
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
Critério 8, a taxa de tech do Arthur (resumo do replay, linha "Agarrado:"):
- 17/11, primeira sessão, contra o boneco da mistura (sozinho-20261117-204847): nenhuma quebra do boneco pegou nele; ele agarrou 12 vezes sem conseguir ver o agarrão na tela (F-211).
- 18/11, treino da quebra com `--dummy=guard_break` (sozinho-20261118-101646): agarrado 9 vezes, tech em 0 (0 %) (F-213).
- 18/11, depois do "aceso = preso" e do `--dummy=block` (commit 235740f):
  - no treino do tech (sozinho-20261118-111400): agarrado 10 vezes, tech em 4 (40 %), com o aperto em mediana 13 ticks (217 ms) depois do contato. Duas quebras do boneco passaram por ele no dash: no primeiro tick ativo da mão, ele estava no 5º e no 6º tick do dash;
  - na mistura (sozinho-20261118-111634): o boneco soltou uma quebra só, que errou de longe (1,62 m). Nenhum agarrão nele, então nenhum tech a medir (F-214).
- Leitura: o tech e a esquiva com o dash saíram no modo que só dá quebras, feito para treiná-los (F-212). Na mistura, a quebra quase não sai, porque o boneco passa a maior parte do tempo no tranco dos leves do Arthur.

- 18/11, depois da revisão, que pediu o critério 8 contra a mistura:
  - na segunda mistura (sozinho-20261118-114353), o boneco soltou 5 quebras em 1 min 44 s; 3 pegaram o Arthur, sem tech, e 2 erraram de longe;
  - no treino de novo (sozinho-20261118-115111): agarrado 9 vezes, tech em 5 (56 %), com o aperto em mediana a 10 ticks (167 ms) do contato. Duas quebras passaram nos ticks invulneráveis do dash (primeiro tick ativo da mão em 201, no 6º tick do dash, e em 381, no 4º). Em 2001, o dash o tirou do alcance.
- O Arthur aceitou fechar o critério 8 com o modo de treino (F-216), e o critério foi reescrito no lugar. O tech contra a mistura fica para a Q-58.

Fechada em 18/11/2026 (F-215; F-216).
- O reviewer aprovou as rodadas de tela, a 3 (a mão vermelha, os dois acesos, o flash, "Botão do meio!" e o `--dummy=guard_break`) e a 4 ("aceso = preso" e o `--dummy=block`), e todos os critérios menos o 8, que se fechou pela F-216. Os critérios 1 a 7 e o 9 já tinham sido aprovados na primeira revisão.
- Portão verde na árvore revisada: 2521 casos, 0 erros, 0 falhas, 679 s.
- Depois da revisão, entraram só textos: a distância do treino (0,9 a 1,4 m, porque a mão erra a 1,5 m), as citações apontadas pelo reviewer, o critério 8 e os docs da F-216. O portão do push roda de novo no commit de fechamento.
- O DoD 3 se fecha com o diário da sessão.
<!-- SECTION:NOTES:END -->
