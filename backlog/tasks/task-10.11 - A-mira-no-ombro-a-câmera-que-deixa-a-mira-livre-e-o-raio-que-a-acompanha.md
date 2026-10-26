---
id: TASK-10.11
title: 'A mira no ombro: a câmera que deixa a mira livre e o raio que a acompanha'
status: In Progress
assignee: []
created_date: '2026-10-26 14:09'
updated_date: '2026-10-26 14:55'
labels:
  - jogo
milestone: m-1
dependencies:
  - TASK-10.6
parent_task_id: TASK-10
ordinal: 17500
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
O Arthur jogou o gancho e achou a mira ruim: "o meu boneco ficava na frente da mira" (F-144 §1). A câmera está centralizada, 3,5 m atrás do ombro e na altura dele (`movimento.md`, "Câmera"), então o centro da tela passa pela cabeça da cápsula, e o corpo cobre o ponto que se quer ver (F-144 §3; os três prints). O `movimento.md` deixou o deslocamento para o ombro para a mira das armas de longe, e o gancho é a primeira coisa que se mira. O Arthur pediu esta filha antes da TASK-10.7 (F-145). A DEC-0044 já previa revisitar o raio da mira quando a câmera ganhasse o ombro ("Revisitar se"). Ao ver a vitrine, o Arthur disse que a câmera por cima do ombro, como no Fortnite, "faz muito mais sentido" (F-146).

### Perguntas em aberto
Nenhuma. As três foram respondidas em 26/10/2026 (F-147), com os números v0 na vitrine "A mira no ombro" (https://claude.ai/artifact/CZxqwAb7JjCJYFADfsYuw9):
- A câmera vai 0,8 m para a direita, na altura do pivô, e nada para cima: o pivô já está no ombro, e subir empurra os pés para fora da tela. O número tem sinal (negativo seria o ombro esquerdo).
- O raio sai do ponto O, na linha do centro da tela: os pés, mais 1,6 m para cima, mais 0,8 m para a direita do yaw. O núcleo calcula O do estado, do input e dos dados, e o servidor refaz sem câmera. O alcance de 3 a 25 m é medido de O.
- A troca de ombro fica para as armas de longe.

### Escolhas a confirmar
Confirmadas pelo Arthur (F-147):
1. A câmera por cima do ombro direito, a 0,8 m, e o raio saindo de O, calculado pelo núcleo. Muda a DEC-0044 §2 por uma DEC nova, pelo modo de plano.
2. O segundo raio, do ombro ao ponto: se bate em algo antes, o ponto não vale e a mira não ganha o ponto. Só roda quando o primeiro raio acha cenário.
3. A câmera cede em duas etapas, as duas só contra o cenário: para trás, como hoje, e depois para o lado, até 0,8 m. Cada etapa para 0,3 m antes da parede (margem v0). Na corrida com a parede à direita, o ombro desliza para o centro e a câmera fica a 3,5 m.

### Fora do escopo
- A mira das armas de longe (fase 2 em diante).
- A câmera que encurta contra uma parede entrando na conta do raio: o raio sai sempre de O, com a câmera livre. Na tela, a mira acompanha o raio quando a câmera é empurrada.
- A troca de ombro (esquerdo e direito): uma tecla e um campo do input, com as armas de longe (F-147).

### O que você vai aprender
- Por que os jogos em terceira pessoa tiram a câmera do centro.
- A paralaxe da mira: a câmera e o ombro olham para o mesmo lado, mas de lugares diferentes, e a mira marca a linha da câmera.
- O servidor sem câmera: a origem do raio como função pura dos pés, do yaw e de um número dos dados.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando o jogador mira o gancho, o próprio corpo não cobre a mira: a câmera fica por cima do ombro, e o centro da tela mostra o ponto que o raio vai achar (F-144; F-145)
- [ ] #2 Quando o raio da mira sai, ele passa pelo centro da tela, e o servidor refaz a mesma conta sem câmera, pelo estado, pelo input e pelos dados (DEC-0044)
- [ ] #3 Quando a sonda do raio e a SyncTest rodam com a câmera nova, dão zero divergência (rede.md §4 e §8)
- [ ] #4 Quando o Arthur joga o gancho nas torres e no pilar, a mira mostra onde ele vai prender, e o que ele sentiu vai para uma fonte (F-041)
- [ ] #5 Quando o raio da mira acha um ponto que o ombro não vê (uma quina entre o ombro e o ponto), o gancho não prende e a mira não ganha o ponto (F-147)
- [ ] #6 Quando uma parede fica à direita do corpo, como na corrida na parede, a câmera fica a 3,5 m e o ombro desliza para o centro, sem entrar na parede; quando a câmera é empurrada por uma parede, a mira na tela acompanha o raio (F-147)
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
