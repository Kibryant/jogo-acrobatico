---
revisado_em: 2026-10-30
fontes: [F-001, F-002, F-005, F-007, F-012, F-013, F-020, F-021, F-025, F-026, F-028, F-029, F-030, F-032, F-038, F-039, F-044, F-045, F-046, F-050, F-051, F-052, F-053, F-056, F-058, F-061, F-066, F-068, F-069, F-070, F-073, F-078, F-079, F-080, F-081, F-083, F-085, F-086, F-087, F-088, F-090, F-091, F-093, F-094, F-095, F-097, F-100, F-112, F-121, F-122, F-129, F-135, F-141, F-146, F-147, F-148, F-152, F-158, F-161, F-165, F-166, F-167, F-169, F-170, F-172, F-173, F-174, F-175, F-176, F-191, F-192]
---

# Glossário

A linguagem ubíqua do jogo (DEC-0004, regra 5): o mesmo termo na conversa, no documento, na task e no código. A coluna "No código" traz o nome em inglês (DEC-0008). Termo novo entra aqui na task que o cria.

## Simulação e rede

| Termo | O que é | Unidade | No código |
|---|---|---|---|
| Lutador | O personagem na simulação, controlado por um jogador ou por um bot. No LoL, é o campeão (DEC-0022) | — | `Fighter` |
| Jogador | A pessoa por trás do lutador; na rede, um peer. No LoL, é o invocador (DEC-0022) | — | `peer_id` |
| Tick | Uma rodada de atualização do jogo, em ritmo fixo: lê o input, aplica as regras e anota a nova situação. O "servidor de 128 ticks" do Valorant faz 128 por segundo | tick | `tick` |
| Passo de física | A batida fixa do motor do Godot, 60 por segundo, independente dos quadros da tela. O tick do netfox roda dentro dela, então anda sempre o mesmo tempo, a 30 ou a 144 fps (DEC-0040) | passo | `_physics_process`, `sync_to_physics` |
| Ticks por segundo | Quantos ticks a simulação roda por segundo. O jogo roda a 60, um tick a cada 16,7 ms; o padrão do netfox é 30 (DEC-0024) | tick/s | `tickrate` |
| Frame | Um desenho da tela. Varia com o PC (FPS); o tick, não. O frame desenha; o tick decide | frame/s | `frame` |
| Loop de ticks | Os ticks que um frame roda de uma vez para alcançar o relógio: nenhum, um ou vários, até 8; também laço de ticks. O `Match` faz cada tick do loop rodar uma vez (`rede.md` §2; F-085). O arquivo de replay guarda o tamanho do laço de cada tick, e o tocador sem tela roda laço a laço como foi gravado (TASK-10.3) | ticks | `before_tick_loop`, `after_tick_loop`, a coluna `loop` |
| Estado | Retrato da simulação num tick, feito de valores planos (número, vetor, texto curto e ID), nunca referência a outro objeto. Fica em quatro caixas: corpo, regras, input e configuração (DEC-0022) | — | `state` |
| Estado do lutador | A caixa de regras do lutador: modo, carimbos e pulos usados. O netfox grava campo a campo, por valor | — | `FighterState` |
| Modo | Em que situação o lutador está: no chão ou no ar e, na fase 1, na parede, no dash ou no gancho. Um por vez, com o tick em que começou | — | `mode`, `mode_since` |
| Ação | O segundo modo, paralelo ao do movimento: o que o lutador faz com as mãos. Nada, a preparação, o ativo e a recuperação de um golpe, a guarda, a postura do parry, a finta, o tranco, o agarrão. Um por vez, com o tick em que começou, como o `mode`; o golpe em curso vai por ID, e a direção dele fica guardada do primeiro tick ativo em diante (`combate.md`, "O leve no tick"; DEC-0051) | — | `action`, `action_since`, `action_move`, `action_yaw` |
| Troca por comando | A troca de modo que nasce de um aperto, no `before_move`, onde o comando sai: o dash leva `GROUND → DASH` no tick do aperto. Como lançar uma habilidade no LoL: a tecla decide, e não o chão (DEC-0041) | — | `Movement.before_move` |
| Troca por contato | A troca de modo que nasce do que o motor relata, no `after_move`: tocou o chão, `GROUND`; deixou o chão, `AIR`. Nunca termina um modo comprometido: o dash que sai da beirada continua dash (DEC-0041 §3) | — | `Movement.after_move` |
| Saída desenhada | O tick em que um modo comprometido termina pela própria regra, com a velocidade e o modo do desenho: o dash sai a 7 m/s na mesma direção, em `GROUND` ou `AIR` conforme o chão, e um aperto guardado pode sair no mesmo tick (DEC-0041 §2; `movimento.md`, "Dash") | tick | `dash_exit_speed`, `Movement.before_move` |
| Carimbo de tick | O tick em que algo aconteceu, guardado no estado no lugar de uma contagem regressiva, como o "flash 12:30" no chat do LoL | tick | `*_tick`, como `buffered_tick` e `stamina_spent_tick` |
| Sanduíche do tick | O tick do lutador em fatias: desde a TASK-12.1, o núcleo luta; depois decide, o motor move e colide, e o núcleo confere (DEC-0051) | — | `Combat.step`, `before_move`, `move_and_slide`, `after_move` |
| Foto do tick | A cópia de todos os lutadores, com o nome, os pés e o estado, tirada logo depois de o netfox restaurar o tick. Cada lutador lê os outros só nela, e por isso a ordem dos nós não muda o resultado. Como dar a cada função uma cópia do estado do começo, e não o objeto que a anterior acabou de mexer (DEC-0026 §3; DEC-0051) | — | `TickPhoto` |
| Plano do movimento | O que a primeira fatia do sanduíche devolve: o estado novo e a velocidade que o núcleo pede ao motor e, desde a TASK-10.6, o pedido de mira | — | `MovePlan` |
| Fatos do movimento | O que o motor devolve depois de mover: se terminou no chão, a velocidade depois da colisão, desde a TASK-10.5 a parede que toca, com a normal e o caminho do colisor (DEC-0042), e desde a TASK-10.6 a posição e a resposta da mira, quando o núcleo pede (DEC-0044) | — | `MoveFacts` |
| Pedido de mira | O pedido que o núcleo faz no plano quando há um Q válido na vaga: "o que tem na mira?". O nó lança o raio do ombro depois do movimento e devolve a resposta nos fatos. Como uma função pura do TypeScript que não pode fazer `fetch`: ela pede o dado, e quem a chamou o busca (DEC-0044) | — | `MovePlan.aim_request` |
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
| Contato | A lâmina encostou no corpo do outro, na pose que quem ataca via. Fica no estado de quem ataca, como carimbo, com o tick, o nome do alvo e o golpe, e nunca é desfeito; a defesa decide o resultado depois. Quem levou o aplica no tick seguinte, o primeiro em que a foto o mostra (DEC-0026; DEC-0051) | tick | `contact_tick`, `contact_target`, `contact_move` |
| Vida | Os pontos que um golpe tira: 100 por lutador, que nunca descem de 0. Sem partida, voltam a 100 dois segundos depois do último golpe levado, o treino contra o boneco (`partida.md`, "A vida sem partida") | pontos | `health` |
| Golpe levado | O carimbo do último golpe que pegou o lutador: o tick do contato, não o tick em que ele o aplicou. É a chave do flash branco, e o tranco da TASK-12.2 conta dele (`combate.md`, "O leve no tick") | tick | `hurt_tick` |
| Golpe bloqueado | O carimbo do último golpe que o lutador bloqueou: o tick do contato. É a chave do sinal do bloqueio e o que quem bateu lê, pela foto, para saber que foi bloqueado e congelar (`combate.md`, "O tranco e a vantagem"; DEC-0055) | tick | `block_tick` |
| Histórico de poses | As poses dos lutadores dos últimos 12 ticks, guardadas no servidor para testar o contato contra a pose que quem ataca via | ticks | — |
| Lag switch | Trapaça: cortar a própria conexão de propósito, para os inputs chegarem atrasados e valerem no passado (Q-17) | — | — |
| Servidor autoritativo | O servidor decide o que aconteceu; o cliente só manda input | — | `server` |
| Ping | O tempo de um pacote ir até o servidor e voltar, o número no canto da tela do LoL. A ida é a metade | ms | `rtt` |
| Atraso de ponta a ponta | Do aperto de um jogador até o estado do lutador dele mudar na tela do outro: as duas idas mais as esperas de tick. A 60 ticks e ping 100, uns 126 ms; a 30, uns 140 (F-026) | ms | — |
| Relógio do servidor | O jeito que o netfox julga sozinho: cada input vale no tick em que foi apertado, no relógio comum. Quem defende paga o atraso de ponta a ponta (F-028) | — | — |
| Estado escondido | Algo que a regra ou o motor usa e o rollback não restaura, e por isso o tick refeito sai diferente do original. Exemplo: o "estava no chão" do `move_and_slide()` (F-025) | — | — |
| SyncTest | O teste que força rollbacks e compara cada tick refeito com o original, como no GGPO. Acusa estado escondido (F-025; DEC-0004, regra 4) | — | — |
| Sonda do motor | Um teste do portão que mede um fato do motor antes que uma regra dependa dele, com o rollback forçado e as precondições provadas. Ao contrário da sonda, fica no repositório. A sonda A mostrou que a parede não tem estado escondido (TASK-10.5); a sonda B, que o raio da mira sai igual no tick refeito (TASK-10.6); a sonda C, que a cabeça do outro já não diverge, porque o snap de reserva da DEC-0037 a zerou (TASK-10.7; `rede.md` §4) | — | `test/fighter/engine_probe_test.gd`, `aim_probe_test.gd`, `head_probe_test.gd` |
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
| Bot de teste | O programa que joga um lutador no lugar do teclado e do mouse: corre de lado e pula a cada 2 s, dá o pulo duplo no topo do pulo e o dash no chão, depois do pouso (TASK-10.8; F-165). Só produz input, como todo bot (DEC-0022) | — | `--bot`, `BotPlayer`, `BotRoute` |
| Sonda | Código descartável, fora do repositório, feito para provar ou derrubar uma hipótese. O jogo não usa | — | — |
| Simulação | O contexto que roda a cada tick: movimento e combate | — | `core/` |
| Meta | O contexto que roda fora do tick: salas, contas e ranking | — | — |

