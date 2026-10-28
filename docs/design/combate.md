---
revisado_em: 2026-10-27
fontes: [F-001, F-028, F-032, F-053, F-061, F-062, F-063, F-166, F-172, F-173, F-174, F-175, F-176]
---

# Combate

Estado atual: o v0 do duelo, fechado no desenho do duelo, a primeira rodada da fase 2 (TASK-12; DEC-0036). Os números são v0 do Claude, para o Arthur julgar jogando (DEC-0017); a vitrine "O desenho do duelo" os mostra em linhas do tempo (DEC-0019). O que o estudo trouxe como "números de partida, não medidos" (F-001) passou por duas sondas (F-027; F-061 a F-063) e por uma pesquisa verificada da tribo (F-173); o que mudou está marcado, com o motivo. A matriz de posição, a esquiva como dash e o boneco da fase foram escolhidos pelo Arthur na rodada 2 (F-174 §2; DEC-0050).

## A referência: Naraka (F-001)

- **O triângulo:** carregado vence básico, parry vence carregado e básico vence parry.
- **As críticas:**
  - o gancho ilimitado vira spam;
  - as armas de longe são fracas no duelo e "baratas" em grupo;
  - o arco foi enfraquecido três vezes por entrar em combo.

## O triângulo e como ele se sustenta

Cada perna do triângulo é uma regra concreta, não uma intenção (F-173 §1, P5 e P6; C17 e C18):

| Perna | A regra que a sustenta | De onde vem |
|---|---|---|
| Carregado vence leve | **Armadura:** durante toda a preparação do carregado, um leve que acerta tira o dano e não interrompe. Sem ela, um leve começado junto pega aos 24 ticks e o carregado só aos 42, e o triângulo se inverte | O Naraka dá armadura durante toda a carga (F-173 §1 C17). No For Honor e no Chivalry, sem armadura, o leve interrompe o pesado (F-173 §1 C11 e C15) |
| Parry vence carregado | **A janela de 200 ms** nos últimos 200 ms da preparação fixa do carregado, e um carregado inteiro garantido para quem apara | A janela do For Honor (de 300 a 100 ms antes do contato) e a do Sekiro (12 frames) são de 200 ms (F-173 §1 C01 e C19) |
| Leve vence parry | **O leve não se apara:** a postura do parry não para o leve, que pega e dá o tranco. Um parry no vazio custa 450 ms de recuperação | No Naraka, os básicos não se aparam (F-173 §1 C18) |

## Princípios v0 (F-001)

- Tempo de animação fixo: o jogador não deforma a animação (lição do Mordhau; DEC-0014).
- Antecipação proporcional ao dano: o leve de 12 prepara em 250 ms, em teste (F-179), o carregado de 30 em 700.
- Indicador visual no mundo e som: os três canais por estado (DEC-0031).
- Feint custa stamina (DEC-0016).
- Arma de longe paga antes do tiro.
- No ar ninguém se defende, e quem atira de longe usa projétil.
- Troca de arma com tempo fixo e sem cancelamento (lição do shotgun do GunZ).
- Uma barra de stamina para tudo.
- **Novo no duelo:** cada risco maior paga mais. O bloqueio dá a vez; o parry e a quebra sem resposta dão um carregado inteiro ("A escada de recompensa", abaixo; F-173 §1).

## Equipamento v0 (F-001)

O equipamento tem três slots:

- **Corpo a corpo:** espada longa, lâminas duplas ou lança. **Na fase 2, só a espada longa.**
- **Distância:** arco, pistola ou mosquete. Entram no marco do arco e das armas, entre a fase 3 e a 4 (DEC-0036).
- **Utilitário:** gancho de 6 s, fumaça ou âncora. Na fase 2, só o gancho, que já existe (`movimento.md`).

Regras de balanceamento:

- A tabela de atributos fica visível no jogo.
- Ajuste se uma combinação passar de 55% de vitória no 1v1 ou de 40% de escolha no 4v4.
- No máximo 2 armas de fogo por time no ranqueado.

## Os golpes e as defesas

Os tempos seguem o formato preparação / ativo / recuperação. No código, tudo vira tick (DEC-0004, regra 3): a 60 ticks, 1 tick são 16,7 ms, e o arredondamento é para o tick mais próximo, com o empate subindo (DEC-0022). "Contato" é o primeiro tick ativo em que a lâmina toca o corpo.

