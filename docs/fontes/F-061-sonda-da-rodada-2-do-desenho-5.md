---
id: F-061
titulo: Sonda da rodada 2 do Desenho 5 — o parry de brinquedo com os tokens de leitura a 60 ticks, o som pela chave do evento, o julgamento na tela de quem defende e o filtro de daltonismo (sessão 9, noite de 07 para 08/10/2026)
recebido_em: 2026-10-08
como: Medido pelo Claude na sessão 9, neste PC, fora do repositório, em `../netfox-sonda/sonda` (o projeto da sonda do Desenho 3, estendido). Os números vêm das linhas que a sonda imprime (`SUMMARY`, `TALLY`, `VERDICT`, `CUE`, `ATTACK_SEEN`, `METRIC`), lidas pelo `analyze_tokens.py` e por consultas diretas aos logs em `runs/tokens/`. As capturas de tela estão em `runs/tokens/shots/f0` a `f3`.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: rodada 2 da TASK-7, critério 5. O parry de brinquedo do Desenho 3 (F-027) ganhou os quatro golpes que o defensor precisa ler, as três defesas, os tokens de leitura (cor, pose e som por estado, como dado), um filtro de daltonismo de tela cheia, um bus de som com prioridade e a versão de brinquedo do julgamento na tela de quem defende (DEC-0026 §3). O que o Arthur leu e disse está na F-062. O que está marcado como leitura do agente é inferência, não medição.

## §1 — O que a sonda é

- **O cenário:** a arena de blocos do Desenho 3, 60 ticks (DEC-0024), um servidor dedicado e um bot atacante sem tela, e a janela de quem defende, ligados pelo `NetworkSimulator` do netfox com 50 ms de latência simulada em cada sentido (`play.sh 60 100`). A câmera é lateral, a 4,6 m, como num jogo de luta 2D.
- **Os quatro golpes do bot**, a cada 3 s, os quatro primeiros em ordem fixa e depois sorteados com semente: o leve (300 / 100 / 250 ms), o carregado (preparação sorteada entre 500 e 900 ms, 120 de ativo, 450 de recuperação), a quebra de guarda (350 / 100 / 400) e a finta, que começa como carregado e corta entre 300 e 450 ms, seguida de um leve (`combate.md`; DEC-0016).
- **As três defesas:** o parry (F, janela de 80 ms antes do contato, 200 ms de recuperação, 400 se errar), o bloqueio (botão direito segurado, 100 ms para subir) e a esquiva (Shift, 60 ms de preparação e 250 ms invulnerável). Números de brinquedo, não de desenho: o alcance de 2,5 m (F-027), o passo da esquiva de 1,5 m e o atordoamento de 350 ms (a Q-10 não tem número).
- **Os tokens, como dado** (`probe_tokens.gd`, um `Resource` com uma tabela estado → cor, pose, som, texto e forma do HUD). O leve não tem cor. O carregado tem a lâmina e uma aura em azul celeste `#56B4E9` desde o tick 0, com a espada acima da cabeça e um som longo subindo. A quebra não tem cor: a espada baixa, a mão vem à frente, o contorno pulsa e um pisão soa. A finta corta com um estalo seco e a pose volta. O ativo é a lâmina e um rastro em vermelhão `#D55E00`. O parry é a lâmina e a aura em amarelo `#F0E442`; o acerto dá o "clang", o som mais forte, com faíscas e um flash nos dois. O time é o contorno, branco para quem joga e preto para o oponente, sem cor (F-053 §3.6 e §6).
- **A pose é uma função do estado** (DEC-0022 §3): a cada quadro, a espada de blocos é posta pela interpolação entre poses-chave a partir de (ação, tipo, tick de início, tick atual); nenhum timer, nenhuma máquina de estados de animação. As poses vivem no plano vertical que a câmera lateral vê inteiro: uma lâmina ao longo do próprio eixo x do corpo aparece de ponta, como um ponto, e foi assim na primeira versão.
- **O HUD como redundância** (F-053 §5): uma faixa embaixo com a forma e a cor do token do oponente e o texto, e o estado de quem defende; o veredito de cada lance e a contagem de leitura certa por golpe. Um `Theme` só, feito em código, com a base de 1920 × 1080 e `canvas_items` + `expand` no `project.godot` da sonda (F-051 §3.3); a escala da interface por `content_scale_factor` nas teclas mais e menos; as teclas por posição física, com o rótulo do teclado ativo por `keyboard_get_label_from_physical` (F-051 §4.3); as cadeias por ID com pt-BR e en, trocadas pela tecla L (F-051 §3.5).
- **O som:** onze clipes sintetizados ao abrir, sem asset nem licença; um `AudioStreamPlayer` por clipe no bus "leitura"; um drone no bus "ambiente" com um `AudioEffectCompressor` em sidechain do "leitura" (F-051 §5.2; F-053 §4). O HUD mostra o pico dos dois buses.
- **O filtro de daltonismo:** um `ColorRect` de tela cheia numa `CanvasLayer` acima de tudo, com `hint_screen_texture` e as matrizes de Machado, Oliveira e Fernandes (2009), as mesmas da vitrine (F-051 §4.5). Teclas 1 a 4: visão comum, protanopia, deuteranopia, tritanopia. Uma régua de amostras no canto, com os tokens e o par vermelho × verde, mostra o filtro agindo.
- **O julgamento na tela de quem defende**, versão de brinquedo da DEC-0026 §3: cada input leva o `view_lag`, a idade em ticks do último estado do oponente na tela; quem ataca grava no próprio estado a marca do contato (tick, id e tipo) quando a lâmina fica ativa e o outro está ao alcance; o tick de quem defende resolve o contato quando ele aparece na tela dele, traduzindo o aperto do parry, a subida da guarda e os quadros da esquiva pelo `view_lag` que cada um levava, com o teto de 12 ticks. Quem ataca lê o veredito no estado do outro e aplica a própria consequência.

