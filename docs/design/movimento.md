---
revisado_em: 2026-10-17
fontes: [F-001, F-012, F-013, F-015, F-084, F-086, F-088]
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
| Direção do pulo duplo | vira para onde o jogador aponta | — | Mantém a velocidade horizontal, sem ganhar |
| Renovação do pulo duplo | ao tocar o chão ou começar uma corrida na parede | — | |
| Custo do pulo duplo | 10 | pontos de stamina | |
| Dano de queda | não | — | Decisão do Arthur (F-015 §1); a explicação no mundo do jogo é a Q-13 |

**No tick:** o código refaz a conta para o tick de 16,7 ms. A subida, 350 ms, vira 21 ticks, e o topo cai em 1,2 m. A descida, 280 ms, vira 17 ticks (283 ms). Por isso a saída do chão fica em 6,69 m/s e a gravidade de descida em 29,9 m/s², e não nos 6,86 m/s e 30,6 m/s² da conta lisa (TASK-9, critério 2; a vitrine, seção "O pulo em ticks").

## Perdão

| Número | Valor | Unidade | Nota |
|---|---|---|---|
| Coyote time | 100 | ms | Ainda pula logo depois de sair da beirada |
| Buffer de input | 150 | ms | Um buffer só, para todo comando (DEC-0016) |

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
| Direção | para onde o jogador aponta, em relação à câmera | — | |
| Recarga | 400 | ms | Conta a partir do fim do dash |
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
| Recuperação | 30 | pontos/s | Vazia, enche em ≈ 3,3 s |
| O que gasta | pulo duplo e dash, além do combate | — | Correr, pular, a parede e o gancho não gastam |

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

## O que o esqueleto andante usa (TASK-9)

O corpo, o chão, o pulo simples, o perdão e a câmera. Pulo duplo, parede, dash, gancho e stamina ficam para a fase 1 (TASK-10).

## Fora do v0

- Agarrar a borda (mantle): volta se o protótipo mostrar o "quase subi".
- Dash no ar, deslizar e escalar a parede na vertical.
- Corpos diferentes (Q-12).

## Referências do estudo (F-001)

- **Titanfall 2:** corrida na parede e o Gauntlet, um percurso cronometrado com fantasma que serve de rampa de aprendizado.
- **Black Ops III:** corrida na parede no COD mais vendido.
- **GunZ e Apex:** a MAIET manteve o K-style, uma técnica descoberta pelos jogadores. A Respawn recuou duas vezes ao tentar tirar o tap-strafe. A regra que fica: técnica descoberta ganha ferramenta, nunca nerf.

O teste da fase 1 é "divertido sozinho por 15 min?" (F-001).