| Ação | Tempos (ms) | Em ticks | Stamina | Dano | O que mudou e por quê |
|---|---|---|---|---|---|
| Golpe leve, **em teste** | 250 / 100 / 200 | 15 / 6 / 12 | 8, no início | 12 | **Em teste desde 28/10/2026 (F-179):** o leve rápido, que se defende segurando a guarda antes, e não reagindo. Com 400 / 100 / 250, o Arthur jogou e disse "parece que é um golpe pesado. Porque ele demora, você não pode se mexer muito"; o replay mostrou 42 cliques na preparação, uns 250 ms depois do anterior (F-178). Os 400 tinham nascido do "não tinha nem como reagir" da sonda, que foi com ping de 100 ms (F-062 §1), e do leve mais rápido do For Honor, 500 ms em 77 de 79 golpes (F-173 §1 C04); mas a regra dos tokens já dizia que ninguém reage ao leve (`visual-e-audio.md`, "O HUD do duelo"). O jogo de reação fica no carregado e na quebra. O dano era "sem número" (F-083 §5): 12 é ≈ 1/8 da vida, a proporção do leve do For Honor (F-173 §2). **Não se apara** |
| Golpe carregado | 700 / 120 / 450, preparação fixa | 42 / 7 / 27 | 25, pagos na soltura; precisa de 25 para começar | 30 | A carga sorteada entre 500 e 900 deu 0 parries em 21 ao Arthur, porque ninguém sabia quando a lâmina descia (F-063 §3; Q-21). Com a preparação fixa, o parry vira tempo, como os 3 parries dele no leve de preparação fixa (F-063 §2). O For Honor tem os pesados fixos em 800 ou 900 ms (F-173 §1 C04). **Armadura contra leves** durante a preparação |
| Quebra de guarda | 350 / 100 / 400 | 21 / 6 / 24 | 15, no início | 0 | A preparação fica rápida de propósito: a defesa não é escolher durante ela, e sim **o tech**, 333 ms depois do contato ("A quebra de guarda e o tech"; Q-25). Sem tech, 1.000 ms de tranco e um carregado garantido |
| Bloqueio | sobe em 100; vale enquanto segurar | 6 | 5 por leve bloqueado, 15 por carregado bloqueado | — | Era "10 por golpe" (F-001). Se bloquear custasse mais que o leve (8), quem só bloqueia perderia a guerra de stamina para o spam de leve; o carregado pesa na guarda, e é ele e a quebra que a abrem. Com a guarda alta, anda-se a 3 m/s ("A guarda andando") |
| Parry | janela de 200 desde o aperto; recupera 200 se aparou, 450 se não | 12; 12 ou 27 | 15, no aperto | — | O v0 "80 / 200 (400 se errar)" admitia duas leituras (`combate.md` anterior); fecha como janela de 200 e recuperação de 200 ou 450. Os 80 ms ficavam abaixo de toda referência medida (F-173 §1 P6; Q-21). **Só apara o carregado** |
| Esquiva | é o dash: 200, invulnerável de 50 a 167 | 12; ticks 3 a 10 | 15, no início | — | Escolha do Arthur na rodada 2 (F-174 §2; DEC-0050): uma tecla só. O dash ganha a invulnerabilidade e segue só no chão, com a recarga de 400 ms (`movimento.md`, "Dash"); assim "no ar ninguém se defende" nasce de graça. Os dois últimos ticks são vulneráveis: um carregado atrasado pega o fim do dash. O v0 do estudo tinha "60, com 250 invulnerável" numa esquiva à parte (F-001) |
| Finta | corta a preparação do carregado até 450 ms; recupera 200 | até 27; 12 | 15, no aperto | — | Só do carregado, e só antes de a janela do parry abrir (500 ms). O carregado fintado não paga os 25: o preço da finta são os 15 (DEC-0016). O For Honor finta até 400 ms antes do contato e recupera em 200 (F-173 §1 §1) |
| Troca de arma | 700 | 42 | — | — | Sem cancelamento. Entra com o arco e as armas |

