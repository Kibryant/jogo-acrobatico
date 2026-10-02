---
id: DEC-0019
titulo: Número, medida e cálculo se mostram ao Arthur num artefato visual
data: 2026-10-02
status: aceita
decidido_por: Arthur
fontes: [F-015, F-016]
substitui:
substituida_por:
---

# DEC-0019 — Número, medida e cálculo se mostram ao Arthur num artefato visual

## Contexto

O Arthur não discute número no abstrato (F-015 §1; DEC-0017). Ele pediu: "coisas métricas e dados, números, esse tipo de coisa, seria bem mostrar em artefato" e "quanto mais ilustrativo for, melhor para mim" (F-016 §1). Contou que nunca teve foco em física e matemática e que prefere ver (F-016 §1).

## Opções consideradas

1. **Tabelas e fórmulas no terminal:** a forma anterior.
2. **Artefato visual e interativo:** a escolhida.

## Decisão

1. Quando a explicação depende de número, medida, física ou cálculo, o Claude a mostra num artefato visual, uma página privada no claude.ai, o mais ilustrativa possível: desenho em escala, animação no tempo real, comparação com coisas conhecidas.
2. O terminal leva o resumo e o link. Os documentos em `docs/` continuam sendo a fonte de verdade; o artefato é a vitrine deles.
3. O primeiro artefato é o do kit de movimento v0 (`docs/design/movimento.md`).

## Consequências

- O artefato fica privado até o Arthur decidir compartilhar.
- Quando os números mudarem, o artefato é republicado no mesmo link, para não ficar desatualizado.
- Para conferir as cores dos gráficos, a máquina ganhou Node.js 24 e Python 3.14, com o ok do Arthur (F-016 §2). Nenhum dos dois entra no portão.

## Revisitar se

- O artefato atrasar o trabalho mais do que ajuda.
