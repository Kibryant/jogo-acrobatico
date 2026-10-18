---
id: TASK-9
title: 'Esqueleto andante: a cápsula em rede de ponta a ponta'
status: Done
assignee: []
created_date: '2026-10-02 16:48'
updated_date: '2026-10-18 20:45'
labels:
  - jogo
  - rede
milestone: m-0
dependencies:
  - TASK-2
  - TASK-4
  - TASK-5
  - TASK-6
  - TASK-8
  - TASK-11
ordinal: 9000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
O primeiro código de jogo (DEC-0012): provar a esteira inteira antes de qualquer funcionalidade. A cápsula se move pelo núcleo puro, dentro do tick do netfox, num servidor dedicado com dois clientes e lag simulado, e o CI gera as builds. Os Desenhos 2 a 6 deixaram a entrada nos comentários desta task. Ela fecha o marco m-0 com a versão 0.1.0 (DEC-0028 §3); depois vem o teste da fase 0, "Gosto de jogar ou só da ideia?" (`roteiro.md`).

### Entrega em três partes
Uma task, com uma branch e um PR por parte, como a TASK-11 (F-084 §2). O Arthur joga no fim de cada parte.
1. **A cápsula sozinha** (critérios 1 a 8): os números do `movimento.md` num `.tres`, convertidos em ticks; as regras do chão, do pulo, do coyote e do buffer em `core/`; o lutador, a arena de blocos, a câmera e o modo Sozinho da `Main`; a SyncTest com os quatro cenários.
2. **A cápsula em rede** (critérios 9 a 13): os modos servidor e cliente da `Main`, o aperto de mão, o fechamento limpo, o oponente suavizado e o comando que abre o servidor e dois clientes com lag.
3. **A esteira** (critérios 14 a 18): as builds no PR e na tag, a imagem do servidor no CI com a conexão provada, a referência, os 60 fps e a versão 0.1.0 com a tag.

O movimento da parte 1 não muda nas partes 2 e 3: o mesmo `_rollback_tick` e o mesmo núcleo rodam no modo Sozinho, no servidor e nos clientes (DEC-0026 §5; F-084 §3).

### Perguntas em aberto
Nenhuma. A Q-16 (ficar em pé na cabeça do outro) segue na fase 1 (DEC-0036); aqui o empurrão da SyncTest fica no chão.

### Escolhas confirmadas
Confirmadas pelo Arthur em 17/10/2026, com "Fechar com as recomendações (Recomendado)" e depois "Continuam (Recomendado)" (F-084 §2 e §3; a lista como ele viu está no §4). O que vem marcado como detalhe do Claude refina a escolha e não foi mostrado a ele.
1. O `yaw` entra no tick pela última amostra; o `move` segue a média das amostras dos frames do tick (DEC-0026 §1).
2. O servidor fecha por um arquivo, conferido a cada segundo: quando ele aparece, o servidor para o tick, fecha a conexão, solta a partida e sai com 0; no Docker, basta um `docker exec … touch` (DEC-0026 §6; DEC-0032 §2). Detalhe do Claude: o caminho do arquivo vem de um argumento da `Main`.
3. A conexão se prova no CI: um cliente sem tela conecta no contêiner, passa no aperto de mão e sai; um cliente de outra versão é recusado (DEC-0032 §1). Detalhe do Claude: o cliente roda do código-fonte, com o mesmo carimbo de commit do servidor, porque não existe cliente Linux exportado.
4. No máximo 2 jogadores; o terceiro é recusado com uma mensagem.
5. O empurrão da SyncTest fica no chão; a Q-16 continua na fase 1.
6. Os quatro cenários da SyncTest juntos em menos de 5 s neste PC (DEC-0027 §3).
7. O teste à mão usa o simulador do netfox a ping 100, com 220 como limite (`rede.md` §10).
8. Duas configurações novas no `project.godot`, guardadas pelo teste de configurações: a cena principal `Main` e o `application/run/flush_stdout_on_print` ligado (F-073 §2).
9. A porta padrão é 7777/udp, a da sonda, trocável por `--port` (F-073).
10. O aperto de mão compara versão e commit exatos; o commit vazio do editor só bate com outro vazio (DEC-0028 §3).

### Números v0 do Claude para o esqueleto
Fechados pelo Claude (DEC-0017), fora da identidade do jogo; o Arthur julga jogando.
- **A arena** junta as duas sondas: um chão de 80 × 80 m; a plataforma de 1 m de altura com beirada e a rampa de 45° da sonda do Desenho 3 (`../netfox-sonda/sonda/probe_arena.gd`); três blocos de 4 × 4 m, com 1, 2 e 3 m de altura, separados (`movimento.md`: bancada, porta e teto); e dois pontos de nascimento a 10 m um do outro, de frente. O bloco de 1 m se sobe com o pulo; o de 2 m e o de 3 m esperam o pulo duplo e a parede da fase 1 (`movimento.md`, métricas de nível).
- **As cores:** o chão e os blocos nos cinzas das sondas; as duas cápsulas em tons neutros, fora das cores dos tokens, a de quem joga mais clara e a outra mais escura (DEC-0031; `visual-e-audio.md`). A câmera seguindo a própria cápsula já a separa da outra sem depender só da cor.
- **O bot:** corre e pula a cada 2 s, como nas medições do Desenho 3 (`rede.md` §10).

### Fora do escopo
- Parede, pulo duplo, dash, gancho e stamina: fase 1 (TASK-10; `movimento.md`, "O que o esqueleto andante usa").
- Combate: fase 2.
- O gravador do replay para o Arthur: fase 1 (DEC-0027 §5). Aqui só a referência, que roda um percurso de bot.
- A tela de remapear as teclas e o Theme: nascem com a primeira cena de interface (DEC-0031).
- O servidor fora deste PC: fase 3 (DEC-0032 §3).
- Os 8 clientes a 60 ticks (Q-09).