**A stamina no combate.** O leve, a quebra, o parry, a finta e o dash pagam no início; o carregado paga os 25 na soltura, mas só começa com 25 na barra. Sem stamina para pagar, a ação não sai e o aperto espera na vaga do buffer (`movimento.md`, "Stamina"). O bloqueio paga no contato: com menos de 5 (ou 15 contra o carregado) na barra, a guarda cai e o golpe pega, com o tranco. A barra, a espera de 800 ms e a recuperação de 30 por segundo são as do `movimento.md`. No v0 não existe estado "cansado" além disso: o For Honor deixa quem está sem stamina lento e fácil de aparar, e o Chivalry desarma (F-173 §1 C12 e C14); se o duelo pedir, é número novo.

## O tranco e a vantagem (Q-10)

O **tranco** é o tempo em que quem levou (hitstun) ou bloqueou (blockstun) um golpe não age. A **vantagem** é quem volta a agir primeiro, e com quantos ticks de folga: `tranco de quem leva − o que falta a quem bateu`, onde o que falta é o resto do ativo mais a recuperação, contando do contato no primeiro tick ativo (F-173 §1, P1). Como o cooldown no LoL: quem tem a skill de volta antes "ganha a próxima".

| Troca | Tranco | Quem bateu ainda ocupado | Vantagem | O que garante |
|---|---|---|---|---|
| Leve acerta | 400 ms, 24 ticks | 300 ms, 18 ticks | quem bateu +6 | Nada: o leve seguinte pegaria no tick 33 e a guarda do outro já sobe no 30. Iniciativa, não combo (leve em teste, F-179) |
| Leve bloqueado | 250 ms, 15 ticks | 300 ms, 18 ticks | quem bloqueou +3 | Nada: o leve é seguro. Quem bloqueou ganha a vez, por pouco: quem apertar primeiro depois do bloqueio pega primeiro (leve em teste, F-179) |
| Carregado acerta | 700 ms, 42 ticks | 570 ms, 34 ticks | quem bateu +8 | Nada garantido; os 30 já saíram |
| Carregado bloqueado | 417 ms, 25 ticks | 570 ms, 34 ticks | quem bloqueou +9 | Nada: o bloqueio dá a vez, e o parry dá o castigo (F-173 §1, P4) |
| Carregado aparado | quem foi aparado: 900 ms, 54 ticks, mais 9 ticks de hitstop sozinho | quem aparou recupera em 200 ms, 12 ticks | quem aparou +42 | **Um carregado garantido:** começa no tick 12, pega no 54; a guarda do outro só subiria no 60 |
| Quebra sem tech | quem levou: 1.000 ms, 60 ticks, do contato | quem agarrou solta no fim da janela do tech, tick 20 | quem agarrou +40 | **Um carregado garantido:** pega no tick 62; a guarda do outro só subiria no 66 |
| Quebra com tech | os dois presos 333 ms, 20 ticks | — | quem respondeu +2 | Nada: tudo recomeça, com 33 ms a favor de quem respondeu (For Honor, F-173 §1 C09) |
| Parry no vazio | quem apertou: 450 ms, 27 ticks | — | o outro +27 | A finta que puxou o parry já tem o leve na vaga: ele pega antes de o parry voltar |
| Leve contra leve, começados juntos | os dois: 24 ticks | — | neutra | Troca: os dois levam 12 |
| Carregado contra carregado | os dois: 42 ticks | — | neutra | Troca: os dois levam 30. Como o "clash" do Naraka (F-173 §1) |

**Por que "seguro" aqui é diferente do jogo de luta.** No Street Fighter e no Tekken, bloquear é instantâneo; aqui, a guarda leva 6 ticks para subir. Um golpe bloqueado só vira castigo quando a desvantagem de quem bateu passa de 9 ticks: os 15 da preparação do leve em teste menos os 6 da guarda (F-173 §1, P2; F-179); com o leve de 400 ms eram 18. Nenhum golpe v0 passa disso no bloqueio: o carregado bloqueado dá 9, exatamente no limite; só o parry e a quebra sem tech passam, e por isso só eles garantem dano.

**Hitstun maior que blockstun**, sempre, como no Tekken (F-173 §1 C22): levar um golpe custa mais tempo do que bloqueá-lo.

