---
revisado_em: 2026-10-27
fontes: [F-001, F-007, F-032, F-044, F-074, F-076, F-082, F-083, F-166, F-172, F-173]
---

# Roteiro

As fases do estudo, cada uma com o teste que pode encerrar o projeto sem culpa (F-001). As estimativas são para 10 horas por semana e somam de 24 a 36 meses.

| Fase | O que é | Duração estimada | Teste que encerra ou segue |
|---|---|---|---|
| 0 | Base, desenho e esqueleto andante (marco m-0) | 2 a 4 semanas | "Gosto de jogar ou só da ideia?" |
| 1 | Movimento: correr, parede, pulo, dash e gancho numa arena de blocos | 3 a 5 meses | "Divertido sozinho por 15 min?" |
| 2 | Duelo contra bot e percurso cronometrado | 3 a 4 meses | "Amigos entendem cada troca?" |
| 3 | 1v1 online | 6 a 9 meses | "Justo entre cidades diferentes?" |
| 4 | Alpha com 1v1 e 4v4, salas, bot, replay e comunidade no GitHub | 6 a 8 meses | "20 pessoas voltam sem ninguém pedir?" |
| 5 | Lançamento grátis no Next Fest | 3 a 5 meses | "30+ no pico uma semana depois?" |

## Fases fechadas

- **Fase 0** fechou em 19/10/2026 com a versão 0.1.0, o esqueleto andante (DEC-0028 §3).
- **Fase 1** fechou em 27/10/2026 com a versão 0.2.0. O teste passou: o Arthur jogou 15 min 38 s sozinho e "com certeza continuaria jogando", pedindo mais ação, que é a fase 2 (F-166 §2). O portão da fase 2 é "Amigos entendem cada troca?".

## Mudanças em relação ao estudo

O detalhe de cada mudança está em `mudancas.md`.

- **Fase 0:** virou base do repositório, fase de desenho e esqueleto andante (DEC-0012). A fase de desenho fechou em 10/10/2026, com os seis desenhos e as DEC-0013 a DEC-0035; não se abre desenho de base novo. Cada fase abre com o seu desenho de jogo, com a lista na DEC-0036; o que aparecer no meio vira Q em `pendencias.md`.
- **Fase 1:** no estudo, era "movimento sem rede". O rollback exige que o movimento rode dentro do tick desde o começo (F-007 §2). O Desenho 3 decidiu: a fase 1 nasce no tick do netfox e é jogada sozinha, no modo "Sozinho" da `Main`, sem rede. A SyncTest no portão cobre cada manobra nova (DEC-0026; DEC-0027). A gravação do replay por inputs também começa na fase 1, para reproduzir sem tela os bugs de movimento; o replay para o jogador segue na fase 4 (F-044 §1; DEC-0027).
- **Fase 2:** abriu em 27/10/2026 com o desenho do duelo, a primeira rodada da fase (TASK-12; DEC-0036; F-172): o `combate.md` ganhou o v0 do duelo golpe a golpe, e o `partida.md` nasceu com os rounds, o plano de morte, o bot e o percurso cronometrado, com a pesquisa verificada da tribo na F-173. A fase traz também o som com licença livre (F-172 §2), o relatório de crash pelo log (DEC-0034) e, a confirmar, o manequim CC0 com os clipes (DEC-0030 §7). Fecha com a versão 0.3.0 (DEC-0028 §3).
- **Fase 3:** o primeiro servidor fora de casa é uma VPS em São Paulo; até lá, nada se paga (DEC-0032).
- **Entre a fase 3 e a 4:** o arco e as armas entram como marco próprio, depois do 1v1 online e antes do 4v4 com bots (DEC-0004, regra 6; DEC-0036).
- **Fase 4:** a comunidade mora no GitHub Discussions, e o Discord só entra como canal extra; no jogo, só sinais rápidos, sem chat livre (DEC-0034; `mudancas.md`).

A rota alternativa do estudo continua de pé: primeiro um jogo para jogar sozinho ou em dupla contra o computador, com a mesma movimentação, para formar público (F-001).
