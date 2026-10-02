---
id: TASK-4
title: 'Desenho 2: a arquitetura detalhada'
status: To Refine
assignee: []
created_date: '2026-10-02 16:48'
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
- A forma do estado da simulação e do input: tipos, IDs e o que é sincronizado.
- O `step` do núcleo dentro do `_rollback_tick`: assinatura e onde vive a configuração.
- As cenas do lutador e da arena; os autoloads, quais e por quê.
- Os acessos inseguros viram erro em `core/`?
- As pastas por feature dentro do jogo.

### Escolhas a confirmar
- Configuração lida dos Resources e convertida para ticks na carga, num objeto imutável. Padrão sugerido: esse (DEC-0004, regra 3).

### Fora do escopo
- O protocolo de rede (Desenho 3, TASK-5).

### O que você vai aprender
- Functional core, imperative shell na prática; como o Godot carrega cena e script; o que é um autoload.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando a conversa termina, `docs/arquitetura/visao-geral.md` mostra o estado, o input, o `step` e as cenas, com diagrama.
- [ ] #2 Quando o Arthur aprova a forma do estado e as pastas, uma DEC registra.
- [ ] #3 Quando a decisão sobre os avisos inseguros em `core/` sai, o `project.godot` e o teste de configurações acompanham.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
