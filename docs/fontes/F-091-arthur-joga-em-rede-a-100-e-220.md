---
id: F-091
titulo: O Arthur joga a cápsula em rede a ping 100 e 220 e não sente lag; a 220, sente uma diferença leve que não sabe explicar (sessão 13, 18/10/2026)
recebido_em: 2026-10-18
como: Duas mensagens do Arthur, por voz, depois de jogar pelo `tools/play_online.sh` (TASK-9, critério 13), que ele mesmo rodou no terminal da sessão. A primeira veio depois do jogo a ping 100, de uns 5 minutos, e a segunda depois do jogo a 220, de uns 2,5 minutos. Texto como chegou. Os fatos do §3 vêm dos logs dos dois jogos (`server.log`, `you.log` e `bot.log`, nas pastas temporárias que o script imprime).
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: a rodada C2 da parte 2 estava no commit `3e8fa13`. Em cada jogo, o script abre um servidor sem tela, um cliente com bot na metade direita da tela e a janela do Arthur na metade esquerda, com o simulador do netfox no ping pedido. Antes do primeiro jogo, o Claude explicou o que reparar: a própria cápsula no presente, a do bot suavizada e no passado, e o atraso que aparece na janela da direita, onde a cápsula do Arthur é a "outra". Entre os dois jogos, o Claude disse que, a ping 100, não sentir lag é o que o critério 13 pede, e repetiu a dica da janela da direita. Não se sabe se ele olhou a janela da direita. A "observação de antes", no §1, é provavelmente a da F-090 ("tá real time, eu acho"), feita nas janelas que o implementer abriu com o simulador ligado; pode ser também a da F-063 ("E acho que não é o lag não"). O agente não perguntou. Nada foi decidido.

## §1 — Depois de jogar a ping 100

"Eu joguei aqui, acho que é a mesma observação que eu tinha feito antes lá quando você me apresentou na primeira vez com ping. Hum, tipo assim, não vi diferença nenhuma de 100 de ping, assim, eu acho que foi bem tranquilo. É... Acho que não vai mudar muita coisa não pra 220 ali, porque não tem muita animação pra o que fazer, né? É... Ah, sei lá, então tipo assim, acho que... Eu vou jogar agora de 220 aqui, mas eu acho que... É, mesmo, as, mesmo a experiência do outro ali, achei muito massa jogar, de poder ver. É, mas acho que é isso. Não vi nenhuma coisa assim de lag, visual pelo menos. Mas é isso. Também não tem, não tem muita animação, né? Tipo assim, ele só andava pro lado e pro outro sem... Enfim, entendeu, né? Não tinha muita... Não tinha muito o que ver, entendeu? Acho que é isso."

## §2 — Depois de jogar a ping 220

"Ou, não senti ping nenhum não, mesma coisa, tá? A mesma coisa pra, pra esse aí, eu não senti diferença nenhuma não de lag, de de enfim, achei a mesma coisa ainda. É, é isso. Eu não senti lag não. Foi bem tranquilo. Tipo assim, pra não dizer que eu não senti lag, eu senti uma diferença assim, mas não consigo te explicar. Mas foi bem leve assim, nada demais."

## §3 — O que os logs dizem

| | Ping 100 | Ping 220 |
|---|---|---|
| O lutador do Arthur na partida, em ticks do servidor | de perto do 283 ao 19.027, uns 5 min 12 s | de perto do 330 ao 9.593, uns 2 min 34 s |
| Ticks entre o pedido de horário do servidor e o relógio acertado, nos dois clientes | 7 (117 ms) | 14 (233 ms) |
| Quem fechou primeiro | a janela do bot; a do Arthur, 26 ticks depois | a do Arthur; a do bot, 44 ticks depois |
| Códigos de saída: a janela dele, o servidor e o bot | 0, 0 e 0 | 0, 0 e 0 |

- Nos dois jogos, o servidor liberou a vaga de quem saiu, e o outro cliente registrou a saída.
- Nenhum log tem aviso. O único erro é o `Couldn't create an ENet host.` que o simulador deixa em cada cliente.
- Os jogos à mão não gravam ticks (`--record`), então os logs não dizem se alguma previsão foi corrigida enquanto ele jogava.

## §4 — Leitura do agente

- **O critério 13 pede que a própria cápsula responda na hora, a 100 e a 220.** As duas mensagens dizem isso com as palavras dele: "não vi diferença nenhuma de 100 de ping" e "não senti lag não".
- **A "diferença leve" a 220 não tem explicação nos logs.** Há três leituras possíveis, nenhuma provada: a cápsula do bot um quarto de segundo no passado, algum tranco se ele encostou no bot, ou só saber que era 220. Para medir da próxima vez, o `play_online.sh` pode gravar os ticks da janela dele, como o `net_run.sh` já faz.
- **"Não tinha muito o que ver" bate com o que o teste tem:** uma cápsula sem animação e um bot que só vai de um lado para o outro. O lag pesa quando um jogador depende do outro, como num golpe, e isso chega com o combate.
