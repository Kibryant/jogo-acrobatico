---
id: TASK-10.10
title: >-
  Ajuste da parede: a volta no corredor, a parede que cobre o corpo e a cápsula
  que inclina
status: Done
assignee: []
created_date: '2026-10-24 17:28'
updated_date: '2026-10-24 18:41'
labels:
  - jogo
dependencies:
  - TASK-10.5
parent_task_id: TASK-10
ordinal: 21000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
O Arthur jogou a parede e os 15 minutos (F-131; F-132) e pediu três ajustes antes do gancho (F-134):
- **voltar pelo corredor sem desgrudar** (Q-36);
- **uma cápsula que não "só gruda"** (Q-37);
- **nem toda parede ser corrível:** um bloco de 2 m aceitava a corrida e ficava feio (Q-38).

Os três mexem na parede da TASK-10.5 e cabem numa filha só. A volta cria um elevador no corredor, e o Arthur escolheu que o mapa o limita (F-135).

### Perguntas em aberto
Nenhuma.

### Escolhas a confirmar
1. O limite do elevador. Confirmada pelo Arthur em 24/10/2026 (F-135): **o mapa limita**. A altura das paredes de um corredor estreito é a altura que se quer alcançar, e isso vira uma métrica de nível, sem regra nova.
2. A sonda da cabeça é um raio de motor, só de leitura, 30 cm acima da cabeça. Passa pelo modo de plano, por ser contato com o motor (DEC-0042).

### Números v0 do Claude
Fechados pelo Claude (DEC-0017), entram no `movimento.md` com o plano aprovado.
- **A volta:** no tick do pulo da parede, se a tecla tem componente ao longo da parede contrária ao sentido da corrida, a velocidade ao longo troca de sinal com a mesma rapidez. Sem tecla, com a tecla para frente ou só para fora, nada muda. Os 5 m/s para fora e o 1,2 m de altura não mudam, e vale também para o pulo guardado (DEC-0016).
- **A parede passa da cabeça:** além do contato de hoje, um raio 30 cm acima da cabeça (2,1 m acima dos pés; era 1,7 m no plano, e o implementer achou a entrada baixa no `Block2m`, `mudancas.md` 24/10/2026, DEC-0017) precisa achar uma face no mesmo plano (normal a até 10°), a no máximo raio + 5 cm do centro. Sem isso, a parede não aceita a corrida. Na corrida, quando o raio passa do topo, ela termina como na borda. O `Block1m` e o `Block2m` recusam, e a `ParedeLonga`, o corredor e o `Block3m` aceitam com o raio abaixo do topo (o `Block3m` só com os pés abaixo de 0,9 m).
- **A leitura visual:** só no visual, sem estado. A malha da cápsula inclina 15° para longe da parede, entrando e saindo em 100 ms, e um rastro curto acompanha a corrida (o mesmo material do rastro do dash; nenhum asset novo, DEC-0029).
- **A métrica do corredor:** num corredor estreito (vão de até 4 m), a altura das paredes é a altura que se quer alcançar. Na arena, o corredor fica com 5 m.

### Fora do escopo
- Uma marca "não corrível" no mapa (Q-38; só quando um mapa pedir).
- Animação de verdade, que espera o modelo do lutador.
- Inclinar a câmera.
- O coyote da Q-35 (TASK-10.6).

