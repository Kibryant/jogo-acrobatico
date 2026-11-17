---
id: TASK-12.4
title: 'A quebra de guarda e o tech, e a esquiva como dash'
status: In Progress
assignee: []
created_date: '2026-10-27 22:02'
updated_date: '2026-11-17 16:05'
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
- [ ] #1 Quando o jogador aperta a quebra (o botão do meio do mouse por padrão, remapeável na tela de opções), a preparação dura 21 ticks, o ativo 6 e a recuperação 24, por 15 de stamina; a mão, a 1,3 m de altura, vai até 1,2 m rumo ao ponto da linha da mira a 1,2 m (F-209): com a mira no eixo do boneco parado no mesmo chão, de 0,95 a 1,4 m de centro a centro, ela agarra; a 0,85 m ou a 1,55 m, erra.
- [ ] #2 Quando a quebra toca quem está no chão sem bater (parado ou andando, bloqueando, na postura do parry, na preparação ou na recuperação de um golpe, no blockstun, na finta ou nos ticks do dash que não são invulneráveis), os dois ficam presos 20 ticks, mais os 4 da paradinha, sem input; quem está no ativo de um golpe, no tranco de um golpe levado, aparado, no ar, na parede, no gancho ou já preso não é agarrado, e duas quebras que tocam no mesmo tick erram as duas.
- [ ] #3 Quando quem foi agarrado aperta a quebra depois do contato, até o último tick preso, os dois se soltam no fim do agarrão (o contato + 20 + os 4 da paradinha) e ele fica 2 ticks à frente; quando não aperta, só volta a agir no contato + 72 + 4, e um carregado começado por quem agarrou ao se soltar pega no contato + 66 (no + 75, se começado no + 33), antes que a guarda, o parry ou o dash de quem foi agarrado saiam (F-208); um aperto de antes do contato não conta como tech.
- [ ] #4 Quando um leve pega quem está na preparação da quebra, a quebra para e quem a tentou leva o tranco: a quebra não tem armadura.
- [ ] #5 Quando o dash sai, os ticks 3 a 10 dos seus 12 são invulneráveis: um golpe que tocaria a cápsula ali não pega; nos ticks 1, 2, 11 e 12, pega e interrompe o dash.
- [ ] #6 Quando a quebra toca quem está nos ticks invulneráveis do dash, ela erra, e quem a tentou recupera em 24 ticks.
- [ ] #7 Quando a cena da quebra roda na SyncTest com o rollback de 7 ticks, nenhum campo diverge, e o veneno no carimbo do agarrão a faz acusar.
- [ ] #8 Quando o Arthur joga contra o boneco que mistura leves, carregados e quebras, ele responde à quebra com o tech e esquiva com o dash; a taxa de tech dele sai do resumo do replay e fica anotada.
- [ ] #9 Quando o replay tem quebras, o resumo do replay imprime, por lutador, as quebras que saíram e o que houve com cada uma (agarrou com tech, agarrou sem tech, errou, cortada) e, de quem foi agarrado, os techs e a taxa de tech.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
