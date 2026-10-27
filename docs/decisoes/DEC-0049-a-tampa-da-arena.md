---
id: DEC-0049
titulo: A tampa da arena — uma placa invisível a 50 m, que só o corpo do lutador enxerga, fecha a saída por cima da borda; o plano de morte fica para a fase 2
data: 2026-10-27
status: aceita
decidido_por: Arthur (F-170 §2)
fontes: [F-152, F-167, F-170]
substitui:
substituida_por:
---

# DEC-0049 — A tampa da arena

## Contexto

A borda de 50 m fecha a arena dos lados (`movimento.md`, "A borda"; F-152). A sonda do canto da TASK-10.8 mediu a saída por cima: a cápsula sobe na quina de cima da borda, com o pulo duplo no topo do Z num canto ou com um gancho preso a 42,8 m ou mais, e cai do lado de fora, sem chão (`movimento.md`, "O canto da borda, medido"). Na F-167 §2, o Arthur escolheu o plano de morte para esse caso, antes de existir a alternativa da tampa.

## Opções consideradas

1. **Só a tampa (escolhida):** uma placa invisível sobre a arena, na altura do topo da borda. A cabeça bate nela antes de os pés chegarem à quina (F-170 §1). É cenário, sem regra do núcleo nem estado no rollback.
2. **Só o plano de morte:** quem cai fora volta ao início. Pega qualquer saída, mas é uma regra do núcleo com teletransporte no rollback, e numa luta pede a regra de duelo para quem cai fora.
3. **As duas.**

## Decisão

Aceita pelo Arthur: "Só a tampa agora (Recomendado)" (F-170 §2).

1. **A tampa:** uma caixa de 82 × 1 × 82 m sobre a arena, com a face de baixo a 50 m, no topo da borda. Sem malha e sem sombra: ninguém a vê.
2. **Uma camada só dela:** só o corpo do lutador colide com a tampa. O raio da mira, o do gancho, as sondas da parede e a câmera seguem enxergando só o cenário (`PhysicsLayers.WORLD`), então ninguém mira o céu nem corre no teto.
3. **O plano de morte vai para a fase 2**, com a regra do duelo para quem cai fora (Q-48). A escolha da F-167 §2 muda por esta DEC.

## Consequências

- O topo dos pés fica em uns 48,2 m (50 m menos a cápsula de 1,8 m), abaixo da quina: o Z do canto e o gancho não tiram mais o lutador da arena. A sonda do canto vira teste no portão.
- Nada abaixo disso muda: o gancho do topo do pilar leva os pés a 43,34 m, e o Z para antes da tampa (`movimento.md`, "A borda").
- Bater num teto invisível a 48 m é estranho, mas só quem procura a saída chega lá.

## Revisitar se

- Um mapa tiver vãos para cair ou saídas que a tampa não fecha: aí entra o plano de morte (Q-48).
- Jogando, a tampa aparecer no caminho de uma jogada que não é a de sair da arena.