## Combate

| Termo | O que é | Unidade | No código |
|---|---|---|---|
| Preparação | A fase antes de o golpe acertar (startup, windup) | ms no design, ticks no código | `windup` |
| Ativo | A fase em que o golpe acerta | ms no design, ticks no código | `active` |
| Recuperação | A fase depois do golpe, em que o atacante fica vulnerável | ms no design, ticks no código | `recovery` |
| Golpe leve | O golpe rápido e barato: 250 / 100 / 200 ms (DEC-0052), 8 de stamina, 12 de dano. Rápido demais para reagir: ele se defende segurando a guarda antes, como o jab do Mortal Kombat. Não se apara, não freia o corpo, e o tranco dele é curto (`combate.md`, "Os golpes e as defesas") | ms no design, ticks no código | `light_attack` |
| Golpe carregado | O golpe lento e forte: 700 ms de preparação fixa, 120 de ativo, 450 de recuperação, 25 de stamina pagos na soltura, 30 de dano. Tem armadura contra leves na preparação, e é o único golpe que se apara (`combate.md`) | ms no design, ticks no código | `charged_attack` |
| Bloqueio | A guarda segurada no botão direito: sobe em 100 ms, para o leve e o carregado, não a quebra; cobre a metade da frente, 90° para cada lado de onde o corpo olha; custa 5 por leve e 15 por carregado bloqueado, e anda a 3 m/s (`combate.md`, "O bloqueio, a guarda andando e a stamina"; DEC-0054) | ms no design, ticks no código | `block` |
| Parry | A defesa de tempo que vence o carregado: uma janela de 200 ms desde o aperto, 15 de stamina. Aparou, recupera em 200 e tem um carregado garantido; errou, 450 de pé. Só o carregado se apara (`combate.md`, "O parry") | ms no design, ticks no código | `parry`, `parry_tick` |
| Feint | Cancelar um golpe durante a preparação, pagando stamina | — | `feint` |
| Quebra de guarda | O agarrão que atravessa o bloqueio e a postura do parry: 350 / 100 / 400 ms, 15 de stamina, sem dano. No contato, os dois ficam presos 333 ms, a janela do tech; sem o tech, 1.000 ms de tranco e um carregado garantido (`combate.md`, "A quebra de guarda e o tech") | ms no design, ticks no código | `guard_break` |
| Esquiva | O movimento curto com uma janela invulnerável. É o dash, invulnerável dos ticks 3 a 10 dos seus 12; não existe tecla à parte (`combate.md`, "A esquiva e o dash"; DEC-0050) | ms no design, ticks no código | `dodge` |
| Stamina | A única barra de recurso, usada para tudo | pontos | `stamina` |
| Troca de arma | Passar de uma arma do equipamento para outra, com tempo fixo | ms no design, ticks no código | `weapon_swap` |
| Equipamento | Uma arma corpo a corpo, uma de distância e um utilitário | — | `loadout` |
| Hitbox | A área que acerta | m | `hitbox` |
| Hurtbox | A área que pode ser acertada | m | `hurtbox` |
| Fatia varrida | A área que a lâmina percorre do começo ao fim de um tick. O teste do golpe usa a fatia, para a lâmina não pular o corpo entre dois ticks (DEC-0026) | m | `sweep` |
| Vantagem | Depois de uma troca, quem volta a agir primeiro, e com quantos ticks de folga: o tranco de quem leva menos o que falta a quem bateu. Como o cooldown no LoL: quem tem a skill de volta antes ganha a próxima (`combate.md`, "O tranco e a vantagem") | ms no design, ticks no código | `advantage` |
| Tranco | O tempo sem agir de quem leva um golpe (hitstun) ou o bloqueia (blockstun): 400 ms no leve e 700 no carregado que acertam, 250 e 417 bloqueados, 900 para quem é aparado, 1.000 para a quebra sem tech. Conta do tick do contato e para durante a paradinha. Sem input de movimento nem de ação; a gravidade segue (`combate.md`, "O tranco e a vantagem"; Q-10) | ms no design, ticks no código | `hitstun`, `blockstun`, `stun_until_tick` |
| Hitstop | A pausa curta de quem bate e de quem leva, no instante do acerto, que faz o golpe parecer que encostou em algo. No v0 é simulado: os dois congelam o mesmo tempo, de 2 a 12 ticks, cada um quando sabe o resultado (quem levou no tick seguinte ao contato, quem bateu um tick depois, pela foto), parados no lugar e com a velocidade guardada para depois (DEC-0055); o relógio do golpe e o do tranco dos dois param junto, e a vantagem não muda; no parry, só quem foi aparado congela. É estado do núcleo e volta no rollback (`combate.md`, "O hitstop e o tremor"; F-173 §2). O tremor da câmera que o acompanha é só apresentação | ms no design, ticks no código | `frozen_until_tick` |
| Armadura | O golpe que leva o dano e não para: a preparação do carregado contra leves. É o que faz o carregado vencer o leve, como no Naraka (`combate.md`, "A armadura do carregado"; F-173 §1) | — | `armor` |
| Tech | A resposta à quebra de guarda: apertar a própria tecla da quebra nos 333 ms depois de ser agarrado. Os dois se soltam, e quem respondeu fica 2 ticks à frente. É reação simples, a um estímulo só, como o "GB tech" do For Honor (`combate.md`, "A quebra de guarda e o tech") | ms no design, ticks no código | `guard_break_tech` |
| Finta | O corte da preparação do carregado, apertando o botão da guarda até os 450 ms: custa 15, recupera em 200, e o carregado não paga os 25. Pune quem apara cedo, como o drible que mostra um lado e vai para o outro (`combate.md`, "A finta"; DEC-0016) | ms no design, ticks no código | `FEINT` |
| Postura do parry | A ação depois do aperto do parry: a janela nos 12 primeiros ticks e, sem carregado aparado nela, mais 27 de recuperação; aparou, ela acaba 12 ticks depois do contato. Não bloqueia nada: o leve pega nela (`combate.md`, "O carregado, o parry e a finta no tick"; DEC-0056) | ticks | `PARRY` |
| Aparado | Quem bateu com o carregado e foi aparado: lê o parry na foto dois ticks depois do contato e fica num tranco sem dano até o contato + 54 + 9, os 9 primeiros congelado (DEC-0056) | ticks | `PARRIED`, `parried_tick` |
| Aperto da guarda | O toque do botão da guarda, verdadeiro só no tick em que ele desce, ao lado do segurar. Na preparação do carregado, é a finta; quem já segurava a guarda não finta sem querer, como o `keydown` do navegador, que não se repete com a tecla presa (DEC-0056) | — | `guard_press` |
| Castigo garantido | Dano que o outro não evita com nenhuma ação: o carregado depois de um parry ou de uma quebra sem tech (`combate.md`, "O tranco e a vantagem") | — | — |
| Seguro | O golpe bloqueado que deixa quem bateu para trás, mas não tanto que o outro acerte antes de a guarda subir: aqui, desvantagem de até 9 ticks, os 15 da preparação do leve menos os 6 da guarda (`combate.md`; DEC-0052) | ticks | — |
| Troca | Dois golpes que pegam no mesmo tick: os dois levam o dano e o tranco (`combate.md`) | — | `trade` |
| Golpe que desce | O leve dado no ar, com o arco inclinado 45° para baixo: o golpe de quem está no alto (`combate.md`, "A matriz de posição"; DEC-0050). Um por pulo (DEC-0053) | ° | `air_light` |
| Golpe por pulo | O limite do golpe no ar: um leve no ar por pulo. O pulo do chão ou a queda de uma beirada, o pulo duplo, o pulo da parede e a soltura do gancho dão um cada; depois do golpe, o aperto espera o próximo (`combate.md`, "A matriz de posição"; DEC-0053) | — | — |
| Regra das mãos | Uma manobra que ocupa uma mão só deixa usar arma de uma mão: na puxada do gancho, a espada não ataca; a pistola, mais tarde, cabe (`combate.md`, "A matriz de posição"; Q-14; DEC-0050) | — | — |
| Guarda andando | Com a guarda alta, o corpo anda a 3 m/s; correr, pular e o dash derrubam a guarda (`combate.md`, "O bloqueio, a guarda andando e a stamina"). O carregado anda no mesmo andar devagar; o leve não freia o corpo (DEC-0052) | m/s | `slow_walk_speed_mps` |
| Lâmina | O segmento com raio que a conta do golpe usa: começa na mão, a 0,6 m do eixo e 1,3 m de altura, tem 1,4 m e 0,08 m de raio, e varre um arco no ativo (`combate.md`, "A lâmina e o contato") | m | `blade` |
| Golpe que acerta uma vez | Cada golpe acerta cada alvo no máximo uma vez por janela ativa. No v0, um golpe guarda um contato só: depois dele, a lâmina não testa mais até o golpe acabar; no 1v1 é a mesma regra (`combate.md`, "O leve no tick"; Q-26; DEC-0051) | — | `contact_tick` |
| Punir o erro | Acertar quem errou um golpe enquanto ele ainda está na recuperação | — | — |
| Cancelamento | Cortar uma ação para começar outra. Só existe o desenhado: na lista, com preço, com aviso e com janela larga (DEC-0016) | — | `cancel` |
| Janela | O intervalo em que uma ação vale, como a do parry | ms no design, ticks no código | `window` |
| Buffer de input | Guardar um comando apertado antes da hora e executá-lo no primeiro tick livre | ms no design, ticks no código | `input_buffer` |
| Invulnerabilidade | A janela em que nada acerta o jogador (i-frames). No v0, só o dash a tem, nos ticks 3 a 10 (`combate.md`, "A esquiva e o dash"; DEC-0050) | ms no design, ticks no código | `invulnerable` |