### O que você vai aprender
- Como uma tecla vira input, passa pela rede, é simulada no servidor e volta como estado, com o rollback acontecendo na sua frente.
- Por que a mesma função de movimento roda no modo Sozinho, no servidor e no cliente: a rede só a chama mais vezes (F-084 §3).
- Como o servidor vira uma imagem Docker testada a cada push, e como a build sai do CI com a versão e o commit carimbados.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Quando o `movement_v0.tres` é carregado, cada tempo do `movimento.md` vira ticks pelo tick mais próximo, com o empate para cima, e um teste falha se algum erro passar de meio tick, a 30 e a 60 ticks (DEC-0004, regra 3; `visao-geral.md`).
- [x] #2 Quando a cápsula pula do chão, a 30 e a 60 ticks, ela sobe 1,2 m com tolerância de 1 cm, chega ao topo em 350 ms e volta ao chão em 280 ms, cada tempo com erro de até meio tick, porque a física é derivada para o tamanho do tick (`movimento.md`; `visao-geral.md`).
- [x] #3 Quando as regras do chão e do ar rodam no núcleo, testes de tabela escritos do `movimento.md` antes do código provam a corrida de 7 m/s, igual para frente, para o lado e para trás, os 150 ms até a velocidade máxima, os 100 ms até parar sem input, o controle no ar de 25% da aceleração do chão, a queda máxima de 30 m/s e a rampa de até 45° como chão, e acima disso não (`movimento.md`; DEC-0004, regra 4).
- [x] #4 Quando o pulo é apertado, o núcleo aceita o aperto até 100 ms depois de sair da beirada (coyote) e guarda o aperto no ar por até 150 ms antes de pousar (buffer); um tick além de cada janela já não pula, um aperto no ar fora do buffer não faz nada (o pulo duplo é da fase 1) e soltar o botão cedo não encurta o pulo (`movimento.md`; DEC-0016).
- [x] #5 Quando um `.tres` de movimento tem um número impossível, como um tempo negativo, um zero onde a regra divide ou uma rampa acima de 90°, a checagem dos dados reprova no portão, e um teste prova que ela barra um `.tres` errado (DEC-0027 §2, camada 3).
- [x] #6 Quando o jogo abre sem argumento, ele entra no modo Sozinho, o par offline: a cápsula de 1,8 m × 0,35 m anda e pula na arena de blocos, com rampa de 45° e beirada, e a câmera em terceira pessoa segue o `movimento.md` (3,5 m, pivô a 1,6 m, centralizada, 70° na vertical, colisão e 0,06° por pixel do mouse), com o corpo olhando para onde a câmera olha; o teste de configurações passa a guardar a cena principal `Main` (DEC-0026 §6; DEC-0013; F-084).
- [x] #7 Quando o jogador usa o teclado, as ações vêm do `InputMap` por posição física (`physical_keycode`), com teste; o `move` é a média das amostras dos frames do tick, o `yaw` é a última amostra e o pulo vale no máximo um tick (DEC-0031; DEC-0026 §1; F-084).
- [x] #8 Quando a SyncTest roda no portão, com os ticks avançados à mão e o rollback forçado de 7 ticks a cada tick, os quatro cenários (rampa de 45°, beirada, pouso e dois lutadores se empurrando no chão) dão zero divergência (posição até 1 mm, `on_floor` e `mode` iguais), juntos em menos de 5 s neste PC; o resumo prova que cada caminho rodou (ticks refeitos, pousos, decolagens, ticks na rampa e choques), e um campo do estado fora do que o netfox grava faz ela acusar (DEC-0025; DEC-0027 §3; `rede.md` §4; F-084).
- [x] #9 Quando o jogo abre com `--server`, na porta de `--port` ou na 7777/udp, ou é o build de servidor dedicado, ele sobe sem tela e sem lutador próprio; sem cliente, espera; cada cliente que entra ganha um lutador num ponto de nascimento; o terceiro é recusado com a mensagem de sala cheia; o lutador de quem sai some para o outro; e o log sai na hora, com o `flush_stdout_on_print` guardado pelo teste de configurações (DEC-0026 §6; F-073 §2; F-084).
- [x] #10 Quando um cliente abre com `--connect=host:porta`, ele manda a versão e o commit; se um dos dois for diferente do servidor, o servidor recusa e o cliente mostra o pedido para atualizar; se o servidor não responde, o cliente mostra o erro; sem tela, nos dois casos, ele sai com código diferente de 0; todo texto na tela usa chave de tradução, com pt-BR e en (DEC-0028 §3; DEC-0031; F-084).
- [x] #11 Quando o arquivo de parada aparece, o servidor o percebe em até 1 s, para o tick, fecha a conexão, solta a partida e sai com código 0, com ou sem clientes conectados, e os clientes mostram que o servidor fechou; quando o jogador fecha a janela, o cliente sai com código 0 (DEC-0026 §6; DEC-0032 §2; F-084).
- [x] #12 Quando dois clientes com bot correm e pulam por 30 s contra o servidor neste PC, a ping 100 e sem se encostar, o estado que o servidor confirma bate com o que cada cliente previu para o próprio lutador em todos os ticks, e o resumo da corrida mostra quantos ticks foram conferidos e quantos corrigidos (DEC-0026 §2; `rede.md` §10).
- [x] #13 Quando o Arthur abre, com um comando, o servidor e dois clientes com o simulador do netfox a ping 100, cada um vê a própria cápsula responder na hora e a outra suavizada, sem previsão; a 220, a própria segue respondendo na hora; o que ele sentiu vai para uma fonte (DEC-0026 §2; DEC-0027 §2, camada 5; F-041).
- [x] #14 Quando um PR é aberto ou atualizado, o CI exporta o cliente Windows e o servidor Linux, com o commit carimbado em `application/config/commit`, e guarda os dois como artefato por 3 dias; quando uma tag `v0.y.z` sobe, eles viram uma release pública do GitHub; o push na main não guarda build (DEC-0028 §2; DEC-0032 §1; DEC-0033).
- [x] #15 Quando há push na main ou num PR, um job do CI fora do portão e do pre-push constrói a imagem Docker do servidor, sobe o contêiner, conecta um cliente sem tela que passa no aperto de mão, vê um cliente de outra versão ser recusado e fecha o servidor pelo arquivo de parada com saída 0, sem guardar a imagem; se o Godot cair ao sair do export (#123712), o job confere o artefato e o teste, e não só o código de saída (DEC-0032 §1; DEC-0028; F-084).
- [x] #16 Quando o portão roda neste PC e o CI roda no Linux, a referência, um percurso de bot de 1.200 ticks na arena com uma cópia congelada dos números do movimento, só do teste, dá o mesmo hash nos dois; uma mudança de código que altere o caminho reprova o portão, e regravar é um comando, com o porquê no commit (DEC-0027 §2, camada 4; F-044 §2).
- [x] #17 Quando a build do cliente roda neste PC em 1080p, com os dois lutadores na tela por 60 s, a média fica em 60 fps ou mais, com os 1% piores registrados (DEC-0002).
- [x] #18 Quando as três partes estão verdes e o Arthur dá o ok, a versão sobe para 0.1.0 no commit que fecha a task, a tag `v0.1.0` vira a primeira release, com notas em português tiradas do diário, e o marco m-0 fecha (DEC-0028 §3).
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Critérios de aceite verificados
- [x] #2 Teste automatizado para toda regra do núcleo (core/)
- [x] #3 Diário da sessão escrito e glossário atualizado
- [x] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Parte 1: a interface pública combinada (para o test-writer e o implementer)

