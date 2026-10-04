---
id: TASK-9
title: 'Esqueleto andante: a cápsula em rede de ponta a ponta'
status: To Refine
assignee: []
created_date: '2026-10-02 16:48'
updated_date: '2026-10-04 17:55'
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

## Comments

<!-- COMMENTS:BEGIN -->
author: Claude
created: 2026-10-04 17:13
---
Entrada do Desenho 3 (TASK-5; DEC-0023 a DEC-0026), para o esqueleto andante:
- O netfox já está em addons/, fixado no cf5189d (DEC-0023). Os 14 autoloads ficam em res:// e o tickrate em 60; o test/project_settings_test.gd guarda os dois.
- A Main tem três modos (DEC-0026 §6): --server com --port=N, ou a feature dedicated_server; --connect=host:porta; e, sem argumento, o par offline. Fechar limpo é parar o NetworkTime, fechar o peer, soltar a Match e só então sair. Conferir a saída com código 0, porque a sonda caía ao fechar (F-026 §4).
- O input (DEC-0026 §1):
  - o move é a média dos frames do tick, e o yaw é o do último frame;
  - o jump é comando de um toque, consumido no after_tick, como o one-off-input.gd do netfox;
  - input_delay 0, sem broadcast, e o RollbackSynchronizer sem previsão.
- O tick do lutador (DEC-0025): o contorno do transform no after_prepare_tick, em todo tick refeito; o contorno D no primeiro tick de cada rollback; o sanduíche depois dos dois.
- A SyncTest vira teste permanente no CI (DEC-0004, regra 4; DEC-0025): rampa de 45°, beirada, pouso e dois lutadores se empurrando, com rollback forçado de 7 ticks, a profundidade de 220 ms a 60. A sonda de referência está em ../netfox-sonda/sonda (main.gd, probe_fighter.gd e sync_probe.gd).
- As medições de referência estão no docs/arquitetura/rede.md §10.
---

author: Claude
created: 2026-10-04 17:55
---
Correção do comentário anterior: como o yaw e o pitch entram no tick fica para a TASK-9 decidir. Pode ser a última amostra ou uma média que respeite a volta de 360°; a média simples de ângulo erra (DEC-0026 §1; rede.md §3). O move segue o padrão do netfox para entrada contínua: a média das amostras dos frames do tick.
---
<!-- COMMENTS:END -->
