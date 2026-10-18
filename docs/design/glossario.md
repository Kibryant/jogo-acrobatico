---
revisado_em: 2026-10-18
fontes: [F-001, F-002, F-005, F-007, F-012, F-013, F-020, F-021, F-025, F-026, F-028, F-030, F-032, F-038, F-039, F-044, F-045, F-046, F-050, F-051, F-052, F-053, F-056, F-058, F-066, F-068, F-069, F-070, F-073, F-078, F-079, F-081, F-083, F-085, F-086, F-087, F-088, F-090, F-091, F-093]
---

# Glossário

A linguagem ubíqua do jogo (DEC-0004, regra 5): o mesmo termo na conversa, no documento, na task e no código. A coluna "No código" traz o nome em inglês (DEC-0008). Termo novo entra aqui na task que o cria.

## Simulação e rede

| Termo | O que é | Unidade | No código |
|---|---|---|---|
| Lutador | O personagem na simulação, controlado por um jogador ou por um bot. No LoL, é o campeão (DEC-0022) | — | `Fighter` |
| Jogador | A pessoa por trás do lutador; na rede, um peer. No LoL, é o invocador (DEC-0022) | — | `peer_id` |
| Tick | Uma rodada de atualização do jogo, em ritmo fixo: lê o input, aplica as regras e anota a nova situação. O "servidor de 128 ticks" do Valorant faz 128 por segundo | tick | `tick` |
| Ticks por segundo | Quantos ticks a simulação roda por segundo. O jogo roda a 60, um tick a cada 16,7 ms; o padrão do netfox é 30 (DEC-0024) | tick/s | `tickrate` |
| Frame | Um desenho da tela. Varia com o PC (FPS); o tick, não. O frame desenha; o tick decide | frame/s | `frame` |
| Loop de ticks | Os ticks que um frame roda de uma vez para alcançar o relógio: nenhum, um ou vários, até 8. O `Match` faz cada tick do loop rodar uma vez (`rede.md` §2; F-085) | ticks | `before_tick_loop`, `after_tick_loop` |
| Estado | Retrato da simulação num tick, feito de valores planos (número, vetor, texto curto e ID), nunca referência a outro objeto. Fica em quatro caixas: corpo, regras, input e configuração (DEC-0022) | — | `state` |
| Estado do lutador | A caixa de regras do lutador: modo, carimbos e pulos usados. O netfox grava campo a campo, por valor | — | `FighterState` |
| Modo | Em que situação o lutador está: no chão ou no ar e, na fase 1, na parede, no dash ou no gancho. Um por vez, com o tick em que começou | — | `mode`, `mode_since` |
| Ação | O segundo modo, paralelo ao do movimento: o que o lutador faz com as mãos, como preparar um golpe ou bloquear. Fase 2 | — | `action`, `action_since` |
| Carimbo de tick | O tick em que algo aconteceu, guardado no estado no lugar de uma contagem regressiva, como o "flash 12:30" no chat do LoL | tick | `*_tick`, como `jump_pressed_tick` |
| Sanduíche do tick | O tick do lutador em três fatias: o núcleo decide, o motor move e colide, o núcleo confere | — | `before_move`, `move_and_slide`, `after_move` |
| Plano do movimento | O que a primeira fatia do sanduíche devolve: o estado novo e a velocidade que o núcleo pede ao motor | — | `MovePlan` |
| Fatos do movimento | O que o motor devolve depois de mover: se terminou no chão, a velocidade depois da colisão e, na fase 1, a parede | — | `MoveFacts` |
| Configuração | Os números de design convertidos na carga para ticks e para a física do tick. Imutável e fora do estado | — | `MovementConfig` |
| Input | O que o dono do lutador, jogador ou bot, apertou num tick: a direção, para onde olha e os comandos de um toque. É o pedido, nunca o resultado. Mora no nó `Input`, com o script `FighterInput` (DEC-0026) | — | `input`, nó `Input` (`FighterInput`) |
| Comando de um toque | Um aperto que vale uma vez, como o pulo: fica guardado entre os frames e vale no máximo um tick, o seguinte (DEC-0026) | — | `jump`, `dash`, `parry`... |
| Redundância de input | Cada pacote de input repete os 3 últimos ticks, para um pacote perdido não perder o aperto | ticks | `input_redundancy` |
| Previsão | O cliente aplica o próprio input na hora, sem esperar o servidor. A previsão do input dos outros fica desligada (DEC-0026) | — | `prediction` |
| Rollback | Voltar ao estado confirmado e re-simular os ticks seguintes | — | `rollback` |
| Tick novo | Tick simulado pela primeira vez neste peer. Só existe para o nó que o peer simula; som e efeito tocam pela chave do evento, não por ele (DEC-0031) | — | `is_fresh` |
| Interpolação | Mostrar os outros jogadores suavizados entre dois estados recebidos | — | `interpolation` |
| Oponente no passado | O oponente aparece na tela no último estado confirmado que chegou, atrasado pelo atraso de ponta a ponta, e nunca adivinhado (DEC-0026) | ms | — |
| Atraso de visão | Quão velho estava o oponente na tela quando o jogador apertou: o tick atual menos o tick do último estado recebido dele. Vai no input, como um carimbo, a partir da fase 3 | ticks | `view_lag` |
| Compensação de lag | O servidor julga cada ação pela tela de quem a fez: o contato, pela de quem ataca; a defesa por tempo, pela de quem defende; até o teto (DEC-0026) | ms | `lag_compensation` |
| Teto de compensação | Até quanto atraso de visão o servidor aceita: 200 ms, 12 ticks a 60. Acima dele, quem tem o atraso paga o excesso (`combate.md`) | ms no design, ticks no código | `compensation_cap` |
| Contato | A lâmina encostou no corpo do outro, na pose que quem ataca via. Fica no estado de quem ataca, como carimbo, e nunca é desfeito; a defesa decide o resultado depois (DEC-0026) | tick | `contact_tick` |
| Histórico de poses | As poses dos lutadores dos últimos 12 ticks, guardadas no servidor para testar o contato contra a pose que quem ataca via | ticks | — |
| Lag switch | Trapaça: cortar a própria conexão de propósito, para os inputs chegarem atrasados e valerem no passado (Q-17) | — | — |
| Servidor autoritativo | O servidor decide o que aconteceu; o cliente só manda input | — | `server` |
| Ping | O tempo de um pacote ir até o servidor e voltar, o número no canto da tela do LoL. A ida é a metade | ms | `rtt` |
| Atraso de ponta a ponta | Do aperto de um jogador até o estado do lutador dele mudar na tela do outro: as duas idas mais as esperas de tick. A 60 ticks e ping 100, uns 126 ms; a 30, uns 140 (F-026) | ms | — |
| Relógio do servidor | O jeito que o netfox julga sozinho: cada input vale no tick em que foi apertado, no relógio comum. Quem defende paga o atraso de ponta a ponta (F-028) | — | — |
| Estado escondido | Algo que a regra ou o motor usa e o rollback não restaura, e por isso o tick refeito sai diferente do original. Exemplo: o "estava no chão" do `move_and_slide()` (F-025) | — | — |
| SyncTest | O teste que força rollbacks e compara cada tick refeito com o original, como no GGPO. Acusa estado escondido (F-025; DEC-0004, regra 4) | — | — |
| Contorno do transform | Antes de cada tick refeito, empurrar a posição restaurada de cada lutador para a física (estático, transform, cinemático), para um colidir com o outro na posição daquele tick (DEC-0025) | — | `after_prepare_tick` |
| Contorno D | No começo de cada rollback, um micro-movimento de sonda que alinha o "estava no chão" guardado pelo `move_and_slide()` com o `on_floor` do estado (DEC-0025). Se a sonda não acha o chão que o estado diz, o snap do motor completa: o snap de reserva (DEC-0037) | — | `apply_floor_snap()` |
| Par offline | O modo em que o jogo é o próprio servidor, sem rede: o `OfflineMultiplayerPeer` do Godot. É o modo "Sozinho" da `Main` | — | `OfflineMultiplayerPeer` |
| Servidor dedicado | O servidor sem tela e sem lutador próprio, que só simula e decide. Sobe com `--server` ou como build exportado para servidor (DEC-0026) | — | `--server`, `dedicated_server` |
| Sala | As vagas de uma partida no servidor: 2 no esqueleto andante. A vaga escolhe o ponto de nascimento, e quem chega com a sala cheia é recusado (`rede.md` §9) | vagas | `Room` |
| Arquivo de parada | O arquivo cujo aparecimento fecha o servidor limpo, com o código 0: o comando próprio de fechar do servidor (DEC-0032 §2). O servidor confere o caminho a cada segundo | — | `--stop-file`, `StopFile` |
| Tick de nascimento | O primeiro tick em que um lutador existe para o netfox. O servidor o manda ao cliente, e os dois começam dali, do mesmo estado (`rede.md` §9) | tick | `spawn_tick` |
| Ticks refeitos | Os ticks que o rollback simula de novo, por segundo. Crescem com o ping e com o quadrado do tickrate (F-026) | tick/s | `rollback_ticks` |
| Ticks conferidos | Os ticks em que o estado que o cliente previu para o próprio lutador foi comparado com o que o servidor confirmou (`tools/net_run.sh`; `rede.md` §10) | ticks | `PredictionCheck` |
| Ticks corrigidos | Os ticks conferidos em que o servidor discordou da previsão: a posição a mais de 1 mm, ou o `on_floor` ou o `mode` diferentes. Quando a correção é grande, o lutador pula para o lugar certo na tela | ticks | `PredictionCheck` |
| Simulador de rede | A peça do netfox que atrasa os pacotes entre os jogos deste PC, para testar com ping sem um servidor longe. Vem em todo jogo como autoload e só liga numa sessão de teste, por um `override.cfg` temporário (DEC-0038) | ms | `NetworkSimulator` |
| Bot de teste | O programa que joga um lutador no lugar do teclado e do mouse: corre de lado e pula a cada 2 s. Só produz input, como todo bot (DEC-0022) | — | `--bot`, `BotPlayer`, `BotRoute` |
| Sonda | Código descartável, fora do repositório, feito para provar ou derrubar uma hipótese. O jogo não usa | — | — |
| Simulação | O contexto que roda a cada tick: movimento e combate | — | `core/` |
| Meta | O contexto que roda fora do tick: salas, contas e ranking | — | — |

