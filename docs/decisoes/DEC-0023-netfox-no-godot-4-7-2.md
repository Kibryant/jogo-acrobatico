---
id: DEC-0023
titulo: O netfox no Godot 4.7.2 — main fixada no cf5189d, com core, extras e internals em addons/, e os autoloads em res:// guardados por teste
data: 2026-10-04
status: aceita
decidido_por: Arthur
fontes: [F-005, F-023, F-024, F-025, F-026, F-027, F-028, F-029, F-033, F-036]
substitui:
substituida_por:
---

# DEC-0023 — O netfox no Godot 4.7.2: main fixada no cf5189d, com core, extras e internals em addons/, e os autoloads em res:// guardados por teste

## Contexto

A DEC-0003 escolheu o netfox na main, fixada num commit. Ela pedia que a suíte do netfox passasse no 4.7.2 antes de ele entrar. A Q-02 perguntava se ele roda no 4.7.2 e se o bug #659 tem contorno (F-005 §8).

Ao deixar o Desenho 3 Ready, o Arthur confirmou as escolhas (F-023 §3):

- a main fixada no `cf5189d`, com core e extras;
- se a suíte falhasse só nos 4 testes de float16, ele entraria assim mesmo, sem usar float16;
- o contorno do #659 seriam os autoloads com `res://` no `project.godot`, guardados por um teste, em vez de remendar o código do netfox.

A rodada 1 rodou a suíte no Godot 4.7.2, no commit `cf5189d` (F-024):

- 297 de 301 testes passaram, em 3,3 s;
- os 4 que falham são os de float16 do grupo `NetworkSchemas`;
- os grupos de rollback, tempo e sincronização passaram inteiros.

O #659 foi reproduzido (F-024 §4). Com os autoloads em `uid://`, o import do zero soltou 30 linhas `SCRIPT ERROR`, não criou o `NetworkTime` e saiu com código 0. O segundo import esconde o erro. Com `res://`, o import do zero saiu limpo.

A mesma cópia do netfox rodou o resto da rodada 1: a SyncTest, as medições com 2 e com 8 clientes e o parry de brinquedo (F-025 a F-029).

Em 04/10/2026, a main do netfox seguia no `cf5189d`. O PR #659 e as issues #554, #613 e #630 seguiam abertos (F-036 §1).

Na sonda, o import do Godot 4.7.2 reescreve os 9 arquivos `.svg.import` dos ícones do netfox: ele acrescenta `compress/uastc_level`, `compress/rdo_quality_loss` e as quatro linhas de `process/channel_remap` (F-036 §2).

## Opções consideradas

1. **A main fixada no `cf5189d`:** a escolhida (F-023 §3).
2. **O release v1.35.3:** tem mais de 10 meses e não traz as correções da main, como as do tick correto (#633 e #639) (F-005 §5 e §8). Ele só seria testado se a suíte falhasse em rollback, tempo ou sincronização (F-023 §3), e ela não falhou.
3. **Remendar o código do netfox com os tipos do PR #659:** recusada. O código de terceiros fica como veio, e o contorno mora no nosso `project.godot` (F-023 §3).

## Decisão

1. **O netfox entra fixado no commit `cf5189d18e98766022c8c1c5e637a6a30c4c3703`** (26/09/2026), versão 1.49.4 no `plugin.cfg`. Em `addons/`, entram três pastas:
   - `netfox`, o core;
   - `netfox.extras`;
   - `netfox.internals`, do qual os outros dois dependem (F-005 §2).
2. **Ficam de fora:**
   - o `netfox.noray`, porque o servidor dedicado dispensa o NAT (F-005 §9);
   - os exemplos;
   - o `vest`;
   - os testes e a documentação do netfox.
3. **O código fica como veio, menos os 9 `.svg.import`.** Eles entram já reescritos pelo import do Godot 4.7.2, para um clone novo não sujar a árvore. Todo o resto bate, byte a byte, com o `git ls-tree -r cf5189d` do upstream.
4. **O float16 não se usa.** Os 4 testes que falham são os serializadores de float16 (F-024 §3).
5. **Os 14 autoloads ficam listados no `project.godot` com caminho `res://`,** na ordem que a sonda provou. São os 12 do core, mais o `WindowTiler` e o `NetworkSimulator` do extras. Com todos presentes, o plugin não acrescenta nenhum com `uid://`. O `test/project_settings_test.gd` guarda o mapa exato de nome e caminho, e falha com `uid://`, com um autoload a menos ou com um a mais.
6. **Os três plugins ficam ligados** em `[editor_plugins]`, ao lado do gdUnit4.
7. **O `WindowTiler` e o `NetworkSimulator` ficam, inertes no jogo de verdade.**
   - O `WindowTiler` sai cedo no build exportado e sem tela (`window-tiler.gd`, `_ready`).
   - O `NetworkSimulator` sai cedo fora do editor e com `netfox/autoconnect/enabled` desligado (`network-simulator.gd`, `_ready`).
   - O `autoconnect` fica desligado, porque quem conecta é a `Main` (DEC-0026).

## Consequências

- A Q-02 fecha. A DEC-0003 fica completa: o commit, os módulos e o contorno do #659.
- O `project.godot` ganha os autoloads e os plugins, e o teste de configurações guarda os dois (critério 3 da TASK-5).
- O #659 é vigiado em duas camadas:
  - o import do portão procura erro no log, e pega o problema num clone limpo, como o do CI;
  - o teste de configurações pega o problema em qualquer máquina, mesmo com o `.godot` já criado (F-024 §5).
- O `AGENTS.md` cita o netfox e o commit na linha de `addons/`.
- Atualizar o netfox é uma DEC nova. Ela roda a suíte no commit novo, refaz a SyncTest dos contornos (DEC-0025), confere o #659 e compara os arquivos com o upstream.
- O comportamento do netfox que o jogo usa está no `docs/arquitetura/rede.md`, citado pelo arquivo e pelo commit.

## Revisitar se

- O netfox lançar uma versão com o #659 resolvido, ou a main trouxer uma correção de que o jogo precise, como a do #613 (previsão) ou a do #630 (banda).
- Uma versão nova do Godot fizer a suíte do netfox falhar fora do float16.
- Um bug do netfox travar uma fase sem contorno.
