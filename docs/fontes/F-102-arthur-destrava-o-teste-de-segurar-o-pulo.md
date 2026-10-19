---
id: F-102
titulo: O Arthur acerta que segurar a tecla é um pulo só e destrava o teste de "segurar o pulo" para o test-writer reescrever (sessão 14, 19/10/2026)
recebido_em: 2026-10-19
como: Respostas escolhidas nas opções de perguntas do Claude Code na sessão 14, na rodada A da TASK-10.1. Texto das perguntas, dos rótulos e das descrições como foram mostrados.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: na rodada A da TASK-10.1, o implementer voltou BLOCKED. O teste travado `test_a_press_of_one_tick_gives_the_full_jump_and_holding_adds_nothing` (`test/core/fighter/movement_jump_test.gd`, escrito na TASK-9 e travado de novo na TASK-10.1) fingia "segurar" o pulo apertando em dez ticks seguidos. Com a regra nova, o aperto no ar com o pulo duplo disponível sai na hora (F-100 §1), então o segundo tick do "segurar" dava o pulo duplo, e outro teste travado exige exatamente isso. No jogo, segurar a tecla é um aperto só: o `FighterInput` entrega o pulo uma vez. Destravar um teste é decisão do Arthur (AGENTS.md; `.claude/harness/README.md`). O Claude explicou uma ideia, com o exemplo de segurar o Q no LoL, e fez a conferência antes da decisão.

## §1 — A conferência

Pergunta: "Conferência (uma só é verdadeira): no jogo, com a regra nova, você aperta a barra de espaço no chão e segura. O que acontece?"

Resposta: "Um pulo só"

A opção dizia: "Sai o pulo de 1,2 m; o pulo duplo só sai com um segundo aperto no ar."

As outras opções eram "Pulo e pulo duplo", "Um pulo mais alto" e "Nada até soltar".

## §2 — A decisão

Pergunta: "Destravo o teste para o test-writer reescrever só ele e travar de novo?"

Resposta: "Destrava e reescreve (Recomendado)"

A opção dizia: "O teste continua provando que um aperto de um tick dá o pulo inteiro de 1,2 m. A parte de \"segurar\" sai do núcleo, porque quem garante que segurar é um aperto só é o `FighterInput`, e o teste dele já cobre isso. Os outros testes travados não mudam."

As outras opções eram "Destrava e troca a parte de segurar" ("O teste passa a provar que apertar em dez ticks seguidos dá um pulo e um pulo duplo, e nada mais. Repete o que outros dois testes já provam.") e "Quero ver o teste antes".
