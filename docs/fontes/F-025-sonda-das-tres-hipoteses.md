---
id: F-025
titulo: A sonda das três hipóteses da DEC-0022 — SyncTest no netfox cf5189d, no Godot 4.7.2 com Jolt (sessão 4, 03/10/2026)
recebido_em: 2026-10-03
como: Execução do Claude Code na rodada 1 do Desenho 3 (TASK-5), num projeto de sonda fora do repositório, em `C:\Users\arthu\Projects\netfox-sonda\sonda` (F-023 §3). Os números são as linhas que a sonda imprimiu; as tabelas só os reorganizam.
status: vigente
substituida_por:
---

## §1 — A montagem

- **Projeto:** o netfox (core, extras e internals) copiado do commit `cf5189d`, com os autoloads em `res://`, Jolt explícito e o renderer Compatibility, como o do jogo (DEC-0002).
- **O lutador:** um CharacterBody3D com a cápsula de 1,8 × 0,35 m e o tick em sanduíche: decide, move e confere (DEC-0022). O estado de regras é trocado por um objeto novo a cada tick, como o `after_move()` fará. O RollbackSynchronizer grava `:position`, `:velocity` e nove campos `:state:*`.
- **A arena:** chão, uma plataforma de 1 m com beirada à esquerda e uma rampa de 45° à direita.
  - `floor_snap_length` de 0,3 m. A 7 m/s e 30 ticks, a rampa de 45° desce 0,233 m por tick (`movimento.md`); com um snap menor, a cápsula decola na descida.
- **O método, uma SyncTest no estilo do GGPO (F-007 §7):**
  - roda num processo só, sem rede, com o par offline do Godot;
  - a cada loop, a sonda manda o netfox voltar K ticks (`NetworkRollback.notify_resimulation_start`) e refazer;
  - cada tick refeito é comparado com o primeiro resultado daquele tick;
  - divergência é posição diferente em mais de 1 mm, ou `on_floor` ou `mode` diferentes;
  - K é 4 a 30 ticks e 7 a 60, a profundidade de um ping de 220 ms.
- **Os bots:**
  - "rampa": vai e volta pela plataforma, desce e sobe a rampa, cai da beirada, pula de volta na plataforma e dá um pulo no chão;
  - "duelo": dois lutadores que se miram, empurram por 1,2 s, recuam por 0,8 s, e um deles pula no meio do empurrão.
- 20 s por corrida (600 ticks a 30, 1.200 a 60), com o frame limitado a 144 fps.

## §2 — Hipótese 1: o caminho aninhado, na gravação e na restauração

- **O veneno:** depois de cada loop, a sonda estraga os campos aninhados (`mode` 99, `on_floor` invertido, `jumps_used` 77, `mode_since` −5). Se o netfox não restaurasse algum, o lixo vazaria para o tick refeito.
- Com veneno e com a variante D da hipótese 3: 0 divergências em 1.776 conferências a 30 ticks e em 7.134 a 60, erro máximo de 1 µm.
- Na rodada de diagnóstico, sem a variante D, o veneno também não mudou nada: 27 divergências com e sem veneno, nos mesmos ticks.
- O lado da rede é medido nas corridas com servidor e clientes (TASK-5, critério 5).

## §3 — Hipótese 2: um lutador contra o outro ao refazer

| Ticks | Sem o contorno do transform | Com o contorno no `after_prepare_tick` | Ticks com contato entre lutadores |
|---|---|---|---|
| 30 | 786 divergências, até 55 cm | 6, até 12,7 cm | 175 |
| 60 | 1.897, até 1,56 m | 32, até 15 cm | 307 |

- Com o contorno, todas as divergências (6 de 6 e 32 de 32) são com um lutador em pé na cabeça do outro, acima de 1,5 m. Nos empurrões de frente, nenhuma.
- Pôr os lutadores numa camada que não conta como plataforma (`platform_floor_layers` só com a arena) deu exatamente o mesmo resultado. A causa não é a velocidade de plataforma, e a causa exata não foi achada.
- Uma primeira versão do duelo, com os bots correndo só no eixo x, se desalinhou depois do primeiro choque e só teve contato nos 2 primeiros segundos: 90 contra 0 divergências a 30 ticks e 419 contra 1 a 60. Ela foi trocada pelo duelo com mira.

## §4 — Hipótese 3: `on_floor` no estado no lugar do movimento extra

| Variante | 30 ticks | 60 ticks |
|---|---|---|
| A, a da DEC-0022: só o `on_floor` no estado | 61 divergências, até 28,7 cm | 71, até 51,7 cm; o bot nem completou o percurso |
| B, o movimento de velocidade zero do netfox, a cada tick | 11, até 18,2 cm | 175, até 20,6 cm |
| D, o flag do motor alinhado com o `on_floor` no começo de cada rollback | 0, erro 0 | 0, erro 0 |

- **A variante C,** com o snap do motor desligado e a regra empurrando o corpo contra o chão, teve 0 divergências na rodada de diagnóstico. Mas ela não sobe a rampa de 45°: ficou 210 de 300 ticks parada na rampa, contra uns 30 das outras.
- **O mecanismo:** o `move_and_slide()` guarda o "estava no chão" do movimento anterior (`character_body_3d.cpp:95`) e usa esse valor no snap (linhas 394 e 495). Depois de um rollback, ele é do presente, não do tick restaurado.
  - Na A, o flag de chão troca com a posição idêntica (tick 38 da rodada de diagnóstico), e daí o pouso muda de tick.
  - Na B, o próprio movimento de velocidade zero usa o flag velho e puxou para cima da plataforma um corpo que estava 18 cm no ar (tick 183).
- **A variante D:** no primeiro tick de cada rollback, um micro-movimento de sonda, para baixo quando o estado diz chão e para cima quando diz ar, alinha o flag do motor. Depois a posição e a velocidade voltam ao que eram.
- **Custo:** a B faz um movimento extra por lutador a cada tick refeito, K + 1 por loop; a D faz um por lutador por loop.
- No duelo de 60 ticks da primeira versão, com o contorno do transform e a D, sobrou um flag de chão trocado num tick, com a posição idêntica até o micrômetro: 1 em 14.268 conferências.

## §5 — Float

- Com o frame sem limite, a variante D a 30 ticks deu 0 divergências e erro máximo de 0,000000 m. O resíduo de float do `physics_factor`, que compensa o tempo do frame no `move_and_slide()` (`network-time.gd`), fica abaixo de 1 µm nesta máquina.

## §6 — Limites

- Uma máquina, o mesmo binário e bots. A SyncTest mede se refazer dá o mesmo resultado, não a rede.
- A arena não tem parede de corrida nem gancho: as manobras da fase 1 não foram testadas.
