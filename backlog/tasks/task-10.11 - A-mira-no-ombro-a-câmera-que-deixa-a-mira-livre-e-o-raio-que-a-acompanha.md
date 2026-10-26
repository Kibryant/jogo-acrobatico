---
id: TASK-10.11
title: 'A mira no ombro: a câmera que deixa a mira livre e o raio que a acompanha'
status: To Refine
assignee: []
created_date: '2026-10-26 14:09'
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
O Arthur jogou o gancho e achou a mira ruim: "o meu boneco ficava na frente da mira" (F-144 §1). A câmera está centralizada, 3,5 m atrás do ombro e na altura dele (`movimento.md`, "Câmera"), então o centro da tela passa pela cabeça da cápsula, e o corpo cobre o ponto que se quer ver (F-144 §3; os três prints). O `movimento.md` deixou o deslocamento para o ombro para a mira das armas de longe, e o gancho é a primeira coisa que se mira. O Arthur pediu esta filha antes da TASK-10.7 (F-145). A DEC-0044 já previa revisitar o raio da mira quando a câmera ganhasse o ombro ("Revisitar se").

### Perguntas em aberto
- Quanto a câmera vai para o lado e para cima, e para que lado (o direito, como no Fortnite)? São números v0 do Claude, numa vitrine (DEC-0017; DEC-0019).
- De onde o raio sai, para passar pelo centro da tela e o servidor refazer a conta sem câmera (DEC-0044 §1 e §2)?
- Trocar de ombro entra agora ou fica para as armas de longe?

### Escolhas a confirmar
1. A câmera por cima do ombro direito, e o raio saindo de um ponto na linha do centro da tela, calculado pelo núcleo a partir dos pés, do yaw, do pitch e de um número dos dados. Padrão: sim. Muda a DEC-0044 por uma DEC nova e passa pelo modo de plano.

### Fora do escopo
- A mira das armas de longe (fase 2 em diante).
- A câmera que encurta contra uma parede entrando na conta do raio.

### O que você vai aprender
- Por que os jogos em terceira pessoa tiram a câmera do centro.
- A paralaxe da mira: a câmera e o ombro olham para o mesmo lado, mas de lugares diferentes.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando o jogador mira o gancho, o próprio corpo não cobre a mira: a câmera fica por cima do ombro, e o centro da tela mostra o ponto que o raio vai achar (F-144; F-145)
- [ ] #2 Quando o raio da mira sai, ele passa pelo centro da tela, e o servidor refaz a mesma conta sem câmera, pelo estado, pelo input e pelos dados (DEC-0044)
- [ ] #3 Quando a sonda do raio e a SyncTest rodam com a câmera nova, dão zero divergência (rede.md §4 e §8)
- [ ] #4 Quando o Arthur joga o gancho nas torres e no pilar, a mira mostra onde ele vai prender, e o que ele sentiu vai para uma fonte (F-041)
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
