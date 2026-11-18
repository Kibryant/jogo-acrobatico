---
id: TASK-12.15
title: 'A câmera centrada: o experimento do --camera=center'
status: Done
assignee: []
created_date: '2026-11-18 15:52'
updated_date: '2026-11-18 17:46'
labels: []
dependencies: []
parent_task_id: TASK-12
ordinal: 41000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
A linha da mira passa 0,8 m à direita do corpo (DEC-0045), e o golpe sai do corpo rumo ao ponto dessa linha a 2,0 m na espada e a 1,2 m na quebra: só nessa distância a mira é exata. Mais perto, o Arthur mira à direita do boneco, e o replay mediu 0,17 a 0,19 m nos três golpes (Q-57; F-213). A pesquisa mostrou que nenhum jogo de espada garante "o que está na mira é o que o golpe pega" com a câmera de lado. O Mordhau, PvP de espada, centralizou a câmera em 2020, e o GunZ deixa a mira no centro com o boneco logo abaixo (F-217; vitrine "A mira de lado"). O Arthur escolheu experimentar a câmera centrada sem mudar o padrão: ele joga as duas e escolhe (F-218; F-219).

### Perguntas em aberto
Nenhuma: os números estão no `movimento.md`, "Câmera", e no plano aprovado (F-219).

### Escolhas a confirmar
Confirmadas pelo Arthur em 18/11/2026, na aprovação do plano (F-219):
- A subida da câmera centrada: 0,6 m, com o pivô a 2,2 m dos pés. É a opção "o jeito do GunZ" da lista da DEC-0045, com os pés a 55 px da borda de baixo.
- A opção ao abrir o jogo, só no Sozinho: `--camera=shoulder|center`.

### Fora do escopo
- Trocar o padrão: só depois de o Arthur jogar as duas câmeras (critério 6).
- A câmera centrada online.
- A troca de ombro (Q-41).
- Ajustar a distância ou o campo de visão.
- A mira das armas de longe.

### O que você vai aprender
- O braço de mola da câmera (SpringArm3D) e o eixo óptico: por que a mira da tela e o raio do jogo saem do mesmo ponto O.
- Dados injetados na partida: a mesma regra rodando com outros números, sem `if` espalhado pelo código.
- O cabeçalho do replay por reflexão: um campo novo nos dados entra no replay sozinho, e é por isso que os replays de antes passam a pedir `--force`.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Quando o Sozinho abre com `--camera=center`, a câmera fica sem deslocamento para o lado e 0,6 m mais alta, com o pivô a 2,2 m dos pés, e com a distância, o campo de visão e a sensibilidade de hoje; sem a opção, ou com `--camera=shoulder`, nada muda (0,8 m à direita, a 1,6 m).
- [x] #2 Quando a câmera está centrada, o ponto O fica no eixo do corpo a 2,2 m dos pés: a mira da tela, o raio do gancho e o alcance de 3 a 25 m saem dele; o segundo raio do gancho e o cabo seguem saindo do ombro do corpo, a 1,6 m.
- [x] #3 Quando a câmera está centrada, o golpe sai na direção da câmera, sem o desvio para a direita: com a mira no eixo do boneco parado no mesmo chão, o leve, o carregado e a quebra pegam de 0,9 m até o alcance de cada golpe (`combate.md`), sem compensação para o lado.
- [x] #4 Quando `--camera=center` vem junto com `--server`, `--connect` ou `--watch`, o jogo recusa e diz por quê: o servidor e os clientes precisam da mesma mira.
- [x] #5 Quando uma sessão com a câmera centrada é gravada, o cabeçalho do replay leva o ombro 0 e a subida de 0,6 m da mira, o replay toca igual sem `--force`, e o `--watch` mostra a câmera centrada; os replays gravados antes desta task pedem `--force`, por causa do campo novo.
- [x] #6 Quando o Arthur joga as duas câmeras no Sozinho (o duelo contra o boneco, a corrida na parede e o gancho), ele escolhe qual fica como padrão; se for a centrada, uma DEC nova substitui a DEC-0045.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Critérios de aceite verificados
- [x] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [x] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Fechada em 18/11/2026 (F-220; DEC-0059).
- Critério 6: o Arthur jogou as duas câmeras e ficou com a centrada como padrão, como no GunZ, para rever no futuro (F-220). Foram duas sessões: a centrada (sozinho-20261118-143319, 2 min 30 s) e a no ombro (sozinho-20261118-143636, 1 min 19 s).
  - A mira em relação ao alvo, nos golpes que pegaram: com a centrada, leve 0,06 m à direita, carregado 0,05 m à esquerda e quebra 0,07 m à esquerda; com a do ombro, 0,34, 0,18 e 0,22 m à direita.
  - A DEC-0059 substitui a DEC-0045. A troca do padrão nos dados e no lançamento ficou para a TASK-12.16, junto com a mão do agarrão, que some atrás do corpo vista da câmera centrada (F-220).
- O reviewer aprovou os critérios 1 a 5. Ele rodou na hora 85 testes, entre eles os 45 travados do golpe reto, e conferiu as travas, a pureza do núcleo e a conta dos 88 px e dos 55 px. Os dois itens menores que apontou entraram em a2e9bdf.
- Portão verde do implementer: 2665 casos, 0 erros, 0 falhas, 707 s. O portão do push roda de novo no commit de fechamento.
- O DoD 3 se fecha com o diário da sessão.
<!-- SECTION:NOTES:END -->
