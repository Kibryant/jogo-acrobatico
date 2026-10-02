---
id: F-007
titulo: Pesquisa: arquitetura do jogo de duelos com Godot 4.7.2 e netfox (02/10/2026)
recebido_em: 2026-10-02
como: Relatório final de um agente de pesquisa do Claude Code (general-purpose), pedido na sessão do my-brain de 02/10/2026. Texto como chegou, com o link da fonte ao lado de cada afirmação.
status: vigente
substituida_por:
---

# Arquitetura para o jogo de duelos (Godot 4.7.2 + netfox): o que vale e o que é excesso

Versões conferidas: o Godot 4.7.2-stable saiu em 18/08/2026 ([arquivo](https://godotengine.org/download/archive/)). O netfox está na 1.49.x ([issue #656](https://github.com/foxssake/netfox/issues/656)) e diz suportar "Godot 4.x" ([repo](https://github.com/foxssake/netfox)). Se funciona na 4.7.2 especificamente: **não confirmado**.

**Resumo:**
- Use DDD estratégico. Do DDD tático, quase nada.
- As regras ficam num núcleo puro em GDScript. Os nodes do Godot são adaptadores finos, e a colisão continua na engine.
- Nada de ECS.
- O personagem usa FSM contada em ticks; behavior tree só para bot.
- O netfox não exige determinismo bit a bit. Exige que o tick possa ser re-simulado a partir de estado sincronizado em tipos-valor.

## 1. DDD: onde ajuda e onde sobra

O próprio Evans disse que os building blocks táticos (entities, value objects, repositories) são "over emphasised" ([Evans, QCon 2009](https://gojko.net/2009/03/12/qcon-london-2009-eric-evans-what-ive-learned-about-ddd-since-the-book/)). Vernon diz que o "sweet spot" do DDD são domínios complexos e que ele "is not appropriate for just any enterprise application" ([entrevista](https://www.informit.com/articles/article.aspx?p=2023702)).

**Ubiquitous language vale desde já.** O vocabulário de fighting games já existe: startup/active/recovery ([critpoints](https://critpoints.net/2023/02/20/frame-data-patterns-that-game-designers-should-know/)). Um glossário curto, com termo, definição e unidade (ms no design, ticks no código), serve a você e ao Claude Code.

**Bounded contexts** ([Fowler](https://martinfowler.com/bliki/BoundedContext.html)):

| Contexto | Onde roda | Tratamento |
|---|---|---|
| **Simulação** (Combat + Movement), o core domain | server e predição no cliente, por tick | glossário + núcleo puro; sem aggregates nem repositories |
| Match/Round | server | FSM pequena e pura |
| Room/Lobby | server/RPC | state machine + CRUD |
| Progression/Stats | backend (Supabase) | aqui aggregate + evento `MatchEnded` fazem sentido, quando existir |
| Accounts | [Supabase Auth](https://supabase.com/docs/guides/auth) | generic subdomain: use pronto |

**Opinião:** Combat e Movement não são contextos separados. Os dois usam a mesma stamina, o mesmo estado "airborne" e o mesmo tick; separar criaria tradução artificial. A fronteira que importa é Simulação (tick, rollback) × Meta (request/response, persistência), e um evento de fim de partida liga as duas.

**DDD tático dentro da simulação atrapalha.**
- Na simulação, a fronteira de consistência é o tick, e a "persistência" é o snapshot do netfox. Esse snapshot exige tipos-valor, porque referências "vazam" entre ticks ([netfox FAQ](https://foxssake.github.io/netfox/latest/faq/)).
- O addon do Snopek diz o mesmo: "Don't put any References, Objects, Arrays or Dictionaries into state, unless you can duplicate them first" ([README](https://gitlab.com/snopek-games/godot-rollback-netcode)).
- A regra de Vernon de referenciar aggregates por identidade ([Vernon](https://www.dddcommunity.org/library/vernon_2011/)) é exatamente o que o rollback pede: IDs, não objetos.
- Domain events, sob rollback, disparam mais de uma vez ou "desacontecem". Para isso existem o `is_fresh` ([RollbackSynchronizer](https://foxssake.github.io/netfox/latest/netfox/nodes/rollback-synchronizer/)) e o `RewindableAction.has_confirmed()` ([doc](https://foxssake.github.io/netfox/latest/netfox/nodes/rewindable-action/)).

## 2. Núcleo funcional, casca imperativa (functional core, imperative shell)

Duas referências de base: valores simples como fronteira entre subsistemas ([Bernhardt](https://www.destroyallsoftware.com/talks/boundaries)) e ports & adapters para testar isolado dos dispositivos ([Cockburn](https://alistair.cockburn.us/hexagonal-architecture/)).

**Formato:**
- O núcleo fica em `core/`, com RefCounted ou funções estáticas: `step(state, input, cfg, tick) -> (state, eventos)`.
- O estado é plano: int, float, Vector3, StringName.
- O adaptador é o `Fighter` (CharacterBody3D), com um RollbackSynchronizer espelhando esse estado. O `_rollback_tick(delta, tick, is_fresh)` só chama o core.
- Animação, VFX, áudio e UI apenas leem o estado, suavizado pelo [TickInterpolator](https://foxssake.github.io/netfox/latest/netfox/nodes/tick-interpolator/).

**Ganhos:**
- rollback, porque o estado é explícito;
- autoridade do servidor, porque o mesmo código roda no server e no cliente;
- bots que só produzem input;
- replays;
- testes sem scene tree.

**Precedentes:**
- **Overwatch:** ECS com ~46 systems; o netcode fica concentrado em 3, e o movimento é determinístico, re-simulado no cliente ([GDC 2017](https://www.gdcvault.com/play/1024001/-Overwatch-Gameplay-Architecture-and); [resumo](https://edgegap.com/blog/game-backend-deep-dive-overwatch-2016-netcode-architecture-rollback)).
- **Photon Quantum:** simulação determinística desacoplada da view Unity ([blog](https://blog.photonengine.com/the-evolution-of-deterministic-multiplayer-photon-quantum-now-a-unity-verified-solution/), [docs](https://doc.photonengine.com/quantum/v3/quantum-intro)).
- **GGPO:** exige estado "fully encapsulated and serializable" e simular um frame sem renderizar ([guide](https://github.com/pond3r/ggpo/blob/master/doc/DeveloperGuide.md)).
- **Mortal Kombat/Injustice:** exigiram mudanças profundas na engine para re-simular 8 frames em 16 ms ([GDC 2018](https://www.gdcvault.com/play/1025471/8-Frames-in-16ms-Rollback)). É o preço de adaptar depois.
- **Rocket League:** física a 120 Hz ([RLBot](https://wiki.rlbot.org/v4/botmaking/tick-rate/)) e rollback com input decay nos carros remotos ([SnapNet](https://www.snapnet.dev/blog/netcode-architectures-part-2-rollback/)).
- **Godot:** o addon do Snopek usa `_save_state/_load_state` por node ([GitLab](https://gitlab.com/snopek-games/godot-rollback-netcode)). O Castagne relata gargalo de performance em GDScript e rollback ainda ausente ([roadmap](https://castagneengine.com/articles/roadmap2025/)).

**Atritos no Godot:**
1. **A colisão mora na engine.**
   - O Godot oficial não faz step manual de física: a PR #76462 está aberta desde 2023 ([PR](https://github.com/godotengine/godot/pull/76462)). RigidBody só entra no rollback com build ou addon especial ([netfox physics](https://foxssake.github.io/netfox/latest/netfox.extras/guides/physics/)).
   - CharacterBody3D e ShapeCast3D, porém, podem repetir movimento e colisão várias vezes por frame ([#272](https://github.com/foxssake/netfox/discussions/272)).
   - Por isso o Movement vira um "impureim sandwich" ([Seemann](https://blog.ploeh.dk/2020/03/02/impureim-sandwich/)): o core decide a intenção (dash, timer de wall-run, stamina), o adaptador chama `move_and_slide()` e raycasts, e devolve fatos como `on_floor` e `wall_normal`.
   - Cuidados: `is_on_floor()` só atualiza depois de `move_and_slide()`, e `intersect_shape()` pode falhar durante o rollback ([caveats](https://foxssake.github.io/netfox/latest/netfox/tutorials/rollback-caveats/)).
2. **O GDScript não tem struct nem interface** ([#7329](https://github.com/godotengine/godot-proposals/issues/7329)). Existe `@abstract` desde a 4.5 ([4.5](https://godotengine.org/article/dev-snapshot-godot-4-5-beta-1/)). Traits não entraram; a PR foi fechada em jul/2026 ([#107227](https://github.com/godotengine/godot/pull/107227)). Value objects ficam como tipos built-in.
3. **Há boilerplate** para espelhar o estado do core nas propriedades do node.
4. **Custo de CPU** de re-simular 16 jogadores em GDScript: **não confirmado**, meça cedo.

## 3. ECS ou composição de nodes

**Recomendação: nodes + núcleo puro, sem framework de ECS.**
- Segundo Linietsky, ECS compensa com "dozens of thousands of objects" ([Godot](https://godotengine.org/article/why-isnt-godot-ecs-based-game-engine/)). Aqui são até 16 jogadores mais projéteis.
- O netfox trabalha sobre nodes e property paths. As opções de ECS:
  - **GECS:** ativo (v9.3.x, set/2026), mas o módulo de rede não menciona predição nem rollback ([GECS](https://github.com/csprance/gecs)).
  - **godex:** último commit em set/2023, e exige compilar módulo ([commits](https://github.com/GodotECS/godex/commits/main)).
  - **Glecs (Flecs):** projeto pequeno, binários só para Windows e Linux ([repo](https://github.com/GsLogiMaker/godot-glecs)).
- Com agente, um paradigma só, o idiomático, deixa menos coisa para revisar. A própria doc diz que "nodes do not work like components" ([docs](https://docs.godotengine.org/en/stable/getting_started/introduction/godot_design_philosophy.html)). Do Overwatch, aproveite a ideia (estado sem comportamento, lógica em funções), não o framework.

## 4. FSM, BT e rollback

**Personagem: FSM hierárquica contada em ticks.**
- Dois superestados: Grounded {Idle, Run, Windup, Active, Recovery, Parry, Feint, Swap} e Airborne {Jump, WallRun, Dash, Grapple}.
- "Não defende no ar" vira regra do superestado. FSM serve para poucos estados distintos, e a hierarquia evita duplicação ([GPP State](https://gameprogrammingpatterns.com/state.html)).
- O netfox já traz a `RewindableStateMachine` ([doc](https://foxssake.github.io/netfox/latest/netfox.extras/guides/rewindable-state-machine/)):
  - `enter/exit` para lógica;
  - `display_enter/exit` para visual;
  - transições que podem não rodar "by design".

**Para o rollback funcionar:**
- **Tudo vira state property:** `state_id`, ticks no estado, stamina, cooldowns em ticks, input em buffer e estado do RNG.
- **Nada de tempo de relógio:** sem Timer, `await` ou `create_timer`. Os caveats citam "safeguards that implement a cooldown" ([caveats](https://foxssake.github.io/netfox/latest/netfox/tutorials/rollback-caveats/)). O Snopek criou NetworkTimer (conta ticks) e NetworkAnimationPlayer (avança por tick e suporta rollback) por esse motivo ([README](https://gitlab.com/snopek-games/godot-rollback-netcode)).
- **Animação é só visual:** AnimationMixer em modo manual, com `advance()` calculado a partir do estado ([doc](https://docs.godotengine.org/en/stable/classes/class_animationmixer.html)). Root motion não dirige gameplay.
- **Inputs de um toque** (ataque, parry, feint) ficam em buffer e valem no máximo um tick ([netfox](https://foxssake.github.io/netfox/latest/netfox/tutorials/input-gathering-tips-and-tricks/)).

**Bots: behavior tree.**
- A IA de jogos migrou para behavior trees e planners ([GPP](https://gameprogrammingpatterns.com/state.html)).
- O LimboAI tem BT + HSM, como módulo ou GDExtension, para Godot 4.6+, e não documenta nada sobre rollback ([repo](https://github.com/limbonaut/limboai)).
- Regra: o bot só produz input. A BT roda no server antes do tick loop, nunca dentro do `_rollback_tick`.
- Como plugar o bot como input authority no netfox: **não confirmado**.

## 5. Dados em Resources

O padrão é Type Object ([GPP](https://gameprogrammingpatterns.com/type-object.html)):
- `MoveData`: fases em ms, stamina, custo de feint, dano, hitbox;
- `WeaponData`: moves e `swap_ms`;
- `StatsTable`.

Como `.tres` é texto, dá para fazer diff no git.

**Armadilhas:**
- **Cache compartilhado.** Resource carregado sai de um cache compartilhado ([Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)); alterar em runtime afeta todo mundo. O FAQ do netfox pede para não depender de resource compartilhado no `_rollback_tick` ([FAQ](https://foxssake.github.io/netfox/latest/faq/)). Trate Resource como configuração imutável.
- **Cópia rasa.** `duplicate()` raso compartilha Array, Dictionary e Resource aninhados ([Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)). O `duplicate_deep()` chegou na 4.5 ([PR #100673](https://github.com/godotengine/godot/pull/100673)).
- **`local_to_scene`.** Há relatos de arrays compartilhados mesmo com `resource_local_to_scene` ligado ([fórum](https://forum.godotengine.org/t/resources-shared-despite-being-local-to-scene/77587)).
- **Referência no estado.** O estado guarda o ID do move, nunca a Resource.
- **ms vs. ticks.** Converta na carga. Com o tickrate padrão de 30 ([netfox.gd](https://github.com/foxssake/netfox/blob/main/addons/netfox/netfox.gd)), cada tick vale 33,3 ms: um parry de 100 ms vira 3 ticks. Um teste deve falhar quando o arredondamento passar da tolerância.
- **Hot reload.** Editar o `.tres` com o jogo rodando e ver o efeito na hora: **não confirmado**.

## 6. Determinismo: o que o netfox exige

**Existem duas famílias de netcode:**
- **Só inputs trafegam** (lockstep, GGPO, For Honor): exige determinismo total ([GGPO](https://github.com/pond3r/ggpo/blob/master/doc/DeveloperGuide.md)).
  - O For Honor relata bugs de desync e otimizações para rodar a lógica do jogo 8 vezes num único frame ([GDC 2019](https://www.gdcvault.com/play/1026322/Back-to-the-Future-Working)).
  - Float só é reprodutível com o mesmo compilador e o mesmo instruction set ([Gaffer](https://gafferongames.com/post/floating_point_determinism/)). Por isso o SG Physics usa fixed-point ([Snopek](https://www.snopekgames.com/tutorial/2021/getting-started-sg-physics-2d-and-deterministic-physics-godot/)).
- **Server autoritativo manda estado** (Overwatch, netfox): dispensa determinismo bit a bit ([SnapNet](https://www.snapnet.dev/blog/netcode-architectures-part-3-snapshot-interpolation/)). Basta ser "deterministic enough" ([Gambetta](https://www.gabrielgambetta.com/client-side-prediction-server-reconciliation.html)).

**O netfox é da segunda família.** Segundo o FAQ, rollback "doesn't need deterministic physics", só consistência razoável ([FAQ](https://foxssake.github.io/netfox/latest/faq/)). O que ele exige:
1. **Tick fixo**, num loop próprio ([NetworkTime](https://foxssake.github.io/netfox/latest/netfox/guides/network-time/)). Padrão: 30 Hz, history de 64 ticks, input_delay 0 ([netfox.gd](https://github.com/foxssake/netfox/blob/main/addons/netfox/netfox.gd)).
2. **Tudo que o `_rollback_tick` lê ou escreve** precisa estar sincronizado como state ou input ([FAQ](https://foxssake.github.io/netfox/latest/faq/)).
3. **RNG que volta no tempo** ([doc](https://foxssake.github.io/netfox/latest/netfox.extras/guides/rewindable-random-number-generator/)), ou ruído calculado por (seed, tick, id) ([Eiserloh](https://www.gdcvault.com/play/1024365/Math-for-Game-Programmers-Noise)).
4. **`NetworkRollback.mutate()`** quando um lutador altera outro. A API é experimental ([doc](https://foxssake.github.io/netfox/latest/netfox/tutorials/modifying-objects-during-rollback/)).

**Quem re-simula:**
- **No cliente:** só os nodes cujo input ele conhece. Os jogadores remotos ficam de fora, a menos que você ligue prediction ([predicting input](https://foxssake.github.io/netfox/latest/netfox/tutorials/predicting-input/)).
- **No host:** ele também faz rollback quando o input chega atrasado ([#630](https://github.com/foxssake/netfox/issues/630)).

Inferência minha: no duelo, você enxerga o windup do oponente com atraso, e janelas curtas de parry sofrem com isso.

**Float:**
- O `float` do GDScript tem 64 bits, mas Vector3 usa 32 ([docs](https://docs.godotengine.org/en/stable/classes/class_float.html)).
- Cliente Windows e server Linux podem divergir um pouco.
- No netfox isso vira correção, não bug. Mas inviabiliza replay só de inputs entre plataformas.

## 7. Testes realistas para 10 h/semana

1. **Spec executável do combate, desde o dia 1.**
   - O GUT 9.7.1 suporta a 4.7 ([GUT](https://github.com/bitwes/Gut)), e o CLI devolve 0/1 ([CLI](https://gut.readthedocs.io/en/latest/Command-Line.html)). O gdUnit4 traz fuzzing e uma GitHub Action ([gdUnit4](https://github.com/godot-gdunit-labs/gdUnit4)).
   - Os testes são tabelas: "feint no tick 4 do windup custa X de stamina e volta a Idle em N ticks". Rodam com `--headless` ([CLI](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)).
   - É o "check" de que o Claude Code precisa para fechar o loop sozinho ([best practices](https://code.claude.com/docs/en/best-practices)).
   - Ligue o aviso `UNTYPED_DECLARATION` ([typing](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html)).
2. **Teste de rollback**, no estilo do SyncTest do GGPO ([GGPO](https://github.com/pond3r/ggpo/blob/master/doc/DeveloperGuide.md)): inputs aleatórios, snapshot, re-simulação e comparação de hash. Pega estado escondido.
3. **Data-lint:** carrega todos os `.tres` e confere invariantes.
4. **Replay como golden master:**
   - Grave inputs e seed no server, re-rode headless e compare o hash final, como o Factorio faz com CRC ([FFF-60](https://factorio.com/blog/post/fff-60)).
   - Mudou o balanceamento, reaprove o golden.
   - A Blizzard chama replays de "invaluable in reproducing bugs" ([GDC](https://gdcvault.com/browse/gdc-17/play/1024053)).
5. **Netcode à mão**, com o NetworkSimulator, que simula latência e perda; só roda no editor e se desliga em CI ([doc](https://foxssake.github.io/netfox/latest/netfox.extras/guides/network-simulator/)). Automatize com [netem](https://man7.org/linux/man-pages/man8/tc-netem.8.html) ou [clumsy](https://jagt.github.io/clumsy/) só se doer.

## 8. Armadilhas, regras e trade-offs

**Armadilhas:**
- Escrever engine em vez de jogo ([Petrie](https://geometrian.com/programming/tutorials/write-games-not-engines/)).
- Esquecer que toda abstração é uma aposta no futuro ([GPP](https://gameprogrammingpatterns.com/architecture-performance-and-games.html)).
- DDD-cosplay: repository para `.tres`, aggregate por entidade.
- Framework de ECS.
- Event bus genérico, que quebra sob rollback.
- Desenhar o 8v8 antes de o 1v1 ser divertido. Derek Yu escreveu um guia inteiro porque deixou "a long trail of unfinished games" ([Yu](https://makegames.tumblr.com/post/1136623767/finishing-a-game)).
- O próprio guia do Claude Code avisa que perseguir todo achado de review leva a over-engineering ([best practices](https://code.claude.com/docs/en/best-practices)).

**Regras:**
1. **Um único núcleo puro** (`core/`, sem Node): estado plano, `step(state, inputs, tick)`, tudo em ticks inteiros.
2. **Nodes como adaptadores finos:** um RollbackSynchronizer por lutador espelhando o estado. A engine faz a colisão e devolve valores. Efeitos só via `is_fresh` ou display callbacks.
3. **Dados imutáveis em Resources, referenciados por ID**, com a conversão de ms para ticks testada.
4. **Testar regra, não engine:** spec + teste de rollback em CI headless desde o dia 1; netcode à mão.
5. **DDD só estratégico:** glossário + fronteira Simulação × Meta.
6. **Escalar por marcos:** 1v1 de espada local → online → arco e armas → 4v4 com bots → 8v8. Meça a CPU com 16 bots antes de prometer o 8v8.

**Trade-offs que só você decide:**
- **Tickrate 30 ou 60:** precisão do parry contra CPU e banda em GDScript.
- **Prediction dos remotos e input_delay:** oponente mostrado no passado contra correções visíveis.
- **Validação de tiro:** favorecer o atacante com server rewind ([SnapNet](https://www.snapnet.dev/blog/netcode-architectures-part-3-snapshot-interpolation/)) ou favorecer o defensor. Não achei server rewind pronto no netfox: **não confirmado**.
- **Hitbox:** formas analíticas no core (testáveis) ou queries de física (exigem cena).
- **Movimento:** CharacterBody3D pronto, ou um kinematic próprio, testável, mas reescrevendo a colisão.
- **Replay:** por inputs (pequeno, mas preso à mesma build e plataforma) ou por snapshots (robusto, mas maior).

---
**Limites da pesquisa:**
- Os slides de Rocket League, Sea of Thieves e o DDD Reference vieram em PDF que eu não consegui ler. Os números do Overwatch vêm de um resumo secundário (Edgegap).
- Nada foi escrito na máquina nem no Yabadoo.
