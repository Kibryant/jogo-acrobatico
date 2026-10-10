---
id: TASK-8
title: 'Desenho 6: infraestrutura e serviços'
status: In Progress
assignee: []
created_date: '2026-10-02 16:48'
updated_date: '2026-10-10 12:56'
labels:
  - infra
  - desenho
milestone: m-0
dependencies:
  - TASK-5
  - TASK-6
  - TASK-7
ordinal: 8000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
Sexta e última conversa da fase de desenho (DEC-0012). Até aqui, tudo roda neste PC. O Desenho 6 decide quando o jogo sai daqui e quanto custa, em quatro frentes: o servidor (DEC-0011: VPS em São Paulo com Docker, ou a Edgegap); o código, que abre neste desenho junto com a licença (F-058; Q-04); os serviços de depois, cada um com o seu gatilho e o seu custo (contas e ranking, Steam, relatório de crash, comunidade e assinatura da build); e o que a lei pede em cada gatilho. A pesquisa de 09/10 (F-066 a F-069) e a medição desta casa (F-070) mudam o plano em sete pontos:
- São Paulo fica a uns 26 ms daqui; Miami, a 113; Dallas, a 143; Los Angeles, a 195 (F-070 §1). Esta conexão não tem IPv6 público e tem CGNAT provável: um amigo não entra direto num servidor neste PC (F-070 §4).
- A Edgegap ligada o dia todo custa quase 8 vezes uma VPS em São Paulo, que na Vultr começa em US$ 7,50 por mês, e não deixa travar a partida em São Paulo: ela escolhe o lugar pelo ping de quem joga. A "relay grátis até 50" só serve para P2P, o que responde à Q-05. O plano grátis, sem cartão, roda um servidor por vez por 60 minutos: serve para uma sonda (F-066 §1, §2, §12 e §13).
- O estudo errou num ponto: a Oracle não acabou com o plano grátis; cortou para 2 núcleos Arm e 12 GB, e tem região em São Paulo (F-066 §3; F-001).
- A licença decide a Steam, a assinatura e o Sentry. A Valve diz que licença copyleft, como a GPL, costuma ser incompatível com o SDK dela (F-067 §3 e §10); a GPL só entra com uma exceção escrita desde o primeiro commit (F-068 §4). A assinatura grátis do SignPath pede licença OSI (F-069 §7 e §12), e o plano do Sentry para código aberto pede uma licença "amigável, como Apache ou MIT" (F-067 §10).
- Sem assinatura, o Smart App Control do Windows 11 barra a build de quem for testar. A única assinatura grátis que atende uma pessoa física no Brasil é a do SignPath, que pede o repositório aberto (F-069 §7; Q-20).
- Abrir publica o histórico inteiro: o Gmail do Arthur como autor de 36 dos 37 commits (o merge feito pelo GitHub saiu com o endereço noreply) e as falas dele em 38 das 65 fontes. Trocar o e-mail no próprio repositório não o esconde, porque as páginas dos PRs guardam os commits antigos (F-069 §6); o Arthur não liga de o e-mail ficar público (F-071 §3). Todo download do LFS, até o de um fork, sai da cota do dono (F-069 §3 e §12).
- A LGPD vale para um jogo grátis de pessoa física aberto ao público, e o ECA Digital alcança jogo eletrônico. A única proibição expressa é a loot box paga, que o jogo não tem; chat pede denúncia e interação limitada por padrão (F-068 §1, §2 e §13). O Discord está sob processo no Brasil, e o Ministério da Justiça o classifica como não recomendado para menores de 18 (F-067 §6 e §10).

Vitrine do Desenho 6, privada (DEC-0019): https://claude.ai/artifact/1RwRJJxuaeRtRKCMiqWvQd

### Perguntas em aberto
A pauta da conversa: cada item sai com resposta, DEC ou pendência.

