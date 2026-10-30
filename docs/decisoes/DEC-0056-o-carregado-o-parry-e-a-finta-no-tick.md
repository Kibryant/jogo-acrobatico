---
id: DEC-0056
titulo: O carregado, o parry e a finta no tick — o carregado paga na soltura e a armadura não congela quem carrega, o parry é uma postura que quem defende resolve e quem bateu lê na foto, e a finta é o aperto da guarda na preparação
data: 2026-10-30
status: aceita
decidido_por: Arthur (F-192; F-191 §2)
fontes: [F-173, F-188, F-190, F-191, F-192]
substitui:
substituida_por:
---

# DEC-0056 — O carregado, o parry e a finta no tick

## Contexto

A DEC-0051 pôs o golpe no tick, e a DEC-0055 pôs a guarda, o tranco e a paradinha. A TASK-12.3 traz o carregado, a armadura, o parry e a finta, com os números do `combate.md`. No refino, o Arthur manteve o leve sem parry e o castigo do desenho até jogar (Q-55), e escolheu o E, o F e o botão direito (F-190; F-191).

Faltavam quatro peças:
- onde o parry mora no estado, e quem o decide;
- como quem bateu sabe que foi aparado;
- como a armadura entra no contato sem mudar o tempo que se conta para aparar;
- como a finta separa o aperto da guarda da guarda segurada.

## Opções consideradas

Para a paradinha da armadura:

1. **Quem carrega não congela; quem bateu congela como num acerto (escolhida).** O carregado desce no tick de sempre, e quem conta o azul para aparar não se engana.
2. **Os dois congelam, como num acerto.** A paradinha fica simétrica, mas o carregado desce 4 ticks depois, e a conta do parry muda no meio.
3. **Ninguém congela.** O leve que pega na armadura não teria peso nenhum na tela.

Para o input da finta:

1. **Um toque novo, o aperto da guarda, lido por evento (escolhida).** Só o aperto conta, e a guarda segurada desde antes do carregado não finta.
2. **A guarda segurada na preparação.** Quem já segurava a guarda ao começar o carregado fintaria sem querer.
3. **Uma tecla própria.** É uma tecla a mais, contra a escolha do Arthur (F-191 §2).

Para a direção do parry:

1. **A metade da frente, como a guarda (escolhida).** A lâmina cruzada fica à frente, e pular por cima ou voltar pelas costas vence o parry, como vence a guarda (DEC-0054).
2. **Todas as direções.** Um parry pelas costas não se lê.

## Decisão

Aceita pelo Arthur no modo de plano (F-192).

1. **A ação ganha `PARRY`, `FEINT` e `PARRIED`,** no fim do enum. O estado ganha dois carimbos: `parry_tick`, o contato do último carregado aparado, em quem aparou, e `parried_tick`, o contato do último golpe aparado, em quem bateu. O input ganha os toques `charged_attack`, `parry` e `guard_press`, e a vaga ganha os comandos `charged_attack` e `parry`.
2. **O carregado** sai como o leve, com 25 na barra, e paga os 25 no primeiro tick ativo. Ele corta de cima para baixo, no plano vertical da direção do golpe (`combate.md`, "O carregado, o parry e a finta no tick").
3. **A armadura** é um ramo do passo 1 do `Combat.step`. O contato é de um golpe que não quebra armadura e chega na preparação de um golpe com armadura. Quem o resolve perde a vida e carimba o `hurt_tick`, sem tranco e sem congelar. Quem bateu congela pela foto, como num acerto.
4. **O parry** é a postura `PARRY`, desde o aperto, com a janela nos 12 primeiros ticks.
   - Quem defende o resolve no passo 1, antes do bloqueio e da armadura: apara o carregado com o contato na janela e quem bate na metade da frente.
   - Quem aparou carimba o `parry_tick` e volta 12 ticks depois do contato.
   - Quem foi aparado lê o `parry_tick` na foto dois ticks depois do contato, como lê o `block_tick`. Entra no `PARRIED`, congelado 9 ticks, até o contato + 54 + 9.
5. **A finta** é um passo novo, depois de as fases andarem e antes da guarda. O `guard_press` na preparação do carregado, até o tick 27, com 15 na barra, vira `FEINT` por 12 ticks.
6. **A vaga:** no mesmo tick, o parry vence o carregado, que vence o leve, e o movimento vence os três.

## Consequências

- O `Combat.step` ganha a armadura e o parry no passo 1, o resultado "aparado" no lado de quem bateu, e o passo da finta.
- O nó lê o aperto da guarda por evento, como o clique do leve; o `guard` segurado continua igual.
- O replay grava o segundo golpe no cabeçalho; os inputs novos entram por reflexão.
- O token passa a ser escolhido pelo golpe, e não só pela ação; no parry, também pelo tick, porque o amarelo só vale na janela.
- O castigo do parry fica o do desenho até o Arthur jogar (Q-55).

## Revisitar se

- Começados juntos, o leve seguido do parry tirar o valor do carregado: quem dá o leve volta no tick 37 e apara o carregado, que desce no 42.
- O leve apertado junto com a finta se perder na vaga e incomodar: a vaga guarda o aperto 150 ms, e a finta dura 200.
- A fase 3 mostrar que a foto do parry chega tarde demais para a paradinha de quem foi aparado.
