---
id: TASK-10
title: 'Fase 1: movimento que diverte sozinho'
status: To Refine
assignee: []
created_date: '2026-10-02 16:48'
labels:
  - jogo
milestone: m-1
dependencies:
  - TASK-9
ordinal: 10000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
Fase 1 do roteiro (`docs/roteiro.md`): correr, subir na parede, pular, dar dash e usar o gancho numa arena de blocos. O teste da fase é "divertido sozinho por 15 min?" (F-001). Esta é a task-mãe: as filhas, do tamanho de uma sessão, nascem com `-p TASK-10` quando o esqueleto andante estiver pronto.

### Perguntas em aberto
- Os números saem do Desenho 1 (TASK-3).

### Escolhas a confirmar
- Nenhuma ainda.

### Fora do escopo
- Combate (fase 2).

### O que você vai aprender
- Game feel: aceleração, coyote time, buffer de input e câmera.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando o Arthur joga 15 minutos sozinho na arena de blocos, ele quer continuar (o teste da fase, F-001).
- [ ] #2 Quando um número de movimento muda no Resource, o jogo muda sem tocar no código.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
