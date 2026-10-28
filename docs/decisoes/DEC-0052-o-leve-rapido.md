---
id: DEC-0052
titulo: O leve rápido — 250 / 100 / 200 ms, defendido segurando a guarda antes, e o leve que não freia o corpo; o andar devagar fica para a guarda e o carregado
data: 2026-10-28
status: aceita
decidido_por: Arthur (F-180 §2; F-179 §2)
fontes: [F-053, F-062, F-173, F-175, F-178, F-179, F-180]
substitui: DEC-0051, só a frase do §5 de que, em pé, o alvo da velocidade durante um golpe é o andar devagar, 3 m/s
substituida_por:
---

# DEC-0052 — O leve rápido

## Contexto

O desenho do duelo deu ao leve 400 ms de preparação, 100 de ativo e 250 de recuperação, e o Arthur escolheu o corpo andando a 3 m/s durante o golpe (F-175 §2). Os 400 ms vieram do "não tinha nem como reagir" da sonda de leitura, que foi jogada com ping de 100 ms (F-062 §1), e do leve mais rápido do For Honor, 500 ms em 77 de 79 golpes (F-173 §1 C04). A regra dos tokens, porém, já supunha que ninguém reage ao leve: ele não tem cor porque "ninguém reage a 300 ms com os 100 ms do bloqueio, então ele se defende por leitura ou distância" (`visual-e-audio.md`; F-053 §2.4).

O Arthur jogou o leve de 400 ms: "Parece que é um golpe pesado. Porque ele demora, você não pode se mexer muito" (F-178 §2). O replay mostrou 136 cliques para 74 golpes, 42 deles perdidos na preparação, uns 250 ms depois do clique anterior (F-178 §1). Ele escolheu testar o leve rápido, sem decidir que ficava (F-179 §2), jogou de novo e aprovou: "Deu pra combar, sentir assim que realmente é um golpe leve. Ficou melhor. Eu gostei mais assim" (F-180 §2). Na segunda sessão, 28 de 73 golpes saíram emendados, contra 7 de 74, e 70 % dos ticks de golpe em pé passaram de 3,5 m/s, contra 4 % (F-180 §1).

## Opções consideradas

1. **O leve rápido, que se defende segurando a guarda antes (escolhida):** 250 / 100 / 200 ms, como o jab de um jogo de luta. O jogo de reação fica no carregado, com o azul e o parry, e na quebra, com o tech.
2. **O leve do For Honor:** 400 ms, reagível no limite, com o peso que a tribo aceita.
3. **O leve em corrente:** o primeiro em 400 ms e os seguintes mais rápidos, apertando de novo na recuperação, por um cancelamento desenhado (DEC-0016).

Para o corpo durante o leve: não frear (escolhida), um meio-termo de 5 m/s, ou os 3 m/s da F-175.

## Decisão

Aceita pelo Arthur depois de jogar o teste: "Eu gostei mais assim [...] Mas eu acho que tá bom" (F-180 §2). Os números são v0 do Claude, para seguir julgando jogando (DEC-0017).

1. **O leve:** 250 ms de preparação, 100 de ativo e 200 de recuperação: 15, 6 e 12 ticks a 60. Do clique ao acerto, de 270 a 300 ms, e um golpe a cada 550 ms. O dano e a stamina não mudam: 12 e 8 (`combate.md`).
2. **O papel do leve:** ele é rápido demais para reagir, e se defende segurando a guarda antes. Ele continua sem cor, como os tokens já diziam (DEC-0031), e não se apara.
3. **O leve não freia o corpo:** em pé, valem as regras do chão, a corrida de 7 m/s, a aceleração e a parada de sempre; a preparação soma até 1,75 m de alcance. Os comandos continuam esperando na vaga até o golpe acabar (DEC-0051 §5). O andar devagar de 3 m/s fica para a guarda (TASK-12.2) e para o carregado (TASK-12.3), por um número do golpe.
4. **A tabela do tranco** refaz as linhas do leve: quem acerta fica 6 ticks à frente, sem combo, porque o leve seguinte pegaria no tick 33 e a guarda do outro sobe no 30; quem bloqueia fica 3 ticks à frente; e um golpe bloqueado só vira castigo com mais de 9 ticks de desvantagem, os 15 da preparação do leve menos os 6 da guarda (`combate.md`, "O tranco e a vantagem").

## Consequências

- O `combat_v0.tres` passa a 250 / 100 / 200 ms, e o movimento deixa o corpo correr durante o leve.
- Os testes travados da TASK-12.1 que fixavam 400 / 100 / 250 ms e o andar de 3 m/s no golpe são atualizados pelo test-writer, a partir do papel, e a trava é refeita, com a liberação do Arthur (F-179 §1).
- A escolha da F-175 §2, o golpe andando a 3 m/s, passa a valer para o carregado, e não para o leve.
- O carregado continua tendo armadura contra leves: começado no meio de uma sequência de leves, ele aguenta e acerta os 30 (`combate.md`, "A armadura do carregado").
- A vitrine "O desenho do duelo" mostra os números novos.

## Revisitar se

- No duelo contra o bot, o leve vencer as trocas sozinho, e a guarda virar a única defesa.
- Segurar a guarda o tempo todo deixar o duelo parado.
- Os amigos não lerem o leve no teste da fase.
