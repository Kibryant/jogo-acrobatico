---
id: F-029
titulo: Oito clientes com o clumsy e o bot com reação de gente — a 30 ticks o servidor fica no limite com 8 lutadores e lag; sem lag, a mesma pessoa defende 50% a 30 ticks e 72% a 60 (sessão 4, 04/10/2026)
recebido_em: 2026-10-04
como: Execução do Claude Code na rodada 1 do Desenho 3 (TASK-5), com a sonda de `C:\Users\arthu\Projects\netfox-sonda\sonda` (`run_net.sh`, `analyze_net.py`, `run_human_bot.sh`, `analyze_parrier.py`). O Arthur abriu o clumsy 0.3 como administrador e trocou o Lag de 50 para 110 a pedido do Claude (F-023 §2). As tabelas são a saída dos scripts.
status: vigente
substituida_por:
---

## §1 — Oito clientes

- **Os processos:** um servidor dedicado e 8 clientes com o bot que corre e pula, todos sem tela, nesta máquina. Os contornos das hipóteses 2 e 3 vão ligados, menos na linha "sem contornos".
- **O lag:**
  - "direct" é sem lag;
  - "clumsy" usa o preset "jogo sonda udp 9999", com Lag de 50 ms para o ping 100 e de 110 ms para o ping 220, aplicado uma vez por pacote no loopback.

| Corrida | Ping medido (ms) | Servidor: CPU de 1 núcleo (%) | Servidor: loop médio / pior (ms) | Servidor: ticks refeitos por s | Banda por cliente, servidor → cliente (kB/s) | Cliente: CPU (%) | Atraso de ponta a ponta, mediana / p90 (ms) | Cliente → servidor, mediana (ms) | Hipótese 1 na rede (pulos que batem) |
|---|---|---|---|---|---|---|---|---|---|
| t30-p0-c8-direct | 17 | 62,0 | 20,74 / 48,0 | 76 | 12,8 | 6,2 | 49 / 85 | 36 | 796 de 796 |
| t30-p0-c8-direct, sem contornos | 15 | 56,2 | 18,77 / 54,5 | 74 | 10,9 | 5,7 | 45 / 164 | 40 | 703 de 703 |
| t30-p100-c8-clumsy | 135 | 74,4 | 32,49 / 160,5 | 105 | 12,4 | 17,4 | 166 / 231 | 96 | 747 de 747 |
| t30-p220-c8-clumsy | 263 | 77,4 | 49,87 / 314,7 | 128 | 12,2 | 26,4 | 303 / 562 | 168 | 764 de 764 |
| t60-p0-c8-direct | 129 | 60,2 | 63,96 / 336,4 | 36 | 9,8 | 53,7 | 147 / 463 | 137 | 431 de 438 |

- **A primeira corrida de 30 ticks sem lag** deixou 3 clientes presos depois que o servidor saiu: a checagem de "acabou o tempo" morava no loop de ticks, que o netfox para quando o servidor sai. A sonda foi consertada e a corrida, refeita; a tabela traz a refeita.
- **A conferência entre as ferramentas,** com 2 clientes, 30 ticks e ping 100:
  - no clumsy: ping medido de 121 ms, servidor a 6,1% de um núcleo, atraso de 155 / 177 ms;
  - no simulador do netfox: 110 ms, 8,3% e 140 / 144 ms (F-026).

## §2 — O bot com reação de gente, sem lag

- **O bot defensor da F-028,** com a reação sorteada a cada golpe numa curva normal em torno de 230 ms, com 40 ms de variação.
- **A mesma sequência nos dois tickrates:** a semente fixa (7) dá os mesmos tempos, começando por 216, 221, 230, 262, 213, 161, 184, 252, 275 e 192 ms.

| Corrida | Golpes ao alcance | Parries | Taxa | Atraso dos F que perderam, mediana (ms) |
|---|---|---|---|---|
| 30 ticks, ping 0 | 36 | 18 | 50 % | 33 |
| 60 ticks, ping 0 | 36 | 26 | 72 % | 50 |

## §3 — O que as tabelas dizem (leitura do Claude)

- **8 lutadores a 30 ticks:** o servidor gasta 62% de um núcleo sem lag, 74% a ping 100 e 77% a ping 220. A ping 220, o loop médio leva 50 ms para um tick de 33, e o servidor fica para trás. O atraso de ver o outro chega a 562 ms no p90.
- **8 lutadores a 60 ticks** não cabem nesta máquina nem sem lag: o loop médio leva 64 ms para um tick de 17.
- **Os contornos das hipóteses 2 e 3** custam uns 6 pontos dos 62%. O resto é o netfox e a simulação básica.
- **Sem lag, o tickrate muda o parry:** 50% contra 72%, com a mesma sequência de reações. É quase o resultado do Arthur (48% contra 72%; F-027), então a diferença que ele sentiu não veio do treino.

## §4 — Limites

- Os 9 processos e o clumsy dividem os 4 núcleos do 3200G (F-004). Num servidor só para ele, o servidor gastaria menos; a tendência continua valendo.
- Clientes sem tela; sem jitter; uma máquina só.
- Os processos caem com falha de segmentação ao fechar, depois de gravar os logs (F-026 §4).
