---
id: F-066
titulo: "Pesquisa: a hospedagem — a Edgegap no Brasil e o plano grátis, as VPS em São Paulo em reais, as formas grátis antes de pagar, o Godot em Docker, os servidores da comunidade e a lista de salas, a latência e a tabela de custo por faixa de jogadores; veredictos do verificador (09/10/2026)"
recebido_em: 2026-10-09
como: Relatório final de um agente de pesquisa (Opus 5.5, esforço alto), um dos quatro pesquisadores que rodaram em paralelo ao deixar a TASK-8 Ready (sessão 10, 09/10/2026), com o modelo e o esforço da tabela que o Arthur aprovou (F-071 §2). O parágrafo de abertura e os §1 a §8 respondem às oito perguntas e estão como chegaram, só com os títulos trocados para "§n —". O §9 é o resumo, o §10 o que o agente não confirmou e o §11 as afirmações importantes. O §12 traz o veredicto do verificador adversarial (Fable 5.1, esforço xhigh), que abriu a fonte de cada afirmação e citou a frase. O §13 é a conferência do orquestrador: o preço da Vultr em São Paulo, que o verificador refutou (X-12), lido na API pública, e a conta do §8 refeita com ele.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: o pedido ao pesquisador trazia as medições do Desenho 3 (um 1v1 a 60 ticks custou de 14,8 a 23,2% de um núcleo do Ryzen 3 PRO 3200G e uns 7 kB/s de descida por cliente; `rede.md` §10) e as afirmações do estudo de setembro a conferir (F-001). Ele corrige duas delas: o plano grátis da Oracle não acabou em 15/06/2026, só foi cortado (§3), e a "relay grátis até 50 jogadores" da Edgegap só serve para jogo P2P (§2), o que responde à Q-05. A tabela do §8 é conta do agente, rotulada como inferência, com o dólar a R$ 5,16 (PTAX de 09/10/2026 com o IOF de 3,5%) e tudo ligado 24 horas no pico. "Não confirmado" quer dizer que o agente não abriu a fonte primária. O que vira regra sai da conversa da TASK-8, não daqui. Cite como F-066 §1 a §13; não há numeração aninhada.

O Arthur pode testar e rodar a fase 3 com custo próximo de zero. Duas afirmações do estudo de setembro estão erradas e precisam de correção: a Oracle não acabou com o servidor grátis, só cortou pela metade (§3), e a Edgegap ligada 24 horas por dia custa umas 7 vezes mais que uma VPS em São Paulo (§8).

## §1 — Edgegap no Brasil

