---
id: TASK-9
title: 'Esqueleto andante: a cápsula em rede de ponta a ponta'
status: To Refine
assignee: []
created_date: '2026-10-02 16:48'
labels:
  - jogo
  - rede
milestone: m-0
dependencies:
  - TASK-2
  - TASK-4
  - TASK-5
  - TASK-6
ordinal: 9000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
O primeiro código de jogo (DEC-0012): provar a esteira inteira antes de qualquer funcionalidade. A cápsula se move pelo núcleo puro, dentro do tick do netfox, num servidor dedicado com dois clientes e lag simulado, e o CI gera as builds.

### Perguntas em aberto
- Saem dos Desenhos 2, 3 e 4.

### Escolhas a confirmar
- Saem dos Desenhos 2, 3 e 4.

### Fora do escopo
- Parede, dash, gancho e combate: da fase 1 em diante.

### O que você vai aprender
- Como uma tecla vira input, passa pela rede, é simulada no servidor e volta como estado, com o rollback acontecendo na sua frente.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando o servidor dedicado roda sem tela e dois clientes conectam com lag simulado, cada um vê a própria cápsula responder na hora e a outra suavizada.
- [ ] #2 Quando o mesmo input é simulado no servidor e no cliente, o núcleo puro dá o mesmo resultado nos dois, com teste.
- [ ] #3 Quando o push chega na main, o CI gera a build do cliente Windows e a do servidor Linux.
- [ ] #4 Quando o jogo roda neste PC em 1080p, fica em 60 fps ou mais (DEC-0002).
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
