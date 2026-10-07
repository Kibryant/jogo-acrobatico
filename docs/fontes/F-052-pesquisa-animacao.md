---
id: F-052
titulo: "Pesquisa: de onde vêm as animações, sob qual licença, por quanto, como chegam ao Godot 4.7.2 e o tamanho do buraco (07/10/2026)"
recebido_em: 2026-10-07
como: Relatório final de um agente de pesquisa (Opus 5.5, esforço alto) de um workflow de 5 agentes do Claude Code, pedido ao deixar a TASK-7 Ready (sessão 8, 07/10/2026). O §1 está como chegou, em português, com o link de cada afirmação, só com os títulos rebaixados um nível. O §2 é o resumo e a lista do que o agente não confirmou, como chegaram. O §3 traz, para cada afirmação que o agente marcou como importante, o veredicto do verificador adversarial (Fable 5.1, esforço xhigh), que abriu a fonte e citou a frase. O §4 lista as demais afirmações, com o link.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: quatro pesquisadores rodaram em paralelo, cada um com uma lente (licenças, Godot, animação e leitura do combate), e um verificador abriu 40 das 48 afirmações marcadas: 37 confirmadas, 1 refutada (o Standard grátis do UAL1 tem 42 animações, não 45) e 2 não verificáveis (os "60 movimentos" do pack da Synty e a licença do Paragon na Fab). As 8 restantes ficaram sem verificação, pelo limite do workflow. "Não confirmado" no texto quer dizer que o agente não conseguiu abrir a fonte primária. Fatos, inferências e recomendações estão marcados pelo próprio agente. O que vira regra sai da conversa da TASK-7, não daqui.

## §1 — O relatório, como chegou

## Animação: de onde vêm, sob qual licença, por quanto e como chegam ao Godot 4.7.2

Pesquisa para o Desenho 5 (TASK-7). Todas as fontes foram conferidas em **2026-10-07**, salvo quando digo outra data. Cada afirmação tem o link ao lado. Quando eu não consegui abrir a fonte primária, escrevo **não confirmado**. O que é opinião minha aparece marcado como **recomendação** ou **inferência**.

Glossário rápido:
- **Rig / esqueleto:** os ossos dentro do modelo 3D. A animação mexe nos ossos, e a malha acompanha.
- **Retarget:** pegar uma animação feita para um esqueleto e tocar em outro. É como um adaptador de tipos em TypeScript: o formato muda, o dado é o mesmo.
- **Root motion:** a animação carrega o deslocamento do corpo (o clipe "anda sozinho"). **In place:** o clipe fica parado no lugar, e o código move o corpo.
- **Clipe:** uma animação (por exemplo, "golpe leve").

---

### 1. Mixamo (Adobe)

