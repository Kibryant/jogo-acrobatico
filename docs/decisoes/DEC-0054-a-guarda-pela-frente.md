---
id: DEC-0054
titulo: A guarda pela frente — o botão direito do mouse, segurado, levanta uma guarda que cobre a metade da frente, 90° para cada lado de onde o corpo olha; pelas costas, o golpe pega
data: 2026-10-28
status: aceita
decidido_por: Arthur (F-182 §2)
fontes: [F-001, F-012, F-173, F-182]
substitui:
substituida_por:
---

# DEC-0054 — A guarda pela frente

## Contexto

O desenho do duelo deu à guarda o tempo de subir, 100 ms, o andar de 3 m/s e o custo em stamina (`combate.md`, "O bloqueio, a guarda andando e a stamina"), mas não a tecla nem a direção. A TASK-12.2, que põe a guarda no jogo, não podia ficar Ready sem as duas (F-182, contexto).

A pesquisa do Claude, mostrada antes da escolha (F-182, contexto):

- **Chivalry 2:** segurar o bloqueio só defende de frente, e andar em diagonal em volta do outro passa pela guarda.
- **Mordhau:** é preciso estar virado para o golpe para apará-lo; o golpe de um ângulo morto é uma causa comum de morte.
- **For Honor:** o golpe vindo direto das costas não se bloqueia, e o jeito é esquivar; os dos lados se bloqueiam.
- **Naraka:** nada achado sobre os golpes pelas costas.

O pilar 3 pede que a acrobacia vire jogada (`visao.md`): com uma guarda pela frente, pular por cima do outro ou voltar da parede pelas costas dele passa a valer no duelo.

## Opções consideradas

1. **A metade da frente, 90° para cada lado (escolhida).**
2. **Uma frente mais estreita, 60° para cada lado,** que premia andar em volta, como no Chivalry 2.
3. **Uma guarda que defende de todos os lados.**

Para a tecla: o botão direito do mouse, segurado (escolhida), ou uma tecla do teclado.

## Decisão

Aceita pelo Arthur: "Concordo com suas recomendações, faz sentido" (F-182 §2).

1. **A tecla:** o botão direito do mouse, segurado, por posição física e remapeável (DEC-0031 §8). O botão direito vale só para a guarda nas opções.
2. **A direção:** a guarda alta bloqueia um golpe de quem está a até 90° de onde o corpo de quem defende olha, medido no plano do chão, do eixo de quem defende ao eixo de quem ataca. Além disso, pelas costas, o golpe pega como se não houvesse guarda.
3. **Onde o corpo olha com a guarda alta:** para onde a câmera olha, como sempre fora do golpe (`movimento.md`, "Princípios"). Virar a câmera vira a guarda.

## Consequências

- A acrobacia que leva às costas do outro, o pulo por cima, o pulo da parede e a soltura do gancho, ganha um uso no duelo (pilar 3).
- O bot da TASK-12.8 precisa virar a guarda para o oponente, e o boneco que ataca da TASK-12.2 também.
- Num 4v4, quem é atacado por dois lados ao mesmo tempo só segura um deles: é o "2 em 1" que o anel visível do estudo protege (F-001; `combate.md`, "Times").

## Revisitar se

- Jogando, golpes pelas costas acontecerem sem que ninguém tenha feito acrobacia para chegar lá: a frente pode precisar de mais que 90°.
- Andar em volta do outro, sem acrobacia, passar a vencer as trocas: a guarda precisa acompanhar melhor.
- Os amigos não entenderem por que um golpe pegou com a guarda alta.
