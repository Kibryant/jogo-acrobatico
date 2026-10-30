---
id: TASK-12.4
title: 'A quebra de guarda e o tech, e a esquiva como dash'
status: To Refine
assignee: []
created_date: '2026-10-27 22:02'
updated_date: '2026-10-30 14:43'
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
A ferramenta contra quem só bloqueia, com a defesa onde a reação cabe: o tech, 333 ms depois do contato (Q-25; `combate.md`, "A quebra de guarda e o tech"). E a esquiva do combate: o dash ganha a invulnerabilidade dos ticks 3 a 10 e segue só no chão, dando de graça o "no ar ninguém se defende" (`combate.md`, "A esquiva e o dash"; escolha do Arthur na rodada 2 do desenho do duelo, F-174 §2; DEC-0050).

### Perguntas em aberto
Nenhuma: os números estão no `combate.md`.

### Escolhas a confirmar
- A tecla da quebra: padrão sugerido, a tecla E por posição física; o tech é a mesma tecla.

### Fora do escopo
- O que a quebra faz no ar (ela não agarra quem está no ar: TASK-12.5).

### O que você vai aprender
- Reação simples contra reação de escolha, e por que mover a defesa para depois do contato resolve a Q-25.
- Invulnerabilidade como janela em ticks dentro de uma manobra que já existia.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando o jogador aperta a quebra, a preparação dura 21 ticks, o ativo 6 e a recuperação 24, por 15 de stamina; a mão a 1,2 m agarra um corpo cujo eixo está a até 1,55 m.
- [ ] #2 Quando a quebra toca quem está parado, bloqueando, na postura do parry, na recuperação de um golpe, no blockstun ou na preparação de um carregado, os dois ficam presos 20 ticks, sem input.
- [ ] #3 Quando quem foi agarrado aperta a quebra nesses 20 ticks, os dois se soltam no tick 20 e ele fica 2 ticks à frente; quando não aperta, fica 60 ticks sem agir desde o contato, e um carregado começado por quem agarrou no tick 20 pega no 62, antes de a guarda poder subir.
- [ ] #4 Quando um leve pega quem está na preparação da quebra, a quebra para e quem a tentou leva o tranco: a quebra não tem armadura.
- [ ] #5 Quando o dash sai, os ticks 3 a 10 dos seus 12 são invulneráveis: um golpe que tocaria a cápsula ali não pega; nos ticks 1, 2, 11 e 12, pega e interrompe o dash.
- [ ] #6 Quando a quebra toca quem está nos ticks invulneráveis do dash, ela erra, e quem a tentou recupera em 24 ticks.
- [ ] #7 Quando a cena da quebra roda na SyncTest com o rollback de 7 ticks, nenhum campo diverge, e o veneno no carimbo do agarrão a faz acusar.
- [ ] #8 Quando o Arthur joga contra o boneco que mistura leves, carregados e quebras, ele responde à quebra com o tech e esquiva com o dash; a taxa de tech dele fica anotada.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
