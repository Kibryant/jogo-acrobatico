---
id: F-073
titulo: "A sonda da rodada 1 do Desenho 6: o servidor do parry de brinquedo num contêiner Docker, aqui e na Edgegap em São Paulo; o tamanho, a partida, a CPU, a memória, a banda, o fechamento, o ping em dois horários e a rajada de trancos (09 e 10/10/2026)"
recebido_em: 2026-10-10
como: Medição feita pelo Claude neste PC e no servidor grátis da Edgegap, na sessão 10, com a sonda em `../servidor-sonda`, fora do repositório. Os números saem das linhas `METRIC` que a sonda imprime a cada segundo (`medir.py`), do `docker stats`, do `docker inspect`, do ping do Windows e do log do contêiner baixado do painel da Edgegap.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: a sonda é uma cópia do parry de brinquedo do Desenho 5 (F-061), exportada pela linha de comando do Godot 4.7.2 com um preset de servidor dedicado Linux e empacotada numa imagem `debian:trixie-slim` com o `tini` como PID 1. Fora do editor, o `NetworkSimulator` do netfox se desliga sozinho, e o servidor abre o ENet direto na porta 7777/UDP. O bot atacante e a janela do Arthur rodam neste PC, no Windows. Cite como F-073 §1 a §6.

## §1 — A build e a imagem

| O que | Valor |
|---|---|
| Exportação do servidor (CLI, release, pacote embutido) | 15 s, um arquivo de 73,8 MB |
| Construção da imagem (primeira vez) | 25 s |
| Tamanho da imagem | 222 MB (`sha256:6642b2ee…`) |
| Envio ao registro da Edgegap | 14 s |
| Docker | 29.8.2, com o WSL 2.7.13; o Docker Desktop 4.94.0 recebe 4 núcleos e 8 GB |

A build release do Godot só descarrega o stdout quando o buffer enche; a primeira medida de partida deu 26 s por isso. Com `application/run/flush_stdout_on_print=true` na cópia, o log sai na hora.

## §2 — O contêiner neste PC

| O que | Valor |
|---|---|
| Do `docker run` até `ROLE server` | 1,2 a 1,6 s em três partidas; 2,5 s com o build no mesmo comando |
| `docker stop` | 0,5 s, saída 143 (morto pelo SIGTERM; não fecha limpo) em quatro paradas |
| Partida jogada pelo Arthur contra o bot | 204 s com os dois lutadores |
| CPU do servidor, linha `METRIC` | mediana 21,5% de um núcleo, p90 26,6%, máximo 46,7% |
| Loop do tick no servidor | mediana 3,6 ms, p90 4,5 ms |
| `docker stats` | 18 a 34% de CPU e 43 MB de memória |
| Saída do servidor | mediana 16,4 kB/s para os dois clientes |
| Entrada do servidor | mediana 50,7 kB/s; cada cliente sobe uns 25,3 kB/s |
| Ping visto pelos clientes | mediana de 10 a 14 ms |
| Leitura do Arthur (certas/total) | leve 5/16, carregado 1/17, quebra 1/16, finta 14/14 |

Um teste sem contêiner, com o servidor e os dois clientes como processos do Windows, deu mediana de 41% de um núcleo ao servidor: os três processos dividiam o PC.

## §3 — O servidor na Edgegap

| O que | Valor |
|---|---|
| Local escolhido pela Edgegap | São Paulo, Brasil (`sao-paulo-edge-2026-g7-p5-e3-87ed1b`) |
| Recursos | 0,5 vCPU e 1 GiB, plano grátis, 60 minutos |
| Ping ICMP até o servidor (20 ecos) | mínimo 24, média 24, máximo 26 ms; nenhuma perda |
| Partida jogada pelo Arthur contra o bot | 262 s com os dois lutadores, 83 golpes julgados |
| CPU do servidor, linha `METRIC` | mediana 13,9% de um núcleo, p90 15,8%, máximo 17,6% |
| Loop do tick no servidor | mediana 2,3 ms, p90 2,6 ms, pior 13,7 ms |
| Saída do servidor | mediana 15,8 kB/s para os dois clientes, p90 23,5 |
| Entrada do servidor | mediana 50,7 kB/s |
| Ping no jogo, na janela do Arthur | mediana 37,5 ms, p90 38, máximo 44 |
| Ticks refeitos por segundo na janela | mediana 170, máximo 181, sem pico |
| Leitura do Arthur (certas/total) | leve 6/18, carregado 4/24, quebra 0/22, finta 16/19 |

## §4 — A rajada de trancos

O evento de tranco do lutador do Arthur disparou em rajada, com chaves diferentes: 4 vezes em 24 ticks em São Paulo (ticks 9349, 9357, 9365 e 9373) e 3 vezes em 13 ticks no teste local, a ping de quase zero (ticks 574, 577 e 587). Nenhuma chave de evento se repetiu nos 408 eventos da partida remota. Leitura do agente: a lâmina do bot acerta de novo enquanto encosta, e cada acerto recomeça o tranco; é regra da sonda, não rede, porque acontece sem rede.

## §5 — O ping desta casa, segundo horário

Sábado, 10/10/2026, às 9h47 de Brasília. Em ms, medianas.

| Destino | Ping (ICMP) | TCP, descontado o DNS |
|---|---|---|
| São Paulo, Vultr | 24 | 26 |
| São Paulo, Akamai | 24 | 25 |
| São Paulo, AWS | — | 25 |
| Santiago | 72 | — |
| Miami | 111 | 113 |
| Nova Jersey | 124 | — |
| Dallas | 140 | 142 |
| Virgínia, AWS | — | 155 |
| Los Angeles | 195 | — |
| Frankfurt | 217 | — |

Os números ficam a até 4 ms dos de sexta à tarde (F-070). O horário de pico da noite não foi medido.

## §6 — A conta do agente

- No data center, o servidor do 1v1 gastou 13,9% de um núcleo; aqui, 21,5%. A reserva de 0,375 núcleo por partida da conta de custo (F-066 §8 e §13) cobre os dois com folga.
- Os 43 MB de memória cabem 20 vezes no plano de 1 GB.
- O ping no jogo (37 ms) fica uns 13 ms acima do ICMP (24 ms), a mesma distância entre o ping e o atraso de visão da F-026 §2.
- A subida de cada cliente, uns 25 kB/s, é o dobro da F-034 (12,4 kB/s). A causa não foi medida; o input desta sonda carrega mais campos que o do Desenho 3.
