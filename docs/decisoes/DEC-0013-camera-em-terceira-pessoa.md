---
id: DEC-0013
titulo: Câmera em terceira pessoa
data: 2026-10-02
status: aceita
decidido_por: Arthur
fontes: [F-001, F-012]
substitui:
substituida_por:
---

# DEC-0013 — Câmera em terceira pessoa

## Contexto

A acrobacia é a identidade do jogo (F-001), e o Arthur quer que "a pessoa do outro lado" consiga "entender o que você está fazendo" (F-012 §1). A câmera estava em aberto no `docs/design/movimento.md`, e a TASK-3 sugeria terceira pessoa, pela leitura do combate e da acrobacia.

## Opções consideradas

1. **Terceira pessoa**, a escolhida. O jogador vê o próprio corpo na parede e no ar, e vê a silhueta inteira do adversário, onde está a leitura do golpe.
2. **Primeira pessoa**: pirueta e mortal em primeira pessoa seriam difíceis de controlar (F-012 §1).

## Decisão

Câmera em terceira pessoa. O Arthur decidiu em 02/10/2026: "Eu concordo com a câmera em terceira pessoa, com certeza em terceira pessoa. O jogo dando pirueta, fazendo um monte de coisa em primeira pessoa ia ser muito difícil de controlar." (F-012 §1)

A distância, o ombro e o campo de visão saem na rodada 2 do Desenho 1 e vão para `docs/design/movimento.md`.

## Consequências

Dois custos conhecidos da terceira pessoa, apontados pelo Claude na rodada 1, entram no desenho:

- **Espiar a quina:** a câmera vê o que o corpo ainda não vê. O efeito diminui com a câmera perto do corpo e com o desenho do mapa.
- **Mira:** a mira fica no centro da tela, mas o projétil sai da arma. O tiro segue para o ponto que uma linha saindo da câmera encontra.

## Revisitar se

- O protótipo da fase 1 mostrar que a câmera atrapalha a corrida na parede ou o gancho.
- Espiar a quina virar vantagem decisiva no 1v1.
