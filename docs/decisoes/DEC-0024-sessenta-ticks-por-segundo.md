---
id: DEC-0024
titulo: 60 ticks por segundo
data: 2026-10-04
status: aceita
decidido_por: Arthur
fontes: [F-005, F-007, F-026, F-027, F-028, F-029, F-030, F-034]
substitui:
substituida_por:
---

# DEC-0024 — 60 ticks por segundo

## Contexto

A Q-01 perguntava se o jogo roda a 30 ticks por segundo, o padrão do netfox, ou a 60, o do estudo (F-005 §3; F-007 §8). A DEC-0003 deixou a escolha para uma medição no Desenho 3.

O Desenho 2 já trazia a evidência do arredondamento: a janela de parry de 80 ms vira 2 ticks (67 ms, −17 %) a 30 e 5 ticks (83 ms, +4 %) a 60 (DEC-0022).

A rodada 1 do Desenho 3 mediu os dois tickrates com rede, nesta máquina:

- **Ver o outro, com 2 clientes** (F-026 §2): a 60 ticks, 21 ms sem lag contra 38 a 30; 126 ms a ping 100 contra 140; 245 a ping 220 contra 240, com a cauda pior a 60 (p90 de 330 contra 271).
- **O custo, com 2 clientes** (F-026 §2):
  - a 60, o servidor refaz de 2,1 a 3,6 vezes os ticks de 30;
  - a CPU do servidor cresce de 2 a 2,7 vezes;
  - a banda dobra, nos dois sentidos (F-034 §2).
- **8 lutadores:**
  - a 30 ticks, o servidor gasta de 62 % a 77 % de um núcleo e fica para trás a ping 220;
  - a 60, não cabem neste PC nem sem lag (F-029 §3).
- **O parry, sem lag e com a mesma reação:** 72 % a 60 contra 50 % a 30, no bot com reação de gente (F-029 §2). O Arthur fez quase o mesmo: 72 % contra 48 % (F-027 §3).

Com lag, nenhum dos dois tickrates salva o parry no relógio do servidor (F-028 §3). Isso é da compensação (DEC-0026).

## Opções consideradas

1. **60 ticks:** a escolhida (F-030 §1).
2. **30 ticks:** metade do custo e cabe 8 lutadores neste PC sem lag. Em troca, a janela de parry perde 17 %, e o mesmo jogador defende 50 % em vez de 72 % (F-029 §2).

## Decisão

O jogo roda a 60 ticks por segundo, um tick a cada 16,7 ms. Na pergunta, o Arthur escolheu "60 ticks (Recomendado)", cuja descrição dizia: "O parry que você sentiu (72% contra 50%) e os números do design fiéis. Custa de 2 a 3,6 vezes a CPU de refazer; o 4v4 se revê na Q-09." (F-030 §1).

- O `project.godot` guarda `netfox/time/tickrate=60`, e o `test/project_settings_test.gd` falha se o valor mudar.
- O tickrate segue sendo um parâmetro da configuração: o `MovementConfig` é criado com ele, e o teste do pulo roda a 30 e a 60 (DEC-0022).

## Consequências

- A Q-01 fecha.
- Os tempos do design viram ticks a 60. A janela de parry de 80 ms vira 83 ms, o buffer de 150 ms fica exato, e o teto de compensação de 200 ms vira 12 ticks (DEC-0026).
- O histórico padrão do netfox, de 64 ticks, passa a valer 1,07 s em vez de 2,1 s (DEC-0026).
- O orçamento de CPU do 4v4 e do 8v8 fica apertado: 8 lutadores a 60 não cabem neste PC. A Q-09 e a regra 6 da DEC-0004, medir com 16 bots antes de prometer o 8v8, ficam mais urgentes. A saída medida é otimizar, ou um núcleo em outra linguagem (DEC-0020).

## Revisitar se

- A medição da Q-09, com o servidor rodando sozinho, mostrar que 60 ticks não seguram o 4v4 mesmo otimizado.
- A fase 2 mostrar que o parry a 30 ticks, já com a compensação, se sente igual ao de 60.
