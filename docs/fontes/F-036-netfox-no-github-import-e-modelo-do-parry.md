---
id: F-036
titulo: Três conferências da sessão 5 — o netfox no GitHub em 04/10/2026, os .svg.import reescritos pelo Godot 4.7.2 e o modelo do parry por ping da vitrine (sessão 5, 04/10/2026)
recebido_em: 2026-10-04
como: Execução do Claude Code na sessão 5 (TASK-5). O §1 traz as saídas do `gh api` sobre o repositório `foxssake/netfox`. O §2 traz o `git diff` de um `.svg.import` na sonda e a comparação do implementer com o `git ls-tree -r cf5189d`. O §3 traz o modelo de `check.js`, rodado com o `node` no scratchpad da sessão. Saídas como saíram; as tabelas só as reorganizam.
status: vigente
substituida_por:
---

## §1 — O netfox no GitHub, em 04/10/2026

Comandos `gh api repos/foxssake/netfox/commits/main` e `gh api repos/foxssake/netfox/issues/N`, rodados à tarde, com a última conferência às 17:50 UTC:

- **A main:** `cf5189d18e98766022c8c1c5e637a6a30c4c3703 2026-09-26T13:54:04Z fix: Look up rapier physics states by cached tick tag (#647)`.
- **#554 [open]:** "NetworkSimulator performance suffers with multiple peers when latency is used", atualizada em 2026-01-20.
- **#613 [open]:** "RollbackSynchronizer prediction is broken", atualizada em 2026-06-15.
  - O relato diz que a fragmentação de pacotes quebrou a previsão do `RollbackSynchronizer`: "players jitter at the end of their movement (it looks as if prediction keeps moving the player forward even though the player has already released the button, which causes them to teleport back)".
  - A única resposta, do mantenedor: "I'll look into fixing this for the next release ( not sure when )".
- **#630 [open]:** "State is (re-)broadcasted for every resimulated tick, and bandwidth explodes when latency exceeds input_delay", atualizada em 2026-09-14.
- **#659 [open]:** "fix: Explicit types on values read from autoloads", atualizado em 2026-09-27.

## §2 — Os `.svg.import` reescritos pelo Godot 4.7.2

- Na sonda (`C:\Users\arthu\Projects\netfox-sonda`), o `git status` mostra os 9 `.svg.import` dos ícones do netfox modificados pelo import do 4.7.2.
- O `git diff` de um deles, `addons/netfox/icons/rollback-synchronizer.svg.import`, só acrescenta linhas:
  - `compress/uastc_level=0` e `compress/rdo_quality_loss=0.0`;
  - `process/channel_remap/red=0`, `process/channel_remap/green=1`, `process/channel_remap/blue=2` e `process/channel_remap/alpha=3`.
- No repositório do jogo, o implementer comparou o hash de cada arquivo copiado com o `git ls-tree -r cf5189d` do upstream:
  - 177 arquivos lá, 177 aqui;
  - 168 batem;
  - os 9 que diferem são esses `.svg.import`, cada um com as mesmas 6 linhas a mais;
  - nenhum falta, nenhum sobra.
- O reviewer da TASK-5 refez a comparação e chegou aos mesmos números.

## §3 — O modelo do parry por ping, da vitrine (versão 8 em diante)

**As premissas:**

- **A reação:** uma curva normal de 230 ± 40 ms, a do bot com reação de gente (F-029 §2).
- **A janela:** os 80 ms do parry viram 5 ticks a 60, 83 ms (DEC-0022).
- **A preparação do golpe leve:** 300 ms (`combate.md`).
- **O atraso de ver o outro a 60 ticks:** as medianas medidas com 2 clientes (F-026 §2), ligadas por retas: 21 ms no ping 0, 126 no 100 e 245 no 220; acima de 220, mais 1 ms por ms de ping.
- **A parte escondida da preparação, por regra:**
  - relógio do servidor: o atraso inteiro;
  - For Honor: o atraso menos o menor entre a metade do ping e 33 ms, o atraso de ataque do artigo da Ubisoft;
  - o nosso: o atraso do ping 0, mais o que passar do teto.
- **A chance de parry:** a probabilidade de a reação cair entre 217 e 300 ms, menos a parte escondida.

**A saída do `check.js`:**

| Ping dos dois | Atraso de ver o outro (ms) | Relógio do servidor | For Honor, 33 ms | O nosso, teto de 200 ms | O nosso, teto de 150 ms | Quem ataca descobre o resultado, o nosso (ms depois do ativo) | No relógio do servidor (ms) |
|---|---|---|---|---|---|---|---|
| 0 | 21 | 69 % | 69 % | 69 % | 69 % | 38 | 17 |
| 50 | 74 | 45 % | 64 % | 69 % | 69 % | 140 | 67 |
| 100 | 126 | 8 % | 28 % | 69 % | 69 % | 243 | 117 |
| 150 | 176 | 0 % | 3 % | 69 % | 65 % | 342 | 167 |
| 220 | 245 | 0 % | 0 % | 52 % | 12 % | 437 | 237 |
| 300 | 325 | 0 % | 0 % | 3 % | 0 % | 517 | 317 |

- A espera de quem ataca é o ping mais um tick e, no nosso, mais o atraso de ver o outro, limitado ao teto.
- É um modelo, não uma medição. No ping 0 ele dá 69 %, perto dos 72 % que o Arthur e o bot fizeram a 60 ticks (F-027 §3; F-029 §2). Com ping 100, no relógio do servidor, dá 8 %, contra os 13 % do Arthur.
