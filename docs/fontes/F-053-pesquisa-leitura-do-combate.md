---
id: F-053
titulo: "Pesquisa: a leitura do combate em For Honor, Chivalry 2, Naraka e Sekiro, o limite do reagível, as cores seguras para daltônicos e o som como aviso (07/10/2026)"
recebido_em: 2026-10-07
como: Relatório final de um agente de pesquisa (Opus 5.5, esforço alto) de um workflow de 5 agentes do Claude Code, pedido ao deixar a TASK-7 Ready (sessão 8, 07/10/2026). O §1 está como chegou, em português, com o link de cada afirmação, só com os títulos rebaixados um nível. O §2 é o resumo e a lista do que o agente não confirmou, como chegaram. O §3 traz, para cada afirmação que o agente marcou como importante, o veredicto do verificador adversarial (Fable 5.1, esforço xhigh), que abriu a fonte e citou a frase. O §4 lista as demais afirmações, com o link.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: quatro pesquisadores rodaram em paralelo, cada um com uma lente (licenças, Godot, animação e leitura do combate), e um verificador abriu 40 das 48 afirmações marcadas: 37 confirmadas, 1 refutada (o Standard grátis do UAL1 tem 42 animações, não 45) e 2 não verificáveis (os "60 movimentos" do pack da Synty e a licença do Paragon na Fab). As 8 restantes ficaram sem verificação, pelo limite do workflow. "Não confirmado" no texto quer dizer que o agente não conseguiu abrir a fonte primária. Fatos, inferências e recomendações estão marcados pelo próprio agente. O que vira regra sai da conversa da TASK-7, não daqui.

## §1 — O relatório, como chegou

Data: 07/10/2026. Toda fonte abaixo foi aberta nesta data, a não ser onde está escrito **não confirmado**. O que é fato tem link. O que é minha conclusão vem marcado como **inferência** ou **recomendação**. Isto é pesquisa, não decisão.

Alguns termos, para ler o resto:
- **Leitura** (telegraph): o aviso que o golpe dá antes de pegar, como a animação de cast de uma skill do LoL antes do skillshot sair.
- **Frame a 60 fps** = 16,7 ms, que é o mesmo que um tick nosso (DEC-0024). "18 frames de startup" = 300 ms.
- **Startup** (FGC, a comunidade de jogos de luta): quanto tempo o golpe leva até poder acertar. É a nossa "preparação".
- **Reagível** (*reactable*): dá para ver e responder a tempo, sem adivinhar.
- **Deuteranopia / protanopia:** os dois daltonismos vermelho-verde (falta o cone verde ou o vermelho). **Tritanopia:** azul-amarelo, raro.

---

### 1. Tabela de referência: como os jogos mostram cada sinal

