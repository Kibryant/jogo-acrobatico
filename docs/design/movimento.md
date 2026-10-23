---
revisado_em: 2026-10-19
fontes: [F-001, F-012, F-013, F-015, F-084, F-086, F-088, F-100]
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
  - a velocidade se conserva entre manobras, dentro dos tetos abaixo;
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
| Controle no ar | 25 | % da aceleração do chão | |
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
| Coyote time | 100 | ms | Ainda pula logo depois de sair da beirada |
| Buffer de input | 150 | ms | Um buffer só, para todo comando (DEC-0016): uma vaga, e o último aperto vence; um aperto que ainda não pode sair espera na vaga pelos 150 ms (DEC-0039; leitura v0 do Claude, TASK-10.1). No mesmo tick, o pulo vence o dash, que vence o gancho (vale quando eles existirem, TASK-10.4 e TASK-10.6) |

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
| Alcance | 25 | m | Do estudo (F-001) |
| Onde prende | numa superfície do cenário, no ponto da mira | — | Puxar outro jogador fica para o combate |
| Tempo até prender | 100 | ms | O tempo do cabo voar |
| Velocidade da puxada | 18 | m/s | 25 m em ≈ 1,4 s |
| Como solta | ao chegar a 1,5 m do ponto, ou quando o jogador pula | — | Conserva a velocidade |
| Recarga | 6 | s | Leitura do Claude para o "gancho de 6 s" do estudo, que critica o gancho ilimitado (F-001). A sessão 1 tinha lido como duração |
| Custo | nenhum | — | O limite é a recarga. No jogo completo, o gancho é uma das opções do slot utilitário (F-001) |

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
| Ombro | centralizada | — | O deslocamento para o ombro entra com a mira das armas de longe |
| Campo de visão | 70 | ° na vertical | ≈ 102° na horizontal em 16:9; o Godot mede na vertical |
| Colisão | sim | — | Aproxima quando uma parede fica no meio |
| Sensibilidade padrão | 0,06 | ° por pixel do mouse | Ajuste do jogador |
| Inclinação máxima | 80 | ° para cima e para baixo | Leitura v0 do Claude (DEC-0017): sem limite, a câmera vira de ponta-cabeça (TASK-9) |

## Métricas de nível (derivadas)

- **Vão:** até ≈ 4,4 m correndo, com o pulo, sem contar o coyote; até ≈ 7 m com o pulo duplo. Mais que isso pede parede ou gancho.
- **Altura, partindo do chão:** um bloco de 1 m se sobe com o pulo; um de 2 m, com o pulo duplo (alcance de ≈ 2,2 m). Com 3 m ou mais, só pela parede ou pelo gancho.
- **Escada:** degraus de 1 m com 4 m de vão se sobem só com o pulo, se ele sair de 3 a 6 ticks depois de deixar o degrau, no fim da janela do coyote: o pulo atrasado. Na arena da TASK-9, o Arthur subiu assim os blocos de 1, 2 e 3 m (F-086 §1), e a medição no jogo está no `mudancas.md` (17/10/2026) e na vitrine, seção "A escada dos três blocos".
- **Parede:** até ≈ 20 m de corrida (2,5 s a 8 m/s).
- **O vão de 6 m da arena:** `PlataformaVaoA` e `PlataformaVaoB`, de 6 × 2 × 6 m com o topo a 2 m, ficam em x = −20 e deixam 6 m livres entre z = 3 e z = −3. O vão passa do pulo com o coyote (≈ 4,4 + 0,7 m) e fica abaixo do pulo duplo (≈ 7 m): só o pulo duplo cruza. Cair no vão é uma queda de 2 m, e voltar para cima pede o pulo duplo (alcance de ≈ 2,2 m); com 1 m, a queda não custava nada e o vão não se lia (F-108; F-109). Elas ficam em chão livre, fora do percurso da referência e dos cenários da SyncTest, e um teste de cena prova isso (TASK-10.2).

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