## §2 — O som toca uma vez: a chave do evento, e não só o `is_fresh`

A DEC-0004 (regra 2) diz que som e efeito tocam só no tick novo (`is_fresh`), nunca na re-simulação. A sonda mostrou que a frase cobre um caso só.

- **O oponente na tela não tem tick novo.** Sem previsão (DEC-0026 §2), o netfox não simula no cliente o nó cujo input ele não tem: o `_rollback_tick` dele nunca roda ali. O que a tela mostra é o último estado que chegou, reaplicado depois de cada rollback (`_restore_latest`).
- **O veredito do contato nasce sempre num tick refeito.** A marca do contato chega ~9 ticks depois de o golpe ficar ativo. Quando chega, o cliente refaz os ticks desde então, e o tick em que a condição "o contato está na minha tela" vira verdade já tinha sido simulado novo antes, sem a marca. A transição aparece num tick com `is_fresh = false`. Na primeira versão da sonda, por isso, o veredito do carregado e das fintas não tocava nem aparecia no HUD.
- **A regra que cobre os três casos:** cada cue é um evento com uma chave, por exemplo "ativo do ataque 542" ou "parry aberto no tick 582". Depois de cada laço de ticks, a tela compara o estado exibido com o último que apresentou e apresenta cada chave uma vez, seja de nó próprio ou espelhado, seja a transição de um tick novo, de um refeito ou de um estado que veio do servidor. Reaplicar o mesmo estado não cria evento. É a `key` de uma lista no React: o mesmo item, com a mesma chave, não é um item novo.
- **O `is_fresh` continua contado**, para medir o que ele teria feito: dentro do `_rollback_tick`, cada transição soma um no contador ingênuo (toda simulação do tick) e um no contador `is_fresh` quando o tick é novo. Nada toca dali.
- **O atraso de visão vem do próprio estado.** O `get_last_known_state()` do `RollbackSynchronizer` devolveu zero para o oponente no cliente: o histórico regrava o estado espelhado a cada tick, então a idade do "último estado" é sempre zero. O estado passou a carregar o tick em que foi calculado (`sim_tick`), e o `view_lag` é o tick atual menos ele.

