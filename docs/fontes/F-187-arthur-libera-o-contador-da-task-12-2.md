---
id: F-187
titulo: O Arthur libera a correção do contador de golpes de um teste travado da TASK-12.2 — contar a entrada no ativo, e não o carimbo do começo que a paradinha empurra (sessão 20, 28/10/2026)
recebido_em: 2026-10-28
como: Resposta escrita do Arthur no terminal da sessão 20 à pergunta do Claude sobre um teste travado. Texto como chegou. A pergunta está como foi mostrada.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: o implementer da TASK-12.2 parou com BLOCKED. O teste travado `test/fighter/guard_sync_test.gd` conta um golpe quando vê `action == ACTIVE` com `action_since` igual ao tick (`Exchanges.observe`). A paradinha da DEC-0055 empurra o `action_since` de quem bateu para a frente no primeiro tick congelado, como exigem os testes travados `combat_hitstop_test.gd` e `combat_block_test.gd`; com o contato no 3º tick do ativo e a paradinha de 4 de um acerto, o começo empurrado cai no tick atual, e o contador conta o mesmo golpe de novo: 6 em vez de 4. O revisor, em contexto limpo, confirmou que nenhuma implementação satisfaz os três testes, e que contar a entrada no ativo, comparando com o tick anterior, mantém a intenção. Como na F-177, só o Arthur destrava (DEC-0009).

## §1 — A pergunta, como foi mostrada

"**Posso corrigir o contador da SyncTest da guarda e refazer a trava?** *Recomendo que sim:* o teste continua exigindo os mesmos 4 golpes, só que contando a entrada no ativo em vez do carimbo do começo."

## §2 — A resposta

"Sim"
