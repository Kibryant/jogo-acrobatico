---
id: TASK-10.8
title: 'O teste dos 15 minutos: o bot com manobras, a Q-16 online e a versão 0.2.0'
status: In Progress
assignee: []
created_date: '2026-10-19 13:47'
updated_date: '2026-10-26 23:06'
labels:
  - jogo
milestone: m-1
dependencies:
  - TASK-10.7
  - TASK-10.9
  - TASK-10.12
parent_task_id: TASK-10
ordinal: 19000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
O teste da fase é "divertido sozinho por 15 min?" (`roteiro.md`:13; F-001), o critério 1 da TASK-10. O Arthur jogou 15 min 38 s e continuaria jogando; a ação que falta é a fase 2 (F-166 §2). Na rede, o bot da corrida de 30 s, que já dá o dash (TASK-10.4), ganha o pulo duplo, e a ping 100 o servidor e os clientes têm de bater em todos os ticks (`rede.md` §8 e §10). A Q-16 virou a DEC-0046, e a sessão online conferiu o escorregão a ping 100 (F-166 §1). O critério 2 da TASK-10 ganha o seu teste pela cópia do Resource (DEC-0017). A pergunta do Arthur sobre a escada em Z achou um risco nos cantos da borda, que esta filha mede (F-167). A regra da mesma parede vai para a TASK-10.13 (DEC-0047), e o fechamento da fase com a 0.2.0, para a TASK-10.14 (F-167 §2).

### Perguntas em aberto
Nenhuma. O teste respondeu a Q-07, a Q-34, a Q-40, a Q-42, a Q-43 e a Q-44, cada uma com a data (`pendencias.md`; F-166).

### Escolhas a confirmar
Confirmadas pelo Arthur em 26/10/2026 (F-165; F-167 §2):
1. O bot da corrida em rede ganha só o pulo duplo, no topo do pulo de cada perna (350 ms depois), ao lado do dash que já tem; a parede e o gancho online esperam a fase 3, que precisa de um alvo na rota do bot e da regra do raio nos ticks previstos (DEC-0044).
2. O Z num canto da borda se mede agora, com uma sonda: se passar dos 50 m, o plano de morte vira filha da TASK-10 antes da 0.2.0.
3. Esta filha fecha sem fechar a TASK-10: o fechamento da fase, a versão 0.2.0 e a release pública ficam na TASK-10.14, depois da TASK-10.13.

### Números v0 do Claude
Fechados pelo Claude (DEC-0017).
- A corrida de 30 s exige zero ticks corrigidos e zero faltando a ping 100, como na TASK-9, com o tempo do portão anotado (`rede.md` §10).
- Com o pulo duplo no topo, o voo do bot vai de 630 ms a uns 1.070 ms: o dash, aos 1.000 ms de cada perna, cairia no ar. Ele passa para depois do pouso, no chão, e termina antes da perna seguinte.
- O teste do critério 2 da TASK-10 muda o pulo duplo de 1,0 para 1,5 m numa cópia do Resource e mede o topo pela simulação, sem tocar no código.
- A sonda do canto dirige o lutador por 30 s em Z entre duas bordas, com a volta no pulo da parede, com e sem o pulo duplo, e mede a altura máxima.

### Fora do escopo
- A regra da mesma parede (TASK-10.13). O fechamento da fase e a 0.2.0 (TASK-10.14).
- O plano de morte, que só nasce se a sonda mandar.
- O combate (fase 2). O bot que reage. O percurso cronometrado com fantasma (fase 2).
- A bancada do Mac (Q-24, task pequena separada). A Q-13, só se o Arthur falar dela.