Concretiza a `visao-geral.md` (o estado em quatro caixas, o sanduíche e as pastas; DEC-0022). Nomes de código em inglês (DEC-0008).

**Dados** (`data/`):
- `movement_data.gd`: `class_name MovementData extends Resource`, com os números do `movimento.md` nas unidades do papel: `capsule_height_m`, `capsule_radius_m`, `max_slope_deg`, `run_speed_mps`, `accel_time_ms`, `stop_time_ms`, `air_control_pct`, `max_fall_speed_mps`, `jump_height_m`, `jump_rise_ms`, `jump_fall_ms`, `coyote_ms`, `buffer_ms` (tempos em `int`, o resto em `float`). `func validate() -> PackedStringArray` devolve uma mensagem por número impossível; vazio quando está certo.
- `movement_v0.tres`: os números das seções O corpo, Chão, Pulo e ar e Perdão do `movimento.md`.

**Tempo** (`core/time/ticks.gd`): `class_name Ticks`, com `static func from_ms(ms: int, tickrate: int) -> int`: o tick mais próximo, e o empate sobe.

**O lutador no núcleo** (`core/fighter/`):
- `movement_config.gd`: `class_name MovementConfig extends RefCounted`, criado por `static func create(data: MovementData, tickrate: int) -> MovementConfig`. Campos: `tickrate`, `accel_ticks`, `stop_ticks`, `rise_ticks`, `fall_ticks`, `coyote_ticks`, `buffer_ticks` (`int`); `run_speed`, `max_fall_speed` (m/s), `floor_max_angle` (rad), `capsule_height`, `capsule_radius` (m); a física derivada para o tick tem nomes livres.
- `fighter_state.gd`: `class_name FighterState extends RefCounted`, com `enum Mode { GROUND, AIR }`, `const NEVER := -1073741824` (o carimbo de "nunca") e os campos `mode`, `mode_since`, `on_floor`, `left_floor_tick`, `jump_pressed_tick`, `jumps_used`, `facing_yaw`; `func copy() -> FighterState`.
- `tick_input.gd`: `class_name TickInput extends RefCounted`: `move: Vector2` (x para a direita, y para a frente, relativo ao `yaw`, comprimento até 1), `yaw: float` (rad), `jump: bool` (um toque, vale um tick).
- `move_plan.gd`: `class_name MovePlan extends RefCounted`: `state: FighterState`, `velocity: Vector3` (m/s).
- `move_facts.gd`: `class_name MoveFacts extends RefCounted`: `on_floor: bool`, `velocity: Vector3` (m/s, depois da colisão).
- `movement.gd`: `class_name Movement`, com `static func before_move(state: FighterState, velocity: Vector3, input: TickInput, config: MovementConfig, tick: int) -> MovePlan` e `static func after_move(state: FighterState, facts: MoveFacts, config: MovementConfig, tick: int) -> FighterState`. Nenhuma das duas altera o estado que recebe.

**As convenções em que os testes se apoiam:**
- O motor move o corpo por `plan.velocity × (1 / tickrate)` no mesmo tick. No ar, sem colisão, `facts.velocity` é a `plan.velocity`.
- A direção no mundo é `Basis(Vector3.UP, yaw) * Vector3(move.x, 0, -move.y)`: `yaw` 0 olha para −Z. O `facing_yaw` copia o `input.yaw` (o corpo olha para onde a câmera olha).
- O aperto do pulo é carimbado no `before_move` (`jump_pressed_tick = tick`) e consumido pelo pulo (volta a `NEVER`). O pulo soma 1 em `jumps_used`; pousar zera.
- As duas janelas contam ticks inteiros desde o carimbo, inclusive: o pulo vale no tick `t` enquanto `t - carimbo <= janela`. O `left_floor_tick` é o tick cujo `after_move` primeiro diz que o corpo saiu do chão. O coyote só vale com `jumps_used == 0`. O aperto guardado pelo buffer pula no `before_move` do primeiro tick que começa no chão.
- A gravidade de subida vale enquanto `velocity.y > 0`; a de descida, no resto. O `velocity.y` nunca passa de `-max_fall_speed`.
- Sem input, a velocidade horizontal chega a 0 em `stop_ticks`. Com input cheio, sai do zero e chega a `run_speed` em `accel_ticks`. No ar, a aceleração é `air_control_pct` da do chão.
- O ângulo do chão é julgado pelo motor, com o `floor_max_angle` da configuração; o núcleo lê `facts.on_floor`.