- Fato: um post do blog da Edgegap diz "Including Brazil, with new locations in Sao Paulo, alongside Chile and new locations in populous Santiago." O texto traz a data "2/13/24" (https://edgegap.com/blog-en/world-s-largest-disitrbuted-network-edgegap-expands-to-550-locations-worldwide, acessado em 09/10/2026).
- Fato: a documentação atual fala em "615+ physical locations and 17+ data center providers", mas não lista cidades. Ela diz que os locais disponíveis aparecem num mapa do painel, que exige conta (https://docs.edgegap.com/llms-full.txt, acessado em 09/10/2026).
- Fato: o local do servidor é escolhido pelo "Server Score". O jogo manda os IPs públicos ou as coordenadas dos jogadores, e "Edgegap deploys in the best possible location with available capacity." Fixar uma região só é possível pelo Server Browser, e a documentação não recomenda isso para partidas (https://docs.edgegap.com/learn/orchestration/deployments, acessado em 09/10/2026).
- Fato: as "ping beacons" servem para medir a latência real. A documentação recomenda limites abaixo de 200 ms por região e abaixo de 150 ms por hub (https://docs.edgegap.com/learn/orchestration/ping-beacons, acessado em 09/10/2026).
- Inferência: num 1v1 entre dois jogadores no Brasil, o servidor provavelmente cairia em São Paulo. Isso não é garantido: sem capacidade livre lá, ele pode ir para Miami. Não há como travar a partida em São Paulo.

## §2 — Preços e plano grátis da Edgegap

- Fato: no Edge Cloud, o preço é "$0.00115 / vCPU / MINUTE" e "Billed by the Minute, Only on Usage". O egress custa "$0.10/GB of monthly Egress". Cada servidor vai de 0,25 a 4 vCPU. Para ativar, basta cadastrar um cartão (https://edgegap.com/pricing, acessado em 09/10/2026).
- Fato: o plano grátis custa "$0 • No credit card" e dá 1,5 vCPU e 3 GB, 1 app e 2 versões. A documentação acrescenta: "Free Tier deployments have a 60 minute time limit" e "You may only run 1 concurrent deployment in Free Tier." (pricing e llms-full.txt, acessados em 09/10/2026).
- Fato: o Private Fleet (máquina física reservada, de 16 vCPU com 15 utilizáveis) custa US$ 280 por mês com contrato de 12 meses, ou US$ 350 por mês sem ele. Matchmaking e Server Browser no plano Hobbyist custam cerca de US$ 22 por mês (pricing, acessado em 09/10/2026).
- Fato: a "relay grátis até 50 jogadores" existe, mas é só para relay. O texto exato é "Up to 50 CCU - 160 GB Egress included", e a página avisa: "Relays are not authoritative game servers. They do not include compute." (pricing, acessado em 09/10/2026).
- Fato: segundo a documentação, as relays servem para jogos P2P, em que "one player must act as the game server since there is no dedicated server" (https://docs.edgegap.com/learn/distributed-relay, acessado em 09/10/2026).
- Inferência: para o nosso servidor dedicado com autoridade no servidor, a relay não serve para nada. O cliente se conecta direto em `*.pr.edgegap.net:porta`.
- Fato: o plugin para Godot "supports Godot versions 4.3.x and newer" e é MIT. O repositório não tem nenhuma release publicada (https://github.com/edgegap/edgegap-godot-plugin, acessado em 09/10/2026).
- Inferência: não há confirmação de teste com o Godot 4.7. Como o plugin só gera o build Linux e a imagem Docker, o risco é baixo.
- Fato: o Hathora fechou em 05/05/2026 e o Unity Multiplay foi encerrado em 31/03/2026. A fonte do Hathora é um fornecedor concorrente, a Gameye (https://gameye.com/blog/game-server-shake-up-2026). A do Multiplay é o aviso da própria Unity (https://status.unity.com/info_notices/362941). Ambas acessadas em 09/10/2026.

## §3 — VPS em São Paulo

- Fato, Vultr: a API pública lista a região "sao" (São Paulo, BR) com a opção `ddos_protection` (https://api.vultr.com/v2/regions, acessado em 09/10/2026). Os planos de vCPU compartilhada mais baratos em São Paulo são:

  | Plano | vCPU | RAM | Tráfego incluído | Preço |
  |---|---|---|---|---|
  | vc2-1c-1gb | 1 | 1 GB | 1 TB | US$ 5 |
  | vc2-2c-2gb | 2 | 2 GB | 3 TB | US$ 15 |
  | vc2-2c-4gb | 2 | 4 GB | 3 TB | US$ 20 |
  | voc (vCPU dedicada) | 1 | 2 GB | — | a partir de US$ 28 |

  (https://api.vultr.com/v2/plans, acessado em 09/10/2026)
- Fato: o excedente de tráfego da Vultr custa US$ 0,01/GB (https://docs.vultr.com/support/platform/billing/what-is-the-bandwidth-overage-rate, atualizado em 16/12/2025). As páginas de preço da Vultr bloquearam o acesso (403); só a API respondeu.
- Fato, Akamai/Linode: a região br-gru (São Paulo) tem preço próprio. O Nanode 1 GB custa US$ 7 (US$ 5 na base), o plano de 2 GB custa US$ 16,80, o de 4 GB e 2 vCPU custa US$ 33,60, e o dedicado de 2 vCPU custa US$ 50,40. O excedente de tráfego em br-gru é de US$ 0,007/GB (https://api.linode.com/v4/linode/types e /v4/network-transfer/prices, acessados em 09/10/2026).
- Fato, AWS EC2 sa-east-1, preço por hora sob demanda (Linux): t4g.micro US$ 0,0134; t4g.small US$ 0,0268; t3.micro US$ 0,0168; c7g.medium US$ 0,0555. Fonte: o JSON que alimenta a página de preços da AWS (https://b0.p.awsstatic.com/pricing/2.0/meteredUnitMaps/ec2/USD/current/ec2-ondemand-without-sec-sel/South%20America%20(Sao%20Paulo)/Linux/index.json, acessado em 09/10/2026).
- Fato: a AWS cobra US$ 0,005 por hora por IPv4 público (https://aws.amazon.com/vpc/pricing/, acessado em 09/10/2026).
- Fato: a AWS dá 100 GB por mês de tráfego de saída grátis, somando todas as regiões (https://aws.amazon.com/ec2/pricing/on-demand/, acessado em 09/10/2026).
- Fato: o Lightsail com IPv4 custa US$ 5 (0,5 GB), US$ 7 (1 GB) e US$ 12 (2 GB). Em São Paulo, a franquia de tráfego cai pela metade (https://aws.amazon.com/lightsail/pricing/, acessado em 09/10/2026).
- Inferência: t4g, Lightsail e Azure B são máquinas "burstable", com CPU base baixa. Não servem para rodar 60 ticks sem parar.
- Fato, Google Cloud southamerica-east1, preço por mês: e2-micro 9,71; e2-small 19,41; e2-medium 38,83; t2d-standard-1 48,95. É um site de terceiros e a moeda não aparece, provavelmente USD (https://gcloud-compute.com/southamerica-east1.html, acessado em 09/10/2026).
- Fato, Azure Brazil South, preço por hora em USD: B2ats_v2 US$ 0,0151 e B1s US$ 0,0168 (https://prices.azure.com/api/retail/prices, acessado em 09/10/2026).
- Fato, Oracle: tem as regiões sa-saopaulo-1 e sa-vinhedo-1 (https://docs.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm, acessado em 09/10/2026).
- Fato: o plano grátis da Oracle não acabou em 15/06/2026; o limite do Ampere A1 caiu pela metade. A documentação diz "For Always Free tenancies, this is equivalent to 2 OCPUs and 12 GB of memory", inclui 10 TB por mês de saída e exige criar as máquinas na região principal da conta (https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm, acessado em 09/10/2026). Antes eram 4 OCPU e 24 GB, e "The change took effect on June 15, 2026." (https://www.infoq.com/news/2026/07/oracle-cloud-free-tier-limits/, 03/07/2026).
- Fato, Magalu Cloud: o plano BV de 1 vCPU e 1 GB custa R$ 34,99 por mês, e o de 2 vCPU e 2 GB custa R$ 59,99, nas regiões se1 e ne1. O tráfego de saída por IP público aparece a R$ 0,00/GiB, mas há um outro item "Internet outbound data transfer" a 0,13/GiB, que é ambíguo (https://api.magalu.cloud/sku/v0/skus, a API da calculadora de https://magalu.cloud/precos/, acessado em 09/10/2026).
- Fato, Hostinger: tem data center em São Paulo (https://www.hostinger.com/br/tutoriais/novo-data-center-no-brasil/). O KVM 1 (1 vCPU, 4 GB, 4 TB) sai por R$ 29,99 por mês, pago de uma vez por 2 anos, e renova a R$ 59,99. O plano tem filtragem DDoS da Wanguard (https://www.hostinger.com/br/servidor-vps). Ambos acessados em 09/10/2026.
- Fato, Locaweb: a VPS de 2 vCPU e 1 GB custa R$ 15,90, e a de 2 vCPU e 2 GB custa R$ 23,90 por mês, com contrato de 24 meses e tráfego ilimitado. A página só diz "infraestrutura no Brasil", sem cidade (https://www.locaweb.com.br/servidor-vps/, acessado em 09/10/2026).
- Fato: DigitalOcean (https://docs.digitalocean.com/platform/regional-availability/), Contabo (https://contabo.com/en/locations/) e Hetzner (https://docs.hetzner.com/cloud/general/locations/) não têm região no Brasil. Os três acessados em 09/10/2026.
- Fato: a Latitude.sh cobra US$ 69 por mês pela vm.small, com 4 vCPU e 16 GB, mas a página não confirma São Paulo (https://www.latitude.sh/pricing, acessado em 09/10/2026).
- Fato: o Decreto 12.499/2025 fixa o IOF sobre compras no exterior feitas pelo usuário do cartão em "3,5% (três inteiros e cinco décimos por cento)" (https://www.planalto.gov.br/ccivil_03/_ato2023-2026/2025/decreto/D12499.htm, 11/06/2025).
- Fato: o dólar PTAX de venda estava em R$ 4,9892 em 09/10/2026 (API do Banco Central, olinda.bcb.gov.br).
- Inferência: o dólar efetivo fica em 4,9892 × 1,035 = R$ 5,16, mais o spread do cartão. Uso R$ 5,16 em todos os cálculos.

## §4 — Formas grátis antes de pagar

- Fato: no Brasil, cerca de 50% do tráfego já passa por IPv6, segundo dados do NIC.br citados pela Internet Society (https://pulse.internetsociety.org/en/news/the-silent-revolution-of-ipv6-in-brazil-50-adoption-milestone-achieved/, acessado em 09/10/2026).
- Inferência: redirecionar porta no PC do Arthur só funciona se o IP WAN do roteador for o mesmo que um site como "qual é meu IP" mostra. Se o IP WAN estiver em 100.64.0.0/10, a conexão está atrás de CGNAT.
- Inferência: IPv6 resolve o CGNAT só se os dois lados tiverem IPv6 e o firewall do roteador liberar a porta.
- Fato, playit.gg: a página de preços põe UDP na coluna "Free". O Premium custa US$ 3 por mês. "Free tunnels on playit.gg are “Global Anycast”", e só o Premium escolhe a região. O Premium também amplia as portas "from 4 to 16" (https://playit.gg/pricing e https://playit.gg/support/playit-premium/, acessados em 09/10/2026). Uma resposta no fórum diz que túneis TCP e UDP exigem Premium, o que contradiz a página de preços; trato como não confirmado.
- Fato: o Tailscale Personal é grátis, para até 6 usuários e com aparelhos ilimitados, só para uso não comercial (https://tailscale.com/pricing). O ZeroTier Personal é grátis para 10 aparelhos e 1 rede (https://www.zerotier.com/pricing/). Ambos acessados em 09/10/2026.
- Fato: o plano grátis do Google Cloud dá uma e2-micro só nas regiões us-west1, us-central1 e us-east1, mais US$ 300 de crédito por 90 dias (https://docs.cloud.google.com/free/docs/free-cloud-features, atualizado em 07/10/2026).
- Fato: a AWS dá US$ 100 de crédito, mais até US$ 100 ganhos ao usar serviços, e a conta fecha em 6 meses (https://aws.amazon.com/free/, acessado em 09/10/2026). A página não diz se vale para São Paulo.
- Inferência: o Oracle Always Free, com a região principal em São Paulo, dá 2 núcleos Arm de graça. Para isso o build precisa ser linux-arm64, e a disponibilidade de máquinas A1 costuma faltar.

## §5 — Godot em Docker

- Fato: a documentação do Godot diz: "You do not need to use a specialized server binary anymore, unlike Godot 3.x." A exportação para servidor dedicado adiciona a tag `dedicated_server`, que força `--headless`. A opção Strip Visuals é recomendada, e o template de exportação é preferível ao editor (https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_dedicated_servers.html, acessado em 09/10/2026).
- Fato: a proposta para tratar SIGTERM e SIGINT por script continua aberta (https://github.com/godotengine/godot-proposals/issues/1361, acessado em 09/10/2026).
- Fato: segundo a documentação do Docker, um processo PID 1 "ignores any signal with the default action". A flag `--init` roda um processo init que "forwards signals and reaps processes" (https://docs.docker.com/reference/cli/docker/container/run/, acessado em 09/10/2026).
- Recomendação: no Dockerfile, usar `ENTRYPOINT` em formato exec e `docker run --init` (ou tini), `USER` sem root e `-p 7777:7777/udp`. Para encerrar limpo, usar um arquivo de parada ou um comando de administrador. O tamanho da imagem não foi confirmado.
- Fato: o Docker Desktop é grátis para "Personal use" e para empresas com menos de 250 funcionários e menos de US$ 10 milhões de receita (https://docs.docker.com/subscription/desktop-license/). Ele exige WSL ≥ 2.1.5 e Windows 11 Pro, Enterprise ou Education 23H2 ou mais novo (https://docs.docker.com/desktop/setup/install/windows-install/). Ambos acessados em 09/10/2026.
- Fato: Podman Desktop e Rancher Desktop são Apache-2.0 (páginas do GitHub, acessadas em 09/10/2026).
- Fato: "GitHub Actions usage is free for self-hosted runners and for public repositories that use standard GitHub-hosted runners." (https://docs.github.com/en/billing/concepts/product-billing/github-actions). Também: "GitHub Packages usage is free for public packages." (https://docs.github.com/en/billing/concepts/product-billing/github-packages). Ambos acessados em 09/10/2026.

## §6 — Servidores da comunidade e lista de salas

- Fato, DDNet: "All ranks made on official servers are available worldwide and you can collect points!" Em 2025 o projeto recebeu 4.803 € em doações, usadas também para pagar servidores (https://ddnet.org/, acessado em 09/10/2026).
- Fato: o mastersrv do DDNet recebe o registro por HTTP POST e só aceita depois de confirmar que o servidor responde por UDP, com um token. Ele gera um `servers.json` publicado por HTTPS (https://github.com/ddnet/ddnet/blob/master/src/mastersrv/README.md, acessado em 09/10/2026).
- Fato, SuperTuxKart: um servidor aberto na internet precisa de conta no stk-addons, e o modo ranqueado ("you require permission for that") exige permissão. A validação dos jogadores passa pelo servidor stk-addons (https://github.com/supertuxkart/stk-code/blob/master/NETWORKING.md, acessado em 09/10/2026).
- Fato: o Luanti tem uma lista global em Python, servers.luanti.org (https://github.com/luanti-org/serverlist). O OpenRA tem um master server com a lista em JSON e MiniYAML (https://github.com/OpenRA/OpenRAMasterServer). Ambos acessados em 09/10/2026.
- Fato: o dpmaster é o master server do DarkPlaces (https://github.com/kphillisjr/dpmaster, acessado em 09/10/2026). A página não menciona o Xonotic.
- Inferência: o padrão comum é o projeto pagar só a lista de servidores, as contas e o ranking, enquanto a comunidade paga os servidores de jogo. A confiança vem de ranking só em servidores oficiais ou autorizados, com bans aplicados em cada servidor.
- Inferência: um único servidor oficial pode listar as próprias salas por RPC, no estilo GunZ, sem serviço separado. Com vários servidores, é preciso um master pequeno (HTTP com a lista em JSON). Matchmaking com fila e rating exige um serviço central a mais.

## §7 — Latência

- Fato, WonderNetwork (servidores em data center, sem a última milha de casa), médias em ms:

  | Origem | São Paulo | Brasília | Miami | Washington | Nova York | Atlanta | Dallas |
  |---|---|---|---|---|---|---|---|
  | São Paulo | — | 15,1 | 108,8 | 112,8 | 110,1 | 128,2 | 141,3 |
  | Brasília | 15,3 | — | 126,8 | 127,6 | 133,4 | 149,0 | 161,5 |
  | João Pessoa | 35,5 | 44,8 | 80,0 | 119,4 | 84,3 | — | 136,9 |

  (https://wondernetwork.com/pings/Sao%20Paulo, /Brasilia e /Joao%20Pessoa, acessados em 09/10/2026)
- Fato: a faixa "10–35 ms" do estudo vem do checkping.io. Ele mede o tempo de ida e volta HTTPS pelo navegador e dá Sul 25–55 ms, Nordeste 45–90 ms e costa leste dos EUA 110–160 ms (https://checkping.io/ping-test/sao-paulo, atualizado em 20/08/2026).
- Fato: não achei dados públicos para Rio, Belo Horizonte, Porto Alegre, Recife e Fortaleza.
- Fato, endpoints de ping em São Paulo:
  - Akamai: `speedtest.sao-paulo.linode.com` (https://www.akamai.com/cloud/speed-test).
  - Google Cloud: `southamerica-east1-5tkroniexa-rj.a.run.app` (https://global.gcping.com/api/endpoints).
  - AWS: `ec2.sa-east-1.amazonaws.com` e `dynamodb.sa-east-1.amazonaws.com`, que resolvem no DNS.
  - Vultr: `sao-br-ping.vultr.com`, que resolve para 216.238.98.118; a página oficial bloqueou o acesso (403).

## §8 — Tabela de custos

- Inferência, premissas:
  - 2 jogadores por partida.
  - Cada partida reserva 0,25 × 1,5 = 0,375 núcleo.
  - Cada partida gera 14 kB/s × 2.628.000 s = 36,8 GB por mês de saída.
  - Tudo ligado 24 horas por dia, no pico.
  - Dólar a R$ 5,16.
- Inferência, carga por tamanho:

  | Jogadores | Partidas | Núcleos | Saída por mês |
  |---|---|---|---|
  | 10 | 5 | 1,9 | 184 GB |
  | 50 | 25 | 9,4 | 0,92 TB |
  | 200 | 100 | 37,5 | 3,7 TB |
  | 1.000 | 500 | 188 | 18,4 TB |

- Inferência (a), Vultr vc2-1c-1gb a US$ 5: com 1 vCPU ÷ 0,375 cabem 2 partidas por máquina, US$ 2,50 por partida. O tráfego incluído cobre tudo.
  - 10 jogadores: 3 máquinas, US$ 15, R$ 77.
  - 50 jogadores: 13 máquinas, US$ 65, R$ 335.
  - 200 jogadores: 50 máquinas, US$ 250, R$ 1.290.
  - 1.000 jogadores: 250 máquinas, US$ 1.250, R$ 6.450.
  - Alternativa: Locaweb de 2 vCPU e 2 GB, com 5 partidas por máquina: R$ 24, R$ 120, R$ 478 e R$ 2.390. É mais barata, mas exige contrato de 24 meses, e a cidade, o DDoS e a qualidade da vCPU não foram confirmados.
- Inferência (b), Edgegap: cada partida usaria 0,5 vCPU (0,375 arredondado). Por hora de partida: 0,5 × US$ 0,069 + 0,0504 GB × US$ 0,10 = US$ 0,0395.
  - Ligado 24 horas, isso dá US$ 28,86 por partida por mês, ou R$ 149: R$ 745 (10 jogadores), R$ 3.725 (50), R$ 14.890 (200) e R$ 74.500 (1.000).
  - Se o pico durar só 3 horas por dia (90 horas por mês): R$ 92, R$ 459, R$ 1.837 e R$ 9.185.
  - A Edgegap só empata com a Vultr de US$ 20 (US$ 4 por partida) se houver menos de 101 horas de partida por mês, cerca de 3,3 horas por dia.
- Inferência (c), comunidade mais um servidor oficial: um oficial Vultr vc2-2c-4gb a US$ 20 (R$ 103) roda 5 partidas e também a lista de salas. Isso dá cerca de R$ 103 por mês em qualquer tamanho, e R$ 0 se for o Oracle A1 grátis. O resto das partidas fica com quem hospedar.
- Inferência: o orçamento de R$ 3–7 mil por ano equivale a R$ 250–583 por mês. Com VPS, isso cobre cerca de 50 jogadores simultâneos o tempo todo. Com a Edgegap ligada 24 horas, cobre só cerca de 10.

## §9 — Resumo

- Fato: a Oracle não cortou o plano grátis. O Ampere A1 caiu de 4 OCPU e 24 GB para 2 OCPU e 12 GB em 15/06/2026, e a Oracle tem região em São Paulo e Vinhedo.
- Fato: a "relay grátis até 50" da Edgegap ("50 CCU") vale só para jogos P2P e é irrelevante para servidor dedicado.
- Fato: o plano grátis da Edgegap tem 1 servidor por vez e limite de 60 minutos. Serve para testar, não para produção.
- Fato: só um post de 2024 da Edgegap afirma presença em São Paulo, e não dá para travar a região de uma partida.
- Fato: a Vultr em São Paulo custa a partir de US$ 5 por mês, com DDoS na região. A Linode em São Paulo custa 40% mais que nos EUA (US$ 7). AWS, Azure B e Lightsail usam CPU "burstable".
- Inferência: a Edgegap ligada 24 horas é cerca de 7 vezes mais cara que uma VPS. Ela só compensa com partidas abaixo de cerca de 3 horas por dia.
- Inferência: o Nordeste fica perto de Miami (80 ms a partir de João Pessoa), mas São Paulo continua sendo o ponto mais justo entre cidades brasileiras.
- Fato: o Godot não trata SIGTERM, e o PID 1 no Docker ignora o sinal. É preciso usar `--init` e um encerramento próprio.
- Fato: Actions e GHCR são grátis para repositório público, e o Docker Desktop é grátis para uso pessoal.
- Recomendação: antes da fase 3, usar o PC do Arthur com Tailscale ou playit, ou o Oracle A1 em São Paulo. Na fase 3, uma Vultr em São Paulo a US$ 5–20. Deixar a Edgegap para quando os jogadores estiverem espalhados.

## §10 — Não confirmado

- A lista atual de locais da Edgegap no Brasil e a capacidade em São Paulo (o mapa exige conta).
- Se o plugin da Edgegap funciona com o Godot 4.7.
- Os preços oficiais da Vultr na página (403; só a API foi lida) e o preço do DDoS da Vultr.
- O preço de egress da AWS e do Google em São Paulo e o preço pago da Oracle (403).
- Se o crédito grátis da AWS vale em sa-east-1.
- O item de egress de R$ 0,13/GiB da Magalu e a cidade da Locaweb.
- A presença da OVH no Brasil e da Latitude.sh em São Paulo.
- UDP no plano grátis do playit (fontes divergem).
- O tamanho de uma imagem Docker do Godot.
- Latências a partir de Rio, BH, Porto Alegre, Recife e Fortaleza.
- Que o Xonotic usa dpmaster.
- Se o IOF de 3,5% continua vigente em outubro de 2026 (só fontes secundárias confirmam).

## §11 — Afirmações importantes

H-01 | A relay grátis da Edgegap vai até 50 CCU, só para relay | https://edgegap.com/pricing | "Up to 50 CCU - 160 GB Egress included"
H-02 | Relays da Edgegap não são servidores de jogo | https://edgegap.com/pricing | "Reminder: Relays are not authoritative game servers. They do not include compute."
H-03 | O Edge Cloud cobra por minuto de uso | https://edgegap.com/pricing | "Billed by the Minute, Only on Usage"
H-04 | O plano grátis da Edgegap roda 1 servidor por vez | https://docs.edgegap.com/llms-full.txt | "You may only run 1 concurrent deployment in Free Tier."
H-05 | Servidores do plano grátis duram 60 minutos | https://docs.edgegap.com/llms-full.txt | "Free Tier deployments have a 60 minute time limit, please consider upgrading your account."
H-06 | A Edgegap anunciou locais em São Paulo | https://edgegap.com/blog-en/world-s-largest-disitrbuted-network-edgegap-expands-to-550-locations-worldwide | "Including Brazil, with new locations in Sao Paulo, alongside Chile and new locations in populous Santiago."
H-07 | A Edgegap escolhe o local pela capacidade disponível | https://docs.edgegap.com/learn/orchestration/deployments | "Edgegap deploys in the best possible location with available capacity."
H-08 | O Oracle Always Free A1 agora é 2 OCPU e 12 GB | https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm | "For Always Free tenancies, this is equivalent to 2 OCPUs and 12 GB of memory."
H-09 | O corte da Oracle valeu em 15/06/2026 | https://www.infoq.com/news/2026/07/oracle-cloud-free-tier-limits/ | "The change took effect on June 15, 2026."
H-10 | O Godot 4 não precisa de binário de servidor separado | https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_dedicated_servers.html | "You do not need to use a specialized server binary anymore, unlike Godot 3.x."
H-11 | O PID 1 no Docker ignora SIGTERM por padrão | https://docs.docker.com/reference/cli/docker/container/run/ | "A process running as PID 1 inside a container is treated specially by Linux: it ignores any signal with the default action."
H-12 | Actions é grátis para repositório público | https://docs.github.com/en/billing/concepts/product-billing/github-actions | "GitHub Actions usage is free for self-hosted runners and for public repositories that use standard GitHub-hosted runners."
H-13 | O DDNet só conta ranking de servidores oficiais | https://ddnet.org/ | "All ranks made on official servers are available worldwide and you can collect points!"
H-14 | A e2-micro grátis do Google só existe nos EUA | https://docs.cloud.google.com/free/docs/free-cloud-features | "1 non-preemptible e2-micro VM instance per month in one of the following US regions:"
H-15 | O IOF em compras no exterior com cartão é 3,5% | https://www.planalto.gov.br/ccivil_03/_ato2023-2026/2025/decreto/D12499.htm | "3,5% (três inteiros e cinco décimos por cento)"

## §12 — O veredicto do verificador

Como chegou, do verificador adversarial (Fable 5.1, esforço xhigh), em 09/10/2026. Ele abriu a fonte de cada afirmação marcada como importante nas quatro pesquisas (F-066 a F-069) e de 12 dúvidas do orquestrador (X-01 a X-12), e citou a frase que achou. Das 72, 61 saíram confirmadas, 10 confirmadas com ressalva e 1 refutada (X-12, o preço da Vultr em São Paulo); nenhuma ficou sem verificar. Cada linha traz o ID, o veredicto, a frase achada, a URL usada e a nota do verificador. O resumo inteiro do verificador, que cobre as quatro pesquisas, vem no fim desta seção. As dúvidas do orquestrador desta pesquisa são X-10, X-11, X-12.

- H-01 | CONFIRMADO | "Up to 50 CCU - 160 GB Egress included" | https://edgegap.com/pricing | Está no cartão "Peer-To-Peer Relays: Free Trial" da seção Distributed Relays. A página chama de "Free Trial", não de plano grátis permanente.
- H-02 | CONFIRMADO | "Reminder: Relays are not authoritative game servers. They do not include compute." | https://edgegap.com/pricing | Lembrete ao fim da seção Distributed Relays.
- H-03 | CONFIRMADO | "Billed by the Minute, Only on Usage" | https://edgegap.com/pricing | Cartão "Edge Cloud (On-Demand)".
- H-04 | CONFIRMADO | "You may only run 1 concurrent deployment in Free Tier." | https://docs.edgegap.com/llms-full.txt | Linha 7842 do arquivo baixado hoje.
- H-05 | CONFIRMADO | "Free Tier deployments have a 60 minute time limit, please consider upgrading your account." | https://docs.edgegap.com/llms-full.txt | Aparece três vezes, com pequenas variações ("have a 60 minute limit").
- H-06 | CONFIRMADO COM RESSALVA | "Including Brazil, with new locations in Sao Paulo, alongside Chile and new locations in populous Santiago." | https://edgegap.com/blog-en/world-s-largest-disitrbuted-network-edgegap-expands-to-550-locations-worldwide | A frase existe, mas o título atual é "...Expand with 615 Locations Worldwide" (não 550) e o corpo diz "Published 2/13/24": é um anúncio de fevereiro de 2024, não prova de capacidade atual em São Paulo.
- H-07 | CONFIRMADO COM RESSALVA | "Edgegap deploys in the best possible location with available capacity, for fast and low-latency matches." | https://docs.edgegap.com/learn/orchestration/deployments | O pesquisador cortou a frase. A página diz que, por padrão, a estratégia "Server Score" escolhe pelo ping dos jogadores; capacidade é condição, não o critério único.
- H-08 | CONFIRMADO | "For Always Free tenancies, this is equivalent to 2 OCPUs and 12 GB of memory." | https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm | Também: "All tenancies get the first 1,500 OCPU hours and 9,000 GB hours per month for free". A página não diz quando mudou.
- H-09 | CONFIRMADO COM RESSALVA | "The change took effect on June 15, 2026." | https://www.infoq.com/news/2026/07/oracle-cloud-free-tier-limits/ | A data vem só de fonte secundária (InfoQ, 03/07/2026, "from 4 OCPUs and 24 GB of RAM to 2 OCPUs and 12 GB of RAM"); a Oracle não publicou anúncio e a doc oficial não traz data.
- H-10 | CONFIRMADO | "You do not need to use a specialized server binary anymore, unlike Godot 3.x." | https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_dedicated_servers.html | Literal.
- H-11 | CONFIRMADO | "A process running as PID 1 inside a container is treated specially by Linux: it ignores any signal with the default action. So, the process doesn't terminate on SIGINT or SIGTERM unless it's coded to do so." | https://docs.docker.com/reference/cli/docker/container/run/ | Literal (está na seção "-a, --attach"); a saída indicada é "--init".
- H-12 | CONFIRMADO | "GitHub Actions usage is free for self-hosted runners and for public repositories that use standard GitHub-hosted runners." | https://docs.github.com/en/billing/concepts/product-billing/github-actions | Literal.
- H-13 | CONFIRMADO | "All ranks made on official servers are available worldwide and you can collect points!" | https://ddnet.org/ | Literal.
- H-14 | CONFIRMADO | "1 non-preemptible e2-micro VM instance per month in one of the following US regions:" | https://docs.cloud.google.com/free/docs/free-cloud-features | Regiões listadas: "Oregon: us-west1", "Iowa: us-central1", "South Carolina: us-east1".
- H-15 | CONFIRMADO | "VII - nas operações de câmbio destinadas ao cumprimento de obrigações das instituições que participem de arranjos de pagamento de abrangência transfronteiriça na qualidade de emissores destes, decorrentes de aquisição de bens e serviços do exterior efetuada por seus usuários, observado o disposto no inciso VIII: 3,5% (três inteiros e cinco décimos por cento);" | https://www.planalto.gov.br/ccivil_03/_ato2023-2026/2025/decreto/D12499.htm | Literal. O cabeçalho remete ao Decreto Legislativo 176/2025 e à ADC 96 (STF); a vigência depende dessa decisão, que não conferi nesta rodada.
- X-10 | CONFIRMADO | "$0 • No credit card" | https://edgegap.com/pricing | Cartão "Free Trial" de Game Server Hosting & Orchestration; a tabela comparativa repete "No credit card required".
- X-11 | CONFIRMADO | "Personal use" (entre os usos gratuitos) / "Windows 11 64-bit: Enterprise, Pro, or Education version 23H2 (build 22631) or higher." / "WSL version 2.1.5 or later." | https://docs.docker.com/subscription/desktop-license/ e https://docs.docker.com/desktop/setup/install/windows-install/ | Grátis também para "Education", "Non-commercial open source projects" e "Small businesses (fewer than 250 employees AND less than $10 million in annual revenue)". A mesma página diz "Windows Home or Education editions only allow you to run Linux containers", o que contradiz a lista de edições; o PC do Arthur (Windows 11 Pro, build 26200) atende de qualquer jeito.
- X-12 | REFUTADO | `"id": "vc2-1c-1gb", "vcpu_count": 1, "ram": 1024, "bandwidth": 1024, "monthly_cost": 5, ... "location_cost": {"sao": {"monthly_cost": 7.5, "hourly_cost": 0.01}}` e `{"id": "sao", "city": "São Paulo", "country": "BR"}` | https://api.vultr.com/v2/plans e https://api.vultr.com/v2/regions | O plano existe e está disponível em "sao", mas em São Paulo custa US$ 7,50/mês (hourly 0,01), não US$ 5; US$ 5 é o preço base das outras regiões. O vc2-1c-2gb vai de US$ 10 para US$ 15 em "sao". O F-066 usa US$ 5 nas linhas 40, 133, 152 e 157; a conta "US$ 2,50 por partida" vira US$ 3,75.

Resumo do verificador, como chegou:

Contagem (72 afirmações): CONFIRMADO 61 · CONFIRMADO COM RESSALVA 10 · REFUTADO 1 · NÃO VERIFICÁVEL 0.

Refutada:
- X-12 (Vultr em São Paulo a US$ 5): a API mostra `location_cost.sao.monthly_cost = 7.5` para o vc2-1c-1gb (e 15 para o vc2-1c-2gb). O F-066 precisa corrigir as linhas 40, 133, 152 e 157 e refazer a conta por partida (US$ 3,75, não US$ 2,50).
- Fora da lista, mas provado por X-01: a afirmação do F-069 §6, linha 85 ("referências a hashes nas mensagens de commit não são reescritas"), está errada; o git filter-repo reescreve por padrão e só preserva com `--preserve-commit-hashes`.

Corrigidas (ressalvas):
- H-06: anúncio de 13/02/2024; título atual fala em 615 localidades.
- H-07: critério padrão é o ping ("Server Score"); capacidade é condição.
- H-09: a data 15/06/2026 vem só da InfoQ; a doc da Oracle não traz data.
- S-14: a frase certa é "In projects exported in release mode, backtraces are disabled by default for performance reasons."; a citada era sobre flush do stdout.
- R-09: "0 (zero) to 10" é da sub-regra "Required reviewers" (por time, inexistente em repositório pessoal); o mínimo geral de aprovações não está escrito nem na doc nem na REST API.
- X-02: a frase de disponibilidade vive na caixa "Who can use this feature"; conferida no texto-fonte do github/docs.
- X-06: a Sentry só diz "make sure it's released under a friendly license like Apache or MIT"; não há regra formal nem exigência de não comercial.
- X-07: 26/08/2026 é inferência de "on Wednesday" numa matéria de 28/08.
- X-08: só imprensa (tnh1 25/09, hardware.com.br 26/09); sem fonte em gov.br/anpd; decisão da Superintendência em 24/09, recurso ainda vai ao Conselho Diretor.
- L-07: a dispensa de verificação de idade é só a do art. 23 (loot boxes), não dos demais deveres do decreto.

Observações de método: para X-02 usei o texto-fonte do github/docs (raw.githubusercontent.com) porque as páginas renderizadas não trazem a frase no corpo; para L-11 usei o HTML oficial da Biblioteca Digital do MJ em vez do datalegis; para L-13/L-14 o gnu.org bloqueou o curl simples e o WebFetch (403/429), mas respondeu com user-agent de navegador. Nenhuma afirmação ficou sem verificar.

## §13 — A conferência do orquestrador

Escrita pelo agente que orquestrou a pesquisa, depois do veredicto do X-12, em 09/10/2026. Ele baixou a lista pública de planos da Vultr (`https://api.vultr.com/v2/plans?per_page=500`) e leu o campo `location_cost` da região `sao`, São Paulo. Em São Paulo, a Vultr cobra 1,5 vez o preço base de cada plano:

| Plano | vCPU | RAM | Tráfego incluído | Base | São Paulo |
|---|---|---|---|---|---|
| `vc2-1c-1gb` | 1, compartilhada | 1 GB | 1 TB | US$ 5 | US$ 7,50 |
| `vc2-1c-2gb` | 1, compartilhada | 2 GB | 2 TB | US$ 10 | US$ 15 |
| `vc2-2c-2gb` | 2, compartilhadas | 2 GB | 3 TB | US$ 15 | US$ 22,50 |
| `vc2-2c-4gb` | 2, compartilhadas | 4 GB | 3 TB | US$ 20 | US$ 30 |
| `vhp-1c-1gb-amd` | 1, alto desempenho | 1 GB | 2 TB | US$ 6 | US$ 9 |
| `voc-c-1c-2gb-25s-amd` | 1, dedicada | 2 GB | 4 TB | US$ 28 | US$ 42 |

A conta do §8 refeita com o preço de São Paulo e as mesmas premissas (0,375 núcleo por partida, tudo ligado 24 horas no pico, dólar a R$ 5,16). A linha (a) usa o `vc2-1c-1gb`, com 2 partidas por máquina, ou US$ 3,75 por partida. A linha (c) põe o servidor oficial no `vc2-2c-4gb`, que roda 5 partidas e a lista de salas. As linhas da Edgegap não mudam, porque ela cobra por minuto, sem preço por região no §2.

| Jogadores | Partidas | (a) VPS em São Paulo | (b) Edgegap, 24 h | (b) Edgegap, 3 h de pico | (c) Comunidade + 1 oficial |
|---|---|---|---|---|---|
| 10 | 5 | 3 máquinas, US$ 22,50, R$ 116 | R$ 745 | R$ 92 | R$ 155 |
| 50 | 25 | 13 máquinas, US$ 97,50, R$ 503 | R$ 3.725 | R$ 459 | R$ 155 |
| 200 | 100 | 50 máquinas, US$ 375, R$ 1.935 | R$ 14.890 | R$ 1.837 | R$ 155 |
| 1.000 | 500 | 250 máquinas, US$ 1.875, R$ 9.675 | R$ 74.500 | R$ 9.185 | R$ 155 |

Com o preço de São Paulo, a Edgegap ligada o dia todo custa umas 7,7 vezes a VPS por partida (US$ 28,86 contra US$ 3,75) e empata com ela em uns 95 horas de partida por mês, umas 3,2 horas por dia. O orçamento do estudo, de R$ 250 a 583 por mês (F-001), cobre uns 50 jogadores ao mesmo tempo em VPS.
