---
id: DEC-0053
titulo: Um golpe no ar por pulo — o pulo do chão ou a queda de uma beirada, o pulo duplo, o pulo da parede e a soltura do gancho dão um leve no ar cada; nada correndo na parede nem na puxada do gancho, e o golpe próprio do gancho espera os estilos
data: 2026-10-28
status: aceita
decidido_por: Arthur (F-181 §2)
fontes: [F-001, F-012, F-174, F-180, F-181]
substitui:
substituida_por:
---

# DEC-0053 — Um golpe no ar por pulo

## Contexto

A matriz de posição da DEC-0050 deu ao ar só o leve, que desce em 45°, e nenhuma defesa; à corrida na parede e à puxada do gancho, nada, pela regra das mãos (F-174 §2). Ela não dizia quantos golpes cabem num voo. Jogando o leve rápido, o Arthur apertou o leve 65 vezes no ar, contra 6 com o leve de 400 ms (F-180 §1), e pediu golpe no pulo com um limite: "Um pulo, um golpe [...] senão fica muito bugado você pular e dar tipo 20 golpes no ar". Ele também questionou a parede e o gancho sem golpe, com o argumento de que a arma de fogo atira em qualquer lugar (F-180 §2).

A pesquisa do Claude, mostrada antes da escolha (F-181, contexto):

- **No ar:** o Naraka usa golpes no ar no meio dos combos, e no GunZ o golpe em quem está no ar o derruba.
- **Na parede:** nos jogos de espada pesquisados, o golpe da parede é um jeito de sair dela. No Naraka, o golpe agarrado na parede lança para a mira; no GunZ, o golpe cancela a parede. No Titanfall 2, a arma de fogo atira correndo na parede, com perda de precisão relatada por jogadores.
- **No gancho:** no Naraka, o golpe do gancho abre combos, e as interações dele foram remendadas em patch pelo menos seis vezes em cinco anos; o estudo já criticava o gancho ilimitado que vira spam (F-001).
- **Na nossa física:** um pulo dura 630 ms (350 de subida e 280 de queda; `movimento.md`, "Pulo e ar"), e o leve inteiro 550 (DEC-0052). Hoje já cabe no máximo um golpe por pulo; os 20 golpes no ar não acontecem, e só uma queda longa daria para começar um segundo.

## Opções consideradas

1. **Um golpe por pulo (escolhida):** cada impulso dá um leve no ar. A regra é clara e custa pouco.
2. **Golpe livre no ar,** limitado só pelo tempo de voo.
3. **Golpe correndo na parede e golpe na puxada do gancho** já na fase 2.

## Decisão

Aceita pelo Arthur: "Fechou. Aceito as recomendações" (F-181 §2).

1. **Um golpe no ar por pulo.** O leve no ar, o golpe que desce em 45°, sai uma vez por pulo. Cada um destes dá um: o pulo do chão ou a queda de uma beirada, o pulo duplo, o pulo da parede e a soltura do gancho. Depois do golpe, outro só sai depois do próximo desses; o aperto espera na vaga do buffer, como todo aperto que ainda não pode sair (DEC-0039).
2. **A parede:** nada correndo nela, como na DEC-0050; o golpe da parede é o pulo da parede seguido do leve no ar.
3. **O gancho:** nada durante a puxada na fase 2, como na DEC-0050; depois da soltura, o leve no ar vale. Um golpe próprio do gancho fica para os estilos de luta (Q-52).
4. **A arma de fogo** na parede e no gancho se decide no marco das armas, pela regra das mãos da DEC-0050.

## Consequências

- A DEC-0050 continua inteira; esta DEC a completa com o número de golpes no ar e com o pulo da parede e a soltura do gancho como portas do golpe no ar.
- A TASK-12.5, a filha da matriz, ganha os critérios do golpe por pulo, do pulo da parede e da soltura.
- O núcleo precisa saber se o voo atual já teve o seu golpe: um carimbo do golpe no ar contra os carimbos dos impulsos, que a TASK-12.5 desenha.

## Revisitar se

- Jogando, um pulo pedir dois golpes, ou o golpe no ar dominar o duelo.
- O golpe que lança da parede, à moda do Naraka, fizer falta para a parede virar jogada (pilar 3).
- Os estilos da Q-52 trouxerem golpes próprios do ar, da parede ou do gancho.
