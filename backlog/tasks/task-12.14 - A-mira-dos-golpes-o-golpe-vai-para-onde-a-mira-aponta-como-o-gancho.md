---
id: TASK-12.14
title: 'A mira dos golpes: o golpe vai para onde a mira aponta, como o gancho'
status: In Progress
assignee: []
created_date: '2026-10-30 14:43'
updated_date: '2026-11-14 17:21'
labels:
  - jogo
milestone: m-2
dependencies:
  - TASK-12.3
parent_task_id: TASK-12
ordinal: 30500
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
Jogando a TASK-12.3, o Arthur errou 11 carregados de lado. Em todos, o boneco estava à direita do corte, em média 0,57 m (F-196 §1). Nas palavras dele: "Eu tive que compensar a mira pra eu acertar o golpe" (F-196 §2).

É a paralaxe da mira da DEC-0045. A câmera fica 0,8 m à direita do corpo, e o golpe saía do eixo do corpo no yaw da câmera, paralelo à linha da mira. Com a mira em cima do boneco, o carregado nunca pegava: o corte passava 0,80 m ao lado da mira, e a folga é de 0,43 m (F-198, contexto). O leve, com 120° de arco, escondia o erro. O raio do gancho não tem o problema, porque sai do próprio ponto O; a lâmina sai da mão, então só cruza a linha da mira num ponto, a convergência (DEC-0057).

O Arthur mandou a correção para esta task, antes da quebra de guarda (F-197), e escolheu o ponto fixo a 2,0 m (F-198 §2; DEC-0057). As regras estão no `combate.md`, "A espada na mira".

### Perguntas em aberto
Nenhuma. O ponto é fixo, a 2,0 m do eixo do corpo, onde chega a ponta da lâmina; não é o corpo do outro nem um raio do motor (F-198 §2; DEC-0057). O corpo olha para a direção do golpe desde a preparação, pela regra que já mandava o corpo olhar para o golpe (DEC-0057 §3).

### Escolhas a confirmar
Confirmadas pelo Arthur:
- a regra vale para o leve e o carregado, e o boneco, e depois o bot da TASK-12.8, mira como gente (F-197 §1, a opção escolhida);
- o ponto fixo a 2,0 m (F-198 §2).

Ele mandou começar antes de a conferência da convergência bater (F-199 §2); a explicação vai de novo, nomeando a ideia que atrapalhou (DEC-0043 §3).

### Fora do escopo
- A tecla do carregado no mouse (Q-56).
- O castigo do parry (Q-55), que se julga de novo depois desta task.
- O ponto da quebra de guarda, que agarra até 1,2 m: a TASK-12.4 decide (DEC-0057, "Revisitar se").

### O que você vai aprender
- A convergência: a espada e a mira se cruzam num ponto só, como os dois olhos no dedo. Perto do ponto, a lâmina passa dentro da folga; colado no corpo, ela ainda não chegou à linha da mira.
- A paralaxe outra vez: a regra do núcleo e a mira da tela precisam falar do mesmo ponto, e um teste de núcleo não vê a câmera.
- Por que o bot mira como gente: ele só produz input, e o input de quem joga é a mira, não a direção do corpo.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando o jogador põe a mira no eixo do boneco parado no mesmo chão, de 1,2 m a 2,3 m de centro a centro, e dá o carregado, o corte pega sem compensar a mira; com o boneco a 1,0 m ou a 2,5 m, ele erra (combate.md, "A espada na mira").
- [ ] #2 Quando o jogador dá o leve com a mira no eixo do boneco, de 1,0 m a 2,3 m, o arco pega, e a direção do leve é a mesma do carregado: o yaw da câmera menos asen(ombro / convergência), 23,58° para a direita com o v0.
- [ ] #3 Quando um golpe está na preparação, o corpo olha para a direção do golpe, e não para a câmera; do primeiro tick ativo ao fim, a direção e o corpo ficam onde estavam, por mais que a câmera gire.
- [ ] #4 Quando o boneco dá o carregado contra quem está parado à frente dele, de 1,2 m a 2,3 m, o corte pega, porque o boneco mira como gente: a linha da mira dele, saindo do ponto O dele, passa pelo eixo de quem joga.
- [ ] #5 Quando a convergência muda no combat_v0.tres, a direção do golpe muda sem tocar no código; um dado com a convergência zero ou negativa é recusado pela validação, que diz por quê; e um teste prova que a convergência do v0 é maior que o ombro do movement_v0.tres.
- [ ] #6 Quando a cena roda na SyncTest com o rollback de 7 ticks, nenhum campo diverge.
- [ ] #7 Quando o Arthur joga, os carregados que erram não erram mais de um lado só, e o replay mede o lado, como na F-196 §1.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
