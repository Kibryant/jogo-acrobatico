---
id: F-168
titulo: O Arthur decide que a volta na mesma parede só vale depois de um pulo da parede, e libera o conserto da cena de um teste travado (sessão 19, 27/10/2026)
recebido_em: 2026-10-27
como: Resposta do Arthur à pergunta de conferência do Claude no terminal da sessão 19, na TASK-10.13, e as opções que ele escolheu nas duas perguntas seguintes. Transcrito como chegou.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: o implementer da TASK-10.13 parou com NEEDS_CONTEXT. Com a regra literal da DEC-0047 §1 (a mesma parede aceita uma corrida nova), uma corrida que acaba pelo tempo, pela trava ou pelo disparo do gancho deixa o corpo encostado na parede, e uma corrida nova começaria no tick seguinte, com a vertical zerada: segurar o direcional contra a parede faria a corrida sem fim, e o limite de 2,5 s cairia (`movimento.md`, "Duração máxima"). 34 casos dos testes antigos caíam por isso. E um caso travado, `test_back_on_the_same_wall_after_the_wall_jump_a_new_run_starts` (`movement_wall_same_test.gd`), exigia o corpo caindo ao encostar, mas a 60 ticks a cena faz a volta em 13 ticks, com o corpo ainda subindo; a regra de entrada de toda corrida aceita o corpo subindo. O Claude perguntou, em aberto: "por que, sem essa trava do pulo da parede, segurar o direcional contra a parede deixaria a corrida sem fim?".

## §1 — A resposta à conferência

"porque a corrida recomeçaria toda vez que acaba encostada"

## §2 — As escolhas

- "Quando a volta na mesma parede vale?": "Só depois de um pulo da parede (Recomendado)". A opção dizia: "O fake de ir e voltar funciona. Uma corrida que acaba pelo tempo, pela trava ou pelo gancho continua recusando a mesma parede até o chão ou outra parede, e o limite de 2,5 s segue inteiro. Sem campo novo no estado." A outra era "Depois de perder o contato".
- "Posso liberar o conserto do teste travado (o caminho de volta mais longo, para o corpo encostar caindo a 30 e a 60 ticks) e refazer a trava?": "Libera (Recomendado)". A opção dizia: "O test-writer só alonga a volta na cena desse caso, sem mudar o que ele exige, e eu refaço o sha256. O erro é da cena, não da regra." A outra era "Não libera".
