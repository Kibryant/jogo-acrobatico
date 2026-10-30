---
revisado_em: 2026-10-28
fontes: [F-001, F-029, F-053, F-166, F-170, F-172, F-173, F-174, F-182]
---

# Partida

Estado atual: o v0 do duelo e dos modos da fase 2, fechado no desenho do duelo (TASK-12, rodada 1; DEC-0036). O formato da partida, o plano de morte e o som são escolhas do Arthur (F-172 §2; DEC-0050); os números são v0 do Claude, para ele julgar jogando (DEC-0017), e estão na vitrine "O desenho do duelo" (DEC-0019). O combate em si, golpe a golpe, está em `combate.md`; o movimento, em `movimento.md`.

## O duelo (Q-29)

Rounds curtos, que preservam o "pensado" do 1v1 (F-001) e dão revanche imediata. É o Duelo do For Honor, a tribo mais próxima: cinco rounds, vence quem ganha três, e no tempo esgotado vence quem tem mais vida (F-173 §2).

| Número ou regra | Valor | Unidade | Nota |
|---|---|---|---|
| Vida do lutador | 100 | pontos | Para ler em porcentagem: 12 de dano são 12% da barra. A mesma proporção do For Honor, que tem 120 a 140 de vida, com o leve de 13 a 15 e o pesado de 26 a 30 (F-173 §2) |
| Golpes para matar | 9 leves, ou 4 carregados, ou 2 carregados e 4 leves | — | O leve tira 12 e o carregado 30 (`combate.md`). O round se decide em uns seis golpes certos |
| Formato | vence quem ganha 3 rounds | — | Melhor de 5. Escolha do Arthur (F-172 §2; DEC-0050) |
| Tempo do round | 90 | s | 5.400 ticks. Entre o Tekken (60 s) e o Street Fighter (99 s), longe dos 5 min do For Honor (F-173 §2). Com 9 leves a uns 650 ms cada, matar leva no mínimo uns 6 s; 90 s sobram para ler e tentar de novo, e são curtos o bastante para fugir com gancho e dash não compensar |
| Tempo esgotado | vence quem tem mais vida | — | A regra do For Honor desde 2017, do Tekken, do Street Fighter e do Smash (F-173 §2). O For Honor só a pôs depois de ver gente fugindo até o relógio zerar; com dash, gancho e parede, fugir é ainda mais fácil aqui, então ela entra desde o v0 |
| Vida igual no tempo esgotado | vence quem acertou primeiro; se ninguém acertou, round sem ponto | — | O terceiro critério do Naraka, sem o sorteio dele (F-173 §2): nada de aleatoriedade sem semente (DEC-0004). Round vazio não premia ninguém |
| Morte dos dois no mesmo tick | round sem ponto | — | O Double KO do Tekken e a regra do Duelo do For Honor (F-173 §2) |
| Cair fora | morte do round; o ponto vai para o outro | — | "O plano de morte", abaixo. Escolha do Arthur (F-172 §2; Q-48; DEC-0050) |
| Limite de rounds | 9; depois, a partida é empate | — | Só para uma partida de empates não ficar sem fim; não deve acontecer |
| Pontos de início | os dois pontos da arena, a 10 m um do outro, de frente | m | `SpawnA` e `SpawnB` de hoje. Os lados trocam a cada round, como o For Honor troca o lugar (F-173 §2) |
| Anti-fuga | fora do v0 | — | Q-50. A regra do tempo esgotado já pune a fuga |

### A transição entre rounds

| Fase | ms | Ticks | O que acontece |
|---|---|---|---|
| O golpe que mata | 200 | 12 | O hitstop do KO, o maior do jogo (`combate.md`, "O hitstop") |
| Fim de round | 2.000 | 120 | A simulação segue, as teclas são ignoradas. Dá tempo de ver o KO e de o som tocar; ninguém bate no corpo |
| Reset | 0 | 0 | Teleporte para os pontos de início, trocando de lado; vida 100, stamina 100, recargas zeradas, modos no chão, como o Naraka faz a cada round (F-173 §2) |
| Contagem | 3.000 | 180 | "3, 2, 1, lutem": as teclas travadas, a câmera livre. Convenção; nenhuma fonte deu o número (F-173 §2) |
| Total entre o KO e a próxima luta | ≈ 5.200 | ≈ 312 | Curto o bastante para manter o ritmo |

### O que se vê

- **O HUD do duelo:** a vida dos dois no topo (a sua à esquerda, a do outro à direita), o placar em marcas entre elas, o relógio do round no centro; a stamina onde já está (`visual-e-audio.md`). O token do golpe do outro repete no HUD, com forma e cor (DEC-0031 §2).
- **A contagem** aparece grande no centro; nos últimos 5 s do round, o relógio cresce e muda de cor, como o Smash (F-173 §2).
- **O fim do round** diz quem venceu e por quê: "KO", "mais vida", "primeiro golpe" ou "sem ponto".

### Por dentro

