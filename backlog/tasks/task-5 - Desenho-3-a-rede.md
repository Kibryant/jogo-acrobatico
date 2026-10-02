---
id: TASK-5
title: 'Desenho 3: a rede'
status: To Refine
assignee: []
created_date: '2026-10-02 16:48'
updated_date: '2026-10-02 22:40'
labels:
  - rede
  - desenho
milestone: m-0
dependencies:
  - TASK-4
ordinal: 5000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
Terceira conversa da fase de desenho (DEC-0012). A rede é a parte mais cara de mudar depois. O netfox resolve previsão e rollback, mas a compensação de lag para espada e tiro não vem pronta, e há um bug aberto no 4.7.2 (F-005; DEC-0003).

### Perguntas em aberto
- Q-01: 30 ou 60 ticks por segundo.
- Q-02: o netfox no 4.7.2, o bug #659, release ou main.
- O input: o que vai nele, o buffer dos comandos de um tick e o `input_delay`.
- A previsão dos jogadores remotos e o efeito dela no parry (F-007 §6).
- A compensação de lag a favor de quem ataca, até ~220 ms, com o bloqueio julgado no tempo de quem defende (DEC-0011).
- A detecção do golpe de espada dentro do rollback (ShapeCast3D).
- Se a fase 1 já nasce no tick do netfox.

### Escolhas a confirmar
- netfox na main fixada num commit (DEC-0003). Padrão sugerido: esse, se a suíte dele passar no 4.7.2.

### Fora do escopo
- Hospedagem (Desenho 6, TASK-8).

### O que você vai aprender
- Previsão, reconciliação, rollback e compensação de lag funcionando de verdade, nos exemplos do netfox, com um servidor, dois clientes e lag simulado.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando a conversa termina, `docs/arquitetura/rede.md` existe, com o tick, o input, o rollback, a interpolação e a compensação de lag.
- [ ] #2 Quando a suíte do netfox roda no 4.7.2, o resultado fica registrado, e o netfox entra fixado num commit em `addons/` com uma DEC, ou a DEC registra o contorno.
- [ ] #3 Quando os exemplos do netfox rodam com um servidor, dois clientes e lag simulado, a medição de 30 e de 60 ticks fica registrada (Q-01).
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->

## Comments

<!-- COMMENTS:BEGIN -->
author: Claude
created: 2026-10-02 22:40
---
Entrada do Desenho 2 (TASK-4; DEC-0022), para este desenho provar com o netfox rodando no 4.7.2. Leitura feita no código-fonte, main, commit `cf5189d`:
- Hipótese 1: o caminho aninhado `:state:mode` funciona de ponta a ponta: grava, restaura e vai pela rede. O `snapshot.gd` lê com `get_indexed`, mas a serialização para a rede não foi lida.
- Hipótese 2: o contorno do transform (estático, transform, cinemático) do `rollback-caveats.md`, que o guia diz valer para o Jolt, deixa um lutador colidir com o outro na posição certa durante a re-simulação.
- Hipótese 3: guardar `on_floor` no estado substitui o movimento extra de velocidade zero que o guia sugere para o `is_on_floor()`.
- Evidência para a Q-01: com o arredondamento da DEC-0022, a janela de parry de 80 ms vira 2 ticks (67 ms, −17 %) a 30 ticks, e 5 ticks (83 ms, +4 %) a 60. O buffer de 150 ms vira 167 ms a 30 ticks e fica exato a 60.
---
<!-- COMMENTS:END -->
