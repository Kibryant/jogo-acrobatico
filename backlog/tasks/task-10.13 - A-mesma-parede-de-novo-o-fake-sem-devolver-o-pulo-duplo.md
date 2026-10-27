---
id: TASK-10.13
title: 'A mesma parede de novo: o fake sem devolver o pulo duplo'
status: Done
assignee: []
created_date: '2026-10-26 23:04'
updated_date: '2026-10-27 13:01'
labels: []
dependencies: []
parent_task_id: TASK-10
ordinal: 22000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
No teste dos 15 minutos, o Arthur foi para outra parede, desistiu, voltou com o pulo duplo para a mesma, e a regra bloqueou a corrida: ele queria dar um fake (F-166 §3). Ele decidiu que a mesma parede vale de novo, sem devolver o pulo duplo, antes da 0.2.0 (DEC-0047; F-167 §2). Começar uma corrida devolve o pulo duplo; se a mesma parede o devolvesse, cada volta subiria 2,2 m sem fim, e a borda de 50 m viraria saída (vitrine "O teste da fase 1", https://claude.ai/artifact/FwtupAUFCANw72rkedVZ7r). Sem devolver, o fake sai uma vez, e a escada de uma parede só não nasce.

### Perguntas em aberto
Nenhuma.

### Escolhas a confirmar
Confirmadas pelo Arthur em 26/10/2026 (F-167 §2; DEC-0047):
1. A mesma parede aceita uma corrida nova, com as regras de entrada de toda corrida, e essa corrida não devolve o pulo duplo; só o chão ou uma corrida em outra parede o devolvem.
2. Entra antes da 0.2.0, numa filha da TASK-10, com os testes do núcleo.

### Números v0 do Claude
Fechados pelo Claude (DEC-0017).
- Nenhum número novo: a regra muda o que a entrada devolve, não um número.
- A conta no papel, com os números do `movimento.md`: saindo de uma corrida a 1,2 m, a volta na mesma parede entra a ≈ 3,4 m, e o pulo da parede seguinte chega a ≈ 4,6 m, sem pulo duplo para voltar. Hoje o mais alto é ≈ 3,4 m. O teste mede no motor, com folga de 10 cm: os pés nunca passam de 3,5 m acima da primeira corrida.

### Fora do escopo
- Os cantos da borda e o plano de morte: a TASK-10.8 mede, e uma filha própria entra se precisar (F-167 §2).
- O Z entre duas paredes, a emenda e a volta no pulo da parede, que ficam como estão (DEC-0047 §4).
- O dash no ar (Q-34) e a escalada (Q-44), que voltam com o primeiro oponente.

### O que você vai aprender
- Como uma regra de recurso separa técnica de exploit: o mesmo movimento, com o pulo duplo devolvido ou não.
- Como um teste do núcleo prova um limite ("não sobe mais que") sem depender de jogar.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Quando o lutador sai de uma corrida e volta à mesma parede no ar, com 4 m/s ou mais ao longo dela, uma corrida nova começa nela, com a vertical zerada e a velocidade de entrada de toda corrida (DEC-0047 §1; `movimento.md`, "Corrida na parede")
- [x] #2 Quando a corrida começa na mesma parede da última, sem chão nem outra parede no meio, o pulo duplo não volta: gasto, segue gasto; disponível, segue disponível (DEC-0047 §2)
- [x] #3 Quando a corrida começa em outra parede, ou depois de tocar o chão, o pulo duplo volta como hoje, e a cabeça de outro lutador não muda a última parede (DEC-0047 §3; DEC-0046 §1)
- [x] #4 Quando o lutador vai e volta na mesma parede com o pulo duplo e segue apertando o pulo, a segunda volta não acha pulo duplo, e os pés nunca passam de 3,5 m acima da primeira corrida (DEC-0047; o limite da escada)
- [x] #5 Quando a SyncTest refaz, com o rollback forçado, uma volta na mesma parede, o servidor e o cliente batem em todos os ticks, e a cena entra no portão (`rede.md` §8; DEC-0004, regra 4)
- [x] #6 Quando o Arthur joga o fake no Sozinho (vai para outra parede, desiste, volta com o pulo duplo e corre de novo na mesma), a corrida sai, e o que ele sentiu vai para uma fonte (F-166 §3; F-041)
- [x] #7 Quando a regra muda, o `movimento.md` troca a linha "Mesma parede", o glossário ganha o termo novo, e a vitrine "O teste da fase 1" segue no mesmo link com a regra nova (DEC-0019; DEC-0047)
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Critérios de aceite verificados
- [x] #2 Teste automatizado para toda regra do núcleo (core/)
- [x] #3 Diário da sessão escrito e glossário atualizado
- [x] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
A mesma parede vale de novo no voo de um pulo da parede, sem devolver o pulo duplo (DEC-0047; DEC-0048). Os testes foram escritos às cegas e travados, com a recusa depois das outras saídas. A SyncTest mesma_parede passou com 0 divergência. O Arthur fez o fake com a diagonal e aprovou (F-169). O revisor aprovou os sete critérios, e o portão passou em 364 s com 1.505 testes.
<!-- SECTION:FINAL_SUMMARY:END -->
