---
id: F-034
titulo: Os números dos clientes na medição com rede — a CPU por tick e a banda de subida, tirados dos mesmos logs da rodada 1, e as corridas de 8 clientes a 60 ticks que faltam (sessão 5, 04/10/2026)
recebido_em: 2026-10-04
como: Execução do Claude Code na sessão 5, para fechar o critério 5 da TASK-5. O script `client_extra.py`, em `C:\Users\arthu\Projects\netfox-sonda\sonda`, reusa o `run_summary` do `analyze_net.py` sobre os mesmos logs de `runs/net` das F-026 e F-029, e soma o que aquelas tabelas não mostravam. A tabela é a saída dele, sem edição.
status: vigente
substituida_por:
---

## §1 — O que faltava

- O critério 5 da TASK-5 pede a CPU por tick do servidor e dos clientes, a banda por cliente e o atraso de ponta a ponta, com 2 e com 8 clientes.
- As tabelas das F-026 e F-029 traziam a CPU dos clientes em porcentagem de um núcleo e a banda de descida, do servidor para cada cliente. Faltavam o loop de ticks dos clientes, em ms, e a banda de subida, de cada cliente para o servidor.
- Os logs são os mesmos: cada processo anotou por segundo o `loop_ms_avg`, o `loop_ms_max`, os ticks refeitos e os bytes do ENet enviados e recebidos (F-026 §1). O resumo ignora os 6 primeiros segundos, como antes.

## §2 — A tabela

| Corrida | Clientes | Cliente: loop médio / pior (ms) | Cliente: CPU de 1 núcleo (%) | Cliente: ticks refeitos por s | Subida por cliente, cliente → servidor (kB/s) | Descida por cliente, servidor → cliente (kB/s) | Servidor: recebido por cliente (kB/s) |
|---|---|---|---|---|---|---|---|
| t30-p0-c2-sim | 2 | 1,18 / 5,0 | 3,5 | 36 | 6,28 | 3,7 | 6,06 |
| t30-p0-c8-direct | 8 | 2,07 / 12,9 | 6,2 | 51 | 6,28 | 13,6 | 5,94 |
| t30-p0-c8-direct-nocontours | 8 | 1,92 / 13,0 | 5,7 | 50 | 6,28 | 12,8 | 5,45 |
| t30-p100-c2-clumsy | 2 | 2,04 / 3,2 | 6,1 | 128 | 6,25 | 3,7 | 4,21 |
| t30-p100-c2-sim | 2 | 1,78 / 4,0 | 5,3 | 117 | 6,27 | 3,8 | 6,08 |
| t30-p100-c8-clumsy | 8 | 5,84 / 70,1 | 17,4 | 160 | 6,25 | 12,7 | 5,98 |
| t30-p220-c2-sim | 2 | 2,45 / 8,0 | 7,4 | 192 | 6,25 | 3,6 | 6,11 |
| t30-p220-c8-clumsy | 8 | 8,85 / 69,7 | 26,4 | 273 | 6,24 | 12,8 | 6,07 |
| t60-p0-c2-sim | 2 | 1,06 / 2,0 | 6,4 | 75 | 12,40 | 7,6 | 11,99 |
| t60-p0-c8-direct | 8 | 16,97 / 144,6 | 53,7 | 357 | 12,41 | 10,4 | 11,65 |
| t60-p100-c2-sim | 2 | 2,45 / 4,5 | 14,7 | 398 | 12,39 | 7,0 | 12,08 |
| t60-p220-c2-sim | 2 | 3,92 / 7,6 | 23,5 | 737 | 12,38 | 6,9 | 12,13 |

## §3 — O que a tabela diz (leitura do Claude)

- **A subida não depende do ping nem do número de clientes.** Cada cliente sobe uns 6,3 kB/s a 30 ticks e 12,4 a 60. Cada pacote de input repete os 3 últimos ticks (`input_redundancy`), um pacote por tick. Com 2 clientes, a subida passa da descida.
- **O cliente refaz mais ticks que o servidor.** A 60 ticks e ping 220, ele refaz 737 por segundo, uns 12 por tick, contra 530 do servidor (F-026 §2). O estado do próprio lutador só volta confirmado depois de uma ida e volta inteira.
- **A 60 ticks, com 2 clientes, o cliente gasta de 1 a 4 ms por loop:** 1,06 sem lag, 2,45 a ping 100 e 3,92 a ping 220. Cabe com folga no tick de 16,7 ms.
- **Com 8 clientes a 60 ticks, sem lag, o cliente já gasta 17 ms por loop,** com pior caso de 145 ms. Os 9 processos dividem os 4 núcleos do 3200G (F-029 §4).

## §4 — As corridas que faltam

- Com 8 clientes a 60 ticks, só existe a corrida sem lag (F-029 §1). Faltam a de ping 100 e a de ping 220.
- Elas não rodaram porque, já sem lag, o servidor fica para trás: o loop médio leva 64 ms num tick de 17 ms (F-029 §3). O lag só aumentaria os ticks refeitos.
- A medição que falta volta com a Q-09, numa máquina em que o servidor rode sozinho.