A partida é o contexto "Partida e round" da arquitetura: uma máquina de estados pequena e pura, no servidor (`visao-geral.md`, "Os contextos"): contagem, luta, fim de round, fim de partida, com o tick em que cada estado começou e o placar. Ela lê a vida dos lutadores e o relógio em ticks, e manda o reset. O tempo do round é em ticks inteiros, carimbo e não contagem (DEC-0022).

## O plano de morte (Q-48)

Uma altura abaixo do chão mais baixo do mapa: quem passa dela morre. É uma regra do núcleo, com teletransporte, então vale igual no rollback (DEC-0049, "Revisitar se"). Escolha do Arthur (F-172 §2; DEC-0050).

| Número ou regra | Valor | Unidade | Nota |
|---|---|---|---|
| A altura | 5 m abaixo do chão mais baixo | m | Pela gravidade de descida de ≈ 29,9 m/s² (`movimento.md`, "Pulo e ar"), 5 m de queda levam ≈ 0,6 s, 35 ticks: curto para ninguém "cair para sempre", longo para não matar quem tropeçou numa borda. O KillZ do Unreal e a blast line do Smash são a mesma ideia (F-173 §2) |
| No duelo | morte do round, o ponto vai para o outro; os dois no mesmo tick, round sem ponto | — | O ring-out do For Honor e do Smash (F-172 §2; DEC-0050). Jogadores do For Honor acham a morte pelo cenário frustrante no duelo (F-173 §2): a arena de duelo v0 não ganha vão, e a regra fica como rede de segurança |
| No percurso cronometrado | volta ao último checkpoint depois de 500 ms (30 ticks), com velocidade zero; o relógio continua | ms | A punição é o tempo perdido, como no Trackmania e no Celeste (F-173 §2 e §3). Os 500 ms dão um respiro para entender o que aconteceu |
| No Sozinho | volta ao ponto de nascimento depois de 500 ms | ms | Sem partida, sem ponto |
| A arena de hoje | não tem vazio: a tampa fecha por cima (DEC-0049) | — | Um teste do núcleo prova a regra com um lutador abaixo da altura; um teste da arena prova que nenhum chão fica abaixo dela |

## O bot que luta (F-029)

O primeiro oponente. Ele só produz input (DEC-0022) e só lê o que o jogador também vê: o modo e a ação do outro, a posição, e o tick em que o golpe começou. O que o faz parecer gente é o atraso de percepção sorteado uma vez por evento, mais uma taxa de erro (F-173 §3). Nenhum nível lê o botão do jogador, nem o que ele vai fazer.

| Nível | Reação média | Desvio | Mínimo | Erro | O que é |
|---|---|---|---|---|---|
| 1 | 450 ms, 27 ticks | 90 ms | 180 ms | 30 % | Uma pessoa distraída |
| 2 | 330 ms, 20 ticks | 60 ms | 180 ms | 15 % | Uma pessoa comum |
| 3 | 260 ms, 16 ticks | 40 ms | 180 ms | 5 % | Uma pessoa boa, dentro dos 213 a 273 ms medidos (F-053 §2.3), perto dos 250 ms do OpenAI Five e dos 230 do bot da F-029 |

- **Quando sorteia:** uma vez por evento, quando o golpe do outro entra na preparação: o bot guarda o tick em que vai reagir. Sorteando a cada tick, ele tenderia ao menor valor (F-173 §3).
- **O erro:** com a taxa do nível, ele ignora o golpe ou escolhe a resposta errada, como uma pessoa sob pressão.
- **O que faz:** chega a 2,5 m, dá a volta, mistura leve, carregado, quebra e finta por pesos; defende o que viu dentro do atraso: bloqueia os leves que leu de antemão, apara o carregado contando o tempo (com erro de ± 30 ms), responde à quebra com o tech, esquiva por palpite. Depois de aparar, castiga com o carregado garantido. Contra o leve, nenhum nível reage de verdade: o nível 3 o bloqueia por palpite, com peso baixo, para não quebrar o triângulo (F-173 §3).
- **Onde fica:** no chão, no v0. O bot que usa a parede e o gancho é outra filha, depois do duelo sentido.
- **Como é feito:** uma árvore de comportamento mínima em GDScript tipado, sem addon (AGENTS.md): seletor, sequência, condição e ação, lida a cada tick no servidor, devolvendo o input seguinte. A memória do bot é dado plano. O sorteio é um hash inteiro de (semente da partida, bot, tick, contador), porque o Godot não promete a mesma sequência do gerador entre versões (F-173 §3): o mesmo bot faz o mesmo no replay.
- **O que mede:** a taxa de parry, de bloqueio e de tech por nível, como na F-029, para comparar com o Arthur e com os amigos.

## O percurso cronometrado

A rampa de aprendizado do estudo: um percurso com fantasma, como o Gauntlet do Titanfall 2 (F-001). Um portão de partida, seis checkpoints em ordem fixa e a chegada, dentro da arena de hoje, pedindo parede, pulo duplo, dash e gancho (F-173 §3).

