---
id: F-042
titulo: A sonda do replay e o tempo da SyncTest — o replay por inputs se repete byte a byte no Windows e no Linux, e a SyncTest pelo relógio do netfox custa o tempo real (sessão 7, 07/10/2026)
recebido_em: 2026-10-07
como: Medido pelo Claude na sessão 7 (rodada 2 da TASK-6), numa sonda fora do repositório (`../replay-sonda`), na sonda do Desenho 3 (`../netfox-sonda/sonda`) e num runner do GitHub, numa branch de sonda já apagada. Números como saíram dos logs.
status: vigente
substituida_por:
---

## §1 — A SyncTest pelo relógio do netfox custa o tempo real

A sonda do Desenho 3 rodou sem tela, a 60 ticks (por um `override.cfg` só na sonda), com rollback forçado de 7 ticks e os dois contornos (DEC-0025).

| Cenário | Ticks | Tempo de relógio | Conferências | Divergências | O que cobriu |
|---|---|---|---|---|---|
| rampa | 300 | 6,3 s | 1.734 | 0 | 2 pousos, 2 decolagens, 28 ticks na rampa |
| rampa | 600 | 11,4 s | 3.534 | 0 | 4 pousos, 4 decolagens, 56 ticks na rampa |
| rampa | 1.200 | 22,0 s | 7.134 | 0 | — |
| rampa, com `--fixed-fps 60` | 1.200 | 21,3 s | 7.134 | 0 | — |
| duelo | 300 | 6,3 s | 3.468 | 32 | 113 contatos entre lutadores |
| duelo | 600 | 11,4 s | 7.068 | 32 | 183 contatos |
| duelo, com `--fixed-fps 60` | 1.200 | 21,3 s | 14.268 | 32 | — |

- O `--fixed-fps 60` não acelera a SyncTest. O relógio do netfox segue o `NetworkTimeSynchronizer.get_time()`, que é o tempo de verdade. Mesmo com `sync_to_physics`, o `_get_ticks_in_loop()` não roda tick quando o laço está mais de um tick à frente do relógio (`addons/netfox/network-time.gd`, `cf5189d`).
- Cada cenário custa o tempo de jogo dele, mais ~1 s para o Godot subir.
- As 32 divergências do duelo são as do lutador em pé na cabeça do outro (Q-16), como no Desenho 3.

## §2 — A sonda do replay

**A montagem:**
- Um projeto Godot 4.7.2 pequeno, sem netfox, com Jolt e 60 ticks de física.
- Uma cápsula com o kit v0 do `movimento.md`: corrida de 7 m/s, pulo de 1,2 m, 350 ms de subida e 280 de descida, coyote de 100 ms e buffer de 150 ms.
- A pista é uma linha: dois blocos de 1 m, um de 2 m colado ao segundo e paredes nas pontas. A câmera fica de lado.
- O arquivo do replay é um cabeçalho (formato, versão, altura do pulo, motor, plataforma, ticks por segundo, arena, posição inicial, número de ticks) mais uma linha `move,jump` por tick. O rastro guarda `tick,x,y,chão` por tick, com 9 casas.

**As gravações:**

| Gravação | Ticks | Bytes do replay | Pulos | Primeiro pulo |
|---|---|---|---|---|
| bot | 600 | 2.747 | 3 | — |
| Arthur, jogada 1 | 1.200 | 5.141 | 16 | tick 836 (13,9 s) |
| Arthur, jogada 2 | 1.200 | 5.455 | 48 | tick 197 (3,3 s) |

O replay em texto ocupa uns 4 bytes por tick com dois campos, mais uns 290 bytes de cabeçalho.

## §3 — O replay se repete idêntico na mesma build

- A gravação do bot com janela e a gravação sem janela deram o mesmo arquivo de replay e o mesmo rastro, byte a byte.
- O replay do bot rodado de novo sem tela, duas vezes num laço só e duas vezes um tick por quadro de física (com `--fixed-fps 60`), refez os 600 ticks com diferença de 0,000000000 m e o mesmo sha256 do rastro (`24af807c9372…`).
- As duas jogadas do Arthur, refeitas sem tela com as mesmas regras, bateram com a gravação em todos os 1.200 ticks. O replay com janela e o sem tela deram as mesmas posições, byte a byte.
- Velocidade: 600 ticks em 10 ms no laço e em 46 a 50 ms um tick por quadro; 1.200 ticks em 11 a 13 ms. O processo inteiro levou 0,4 s.

## §4 — A mesma tecla com outra regra

- **Pulo de 0,9 m:** a cápsula ainda sobe o bloco de 1 m. O fundo dela é redondo (raio 0,35 m) e, com o fundo acima de uns 0,65 m, a quina a empurra para cima. Com o bot, a maior distância foi 1,84 m, e os caminhos se juntaram de novo na parede. A figura da vitrine, que era só cinemática, não previa isso.
- **Pulo de 0,6 m:** a cápsula não sobe o bloco. Com o bot, ela ficou presa na frente do primeiro bloco, a até 15,0 m do caminho gravado.
- **Nas duas jogadas do Arthur, a separação começou exatamente no tick do primeiro pulo** (836 e 197). Antes dele, só houve corrida, que é igual nas duas regras. A maior distância foi de 15,05 m e de 15,29 m.

## §5 — Windows × Linux

Num runner `ubuntu-24.04` do GitHub, com o Godot 4.7.2 do `setup-godot@v2`, a sonda rodou os três replays gravados no Windows, com o pulo de 1,2 m e com o de 0,6 m, e comparou com os rastros do Windows (run 37661261172, branch `probe/replay-linux`, apagada depois).

| Replay | Pulo | sha256 do rastro no Linux | Diferença para o Windows |
|---|---|---|---|
| bot | 1,2 m | `24af807c9372…` | nenhuma: 0,000000000 m |
| bot | 0,6 m | `16041af827e7…` | nenhuma |
| jogada 1 | 1,2 m | `8c9c021af8e8…` | nenhuma |
| jogada 1 | 0,6 m | `92c5108e2a01…` | nenhuma |
| jogada 2 | 1,2 m | `4db1e197ce33…` | nenhuma |
| jogada 2 | 0,6 m | `79267639f0e9…` | nenhuma |

- Os seis rastros bateram byte a byte, com o mesmo sha256 dos rastros do Windows.
- No Linux, cada replay simulou em 6 a 10 ms.
- O limite: é uma cápsula, blocos parados e contas simples. Seno, cosseno e física com vários corpos não entraram nesta sonda.