## Combate

| Termo | O que é | Unidade | No código |
|---|---|---|---|
| Preparação | A fase antes de o golpe acertar (startup, windup) | ms no design, ticks no código | `windup` |
| Ativo | A fase em que o golpe acerta | ms no design, ticks no código | `active` |
| Recuperação | A fase depois do golpe, em que o atacante fica vulnerável | ms no design, ticks no código | `recovery` |
| Golpe leve | Golpe rápido e barato | — | `light_attack` |
| Golpe carregado | Golpe segurado, mais lento e mais forte | — | `charged_attack` |
| Bloqueio | Defesa que gasta stamina a cada golpe recebido | — | `block` |
| Parry | Defesa com janela curta, que vence o golpe carregado | — | `parry` |
| Feint | Cancelar um golpe durante a preparação, pagando stamina | — | `feint` |
| Quebra de guarda | Golpe que atravessa o bloqueio | — | `guard_break` |
| Esquiva | Movimento curto com uma janela invulnerável | — | `dodge` |
| Stamina | A única barra de recurso, usada para tudo | pontos | `stamina` |
| Troca de arma | Passar de uma arma do equipamento para outra, com tempo fixo | ms no design, ticks no código | `weapon_swap` |
| Equipamento | Uma arma corpo a corpo, uma de distância e um utilitário | — | `loadout` |
| Hitbox | A área que acerta | m | `hitbox` |
| Hurtbox | A área que pode ser acertada | m | `hurtbox` |
| Fatia varrida | A área que a lâmina percorre do começo ao fim de um tick. O teste do golpe usa a fatia, para a lâmina não pular o corpo entre dois ticks (DEC-0026) | m | `sweep` |
| Vantagem | Depois de uma troca, quem volta a agir primeiro, e com quantos ms de folga | ms no design, ticks no código | `advantage` |
| Tranco | O tempo sem agir de quem leva um golpe (hitstun) ou o bloqueia (blockstun). Ainda sem número (Q-10) | ms no design, ticks no código | `hitstun`, `blockstun` |
| Hitstop | A pausa curta de quem bate e de quem leva, no instante do acerto, que faz o golpe parecer que encostou em algo. É só apresentação: o tick não para, a tela segura a pose. Padrão do gênero (F-083 §4); ainda sem número, v0 do Claude no desenho do duelo (DEC-0036; DEC-0017) | ms | `hitstop` |
| Punir o erro | Acertar quem errou um golpe enquanto ele ainda está na recuperação | — | — |
| Cancelamento | Cortar uma ação para começar outra. Só existe o desenhado: na lista, com preço, com aviso e com janela larga (DEC-0016) | — | `cancel` |
| Janela | O intervalo em que uma ação vale, como a do parry | ms no design, ticks no código | `window` |
| Buffer de input | Guardar um comando apertado antes da hora e executá-lo no primeiro tick livre | ms no design, ticks no código | `input_buffer` |
| Invulnerabilidade | A janela em que nada acerta o jogador (i-frames). No v0, a esquiva tem 250 ms; se alguma manobra terá, ainda não se decidiu | ms no design, ticks no código | `invulnerable` |

