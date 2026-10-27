---
id: TASK-12.8
title: 'O bot que luta: a árvore, a reação sorteada e os três níveis'
status: To Refine
assignee: []
created_date: '2026-10-27 22:02'
labels:
  - jogo
milestone: m-2
dependencies:
  - TASK-12.7
parent_task_id: TASK-12
ordinal: 35000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
O primeiro oponente. Ele só produz input e só lê o que o jogador vê; o atraso de percepção sorteado uma vez por evento e a taxa de erro por nível o fazem parecer gente (`partida.md`, "O bot que luta"; F-029; F-173 §3). É o duelo de verdade: a Q-34 (dash no ar), a Q-44 (escalada), a Q-50 (anti-fuga) e a Q-51 (a arena) voltam aqui, com o Arthur jogando.

### Perguntas em aberto
Nenhuma: os níveis estão no `partida.md`.

### Escolhas a confirmar
- A escolha do nível na tela do Sozinho. Padrão sugerido: os três, com o 2 selecionado.

### Fora do escopo
- O bot que usa a parede e o gancho. O bot em rede (fase 3).

### O que você vai aprender
- Uma árvore de comportamento em dados: seletor, sequência, condição, ação, e por que ela devolve input e nunca mexe no estado.
- Determinismo por hash: por que o gerador do Godot não serve ao núcleo (F-173 §3), e como o replay reproduz o bot.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando o bot entra no duelo, ele chega a 2,5 m do oponente, dá a volta e mistura leve, carregado, quebra e finta por pesos; cada aperto dele passa pelo mesmo input de um jogador.
- [ ] #2 Quando o golpe do oponente entra na preparação, o bot sorteia uma vez o atraso de percepção pelo nível (450 ± 90, 330 ± 60 ou 260 ± 40 ms, mínimo 180) e só reage no tick sorteado; com a taxa de erro do nível, ele ignora o golpe ou escolhe a resposta errada.
- [ ] #3 Quando o bot reage a um carregado, ele apara contando o tempo, com erro de ± 30 ms; a uma quebra, responde com o tech; a um leve, só bloqueia por palpite, com peso baixo.
- [ ] #4 Quando o bot lê o estado, ele lê só o modo, a ação, a posição e o tick em que o golpe começou: nunca o input do jogador nem o que vai acontecer.
- [ ] #5 Quando um replay de um duelo contra o bot é tocado de novo, o bot faz exatamente o mesmo: o sorteio é um hash de (semente da partida, bot, tick, contador).
- [ ] #6 Quando 60 s de duelo rodam sem tela em cada nível, o resumo imprime a taxa de parry, de bloqueio e de tech do bot, e o nível 3 apara mais que o 1.
- [ ] #7 Quando o Arthur joga 15 minutos de duelo contra o bot, ele diz quem acertou, quem defendeu e por quê em cada troca, e responde pelas Q-34, Q-44, Q-50 e Q-51 jogando.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
