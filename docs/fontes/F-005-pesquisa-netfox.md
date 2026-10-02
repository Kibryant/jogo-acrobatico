---
id: F-005
titulo: Pesquisa: netfox, verificada em 02/10/2026
recebido_em: 2026-10-02
como: Relatório final de um agente de pesquisa do Claude Code (general-purpose), pedido na sessão do my-brain de 02/10/2026. Texto como chegou; cada afirmação traz o link da fonte, e o que não foi confirmado está marcado.
status: vigente
substituida_por:
---

# netfox: briefing técnico (verificado em 02/10/2026)

## 1. O que é, quem mantém, maturidade
- É um conjunto de addons em GDScript para multiplayer responsivo no Godot 4. Oferece tempo sincronizado entre máquinas, client-server, interpolação, CSP (client-side prediction) com server reconciliation e integração com o noray ([README](https://github.com/foxssake/netfox/blob/main/README.md)).
- Quem mantém é Tamás Gálffy (@elementbound), da Fox's Sake Studio. Licença MIT ([plugin.cfg](https://github.com/foxssake/netfox/blob/main/addons/netfox/plugin.cfg), [hosting](https://foxssake.github.io/netfox/latest/hosting/)).
- Linha do tempo: repo criado em 07/2023 e v1.0.0 lançada em 23/11/2023. São 12 releases, e a última é a v1.35.3, de 23/11/2025 ([API](https://api.github.com/repos/foxssake/netfox), [v1.35.3](https://github.com/foxssake/netfox/releases/tag/v1.35.3)).
- Comunidade:
  - 1.109 stars, 87 forks, 32 issues e 16 PRs abertos ([API](https://api.github.com/repos/foxssake/netfox)).
  - Cerca de 37 contribuidores ([contrib.rocks](https://contrib.rocks/image?repo=foxssake/netfox)).
  - Discord com cerca de 585 membros ([invite API](https://discord.com/api/v9/invites/xWGh4GskG5?with_counts=true)).
- Há 5 jogos na Steam feitos com netfox, todos de pequena escala. Kick and Hide, por exemplo, é para 4 a 6 jogadores ([Made with netfox](https://foxssake.github.io/netfox/latest/made-with-netfox/)).
- Existe uma v2 planejada, com breaking changes e exigindo o Godot mais novo, mas o próprio mantenedor diz que "work is currently not being done" ([#441](https://github.com/foxssake/netfox/issues/441)).

## 2. Addons
- **netfox** (core): NetworkTime, NetworkRollback, RollbackSynchronizer (RBS), StateSynchronizer, TickInterpolator, NetworkEvents e RewindableAction. Só na main também existem PredictiveSynchronizer, Schemas, NetworkCommandServer e a arquitetura interna de "servers" ([docs](https://foxssake.github.io/netfox/latest/), [compare](https://github.com/foxssake/netfox/compare/v1.35.3...main)).
- **netfox.noray**: os autoloads `Noray` e `PacketHandshake` ([guia](https://foxssake.github.io/netfox/latest/netfox.noray/guides/noray/)).
- **netfox.extras**: BaseNetInput, NetworkWeapon (2D/3D/Hitscan3D), RewindableStateMachine, RewindableRandomNumberGenerator, NetworkSimulator, WindowTiler e física (PhysicsDriver, NetworkRigidBody2D/3D) ([docs](https://foxssake.github.io/netfox/latest/)).
- **netfox.internals**: utilitários, entra como dependência ([README](https://github.com/foxssake/netfox/blob/main/README.md)).
- O repo também traz `nohub.gd` (cliente de lobby), `trimsock.gd` e `vest` (testes), que não fazem parte do netfox ([addons](https://github.com/foxssake/netfox/tree/main/addons)).
- Para C# existe o NetfoxSharp, que acompanha só os releases ([FAQ](https://foxssake.github.io/netfox/latest/faq/)).

## 3. Modelo mental (analogia web: optimistic update + event sourcing + git rebase)
- **Tick** é um relógio lógico compartilhado, independente do FPS (default 30 tps).
  - No cliente, `NetworkTime.start()` sincroniza com o host antes de começar.
  - O loop é `before_tick_loop → (before_tick, on_tick, after_tick)×N → after_tick_loop` ([NetworkTime](https://foxssake.github.io/netfox/latest/netfox/guides/network-time/), [netfox.gd](https://github.com/foxssake/netfox/blob/main/addons/netfox/netfox.gd)).
- **Input** é uma action carimbada com o tick.
  - Fica num nó separado, owned pelo jogador. O `_gather()` roda antes de cada tick loop e só na authority ([tutorial](https://foxssake.github.io/netfox/latest/netfox/tutorials/responsive-player-movement/)).
  - Vai unreliable, com redundância de 3 ticks; `input_delay` é opcional ([NetworkRollback](https://foxssake.github.io/netfox/latest/netfox/guides/network-rollback/)).
  - Gotcha: `is_action_just_pressed` não bate com os ticks. Dash, pulo e tiro precisam de buffer ([tips](https://foxssake.github.io/netfox/latest/netfox/tutorials/input-gathering-tips-and-tricks/)).
- **State** é um snapshot por tick, com histórico de 64 ticks. Os nós de state são owned pelo servidor ([RBS](https://foxssake.github.io/netfox/latest/netfox/nodes/rollback-synchronizer/)).
- **`_rollback_tick(delta, tick, is_fresh)`** funciona como um reducer: (state[t], input[t]) → state[t+1], igual no servidor e nos clientes. Som e VFX ficam atrás de `is_fresh` ou de RewindableAction.
- **Rollback e reconciliação**:
  - O cliente prevê na hora. Quando chega o state do tick T, ele volta a T e resimula até o tick atual, como um rebase.
  - O servidor também faz rollback: um input atrasado para T faz o mundo voltar a T e ser resimulado ([NetworkRollback](https://foxssake.github.io/netfox/latest/netfox/guides/network-rollback/)).
  - Nós sem input não são simulados; predição de input é opt-in ([predicting](https://foxssake.github.io/netfox/latest/netfox/tutorials/predicting-input/)).
- **Quando usar cada nó** ([FAQ](https://foxssake.github.io/netfox/latest/faq/), [TickInterpolator](https://foxssake.github.io/netfox/latest/netfox/nodes/tick-interpolator/)):
  - RBS: jogador, ou qualquer coisa que interage dentro do rollback.
  - StateSynchronizer: NPCs, sem rollback.
  - TickInterpolator: suaviza o visual entre ticks; fica desligado em headless.
  - PredictiveSynchronizer: rollback só local, para projéteis.
  - NetworkEvents: sinais de server start/stop.
- **Diferença para o nativo**: o MultiplayerSynchronizer só replica propriedades da authority, sem relógio, histórico ou predição ([Godot](https://docs.godotengine.org/en/stable/classes/class_multiplayersynchronizer.html)). O netfox roda em cima da mesma MultiplayerAPI/RPC e convive com o MultiplayerSpawner ([FAQ](https://foxssake.github.io/netfox/latest/faq/)).

## 4. Lag compensation, autoridade, anti-cheat
- **O que existe**: CSP mais reexecução do input no tick em que ele foi dado ([#431](https://github.com/foxssake/netfox/issues/431)).
- **O que não existe**: "favor the shooter".
  - O FAQ diz que é "not trivial" ([FAQ](https://foxssake.github.io/netfox/latest/faq/)).
  - Dá para fazer à mão com `NetworkRollback.on_prepare_tick.emit(tick)` ou `notify_resimulation_start(tick)`, dentro do `history_limit` ([#232](https://github.com/foxssake/netfox/issues/232)).
  - Inferência minha: o atirador vê o alvo atrasado, mas o servidor checa a posição real do alvo no tick do tiro.
- **Hitscan**:
  - `NetworkWeaponHitscan3D` faz o raycast local, no estado físico atual, e `_is_reconcilable` sempre devolve `true` ([src](https://github.com/foxssake/netfox/blob/main/addons/netfox.extras/weapon/network-weapon-hitscan-3d.gd)).
  - O exemplo `multiplayer-fps` dispara em `on_tick`, então não há rewind nenhum ([src](https://github.com/foxssake/netfox/blob/main/examples/multiplayer-fps/scripts/player-weapon.gd)).
  - O `rollback-fps` dispara dentro do rollback, com RewindableAction, que é experimental ([exemplo](https://github.com/foxssake/netfox/tree/main/examples/rollback-fps), [doc](https://foxssake.github.io/netfox/latest/netfox/nodes/rewindable-action/)).
- **Projéteis**:
  - `NetworkWeapon3D` spawna local e manda RPC com o tick do disparo.
  - O servidor valida com `_can_peer_use`, `_can_fire` e `_is_reconcilable`/`distance_threshold`; `get_fired_tick()` serve para catch-up ([doc](https://foxssake.github.io/netfox/latest/netfox.extras/guides/network-weapon/)).
  - Há um bug aberto ([#519](https://github.com/foxssake/netfox/issues/519)).
- **Melee**: não há componente ([weapon/](https://github.com/foxssake/netfox/tree/main/addons/netfox.extras/weapon)). O caminho é ShapeCast3D com `force_shapecast_update()` dentro do rollback ([caveats](https://foxssake.github.io/netfox/latest/netfox/tutorials/rollback-caveats/)). Esse padrão não aparece em exemplo oficial: não confirmado.
- **Autoridade**: "server" é simplesmente o dono do nó, e o NetworkTime sempre usa o host como referência. P2P não é suportado oficialmente ([ownership](https://foxssake.github.io/netfox/latest/netfox/concepts/servers-clients-ownership/)).
- **Anti-cheat**:
  - O cliente não escreve HP nem munição ([FAQ](https://foxssake.github.io/netfox/latest/faq/)).
  - Desligar input broadcast reduz a superfície de ataque. Na v1.35.3 o default do nó é `true` ([src](https://github.com/foxssake/netfox/blob/v1.35.3/addons/netfox/rollback/rollback-synchronizer.gd)).
  - Visibility filters ajudam contra wallhack ([doc](https://foxssake.github.io/netfox/latest/netfox/guides/visibility-management/)).
  - Inferência minha: o input continua confiável, então é preciso normalizar no servidor. Aimbot passa ileso. Aceitar input até cerca de 2 s no passado abre janela para lag switch; se há algum limite extra, não confirmado.

## 5. Física em rollback
- **CharacterBody3D** funciona:
  - Use `velocity *= NetworkTime.physics_factor`, depois `move_and_slide()`, depois divida de volta.
  - `is_on_floor()` exige um move de velocidade zero antes.
  - Queries contra corpos rebobinados veem posições velhas. O workaround (static → transform → kinematic) "works for both Jolt and GodotPhysics3D" ([caveats](https://foxssake.github.io/netfox/latest/netfox/tutorials/rollback-caveats/)).
  - Wall-run, dash e grappling cinemáticos cabem aqui (recomendação minha).
- **RigidBody**:
  - O Godot oficial não tem `space_step`; o PR [#76462](https://github.com/godotengine/godot/pull/76462) está aberto desde 2023.
  - Opções ([physics](https://foxssake.github.io/netfox/latest/netfox.extras/guides/physics/)):
    - build da comunidade `v4.7.2-stepping-physics`, com Jolt ([albertok/godot](https://github.com/albertok/godot/releases));
    - Blazium;
    - Rapier. Os drivers foram testados com a 0.8.26 e o Rapier já está na v0.36.0, então compatibilidade com a atual é não confirmada ([releases](https://github.com/appsinacup/godot-rapier-physics/releases)).
  - Ativação:
    - Project → Tools → Enable physics driver.
    - Nó PhysicsDriver3D na raiz da cena.
    - `NetworkRigidBody3D.physics_state` como state no RBS, com a lógica em `_physics_rollback_tick`.
- **Jolt**: é o default em projetos 3D novos desde o 4.6 ([release](https://godotengine.org/releases/4.6/)). Sem stepping, o driver se recusa a ativar ([src](https://github.com/foxssake/netfox/blob/main/addons/netfox.extras/physics/physics-driver-toggles.gd)).
- **Commits recentes, só na main**: #633/#639 (tick correto), #647 (estados do Rapier procurados pela tag do tick), #651 e #646 ([compare](https://github.com/foxssake/netfox/compare/v1.35.3...main)). Seguem abertos [#582](https://github.com/foxssake/netfox/issues/582) e [#515](https://github.com/foxssake/netfox/issues/515).
- **Determinismo**: não é exigido, só consistência. Não compartilhe Resources nem guarde tipos por referência no state ([FAQ](https://foxssake.github.io/netfox/latest/faq/)).

## 6. Latência, jitter e perda
- **NetworkSimulator** (desde v1.35.3):
  - Faz autoconnect: a 1ª instância hospeda e as outras conectam.
  - Simula latência e perda, e só roda no editor ([doc](https://foxssake.github.io/netfox/latest/netfox.extras/guides/network-simulator/)).
  - A latência é one-way (RTT = 2×). Não simula jitter, reorder nem duplicação ([src](https://github.com/foxssake/netfox/blob/main/addons/netfox.extras/network-simulator.gd)).
  - Bug aberto: com 4 ou mais peers e latência, um deles congela ([#554](https://github.com/foxssake/netfox/issues/554)). Isso atrapalha teste de 8v8.
- **Ferramentas externas**, citadas no próprio doc:
  - clumsy (Windows): lag, drop, throttle, duplicate, out-of-order; funciona em localhost ([clumsy](https://jagt.github.io/clumsy/)).
  - `tc netem` (Linux): delay com jitter ([man](https://man7.org/linux/man-pages/man8/tc-netem.8.html)).
- **Apoio**: WindowTiler e os monitores do NetworkPerformance ([doc](https://foxssake.github.io/netfox/latest/netfox/guides/network-performance/)).

## 7. Exemplos
- **Comparação**: `single-player`, `multiplayer-simple` (nativo, ingênuo) e `multiplayer-netfox` (RBS) ([README](https://github.com/foxssake/netfox/blob/main/README.md)).
- **Features** ([examples](https://github.com/foxssake/netfox/tree/main/examples)):
  - `input-gathering`;
  - `multiplayer-state-machine`;
  - `multiplayer-fps` (Hitscan3D);
  - `rollback-fps` (RewindableAction);
  - `property-configuration`;
  - `input-prediction`;
  - `rollback-npc` (RBS sem input);
  - `state-synchronizer-npc`;
  - `visibility-filtering`.
  - O README ainda cita o "Rollback Debugger", que já foi removido ([upgrading](https://foxssake.github.io/netfox/latest/upgrading/)).
- **Jogos**: Forest Brawl (LAN/noray, com bootstrap de dedicated server na main, [#635](https://github.com/foxssake/netfox/pull/635)) e [Godot Rocket League](https://github.com/albertok/godot-rocket-league) (física).
- **Como rodar host + 2 clientes**:
  1. Abra o projeto da raiz do repo.
  2. Vá em Debug → Customize Run Instances, marque Enable Multiple Instances e ponha 3 ([Godot docs](https://docs.godotengine.org/en/latest/tutorials/scripting/debug/overview_of_debugging_tools.html)).
  3. Use Run Project (o Forest Brawl é a main scene).
  4. Numa janela clique Host; nas outras duas, Join em `127.0.0.1`.
  - `host_only()` sobe o servidor sem avatar ([src](https://github.com/foxssake/netfox/blob/main/examples/shared/scripts/lan-bootstrapper.gd)).
  - Múltiplas instâncias com F6 (rodar só a cena aberta): não confirmado.

## 8. Compatibilidade com o Godot
- **O que é oficial**:
  - O README diz "Godot 4.x is supported", com exemplos escritos para 4.1 ([README](https://github.com/foxssake/netfox/blob/main/README.md)).
  - O CI só testa no 4.2.2 ([ci.yml](https://github.com/foxssake/netfox/blob/main/.github/workflows/ci.yml)).
  - Não há nenhuma declaração sobre 4.6 ou 4.7.
- **Problemas conhecidos em 4.6+/main**:
  - [#659](https://github.com/foxssake/netfox/pull/659) (aberto, 27/09): em 4.6.0, 4.6.3 e 4.7.2, o primeiro import sem `.godot` quebra os autoloads registrados como `uid://`. Também há 4 testes float16 falhando no 4.7.
  - [#658](https://github.com/foxssake/netfox/pull/658): bug de interpolação que só existe na main.
  - [#613](https://github.com/foxssake/netfox/issues/613): predição quebrada na main.
- **Release ou main**:
  - A v1.35.3 tem 10 meses. A main está 69 commits e 300 arquivos à frente, com `plugin.cfg` 1.49.4 e sem tag ([compare](https://github.com/foxssake/netfox/compare/v1.35.3...main)).
  - O FAQ chama o release de estável e a main de "bleeding edge" ([FAQ](https://foxssake.github.io/netfox/latest/faq/)).
  - Opinião minha: usar a main fixada num commit, rodar a suíte `vest` no 4.7.2 e acompanhar #658, #659 e #613. Quem quer risco mínimo usa a v1.35.3 e migra depois.

## 9. noray e Edgegap
- **noray** é um servidor (Bun, MIT) que faz NAT punchthrough e cai para relay UDP quando não dá ([noray](https://github.com/foxssake/noray)).
  - O fluxo é `register_host` → OpenID → `connect_nat`/`connect_relay` ([guia](https://foxssake.github.io/netfox/latest/netfox.noray/guides/noray/)).
  - Só é necessário quando o jogador hospeda atrás de NAT ([hosting](https://foxssake.github.io/netfox/latest/hosting/)). Com dedicated server em IP público, não (inferência minha).
  - A instância grátis `foxssake.studio:8890` tem limites e não tem SLA ([README](https://github.com/foxssake/netfox/blob/main/README.md)).
- **Edgegap** ([#652](https://github.com/foxssake/netfox/pull/652), merged em 20/09/2026):
  - O doc de hosting compara as duas opções: dedicado é estável mas custa, player hosting é grátis mas esbarra em NAT.
  - Apresenta a Edgegap como parceira, por assinatura, com orquestração na borda, matchmaking (com backfill) e server browser ([hosting](https://foxssake.github.io/netfox/latest/hosting/)).
  - O guia da Edgegap pede Godot 4.3+ e conta grátis sem cartão. O plugin deles gera a build Linux e a imagem Docker, testa local e faz o deploy. Porta default 7777; o cliente conecta em `*.pr.edgegap.net:porta` ([guia](https://docs.edgegap.com/docs/sample-projects/godot/netfox-forest-brawl), [Godot](https://docs.edgegap.com/godot)).

## 10. Limitações, performance e alternativas
- **Escala**: não há benchmark oficial, então 8v8 em 3D é não confirmado. Defaults: 30 tps, no máximo 8 ticks por frame, pacote de 508 B ([netfox.gd](https://github.com/foxssake/netfox/blob/main/addons/netfox/netfox.gd)).
- **CPU**: cresce com a profundidade do rollback (que acompanha a latência) vezes o número de nós ([perf](https://foxssake.github.io/netfox/latest/netfox/guides/network-performance/)).
- **Banda**: [#630](https://github.com/foxssake/netfox/issues/630) está aberto.
  - Com latência one-way maior que o `input_delay`, o state passa a ser reenviado a cada tick resimulado, numa espiral que se alimenta.
  - Um contribuidor respondeu "not really a bug". A saída é usar `input_delay` e matchmaking regional.
- **Outros problemas**: stalls do main thread quebram o RBS ([#543](https://github.com/foxssake/netfox/issues/543)), e não há sync de AnimationTree ([#553](https://github.com/foxssake/netfox/issues/553)).
- **Alternativas, em uma linha cada**:
  - **Godot nativo**: replicação por authority, sem predição ([doc](https://docs.godotengine.org/en/stable/classes/class_multiplayersynchronizer.html)).
  - **GodotSteam**: é só transporte (Steam Sockets + relay) e combina com o netfox ([codeberg](https://codeberg.org/godotsteam/multiplayerpeer)).
  - **Snopek Godot Rollback Netcode**: estilo GGPO, P2P com detecção de mismatch (exige determinismo), v1.0.0 em 06/2026. Serve para jogo de luta 2D, não para este caso ([GitLab](https://gitlab.com/snopek-games/godot-rollback-netcode)).
  - **Photon Fusion para Godot**: comercial, ainda em preview, Godot 4.6+ ([store](https://store.godotengine.org/asset/photon/photon-fusion/)).
  - **MonkeNet**: em C#, exige fork do Godot e ainda não tem lag compensation entre clientes ([README](https://github.com/grazianobolla/godot-monke-net)).
