---
revisado_em: 2026-10-02
fontes: [F-001, F-002, F-005, F-007]
---

# Glossário

A linguagem ubíqua do jogo (DEC-0004, regra 5): o mesmo termo na conversa, no documento, na task e no código. A coluna "No código" traz o nome em inglês (DEC-0008). Termo novo entra aqui na task que o cria.

## Simulação e rede

| Termo | O que é | Unidade | No código |
|---|---|---|---|
| Tick | Um passo fixo da simulação | tick | `tick` |
| Ticks por segundo | Quantos ticks a simulação roda por segundo: 30 ou 60 (Q-01) | tick/s | `tickrate` |
| Estado | Retrato da simulação num tick, feito de valores planos, sem objeto | — | `state` |
| Input | O que o jogador apertou num tick | — | `input` |
| Previsão | O cliente aplica o próprio input na hora, sem esperar o servidor | — | `prediction` |
| Rollback | Voltar ao estado confirmado e re-simular os ticks seguintes | — | `rollback` |
| Tick novo | Tick simulado pela primeira vez; só nele tocam som e efeito | — | `is_fresh` |
| Interpolação | Mostrar os outros jogadores suavizados entre dois estados recebidos | — | `interpolation` |
| Compensação de lag | O servidor volta no tempo para julgar um acerto do ponto de vista de quem atacou | ms | `lag_compensation` |
| Servidor autoritativo | O servidor decide o que aconteceu; o cliente só manda input | — | `server` |
| Simulação | O contexto que roda a cada tick: movimento e combate | — | `core/` |
| Meta | O contexto que roda fora do tick: salas, contas e ranking | — | — |

## Combate

| Termo | O que é | Unidade | No código |
|---|---|---|---|
| Preparação | A fase antes de o golpe acertar (startup, windup) | ms no design, ticks no código | `windup` |
| Ativo | A fase em que o golpe acerta | ms no design, ticks no código | `active` |
| Recuperação | A fase depois do golpe, em que o atacante fica vulnerável | ms no design, ticks no código | `recovery` |
| Golpe leve | Golpe rápido e barato | — | `light_attack` |
| Golpe carregado | Golpe segurado, mais lento e mais forte | — | `charged_attack` |
| Bloqueio | Defesa que gasta stamina a cada golpe recebido | — | `block` |
| Parry | Defesa com janela curta, que vence o golpe carregado | — | `parry` |
| Feint | Cancelar um golpe durante a preparação, pagando stamina | — | `feint` |
| Quebra de guarda | Golpe que atravessa o bloqueio | — | `guard_break` |
| Esquiva | Movimento curto com uma janela invulnerável | — | `dodge` |
| Stamina | A única barra de recurso, usada para tudo | pontos | `stamina` |
| Troca de arma | Passar de uma arma do equipamento para outra, com tempo fixo | ms no design, ticks no código | `weapon_swap` |
| Equipamento | Uma arma corpo a corpo, uma de distância e um utilitário | — | `loadout` |
| Hitbox | A área que acerta | m | `hitbox` |
| Hurtbox | A área que pode ser acertada | m | `hurtbox` |

## Movimento

| Termo | O que é | Unidade | No código |
|---|---|---|---|
| Corrida na parede | Correr pela parede por um tempo limitado | s | `wall_run` |
| Dash | Arrancada curta; se é a mesma coisa que a esquiva, o Desenho 1 decide | m, ms | `dash` |
| Gancho | Puxa o jogador até um ponto a até 25 m | m | `grapple` |
| No chão | Superestado: parado, correndo, golpes, defesa e troca de arma | — | `Grounded` |
| No ar | Superestado: pulo, parede, dash e gancho; ninguém se defende | — | `Airborne` |
