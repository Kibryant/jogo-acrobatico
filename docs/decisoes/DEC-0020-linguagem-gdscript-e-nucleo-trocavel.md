---
id: DEC-0020
titulo: Linguagem — GDScript no jogo todo; só o núcleo muda de linguagem, se a medição pedir
data: 2026-10-02
status: aceita
decidido_por: Arthur
fontes: [F-001, F-005, F-006, F-007, F-019]
substitui:
substituida_por:
---

# DEC-0020 — Linguagem: GDScript no jogo todo; só o núcleo muda de linguagem, se a medição pedir

## Contexto

A DEC-0001 escolheu "Godot com GDScript", mas comparou motores, não linguagens. O Arthur perguntou se C# ou C++ não seriam melhores em otimização e em ecossistema: "Você acha que GDS é a melhor opção mesmo?" (F-019 §1).

Dentro do Godot há três caminhos: GDScript, C# (a versão .NET do Godot) e C++ (GDExtension). O netfox é escrito em GDScript; para C# existe o NetfoxSharp, que só acompanha os releases (F-005). O custo de CPU de re-simular 16 jogadores em GDScript ainda não foi medido (F-007).

## Opções consideradas

1. **GDScript no jogo todo:** não compila, lê como Python e é a língua do netfox e de toda a base (portão, formatador, checagem de pureza e gdUnit4). É a mais lenta das três na lógica pesada.
2. **C#:** várias vezes mais rápido na lógica pesada, com o ecossistema do .NET. Pede a versão .NET do Godot, leva o runtime do .NET na build e usa o netfox pelo NetfoxSharp, que só acompanha os releases; a DEC-0003 usa a `main` fixada num commit.
3. **C++ (GDExtension):** o mais rápido. Compila a cada mudança, um erro de memória derruba o jogo, e não há ponte pronta para o netfox.

## Decisão

GDScript no jogo todo, como já dizia a DEC-0001. Se a medição de CPU com 16 bots (DEC-0004, regra 6) mostrar que a re-simulação não cabe no tick, só o núcleo puro, em `core/`, muda para C# ou C++, decidido com os números na mão.

O Arthur decidiu em 02/10/2026: "Eu concordo, tá? [...] pode fazer uma deck curta aí" (F-019 §2).

## Consequências

- Esta DEC completa a DEC-0001, que continua valendo.
- Nada muda na base: portão, formatador, checagem de pureza e gdUnit4 seguem em GDScript.
- O núcleo isolado (DEC-0004) também é o que permite trocar a linguagem do trecho mais pesado sem reescrever o jogo. O Desenho 2 (TASK-4) parte desta premissa.

## Revisitar se

- A medição com 16 bots estourar o orçamento de CPU do tick.
- O netfox for abandonado, ou surgir uma rede em C# claramente melhor.
- O Arthur quiser aprender C# por outro motivo, como a carreira. A decisão é dele, e o motivo precisa ser dito.