**Quem testa o quê na parte 1:** o test-writer escreve os testes dos critérios 1 a 5, cegos à implementação, e eles são travados. O implementer escreve os testes dos critérios 6 a 8: as cenas, o input por posição física, a rampa de 45° contra a de 46° numa cena e a SyncTest.

**Leituras v0 do Claude, sem número no papel** (DEC-0017; o Arthur julga jogando; anotadas depois da entrega do test-writer, que não as testa):
- O alvo horizontal é `run_speed × move`, girado pelo `yaw`; com o teclado, o `move` só fica abaixo de 1 no tick em que a tecla muda, pela média dos frames (DEC-0026 §1).
- No ar, sem input, a velocidade horizontal se conserva (`movimento.md`, Princípios: "a velocidade se conserva entre manobras"); com input, ela vai para o alvo com `air_control_pct` do ganho do chão. A sonda freava no ar, e um pulo sem tecla perderia a corrida inteira em 0,4 s.
- O pulo do coyote substitui a velocidade vertical: é sempre um pulo cheio.
- A física do pulo é derivada para o degrau do tick: o tick do aperto conta como o passo 1, o topo chega no passo `rise_ticks` e o pouso no passo `rise_ticks + fall_ticks`. A aceleração é um ganho fixo por tick, `run_speed / accel_ticks`, e a frenagem, `run_speed / stop_ticks`.

**Rodada B (as cenas, o input e a SyncTest):**
- A `Main` fica em `main/main.tscn`, a cena principal do `project.godot`; os números da câmera do `movimento.md` ficam num `data/camera_data.gd` com `data/camera_v0.tres`, com a mesma checagem dos dados.
- Leitura v0 do Claude: a câmera sobe e desce no máximo 80° (sem esse limite ela vira de ponta-cabeça; o papel não tem número).
- O lutador nasce com o corpo no chão, no ponto de nascimento: um estado novo parte do chão, e nascer no ar abriria uma janela de coyote (achado da rodada A).
- O snap do chão do motor cobre a corrida de 7 m/s descendo a rampa de 45° (uns 0,12 m por tick a 60), derivado da configuração.

## Parte 2: a cápsula em rede (critérios 9 a 13; F-089)

**Rodada C1 (critérios 9 a 11):**
- A `Main` lê os argumentos `--server`, `--port=`, `--connect=host:porta` e `--stop-file=`. O build com a feature `dedicated_server` entra como servidor (DEC-0026 §6).
- **O servidor:**
  - escuta por ENet na porta de `--port` ou na 7777/udp (F-073), sem tela e sem lutador próprio;
  - dá um lutador a cada cliente, num ponto de nascimento livre, com a autoridade do input no cliente;
  - aceita no máximo 2 clientes; o terceiro é recusado com a mensagem de sala cheia;
  - o lutador de quem sai some para o outro.
- **O aperto de mão:**
  - o cliente manda o `application/config/version` e o `application/config/commit`;
  - o servidor compara exato, e o commit vazio só bate com outro vazio (DEC-0028 §3);
  - se forem diferentes, ele recusa com o pedido de atualizar; se o servidor não responde, o cliente mostra o erro;
  - sem tela, o cliente sai com código diferente de 0 nos dois casos.
- **O relógio:** o servidor inicia o `NetworkTime` antes de aceitar clientes. O cliente o inicia depois do aperto de mão, e o `start()` sincroniza com o servidor (`rede.md` §9).
- **O arquivo de parada:** conferido a cada segundo. Quando ele aparece, o servidor para o tick, fecha a conexão, solta a partida e sai com 0, e os clientes mostram que o servidor fechou (DEC-0032 §2).
- **Os textos na tela** usam chaves de tradução, com pt-BR e en, carregadas pela `Main` (DEC-0031).
- **O `project.godot`:** o `application/run/flush_stdout_on_print` ligado, guardado pelo teste de configurações (F-073 §2; escolha 8).

**Rodada C2 (critérios 12 e 13):**
- **O bot:** um cliente com `--bot` corre e pula a cada 2 s e só produz input (DEC-0022; "Números v0 do Claude").
- **A corrida de 30 s:**
  - um comando sobe o servidor e dois clientes com bot, sem tela, com o simulador do netfox a ping 100;
  - cada cliente anota o que previu para o próprio lutador, e o servidor anota o que confirmou;
  - o resumo mostra os ticks conferidos e os corrigidos.
- **O comando para jogar:** sobe o servidor sem tela, um cliente com bot numa janela e a janela do Arthur, a ping 100 ou 220.
  - O simulador do netfox só funciona com a conexão automática dele. Por isso o comando escreve um `override.cfg` temporário, como a sonda (`../netfox-sonda/sonda/play.sh`), e a `Main` usa a conexão que o simulador abriu.
  - O `project.godot` segue com a conexão automática desligada (DEC-0023), e o `override.cfg` entra no `.gitignore`.

**Depois:** o revisor julga os critérios 9 a 13. O Arthur joga a 100 e a 220, e o que ele sentir vai para uma fonte (critério 13).

