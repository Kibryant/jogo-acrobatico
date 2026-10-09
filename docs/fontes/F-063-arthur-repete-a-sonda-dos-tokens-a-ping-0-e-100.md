---
id: F-063
titulo: O Arthur repete a sonda dos tokens a ping 0 e 100, com fone — acha muito difícil, não acerta o carregado nem a quebra, defende leves "de verdade", diz que não é o lag e que "deu bom" (sessão 9, 08/10/2026)
recebido_em: 2026-10-08
como: Dois jogos pelo terminal da sessão 9 (`play.sh 60 0` e `play.sh 60 100`), com fone, com uns 3 e 1,5 minutos de golpes, já com a mão vermelha da quebra na sonda (F-062 §4). Mensagem por voz depois do segundo jogo, como chegou, sem correção. Os números do §2 vêm dos logs `../netfox-sonda/sonda/runs/tokens/play-you-t60-p0-f0-074301.out` e `play-you-t60-p100-f0-074721.out`, lidos pelo `analyze_tokens.py` e por uma consulta lance a lance.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: o re-teste pedido na F-062 ("vamos testar mais"), feito na mesma noite, para separar o lag da leitura. Leitura do agente de trechos: "o golpe forte" é o carregado; "travadinha" foi lido como o engasgo em que o aviso aparece atrasado na tela (§2); "isso não impacta", sobre o boneco, é a opinião dele, e o agente discorda em parte (§3). Nada foi decidido.

## §1 — A mensagem

"Olha, é, O fone, o, o som chegou no fone. É, não, mas achei muito difícil. Eu achei muito difícil mesmo. Eu acho que eu também, minha reação foi muito ruim, o meu timing, mas o, o de quebra e o golpe forte, caralho, eu acho que não acertei nenhum. Foi muito difícil, tem que ter um timing muito bom. Mas aí eu acho que é questão de reação. É... Então, tipo assim... Ou talvez seja... É porque, tipo assim, ele não tem uma animação de boneco, sabe? É só a espada, não sei explicar. É porque, tipo assim, eu não tô acostumado com do jeito que foi mostrado, entendeu? Eu acho que é isso. É porque, tipo assim, só... Es... Não sei explicar também. Talvez se fosse algum boneco fazendo alguma animação, eu acho que daria pra... Tipo assim, mas aí é muito complexo, aí também não faz sentido. Isso aí acho que é só detalhe, isso não, acho que não impacta não. Mas achei muito difícil. Achei muito difícil. É... Dá pra fazer, eu tenho certeza que dá. Mas eu errava o time... E acho que é isso. E acho que não é o lag não. Mas é, acho que é isso. Tinha algumas vezes que dava uma travadinha assim, o golpe saía muito rápido nos dois, no zero e no cem. E eu, por incrível que pareça, eu consegui defender alguns golpes leves. Tipo, defender mesmo. Eu não fiquei apertando o F aleatoriamente não. Eu senti que ia sair e apertei. É... Deixa eu ver o que mais. Eu acho que é isso. É, acho que é isso. Mas acho que deu bom, deu bom. Deu bom. Eu acho. Diga aí sua análise."

## §2 — O que os logs dizem

Ping medido de 14 ms no primeiro jogo (atraso de visão de 1 a 3 ticks) e de 119 ms no segundo (7 a 10 ticks). As colunas são as da F-062 §2.

| Jogo | Golpe | Lances | Leitura certa | Parries | Bloqueios | Esquivas | Levou | Guarda quebrada | Mordeu a finta | Primeira defesa (ms) |
|---|---|---|---|---|---|---|---|---|---|---|
| ping 0 | Leve | 15 | 1 (7 %) | 1 | 0 | 0 | 14 | 0 | — | 214 |
| ping 0 | Carregado | 16 | 2 (12 %) | 0 | 2 | 0 | 14 | 0 | — | 332 |
| ping 0 | Quebra | 15 | 1 (7 %) | 0 | 0 | 1 | 8 | 6 | — | 273 |
| ping 0 | Finta | 15 | 10 (67 %) | 1 | 0 | 1 | 13 | 0 | 5 | 147 |
| ping 100 | Leve | 7 | 3 (43 %) | 2 | 1 | 0 | 4 | 0 | — | 287 |
| ping 100 | Carregado | 5 | 1 (20 %) | 0 | 0 | 1 | 4 | 0 | — | 295 |
| ping 100 | Quebra | 7 | 1 (14 %) | 0 | 0 | 1 | 2 | 4 | — | 296 |
| ping 100 | Finta | 5 | 3 (60 %) | 0 | 0 | 0 | 5 | 0 | 2 | 211 |