**O tranco e o corpo.** No tranco não há input de movimento nem de ação; a gravidade continua, e a velocidade horizontal cai pela desaceleração do chão. No ar, o corpo segue a trajetória. Um golpe não empurra no v0: o recuo do corpo é só pose (DEC-0031, "Reação").

## A armadura do carregado

Durante toda a preparação do carregado (os 42 ticks), um leve que acerta tira os 12 de vida e **não** interrompe: não há tranco, e a preparação segue. A armadura vale só contra leves. A quebra de guarda agarra quem está em preparação; o parry não se aplica (ele apara o carregado, não o contrário); outro carregado é troca; a esquiva nem entra. A recuperação do carregado não tem armadura. Começar no tick 0 é a regra mais simples de ler (F-173 §1, R6); a alternativa, começar aos 100 ms como alguns finalizadores do For Honor (F-173 §1 C11), fica como ajuste se o leve parecer inútil contra quem carrega.

## O parry (Q-21)

- **O que apara:** só o carregado. O leve pega na postura do parry e dá o tranco; a quebra agarra quem está na postura.
- **A janela:** 200 ms (12 ticks) a partir do aperto. Como a preparação do carregado é fixa, a janela útil são os últimos 200 ms dela: quem vê o azul no tick 0 aperta entre 500 e 700 ms. É acerto de tempo guiado pela preparação que se vê, não reação ao início (F-053 §2.4; F-063 §3): a pessoa conta até o fim.
- **O acerto:** o "clang", o flash e as faíscas nos dois (DEC-0031); quem foi aparado congela 9 ticks sozinho e fica 900 ms sem agir; quem aparou recupera em 200 ms e tem um carregado garantido.
- **O erro:** 450 ms de recuperação, de pé, lendo o que vem. Um parry apertado por medo aos 300 ms fecha a janela aos 500, antes do contato, e os 450 ms pegam a pessoa parada: é o 0 em 21 da sonda, agora com uma causa visível (F-063 §3).
- **Contra spam:** a recuperação do erro e "o leve não se apara" bastam no v0. O Sekiro encolhe a janela a cada aperto (F-173 §1 C19); fica como ajuste se o duelo pedir.
- **Na rede:** o parry é defesa por tempo, julgada na tela de quem defende (DEC-0026 §3). A fase 2 escreve a regra com `view_lag` zero.

## A quebra de guarda e o tech (Q-25)

A sonda provou que escolher entre parry, guarda e esquiva durante uma preparação de 350 ms não cabe na reação de escolha: 20 de 22 falharam, e a mão vermelha não mudou a resposta (F-063 §3). A quebra fica rápida de propósito, e a defesa muda de lugar, como no For Honor (F-173 §1 C08, P7):

1. **A quebra agarra** quem está parado, bloqueando, na postura do parry, na recuperação de um golpe, no tranco de bloqueio ou na preparação de um carregado. Não agarra quem está no ar, no dash invulnerável, nem quem acerta antes: a quebra não tem armadura, e um leve que pega durante os 350 ms a derruba. Começando juntos, a quebra (contato no tick 21) chega antes do leve (24).
2. **No contato, os dois ficam presos** 333 ms (20 ticks): a animação do agarrão. Nesse tempo, quem foi agarrado pode apertar a própria tecla da quebra: **o tech**. É reação simples a um estímulo só ("fui agarrado"), que cabe nos 213 a 273 ms medidos (F-053 §2.3), com folga de 60 a 120 ms.
3. **Com o tech,** os dois se soltam no fim dos 20 ticks, e quem respondeu fica 2 ticks à frente (os 33 ms do For Honor, F-173 §1 C09). Tudo recomeça.
4. **Sem o tech,** quem foi agarrado fica 1.000 ms (60 ticks) sem agir, contados do contato; quem agarrou solta no tick 20 e tem um carregado garantido (pega no 62). A quebra não tira vida: o carregado tira.
5. **No vazio** (esquivada, ou o alvo saiu do alcance), a quebra recupera em 400 ms, e quem esquivou ganha a vez e a posição.

A quebra continua "não reagível por escolha" na preparação, e isso é desenho: ela é a ferramenta contra quem só bloqueia. Uma quebra reagível na preparação precisaria de 500 ms ou mais, e aí a esquiva passaria sempre, e a quebra perderia a função (F-173 §1 R8).

## A esquiva e o dash (DEC-0050)

