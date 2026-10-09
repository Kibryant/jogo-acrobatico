---
id: F-070
titulo: "O ping e a conexão desta casa: uns 25 ms até São Paulo, de 113 a 195 ms até os EUA e 220 até Frankfurt; sem IPv6 público e com CGNAT provável (09/10/2026)"
recebido_em: 2026-10-09
como: Medição feita pelo Claude neste PC (Windows 11, Git Bash), na sessão 10, ao deixar a TASK-8 Ready, numa sexta-feira à tarde, às 15h09 e às 15h17 de Brasília (18h09 e 18h17 UTC). Três scripts no scratchpad da sessão, fora do repositório. O primeiro rodou o ping do Windows, com 20 ecos por host. O segundo cronometrou o aperto de mão TCP com o curl, descontado o DNS, em 15 conexões por host. O terceiro leu os primeiros saltos do tracert e só imprimiu vereditos, nunca um endereço.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: o estudo diz que, do Brasil, um servidor em São Paulo fica a 10 a 35 ms e um nos EUA a 110 a 160 ms (F-001). Esta medição põe a casa do Arthur nessa conta. Os hosts são os endpoints públicos de teste dos provedores: o looking glass da Vultr, o speedtest da Akamai (Linode) e o endpoint regional da API da AWS. A AWS não responde ao ping (ICMP bloqueado) e por isso só tem a medida por TCP. A medição é de uma tarde só; o horário de pico da noite pode dar outro número. Cite como F-070 §1 a §5.

## §1 — O ping (ICMP), 20 ecos por host, 18h09 UTC

Tempo de ida e volta, em ms.

| Região | Provedor e local | Host | Mínimo | Mediana | Média | Máximo |
|---|---|---|---|---|---|---|
| Brasil | Vultr, São Paulo | `sao-br-ping.vultr.com` | 24 | 26 | 26,9 | 38 |
| Brasil | Akamai, São Paulo | `speedtest.sao-paulo.linode.com` | 24 | 24 | 26,6 | 43 |
| Brasil | AWS `sa-east-1`, São Paulo | `ec2.sa-east-1.amazonaws.com` | — | — | — | — |
| Chile | Vultr, Santiago | `scl-cl-ping.vultr.com` | 71 | 72 | 73,5 | 89 |
| EUA | Vultr, Miami | `fl-us-ping.vultr.com` | 111 | 113 | 115,2 | 133 |
| EUA | Vultr, Nova Jersey | `nj-us-ping.vultr.com` | 123 | 126 | 128,7 | 138 |
| EUA | Vultr, Dallas | `tx-us-ping.vultr.com` | 139 | 143 | 144,2 | 153 |
| EUA | AWS `us-east-1`, Virgínia | `ec2.us-east-1.amazonaws.com` | — | — | — | — |
| EUA | Vultr, Los Angeles | `lax-ca-us-ping.vultr.com` | 194 | 195 | 198,7 | 224 |
| Alemanha | Vultr, Frankfurt | `fra-de-ping.vultr.com` | 217 | 220 | 220,4 | 226 |

Nenhum eco se perdeu nos hosts que respondem. Os dois da AWS não responderam a nenhum dos 20.

## §2 — O aperto de mão TCP, descontado o DNS, 15 conexões por host, 18h17 UTC

O tempo entre o fim da consulta de DNS e a conexão TCP aberta na porta 443 é uma ida e volta. Em ms.

| Região | Provedor e local | Conexões | Mínimo | Mediana | Média | Máximo |
|---|---|---|---|---|---|---|
| Brasil | Vultr, São Paulo | 14 | 25 | 28 | 28,5 | 35 |
| Brasil | AWS `sa-east-1`, São Paulo | 15 | 24 | 28 | 29,0 | 40 |
| Brasil | Akamai, São Paulo | 15 | 24 | 28 | 28,5 | 36 |
| EUA | Vultr, Miami | 15 | 112 | 118 | 118,9 | 134 |
| EUA | AWS `us-east-1`, Virgínia | 15 | 154 | 159 | 160,5 | 171 |
| EUA | Vultr, Dallas | 15 | 143 | 148 | 150,8 | 165 |

O TCP fica de 2 a 5 ms acima do ping nos mesmos hosts.

## §3 — A primeira medida por TCP, descartada

A primeira rodada, junto com a do §1, usou o `time_connect` do curl sem descontar o DNS. Saiu inflada e com muita variação: mediana de 112 ms na Vultr de São Paulo, contra 26 no ping. O `time_connect` inclui a consulta de DNS. Ela não entra em nenhuma conta; a do §2 a substitui.

## §4 — A conexão

| Pergunta | Resposta |
|---|---|
| Há IPv6 público? | Não: o pedido por IPv6 a um serviço externo não respondeu |
| Um IPv4 público aparece do lado de fora? | Sim |
| Saltos lidos até `1.1.1.1` (os 6 primeiros) | 6 |
| Saltos na faixa `100.64.0.0/10`, a do CGNAT (RFC 6598) | 1 |
| Saltos em faixas privadas (`10/8`, `172.16/12`, `192.168/16`) | 3 |
| Veredito do script | CGNAT provável |

Leitura do agente: com CGNAT, o IPv4 público que aparece lá fora é dividido pela operadora entre vários clientes. Um amigo não consegue abrir conexão direto com um servidor neste PC pelo IPv4, nem com redirecionamento de porta no roteador. Os endereços não foram impressos nem guardados.

## §5 — A conta em ticks, pelo agente

A 60 ticks por segundo, um tick dura 16,7 ms (DEC-0024). Com as medianas do §1 e do §2:

| Destino | Ida e volta | Em ticks |
|---|---|---|
| São Paulo | 24 a 28 ms | 1,4 a 1,7 |
| Santiago | 72 ms | 4,3 |
| Miami | 113 a 118 ms | 6,8 a 7,1 |
| Nova Jersey | 126 ms | 7,5 |
| Dallas | 143 a 148 ms | 8,6 a 8,9 |
| Virgínia (AWS) | 159 ms | 9,5 |
| Los Angeles | 195 ms | 11,7 |
| Frankfurt | 220 ms | 13,2 |

As medidas de São Paulo (24 a 28 ms) caem na faixa do estudo (10 a 35 ms). As da costa leste e do centro dos EUA (113 a 159 ms) também caem (110 a 160 ms). Los Angeles e Frankfurt ficam acima dela (F-001).
