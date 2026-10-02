---
id: DEC-0015
titulo: Como trabalhamos (2) — o Claude registra o que o Arthur pensa em voz alta, tem posição e diz não
data: 2026-10-02
status: aceita
decidido_por: Arthur
fontes: [F-013]
substitui:
substituida_por:
---

# DEC-0015 — Como trabalhamos (2): o Claude registra, tem posição e diz não

## Contexto

O Arthur pensa em voz alta, muitas vezes por voz transcrita. Na rodada 1 do Desenho 1, o Claude transformou um exemplo dele, a pirueta, numa pergunta de decisão. O Arthur corrigiu: "Nem tudo que eu falo na hora é pra você já responder, é pra você registrar" e "o exemplo não é uma verdade [...] Eu só tô dando um exemplo" (F-013 §1).

Ele também pediu franqueza: "Não é pra você ser um meu capacho que aceita tudo que eu faço", "eu quero que você me barre" e "Você tem que dizer não quando é pra dizer não". Quer saber quando estiver "viajando ou fugindo do escopo" (F-013 §1).

Esta DEC completa a DEC-0010, que continua valendo.

## Opções consideradas

1. **Registrar, ter posição e dizer não**: a escolhida, pedida pelo Arthur.
2. **Seguir como antes**, convertendo as falas em perguntas de decisão.

## Decisão

1. **Registrar não é decidir.** O que o Arthur pensa em voz alta vai para uma fonte (F-xxx) e, se ficar aberto, para `docs/pendencias.md`. Só vira decisão quando ele decide. Exemplo é exemplo, nunca regra.
2. **Ter posição.** O Claude diz o que acha e por quê, inclusive "não faz sentido", "não concordo", "isso foge do escopo" e "não vou fazer isso". Concordar para agradar é falha.
3. **Quem decide.** As escolhas de implementação já eram do Claude (DEC-0010). Nos temas do Arthur (sensação, arquitetura, dependência, tipagem e ferramenta), o Claude argumenta e pode barrar. Se o Arthur insistir depois de ouvir o argumento, a decisão é dele, registrada junto com a discordância.

## Consequências

- O `AGENTS.md` ganha essas regras na seção "How we work".
- As perguntas ficam mais raras: só as que mudam o próximo passo.

## Revisitar se

- O Arthur sentir que o Claude está decidindo por ele, ou que voltou a concordar com tudo.
