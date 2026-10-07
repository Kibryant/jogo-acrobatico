---
id: F-050
titulo: "Pesquisa: fontes de assets e licenças, conferidas na origem, e a cota do Git LFS no GitHub Free (07/10/2026)"
recebido_em: 2026-10-07
como: Relatório final de um agente de pesquisa (Opus 5.5, esforço alto) de um workflow de 5 agentes do Claude Code, pedido ao deixar a TASK-7 Ready (sessão 8, 07/10/2026). O §1 está como chegou, em português, com o link de cada afirmação, só com os títulos rebaixados um nível. O §2 é o resumo e a lista do que o agente não confirmou, como chegaram. O §3 traz, para cada afirmação que o agente marcou como importante, o veredicto do verificador adversarial (Fable 5.1, esforço xhigh), que abriu a fonte e citou a frase. O §4 lista as demais afirmações, com o link.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: quatro pesquisadores rodaram em paralelo, cada um com uma lente (licenças, Godot, animação e leitura do combate), e um verificador abriu 40 das 48 afirmações marcadas: 37 confirmadas, 1 refutada (o Standard grátis do UAL1 tem 42 animações, não 45) e 2 não verificáveis (os "60 movimentos" do pack da Synty e a licença do Paragon na Fab). As 8 restantes ficaram sem verificação, pelo limite do workflow. "Não confirmado" no texto quer dizer que o agente não conseguiu abrir a fonte primária. Fatos, inferências e recomendações estão marcados pelo próprio agente. O que vira regra sai da conversa da TASK-7, não daqui.

## §1 — O relatório, como chegou

Pesquisa feita em 2026-10-07. Cada fato tem o link da fonte primária que eu abri. Quando escrevo **recomendação** ou **inferência**, a opinião é minha e não está na fonte. "Não confirmado" quer dizer que não consegui abrir a fonte primária.

Três termos aparecem em todo o relatório:
- **CC0**: o autor abre mão de todos os direitos. É como uma lib MIT sem nem a exigência de manter o aviso.
- **CC BY**: você pode tudo, desde que dê crédito.
- **EULA**: um contrato próprio da loja. É como os termos de uso de uma skin do LoL: você ganha o direito de usar, não o arquivo.

### 1. 3D e personagens

| Fonte | O que oferece | Licença | Comercial / modificar / no build | Atribuição | Preço | Repo público depois? |
|---|---|---|---|---|---|---|
| Kenney | 3D, 2D, UI, áudio, fontes | CC0 1.0 | sim / sim / sim | não exigida | packs grátis; All-in-1 US$ 19,95+ | sim (CC0) |
| Quaternius | 3D low-poly, personagens, animações | CC0 1.0 | sim / sim / sim | não exigida | grátis; Pro US$ 9,99+, Source US$ 14,99+ | sim (CC0) |
| KayKit (Kay Lousberg) | 3D estilizado, personagens, animações | CC0 1.0 (packs conferidos) | sim / sim / sim | não exigida | grátis; Extra US$ 7,95+, Source US$ 11,95–14,99+; Complete US$ 150 | sim (CC0) |
| Poly Haven | HDRIs, texturas PBR, modelos | CC0 | sim / sim / sim | não exigida | grátis | sim |
| Synty | 3D low-poly (POLYGON) | EULA própria (9 jul 2026) | sim / sim / sim | não exigida | packs avulsos; SyntyPass US$ 30–40/mês | **não** (inferência, ver §1.5) |
| Fab (Epic) | tudo; Megascans | Fab Standard License ou CC BY | sim (Standard) | depende | grátis ou pago; Personal/Professional | não confirmado |
| Sketchfab | modelos de usuários | CC por modelo, Standard, Editorial | depende do modelo | depende | grátis (CC) | depende |
| itch.io | de tudo | por projeto (escolhida pelo criador) | depende | depende | variado | depende |
| OpenGameArt | 2D, 3D, áudio | CC0, CC BY 3.0/4.0, CC BY-SA 3.0/4.0, GPL 2/3, OGA-BY | depende | depende | grátis | depende |