## Movimento

| Termo | O que é | Unidade | No código |
|---|---|---|---|
| Corrida na parede | Correr pela parede por um tempo limitado | s | `wall_run` |
| Dash | Arrancada curta, só no chão e sem invulnerabilidade. No v0, separada da esquiva (`movimento.md`) | m, ms | `dash` |
| Gancho | Puxa o jogador até um ponto a até 25 m | m | `grapple` |
| No chão | Superestado do modo: o lutador apoiado no chão, parado, correndo ou no dash (`movimento.md`). É onde a defesa vale | — | `is_grounded(mode)` |
| No ar | Superestado do modo: pulo e gancho; ninguém se defende. Se a corrida na parede conta como ar no combate é a Q-14 | — | `is_airborne(mode)` |
| Manobra | O verbo de uma acrobacia como entidade do núcleo: deslocamento, tempo, custo e o que dá para fazer durante ela. É o back-end; a animação só mostra (F-013 §1) | m, ms | `maneuver` |
| Animação | A apresentação de uma manobra ou de um golpe, no nó. Mostra e nunca decide (DEC-0004) | — | `animation` |
| Transição | Uma animação deslizando para a próxima sem encurtar nenhuma das duas (blend). É só visual | ms | `blend` |
| Cápsula | O corpo de colisão do personagem: 1,8 m de altura e 0,35 m de raio no v0 | m | `capsule` |
| Viseira | A faixa escura na frente da cápsula. Mostra para onde o lutador olha, e o corpo olha para onde a câmera olha (`movimento.md`, princípios; F-090) | — | nó `Visor` |
| Pulo duplo | O segundo pulo no ar, um por voo, renovado no chão ou ao começar uma corrida na parede | m | `double_jump` |
| Pulo da parede | O pulo que sai da corrida na parede, jogando o jogador para fora dela | m, m/s | `wall_jump` |
| Controle no ar | Quanto o jogador muda a direção no ar, em % da aceleração do chão | % | `air_control` |
| Coyote time | O tempo em que ainda dá para pular depois de sair da beirada. O nome vem do Coiote do Papa-Léguas, que corre para fora do penhasco e só cai quando olha para baixo | ms no design, ticks no código | `coyote_time` |
| Pulo atrasado | O pulo de coyote dado no fim da janela. A corrida antes dele ganha distância, e ele sobe um degrau de 1 m a 4 m de distância que o pulo na beirada não alcança (`movimento.md`, métricas de nível; F-086) | ticks | — |
| Snap do chão | O puxão do motor que, depois de mover, cola o corpo num chão que desce. Cobre a descida da rampa de 45° a 7 m/s: 0,121 m por tick a 60 | m | `floor_snap_length` |
| Conservação de velocidade | A velocidade que passa de uma manobra para a outra | m/s | `momentum` |
| Recarga | O tempo até uma manobra poder ser usada de novo | ms no design, ticks no código | `cooldown` |

