---
id: TASK-12.1
title: >-
  A ação e o leve: o segundo modo, a lâmina no núcleo e o golpe que acerta uma
  vez
status: In Progress
assignee: []
created_date: '2026-10-27 22:02'
updated_date: '2026-10-27 23:15'
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
A primeira regra do combate. O segundo modo do lutador, a ação (nada, preparação, ativo, recuperação), nasce como dado no núcleo, paralelo ao modo do movimento (DEC-0022; `visao-geral.md`, "A máquina de estados"). A lâmina vira a conta do núcleo da DEC-0026 §4: um segmento com raio contra a cápsula, com a fatia varrida por tick, e cada golpe acerta cada alvo uma vez só (Q-26). O boneco ganha vida e perde 12 por leve. O tick ganha a foto e o passo do combate antes do movimento (DEC-0051). É a filha que põe o leve de 400 ms na mão do Arthur: ele julga a leitura (`combate.md`, "Os golpes e as defesas").

### Perguntas em aberto
Nenhuma: os números e as regras do tick estão no `combate.md` ("Os golpes e as defesas", "A lâmina e o contato", "O leve no tick"), no `partida.md` ("A vida sem partida") e no `visual-e-audio.md` ("O leve na tela").

### Escolhas a confirmar
Nenhuma: o leve no botão esquerdo do mouse e o golpe andando a 3 m/s são escolhas do Arthur (F-175 §2), e o plano do tick foi aprovado no modo de plano (F-176; DEC-0051).

### Fora do escopo
- A defesa, o tranco e o hitstop (TASK-12.2): aqui o golpe levado não interrompe o seu. O carregado (TASK-12.3). A matriz de posição e o leve no ar (TASK-12.5). A partida e o KO (TASK-12.7): aqui a vida para em zero e volta a 100 dois segundos depois do último golpe levado. Um golpe que acerta dois alvos (o 4v4).

### O que você vai aprender
- Frame data: preparação, ativo e recuperação em ticks, e por que o contato é um carimbo no estado de quem bateu (DEC-0026 §3).
- A foto do tick: por que cada lutador lê o outro numa cópia do começo do tick, e o tick de atraso que isso custa (DEC-0051).
- A fatia varrida: por que testar só a pose de cada tick deixaria a lâmina pular o corpo.
- O replay ganha as colunas do combate sozinho, pelo cabeçalho declarado (`testes-e-entrega.md` §4), e a Q-39 mede o tamanho.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando o jogador aperta o leve em pé no chão, sem golpe em curso e com 8 de stamina, a ação passa pela preparação de 24 ticks, pelo ativo de 6 e pela recuperação de 15, com os 8 pagos no primeiro tick, e nenhum input corta a sequência (DEC-0016).
- [ ] #2 Quando o jogador aperta o leve sem 8 de stamina, no ar ou com um golpe em curso, o golpe não sai, nada é pago e o aperto espera na vaga do buffer pelos 150 ms, saindo no primeiro tick em que pode (`movimento.md`, "Stamina" e "Perdão").
- [ ] #3 Quando o jogador anda durante o golpe, em pé, o corpo vai a até 3 m/s; um pulo, um dash ou um gancho apertados durante o golpe esperam na vaga e saem no primeiro tick depois da recuperação, se ainda estiverem nos 150 ms; e, no mesmo tick, qualquer tecla de movimento vence o leve (F-175 §2; DEC-0051).
- [ ] #4 Quando a fatia varrida de um tick do ativo toca a cápsula do boneco (a lâmina de 1,4 m com 0,08 m de raio, da mão a 0,6 m do eixo e 1,3 m de altura, varrendo de −60° a +60° da direita para a esquerda, 20° por tick), o contato é carimbado no estado de quem bateu, com o tick, o nome do alvo e o golpe, e no tick seguinte o boneco perde 12 de vida.
- [ ] #5 Quando um alvo está entre a lâmina do fim de um tick e a do fim do seguinte, a fatia o acerta; um teste com tabela prova a conta exata: até 0,43 m do eixo da cápsula pega, e um pouco além não pega, no alcance, na borda do arco e na altura.
- [ ] #6 Quando a lâmina fica parada dentro do corpo do boneco por todo o ativo, ele perde 12 uma vez só (Q-26), e um teste do núcleo prova isso com tabela.
- [ ] #7 Quando o golpe entra no ativo, a direção do arco é a da câmera no último tick da preparação, e girar a câmera durante o ativo e a recuperação não move o arco nem para onde o corpo olha.
- [ ] #8 Quando dois leves tocam no mesmo tick, os dois lutadores perdem 12 no tick seguinte (a troca), e o resultado é o mesmo com os lutadores em qualquer ordem na árvore.
- [ ] #9 Quando passam 120 ticks do contato do último golpe que um lutador levou, a vida dele volta a 100; e um golpe que a levaria abaixo de 0 a deixa em 0.
- [ ] #10 Quando a SyncTest roda a cena do leve com o rollback de 7 ticks, nenhum campo do estado diverge, os sinais apresentados são tantos quanto os golpes mais os acertos, e o veneno no campo da ação a faz acusar.
- [ ] #11 Quando um replay de uma sessão com leves é tocado sem tela, ele refaz o rastro igual à coluna check, com os números do combate tirados do cabeçalho, e um arquivo gravado sem eles toca só com --force.
- [ ] #12 Quando o Arthur joga, o leve sai no botão esquerdo, a espada de blocos vai para trás e varre o arco em vermelhão, o boneco pisca e a barra de vida dele desce 12 por acerto e volta a 100; a tela de opções troca a tecla do leve; e o tamanho do replay por tick e lutador fica anotado (Q-39).
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
