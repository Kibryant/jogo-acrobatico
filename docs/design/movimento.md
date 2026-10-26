---
revisado_em: 2026-10-26
fontes: [F-001, F-012, F-013, F-015, F-084, F-086, F-088, F-100, F-108, F-109, F-121, F-122, F-127, F-128, F-129, F-131, F-132, F-135, F-136, F-140, F-141, F-146, F-147, F-148, F-151, F-152, F-153]
---

# Movimento

Estado atual: o kit v0 fechado no Desenho 1 (TASK-3). O Arthur fechou a primeira tabela (corpo, chão, pulo, perdão e câmera) como v0, para julgar no protótipo (F-015 §1). O resto foi fechado pelo Claude, pela melhor experiência do jogador (DEC-0017). A primeira tabela já foi jogada na parte 1 do esqueleto andante, e o Arthur gostou (TASK-9; F-086 §1). O resto ainda não foi sentido em jogo, e o valor certo sai da fase 1. No código, tudo vira tick na carga, e o arredondamento é testado (DEC-0004, regra 3).

Vitrine visual, em escala e no tempo real: [Kit de movimento v0](https://claude.ai/artifact/DT8QMmuKiBffEjtfUimDWL), privada (DEC-0019). Quando um número daqui mudar, a vitrine é republicada no mesmo link.

## Como os números nasceram

Cada número tem uma origem, e nem todos têm a mesma firmeza; a vitrine mostra a origem número por número. A física não escolhe número: ela deriva gravidade, distâncias e tempos da sensação escolhida.

- **Corpo humano:** a altura e o raio da cápsula; os blocos de 1, 2 e 3 m (bancada, porta e teto).
- **Outros jogos e motores:** a rampa de 45° (padrão do Godot e do Unity), a régua de 5,5 m/s do Overwatch, perdões entre 50 e 200 ms.
- **O estudo (F-001):** 2,5 s de parede, o gancho de 25 m e 6 s, os custos de golpe.
- **Os pilares:** a corrida acima do Overwatch, o prêmio por usar a parede, o compromisso no ar, o dash sem invulnerabilidade.
- **Chutes assumidos, os primeiros a mexer no protótipo:** controle no ar, queda máxima, descida na parede, recarga e custo do dash, ponto em que o gancho solta, espera e recuperação da stamina, sensibilidade.

## Princípios

- **Verbo e animação separados.** A manobra é uma entidade do núcleo, o back-end: deslocamento, tempo, custo e o que dá para fazer durante ela. A animação só mostra (F-013 §1; DEC-0004).
- **O designer regula a sensação, e o código deriva a física.** Altura e tempo do pulo viram gravidade e velocidade de saída; tempo até a velocidade máxima vira aceleração.
- **Uma barra de stamina para tudo** (F-001). Manobra de impulso gasta stamina; manobra de duração tem limite de tempo; o gancho tem recarga.
- **No ar ninguém se defende** (F-001).
- **Câmera em terceira pessoa** (DEC-0013), e o corpo olha para onde a câmera olha (F-015 §1). A referência de sensação do Arthur é a câmera do GunZ (F-015 §1). Copiar mecânica é livre; código, arte e som do GunZ, não (F-001).
- **Espaço para a técnica própria (Q-07):**
  - a velocidade se conserva entre manobras, dentro dos tetos abaixo; no ar, o input não corta o excesso ("Pulo e ar", controle no ar; F-127);
  - começar uma corrida na parede renova o pulo duplo, e pular solta o gancho: as manobras emendam;
  - a mesma regra vale em todo lugar, para o jogador confiar no que descobriu;
  - técnica nasce de manobras desenhadas, nunca de brecha (DEC-0016), e técnica descoberta ganha ferramenta, nunca nerf (F-001).

## O corpo

| Número | Valor | Unidade | Nota |
|---|---|---|---|
| Altura da cápsula | 1,8 | m | Um corpo só no v0 (Q-12) |
| Raio da cápsula | 0,35 | m | Passa folgado por uma porta de 1 m |
| Rampa máxima | 45 | ° | Acima disso não é chão |
| Degrau | nenhum | — | A arena usa rampa |
| A cabeça do outro | não é chão para as regras | — | A Q-16 começa proibida, como no CoD: quem cai sobre a cabeça de outro lutador fica no ar. Sem pulo do chão nem dash, sem renovar o pulo, o pulo duplo nem a última parede, sem coyote e com a gravidade do ar; o pulo duplo guardado e o gancho saem como no ar. O motor segue dizendo chão até 45° no domo, e o contorno D lê essa resposta (DEC-0025 §2; DEC-0037); as regras perguntam outra coisa (`Movement.stands`). De lado, o choque segue como o empurrão da TASK-9. A cabeça não é plataforma: não carrega quem está em cima nem passa a velocidade dela na saída. Escolha do Arthur para o v0, decidida de vez jogando na TASK-10.8 (F-152; Q-16) |
| Escorregar da cabeça | 3,0 | m/s | Para longe do eixo do outro, pela normal do contato achatada no plano; num pouso exato no centro, para as costas de onde o corpo olha. Com raios de 0,35 m, o domo deixa de ser chão além de 45°, a 0,495 m do eixo: do centro, 10 ticks a 60, uns 0,2 s. Leitura v0 do Claude (TASK-10.7; vitrine "A cabeça do outro") |

## Chão

| Número | Valor | Unidade | Nota |
|---|---|---|---|
| Velocidade de corrida | 7 | m/s | A mesma para frente, para o lado e para trás |
| Tempo até a velocidade máxima | 150 | ms | Deriva a aceleração: ≈ 46,7 m/s² |
| Tempo até parar | 100 | ms | Deriva a desaceleração: 70 m/s² |
| Andar devagar | não existe | — | Um modo de guarda pode vir com o combate (fase 2) |

## Pulo e ar

| Número | Valor | Unidade | Nota |
|---|---|---|---|
| Altura do pulo | 1,2 | m | |
| Tempo de subida | 350 | ms | Deriva a gravidade de subida (≈ 19,6 m/s²) e a velocidade de saída (≈ 6,86 m/s) |
| Tempo de descida, do topo ao chão | 280 | ms | Deriva a gravidade de descida: ≈ 30,6 m/s² |
| Controle no ar | 25 | % da aceleração do chão | Acima da velocidade de corrida, o input só gira e freia pela aceleração do ar (0,194 m/s por tick a 60), sem cortar o excesso; no chão, o excesso cai pela aceleração do chão. Escolha do Arthur (F-127); é a Q-07, julgada jogando |
| Controle no ar com o direcional pela metade | o alvo é a direção apontada vezes o tamanho do direcional vezes a maior entre 7 m/s e a velocidade atual | — | Acima de 7 m/s, o direcional inteiro mantém a velocidade, e um direcional pela metade a freia aos poucos, pela aceleração do ar, rumo à metade dela; abaixo de 7 m/s, nada muda. Leitura v0 do Claude (TASK-10.5) |
| Velocidade máxima de queda | 30 | m/s | |
| Pulo variável | não | — | Soltar o botão cedo não encurta o pulo |
| Pulo duplo | sim, um por voo | — | Decisão do Arthur (F-015 §1) |
| Altura do pulo duplo | 1,0 | m | Com a gravidade de subida: ≈ 6,26 m/s e ≈ 320 ms até o topo |
| Direção do pulo duplo | vira para onde o jogador aponta | — | Mantém a velocidade horizontal, sem ganhar. Sem direção apontada, mantém a direção e o módulo: leitura v0 do Claude (DEC-0017; TASK-10.1) |
| Aperto no ar com o pulo duplo disponível | sai na hora | — | Mesmo a poucos ticks do pouso; o aperto guardado para o pouso só vale com o pulo duplo gasto ou sem stamina. Leitura v0 do Claude, que o Arthur julga jogando na TASK-10.1 (F-100 §1) |
| Aperto depois do coyote, sem ter pulado | é o pulo duplo | — | Sair da beirada sem pular ainda dá ao voo o seu pulo no ar: um por voo. Dentro do coyote, sai o pulo cheio de 1,2 m. Leitura v0 do Claude (TASK-10.1) |
| Renovação do pulo duplo | ao tocar o chão ou começar uma corrida na parede | — | |
| Custo do pulo duplo | 10 | pontos de stamina | |
| Dano de queda | não | — | Decisão do Arthur (F-015 §1); a explicação no mundo do jogo é a Q-13 |

**No tick:** o código refaz a conta para o tick de 16,7 ms. A subida, 350 ms, vira 21 ticks, e o topo cai em 1,2 m. A descida, 280 ms, vira 17 ticks (283 ms). Por isso a saída do chão fica em 6,69 m/s e a gravidade de descida em 29,9 m/s², e não nos 6,86 m/s e 30,6 m/s² da conta lisa (TASK-9, critério 2; a vitrine, seção "O pulo em ticks"). O pulo duplo, 1,0 m, sai a 6,10 m/s a 60 ticks (o topo a 0,9999 m no 19º tick) e a 5,68 a 30, pela mesma conta: `sqrt(2 · g · tickrate · h) − g / 2`, com `g` a gravidade de subida por tick; sem o meio tick (− g / 2), a saída seria de 6,26 m/s a 60 e de 5,98 a 30, e o topo passaria de 1,0 m, para 1,05 m a 60 e 1,10 m a 30, porque o tick do aperto andaria com a velocidade inteira de saída (leitura v0 do Claude, TASK-10.1; a vitrine ganha a seção "O pulo duplo em ticks" quando a filha fechar).

## Perdão

| Número | Valor | Unidade | Nota |
|---|---|---|---|
| Coyote time | 100 | ms | Ainda pula logo depois de sair da beirada. A cabeça de outro lutador nunca abre o coyote, nem ao sair do chão para ela, nem ao escorregar dela ("O corpo": "A cabeça do outro"; TASK-10.7) |
| Buffer de input | 150 | ms | Um buffer só, para todo comando (DEC-0016): uma vaga, e o último aperto vence; um aperto que ainda não pode sair espera na vaga pelos 150 ms (DEC-0039; leitura v0 do Claude, TASK-10.1). No mesmo tick, o pulo vence o dash, que vence o gancho (TASK-10.4; TASK-10.6) |

## Corrida na parede

| Número | Valor | Unidade | Nota |
|---|---|---|---|
| Como entra | no ar, encostando numa parede quase vertical, com velocidade ao longo dela | — | De frente para a parede não entra |
| Inclinação mínima da parede | 80 | ° | |
| Velocidade mínima para entrar | 4 | m/s, ao longo da parede | |
| Velocidade na parede | 8 | m/s | Quem entra mais rápido conserva a velocidade de entrada |
| Teto de velocidade na parede | 12 | m/s | |
| Duração máxima | 2,5 | s | Do estudo (F-001) |
| Altura | mantida por 1,5 s | s | Depois desce com 10% da gravidade de subida (≈ 2 m/s²) e perde ≈ 1 m até soltar |
| Pulo da parede | 1,2 m de altura e 5 m/s para fora da parede | m, m/s | Mantém a velocidade ao longo da parede |
| Mesma parede | só vale de novo depois de tocar o chão ou outra parede | — | Impede subir em zigue-zague na mesma parede |
| Custo | nenhum | — | O limite é o tempo |
| Parede válida | `|normal.y| ≤ cos 80°` (0,1736) | — | A tradução dos 80° para a normal. Leitura v0 do Claude (TASK-10.5; F-128) |
| O que decide a entrada | só a velocidade horizontal no plano da parede | m/s | De frente, a velocidade ao longo é quase zero e não entra. Na entrada, a vertical zera, o pulo duplo renova e a velocidade vai a 8 m/s, ou à de entrada até 12, na direção da entrada. O input não vira nem freia. Leitura v0 do Claude (F-128) |
| Descida, tick a tick | no k-ésimo tick de descida, a vertical é `−k · 10% · g_tick`, antes do movimento | — | Perde 0,996 m a 60 ticks e 0,922 m a 30 até soltar aos 2,5 s (150 e 75 ticks). Leitura v0 do Claude (F-128) |
| Fins da corrida | tempo, borda, chão, trava abaixo de 4 m/s ou pulo | — | O mínimo de entrada serve de trava, sem número novo. Ao fim por tempo ou contato, cai no ar com o pulo duplo disponível. Leitura v0 do Claude (F-128) |
| Pulo da parede no voo | conta como o primeiro pulo | — | O pulo duplo continua disponível. Não existe coyote da parede. Um pulo guardado até 150 ms antes de encostar sai no primeiro tick da corrida (DEC-0016). Leitura v0 do Claude (F-128) |
| O coyote do chão na entrada | zera | — | Entrar na corrida apaga o coyote de quem acabou de sair do chão: uma corrida que começa e termina nos 100 ms depois do chão deixa no ar o pulo duplo, nunca o pulo cheio. Leitura v0 do Claude (Q-35; TASK-10.6) |
| Mesma parede, em números | o mesmo colisor com a normal a até 10°, inclusive | ° | 10° separa as faces de uma caixa; a identidade é o caminho do nó (DEC-0042; F-127). A câmera não inclina no v0 |
| Emenda | a corrida continua | — | Um colisor novo no mesmo plano (normal a até 10°), sem perder o contato, é a mesma corrida: o cronômetro segue, o pulo duplo não renova, e o `wall_id` passa a ser o do bloco novo. Escolha do Arthur depois da sonda A (F-129) |
| Pulo encostado na parede | entra na corrida no tick do pulo | — | Pular do chão já encostado numa parede válida começa a corrida no mesmo tick, porque o corpo já está no ar quando o motor devolve o contato. Leitura v0 do Claude (TASK-10.5) |
| O mesmo colisor na corrida | a corrida segue, e a normal guardada é a da face | — | Lido a cada tick, o mesmo colisor mantém a corrida qualquer que seja a normal que o motor dê, como na quina arredondada antes do canto (até ≈ 12°, `rede.md` §4). O estado guarda a normal da face da entrada, para a mesma face continuar recusando depois que o lutador sai pela ponta. Leitura v0 do Claude (TASK-10.5) |
| Velocidade em cada tick da corrida | volta a 8 m/s, ou fica entre 8 e 12, em todo tick | m/s | A velocidade ao longo é levada à faixa de 8 a 12 em todo tick da corrida, e não só no primeiro: um obstáculo que a baixa para entre 4 e 8 m/s sem travar a corrida a vê voltar a 8 no tick seguinte. Leitura v0 do Claude (TASK-10.5) |
| A volta no pulo da parede | a tecla para trás ao longo da parede troca o sentido | — | No tick do pulo, se a tecla tem componente ao longo da parede contrária ao sentido da corrida, a velocidade ao longo troca de sinal com a mesma rapidez. Sem tecla, com a tecla para frente ou só para fora, nada muda; o empurrão e a altura não mudam, e vale para o pulo guardado. Leitura v0 do Claude (TASK-10.10; F-131; F-136) |
| A parede passa da cabeça | um raio a 2,1 m acima dos pés, 30 cm acima da cabeça, acha uma face no mesmo plano (até 10°) | m | O raio sai do eixo da cápsula e vai até o raio dela mais 5 cm. Sem a face, a parede não aceita a corrida, e na corrida o raio passando do topo termina como na borda. Uma pilha de blocos no mesmo plano conta como uma parede. Os blocos de 1 e 2 m recusam em qualquer altura, até no pulo dado encostado neles; o `Block3m` aceita com os pés abaixo de 0,9 m e recusa no ápice do pulo; a `ParedeLonga` aceita com os pés abaixo de 1,9 m e o corredor, abaixo de 2,9 m. Num canto externo, a corrida solta quando o eixo da cápsula passa do fim da face, até ≈ 35 cm antes do que a sonda da TASK-10.5 soltava. Leitura v0 do Claude (TASK-10.10; F-132; F-136), com os 30 cm acima da cabeça depois de o implementer achar a entrada baixa no `Block2m` |
| O que se vê na parede | a cápsula inclina 15° para longe da parede, em 100 ms, com um rastro curto | °, ms | Só no visual, fora do estado (DEC-0031 §6). Leitura v0 do Claude (TASK-10.10; F-131; F-136) |

## Dash

| Número | Valor | Unidade | Nota |
|---|---|---|---|
| Onde | só no chão | — | No ar, a carta é o pulo duplo |
| Distância | 4 | m | |
| Duração | 200 | ms | Deriva a velocidade: 20 m/s |
| Velocidade na saída | 7 | m/s | Sai na velocidade de corrida |
| Direção | para onde o jogador aponta, em relação à câmera | — | Sem direção apontada, para onde o corpo olha; fixada no início, e o input de direção não muda nada nos 200 ms (DEC-0016; F-012 §1; F-015 §1). Leitura v0 do Claude (TASK-10.4) |
| Comprometido | o dash só termina pela própria regra | — | O pulo não o corta: um pulo apertado durante o dash sai no primeiro tick depois do fim, se ainda estiver nos 150 ms do buffer (F-121; DEC-0041) |
| Saindo da beirada | continua os 200 ms, com a gravidade, e sai a 7 m/s | — | "Só no chão" fala de onde ele começa. Leitura v0 do Claude (TASK-10.4) |
| Descendo a rampa de 45° | fica no chão em todos os ticks | — | O snap do chão cobre a maior velocidade no chão: 0,338 m a 60 ticks (20 m/s ÷ 60 × tan 45°, mais as margens do motor), contra 0,121 m da corrida. Um degrau de até 0,338 m passa a ser chão (F-122) |
| Contra uma parede | o tempo segue, e o motor desliza | — | Leitura v0 do Claude (TASK-10.4) |
| Tecla | Shift esquerdo, por posição física | — | F-121; DEC-0031 §8 |
| Dash guardado | sai na direção do tick em que sai | — | Um aperto guardado no ar ou na recarga usa a direção apontada, ou para onde o corpo olha, no tick em que o dash começa. Leitura v0 do Claude (TASK-10.4) |
| Para onde o corpo olha no dash | segue a câmera | — | Só a imagem: a direção do dash não muda (F-015 §1). Leitura v0 do Claude (TASK-10.4) |
| Pulo depois de um dash que saiu da beirada | o coyote conta da beirada | — | Dentro dos 100 ms do coyote, sai o pulo cheio; depois, é o pulo duplo ("Pulo e ar"). Leitura v0 do Claude (TASK-10.4) |
| Recarga | 400 | ms | Conta a partir do fim do dash: 24 ticks a 60 e 12 a 30. O dash dura 12 ticks a 60 e 6 a 30 |
| Custo | 15 | pontos de stamina | |
| Invulnerabilidade | nenhuma | — | Separado da esquiva, que é do combate (`combate.md`); o protótipo pode pedir para unir os dois |

## Gancho

| Número | Valor | Unidade | Nota |
|---|---|---|---|
| Alcance | 25 | m | Do estudo (F-001). Medido do ponto O, ao longo da mira ("De onde sai a mira"; DEC-0045) |
| Alcance mínimo | 3 | m | Medido do ponto O. Mais perto que isso é erro. Encostado numa parede, mirando reto, os pés iriam ao ponto e subiriam 8 m de uma vez (vitrine "A puxada do gancho"). Leitura v0 do Claude (TASK-10.6; F-141) |
| De onde sai a mira | do ponto O: os pés, mais 1,6 m para cima, mais 0,8 m para a direita do yaw; pelo yaw e pelo pitch da câmera | — | O é a linha do centro da tela na profundidade do corpo: a altura do pivô e o ombro da câmera ("Câmera"). O núcleo o calcula do estado, do input e dos dados, sem câmera, e o servidor refaz a conta (DEC-0044 §1; DEC-0045). O raio só pergunta ao cenário e passa pelos lutadores. Leitura v0 do Claude (TASK-10.6; TASK-10.11) |
| Onde prende | numa superfície do cenário, no ponto da mira | — | Puxar outro jogador fica para o combate |
| A quina | um ponto que o ombro não vê não vale | — | Um segundo raio, do ombro (1,6 m acima dos pés) ao ponto, só quando o primeiro acha cenário: se bate em algo antes do ponto, é erro, e a mira não ganha o ponto. Sem ele, o raio que sai ao lado do corpo prenderia atrás de uma quina, e o cabo atravessaria a parede. Escolha do Arthur (F-147; DEC-0045) |
| O erro | céu, além de 25 m ou aquém de 3 m | — | Nada acontece, e a recarga não conta: o aperto espera na vaga pelos 150 ms, e a mira é refeita a cada tick, com a direção daquele tick (DEC-0039). Leitura v0 do Claude (TASK-10.6) |
| De onde dispara | do chão, do ar e da parede | — | Na parede, a corrida acaba no disparo. Não dispara no dash nem com outro gancho no ar, voando ou puxando: o aperto espera na vaga (DEC-0041). Leitura v0 do Claude (TASK-10.6) |
| Tempo até prender | 100 | ms | O tempo do cabo voar: 6 ticks a 60 e 3 a 30. O ponto fica fixo no disparo, e o corpo segue as regras do seu modo enquanto o cabo voa; o dash espera na vaga. Leitura v0 do Claude (TASK-10.6) |
| O que a puxada leva ao ponto | os pés | — | Você cai onde mira. Puxado pelo ombro, o corpo chegaria com os pés 1,6 m abaixo do ponto, e a travessia de torre para torre bateria na parede (vitrine "A puxada do gancho"). Leitura v0 do Claude (TASK-10.6; F-141) |
| Velocidade da puxada | 18 | m/s | 25 m em ≈ 1,4 s. Rumo ao ponto, recalculada a cada tick, sem gravidade e sem input |
| Como solta | ao chegar a 1,5 m do ponto, ou quando o jogador pula | — | Conserva a velocidade. Os 1,5 m contam dos pés |
| Trava | abaixo de 50% da puxada (9 m/s) | % | A partir do segundo tick da puxada, a velocidade rumo ao ponto abaixo de 9 m/s solta o gancho: uma batida come mais da metade. Leitura v0 do Claude (TASK-10.6) |
| O pulo na puxada | só solta | — | Conserva a velocidade, sem impulso e sem custo, e o aperto se gasta na soltura: o próximo aperto no ar é o pulo duplo, se houver. Um pulo apertado enquanto o cabo voa segue as regras do modo e não solta; se ele ainda espera na vaga quando a puxada acaba pela distância ou pela trava, sai no tick da soltura, como qualquer aperto guardado ("Perdão"). O pulo duplo troca a vertical por 6,1 m/s e cortaria a subida de quem é puxado para cima. Leitura v0 do Claude (TASK-10.6; F-141) |
| Coyote do gancho | não existe | — | Sair do chão puxado não abre o coyote ("Perdão"): depois da soltura, no ar, o primeiro aperto é o pulo duplo. Leitura v0 do Claude (TASK-10.6) |
| Recarga | 6 | s | Leitura do Claude para o "gancho de 6 s" do estudo, que critica o gancho ilimitado (F-001). A sessão 1 tinha lido como duração. Conta da soltura, como a do dash: 360 ticks a 60 e 180 a 30 |
| Custo | nenhum | — | O limite é a recarga. No jogo completo, o gancho é uma das opções do slot utilitário (F-001) |
| Tecla | Q, por posição física | — | Escolha do Arthur (F-140 §1; DEC-0031 §8) |

## Stamina

| Número | Valor | Unidade | Nota |
|---|---|---|---|
| Máximo | 100 | pontos | Os custos do combate v0 vão de 8 a 25 (`combate.md`) |
| Espera para recuperar | 800 | ms sem gastar | |
| Recuperação | 30 | pontos/s | Vazia, enche em ≈ 3,3 s depois da espera (4,1 s contando os 800 ms) |
| O que gasta | pulo duplo e dash, além do combate | — | Correr, pular, a parede e o gancho não gastam |
| Como se guarda | o valor logo depois do último gasto, mais o carimbo do gasto | — | A barra se calcula pelo tick: `min(100, valor + 0,5 · max(0, tick − carimbo − 48))` a 60 ticks; carimbo, nunca contagem (DEC-0022). Leitura v0 do Claude (TASK-10.1) |
| Sem stamina suficiente | a manobra não sai | — | Nada é pago, e o aperto espera na vaga do buffer pelos 150 ms. Leitura v0 do Claude (TASK-10.1) |

## Câmera

| Número | Valor | Unidade | Nota |
|---|---|---|---|
| Distância | 3,5 | m | |
| Altura do pivô | 1,6 | m | No ombro |
| Ombro | 0,8 | m à direita, na altura do pivô | A câmera do Fortnite: o corpo fica no canto inferior esquerdo e o centro da tela livre, com 90 px entre a cápsula e a mira a 1080p (vitrine "A mira no ombro"). Nada para cima: subir empurra os pés para fora da tela. Com sinal: negativo seria o ombro esquerdo, e a troca de ombro fica para as armas de longe (Q-41). Escolha do Arthur (F-147; DEC-0045) |
| Campo de visão | 70 | ° na vertical | ≈ 102° na horizontal em 16:9; o Godot mede na vertical |
| Colisão | sim, em duas etapas | — | Para trás, do pivô até 3,5 m, e depois para o lado, até o ombro; as duas só contra o cenário. Uma parede atrás aproxima a câmera; uma parede ao lado, como na corrida na parede, desliza o ombro para o centro e a câmera fica a 3,5 m (vitrine "A mira no ombro"). Leitura v0 do Claude (TASK-10.11; DEC-0045) |
| Margem da colisão | 0,3 | m | Cada etapa para antes da parede, para o plano próximo da câmera (5 cm) não cortá-la. Leitura v0 do Claude (TASK-10.11) |
| Sensibilidade padrão | 0,06 | ° por pixel do mouse | Ajuste do jogador |
| Inclinação máxima | 80 | ° para cima e para baixo | Leitura v0 do Claude (DEC-0017): sem limite, a câmera vira de ponta-cabeça (TASK-9) |

## Métricas de nível (derivadas)

- **Vão:** até ≈ 4,4 m correndo, com o pulo, sem contar o coyote; até ≈ 7 m com o pulo duplo. Mais que isso pede parede ou gancho.
- **Altura, partindo do chão:** um bloco de 1 m se sobe com o pulo; um de 2 m, com o pulo duplo (alcance de ≈ 2,2 m). Com 3 m ou mais, só pela parede ou pelo gancho.
- **Escada:** degraus de 1 m com 4 m de vão se sobem só com o pulo, se ele sair de 3 a 6 ticks depois de deixar o degrau, no fim da janela do coyote: o pulo atrasado. Na arena da TASK-9, o Arthur subiu assim os blocos de 1, 2 e 3 m (F-086 §1), e a medição no jogo está no `mudancas.md` (17/10/2026) e na vitrine, seção "A escada dos três blocos".
- **Parede:** até ≈ 20 m de corrida (2,5 s a 8 m/s).
- **O vão de 6 m da arena:** `PlataformaVaoA` e `PlataformaVaoB`, de 6 × 2 × 6 m com o topo a 2 m, ficam em x = −20 e deixam 6 m livres entre z = 3 e z = −3. O vão passa do pulo com o coyote (≈ 4,4 + 0,7 m) e fica abaixo do pulo duplo (≈ 7 m): só o pulo duplo cruza. Cair no vão é uma queda de 2 m, e voltar para cima pede o pulo duplo (alcance de ≈ 2,2 m); com 1 m, a queda não custava nada e o vão não se lia (F-108; F-109). Elas ficam em chão livre, fora do percurso da referência e dos cenários da SyncTest, e um teste de cena prova isso (TASK-10.2).
- **A parede longa e o corredor (TASK-10.5):** a `ParedeLonga` tem 24 m, mais que os ≈ 20 m de uma corrida. O corredor tem 3,5 m de vão interno: a 5 m/s para fora, 2,8 m de centro a centro levam 0,56 s, e o lutador chega ≈ 0,54 m acima. O `PatamarDoCorredor` tem o topo a 3 m, que só se alcança com pulo da parede (+1,2 m) mais pulo duplo (+1,0 m). Leitura v0 do Claude (F-128).
- **Onde ficam na arena (TASK-10.5):** a `ParedeLonga` (1 × 4 × 24 m) tem o centro em x = 14,5 e z = −8, de z = 4 a −20, com faces para o oeste e para o leste. As paredes do corredor (1 × 5 × 24 m) ficam em x = 22,5 e x = 27, no mesmo trecho de z, com 3,5 m livres entre x = 23 e 26,5. O patamar (3,5 × 3 × 4 m) fecha a ponta sul do corredor, de z = −20 a −24. A face leste do `Block3m` e a face oeste da `ParedeLonga` ficam a 4 m uma da outra, um par para brincar.
- **Corredor estreito (TASK-10.10):** com a volta no pulo da parede, ir e voltar num corredor de vão de até 4 m sobe ≈ 0,54 m por travessia, sem fim. O mapa limita: a altura das paredes de um corredor estreito é a altura que se quer alcançar, porque a corrida termina quando o raio, 30 cm acima da cabeça, passa do topo. O corredor da arena tem 5 m. Escolha do Arthur (F-135).
- **O gancho (TASK-10.6):** de 3 a 25 m, a 18 m/s: os 16 m entre as torres levam ≈ 1 s. Com os pés indo ao ponto, o topo de uma torre de 6 m se alcança do chão mirando a face logo abaixo da borda, de uns 6 a 14 m dela; de mais longe, com o pulo duplo depois da soltura. Mirando a própria borda de perto, o embalo passa por cima de uma torre de 4 m, e soltar antes com o pulo resolve. Simulação 2D de lado, a cápsula contra caixas, na vitrine "A puxada do gancho"; o motor difere em centímetros. Leitura v0 do Claude (F-141).
- **As torres e o pilar (TASK-10.6):** a `TorreA` (centro em x = −8, z = −30) e a `TorreB` (x = 12, z = −30), de 4 × 6 × 4 m, deixam 16 m entre as faces, mais que os ≈ 7 m do pulo duplo: só o gancho cruza. O `Pilar10m` (x = 2, z = −36), de 2 × 10 × 2 m, tem o topo a 10 m. Ficam em chão livre, longe do percurso da referência e das cenas da SyncTest, e um teste de cena prova isso. Leitura v0 do Claude (F-141).
- **A borda (TASK-10.7):** quatro paredes de 50 m de altura e 1 m de espessura fecham os 80 × 80 m do chão, com a face de dentro em ±40 m: a `BordaNorte` e a `BordaSul` (82 × 50 × 1 m, centros em z = ∓40,5) e a `BordaLeste` e a `BordaOeste` (1 × 50 × 82 m, em x = ±40,5). São do cenário, corríveis e ganchoáveis como qualquer parede, e não fazem sombra: com o sol a 50° de altura, 50 m escureceriam 42 m da arena. A altura sai do gancho que conserva os 18 m/s: um gancho para cima da borda leva os pés uns 7,4 m acima do ponto, com o pulo duplo no topo; do chão, o ponto mais alto ao alcance fica a 26,2 m e os pés chegam a 33,6 m; do topo do pilar, a 3 m da borda norte, o ponto fica a 36,2 m e os pés chegam a 43,6 m. Os 50 m deixam 6,4 m de folga. No motor, o teste da borda mediu o gancho do topo do pilar prendendo a 35,99 m e os pés a 43,34 m, 6,66 m abaixo do topo (`test/arena/arena_border_test.gd`). O rascunho de 30 m era de antes da velocidade conservada (simulação de lado, a 60 ticks, na vitrine "A cabeça do outro"). Um especialista talvez escape por um canto, com o elevador da parede ("Corredor estreito") e um gancho lá em cima; não foi medido, e o plano de morte entraria numa task própria. Leitura v0 do Claude (F-152).

## O que o esqueleto andante usa (TASK-9)

O corpo, o chão, o pulo simples, o perdão e a câmera. Pulo duplo, parede, dash, gancho e stamina entram na fase 1 pelas filhas da TASK-10, a começar pelo pulo duplo e pela stamina na TASK-10.1 (F-100).

## Fora do v0

- Agarrar a borda (mantle): volta se o protótipo mostrar o "quase subi".
- Dash no ar, deslizar e escalar a parede na vertical.
- Corpos diferentes (Q-12).

## Referências do estudo (F-001)

- **Titanfall 2:** corrida na parede e o Gauntlet, um percurso cronometrado com fantasma que serve de rampa de aprendizado.
- **Black Ops III:** corrida na parede no COD mais vendido.
- **GunZ e Apex:** a MAIET manteve o K-style, uma técnica descoberta pelos jogadores. A Respawn recuou duas vezes ao tentar tirar o tap-strafe. A regra que fica: técnica descoberta ganha ferramenta, nunca nerf.

O teste da fase 1 é "divertido sozinho por 15 min?" (F-001).
