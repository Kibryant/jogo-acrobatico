---
id: TASK-12.3
title: >-
  O carregado, o parry e a finta: a armadura, a janela de 200 ms e o castigo
  garantido
status: To Refine
assignee: []
created_date: '2026-10-27 22:02'
updated_date: '2026-10-28 14:53'
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
Nenhuma: os números estão no `combate.md` ("Os golpes e as defesas", "A armadura do carregado", "O parry", "A finta").

### Escolhas a confirmar
- As teclas: o carregado no botão esquerdo segurado ou numa tecla própria? Padrão sugerido: segurar o botão esquerdo por mais de 150 ms vira carregado, soltar antes é leve; o parry numa tecla própria (F, como na sonda); a finta na tecla do bloqueio durante a preparação. O Arthur confirma ao abrir.

### Fora do escopo
- A quebra de guarda (TASK-12.4). O som (TASK-12.6).

### O que você vai aprender
- Armadura: levar o dano e não parar, e por que sem ela o triângulo se inverte.
- A janela do parry como tempo contado, não reflexo; e o castigo garantido como conta de ticks: 12 de recuperação mais 42 de preparação, antes dos 54 do tranco.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando o jogador começa o carregado com 25 ou mais de stamina, a preparação dura 42 ticks fixos, o ativo 7 e a recuperação 27; os 25 são pagos no primeiro tick ativo, e com menos de 25 o carregado não começa.
- [ ] #2 Quando um leve toca quem está na preparação do carregado, ele perde 12 e a preparação segue sem tranco (a armadura); na recuperação, o leve interrompe como sempre.
- [ ] #3 Quando um carregado pega sem guarda, o alvo perde 30 e fica 42 ticks no tranco; bloqueado, custa 15 de stamina e 25 ticks de blockstun, e quem bateu fica 9 ticks atrás.
- [ ] #4 Quando o jogador aperta o parry e um carregado toca a cápsula nos 12 ticks seguintes, quem bateu perde a vez: 54 ticks de tranco e 9 de hitstop sozinho; quem aparou recupera em 12 e um carregado começado ali pega no tick 54, antes de a guarda do outro poder subir.
- [ ] #5 Quando o jogador aperta o parry e nenhum carregado toca a cápsula na janela, ele fica 27 ticks sem agir; quando um leve toca a cápsula durante a postura do parry, o leve pega como sem defesa.
- [ ] #6 Quando o jogador finta o carregado até o tick 27 da preparação, a preparação para, os 25 não são pagos, a finta custa 15 e recupera em 12 ticks, e a pose volta com o estalo (DEC-0016).
- [ ] #7 Quando a cena do carregado roda na SyncTest com o rollback de 7 ticks, nenhum campo diverge, e o veneno no carimbo do parry a faz acusar.
- [ ] #8 Quando o Arthur joga contra o boneco que mistura leves e carregados, ele apara contando o azul e sente a finta; a taxa de parry dele fica anotada, como na F-063.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Do refino a fazer, pela F-188 §2 (o Arthur depois de jogar a guarda): ele imagina o parry refletindo a espada, com a animação mostrando o reflexo; quem apara ganha e combina, "talvez dois golpes e um golpe forte", contra o carregado garantido do desenho (combate.md, "O tranco e a vantagem"); e "não existe parry infinito", o que o parry no vazio de 450 ms já cobra. Conferir com ele, com pesquisa, se o leve continua sem parry ("quando os dois apertaram ao mesmo tempo, a pessoa que apertou [...] refletir ali e ganhar").
<!-- SECTION:NOTES:END -->