Escolha do Arthur na rodada 2 (F-174 §2; DEC-0050): a esquiva **é** o dash. O dash de 4 m em 200 ms (`movimento.md`, "Dash") ganha invulnerabilidade dos 50 aos 167 ms (ticks 3 a 10), mantém os 15 de stamina, a recarga de 400 ms e a regra "só no chão". O que isso dá: uma tecla a menos para aprender, e "no ar ninguém se defende" como consequência, não como regra à parte. O preço: a esquiva leva o corpo 4 m para fora do alcance, então ela dá a vez e a posição, nunca um castigo garantido; e os ticks 1, 2, 11 e 12 são vulneráveis, para um carregado atrasado pegar o fim do dash. Um golpe que pega nesses ticks interrompe o dash. A alternativa recusada era a esquiva do estudo à parte: 60 ms de preparação, 250 invulnerável, recuperação de 200, 20 de stamina, 2 m, numa tecla nova (F-001).

## A finta

Só o carregado finta, até 450 ms (27 ticks) da preparação, antes de a janela do parry abrir aos 500. A finta corta a preparação, custa 15 e recupera em 200 ms; o carregado fintado não paga os 25. O que ela faz: quem viu o azul e apertou o parry cedo paga os 450 ms, e o leve que a finta já deixou na vaga pega antes de ele voltar. Ela cumpre as quatro condições da DEC-0016: está na lista, tem preço, tem aviso (a pose volta num estalo, com o estalo seco) e tem janela larga.

## O bloqueio, a guarda andando e a stamina

- **Segurar** a tecla levanta a guarda em 100 ms (6 ticks); soltar derruba na hora. A guarda alta bloqueia o leve e o carregado, não a quebra.
- **A guarda andando:** com a guarda alta, o corpo anda a 3 m/s em qualquer direção (o "modo de guarda" que o `movimento.md`, "Chão", deixava para o combate). Correr a 7 m/s, pular e dar o dash derrubam a guarda: o dash sai e a guarda cai. No ar não há guarda.
- **O custo:** 5 de stamina por leve bloqueado e 15 por carregado bloqueado, pagos no contato. O For Honor não cobra stamina de quem bloqueia; o Chivalry cobra um terço do dano (F-173 §1 C14). O v0 fica no meio: bloquear leve é sustentável, bloquear carregado cansa.
- **Sem stamina** para o custo, a guarda cai no golpe: o golpe pega com o tranco cheio.

## A lâmina e o contato (DEC-0026 §4)

A conta do golpe é do núcleo, com formas simples: a lâmina é um segmento com raio, e o corpo é a cápsula de 1,8 m × 0,35 m. O teste usa a fatia varrida de cada tick. Os números v0:

| Número | Valor | Unidade | Nota |
|---|---|---|---|
| A mão | 0,6 m do eixo do corpo, a 1,3 m de altura | m | Onde a lâmina começa |
| Comprimento da lâmina | 1,4 | m | A ponta a 2,0 m do eixo |
| Raio da lâmina | 0,08 | m | A espessura do contato |
| Alcance efetivo | ≈ 2,4 | m, centro a centro | Ponta mais raio mais o raio da cápsula; dentro do arco |
| Leve | arco horizontal de 120° (±60° da frente), a 1,3 m, varrido nos 6 ticks do ativo | ° | Do lado da mão para o outro |
| Carregado | corte de cima para baixo no plano da frente, de 2,2 m a 0,6 m de altura, nos 7 ticks | m | A ponta chega a 2,0 m à frente |
| Quebra de guarda | a mão em linha reta até 1,2 m à frente, nos 6 ticks | m | Agarra um corpo cujo eixo está a até ≈ 1,55 m |
| O leve no ar | o mesmo arco, inclinado 45° para baixo | ° | O golpe de quem está no alto ("A matriz de posição") |
| Direção | para onde a câmera olha, fixada no último tick da preparação | — | Durante a preparação o corpo gira livre; no ativo e na recuperação, não. Sem travar a mira no oponente: o golpe sai para onde a câmera olha, como o gancho |
| Um acerto por janela ativa (Q-26) | cada golpe acerta cada alvo no máximo uma vez | — | O estado guarda quem o golpe já acertou. Na sonda, a lâmina parada no corpo recomeçava o tranco 4 vezes em 24 ticks (F-073 §4); é a regra do Tekken (F-173 §1 C23). Um teste do núcleo prova com a lâmina parada dentro do corpo por todo o ativo |
| Parede no meio | não bloqueia no v0 | — | DEC-0026 §4 |
| Dois golpes no mesmo tick | os dois pegam: troca | — | Sem prioridade entre eles |