| Número ou regra | Valor | Unidade | Nota |
|---|---|---|---|
| Checkpoints | 6, em ordem fixa, mais a partida e a chegada | — | O Mirror's Edge usa 4 a 5 por fase (F-173 §3); 6 cobrem as cinco manobras. Cruzar o 4 antes do 3 não conta |
| O volume | esfera de 3 m de diâmetro | m | Um anel visível no mundo, com o número |
| Cruzar | o segmento entre a posição de um tick e a do seguinte toca a esfera | — | Regra do núcleo. Testar só a posição do tick furaria o volume no dash (0,33 m por tick) e no gancho; é o bug do portão do Gauntlet (F-173 §3) |
| O relógio | começa ao cruzar a partida, para ao cruzar a chegada com os seis | ticks | Inteiros, 60 por segundo; a tela mostra em segundos e centésimos |
| Cair | volta ao último checkpoint depois de 500 ms, velocidade zero, relógio correndo | ms | "O plano de morte" |
| Recomeçar | uma tecla, na hora | — | O que dá "só mais uma" é o recomeço instantâneo (F-173 §3) |
| Medalhas | bronze, prata e ouro | — | Só depois de o Arthur correr: o ouro nasce do tempo dele. Nenhum número inventado (DEC-0017) |
| O fantasma | a posição, a rotação e o modo por tick da melhor volta, desenhado translúcido, sem colisão | — | O rastro de estado, e não o replay por inputs: o fantasma por posição sobrevive a um ajuste de número; o por inputs só reproduz na mesma build (F-173 §3; `testes-e-entrega.md` §4). Uns 72 KB por minuto. Guardado em `user://` com a impressão da arena; outra arena, outro fantasma |
| O traçado v0 | partida perto do `SpawnA`; o bloco de 3 m; o corredor; o patamar; a `TorreB`; o `Pilar10m`; a `TorreA`; a chegada no vão das plataformas | — | Rascunho na vitrine; a filha do percurso o fecha com o Arthur correndo |

## Os modos da Main

A `Main` abre hoje em três papéis (DEC-0026 §6): servidor dedicado, cliente e Sozinho. A fase 2 põe dentro do Sozinho a escolha do que jogar: o duelo contra o bot (com o nível), o percurso cronometrado, e a arena livre de hoje com o boneco. Uma tela simples, no Theme (DEC-0031 §8); o detalhe sai na filha da partida.

**A vida sem partida** (TASK-12.1; leitura v0 do Claude, DEC-0017): até a partida da TASK-12.7, todo lutador tem vida 100, que nunca desce de 0, e ela volta a 100 dois segundos, 120 ticks, depois do último golpe que ele levou. É o treino contra o boneco: a barra mostra cada acerto e se refaz sozinha. Na partida, os rounds tomam o lugar dessa regra (`combate.md`, "O leve no tick").

**O boneco que ataca** (TASK-12.2; leitura v0 do Claude, F-182, contexto): até o bot que luta da TASK-12.8, o boneco do Sozinho começa um golpe a cada 3 s, 180 ticks, virado para quem joga, para treinar a guarda e sentir a vez. Ele não anda, não segura a guarda e não reage.

**A mistura do boneco** (TASK-12.3; leitura v0 do Claude, aprovada no plano, F-192): o golpe de número k sai de uma conta fixa sobre o k, um hash de inteiros, sem sorteio e sem semente. De cada 5, 2 são leves, 2 são carregados e 1 é finta, na média; a ordem não se repete de um jeito que dê para decorar, e os quatro primeiros já trazem os três. A finta é um carregado cortado pelo aperto da guarda 24 ticks depois do começo, dentro dos 27 da finta (`combate.md`, "A finta"), e um leve apertado 4 ticks depois, que espera na vaga até os 12 ticks da finta acabarem e sai no fim deles. Como não há semente, o replay refaz a mesma mistura. É o que o critério 8 da TASK-12.3 pede: o Arthur apara contando o azul, morde fintas e anota a taxa de parry, como na F-063.

## O relatório de crash pelo log (DEC-0034)

Quando os amigos testarem, o jogo precisa deixar o log no PC deles, com a pilha de chamadas, e o passo a passo precisa dizer onde ele fica e como mandar. As configurações do Godot e os passos estão em `docs/arquitetura/testes-e-entrega.md` §13, e o passo a passo público nasce na filha do log.

## Fora do v0

- **Anti-fuga** (Q-50): só se o duelo jogável mostrar fuga até o relógio zerar.
- **Crédito do ring-out no 4v4:** para quem acertou por último nos 3 s anteriores, como o environmental kill do Overwatch (F-173 §2). Fase 4.
- **O bot acrobata**, que usa a parede e o gancho.
- **O fantasma de outra pessoa** e o ranking do percurso: fase 4, com as contas (DEC-0034).
- **Fora dos limites por cima:** a tampa fecha (DEC-0049); se um mapa abrir o teto, um aviso de 3 s e a morte, com o cronômetro fixo como o Apex aprendeu a fazer (F-173 §2).

## Em aberto

- **Q-50:** o anti-fuga.
- **Q-51:** a arena do duelo: a mesma de 80 × 80 m, ou uma menor? A recomendação é a mesma no v0 e medir, no duelo contra o bot, quanto tempo de round é perseguição.