Com a chave do evento, os contadores. "Apresentados" é o que tocou; "`is_fresh`" é o que a regra da DEC-0004 tocaria; "ingênuo" é o que uma regra sem `is_fresh` tocaria dentro do `_rollback_tick`; "passadas" é o que tocaria uma regra "toca enquanto o estado for X" a cada laço.

| Corrida | Golpes | Apresentados | `is_fresh` | Ingênuo | Passadas | Ticks refeitos |
|---|---|---|---|---|---|---|
| SyncTest, 1.800 ticks, rollback forçado de 4 ticks a cada tick, os dois lutadores locais | 10 | 42 | 42 | 168 | 394 | 7.177 |
| Cliente de quem defende, ping 120, 36 s, visão comum | 9 | 42 | 18 | 103 | 361 | 14.659 |
| Cliente, protanopia | 12 | 56 | 21 | 101 | 568 | 13.469 |
| Cliente, deuteranopia | 12 | 54 | 24 | 113 | 498 | 13.553 |
| Cliente, tritanopia | 12 | 55 | 18 | 98 | 393 | 12.811 |
| Servidor, as quatro corridas | 13 cada | 57 · 58 · 61 · 58 | 54 · 56 · 59 · 56 | 59 · 75 · 75 · 87 | 0 | 15.220 · 14.555 · 13.926 · 15.253 |

- Na SyncTest, apresentados e `is_fresh` coincidem: nada chega atrasado quando os dois lutadores são locais. A conferência de estado da sonda do Desenho 3 (`SyncProbe`) rodou junto: 10.752 conferências, zero divergência, com o combate inteiro no estado.
- No cliente, o `is_fresh` veria entre um terço e metade dos eventos: faltam todos os do oponente espelhado e os vereditos. No servidor, faltam só os vereditos que nascem refeitos (1 a 3 por corrida).
- O cliente refez de 12 a 15 mil ticks em 36 s, e nenhum evento tocou duas vezes.

## §3 — O bot leitor a ping 120

Um bot defensor que lê o token na própria tela e responde pelo tipo, 200 ± 40 ms depois de o aviso aparecer: guarda alta contra o leve, parry no contato do carregado (ele lê o tamanho da carga no estado, o que uma pessoa não consegue), esquiva contra a quebra; toma a finta por carregado. Quatro corridas de 36 s, uma por simulação de daltonismo, com o `view_lag` entre 7 e 10 ticks.

| Golpe | Lances | Resposta certa | Como |
|---|---|---|---|
| Leve | 12 | 5 (42 %) | 5 bloqueios; 7 levou. Reação de 200 ms mais 100 ms de guarda dá os 300 ms da preparação: a moeda que a F-053 §2.4 previu |
| Carregado | 8 | 8 (100 %) | 8 parries, com o F de 17 a 50 ms antes do contato na tela de quem defende, mediana 50 |
| Quebra de guarda | 16 | 13 (81 %) | 13 esquivas; nas 3 perdidas, o aviso apareceu na tela 14, 15 e 25 ticks depois de começar, em vez dos 8 a 10 de costume, e a esquiva de 200 ms chegou depois do contato |
| Finta | 12 | 12 (100 %) | 12 sem morder: 7 bloqueios do leve que segue, 1 parry, 4 levou |

- O parry do carregado a ping 120 com a regra da DEC-0026: 8 de 8. No Desenho 3, com o relógio do servidor, o mesmo bot de 150 ms não aparava nada a ping 100 (F-028 §3).
- As três quebras perdidas são o jitter da entrega, que o simulador do netfox não tem (rede.md §5): nessa máquina, com três processos, o estado do oponente às vezes chega tarde. Ponto para a Q-09.