### O leve no tick (TASK-12.1; DEC-0051)

Como as regras acima viram ticks. O que não estava no papel é leitura v0 do Claude (DEC-0017), salvo o andar no golpe e a tecla, que são escolhas do Arthur (F-175 §2).

- **Quando o leve sai:** em pé no chão (o modo `GROUND`, fora da cabeça de outro lutador; `movimento.md`, "O corpo"), sem golpe em curso e com 8 de stamina, pagos no primeiro tick da preparação. Fora disso, o aperto espera na vaga do buffer pelos 150 ms (`movimento.md`, "Perdão" e "Stamina"). Num dash, o leve guardado sai no tick seguinte ao da saída do dash, e não nele: o combate decide antes do movimento, e é o movimento que termina o dash (DEC-0051 §2). A tecla é o botão esquerdo do mouse, remapeável (F-175 §2; DEC-0031 §8).
- **A vaga dividida:** uma vaga só para todo comando (DEC-0039). No mesmo tick, o pulo vence o dash, que vence o gancho, que vence o leve: qualquer tecla de movimento apertada junto com o leve leva a vaga.
- **As fases:** a preparação de 15 ticks, o ativo de 6 e a recuperação de 12, em teste (F-179; eram 24, 6 e 15), um depois do outro, contados do tick em que cada fase começou. Nenhum input corta a sequência (DEC-0016).
- **O corpo durante o golpe, em teste** (F-179): o leve não freia o corpo. Em pé, valem as regras do chão: o corpo corre a até 7 m/s, acelera e para como sempre, e a preparação de 250 ms soma até 1,75 m de alcance. O andar devagar de 3 m/s fica para a guarda e para o carregado. Com o leve de 400 ms, o golpe andava a 3 m/s (F-175 §2). Nenhum comando sai da vaga durante o golpe: um pulo, um dash ou um gancho apertados nele esperam e saem no primeiro tick depois da recuperação, se ainda estiverem nos 150 ms. Saindo de uma beirada no meio do golpe, valem as regras do ar, e o golpe continua.
- **A direção:** em cada tick da preparação, a direção do golpe é a da câmera, e o corpo olha para ela. Do primeiro tick ativo ao fim da recuperação, ela fica, e o corpo olha para ela, por mais que a câmera gire.
- **O arco do leve:** da direita, o lado da mão, para a esquerda: de −60° a +60° da direção do golpe, com o ângulo positivo girando para a esquerda, como o yaw. A fatia do tick k do ativo, de 1 a 6, vai de −60° + 20°·(k − 1) a −60° + 20°·k: a coroa de círculo entre 0,6 m e 2,0 m do eixo de quem bate, na altura da mão, 1,3 m acima dos pés dele.
- **O toque:** a fatia toca o alvo quando a menor distância entre ela e o eixo da cápsula do alvo, o segmento de 0,35 m a 1,45 m acima dos pés dele, é de até 0,43 m, os 0,35 do corpo mais os 0,08 da lâmina. A conta é exata, sem amostrar ângulos: um alvo entre a lâmina do fim de um tick e a do fim do seguinte é acertado.
- **O contato:** no tick do toque, o estado de quem bateu carimba o tick, o nome do alvo e o golpe (DEC-0026 §3). Um golpe faz um contato só: depois dele, a lâmina não testa mais até o golpe acabar (Q-26). Os alvos são testados em ordem de nome.
- **Quem levou** aplica o contato no tick seguinte ao toque, o primeiro em que a foto do tick o mostra (DEC-0051): perde o dano do golpe, e a vida nunca desce de 0. O dano e, na TASK-12.2, o tranco contam do tick do contato. Dois leves que tocam no mesmo tick tiram 12 dos dois no tick seguinte, em qualquer ordem dos lutadores.
- **A vida no treino:** sem partida, até a TASK-12.7, a vida volta a 100 dois segundos, 120 ticks, depois do último golpe levado (`partida.md`, "Os modos da Main").
- **Na TASK-12.1, o golpe levado não interrompe o seu:** o tranco entra na TASK-12.2.

