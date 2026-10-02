---
id: DEC-0016
titulo: Cancelamento só desenhado — na lista, com preço, com aviso e com janela larga
data: 2026-10-02
status: aceita
decidido_por: Arthur
fontes: [F-001, F-012, F-013, F-014]
substitui:
substituida_por:
---

# DEC-0016 — Cancelamento só desenhado: na lista, com preço, com aviso e com janela larga

## Contexto

O Arthur quer animação fluida e disse "Eu não quero o cancelamento de animações" (F-012 §1). Depois, em dúvida, perguntou se cancelar faz sentido, lembrando a Riven do LoL: "o cara que sabe cancelar a animação fica muito na frente dos outros" (F-013 §1).

O combate v0 já tem dois cancelamentos (F-001):
- a finta, que corta a preparação de um golpe por 15 de stamina;
- a recuperação do leve, que pode ser cancelada para a esquiva.

O K-style do GunZ é uma técnica descoberta pelos jogadores, não desenhada (F-001).

## Opções consideradas

1. **Nenhum cancelamento:** mata a finta, que é o centro do jogo mental da tribo For Honor e Chivalry 2 (DEC-0014).
2. **Tolerar cancelamento por brecha:** premia o dedo, e não a decisão. A animação pula, e o outro lado não consegue ler, o que fere o pilar 1 (`docs/design/visao.md`).
3. **Só cancelamento desenhado:** a escolhida, proposta pelo Claude.

## Decisão

O Arthur aceitou em 02/10/2026: "Ok" (F-014 §1). Todo cancelamento do jogo cumpre quatro condições:

1. **Está na lista** de `docs/design/combate.md`. O que não está na lista não cancela.
2. **Tem preço**, em stamina.
3. **Tem aviso:** o outro lado vê e ouve o corte.
4. **Tem janela larga:** com o buffer de input, cancelar é decisão, não reflexo de um tick.

No v0, a lista tem a finta e a passagem da recuperação do leve para a esquiva, as duas como hipótese. O protótipo da fase 2 decide se a do leve fica.

## Consequências

- Na máquina de estados do personagem, cada cancelamento é uma transição escrita e testada. Transição que ninguém escreveu não existe (DEC-0004).
- A técnica própria do jogo (Q-07) não pode nascer de cancelamento por brecha.
- O pilar 1 e o anti-pilar 5 de `docs/design/visao.md` seguem esta regra.

## Revisitar se

- O protótipo mostrar uma luta travada demais.
- Um cancelamento da lista virar obrigatório para competir.
