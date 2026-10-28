---
id: F-177
titulo: O Arthur libera a correção de uma linha de um teste travado da TASK-12.1 — o estado do fim do tick no lugar do estado do meio (sessão 20, 28/10/2026)
recebido_em: 2026-10-28
como: Resposta escrita do Arthur no terminal da sessão 20 à pergunta do Claude sobre um teste travado. Texto como chegou. A pergunta está como foi mostrada.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: o implementer da TASK-12.1 parou com BLOCKED. O teste travado `test_a_press_in_a_dash_waits_and_fires_on_the_first_tick_back_on_the_ground` (`test/core/fighter/combat_light_attack_test.gd`) confere, logo depois de apertar o dash, que o dash começou, lendo `fighter.fought.mode`: o estado que o `Combat.step` devolve, antes do `Movement.before_move`. O dash só começa dentro do `before_move` (DEC-0041 §1; DEC-0051 §2 e §4), então essa leitura é sempre `GROUND` e falha a 30 e a 60 ticks. O revisor, em contexto limpo, concluiu o mesmo: nenhuma implementação que respeite as duas DECs passa nessa linha, e ler o estado do fim do tick, `fighter.state().mode`, mantém a intenção do teste, como a linha 465 do próprio teste já faz. Como na F-168 §2, só o Arthur destrava (DEC-0009).

## §1 — A pergunta, como foi mostrada

"**Posso corrigir a linha 452 e refazer a trava?** *Recomendo que sim:* o teste continua cobrando exatamente o que cobrava, só olhando o estado no ponto certo do tick."

E, depois do veredito do revisor: "**Posso corrigir a linha 452 do teste travado e refazer a trava?** Recomendo que sim. Depois disso, eu rodo o portão, e você joga o leve no boneco."

## §2 — A resposta

"Ok"