## O hitstop e o tremor

O **hitstop** é a pausa curta dos dois lutadores no instante do acerto, que faz o golpe parecer ter encostado em algo. No v0 ele é **simulado**, curto e simétrico: os dois congelam o mesmo tempo, o relógio do golpe dos dois para junto, e por isso a vantagem não muda (F-173 §2, princípio 7); o relógio do round e os outros lutadores não param. Ser estado do núcleo faz a animação nunca descolar da simulação e o rollback refazê-lo igual; o custo é uma correção do tamanho do hitstop quando um acerto chega atrasado pela rede, e por isso ele é curto. A definição anterior do glossário, "só apresentação", muda com este desenho (`mudancas.md`). O jogo de luta 2D usa 9 a 13 frames; o Celeste, 3 (F-173 §2); aqui o leve inteiro dura 24, então 4 a 7.

| Evento | Quem congela | ms | Ticks | Tremor da câmera (apresentação) |
|---|---|---|---|---|
| Leve acerta | os dois | 67 | 4 | 100 ms, 0,5°, em quem levou |
| Carregado acerta | os dois | 117 | 7 | 200 ms, 1,5°; metade em quem bateu |
| Quebra pega | os dois | 67 | 4 | 100 ms, 0,5° |
| Leve bloqueado | os dois | 33 | 2 | 100 ms, 0,3°, em quem bloqueou |
| Carregado bloqueado | os dois | 67 | 4 | 100 ms, 0,3° |
| Parry | só quem foi aparado | 150 | 9 | 150 ms, 1,0°, nos dois |
| Golpe que mata | os dois | 200 | 12 | 300 ms, 2,0° |

O precedente do parry é o perfect shield do Smash: só o atacante congela (F-173 §2). O tremor é só apresentação, toca uma vez por evento pela chave (DEC-0031 §6), tem opção para desligar na tela de opções, e as amplitudes são pequenas porque a câmera também é a mira (DEC-0014). Com mais lutadores na arena (4v4), o hitstop encolhe, como o Smash faz com 8 jogadores (F-173 §2); número da fase 4.

## A matriz de posição (Q-14; DEC-0050)

Cada lugar tem uma força e uma fraqueza (pilar 2), e a troca tem de ser legível de fora (pilar 1). Escolha do Arthur na rodada 2 (F-174 §2; DEC-0050):

| Onde | Ataca | Defende | Se leva um golpe | O preço |
|---|---|---|---|---|
| Chão (parado, correndo, guarda andando) | leve, carregado, quebra, finta | bloqueio, parry, esquiva | tranco normal | nenhum: é a base |
| Dash | nada: comprometido | invulnerável nos ticks 3 a 10 | nos ticks 1, 2, 11 e 12: tranco normal, e o dash acaba | sai 4 m do alcance; recarga de 400 ms |
| Ar (pulo, pulo duplo, queda) | só o leve, que desce em 45°: o golpe de quem está no alto (F-012 §1) | nada: "no ar ninguém se defende" (F-001) | tranco, e continua caindo | sem defesa; o pulo duplo é a única carta |
| Parede (corrida) | nada: as mãos estão na parede | nada | cai da parede, com tranco | a altura e o ângulo em troca de até 2,5 s exposto |
| Gancho (puxada) | nada: uma mão no cabo (a regra das mãos) | nada | solta o gancho, com tranco | atravessa 25 m em 1,4 s sem poder responder |
| Tranco e preso no agarrão | nada | nada (só o tech) | um acerto por janela ativa; a quebra não agarra quem está no ar | — |

- **A regra das mãos** (proposta na Q-14): uma manobra que ocupa uma mão só deixa usar arma de uma mão. Na fase 2, com a espada longa, a puxada do gancho não ataca; mais tarde, a pistola cabe na puxada e a espada não.
- **A quebra** só agarra quem está no chão: agarrar no ar não se lê.
- **O leve no ar** é comprometido como qualquer golpe: pousar durante o ativo ou a recuperação não o corta.
- **O gancho não prende em gente** no v0 (a crítica ao Naraka, F-001; `movimento.md`, "Gancho").
- As alternativas recusadas na rodada 2: o leve sai da parede também (uma lâmina correndo de lado numa parede é difícil de ler); ou tudo vale em todo lugar, sem matriz.