## Desenho

| Termo | O que é | Unidade | No código |
|---|---|---|---|
| Pilar | Frase sobre a experiência que o jogo precisa entregar. A ordem dos pilares desempata (`visao.md`) | — | — |
| Anti-pilar | O que o jogo decide não ser | — | — |
| Verbo | O que o jogador faz: correr, subir na parede, dar dash, puxar o gancho, golpear | — | — |
| Leitura | O aviso que uma ação dá antes de acontecer: postura, brilho, som (telegraph) | ms no design, ticks no código | `telegraph` |
| Compromisso | O quanto o jogador fica preso depois de começar uma ação | ms | — |
| Piso e teto de habilidade | Quanto custa começar e até onde dá para melhorar | — | — |
| Contrajogo | Toda opção tem resposta; cada posição tem força e fraqueza | — | — |
| Expressão de habilidade | A habilidade aparecendo na jogada, como o outplay | — | — |
| Métricas de nível | As medidas da arena que saem do movimento: vão, altura de bloco, comprimento de parede | m | — |

## Testes e entrega

| Termo | O que é | Unidade | No código |
|---|---|---|---|
| Esteira | O caminho de uma mudança até o jogo na mão do jogador, com uma checagem em cada estação: o hook do Claude, o commit, o push, o CI e a build (pipeline) | — | — |
| Portão | As checagens que todo push precisa passar, no pre-push e no CI: formato, lint, pureza, travas, import, compilar tudo e testes (DEC-0027) | s | `tools/gate.sh` |
| Compilar tudo | O passo do portão que carrega todos os nossos scripts numa execução só do Godot, como o `tsc --noEmit` | s | `tools/check_scripts.sh` |
| Canário | Um arquivo com erro de propósito que uma checagem precisa barrar a cada rodada; se ele passar, a checagem perdeu uma regra | — | `tools/canaries/` |
| Log limpo | Um portão verde não tem linha `ERROR:` no log; testes que passam com erro no log reprovam (F-039) | — | `tools/run_tests.sh` |
| Trava do teste de aceite | O sha256 de um teste de aceite, guardado enquanto a task está aberta. Só o Arthur destrava (DEC-0009) | — | `.claude/harness/locks/` |
| Hook do Claude Code | Um comando que o Claude Code roda antes ou depois de cada ferramenta do agente, como um middleware. Aqui, ele nega a edição de teste travado e formata o `.gd` | — | `.claude/hooks/` |
| Replay por inputs | A partida guardada como o input de cada tick e tocada de novo no servidor. Só reproduz na mesma build: a mesma tecla com outra regra dá outra partida (DEC-0011; DEC-0027) | — | — |
| Referência | Um replay gravado de um percurso, com o caminho guardado; o teste refaz e compara, como o snapshot do Jest. Mudou de propósito? Regrava, e o commit diz por quê (golden master; DEC-0027) | — | — |
| Números congelados | A cópia dos números do movimento que só a referência usa: o ajuste fino do jogo não a quebra, só uma mudança de código (DEC-0027) | — | — |
| Build | O jogo empacotado para rodar fora do editor: o template mais o pacote do jogo, num arquivo só (DEC-0028) | MB | `build/` |
| Template de export | O motor compilado sem o editor, por plataforma. É o Chromium do Electron (DEC-0028) | MB | — |
| Pacote (`.pck`) | As cenas, os scripts e os dados do jogo, empacotados. É o `.asar` do Electron (DEC-0028) | kB | — |
| Preset de export | A receita de uma build: plataforma, o que entra e o que fica de fora. Há dois: o cliente Windows e o servidor Linux (DEC-0028) | — | `export_presets.cfg` |
| Feature tag | Uma marca na build que o código consulta, como o `NODE_ENV`. A do servidor é `dedicated_server` (DEC-0028) | — | `OS.has_feature` |
| Artefato | O arquivo que o CI guarda depois de rodar, como as builds de um PR, por alguns dias (DEC-0028) | MB | — |
| Release | Uma versão publicada no GitHub, a partir de uma tag, com as builds e as notas (DEC-0028) | — | `v0.y.z` |
| Versão | O número da build, em SemVer `0.y.z`: o `y` sobe a cada marco do roteiro, o `z` a cada build que sai (DEC-0028) | — | `application/config/version` |
| Carimbo do commit | Os 7 primeiros caracteres do commit, escritos pelo CI na build: dizem exatamente qual código rodou (DEC-0028) | — | `application/config/commit` |
| Aperto de mão | Na conexão, o cliente manda a versão e o commit, e o servidor recusa os diferentes (DEC-0028). Roda na etapa de autenticação do Godot, e a recusa pede para atualizar o jogo ou diz que a sala está cheia (`rede.md` §9) | — | `Handshake` |
| Branch da task | A linha de trabalho de uma task, do In Progress ao Done, que volta para a main num PR (DEC-0028) | — | `task-N-nome` |
| PR | O pedido para juntar uma branch na main: o lugar onde o Arthur revisa o diff e joga a build (DEC-0028) | — | — |
| Merge commit | O commit que junta a branch na main sem apagar os commits dela; desfazer a task inteira é um revert só (DEC-0028) | — | — |
| Worktree | Uma segunda pasta do mesmo repositório, noutra branch: duas sessões ao mesmo tempo nunca dividem a mesma pasta (DEC-0028) | — | `git worktree` |

