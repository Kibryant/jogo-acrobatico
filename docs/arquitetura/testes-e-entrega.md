---
revisado_em: 2026-10-26
fontes: [F-007, F-009, F-010, F-021, F-038, F-039, F-040, F-041, F-042, F-043, F-044, F-045, F-046, F-047, F-048, F-049, F-085, F-087, F-088, F-091, F-093, F-094, F-095, F-097, F-098, F-101, F-112, F-121, F-122, F-129, F-140, F-141, F-143]
---

# Testes e entrega

Estado atual: o Desenho 4 (TASK-6) fechado, com as DEC-0027 e DEC-0028. A parte 1 do esqueleto andante (TASK-9) trouxe o primeiro código de jogo; a parte 2, a rede e os scripts que a provam com processos de verdade; a parte 3, a esteira: as builds e a release no CI, a imagem do servidor e a referência.

- O portão, os canários e os hooks do Claude Code já rodam.
- A especificação, a checagem dos dados e a SyncTest nasceram na parte 1 da TASK-9; o aperto de mão, na parte 2; a referência, os jobs de build e de release e a imagem do servidor, na parte 3.
- O gravador do replay nasceu na TASK-10.3, com o tocador sem tela e o `--watch` (§4).
- O gancho, na TASK-10.6, trouxe a sonda B, a cena `gancho` da SyncTest e as colunas `pitch` e `grapple` do replay (§3; §4).
- A cabeça do outro, na TASK-10.7, trouxe a sonda C, a cena `cabeca` da SyncTest, o boneco do Sozinho, que o replay grava junto (`--dummy=off` o tira), e a borda da arena (§3; §4).
- A versão visual e interativa deste documento é a vitrine [A esteira por dentro](https://claude.ai/artifact/L9FpEtDFoyGJYWLSR6TFA1), privada (DEC-0019).

## 1. A esteira

O caminho de uma mudança até o jogo na mão de quem joga, com uma checagem em cada estação. Os tempos foram medidos neste PC (Ryzen 3 PRO 3200G) e no GitHub.

| Estação | O que confere | Tempo |
|---|---|---|
| O Claude edita | Os hooks: a trava do teste de aceite e o formatador (§9) | 0,2 a 0,8 s por hook; um `.gd` passa pelos dois (F-049 §6) |
| `git commit` | O pre-commit: gitleaks, formato e pureza | de 0,8 a 2,9 s nos commits, quase tudo o gitleaks (F-049 §2), de um teto de 15 (DEC-0027) |
| `git push` | O pre-push: o portão inteiro (§2) | 31 s, de um teto de 90 (F-049 §5) |
| O CI no GitHub | O gitleaks no histórico e o mesmo portão; no PR e na tag, as duas builds e o teste de fumaça; no push da main e no PR, a imagem do servidor; na tag, a release (§6) | no PR #8, o job do portão em 22 s, o de export em 48 a 57 s e o da imagem em 47 a 58 s |
| A build | O cliente Windows e o servidor Linux (§6) | o export dos dois em segundos, dentro do job de export |
| Quem joga | A versão certa, conferida na conexão (§7) | Desde a parte 2 da TASK-9 (`rede.md` §9) |

## 2. O portão (DEC-0027 §1)

O `tools/gate.sh` é o mesmo no pre-push e no CI. Ele para na primeira falha.

| Passo | O que pega | Tempo em 04/10, neste PC |
|---|---|---|
| Formato e lint | Código fora do formato do `gdscript-formatter` 0.27.0 | 0,6 s |
| Pureza do núcleo | Nó, relógio, timer ou sorteio sem semente em `core/`; o `#` dentro de string não esconde mais nada | 0,4 s |
| Assets e LFS | Um pack de terceiros sem linha no `CREDITS.md` ou sem o arquivo de licença, um arquivo solto, ou um formato da lista fora do LFS, provado pelo `git check-attr` (DEC-0029) | menos de 1 s (08/10) |
| Travas | Um teste de aceite travado que mudou | 0,2 s |
| Import | Um erro ao importar o projeto | 15,7 s (em outras rodadas, de 9,7 a 17,7 s; F-049 §1 e §5) |
| Compilar tudo | Um erro de tipo num script que nenhum teste carrega | 3,9 s |
| Testes | Uma falha, um erro, ou uma linha `ERROR:` no log com tudo verde | 9,7 s |

Os tempos são os da rodada B depois dos consertos (F-049 §5). O total foi 31,3 s; antes da rodada 1, era 28,3 s (F-049 §1).

- **Os canários** (`tools/canaries/`) são arquivos com erro de propósito: 9 para a pureza, 5 para os assets e 3 para a compilação. Se uma checagem perder uma regra, o canário dela falha. A prova: estragadas de propósito, as duas checagens fizeram os canários gritarem (F-039, contexto; F-049 §5).
- **O log limpo:** testes verdes com uma linha `ERROR:` reprovam. O bug #659 do netfox se escondeu assim no Desenho 3: saída 0, erro só no log (F-039 §2).
- **O `-c`:** o gdUnit4 mostra todas as falhas de uma vez, e não só a primeira (F-047 §1.8).
- **Sem o `--remote-debug`:** sem o `-d`, o Godot não tem depurador para travar num erro de sintaxe. A sonda mostrou a saída 105 em 7,1 s e as falhas relatadas como antes (F-049 §4).
- **Ainda sem canário:** o formato, o lint, as travas, o import e o log limpo (TASK-6, notas da rodada 1).

## 3. As camadas de teste (DEC-0027 §2)

| Camada | Pega o quê | Onde roda | Nasce | Quanto gasta |
|---|---|---|---|---|
| 1. A especificação | A regra do núcleo diferente do papel; o teste de unidade do Jest para função pura | portão | TASK-9 | sem medida |
| 2. A SyncTest | Estado escondido: refazer um tick dá outro resultado em qualquer campo do estado (DEC-0025; TASK-10.1) | portão | TASK-9, com os ticks à mão; o estado inteiro na TASK-10.1 | pelo relógio, ~6 s por cenário de 5 s (F-042 §1); à mão, as quatro cenas em uns 2,5 s (F-087 §1), as cinco da TASK-10.1 em 3,9 a 4,3 s, e as seis da TASK-10.4, com o dash, em uns 4,1 s; as cenas da parede, do gancho e da cabeça rodam em testes próprios, em uns 2,2, 1,4 e 0,9 s |
| 3. A checagem dos dados | Um número impossível num `.tres` | portão | com o primeiro `.tres` de design (F-048) | sem medida |
| 4. A referência | Uma mudança de código que muda o movimento sem querer; o snapshot do Jest | portão e CI | TASK-9, parte 3; regravada na TASK-10.1, com o pulo duplo, e na TASK-10.4, com o snap do dash | 1.200 ticks em uns 0,7 a 1,4 s neste PC e 0,14 s no Linux do CI, com a partida de verdade e o netfox; a sonda, sem os dois, fazia em 11 a 13 ms (F-042 §3) |
| O replay por inputs | Uma jogada que o tocador sem tela não refaz igual: a gravação, o arquivo e a refeita, byte a byte (§4) | portão, e à mão pelo `tools/replay.sh` | TASK-10.3 | 600 ticks gravados em uns 0,42 s e tocados em uns 0,3 s, neste PC |
| 5. A rede à mão | A sensação com lag | o Arthur, pelo `tools/play_online.sh` | TASK-9, parte 2 (F-091), e de tempos em tempos (DEC-0026) | o tempo dele, e o que ele sentiu (F-041) |
| As checagens com processos | O servidor e os clientes de verdade: as portas, o aperto de mão, a sala, o arquivo de parada, os códigos de saída e a previsão conferida com o servidor | à mão, fora do portão: `tools/net_check.sh` e `tools/net_run.sh` | TASK-9, parte 2 | 32 s e 36 s na revisão da parte 2 |
| A guarda das configurações | Uma configuração decidida que voltou atrás | portão | desde o Desenho 2 | dentro dos testes |
| Compilar tudo e os canários | §2 | portão | rodada 1 (F-039) | ~4 s e menos de 1 s (F-049 §5) |
| O teste de fumaça da build | O servidor exportado não sobe, não traz o carimbo do commit, ou não fecha com código 0 | CI, no job de export (`tools/smoke_test_server.sh`) | TASK-9, parte 3 | no PR #8, o servidor escutou 208 ms depois de subir e fechou pelo arquivo de parada em 1,1 s |
| A imagem do servidor | A imagem Docker não sobe, o aperto de mão falha, outra build entra, ou o servidor não fecha com 0 | CI, no push da main e no PR, fora do portão (DEC-0032 §1; `tools/server_image_check.sh`) | TASK-9, parte 3 | 25 s de checagem; a imagem tem 153 MB e fica pronta em 0,45 s (PR #8) |

**A SyncTest com os ticks à mão.**
- Pelo relógio do netfox, cada cenário custa o tempo de jogo dele, e o `--fixed-fps` não acelera (F-042 §1).
- A SyncTest da TASK-9 avança os ticks como a suíte do próprio netfox faz em `test/network-mocks.gd`: chama `NetworkTime._before_tick_loop()`, os sinais do tick e `_after_tick_loop()`. Assim ela roda o rollback de verdade dele sem esperar o relógio.
- É a exceção escrita à regra de testar só por interface pública. O netfox está fixado no `cf5189d` (DEC-0023), e atualizá-lo já é uma DEC nova, com a SyncTest refeita (F-044 §2).
- O ajudante `test/support/netfox_ticks.gd` faz isso para toda suíte que roda o netfox, e não só para a SyncTest: o lutador, a entrada, a rampa, a partida e a Main. As 4 chamadas privadas dele declaram a exceção ao linter, linha a linha, com o ok do Arthur (F-085 §1; F-088 §1).
- Os ticks rodam dentro de um frame de física: ali o `physics_factor` do netfox vale 1, e o `move_and_slide()` anda o passo fixo da física, então um tick anda exatamente um tick.
- O tempo das cenas aparece em toda rodada do portão, sem trava: uns 2,5 s para as quatro da TASK-9 com o PC quieto, até o triplo com o PC ocupado (F-087 §1); 3,9 a 4,3 s para as cinco da TASK-10.1, no portão em silêncio; uns 4,1 s para as seis da TASK-10.4. Nas rodadas da TASK-10.6, as seis deram de 5,4 a 5,8 s, acima dos 5 s do orçamento já antes de qualquer regra do gancho; a cena do dash variou de 1,3 a 1,7 s entre duas rodadas do mesmo código.
- **O estado inteiro** (TASK-10.1, critério 8; F-101 §1): o observador, `test/support/sync_observer.gd`, compara a posição, a velocidade e todo campo do `FighterState`, achado por reflexão na classe, além do "todo campo gravado" do plano: um campo escondido do netfox continua comparado, e o teste de veneno o vê (TASK-10.1, rodada B). Inteiros, booleanos, enums e nomes têm de ser iguais; floats e vetores, até 1 µm. É trocar um `expect` de três campos por um `toEqual` do objeto inteiro. O erro medido foi zero exato nas cinco cenas, e a conferência da rede ficou em 1 mm (`rede.md` §4).
- **Os venenos:** tirar o `on_floor`, o `stamina_at_spend`, o `double_jump_tick`, o `dash_tick` (TASK-10.4), o `wall_id` (TASK-10.5), o `grapple_point` (TASK-10.6), o `slide_off_dir` (TASK-10.7) ou o `jumps_used` (TASK-10.13) do que o netfox grava faz a SyncTest acusar. Os quatro últimos são a prova de que ela compara o estado inteiro: com a comparação antiga, passariam calados (TASK-10.1).
- **A cena do dash** (TASK-10.4, critério 6): o dash no plano, descendo a rampa sem tick no ar, contra a parede, saindo da beirada, guardado no ar e guardado pela barra, recusado na recarga e pela barra, e um pulo no fim. O resumo traz os contadores, e o portão exige cada um: `dashes=6 ramp_dash_ticks=4 ramp_dash_air_ticks=0 ledge_dashes=1 blocked_dashes=1 buffered_dashes=2 refused_cooldown=1 refused_stamina=2 jumps_after_dash=1`, com zero divergência. A barra de 20 da cena faz a recarga acabar sempre antes da barra (`rede.md` §4).
- **Os sinais das manobras:** nas cenas do pulo duplo, do dash, da parede, da mesma parede, do gancho e da cabeça, os sinais apresentados têm de ser iguais aos eventos, e os eventos às manobras (DEC-0031 §6; TASK-10.4, critério 5). No gancho, o cabo e o rastro da puxada tocam uma vez por chave, e um teste próprio desenha o cabo, opaco e de 3 cm, com a ponta chegando ao ponto em 100 ms contados em ticks do netfox (TASK-10.6). Na cabeça, o rastro curto toca uma vez por pouso, e, com tela, um teste próprio o vê seguir o escorregão e sumir sozinho (TASK-10.7). Um teste próprio, `test/fighter/maneuver_cues_test.gd`, confere que o sinal toca uma vez por chave, que o rollback de 7 ticks não o toca de novo e que, com tela, o rastro e a baforada aparecem e somem sozinhos.
- **A cena da parede** (TASK-10.5, critério 7): a cena `parede` roda num teste próprio, com paredes que ela constrói na arena: as entradas, o fim por tempo, a borda, os pulos de uma parede para a outra, a recusa da mesma parede depois do fim por tempo (DEC-0048 §2), a volta na mesma parede no voo de um pulo da parede, sem devolver o pulo duplo (DEC-0047), um pulo duplo depois do pulo da parede e uma emenda atravessada (F-129). O portão exige cada contador e que os sinais sejam tantos quanto os pulos da parede e os pulos duplos; o veneno no `:state:wall_id` a faz acusar (`rede.md` §4).
- **A cena da mesma parede** (TASK-10.13, critério 5): a cena `mesma_parede` roda num teste próprio, nas paredes da cena `parede`, com o fake na parede: o pulo da parede, o pulo duplo de volta para a mesma, a corrida nova sem devolver o pulo duplo, o aperto no ar que não acha pulo duplo e a outra parede que o devolve. O portão exige a volta na mesma parede com o pulo duplo gasto, nenhuma volta que devolva algo, o aperto recusado, a outra parede renovando e os sinais tantos quanto os pulos e as corridas; o veneno no `:state:jumps_used` a faz acusar (`rede.md` §8; DEC-0047; DEC-0048).
- **A cena do gancho** (TASK-10.6, critério 8): a cena `gancho` roda num teste próprio, com paredes que ela constrói na arena, longe das formas dela, e a recarga de 500 ms. Ela passa pelas três solturas, pela distância, pelo pulo e pela trava, por um erro no céu e por um aperto recusado na recarga. O portão exige cada contador, que os sinais sejam tantos quanto os disparos e as puxadas, e que cada disparo saia de novo nos ticks refeitos: só um raio lançado de novo dá isso. O veneno no `:state:grapple_point` a faz acusar (`rede.md` §8).
- **A cena da cabeça** (TASK-10.7, critério 3): a cena `cabeca` roda num teste próprio, no noroeste vazio da arena. Um lutador fica parado, e o outro pousa na cabeça dele duas vezes, com o pulo e o pulo duplo, aperta o pulo lá em cima, que fica na vaga, e escorrega. O portão exige 2 pousos, 2 escorregões, 1 pulo recusado e 1 colisão, nenhum tick em pé na cabeça e os sinais tantos quanto os pulos duplos e os pousos; o veneno no `:state:slide_off_dir` a faz acusar (`rede.md` §8).
- **O teste da rampa no motor** (`test/fighter/fighter_slope_test.gd`; TASK-10.4, critério 4): um dash do alto de um bloco, pela crista, desce a rampa de 45° no chão em todos os 12 ticks com o snap de 0,338 m; com o snap da TASK-9, de 0,121 m, a mesma arrancada sai do chão em 9 dos 12.
- **A sonda A da parede** (`test/fighter/engine_probe_test.gd`; TASK-10.5, critério 1; DEC-0042 §4): antes de qualquer regra da parede, o lutador de verdade bate numa parede de teste de dois colisores, desliza, cruza a emenda, passa o canto e corre paralelo a ela, de 0 a 4,5 cm, com o rollback de 7 ticks a cada loop. Os fatos da parede, das colisões do movimento e da sonda só de teste, saem iguais no tick novo e no refeito: 0 divergência em 2.634 conferências, em 10 voos. Cada voo prova as precondições: os ticks refeitos que o netfox devia, o contato, a emenda e o canto; a 6 cm, a sonda prova que sabe dizer não. Ela imprime a taxa de ticks sem colisão do movimento correndo paralelo (100 %), os ids e RIDs dos colisores em três construções e a medida do empurrão de 1 m/s, que trava na emenda. Os números estão no `rede.md` §4. Os dez voos levaram uns 3,7 s com o PC ocupado (23/10/2026). Desde a rodada B, os voos nunca entram na corrida: a sonda mede o motor, e a cena `parede` mede a regra.
- **A sonda B da mira** (`test/fighter/aim_probe_test.gd`; TASK-10.6, critério 1; DEC-0044 §4; TASK-10.11, critério 3): antes de qualquer regra do gancho, o lutador de verdade voa a 8 m/s e, a cada tick, lança a mira de 25 m pelo próprio `Fighter.aim_ray`, com a mira que viaja no input. Desde a TASK-10.11, o raio sai do ponto O, 0,8 m à direita do ombro, e um segundo raio, do ombro ao ponto, recusa a quina (DEC-0045). Ela confere o tick refeito contra o novo e contra a mesma mira num quadro de processo: 0 divergência em 333 de 333 e em 60 de 60, em cada um dos dois voos, com 30 acertos, 30 erros e as 10 miras de quina recusadas. Ela imprime o tempo de 1.000 miras: de 9 a 10 µs por mira em rodízio, de 10,7 a 10,8 µs num acerto, com os dois raios, e de 4,3 a 5,3 µs num erro. Os números estão no `rede.md` §4.
- **A sonda C da cabeça** (`test/fighter/head_probe_test.gd`; TASK-10.7, critério 2; F-025 §3): antes da regra da cabeça, dois lutadores de verdade num chão de teste, um parado e o outro pousando na cabeça dele com o pulo e o pulo duplo, com o rollback de 7 ticks a cada loop. Ela mede, nos ticks refeitos contra os novos, o corpo, o estado e os fatos do motor: o chão, a normal dele, a velocidade de plataforma, as colisões do movimento e uma sonda só de teste 5 cm para baixo. Os voos são centrado, a 0,30 m do eixo e com a cabeça andando, com as camadas de plataforma do Godot e com as do lutador. Antes da regra, ela deu 0 divergência e velocidade de plataforma zero; sem a reserva do snap da DEC-0037, numa cópia local, as divergências do Desenho 2 voltaram. Desde a regra, ela afirma zero divergência, o lutador de baixo nomeado pela sonda em todo tick na cabeça e nenhum tick em pé nela. Os oito voos levam uns 7 s. Os números estão no `rede.md` §4.

**A referência (golden master).**
- É um percurso fixo de bot, de 1.200 ticks, na arena de verdade, no Sozinho, com os ticks à mão (`test/reference/`). O percurso é uma tabela no teste, e não um arquivo de replay: o gravador, que nasceu na TASK-10.3, grava o Sozinho de quem joga (§4).
- O teste guarda o rastro do caminho, com a posição em 9 casas e o chão de cada tick, e confere o sha256 no portão, no Windows, e no CI, no Linux. Os dois deram o mesmo, `b73cccbc…` (PR #8). Quando difere, ele mostra o primeiro tick diferente.
- **Regravada na TASK-10.1** (critério 8): o aperto no ar do passo 513 virou pulo duplo. O percurso ganhou um aperto no topo do salto do passo 480, o pulo duplo, e o aperto da vaga passou do passo 513 para o 537, porque o pulo duplo alonga o voo. O caminho é o mesmo até o passo 499, e o rastro novo é `d53a533c…`. Ele cobre um pulo duplo a mais, segue sem rampa e com o yaw 0, e a prova no Linux espera o push (F-101 §1).
- **Regravada na TASK-10.4:** o snap do chão passou de 0,121 para 0,338 m, para o dash descer a rampa. A cápsula que sai da quina da plataforma, apoiada na base redonda, desce um pouco mais pela quina: o caminho se separa no tick 233 (y 0,999071 contra 0,998995) e chega no máximo a 1,2 mm, no tick 1154. O percurso cobre o mesmo, com os mesmos contadores, e não aperta o dash; o rastro novo é `3a877934…`, e a prova no Linux espera o push.
- O percurso olha sempre para a mesma direção e não passa pela rampa, porque seno e cosseno podem diferir no último bit entre os dois sistemas, e a sonda só provou o caminho sem eles (F-042 §5). A SyncTest segue cobrindo a rampa.
- Ela usa uma cópia congelada dos números do movimento, só do teste. O ajuste fino do jogo não quebra a referência; só uma mudança de código quebra. Se ela reprovar sem uma mudança de movimento de propósito, o primeiro passo é investigar (F-094 §2).
- Regravar é um comando, `bash tools/record_reference.sh`, como o `jest -u`, e o commit diz por quê (F-044 §2).

**A física na thread principal.** O `physics/3d/run_on_separate_thread` fica em `false`, o padrão do Godot, e o teste de configurações guarda. O rollback refaz vários `move_and_slide()` por passo de física, um por tick refeito, e uma thread separada só ajudaria com física pesada. A pergunta volta na medição com 16 bots (DEC-0004, regra 6). O motivo antigo, o laço de ticks no `_process`, deixou de valer com a DEC-0040 (F-122).

**O que não cabe nos 90 s** vira um job do CI fora do pre-push, com uma DEC nova (DEC-0027 §4).

## 4. O replay por inputs (DEC-0027 §5)

É event sourcing: guarda o input de cada tick, e não o vídeo, como o Redux DevTools, que refaz a tela pelas actions. Para assistir, o jogo roda a partida de novo. Nasceu na TASK-10.3.

**O gravador** (`replay/replay_recorder.gd`):
- O Sozinho grava toda sessão, sempre, em `user://replays/`, guardando os 20 arquivos mais novos (F-112 §2). No Windows, a pasta é `%APPDATA%\Godot\app_userdata\Jogo Acrobático\replays\`, e o log diz o caminho completo de cada arquivo, `sozinho-AAAAMMDD-HHMMSS.replay`.
- `--replay=CAMINHO` grava num arquivo, `--replay-dir=PASTA` em outra pasta, e `--no-replay` desliga. O cliente e o servidor não gravam na v1.
- **O boneco** (TASK-10.7, critério 5): o Sozinho põe um lutador parado no segundo ponto de nascimento, dirigido por este PC sem câmera, sem teclado e sem bot, e o replay grava os dois. O `--dummy=off` o tira, e só vale no Sozinho que se joga: o servidor, o cliente e o `--watch` o recusam. O `--watch` toca os dois lutadores do arquivo, com os tons do jogo: o do jogador no primeiro, o do outro no boneco (`Match.solo_tone`). O `--measure-fps` do Sozinho também mede com o boneco na tela. A borda mudou a impressão da arena: um replay gravado antes dela toca só com `--force`.
- Ele salva a cada segundo (`FileAccess.flush` a cada 60 ticks): um fechamento brusco perde no máximo o último segundo. O teste lê o arquivo com o gravador ainda aberto, o que um fechamento brusco deixaria no disco, e o arquivo toca (leitura v0 do Claude, TASK-10.3).
- Ele só lê: escuta o `after_process_tick` do netfox, como o `TickRecorder`, e anota o input que o netfox restaurou para aquele tick.
- **O lutador existe para o netfox antes do primeiro tick.** O `RollbackSynchronizer` do netfox registra a entrada, o estado e a simulação do lutador só quando o Godot esvazia as chamadas adiadas (`process_settings.call_deferred`, `rollback-synchronizer.gd`). Com o tick no passo de física (DEC-0040), o primeiro passo do jogo aberto roda antes disso. Um lutador criado no `_ready` da `Main` ficava parado nos primeiros ticks, sem simulação e sem input anotado.
  - A gravação de 23/10 tinha `first_tick=0` e começava no tick 2, e o tocador a recusou (F-118, contexto).
  - Por isso o Sozinho e o `--watch` começam a sessão no primeiro quadro (`Main._first_frame`). O quadro esvazia as chamadas adiadas antes do próximo passo de física.
  - Um teste da `Main` abre o Sozinho logo antes de um passo de física, que é a mesma ordem. Ele confere que a primeira linha é o `first_tick` e que o tocador refaz o arquivo sem se separar da coluna `check`. Sem a correção, o teste vê a primeira linha no tick 1.

**O portão nunca escreve em `user://replays/`** (critério 1 da TASK-10.3). Os testes da `Main` passam `--no-replay` ou gravam numa pasta temporária, como os do gravador. Depois de cada rodada, o `tools/run_tests.sh` reprova se achar ali um arquivo mais novo que ela; um teste diz onde a pasta fica nesta máquina. A prova: tirar o `--no-replay` de um teste da `Main` reprovou a rodada, com o arquivo nomeado.

**O portão nunca escreve no `user://options.cfg`** (TASK-10.9). É o arquivo de opções de quem joga: as teclas das sete ações, a sensibilidade do mouse e a escala da interface (`ui/options/options_store.gd`; `visual-e-audio.md`, "A tela de opções"). No Windows, fica em `%APPDATA%\Godot\app_userdata\Jogo Acrobático\options.cfg`, e o log da `Main` diz o caminho ao abrir o jogo. O caminho é um parâmetro do `OptionsStore` e da `Main` (`options_path`): os testes usam um arquivo temporário cada um e nunca leem nem escrevem o do jogador. Depois de cada rodada, o `tools/run_tests.sh` reprova se o arquivo for mais novo que ela, como faz com a pasta dos replays; um teste diz onde ele fica nesta máquina. A prova: tocar o arquivo no meio de uma rodada a reprovou, com o arquivo nomeado. Um teste que provoca de propósito o erro de leitura do `ConfigFile` desliga as mensagens do motor só durante aquela leitura, para o log verde seguir sem `ERROR:`.

**O arquivo, formato 1** (`replay/replay_file.gd`):
- Texto em UTF-8, com `\n`. O cabeçalho vem em linhas `chave=valor`: formato, versão, commit, impressão das regras, motor, plataforma, ticks por segundo, `physics_ticks_per_second`, `sync_to_physics`, `max_ticks_per_frame`, `input_delay`, a arena e a impressão dela, a semente, a configuração inteira, os lutadores, o primeiro tick e as colunas declaradas (F-044 §2).
- A configuração vai inteira, um campo do `MovementData` por linha, tipado (`config.jump_height_m:f64=...`). O tocador toca com esses números mesmo depois de um ajuste no `.tres`.
- Depois do `---`, uma linha por tick e lutador: o tick absoluto do netfox, o tamanho do laço que o rodou, o lutador, o input (`move.x`, `move.y`, `yaw`, `pitch`, `jump`, `dash` e `grapple`; o `dash` desde a TASK-10.4, o `pitch` e o `grapple` desde a TASK-10.6) e a coluna `check`.
- **Os floats vão como os 8 bytes do double, em 16 dígitos hexadecimais.** O `%.9f` perde bits perto de π, e um yaw de mouse nunca é redondo (F-042 §3). Uma célula que não tem exatamente 16 dígitos hexadecimais minúsculos é recusada antes de ser lida, nunca lida como 0. Os bools vão como 0 e 1; um texto, como os bytes UTF-8 em hexadecimal.
- **As colunas declaradas** saem do `TickInput` por reflexão, e o leitor acha cada uma pelo nome: um campo novo do input entra no arquivo sozinho. O `dash` entrou assim na TASK-10.4, e um arquivo gravado antes dele toca só com `--force`, com o `dash` falso em todo tick. O `pitch` e o `grapple` entraram do mesmo jeito na TASK-10.6. A tampa da arena (TASK-10.15; DEC-0049) mudou a impressão da arena: um replay gravado antes dela é recusado como de outra arena e toca só com `--force`.
- **Um arquivo da TASK-10.3** não tem o `dash`, o `pitch` e o `grapple`, e tem só os 18 números do `MovementData` de então. O tocador o recusa e nomeia cada coluna e cada número que faltam. Com `--force`, toca todo tick, com as colunas que faltam no padrão do `TickInput` (0 e falso) e os números que faltam tirados do `movement_v0.tres`. Um teste do portão prova isso com a corrida do portão reescrita como a TASK-10.3 a gravaria (TASK-10.6, critério 2).
- **Um arquivo mais velho se separa da coluna `check` no tick 0.** A impressão do estado vem da linha do rastro, com todo campo do `FighterState`, e cada campo novo, os do dash, da parede e do gancho, muda a linha de todo tick. Um arquivo gravado antes de um campo novo toca todo tick com `--force`, mas o tocador aponta a primeira divergência no tick 0. No teste do portão, a corrida reescrita traz a coluna `check` desta build e se separa no tick 367, o primeiro aperto do dash que a coluna apagada levou.
- **A impressão das regras** é o sha256 dos scripts e das cenas que movem o corpo (`core/`, `fighter/`, `match/`, `arena/` e `common/`, com as camadas de colisão, mais os `.gd` de `data/`) mais a fixação do netfox, `cf5189d`. É calculada dos arquivos quando o jogo roda do código-fonte, como o Arthur joga; na build exportada fica vazia, porque o commit já diz qual é. O tocador só compara quando as duas existem.
- **A impressão da arena** é o sha256 de toda `CollisionShape3D` da arena (caminho, tamanho da caixa e posição) e dos pontos de nascimento. Uma forma que não seja caixa a deixa vazia, e o arquivo é recusado até ela ganhar nome no código.
- **A impressão do estado**, a coluna `check`, são 8 dígitos do sha256 da linha do rastro de estado depois de cada tick ao vivo.

**O tocador sem tela** (`bash tools/replay.sh ARQUIVO`):
- Ele roda a partida de verdade pela `Match`, no Sozinho, com os números do cabeçalho, laço a laço como foi gravado.
- O relógio do netfox começa no primeiro tick gravado, pelo ajudante dos testes (`test/support/netfox_ticks.gd`, a exceção da DEC-0027 §3). Um salto do relógio gravado, depois de um travamento de mais de 1 s, é tocado como o mesmo salto.
- A entrada de cada tick é a linha gravada, exatamente: o `FighterInput` continua o único que escreve a caixa, sem a média nem o `limit_length` do amostrador.
- Ele imprime os ticks, o sha256 do rastro de estado e o primeiro tick em que o estado se separa da coluna `check`. `--trace=SAÍDA` escreve o rastro, `--readable=SAÍDA` uma cópia do arquivo em decimal, que nenhum tocador toca, e `--force` toca um arquivo de outra build.
- **O rastro de estado** tem uma linha por tick e lutador, com o estado inteiro: a posição, a velocidade e todo campo do `FighterState`, por reflexão. Um vetor do estado, como o `dash_direction`, vira três colunas, `.x`, `.y` e `.z`, como a posição, e o cabeçalho tem um nome por célula (TASK-10.4). Os ticks e os carimbos do estado contam a partir do primeiro tick gravado, e o `NEVER` fica `NEVER`.
- No portão, um teste grava uma corrida de 600 ticks com yaw e move fracionários, laços de 2 e 3 ticks, 8 pulos duplos e, desde a TASK-10.4, 4 dashes, prova essa precondição e prova que a refeita dá o mesmo rastro byte a byte, duas vezes com o mesmo sha256. Gravar levou uns 0,42 s, e tocar, uns 0,3 s.
- Desde a TASK-10.5, a corrida abre com uma corrida na parede e um pulo da parede na face leste da `PlataformaVaoA`, e o rastro tem os campos da parede com uma parede neles. A precondição ganhou os dois: 1 corrida e 1 pulo da parede, e a corrida segue com 5 pulos duplos e 4 dashes, igual byte a byte.
- Desde a TASK-10.6, a câmera da corrida olha para baixo com um `pitch` de muitas casas em cada laço, e ela aperta o Q duas vezes: olhando para baixo, o raio acha o chão alguns metros à frente. No portão de 26/10/2026: 280 ticks com `pitch`, 2 apertos e 1 gancho que prendeu e puxou, igual byte a byte; a corrida segue com 2 pulos duplos e 4 dashes. Um teste próprio grava uma sessão curta com o gravador de verdade e prova que o `pitch` volta com todos os bits e o `grapple` no seu tick, do input ao arquivo e de volta à caixa.

**O que o tocador recusa** (critério 7 da TASK-10.3; F-042 §4):

| Caso | O que acontece |
|---|---|
| Outro formato, outros ticks por segundo, outra arena, outra configuração de física ou de relógio; uma coluna desconhecida; uma linha quebrada; uma célula malformada; fim de linha CR | Recusa e diz o campo; nem o `--force` toca |
| Outra versão, outro commit, outro motor, outra impressão das regras ou da arena; uma coluna de input que falta; um campo da configuração que falta ou que a build não conhece | Recusa e diz qual; com `--force`, toca, e a coluna que falta recebe o valor padrão do `TickInput` com um aviso que a nomeia |
| Outra plataforma; a última linha ou o último laço cortados | Avisa: descarta o pedaço cortado e toca o resto |

**O `--watch`** (`bash tools/replay.sh ARQUIVO --watch [--max-fps N]`):
- É o jogo no Sozinho, com o relógio de verdade, a entrada do arquivo, a câmera no lutador, o HUD e o texto de fim, por chave de tradução.
- Ele nunca escreve no relógio do netfox, que é código de jogo. Toca as linhas em ordem, a partir do próprio primeiro tick, e um salto do relógio gravado vira ticks seguidos ali.
- Ele anota o tamanho de cada laço que rodou. Com `--trace=SAÍDA`, ele escreve o rastro e os laços ao lado (`SAÍDA.loops`) e fecha; o tocador sem tela toca o mesmo arquivo e diz se os dois rastros batem ou onde se separam.
- `--max-fps N` limita os quadros a N, com o vsync desligado para o limite valer acima dos 60 Hz da tela.

**A medição do critério 5 (19/10/2026, neste PC).**
- O arquivo é a corrida do teste do portão, gravada sem tela pelo `bash tools/replay.sh --sample=ARQUIVO`: 600 ticks.
- A CPU estava entre 46% e 64% ocupada por outros programas. A tela é de 60 Hz.

| Quem tocou | Igual ao sem tela? | Primeiro tick diferente | Laço ali (janela / gravado) | Maior distância na posição |
|---|---|---|---|---|
| Sem tela, duas vezes | Sim, sha256 `312cbd75…` nas duas, igual ao da gravação | — | — | 0 |
| Janela, 30 quadros por segundo | Não | 3, a velocidade em x | 2 / 2, o mesmo tamanho | 3,1 µm |
| Janela, 60 | Não | 13, a posição em y | 1 / 2 | 2,4 µm |
| Janela, 144 | Não | 6, a posição em x | 1 / 3 | 2,0 µm |

- Em todas, a diferença começa no último bit de um float de 32 bits e fica em micrômetros nos 600 ticks.
- Nenhum campo discreto se separou: chão, modo, pulos usados e carimbos ficaram iguais em todo tick.
- Duas janelas a 60 também saíram diferentes entre si.
- **A causa provável:** no jogo, os ticks rodavam no `_process` (até a DEC-0040). Ali, o `physics_factor` vale o tempo do tick dividido pelo do quadro, e o `move_and_slide()` usa o tempo daquele quadro. O tocador sem tela roda dentro de um quadro de física, onde o fator vale exatamente 1 (`network-time.gd`). Duas medidas apontam para isso:
  - a 30 quadros, o laço tinha o mesmo tamanho do gravado, e o rastro se separou assim mesmo;
  - no portão, o mesmo `ReplayWatch`, rodando dentro de um quadro de física, a partir do tick 37 e em laços de 1 tick, refaz byte a byte a gravação feita do tick 1000 em laços de 1 a 3. Nem o tick de começo nem o tamanho do laço separam o rastro; o tempo do quadro do `_process`, sim.
- **O que isso quer dizer:** o tocador sem tela refaz o arquivo e a si mesmo byte a byte, mas não o que a janela calculou. Um bug que dependa de um micrômetro pode aparecer ao vivo e não no replay.
- A escolha do `sync_to_physics` voltou ao Arthur com estes números antes da TASK-10.4 (F-025 §5; F-112, contexto). A sonda de 23/10 confirmou a causa com o replay de 11 180 ticks dele: desligado, a janela se separa entre o tick 342 e o 408, com até 5 a 13 µm, a 30, 60 e 144 fps; ligado, sai igual byte a byte em todos. O Arthur ligou o `sync_to_physics` (DEC-0040; F-117).

**O tamanho:**
- Desde a TASK-10.6, uns 93 bytes por tick e lutador, com os floats em hexadecimal e o tick de 5 dígitos, mais uns 2,4 KB de cabeçalho, com os 44 números da configuração. Eram 71 bytes na TASK-10.3; o `dash`, o `pitch` e o `grapple` somaram 22.
- Dá uns 335 KB por minuto de jogo e 5,0 MB a cada 15 minutos. Os 20 arquivos, se todos tivessem 15 minutos, somariam uns 100 MB, na beira dos "menos de 100 MB" da escolha do Arthur, feita com 4 MB a cada 15 minutos (F-112 §2).
- A sonda, com dois campos em texto, gastava uns 4 bytes por tick (F-042 §2).

**Só reproduz na mesma build.**
- A mesma tecla, com outra regra, leva o boneco a outro lugar.
- Na sonda, com o pulo trocado de 1,2 para 0,6 m, as duas jogadas do Arthur se separaram exatamente no tick do primeiro pulo e chegaram a 15 m de distância (F-042 §4).
- No portão, um cabeçalho com outra altura de pulo separa a refeita da coluna `check` no tick do primeiro pulo.

**No Windows e no Linux:** os seis replays da sonda deram o mesmo sha256 (F-042 §5). Vale para a cápsula de hoje; seno, cosseno e física com vários corpos não passaram por essa prova. Se um dia divergirem, a referência vale só no Linux (DEC-0011; F-048).

**O que precisa continuar verdade** (F-044 §2):
- todo sorteio tem semente e mora no estado; a semente do cabeçalho é 0, porque nada sorteia ainda;
- o núcleo não lê relógio (DEC-0004);
- a build carrega a versão.

**Para que mais serve:**
- reproduzir sem tela o bug que o Arthur achar jogando: o arquivo vai junto (F-044 §1; `rede.md` §8);
- a referência (§3);
- rever denúncia contra trapaça (Q-19);
- o fantasma do percurso cronometrado e o replay que marca o erro (`visao.md`), na fase 2.

## 5. Os ambientes (DEC-0028 §5)

| Ambiente | O que roda ali |
|---|---|
| O PC do Arthur | O editor, o portão local e as sondas, fora do repositório (`../netfox-sonda`, `../replay-sonda`, `../export-sonda`) |
| O CI no GitHub (Linux, `ubuntu-24.04`) | O portão; no PR e na tag, as duas builds; no push da main e no PR, a imagem do servidor; na tag, a release |
| A build de teste | O artefato do PR, por 3 dias, ou a release da tag |
| O servidor de verdade | Desenho 6 (TASK-8) |

O endereço do servidor vem dos argumentos da Main (DEC-0026).

## 6. As builds (DEC-0028 §1 e §2)

**Os dois presets, no `export_presets.cfg`:**

| Preset | Plataforma | O que tem | Tamanho medido |
|---|---|---|---|
| Cliente Windows | Windows Desktop, x86_64 | PCK embutido; ícone e versão do `.exe` escritos pelo Godot, sem rcedit (F-047 §1.5) | 109 MB (F-045 §2) |
| Servidor Linux | Linux, x86_64 | PCK embutido; servidor dedicado, com a feature tag `dedicated_server` e sem a parte visual (F-047 §1.6) | 74 MB (F-045 §2) |

- **O que fica fora:** `test/*`, `addons/gdUnit4/*`, `tools/*` e `reports/*`. Neste PC, o pacote do jogo teve 163 arquivos (~216 kB), sem nenhum desses (F-045 §2). No CI, o conteúdo do pacote não foi listado.
- **A build roda o jogo inteiro:** sem argumento, o Sozinho; com `--server`, ou exportada como servidor dedicado, o servidor; com `--connect`, o cliente (`rede.md` §9).
- **O job de export** (`.github/workflows/ci.yml`; `tools/export_builds.sh`): carimba o commit (`tools/stamp_build.sh`), importa antes de exportar, exporta os dois presets, confere que cada arquivo está inteiro e roda o teste de fumaça do servidor. No PR, ele exporta o commit da branch, que é o que o carimbo nomeia, e não o commit temporário de merge do GitHub.
- **Os templates:**
  - neste PC, só os de Windows e Linux, baixados pelo editor: 344 MB no disco, contra 1,28 GB do pacote inteiro (F-045 §1);
  - no CI, o `setup-godot` baixa o pacote inteiro, em 51 s, ou restaura do cache em 30 s (F-045 §3; F-047 §1.4).

**Quando a build sai:**
- **No PR,** guardada por 3 dias.
- **Na tag `v0.y.z`,** como release.
- **No push da main, nenhuma build fica guardada** (F-046 §1). O job da imagem exporta o servidor só para testá-lo, e não guarda nada (DEC-0032 §1).

**A conta da cota:**
- o plano Free dá 2.000 minutos de CI por mês e 500 MB para artefatos, divididos com os pacotes; o artefato fica 90 dias se ninguém disser outra coisa (F-047 §1.1);
- uma dupla de builds compactada pesa 68,4 MB (F-045 §3); três PRs abertos ocupam uns 200 MB (3 × 68,4);
- o arquivo de uma release não entra nessa conta, até onde a documentação diz, mas isso não está confirmado (F-047 §1.1);
- o job de export da sonda levou de 57 a 83 s (F-045 §3); o da TASK-9, de 48 a 57 s, e a dupla de builds compactada, 68,5 MB (PR #8).

**Os riscos do export:**
- **O #123712:** o Godot cai ao sair depois de exportar no Linux, com código 134. Não apareceu em quatro exports da sonda, dois neste PC e dois no CI (F-045 §2 e §3; F-047 §1.6). O job da TASK-9 registra o código de saída, mas quem decide é o arquivo da build, que precisa estar inteiro e terminar com a assinatura do pacote, e o teste de fumaça (`tools/export_builds.sh`; `tools/build_lib.sh`).
- **O erro conhecido do servidor de release:** depois que um cliente usou RPCs, o servidor Linux exportado imprime, ao fechar a conexão, uma linha `ERROR: Attempt to disconnect a nonexistent connection … Signal: 'tree_exited', callable: ''.` por nó. É um bug do Godot 4.7.2 que só a build de release do Linux mostra (Godot #123751, fechado como "não planejado"); nada muda para quem joga. Só o job da imagem deixa essa linha exata de fora e a conta no relatório; o teste de fumaça segue reprovando qualquer `ERROR` (F-097).
- **O #1324 do gdUnit4:** derruba o primeiro export feito sem a pasta `.godot`. O import roda antes do export, e o gdUnit4 fica fora do pacote (F-047 §1.6).

## 7. As versões (DEC-0028 §3)

- **SemVer `0.y.z`,** só dígitos e pontos. O `.exe` mostra `0.1.0` como `0.1.0.0`, e qualquer outra coisa o faz cair para `1.0.0.0` (F-045 §2; F-047 §1.5).
- **O `y` sobe quando um marco do roteiro fecha:** 0.1.0 é o esqueleto andante, 0.2.0 a fase 1, 0.3.0 a fase 2; o 1.0.0 é o lançamento.
- **O `z` sobe a cada build que sai com tag** para alguém jogar (F-046 §2).
- **Onde mora:** `application/config/version` no `project.godot`. Até o esqueleto andante, vale `0.0.0`. Quem sobe é o Claude, no commit da tag, com o ok do Arthur (F-048).
- **O commit carimbado:** o CI escreve os 7 primeiros caracteres em `application/config/commit` na hora do export (F-045 §3), e o `.exe` feito no Linux leu o carimbo neste PC (F-045 §4).
- **A tag e as notas:** a tag `v0.y.z` vira uma release pública no GitHub (DEC-0033), com as duas builds e notas em português tiradas do diário (F-046 §2). As notas ficam em `docs/releases/v0.y.z.md`. O job da release é o único com permissão de escrita e só roda na tag; ele recusa a tag que não bate com a versão do `project.godot` e a que não tem notas (`tools/release.sh`). Em todo PR, ele ensaia sem publicar.
- **A primeira release** é a v0.1.0, que fecha o esqueleto andante (TASK-9, critério 18).
- **O aperto de mão:** o cliente manda versão e commit ao conectar, e o servidor recusa os diferentes. No rollback, os dois precisam rodar a mesma regra (DEC-0026). O replay leva o mesmo carimbo (§4).

## 8. O fluxo de branch e o worktree (DEC-0028 §4)

1. A task fica Ready na main.
2. No In Progress, nasce uma branch curta, `task-N-nome`, e todo commit da task vai nela, inclusive o diário das sessões dela.
3. No fim, o Claude abre o PR em português, com o que mudou, os critérios, como testar e o link da build. A task vira Done dentro do PR.
4. O CI roda no PR o portão e as duas builds.
5. O Arthur revisa e joga a build. O merge é dele, ou do Claude com o ok dele, num merge commit.
6. Sessão sem task vai direto na main.
7. Duas sessões ao mesmo tempo usam worktrees separados. As branches de sonda da TASK-6 já rodaram assim, num worktree à parte (F-045 §3).

O plano Free não impõe nada disso: o pre-push continua sendo a trava, e o CI no PR é a segunda conferência (Q-03). A TASK-6 abriu antes do fluxo e fechou na main; a primeira branch é a da próxima task.

## 9. Os hooks do Claude Code (DEC-0027 §6)

| Hook | Quando | O que faz |
|---|---|---|
| `guard_locked_tests.sh` | Antes de `Edit`, `Write`, `MultiEdit` e `NotebookEdit` | Nega a edição de um arquivo listado em `.claude/harness/locks/*.sha256`, com o motivo |
| `format_gd.sh` | Depois de `Edit`, `Write` e `MultiEdit` | Formata o `.gd` nosso; um erro do formatador volta para o Claude |

- **Provados duas vezes:** nesta sessão, sem reiniciar, e numa sessão nova, no modo sem permissões. A trava negou o Edit e o Write na conversa principal e o Edit de um subagente, e o formatador consertou um `.gd` torto (F-040).
- **Os scripts leem o JSON com `python`** (F-038 §4), nunca com `python3`, que neste PC é o atalho falso da Microsoft Store (TASK-6, pauta da rodada 1).
- **A escrita pelo Bash não passa pela trava** (F-039 §2), e no Windows não há caixa de areia (F-047 §2). A trava de verdade continua sendo o sha256 no portão.

## 10. As medições

- **O portão, passo a passo:** §2 (F-049 §1 e §5).
- **O replay e a SyncTest:** F-042 (sessão 7).
- **O export, neste PC e no CI:** F-045 (sessão 7).
- **A prova a partir deste repositório,** com os presets que entraram: nas notas de fechamento da TASK-6.

## 11. O que fica para depois

- **O tempo do portão:** na TASK-9, ele levou de 61 a 114 s neste PC, conforme o PC estava quieto ou ocupado, contra o limite de 90 s do pre-push (DEC-0027). Os passos que mais pesam são o import e os testes; a referência soma uns 1,1 s.
  - Na TASK-10.1, medido em silêncio: 72 s na rodada A, 76 s na rodada B e 78 s no fechamento, com os testes em uns 34 s, contra os 90 s (DEC-0027 §1).
  - Na TASK-10.4: 165 s na rodada A, com o PC ocupado (os testes em 134 s), e 113 s na rodada B, com o PC quieto (os testes em 79 s). Passa dos 90 s do pre-push nos dois; a divisão do CI da DEC-0027 §4 volta ao Arthur como DEC se ficar assim. Com o PC ocupado, o revisor mediu 103 s e 116 s, com a SyncTest de 4 s subindo para 6 a 11 s: o pre-push de quem trabalha com outra coisa aberta pode passar do limite. A divisão do CI da DEC-0027 §4 ainda não precisou entrar.
  - Na TASK-10.8: 369 s, com o PC quieto (CPU a 1 %), os testes em 5 min 28 s e 1.453 casos: quatro vezes os 90 s do pre-push. A divisão da DEC-0027 §4 volta ao Arthur (Q-46).
- **Q-20:** a assinatura do `.exe`, antes de alguém de fora testar.
- **Canários** para o formato, o lint, as travas, o import e o log limpo, se um furo aparecer ali.
- **Um job do CI fora do pre-push,** quando uma camada não couber nos 90 s.

## 12. A máquina e as ferramentas

O inventário que o `AGENTS.md` resumia (veio para cá no fechamento do Desenho 5, F-065):

- Windows 11 com o Git Bash; os scripts são bash.
- No PATH (`~/.local/bin`): `godot` (o console do 4.7.2), `backlog`, `gdscript-formatter` 0.27.0, `lefthook`, `gitleaks` e `gh`; o `git-lfs` vem com o Git.
- O clumsy 0.3 (`~/.local/opt/clumsy-0.3`, como administrador) simula lag para 4 clientes ou mais (F-023 §2).
- Os scripts de rede, fora do portão (TASK-9, parte 2):
  - `tools/net_check.sh`: 26 checagens com processos de verdade;
  - `tools/net_run.sh [ping]`: a corrida de 30 s;
  - `tools/play_online.sh [ping]`: o teste à mão.

  Os dois últimos ligam o simulador do netfox por um `override.cfg` temporário, e o portão recusa rodar com ele na raiz (DEC-0038; `rede.md` §10).
- Os scripts da esteira (TASK-9, parte 3), que o CI roda e que também rodam aqui:
  - `tools/stamp_build.sh COMMIT`: o carimbo do commit, só no CI. O teste de configurações reprova um `project.godot` com carimbo esquecido;
  - `tools/export_builds.sh [client] [server]`: o import e o export dos presets;
  - `tools/smoke_test_server.sh`: o teste de fumaça do servidor exportado;
  - `tools/release.sh [--dry-run] TAG`: a release da tag, ou o ensaio dela;
  - `tools/server_image_check.sh`: a imagem do servidor. Aqui ele precisa do Docker Desktop aberto, que é pesado; o CI o roda em todo PR;
  - `tools/record_reference.sh`: regrava a referência;
  - `tools/replay.sh ARQUIVO [--force] [--readable=SAÍDA] [--trace=SAÍDA]`: refaz um replay sem tela; com `--watch [--max-fps N]`, com janela; com `--sample=SAÍDA`, grava a corrida do teste do portão (§4);
  - `tools/measure_fps.sh`: a medição de fps, com a build em tela cheia por uns 2 minutos e o PC livre (F-095).
- O `node` 24 e o `python` 3.14 servem scripts de apoio e os hooks, nunca o portão (F-016 §2); `python`, nunca `python3`, que aqui é um atalho da Store.
- As sondas ficam fora do repositório, em pastas ao lado dele (`../netfox-sonda`, `../assets-sonda`, `../git-sonda`).

## 13. O relatório de crash pelo log (DEC-0034; TASK-12)

Quando os amigos testarem a fase 2, o jogo precisa deixar no PC deles o log com a pilha de chamadas, e o passo a passo precisa dizer onde ele fica e como mandar (DEC-0034; F-173 §3). O que entra no `project.godot`, cada um com guarda no `test/project_settings_test.gd`:

| Configuração | Valor | Por quê |
|---|---|---|
| `debug/file_logging/enable_file_logging` e `enable_file_logging.pc` | `true` | O arquivo de log. O `.pc` já é `true` no desktop; o explícito evita surpresa numa troca de template (F-173 §3) |
| `debug/file_logging/log_path` | `user://logs/godot.log`, o padrão | No Windows, `%APPDATA%\Godot\app_userdata\<nome do projeto>\logs` (F-173 §3) |
| `debug/file_logging/max_log_files` | 10 | Cada sessão renomeia o log anterior com a data; o padrão é 5, e 10 cobrem uma tarde de testes |
| `application/run/flush_stdout_on_print` | `true` | Sem ele, a saída padrão só vai ao arquivo quando o jogo fecha ou cai; a sonda da F-073 §1 tropeçou nisso |
| `debug/settings/gdscript/always_track_call_stacks` | `true`, medindo o custo no PC mínimo antes de manter | Sem ele, um erro de GDScript no exportado não traz a pilha; desde o Godot 4.5, o erro registra um backtrace até a origem (F-173 §3) |
| `debug/settings/crash_handler/message` | o pedido ao testador, em português | O tratador de queda imprime a mensagem antes do backtrace. O template oficial não tem símbolos de depuração, então uma queda nativa dá só endereços; o Sentry da fase 3 pede símbolos próprios (F-173 §3) |

A primeira linha do log traz a versão e o commit (`common/build_stamp.gd`). O passo a passo público para os testadores nasce na filha do log (TASK-12.12), junto com o pedido ao SignPath (Q-20): não reabrir o jogo antes de copiar o log, porque a sessão nova o renomeia; Win+R com o caminho da pasta; mandar o `godot.log` mais recente com o que a pessoa estava fazendo e, se houver, o arquivo de replay da sessão (§4).
