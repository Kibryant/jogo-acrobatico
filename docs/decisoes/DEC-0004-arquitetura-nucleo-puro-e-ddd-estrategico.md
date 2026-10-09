---
id: DEC-0004
titulo: Arquitetura — núcleo puro, nós finos e DDD só estratégico
data: 2026-10-02
status: aceita
decidido_por: Arthur
fontes: [F-002, F-003, F-005, F-007]
substitui:
substituida_por: DEC-0022, só a frase sobre a RewindableStateMachine; DEC-0031, só a frase "Som e VFX só tocam em tick novo, nunca na re-simulação" da regra 2
---

> ⚠️ Em parte substituída por DEC-0022 em 2026-10-02: a frase sobre a `RewindableStateMachine` não é a regra atual. As seis regras continuam valendo.

> ⚠️ Em parte substituída por DEC-0031 em 2026-10-08: a frase "Som e VFX só tocam em tick novo, nunca na re-simulação" da regra 2 não é a regra atual; som e efeito tocam uma vez por evento, pela chave. O resto da regra 2 e as outras regras continuam valendo.

# DEC-0004 — Arquitetura: núcleo puro, nós finos e DDD só estratégico

## Contexto

O Arthur quer "inovar" e ter a arquitetura definida desde o começo; citou DDD (F-003 §3). A pesquisa mostrou onde o DDD ajuda num jogo com rollback e onde atrapalha. Dentro da simulação, o rollback exige estado feito de valores, e evento de domínio dispara duas vezes ou "desacontece" (F-007 §1).

## Opções consideradas

1. **Núcleo puro com nós finos, e DDD só estratégico**, a escolhida (F-007 §2).
2. **Tudo em nós do Godot**: dá menos trabalho no começo, mas o rollback e os testes ficam mais difíceis (F-007 §2).
3. **ECS** (GECS, Flecs): compensa com dezenas de milhares de objetos, e o netfox trabalha com nós (F-007 §3).

## Decisão

Aceita pelo Arthur em 02/10/2026 (F-003 §4; F-002). São seis regras:

1. Um único núcleo puro em `core/`, sem nó: `step(estado, input, tick)`, com tudo em ticks inteiros.
2. Os nós são adaptadores finos. Som e VFX só tocam em tick novo, nunca na re-simulação.
3. Os dados ficam em Resources imutáveis, referenciados por ID no estado. A conversão de ms para ticks é testada.
4. Testar a regra, não a engine: a especificação do combate e o teste de rollback rodam no CI desde o dia 1.
5. DDD só estratégico: o glossário é a linguagem ubíqua, e a fronteira que importa é Simulação contra Meta.
6. Crescer por marcos: 1v1 de espada local, depois online, depois arco e armas, depois 4v4 com bots e por fim 8v8. A CPU com 16 bots é medida antes de prometer o 8v8.

Junto com as regras:

- O personagem é uma máquina de estados hierárquica, contada em ticks, feita com a `RewindableStateMachine` do netfox (F-005 §2).
- Os bots usam behavior tree (LimboAI) no servidor e só produzem input.
- Não entra ECS.

## Consequências

- `tools/check_core_purity.sh` barra em `core/` nó, singleton do motor, relógio, `Timer`, `await` e sorteio sem semente. O script roda no pre-commit e no portão.
- O movimento vira um "sanduíche": o núcleo decide a intenção, e o nó move e consulta a física (F-007 §2).
- Os contextos estratégicos (Simulação, Partida, Sala, Progressão e Contas) estão em `docs/arquitetura/visao-geral.md`.

## Revisitar se

- Re-simular 16 jogadores em GDScript estourar o orçamento de CPU. O custo ainda não foi medido (F-007 §2).
