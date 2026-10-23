---
id: F-122
titulo: O Arthur aprova o plano da TASK-10.4, o dash, no plan mode (sessão 15, 23/10/2026)
recebido_em: 2026-10-23
como: Aprovação do Arthur ao plano "TASK-10.4 — O dash: o plano para o seu ok", no plan mode do terminal da sessão 15. Aprovação como chegou, sem texto.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: o plano veio depois das escolhas da F-121.

## §1 — O plano aprovado

**Três mudanças de arquitetura:**
- A troca de modo por comando no `before_move` (`GROUND → DASH`), na DEC-0041, que substitui a DEC-0022 só nisso. O `DASH` só termina pela própria regra, e o `after_move` não mexe no modo durante o dash.
- O snap do chão cobrindo a maior velocidade no chão: de 0,121 m para 0,338 m a 60 ticks. O preço é que um degrau de até 0,338 m vira chão.
- Os sinais das manobras por chave de evento (lutador, tipo, tick), lidos do estado exibido e só visuais no v0.

**Os números v0 do Claude:**
- 4 m em 200 ms (12 ticks a 60, 6 a 30);
- saída a 7 m/s;
- recarga de 400 ms contada do fim;
- custo de 15;
- sem direção apontada, para onde o corpo olha, fixado no início;
- da beirada, continua com a gravidade;
- contra a parede, o tempo segue e o motor desliza;
- o pulo vence o dash no mesmo tick;
- um arco da recarga no HUD.

**O `run_on_separate_thread`:** fica em `false`, com o motivo novo. O rollback refaz vários `move_and_slide()` por passo, e a thread só ajudaria com física pesada.

**A ordem:** test-writer cego nos critérios 1 a 4, implementer em duas rodadas, revisor, portão e `net_run.sh`, e o Arthur jogando. No teste à mão, ele também julga a Q-33.
