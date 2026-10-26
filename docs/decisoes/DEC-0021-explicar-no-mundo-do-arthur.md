---
id: DEC-0021
titulo: Explicar no mundo do Arthur — pergunta fixa de entendimento, exemplo do que ele conhece e escolha como trade-off
data: 2026-10-02
status: aceita
decidido_por: Arthur
fontes: [F-016, F-020]
substitui:
substituida_por: DEC-0043, só a forma da pergunta fixa (§1)
---

> ⚠️ Em parte substituída por DEC-0043 em 2026-10-24: a pergunta fixa no começo de toda rodada, de múltipla escolha, não é a regra atual. A conferência é uma pergunta aberta, respondida com as palavras do Arthur, antes de uma decisão que depende da explicação. O resto desta DEC continua valendo.

# DEC-0021 — Explicar no mundo do Arthur: pergunta fixa de entendimento, exemplo do que ele conhece e escolha como trade-off

## Contexto

O Claude constrói e ensina, e o Arthur nunca pode virar espectador (DEC-0010). Na rodada 1 do Desenho 2 (TASK-4), o Claude explicou tick, carimbo de tempo e rollback com o vocabulário técnico do netfox. O Arthur entendeu as caixas do estado e o rollback, mas não o tick: "Eu não entendi merda nenhuma. [...] um tick seria... Segundos?" (F-020 §2).

O que ele pediu (F-020 §2):

- "vai ter que ser mais leigo pra mim. E aí você me perguntando se eu tô entendendo";
- "a primeira coisa é ser se eu entendi o problema e o que, que a gente está fazendo. Eu acho que devia ser essa a primeira pergunta fixa";
- "eu sei muito TypeScript, Python [...] LoL, Call of Duty [...] Tenta trazer exemplos mais palpáveis pra mim";
- "coisas de programação eu já sei, [...] não precisa ficar muito preso a isso";
- "Se eu falar que, olha, [...] você está explicando coisas muito básicas. Aí você se atenta a isso".

E logo depois: "trade-offs são muito importantes para mim. Eu entender o que eu ganho e o que eu perco" (F-020 §4).

Com a explicação refeita (o servidor de 128 ticks do Valorant, o `setInterval` do TypeScript, o frame contra o tick no LoL e o Flash anotado no chat como carimbo), ele acertou as três perguntas de conferência (F-020 §3). Com as decisões mostradas como trade-off, confirmou a rodada 1 (F-020 §5).

É a segunda vez que uma explicação acima do nível dele precisa ser refeita. A primeira foi com número e cálculo, e virou a DEC-0019 (F-016 §1).

## Opções consideradas

1. **Seguir como antes:** conceito técnico, com analogia web "quando ajuda" (DEC-0010).
2. **Explicar no mundo do Arthur, com trade-off e conferência de entendimento:** a escolhida.

## Decisão

1. **A pergunta fixa.** Antes de pedir qualquer decisão, a primeira pergunta da rodada confere se o Arthur entendeu o problema e o que está sendo feito. Se ele não entendeu, o Claude explica de outro jeito antes de seguir.
2. **Conceito novo vem com exemplo do mundo dele:** TypeScript, Python, LoL, Call of Duty e os jogos que ele conhece. O termo técnico vem depois do exemplo, ou definido na mesma frase.
3. **Escolha vem como trade-off:** para cada opção, o que se ganha e o que se perde, de preferência numa tabela.
4. **O básico de programação não se explica.** Se o Arthur disser que ficou básico demais, o Claude sobe o nível.

## Consequências

- O `AGENTS.md` ganha a regra em "How we work".
- A pergunta de conferência ocupa uma das três perguntas da vez.
- Os artefatos visuais (DEC-0019) seguem a mesma regra. O "O tick por dentro" é republicado no mesmo link com a explicação refeita.

## Revisitar se

- A pergunta de conferência virar burocracia, ou a explicação ficar básica demais para o Arthur.