### O que você vai aprender
- Uma escolha no tick do comando contra o controle contínuo no ar: o "compromisso no ar" continua.
- Um raio do motor só de leitura e por que ele não suja o rollback.
- Visual fora do estado: o que o replay e o rollback não veem, e por que isso é de propósito.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Quando o lutador aperta o pulo na corrida, ou o guardou até 150 ms antes de encostar, com a tecla tendo componente ao longo da parede contrária ao sentido da corrida, o pulo da parede sai com a velocidade ao longo trocada de sinal e a mesma rapidez, os mesmos 5 m/s para fora e 1,2 m de altura (tolerância de 1 cm); sem tecla, com a tecla para frente ou só para fora, sai como hoje (F-131; Q-36; leitura v0 do Claude)
- [x] #2 Quando o lutador pula para trás da parede de um corredor de 3,5 m e cruza sem tecla no ar, ele entra na outra parede correndo no sentido de volta; com a tecla segurada só para trás, reta, ele não cruza, e isso não é erro (F-131; Q-36)
- [x] #3 Quando o lutador encosta numa parede de 80° ou mais e o raio 30 cm acima da cabeça (2,1 m acima dos pés) não acha uma face no mesmo plano, a no máximo raio + 5 cm do centro, a parede não aceita a corrida; na corrida, quando o raio passa do topo, ela termina como na borda; uma pilha de dois blocos no mesmo plano conta como uma parede; o raio não move nada e sai igual no tick novo e no refeito com o rollback de 7 ticks (F-132; Q-38; DEC-0042)
- [x] #4 Quando o lutador corre na arena, o Block1m e o Block2m recusam a corrida, e a ParedeLonga, as paredes do corredor e o Block3m a aceitam com o raio abaixo do topo; o movimento.md ganha a métrica do corredor estreito (vão de até 4 m: a altura das paredes é a altura que se quer alcançar) (F-135)
- [x] #5 Quando o lutador corre na parede, a malha da cápsula inclina 15° para longe dela, entrando e saindo em 100 ms, e um rastro curto a acompanha; nada disso entra no estado, o rollback não duplica o rastro e a gravação de um replay refaz o mesmo rastro de estado (Q-37; DEC-0031 §6; DEC-0004, regra 2)
- [x] #6 Quando a SyncTest roda o cenário da parede com uma volta, ela acha zero divergências; o portão fica verde; o Arthur corre o corredor indo e voltando, tenta o Block2m e vê a cápsula inclinar, e o que ele sentiu vai para uma fonte (F-041; DEC-0027 §5)
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Critérios de aceite verificados
- [x] #2 Teste automatizado para toda regra do núcleo (core/)
- [x] #3 Diário da sessão escrito e glossário atualizado
- [x] #4 Mudanças registradas em docs/mudancas.md
- [ ] #5 Critérios de aceite verificados
- [ ] #6 Teste automatizado para toda regra do núcleo (core/)
- [ ] #7 Diário da sessão escrito e glossário atualizado
- [ ] #8 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
# TASK-10.10 — Ajuste da parede: o plano para o seu ok

## Contexto

Você jogou a parede e os 15 minutos (F-131; F-132) e pediu três ajustes antes do gancho (F-134). Hoje você escolheu que o mapa limita o elevador da volta (F-135). A TASK-10.10 já existe, em To Refine, e a TASK-10.6 depende dela.

## O que você aprova aqui: três mudanças

1. **A volta, no núcleo** (Q-36). No tick do pulo da parede, se a sua tecla aponta para trás ao longo da parede, a velocidade ao longo troca de sinal e mantém a rapidez. A escolha é só naquele tick; o voo segue comprometido. Os testes da TASK-10.5 pulam sem tecla, então nenhum deles muda.
2. **A parede passa da cabeça, no adaptador** (Q-38; DEC-0042). Hoje, o contato vem do próprio movimento ou da sonda de 5 cm. Agora entra também um raio 30 cm acima da cabeça, a 2,1 m dos pés (era 1,7 m; `mudancas.md` 24/10/2026), que pergunta ao motor "tem parede aqui?", sem mover nada.
   - Sem face no mesmo plano (normal a até 10°), o nó não entrega a parede ao núcleo: a entrada é recusada, e na corrida ela termina como na borda.
   - O núcleo não muda nesta parte, e o estado não ganha campo.
   - É uma pergunta ao motor de novo, como a sonda: a SyncTest e o rollback de 7 ticks conferem que ela sai igual no tick refeito.
