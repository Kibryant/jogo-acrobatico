---
id: DEC-0057
titulo: A espada na mira — o golpe aponta do corpo para o ponto da linha da mira a 2,0 m, onde chega a ponta da lâmina; o corpo olha para ele desde a preparação, e o boneco e o bot miram como gente
data: 2026-11-14
status: aceita
decidido_por: Arthur (F-197; F-198; F-199)
fontes: [F-196, F-197, F-198, F-199, F-200]
substitui: DEC-0051, só o item 5 do §2 (a direção do golpe segue a câmera na preparação) e a frase do §5 de que o corpo olha para a direção do golpe do primeiro tick ativo ao fim
substituida_por:
---

# DEC-0057 — A espada na mira: o golpe aponta do corpo para o ponto da linha da mira a 2,0 m, onde chega a ponta da lâmina; o corpo olha para ele desde a preparação, e o boneco e o bot miram como gente

## Contexto

Jogando a TASK-12.3, o Arthur errou 11 carregados ao alcance, e em todos o boneco estava à direita do corte, em média 0,57 m (F-196 §1). Nas palavras dele: "Eu tive que compensar a mira pra eu acertar o golpe" e "Sendo que o golpe leve não precisa compensar a mira" (F-196 §2).

É a paralaxe da mira da DEC-0045. A câmera fica 0,8 m à direita do corpo, e o golpe saía do eixo do corpo na direção do yaw da câmera (DEC-0051 §2, item 5), paralelo à linha da mira e 0,8 m à esquerda dela. Com a mira em cima do boneco, o carregado nunca pegava: o corte passava 0,80 m ao lado da mira, e a folga é de 0,43 m, os 0,35 m do corpo mais os 0,08 m da lâmina (F-198, contexto). O leve, com 120° de arco, escondia o erro. O gancho foi corrigido trocando a origem do raio para o ponto O, em cima da linha da mira (DEC-0045 §2). A lâmina não pode trocar de origem, porque sai da mão, então só pode cruzar a linha da mira num ponto.

O Arthur mandou a correção para uma task nova, a TASK-12.14, que vale para o leve e o carregado e faz o boneco mirar como gente (F-197 §1, a opção escolhida).

