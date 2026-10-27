---
id: TASK-12
title: 'Fase 2: duelo contra bot e percurso cronometrado'
status: In Progress
assignee: []
created_date: '2026-10-27 15:29'
labels:
  - jogo
milestone: m-2
dependencies:
  - TASK-10
ordinal: 25000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
Fase 2 do roteiro (`docs/roteiro.md`): o duelo contra um bot e o percurso cronometrado. O teste da fase é "Amigos entendem cada troca?" (F-001). Esta é a task-mãe: as filhas, do tamanho de uma sessão, nascem com `-p TASK-12`. A primeira rodada da fase é o desenho do duelo (DEC-0036), que fecha no papel, com números v0 (DEC-0017) e numa vitrine (DEC-0019): a vida e o formato da partida (Q-29), o tranco e a vantagem (Q-10), a matriz de posição (Q-14), a janela do parry (Q-21), a quebra de guarda (Q-25), o golpe que acerta uma vez (Q-26), o hitstop, o bot de reação de gente (F-029), o percurso cronometrado, o relatório de crash pelo log (DEC-0034) e o plano de morte (Q-48). O Arthur abriu a fase em 27/10/2026 pedindo o desenho de ponta a ponta (F-172).

### Perguntas em aberto
Nenhuma depois do desenho: cada número cita a seção do `combate.md` ou do `partida.md`, e uma lacuna é "leitura v0 do Claude", julgada jogando (DEC-0017).

### Escolhas a confirmar
Confirmadas pelo Arthur em 27/10/2026 (F-172 §2): a partida em rounds curtos, melhor de 5, com tempo por round e vida fixa; cair fora é a morte do round no duelo e a volta ao último checkpoint no percurso (Q-48); o som entra na fase 2 com um pacote CC0. Ainda com ele: a matriz de posição (atacar da parede e a regra das mãos), a esquiva unida ao dash ou separada, e o boneco com os clipes dentro da fase 2.

### Fora do escopo
- O 1v1 online e o `view_lag` (fase 3). O arco e as armas (entre a fase 3 e a 4). O 4v4 e o anti-hack (fase 4). Contas, ranking e salas (fase 4). Os mapas e a arte final (fase 5).

### O que você vai aprender
- Frame data de jogo de luta: preparação, ativo, recuperação, tranco e vantagem, tudo em ticks.
- O combate como um segundo modo paralelo ao do movimento (`action`), e "no ar ninguém se defende" como uma regra entre os dois modos (DEC-0022).
- Uma árvore de comportamento que só produz input, com a reação de gente como distribuição e nunca como leitura de estado escondido.
- O fantasma de um percurso como rastro de estado, e o que um replay por inputs não consegue ser.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando amigos jogam o duelo contra o bot, ou um contra o outro, eles entendem cada troca: dizem quem acertou, quem defendeu e por quê (o teste da fase, F-001).
- [ ] #2 Quando um número do combate ou da partida muda no Resource, o jogo muda sem tocar no código (DEC-0004, regra 3).
- [ ] #3 Quando alguém joga o percurso cronometrado, o tempo corre, o fantasma da melhor volta aparece e o melhor tempo fica salvo no PC.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
