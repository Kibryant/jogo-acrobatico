---
id: F-026
titulo: A medição com rede — servidor dedicado e 2 clientes no simulador do netfox, a 30 e a 60 ticks, com ping 0, 100 e 220 (sessão 4, 03/10/2026)
recebido_em: 2026-10-03
como: Execução do Claude Code na rodada 1 do Desenho 3 (TASK-5), com a sonda de `C:\Users\arthu\Projects\netfox-sonda\sonda` (F-023 §3; F-025 §1). A tabela é a saída do `analyze_net.py` sobre os logs, sem edição.
status: vigente
substituida_por:
---

## §1 — A montagem

- **Os processos:** um servidor dedicado sem tela, sem lutador próprio, e 2 clientes sem tela, cada um com um bot que corre de um lado para o outro e pula a cada 2 s. Os três rodam nesta máquina, limitados a 144 fps.
- **O lag:** o `NetworkSimulator` do netfox atrasa cada direção em ping/2, sem jitter e sem perda.
- **Os contornos ligados:** o do transform (hipótese 2) e a variante D (hipótese 3), para o custo medido ser o do jogo (F-025).
- **Duração:** 34 s no servidor e 30 s nos clientes; o resumo ignora os 6 primeiros segundos.
- **O que cada processo anota por segundo:**
  - o tempo do loop de ticks do netfox, do `before_tick_loop` ao `after_tick_loop`, com o rollback dentro;
  - a CPU de um núcleo, que é esse tempo dividido pelo segundo;
  - os ticks refeitos, contados no `NetworkRollback.on_process_tick`;
  - os bytes do ENet (`HOST_TOTAL_SENT_DATA` e `HOST_TOTAL_RECEIVED_DATA`);
  - o RTT do `NetworkTimeSynchronizer`.
- **O atraso de ponta a ponta:**
  - o bot anota o aperto do pulo com o tick e o relógio sincronizado do netfox (`NetworkTimeSynchronizer.get_time()`);
  - quem observa anota quando o estado do outro lutador vira AIR, com o tick lido em `state.mode_since` e o mesmo relógio;
  - o atraso é a diferença. Ele vale para o estado, antes da suavização da tela.

## §2 — A tabela

| Corrida | Ping medido (ms) | Servidor: CPU de 1 núcleo (%) | Servidor: loop médio / pior (ms) | Servidor: ticks refeitos por s | Banda por cliente, servidor → cliente (kB/s) | Cliente: CPU (%) | Atraso de ponta a ponta, mediana / p90 (ms) | Cliente → servidor, mediana (ms) | Hipótese 1 na rede (pulos que batem) |
|---|---|---|---|---|---|---|---|---|---|
| t30-p0-c2-sim | 7 | 7,2 | 2,41 / 6,6 | 69 | 3,6 | 3,5 | 38 / 43 | 8 | 59 de 59 |
| t30-p100-c2-sim | 110 | 8,3 | 2,76 / 5,3 | 100 | 3,6 | 5,3 | 140 / 144 | 64 | 58 de 58 |
| t30-p220-c2-sim | 232 | 8,5 | 2,84 / 7,3 | 146 | 3,5 | 7,4 | 240 / 271 | 123 | 56 de 56 |
| t60-p0-c2-sim | 8 | 14,8 | 2,46 / 4,9 | 148 | 7,3 | 6,4 | 21 / 28 | 9 | 60 de 60 |
| t60-p100-c2-sim | 111 | 18,2 | 3,03 / 5,5 | 305 | 6,8 | 14,7 | 126 / 135 | 61 | 58 de 58 |
| t60-p220-c2-sim | 230 | 23,2 | 3,87 / 7,1 | 530 | 6,9 | 23,5 | 245 / 330 | 125 | 58 de 58 |

## §3 — O que a tabela diz (leitura do Claude)

- **Hipótese 1 pela rede:** em 349 de 349 pulos, o tick lido no estado aninhado de quem observa bateu com o tick do aperto. O caminho `:state:mode_since` vai e volta pela rede.
- **O modelo da vitrine (TASK-5) acertou a ordem de grandeza:** a 30 ticks e ping 100, ele previa uns 150 ms no estado, e a medição deu 140.
- **60 ticks contra 30, no atraso de ver o outro:**
  - a ping 0, 21 contra 38 ms;
  - a ping 100, 126 contra 140 ms;
  - a ping 220, 245 contra 240 ms, com a cauda maior a 60 (p90 de 330 contra 271).
- **60 ticks contra 30, no custo:**
  - os ticks refeitos no servidor crescem 2,1, 3 e 3,6 vezes, perto da conta do quadrado do tickrate;
  - a CPU do servidor cresce 2 a 2,7 vezes, e a do cliente 1,8 a 3,2;
  - a banda dobra.
- **O que não apareceu:** a explosão de banda do #630. Com 2 lutadores e o diff de estado ligado, a banda ficou estável.

## §4 — Limites

- Os três processos dividem os 4 núcleos do 3200G (F-004). A CPU de cada um é medida no loop de ticks do netfox, não no sistema.
- Sem tela: o `TickInterpolator` fica desligado sem tela, e a suavização soma até 1 tick ao atraso que a pessoa vê.
- O simulador não tem jitter. O ping medido fica 7 a 10 ms acima do configurado.
- Só 2 lutadores. O custo do servidor cresce com o número de lutadores, e a medição com 8 clientes é outra corrida (TASK-5, critério 5).
- 12 dos 18 processos caíram com falha de segmentação ao fechar, depois de gravar o log completo. Os números não foram afetados, mas o jogo vai precisar de um encerramento limpo.
