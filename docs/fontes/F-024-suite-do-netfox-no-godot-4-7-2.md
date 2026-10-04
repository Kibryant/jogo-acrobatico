---
id: F-024
titulo: A suíte do netfox no Godot 4.7.2, no commit cf5189d, e o #659 reproduzido (sessão 4, 03/10/2026)
recebido_em: 2026-10-03
como: Execução do Claude Code na rodada 1 do Desenho 3 (TASK-5), num clone do netfox em `C:\Users\arthu\Projects\netfox-sonda`, fora do repositório (F-023 §3). Comandos e saídas como saíram; as listas longas estão resumidas onde indicado.
status: vigente
substituida_por:
---

## §1 — O ambiente

- Godot `4.7.2.stable.official.ed1daf0bf`, o console do PATH, no Windows 11 com o Ryzen 3 PRO 3200G (F-004).
- netfox `main`, commit `cf5189d18e98766022c8c1c5e637a6a30c4c3703` (26/09/2026), baixado com `git fetch --depth 1`.
- Os comandos são os do `sh/test.sh` do netfox:
  - `godot --headless --import .`
  - `godot --headless -s addons/vest/cli/vest-cli.gd --vest-glob "res://test/*.test.gd" --vest-report-format tap --vest-report-file vest.log`

## §2 — O primeiro import, do zero

- Sem `.godot` e com os autoloads em `res://`, como o `project.godot` do netfox os registra: saída 0, 14,7 s, nenhum `SCRIPT ERROR`.
- Os avisos são dos assets dos exemplos: dois scripts com UID duplicado entre `visibility-filtering` e `rollback-npc`, malhas do Forest Brawl em formato antigo e um arquivo menor que o esperado.
- O import não reescreveu o `project.godot`; só os `.import` dos assets mudaram.

## §3 — A suíte

- 32 grupos e 301 testes, em 3,3 s: 297 passam e 4 falham.
- Os 4 que falham estão no grupo `NetworkSchemas`, todos de float16 (`test/netfox/schemas/network-schemas.test.gd`, linhas 107 e 108):

| Teste | Mensagem |
|---|---|
| `vec2f16` | "Size mismatch!": esperava 4 bytes, recebeu 8 |
| `normal2f16` | "Value mismatch!": esperava (0.866025, 0.5), recebeu (0.866106, 0.49986) |
| `quat16f` | "Value mismatch!": esperava (0.570942, 0.167519, 0.167519, 0.786067), recebeu (0.570801, 0.16748, 0.16748, 0.785645) |
| `transform2f16` | "Value mismatch!": esperava X (0.765414, -0.643538), recebeu X (0.765137, -0.643066) |

- São os 4 testes de float16 que o PR #659 relata no 4.7 (F-005 §8).
- Passam inteiros os grupos de rollback, tempo e sincronização: `RollbackSynchronizer`, `NetworkRollback`, `RollbackSimulationServer`, `NetworkHistoryServer`, `NetworkSynchronizationServer`, `RollbackLivenessServer`, `NetworkTickrateHandshake`, `InterpolationServer`, os três serializadores de snapshot, `PropertyEntry`, `PropertySnapshot` e `Snapshot`.

## §4 — O #659 reproduzido

- Os 16 autoloads do netfox trocados para `uid://`, com os valores dos arquivos `.gd.uid`, sem `.godot`, e `godot --headless --import .`:
  - saída 0;
  - 30 linhas `SCRIPT ERROR`, como "Parse Error: Cannot infer the type of \"spawn_callback\" variable because the value doesn't have a set type." e "Compile Error: Failed to compile depended scripts.";
  - "ERROR: Failed to create an autoload, script 'res://addons/netfox/network-time.gd' is not compiling."
- O segundo import, com o `.godot` já criado: saída 0 e nenhum erro. A suíte logo depois dá o mesmo resultado do §3.
- Com o `project.godot` original de volta, em `res://`, o import do zero ficou limpo de novo.

## §5 — O que isso diz do nosso portão (leitura do Claude)

- O `tools/gate.sh` procura `SCRIPT ERROR`, `Parse Error` e `ERROR:` no log do import (linha 26). Num clone limpo, como o do CI, ele pegaria o #659 mesmo com a saída 0.
- Numa máquina que já tem `.godot`, o segundo import não mostra nada. O pre-push local passaria, e só o CI ficaria vermelho. O teste que vigia o `res://` (TASK-5, critério 3) pega o problema antes, em qualquer máquina.
