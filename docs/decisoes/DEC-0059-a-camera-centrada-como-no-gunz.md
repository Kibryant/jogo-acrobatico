---
id: DEC-0059
titulo: A câmera centrada, como no GunZ — sem ombro e 0,6 m mais alta, o ponto O no eixo do corpo, e o ombro do corpo para o cabo e o segundo raio
data: 2026-11-18
status: aceita
decidido_por: Arthur (F-220)
fontes: [F-213, F-217, F-218, F-219, F-220]
substitui: DEC-0045
substituida_por:
---

# DEC-0059 — A câmera centrada, como no GunZ: sem ombro e 0,6 m mais alta, o ponto O no eixo do corpo, e o ombro do corpo para o cabo e o segundo raio

## Contexto

A DEC-0045 pôs a câmera 0,8 m à direita do pivô, como no Fortnite, para o corpo não cobrir a mira do gancho. Com a espada na mira (DEC-0057), o golpe sai do eixo do corpo rumo ao ponto da linha da mira a 2,0 m, e a quebra a 1,2 m (DEC-0058). Como a linha da mira passa ao lado do corpo, a mira só é exata nessa distância: o alvo a d metros pede a mira 0,8 × (1 − d ÷ c) à direita dele (`combate.md`, a tabela da lâmina; vitrine "A mira de lado").

- **Três sessões seguidas** com a mesma estranheza (Q-57): "parece que o golpe tá errado" (F-202 §1); depois, "cada vez mais eu tô achando estranho ser lateral", "parece que eu tenho que compensar a mira" (F-213). O replay mediu a compensação nos três golpes: 0,17 a 0,19 m à direita.
- **A pesquisa** olhou 11 jogos de espada (F-217). Nenhum garante "o que está na mira é o que o golpe pega" com a câmera de lado: eles travam no alvo, puxam o golpe, centralizam a câmera ou deixam o golpe seguir só a direção da câmera. O Mordhau, PvP de espada, centralizou a terceira pessoa em junho de 2020. O GunZ deixa a mira no centro com o boneco logo abaixo. O nosso ombro de 0,8 m é maior que todos os achados, de 0,43 a 0,55 m.
- **O experimento.** O Arthur escolheu experimentar a câmera centrada sem mudar o padrão (F-218), e o plano da TASK-12.15 pôs a câmera centrada atrás da opção `--camera=center` (F-219).
- **O teste.** Ele jogou as duas (F-220). Com a centrada, a mira ficou em média a menos de 0,07 m do alvo nos três golpes; com a do ombro, de 0,18 a 0,34 m à direita.

## Opções consideradas

1. **Manter a câmera no ombro** (DEC-0045). Ela deixa ver o lado direito, mas pede a compensação, que o Arthur sente como erro.
2. **O ombro a 0,4 m.** O erro cai pela metade, mas a compensação continua. Nenhum jogo de espada PvP usa um meio-termo documentado.
3. **A câmera centrada e mais alta, como no GunZ.** O erro vai a zero em qualquer distância. O boneco fica embaixo da mira, como no GunZ e no Mordhau depois de 2020. Era a opção 2 da DEC-0045, "o jeito do GunZ", com os pés a 55 px da borda de baixo.
4. **Centrar só no golpe.** A câmera anda a cada golpe, e nenhum PvP faz isso.
5. **A mão mirar a distância de quem está na mira.** Esse é o padrão dos jogos de tiro, e nenhum jogo de espada faz. De perto, o corpo ainda vira até 63° no golpe.
6. **Puxar o golpe para o alvo.** É ajuda de mira, e a mira deixa de ser habilidade.

## Decisão

Escolha do Arthur, depois de jogar as duas câmeras (F-220): "Vamos deixar o centralizado, o GANZI é centralizado. Vamos usar o GANZI. Ele é centralizado. Vamos tentar... E aí a gente vê depois no futuro"; "pra mim parece mais real e suave o centralizado". Ele chamou a escolha de "flip coin", no sentido de que só jogando mais vai saber, e pediu para rever no futuro. Essa ressalva está em "Revisitar se".

1. **A câmera padrão** fica centrada:
   - ombro 0;
   - subida de 0,6 m, com o pivô a 2,2 m dos pés;
   - distância de 3,5 m, campo de visão de 70° e a sensibilidade das opções, como antes.

   A câmera no ombro fica como opção do Sozinho, `--camera=shoulder`, para comparar. A troca do padrão nos dados e no lançamento é a TASK-12.16.
2. **O ponto O** fica no eixo do corpo, nos pés mais `aim_height_m` mais `aim_rise_m` para cima (1,6 + 0,6 = 2,2 m), calculado pelo núcleo em `Movement.aim_origin` (TASK-12.15). Dele saem:
   - o raio da mira;
   - a mira da tela;
   - o alcance do gancho, de 3 a 25 m.

   O ombro (`aim_side_m`) e a subida são cópias da câmera no `MovementData`, guardadas por teste (DEC-0044 §3).
3. **O segundo raio** continua saindo do ombro do corpo, 1,6 m acima dos pés, sem a subida, só quando o primeiro acha cenário. Se bate em algo antes do ponto, é erro (o §3 da DEC-0045, repetido aqui).
4. **A mira da tela** acompanha o raio quando uma parede empurra a câmera (o §4 da DEC-0045, repetido aqui).
5. **O cabo** continua saindo do ombro exibido, a 1,6 m (o §5 da DEC-0045, repetido aqui).
6. **A colisão da câmera** continua em duas etapas, só contra o cenário, com margem de 0,3 m. Sem ombro, a etapa do lado não tem comprimento e não colide (TASK-12.15).

## Consequências

- **O golpe sai para onde a câmera olha,** sem compensação para o lado, em qualquer distância: `Aim.swing_yaw` com ombro 0 dá a própria direção da câmera. O golpe do boneco também vem reto (DEC-0057 §4).
- **A mão do agarrão some atrás do corpo,** vista da câmera centrada (F-220). Antes do manequim (TASK-12.9), a TASK-12.16 decide como deixá-la visível.
- **De perto, a mira fica acima do boneco.** O Arthur baixou a mira até ele (F-220), mas o golpe não usa a altura: só o lado importa (`aim.gd`, "The pitch does not enter"). A altura só vale no gancho.
- **Três perguntas abertas perdem o objeto:**
  - a troca de ombro (Q-41), até as armas de longe pedirem um ombro;
  - o ponto O dentro da parede na corrida (Q-42);
  - o pulo de lado da câmera na parede (Q-43).
- **Os replays** gravados com o ombro continuam tocando com os números do próprio cabeçalho, e o `--watch` monta a câmera com o ombro e a subida que estão nele (TASK-12.15).
- **A Q-57 se responde** com esta DEC.

## Revisitar se

- Os amigos estranharem a câmera centrada no teste da fase (TASK-12.13), ou alguém com experiência em jogos de espada der o aval contrário, que o Arthur pediu (F-220).
- O manequim e as animações (TASK-12.9; TASK-12.10) mudarem a leitura dos golpes de perto, para melhor ou para pior.
- As armas de longe pedirem um ombro para mirar (Q-41).
- O corpo cobrir o alvo de perto de um jeito que atrapalhe, e a subida precisar de outro número.