## Visual e áudio

| Termo | O que é | Unidade | No código |
|---|---|---|---|
| Token de leitura | O sinal que um estado do combate emite para quem olha: uma cor, uma pose e um som, sempre os três juntos. Vive como dado num Resource, é lido do estado e toca uma vez por evento, pela chave (DEC-0031; F-053) | — | `telegraph_token` |
| Reagível | Golpe que dá para ver começar e responder a tempo, sem adivinhar. Uma pessoa mediana reage em 213 a 273 ms; o leve de 300 ms não é reagível para bloquear, o carregado de 500 a 900 é (F-053 §2) | ms | — |
| CC0 | Licença em que o autor abre mão de todos os direitos: uso comercial, modificação e redistribuição livres, sem crédito. Uma lib MIT sem nem o aviso (F-050) | — | — |
| CC BY | Licença que permite tudo com crédito ao autor, na forma que a licença pede (F-050) | — | — |
| EULA | O contrato próprio de uma loja de assets: compra-se o direito de usar no jogo, não o arquivo. Costuma proibir passar o arquivo-fonte para fora do time, o que tranca o repositório como privado (F-050) | — | — |
| Rig | Os ossos dentro do modelo 3D; a animação mexe nos ossos, e a malha acompanha (F-052) | — | `Skeleton3D` |
| Retarget | Tocar num rig uma animação feita para outro, casando os nomes e as poses de repouso dos ossos (F-051 §1.5) | — | `BoneMap`, `SkeletonProfileHumanoid` |
| Clipe | Uma animação com nome, como "golpe leve". Entra in place, com marcas de início e fim do ativo, e tem o tempo reajustado pelo estado, fase a fase (F-052 §6) | ms no design, ticks no código | `Animation` |
| Root motion | O clipe carrega o deslocamento do corpo. Aqui nunca move o lutador: o deslocamento vem do núcleo, e o clipe entra in place (F-007; F-052 §6.3) | — | `root_motion_track` |
| Casco invertido | O contorno feito com uma segunda casca da malha, um pouco maior e só com as faces de trás. Funciona no Compatibility (F-051 §2.5) | — | `grow`, `next_pass` |
| Theme | A folha de estilo da interface do Godot: os tipos de tema são os seletores, os itens são as propriedades, as variações são as classes e o override local é o style inline (F-051 §3.1) | — | `Theme` |
| Bus de som | Um canal de mixagem com volume e efeitos próprios, como um canal de uma mesa de som. O bus "leitura" abaixa os outros para o aviso do golpe nunca ser mascarado (F-051 §5.2; F-053 §4) | dB | `AudioServer` |
| Redistribuir | Passar adiante uma cópia do arquivo. Um repositório público redistribui tudo o que tem dentro, para cada pessoa que clona; por isso só entra asset cuja licença deixa redistribuir, pago ou grátis (F-058) | — | — |
| Projeto aberto | Código público com uma licença que deixa outros usarem, mudarem e mandarem PR. O mantenedor decide o que entra no merge, como no próprio Godot (F-058) | — | — |
| Orçamento de vértices | Quantos vértices um lutador pode ter no detalhe máximo para 16 lutadores caberem no piso de 60 fps. O valor v0 é 10 mil, com a arma, e LOD a distância (DEC-0030 §6; F-056 §6) | vértices | — |
| Marca do ativo | O trecho de um clipe em que o golpe pega, marcado à mão. O clipe de biblioteca não traz a marca; no `Sword_Regular_A`, ela fica de 46% a 69% do clipe (F-056 §4) | % do clipe | — |
| Chave do evento | O nome de um acontecimento do combate que a tela apresenta uma vez só, por exemplo "ativo do ataque 542": a tela compara o estado exibido com o último que apresentou e toca o som ou o efeito de cada chave nova. Cobre o nó próprio, o oponente espelhado e o veredito que nasce num tick refeito, onde o `is_fresh` do netfox não chega (F-061 §2). Como a `key` de uma lista no React: reaplicar o mesmo estado não cria evento | — | `present()`, `_cued` |
| Pack de terceiros | Um conjunto de assets de uma fonte de fora, numa pasta `assets/third_party/<fonte>/<pack>/` com o arquivo de licença dentro e uma linha no `CREDITS.md`; sem os dois, o portão derruba (DEC-0029) | — | `assets/third_party` |