## §4 — O filtro e as cores

- Sob deuteranopia e protanopia, o par vermelho × verde da régua vira dois tons de oliva quase iguais. Os tokens continuam separados: o azul celeste do carregado, o vermelhão do ativo (que vira um ocre escuro) e o amarelo do parry se distinguem pelo brilho, não só pelo matiz.
- O roxo-avermelhado "de longe" (`#CC79A7`), que a sonda só mostra na régua, perde a cor sob deuteranopia e fica perto do cinza do leve. A arma de longe não entrou no jogo da sonda; o ponto fica anotado para o arco (F-053 §3.6 avisava do par amarelo e roxo-avermelhado na tritanopia; este é outro par, na deuteranopia).
- O ducking: o fundo de ambiente ficou em −18 dB de pico; durante um cue, caiu de 33 a 39 dB abaixo disso, com o compressor em limiar −16 dB e razão 2,5. É mais do que um jogo quer; serve para ouvir o mecanismo.
- O rótulo das teclas no teclado do Arthur: F, Shift, e a posição do ponto e vírgula do teclado americano se chama ";" aqui. O mecanismo está ligado; num ABNT2, a mesma posição diria Ç.
- A janela: 1920 × 1080, base 1920 × 1080, `canvas_items`. A escala da interface subiu até 1,2 e voltou a 1,0 pelas teclas, e o idioma trocou entre pt-BR e en pela tecla L, nos jogos do Arthur (F-062).

## §5 — O que mudou enquanto a sonda era feita

- O `_shown`, o último estado apresentado, guardava a referência do estado, que o netfox muta no lugar: a comparação nunca via transição. Virou uma cópia.
- Os pontos de spawn por `id % 4` dos peers: dois ids no mesmo slot puseram os lutadores dentro um do outro, e a física os deixou encostados; o bot só sabia se aproximar. O spawn passou a ser por ordem de entrada, e o bot recua quando chega a 1,4 m.
- A câmera a 7 m deixava as cápsulas miúdas, o mesmo tropeço do primeiro parry de brinquedo (F-027 §1; registro da TASK-5). Foi para 4,6 m.
- O bot leitor apertava o parry 3 ticks antes do contato no relógio de quem ataca, sem somar o atraso de visão: 200 ms cedo. Passou a mirar o contato como ele vai aparecer na própria tela.
- O tipo do golpe do veredito ficava no espelho do oponente, que pode chegar depois do próprio estado: um veredito saiu "NENHUM". O tipo passou a ser gravado no estado de quem defende ao resolver.
- Uma corrida da protanopia teve os vereditos atrasados em até 30 ticks e o ping em 150; a repetição saiu limpa. Os números da tabela do §2 são da repetição.

## §6 — Onde está e como rodar

- `../netfox-sonda/sonda/`: `probe_tokens.gd` (a tabela dos tokens), `probe_state.gd`, `probe_input.gd` (a pessoa, o bot atacante e o bot leitor), `probe_fighter.gd` (as regras de brinquedo, as poses e as cues), `probe_audio.gd`, `probe_filter.gd`, `probe_hud.gd`, `main.gd`, `project.godot`.
- `play.sh <ticks> <ping> [filtro 0-3]` abre o jogo para uma pessoa, em tela cheia, com o servidor e o bot sem tela; o log fica em `runs/tokens/play-you-*.out`.
- `check_tokens.sh [synctest|reader|all]` roda a SyncTest e as quatro corridas com o bot leitor, com as capturas em `runs/tokens/shots/f<N>/`.
- `python analyze_tokens.py <logs>` imprime as tabelas de leitura, as margens dos parries, as cues por origem e o ducking.
- Um argumento desconhecido imprime o uso e fecha, pela lição da rodada 1 (F-056 §7).