3. **A cápsula inclina, só no visual** (Q-37). A malha inclina 15° para longe da parede em 100 ms, e um rastro curto acompanha a corrida, reaproveitando o `Trail` do dash (`fighter/maneuver_cues.gd`). Nada disso entra no estado, como os sinais da DEC-0031 §6.

**A métrica do mapa (F-135):** num corredor estreito (vão de até 4 m), a altura das paredes é a altura que se quer alcançar. O corredor da arena fica com 5 m, e o raio da cabeça já termina a corrida no topo.

## A ordem

0. Na main: a TASK-10.10 vira Ready, e o `movimento.md` ganha a volta, a cabeça e a métrica do corredor. Depois, a branch `task-10.10-wall-tuning`.
1. **test-writer**, cego ao código: critério 1 (a volta, a 30 e a 60 ticks, com o pulo guardado) e critério 2 (a travessia de volta, contra a parede falsa do rig). Eu travo.
2. **implementer**, numa rodada só:
   - a volta no núcleo;
   - o raio da cabeça no `Fighter._wall_contact`, com um teste de motor que usa a geometria de teste (bloco de 2 m recusa, parede de 4 m aceita, pilha de dois blocos aceita, topo termina) e o rollback de 7 ticks;
   - o teste de cena da arena (critério 4);
   - a inclinação e o rastro;
   - a volta no cenário "parede" da SyncTest;
   - os docs.
3. **reviewer**, de contexto limpo.
4. O portão e o `net_run.sh`.
5. **Você joga:** o corredor indo e voltando, o `Block2m`, a cápsula inclinando.
6. Push, PR e merge, cada um com o seu ok.

## Quem roda o quê

| Agente | Modelo | Esforço | Por quê |
|---|---|---|---|
| test-writer | Fable | high | Regra pequena, mas com a travessia em escala e o pulo guardado |
| implementer | Opus 5.5 | high | Uma rodada; o raio do motor é o ponto delicado |
| reviewer | Fable | high | Confere que o raio não esconde estado e que o visual não entra no estado |

O ultracode da TASK-10 já foi usado; nada de workflow aqui.

## Verificação

- `bash tools/gate.sh` verde, com os testes travados passando sem edição.
- O teste de motor do raio: o bloco de 2 m recusa, a parede de 4 m aceita, a pilha aceita, o topo termina, e tudo sai igual no tick refeito.
- A SyncTest "parede" com a volta acha zero divergências.
- O `net_run.sh` passa com zero ticks corrigidos.
- Você jogando, e o que sentir vai para uma fonte.

## Riscos

- **O raio numa quina:** o raio sai do eixo da cápsula, então a corrida solta quando o eixo passa da ponta da face, até ≈ 35 cm antes da sonda da TASK-10.5 (`movimento.md`).
- **O `Block3m`:** com o raio a 2,1 m dos pés, ele aceita só com os pés abaixo de 0,9 m e recusa no alto do pulo.
<!-- SECTION:PLAN:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Os três ajustes da parede pedidos pelo Arthur (F-131; F-132; F-134) estão no jogo:
- **A volta (Q-36):** a tecla para trás no tick do pulo da parede troca o sentido com a mesma rapidez; o mapa limita o elevador (F-135).
- **A parede passa da cabeça (Q-38):** um raio só de leitura a 2,1 m dos pés; era 1,7 m no plano, e o implementer achou a entrada baixa no Block2m (leitura v0 do Claude, `mudancas.md`).
- **A cápsula inclina (Q-37):** 15° em 100 ms, com um rastro curto, fora do estado.

Provas: 39 testes travados da volta, testes de motor do raio com rollback de 7 ticks e zero divergências, SyncTest "parede" com `turned_wall_jumps=1` e zero divergências, `net_run` com zero ticks corrigidos e portão verde (952 testes). Revisor: APPROVE, com duas correções de texto aplicadas. O Arthur jogou e achou excelente (F-137). Observação do revisor: o `MovementConfig` guarda três números só do adaptador e do visual, um deles em segundos.
<!-- SECTION:FINAL_SUMMARY:END -->