## Parte 3: a esteira (critérios 14 a 18; F-094)

Branch `task-9-delivery-pipeline`. O mapa das entradas (DECs, fontes, CI de hoje e sondas) foi feito pelo explorer em 18/10/2026.

**Rodada D1, no portão (critério 16 e as sobras da parte 1):**
- **A referência** (DEC-0027 §2, camada 4; F-044 §2; F-042):
  - um teste do portão roda a partida de verdade no Sozinho, com os ticks à mão (`test/support/netfox_ticks.gd`), por 1.200 ticks;
  - um percurso fixo de bot, só do teste, com `yaw` 0 o tempo todo e sem passar pela rampa: seno e cosseno podem diferir no último bit entre Windows e Linux, e a sonda não provou isso (F-042, limites). A SyncTest segue cobrindo a rampa;
  - uma cópia congelada dos números do `movement_v0.tres`, só do teste: o ajuste fino do jogo não quebra a referência;
  - o rastro guarda, por tick, a posição com 9 casas e o chão, como a sonda (`../replay-sonda`). O teste compara o rastro com o guardado e mostra o sha256 dos dois; se diferirem, mostra o primeiro tick diferente;
  - regravar é um comando, `bash tools/record_reference.sh`, e o commit diz por quê;
  - se o Windows e o Linux derem rastros diferentes, o Claude para e leva ao Arthur: a DEC-0027 diz que aí a referência vale só no Linux, e o critério 16 pede os dois.
- **A checagem dos dados** (achado 5 do revisor da parte 1): um dos quatro tempos que as regras dividem (aceleração, parada, subida e queda) que arredonda para 0 tick a 30 ou a 60 ticks reprova no `MovementData.validate()`. O `assert` do `MovementConfig.create()` some na build de release. O test-writer escreve o teste antes, num arquivo novo, e ele fica travado.
- **O `data/camera_v0.tres`** ganha um uid.
- **A recusa de argumento desconhecido** já tem prova com processo no `tools/net_check.sh` (código 2); a nota da parte 1 fecha.