#### 1.1 Kenney
- Fato: é CC0. "You're free to use them, even in commercial projects" e "Attribution is not required" ([kenney.nl/support](https://kenney.nl/support), 2026-10-07).
- Fato: o logo do Kenney é reservado: "Do not use our logo" (mesma página).
- Fato: o All-in-1 custa "$19.95 USD or more", tem mais de 60.000 assets e é "Creative Commons Zero v1.0 Universal" ([kenney.itch.io/kenney-game-assets](https://kenney.itch.io/kenney-game-assets), 2026-10-07).
- Fato: o UI Pack é grátis e CC0 ([kenney.nl/assets/ui-pack](https://kenney.nl/assets/ui-pack), 2026-10-07).

#### 1.2 Quaternius
- Fato: é CC0, "can be used for free without the need for attribution in commercial, educational, and personal projects" ([quaternius.com/faq.html](https://quaternius.com/faq.html), 2026-10-07).
- Fato: o Universal Animation Library tem três versões. A Standard é grátis (45 animações, CC0). A Pro custa US$ 9,99+ (120+ animações, "Exported for Unity, UE and Godot"). A Source custa US$ 14,99+ (.blend) ([quaternius.itch.io/universal-animation-library](https://quaternius.itch.io/universal-animation-library), 2026-10-07).
- Fato: o Patreon começa em "BRL20/month" ([patreon.com/quaternius](https://www.patreon.com/quaternius), 2026-10-07). **Não confirmado**: o que cada tier dá. A página não mostrou os tiers.

#### 1.3 KayKit
- Fato: o Adventurers é "Free for personal and commercial use, no attribution required. (CC0 Licensed)". O autor pede "please don't resell unmodified copies". Os tiers são US$ 0, US$ 7,95+ e US$ 11,95+ ([kaylousberg.itch.io/kaykit-adventurers](https://kaylousberg.itch.io/kaykit-adventurers), 2026-10-07).
- Fato: o Character Animations é CC0 (grátis; Source US$ 14,99+) e vem em FBX e GLTF, com tutorial para Godot ([kaylousberg.itch.io/kaykit-character-animations](https://kaylousberg.itch.io/kaykit-character-animations), 2026-10-07).
- Fato: o Complete KayKit custa US$ 150, e os Mystery Series custam US$ 19,99 cada ([kaylousberg.itch.io](https://kaylousberg.itch.io/), 2026-10-07). **Não confirmado**: a licença dos packs pagos Mystery Series (a página deu 404).

#### 1.4 Poly Haven
- Fato: é CC0: "You can use our assets for any purpose, including commercial work" e "You can redistribute them" ([polyhaven.com/license](https://polyhaven.com/license), 2026-10-07).

#### 1.5 Synty
A **One Time Purchase Licence** é de 9 jul 2026 ([syntystore.com/pages/one-time-purchase-licence](https://syntystore.com/pages/one-time-purchase-licence), 2026-10-07):
- "The licence is worldwide, and is not limited by game engine".
- "each single licence purchase you make includes five seats for your Team".
- "You must not share the source files of any Assets outside your team."
- "you must not distribute our Assets as stock images or stock art (2D or 3D) or otherwise share them for re-use by third parties."
- Ela proíbe NFT, "Game Creation Software" e qualquer uso com IA generativa ([EULA](https://syntystore.com/pages/end-user-licence-agreement)).

A **Standard Subscription Licence (SyntyPass)** também é de 9 jul 2026 ([syntystore.com/pages/standard-subscription-licence](https://syntystore.com/pages/standard-subscription-licence)). Ao terminar a assinatura, "you must cease using our Assets in any new Intellectual Property". Continuam permitidas apenas "minor bug fixes such as maintenance updates".

O SyntyPass custa US$ 40/mês (mínimo de 3 meses) ou US$ 30/mês no plano anual ([syntystore.com/products/syntypass](https://syntystore.com/products/syntypass), 2026-10-07).

A Synty dá suporte oficial só a Unity e Unreal: "technically possible to use some of our assets within other engines, such as Godot... we currently only provide official support for Unity and Unreal Engine" ([FAQ](https://syntystore.com/community/faq), 2026-10-07).

**Inferência:** a EULA não fala de GitHub. Mas um repositório público entrega os arquivos a terceiros fora do time, e isso fere as duas cláusulas acima.

#### 1.6 Fab (Epic)
- Fato: a licença Standard tem dois tiers de preço. O Personal é para quem gerou menos de US$ 100.000 nos últimos 12 meses, e o Professional para quem passou disso. Também existe a opção CC BY ([dev.epicgames.com, Licenses and Pricing in Fab](https://dev.epicgames.com/documentation/fab/licenses-and-pricing-in-fab?lang=en-US), 2026-10-07).
- Fato: o conteúdo antigo do UE Marketplace continua "governed by the Epic Content License Agreement". Os Megascans antigos aparecem sob a "Quixel Content License" ([Purchasing and Downloading Assets in Fab](https://dev.epicgames.com/documentation/fab/purchasing-and-downloading-assets-in-fab), 2026-10-07).
- Fato: uma postagem oficial da Epic (26 mar 2025) diz que "the Fab EULA allows broader usage of assets than the Epic Content License, which required that assets acquired under the UE plan only be used in Unreal Engine. You can use Fab Standard licensed assets in any engine or tool." ([Megascans update, March 2025](https://forums.unrealengine.com/t/megascans-update-march-2025/2419561), 2026-10-07).
- Fato: "Assets bought on Fab are available under the Fab Standard License" ([quixel.com/license](https://quixel.com/license), 2026-10-07).
- **Não confirmado**: o texto da [Fab EULA](https://www.fab.com/eula) e da [Epic Content License](https://www.unrealengine.com/eula/content) (as duas deram 403). Sem esse texto não dá para confirmar:
  - a cláusula sobre compartilhar com colaboradores "via a private repository", que só vi num snippet de busca;
  - a definição de "UE-Only Content";
  - o preço atual dos Megascans (a imprensa fala em pagos desde 2025).

**Recomendação:** só aceitar asset da Fab se a página do asset disser "Standard" ou "CC BY". Recusar os marcados como UE Marketplace/Epic Content License, que podem ser UE-Only.

#### 1.7 Sketchfab
- Fato: a licença Editorial "cannot be used for any commercial or promotional use" ([sketchfab.com/licenses](https://sketchfab.com/licenses), 2026-10-07).
- Fato: os modelos grátis usam "Creative Commons licenses", com a licença definida modelo a modelo ([sketchfab.com/features/free-3d-models](https://sketchfab.com/features/free-3d-models), 2026-10-07).
- Fato: em 22 out 2024 a loja foi para a Fab, com a promessa de "plenty of notice before free downloadable content is no longer supported" ([blog Sketchfab](https://sketchfab.com/blogs/community/sketchfab-update-what-you-need-to-know-now-that-fabs-live/), 2026-10-07).
- Fato: "Epic has sold portfolio platform ArtStation and 3D model marketplace Sketchfab to KitBash" ([Game Developer, 12 ago 2026](https://www.gamedeveloper.com/business/epics-sells-artstation-and-sketchfab-to-kitbash), 2026-10-07).
- **Inferência:** a plataforma pode mudar de regras de novo. Guardar uma cópia da página de licença do modelo no momento do download.

#### 1.8 itch.io e OpenGameArt
- Fato (itch.io): a licença é por projeto: "You can pick one of the popular licenses in your project metadata, or else simply add your own in the description". O itch.io não exige licença nenhuma ("We don't mandate it") ([moderador do itch.io, set 2022](https://itch.io/t/2364809/how-do-itchio-handle-stuff-like-licenses-or-permissions-for-graphical-assets), 2026-10-07).
- Fato (OpenGameArt): aceita CC0, CC BY 3.0/4.0, CC BY-SA 3.0/4.0, GPL 2.0/3.0 e OGA-BY 3.0/4.0. O crédito sugerido é "[asset name] by [author name] licensed [license(s)]: [asset url]". Sobre CC BY-SA, o FAQ diz que "the work may not be used on distribution networks that use some form of Digital Rights Management (DRM)" ([opengameart.org/content/faq](https://opengameart.org/content/faq), 2026-10-07).

### 2. 2D, UI e ícones

| Fonte | Licença | Exigência |
|---|---|---|
| Kenney UI packs | CC0 ([UI Pack](https://kenney.nl/assets/ui-pack)) | nenhuma |
| game-icons.net | CC BY 3.0 | crédito por autor: "Icons made by {author}. Available on https://game-icons.net" ([about](https://game-icons.net/about.html)) |
| Lucide | ISC; os ícones vindos do Feather são MIT | levar o aviso de copyright e a licença "in all copies" ([lucide.dev/license](https://lucide.dev/license)) |
| Material Symbols | Apache 2.0 ([docs](https://developers.google.com/fonts/docs/material_symbols)) | levar a cópia da licença e o NOTICE, se houver ([Apache 2.0 §4](https://www.apache.org/licenses/LICENSE-2.0)) |

Todos conferidos em 2026-10-07.

### 3. Fontes (Google Fonts e OFL)
- Fato: "Most of the fonts in the collection use the SIL Open Font License, v1.1. Some fonts use the Apache 2 license. The Ubuntu fonts use the Ubuntu Font License v1.0." A pasta de cada família (ofl/, apache/, ufl/) já indica a licença ([github.com/google/fonts](https://github.com/google/fonts), 2026-10-07).
- Fato, OFL 1.1 ([texto oficial](https://openfontlicense.org/open-font-license-official-text/), 2026-10-07):
  - Cláusula 1: a fonte não pode ser "sold by itself".
  - Cláusula 2: ela "may be bundled, redistributed and/or sold with any software, provided that each copy contains the above copyright notice and this license".
  - Cláusula 3: uma versão modificada não pode usar o Reserved Font Name (RFN).
  - Cláusula 5: tudo continua sob a OFL.
- Fato, [OFL-FAQ](https://openfontlicense.org/ofl-faq/) (2026-10-07):
  - 1.4: jogos estão listados como bundling permitido ("games and entertainment software").
  - 1.20: "At a minimum you must include the copyright statement, the license notice and the license text".
  - 2.6: o subsetting "is considered modification... would not normally allow the use of RFNs".
- **Recomendação:** o arquivo OFL.txt fica ao lado do .ttf no repositório, e a tela de créditos do jogo cita a fonte. Não fazer subset de fonte com RFN, ou renomear a fonte se fizer.

### 4. Áudio

| Fonte | Licença | Comercial | Atribuição | Pega para nós? |
|---|---|---|---|---|
| Kenney audio | CC0 | sim | não | sim |
| Freesound | por som: CC0, CC BY 4.0, CC BY-NC 4.0, Sampling+ (legado) | só CC0 e CC BY | CC BY: sim | só CC0 e CC BY |
| Sonniss GDC | licença própria v2.0 (27 ago 2026) | sim | não | sim (sem redistribuir os .wav) |
| OpenGameArt audio | por asset | depende | depende | CC0, CC BY, OGA-BY |
| Pixabay | Pixabay Content License | sim | não | sim, com ressalvas |
| ZapSplat | Standard License (8 mai 2026) | sim | grátis: sim; Premium: não | sim, com crédito |
| Mixkit | Mixkit Free License | sim | não | sim (parcialmente confirmado) |
| BBC Sound Effects | RemArc | **não** | — | **não** |

Detalhes:
- **Freesound**: as licenças são CC0, CC BY 4.0, CC BY-NC 4.0 e o antigo Sampling+. O crédito sugerido é "'sound1' by user1 ( http://freesound.org/s/soundID/ ) licensed under CCBY 4.0". Sobre NC, o FAQ diz: "you can't earn any money with the piece of work you create" ([FAQ](https://freesound.org/help/faq/), 2026-10-07).
- **O que é NC (NonCommercial)**: a CC define assim: "not primarily intended for or directed towards commercial advantage or monetary compensation" ([CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/legalcode.en), 2026-10-07). **Inferência:** um jogo grátis e sem receita hoje passa no NC. Mas basta uma doação, uma loja paga ou um anúncio no futuro para ser preciso trocar o som. É como uma dívida técnica escondida: recusar.
- **Sonniss GDC** ([licença](https://sonniss.com/gdc-bundle-license/), 2026-10-07):
  - Permite: "may use and modify... for personal and commercial projects", incluindo "games", sem atribuição.
  - Proíbe: "may not distribute, publish, sub-license or otherwise supply the sound effects as sound effects to any other person".
  - Permite compartilhar com "people in the Licensee's own team".
  - Proíbe treinar IA.
  - É grátis, com bundles de 2015 a 2024 ([sonniss.com/gameaudiogdc](https://sonniss.com/gameaudiogdc), 2026-10-07).
  - **Inferência:** os .wav brutos num repositório público seriam "supply... as sound effects". O mesmo risco da Synty.
- **Pixabay**: livre para uso comercial e sem atribuição. Proíbe "sell or distribute the Content... on a Standalone basis". A licença é de 18 nov 2024 ([termos](https://pixabay.com/service/terms/), [resumo](https://pixabay.com/service/license-summary/), 2026-10-07). **Não confirmado**: regras de Content ID para músicas.
- **ZapSplat** ([Standard License, atualizada em 8 mai 2026](https://www.zapsplat.com/license-type/standard-license/), 2026-10-07; aberta via curl, a página deu 403 no fetcher):
  - Conta Basic (grátis): "You must provide clear credit to 'ZapSplat'".
  - Conta Premium: "Attribution is not required".
  - "Games, apps, and software" estão permitidos.
  - Proibido: "Redistribute our sounds in any form" e o uso para treinar IA.
  - Fala em "single user".
- **Mixkit**: "use in commercial projects... No attribution required". É proibido vender cópias "without first altering them" ([mixkit.co/llm-info](https://mixkit.co/llm-info/), página oficial, 2026-10-07). **Não confirmado**: o texto integral da "Sound Effects Free License" (o link "View License" não abriu).
- **BBC**: o site diz "Commercial use of this content is not allowed under the RemArc license". Para uso comercial, é preciso comprar da Pro Sound Effects. No FAQ, conta como comercial "if you monetise it, sell it, or charge for access to it, or if it is advertising-funded" (texto do app [sound-effects.bbcrewind.co.uk/licensing](https://sound-effects.bbcrewind.co.uk/licensing), lido do bundle JS do site em 2026-10-07; o texto integral da licença RemArc não foi aberto). **Inferência:** um jogo grátis sem anúncio até ficaria fora de "comercial". Mas é o mesmo problema do NC, então recusar.

### 5. Git LFS no GitHub Free
- Fato: o plano inclui 10 GiB de armazenamento e 10 GiB de banda (Free, Pro e Free para organizações). Team e Enterprise têm 250 GiB ([Git LFS billing](https://docs.github.com/en/billing/concepts/product-billing/git-lfs), 2026-10-07).
- Fato: o excedente é cobrado por uso medido. "Previously, Git LFS billing used pre-paid data packs. These have been removed and replaced with metered billing" (mesma página).
- Fato: com orçamento US$ 0, "You are not charged for overages, but Git LFS usage is blocked for the rest of the calendar month". Cada push de uma nova versão conta o arquivo inteiro: "if you make a 1 byte change and push the file again, you'll use another 500 MB". Só download conta como banda ([About storage and bandwidth usage](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-storage-and-bandwidth-usage), 2026-10-07).
- Fato: o GitHub Actions também consome a cota. "If GitHub Actions downloads a 500 MB file that is tracked with Git LFS, it will use 500 MB of the repository owner's bandwidth" ([billing](https://docs.github.com/en/billing/concepts/product-billing/git-lfs)).
- Fato: o tamanho máximo de arquivo é 2 GB no Free e no Pro, 4 GB no Team e 5 GB no Enterprise Cloud ([About Git LFS](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-git-large-file-storage), 2026-10-07).
- Fato: o preço do excedente é US$ 0,07 por GB de armazenamento por mês e US$ 0,0875 por GB de banda. "The budget defaults to zero for customers with no payment method on file" ([FAQ oficial da GitHub, discussão #61362](https://github.com/orgs/community/discussions/61362), 2026-10-07). A página da documentação manda usar a calculadora e não mostra o preço.
- Fato: em 2025 o novo modelo de billing chegou às contas pessoais: "Git Large File Storage will transition from prepaid, quota-based data packs to a usage-based metered billing model" ([changelog 2025-02-25](https://github.blog/changelog/2025-02-25-enhanced-billing-platform-is-now-available-for-personal-accounts/), 2026-10-07). Não achei mudança de cota em 2026 (a busca no changelog não trouxe nada).
- Atenção: [github.com/pricing](https://github.com/pricing) ainda mostra "$5 per month for 50 GB bandwidth and 50 GB of storage", o modelo antigo de data packs. Isso contradiz a documentação. **Recomendação:** confiar na documentação.
- **Inferência:** o .gitattributes do repositório cobre .glb, .fbx, .png, .ogg e outros, mas não cobre .gltf, .bin, .obj, .woff/.woff2 nem .tres/.res binários. Packs KayKit e Kenney em glTF iriam para o git comum. Com 10 GiB e uma .blend de 50 MB reenviada 20 vezes, já se vai 1 GB.

### 6. O que a política precisa dizer

**Fatos que sustentam a política:**
- O CC BY 4.0 exige identificar o autor, ter um aviso de copyright, citar a licença com link, ter o aviso de isenção de garantia, dar o link do material e "indicate if You modified". Tudo pode ser feito "in any reasonable manner" ([CC BY 4.0 §3(a)](https://creativecommons.org/licenses/by/4.0/legalcode.en)).
- A OFL exige o copyright e a licença em cada cópia (§3 deste relatório).
- A Apache 2.0 exige uma cópia da licença e do NOTICE (§2).
- A Synty proíbe compartilhar fora do time (§1.5), e a Sonniss proíbe "supply... as sound effects" (§4).

**Recomendações (minhas):**

1. **Linha do CREDITS.md por tipo de licença.**

   Colunas de toda linha: asset, autor, licença com versão e link, URL da página de origem, data do download, se foi modificado (sim/não, e o quê), onde é usado e onde está o arquivo de licença.

   | Tipo | O que a linha precisa ter |
   |---|---|
   | CC0 | as colunas básicas; atribuição opcional, mas registrar a fonte mesmo assim (prova de proveniência) |
   | CC BY | o texto exato do crédito que vai na tela de créditos do jogo e a marcação "modificado" |
   | EULA | nome e versão/data da EULA, o comprador (conta), o número do pedido ou recibo, os assentos e a frase "repo deve ficar privado" |

2. **Arquivo de licença ao lado do pack.** Por exemplo, `assets/third_party/<fonte>/<pack>/LICENSE.txt`, a cópia do texto como baixado. Para as EULAs, guardar um PDF ou print da página com a data. Para fontes, o OFL.txt ao lado do .ttf.
3. **Licenças a recusar:**
   - NC (CC BY-NC e qualquer "non-commercial"), porque fecha a porta de doação ou loja;
   - ND (sem derivados), porque impede ajustar escala, cor ou material;
   - "Editorial" (Sketchfab);
   - engine-locked (UE-Only, Epic Content License, UE Marketplace);
   - "personal use only" e RemArc (BBC);
   - CC BY-SA, pela cláusula anti-DRM e pelo efeito viral; entra só com o ok de Arthur.
4. **EULA em repositório privado:** um asset de EULA (Synty, Sonniss, ZapSplat, Fab Standard) obriga o repositório a ficar privado para sempre, ou o histórico do git a ser reescrito antes de abrir. O git guarda tudo: mesmo removido depois, o arquivo continua nos commits antigos e nos objetos LFS. **Sugestão:** isolar esses assets numa pasta `assets/eula/` e registrar no gate um check que lista o que está nela. Assim a decisão de tornar o repositório público sabe o custo exato.
5. **GunZ (F-001):** em fontes abertas (Freesound, OpenGameArt, Sketchfab), recusar qualquer asset com "GunZ", "MAIET" ou ripado de jogo no título ou na descrição. O próprio Freesound diz que sons de jogos protegidos "is not legal in 99.9% of cases".

## §2 — O resumo e o que não foi confirmado, pelo agente

1. Kenney, Quaternius, KayKit e Poly Haven são CC0 1.0 nas fontes. Nenhum deles exige atribuição, e todos permitem uso comercial e redistribuição dentro do jogo, inclusive num repositório público. A versão paga (Kenney All-in-1 a US$ 19,95; Pro/Source de Quaternius e KayKit) continua CC0, mas não confirmei os packs "Mystery Series" pagos do KayKit.
2. Synty (EULA de 9 jul 2026) não restringe engine e dá 5 assentos por licença. Proíbe compartilhar os arquivos-fonte "outside your team" e compartilhar "for re-use by third parties". Inferência: um repositório que vira público com Synty dentro viola a EULA. Na assinatura (SyntyPass, US$ 30-40/mês), depois de cancelar só se pode fazer manutenção do produto, e nenhum conteúdo novo pode usar os assets.
3. Fab: uma postagem da Epic (mar 2025) diz que assets na Fab Standard License podem ser usados "in any engine or tool". O texto da EULA (fab.com/eula) e o da Epic Content License (UE-Only) deram 403 e ficam não confirmados. A maior parte dos Megascans é paga desde 2025.
4. Sketchfab foi vendido pela Epic à KitBash (anunciado em 10 ago 2026). A loja paga já tinha ido para a Fab em 2024. Os modelos grátis seguem com licença CC por modelo, que precisa ser conferida um a um. A licença "Editorial" proíbe uso comercial.
5. Áudio: o Freesound mistura CC0, CC BY 4.0 e CC BY-NC 4.0 (e o antigo Sampling+) som a som. O Sonniss GDC (licença v2.0, 27 ago 2026) é grátis, comercial e sem atribuição, mas proíbe redistribuir os sons em si. O ZapSplat grátis exige crédito e proíbe redistribuir. A BBC (RemArc) proíbe uso comercial.
6. Fontes: o Google Fonts é quase todo OFL 1.1 (alguns Apache 2.0, Ubuntu UFL). Pela OFL, o jogo pode embutir a fonte desde que leve o aviso de copyright e o texto da licença. A fonte não pode ser vendida sozinha. Subsetting conta como modificação, e então o Reserved Font Name não pode ser usado.
7. Git LFS no GitHub Free: 10 GiB de armazenamento e 10 GiB/mês de banda, por conta, e arquivos de até 2 GB. Cada versão enviada conta o tamanho inteiro. O excedente é medido a US$ 0,07/GiB-mês de armazenamento e US$ 0,0875/GiB de banda. Sem forma de pagamento o orçamento é US$ 0, e o LFS fica bloqueado até o dia 1º do mês seguinte. O checkout do CI com LFS também gasta banda.
8. Inferência para o repositório: o .gitattributes atual não cobre .gltf, .bin, .obj e .woff2. Os packs KayKit e Kenney em glTF iriam para o git comum.
9. Recomendação: aceitar CC0, CC BY, OFL, Apache, ISC/MIT e uma EULA só com a regra de nunca tornar público o repositório que a contiver. Recusar NC, ND, Editorial, UE-Only/engine-locked, licença pessoal, RemArc e CC BY-SA (por causa da cláusula de DRM).

O que o agente não confirmou:

- Texto da Fab EULA (fab.com/eula): 403. A cláusula de compartilhar com colaboradores 'via a private repository' veio só de um snippet de busca.
- Texto da Epic Content License (unrealengine.com/eula/content) e a definição de 'UE-Only Content': 403.
- Preço atual dos Megascans na Fab desde 2025 (só imprensa e snippets).
- Tiers e preços do Patreon da Quaternius além de 'Starting at BRL20/month'.
- Licença dos packs pagos KayKit Mystery Series (a página deu 404).
- Texto integral da Mixkit Sound Effects Free License (o link 'View License' não abriu; usei a página mixkit.co/llm-info).
- Texto integral da licença RemArc da BBC (só o texto do app, lido do bundle JS do site).
- Política de Content ID da Pixabay para músicas.
- Mudança de cota de Git LFS em 2026 (nada encontrado no changelog; a busca foi limitada).
- Conflito: github.com/pricing ainda mostra o data pack de US$ 5 por 50 GB, que a documentação diz ter sido removido.
- Preço do excedente de LFS (US$ 0,07 e US$ 0,0875) confirmado só na discussão oficial #61362 da GitHub; a página da documentação não mostra o valor.

## §3 — As afirmações marcadas como importantes e o veredicto do verificador

- **licencas:C01** — Os assets da Kenney são CC0: uso comercial livre e atribuição não exigida.
  - Veredicto: **CONFIRMED**. Página de suporte da Kenney declara CC0, uso comercial livre e atribuição opcional.
  - Lido em: https://kenney.nl/support
  - Trecho: "Yes, all game assets on the asset pages are public domain licensed (CC0). [...] You're free to use them, even in commercial projects. [...] Attribution is not required, but if you choose to give credit you can do so by mentioning 'Kenney'."
- **licencas:C02** — Os assets da Quaternius são CC0, sem atribuição, inclusive em projetos comerciais.
  - Veredicto: **CONFIRMED**. FAQ oficial da Quaternius: CC0, sem atribuição, inclusive comercial.
  - Lido em: https://quaternius.com/faq.html
  - Trecho: "All models are under the CC0 License. [...] Yes, these assets can be used for free without the need for attribution in commercial, educational, and personal projects."
- **licencas:C03** — O KayKit Adventurers é CC0, com uso comercial e sem atribuição.
  - Veredicto: **CONFIRMED**. Página do KayKit Adventurers no itch.io confirma CC0, uso comercial e sem atribuição; o autor pede (sem força de licença) para não revender cópias não modificadas.
  - Lido em: https://kaylousberg.itch.io/kaykit-adventurers
  - Trecho: "Free for personal and commercial use, no attribution required. (CC0 Licensed) [...] These assets are CC0 so you can use them freely. But please don't resell unmodified copies or claim them as your own."
- **licencas:C04** — Os assets da Poly Haven são CC0, para qualquer uso, com redistribuição permitida.
  - Veredicto: **CONFIRMED**. Página de licença da Poly Haven confirma CC0, qualquer uso e redistribuição explícita.
  - Lido em: https://polyhaven.com/license
  - Trecho: "You can use our assets for any purpose, including commercial work. [...] You can redistribute them, share them around, include them when sharing your own work, or even in a product you sell."
- **licencas:C05** — A EULA da Synty (One Time Purchase, 9 jul 2026) proíbe compartilhar arquivos-fonte fora do time e compartilhar os assets para reuso por terceiros; não tem restrição de engine.
  - Veredicto: **CONFIRMED**. EULA 'One Time Purchase Licence [Current]' datada de 9 July 2026: proíbe compartilhar source files fora do time e compartilhar para reuso por terceiros; diz explicitamente que não é limitada por engine.
  - Lido em: https://syntystore.com/pages/one-time-purchase-licence
  - Trecho: "You must not share the source files of any Assets outside your team. [...] you must not distribute our Assets as stock images or stock art (2D or 3D) or otherwise share them for re-use by third parties. [...] The licence is worldwide, and is not limited by game engine, OS, platform or device."
- **licencas:C06** — Segundo a Epic, assets na Fab Standard License podem ser usados em qualquer engine; a Epic Content License antiga restringia o plano UE ao Unreal.
  - Veredicto: **CONFIRMED**. Post original de 2025-03-26 por 'skfabby' (Abby); o JSON do Discourse do fórum mostra primary_group_name 'Epic_Games_Inc', user_title 'Staff', staff: true, logo é fala da Epic. Citação confere literalmente.
  - Lido em: https://forums.unrealengine.com/t/megascans-update-march-2025/2419561
  - Trecho: "the Fab EULA allows broader usage of assets than the Epic Content License, which required that assets acquired under the UE plan only be used in Unreal Engine. You can use Fab Standard licensed assets in any engine or tool"
- **licencas:C07** — No Freesound, a licença é definida som a som: CC0, CC BY 4.0, CC BY-NC 4.0 ou o antigo Sampling+.
  - Veredicto: **CONFIRMED**. FAQ do Freesound: licença escolhida pelo uploader por som, entre três licenças CC (os links apontam para by/4.0 e by-nc/4.0; a versão '4.0' aparece só nas URLs, não no texto) mais o Sampling+ legado, que a FAQ chama de 'retired'.
  - Lido em: https://freesound.org/help/faq/
  - Trecho: "freesound lets the user select one of three licenses for their sounds. And, we used to have a 4th license [...] zero (cc0): http://creativecommons.org/publicdomain/zero/1.0/ attribution (by): http://creativecommons.org/licenses/by/4.0/ attribution noncommercial (by-nc): http://creativecommons.org/licenses/by-nc/4.0/ [...] In freesound "1" we had an additional license called Sampling+ [...] Creative Commons says Sampling+ is "retired""
- **licencas:C08** — A licença do Sonniss #GameAudioGDC (v2.0, 27 ago 2026) permite uso comercial em jogos sem atribuição e proíbe redistribuir os sons como sons.
  - Veredicto: **CONFIRMED**. Página da licença mostra 'Version 2.0 · Effective 27 August 2026'; permite uso comercial em jogos sem atribuição e proíbe redistribuir os sons como sons.
  - Lido em: https://sonniss.com/gdc-bundle-license/
  - Trecho: "Licensee may use and modify the licensed sound effects for personal and commercial projects without attribution to the original creator. [...] games, films, television & interactive projects. [...] Licensee may not distribute, publish, sub-license or otherwise supply the sound effects as sound effects to any other person, without the Licensor's prior written permission."
- **licencas:C09** — A OFL 1.1 permite embutir a fonte num software se cada cópia levar o aviso de copyright e a licença; a fonte não pode ser vendida sozinha.
  - Veredicto: **CONFIRMED**. Texto oficial da OFL 1.1 (26 February 2007) confirma o bundling com aviso de copyright e licença e a proibição de venda isolada.
  - Lido em: https://openfontlicense.org/open-font-license-official-text/
  - Trecho: "Neither the Font Software nor any of its individual components, in Original or Modified Versions, may be sold by itself. [...] Original or Modified Versions of the Font Software may be bundled, redistributed and/or sold with any software, provided that each copy contains the above copyright notice and this license."
- **licencas:C10** — O GitHub Free inclui 10 GiB de armazenamento e 10 GiB de banda de Git LFS; os data packs foram substituídos por cobrança medida.
  - Veredicto: **CONFIRMED**. Doc oficial do GitHub: GitHub Free com 10 GiB de banda e 10 GiB de armazenamento; data packs substituídos por cobrança medida.
  - Lido em: https://docs.github.com/en/billing/concepts/product-billing/git-lfs
  - Trecho: "GitHub Free | 10 GiB | 10 GiB [...] Previously, Git LFS billing used pre-paid data packs. These have been removed and replaced with metered billing and you only pay for what you actually use."
- **licencas:C11** — O limite de tamanho por arquivo no Git LFS é 2 GB no GitHub Free.
  - Veredicto: **CONFIRMED**. Tabela de tamanho máximo por arquivo no Git LFS.
  - Lido em: https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-git-large-file-storage
  - Trecho: "GitHub Free | 2 GB | GitHub Pro | 2 GB | GitHub Team | 4 GB | GitHub Enterprise Cloud | 5 GB"
- **licencas:C12** — O excedente de LFS custa US$ 0,07/GB-mês de armazenamento e US$ 0,0875/GB de banda; o orçamento padrão é zero sem forma de pagamento, e o LFS fica bloqueado até o mês seguinte.
  - Veredicto: **CONFIRMED**. Preços confirmados na calculadora oficial do GitHub (unidade é GiB, não GB) e no changelog oficial de 2024-06-03 ('$0.07 per GiB per month (USD)', '$0.0875 per GiB'); o orçamento padrão zero vem da FAQ oficial de um GitHub Community Maintainer (2023-07-20): 'The budget defaults to zero for customers with no payment method on file.'; o bloqueio até o mês seguinte está na doc: 'Budget set to $0: You are not charged for overages, but Git LFS usage is blocked for the rest of the calendar month.' A doc de billing não lista os preços.
  - Lido em: https://github.com/pricing/calculator
  - Trecho: "Additional storage $0.07 per GiB, additional data transfer out $0.0875 per GiB."

## §4 — As demais afirmações, com o link

- licencas:C13 — O Kenney All-in-1 custa US$ 19,95 ou mais e é CC0. — https://kenney.itch.io/kenney-game-assets
- licencas:C14 — Na SyntyPass, depois que a assinatura termina, os assets não podem ser usados em nova propriedade intelectual; só manutenção. — https://syntystore.com/pages/standard-subscription-licence
- licencas:C15 — A SyntyPass custa US$ 40/mês (mínimo de 3 meses) ou US$ 30/mês no plano anual. — https://syntystore.com/products/syntypass
- licencas:C16 — A licença Standard da Fab tem os tiers Personal (receita abaixo de US$ 100 mil em 12 meses) e Professional. — https://dev.epicgames.com/documentation/fab/licenses-and-pricing-in-fab?lang=en-US
- licencas:C17 — A licença Editorial do Sketchfab proíbe uso comercial. — https://sketchfab.com/licenses
- licencas:C18 — A Epic vendeu o ArtStation e o Sketchfab à KitBash em agosto de 2026. — https://www.gamedeveloper.com/business/epics-sells-artstation-and-sketchfab-to-kitbash
- licencas:C19 — O OpenGameArt aceita CC0, CC BY, CC BY-SA, GPL e OGA-BY; o FAQ diz que o CC BY-SA impede plataformas com DRM. — https://opengameart.org/content/faq
- licencas:C20 — Os ícones do game-icons.net são CC BY 3.0, com crédito por autor. — https://game-icons.net/about.html
- licencas:C21 — O Lucide é ISC, e os ícones vindos do Feather são MIT; é preciso manter o aviso em todas as cópias. — https://lucide.dev/license
- licencas:C22 — Os Material Symbols são Apache 2.0. — https://developers.google.com/fonts/docs/material_symbols
- licencas:C23 — A coleção do Google Fonts é majoritariamente OFL 1.1, com alguns Apache 2 e as fontes Ubuntu em UFL. — https://github.com/google/fonts
- licencas:C24 — Pelo OFL-FAQ, quem embute a fonte num app precisa incluir o copyright, o aviso e o texto da licença; subsetting conta como modificação. — https://openfontlicense.org/ofl-faq/
- licencas:C25 — A CC define NonCommercial como não primariamente voltado a vantagem comercial ou compensação monetária. — https://creativecommons.org/licenses/by-nc/4.0/legalcode.en
- licencas:C26 — A Pixabay Content License permite uso comercial sem atribuição e proíbe distribuir o conteúdo de forma standalone. — https://pixabay.com/service/terms/
- licencas:C27 — Na ZapSplat, usuários grátis precisam creditar a ZapSplat; jogos são permitidos; redistribuir os sons é proibido. — https://www.zapsplat.com/license-type/standard-license/
- licencas:C28 — A BBC Sound Effects (RemArc) não permite uso comercial; o licenciamento comercial é feito pela Pro Sound Effects. — https://sound-effects.bbcrewind.co.uk/licensing
- licencas:C29 — A Mixkit Free License permite uso comercial sem atribuição. — https://mixkit.co/llm-info/
- licencas:C30 — Cada push de nova versão de um arquivo LFS conta o tamanho inteiro no armazenamento; com orçamento zero o LFS bloqueia até o mês seguinte. — https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-storage-and-bandwidth-usage
- licencas:C31 — Downloads de LFS feitos pelo GitHub Actions contam na banda do dono do repositório. — https://docs.github.com/en/billing/concepts/product-billing/git-lfs
- licencas:C32 — O CC BY 4.0 exige o crédito ao autor, o aviso de licença com link e a indicação de modificações, e aceita qualquer forma razoável. — https://creativecommons.org/licenses/by/4.0/legalcode.en