Rodada 1, o servidor fora de casa, com a mão na massa:
- Abre com o ping repetido à noite, no horário de pico, e com o que o CGNAT quer dizer para jogar com amigos (F-070).
- A sonda, fora do repositório (`../servidor-sonda`): o servidor do parry de brinquedo do Desenho 5 (`../netfox-sonda/sonda`) exportado como servidor dedicado Linux, numa imagem Docker. Ela roda primeiro aqui, no Docker Desktop, com os clientes Windows. Depois roda num servidor grátis da Edgegap, de 60 minutos, que escolhe o lugar pelo ping de quem joga; ela anunciou São Paulo em 2024 (F-066 §1, §2 e §12). O Arthur joga contra o bot com o servidor fora de casa e diz o que sentiu (F-041; F-055).
- O que a sonda mede: a CPU, a memória e a banda do servidor num host de verdade, o tamanho da imagem, o tempo até aceitar conexão e onde a Edgegap pôs o servidor. E o fechamento limpo no contêiner, porque o Godot não trata o SIGTERM e o PID 1 ignora o sinal (F-066 §5).
- A hospedagem de cada fase, com o custo por faixa (10, 50, 200 e 1.000 jogadores): este PC; um túnel para amigos (Tailscale ou playit); o Oracle grátis em São Paulo, que pede o servidor em Linux Arm; uma VPS em São Paulo; a Edgegap; e os servidores da comunidade, com um oficial e a lista de salas (F-066 §3, §4, §6 e §8). A Q-05 sai respondida.
- A DEC da hospedagem do esqueleto andante (critério 2) e a entrada do Desenho 6 na TASK-9.

Rodada 2, o código aberto e os serviços, com a mão na massa:
- Abre com o ensaio da abertura num clone: o gitleaks no histórico inteiro e a lista de tudo o que fica público, das falas nas fontes aos diários, aos PRs e aos logs do CI, para o Arthur conferir (F-069 §5).
- A licença do código e dos assets próprios, a contribuição (inbound=outbound, DCO ou CLA) e o nome e o logo reservados (Q-04; F-068 §4 a §7).
- O e-mail fica público, porque o Arthur não liga para isso, e o histórico abre como está, sem reescrita e sem repositório novo (F-071 §3); a DEC registra.
- O que muda com o repositório público: a regra da main (a Q-03 de novo), o CI de PR de fora sem segredo e só com aprovação, o LFS fora dos jobs que não precisam dele, a varredura de segredo e os arquivos da comunidade (F-069 §1 a §5 e §8).
- Os serviços, com o gatilho, a direção e o custo de cada um: contas e ranking (o Supabase grátis pausa sem uso, e o Pro custa US$ 25 por mês; ou o banco do servidor oficial), Steam (a página, o Steam Direct, o GodotSteam e o SDK fora do repositório), relatório de crash (o log do Godot, depois o Sentry sem dado pessoal), comunidade (GitHub Discussions; o Discord sob processo) e a assinatura da build (o SignPath; Q-20) (F-067; F-069 §7).
- A lei em cada gatilho: a LGPD no IP e nas contas, o ECA Digital no chat e na interação, a classificação indicativa no lançamento, e onde um advogado é preciso (F-068).

### Escolhas confirmadas
Confirmadas pelo Arthur em 09/10 (F-071 §3 e §4):
1. Nada pago e nenhum cartão cadastrado antes da fase 3. Sem cartão, o GitHub bloqueia o excedente do LFS em vez de cobrar (F-050 §5).
2. Duas rodadas com sonda fora do repositório, como nos Desenhos 3 a 5, e o fechamento no modo de plano, revisado antes por um agente de planejamento.
3. A sonda da rodada 1 instala o WSL 2 e o Docker Desktop neste PC, grátis para uso pessoal, e o Windows 11 Pro daqui atende (F-066 §5 e §12). O Arthur cria uma conta grátis na Edgegap, sem cartão.
4. A partida do esqueleto andante, que a rodada 1 decide: o servidor e os clientes neste PC, como a TASK-9 já diz, e a imagem do servidor Linux testada no CI a cada push. Servidor alugado só na fase 3.
5. A licença de partida, que a rodada 2 decide: MIT no código, CC BY 4.0 nos assets próprios e o nome e o logo reservados (F-068 §4 a §7).
6. A abertura vira uma task curta própria, a TASK-11, Ready no fechamento: ela é voltada para fora e não se desfaz.

