---
id: DEC-0002
titulo: Piso de desempenho nesta máquina, renderer Compatibility e física Jolt
data: 2026-10-02
status: aceita
decidido_por: Arthur
fontes: [F-002, F-003, F-004, F-006]
substitui:
substituida_por:
---

# DEC-0002 — Piso de desempenho nesta máquina, renderer Compatibility e física Jolt

## Contexto

O PC do Arthur tem um Ryzen 3 PRO 3200G, 16 GB de RAM e uma RX 550 de 4 GB, com monitor 1080p (F-004). Um jogo grátis com público brasileiro vai encontrar muito PC parecido com esse (F-002). O Godot tem três renderers: Forward+, Mobile e Compatibility. Trocar de Compatibility para os outros dois depois custa mais ajuste visual do que trocar entre eles (F-006 §3).

## Opções consideradas

1. **Piso nesta máquina, com renderer Compatibility**, a escolhida.
2. **Piso nesta máquina, com renderer Mobile**: tem mais recursos visuais e roda em Vulkan.
3. **Sem piso definido, com Forward+**: tem todos os recursos e fica pesado para a RX 550.

## Decisão

1. O piso de desempenho é 60 fps em 1080p neste PC, que vira a máquina de requisito mínimo do jogo. O Arthur decidiu em 02/10/2026: "fecho com desempenho mínimo" (F-003 §2).
2. O renderer é o Compatibility (OpenGL), aceito em 02/10/2026 (F-003 §4; F-002).
3. A física 3D é o Jolt, ligada explicitamente no `project.godot`. O padrão do motor ainda é a física antiga, e o Jolt só vem ligado quando o projeto nasce pelo gerenciador de projetos (F-006 §3).

## Consequências

- `test/project_settings_test.gd` confere o renderer, o Jolt e o `physics_jitter_fix = 0`, que a documentação recomenda para jogo em rede (F-006 §1).
- Se faltar recurso visual, a troca para o Mobile tem custo de ajuste.

## Revisitar se

- Faltar um recurso visual que o Compatibility não tem.
- O desempenho cair abaixo do piso com 16 jogadores.