## Partida

| Termo | O que é | Unidade | No código |
|---|---|---|---|
| Partida | O duelo inteiro: rounds até alguém ganhar 3, no máximo 9. É o contexto "Partida e round" da arquitetura, uma máquina de estados pequena e pura no servidor: contagem, luta, fim de round, fim de partida (`partida.md`, "O duelo"; `visao-geral.md`) | — | `MatchState` |
| Round | Uma luta de até 90 s, com a vida e a stamina cheias no começo. Acaba por KO, por queda fora, ou pelo tempo (`partida.md`) | s no design, ticks no código | `round`, `round_since` |
| KO | A vida chegou a zero: o round acaba, com o hitstop de 12 ticks e 2 s de fim de round (`partida.md`, "A transição entre rounds") | — | `ko_tick` |
| Tempo esgotado | O round acabou com os dois vivos: vence quem tem mais vida; vida igual, quem acertou primeiro; ninguém acertou, round sem ponto (`partida.md`) | — | `time_out` |
| Round sem ponto | O round que ninguém ganha: vida igual sem golpe, ou os dois mortos no mesmo tick (o Double KO) (`partida.md`) | — | — |
| Contagem | Os 3 s antes de cada round, com as teclas travadas e a câmera livre (`partida.md`) | s | `countdown` |
| Plano de morte | A altura 5 m abaixo do chão mais baixo do mapa: quem passa dela morre. No duelo, perde o round; no percurso, volta ao último checkpoint. Regra do núcleo com teletransporte, igual no rollback (`partida.md`, "O plano de morte"; Q-48; DEC-0049) | m | `death_plane_y` |
| Ring-out | Morrer caindo fora da arena num duelo. É como o For Honor e o Smash tratam a queda (`partida.md`; F-173 §2) | — | — |
| Percurso cronometrado | O modo de treino: a partida, seis checkpoints em ordem e a chegada, com o relógio em ticks e o fantasma da melhor volta (`partida.md`, "O percurso cronometrado"; F-001) | ticks | `time_trial` |
| Checkpoint | Uma esfera de 3 m no percurso, com número. Cruzar é o segmento entre a posição de um tick e a do seguinte tocar a esfera, na ordem (`partida.md`) | m | `checkpoint` |
| Fantasma | A melhor volta do percurso desenhada translúcida e sem colisão: a posição, a rotação e o modo por tick, um rastro de estado, não um replay por inputs (`partida.md`; `testes-e-entrega.md` §4) | — | `ghost` |
| Medalha | Bronze, prata e ouro por tempo no percurso; o ouro nasce do tempo do Arthur (`partida.md`) | s | `medal` |
| Bot de duelo | O primeiro oponente: só produz input e só lê o que o jogador vê; reage com um atraso sorteado por evento e erra numa taxa por nível (`partida.md`, "O bot que luta"; F-029) | — | `DuelBot` |
| Nível do bot | A reação média e a taxa de erro do bot: 450 ms e 30 % no nível 1, 330 e 15 % no 2, 260 e 5 % no 3, com o mínimo de 180 ms (`partida.md`) | ms | `bot_level` |
| Atraso de percepção | O tempo entre um golpe entrar na preparação e o bot "enxergá-lo", sorteado uma vez por evento. É só isso que o faz parecer gente (`partida.md`; F-173 §3) | ms no design, ticks no código | `perception_delay` |
| Árvore de comportamento | A decisão do bot como uma árvore de seletores, sequências, condições e ações, lida a cada tick e devolvendo o input seguinte. Em GDScript puro, sem addon; a memória do bot é dado plano (`partida.md`) | — | `BehaviorTree` |