### Fora do escopo
- Contratar serviço, criar conta paga ou cadastrar cartão.
- Abrir o repositório: fica para a TASK-11.
- Implementar contas, ranking, salas, Steam ou o relatório de crash: daqui saem o gatilho, a direção e o custo.
- O nome definitivo e o logo (DEC-0018).
- O anti-cheat, que tem conversa própria antes da fase 4 (Q-19).
- Parecer jurídico: a conversa diz o que a lei pede e onde um advogado é preciso.

### O que você vai aprender
- Como um servidor de jogo roda num contêiner, e por que a região importa: 26 ms contra 113 a 195 daqui.
- Quanto custa um jogador online por mês, a partir da CPU e da banda que a gente mediu.
- O que uma licença aberta deixa os outros fazerem, e por que ela decide a Steam e a assinatura da build.
- O que "ficar público" quer dizer no git: o histórico, o e-mail e as páginas dos PRs.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando a conversa termina, `docs/arquitetura/infraestrutura.md` tem cada serviço (servidor, contas e ranking, Steam, relatório de crash, comunidade, assinatura da build e o repositório) com o gatilho de entrada, a direção, o custo estimado por faixa de jogadores (10, 50, 200 e 1.000) e o que a lei pede nele, com a fonte de cada número.
- [ ] #2 Quando o Arthur decide a hospedagem do esqueleto andante, uma DEC registra, e a TASK-9 ganha a entrada do Desenho 6.
- [ ] #3 Quando a sonda da rodada 1 roda o servidor num contêiner, aqui e fora de casa, uma fonte registra o ping em dois horários, a CPU, a memória e a banda do servidor, o tamanho da imagem, onde o servidor rodou e o que o Arthur sentiu; quando o contêiner não sobe ou não fecha limpo, a fonte diz por quê.
- [ ] #4 Quando o Arthur decide a licença do código e dos assets próprios, a contribuição e o que fica público, uma DEC registra e a Q-04 fecha.
- [ ] #5 Quando o ensaio da abertura roda num clone, o gitleaks no histórico inteiro sai limpo e uma lista mostra tudo o que fica público; quando aparece segredo, arquivo de licença fechada ou dado que o Arthur não quer expor, a TASK-11 traz a correção antes da abertura.
- [ ] #6 Quando a conversa termina, a TASK-11 está Ready com os critérios da abertura: os arquivos da licença e da comunidade, o CI de PR de fora sem segredo e só com aprovação, o LFS fora dos jobs que não precisam dele, a virada para público com o ok do Arthur na hora, a regra da main e a conferência no repositório público.
- [ ] #7 Quando a conversa termina, a Q-05 e a Q-20 têm resposta, e cada pergunta nova vira Q em `docs/pendencias.md`.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Rodada 1, o servidor fora de casa:
   - O ping à noite, no horário de pico, e o CGNAT explicado (F-070).
   - O WSL 2 e o Docker Desktop instalados (escolha 3). A sonda em `../servidor-sonda`: o servidor do parry de brinquedo exportado para Linux, a imagem, o `docker run` aqui com os clientes Windows e o fechamento limpo; depois o servidor grátis da Edgegap, em que o Arthur joga contra o bot e diz o que sentiu; as medições.
   - A hospedagem de cada fase e o custo por faixa; a vitrine republicada; a fonte das medições; as perguntas da rodada, com a hospedagem do esqueleto andante.
2. Rodada 2, o código aberto e os serviços:
   - O ensaio da abertura num clone e a lista do que fica público, para o Arthur conferir.
   - A licença, a contribuição, a regra da main, o CI de PR de fora e o LFS; os serviços e os gatilhos; a lei.
   - A vitrine republicada; a fonte; as perguntas da rodada.
