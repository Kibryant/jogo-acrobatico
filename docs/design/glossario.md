---
revisado_em: 2026-10-04
fontes: [F-001, F-002, F-005, F-007, F-012, F-013, F-020, F-021, F-025, F-026, F-028, F-030]
---

# Glossário

A linguagem ubíqua do jogo (DEC-0004, regra 5): o mesmo termo na conversa, no documento, na task e no código. A coluna "No código" traz o nome em inglês (DEC-0008). Termo novo entra aqui na task que o cria.

## Simulação e rede

| Termo | O que é | Unidade | No código |
|---|---|---|---|
| Lutador | O personagem na simulação, controlado por um jogador ou por um bot. No LoL, é o campeão (DEC-0022) | — | `Fighter` |
| Jogador | A pessoa por trás do lutador; na rede, um peer. No LoL, é o invocador (DEC-0022) | — | `peer_id` |
| Tick | Uma rodada de atualização do jogo, em ritmo fixo: lê o input, aplica as regras e anota a nova situação. O "servidor de 128 ticks" do Valorant faz 128 por segundo | tick | `tick` |
| Ticks por segundo | Quantos ticks a simulação roda por segundo: 30 ou 60 (Q-01). A 30, um tick a cada 33 ms; a 60, a cada 16,7 ms. O Arthur escolheu 60, e a DEC sai no fim do Desenho 3 (F-030) | tick/s | `tickrate` |
| Frame | Um desenho da tela. Varia com o PC (FPS); o tick, não. O frame desenha; o tick decide | frame/s | `frame` |
| Estado | Retrato da simulação num tick, feito de valores planos (número, vetor, texto curto e ID), nunca referência a outro objeto. Fica em quatro caixas: corpo, regras, input e configuração (DEC-0022) | — | `state` |
| Estado do lutador | A caixa de regras do lutador: modo, carimbos e pulos usados. O netfox grava campo a campo, por valor | — | `FighterState` |
| Modo | Em que situação o lutador está: no chão ou no ar e, na fase 1, na parede, no dash ou no gancho. Um por vez, com o tick em que começou | — | `mode`, `mode_since` |
| Ação | O segundo modo, paralelo ao do movimento: o que o lutador faz com as mãos, como preparar um golpe ou bloquear. Fase 2 | — | `action`, `action_since` |
| Carimbo de tick | O tick em que algo aconteceu, guardado no estado no lugar de uma contagem regressiva, como o "flash 12:30" no chat do LoL | tick | `*_tick`, como `jump_pressed_tick` |
| Sanduíche do tick | O tick do lutador em três fatias: o núcleo decide, o motor move e colide, o núcleo confere | — | `before_move`, `move_and_slide`, `after_move` |
| Plano do movimento | O que a primeira fatia do sanduíche devolve: o estado novo e a velocidade que o núcleo pede ao motor | — | `MovePlan` |
| Fatos do movimento | O que o motor devolve depois de mover: se terminou no chão, a velocidade depois da colisão e, na fase 1, a parede | — | `MoveFacts` |
| Configuração | Os números de design convertidos na carga para ticks e para a física do tick. Imutável e fora do estado | — | `MovementConfig` |
| Input | O que o dono do lutador, jogador ou bot, apertou num tick: a direção, para onde olha e os comandos de um toque. Mora no nó `Input`, com o script `FighterInput` | — | `input`, nó `Input` (`FighterInput`) |
| Previsão | O cliente aplica o próprio input na hora, sem esperar o servidor | — | `prediction` |
| Rollback | Voltar ao estado confirmado e re-simular os ticks seguintes | — | `rollback` |
| Tick novo | Tick simulado pela primeira vez; só nele tocam som e efeito | — | `is_fresh` |
| Interpolação | Mostrar os outros jogadores suavizados entre dois estados recebidos | — | `interpolation` |
| Compensação de lag | O servidor volta no tempo para julgar um acerto do ponto de vista de quem atacou | ms | `lag_compensation` |
| Servidor autoritativo | O servidor decide o que aconteceu; o cliente só manda input | — | `server` |
| Ping | O tempo de um pacote ir até o servidor e voltar, o número no canto da tela do LoL. A ida é a metade | ms | `rtt` |
| Atraso de ponta a ponta | Do aperto de um jogador até o estado do lutador dele mudar na tela do outro: as duas idas mais as esperas de tick. A 30 ticks e ping 100, uns 140 ms (F-026) | ms | — |
| Relógio do servidor | O jeito que o netfox julga sozinho: cada input vale no tick em que foi apertado, no relógio comum. Quem defende paga o atraso de ponta a ponta (F-028) | — | — |
| Estado escondido | Algo que a regra ou o motor usa e o rollback não restaura, e por isso o tick refeito sai diferente do original. Exemplo: o "estava no chão" do `move_and_slide()` (F-025) | — | — |
| SyncTest | O teste que força rollbacks e compara cada tick refeito com o original, como no GGPO. Acusa estado escondido (F-025; DEC-0004, regra 4) | — | — |
| Ticks refeitos | Os ticks que o rollback simula de novo, por segundo. Crescem com o ping e com o quadrado do tickrate (F-026) | tick/s | `rollback_ticks` |
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
| Vantagem | Depois de uma troca, quem volta a agir primeiro, e com quantos ms de folga | ms no design, ticks no código | `advantage` |
| Tranco | O tempo sem agir de quem leva um golpe (hitstun) ou o bloqueia (blockstun). Ainda sem número (Q-10) | ms no design, ticks no código | `hitstun`, `blockstun` |
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
| Pulo duplo | O segundo pulo no ar, um por voo, renovado no chão ou ao começar uma corrida na parede | m | `double_jump` |
| Pulo da parede | O pulo que sai da corrida na parede, jogando o jogador para fora dela | m, m/s | `wall_jump` |
| Controle no ar | Quanto o jogador muda a direção no ar, em % da aceleração do chão | % | `air_control` |
| Coyote time | O tempo em que ainda dá para pular depois de sair da beirada | ms no design, ticks no código | `coyote_time` |
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