Lance a lance:

- **O carregado:** nenhum parry em 21. O F veio de 263 a 515 ms depois de o azul aparecer, e o contato de 516 a 900 ms, porque a carga é sorteada: o F caiu de 200 a 767 ms antes do contato. O mesmo padrão da F-062 a ping 100, agora a ping 14.
- **A quebra, já com a mão vermelha:** o F de 282 a 346 ms depois de a mão vir à frente, e a guarda quebrada, em 10 de 22. A esquiva a tempo, 2 de 22 (uma a cada ping). A mão vermelha não mudou a resposta na primeira exposição.
- **O leve:** 3 parries, com o F de 279 a 312 ms depois de o aviso aparecer e margem de 0 a 17 ms antes do contato. Um bloqueio. "Eu senti que ia sair e apertei" bate com o log: o F veio no fim da preparação fixa de 300 ms, não espalhado.
- **A finta:** mordeu 7 de 20.
- **A "travadinha":** a ping 0, um leve apareceu com atraso de visão de 19 ticks (317 ms) em vez de 1 a 3; nas corridas do bot, três quebras apareceram 14 a 25 ticks atrasadas (F-061 §3). Quando o aviso chega atrasado, o golpe parece sair do nada, no zero e no cem, como ele disse. São três processos do Godot no mesmo PC, um deles com a janela.
- **O som:** chegou no fone; nenhuma leitura além disso.
- **Os eventos:** 315 e 121 apresentados, nenhum repetido; 15.926 e 29.588 ticks refeitos.

## §3 — Leitura do agente

- **O lag está descartado.** A ping 14 o padrão foi o mesmo da F-062 a ping 119: a defesa já era julgada na tela dele, e o atraso de visão não tirava janela. O que ele chamou de difícil é a leitura e o tempo, não a rede.
- **O tempo contra uma preparação fixa existe.** Os 3 parries no leve, com o F a 279 a 312 ms do aviso, são o tempo sentido, não sorte. Com a preparação fixa, a regra "o parry é acerto de tempo guiado pela preparação" (F-053 §2.4) funciona para ele.
- **Contra o carregado não há tempo a acertar.** A carga sorteada entre 500 e 900 ms tira a informação; o bot que a lê no estado aparou 8 de 8 (F-061 §3). Reforça a Q-21: preparação fixa por arma, ou um aviso próprio da soltura.
- **A quebra é um problema de escolha, não de cor.** A mão vermelha ficou visível e ele seguiu apertando F a 300 ms, a mesma resposta de todos os golpes. Escolher entre parry, guarda e esquiva é reação de escolha, mais lenta que a simples (F-053 §2.3), e a preparação de 350 ms cabe a reação simples mais os 60 ms da esquiva, não a escolha. Vira a Q-25: a quebra precisa de preparação maior, ou de um aviso que decida a resposta antes da escolha.
- **A pose é o canal que a sonda menos tem.** Uma cápsula com espada de blocos dá só um esboço da pose; ele sentiu a falta do boneco. O agente discorda em parte do "não impacta": o canal da pose é um dos três (F-053 §2.2), e só o boneco com clipes, na fase 2, vai dizer quanto ele acrescenta. Nada se compra nem se faz à mão agora (TASK-7, escolha 4).
- **"Deu bom"** é o sistema: os tokens como dado, a chave do evento, o julgamento na tela dele, o filtro e o bus funcionaram nos quatro jogos. O que fica em aberto é a leitura de dois golpes, e é número de desenho, não de sonda (DEC-0017).

## §4 — O que fica

- Q-21 ganha a prova a ping 0: a carga sorteada é o problema, não o lag.
- Q-25 nasce: a quebra de guarda de 350 ms não é reagível por escolha.
- A sonda não muda de novo nesta sessão. O fechamento do Desenho 5 pode seguir: a DEC dos tokens registra a cor lida, a mão vermelha da quebra como hipótese e as duas pendências.
