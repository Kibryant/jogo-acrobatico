---
id: TASK-12.3
title: >-
  O carregado, o parry e a finta: a armadura, a janela de 200 ms e o castigo
  garantido
status: Done
assignee: []
created_date: '2026-10-27 22:02'
updated_date: '2026-10-30 14:46'
labels:
  - jogo
milestone: m-2
dependencies:
  - TASK-12.2
parent_task_id: TASK-12
ordinal: 30000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
As duas pernas do triângulo que faltam: o carregado vence o leve pela armadura, e o parry vence o carregado pela janela de 200 ms nos últimos 200 ms da preparação fixa de 700 (`combate.md`, "O triângulo e como ele se sustenta"). A finta corta o carregado até 450 ms e pune quem apara cedo. É a filha que responde a Q-21 jogando: a carga sorteada deu 0 em 21 (F-063); a fixa dá à pessoa um tempo para contar.

### Perguntas em aberto
Nenhuma: os números estão no `combate.md` ("Os golpes e as defesas", "A armadura do carregado", "O parry", "A finta"). As regras do tick saem no plano, como o "O leve no tick" saiu na TASK-12.1.

### Escolhas a confirmar
Nenhuma. O Arthur fechou no refino (F-190; F-191 §2): o leve continua sem parry; o parry garante um golpe só, o carregado ou o leve, como no desenho, até ele jogar (Q-55); o carregado no E, num aperto só; o parry no F, como na sonda; a finta no aperto do botão direito durante a preparação do carregado. As teclas são por posição física e remapeáveis (`combate.md`, "As teclas").

### Fora do escopo
- A quebra de guarda (TASK-12.4). O som, com o "clang" e o estalo da finta (TASK-12.6). A animação do reflexo (TASK-12.10): na cápsula, a espada de quem foi aparado volta para cima.
- O combo depois do parry (Q-55) e o parry no leve (F-191 §2).
- A janela que encolhe a cada aperto, como no Sekiro: fica como ajuste se o duelo pedir (`combate.md`, "O parry").

### O que você vai aprender
- Armadura: levar o dano e não parar, e por que sem ela o triângulo se inverte.
- A janela do parry como tempo contado, não reflexo; e o castigo garantido como conta de ticks: 12 de recuperação mais 42 de preparação, antes dos 54 do tranco.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Quando o jogador começa o carregado com 25 ou mais de stamina, a preparação dura 42 ticks fixos, o ativo 7 e a recuperação 27; os 25 são pagos no primeiro tick ativo, e com menos de 25 o carregado não começa.
- [x] #2 Quando um leve toca quem está na preparação do carregado, ele perde 12 e a preparação segue sem tranco (a armadura); na recuperação, o leve interrompe como sempre.
- [x] #3 Quando um carregado pega sem guarda, o alvo perde 30 e fica 42 ticks no tranco; bloqueado, custa 15 de stamina e 25 ticks de blockstun, e quem bateu fica 9 ticks atrás.
- [x] #4 Quando o jogador aperta o parry e um carregado toca a cápsula nos 12 ticks seguintes, quem bateu perde a vez: 54 ticks de tranco e 9 de hitstop sozinho; quem aparou volta a agir 12 ticks depois do contato, e um carregado começado ali pega no tick 54, antes de a guarda do outro poder subir.
- [x] #5 Quando o jogador aperta o parry e nenhum carregado toca a cápsula na janela, ele fica mais 27 ticks sem agir depois de a janela fechar; quando um leve toca a cápsula durante a postura do parry, o leve pega como sem defesa.
- [x] #6 Quando o jogador finta o carregado até o tick 27 da preparação, a preparação para, os 25 não são pagos, a finta custa 15 e recupera em 12 ticks, e a pose volta com o estalo (DEC-0016).
- [x] #7 Quando a cena do carregado roda na SyncTest com o rollback de 7 ticks, nenhum campo diverge, e o veneno no carimbo do parry a faz acusar.
- [x] #8 Quando o Arthur joga contra o boneco que mistura leves, carregados e fintas, ele apara contando o azul e sente a finta; a taxa de parry dele fica anotada, como na F-063.
- [x] #9 Quando o jogador aperta o E, o F ou, na preparação do carregado, o botão direito, sai o carregado, o parry ou a finta; só o aperto finta, e quem já segurava a guarda quando o carregado começou não finta; o carregado e o parry ganham linhas na tela de opções e se trocam como as outras teclas, e a finta segue a tecla da guarda (F-191 §2).
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Critérios de aceite verificados
- [x] #2 Teste automatizado para toda regra do núcleo (core/)
- [x] #3 Diário da sessão escrito e glossário atualizado
- [x] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Refino feito em 30/10/2026 (F-190; F-191), sobre a nota da F-188 §2. A pesquisa (For Honor, Naraka, Chivalry 2) e as contas estão na vitrine "O parry e o castigo" (https://claude.ai/artifact/7WuJXvK2U6LQcZonJUgDHB). O leve continua sem parry; o castigo fica o do desenho até o Arthur jogar (Q-55); as teclas são o E, o F e o botão direito. O "não existe parry infinito" da F-188 já está coberto: o leve não se apara, o parry no vazio cobra 450 ms e cada aperto custa 15. A sugestão antiga, o carregado no clique segurado, contrariava a F-175 §1.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Fechada em 30/10/2026, na sessão 21.

O carregado, a armadura, o parry e a finta foram para o tick (DEC-0056). Há 73 testes de aceite travados, a SyncTest com o veneno nos carimbos do parry, e o portão verde com 2.034 casos.

Dois testes travados pediam o impossível e foram corrigidos com a liberação do Arthur (F-195). O reviewer achou e fechou um furo do 4v4: o leve virava aparado.

Critério 8: o Arthur jogou 3 minutos (F-196 §1).
- Aparou 3 carregados em 17, contando o azul, sempre com o F de 533 a 650 ms depois de o azul aparecer. Na sonda tinham sido 0 em 21 (F-063).
- Mordeu 4 fintas de 11.

Os carregados dele erraram sempre à direita do corte, pela paralaxe da mira da DEC-0045. A correção virou a TASK-12.14, que vem antes da TASK-12.4 (F-197).

Ficaram em aberto a tecla do carregado no mouse (Q-56) e o castigo do parry (Q-55).
<!-- SECTION:FINAL_SUMMARY:END -->