**Rodada D2, no CI (critérios 14 e 15):**
- **As builds, no PR e na tag `v0.y.z`, nunca no push da main** (DEC-0028 §2):
  - o `setup-godot` com os templates (1,28 GB, em cache), o import antes do export (gdUnit4 #1324), o carimbo dos 7 primeiros caracteres do commit em `application/config/commit` e o export dos dois presets;
  - o teste de fumaça: o servidor exportado sobe sem tela e fecha pelo arquivo de parada com 0. Se o Godot cair ao sair do export (#123712), o job confere a build e o teste de fumaça, e não só o código de saída;
  - no PR, as duas builds num artefato de 3 dias;
  - na tag, um job à parte, o único com permissão de escrita, publica a release pública com as duas builds e as notas do `docs/releases/v0.y.z.md`, em português (DEC-0033). No PR, ele ensaia, sem publicar.
- **A imagem do servidor, no push da main e no PR, fora do portão** (DEC-0032 §1):
  - o `Dockerfile` da sonda (`../servidor-sonda`): `debian:trixie-slim`, o `tini` como PID 1, um usuário sem root, a porta 7777/udp e o servidor com `--stop-file`;
  - o `tools/server_image_check.sh` exporta o servidor, constrói a imagem e sobe o contêiner. Conecta um cliente sem tela do código-fonte, com o mesmo carimbo, que passa no aperto de mão; carimba outro commit e vê o segundo cliente ser recusado (código 4); fecha pelo `docker exec … touch` e confere a saída 0 do servidor e do primeiro cliente. A imagem não é guardada;
  - o script roda também neste PC, com o Docker Desktop, antes do CI.

**Rodada D3, neste PC (critério 17):**
- O jogo ganha `--measure-fps=CAMINHO`: com tela, em tela cheia 1920 × 1080, vsync desligado e fps sem limite. Espera 2 s e mede 60 s quadro a quadro, como a sonda dos assets (F-056 §5), e grava a média e os 1% piores (o 99º percentil do tempo de quadro).
- O `tools/measure_fps.sh` exporta o cliente aqui, sobe um servidor e um bot sem tela e abre a build em tela cheia, com o bot jogando o lutador dela, a ping 0: os dois lutadores na tela. O Arthur roda com o PC livre, por uns 2 minutos.

**Depois:** o revisor julga os critérios 14 a 17. O critério 18 vem por último, com o ok do Arthur: a versão 0.1.0 no commit que fecha a task, as notas tiradas do diário com o passo a passo para abrir uma build sem assinatura (Q-20), a tag `v0.1.0`, a release e o marco m-0 fechado.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Parte 1, fechada em 17/10/2026 (branch task-9-solo-capsule)

- O revisor aprovou os critérios 1 a 8, com o portão verde (231 testes). O Arthur jogou o modo Sozinho e gostou (F-086).
- Achados que viraram regra ou doc:
  - sem notícia da rede, o netfox simulava só o último tick de um loop, e o `Match` pede o primeiro (F-085; `rede.md` §2);
  - a checagem de compilação do portão roda no `_initialize()`, depois dos autoloads (F-085);
  - o snap de reserva do contorno D (DEC-0037; F-087);
  - o tempo da SyncTest aparece sem trava (F-087 §1);
  - a escada dos blocos, com o pulo atrasado (F-086; `movimento.md`).
- Para a parte 2:
  - o `Match` já pede o primeiro tick do loop em todos os modos;
  - a SyncTest e o `test/support/netfox_ticks.gd` servem de base;
  - o `main_test` ainda não exercita a recusa de um argumento desconhecido, só o `unknown_arguments()`, e o critério 10 pede a saída diferente de 0 sem tela.
- Para a parte 3:
  - o `MovementConfig.create()` barra um tempo que arredonda para 0 tick só com `assert`, que some no build de release. Vale uma checagem que devolva erro antes das builds (achado 5 do revisor);
  - o `camera_v0.tres` não tem uid, e o editor põe um no primeiro save.
- No fechamento da task, a linha da TASK-9 no `.claude/harness/registro.md`, com as lições da parte 1:
  - as cinco conferências erradas da sessão 13 e a explicação de uma coisa por vez;
  - a SyncTest achando o que a sonda do Desenho 3 não via;
  - a medição feita num worktree separado.

## Parte 2, rodada C1 (critérios 9 a 11), 17/10/2026

**Escolhas v0 do implementer**, fora do papel até o fechamento da parte 2:

| Escolha | Valor |
|---|---|
| Espera do cliente pelo servidor | 5 s; o ENet sozinho desiste só depois de uns 31 s |
| Códigos de saída | 0 fim limpo; 2 argumento errado; 3 servidor não respondeu; 4 atualizar o jogo; 5 sala cheia; 6 porta ocupada |
| Cliente sem tela quando o servidor fecha | Sai com 0, então um arquivo de parada encerra todos os processos limpos |
| Assento | O primeiro livre; o primeiro jogador nasce no SpawnA |
| Nome do lutador | Pela ordem de nascimento, escolhido pelo servidor: `Fighter0`, `Fighter1`, `Fighter2`...; nunca se repete na partida, então quem entra no lugar de quem saiu não herda a rota dele no netfox |
| Arquivo de parada | Nunca é apagado: um caminho errado, como `--stop-file=project.godot`, seria destruído |
| `--server` com tela | Recusado com o código 2: o servidor nunca abre janela |

**O que o Godot e o netfox ensinaram:**

- o aperto de mão roda na etapa de autenticação do Godot, antes de o netfox ou qualquer RPC ver o cliente;
- a recusa sai com `peer_disconnect_later()`: o `disconnect_peer()` joga fora a mensagem que estava na fila;
- no servidor e no cliente, o `NetworkEvents` do netfox inicia e para o relógio, e a `Main` espera por ele (`docs/mudancas.md`);
- o servidor manda o estado de um lutador só a quem já sabe que ele existe (o filtro de visibilidade do netfox).

**Provas:**

- `bash tools/gate.sh`: verde, 268 testes, 74 s;
- `bash tools/net_check.sh`: 26 de 26.

**A acompanhar:** o portão foi de 58 s no começo da sessão para 71 a 82 s, contra o limite de 90 s do pre-push.

**Para o fechamento da parte 2:**

- o `rede.md` §9 (o relógio, a porta 7777 e o aperto de mão na autenticação);
- os textos na tela usam a fonte padrão de 16 px até o Theme chegar.

## Parte 2, rodada C2 (critérios 12 e 13), 17/10/2026

**Os comandos novos**, nenhum deles passo do portão:

- `bash tools/net_run.sh [ping]`: a corrida de 30 s do critério 12;
- `bash tools/play_online.sh [ping]`: o teste à mão do critério 13;
- os dois escrevem o `override.cfg` com o simulador do netfox e o apagam quando os jogos já o leram, ou em qualquer saída;
- o portão e o `net_check.sh` se recusam a rodar enquanto existir um `override.cfg`, que já está no `.gitignore`.

**Escolhas v0 do implementer**, fora do papel até o fechamento da parte 2:

| Escolha | Valor |
|---|---|
| Rota do bot | Corre de lado, 2 s para a direita e 2 s para a esquerda, e pula no primeiro tick de cada trecho, contando do primeiro tick do lutador |
| Espera pela conexão do simulador | Até 10 frames |
| Servidor com o simulador, ao sair | Espera a latência mais 100 ms no relógio de parede, para o adeus passar pelo proxy |
| Registro da corrida | CSV com 6 casas; uma corrida exige 25 s de ticks conferidos |
| Processos sem tela | `--max-fps 144`, como na sonda |
| Janelas | `--half=left\|right`: a do bot abre primeiro, na direita, e a do Arthur na esquerda. O WindowTiler do netfox falhou na maioria das vezes |
| Endereço com o simulador ligado | Um `--port` ou `--connect` diferente do simulador é recusado; o Sozinho também é recusado |
| Varredura dos logs | Ignora só o `ERROR: Couldn't create an ENet host.`, que o simulador causa em todo cliente |

**Três consertos na C1**, achados pela corrida de 30 s (a primeira teve 13 ticks corrigidos):

- o lutador do cliente começa no primeiro tick do servidor, que o RPC `_add_fighter` agora leva;
- o lutador usa o nascimento do netfox (`_rollback_spawn` e `_rollback_despawn`) e não existe antes desse tick;
- o servidor com o simulador espera o proxy entregar o adeus antes de sair.

**O que o netfox e o Godot ensinaram:**

- logo depois de sincronizar, o relógio do cliente fica atrás do servidor mais ou menos a latência de ida, e o lutador dele nascia um tick antes; o estado de nascimento do servidor apagava a previsão no meio do pulo;
- um `SceneTreeTimer` conta o tempo dos frames, e um frame longo come o timer inteiro;
- um input mais velho que as 64 ticks de histórico faz o netfox refazer as 64 ticks em todo frame. Com o PC sobrecarregado, isso trava o servidor por segundos.

**Provas:**

- `bash tools/gate.sh`: verde, 286 testes, 79 s;
- `bash tools/net_check.sh`: 26 de 26;
- `bash tools/net_run.sh`: 1.852 e 1.850 ticks conferidos, 0 corrigidos, 10 m de distância mínima.

**A acompanhar:**

- o portão foi de 79 s a 85 s nesta rodada, contra o limite de 90 s do pre-push;
- o corpo do lutador fica no mundo da física antes do primeiro tick dele. Já era assim; vale olhar quando houver colisão entre lutadores no nascimento.

## Parte 2, revisão e fechamento, 18/10/2026

**O teste à mão do critério 13:** o Arthur jogou pelo `play_online.sh` a ping 100, uns 5 minutos, e a 220, uns 2,5 minutos. Ele não sentiu lag na própria cápsula; a 220, sentiu uma diferença leve que não sabe explicar (F-091; F-092).

**O revisor**, com o modelo Fable e contexto limpo, aprovou os critérios 9 a 13 com estas provas, que ele mesmo rodou:

- `bash tools/gate.sh`: verde em 61 s, com 286 testes;
- `bash tools/net_check.sh`: 26 de 26, em 32 s;
- `bash tools/net_run.sh`: 1.852 e 1.846 ticks conferidos e 0 corrigidos, em 36 s.

**Os achados e o que foi feito:**

| Achado | O que foi feito |
|---|---|
| A história do erro de digitação da sonda (300 s em tela cheia) citava a F-056; ela está no registro do harness, 07/10/2026 | Quatro comentários corrigidos no `c9af37c`, dois deles herdados da parte 1 |
| A frase do flush do log citava a F-073 §2; ela está no §1 | Um comentário e a mensagem do teste de configurações, no `c9af37c`. O texto do critério 9 segue com "F-073 §2" |
| Os números v0 de engenharia não tinham casa nos docs | Uma tabela no `rede.md` §9, com os códigos de saída |
| A sessão do simulador não estava numa DEC | DEC-0038, completando a DEC-0023 §7 (F-093) |
| O `net_run.sh` ignora uma linha de erro do motor | Fica, descrito na DEC-0038 e no `rede.md` §10: só a linha exata que o simulador deixa em todo cliente |
| Docs desatualizados | `rede.md`, `testes-e-entrega.md`, o glossário e o `mudancas.md`, com o ok do Arthur (F-093 §1) |

**A conferência do fechamento:** o Arthur errou duas vezes a pergunta sobre o simulador (F-093). Uma nota da mesma sessão tinha dito que "o lag do simulador mora no servidor", e as duas respostas seguiram essa ideia. O Claude explicou uma vez com o autoload do `project.godot` e seguiu com as escolhas dele: os docs com a DEC-0038, o push, o PR e o merge com o CI verde.

**O portão no fechamento:** verde em 64 s, depois das correções.

**A acompanhar na parte 3:**

- o corpo do lutador fica no mundo da física antes do primeiro tick dele;
- o `play_online.sh` pode gravar os ticks da janela do jogador, para uma sensação virar número (F-091 §4);
- na parte 2, o portão rodou entre 61 e 85 s, contra o limite de 90 s do pre-push.

## Parte 3, revisão e fechamento, 18/10/2026 (branch task-9-delivery-pipeline, PR #8)

**As rodadas:**
- D1: a referência (1.200 ticks, `b73cccbc…` no Windows e no Linux) e a checagem dos ticks, cujo teste o test-writer escreveu antes e ficou travado;
- D2: os jobs de export, release e imagem do servidor;
- D3: a medição de fps. O Arthur rodou e deu 312,71 fps de média e 157,62 nos 1% piores (F-095).

**O que o CI achou:** no primeiro run do PR #8, o servidor Linux de release imprimiu quatro linhas de `ERROR` ao fechar, depois de RPCs. É o bug #123751 do Godot 4.7.2, só na build de release do Linux. O Arthur escolheu deixar só essa linha de fora no job da imagem (F-097).

**O revisor**, com o modelo Fable e contexto limpo, aprovou os critérios 14 a 17:
- portão verde em 86 s, com 340 testes;
- no CI, a referência com o mesmo hash no Linux, o export com o artefato de 68,5 MB e o `server-image` com 15 conferências ok;
- o ensaio da release passou, e uma tag que não bate com a versão foi recusada.

A metade do critério 14 que fala da tag se prova na release v0.1.0.

**Os achados e o que foi feito:**

| Achado | O que foi feito |
|---|---|
| O filtro da F-097 valia também no teste de fumaça | Ficou só no job da imagem (`0b55f35`) |
| O custo da referência nos docs era o da sonda | `testes-e-entrega.md` §3 e uma linha no `mudancas.md` |
| Docs desatualizados | `testes-e-entrega.md`, `rede.md`, glossário, `README.md`, `visao-geral.md` e `infraestrutura.md`, com o ok do Arthur (F-098 §1) |

**O critério 18:**
- a versão sobe para 0.1.0 neste fechamento;
- as notas da release estão em `docs/releases/v0.1.0.md`, tiradas do diário de 18/10, com o passo a passo da build sem assinatura (Q-20);
- o Arthur lê as notas antes do merge e da tag `v0.1.0` (F-098 §1).

**As conferências:** desde o fechamento da parte 2, cinco erradas e duas certas. O arquivo do simulador e a release pública falharam duas vezes cada, e foram explicados uma vez com o próprio projeto.

**A acompanhar depois da TASK-9:**
- o portão leva de 61 a 114 s neste PC, contra o limite de 90 s do pre-push;
- o erro #123751 do Godot, a olhar a cada versão nova;
- o corpo do lutador fica no mundo da física antes do primeiro tick;
- o `play_online.sh` pode gravar os ticks da janela do jogador (F-091 §4);
- a DEC-0037 e a DEC-0038 ainda não estão no Yabadoo.
<!-- SECTION:NOTES:END -->

## Comments

<!-- COMMENTS:BEGIN -->
author: Claude
created: 2026-10-04 17:13
---
Entrada do Desenho 3 (TASK-5; DEC-0023 a DEC-0026), para o esqueleto andante:
- O netfox já está em addons/, fixado no cf5189d (DEC-0023). Os 14 autoloads ficam em res:// e o tickrate em 60; o test/project_settings_test.gd guarda os dois.
- A Main tem três modos (DEC-0026 §6): --server com --port=N, ou a feature dedicated_server; --connect=host:porta; e, sem argumento, o par offline. Fechar limpo é parar o NetworkTime, fechar o peer, soltar a Match e só então sair. Conferir a saída com código 0, porque a sonda caía ao fechar (F-026 §4).
- O input (DEC-0026 §1):
  - o move é a média dos frames do tick, e o yaw é o do último frame;
  - o jump é comando de um toque, consumido no after_tick, como o one-off-input.gd do netfox;
  - input_delay 0, sem broadcast, e o RollbackSynchronizer sem previsão.
- O tick do lutador (DEC-0025): o contorno do transform no after_prepare_tick, em todo tick refeito; o contorno D no primeiro tick de cada rollback; o sanduíche depois dos dois.
- A SyncTest vira teste permanente no CI (DEC-0004, regra 4; DEC-0025): rampa de 45°, beirada, pouso e dois lutadores se empurrando, com rollback forçado de 7 ticks, a profundidade de 220 ms a 60. A sonda de referência está em ../netfox-sonda/sonda (main.gd, probe_fighter.gd e sync_probe.gd).
- As medições de referência estão no docs/arquitetura/rede.md §10.
---

author: Claude
created: 2026-10-04 17:55
---
Correção do comentário anterior: como o yaw e o pitch entram no tick fica para a TASK-9 decidir. Pode ser a última amostra ou uma média que respeite a volta de 360°; a média simples de ângulo erra (DEC-0026 §1; rede.md §3). O move segue o padrão do netfox para entrada contínua: a média das amostras dos frames do tick.
---

created: 2026-10-07 17:52
---
Entrada do Desenho 4, rodada 2 (TASK-6; F-042; F-044), para o esqueleto andante:
- A SyncTest permanente avança os ticks à mão, como a suíte do netfox (`test/network-mocks.gd`: `NetworkTime._before_tick_loop()`, os sinais do tick e `_after_tick_loop()`), rodando o rollback de verdade dele. Pelo relógio, cada cenário custa o tempo de jogo (5 s de rampa, 6,3 s de portão), e os quatro somariam uns 25 s. Meta: poucos segundos para os quatro.
- A referência (camada 4) nasce aqui: um percurso de bot gravado como replay por inputs, com o hash do caminho conferido no portão (Windows) e no CI (Linux). Ela usa uma cópia congelada dos números do movimento, só do teste; regravar é um comando, e o commit diz por quê. A sonda de referência está em `../replay-sonda` (main.gd, fighter.gd, arena.gd).
- A checagem dos dados nasce com o primeiro `.tres` de design.
- O que proteger desde já para o replay: o input que vale é o que o servidor aplicou; todo sorteio tem semente e mora no estado; o núcleo não lê relógio; a build carrega a versão.
---

created: 2026-10-07 19:24
---
Entrada do Desenho 4, rodada 3 e fechamento (TASK-6; DEC-0027; DEC-0028), para o esqueleto andante:
- O job de build no CI: nos PRs (artefato por 3 dias) e nas tags `v0.y.z` (release); o push na main não gera build. O critério 3 desta task, que pedia a build a cada push na main, é refeito quando ela ficar Ready (DEC-0028 §2).
- Os presets já estão no `export_presets.cfg`, com guarda em `test/export_presets_test.gd`. O CI roda o import antes do export, o que evita o #1324 do gdUnit4. Se o #123712 aparecer (o Godot cai ao sair depois do export), o job confere o artefato e o teste de fumaça, e não só o código de saída (DEC-0028, Consequências).
- O teste de fumaça: o servidor exportado sobe sem tela e fecha com código 0, como a sonda provou (F-045 §3).
- A versão: o 0.1.0 entra no commit que fecha esta task, com a tag `v0.1.0`; o CI carimba o commit em `application/config/commit` no export (DEC-0028 §3).
- O aperto de mão na Main: o cliente manda versão e commit, e o servidor recusa os diferentes (DEC-0028 §3).
- Esta é a primeira task no fluxo de branch e PR: nasce numa branch `task-9-...` no In Progress e fecha num PR em português, com o Arthur no merge (DEC-0028 §4).
---

created: 2026-10-10 13:20
---
Entrada do Desenho 6 (TASK-8; DEC-0032), para o esqueleto andante:
- O servidor e os clientes rodam neste PC. Um job do CI, fora do portão e do pre-push, constrói a imagem Docker do servidor Linux em todo push na main e em todo PR e confere que ela sobe e fecha com saída 0, sem guardar artefato (DEC-0032 §1). Como provar a conexão no CI, se não há cliente Linux exportado, sai desta task.
- O fechamento limpo é por um comando nosso, fora de banda (entrada padrão, arquivo ou RPC, a escolher aqui): para o tick, fecha a conexão e sai com 0. O SIGTERM mata com 143, porque o Godot não o trata; o tini como PID 1 só repassa o sinal (DEC-0032 §2; F-073 §2).
- Ponto de partida do Claude, não regra: a sonda em `../servidor-sonda` (Dockerfile com `debian:trixie-slim`, `tini`, usuário sem root e a porta 7777/udp; o preset de servidor dedicado; `application/run/flush_stdout_on_print=true`, sem o qual o log de uma build release só sai quando o buffer enche). A imagem tem 222 MB e fica pronta em 1,2 a 1,6 s (F-073 §1 e §2).
- A TASK-9 começa depois da TASK-11, para o histórico estar parado na virada do repositório para público.
---
<!-- COMMENTS:END -->
