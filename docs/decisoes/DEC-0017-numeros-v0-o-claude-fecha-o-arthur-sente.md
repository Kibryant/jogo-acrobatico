---
id: DEC-0017
titulo: Números v0 — o Claude fecha pela melhor experiência do jogador, e o Arthur julga jogando
data: 2026-10-02
status: aceita
decidido_por: Arthur
fontes: [F-015]
substitui:
substituida_por:
---

# DEC-0017 — Números v0: o Claude fecha pela melhor experiência do jogador, e o Arthur julga jogando

## Contexto

Na rodada 2a do Desenho 1, o Claude mostrou uma tabela de números de movimento para aprovação. O Arthur respondeu que não consegue discutir número no abstrato: "como é que eu vou discutir com você a proposta de um 80 de altura da cápsula" (F-015 §1). Ele fechou a tabela como v0, para julgar no protótipo: "vamos fechar com V0 que você colocou [...] eu testo na V0" (F-015 §1). E pediu que tudo se baseie na experiência do jogador: "você quer a minha melhor experiência. Então você vai falar assim, em tudo que eu te falei, se baseia nisso" (F-015 §1).

## Opções consideradas

1. **Tabela para o Arthur aprovar número a número:** a forma anterior, que ele recusou.
2. **O Claude fecha os números v0, e o Arthur julga jogando:** a escolhida.

## Decisão

1. Nas conversas de desenho, o Claude fecha os números v0 pela melhor experiência do jogador, cada um com unidade e motivo, em `docs/design/`.
2. Na conversa, o Claude explica a sensação que o número cria, comparando com jogos que o Arthur conhece, e não pede aprovação de tabela crua.
3. Continua sendo pergunta para o Arthur o que muda a identidade do jogo, como ter ou não pulo duplo.
4. O Arthur julga jogando: é no protótipo que o número vira dele.
5. Fora das conversas de desenho, nada muda: o implementer e o test-writer só usam números de `docs/design/` e nunca inventam um.

## Consequências

- O `AGENTS.md` registra a regra nas regras de verdade.
- A rodada 2b do Desenho 1 fechou sem perguntas de número.

## Revisitar se

- Um número fechado pelo Claude mudar a identidade do jogo sem passar pelo Arthur.
- O Arthur quiser voltar a ver e aprovar os números.
