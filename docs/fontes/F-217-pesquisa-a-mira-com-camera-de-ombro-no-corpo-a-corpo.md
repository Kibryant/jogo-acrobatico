---
id: F-217
titulo: "Pesquisa: a mira com câmera de ombro nos jogos de ação corpo a corpo, para a Q-57 (18/11/2026)"
recebido_em: 2026-11-18
como: Relatório de um agente de pesquisa na web (general-purpose, Opus 5.5), pedido pelo Arthur depois da TASK-12.4 (F-215; sessão 24, 18/11/2026). O agente escreveu o documento em português, com uma marca de origem em cada afirmação. O orquestrador abriu três das páginas que mais pesam na decisão. O patch v1.14.1 do For Honor e o tópico de 24/06/2020 do Mordhau conferiram palavra por palavra. A citação do OpenMW (PR #1425) era uma paráfrase entre aspas e foi trocada pela frase real do autor do PR, nas seções 2.5 e 4. Fora essa troca, o texto está como chegou.
status: vigente
substituida_por:
---

# Pesquisa: mira com câmera de ombro em jogos de ação corpo a corpo

Data da pesquisa: 2026-11-18. Todos os links foram acessados nessa data.

**Pergunta.** Como jogos de ação em terceira pessoa com combate corpo a corpo fazem "o que está sob a mira é o que o golpe acerta" funcionar quando a câmera fica deslocada, sobre o ombro?

**Contexto (do briefing, não pesquisado).** Nossa câmera fica 0,8 m à direita do corpo, na mesma altura. O golpe sai do eixo do corpo em direção a um ponto da linha da mira a uma distância fixa c (convergência): 2,0 m para a espada, 1,2 m para o agarrão. A mira só é exata em d = c. Para acertar um alvo a d metros, o jogador precisa mirar 0,8 × (1 − d/c) m ao lado dele. Nos replays ele compensa 0,17 a 0,19 m em todo golpe e diz que a mira de lado parece "mentalmente bugada".

## Como ler as marcas

| Marca | Significa |
|---|---|
| **[P]** | Fonte primária: desenvolvedor, nota de patch oficial, documentação ou wiki oficial. |
| **[S]** | Fonte secundária: imprensa, guia, wiki de fãs, análise. |
| **[F]** | Fórum ou jogador. Vale como relato, não como regra do jogo. |
| **[O]** | Observação minha de uma captura de tela oficial (loja Steam). Pode ser modo foto; vale como indício. |
| **não confirmado** | Veio só de trecho de busca (a página não abriu), de resumo automático ou secundário, ou de memória. |

## Resumo

1. Nos jogos corpo a corpo documentados, quase ninguém promete "mira = acerto" com câmera deslocada. As respostas que aparecem são: travar no alvo (For Honor, Souls, God of War, Naraka), puxar o golpe para o alvo (For Honor fora da trava, God of War, Warframe, Naraka), centralizar a câmera (Mordhau em 2020, Skyrim em combate, Zelda ao mirar o arco) ou fazer o golpe seguir só a direção da câmera (Warframe, Monster Hunter Wilds).
2. A convergência pela profundidade do alvo (raio da câmera acha o ponto, o golpe vai até lá) é o padrão dos jogos de tiro (Monday Night Combat, The Last of Us Part II, Lyra da Epic, Cinemachine da Unity, Fortnite). Não achei nenhum jogo corpo a corpo que documente isso para golpes.
3. O único PvP corpo a corpo com mudança de câmera documentada é Mordhau: a terceira pessoa saiu do ombro e foi centralizada em junho de 2020.
4. Acerto pelo raio da câmera "estilo picareta do Fortnite" ficou **não confirmado**: não achei fonte primária sobre a picareta.
5. Nosso deslocamento de 0,8 m é maior que todos os números encontrados: Skyrim fora de combate ≈ 0,43 m (conversão aproximada) e 0 em combate; tutoriais de Godot e Unreal usam 0,5 a 0,55 m, ligados ao botão de mirar.

---

## 1. Jogos

### 1.0 Quadro geral

Células curtas; detalhes e fontes nas tabelas de cada jogo.

| Jogo | Câmera | Direção do golpe | Ajuda de mira | Câmera muda no golpe? |
|---|---|---|---|---|
| GunZ: The Duel | Atrás, quase centrada (relançamento) [O] | Não confirmado | Nenhuma encontrada | Não encontrado |
| For Honor | Ombro direito; travada aponta para o alvo [O][S] | Trava + 3 direções de guarda; fora da trava, snap ao alvo | Trava; snap fora da trava [P] | Trava a câmera no alvo [S] |
| Mordhau | 1ª pessoa; 3ª era de ombro, centrada desde 2020 [F][S] | Golpe guiado pelo mouse | Nenhuma encontrada | Não |
| Chivalry 2 | 1ª ou 3ª pessoa; posição lateral não encontrada | Não documentado | Nenhuma encontrada | Não encontrado |
| Naraka: Bladepoint | 3ª pessoa; posição lateral não verificada | Direção do personagem, ou assistida | Assistência de corpo a corpo e trava (controle) [P] | Sim, opção padrão no controle [P] |
| God of War (2018) / Ragnarök | Ombro direito, próxima [P][O] | Analógico + orientação automática ao alvo | Puxa ao alvo; trava tardia; Ragnarök: modos de trava [P] | Ragnarök: "Recenter Camera on Attack" [P] |
| Elden Ring / Dark Souls | Atrás (lateral não confirmada) | Analógico esquerdo | Trava (hard lock) | Na trava, segue o alvo |
| Warframe | Ombro, com presets e troca de lado [P] | Direção da câmera, opcional [P] | Auto-target opcional [P] | Opcional: câmera segue o alvo [P] |
| Fortnite | Ombro direito, sem troca [S] | Picareta: não confirmado | — | Não |
| Monster Hunter Wilds | Atrás (lateral não verificada) | Focus Mode: direção da câmera [S] | Destaque de feridas (não confirmado) | Câmera livre |
| Skyrim | Ombro fora de combate; centrada em combate [S] | — | — | Sim: centraliza e aproxima [S] |

### 1.1 GunZ: The Duel

| Campo | O que se sabe | Fontes |
|---|---|---|
| Câmera | Terceira pessoa: "a complex third-person shooter" [S]. Na captura oficial do relançamento de 2026 (tela de jogo com tiro), a mira de três traços fica no centro exato da tela e a personagem fica logo abaixo dela, uns 80 px à esquerda do centro numa imagem de 1920 px (≈4% da largura): câmera atrás e acima, sem deslocamento lateral grande [O]. Não achei texto que descreva a câmera do original de 2006: **não confirmado** para o original. | [gitbook](https://gunz.gitbook.io/gunz-guide/how-to-play-gunz/how-to-play/gameplay-and-mechanics); [captura Steam](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/3139440/e03a7a8f80fe71de587c08a1dead8bc38dac3ce5/ss_e03a7a8f80fe71de587c08a1dead8bc38dac3ce5.1920x1080.jpg) |
| Direção do golpe | Espada e tiro usam o mesmo botão: "slashing and shooting was both done with M1" [S]. Que o golpe siga o yaw da câmera vem de memória: **não confirmado**. | [Critpoints](https://critpoints.net/2016/04/21/mtm-gunz-legendkiller-2/) |
| Ajuda de mira | Guia da StrategyWiki: adagas são mais difíceis "as the cross hair must be kept on the target, making faster targets harder to hit, especially at close range". **Não confirmado**: só trecho de busca; a página dá 403. Nenhuma menção a trava ou magnetismo. | [StrategyWiki](https://strategywiki.org/wiki/GunZ_The_Duel/Weapons) |
| Câmera muda no golpe? | Não encontrado. | — |
| Nota | Wall cancel: "jump, dash mid-air in the direction of the wall, and upon hitting it slash or stab with their melee weapon" [S]. | [Wikipedia, revisão de 2015](https://en.wikipedia.org/w/index.php?oldid=693344930) |

### 1.2 For Honor

| Campo | O que se sabe | Fontes |
|---|---|---|
| Câmera | Terceira pessoa [S]. Há dois modos: fora da trava ou "locking the camera on an enemy" [S]. Na captura oficial de um duelo travado, o indicador de guarda do alvo fica no centro exato da tela e o herói do jogador ocupa a parte inferior esquerda: câmera atrás e à direita do ombro, apontada para o alvo [O]. | [Wikipedia](https://en.wikipedia.org/wiki/For_Honor); [GamePressure](https://www.gamepressure.com/forhonor/general-information/z696b5); [captura Steam](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/304390/37c713982e81b3a94152f75ac4a645749e56787a/ss_37c713982e81b3a94152f75ac4a645749e56787a.1920x1080.jpg) |
| Direção do golpe | Travado: "players aim at their opponent with their weapon" e escolhem uma de três direções (esquerda, direita, cima) [S]. "The stances can only be used in Lock Mode." [S]. Fora da trava, desde a v1.14.1 (28/09/2017): "From now on, out of lock attacks always snap towards a target if in range." e "We fixed this by forcing the system to aim directly at the nearby target." [P] | [Wikipedia](https://en.wikipedia.org/wiki/For_Honor); [GamePressure](https://www.gamepressure.com/forhonor/general-information/z696b5); [Ubisoft v1.14.1](https://www.ubisoft.com/en-us/game/for-honor/news-updates/6xmrHNNcxYfb9lybtGfYlE/for-honor-v1141-patch-notes) |
| Ajuda de mira | Trava e snap. O snap veio para fechar um exploit: atacar sem trava gerava golpes que miravam o oponente mas não podiam ser aparados; "This will significantly reduce the unlock exploit" [P]. A Ubisoft diz: "As we don't want to incentivize Out of Guard mode combat" (v1.07, 11/05/2017) [P]. | [Ubisoft v1.14.1](https://www.ubisoft.com/en-us/game/for-honor/news-updates/6xmrHNNcxYfb9lybtGfYlE/for-honor-v1141-patch-notes); [Ubisoft v1.07](https://www.ubisoft.com/en-us/game/for-honor/news-updates/5VI8R7GvlBZqFwWEELluhH/patch-notes-for-honor-v107) |
| Câmera muda no golpe? | A trava mantém a câmera no alvo [S][O]. Zoom para caber vários oponentes: relato de jogador, **não confirmado**. | [Reddit (espelho)](https://reddit.birdcat.cafe/r/CompetitiveForHonor/comments/agdawq/qa_megathread_v4/ee6fau9) |

### 1.3 Mordhau

| Campo | O que se sabe | Fontes |
|---|---|---|
| Câmera | Primeira pessoa por padrão, terceira opcional: **não confirmado** (guias com trecho de busca). A terceira pessoa era sobre o ombro: em 5/6/2019 um jogador pergunta como deixá-la "centered above the character instead of the standard shoulder view"; outro diz que os desenvolvedores "removed camera zoom & tweaking options during beta" [F]. No Patch 18 (junho de 2020) a terceira pessoa foi centralizada: tópico na Steam "Third person camera changed to a centered view." (24/06/2020) [F]; tradução russa das notas: «Камера от третьего лица теперь направлена по центру.» [S]; o SteamDB dá 403 e só aparece em trecho de busca (**não confirmado**). | [Steam 2019](https://steamcommunity.com/app/629760/discussions/0/1640913421067265827); [Steam 2020](https://steamcommunity.com/app/629760/discussions/0/2572067496656650802); [DTF, Patch 18](https://dtf.ru/id136355/160686-patch-18); [SteamDB](https://steamdb.info/patchnotes/5209020) |
| Motivo declarado | Post listado no devtrackers (rastreador de posts de desenvolvedores; o nome do autor não aparece), 2020: a terceira pessoa "has been reworked recently (only in dev builds atm) to be much more in line with first person" e "have removed/greatly reduced extra vision that allows this kind of playstyle" [P, com a ressalva do autor não identificado]. | [devtrackers](https://devtrackers.gg/mordhau/p/8e6f6226-ridiculous-spins-drags-delays-exploits) |
| Direção do golpe | O jogador conduz o golpe com o mouse; a wiki define manipular o golpe como mover o "attack tracer" (**não confirmado**: trecho de busca; Fandom dá 402). | [Mordhau Wiki](https://mordhau.fandom.com/wiki/Accels) |
| Ajuda de mira | Nenhuma encontrada. | — |
| Câmera muda no golpe? | Não. | — |
| Jogadores | Antes da mudança (tópico sem data visível; o resumo de busca o situa em 2019): "Aiming stabs feels really ahrd in 3rd, but feel like i have better sight/controll over slashes"; "in fights i always ♥♥♥♥ up the range with third person." [F]. Depois (2020): "The new position does help you be more accurate with your aim, closer to 1st person view.."; queixa: "Now I need to spend hours to fix my aim and play style." [F]. Palpite de jogador sobre o motivo: "so you cant peak around corners nearly as much" [F]. | [Steam 2019](https://steamcommunity.com/app/629760/discussions/0/1651043958640598989); [Steam 2020](https://steamcommunity.com/app/629760/discussions/0/2572067496656650802) |

### 1.4 Chivalry 2

| Campo | O que se sabe | Fontes |
|---|---|---|
| Câmera | Primeira ou terceira pessoa (**não confirmado**: trecho de busca da Wikipedia). Não achei a posição lateral da câmera em terceira pessoa. Servidores podem forçar uma das duas: "Ability to restrict players to third person or first person" (Update 1.35 / 2.10, 05/03/2024) [S, citando as notas]. | [Wikipedia](https://en.wikipedia.org/wiki/Chivalry_2); [MP1st](https://mp1st.com/?p=254237) |
| Direção do golpe | Não documentado nas fontes lidas. | — |
| Ajuda de mira | Nenhuma encontrada. | — |
| Câmera muda no golpe? | Não encontrado. | — |
| Jogadores | "Playing in 3rd person can also help you see attacks you wouldnt be able to read in 1st person." (**não confirmado**: trecho de busca). | [Steam](https://steamcommunity.com/app/1824220/discussions/0/4767711099754558596) |

### 1.5 Naraka: Bladepoint

| Campo | O que se sabe | Fontes |
|---|---|---|
| Câmera | Terceira pessoa. Posição lateral **não verificada** (as capturas da loja são só cenário). | — |
| Direção do golpe | Com a assistência desligada no controle: "Launch melee strikes in the direction faced." [P] | [Naraka, 01/06/2022](https://narakathegame.com/news/update/20220525/33459_1020175.html) |
| Ajuda de mira | "Melee Aim Assist (Controller)": "[Aim Assist + Camera Shift]" é o padrão e "Automatically aims melee strikes toward the enemy, and moves the camera to face them when attacking."; "[Aim Assist]" faz o mesmo "without moving the camera"; pode desligar [P]. Trava no controle, com troca de alvo pelo analógico direito [P]. No mouse, "Auto Aim" configurável nos botões ao usar o gancho [P, 16/06/2021]. Um guia cita "Autolock Target", "Aim Assist" e "Attack from stick direction" (**não confirmado**: trecho de busca). | [Naraka, 01/06/2022](https://narakathegame.com/news/update/20220525/33459_1020175.html); [Naraka, 16/06/2021](https://www.narakathegame.com/news/official/20210616/32172_953985.html); [Player.One](https://www.player.one/naraka-bladepoint-melee-assist-mode-controllers-has-been-added-latest-147789) |
| Câmera muda no golpe? | Sim, na opção padrão do controle: a câmera gira para o inimigo ao atacar [P]. | [Naraka, 01/06/2022](https://narakathegame.com/news/update/20220525/33459_1020175.html) |

### 1.6 God of War (2018) e Ragnarök (2022)

| Campo | O que se sabe | Fontes |
|---|---|---|
| Câmera | "a much more intimate and player-controlled camera would fundamentally change the combat experience" (resumo da palestra de Mihir Sheth, Sony Santa Monica, GDC 2019) [P]. Em capturas oficiais de jogo, Kratos aparece no terço esquerdo da tela: câmera à direita do ombro [O]. | [GDC Vault](https://gdcvault.com/play/1026423/Evolving-Combat-in-God-of); [Game Developer](https://gamedeveloper.com/design/see-how-i-god-of-war-i-s-combat-evolved-to-match-its-new-camera-system-at-gdc-); [captura Steam](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1593500/ss_93a3ca63aa2cd8c675bbb6430324ee3f2d44b845.1920x1080.jpg) |
| Direção do golpe | Resumo automático da palestra (**não confirmado** no vídeo): o alvo muda com o analógico esquerdo; "Kratos will attack directly forward if no targets are available."; "Kratos' attacks automatically orient towards any selected target to avoid clumsy misses when enemies are nearby."; inimigos fora da tela não podem ser alvo. A Critpoints chama o 2018 de "mouselook": "the camera controls the facing direction of the character" [S]. | [VideoHighlight](https://videohighlight.com/v/hE5tWF-Ou2k); [Critpoints](https://critpoints.net/2015/05/24/what-is-your-ideal-form-of-lock-on-in-action-games/) |
| Ajuda de mira | Mesmo resumo (**não confirmado**): "suck to target" puxa Kratos para o alvo, com alcance que diminui quando o ângulo aumenta; um "strike assist" vira o inimigo atingido para a câmera; a trava entrou tarde, por demanda nos testes; a abordagem inicial imitando shooter não funcionou. Ragnarök: "Lock-on will keep the enemy in the center of the camera view until an event or action breaks the lock.", com modos Classic, Auto-Target e Auto-Target+ [P]. | [VideoHighlight](https://videohighlight.com/v/hE5tWF-Ou2k); [PlayStation, acessibilidade do Ragnarök](https://www.playstation.com/en-us/games/god-of-war-ragnarok/accessibility/) |
| Câmera muda no golpe? | Ragnarök tem "Recenter Camera on Attack": "Camera will automatically move behind the player when using melee attacks."; no modo Priority, "Recenters the camera towards the nearest on-screen enemy when swinging a weapon or on parry." [P]. No 2018, o resumo cita assistência de câmera ao andar de lado e reorientação para os ataques (**não confirmado**). | [PlayStation](https://www.playstation.com/en-us/games/god-of-war-ragnarok/accessibility/); [VideoHighlight](https://videohighlight.com/v/hE5tWF-Ou2k) |
| Problemas citados | Resumo (**não confirmado**): preocupação com visibilidade depois da E3; "suck to target" às vezes errava "because of the new angles" (percepção de profundidade); ansiedade com inimigos fora da tela. | [VideoHighlight](https://videohighlight.com/v/hE5tWF-Ou2k) |

### 1.7 Elden Ring e Dark Souls

| Campo | O que se sabe | Fontes |
|---|---|---|
| Câmera | Atrás do personagem. Não achei fonte em texto sobre deslocamento lateral (**não confirmado**; existe um mod de "camera offset", visto só em trecho de busca). | [Nexus](https://www.nexusmods.com/eldenring/mods/3449) |
| Direção do golpe | Analógico esquerdo. Dark Souls 2: "lock-on no longer causes your weapons to autotrack the target; the player must manually aim swings with the left stick." e "Tilting the camera up or down will aim certain weapons slightly" [S]. | [Fextralife DS2](https://darksouls2.wiki.fextralife.com/Combat) |
| Ajuda de mira | Trava (hard lock); a Critpoints lista Dark Souls entre os jogos de hard lock [S]. Opções "Manual Attack Aiming", "Auto Target" e "Toggle Auto Lock-On" no Elden Ring (**não confirmado**: trecho de busca). | [Critpoints](https://critpoints.net/2015/05/24/what-is-your-ideal-form-of-lock-on-in-action-games/); [Steam](https://steamcommunity.com/app/1245620/discussions/0/3279194170694192936) |
| Câmera muda no golpe? | Na trava, a câmera acompanha o alvo. O patch 1.04 adicionou desligar a rotação automática da câmera (**não confirmado**: trecho de busca). | [Neowin](https://www.neowin.net/news/elden-ring-update-has-a-camera-auto-rotate-toggle-colossal-weapon-buffs-and-more/) |

### 1.8 Warframe

| Campo | O que se sabe | Fontes |
|---|---|---|
| Câmera | Sobre o ombro. A Update 43.0 criou "Camera Position" com três presets: Default, Side Offset e Far Offset ("The Camera is further back and higher up, giving you the greatest visibility of the three") [P]. Há o atalho `REVERSE_CAMERA_OFFSET`, "Switch camera location", e o Side Offset respeita o "Reverse Camera" [P]. | [Patch 43.0.0](https://www.warframe.com/patch-notes/pc/43-0-0); [Wiki oficial, Settings](https://wiki.warframe.com/w/Settings) |
| Direção do golpe | "Align Attacks to Camera": "Automatically redirects melee attack to the direction of camera." [P]. Desde a Update 24.4 (2019): "Melee mode has received its own reticle!", o bloqueio é automático "when aiming at an attacking enemy" e "Your Reticle determines all!" [P]. | [Wiki oficial](https://wiki.warframe.com/w/Settings); [Update 24.4.0](https://devtrackers.gg/warframe/p/d778b618-buried-debts-update-24-4-0) |
| Ajuda de mira | "Melee Auto Targeting": "Automatically redirects melee attack to any applicable target, overrides Align Attacks to Camera." [P] | [Wiki oficial](https://wiki.warframe.com/w/Settings) |
| Câmera muda no golpe? | "Camera Tracks Melee Target" (só controle): "Automatically redirects camera to a melee target." [P] | [Wiki oficial](https://wiki.warframe.com/w/Settings) |
| Jogadores | No PC, jogadores recomendam desligar o auto-target e ligar "Align attacks to camera" (**não confirmado**: trecho de busca; o fórum dá 403). | [Fórum Warframe](https://forums.warframe.com/topic/322611-melee-auto-targeting/) |

### 1.9 Fortnite

| Campo | O que se sabe | Fontes |
|---|---|---|
| Câmera | Sobre o ombro direito, sem troca de ombro (2018): "you can't shoulder swap from your left to your right shoulder" [S]. | [DBLTap](https://www.dbltap.com/posts/6018415-fortnite-desperately-needs-an-option-to-shoulder-swap) |
| Direção do golpe | Picareta acertando pelo raio da câmera: **não confirmado**. Não achei fonte primária, nota de patch ou documentação da Epic sobre isso. O que está documentado é das armas de fogo: no design chat da Epic, "the green line is supposed to be the bullet trace, while the yellow line is a traces from the centre of the player's camera" [S]. | [CGMagazine](https://www.cgmagonline.com/news/fortnite-explains-ghost-peeking-changes-in-v5-10-update) |
| Ajuda de mira | — | — |
| Câmera muda no golpe? | Não. | — |
| Nota (paralaxe) | "Ghost peeking": o traço da bala saía cerca de um pé acima do cano e deixava atirar por cima da cobertura sem aparecer; a v5.10 (julho de 2018) tornou o atirador atingível; efeito colateral: a cabeça da skin pode bloquear a linha entre a câmera e o retículo ao mirar [S]. | [PCGamesN](https://www.pcgamesn.com/fortnite/fortnite-ghost-peeking-fix); [CGMagazine](https://www.cgmagonline.com/news/fortnite-explains-ghost-peeking-changes-in-v5-10-update) |

### 1.10 Monster Hunter Wilds

| Campo | O que se sabe | Fontes |
|---|---|---|
| Câmera | Atrás do caçador. Posição lateral **não verificada**. | — |
| Direção do golpe | Focus Mode: "attacks and guards performed during Focus Mode will be aimed at where the player's camera is facing" (resumo do trailer oficial, 05/08/2024) [S]. Um guia diz que surge uma mira central e o caçador dirige todos os ataques para ela (**não confirmado**: trecho de busca; a página não carregou inteira). Em World e Rise, a direção do personagem decidia (**não confirmado**: trecho de busca). | [RPG Site](https://www.rpgsite.net/news/16127-monster-hunter-wilds-introduces-its-basic-mechanics-new-focus-mode-and-the-great-sword-weapon); [GamesRadar](https://www.gamesradar.com/games/monster-hunter/monster-hunter-wilds-focus-mode) |
| Ajuda de mira | Feridas e pontos fracos destacados no Focus Mode (**não confirmado**: trecho de busca). | — |
| Câmera muda no golpe? | A câmera fica livre; movê-la durante a preparação muda a direção do golpe (**não confirmado**: guia em trecho de busca). | — |

### 1.11 Skyrim (Bethesda)

| Campo | O que se sabe | Fontes |
|---|---|---|
| Câmera | Valores padrão do INI: fora de combate, `fOverShoulderPosX` = 30 (deslocada para o lado); em combate, `fOverShoulderCombatPosX` = 0 (centrada), `fOverShoulderCombatPosZ` = 20 (mais alta) e `fOverShoulderCombatAddY` = −100 ("the amount of zoom while in combat mode") [S]. Conta minha: 30 unidades ≈ 0,43 m, usando a escala "128 world units is equal to 6 feet" da UESP (**não confirmado**: a UESP deu 403, só trecho de busca; e não está documentado que o INI use essa mesma unidade). | [STEP, Skyrim INI](https://stepmodifications.org/wiki/Guide:Skyrim_INI/Camera); [UESP](https://ck.uesp.net/wiki/Unit) |
| Câmera muda no golpe? | Sim: ao entrar em combate a câmera centraliza e aproxima [S]. Um desenvolvedor do OpenMW cita "a Skyrim-style centered camera when the weapon is drawn" [F]. | [STEP](https://stepmodifications.org/wiki/Guide:Skyrim_INI/Camera); [OpenMW PR #1425](https://github.com/OpenMW/openmw/pull/1425) |

### 1.12 Outros, uma linha cada

- **Batman: Arkham Asylum.** "As soon as a fight begins, the camera zooms out and centers itself so that the player can attack the opponent unhindered." [S] ([Game Developer, Buehler 2019](https://www.gamedeveloper.com/design/third-person-camera-view-in-games-a-record-of-the-most-common-problems-in-modern-games-solutions-taken-from-new-and-retro-games))
- **The Elder Scrolls Online.** A câmera "is slightly offset to the right"; o disco de mira "represents the center of the camera view, and not the center from view of the main character", e o jogador erra alvos; um add-on de fã centraliza a câmera ao acertar o oponente [S] (mesma fonte).
- **Zelda: Tears of the Kingdom (arco).** Ao mirar, "the camera zooms in directly behind Link and not behind his shoulder"; a leitura é que a Nintendo "chose clarity over cinematic impact" para evitar a discrepância entre para onde o personagem olha e a linha da mira [S] ([80.lv](https://80.lv/articles/tears-of-the-kingdom-s-bow-aiming-camera-explained)).
- **Black Myth: Wukong.** Trava no botão do meio do mouse; jogadores reclamam da câmera puxando para o alvo (**não confirmado**: trecho de busca) ([Steam](https://steamcommunity.com/app/2358720/discussions/0/4426562616038129469)).
- **Devil May Cry.** Hard lock e, nas armas de fogo sem trava, soft lock [S] ([Critpoints](https://critpoints.net/2015/05/24/what-is-your-ideal-form-of-lock-on-in-action-games/)); no DMC5, segurar R1 trava no inimigo mais próximo à frente (**não confirmado**: guia em trecho de busca).
- **Kingdom Hearts.** Trava com câmera que segue o alvo; habilidade Auto-Lock no 358/2 Days (**não confirmado**: trecho de busca) ([KH Wiki](https://khwiki.com/Lock-On)).
- **Absolver, Sifu, Lies of P, Hellish Quart.** Nada útil em texto nesta rodada.

---

## 2. Paralaxe: como resolvem nos jogos de tiro e no corpo a corpo

### 2.1 O problema, nas palavras de quem resolveu

- The Last of Us Part II (GDC 2024, Derek Mattson, Naughty Dog): "The decoupling of the camera from the player creates as many problems as ways to solve them." [P] ([GDC Vault](https://www.gdcvault.com/play/1034215/A-Second-Shot-Improving-Ranged))
- Monday Night Combat (Forrest Smith, 2011): "What the player views (third person) is different than what the character can view (first person)." [P] ([Game Developer](https://gamedeveloper.com/design/opinion-adventures-with-guns-in-a-third-person-shooter))

### 2.2 A solução padrão dos jogos de tiro: a câmera decide, a arma confere

1. **Raio da câmera, depois traço da arma (Monday Night Combat)** [P]. "We will perform a ray trace from the camera through the screen centered crosshairs to determine a hit location." Depois: "A secondary weapon trace is then performed from weapon barrel tip to the initial hit location." Se esse traço bate numa parede, por exemplo "a wall 6 inches in front the character", vale a parede. O traço da arma tem distância máxima "(empirically tested to ~7 meters)". Conclusão do autor: "It is critical for the trace to come from the camera for the controlling player to have a positive play experience." Limite admitido: "Short geometry can block shots in a surprising manner and shooting down from a platform can be problematic." ([Game Developer](https://gamedeveloper.com/design/opinion-adventures-with-guns-in-a-third-person-shooter))
2. **Mover a mira para onde a arma acerta foi testado e rejeitado** [P]: "This was tested for MNC, but it causes the crosshair to jump around causing a confusing and unpleasant play experience." (mesma fonte)
3. **The Last of Us Part II: duas sondas e uma escondida** [P]. Resumo dos slides: "Camera Probe (invisible) — Spherecast that ignores environment"; "Secret raycast collides with everything"; "Player Character Probe — Back calculated from predicted camera probe — Only collides with enemies". A sonda do personagem cobre o caso em que "an enemy is standing right in front of the player character, but the reticle technically isn't" sobre ele. Regra: "Reticle is King — If you are using a reticle in your game, and it has shooting, it is expected to be reliable". Ressalva para PvP: "This might not be ideal for competitive 3rd person games" e "Imagine getting shot by another player that is fully hidden behind a corner." ([notas dos slides, PDF](https://media.gdcvault.com/gdc2024/Slides/GDC+slide+presentations/Mattson_Derek_ASecondShot_Notes.pdf); [GDC Vault](https://www.gdcvault.com/play/1034215/A-Second-Shot-Improving-Ranged))
4. **Lyra (amostra da Epic para Unreal)** [F]. O traço padrão da arma usa `ELyraAbilityTargetingSource::CameraTowardsFocus`; um desenvolvedor acrescentou um traço extra da arma até o ponto de impacto para pegar paredes no caminho. ([fórum Unreal](https://forums.unrealengine.com/t/lyra-weapon-wall-trace/1896455))
5. **Unity Cinemachine, 3rd Person Aim** [P]. Na 3.1, a extensão "projects a ray from the camera's position along its forward axis"; o `AimTarget` é "the actual point that the player would hit if it were to fire"; na maioria dos jogos dá para "ignore the discrepancy" e atirar no ponto da câmera, e o deslocamento só importa quando algo bloqueia o jogador mas não a câmera. Na 2.9, com um retículo de alvo, um raio sai "from the Follow target's position" e o retículo vai ao primeiro impacto: "This point may be different from what the camera is looking at, if the found object is close enough to be affected by parallax as a result of the offset between player and camera." ([3.1](https://docs.unity3d.com/Packages/com.unity.cinemachine@3.1/manual/CinemachineThirdPersonAim.html); [2.9](https://docs.unity3d.com/Packages/com.unity.cinemachine@2.9/manual/Cinemachine3rdPersonAim.html))
6. **Fortnite** [S]: traço do centro da câmera e traço da bala, e o "ghost peeking" quando os dois discordam (seção 1.9).
7. **Lista de soluções num fórum da Unity** [F]: atirar do centro da câmera com o cano só visual ("most raycast guns just shoot from the camera center and the model just does muzzle flash"); separar efeito de colisão; misturar a mira central com "just plain forwards over some short distance in front of the player". Desvantagem citada: a mira pela câmera fica "weird at close distances". ([Unity Discussions](https://discussions.unity.com/t/does-anyone-know-of-a-definitive-list-of-weapon-parallax-solutions-for-fps-s/860525))

### 2.3 Falhas conhecidas da solução padrão

- **Atirar através de paredes.** Segundo Smith: "Gears of War 1 tracers play from weapons, but all shots can go through geometry while standing or in cover."; "Gears of War 2 ... Players who are in cover can shoot through walls." [P, afirmação dele] ([Game Developer](https://gamedeveloper.com/design/opinion-adventures-with-guns-in-a-third-person-shooter))
- **Ver e atirar sem ser visto.** Ghost peeking no Fortnite (seção 1.9); a ressalva de Mattson sobre PvP (item 3 acima).
- **Tiro bloqueado sem aviso.** O Deadlock (Valve) mostra um X vermelho na mira: "The red cross would have indicated your bullets being blocked before." [F] ([fórum Deadlock](https://forums.playdeadlock.com/threads/ui-shooting-around-cover-produces-a-big-red-cross-at-your-crosshair-obscuring-targets-from-view.11454)). A Cinemachine faz o mesmo com o retículo no `AimTarget` (item 5).

### 2.4 Os jogos de tiro do briefing que não trouxeram dado

- **Splitgate** é "first-person shooter" ([Wikipedia](https://en.wikipedia.org/wiki/Splitgate)): não tem câmera de ombro.
- **Uncharted** e **The Division**: não achei fonte em texto sobre o método de mira. Na Division 2, clicar o analógico esquerdo troca o ombro (**não confirmado**: trecho de busca) ([God is a Geek](https://godisageek.com/2019/03/the-division-2-10-beginners-tips/)).
- **Template de terceira pessoa da Unreal.** Num tutorial, a vista normal usa `Socket Offset` (0, 0, 0) com braço de 400 cm, e o ombro (0, 55, 30) cm com braço de 180 cm, ligado ao botão direito (`IA_Aim`) [S] ([uhiyama-lab](https://uhiyama-lab.com/en/notes/ue/camera-spring-arm-guide/)). A variante Combat da Unreal 5.6 promete "combat mechanics, enemy targeting" sem explicar como o alvo é escolhido [P] ([Epic](https://dev.epicgames.com/documentation/unreal-engine/variants-in-game-templates)).

### 2.5 O que há de específico para corpo a corpo

- **God of War (2018).** É a única palestra de desenvolvedor sobre trocar para câmera próxima num jogo corpo a corpo. O que temos dela é resumo (**não confirmado**): direção pelo analógico, orientação automática ao alvo escolhido, puxar para o alvo com alcance que cai com o ângulo, trava adicionada tarde (seção 1.6).
- **OpenMW, PR #1425 (2017–2019)** [F, desenvolvedores do projeto]. Com câmera sobre o ombro, as flechas não batiam com a mira. O autor do PR, crussell187, em 14/09/2017: "I've experimented with both and making the camera look at the target works mostly except that the initial targeting for the player is non-intuitive. You have to look slightly to the right of the target so that the camera will rotate to look at what the player is facing." (citação conferida na página pelo orquestrador; a primeira versão deste documento trazia uma paráfrase entre aspas). Outro desenvolvedor insistiu que personagem e câmera "must agree on the aim point". A proposta final foi uma câmera centrada ao sacar a arma, como no Skyrim. ([GitHub](https://github.com/OpenMW/openmw/pull/1425))
- **Taxonomia da Critpoints** [S]. Hard lock: "orients the character and camera to face a target"; deixa o combate "1 dimensional, literally". Soft lock: "Soft-Lock allows players to move in any direction unrestricted, but always attacks accurately", porém "Soft lock is unreliable for targeting, because you can't tell what you're going to attack before you hit the button." ([Critpoints](https://critpoints.net/2015/05/24/what-is-your-ideal-form-of-lock-on-in-action-games/))
- **Golpe pela direção da câmera, não pelo raio:** Warframe ("Align Attacks to Camera") e Monster Hunter Wilds (Focus Mode). O retículo de corpo a corpo do Warframe decide o bloqueio (seções 1.8 e 1.10).
- **Trava e snap no PvP:** For Honor (seção 1.2) e Naraka no controle (seção 1.5).

### 2.6 Números de deslocamento lateral encontrados

| Fonte | Deslocamento lateral | Quando |
|---|---|---|
| Skyrim, INI padrão [S] | 30 unidades (≈ 0,43 m, conta minha, **não confirmado**) | Fora de combate |
| Skyrim, INI padrão [S] | 0 | Em combate |
| Tutorial Godot 4.7, SpringArm3D [S] | 0,5 m para uma cápsula de raio 0,4 m: "Shift it just enough that the center of the screen clears the character's body." Braço de 4,0 m normal e 2,0 m mirando | Ao mirar ([uhiyama-lab](https://uhiyama-lab.com/en/notes/godot/springarm3d-third-person-camera/)) |
| Tutorial Unreal 5 [S] | 0 normal; 0,55 m com braço de 1,8 m | Ao segurar o botão direito, `IA_Aim` ([uhiyama-lab](https://uhiyama-lab.com/en/notes/ue/camera-spring-arm-guide/)) |
| Warframe [P] | Presets Default, Side e Far, sem números publicados | Escolha do jogador |
| Nosso jogo (briefing) | 0,8 m | Sempre |

Erro de mira com a fórmula do briefing, erro = s × (1 − d/c), para a espada (c = 2,0 m). Conta minha; positivo é para a direita.

| s (deslocamento) | d = 0,9 m | d = 1,2 m | d = 3,0 m |
|---|---|---|---|
| 0,8 m (atual) | +0,44 m | +0,32 m | −0,40 m |
| 0,5 m (tutorial Godot) | +0,28 m | +0,20 m | −0,25 m |
| 0,43 m (Skyrim fora de combate) | +0,24 m | +0,17 m | −0,22 m |
| 0 (centrada) | 0 | 0 | 0 |

---

## 3. Centralizar ou trocar de ombro

### 3.1 Quem centraliza, e quando

| Quando | Jogos | Fontes |
|---|---|---|
| Sempre (lateral zero) | Mordhau em terceira pessoa desde junho de 2020; GunZ no relançamento (quase centrado) | Seção 1.3 [F][S]; seção 1.1 [O] |
| Só no combate | Skyrim (centraliza e aproxima); Batman: Arkham Asylum (afasta e centraliza); add-on de fã do ESO (centraliza ao acertar) | [STEP](https://stepmodifications.org/wiki/Guide:Skyrim_INI/Camera); [Buehler](https://www.gamedeveloper.com/design/third-person-camera-view-in-games-a-record-of-the-most-common-problems-in-modern-games-solutions-taken-from-new-and-retro-games) |
| Só ao mirar | Zelda: Tears of the Kingdom (arco) | [80.lv](https://80.lv/articles/tears-of-the-kingdom-s-bow-aiming-camera-explained) |
| Gira a câmera (yaw) para trás do jogador ou para o inimigo no golpe | God of War Ragnarök ("Recenter Camera on Attack"); Naraka ("Camera Shift"); Warframe ("Camera Tracks Melee Target") | Seções 1.6, 1.5 e 1.8 [P] |
| Escolha do jogador | Warframe (Default, Side, Far); AION 2 com "Default keeps your character centered" e uma vista sobre o ombro (**não confirmado**: trecho de busca) | [Warframe 43.0](https://www.warframe.com/patch-notes/pc/43-0-0); [allthings.how](https://allthings.how/aion-2-settings-how-to-change-camera-perspective-and-control-modes/) |

### 3.2 Troca de ombro

- **Fortnite não tem** (2018): "peeking with your left shoulder will put you into situations where you can't see enemies, but they can see you."; "Almost every relevant third-person game released in the past decade has included an option to shoulder swap."; e "Even PLAYERUNKNOWN'S BATTLEGROUNDS ... has an option to shoulder swap." [S] ([DBLTap](https://www.dbltap.com/posts/6018415-fortnite-desperately-needs-an-option-to-shoulder-swap))
- **Warframe tem** "Reverse Camera" [P] (seção 1.8).
- **Ghost Recon Breakpoint**: botão do meio do mouse (**não confirmado**: trecho de busca) ([GameRevolution](https://www.gamerevolution.com/guides/602243-ghost-recon-breakpoint-switch-over-the-shoulder-camera-left-right-shoulder-viewpoint)).
- **Motores**: a Cinemachine tem "Camera Side": "Specifies which shoulder the camera is on (left, right, or somewhere in-between)." [P] ([Unity](https://docs.unity3d.com/Packages/com.unity.cinemachine@2.9/manual/Cinemachine3rdPersonFollow.html))
- **Não achei nenhum jogo PvP corpo a corpo** em que trocar de ombro faça parte do combate.

### 3.3 Prós e contras declarados

| Tema | O que dizem | Fontes |
|---|---|---|
| Oclusão e visão | O deslocamento dificulta alinhar com portas e alvos (ESO) [S]. No Warframe, o preset mais afastado dá "the greatest visibility of the three" [P]. O Mordhau cortou a "extra vision" da terceira pessoa [P, autor não identificado]. Na Dragon Age: The Veilguard, jogadores dizem que o deslocamento esconde inimigos de um lado e pedem câmera centrada (**não confirmado**: trecho de busca; o fórum dá 403). | [Buehler](https://www.gamedeveloper.com/design/third-person-camera-view-in-games-a-record-of-the-most-common-problems-in-modern-games-solutions-taken-from-new-and-retro-games); [Warframe 43.0](https://www.warframe.com/patch-notes/pc/43-0-0); [devtrackers](https://devtrackers.gg/mordhau/p/8e6f6226-ridiculous-spins-drags-delays-exploits); [EA Forums](https://forums.ea.com/discussions/dragon-age-the-veilguard-discussion-en/camera-position/5009060) |
| Legibilidade | Zelda trocou o ombro por clareza ao mirar [S]. No Mordhau, estocadas ficam difíceis de mirar em terceira pessoa [F]. No Chivalry 2, a terceira pessoa ajuda a ler ataques (**não confirmado**). | Seções 1.12, 1.3 e 1.4 |
| Justiça | Câmera de ombro deixa espiar esquinas de um lado só (Fortnite) [S]; o palpite dos jogadores para a centralização do Mordhau foi limitar espiadas [F]; Mattson alerta que sondas que favorecem o atirador podem deixar alguém escondido acertar você [P]. | [DBLTap](https://www.dbltap.com/posts/6018415-fortnite-desperately-needs-an-option-to-shoulder-swap); [Steam](https://steamcommunity.com/app/629760/discussions/0/2572067496656650802); [notas GDC 2024](https://media.gdcvault.com/gdc2024/Slides/GDC+slide+presentations/Mattson_Derek_ASecondShot_Notes.pdf) |
| Enjoo | Um jogador de Mordhau usava a terceira pessoa porque "1st person gives me headache" [F]. Câmera de trava causando enjoo no Warframe e câmera puxando para o alvo no Black Myth (**não confirmado**: trechos de busca). Não achei declaração de desenvolvedor sobre enjoo ligado a centralizar. | [Steam](https://steamcommunity.com/app/629760/discussions/0/2572067496656650802) |

---

## 4. Relatos de jogadores

- **Mordhau, terceira pessoa de ombro (antes de junho de 2020; tópico sem data visível):** "Aiming stabs feels really ahrd in 3rd"; "in fights i always ♥♥♥♥ up the range with third person."; "3rd person in this game is really uncomfortable" [F] ([Steam](https://steamcommunity.com/app/629760/discussions/0/1651043958640598989)).
- **Mordhau, depois de centralizar (2020):** a favor: "The new position does help you be more accurate with your aim, closer to 1st person view.."; contra: "Why to do such drastic change without option to toggle it back." e "Now I need to spend hours to fix my aim and play style." [F] ([Steam](https://steamcommunity.com/app/629760/discussions/0/2572067496656650802)).
- **OpenMW, teste de desenvolvedor (2017):** "the initial targeting for the player is non-intuitive. You have to look slightly to the right of the target" [F] ([GitHub](https://github.com/OpenMW/openmw/pull/1425); conferido pelo orquestrador). É o relato mais próximo do que o Arthur descreveu: mirar um pouco à direita do alvo.
- **ESO:** o disco de mira marca o centro da câmera, não a linha de visão do personagem, e o jogador erra alvos [S] ([Buehler](https://www.gamedeveloper.com/design/third-person-camera-view-in-games-a-record-of-the-most-common-problems-in-modern-games-solutions-taken-from-new-and-retro-games)).
- **Skyrim (fórum da Nexus):** o esquema de câmera torna "an absolute nightmare to try and target an enemy in third person view", e "even melee characters have a hard time" (**não confirmado**: trecho de busca; o fórum dá 403) ([Nexus](https://forums.nexusmods.com/topic/500696-third-person-overhaul)).
- **Dragon Age: The Veilguard:** "the over the shoulder offset drives me up a wall" e pedido de opção de posição horizontal (**não confirmado**: trecho de busca) ([EA Forums](https://forums.ea.com/discussions/dragon-age-the-veilguard-discussion-en/camera-position/5009060)).
- **Fortnite:** pedido de troca de ombro por desvantagem ao espiar pela esquerda [S] ([DBLTap](https://www.dbltap.com/posts/6018415-fortnite-desperately-needs-an-option-to-shoulder-swap)).
- **Dados quantitativos:** não achei telemetria, pesquisa ou números sobre mira corpo a corpo com câmera deslocada.

---

## 5. Leitura: as opções (a) a (f) contra o que os jogos fazem

| Opção | Quem usa (seção) | No PvP corpo a corpo |
|---|---|---|
| (a) Aproximar o ombro do centro | Warframe como escolha do jogador (1.8); Skyrim fora de combate ≈ 0,43 m (1.11); tutoriais usam 0,5 a 0,55 m (2.6) | Não achei caso intermediário documentado; o Mordhau foi direto ao zero. **Raro.** |
| (b) Centralizar sempre, estilo GunZ | Mordhau em terceira pessoa desde 2020 (1.3); GunZ no relançamento (1.1, [O]); Skyrim em combate (1.11) | Mordhau (documentado) e GunZ (por observação). **Comum entre os corpo a corpo encontrados**, com apenas um caso PvP documentado em texto. |
| (c) Centralizar só no corpo a corpo | Skyrim, Batman: Arkham, add-on do ESO (3.1); Zelda só ao mirar o arco | Todos PvE; nenhum caso PvP encontrado. **Raro no PvP.** |
| (d) Convergir na profundidade do alvo sob a mira | Padrão dos jogos de tiro: Monday Night Combat, TLOU2, Lyra, Cinemachine, Fortnite (2.2) | Nenhum jogo corpo a corpo encontrado. Mattson alerta que sondas que favorecem o atirador "might not be ideal" no competitivo. **Não documentado no corpo a corpo.** |
| (e) Soft lock ou magnetismo num cone | For Honor fora da trava (1.2); Naraka no controle (1.5); God of War (1.6); Warframe (1.8); Devil May Cry (1.12) | For Honor e Naraka usam; Mordhau e Chivalry 2 não têm menção nas fontes lidas. **Presente no PvP**, ao lado da trava. |
| (f) Acerto pelo raio da câmera, estilo picareta do Fortnite | Picareta do Fortnite: **não confirmado** (1.9). O mais próximo é golpe pela direção da câmera: Warframe e Monster Hunter Wilds (1.8, 1.10) | Nenhum caso encontrado. **Não documentado.** |
| Fora da lista: trava dura (hard lock) | For Honor, Souls, Naraka no controle, God of War, Black Myth, Devil May Cry, Kingdom Hearts | É a resposta mais frequente no corpo a corpo, PvP incluído (For Honor). |
| Fora da lista: primeira pessoa | Mordhau por padrão (**não confirmado**); Chivalry 2 como opção | Presente nos dois duelos medievais pesquisados. |

**Para olhar com o Arthur (fatos, não decisões):**

- Nos jogos corpo a corpo com câmera de ombro e golpe guiado pela câmera, a mira serve para dar a direção (Warframe, Monster Hunter Wilds) ou fica de lado em favor de trava e puxão (God of War, For Honor, Naraka). Nenhum documenta "o ponto sob a mira é o ponto do acerto" para golpes.
- O único PvP corpo a corpo que mudou a câmera de terceira pessoa (Mordhau) foi para o centro, citando visão extra. Jogadores elogiaram a precisão e reclamaram de ter que reaprender a mira.
- A opção (d) é exatamente o que os jogos de tiro fazem, mas eles têm uma rede de proteção: um segundo traço da arma, indicador de tiro bloqueado e, no TLOU2, uma sonda que só colide com inimigos. O próprio Mattson diz que isso favorece quem ataca e pode não servir para competitivo.
- Com 0,8 m, nosso erro a 1,2 m é 0,32 m. Com o deslocamento do Skyrim fora de combate seria 0,17 m, e com câmera centrada, zero (tabela da seção 2.6).

---

## 6. Páginas que não carregaram e lacunas

**Não abriram (usei outra fonte ou marquei "não confirmado"):** StrategyWiki (403, inclusive a versão raw); Fandom: wikis de GunZ, Mordhau e Fortnite (402); SteamDB (403); Reddit (bloqueado), e um espelho recusou conexão; web.archive.org (bloqueado); upload.wikimedia.org (bloqueado); MobyGames (desafio da Cloudflare); notícia do GDC sobre God of War (404); GameSpot (403); esports.gg (403); Nexus Mods e o fórum da Nexus (403); uxdesign.cc (403); fórum do Warframe (403); fórum da EA (403); icy-veins (403); dsogaming (403); stevivor (403); Twinfinite (403); blog da HyperX (falha de DNS); devtrackers v2 (503); UESP (403); gearsofwar.com (404); Sportskeeda (405).

**Lacunas:**

- **GunZ:** não há descrição em texto da câmera nem de como o golpe escolhe a direção. Só a observação da captura do relançamento.
- **Picareta do Fortnite:** nenhuma fonte primária sobre acerto pelo raio da câmera.
- **Câmera lateral** de Chivalry 2, Naraka, Elden Ring e Monster Hunter Wilds: não verificada.
- **God of War 2018:** o conteúdo da palestra vem de resumo automático; o vídeo completo no GDC Vault pode exigir assinatura.
- **Absolver, Sifu, Lies of P, Hellish Quart:** nada útil em texto nesta rodada.
- **A ideia de golpe-convergência na profundidade do alvo (d) em corpo a corpo** não aparece documentada em lugar nenhum que encontrei. Isso não prova que nenhum jogo faça; prova só que ninguém escreveu sobre isso nas fontes acessíveis.
