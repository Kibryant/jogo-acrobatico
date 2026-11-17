---
id: DEC-0058
titulo: A quebra, o tech e a esquiva no tick — a mão mira o ponto da linha da mira a 1,2 m, quem foi agarrado resolve o agarrão e quem agarrou lê na foto, o tech é um aperto depois do contato, e a esquiva é conferida por quem bate, pela foto
data: 2026-11-17
status: aceita
decidido_por: Arthur (F-210; F-209; F-208; F-207)
fontes: [F-173, F-174, F-207, F-208, F-209, F-210]
substitui:
substituida_por:
---

# DEC-0058 — A quebra, o tech e a esquiva no tick

## Contexto

A DEC-0051 pôs o golpe no tick; a DEC-0055, a guarda, o tranco e a paradinha; a DEC-0056, o carregado, o parry e a finta; a DEC-0057, a espada na mira. A TASK-12.4 traz a quebra de guarda, o tech e a esquiva como dash, com os números do `combate.md` (Q-25; DEC-0050). No refino, o Arthur escolheu o botão do meio do mouse (F-207) e o tranco de 1.200 ms na quebra sem tech, para o carregado ser garantido também contra o parry e o dash (F-208).

Faltavam cinco peças:
- para onde a mão vai, com a câmera de ombro (DEC-0045);
- quem a quebra agarra, além da lista do papel;
- como os dois ficam presos, e como quem agarrou sabe;
- o que conta como tech;
- quem confere a esquiva, e o que o golpe faz com o dash que ele corta.

## Opções consideradas

Para a direção da mão (F-209):

1. **O ponto da linha da mira a 1,2 m, onde a mão chega (escolhida).** É o princípio da espada: o fim da arma cruza a mira. Com a mira no eixo do boneco, pega de 0,88 a 1,48 m. Na preparação, o corpo vira 42° para a direita da câmera.
2. **O ponto a 2,0 m, como a espada.** A mão para antes de cruzar a mira e só pega de 1,25 a 1,48 m.
3. **Reto à frente do corpo.** Com a mira no boneco, a mão passa 0,8 m ao lado e nunca pega.

Para a esquiva:

1. **Quem bate confere, pela foto (escolhida).** O golpe que passa pelos ticks invulneráveis segue vivo e pega o fim do dash, como o papel pede ("um carregado atrasado pega o fim do dash").
2. **Quem defende resolve, como o bloqueio.** O contato carimbado gastaria a única chance do golpe (Q-26), e ele nunca pegaria o fim do dash.

Para o tech:

1. **Um aperto da quebra depois do contato, de graça (escolhida).** É resposta a um estímulo só, e quem está sem stamina não fica sem defesa.
2. **Com os 15 de stamina da quebra.** Sem stamina não haveria tech, e a quebra viraria castigo garantido contra quem está cansado.

## Decisão

Aceita pelo Arthur no modo de plano (F-210), com a direção da mão escolhida por ele (F-209).

1. **A ação ganha `GRABBING` (quem agarrou) e `GRABBED` (quem foi agarrado),** no fim do enum. O estado ganha dois carimbos em quem foi agarrado: `grabbed_tick`, o contato do último agarrão, e `tech_tick`, o tick do último tech. O input ganha o toque `guard_break`, e o comando, `GUARD_BREAK`.
2. **A quebra** sai como o leve: em pé no chão, sem golpe nem tranco, com 15 na barra, pagos no disparo. Tem 21, 6 e 24 ticks.
   - A mão sai do eixo do corpo a 1,3 m de altura e avança 0,2 m por tick nos 6 ticks do ativo, até 1,2 m, rumo ao ponto da linha da mira a 1,2 m. Toca a até 0,35 m do eixo do outro.
   - A convergência passa a ser de cada golpe, no dado: 2,0 m no leve e no carregado, 1,2 m na quebra.
3. **Quem a quebra agarra:** quem está no chão sem bater. Parado ou andando, bloqueando, na postura do parry, na preparação ou na recuperação de um golpe, no blockstun, na finta e nos ticks do dash que não são invulneráveis. Não agarra quem está no ativo de um golpe, no tranco de um golpe levado, aparado, no ar, na parede, no gancho ou já preso. Duas quebras que tocam no mesmo tick erram as duas.
4. **O agarrão** é um ramo do passo 1 do `Combat.step`, antes do parry.
   - Quem foi agarrado o resolve no tick seguinte ao contato: entra no `GRABBED`, carimba o `grabbed_tick` e congela os 4 ticks da paradinha.
   - Quem agarrou lê o carimbo na foto dois ticks depois do contato, pelo `contact_target`, e entra no `GRABBING`, congelado 4 ticks.
   - Os dois ficam presos até o contato + 20 + 4. Um golpe em quem está preso ou atordoado pelo agarrão pega como em quem está parado: é assim que o carregado garantido pega.
5. **O tech** é um aperto da quebra depois do contato, até o último tick preso, sem custo.
   - Quem respondeu carimba o `tech_tick` e se solta no contato + 24; quem agarrou lê o carimbo na foto e se solta 2 ticks depois, no + 26.
   - Sem tech, quem agarrou se solta no + 24, e quem foi agarrado só volta a agir no contato + 72 + 4.
6. **A esquiva:** quem bate testa a foto. Com o outro no dash, sem tranco, entre o 3º e o 10º tick, a lâmina ou a mão passa sem carimbar, e o golpe segue vivo. O golpe que pega no 1º, 2º, 11º ou 12º tick corta o dash, que acaba como acabaria sozinho: o modo do chão e a velocidade de saída.
7. **A vaga:** no mesmo tick, o parry vence a quebra, que vence o carregado, que vence o leve; as teclas de movimento vencem todos.

## Consequências

- O `Combat.step` ganha o agarrão no passo 1, o "agarrou" no lado de quem bateu, o tech e o fim do agarrão. O teste da mão fica ao lado do da lâmina.
- O teste do toque passa a ler o estado do outro na foto, pela primeira vez, para a esquiva.
- `Aim.swing_yaw` recebe a convergência do golpe.
- O `Movement` corta o dash de quem leva um golpe.
- O replay grava a quebra no cabeçalho e o toque novo nas colunas; os replays de antes só tocam com `--force`.
- O resumo do replay ganha o bloco da quebra e a taxa de tech de quem é agarrado (TASK-14).

## Revisitar se

- A faixa da mão, de 0,88 a 1,48 m com a mira no eixo, pedir um passo a mais ou a menos jogando: a convergência da quebra é um número do dado.
- Agarrar abaixo de 1,11 m deixar o carregado garantido fora de alcance: com a mira no eixo, ele só pega a partir de 1,11 m.
- O 4v4 trouxer terceiros batendo em quem está preso: no v0, o golpe pega, e o outro lado segue no agarrão até o fim dele.
- O tech de graça virar aperto às cegas: hoje, um aperto antes do contato não conta.
