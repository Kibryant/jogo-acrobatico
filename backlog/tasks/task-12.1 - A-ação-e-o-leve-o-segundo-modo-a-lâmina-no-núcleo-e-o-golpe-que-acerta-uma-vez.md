---
id: TASK-12.1
title: >-
  A ação e o leve: o segundo modo, a lâmina no núcleo e o golpe que acerta uma
  vez
status: Ready
assignee: []
created_date: '2026-10-27 22:02'
labels:
  - jogo
milestone: m-2
dependencies: []
parent_task_id: TASK-12
ordinal: 28000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
A primeira regra do combate. O segundo modo do lutador, a ação (nada, preparação, ativo, recuperação), nasce como dado no núcleo, paralelo ao modo do movimento (DEC-0022; `visao-geral.md`, "A máquina de estados"). A lâmina vira a conta do núcleo da DEC-0026 §4: um segmento com raio contra a cápsula, com a fatia varrida por tick, e cada golpe acerta cada alvo uma vez só (Q-26). O boneco ganha vida e perde 12 por leve. É a filha que põe o leve de 400 ms na mão do Arthur: ele julga a leitura (`combate.md`, "Os golpes e as defesas").

### Perguntas em aberto
Nenhuma: os números estão no `combate.md` ("Os golpes e as defesas", "A lâmina e o contato") e no `partida.md` (a vida de 100).

### Escolhas a confirmar
- A tecla do leve: o botão esquerdo do mouse, por posição física, remapeável (DEC-0031 §8). Padrão sugerido; o Arthur confirma ao abrir.

### Fora do escopo
- A defesa, o tranco e o hitstop (TASK-12.2). O carregado (TASK-12.3). A partida e o KO que encerra o round (TASK-12.7): aqui a vida para em zero e o boneco volta a 100 depois de 2 s.

### O que você vai aprender
- Frame data: preparação, ativo e recuperação em ticks, e por que o contato é um carimbo no estado de quem bateu (DEC-0026 §3).
- A fatia varrida: por que testar só a pose de cada tick deixaria a lâmina pular o corpo.
- O replay ganha as colunas do combate sozinho, pelo cabeçalho declarado (`testes-e-entrega.md` §4), e a Q-39 mede o tamanho.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando o jogador aperta o leve no chão, a ação passa pela preparação de 24 ticks, pelo ativo de 6 e pela recuperação de 15, com os 8 de stamina pagos no primeiro tick, e nenhum input corta a sequência (DEC-0016).
- [ ] #2 Quando o jogador aperta o leve sem 8 de stamina, o golpe não sai, nada é pago e o aperto espera na vaga do buffer pelos 150 ms (`movimento.md`, "Stamina").
- [ ] #3 Quando a lâmina, um segmento de 1,4 m com 0,08 m de raio na mão a 0,6 m do eixo e 1,3 m de altura, varre o arco de 120° nos 6 ticks do ativo e a fatia varrida toca a cápsula do boneco, o contato é carimbado no estado de quem bateu, com o tick, o alvo e o golpe, e o boneco perde 12 de vida.
- [ ] #4 Quando a lâmina fica parada dentro do corpo do boneco por todo o ativo, ele perde 12 uma vez só (Q-26), e um teste do núcleo prova isso com tabela.
- [ ] #5 Quando o golpe entra no ativo, a direção do arco é a da câmera no último tick da preparação, e girar a câmera durante o ativo não a move.
- [ ] #6 Quando dois leves pegam no mesmo tick, os dois lutadores perdem 12 (a troca).
- [ ] #7 Quando a SyncTest roda a cena do leve com o rollback de 7 ticks, nenhum campo do estado diverge, os sinais apresentados são tantos quanto os golpes, e o veneno no campo da ação a faz acusar.
- [ ] #8 Quando o Arthur joga, o leve sai no botão escolhido, a lâmina de blocos mostra a preparação e o arco, e a barra de vida do boneco desce 12 por acerto; o replay desta sessão guarda as colunas novas, e o tamanho por tick e lutador fica anotado (Q-39).
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
