---
id: DEC-0045
titulo: A mira no ombro e o ponto O — a câmera por cima do ombro direito, o raio da mira saindo da linha do centro da tela, calculado pelo núcleo, e o segundo raio que recusa a quina
data: 2026-10-26
status: aceita
decidido_por: Arthur (F-147; F-148)
fontes: [F-144, F-145, F-146, F-147, F-148]
substitui: DEC-0044, só a direção pelo centro da tela com a câmera centralizada (§2) e a linha "Ombro: centralizada" da tabela da câmera
substituida_por:
---

# DEC-0045 — A mira no ombro e o ponto O: a câmera por cima do ombro direito, o raio da mira saindo da linha do centro da tela, calculado pelo núcleo, e o segundo raio que recusa a quina

## Contexto

O Arthur jogou o gancho e achou a mira ruim: "o meu boneco ficava na frente da mira" (F-144 §1). A câmera era centralizada: olhava reto para um pivô dentro da cápsula, 1,6 m acima dos pés e 3,5 m à frente dela (`movimento.md`, "Câmera"), então o centro da tela passava pela cabeça, e o corpo cobria a mira por 56 px a 1080p (vitrine "A mira no ombro", https://claude.ai/artifact/CZxqwAb7JjCJYFADfsYuw9). O `movimento.md` tinha deixado o deslocamento para o ombro para a mira das armas de longe, e o gancho foi a primeira coisa que se mira. O Arthur pediu a filha antes da TASK-10.7 (F-145).

A DEC-0044 §2 dizia: "Com a câmera centralizada, o raio do ombro passa pelo centro da tela", e previa em "Revisitar se" a câmera ganhar o ombro. Com a câmera deslocada, um raio que sai do ombro na direção da câmera corre paralelo à linha do centro da tela, 0,8 m ao lado dela, e a mira mentiria. É a paralaxe da mira: a câmera e o ombro olham para o mesmo lado, de lugares diferentes, e a mira marca a linha da câmera. No print do Fortnite que o Arthur mandou, a arma fica no ombro, à esquerda da mira, e a bala vai para onde a mira aponta (F-146).

Na conferência aberta (DEC-0043), o Arthur chegou perto: um raio saindo do ombro "não sairia centralizado" (F-146 §1). Ao ver a vitrine, disse que a câmera por cima do ombro "faz muito mais sentido" (F-146 §1).

## Opções consideradas

Para a câmera:

1. **Por cima do ombro direito, 0,8 m à direita do pivô, nada para cima (escolhida):** a câmera do Fortnite. O corpo fica no canto inferior esquerdo, com 90 px livres entre a cápsula e a mira a 1080p; os pés a 187 px da borda de baixo. Fica um lado cego à esquerda, atrás do corpo.
2. **Acima da cabeça, 0,6 m para cima:** o jeito do GunZ. Libera a mira sem lado cego, mas os pés ficam a 55 px da borda de baixo, e o chão só aparece 0,36 m antes dos pés, contra 1,21 m. Num jogo de pousar em torres e plataformas, ver os pés vale mais.
3. **Ombro direito e um pouco para cima (0,3 m):** mais chão à frente e menos chão abaixo dos pés; um número a mais para julgar.

Para a origem do raio:

1. **O ponto O, na linha do centro da tela, calculado pelo núcleo (escolhida):** os pés, mais a altura da mira, mais o ombro para a direita do yaw: `Aim.origin(feet, yaw, height, side)`, uma função pura. O servidor refaz sem câmera, como o pedido de mira já pedia (DEC-0044 §1). O alcance é medido de O.
2. **Do ombro, "entortado" para o ponto que a câmera acha:** dois raios em todo tick com pedido, e o primeiro dependeria da câmera, que o servidor não tem.
3. **Da câmera:** o servidor não tem câmera, e o braço que encurta contra uma parede entraria na conta.

Para a quina, o ponto que o raio de O acha e o ombro não vê:

1. **Um segundo raio, do ombro ao ponto, agora (escolhida):** se ele bate em algo antes do ponto, o ponto não vale, e a mira não ganha o ponto. Só roda quando o primeiro acha cenário, uns 8 µs a mais. A mira nunca promete o que o corpo não alcança.
2. **Deixar para o teste dos 15 minutos:** uma pendência; até lá o gancho prenderia atrás de uma quina, o cabo atravessaria a parede e a trava soltaria na batida.

Para a câmera perto das paredes:

1. **Duas etapas, só contra o cenário (escolhida):** para trás, do pivô até 3,5 m, como hoje, e depois para o lado, até o ombro; cada etapa para 0,3 m antes da parede. Na corrida com a parede à direita, o ombro desliza para o centro e a câmera fica a 3,5 m.
2. **Um braço só, na diagonal, do corpo até a câmera:** dá zoom no corpo em toda corrida com a parede à direita, a assinatura do jogo.
3. **O ombro sem colisão:** a câmera entra na parede.

Para a troca de ombro:

1. **Fica para as armas de longe (escolhida):** o número do ombro nasce com sinal, então a troca custa depois uma tecla e um campo do input (Q-41).
2. **Entra agora, com uma tecla:** uma tecla, um campo no input que o servidor lê para o raio, uma coluna no replay e a câmera que troca de lado.

## Decisão

Aceita pelo Arthur em 26/10/2026: as três escolhas (F-147 §1), todas pela recomendação, e o plano no modo de plano (F-148 §1).

1. **A câmera** fica 0,8 m à direita do pivô, na altura dele, nada para cima. A colisão é em duas etapas, para trás e depois para o lado, as duas só contra o cenário, com margem de 0,3 m. Os números moram no `CameraData` (`shoulder_m`, `collision_margin_m`), com sinal no ombro.
2. **O raio da mira** sai do ponto O: os pés, mais 1,6 m para cima, mais 0,8 m para a direita do yaw, ao longo de `Aim.direction(yaw, pitch)`. O ponto O é `Aim.origin`, uma função pura do núcleo; o nó lança o raio dela no tick, a mira da tela a chama com o yaw da câmera, e o `after_move` mede o alcance de 3 a 25 m a partir dela (`Movement.in_reach`), com o `facing_yaw` do tick. O ombro entra no `MovementData` como cópia (`aim_side_m`), guardada por um teste de igualdade com o `camera_v0.tres`, como a altura (DEC-0044 §3).
3. **O segundo raio:** só quando o primeiro acha cenário, um raio do ombro (1,6 m acima dos pés) ao ponto. Se bate em algo antes do ponto, é erro: o gancho não prende e a mira não ganha o ponto.
4. **A mira da tela** acompanha o raio quando a câmera é empurrada por uma parede: o anel fica onde o raio se projeta, que é o centro da tela com a câmera livre. O raio não entra na conta da câmera empurrada: sai sempre de O.
5. **O cabo** continua saindo do ombro exibido: é a paralaxe que se vê.

## Consequências

- **O núcleo** ganha `Aim.origin`; `Movement.in_reach` ganha o yaw; `MovementConfig` e `MovementData` ganham o ombro. `MovePlan`, `MoveFacts`, `TickInput`, o replay e o `FighterState` não mudam.
- **O nó** lança dois raios por pedido com acerto, ambos só na máscara do mundo, sem o próprio RID. A sonda B roda de novo com O e com a quina, e a cena `gancho` da SyncTest mira a partir de O (`rede.md` §4 e §8).
- **A câmera** ganha o segundo braço, e o eixo ótico da câmera livre passa por O: um teste do rig liga a câmera ao núcleo.
- **O papel:** `movimento.md` ("Câmera" e "Gancho"), `visual-e-audio.md` ("O gancho na tela"), o glossário (ponto O, ombro da câmera, paralaxe da mira, segundo raio) e a vitrine "Kit de movimento v0" republicada (DEC-0019).
- **A DEC-0044** continua valendo no pedido de mira (§1), na cópia no `MovementData` (§3) e na sonda B (§4). Só o §2 e a linha "Ombro: centralizada" mudam.

## Revisitar se

- A sonda B ou a SyncTest acharem o raio diferente no tick refeito.
- O custo dos dois raios pesar com 16 lutadores (DEC-0004, regra 6).
- O lado cego à esquerda incomodar jogando: a troca de ombro (Q-41).
- A mira das armas de longe pedir outro ombro, outra margem ou um deslocamento para cima.
