---
id: DEC-0026
titulo: A rede — o input, o oponente no passado, a compensação de lag, a detecção do golpe, a fase 1 no tick e a Main
data: 2026-10-04
status: aceita
decidido_por: Arthur
fontes: [F-001, F-005, F-007, F-023, F-026, F-027, F-028, F-029, F-032, F-033, F-036]
substitui:
substituida_por: DEC-0031, só a frase do §2 que dá o atraso de visão pelo get_last_known_state()
---

> ⚠️ Em parte substituída por DEC-0031 em 2026-10-08: a frase do §2 que dá o atraso de visão pelo `get_last_known_state()` não é a regra atual; o atraso vem do tick que o próprio estado carrega. O resto desta DEC continua valendo.

# DEC-0026 — A rede: o input, o oponente no passado, a compensação de lag, a detecção do golpe, a fase 1 no tick e a Main

## Contexto

A rodada 2 do Desenho 3 (TASK-5) desenhou seis peças: o input, o oponente no passado, a compensação de lag, a detecção do golpe, a fase 1 no tick e a `Main`. O código da compensação e da detecção nasce com a espada: local na fase 2, em rede na fase 3 (F-023 §3).

A rodada 1 mostrou o problema central. No relógio do servidor, que é o que o netfox faz sozinho, ninguém defende por reação com ping de 100 ms ou mais, a 30 ou a 60 ticks (F-028 §3). A DEC-0011 já dava a direção: "o tiro é julgado a favor de quem ataca, até ~220 ms. O bloqueio é julgado no tempo de quem defende". O estudo pedia "compensação de lag até ~220 ms pra tiro e ~150–200 ms pra espada, com bloqueio validado no tempo de quem defende" (F-001).

O que o netfox oferece, lido no commit `cf5189d`:

- **O input vale no tick em que foi apertado.** O servidor volta no tempo quando um input chega atrasado (`addons/netfox/rollback/network-rollback.gd`, `_rollback`).
- **Sem previsão, um lutador não é simulado num tick cujo input ainda não chegou** (`addons/netfox/servers/rollback-simulation-server.gd`, `_get_nodes_to_simulate`). O servidor só grava e manda o estado simulado com input (`addons/netfox/servers/network-history-server.gd`, `_record_rollback_state`; `addons/netfox/servers/network-synchronization-server.gd`, `_make_peer_snapshot`).
- **O cliente sabe de qual tick é o último estado que recebeu de cada lutador** (`addons/netfox/rollback/rollback-synchronizer.gd`, `get_last_known_state`).
- **O input mais velho que o histórico é descartado, e o input recebido nunca substitui um tick que já está guardado** (`network-history-server.gd`, `_merge_history` e `_merge_snapshot`).
- **O broadcast de input vem desligado por padrão** (`network-synchronization-server.gd`).
- **O comando de um toque é guardado entre os frames e consumido depois de cada tick,** e vale no máximo um tick (`examples/snippets/input-gathering-tutorial/one-off-input.gd`; `docs/netfox/tutorials/input-gathering-tips-and-tricks.md`).
- **A previsão de input da main está quebrada** (#613, aberta em 04/10/2026; F-036 §1). O netfox não tem componente de corpo a corpo (F-005 §4).

Na rodada 2, o Claude mostrou como três jogos escolhem quem paga o atraso (F-032, contexto):

- **CoD:** quem leva o tiro.
- **For Honor:** quem defende, com 33 ms de atraso em todo input de ataque, menos o parry (Ubisoft, 2018).
- **O nosso:** cada um tem razão sobre o que fez na própria tela, até um teto.

O modelo, calibrado com o bot de reação de gente e o atraso medido a 60 ticks, dá, com ping 100: 8 % de parry no relógio do servidor, 28 % com o atraso do For Honor e 69 % no tempo de quem defende (F-032, contexto). Ele bate com o Arthur a 60 ticks: 72 % sem lag e 13 % com ping 100, no relógio do servidor (F-027 §3).

## Opções consideradas

**Quem paga o atraso**

1. **O relógio do servidor**, o netfox sozinho: quem defende paga o atraso de ponta a ponta inteiro (F-028).
2. **O jeito do For Honor:** um relógio só, 33 ms de atraso nos ataques e golpes mais longos, o que muda o ritmo do combate.
3. **Cada um tem razão sobre a própria tela, até um teto:** a escolhida, a direção da DEC-0011 (F-032 §3).

**A posição na espada** (F-032 §2)

1. **A tela de quem ataca:** a escolhida.
2. **O servidor:** divide o erro entre os dois, e nenhuma tela tem razão.
3. **A tela de quem defende:** quem ataca precisa mirar à frente de quem corre.

**O oponente:** no passado, sem previsão, o escolhido; ou com previsão de input, quebrada na main (#613).

**A detecção do golpe:** forma no núcleo, a escolhida; ou o `ShapeCast3D` do Godot (F-007 §8).

**A fase 1:** no tick do netfox, a escolhida; ou no `_physics_process`, portada depois (F-007 §2).

## Decisão

Na pergunta da posição, o Arthur escolheu "A de quem ataca (Recomendado)". Nas outras cinco escolhas e no teto de 200 ms, escolheu "Fechar com os padrões (Recomendado)" (F-032 §2 e §3).

### 1. O input

O input é o pedido do jogador para o tick, nunca o resultado. O cliente não escreve vida nem munição (F-005 §4).

| Campo | O que é | Desde |
|---|---|---|
| `move` | Para onde andar, até 1, relativo à câmera | esqueleto andante |
| `yaw` | Para onde a câmera olha | esqueleto andante |
| `jump` | Um toque | esqueleto andante |
| `pitch` | A mira na vertical, para o gancho | fase 1 |
| `dash`, `grapple` | Um toque | fase 1 |
| `light`, `parry`, `dodge`, `feint`, `swap` | Um toque | fase 2 |
| `heavy`, `block` | Segurar | fase 2 |
| `view_lag` | Quão velho estava o oponente na tela, em ticks | fase 3 |

- **O comando de um toque** segue o padrão do netfox: o aperto fica guardado entre os frames e é consumido depois de cada tick, então vale no máximo um tick. O `move` segue o padrão do netfox para entrada contínua: a média das amostras dos frames do tick (`docs/netfox/tutorials/input-gathering-tips-and-tricks.md`). Como o `yaw` e o `pitch` entram no tick fica para a TASK-9.
- **A configuração do netfox fica no padrão,** guardada pelo teste de configurações:
  - `input_delay` 0;
  - `input_redundancy` 3;
  - `enable_input_broadcast` desligado;
  - `history_limit` de 64 ticks, 1,07 s a 60 ticks.

### 2. O oponente no passado

- Nenhum lutador tem previsão de input: o `enable_prediction` do `RollbackSynchronizer` fica desligado.
- O oponente aparece no último estado confirmado que chegou, suavizado pelo `TickInterpolator`.
- O atraso de visão é o tick atual menos o `get_last_known_state()` do oponente.

### 3. A compensação de lag

Cada um tem razão sobre o que fez na própria tela, até o teto de 200 ms, que são 12 ticks a 60.

- **O contato, a posição, é decidido na tela de quem ataca.**
  - O tick de quem ataca testa a lâmina contra a pose de quem defende como ele a via, `view_lag` ticks atrás, limitado ao teto.
  - O contato fica gravado no estado de quem ataca, como um carimbo: o tick, o alvo e o golpe.
  - Um contato nunca é desfeito.
- **A defesa por tempo é decidida na tela de quem defende.**
  - O tick de quem defende resolve o contato quando ele aparece na tela dele, isto é, quando o tick do contato fica a até `view_lag` ticks atrás.
  - Nesse tick valem as defesas de tempo de quem defende, julgadas como ele viu:
    - o parry, com o aperto traduzido para o tempo de quem ataca;
    - o bloqueio levantado;
    - a invulnerabilidade da esquiva;
    - no ar, ninguém se defende.
  - O resultado vai para o estado de quem defende. Quem ataca lê esse resultado e aplica a própria consequência no tick seguinte.
- **Um lutador escreve só o próprio estado** e lê o dos outros numa foto do tick, tirada no `after_prepare_tick`. Assim a ordem dos nós na árvore não muda o resultado.
- **Por que é viável no netfox:**
  - o servidor só simula o tick de quem defende depois que o input daquele tick chega, então julga a defesa sabendo tudo o que ele fez até ali, sem desfazer nada;
  - no cliente de quem defende, o oponente na tela é exatamente o passado que a regra usa, e a previsão dele bate com o servidor.
- **O servidor guarda um histórico de poses** dos lutadores dos últimos 12 ticks (posição, direção, ação e o carimbo dela), gravado no `on_record_tick`, para o teste do contato contra a pose passada. No cliente de quem ataca, essa pose é a que está na tela.
- **O teto de 200 ms** é um número v0, fechado pelo Claude (DEC-0017) e registrado no `combate.md`.
  - O estudo propõe de 150 a 200 ms para a espada (F-001).
  - A 60 ticks, ver o outro levou 126 ms com ping 100, com p90 de 135 (F-026 §2).
  - Acima do teto, quem tem o atraso paga o excesso.
- **O custo é de quem ataca:** ele descobre o resultado depois do contato mais o atraso de visão de quem defende e da viagem. Com ping 100, são uns 240 ms; no relógio do servidor, seriam uns 120 (F-032, contexto).
- **Contra trapaça, já agora:**
  - o teto;
  - o netfox não deixa reescrever input passado e descarta o mais velho que o histórico.
- **Fica para a fase 3 (Q-17):** conferir o `view_lag` com o ping medido pelo servidor, e a regra contra o lag switch de quem ataca.
- **As fases:**
  - a fase 2, local, escreve as regras no núcleo com `view_lag` zero; sem lag, o tempo de quem defende é o relógio do servidor;
  - a fase 3 preenche o `view_lag` e o histórico de poses;
  - o tiro com projétil segue a favor de quem ataca, da fase 3 em diante (DEC-0011), com as mesmas peças;
  - o 4v4, com um atraso diferente por atacante, é a Q-18.

### 4. A detecção do golpe

- **A conta é do núcleo, com formas simples:** a lâmina como um segmento com raio, contra a cápsula do corpo (1,8 m × 0,35 m de raio; `movimento.md`). É uma função pura, testada com tabela (DEC-0004, regra 4).
- **O teste usa a fatia varrida em cada tick:** a área que a lâmina percorre do começo ao fim do tick. Assim, ela não pula o corpo entre dois ticks.
- **O alcance, o arco e as formas** são dados do golpe, referenciados por ID (DEC-0004, regra 3). Os números saem na fase 2.
- **Parede no meio não bloqueia no v0.** Se precisar, o adaptador pergunta ao motor com um raio e passa a resposta como um fato do tick, como os `MoveFacts`.
- O `ShapeCast3D` não entra no teste do golpe.

### 5. A fase 1 no tick

- O movimento da fase 1 nasce no tick do netfox e é jogado no modo "Sozinho" da `Main`: o par offline do Godot, em que o PC do jogador é o próprio servidor, sem rede e sem rollback.
- A SyncTest, no CI, cobre cada manobra nova (parede, gancho, dash) desde o dia em que ela nasce (DEC-0025).
- De tempos em tempos, o mesmo movimento roda com 2 clientes e o simulador do netfox, para ver a correção com lag.

### 6. A Main

A cena de entrada `Main` olha como o jogo foi aberto:

| Como abre | Papel |
|---|---|
| `--server` (com `--port=N`), ou o build exportado como servidor dedicado, que liga a feature `dedicated_server` | Servidor dedicado: sem tela e sem lutador próprio; cria um lutador para cada cliente que entra |
| `--connect=host:porta` | Cliente |
| Sem argumento | Sozinho, no par offline |

- Depois, ela inicia o relógio do netfox e cria a `Match` com a configuração, passada na mão (DEC-0022).
- **Fechar limpo faz parte da Main:**
  - parar o relógio do netfox;
  - fechar a conexão;
  - soltar a partida;
  - só então sair.
- A sonda caía com falha de segmentação ao fechar (F-026 §4); o esqueleto andante confere a saída com código 0.
- O `netfox/autoconnect/enabled` fica desligado (DEC-0023).

## Consequências

- **A DEC-0011 fica completa na validação de acerto da espada.** A do tiro segue como direção, para a fase 3.
- **A base acompanha:**
  - o `docs/arquitetura/rede.md` guarda o detalhe, com cada comportamento do netfox citado pelo arquivo e pelo commit;
  - o `combate.md` ganha a seção "A rede no combate", com o teto e as duas regras;
  - o `roteiro.md` registra a fase 1 no tick;
  - o glossário ganha os termos novos;
  - a Q-17 e a Q-18 entram nas pendências, e a Q-09 é atualizada.
- **O teste de configurações** guarda a configuração do netfox do item 1.
- **O código:**
  - o esqueleto andante (TASK-9) traz os modos da `Main`, o padrão do input, o oponente sem previsão e o fechamento limpo;
  - a fase 2 escreve as regras do contato e da defesa no núcleo, com `view_lag` zero;
  - a fase 3 acrescenta o `view_lag`, o histórico de poses e os testes com rede.

## Revisitar se

- Na fase 3, a espera de quem ataca, uns 240 ms com ping 100, se sentir ruim. O botão de reserva é o atraso de ataque do For Honor, que encurta essa espera.
- Levar o golpe depois de sair do alcance correndo se sentir injusto para quem defende.
- O netfox consertar o #613, e o oponente previsto ficar interessante.
- Aparecer trapaça com o `view_lag` ou o lag switch (Q-17).
- O 4v4 chegar (Q-18).