### O que você vai aprender
- Decidir uma regra jogando: o que muda entre "achei estranho" e "é assim".
- O que o teste da fase mede, e o que fazer quando ele diz "não".
- O netcode com manobras: por que um bot que dá pulo duplo e dash a ping 100 prova mais que mil testes do núcleo.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando o `tools/net_run.sh` roda 30 s com os bots dando pulo duplo e dash, a corrida passa a ping 100 com zero ticks corrigidos e zero faltando, cada bot dá ao menos um pulo duplo e um dash, e o tempo do portão fica anotado (`rede.md` §8 e §10; DEC-0027 §1; F-165)
- [ ] #2 Quando um número de movimento muda numa cópia do Resource (o pulo duplo de 1,0 para 1,5 m), o jogo muda sem tocar no código, e um teste prova isso pela cópia (TASK-10, critério 2; DEC-0017; DEC-0004, regra 3)
- [ ] #3 Quando o Arthur sobe na cabeça do bot online pelo `tools/play_online.sh 100`, ele escorrega como no Sozinho, sem o corpo voltar para cima por uma correção, e o que ele sentiu vai para uma fonte; um problema ali é bug de rede, corrigido sem mudar a DEC-0046 (DEC-0046; F-165)
- [ ] #4 Quando o Arthur joga 15 minutos cronometrados sozinho na arena com o kit inteiro, ele quer continuar; o que ele sentiu e as técnicas que achou vão para uma fonte, as pendências Q-07, Q-34, Q-40, Q-42, Q-43 e Q-44 ganham a resposta datada, e os números que ele pedir mudam no `.tres`, no `movimento.md` e na vitrine, no mesmo link, sem tocar no código; quando ele não quer continuar, o motivo vira fonte e as filhas de ajuste nascem com `-p TASK-10` (F-001; TASK-10, critério 1; DEC-0017; DEC-0019)
- [ ] #5 Quando a sonda do canto dirige o lutador em Z entre duas bordas, num canto da arena, por 30 s, a altura máxima fica medida e anotada no `movimento.md` ("A borda"); se passar dos 50 m, o plano de morte nasce como filha da TASK-10 e entra nas dependências da TASK-10.14 (F-167 §2)
- [ ] #6 Quando o Sozinho fecha e salva o replay, o log diz quantos ticks a sessão teve, e não quantas linhas os dois lutadores escreveram (F-166, contexto)
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
**Rodada A, o implementer (Opus 5.5, xhigh):**
1. **O pulo duplo do bot:** a `BotRoute` ganha o aperto do pulo duplo no topo do pulo de cada perna (350 ms), e o dash passa para depois do pouso, no chão, terminando antes da perna seguinte. O `BotPlayer` aperta pelo `FighterInput`. O CSV do `tools/net_run.sh` ganha, por cliente, os pulos duplos e os dashes que saíram, maiores que zero como pré-condição. A corrida a ping 100 passa com zero ticks corrigidos e zero faltando, e o tempo do portão fica anotado (`rede.md` §10).
2. **O teste do critério 2 da TASK-10:** `test/data/movement_tuning_test.gd` faz o `duplicate()` do `movement_v0.tres`, põe o pulo duplo em 1,5 m, confere o `validate()` vazio e mede o topo pela simulação, a 1,5 m com 1 cm de folga a 60 ticks. O recurso em cache fica intocado (DEC-0004, regra 3).
3. **A sonda do canto:** no motor, o lutador num canto da borda, dirigido tick a tick em Z entre as duas bordas, com a volta no pulo da parede e o pulo guardado, com e sem o pulo duplo, por 30 s. Mede a altura máxima. A sonda é temporária e fica fora do portão; o resultado e o método vão para o `movimento.md` ("A borda"). Se passar dos 50 m, a filha do plano de morte nasce com `-p TASK-10` e entra nas dependências da TASK-10.14.
4. **O log do Sozinho:** a frase do replay salvo conta os ticks, e não as linhas dos dois lutadores.

**Rodada B:** o revisor (Fable, high) julga os seis critérios com prova, começando do "não". Depois, o portão, com o Godot fechado e a CPU conferida.

**Rodada C:** o diário, o registro, o PR em português e o merge, com o ok do Arthur.

Sem test-writer: nenhuma regra nova do núcleo. A SyncTest segue com as oito cenas, e a corrida em rede é a prova desta filha.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
O rascunho de 19/10 (em inglês) virou o plano acima. Mudou desde ele: o bot ganha só o pulo duplo, porque o dash já veio na TASK-10.4 (F-165); a Q-16 virou a DEC-0046 antes da sessão online (F-165); o teste dos 15 minutos passou e respondeu as pendências (F-166); a regra da mesma parede foi para a TASK-10.13 (DEC-0047), e o fechamento da fase com a 0.2.0, para a TASK-10.14 (F-167 §2); a sonda do canto entrou (F-167 §2).
<!-- SECTION:NOTES:END -->