## Infraestrutura

| Termo | O que é | Unidade | No código |
|---|---|---|---|
| Gatilho | O momento em que um serviço entra no projeto, amarrado a uma fase ou a um número, nunca antes. Contas, Steam e salas entram "na hora da funcionalidade" (DEC-0012) | — | — |
| Ping | O tempo de um pacote ir até o servidor e voltar. Daqui, uns 26 ms até São Paulo e de 113 a 195 ms até os EUA; a 60 ticks, 26 ms são 1,6 tick (F-070) | ms | — |
| Região | O lugar do data center onde o servidor roda. É escolher o servidor BR no LoL: o mesmo jogo, com outro ping (DEC-0011; F-070) | — | — |
| CGNAT | A operadora divide um IPv4 público entre vários clientes. Ninguém de fora abre conexão direto com um PC atrás dele, nem com porta redirecionada; um amigo só entra por um túnel ou por um servidor fora de casa (F-070 §4; F-066 §4) | — | — |
| VPS | Um servidor virtual alugado por mês num data center, com núcleos, memória e banda contados. Na Vultr em São Paulo, começa em US$ 7,50 por mês, 1,5 vez o preço das outras regiões (F-066 §13) | R$/mês | — |
| Imagem e contêiner | A imagem é o servidor empacotado com um Linux mínimo, o binário e o pacote do jogo; o contêiner é uma cópia dela rodando. Roda igual aqui, no CI e num servidor alugado, como um `package-lock.json` que trava até o sistema operacional (F-066 §5) | MB | `Dockerfile` |
| Servidor da comunidade | Um servidor dedicado que um jogador sobe com a build do servidor e anuncia na lista. O projeto paga o oficial, a lista e o ranking, e o ranking só conta nos servidores oficiais, como no DDNet (F-066 §6) | — | — |
| Lista de servidores | O serviço pequeno em que cada servidor se anuncia e o cliente escolhe onde jogar. Com um servidor só, ele mesmo lista as salas, no estilo do GunZ (F-066 §6) | — | — |
| Licença permissiva e copyleft | A permissiva (MIT, Apache) deixa qualquer um usar, mudar e até fechar o código, desde que mantenha o aviso, como o Godot e o netfox. A copyleft (GPL) obriga quem distribui uma versão mudada a abrir o código dela, como o Linux (F-068 §4) | — | `LICENSE` |
| Assinatura da build | Um certificado que diz ao Windows quem publicou o `.exe`. Sem ele, o Smart App Control barra a build de um jogo novo; o SignPath assina de graça projeto de código aberto (F-069 §7; Q-20) | — | — |
| Cota do LFS | Quanto o GitHub guarda e entrega dos arquivos grandes no plano grátis: 10 GiB guardados e 10 GiB baixados por mês. Num repositório público, todo download sai da cota do dono, até o de um fork (F-050 §5; F-069 §3) | GiB | `.gitattributes` |
| Registro de imagens | Onde a imagem do servidor fica guardada para outra máquina baixar. É o npm das imagens; a sonda usou o registro da Edgegap (F-073 §1) | MB | `docker push` |
| Deploy | Pôr uma cópia da imagem para rodar num servidor de verdade. Na Edgegap grátis, um por vez e por 60 minutos (F-066 §2; F-073 §3) | min | — |
| Sinal de parada e PID 1 | O `docker stop` manda o SIGTERM ao primeiro processo do contêiner. O Godot não o trata e morre com saída 143; por isso o servidor fecha por um comando nosso, e o `tini` como PID 1 só repassa o sinal (DEC-0032 §2; F-073 §2) | — | `tini` |
| Ruleset | A trava da main no próprio GitHub: o pre-push do lado do servidor, valendo para quem não tem este PC. Aqui, recusa force push e apagar a main (DEC-0033 §3) | — | — |
| PR de fork | O pedido de merge de quem não tem acesso ao repositório: a pessoa copia o projeto, muda e pede para entrar. O CI dele só roda com a aprovação do Arthur, sem segredo (DEC-0033 §3) | — | — |
| Inbound=outbound | Quem manda um PR entrega o código sob a mesma licença do repositório, pelos termos do GitHub, sem contrato extra (DEC-0033 §1; F-068 §6) | — | `LICENSE` |
| Virada para público | Tornar o repositório público. Libera o CI grátis em 4 núcleos e as travas que o plano Free só dá a repositório público, zera os watchers e não se desfaz: quem clonou ou fez fork fica com a cópia (F-069 §5 e §12, R-12; F-080 §2; F-081 §3 a §5) | — | `gh repo edit --visibility public` |
| Commit solto | Commit que nenhuma branch alcança, como o de uma branch apagada. Não vem num clone, mas o GitHub ainda o mostra pelo SHA; por isso entrou na varredura da abertura (F-079 §2; F-081 §2) | — | `git rev-list <sha> --not --all` |
| Runner | A máquina do GitHub que roda o CI. No repositório público, o padrão tem 4 núcleos e 16 GB e sai de graça; no privado, 2 núcleos e 8 GB, na cota de minutos. O passo "Runner size" do CI mostra qual rodou (F-069 §1; F-081 §5) | vCPU | `runs-on: ubuntu-24.04` |
| Secret scanning e push protection | O GitHub procura senhas e chaves nos commits e, com o push protection, recusa o push que traz uma: o gitleaks do lado do servidor (F-069 §4; F-081 §4) | — | — |
| Alerta do Dependabot | O aviso do GitHub quando uma dependência do repositório, como uma action do CI, tem uma falha de segurança conhecida (F-069 §4; F-081 §4) | — | — |
| Relato privado de vulnerabilidade | O botão da aba Security por onde alguém conta uma falha só para o mantenedor, em vez de abrir uma issue pública (F-069 §4; F-081 §4) | — | `SECURITY.md` |
| Código de conduta | As regras de convivência da comunidade: o Contributor Covenant 3.0 traduzido, com o Arthur na moderação e o Gmail dele como contato (F-078 §2; F-079 §3) | — | `CODE_OF_CONDUCT.md` |