| Jogo | Sinal | Como aparece | Fonte |
|---|---|---|---|
| For Honor | Postura e direção do golpe | Golpe leve ou pesado em 3 direções (esquerda, direita, cima); "ícone vermelho piscando" no inimigo avisa o golpe | [TheGamer](https://www.thegamer.com/for-honor-complete-beginners-guide/) — "Pay attention to the red flashing icon on an enemy" |
| For Honor | Inbloqueável | **Oficial:** "rastro vermelho na arma" mais um símbolo próprio. **Guias e jogadores:** "ícone laranja com uma seta atravessando". As duas descrições divergem na cor | [Ubisoft, Terminology Guide, 2021](https://www.ubisoft.com/en-us/game/for-honor/news-updates/6XEM2qUiwcokp753uCzgkz/for-honor-terminology-guide); [TheGamer](https://www.thegamer.com/for-honor-complete-beginners-guide/) |
| For Honor | Bash (empurrão) | Laranja **sem** indicador de direção = bash, e a resposta é esquivar. Com direção = inbloqueável, e dá para aparar. Fonte de jogadores, não oficial | [Steam, discussão](https://steamcommunity.com/app/304390/discussions/0/3122676324247096622/?l=english) |
| For Honor | Quebra de guarda | "ícone de escudo piscando" | [TheGamer](https://www.thegamer.com/for-honor-complete-beginners-guide/) |
| For Honor | Finta | Hard feint cancela o pesado; soft feint troca de golpe sem o botão de finta. O som e o visual da finta não estão descritos na fonte oficial: **não confirmado** | [Ubisoft, Terminology Guide](https://www.ubisoft.com/en-us/game/for-honor/news-updates/6XEM2qUiwcokp753uCzgkz/for-honor-terminology-guide) |
| For Honor | Daltonismo | O patch 1.09 (jul/2017) adicionou protanopia, deuteranopia e tritanopia na interface, no multiplayer e no "fight feedback" | [TheSixthAxis](https://www.thesixthaxis.com/?p=292419) |
| Chivalry 2 | Preparação (windup) | "o jogador faz um movimento único para sinalizar que está começando o ataque"; na preparação a arma não causa dano | [Chivalry Wiki](https://chivalry.wiki.gg/wiki/Combat_(Chivalry_II)) |
| Chivalry 2 | Som do pesado | "A player performing a heavy attack will also have an extended grunt, which serves as an audio cue." | [Chivalry Wiki](https://chivalry.wiki.gg/wiki/Combat_(Chivalry_II)) |
| Chivalry 2 | "Whoosh" do golpe | Sem fonte que descreva: **não confirmado** | — |
| Chivalry 2 | Riposte e contra-ataque | Janela de ~meio segundo depois do bloqueio; a retícula fica **amarela** ("Riposte Success") e, no contra-ataque, **azul** ("Counter Success"). É confirmação **depois** do lance, não leitura antes | [Chivalry Wiki](https://chivalry.wiki.gg/wiki/Combat_(Chivalry_II)) |
| Chivalry 2 | Finta | Trocar de golpe durante a preparação; "o golpe fintado sai mais rápido" | [Chivalry Wiki](https://chivalry.wiki.gg/wiki/Combat_(Chivalry_II)) |
| Chivalry 2 | Drag | Girar a câmera contra o arco para atrasar a lâmina (manipulação de golpe; a nossa tribo proíbe, DEC-0014) | [Chivalry Wiki](https://chivalry.wiki.gg/wiki/Combat_(Chivalry_II)) |
| Naraka | Focus (carregado) | "Focus attacks are blue aura attacks [...] and can be parried." | [KosGames](https://kosgames.com/naraka-bladepoint-beginners-guide-movement-attacks-2960/) |
| Naraka | Golpe dourado | "gold attacks which work like focus attacks however these cannot be parried" | [KosGames](https://kosgames.com/naraka-bladepoint-beginners-guide-movement-attacks-2960/) |
| Naraka | Golpe comum | Choca com outro comum e não pode ser aparado | [KosGames](https://kosgames.com/naraka-bladepoint-beginners-guide-movement-attacks-2960/) |
| Naraka | Contra-ataque | Os dois botões do mouse juntos. Quem é aparado fica com aura vermelha e solta a arma. Só vi em resumo de busca de guias (PCGamer e outros); a página não abriu: **não confirmado** | — |
| Sekiro | Ataque perigoso | "a red Kanji meaning 'Danger' flashes over Sekiro's head". Quatro tipos (varrida, estocada, agarrão, raio), **o mesmo símbolo para todos**: o tipo se lê pela animação | [Fextralife](https://sekiroshadowsdietwice.wiki.fextralife.com/Combat) |
| Sekiro | Deflect | Guarda até "meio segundo" antes do golpe. A FromSoftware diz que o deflect é "very precise" e exige animações inimigas exatas para "see what's coming [...] and react accordingly". A faísca e o som do deflect não estão descritos em fonte: **não confirmado** | [Fextralife](https://sekiroshadowsdietwice.wiki.fextralife.com/Combat); [GamingBolt](https://gamingbolt.com/sekiro-shadows-die-twice-dev-talks-about-how-combat-differs-from-dark-souls-and-the-challenges-of-developing-it) |
| Elden Ring / Dark Souls | Sem cor, só animação e som | Fonte primária não encontrada; só reclamações de jogadores sobre "delayed attacks" no Steam: **não confirmado** | — |
| Monster Hunter | Tells por animação | Fujioka (Capcom): "When it does this, you know it's going to charge at you"; monstros iniciais com "easy tells" | [VICE](https://vice.com/en/article/the-developers-of-monster-hunter-explain-what-its-like-to-build-monsters) |
| Street Fighter 6 | Drive Impact | 26 frames de startup, "quase meio segundo", "just enough time" para reagir pulando ou com outro Drive Impact. A cor e o som (respingo de tinta, voz) estão só em resumo de busca: **não confirmado** | [Hotspawn](https://www.hotspawn.com/street-fighter/guide/street-fighter-6-drive-system) |
| Street Fighter 6 | Burnout e Drive Rush | Burnout perde todo o sistema Drive; o brilho cinza e o rastro verde estão só em resumo de busca: **não confirmado** | [Dexerto](https://www.dexerto.com/street-fighter/street-fighter-6-drive-gauge-system-2144653/) |
| Overwatch | Jogar pelo som | Palestra GDC 2016 "Overwatch – The Elusive Goal: Play by Sound" (Scott Lawlor, Tomas Neumann) | [GDC Vault](https://gdcvault.com/play/1023010/Overwatch-The-Elusive-Goal-Play) |
| Overwatch | Prioridade na mixagem | Cada jogador recebe uma "importance" na mixagem, que começa pelo tamanho na tela e inclui se ele está mirando em você | [PCGamesN](https://www.pcgamesn.com/overwatch/overwatch-devs-on-creating-a-game-you-can-play-by-sound-and-announcing-dolby-atmos-support) |
| Overwatch | Fala do ultimate | O aliado ouve uma frase, o inimigo outra (Reaper: "Clearing the area" contra "Die, die, die!"). Só fórum de jogadores, sem resposta da Blizzard | [Fórum Blizzard](https://us.forums.blizzard.com/en/overwatch/t/supports-themselves-hear-ult-voice-lines-in-english-why/538419) |
| Overwatch | Cor de equipe | Patch de 09/10/2018: "nine different colorblind-friendly colors", inimigo e aliado separados | [Patch notes](https://overwatch.blizzard.com/en-us/news/patch-notes/live/2018/10/) |
| Overwatch | Silhuetas | Palestra GDC 2017 de Petras e Tsang sobre direção de arte; o resumo não fala de leitura | [Game Developer](https://www.gamedeveloper.com/art/video-defining-and-evolving-the-art-direction-of-i-overwatch-i-) |
| Overwatch | Som do arco do Hanzo ouvido pela vítima | **não confirmado** | — |
| Marvel Rivals | Som da carga do Hawkeye | **não confirmado** | — |
| Tekken | Inbloqueáveis | Jogadores falam de "flashing lights"; o "charge glow" por personagem está só em resumo de busca da wiki | [Steam](https://steamcommunity.com/app/389730/discussions/0/2333276539602033336/) |
| Mortal Kombat | Flash de inbloqueável | **não confirmado** | — |
| League of Legends | Pilar "clarity" | "the ability to understand what's happening in League and respond to it". Zoe Q: "has an audio cue ahead of time". "skins should never be pay-to-win" | [Riot, Clarity in League, 12/03/2021](https://www.leagueoflegends.com/en-gb/news/dev/clarity-in-league/) |
| League of Legends | Silhueta e som | "silhouette, which is basically their shadow"; "certain abilities should be louder than others" | [Riot, Ask Riot](https://www.leagueoflegends.com/en-us/news/dev/ask-riot-let-s-talk-clarity/) |

**Inferência:** os jogos usam duas famílias de leitura.
- **Cor que muda a regra:** For Honor (inbloqueável), Naraka (azul dá para aparar, dourado não) e Sekiro (kanji de perigo). A cor marca a **exceção** ao padrão e diz qual defesa serve.
- **Corpo e som só:** Chivalry 2 e Monster Hunter. A animação de preparação e o grunhido carregam a leitura.

Nenhum dos dois põe cor em tudo. Põem cor no golpe que exige uma resposta diferente.

---

### 2. Princípios com fonte

#### 2.1 Antecipação proporcional ao dano
- **Disney:** "Anticipation is used to prepare the audience for an action" (Thomas e Johnston, 1981, via [Wikipedia](https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation)).
- **GDKeys, "Anatomy of an attack"** (Nicolas Kraj, 25/04/2020): o golpe tem três fases, antecipação, ataque e recuperação, como a nossa preparação, ativo e recuperação. A fórmula é "Anticipation time = (player's reaction time) + (expected player's ability trigger time) + (difficulty buffer)", com reação de base de "0.25 seconds (so around [...] 15 frames in a 60fps one)". Ele recomenda um rastro de VFX na arma para marcar a parte que machuca ([GDKeys](https://gdkeys.com/keys-to-combat-design-1-anatomy-of-an-attack/)).
- **Atenção:** o GDKeys **não** diz que a antecipação deve crescer com o dano. No exemplo do Hornet, o golpe mais curto é o mais perigoso. "Proporcional ao dano" é regra nossa (F-001, DEC-0014), não do GDKeys.

#### 2.2 Três canais redundantes: cor + pose + som
Por que não confiar num canal só:
1. **Daltonismo:** ~8% dos homens (§3).
2. **Visão periférica:** "weak [...] at distinguishing detail, color, and shape", mas "relatively good at detecting motion" ([Wikipedia, Peripheral vision](https://en.wikipedia.org/wiki/Peripheral_vision)). **Inferência:** na luta 4v4, o golpe de quem está no canto da tela é lido pelo **movimento**, não pela cor. A pose tem que ser grande.
3. **A rede:** o oponente aparece no passado. Com ping 100, ~126 ms de atraso na mediana (`docs/arquitetura/rede.md` §5; F-026 §2). A compensação até 200 ms devolve a preparação inteira a quem defende (DEC-0026; `combate.md`). **Inferência:** o tempo existe, mas a leitura tem que estar no estado autoritativo desde o tick 0 da preparação, porque não há previsão do oponente (rede.md §5).
4. **Fora da tela:** em terceira pessoa (DEC-0013), um golpe pelas costas só chega pelo som. **Inferência.**
5. **Acessibilidade:** a WCAG 1.4.1 diz "Color is not used as the only visual means of conveying information" ([W3C](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html)), e as [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/ensure-no-essential-information-is-conveyed-by-a-colour-alone/) repetem a regra e citam o For Honor como bom exemplo de contraste na interface.

#### 2.3 O limite do reagível: números medidos

| Medida | Valor | Fonte |
|---|---|---|
| Reação simples visual, 1.469 pessoas de 18 a 65 anos | 231 ms; **213 ms** descontado o atraso do equipamento (17,8 ms) | [Woods et al., 2015, Frontiers in Human Neuroscience](https://www.frontiersin.org/journals/human-neuroscience/articles/10.3389/fnhum.2015.00131/full) |
| Reação simples, universitários | ~**190 ms** visual, ~**160 ms** auditiva | [Wikipedia, Mental chronometry](https://en.wikipedia.org/wiki/Mental_chronometry) |
| Reação visual e auditiva (Thompson, citado por Jain) | **180–200 ms** visual, **140–160 ms** som; o som chega ao cérebro em 8–10 ms, a imagem em 20–40 ms | [Jain et al., 2015, IJABMR (PMC)](https://pmc.ncbi.nlm.nih.gov/articles/PMC4456887) |
| Human Benchmark (milhões de cliques, com atraso de monitor e mouse) | ~265 ms segundo o Infil; ~273 ms segundo sites secundários. A página do HB não abriu (é renderizada por JavaScript): **não confirmado** na fonte | [Infil](https://ki.infil.net/reaction.html) |
| Limite da FGC | ~265 ms ≈ 16 frames; "it is possible to react to moves that have 16 frames of startup or more quite consistently", mas só esperando **um** golpe específico. "Light auto-doubles" com ~20 frames entre a primeira pista e o fim da janela: "you won't be able to react". Pesados com ~40 frames: reagíveis | [Infil, Killer Instinct guide](https://ki.infil.net/reaction.html) |
| Golpe longo e parado | Golpe de 30+ frames é impossível de reagir se "the first 20 frames has very little movement"; "obvious visual or aural windup tell[s] are easier to react to" | [Infil](https://ki.infil.net/reaction.html) |
| Referência de golpe "no limite" | Drive Impact do SF6: 26 frames (433 ms), "just enough time" | [Hotspawn](https://www.hotspawn.com/street-fighter/guide/street-fighter-6-drive-system) |

**Leitura dos números.** O valor de laboratório (~190–213 ms) é reagir a **um** estímulo esperado. No jogo, quem defende escolhe entre leve, carregado, finta e quebra de guarda: isso é reação de **escolha**, mais lenta (a lei de Hick: mais opções, mais tempo). Ainda falta somar a tela e o input (~18 ms medidos por Woods) e até 1 tick do `TickInterpolator` (rede.md). A faixa do jogador real fica perto dos 250–300 ms do GDKeys e do Infil. **Inferência.**

#### 2.4 Comparação com o v0 (`docs/design/combate.md`) — tudo **inferência**

| Ação v0 | Em ms | Em ticks a 60 | Reagível? |
|---|---|---|---|
| Preparação do leve | 300 | 18 | **Não, para bloquear.** Reação de ~213–273 ms mais os 100 ms do bloqueio dá 313–373 ms, depois do golpe pegar aos 300. Na fórmula do GDKeys sobram 50 ms para "acionar a defesa + folga", menos que os 100 ms do bloqueio. O Infil também classifica 18–20 frames com escolha como não reagível. O leve se defende por **leitura** (guarda já posta, adivinhar) ou pela distância. É coerente com "o básico vence o parry": o leve é o golpe que pune quem espera para reagir |
| Preparação do carregado | 500 a 900 | 30 a 54 | **Sim.** Com 500 ms sobram ~150–230 ms depois da reação e do bloqueio; com 900, muito mais. A condição (Infil): o carregado tem que **parecer diferente do leve nos primeiros ~100 ms** (6 ticks), senão a pessoa só descobre tarde |
| Janela do parry | 80 | ~5 (4,8) | A janela não se acerta por reação ao início do golpe. É **acerto de tempo** em relação ao momento do contato, guiado pela preparação que se vê. Em comparação: o Chivalry dá meio segundo para o riposte e a Fextralife descreve o deflect do Sekiro como "within a half second". Os 80 ms são apertados para um jogo de leitura; anotar para o protótipo, sem mudar número aqui (DEC-0017) |
| Finta | entre 300 e 450 | 18 a 27 | Quem reagiu ao carregado decide perto de 250–300 ms. A finta aos 300–450 corta **depois** desse compromisso: a isca funciona como desenhada. O aviso exigido pela DEC-0016 (ver e ouvir o corte) é o que torna a finta legível, não o que a torna reagível |
| Puxada do arco | até 1.200 | até 72 | Reagível **se a pessoa perceber**. Em terceira pessoa o arqueiro pode estar fora da tela, então o canal é o som (a reação auditiva é ~30–40 ms mais rápida e não depende de para onde se olha) |

---

### 3. Cor segura para daltônicos

#### 3.1 Prevalência
- "affects approximately 1 in 12 men (8%) and 1 in 200 women", com ~300 milhões de pessoas no mundo ([Colour Blind Awareness](https://www.colourblindawareness.org/colour-blindness/)).
- O NIH confirma "About 1 in 12 men" e que o tipo mais comum é vermelho-verde ([NEI/NIH](https://www.nei.nih.gov/learn-about-eye-health/eye-conditions-and-diseases/color-blindness)).
- **Inferência:** num 4v4 só de homens, a chance de pelo menos um dos 8 ser daltônico é de ~50% (1 − (11/12)^8 ≈ 0,50).

#### 3.2 Paletas

**Okabe-Ito** (Masataka Okabe e Kei Ito, Color Universal Design). Hex conforme o código-fonte do R, `grDevices`, que cita o site deles ([R source, colorstuff.R](https://raw.githubusercontent.com/wch/r-source/trunk/src/library/grDevices/R/colorstuff.R)):

| Nome | Hex |
|---|---|
| preto | `#000000` |
| laranja | `#E69F00` |
| azul celeste | `#56B4E9` |
| verde azulado | `#009E73` |
| amarelo | `#F0E442` |
| azul | `#0072B2` |
| vermelhão | `#D55E00` |
| roxo-avermelhado | `#CC79A7` |

O R acrescenta um cinza `#999999` como 9ª cor. O raciocínio dos autores ([jfly, Okabe e Ito](https://jfly.uni-koeln.de/color/)):
- vermelhão "since it is recognizable also to protanopes";
- verde azulado "so that it won't be confused with red or brown";
- "Since violet is close to blue and appear the same to colorblinds, reddish purple is chosen";
- regra-mãe: "do not use the combination of red and green";
- para o protanope, o vermelho escuro "appears almost as black";
- daltônicos distinguem melhor os tons azulados.

**Paul Tol** ([SRON](https://sronpersonalpages.nl/~pault/)):
- "bright", "colour-blind safe": `#4477AA` `#EE6677` `#228833` `#CCBB44` `#66CCEE` `#AA3377` `#BBBBBB`;
- "high-contrast", que funciona até em tons de cinza: `#004488` `#DDAA33` `#BB5566`;
- "vibrant": `#EE7733` `#0077BB` `#33BBEE` `#EE3377` `#CC3311` `#009988` `#BBBBBB`.

**IBM Design Library** (`#648FFF` `#785EF0` `#DC267F` `#FE6100` `#FFB000`): só achei em sites secundários, sem página da IBM. **Não confirmado.**

#### 3.3 Pares a evitar (Okabe e Ito)
- vermelho com verde de brilho parecido;
- verde-amarelado com amarelo;
- violeta com azul;
- cores pouco saturadas entre si (rosa com azul celeste, cinza com azul-claro).

#### 3.4 Contraste (WCAG)
- Texto: 4,5:1, e 3:1 para texto grande ([1.4.3](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)).
- Objetos gráficos e partes da interface: **3:1** contra a cor vizinha ([1.4.11](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html)).
- A conta do contraste usa luminância, "color (hue) is not a key factor". **Inferência:** um token que só muda o matiz, sem mudar o brilho, falha para o daltônico e para a WCAG ao mesmo tempo.

#### 3.5 O que os jogos fazem

| Jogo | O que muda | Fonte |
|---|---|---|
| Overwatch | Desde 2018, cor de equipe escolhida entre 9 em nome, HUD, barras de vida e contorno, com inimigo e aliado separados. Antes era um filtro na tela toda | [Patch 09/10/2018](https://overwatch.blizzard.com/en-us/news/patch-notes/live/2018/10/) |
| Fortnite | Três modos (protanope, deuteranope, tritanope) e um controle de intensidade | [Can I Play That?](https://caniplaythat.com/2022/04/26/fortnite-accessibility-menu-deep-dive/); [AbleGamers APX](https://accessible.games/?p=6018) |
| LoL | Modo daltônico: a própria vida fica amarela em vez de verde, a dos aliados azul. Jogadores protanopes criticam que é pouco | [Gamepressure](https://www.gamepressure.com/newsroom/lol-colorblind-mode-is-useles-for-players-suffering-from-actual-c/za2e03) |
| Valorant | Destaque do inimigo: vermelho (padrão), roxo (tritanopia), amarelo (deuteranopia), amarelo (protanopia) | [eXputer](https://exputer.com/guides/valorant-best-enemy-highlight-color-options/) |
| For Honor | Modos para protanopia, deuteranopia e tritanopia desde 2017 | [TheSixthAxis](https://www.thesixthaxis.com/?p=292419) |

**Inferência:** os melhores trocam a **cor de elementos específicos** (o contorno do inimigo, o token). O filtro na tela inteira é o que o Overwatch abandonou.

#### 3.6 Conjunto candidato de tokens — **recomendação**, a verificar por simulação depois

| Token | Cor | Hex | Por quê |
|---|---|---|---|
| Preparação do **carregado** ("esse dá para aparar") | azul celeste | `#56B4E9` | No eixo azul, que o daltônico vermelho-verde enxerga bem. É também o código do Naraka para o golpe que se apara |
| **Ativo** (o rastro que machuca) | vermelhão | `#D55E00` | É o "vermelho" que a Okabe-Ito escolheu por continuar visível ao protanope. Mais escuro que o azul celeste e que o amarelo, então se separa pelo brilho |
| **Janela ou acerto do parry** | amarelo | `#F0E442` | A cor mais clara da paleta, o brilho máximo, combinando com a faísca e o "clang" |
| **Arma de longe carregada** (puxada do arco) | roxo-avermelhado | `#CC79A7` | Escolhida pelos autores para não se confundir com o azul. Fica longe do vermelhão no eixo azul-amarelo |

Regras que acompanham, também **recomendação**:
- nenhum verde;
- nunca laranja `#E69F00` junto com vermelhão ou amarelo;
- cada token com uma forma ou pose própria e um som próprio (§2.2);
- 3:1 contra o fundo da arena;
- o leve **sem cor**: é o padrão, e a cor marca a exceção, como no For Honor e no Naraka.

**Atenção:** o amarelo e o roxo-avermelhado ficam mais perto um do outro para quem tem tritanopia. É raro, mas a simulação deve checar.

---

### 4. Som como leitura

- **Overwatch, "Play by Sound"** ([GDC Vault, 2016](https://gdcvault.com/play/1023010/Overwatch-The-Elusive-Goal-Play)):
  - pilares de mixagem limpa, som que se localiza e som que informa;
  - "every character in Overwatch has their own unique footstep sound";
  - cada jogador recebe uma "importância" que inclui se está mirando em você ([PCGamesN](https://www.pcgamesn.com/overwatch/overwatch-devs-on-creating-a-game-you-can-play-by-sound-and-announcing-dolby-atmos-support)).
- **LoL:** aviso sonoro antes do golpe (Zoe Q, "audio cue ahead of time") e hierarquia: "certain abilities should be louder than others" ([Clarity](https://www.leagueoflegends.com/en-gb/news/dev/clarity-in-league/); [Ask Riot](https://www.leagueoflegends.com/en-us/news/dev/ask-riot-let-s-talk-clarity/)).
- **Chivalry 2:** o grunhido longo do pesado é o aviso sonoro ([wiki](https://chivalry.wiki.gg/wiki/Combat_(Chivalry_II))).
- **For Honor:** o diretor de áudio Nicholas Duveau fala de "sculpted whooshes for the weapons", e de que a camada de cada personagem "provides some audio feedback" ([MCV/Develop](https://www.mcvuk.com/drums-of-war-for-honors-audio-design/)). Não achei palestra da GDC sobre o áudio do For Honor nem sobre áudio de jogo de luta: **não confirmado**.
- **Prioridade e ducking** (abaixar o resto para um som passar):
  - definição em [Game Developer, 2009](https://www.gamedeveloper.com/audio/game-audio-theory-ducking);
  - HDR audio da DICE e do Wwise: os sons mais altos empurram a "janela" e abaixam os mais baixos (resumo de busca; a página da Audiokinetic deu 403);
  - **no Godot:** o `AudioEffectCompressor` tem `sidechain`, "also known as 'ducking'" ([docs](https://docs.godotengine.org/en/stable/classes/class_audioeffectcompressor.html)). O `AudioStreamPlayer3D.max_polyphony` "will cut off the oldest sounds", e **não existe prioridade** ([docs](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer3d.html)).
- **Arco carregado audível ao alvo** (Hanzo, Hawkeye) e **tom subindo na carga** (Mega Man): **não confirmado**. Não dá para usar como precedente citado.

**Recomendação:**
1. Um barramento (bus) "leitura" com prioridade, que abaixa música e ambiente por sidechain e nunca é cortado pelo limite de vozes.
2. Uma camada de som por token: o "whoosh" da preparação mais longo no carregado, o "clang" do parry como o som mais forte do jogo, o corte audível da finta (DEC-0016) e a puxada do arco ouvida pelo alvo, com direção 3D.
3. Tocar só em tick novo (`is_fresh`), nunca na re-simulação (DEC-0004).

---

### 5. Onde mora o sinal: no mundo ou no HUD

| Jogo | Onde |
|---|---|
| For Honor | **HUD** de guarda (3 direções, ícone vermelho piscando, laranja ou vermelho para o inbloqueável, escudo para a quebra de guarda) mais o rastro na arma |
| Chivalry 2 | **Nenhum** indicador de golpe chegando. A leitura é o movimento e o grunhido; o HUD só confirma depois (retícula amarela ou azul) |
| Naraka | **No corpo:** aura azul, dourada ou vermelha |
| Sekiro | Kanji sobre a cabeça do **próprio** jogador mais a animação do inimigo |
| LoL | VFX no mundo mais áudio, com regra de hierarquia |

Não achei argumento escrito pelos desenvolvedores sobre o HUD do For Honor contra o "sem HUD" do Chivalry: **não confirmado**.

**Inferência e recomendação:**
- O pilar 1 ("nada acontece escondido") e a terceira pessoa pedem o sinal **principal no mundo**: pose, rastro e brilho na arma. É isso que o espectador e o replay (pilar 5) também veem.
- O HUD fica como **redundância** e para o que está **fora da tela**: uma seta na borda para golpe ou flecha pelas costas, como o "red flashing icon" do For Honor, mas preso à direção.
- Dar ao jogador escolher (HUD ligado ou desligado) é uma opção a discutir, não decidida.

---

### 6. Leitura no 4v4: o anel e as cores de equipe

- O `combate.md` prevê "um anel visível" contra o 2 em 1 (F-001). Não achei jogo de referência com esse anel: **não confirmado** como precedente.
- **Cor de equipe:** Overwatch (9 cores, inimigo e aliado em separado), Valorant (vermelho por padrão, com amarelo ou roxo para daltônicos), LoL (no modo daltônico: a própria vida amarela, aliados azuis). Fontes no §3.5.
- **Conflito (inferência):** se o inimigo for vermelho, como no padrão do Valorant, ele colide com o token "ativo" em vermelhão.

**Recomendação:**
- equipe identificada por contorno e anel, com cor ajustável;
- tokens de combate presos à arma e à pose, com cor fixa;
- nenhuma cor de equipe repete um token de combate;
- o anel do 2 em 1 usa **forma** (espessura, segmentos) mais do que cor, porque costuma ser visto na periferia, onde a cor quase não é percebida (§2.2).

---

### 7. O que muda o plano

1. O leve não dá para defender por reação: é leitura.
2. O carregado dá, se a pose se diferenciar no começo da preparação.
3. O som avisa mais rápido e cobre o que está fora da tela, e o Godot não prioriza vozes sozinho.
4. A cor marca a exceção, não tudo.
5. Paleta candidata no eixo azul-amarelo da Okabe-Ito.
6. Cor de equipe separada dos tokens.
7. Antes de citar, conferir a cor do inbloqueável do For Honor e o "arco audível ao alvo".

## §2 — O resumo e o que não foi confirmado, pelo agente

1. O golpe leve (300 ms de preparação, 18 ticks) não dá para defender por reação vendo o início do golpe. Uma pessoa mediana reage em 213 a 273 ms. Somando 100 ms para levantar o bloqueio, a defesa chega em 313 a 373 ms, depois dos 300 ms. Contra o leve, quem defende precisa de leitura antecipada ou de guarda já levantada (inferência a partir de Woods 2015, Infil e GDKeys).
2. O carregado (500 a 900 ms, 30 a 54 ticks) dá para defender por reação, mas só se a pose dele já for diferente da do leve nos primeiros ~100 ms. O Infil mostra que um golpe longo, cujos primeiros 20 frames quase não se mexem, também não dá para reagir. O token "carregado" precisa aparecer no tick 0 da preparação (inferência).
3. O som avisa ~30 a 40 ms mais rápido que a imagem: 160 contra 190 ms segundo a Wikipedia, 140–160 contra 180–200 ms na fonte citada por Jain 2015. Ele também funciona fora da tela. Na câmera em terceira pessoa, o arco e os ataques pelas costas precisam de som próprio e com prioridade de mixagem. O Godot não tem prioridade de voz: com o limite atingido, o AudioStreamPlayer3D corta o som mais antigo, então essa prioridade vai ser nossa.
4. Os jogos da tribo usam três canais redundantes (cor + pose + som). For Honor e Naraka põem cor no golpe que muda a regra: inbloqueável laranja ou vermelho no For Honor; azul (dá para aparar) e dourado (não dá) no Naraka. O Chivalry 2 não tem nenhum indicador de golpe no HUD: usa movimento próprio da preparação e um grunhido longo no pesado.
5. Para combinar com o nosso triângulo (o parry vence o carregado), o Naraka é o modelo mais próximo: a aura azul anuncia "esse dá para aparar".
6. Daltonismo atinge ~1 em 12 homens e 1 em 200 mulheres, a maioria do tipo vermelho-verde. Recomendação: montar os tokens nos eixos azul–amarelo e claro–escuro da Okabe-Ito. Preparação do carregado em #56B4E9, ativo em #D55E00, parry em #F0E442 e arma de longe carregada em #CC79A7. Nada de verde, e laranja e vermelhão nunca juntos. A checagem por simulação fica para depois.
7. A cor da equipe colide com os tokens: Valorant e LoL usam vermelho para o inimigo por padrão. Recomendação: a equipe é identificada por contorno ou anel com cor ajustável, como no Overwatch (9 cores, inimigo e aliado separados, patch de out/2018), e o vermelho não é usado para o time.
8. Pontos que precisam de decisão antes de fechar os tokens. O For Honor tem fontes conflitantes: a Ubisoft escreve "red trail" e a comunidade diz "orange". Também não se confirmou em fonte primária que o arco do Hanzo ou do Hawkeye avise o alvo pelo som, nem o tom subindo na carga do Mega Man. Não dá para citar isso como precedente.

O que o agente não confirmou:

- Human Benchmark: mediana de ~273 ms (ou ~265 ms, segundo o Infil). A página do Human Benchmark é renderizada por JavaScript e não abriu; os números vêm de fontes secundárias.
- For Honor: a cor exata do inbloqueável. A Ubisoft diz 'red trail on the weapon'; guias e jogadores dizem 'orange icon'. As fontes divergem.
- For Honor: o som e o visual da finta, e um argumento dos desenvolvedores sobre o HUD de guarda; não encontrados.
- Chivalry 2: o 'whoosh' da preparação como aviso; nenhuma fonte o descreve.
- Naraka: aura vermelha em quem é aparado, e cor e funcionamento do gancho; só em resumos de busca, porque as páginas (PCGamer, Sportskeeda, ProGameGuides) não abriram.
- Sekiro: a faísca e o som do deflect; nenhuma fonte primária.
- Elden Ring e Dark Souls: a leitura sem cor, só com animação e som; achei só discussões de jogadores no Steam, nenhuma fonte de desenvolvedor.
- Street Fighter 6: as cores do sistema Drive (respingo de tinta no Drive Impact, verde do Drive Rush, cinza do Burnout) e o aviso sonoro do Drive Impact; só em resumos de busca, porque as páginas oficiais da Capcom e do SuperCombo deram 403.
- Overwatch: o som da puxada do arco do Hanzo ouvido pelas vítimas; nenhuma fonte.
- Overwatch: uma palestra específica sobre silhuetas e leitura; a palestra GDC 2017 de arte (Petras e Tsang) existe, mas o resumo não trata de leitura.
- Overwatch: frases de ultimate diferentes para aliado e inimigo; só fórum de jogadores, sem confirmação da Blizzard.
- Marvel Rivals: o som da carga do Hawkeye audível ao alvo; não encontrado.
- Mega Man: o tom subindo durante a carga do tiro, e a cor do brilho por nível; a página da wiki não abriu.
- Mortal Kombat: flash de golpe inbloqueável; não encontrado.
- Tekken: 'charge glow' nos inbloqueáveis; só em resumo de busca da Tekken Wiki (fandom deu 402), e o Steam fala vagamente de 'flashing lights'.
- Paleta IBM Design Library (#648FFF #785EF0 #DC267F #FE6100 #FFB000): achada só em sites secundários, sem página da IBM.
- Palestra da GDC sobre o áudio do For Honor ou sobre áudio de jogos de luta: não encontrada.
- Precedente de um 'anel visível' contra o 2 em 1 em outro jogo: não encontrado.
- Wwise HDR (a janela de dinâmica que abaixa os sons mais baixos): só em resumo de busca, porque a página da Audiokinetic deu 403.

## §3 — As afirmações marcadas como importantes e o veredicto do verificador

- **leitura:C01** — Tempo de reação simples visual médio de 231 ms, ou 213 ms corrigido pelo atraso do equipamento, em 1.469 pessoas de 18 a 65 anos (Woods et al., 2015).
  - Veredicto: **CONFIRMED**. Artigo original (Woods et al., 2015, Frontiers in Human Neuroscience).
  - Lido em: https://www.frontiersin.org/journals/human-neuroscience/articles/10.3389/fnhum.2015.00131/full
  - Trecho: "1469 subjects ranging in age from 18 to 65 [...] Mean SRT latencies were short (231, 213 ms when corrected for hardware delays)"
- **leitura:C02** — Reação simples média de universitários: ~160 ms a estímulo auditivo e ~190 ms a visual.
  - Veredicto: **CONFIRMED**. Frase presente no artigo da Wikipedia (fonte secundária, como a afirmação indica).
  - Lido em: https://en.wikipedia.org/wiki/Mental_chronometry
  - Trecho: "Mean RT for college-age individuals is about 160 milliseconds to detect an auditory stimulus, and approximately 190 milliseconds to detect visual stimulus."
- **leitura:C03** — Jain et al. (2015) citam 180–200 ms para estímulo visual e 140–160 ms para som; o som chega ao cérebro em 8–10 ms e a imagem em 20–40 ms.
  - Veredicto: **CONFIRMED**. Jain et al. (2015), PMC4456887; as frases são citações que o artigo faz de Thompson et al. e de Kemp.
  - Lido em: https://pmc.ncbi.nlm.nih.gov/articles/PMC4456887
  - Trecho: "the mean RT to detect visual stimuli is approximately 180–200 ms, whereas for sound it is around 140–160 ms [...] an auditory stimulus takes only 8–10 ms to reach the brain, but on the other hand, a visual stimulus takes 20-40 ms"
- **leitura:C04** — Na FGC, um golpe com 16 frames de startup ou mais é reagível com consistência quando se espera um golpe específico; a reação média citada é ~265 ms (Human Benchmark).
  - Veredicto: **CONFIRMED**. O texto 'around 265 milliseconds' é um link para humanbenchmark.com/tests/reactiontime/statistics (o nome 'Human Benchmark' não aparece escrito).
  - Lido em: https://ki.infil.net/reaction.html
  - Trecho: "The average human reaction time, if asked to simply press a button on reaction to exactly one easily-identifiable stimulus, is around 265 milliseconds [...] if you were waiting for exactly one particular move from your opponent, and only had to adjust your input barely on reaction to that move [...] it is possible to react to moves that have 16 frames of startup or more quite consistently."
- **leitura:C05** — Daltonismo atinge cerca de 1 em 12 homens (8%) e 1 em 200 mulheres.
  - Veredicto: **não verificada** (ficou fora do limite de 40 afirmações do verificador)
- **leitura:C06** — Hex da paleta Okabe-Ito: #000000, #E69F00, #56B4E9, #009E73, #F0E442, #0072B2, #D55E00, #CC79A7 (o R acrescenta o cinza #999999).
  - Veredicto: **não verificada** (ficou fora do limite de 40 afirmações do verificador)
- **leitura:C07** — No For Honor, segundo a Ubisoft, o golpe inbloqueável é marcado por um rastro vermelho na arma e um símbolo próprio.
  - Veredicto: **não verificada** (ficou fora do limite de 40 afirmações do verificador)
- **leitura:C08** — Guias descrevem o indicador de inbloqueável do For Honor como um ícone laranja com uma seta atravessando (diverge do 'red trail' oficial).
  - Veredicto: **não verificada** (ficou fora do limite de 40 afirmações do verificador)
- **leitura:C09** — No Sekiro, ataques perigosos (inbloqueáveis) são avisados por um kanji vermelho de 'perigo' sobre a cabeça do personagem; o mesmo símbolo vale para os quatro tipos.
  - Veredicto: **não verificada** (ficou fora do limite de 40 afirmações do verificador)
- **leitura:C10** — No Naraka: Bladepoint, o focus attack tem aura azul e pode ser aparado; o golpe dourado funciona igual, mas não pode ser aparado.
  - Veredicto: **não verificada** (ficou fora do limite de 40 afirmações do verificador)
- **leitura:C11** — Palestra GDC 2016 'Overwatch – The Elusive Goal: Play by Sound', de Scott Lawlor e Tomas Neumann.
  - Veredicto: **não verificada** (ficou fora do limite de 40 afirmações do verificador)
- **leitura:C12** — Chivalry 2: na preparação o jogador faz um movimento único; o golpe pesado tem um grunhido longo como aviso sonoro.
  - Veredicto: **não verificada** (ficou fora do limite de 40 afirmações do verificador)

## §4 — As demais afirmações, com o link

- leitura:C13 — Golpes de ~20 frames entre a primeira pista e o fim da janela (light auto-doubles) não são reagíveis; os de ~40 frames são. — https://ki.infil.net/reaction.html
- leitura:C14 — O GDKeys define o tempo de antecipação como reação + tempo de acionar a defesa + folga, com reação de base de 0,25 s (~15 frames a 60 fps). — https://gdkeys.com/keys-to-combat-design-1-anatomy-of-an-attack/
- leitura:C15 — Desde out/2018, o Overwatch permite escolher a cor de equipe entre nove cores seguras para daltônicos, com inimigo e aliado separados. — https://overwatch.blizzard.com/en-us/news/patch-notes/live/2018/10/
- leitura:C16 — A Riot define clareza como entender o que acontece e responder; a Q da Zoe é exemplo de aviso sonoro antecipado; skins nunca podem ser menos claras que a base. — https://www.leagueoflegends.com/en-gb/news/dev/clarity-in-league/
- leitura:C17 — WCAG 1.4.1: a cor não pode ser o único meio visual de transmitir informação. — https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html
- leitura:C18 — WCAG 1.4.11: objetos gráficos e componentes de interface precisam de contraste de pelo menos 3:1 contra as cores vizinhas. — https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html
- leitura:C19 — Okabe e Ito escolheram o roxo-avermelhado porque o violeta parece azul para daltônicos, e recomendam não combinar vermelho com verde. — https://jfly.uni-koeln.de/color/
- leitura:C20 — A visão periférica é fraca para cor e forma, mas relativamente boa para detectar movimento. — https://en.wikipedia.org/wiki/Peripheral_vision
- leitura:C21 — No Godot, o AudioEffectCompressor faz ducking por sidechain; o AudioStreamPlayer3D, ao chegar no max_polyphony, corta os sons mais antigos (não há prioridade). — https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer3d.html
- leitura:C22 — O Drive Impact do SF6 tem 26 frames de startup, tempo apenas suficiente para reagir pulando ou com outro Drive Impact. — https://www.hotspawn.com/street-fighter/guide/street-fighter-6-drive-system
- leitura:C23 — Valorant oferece quatro cores de destaque do inimigo: vermelho (padrão), roxo (tritanopia), amarelo (deuteranopia) e amarelo (protanopia). — https://exputer.com/guides/valorant-best-enemy-highlight-color-options/
- leitura:C24 — Paul Tol: esquema 'bright' seguro para daltônicos, #4477AA #EE6677 #228833 #CCBB44 #66CCEE #AA3377 #BBBBBB. — https://sronpersonalpages.nl/~pault/
- leitura:C25 — O Overwatch dá a cada jogador uma 'importância' na mixagem, que começa pelo tamanho dele na tela de quem ouve. — https://www.pcgamesn.com/overwatch/overwatch-devs-on-creating-a-game-you-can-play-by-sound-and-announcing-dolby-atmos-support
- leitura:C26 — For Honor ganhou modos para protanopia, deuteranopia e tritanopia no patch 1.09 (julho de 2017). — https://www.thesixthaxis.com/?p=292419
- leitura:C27 — No modo daltônico do LoL, a própria barra de vida fica amarela em vez de verde e a dos aliados azul; jogadores protanopes criticam que é insuficiente. — https://www.gamepressure.com/newsroom/lol-colorblind-mode-is-useles-for-players-suffering-from-actual-c/za2e03
- leitura:C28 — Monster Hunter: os monstros iniciais têm tells simples ('When it does this, you know it's going to charge at you'). — https://vice.com/en/article/the-developers-of-monster-hunter-explain-what-its-like-to-build-monsters