No refino, o Claude refez sem tela o replay de 30/10, sem divergir em nenhum tick. Os 21 carregados do Arthur ao alcance começaram todos entre 1,46 e 2,18 m de centro a centro, com mediana de 1,84 m, e os dois nunca ficaram a menos de 1,46 m (F-198, contexto; vitrine "A espada na mira", https://claude.ai/artifact/L7KqadgdN4jZh4aqhpP6ao). Nos jogos de tiro em terceira pessoa, a correção padrão é a mesma: o tiro sai da arma para o ponto que a mira indica, com um ponto a uma distância fixa quando o raio não acha nada (F-200 §1). Na espada, o Naraka vai pela assistência, que mira o golpe no inimigo (F-200 §2).

## Opções consideradas

1. **Um ponto fixo da linha da mira, a 2,0 m do eixo do corpo, onde chega a ponta da lâmina (escolhida):** o golpe gira asen(0,8 / 2,0) ≈ 23,58° para a direita do yaw da câmera. Com a mira no eixo do alvo, o carregado pega de 1,11 a 2,40 m de centro a centro, e o leve de 0,80 a 2,42 m. Cobre toda a faixa medida, de 1,46 a 2,18 m. A direção depende só do input de quem bate: uma conta pura do yaw e do dado, e, no rollback, a correção do servidor nunca muda a direção da própria espada. Perde o carregado colado, abaixo de 1,1 m, que não aconteceu nenhuma vez na sessão.
2. **O ponto em que a linha da mira encontra o corpo do outro:** o carregado pegaria de 0,81 a 2,42 m. Mas a direção passaria a depender de onde o outro está. Seria um pouco de aim assist, com a espada se curvando para o corpo, e o desenho recusou travar a mira no oponente (`combate.md`, "A lâmina e o contato": "Direção"). Online, o servidor corrigiria depois a direção da espada quando a posição prevista do outro errasse. No 4v4, seria preciso decidir em qual corpo a mira está.
3. **Um raio do motor, como o do gancho:** o raio da mira só vê o cenário (DEC-0045 §3), então acharia a parede atrás do outro. Um raio contra os corpos é a opção 2.
4. **Outra distância de ponto:** um ponto a 1,5 m pega de 0,93 a 2,18 m: ganha a curta distância e perde o fim do alcance, onde o Arthur bateu (2,03 a 2,18 m). A ponta, a 2,0 m, é a distância que se explica sozinha: a ponta da espada cai em cima da mira.

## Decisão

Aceita pelo Arthur em 14/11/2026: "Recomendo ponto fixo a 2 metros também" (F-198 §2). A regra vale para o leve e o carregado, e o boneco mira como gente (F-197 §1). Ele mandou começar antes de a conferência da convergência bater: "pode fazer agora já. As tasks já. Pode começar" (F-199 §2). A explicação foi dada de novo, nomeando a ideia que atrapalhou (DEC-0043 §3).

1. **A convergência:** o ponto da linha da mira a 2,0 m do eixo de quem bate, no plano do chão, onde chega a ponta da lâmina. É um número do `CombatData`, `aim_convergence_m`, em metros, positivo, e maior que o ombro.
2. **A direção do golpe:** em cada tick da preparação, `Aim.swing_yaw(yaw, side, convergence)`, uma função pura do núcleo, igual a `yaw − asin(side / convergence)`. O `side` é o ombro do `MovementData` (`aim_side_m`, cópia do da câmera; DEC-0045 §2), e o `convergence` é o do `CombatConfig` (`aim_convergence`). Do primeiro tick ativo ao fim, a direção fica fixa, como antes. O pitch não entra. Leve e carregado usam o mesmo ponto.
3. **O corpo** olha para a direção do golpe na preparação também, e não para a câmera: 23,58° para a direita com o ombro de 0,8 m. A câmera e a mira não se mexem.
4. **O boneco e o bot miram como gente:** o yaw que eles mandam põe a linha da mira deles, saindo do ponto O deles, no eixo do outro. A conta é o yaw dos pés deles aos pés do outro mais `asin(side / distância)`, com a distância no plano do chão maior que o ombro; mais perto, só o yaw dos pés aos pés. Eles só produzem input (DEC-0022), e o golpe deles converge como o de quem joga.
5. **O que não muda:** a guarda e o parry medem a frente pelo corpo de quem defende, que olha para a câmera fora do golpe (DEC-0054; DEC-0056). O raio do gancho sai do ponto O (DEC-0045).

## Consequências

- **O núcleo:** o `Aim` ganha `swing_yaw`, que nunca devolve NaN: a razão `side / convergence` fica presa entre −1 e 1. O `Combat.step` escreve o `action_yaw` da preparação com ele, e o `Movement.before_move` põe o `facing_yaw` no `action_yaw` também na preparação. O `CombatData` e o `CombatConfig` ganham a convergência, e o `combat_v0.tres` traz 2,0. A validação do dado recusa uma convergência zero ou negativa, e um teste de dado prova que a do v0 é maior que o ombro do `movement_v0.tres`, como o teste de igualdade do ombro (DEC-0045 §2). O `FighterState` e o `TickInput` não mudam.
- **O boneco:** o `AttackingDummy` manda o yaw de quem mira como gente. O bot da TASK-12.8 nasce com a mesma regra.
- **O replay:** a direção nova refaz de outro jeito um replay gravado antes dela, então um replay antigo diverge da sessão gravada e só toca com `--force` (`arquitetura/testes-e-entrega.md` §4).
- **O papel:** o `combate.md` ganha "A espada na mira" e as linhas "Direção" e "Convergência", e "A direção" do leve e do carregado passa a seguir a convergência. O `partida.md` registra o boneco e o bot que miram como gente. O glossário ganha "convergência" e "mirar como gente". A DEC-0051 ganha o aviso de substituição parcial.

## Revisitar se

- O Arthur sentir o carregado colado errar, abaixo de 1,1 m, por exemplo contra o bot que anda (TASK-12.8).
- A quebra de guarda (TASK-12.4), que agarra em linha reta até 1,2 m, pedir um ponto próprio: a 1,2 m, o giro seria de 41,8°.
- A troca de ombro (Q-41) ou a mira das armas de longe mudarem o ombro.
- O manequim (TASK-12.9) mostrar o giro de 23,58° no golpe como estranho.