3. O plano no modo de plano, revisado antes por um agente de planejamento (registro da TASK-5). Com o ok: uma fonte com o plano, as DECs (a hospedagem; o repositório aberto e a licença; os serviços e os gatilhos), o `docs/arquitetura/infraestrutura.md`, a entrada do Desenho 6 na TASK-9 e a TASK-11 Ready; o `AGENTS.md` acompanha o que mudar.
4. Registro: as fontes, o glossário, o `mudancas.md` (a correção da Oracle e o que mudar no roteiro), o `pendencias.md` (Q-05, Q-20 e as novas) e o registro da harness; depois o reviewer e o portão num clone limpo.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Rodada 1 (09/10, sessão 10), o servidor fora de casa:
- A sonda fica em `../servidor-sonda`: uma cópia do parry de brinquedo do Desenho 5 em `jogo/` (sem o `override.cfg`), com o preset "Servidor Linux" de servidor dedicado; o `Dockerfile` (debian:trixie-slim, o `tini` como PID 1, um usuário sem root e a porta 7777/udp); o `local.sh`, o `remoto.sh`, o `medir.py` e os scripts de ping.
- Fora do editor, o `NetworkSimulator` do netfox se desliga sozinho (`OS.has_feature("editor")`), e o `main.gd` abre o ENet pelo `--port` e pelo `--host`: a build do servidor nunca simula lag.
- A exportação pela linha de comando do Godot 4.7.2 levou 15 s e deu um binário só, de 73,8 MB, com o pacote embutido.
- O teste sem contêiner, com os três processos neste PC: o servidor desta sonda gasta mediana de 41% de um núcleo, e cada cliente sobe uns 25 kB/s, acima do Desenho 3 (de 15 a 23% e 12,4 kB/s; F-034). O contêiner mede o servidor sozinho.
- A instalação: o Docker Desktop 4.94.0 entrou pelo winget. O WSL 2.7.13 só entrou num PowerShell elevado: o `wsl.exe` de fábrica recusou o `--no-distribution`, e o pacote do WSL pede administrador. O Windows pede reinício para a plataforma de máquina virtual.
- Depois do reinício: abrir o Docker Desktop, aceitar os termos, esperar o motor rodar e seguir com o `local.sh`.

- Depois do reinício: o Docker 29.8.2 rodou; a imagem tem 222 MB e o servidor sobe em 1,2 a 1,6 s no contêiner; o `docker stop` leva 0,5 s, mas sai com 143, morto pelo SIGTERM: o fechamento limpo é ponto para o esqueleto andante (F-073 §1 e §2).
- O Arthur jogou 204 s com o servidor no contêiner aqui (21,5% de um núcleo, 43 MB) e 262 s com ele na Edgegap, que o pôs em São Paulo: 13,9% de um núcleo, ping de 24 ms e 37 ms no jogo, estável, sem perda (F-073 §2 e §3).
- Ele achou liso, com umas travadas em que o golpe repetia (F-072 §3). Os logs mostram rajadas do tranco também sem rede: é regra da sonda, não servidor (F-073 §4); virou a Q-26.
- O segundo horário do ping saiu num sábado às 9h47, igual ao de sexta à tarde; o pico da noite segue sem medida (F-073 §5).
<!-- SECTION:NOTES:END -->

## Comments

<!-- COMMENTS:BEGIN -->
created: 2026-10-07 23:13
---
Entrada do Desenho 5, rodada 1 (TASK-7; F-058): o Arthur quer o jogo aberto, com o repositório público, contribuições por PR e ele como mantenedor principal, sem lucro. O repositório abre neste desenho, junto com a licença do código (Q-04). Até lá, os assets já só entram com licença que deixa redistribuir (TASK-7). O que abrir muda: o CI fica grátis em repositório público, e a regra de branch passa a valer no plano Free (F-047 §1.1; Q-03); a banda do LFS é cobrada por download (F-050 §5), e num repositório público quem clona também baixa (inferência); o histórico precisa estar limpo de segredo e de asset fechado antes de abrir (o gitleaks já varre o histórico inteiro, registro da TASK-2).
---
<!-- COMMENTS:END -->
