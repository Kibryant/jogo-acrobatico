---
id: F-028
titulo: O bot de reação fixa no parry de brinquedo — com o julgamento no relógio do servidor, reação de gente não defende a ping 100 nem a 220, a 30 ou a 60 ticks (sessão 4, 04/10/2026)
recebido_em: 2026-10-04
como: Execução do Claude Code na rodada 1 do Desenho 3 (TASK-5), com `run_parrier.sh` e `analyze_parrier.py` da sonda (`C:\Users\arthu\Projects\netfox-sonda\sonda`), numa cópia na porta 9800, sem ninguém jogando ao mesmo tempo. A tabela é a saída do script.
status: vigente
substituida_por:
---

## §1 — A montagem

- O parry de brinquedo da F-027, sem pessoa: um servidor dedicado, o bot atacante e um bot defensor, os três sem tela, com o ping do simulador do netfox.
- O defensor fica parado e aperta F uma vez por golpe, um tempo fixo depois de ver o atacante ficar amarelo na tela dele: 0, 150 ou 250 ms.
- O servidor julga no relógio dele, como o netfox faz sozinho. O F conta se cair até 80 ms antes de o golpe ficar ativo: 2 ticks a 30 e 5 ticks a 60 (DEC-0022).
- 10 golpes por corrida. Cada golpe conta uma vez, com o último veredito, porque o servidor corrige o veredito depois do rollback.

## §2 — A tabela

| Corrida | Golpes ao alcance | Parries | Taxa | Atraso dos F que perderam, mediana (ms) |
|---|---|---|---|---|
| t30-p100-r0 | 10 | 0 | 0 % | — (todos cedo demais: de 133 a 167 ms antes) |
| t30-p100-r150 | 10 | 0 | 0 % | 33 |
| t30-p100-r250 | 10 | 0 | 0 % | 167 |
| t30-p220-r0 | 10 | 10 | 100 % | — |
| t30-p220-r150 | 10 | 0 | 0 % | 200 |
| t30-p220-r250 | 10 | 0 | 0 % | 267 |
| t60-p100-r0 | 10 | 0 | 0 % | — (todos cedo demais) |
| t60-p100-r150 | 10 | 1 | 10 % | 50 |
| t60-p100-r250 | 10 | 0 | 0 % | 150 |
| t60-p220-r0 | 10 | 8 | 80 % | 17 |
| t60-p220-r150 | 10 | 0 | 0 % | 158 |
| t60-p220-r250 | 10 | 0 | 0 % | 250 |

"t30-p100-r150" quer dizer 30 ticks, ping 100 e reação de 150 ms. As margens "cedo demais" vêm do resumo da primeira corrida, `runs/parrier/summary.txt`.

## §3 — O que a tabela diz (leitura do Claude)

- **A conta que fecha os números:** no relógio do servidor, o defensor só acerta se reagir em uns 300 ms (a preparação) menos o atraso com que o golpe aparece na tela dele, com uma folga do tamanho da janela.
  - A ping 100, essa reação fica entre uns 100 e 160 ms: com 0 ms ele aperta cedo demais, e com 150 ms aperta tarde.
  - A ping 220, ela fica perto de 0 ms: só o bot de reflexo instantâneo defendeu.
- **Reação de gente, de 150 a 250 ms:** de 0 a 10% de parry, nos dois pings e nos dois tickrates. O tickrate quase não muda isso; o atraso da rede manda.
- **Junto com a F-027:** sem lag, a pessoa defendeu 48% a 30 ticks e 72% a 60, com um aperto por golpe. Com lag, só apertando sem parar.
