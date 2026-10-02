---
id: TASK-4
title: 'Desenho 2: a arquitetura detalhada'
status: In Progress
assignee: []
created_date: '2026-10-02 16:48'
updated_date: '2026-10-02 21:33'
labels:
  - desenho
milestone: m-0
dependencies:
  - TASK-3
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
Segunda conversa da fase de desenho (DEC-0012). As regras já estão fixadas (DEC-0004), mas falta a forma concreta: o estado, o input, o encaixe do núcleo no netfox, as cenas e as pastas (`docs/arquitetura/visao-geral.md`).

### Perguntas em aberto
A pauta da conversa: cada item sai com resposta, DEC ou pendência.
- A forma do estado e do input: tipos, IDs e o que é sincronizado. O esqueleto andante em detalhe, a fase 1 esboçada e o combate só nomeado (F-018 §1).
- O `step` do núcleo dentro do `_rollback_tick`: a assinatura, o sanduíche com o `move_and_slide()` e onde vive a configuração.
- A máquina de estados do personagem. A DEC-0004 diz `RewindableStateMachine`, mas nela cada estado é um nó com lógica, contra a regra 1. Ela mora no núcleo, como dado?
- As cenas do lutador e da arena; os autoloads, quais e por quê.
- Os acessos inseguros. O Godot 4.7.2 não regula o nível de aviso por pasta: o `directory_rules` só inclui ou exclui. Viram erro no projeto todo, com os addons de fora, ou seguem como aviso (DEC-0005)?
- As pastas por feature dentro do jogo, e o nome do personagem no código.

### Escolhas confirmadas
- Configuração: os números de design ficam em Resources, em ms e metros, e viram na carga um objeto imutável, em ticks, que o núcleo só lê (DEC-0004, regra 3; F-018 §1).
- Escopo do estado: o esqueleto em detalhe, a fase 1 esboçada e o combate só nomeado (F-018 §1).

### Fora do escopo
- O protocolo de rede, o tickrate e a compensação de lag (Desenho 3, TASK-5).
- Instalar o netfox no projeto. Aqui ele é lido no código-fonte, e a prova com ele rodando é do Desenho 3 (Q-02).
- O estado do combate em detalhe: golpe, parry, bloqueio e hitbox (fase 2; Q-10; Q-14).
- Código de jogo: o primeiro código é o esqueleto andante (TASK-9).

### O que você vai aprender
- Functional core, imperative shell na prática, e o sanduíche do movimento.
- Por que o rollback pede estado feito de valores, e não de objetos.
- Como o Godot carrega cena e script; o que é um autoload, e por que evitar estado global.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando a conversa termina, `docs/arquitetura/visao-geral.md` mostra o estado, o input, o `step` e as cenas, com diagrama.
- [ ] #2 Quando o Arthur aprova a forma do estado e as pastas, uma DEC registra.
- [ ] #3 Quando a decisão sobre os acessos inseguros sai, o `project.godot` e o teste de configurações acompanham.
- [ ] #4 Quando um termo novo aparece, ele entra no glossário com o nome no código.
- [ ] #5 Quando o desenho depende de um comportamento do netfox, o documento cita o arquivo do netfox que o confirma, num commit identificado, e o que só o Desenho 3 pode provar fica marcado como hipótese.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Leitura do netfox no código-fonte, sem instalar: como o RollbackSynchronizer lê e restaura as propriedades, o `_rollback_tick`, a `RewindableStateMachine` e os cuidados com o CharacterBody3D.
2. Rodada 1, o núcleo: estado, input, `step`, o sanduíche e a máquina de estados, com um artefato visual de um tick e de um rollback (DEC-0019).
3. Rodada 2, a casca: cenas, autoloads, pastas, nome do personagem e acessos inseguros.
4. Proposta pelo modo de plano; com o ok do Arthur, a DEC e o `visao-geral.md`.
5. Registro: as palavras do Arthur numa F-xxx, o glossário, `mudancas.md`, `pendencias.md`, e o `project.godot` com o teste, se os avisos mudarem.
<!-- SECTION:PLAN:END -->
