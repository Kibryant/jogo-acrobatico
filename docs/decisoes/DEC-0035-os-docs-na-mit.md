---
id: DEC-0035
titulo: Os docs na MIT — tudo no repositório fica na MIT, inclusive os docs, as fontes e o AGENTS.md, salvo as exceções que a DEC-0033 e a DEC-0029 já dão, o código de conduta e o nome
data: 2026-10-10
status: aceita
decidido_por: Arthur (F-078 §4)
fontes: [F-078, F-079, DEC-0033, DEC-0029]
substitui:
substituida_por:
---

# DEC-0035 — Os docs na MIT: tudo no repositório fica na MIT, inclusive os docs, as fontes e o AGENTS.md, salvo as exceções que a DEC-0033 e a DEC-0029 já dão, o código de conduta e o nome

## Contexto

A DEC-0033 §1 dá a MIT ao código, aos testes e às ferramentas, e a CC BY 4.0 aos assets que o projeto fizer. Ela não diz a licença dos docs: `docs/`, com as fontes que guardam as falas do Arthur, os diários e as DECs, e o `AGENTS.md` com as skills. A lacuna apareceu quando um agente de planejamento com contexto limpo criticou o roteiro da abertura (F-078 §4). O texto da MIT cobre "this software and associated documentation files" (`LICENSE`).

O código de conduta é uma tradução do Contributor Covenant 3.0, que está sob a CC BY-SA 4.0 e não tem tradução oficial para o português; uma tradução é material adaptado e leva a mesma licença (F-079 §3).

## Opções consideradas

1. **MIT, como o código:** a escolhida. Uma licença só para tudo o que não é asset, sem fronteira para discutir no `AGENTS.md`, nas skills e nos comentários, que misturam código e texto. Quem copia mantém o aviso da licença e pode mudar o texto, inclusive as falas do Arthur nas fontes (F-078 §4).
2. **CC BY 4.0, como os assets:** feita para texto e mídia; quem copia dá o crédito e avisa o que mudou, o que protege um pouco mais as falas citadas. O README ganharia uma terceira regra, e o `AGENTS.md` e as skills ficariam numa fronteira a decidir (F-078 §4).

## Decisão

Decidida pelo Arthur em 10/10/2026: "MIT, como o código (Recomendado)" (F-078 §4).

- Tudo no repositório fica na MIT (`LICENSE`): o código, os testes, as ferramentas e os docs, inclusive `docs/`, as fontes, os diários, as DECs, o `AGENTS.md` e as skills. Completa a DEC-0033 §1.
- As exceções são só estas:
  - os assets próprios em `assets/`, fora de `assets/third_party/`, na CC BY 4.0 (`LICENSE-ASSETS`; DEC-0033 §1);
  - os assets de terceiros e os addons, cada um na sua licença, ao lado dos arquivos (DEC-0029);
  - o código de conduta, na CC BY-SA 4.0, a licença do original (F-079 §3);
  - o nome e o logo do jogo, que não têm licença (DEC-0033 §1).
- O README diz isso no formato "tudo é MIT, exceto", para que um arquivo novo sem aviso caia na MIT.

## Consequências

- As falas do Arthur nas fontes podem ser copiadas e mudadas por qualquer pessoa, desde que leve o aviso da MIT.
- Um arquivo que precise de outra licença precisa de um aviso próprio e de uma linha nas exceções do README.

## Revisitar se

- Alguém usar as falas do Arthur fora de contexto e isso pesar para ele.
- Entrar um texto de terceiros com licença que não combine com a MIT.
