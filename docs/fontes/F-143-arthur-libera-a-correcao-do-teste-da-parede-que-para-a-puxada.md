---
id: F-143
titulo: O Arthur libera a correção de uma linha no teste travado da parede que para a puxada (sessão 16, 26/10/2026)
recebido_em: 2026-10-26
como: Resposta do Arthur à pergunta do Claude no terminal da sessão 16, retomada em 26/10/2026. Opção escolhida, como chegou.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: o implementer parou a rodada B da TASK-10.6 num caso travado, `test_a_wall_that_stops_the_body_releases_the_grapple_on_the_next_tick` (`test/core/fighter/movement_grapple_test.gd`). A conta auxiliar `_first_contact_index` chamava de batida o primeiro tick da puxada que terminava a até 5 cm da parede (`WALL_PROBE_DISTANCE`), mas o rig só para o corpo quando o movimento cruza o plano. O corpo cai um pouco enquanto o cabo voa, a puxada sobe levemente, e um tick terminava 0,53 mm (30 ticks) ou 0,32 mm (60 ticks) antes da parede, sem encostar: o teste esperava a soltura um tick cedo demais. O Claude conferiu a análise no rig e mostrou a tabela dos ticks. A correção conta como batida só o tick que termina no plano (`LANDING_HAIR`); com ela, os 94 casos passam.

## §1 — A resposta

- "Posso corrigir essa linha do teste travado e travar de novo?": "Pode corrigir (Recomendado)". A opção dizia: "Uma linha na conta auxiliar do teste. A regra e o que o teste exige não mudam. Eu travo de novo, registro no mudancas.md e no registro do harness, e o implementer segue para o raio no nó."
- A outra era "Quero ver antes" ("Te mostro o diff da linha e a conta tick a tick antes de mexer em qualquer coisa.").