## Fora do v0

- **Anti-fuga:** a regra do tempo esgotado pela vida já pune a fuga (`partida.md`); o For Honor só precisou de um anti-fuga depois do jogo real (F-173 §2). Entra se o duelo pedir (Q-50).
- **Dano que atravessa a guarda** (chip damage): o bloqueio custa stamina, não vida.
- **Empurrão no acerto e no agarrão:** no v0, nenhum golpe move o outro; o recuo é pose.
- **Travar a mira no oponente** (lock-on): não; o golpe sai para onde a câmera olha.
- **Cancelamentos além da lista** da DEC-0016: a finta, e a passagem da recuperação do leve para a esquiva, que fica como hipótese até o duelo jogável.
- **O estado "sem stamina"** do For Honor e o desarme do Chivalry.

## Times (F-001)

- **1v1:** preserva o "pensado".
- **4v4:** também preserva, com proteção contra 2 em 1: um anel visível.
- **8v8:** vira leitura de mapa, e a rede passa de 56 para 240 pares de jogadores por atualização.
- **Ordem:** 1v1, depois 4v4, e o 8v8 como evento.

## Decidido no Desenho 1

- **Tribo For Honor e Chivalry 2** (Q-06; DEC-0014): tempo fixo e aviso claro. A profundidade vem de ler e escolher, não de manipular a animação.
- **Cancelamento só desenhado** (DEC-0016): na lista, com preço, com aviso e com janela larga. O que não está na lista não cancela. A lista do v0, como hipótese até a fase 2:
  - a finta, que corta a preparação por 15 de stamina;
  - a recuperação do golpe leve, que pode passar para a esquiva, pagando os 20 de stamina da esquiva.
- **A barra de stamina** (máximo e recuperação) está em `movimento.md`, porque o pulo duplo e o dash também gastam dela (DEC-0017).

## A rede no combate (Desenho 3; DEC-0026)

Com ping, o golpe do outro chega atrasado na tela de quem defende. No relógio do servidor, ninguém defende por reação com ping de 100 ms ou mais (F-028 §3). O jogo julga cada um pela própria tela, até um teto. O detalhe está em `docs/arquitetura/rede.md` §6.

| Número ou regra | Valor | Unidade | Nota |
|---|---|---|---|
| Teto de compensação | 200 | ms | 12 ticks a 60. Número v0, fechado pelo Claude (DEC-0017). O estudo propõe de 150 a 200 para a espada (F-001). Acima dele, quem tem o atraso paga o excesso |
| Quem tem razão sobre a posição | a tela de quem ataca | — | A espada pega o que quem ataca via, e o contato nunca é desfeito. Escolha do Arthur (F-032 §2) |
| Quem tem razão sobre a defesa por tempo | a tela de quem defende | — | Parry, bloqueio, esquiva e o tech valem como quem defende viu. Direção da DEC-0011 |

**O que se sente:**

- Até o teto, quem defende tem a preparação inteira para reagir, como sem lag: o mesmo parry do ping 0.
- Quem ataca descobre o resultado depois do contato: uns 240 ms com ping 100.
- Quem só correu para sair do alcance leva o golpe se, na tela de quem ataca, ainda estava nele. A esquiva, o parry e o bloqueio salvam, porque valem no tempo de quem defende.

## Em aberto

- **Q-07:** qual a técnica própria do jogo, o equivalente ao K-style do GunZ? O duelo é o próximo lugar onde ela pode aparecer (F-166).
- **Q-34 e Q-44:** o dash no ar e a escalada voltam com o primeiro oponente, na filha do bot (F-166 §4 e §6).
- **O que o duelo jogável mede,** na ordem em que o Arthur vai sentir: se o leve de 400 ms se lê e se defende; se o carregado de 700 se apara contando; se a quebra se responde com o tech; se o bloqueio a 5 e 15 de stamina sustenta; se o hitstop de 4 e 7 ticks pesa sem grudar; se a recuperação do leve para a esquiva (DEC-0016) faz falta. Cada um é um número no Resource, trocado sem tocar no código (DEC-0004, regra 3).
