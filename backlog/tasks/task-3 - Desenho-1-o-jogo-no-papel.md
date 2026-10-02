---
id: TASK-3
title: 'Desenho 1: o jogo no papel'
status: In Progress
assignee: []
created_date: '2026-10-02 16:48'
updated_date: '2026-10-02 19:13'
labels:
  - desenho
milestone: m-0
dependencies: []
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
Primeira conversa da fase de desenho (DEC-0012). O combate tem os números v0 do estudo, mas o movimento quase não tem números, e nenhum código pode inventá-los (`docs/design/movimento.md`; AGENTS.md). Esta conversa fecha o jogo no papel o suficiente para o esqueleto andante e para a fase 1.

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
- [x] #1 Quando a conversa termina, `docs/design/visao.md` tem os pilares e os anti-pilares fechados.
- [x] #2 Quando a conversa termina, `docs/design/movimento.md` tem o kit v0 em números, cada um com a unidade, sem lacuna que o esqueleto andante precise.
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Rodada 1, a alma: pilares e anti-pilares, câmera e tribo do combate (Q-06).
2. Rodada 2, o corpo: o kit de movimento v0 em números, dash e esquiva, e o espaço para a técnica própria (Q-07).
3. Rodada 3: o nome provisório (Q-04) e a revisão das DECs.
4. Registro: as palavras do Arthur numa F-xxx; `visao.md`, `movimento.md` e o glossário; as DECs pela skill `adr`; `mudancas.md` e `pendencias.md`.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Rodada 1 (02/10/2026, sessão 2):
- Pilares e anti-pilares fechados em `docs/design/visao.md` (F-012; F-013; F-014).
- Câmera em terceira pessoa (DEC-0013), tribo For Honor e Chivalry 2 (DEC-0014) e cancelamento só desenhado (DEC-0016).
- Como trabalhamos: o Claude registra o que é pensamento em voz alta, tem posição e diz não (DEC-0015).
- Registrado como ideia, não como decisão: a pirueta expõe e também tira da linha do tiro (F-012; F-013).
- Pendências novas: Q-10 (tranco) e Q-11 (combinações de armas).

Rodada 2 (02/10/2026, sessão 2):
- Kit de movimento v0 fechado em `docs/design/movimento.md`: a primeira tabela pelo Arthur (F-015), o resto pelo Claude (DEC-0017).
- Decisões do Arthur: pulo duplo, sem dano de queda, o corpo olha para onde a câmera olha e a câmera do GunZ como referência (F-015).
- Dash e esquiva ficaram separados no papel; o protótipo pode unir os dois.
- Pendências novas: Q-12 (corpos diferentes), Q-13 (a explicação no mundo para a acrobacia) e Q-14 (matriz de posição e regra das mãos).
<!-- SECTION:NOTES:END -->
