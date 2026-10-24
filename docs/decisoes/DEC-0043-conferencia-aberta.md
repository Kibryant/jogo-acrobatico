---
id: DEC-0043
titulo: A conferência aberta — uma pergunta só, sem opções, antes da decisão que depende da explicação; a DEC-0021 muda só nisso
data: 2026-10-24
status: aceita
decidido_por: Arthur (F-140 §5)
fontes: [F-020, F-038, F-084, F-085, F-087, F-088, F-140]
substitui: DEC-0021, só a forma da pergunta fixa (§1)
substituida_por:
---

# DEC-0043 — A conferência aberta: uma pergunta só, sem opções, antes da decisão que depende da explicação; a DEC-0021 muda só nisso

## Contexto

A DEC-0021 criou a pergunta fixa a pedido do Arthur: "a primeira coisa é ser se eu entendi o problema e o que, que a gente está fazendo. Eu acho que devia ser essa a primeira pergunta fixa" (F-020 §2). Ela existe para ele nunca decidir no escuro (DEC-0010). Ela confere a explicação do Claude, não o Arthur.

Com o tempo, a pergunta virou um teste de múltipla escolha sobre um detalhe técnico, com uma resposta esperada e sem recomendação:

- na sessão 6, duas conferências do replay por inputs erraram (F-038 §2 e §3);
- na sessão 13, cinco erraram seguidas, com explicações que juntavam causa, sintoma e conserto (F-084; F-085; F-087). Uma recapitulação de uma ideia só acertou (F-088);
- na sessão 16, na abertura da TASK-10.6, três erraram, todas pela primeira opção da lista, e nenhuma tinha recomendação (F-140 §1 a §3). Pedida com as palavras dele, a resposta veio certa de primeira (F-140 §4).

Na mesma mensagem, o Arthur disse que já não sabia por que a pergunta existe e que às vezes ela é complexa demais: "eu não tô entendendo qual é o real motivo por ela. É, e às vezes ela é muito complexa" (F-140 §4). É o caso do "Revisitar se" da DEC-0021: "A pergunta de conferência virar burocracia".

## Opções consideradas

1. **Aberta, com as palavras dele:** uma pergunta só, sem opções, antes de uma decisão que dependa da explicação, respondida por voz ou por texto. Não tem chute, e a resposta mostra o que ele imaginou. Custa um pouco mais de esforço dele. A escolhida.
2. **Manter a múltipla escolha em toda rodada:** é mais rápida, mas, sem recomendação, virou chute pela primeira opção (F-140 §6).
3. **Tirar a conferência:** o Claude explica, e o Arthur pergunta quando não entender. É a mais leve, mas perde a trava contra decidir no escuro.

## Decisão

Aceita pelo Arthur em 24/10/2026: "Aberta, com as minhas palavras (Recomendado)" (F-140 §5).

1. **A pergunta de conferência é aberta.** Uma pergunta só, sem opções, sobre a ideia que a explicação acabou de dar. O Arthur responde com as palavras dele, por voz ou por texto.
2. **Ela vem antes de uma decisão que depende da explicação.** Uma rodada sem decisão que dependa de uma ideia nova, como uma escolha que ele faz pela sensação ou um número v0 que ele julga jogando (DEC-0017), não precisa dela.
3. **Se a resposta não bater,** o Claude explica de outro jeito, nomeando a ideia que atrapalhou, antes da decisão, como já era (F-038).
4. **As perguntas de decisão continuam iguais:** com opções, cada uma com a recomendação do Claude, no máximo três por vez, contando a de conferência.

O resto da DEC-0021 continua valendo: o exemplo do mundo do Arthur antes do termo técnico, a escolha como trade-off e o básico de programação sem explicação.

## Consequências

- **A DEC-0021** ganha o aviso de substituição parcial no topo e continua valendo no resto.
- **O `AGENTS.md`** ("How we work") troca a frase da primeira pergunta de toda rodada pela conferência aberta.
- **A memória do Claude** ("uma ideia antes da conferência") ganha o que a sessão 16 mostrou: sem recomendação, a múltipla escolha vira chute pela primeira opção.

## Revisitar se

- A pergunta aberta pesar demais para o Arthur, como tarefa a mais em toda rodada.
- As respostas abertas mostrarem que ele entendeu, rodada após rodada, e a conferência puder ficar só para os conceitos novos de arquitetura.
