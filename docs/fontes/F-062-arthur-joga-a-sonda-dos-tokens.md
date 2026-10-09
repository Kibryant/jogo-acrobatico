---
id: F-062
titulo: O Arthur joga a sonda dos tokens — acha complicado e pouco claro, foi "no susto", desconfia do ping, não formou opinião sobre o som e pede para testar mais (sessão 9, 08/10/2026)
recebido_em: 2026-10-08
como: O Arthur rodou dois jogos pelo terminal da sessão 9 (`play.sh 60 100`, visão comum, e `play.sh 60 100 2`, deuteranopia), em tela cheia, com uns 3,5 e 2,5 minutos de golpes, e mandou esta mensagem por voz depois do segundo. Texto como chegou, sem correção. Os números do §2 vêm dos logs dos dois jogos (`../netfox-sonda/sonda/runs/tokens/play-you-t60-p100-f0-071847.out` e `play-you-t60-p100-f2-072733.out`), lidos pelo `analyze_tokens.py` e por uma consulta lance a lance.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: rodada 2 da TASK-7, critério 5. Antes de jogar, ele acertou a pergunta fixa de entendimento ("o leve é o padrão; a cor marca a exceção"). O Claude pediu o que ele leu e o que não leu (F-041; F-055). Leitura do agente de trechos: "não tenho muito pra falar do som" quer dizer que o som não foi testado, porque ele jogou sem fone; "o caminho é esse, pra eu refletir mais" foi lido como continuar testando a sonda antes de decidir qualquer coisa. Nada foi decidido.

## §1 — A mensagem

"Eu achei meio complicado agora, eu não sei se porque o ping estava alto de 100, mas estava meio lento, tipo, às vezes ele dava o golpe e, nossa, não tinha nem o que fazer, não tinha nem como reagir. É... Mas... Eu acho que não ficou muito fluido, não ficou muito fácil de entender o que tá acontecendo, não. Não entendi muito bem, não. Eu fui meio no susto, assim, tipo, eu acho que não foi falta de explicação, não, eu entendi. Mas eu acho que foi algo mais visual. É, o áudio eu escutei, mas eu não escutei tanto assim, não. Eu acho que eu não, eu não joguei com o fone aqui, joguei só um pouquinho. É, é, não tenho muito pra falar do som, não. Não tenho muita opinião ainda não, mas do visual eu não achei meio estranho, sei lá. Mas acho que foi por causa do ping, não sei. É, não ficou muito... Não ficou muito... Sabe como te explicar? Não ficou muito... Não sei, não ficou muito claro, eu acho. Não consegui fazer... Tipo, eu sabia o que ia defender, sabia que... Ah, não sei explicar agora também. Acho que vamos testar mais um pouco, testar mais um pouco. Acho que o caminho é esse, pra eu refletir mais."

## §2 — O que os logs dizem

Os dois jogos, a 60 ticks e ping medido de 113 a 118 ms, com o atraso de visão (`view_lag`) de 7 a 9 ticks. "Leitura certa" é a resposta que o golpe admite: qualquer defesa contra o leve e o carregado, a esquiva contra a quebra, não morder a finta. "Primeira defesa" é o tempo entre o aviso aparecer na tela dele e a primeira tecla de defesa, mediana.

| Jogo | Golpe | Lances | Leitura certa | Parries | Bloqueios | Esquivas | Levou | Guarda quebrada | Mordeu a finta | Primeira defesa (ms) |
|---|---|---|---|---|---|---|---|---|---|---|
| 1, visão comum | Leve | 18 | 5 (28 %) | 3 | 2 | 0 | 13 | 0 | — | 294 |
| 1 | Carregado | 19 | 4 (21 %) | 0 | 2 | 2 | 15 | 0 | — | 346 |
| 1 | Quebra | 16 | 1 (6 %) | 0 | 0 | 1 | 12 | 3 | — | 313 |
| 1 | Finta | 17 | 12 (71 %) | 0 | 3 | 1 | 13 | 0 | 5 | 179 |
| 2, deuteranopia | Leve | 13 | 2 (15 %) | 0 | 2 | 0 | 11 | 0 | — | 196 |
| 2 | Carregado | 10 | 5 (50 %) | 1 | 2 | 2 | 5 | 0 | — | 337 |
| 2 | Quebra | 11 | 0 (0 %) | 0 | 0 | 0 | 4 | 7 | — | 312 |
| 2 | Finta | 10 | 7 (70 %) | 0 | 1 | 0 | 9 | 0 | 3 | 194 |

