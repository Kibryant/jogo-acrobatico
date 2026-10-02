---
id: TASK-3
title: 'Desenho 1: o jogo no papel'
status: Ready
assignee: []
created_date: '2026-10-02 16:48'
labels:
  - desenho
milestone: m-0
dependencies: []
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
Primeira conversa da fase de desenho (DEC-0012, proposta). O combate tem os números v0 do estudo, mas o movimento quase não tem números, e nenhum código pode inventá-los (`docs/design/movimento.md`; AGENTS.md). Esta conversa fecha o jogo no papel o suficiente para o esqueleto andante e para a fase 1.

### Perguntas em aberto
- Pilares e anti-pilares (`docs/design/visao.md`).
- Kit de movimento v0 em números: velocidades, pulo, dash, parede, gancho e câmera (`docs/design/movimento.md`).
- Tribo do combate: Mordhau ou For Honor (Q-06).
- Técnica própria do jogo (Q-07): só abrir espaço para ela.
- Nome do jogo (Q-04): provisório ou definitivo.

### Escolhas a confirmar
- Câmera em terceira pessoa. Padrão sugerido: terceira pessoa, pela leitura do combate e da acrobacia.
- Dash e esquiva. Padrão sugerido: separados no papel, unificados se o protótipo pedir.
- Tribo For Honor e Chivalry 2 (Q-06). Padrão sugerido: essa, como as regras v0 já puxam.

### Fora do escopo
- Mapas e armas além das três primeiras.
- Arte e som (Desenho 5, TASK-7).

### O que você vai aprender
- Como um designer escreve sensação em números (ms, metros, curvas), e por que esses números viram teste.
- O vocabulário de jogo de luta: preparação, ativo, recuperação e vantagem de frame.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando a conversa termina, `docs/design/visao.md` tem os pilares e os anti-pilares fechados.
- [ ] #2 Quando a conversa termina, `docs/design/movimento.md` tem o kit v0 em números, cada um com a unidade, sem lacuna que o esqueleto andante precise.
- [ ] #3 Quando o Arthur decide a tribo do combate, a câmera e o nome provisório, uma DEC registra cada decisão.
- [ ] #4 Quando um termo novo aparece, ele entra no glossário com o nome no código.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