## Movimento

| Termo | O que é | Unidade | No código |
|---|---|---|---|
| Corrida na parede | Correr pela parede por um tempo limitado | s | `wall_run` |
| Dash | Arrancada curta de 4 m em 200 ms, só no chão. É também a esquiva do combate, invulnerável dos ticks 3 a 10 (`movimento.md`, "Dash"; `combate.md`, "A esquiva e o dash"; DEC-0050) | m, ms | `dash` |
| Gancho | Puxa os pés do jogador até um ponto do cenário, de 3 a 25 m do ponto O, pela mira (`movimento.md`, "Gancho") | m | `grapple` |
| Mira | A direção para onde a câmera olha, pelo yaw e pelo pitch, saindo do ponto O. Na tela, um anel que ganha um ponto quando o Q prenderia agora; como a mira do CoD, é o centro da tela, e acompanha o raio quando uma parede empurra a câmera (`movimento.md`, "Gancho"; DEC-0045) | m | `Aim.direction`, `Aim.origin`, `pitch` |
| Ponto O | De onde o raio da mira sai: os pés, mais 1,6 m para cima, mais 0,8 m para a direita do yaw. É a linha do centro da tela na profundidade do corpo, calculada pelo núcleo sem câmera, como um backend que recalcula o preço pela tabela em vez de confiar no front (`movimento.md`, "Gancho"; DEC-0045) | m | `Aim.origin`, `aim_height_m`, `aim_side_m` |
| Ombro da câmera | O quanto a câmera fica ao lado do pivô: 0,8 m à direita, como no Fortnite, para o corpo não cobrir a mira. Com sinal: negativo é o esquerdo (`movimento.md`, "Câmera") | m | `shoulder_m` |
| Paralaxe da mira | A câmera e o ombro olham para o mesmo lado, de lugares diferentes: a mira marca a linha da câmera, e o cabo, que sai do ombro, chega no ponto com um ângulo, grande de perto e nenhum de longe (DEC-0045) | ° | — |
| Segundo raio | O raio do ombro ao ponto que o primeiro raio achou: se bate em algo antes, o ponto está atrás de uma quina e não vale (`movimento.md`, "Gancho", "A quina") | m | `Fighter.aim_ray` |
| Alcance mínimo | A distância do ponto O abaixo da qual a mira não prende: 3 m. Mais perto, é erro, como o céu, e a recarga não conta (`movimento.md`, "Gancho") | m | `grapple_min_range_m` |
| Ponto do gancho | Onde o raio da mira tocou o cenário no tick do disparo. Fica fixo até a soltura (`movimento.md`, "Gancho") | m | `grapple_point` |
| Cabo | O voo do gancho até o ponto, 100 ms, e a linha que liga o ombro ao ponto enquanto o gancho vale. Na tela, uma linha de 3 cm (`visual-e-audio.md`, "O gancho na tela") | ms | `grapple_fired_tick`, `grapple_attach_ms` |
| Puxada | O modo do gancho preso: os pés vão ao ponto a 18 m/s, sem gravidade e sem input, até a soltura (`movimento.md`, "Gancho") | m/s | `Mode.GRAPPLE`, `grapple_pull_speed_mps` |
| Soltura | O fim da puxada: com os pés a 1,5 m do ponto, pela trava ou pelo pulo. Conserva a velocidade, e a recarga conta dela (`movimento.md`, "Gancho") | m | `grapple_end_tick`, `grapple_release_distance_m` |
| Escorregar da cabeça | O que acontece com quem cai sobre a cabeça de outro lutador: a cabeça conta como ar, e ele escorrega para fora a 3 m/s, em uns 0,2 s. Como no CoD; no CS, ficar na cabeça do colega é o "boost" (`movimento.md`, "O corpo"; Q-16) | m/s | `slide_off_dir`, `head_slide_speed_mps`, `head_landing_tick` |
| Em pé e no chão | Duas perguntas diferentes. No chão (`on_floor`) é o veredito do motor: encostado numa superfície de até 45°. Em pé (`stands`) é a regra: no chão e não numa cabeça. Como `user.exists` e `user.canLogin` no TypeScript (`movimento.md`, "O corpo") | — | `FighterState.on_floor`, `Movement.stands` |
| Plataforma móvel | O que o motor faz com um corpo em pé sobre outro que se mexe: leva junto e, na saída, passa a velocidade dele. Os lutadores só tratam o cenário como plataforma (F-152) | — | `platform_floor_layers`, `platform_on_leave` |
| Boneco | O segundo lutador do Sozinho, parado no `SpawnB`, para julgar sozinho uma regra de dois corpos. Desliga com `--dummy=off` | — | `--dummy` |
| Borda da arena | As quatro paredes de 50 m que fecham o chão de 80 × 80 m, altas o bastante para um gancho não passar por cima (`movimento.md`, "Métricas de nível") | m | `BordaNorte`, `BordaSul`, `BordaLeste`, `BordaOeste` |
| Tampa da arena | A placa invisível de 82 × 1 × 82 m sobre a arena, com a face de baixo a 50 m, no topo da borda: a cabeça bate nela antes de os pés chegarem à quina, e ninguém sai por cima. Fica numa camada de física só dela, que só o corpo do lutador enxerga; a mira, o gancho, as sondas e a câmera passam por ela. Como a barreira invisível de um mapa do CoD, que para o jogador e não para o tiro (`movimento.md`, "Métricas de nível"; DEC-0049; F-170) | m | `Tampa`, `PhysicsLayers.BOUNDS` |
| Camada de física | O bit que diz com quem um corpo colide: um corpo está em camadas (`collision_layer`) e enxerga camadas (`collision_mask`), e um raio só acha o que está na máscara dele. O cenário fica na `WORLD`, os lutadores na `FIGHTERS` e a tampa da arena na `BOUNDS` (`common/physics_layers.gd`; DEC-0049 §2) | bit | `PhysicsLayers` |
| Contraste de valor | O claro contra o escuro, que faz uma forma ser lida, mais do que a cor. No LoL, o mapa é apagado para os campeões e as magias saltarem; aqui, o cenário fica em tons médios e os corpos se destacam (F-158; `visual-e-audio.md`, "A cara da arena") | — | as cores dos materiais |
| Tonemapping | A curva que comprime as luzes fortes antes da tela, como o filtro de uma câmera que não deixa o branco estourar. A arena usa o Filmic (`visual-e-audio.md`, "A cara da arena") | — | `Environment.tonemap_mode` |
| Luz do céu | A luz ambiente que o céu procedural pinta: num dia claro, ela deixa as sombras azuis (`visual-e-audio.md`, "A cara da arena") | — | `AMBIENT_SOURCE_SKY` |
| Tela de opções | A tela do Esc, por cima do jogo: as teclas, a sensibilidade do mouse e a escala da interface, salvas no PC. O jogo não pausa, e o lutador fica parado enquanto ela está aberta (`visual-e-audio.md`, "A tela de opções"; F-161) | — | `OptionsScreen`, `OptionsStore`, `user://options.cfg` |
| Rótulo da tecla | A letra que o teclado ativo imprime na posição física de uma tecla: o lugar do W mostra "Z" num teclado francês. O jogo guarda a posição, e a tela mostra o rótulo (DEC-0031 §8) | — | `keyboard_get_label_from_physical` |
| Escala da interface | Um número que multiplica toda a interface, de 0,8 a 1,5, como o zoom do navegador; a arena não muda (DEC-0031 §8) | — | `content_scale_factor` |
| Trava do gancho | A soltura de quem bateu: a partir do segundo tick da puxada, a velocidade rumo ao ponto abaixo de 9 m/s, a metade da puxada (`movimento.md`, "Gancho") | % | `grapple_block_pct` |
| No chão | Superestado do modo: o lutador apoiado no chão, parado, correndo ou no dash (`movimento.md`). É onde a defesa vale | — | `is_grounded(mode)` |
| No ar | Superestado do modo: pulo, queda e gancho; ninguém se defende, e só o leve ataca, descendo em 45°. A corrida na parede conta como ar no combate, e nela nem o leve sai: as mãos estão na parede (`combate.md`, "A matriz de posição"; Q-14; DEC-0050) | — | `is_airborne(mode)` |
| Manobra | O verbo de uma acrobacia como entidade do núcleo: deslocamento, tempo, custo e o que dá para fazer durante ela. É o back-end; a animação só mostra (F-013 §1) | m, ms | `maneuver` |
| Animação | A apresentação de uma manobra ou de um golpe, no nó. Mostra e nunca decide (DEC-0004) | — | `animation` |
| Transição | Uma animação deslizando para a próxima sem encurtar nenhuma das duas (blend). É só visual | ms | `blend` |
| Cápsula | O corpo de colisão do personagem: 1,8 m de altura e 0,35 m de raio no v0 | m | `capsule` |
| Viseira | A faixa escura na frente da cápsula. Mostra para onde o lutador olha, e o corpo olha para onde a câmera olha (`movimento.md`, princípios; F-090) | — | nó `Visor` |
| Pulo duplo | O segundo pulo no ar, um por voo, renovado no chão ou ao começar uma corrida em outra parede; a volta na mesma parede não o renova (DEC-0047 §2) | m | `double_jump` |
| Pulo da parede | O pulo que sai da corrida na parede, jogando o jogador para fora dela | m, m/s | `wall_jump` |
| Normal da parede | A direção para fora da face que o lutador toca, deitada no plano horizontal: diz de que lado a parede está e para onde o pulo da parede empurra. Como a seta que sai de uma parede num mapa (DEC-0042) | vetor unitário | `wall_normal` |
| Velocidade ao longo da parede | A parte da velocidade horizontal que corre no plano da parede, sem a parte para dentro ou para fora dela; o produto escalar com a normal separa as duas. De frente para a parede, é quase zero (`movimento.md`, "Corrida na parede") | m/s | `_along_wall` |
| Inclinação mínima da parede | O quanto uma face precisa estar em pé para ser parede: 80°, ou seja, `abs(normal.y)` de no máximo cos 80° (0,1736). Abaixo disso, é rampa ou chão (`movimento.md`, "Corrida na parede") | ° | `wall_min_incline_deg`, `wall_max_normal_y` |
| Velocidade mínima para entrar | A velocidade ao longo da parede que começa uma corrida: 4 m/s. Abaixo dela, a corrida também trava, como quando um obstáculo para o corpo (`movimento.md`, "Corrida na parede") | m/s | `wall_entry_speed_mps` |
| Teto de velocidade | A maior velocidade de uma corrida na parede: 12 m/s. Quem entra mais rápido corre a 12; quem entra entre 8 e 12 mantém a sua (`movimento.md`, "Corrida na parede") | m/s | `wall_max_speed_mps` |
| Mesma parede | O mesmo colisor, pelo caminho do nó, com a normal a até 10°, inclusive (DEC-0042 §3). Ela aceita nova corrida só no voo de um pulo da parede, e essa corrida não devolve o pulo duplo; depois de uma corrida que acaba pelo tempo, pela trava, pelo gancho ou pelo contato, ela recusa até o lutador tocar o chão ou outra parede (DEC-0047; DEC-0048) | ° | `wall_id`, `wall_same_face_deg` |
| Fake na parede | Sair da parede com o pulo da parede como quem vai para outra, desistir e voltar para a mesma com o pulo duplo, numa corrida nova. Como a finta de um drible: o corpo diz que vai, e volta. A corrida da volta não devolve o pulo duplo, por isso o fake sai uma vez e não vira escada: a segunda volta não acha pulo duplo. A volta pede a diagonal, frente mais o lado da parede, segurada até encostar: reto para a parede, a velocidade ao longo dela cai abaixo dos 4 m/s da entrada e a corrida não sai (F-169 §3) (`movimento.md`, "Mesma parede"; DEC-0047; DEC-0048; F-166 §3; F-167 §2) | — | `_enter_wall` |
| Emenda | Onde dois colisores do mesmo plano se encontram numa parede. A corrida passa por ela sem recomeçar: o cronômetro segue, o pulo duplo não renova, e o `wall_id` vira o do bloco novo (F-129) | — | — |
| Sonda da parede | A pergunta do nó ao motor durante a corrida: "se eu me movesse 5 cm para dentro da parede, bateria?", sem mover nada. Correndo paralelo, o movimento quase nunca colide, e é ela que segura o contato (DEC-0042 §1; `rede.md` §4) | m | `WALL_PROBE_DISTANCE`, `move_and_collide` com `test_only` |
| Volta no pulo da parede | No tick do pulo da parede, a tecla com alguma parte ao longo da parede contra o sentido da corrida troca o sinal da velocidade ao longo, com a mesma rapidez; o empurrão para fora e a altura não mudam. Só conta a tecla do tick em que o pulo sai, também no pulo guardado; depois, o voo segue comprometido. Num corredor, ir e voltar vira um elevador, e o mapa o limita (`movimento.md`, "A volta no pulo da parede"; F-135) | — | `_points_back` |
| Escada em Z | Subir alternando duas paredes que formam um par, com o pulo da parede e a volta: um corredor estreito, ou um canto da borda. Cada entrada renova o pulo duplo, e o limite é a altura das paredes, onde o raio acima da cabeça deixa de achar a face. No canto da borda, o pulo duplo ou o gancho lá em cima passavam dos 50 m; a tampa da arena os para com os pés em 48,2 m (`movimento.md`, "Corredor estreito" e "A borda"; F-135; F-167; DEC-0049) | m por pulo | — |
| Raio acima da cabeça | A pergunta do nó ao motor, a 2,1 m dos pés, 30 cm acima da cabeça: "tem uma face no mesmo plano à minha frente, a até o raio mais 5 cm do eixo?". Sem ela, a parede não passa da cabeça: não aceita a corrida, e na corrida o raio passando do topo termina como na borda. Uma pilha de blocos no mesmo plano conta. Só lê o espaço da física e não move nada, por isso sai igual no tick refeito (`movimento.md`, "A parede passa da cabeça"; `rede.md` §4) | m | `covers_body`, `wall_clear_above_head_m`, `wall_ray_height` |
| Inclinação na parede | Na corrida, a malha da cápsula e a viseira inclinam 15° para longe da parede, com o pivô nos pés, entrando e saindo em 100 ms. Só na tela, quadro a quadro: nunca entra no estado, e o rollback, o replay e a SyncTest não a veem (`movimento.md`, "O que se vê na parede"; DEC-0031 §6) | °, ms | `Fighter.lean`, `wall_lean_deg`, `wall_lean_ms` |
| Controle no ar | Quanto o jogador muda a direção no ar, em % da aceleração do chão | % | `air_control` |
| Coyote time | O tempo em que ainda dá para pular depois de sair da beirada. O nome vem do Coiote do Papa-Léguas, que corre para fora do penhasco e só cai quando olha para baixo | ms no design, ticks no código | `coyote_time` |
| Pulo atrasado | O pulo de coyote dado no fim da janela. A corrida antes dele ganha distância, e ele sobe um degrau de 1 m a 4 m de distância que o pulo na beirada não alcança (`movimento.md`, métricas de nível; F-086) | ticks | — |
| Snap do chão | O puxão do motor que, depois de mover, cola o corpo num chão que desce. Cobre a descida da rampa de 45° a 7 m/s: 0,121 m por tick a 60 | m | `floor_snap_length` |
| Conservação de velocidade | A velocidade que passa de uma manobra para a outra | m/s | `momentum` |
| Recarga | O tempo até uma manobra poder ser usada de novo | ms no design, ticks no código | `cooldown` |
| Voo | Do momento em que o lutador sai do chão até tocar o chão de novo; começar uma corrida na parede abre um voo novo para o pulo duplo | — | `jumps_used`, `double_jump_tick` |
| Custo | Quanto de stamina uma manobra gasta ao começar | pontos | `double_jump_cost`, `dash_cost` |
| Espera para recuperar | O tempo sem gastar antes de a stamina voltar a subir | ms no design, ticks no código | `stamina_wait_ms` |
| Recuperação | Quantos pontos por segundo a stamina volta depois da espera | pontos/s | `stamina_regen_per_s` |
| Stamina no último gasto | O valor da barra logo depois do último gasto; com o carimbo do gasto, a barra se calcula pelo tick, sem contador | pontos | `stamina_at_spend`, `stamina_spent_tick` |
| Vaga do buffer | O único lugar onde um comando apertado antes da hora espera; o último aperto ocupa a vaga (DEC-0039) | ticks | `buffered_command`, `buffered_tick` |

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
| Replay por inputs | A partida guardada como o input de cada tick e tocada de novo no servidor. Só reproduz na mesma build: a mesma tecla com outra regra dá outra partida (DEC-0011; DEC-0027) | — | `replay/` |
| Gravador de replay | Quem escreve o arquivo de replay enquanto se joga no Sozinho: o cabeçalho ao começar e, a cada tick, o input aplicado e a impressão do estado. Salva a cada segundo e guarda os 20 mais novos em `user://replays/` (F-112 §2; TASK-10.3) | — | `ReplayRecorder` |
| Arquivo de replay | O texto que guarda uma sessão: um cabeçalho que diz qual jogo gravou, com a configuração inteira, e uma linha por tick e lutador com o input. Os floats vão em 16 dígitos hexadecimais, os bits exatos (`testes-e-entrega.md` §4). Eram uns 71 bytes por tick e lutador na TASK-10.3; o `dash`, o `pitch` e o `grapple` levaram a uns 93 (TASK-10.6) | ~93 bytes por tick e lutador | `ReplayFile`, `.replay` |
| Colunas declaradas | A lista de nome e tipo das colunas, no cabeçalho do arquivo de replay, tirada do `TickInput` por reflexão. O leitor acha cada coluna pelo nome, e um campo novo do input entra no arquivo sozinho | — | `columns` |
| Tocador de replay | Quem roda a partida de novo a partir do arquivo: sem tela, pela `Match` de verdade, laço a laço, com o relógio no primeiro tick gravado; ou com janela, no relógio de verdade (`--watch`) | ticks | `tools/replay.sh`, `ReplayWatch` |
| Rastro de estado | Uma linha por tick e lutador com o estado inteiro depois do tick, os ticks e os carimbos contados a partir do primeiro tick gravado. Dois rastros iguais byte a byte provam que as duas corridas calcularam o mesmo | — | `StateTrace` |
| Impressão do estado | 8 dígitos do sha256 de uma linha do rastro de estado, gravados a cada tick ao vivo na coluna `check`: o tocador diz o primeiro tick em que a refeita se separa do que o jogo calculou | — | `check` |
| Impressão das regras | O sha256 dos scripts que movem o corpo mais a fixação do netfox, lido dos arquivos quando o jogo roda do código-fonte; vazio na build exportada, onde o commit diz qual é. Outra impressão é outra build: o tocador recusa sem `--force` | — | `rules` |
| Impressão da arena | O sha256 das caixas que o corpo colide e dos pontos de nascimento da arena. Outra impressão é outra arena: o tocador recusa sem `--force` | — | `arena_sha256` |
| Referência | Um percurso fixo de bot, com o rastro do caminho guardado; o teste refaz e compara, como o snapshot do Jest. Reprovou sem uma mudança de movimento de propósito? Investiga. Mudou de propósito? Regrava, e o commit diz por quê (golden master; DEC-0027; F-094) | ticks | `test/reference/`, `tools/record_reference.sh` |
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
| Teste de fumaça | A prova mais curta de que uma build funciona: o servidor exportado sobe, mostra o carimbo e fecha com 0. Como ligar um aparelho novo para ver se não sai fumaça | s | `tools/smoke_test_server.sh` |
| Imagem do servidor | O servidor exportado empacotado com um Linux pequeno, numa imagem Docker que roda igual em qualquer máquina. O CI a constrói e testa em todo push, e não a guarda (DEC-0032) | MB | `Dockerfile` |
| Ensaio | Rodar um passo de publicação conferindo tudo, mas sem publicar (dry run). A release ensaia em todo PR | — | `--dry-run` |
| 1% piores | O fps dos quadros mais lentos: o 99º percentil do tempo de quadro. A média esconde o engasgo; os 1% piores mostram (F-056 §5) | fps | `one_percent_low_fps` |
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
| Theme | A folha de estilo da interface do Godot: os tipos de tema são os seletores, os itens são as propriedades, as variações são as classes e o override local é o style inline (F-051 §3.1). O jogo tem um só, o lugar das fontes, dos tamanhos e das cores da tela (DEC-0031 §8; TASK-10.2) | px na base de 1080p | `Theme`, `ui/theme/game_theme.tres` |
| HUD | O que a tela desenha por cima do jogo para quem joga: hoje a barra de stamina, o número e o modo. Lê o estado exibido a cada quadro e nunca conta o tempo; só existe com tela, e repete com forma o que a cor diz (F-051 §3.4; DEC-0031 §2; TASK-10.2) | px na base de 1080p | `Hud` |
| Chave de tradução | O ID de um texto da tela, como `HUD_MODE_AIR`: o código mostra a chave, e o arquivo de cada idioma dá a frase. Como o i18n de um app web (DEC-0031 §8) | — | `GameText`, `ui/translations/*.po` |
| Bus de som | Um canal de mixagem com volume e efeitos próprios, como um canal de uma mesa de som. O bus "leitura" abaixa os outros para o aviso do golpe nunca ser mascarado (F-051 §5.2; F-053 §4) | dB | `AudioServer` |
| Redistribuir | Passar adiante uma cópia do arquivo. Um repositório público redistribui tudo o que tem dentro, para cada pessoa que clona; por isso só entra asset cuja licença deixa redistribuir, pago ou grátis (F-058) | — | — |
| Projeto aberto | Código público com uma licença que deixa outros usarem, mudarem e mandarem PR. O mantenedor decide o que entra no merge, como no próprio Godot (F-058) | — | — |
| Orçamento de vértices | Quantos vértices um lutador pode ter no detalhe máximo para 16 lutadores caberem no piso de 60 fps. O valor v0 é 10 mil, com a arma, e LOD a distância (DEC-0030 §6; F-056 §6) | vértices | — |
| Marca do ativo | O trecho de um clipe em que o golpe pega, marcado à mão. O clipe de biblioteca não traz a marca; no `Sword_Regular_A`, ela fica de 46% a 69% do clipe (F-056 §4) | % do clipe | — |
| Sinal da manobra | O efeito que a tela mostra uma vez quando uma manobra aparece no estado exibido: o rastro do dash e a baforada do pulo duplo. Toca pela chave do evento (lutador, tipo, carimbo), nunca de novo na re-simulação, e só desenha com tela; o som espera um pacote com licença (DEC-0031 §6; DEC-0029; TASK-10.4) | — | `ManeuverCues` |
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
