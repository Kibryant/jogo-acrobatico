---
id: TASK-8
title: 'Desenho 6: infraestrutura e serviços'
status: To Refine
assignee: []
created_date: '2026-10-02 16:48'
labels:
  - infra
  - desenho
milestone: m-0
dependencies:
  - TASK-5
  - TASK-6
ordinal: 8000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
Sexta conversa da fase de desenho (DEC-0012). O jogo vai precisar de servidor em São Paulo, contas, Steam e comunidade. A maior parte se decide depois, mas os gatilhos e as direções se fixam agora (DEC-0011).

### Perguntas em aberto
- Hospedagem: VPS em SP com Docker ou Edgegap (Q-05), e o custo por faixa de jogadores (F-001).
- Contas e ranking no Supabase: quando entram e em qual projeto.
- Steam: quando a página entra, o Steam Direct (US$ 100) e o GodotSteam (F-001; F-006 §11).
- Telemetria e relatório de crash.
- Comunidade: o Discord como pilar de relacionamento (F-001).
- Legal: LGPD art. 14, ECA Digital, classificação indicativa e a licença (Q-04) (F-001).

### Escolhas a confirmar
- Nada pago antes da fase 3. Padrão sugerido: sim.

### Fora do escopo
- Contratar qualquer serviço.

### O que você vai aprender
- Como um servidor de jogo roda em Docker, e por que a região importa: de 10 a 35 ms em São Paulo contra 110 a 160 ms nos EUA (F-001).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando a conversa termina, `docs/arquitetura/infraestrutura.md` tem cada serviço com o gatilho de entrada e o custo estimado.
- [ ] #2 Quando o Arthur decide a hospedagem do esqueleto andante, uma DEC registra.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