Lance a lance:

- **O carregado.** Em 14 dos 29, ele apertou F de 330 a 545 ms depois de o azul aparecer, e o contato veio de 516 a 900 ms depois, porque a carga é sorteada. O F caiu de 83 a 550 ms antes do contato, fora da janela de 80 ms, e a recuperação de 400 ms do parry errado o prendeu quando a lâmina desceu. Um parry acertou, com 17 ms de margem. Os bloqueios e as esquivas que deram certo vieram de 144 a 615 ms depois do azul.
- **A quebra.** Em 10 dos 27, ele apertou F de 262 a 630 ms depois de a mão vir à frente, e a guarda quebrou (ou o golpe pegou, quando o F veio depois do contato). A esquiva a tempo aconteceu uma vez em 27; as outras esquivas vieram de 1 a 4 s depois.
- **O leve.** Três parries no primeiro jogo, com o F de 0 a 33 ms antes do contato na tela dele, e os bloqueios quando a guarda já estava alta. Nos outros, o golpe pegou: a primeira tecla veio 294 ms depois do aviso, e a preparação dura 300.
- **A finta.** Mordeu 8 de 27: o F veio de 12 a 380 ms depois de o azul aparecer, antes do corte. Nas outras, o leve que segue pegou em 22 de 27.
- **Os filtros, a escala e o idioma.** No primeiro jogo ele passou pelas quatro simulações, subiu a escala da interface a 1,2 e voltou, e trocou o idioma duas vezes. O segundo jogo inteiro foi em deuteranopia. O padrão das respostas não mudou entre os dois.
- **A janela do cliente:** 1920 × 1080 em tela cheia; o cliente refez 86.610 e 57.336 ticks; 391 e 252 eventos apresentados, nenhum repetido; o ambiente abaixou de 34 a 39 dB sob os cues.

## §3 — O que se leu e o que não se leu, na leitura do agente

- **A cor do carregado se leu; o tempo do parry, não.** Ele viu o azul e respondeu com F em meio segundo, 29 vezes em 29 sabia "o que ia defender", como disse. Mas com a carga sorteada entre 500 e 900 ms ninguém sabe quando a lâmina desce: o bot que lê a carga no estado aparou 8 de 8 (F-061 §3); ele, 1 de 29. A diferença é informação, não reflexo. Com a preparação fixa do leve, ele acertou 3 parries com margem de 0 a 33 ms.
- **A forma da quebra não se leu.** A mão à frente, o contorno pulsando e o pisão não disseram "esquive": a resposta foi F, como para o carregado. Um token só de forma, sem cor, falhou no primeiro contato.
- **O leve é o "não tinha nem como reagir".** É o que a F-053 §2.4 previa para 300 ms de preparação, e a sensação dele confirma: o leve se defende por leitura ou distância, e isso ainda não é jogável nem agradável numa sonda sem movimento.
- **O som não foi testado:** sem fone, ele quase não ouviu. O canal fica para o próximo teste.
- **O ping não tirou janela:** a defesa foi julgada na tela dele (F-061 §1), e o atraso de visão ficou em 117 a 150 ms. A sensação de "lento" existe mesmo assim; o próximo teste roda também a ping 0, para separar o lag da leitura.
- **"Algo mais visual"** com cápsulas e uma espada de blocos: a sonda prova o sistema dos tokens, não a arte; a leitura com o boneco e os clipes chega na fase 2.

## §4 — O que muda antes da DEC (critério 5)

- A quebra de guarda ganha cor: a mão em vermelhão `#D55E00` desde o tick 0, com o pulso do contorno e o pisão mantidos. É a convenção da tribo: o rastro vermelho do inbloqueável no For Honor e o kanji vermelho do Sekiro dizem "não bloqueie, saia" (F-053 §1). Trocado na sonda nesta sessão; a provar no próximo teste.
- O carregado de carga variável vai para a Q-21: o parry por leitura pede uma preparação fixa por arma, ou um aviso próprio da soltura com pelo menos o tempo de reação.
- O próximo teste, antes do fechamento: ping 0 e ping 100, com fone, e ele diz de novo o que leu.
