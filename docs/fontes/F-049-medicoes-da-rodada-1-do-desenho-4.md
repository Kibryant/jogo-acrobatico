---
id: F-049
titulo: As medições da rodada 1 do Desenho 4 — o portão passo a passo antes e depois, o pre-commit, as sondas dos furos, o runner do gdUnit4 e o custo dos hooks (sessão 6, 04/10/2026)
recebido_em: 2026-10-07
como: Medido pelo Claude e pelo implementer na sessão 6 (04/10/2026), neste PC, no repositório e num clone fora dele (`../esteira-sonda`); os tempos de commit do §2 vão até 07/10. Números como saíram dos logs da conversa, conferidos de novo contra o registro bruto das sessões antes de virar fonte. Guardados como fonte na sessão 7, quando o reviewer do fechamento viu que eles só existiam nas notas da TASK-6 e na vitrine.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: as rodadas 2 e 3 ganharam fontes de medição (F-042 e F-045); a rodada 1, não. Esta fonte junta o que foi medido na rodada 1 e no seu começo. O contexto da F-039 resume os mesmos resultados, sem os tempos de cada passo.

## §1 — O portão antes da rodada 1

Cada script rodado em separado, no repositório, com o projeto já importado:

| Passo | Tempo |
|---|---|
| Formato e lint (`check_format.sh`) | 0,94 s |
| Pureza (`check_core_purity.sh`) | 0,34 s |
| Travas (`check_test_locks.sh`) | 0,14 s |
| Import | 17,67 s |
| Testes (`run_tests.sh`) | 7,59 s; os 17 testes rodaram em 0,485 s |
| O portão inteiro (`gate.sh`) | 28,27 s |

O log dos testes tinha 2 linhas `ERROR:`, as do truque `--remote-debug tcp://127.0.0.1:0`: "The remote port number must be between 1 and 65535 (inclusive)." e "Remote Debugger: Unable to connect to host '127.0.0.1:0'."

## §2 — O pre-commit

- **Medido em separado:** o `gitleaks git --pre-commit --staged` levou 1,71 s; o formatador, num arquivo, 0,06 s; o `lefthook run pre-commit`, sem nada no stage, 0,45 s.
- **Nos commits de verdade,** o resumo do lefthook marcou o total e, entre parênteses, a parte do gitleaks (`secrets`):
  - 2,93 s (2,80 s) no `81cd29d` (04/10);
  - 1,51 s (1,36 s) no `963bdca` (04/10);
  - 0,91 s (0,79 s) no `0d96dfb` (04/10);
  - 0,81 s (0,76 s) no `abb30d2` e 0,81 s (0,73 s) no `62bd174` (07/10).

## §3 — As sondas do antes, no clone

- **Pureza:**
  - O `var c := "#ff0000"; var t := Time.get_ticks_msec()` em `core/` deu `core/ is pure (4 files)`, com saída 0. Um `Time.get_ticks_msec()` depois de uma string de três aspas com `#` também passou.
  - O formatador quebra `a; b` em duas linhas. Por isso o furo real é numa instrução só: `var label := "#%d" % randi()` também deu `core/ is pure`, com saída 0.
- **Compilação:** com `var count = 5` e `body.velocity.length()` (`body: Object`) em `core/`, num script que nenhum teste carrega, o portão inteiro saiu verde, com saída 0, em 41,0 s, porque o clone importou do zero.
- **O jeito de compilar tudo:** uma execução só do Godot carregou os 6 scripts em 4,06 s de relógio, sendo 1.842 ms dentro do Godot, com os autoloads do netfox subindo junto. Ela pegou o `var count = 5`, o `velocity` num `Object` e o `length()` num `Variant`, cada um com arquivo e linha. Compilado a partir do texto, pegou também um `var n = 3` num arquivo fora do projeto.

## §4 — O runner do gdUnit4, com e sem o truque do depurador

Rodado no clone, sempre com `-c`:

| Caso | Com `-d --remote-debug` | Sem `-d` |
|---|---|---|
| Dois testes falhando | saída 100 em 8,5 s; as duas falhas e as 2 linhas `ERROR:` | saída 100 em 7,7 s; as duas falhas e nenhuma linha `ERROR:` |
| Arquivo de teste que não compila | saída 105 em 7,1 s | saída 105 em 7,1 s, sem prompt `debug>` |
| Chamada num `null` dentro de um teste | o teste falha, conta como erro, saída 100 em 7,0 s | o mesmo, saída 100 em 8,6 s |
| `push_error` num teste que passa | o teste passa | o teste passa |

## §5 — Depois dos consertos

- **O portão, no repositório:** verde em 31,1 s, sem nenhuma linha `ERROR:`, `SCRIPT ERROR:` ou `USER ERROR:` no log inteiro.
- **No clone, com os consertos:**
  - o `"#%d" % randi()` foi barrado na linha 5, com saída 1;
  - o `var count = 5` derrubou o portão no passo "compilar tudo", com o arquivo e a linha;
  - os dois testes falhando apareceram juntos, com saída 100 em 8,7 s.
- **As checagens estragadas de propósito:** com o corte antigo do `#` de volta na pureza, 5 canários acusaram "expected flagged, got clean". Com `untyped_declaration=1` no `project.godot`, o canário `bad_untyped.gd` acusou "expected rejected, got compiled". As duas saíram com código 1.
- **O portão passo a passo, em duas rodadas:**

| Passo | Rodada A | Rodada B |
|---|---|---|
| Formato e lint | 0,65 s | 0,58 s |
| Pureza | 0,45 s | 0,39 s |
| Travas | 0,15 s | 0,23 s |
| Import | 15,76 s | 15,66 s |
| Compilar tudo | 4,61 s | 3,86 s |
| Testes | 8,13 s | 9,69 s |

  O portão inteiro levou 31,3 s.
- **Nas três rodadas do implementer:** formato e lint de 0,3 a 1,1 s; pureza de 0,2 a 0,5 s; travas de 0,1 a 0,2 s; import de 9,7 a 14,8 s; compilar tudo de 3,4 a 3,8 s; testes de 8,0 a 9,8 s; o portão inteiro de 21 a 28 s.

## §6 — O custo dos hooks

Medido pelo implementer, com o JSON do hook dado na entrada padrão. Quase tudo é o Git Bash subindo:
- **a trava:** 0,2 a 0,4 s sem nenhuma trava; 0,4 a 0,6 s com uma trava, porque aí o Python sobe;
- **o formatador:** 0,3 s num arquivo que não é `.gd`; 0,5 a 0,8 s num `.gd`.