#### 1.1 Está no ar e é grátis?
- **Fato:** o FAQ oficial diz: "Mixamo is available free for anyone with an Adobe ID and does not require a subscription to Creative Cloud". Não funciona com IDs Enterprise/Federated, nem para quem tem código de país da China. [FAQ do Mixamo](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html). A página bloqueia leitura automática (HTTP 403), então li a [cópia do Internet Archive de 2026-09-24](https://web.archive.org/web/20260924203626/https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html). A própria página diz "Last updated on Sep 14, 2021".
- **Não confirmado:** se o mixamo.com está no ar hoje. O site só devolve uma casca em JavaScript ("Loading Mixamo"), e não consigo abri-lo sem navegador e login ([mixamo.com](https://www.mixamo.com/)). Guias de terceiros de 2026 dizem que o serviço segue no ar, sem atualizações relevantes desde 2015 e com uma queda de vários dias em junho de 2025 ([cinevva](https://app.cinevva.com/guides/mixamo-to-blender-2026)). Isso é fonte secundária.
- **Não confirmado:** a contagem de "2.000+ animações". Ela só aparece em agregadores ([Meshy](https://www.meshy.ai/blog/mixamo-alternative)).
- **Auto-rigger** (ele coloca os ossos num modelo sozinho): só funciona com humanoides bípedes em pose neutra, sem apêndices grandes, centrados na origem e com a malha limpa ([FAQ](https://web.archive.org/web/20260924203626/https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html)).

#### 1.2 Licença
- **Fato (FAQ):** "You can use both characters and animations royalty free for personal, commercial, and non-profit projects including: … Create video games." ([FAQ](https://web.archive.org/web/20260924203626/https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html))
- **Fato (post no fórum oficial da Adobe, 2022-09-29, autor TylerG 3D):** "really the only thing you can't do is distribute the raw character and animation files". O post proíbe "Any type of free distribution of character or animation raw files" e diz que "all members of that project team may access and use the file. You may not distribute the files to customers or non-team members" ([fórum Adobe](https://community.adobe.com/questions-696/mixamo-faq-licensing-royalties-ownership-eula-and-tos-589400)). Um post de fórum não é o texto legal, e eu não achei o texto legal específico do Mixamo nos Termos Gerais da Adobe (**não confirmado**).
- **Inferência para nós:** o repositório **privado** no GitHub, com acesso só do time, cabe nessa regra. Se o repositório virar **público**, os FBX do Mixamo dentro dele seriam "distribuição gratuita de arquivo cru", o que é proibido. O jogo exportado (o .pck) é "incorporar num projeto", o que é permitido.

#### 1.3 Problemas conhecidos
| Problema | O que é | Fonte |
|---|---|---|
| Prefixo `mixamorig:` nos ossos | Os nomes não batem com outros rigs; o BoneMap do Godot precisa mapeá-los | [MixaBridge (Asset Library)](https://godotengine.org/asset-library/asset/edit/22944) cita "mixamorig: and mixamorig_ prefixes" |
| Escala 0,01 | O FBX vem em centímetros; aplicar a escala pode quebrar o root motion | **não confirmado** na fonte primária (só em [itch.io](https://itch.io/post/3463127)) |
| Root motion e "In Place" | Os clipes de locomoção têm uma opção "In Place" no site | **não confirmado** (o site exige login) |
| Braços torcidos ou atravessando o corpo depois do retarget | Godot 4.6.2, abril de 2026: "the character's arms … clip through the body"; quem respondeu diz que não acontece com modelo em T-pose | [fórum Godot](https://forum.godotengine.org/t/mixamo-animation-retarget/137067) |
| Personagem Synty com animação Mixamo | Ossos faltando (em roxo no BoneMap) e ombros distorcidos; a solução foi renomear ossos à mão | [fórum Godot, Godot 4.4.1](https://forum.godotengine.org/t/synty-studio-characters-with-mixamo-animations/110613) |

#### 1.4 Caminho até o Godot 4.7.2
- **Fato:** "any FBX file added to a Godot project in Godot 4.3 or later will use the ufbx import method". O FBX2glTF fica só para projetos antigos e "generally not recommend". O glTF 2.0 é o formato marcado como recomendado ([docs 4.7, formatos](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html)).
- **Dois caminhos:**
  - **FBX direto (ufbx):** sem passo extra.
  - **FBX → Blender → glTF:** limpa a armadura, tira o prefixo e acerta a escala. Esse é o caminho que o próprio fórum sugere ([fórum](https://forum.godotengine.org/t/mixamo-animation-retarget/137067)).
- **Recomendação:** glTF via Blender para tudo que vier do Mixamo. Plugins como o MixaBridge seriam uma dependência nova e precisam do ok do Arthur.

### 2. Bibliotecas grátis

#### 2.1 Quaternius: Universal Animation Library (UAL1 e UAL2)
| | UAL1 | UAL2 |
|---|---|---|
| Licença | CC0 ([itch](https://quaternius.itch.io/universal-animation-library); `License.txt` do zip: "CC0 1.0 Universal") | CC0 ([itch](https://quaternius.itch.io/universal-animation-library-2); `License.txt` igual) |
| Total | 120+ | 130+ |
| Grátis (Standard) | 45 (46 clipes no GLB, contando a T-pose) | 42 (43 no GLB, contando a T-pose) |
| Pago | Pro a partir de US$ 9,99 (todos os clipes); Source a partir de US$ 14,99 (.blend) | Source a partir de US$ 14,99 |
| Root motion | Clipes `_RM` separados; "Added Root Motion" em 2026-06-16 ([devlog](https://quaternius.itch.io/universal-animation-library/devlog/1326702/updated-files-v20-new-animation-library)) | "one with full Root Motion and one with Root Motion disabled" ([itch](https://quaternius.itch.io/universal-animation-library-2)) |
| Rig | v2.0 (2026-01-23): "Updated to new rig naming scheme" ([devlog](https://quaternius.itch.io/universal-animation-library/devlog/1326702/updated-files-v20-new-animation-library)) | 65 ossos, nomes no padrão Unreal (`pelvis`, `spine_01`, `upperarm_l`…), com dedos |

Baixei os zips Standard do OpenGameArt ([UAL1](https://opengameart.org/content/universal-animation-library), [UAL2](https://opengameart.org/content/universal-animation-library-2)) e li a lista de clipes dentro dos GLB.
- **UAL1 Standard (clipes de interesse):** `Idle_Loop, Jog_Fwd_Loop, Sprint_Loop, Walk_Loop, Jump_Start, Jump_Loop, Jump_Land, Roll, Roll_RM, Sword_Idle, Sword_Attack, Sword_Attack_RM, Hit_Chest, Hit_Head, Death01, Pistol_Idle_Loop, Pistol_Aim_Up/Neutral/Down, Pistol_Shoot, Pistol_Reload, Punch_Jab, Punch_Cross, Crouch_*`.
- **UAL2 Standard (clipes de interesse):** `Sword_Regular_A, Sword_Regular_A_Rec, Sword_Regular_B, Sword_Regular_B_Rec, Sword_Regular_C, Sword_Regular_Combo, Sword_Block, Sword_Dash_RM, Idle_Shield_Loop, Idle_Shield_Break, Shield_OneShot, Shield_Dash_RM, Melee_Hook, Melee_Hook_Rec, Hit_Knockback(_RM), NinjaJump_Start/Idle_Loop/Land, Slide_Start/Loop/Exit, ClimbUp_1m_RM, OverhandThrow`.
- **Achado:** o zip do UAL1 no OpenGameArt é de março de 2025, com o rig antigo (estilo Rigify, `DEF-hips`…, 53 ossos). O UAL1 v2.0 do itch (2026) trocou para o mesmo esquema de nomes do UAL2. **Recomendação:** baixar do itch, não do OpenGameArt, para os dois pacotes terem um rig só.
- **Achado:** o UAL2 separa o golpe da recuperação (`Sword_Regular_A` + `_Rec`). Isso casa com o nosso formato preparação / ativo / recuperação.

#### 2.2 KayKit Character Animations (Kay Lousberg)
- **Fato:** CC0 ("Creative Commons Zero v1.0 Universal"), com "150+" animações grátis em FBX e glTF. Os rigs são `Rig_Medium` e `Rig_Large`; o Source (.blend) custa a partir de US$ 14,99 ([itch](https://kaylousberg.itch.io/kaykit-character-animations)).
- **Nomes dos clipes:** o itch não lista os clipes, então li os GLB `Rig_Medium_*` de uma [cópia num repositório público](https://github.com/batazor/breakpoint/tree/HEAD/assets/animations). Não sei qual versão é essa cópia (**inferência**: é o pacote atual).
  - **Corpo a corpo:** `Melee_1H_Attack_Chop/Slice_Diagonal/Slice_Horizontal/Stab/Jump_Chop, Melee_2H_Attack_Chop/Slice/Stab/Spin, Melee_2H_Idle, Melee_Block, Melee_Blocking, Melee_Block_Hit, Melee_Block_Attack, Melee_Dualwield_*`
  - **Distância:** `Ranged_Bow_Aiming_Idle, Ranged_Bow_Draw, Ranged_Bow_Draw_Up, Ranged_Bow_Idle, Ranged_Bow_Release, Ranged_Bow_Release_Up, Ranged_1H_Aiming/Shoot/Shooting/Reload, Ranged_2H_Aiming/Shoot/Shooting/Reload`
  - **Movimento:** `Dodge_Forward/Backward/Left/Right, Running_Strafe_Left/Right, Walking_Backwards, Running_HoldingBow, Running_HoldingRifle, Jump_Start/Idle/Land, Jump_Full_Short/Long, Running_A/B`
  - **Geral:** `Hit_A, Hit_B, Death_A, Death_B`
- **Achado:** o rig do KayKit é simples. Ele tem `hips, spine, chest, head, upperarm, lowerarm, wrist, hand, handslot, upperleg, lowerleg, foot, toes` e **não tem pescoço, clavícula nem dedos**. **Inferência:** o retarget para um rig humanoide completo deixa ossos sem par, e os ombros podem ficar rígidos.
- O pacote antigo (v1.2, OpenGameArt) tem outro rig e outros nomes (`Attack(1h)`, `Block`, `DashFront`…) ([OpenGameArt](https://opengameart.org/content/kaykit-character-animations)).

#### 2.3 Outras fontes grátis
| Fonte | Licença | O que tem | Serve? |
|---|---|---|---|
| Kenney Animated Characters 3 | CC0 ([itch](https://kenney-assets.itch.io/animated-characters-3)) | 3 animações: idle, jump, running | Não para combate |
| Rokoko Motion Library | Os assets grátis podem ser usados "including for commercial use" ([263 assets](https://www.rokoko.com/resources/download-263-rokoko-motion-capture-assets)); 100 assets grátis ao criar conta no Rokoko Studio ([página](https://www.rokoko.com/products/motion-library)) | Mocap variado; o pacote de 263 é tema "magia". Exporta FBX para os esqueletos Mixamo e UE | Talvez. A regra de que a licença dura enquanto a conta existir é **não confirmada** (só apareceu em trecho de busca) |
| CMU Mocap | "may be copied, modified, or redistributed without permission" ([FAQ CMU](http://mocap.cs.cmu.edu/faqs.php)) | Mocap cru em ASF/AMC e C3D (BVH só em conversões de terceiros) | Só como material bruto: pede limpeza pesada e não tem golpes de espada de jogo |
| Blender Studio (filmes abertos) | **não confirmado** (a página de licença deu 404) | Personagens de filme, não de jogo | Não |

### 3. Pagos

#### 3.1 Synty ANIMATION - Sword Combat
- **Preço:** US$ 59,99. Li o valor no JSON da loja ([Synty Store](https://syntystore.com/products/animation-sword-combat)), e ele bate com o F-001. A busca também mostrou uma promoção de 70% (US$ 18), que não consegui confirmar na fonte.
- **Conteúdo:** "105 Sword Combat animation FBX files, including RootMotion versions". São **60 movimentos distintos**: os 105 arquivos contam as versões com e sem root motion e "ReturnToIdle" ([loja](https://syntystore.com/products/animation-sword-combat)). Entre eles:
  - golpes: `Attack_LightCombo01A/B/C, Attack_HeavyCombo01A/B/C, Attack_HeavyStab01, Attack_LightFencing01, Attack_LightLeaping01`
  - bloqueio: `Block_Begin/Loop/End`
  - parry: `Parry_F/L/R, Parry_Break, Parry_F_CounterShove, Parry_F_PommelStrike`
  - esquiva e reação: `Dodge_F/B/L/R, Hit_*_React, Hit_*_Stagger, Stun_*, KnockDown_*`
  - morte: `Death_F/B/L/R`
  - troca de arma: `Draw_Sword_*, Sheathe_Sword_*`
- **Limites técnicos (fato, FAQ da loja):**
  - "only supports standard POLYGON characters, POLYGON Kids, and POLYGON Big Rig characters";
  - usa "a prop bone, an extra bone added to the hand", e "You may need to retarget the animations using third-party tools";
  - não há suporte oficial para Unreal, e Godot nem é citado.
- **EULA de compra única, versão de 2026-07-09** ([EULA](https://syntystore.com/pages/one-time-purchase-licence)):
  - "You must not share the source files of any Assets outside your team."
  - "You must not distribute our Assets as stock images or stock art (2D or 3D) or otherwise share them for re-use by third parties."
  - Cada licença inclui "five seats for your Team".
  - A licença "is not limited by game engine".
  - Time, na definição do EULA: "All employees, contractors and other collaborators working in a technical or creative role…"
- **Inferência:** um repositório privado só com o Arthur está dentro da regra. Um repositório público seria compartilhar arquivo-fonte fora do time.

#### 3.2 Fab (Epic)
- **Licença padrão (resumo oficial, "not legally binding"):** "Use the assets with any compatible tools (usage is not limited to Unreal Engine)". "Share the asset (directly, via a private repository or in the Project) with your collaborators". "You may not: Resell or redistribute the asset for free on a standalone basis" ([Fab EULA](https://www.fab.com/eula)). O texto legal completo não carregou sem navegador (**não confirmado**).
- **Paragon (exemplo: Greystone):** a página diz "released to the Unreal Engine community for free to use as you like **in your Unreal Engine projects**!" e "You may not use the trademark PARAGON". O formato incluído é só "Unreal Engine" ([listagem](https://www.fab.com/listings/122fd7bf-6f12-4304-a930-cccbbacdaebc); lida na [cópia de 2025-11-13 do Internet Archive](https://web.archive.org/web/20251113115821/https://www.fab.com/listings/122fd7bf-6f12-4304-a930-cccbbacdaebc), porque a Fab devolve 403). No fórum da Epic, usuários notaram que o selo "UE-only" sumiu na migração para a Fab, e a Epic não respondeu oficialmente ([fórum Epic, 2024-10](https://forums.unrealengine.com/t/fab-ue-only-content-licensing/2082870)).
  - **Recomendação:** não usar Paragon. O texto da própria listagem restringe a "Unreal Engine projects", os arquivos só saem do Unreal com ferramenta extra, e o risco jurídico não compensa.
- **Pacotes de espada na Fab:** a Kubold ("scabbard") venderia One Handed Sword Animset Pro e Two-Handed Katana Animset Pro a partir de US$ 29,99. **Não confirmado**: veio de trecho de busca, e a Fab bloqueia a leitura ([vendedor](https://www.fab.com/sellers/scabbard)).

#### 3.3 Outros
- **Mocap Online:** 22 pacotes; "Mobility (From $12.99)", "Ninja (From $14.99)", "Punch (From $10.99)". A página não lista pacote de espada, e a licença padrão "covers personal, indie & small commercial projects" ([Mocap Online](https://mocaponline.com/collections/all)).
- **Reallusion ActorCore:** existe um "Laser Sword Combat Motion Pack" ([Reallusion](https://discussions.reallusion.com/t/laser-sword-combat-motion-pack-now-available/15890)). Preços (US$ 1,50 a 12 por clipe, até US$ 200 por pacote) **não confirmados**: vêm de notícias de 2020 e 2021.

### 4. Cascadeur em 2026
Fonte: [cascadeur.com/plans](https://cascadeur.com/plans). A página mostra preços em reais para o IP brasileiro, e o FAQ da mesma página lista os preços em dólar.

| Plano | Mensal | Anual (por mês) | Teto de receita | Exportação | Uso comercial |
|---|---|---|---|---|---|
| Free | R$ 0 | — | receita ou financiamento < US$ 100 mil nos 12 meses | **só .casc** ("Export to .casc format only. .fbx and .dae are not available"); 300 quadros e 120 juntas por cena | "Only non-commercial use"; pede crédito ao Cascadeur |
| Indie | R$ 99 (US$ 19) | **R$ 42** (US$ 96/ano) | "The revenue must be less than $100k per year" | O cartão diz FBX e DAE; a tabela diz CASC, FBX, DAE, USD e GLTF | sim, abaixo do teto |
| Pro | R$ 256 (US$ 49) | R$ 172 (US$ 396/ano) | sem limite | CASC, FBX, DAE, USD e GLTF | "Commercial use with no limits" |

- **Correção do F-001:** o F-001 diz "R$ 41/mês no anual". Hoje são **R$ 42/mês no anual** (R$ 504/ano, **inferência** por conta: 42 × 12).
- **Licença perpétua:** um plano anual Indie ou Pro "is automatically converted into a perpetual license after the minimum term of one year". Depois de cancelar, você continua usando a última versão lançada durante a assinatura ([plans](https://cascadeur.com/plans)).
- **De quem é o resultado:** "you retain ownership of the intellectual property rights in the characters, animations, scenes or other content you create" (EULA 6.3, [EULA](https://cascadeur.com/help/cascadeur_end_user_agreement)).
- **Inferência:** o plano Free não serve para nós. Ele só exporta .casc, que o Godot não lê. O Indie é o piso.
- **Caminho até o Godot:** Cascadeur → FBX ou glTF → importador do Godot. Faltam dados de uso real com o Godot 4.7 (**não confirmado**).
- **Curva de aprendizado:** não achei número confiável (**não confirmado**).

### 5. Fazer na mão
- **Versão atual do Blender:** **5.2.2 LTS, de 2026-09-15** ("Blender 5.2.2 LTS … September 15, 2026", [blender.org](https://www.blender.org/download/)). O pedido falava em Blender 4.x, mas a série atual é a 5.
- **Rigify:** vem embutido no Blender e é grátis (**inferência** a partir do conhecimento geral; não abri a página do Rigify).
- **Auto-Rig Pro (Superhive):** US$ 50 o Full (com Remap para retarget e exportação FBX/glTF) e US$ 25 o Lite; 12 meses de suporte, e mais 12 meses custam 25% do preço ([Superhive](https://superhivemarket.com/products/auto-rig-pro)).
- **Horas por animação (dados reais, todos de profissionais ou de fórum):**
  - Estúdio de jogo: "'normal' ranges between 5-10 seconds per day"; algo importante cai para 2 a 4 s por dia ([Animator Island, 2013](https://www.animatorisland.com/how-fast-should-you-animate/)).
  - Fórum de Blender, 2016: "I'm a noob animator but I got like 1 second a day at average"; outro escreve "for a 8 hour work day I could probably achieve -at best- five seconds of relatively polished animation" ([BlenderArtists](https://blenderartists.org/t/animators-how-much-animation-can-you-complete-in-a-day/669818)).
  - Não achei medição feita com amadores de 3D. Os números acima são relatos.
- **Inferência (conta):** um golpe ou manobra tem cerca de 1 s. Um iniciante leva perto de 1 dia (6 a 8 h) por clipe, e um intermediário, de 1 a 2 h. Para 80 clipes, isso dá de 160 a 640 h, ou **16 a 64 semanas** a 10 h por semana. Fazer tudo à mão não cabe no projeto. Fazer à mão só os buracos (cerca de 10 a 20 clipes) cabe.

### 6. O lado do Godot

#### 6.1 Retarget com SkeletonProfileHumanoid e BoneMap
- **Fato:** "When you use SkeletonProfileHumanoid, auto-mapping will be performed when the SkeletonProfile is set" ([docs 4.7](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html)).
- Para compartilhar animação, os nomes **e** as poses de repouso precisam bater. Opções que importam:
  - **Overwrite Axis:** "the most important option for sharing animations in Godot 4".
  - **Fix Silhouette:** liga para modelo em A-pose, dispensa em T-pose.
  - **Remove Unimportant Positions:** evita que a animação deforme o corpo.
  Todas na mesma página ([docs](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html)).
- **Inferência:** UAL1 v2.0 e UAL2 já compartilham o rig, então nem precisam de retarget entre si. Mixamo e Synty precisam. O KayKit tem ossos de menos.

#### 6.2 AnimationTree ou "animação lê o estado"
- **Fato:** o AnimationMixer, base do AnimationPlayer e do AnimationTree, tem o modo `ANIMATION_CALLBACK_MODE_PROCESS_MANUAL`: "Do not process animation. Use advance() to process the animation manually". Ele também tem a propriedade `deterministic` ([docs](https://docs.godotengine.org/en/stable/classes/class_animationmixer.html)). É o caminho do F-007.
- **Recomendação:** a pose sai de uma função do estado, `(modo, tick_de_início, tick_atual) → (clipe, tempo no clipe)`. Pense numa função pura em TypeScript que recebe o estado e devolve o frame. Com isso:
  - o rollback não precisa desfazer nada na animação, porque a cada quadro a pose é recalculada do estado;
  - uma máquina de estados do AnimationTree, com transições e "travel" próprios, viraria um **segundo** estado que o netfox não volta no tempo. Use o AnimationTree no máximo como mixer (misturas e camadas de corpo superior), sem decidir transição;
  - a regra "som e VFX só no tick fresco" continua valendo (DEC-0004).
- **Achado importante (medido nos GLB):** nenhum clipe de biblioteca tem os nossos tempos.

  | Ação | Desenho | Clipe de biblioteca |
  |---|---|---|
  | Golpe leve | 300 / 100 / 250 ms = 650 ms | `Sword_Regular_A` (433 ms) + `Sword_Regular_A_Rec` (967 ms) = 1.400 ms |
  | Recarga da pistola | 2,5 s | `Pistol_Reload` de 1.667 ms |
  | Recarga do mosquete | 3,5 s | `Ranged_2H_Reload` de 1.600 ms |
  | Esquiva | 60 ms + 250 ms invulnerável | `Dodge_*` do KayKit de 400 ms |

  **Inferência:** todo clipe vai ser reajustado no tempo, fase por fase. O tempo no clipe é uma função por trechos do progresso de cada fase, e cada clipe ganha marcas de "início do ativo" e "fim do ativo". Isso respeita o "tempo de animação fixo" (F-001; DEC-0014), porque quem manda é o núcleo. Também pesa a favor de clipes já cortados em fases, como o `_Rec` do UAL2, e a favor de ajustar alguns clipes no Blender ou no Cascadeur.

#### 6.3 In place ou root motion
- O F-007 diz que root motion não dirige a jogabilidade. **Recomendação:** importar sempre a versão in place. O UAL2 entrega as duas versões, o UAL1 tem os `_RM` separados e o Synty tem os dois. O deslocamento do dash, do pulo e da parede vem do núcleo (`movimento.md`). Se um clipe só existir com root motion, o importador pode descartar a trilha de raiz.
- Usar root motion só como **medida** para conferir se o pé escorrega é uma ideia. Fica como pergunta, não como regra.

#### 6.4 O que o issue #553 do netfox implica
- **Fato:** a issue "Synchronized AnimationTree" está aberta desde 2026-01-19, com o rótulo "feature". Um comentário (2026-04-23) diz que sincronizar o esqueleto custaria até cerca de 2.560 bytes por pose, que a solução dele exige modificar o motor, e que ele duvida que dê para fazer como GDExtension ([netfox #553](https://github.com/foxssake/netfox/issues/553)).
- **Inferência:** para nós, a ausência não é problema, porque a animação não é estado de rede. Cada cliente deriva a pose do estado sincronizado (modo e tick de início). O que o #553 deixaria fácil, tocar uma máquina de estados do AnimationTree e sincronizá-la, é justamente o que a DEC-0022 §3 evita.

### 7. O tamanho do buraco (derivado dos documentos)
Fontes: [`docs/design/movimento.md`](docs/design/movimento.md) e [`docs/design/combate.md`](docs/design/combate.md). A lista abaixo é a minha leitura do kit v0, sem número novo de jogo. As colunas de cobertura usam os nomes de clipe que li nos GLB (seção 2). "Std" quer dizer grátis.

#### 7.1 Movimento (cerca de 22)
| Clipe | Qtd | Cobertura grátis hoje |
|---|---|---|
| Parado | 1 | UAL1 `Idle_Loop`; KayKit `Idle_A` |
| Corrida para frente, para trás, esquerda e direita (7 m/s nas quatro, `movimento.md`) | 4 | Frente: UAL1 `Jog_Fwd_Loop`, KayKit `Running_A`. Lados: KayKit `Running_Strafe_Left/Right`. **Trás: falta** (KayKit só tem `Walking_Backwards`); o UAL1 Pro promete "8 directions" (nomes não confirmados) |
| Virar parado (o corpo segue a câmera, F-015) | 2 | **falta** |
| Pulo: saída, subida, queda e aterrissagem | 4 | UAL1 `Jump_Start/Jump_Loop/Jump_Land`; KayKit `Jump_Start/Jump_Idle/Jump_Land` |
| Pulo duplo | 1 | Parcial: UAL2 `NinjaJump_Start` (é um salto de chão) |
| Corrida na parede, esquerda e direita | 2 | **falta** |
| Pulo da parede | 1 a 2 | **falta** |
| Dash em 4 direções (200 ms) | 4 | Parcial: KayKit `Dodge_*` (400 ms); UAL2 `Sword_Dash_RM` |
| Gancho: disparo, puxada e soltura | 3 | **falta** (o UAL2 `OverhandThrow` pode servir de base para o disparo) |

#### 7.2 Espada v0 (cerca de 25)
| Clipe | Qtd | Cobertura grátis hoje |
|---|---|---|
| Guarda parada | 1 | UAL1 `Sword_Idle`; KayKit `Melee_2H_Idle` |
| Corpo de cima com espada durante a corrida | 1 | **falta** (dá para resolver com camada sobre a corrida) |
| Golpe leve (combo e direção não estão no desenho) | 1 a 3 | UAL2 `Sword_Regular_A/B/C` com `_Rec`; KayKit `Melee_1H/2H_Attack_*` |
| Golpe carregado: preparação, segurar (500 a 900 ms), soltura e recuperação | 3 | **falta** a divisão; o KayKit `Melee_2H_Attack_Chop` serve de base para editar |
| Bloqueio: entrar, manter, levar o golpe | 3 | UAL2 `Sword_Block`; KayKit `Melee_Block`, `Melee_Blocking`, `Melee_Block_Hit` |
| Parry: tentativa, acerto, erro (400 ms) | 2 a 3 | **falta** no grátis (o Synty tem `Parry_F/L/R`, `Parry_Break`) |
| Esquiva | 1 a 4 | KayKit `Dodge_*`; UAL1 `Roll` |
| Quebra de guarda (350 / 100 / 400) e quem sofre a quebra | 2 | Parcial: UAL2 `Shield_OneShot`, `Melee_Hook`; quem sofre: UAL2 `Idle_Shield_Break` |
| Finta (corta a preparação) | 1 | **falta** (pode ser uma mistura de volta para a guarda) |
| Quem levou parry fica atordoado | 1 | **falta** no grátis (o Synty tem `Stun_*`) |
| Reações a golpe (frente, costas e lados) | 2 a 4 | UAL1 `Hit_Chest/Hit_Head`; KayKit `Hit_A/B`; UAL2 `Hit_Knockback` |
| Morte | 1 a 2 | UAL1 `Death01`; KayKit `Death_A/B` |
| Troca de arma (700 ms, sem cancelamento) | 2 a 4 | **falta** no grátis (o Synty tem `Draw/Sheathe_Sword`) |

#### 7.3 Arco, pistola e mosquete (cerca de 22)
| Arma | Clipes | Cobertura grátis hoje |
|---|---|---|
| Arco | mirar parado, puxar (até 1.200 ms), segurar, soltar, encaixar flecha, mira para cima/baixo, correr com arco | KayKit `Ranged_Bow_Idle/Aiming_Idle/Draw/Draw_Up/Release/Release_Up`, `Running_HoldingBow`. **Falta**: encaixar a flecha |
| Pistola | mirar, atirar, recarga (2,5 s), mira em 3 alturas, sacar e guardar | UAL1 `Pistol_Idle_Loop/Aim_Up/Neutral/Down/Shoot/Reload`; KayKit `Ranged_1H_*`. **Falta**: sacar e guardar |
| Mosquete | mirar, atirar (coice), recarga (3,5 s, carregar pela boca), correr | Parcial: KayKit `Ranged_2H_Aiming/Shoot/Reload`, `Running_HoldingRifle`. **Falta**: recarga de antecarga |

#### 7.4 Transições (cerca de 8 a 12)
Parado ↔ guarda, chão → parede, parede → ar, gancho → ar, aterrissar e correr, bloqueio ↔ guarda, e assim por diante. Em geral se resolvem com mistura (crossfade) calculada pelo tick; quando a mistura fica feia, viram clipe.

#### 7.5 Conta
- **Mínimo do v0:** cerca de 22 + 25 + 22 + 8 = **cerca de 77 a 80 clipes**. Com 8 direções na locomoção, combos de 3 golpes, reações em 4 direções e variações de corpo de cima, passa de **120 a 150**. O "80 a 150" do F-001 se sustenta.
- **Cobertura grátis (UAL1, UAL2 e KayKit, Standard):** inferência por contagem nas tabelas acima. Cerca de metade tem algo aproveitável, mas quase sempre com tempo errado (6.2) e às vezes em rigs diferentes.
  - **Buracos sem fonte grátis:** corrida na parede (2), pulo da parede, gancho (3), virar parado (2), divisão do carregado, parry (2 a 3), finta, atordoado, troca de arma e recarga do mosquete. São **cerca de 15 a 18 clipes**, exatamente a parte que dá identidade ao jogo.
  - O Synty Sword Combat fecha boa parte dos buracos de espada (parry, atordoado, troca), ao custo do rig POLYGON com osso de prop.

### 8. Recomendações (minhas, não decisão)
1. **Base CC0 com um rig só:** UAL1 v2.0 (do itch) + UAL2. O CC0 permite guardar no repositório até se ele ficar público, sem trava de time.
2. **Complemento:** KayKit para arco e armas, retargetado. Antes, um teste rápido de como fica no rig da base, porque faltam pescoço, clavícula e dedos.
3. **Buracos de identidade (parede, gancho, carregado, parry, finta):** feitos à mão ou ajustados, no Cascadeur Indie (R$ 42/mês no anual, com licença perpétua depois de 12 meses) ou no Blender 5.2 com Rigify (grátis).
4. **Mixamo e Synty:** só se o repositório continuar privado e o Arthur aceitar registrar no `assets/CREDITS.md` que eles travam a abertura do repositório. Paragon: não.
5. **Arquitetura:** a pose como função pura do estado; clipes in place com marcas de fase; nada de máquina de estados no AnimationTree (DEC-0022 §3; F-007).

## §2 — O resumo e o que não foi confirmado, pelo agente

1. O buraco se confirma pelos documentos: o kit v0 de movimento.md e combate.md pede de 77 a 80 clipes no mínimo e de 120 a 150 com direções e combos. O "80 a 150" do F-001 se sustenta.
2. A cobertura grátis tem nome e licença conferidos: Quaternius UAL1 e UAL2 (CC0; 45 e 42 clipes grátis, 120+ e 130+ no total) e KayKit Character Animations (CC0, 150+). Arco, pistola, pulo, bloqueio, esquiva, reação e morte existem. Corrida na parede, gancho, pulo da parede, parry, finta, divisão do carregado e troca de arma não existem em nenhuma fonte grátis: são cerca de 15 a 18 clipes, justamente os de identidade.
3. Nenhum clipe de biblioteca tem os nossos tempos (exemplo: o golpe leve do UAL2 dura 1.400 ms contra 650 ms no desenho). Todo clipe vai ser reajustado fase por fase, com o tempo vindo do estado. Isso reforça a pose como função pura do estado (F-007; DEC-0022 §3) e descarta uma máquina de estados no AnimationTree. O netfox #553 continua aberto e não nos afeta.
4. Rig: UAL1 v2.0 (itch, 2026) e UAL2 compartilham o rig de nomes estilo Unreal. O zip do UAL1 no OpenGameArt ainda é o rig antigo de 2025. O KayKit não tem pescoço, clavícula nem dedos.
5. Licença e repositório: Mixamo (grátis com Adobe ID, royalty-free para jogos) e Synty (EULA de 2026-07-09: "must not share the source files … outside your team") só cabem em repositório privado. CC0 cabe em qualquer um. O Paragon na Fab diz "in your Unreal Engine projects" e só vem em formato Unreal: evitar.
6. Cascadeur: o Indie custa R$ 42/mês no anual (não R$ 41, como diz o F-001) ou R$ 99 no mensal, com teto de receita de US$ 100 mil, licença perpétua depois de 12 meses no anual e a animação sendo de quem a fez. O Free só exporta .casc e não serve.
7. O Blender atual é o 5.2.2 LTS (2026-09-15), não um 4.x. O Auto-Rig Pro custa US$ 50 (Full) ou US$ 25 (Lite). Fazer 80 clipes à mão custaria de 16 a 64 semanas a 10 h/semana (inferência a partir de relatos de 1 a 5 s de animação por dia), o que não cabe. Fazer só os buracos cabe.
8. O Godot 4.7 importa FBX pelo ufbx desde a 4.3 e marca o glTF como recomendado. O retarget por SkeletonProfileHumanoid funciona, mas o fórum relata braços torcidos com Mixamo fora de T-pose.

O que o agente não confirmou:

- Se o site mixamo.com está no ar em outubro de 2026 (devolve só uma casca em JS; o FAQ foi lido na cópia do Internet Archive de 2026-09-24, porque a Adobe devolve 403)
- Contagem de 2.000+ animações do Mixamo (só agregadores)
- Opção 'In Place' e escala 0,01 do FBX do Mixamo (só fontes de comunidade; o site exige login)
- Texto legal específico do Mixamo nos Termos Gerais da Adobe sobre redistribuição (só o post do fórum oficial)
- Nomes dos clipes pagos (Pro/Source) do UAL1 e UAL2, inclusive se há corrida na parede no 'parkour'
- Versão exata do pacote KayKit lido do repositório de terceiros
- Promoção de 70% (US$ 18) do Synty Sword Combat
- Texto legal completo do EULA da Fab (só o resumo não vinculante carregou)
- Preços dos animsets de espada da Kubold na Fab (a partir de US$ 29,99, só em trecho de busca)
- Preços do Reallusion ActorCore (US$ 1,50 a 12 por clipe, até US$ 200 por pacote, de notícias de 2020-2021)
- Licença da Rokoko atrelada à existência da conta (só em trecho de busca)
- Licença dos assets do Blender Studio (a página de licença deu 404)
- Curva de aprendizado do Cascadeur e o caminho Cascadeur → Godot 4.7 na prática
- Formatos de exportação do Cascadeur Indie: o cartão diz FBX e DAE, a tabela diz CASC, FBX, DAE, USD e GLTF
- Horas por animação medidas com amadores de 3D (só há relatos de fórum e números de estúdio)
- Rigify embutido no Blender 5.2 (conhecimento geral, página não aberta)

## §3 — As afirmações marcadas como importantes e o veredicto do verificador

- **animacao:C01** — O Mixamo é grátis para quem tem Adobe ID, sem assinatura do Creative Cloud (indisponível para IDs Enterprise/Federated e para a China)
  - Veredicto: **CONFIRMED**. A página viva devolve HTTP 403 a clientes automáticos (WebFetch, curl com vários User-Agents e locales); lido na captura do Internet Archive de 2026-09-24 da mesma URL (página 'Last updated on Sep 14, 2021').
  - Lido em: https://web.archive.org/web/20260924203626id_/https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html
  - Trecho: "Mixamo is available free for anyone with an Adobe ID and does not require a subscription to Creative Cloud. The following restrictions apply: Mixamo is not available for Enterprise and Federated IDs. Mixamo is not available for users who have a country code from China."
- **animacao:C02** — Personagens e animações do Mixamo podem ser usados sem royalties, inclusive comercialmente e em jogos
  - Veredicto: **CONFIRMED**. Mesma captura do Internet Archive (2026-09-24) da FAQ oficial, já que a página viva bloqueia clientes automáticos (403).
  - Lido em: https://web.archive.org/web/20260924203626id_/https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html
  - Trecho: "You can use both characters and animations royalty free for personal, commercial, and non-profit projects including: Incorporate characters into illustrations and graphic art. 3D print characters. Create films. Create video games."
- **animacao:C03** — Mixamo: é proibido distribuir os arquivos crus de personagem e animação, mesmo de graça; o time do projeto pode compartilhar (post no fórum oficial da Adobe, não é texto legal)
  - Veredicto: **CONFIRMED**. Citações conferem. Ressalva: o post original (2022-09-29) é de 'TylerG 3D', com selo 'Inspiring' (membro da comunidade, não funcionário Adobe), reproduzindo uma FAQ antiga do Mixamo; a ressalva 'não é texto legal' da afirmação está correta.
  - Lido em: https://community.adobe.com/questions-696/mixamo-faq-licensing-royalties-ownership-eula-and-tos-589400
  - Trecho: "Any type of free distribution of character or animation raw files [...] really the only thing you can't do is distribute the raw character and animation files [...] If you download an asset for a team then all members of that project team may access and use the file. You may not distribute the files to customers or non-team members however."
- **animacao:C04** — Quaternius UAL1: CC0, 120+ animações, 45 no Standard grátis, Pro a partir de US$ 9,99
  - Veredicto: **REFUTED**. CC0 ('Creative Commons Zero v1.0 Universal'), '120+ animations' e Pro 'if you pay $9.99 USD or more' conferem no itch. O número 45 não aparece na página do itch; só no texto antigo do autor no OpenGameArt ('the Standard version which includes 45 of those animations'). O zip Standard atual (baixado do itch em 2026-10-07, v3.0 de 16/6/2026) contém em UAL1_Standard.glb 43 tracks de animação, sendo uma 'A_TPose': 42 animações, não 45.
  - Lido em: https://quaternius.itch.io/universal-animation-library
  - Trecho: "Universal Animation Library[Standard].zip 15 MB Universal Animation Library[Pro].zip 41 MB if you pay $9.99 USD or more [...] Asset license Creative Commons Zero v1.0 Universal"
- **animacao:C05** — Quaternius UAL2: CC0, 130+ animações, 42 no Standard grátis, com versões com e sem root motion
  - Veredicto: **CONFIRMED**. CC0, 130+ e as duas versões de root motion conferem no itch. O número 42 não está no texto da página; foi verificado no zip Standard baixado do itch (2026-10-07): UAL2_Standard.glb e UAL2_Standard_RM.glb têm 43 tracks cada, sendo uma 'A_TPose', ou seja, 42 animações.
  - Lido em: https://quaternius.itch.io/universal-animation-library-2
  - Trecho: "The Universal Animation Library 2 is a kit of 130+ animations [...] Now including two versions, one with full Root Motion and one with Root Motion disabled. [...] Free to use in personal, educational and commercial projects. (CC0 License)"
- **animacao:C06** — KayKit Character Animations: CC0, 150+ animações grátis, nos rigs Rig_Medium e Rig_Large
  - Veredicto: **CONFIRMED**. Página do itch: 150+ animações grátis, CC0, rigs Rig_Medium e Rig_Large.
  - Lido em: https://kaylousberg.itch.io/kaykit-character-animations
  - Trecho: "FREE : Free! includes 150+ Humanoid character animations, that are completely free to use in any project of your choosing (yes, also commercially). [...] The animations are split up per rig type, currently Rig_Medium and Rig_Large [...] Asset license Creative Commons Zero v1.0 Universal"
- **animacao:C07** — Synty ANIMATION - Sword Combat custa US$ 59,99 e tem 105 arquivos FBX (60 movimentos distintos), só para rigs POLYGON e com osso de prop
  - Veredicto: **UNVERIFIABLE**. Preço '$59.99 USD', '105 Sword Combat animation FBX files, including RootMotion versions', restrição a rigs POLYGON ('this pack only supports standard POLYGON characters, POLYGON Kids, and POLYGON Big Rig characters'; 'do not work with SIMPLE characters') e o prop bone conferem. O número '60 movimentos distintos' não aparece na página da Synty nem na listagem da Unity Asset Store; a página fala em '105 Sword Combat essential animations'.
  - Lido em: https://syntystore.com/products/animation-sword-combat
  - Trecho: "105 Sword Combat animation FBX files, including RootMotion versions, designed for a complete combat system [...] ANIMATION - Swords Combat animations make use of a prop bone, an extra bone added to the hand."
- **animacao:C08** — O EULA de compra única da Synty (2026-07-09) proíbe compartilhar arquivo-fonte fora do time e compartilhar assets para reuso por terceiros
  - Veredicto: **CONFIRMED**. Mesma EULA de licencas:C05, 'One Time Purchase Licence [Current]', 9 July 2026.
  - Lido em: https://syntystore.com/pages/one-time-purchase-licence
  - Trecho: "You must not share the source files of any Assets outside your team. [...] you must not distribute our Assets as stock images or stock art (2D or 3D) or otherwise share them for re-use by third parties."
- **animacao:C09** — Os assets Paragon na Fab (exemplo: Greystone) são liberados para uso em projetos Unreal Engine, só em formato Unreal
  - Veredicto: **UNVERIFIABLE**. Não consegui ler a listagem na Fab: fab.com responde com desafio Cloudflare (403) ao WebFetch e ao curl, inclusive na API /i/listings; as capturas do Internet Archive (2025-02-19 e 2025-11-13) são só a casca da SPA sem o texto; não há captura da API; a página antiga docs.unrealengine.com/marketplace/.../paragon-greystone devolve 403; a doc da Epic sobre conteúdo grátis só diz que os assets de Paragon são distribuídos como conteúdo grátis na Fab, sem citar licença ou formato. Um trecho de busca reproduz a frase da afirmação, mas não é leitura da fonte.
  - Lido em: https://www.fab.com/listings/122fd7bf-6f12-4304-a930-cccbbacdaebc
  - Trecho: ""
- **animacao:C10** — Cascadeur: Indie a R$ 99/mês ou R$ 42/mês no anual (US$ 19 ou US$ 96/ano), receita abaixo de US$ 100 mil; Pro a R$ 256 ou R$ 172; o Free só exporta .casc e é não comercial
  - Veredicto: **CONFIRMED**. Página de planos exibida em R$ (geolocalizada); o JSON-LD da FAQ embutida na mesma página traz os valores em dólar: 'Indie: Yearly - $96, Monthly - $19' e 'Pro: Yearly - $396, Monthly - $49'. Free: 'Export to .casc format only. .fbx and .dae are not available Only non-commercial use'. Pro: 'R$ 256 per month R$ 172 per month billed annually'.
  - Lido em: https://cascadeur.com/plans
  - Trecho: "R$ 99 per month R$ 42 per month billed annually Gives access to a Perpetual license Get Indie Everything on Free, plus: Export to .fbx and .dae Priority support The revenue must be less than $100k per year"
- **animacao:C11** — A versão estável atual do Blender é a 5.2.2 LTS, de 15 de setembro de 2026
  - Veredicto: **CONFIRMED**. Versão e data conferem. Os tamanhos mostrados são 348 MB (Windows Installer), 227 MB (Windows ARM) e 330 MB (macOS Apple Silicon); o '89 MB' da citação da afirmação não corresponde a nenhum build exibido, mas a afirmação em si (5.2.2 LTS, 15 set 2026) está correta.
  - Lido em: https://www.blender.org/download/
  - Trecho: "Download Blender Windows Installer 5.2.2 LTS 348 MB September 15, 2026"
- **animacao:C12** — No Godot 4.3 ou mais novo, todo FBX é importado pelo ufbx; o FBX2glTF não é recomendado
  - Veredicto: **CONFIRMED**. Doc stable (4.7).
  - Lido em: https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html
  - Trecho: "By default any FBX file added to a Godot project in Godot 4.3 or later will use the ufbx import method. [...] If you want to setup the FBX2glTF workflow, which is generally not recommend unless you have a specific reason to use it"

## §4 — As demais afirmações, com o link

- animacao:C13 — Licença padrão da Fab (resumo): uso fora da Unreal permitido, compartilhar via repositório privado com colaboradores, proibido redistribuir o asset avulso — https://www.fab.com/eula
- animacao:C14 — Cascadeur: o plano anual Indie ou Pro vira licença perpétua depois de 12 meses — https://cascadeur.com/plans
- animacao:C15 — Cascadeur: o usuário mantém a propriedade das animações que cria — https://cascadeur.com/help/cascadeur_end_user_agreement
- animacao:C16 — Cascadeur Free: exportação limitada a 300 quadros e 120 juntas por cena, só em .casc — https://cascadeur.com/plans
- animacao:C17 — Auto-Rig Pro: US$ 50 (Full, com Remap) e US$ 25 (Lite) — https://superhivemarket.com/products/auto-rig-pro
- animacao:C18 — O UAL1 v2.0 (2026-01-23) trocou o esquema de nomes do rig — https://quaternius.itch.io/universal-animation-library/devlog/1326702/updated-files-v20-new-animation-library
- animacao:C19 — Com SkeletonProfileHumanoid, o BoneMap faz mapeamento automático; Overwrite Axis é a opção mais importante para compartilhar animação — https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html
- animacao:C20 — O AnimationMixer tem um modo manual que só avança via advance() — https://docs.godotengine.org/en/stable/classes/class_animationmixer.html
- animacao:C21 — A issue #553 do netfox (Synchronized AnimationTree) está aberta, e a proposta de solução exige modificar o motor — https://github.com/foxssake/netfox/issues/553
- animacao:C22 — Os dados de mocap da CMU podem ser copiados, modificados e redistribuídos sem permissão — http://mocap.cs.cmu.edu/faqs.php
- animacao:C23 — Os assets grátis da Rokoko podem ser usados comercialmente — https://www.rokoko.com/resources/download-263-rokoko-motion-capture-assets
- animacao:C24 — Kenney Animated Characters 3: CC0, só 3 animações (idle, jump e running) — https://kenney-assets.itch.io/animated-characters-3
- animacao:C25 — Ritmo de animação em estúdio de jogo: 5 a 10 s por dia — https://www.animatorisland.com/how-fast-should-you-animate/
- animacao:C26 — Relato de animador iniciante em fórum de Blender: cerca de 1 s de animação por dia — https://blenderartists.org/t/animators-how-much-animation-can-you-complete-in-a-day/669818
- animacao:C27 — Retarget de Mixamo no Godot 4.6.2: braços atravessando o corpo; quem respondeu diz que não acontece com modelo em T-pose — https://forum.godotengine.org/t/mixamo-animation-retarget/137067
- animacao:C28 — Mocap Online: pacotes a partir de US$ 10,99 a 14,99; nenhum pacote de espada no catálogo — https://mocaponline.com/collections/all
- animacao:C29 — Nomes e durações dos clipes do UAL1 e UAL2 Standard (por exemplo, Sword_Regular_A = 433 ms e _Rec = 967 ms), lidos dos GLB do zip do OpenGameArt — https://opengameart.org/content/universal-animation-library-2
- animacao:C30 — Nomes dos clipes do KayKit Rig_Medium (Melee_Block, Ranged_Bow_Draw, Dodge_Forward…), lidos de uma cópia num repositório de terceiros — https://github.com/batazor/breakpoint/tree/HEAD/assets/animations
