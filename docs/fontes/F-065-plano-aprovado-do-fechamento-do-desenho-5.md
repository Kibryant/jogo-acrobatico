---
id: F-065
titulo: O plano aprovado do fechamento do Desenho 5 — três DECs, o visual-e-audio.md, a checagem de assets e a prova do LFS no portão, as guardas do project.godot e o que acompanha (sessão 9, 08/10/2026)
recebido_em: 2026-10-08
como: O plano escrito pelo Claude no modo de plano da sessão 9, criticado antes por um agente de planejamento com contexto limpo (Fable 5.1), que devolveu 16 achados, todos incorporados; aprovado pelo Arthur no ExitPlanMode, depois de autorizar o fechamento (F-064). O §1 é o plano como foi aprovado. O §2 resume a crítica do agente.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: o ok no modo de plano é consentimento de verdade, mas não deixa F-xxx; por isso o plano aprovado vira fonte logo depois (registro da TASK-4). O que o plano decide de número é v0, fechado pelo Claude (DEC-0017); o que ele decide de regra vem das fontes que cita.

## §1 — O plano aprovado

### Contexto

As duas rodadas da TASK-7 acabaram. A rodada 1 provou o pipeline e mediu os 16 lutadores (F-056); a rodada 2 provou os tokens, o som pela chave do evento e o julgamento na tela de quem defende, e o Arthur jogou quatro vezes (F-061 a F-063). O que ele decidiu está nas fontes: as cinco escolhas do Ready (F-054 §4), o jogo aberto com a política só de licença que deixa redistribuir, decidida pelo Claude por delegação (F-058 §2), o contorno como parte da cara do jogo (F-059) e o "deu bom" com dois golpes em aberto (F-063). O fechamento transforma isso em regra: três DECs, o `docs/design/visual-e-audio.md`, a checagem "asset sem linha não entra" no portão com canários, a prova do LFS pelo próprio git, o `project.godot` com a base de 1920 × 1080 e o MSAA 2x guardados por teste, e o `AGENTS.md`, o `rede.md`, o `reviewer.md` e o glossário acompanhando. Depois, o reviewer, o portão num clone limpo e o PR.

Os números v0 que o Claude fecha (DEC-0017), nenhum do `combate.md` ou do `movimento.md`: o orçamento de 10 mil vértices por lutador (F-056 §6), o MSAA 2x (F-056 §5 e §6), o contorno de 1,2 cm (F-056 §5), as cores dos tokens (F-053 §3.6; F-061), o ducking de uns 12 dB e a escala da interface de 0,8 a 1,5, estes dois sem medida na fonte e marcados "v0, fechado pelo Claude" com a razão (a sonda abaixou 33 a 39 dB e chamou de demais, F-061 §4; a sonda subiu a escala até 1,2, F-062 §2). Q-21 e Q-25 ficam para a fase 2.

### 0. Antes de escrever: a pergunta fixa e a reconferência do netfox

- Uma pergunta de entendimento (DEC-0021) sobre a chave do evento, antes das DECs: a da rodada foi sobre a cor.
- Reconferir contra a F-061 toda afirmação sobre o netfox nas DECs vigentes, e registrar o resultado na DEC-0031: a DEC-0004 (regra 2: "som e VFX só no tick novo", falha em dois casos de três); a DEC-0022 §3 (comparar o modo desenhado com o do estado: coerente com a chave do evento); a DEC-0026 §2 ("o atraso de visão é o tick atual menos o `get_last_known_state()` do oponente": devolve zero para o oponente espelhado, F-061 §2). O comentário do próprio netfox que prometia o contrário (`addons/netfox/rollback/rollback-synchronizer.gd`, `get_last_known_state`) e o aviso do `network-rollback.gd` ("the `is_fresh` parameter may not work as expected") entram na DEC-0031, para a afirmação ser reconferida quando o netfox subir de versão (DEC-0023).
- A sonda do "antes" do critério 3: um pack falso em `assets/third_party/sonda/pack/` com `modelo.txt` e sem linha passa pelo portão de hoje em verde, com o comando e as últimas linhas nas notas da task, como a TASK-6 fez.

### 1. As três DECs (status `aceita`)

**DEC-0029 — A política de assets e as fontes.** Fontes: F-050, F-054, F-056, F-058. Decidido por Arthur (F-054 §4; F-058), com a política só-redistribuível e o momento de abrir decididos pelo Claude por delegação (F-058 §2) e os números v0 pelo Claude (DEC-0017); as palavras dele citadas na Decisão.
- Só entra licença que deixa redistribuir e modificar: CC0 primeiro; CC BY com o crédito na forma que a licença pede; OFL 1.1 para fontes; MIT, Apache 2.0 e ISC para ícones e código. Recusa: NC, ND, Editorial, só-Unreal, uso pessoal, RemArc, EULA e "não redistribua" (Synty, Mixamo, Sonniss, Fab Standard), qualquer coisa com "GunZ" ou "MAIET"; BY-SA só com o ok do Arthur. Nada se compra. A razão da recusa da EULA é a regra do repositório privado: um asset de EULA obrigaria o repositório a ficar privado para sempre, porque o git guarda cada commit e cada objeto do LFS (F-050 §1.6, item 4; F-056 §1), e o repositório abre no Desenho 6 (F-058; Q-04). Supera a escolha 3 do Ready (F-054 §4).
- Critério 2, a tabela das fontes: para cada uma, o nome, a versão ou a data, o link, a frase que permite o uso, entre aspas, como a fonte traz, e o que ela proíbe. Kenney, Quaternius, KayKit e Poly Haven: CC0, as frases de F-050 §3 (C01 a C04), lidas em 07/10/2026. O UAL2: o `License.txt` do zip (F-056 §2) e a página do OpenGameArt; o UAL1 v2.0: a página do itch (F-052 §2.1). Google Fonts: OFL 1.1 (F-050 §1.3 e §3 C09). game-icons.net: CC BY 3.0 com o texto do crédito; Lucide: ISC, e MIT nos ícones vindos do Feather; Material Symbols: Apache 2.0, com a cópia da licença e do NOTICE (F-050 §1.2). O que a CC BY exige (F-050 §1.6).
- A pasta `assets/third_party/<fonte>/<pack>/`, nomes em snake_case (F-051 §1.9), o arquivo de licença dentro dela com o nome original, e uma linha por pack no `assets/CREDITS.md` citando o caminho `assets/third_party/<fonte>/<pack>` sem barra final, com as colunas: pack e caminho, autor, licença com versão e link, URL de origem, data do download, modificado (o quê), onde é usado, arquivo de licença; a CC BY leva o texto exato do crédito (F-050 §1.6). "Asset sem linha não entra" é um passo do portão.
- A cota do LFS: 10 GiB guardados e 10 GiB por mês, 2 GB por arquivo, orçamento zero sem cartão, cada versão enviada conta inteira, o CI gasta banda ao baixar (F-050 §1.5; §3 C10 a C12). A lista de formatos vive no `.gitattributes` e no `visual-e-audio.md`.

**DEC-0030 — O pipeline de import e o caminho da animação.** Fontes: F-051, F-052, F-054, F-056, F-059.
- Entrada em glTF (`.glb`); FBX só quando não houver glTF; `.blend` não entra no repositório (exige o Blender em toda máquina, F-051 §1.1; no CI também, inferência do agente).
- 1 unidade = 1 m, a convenção do Godot (F-051 §1.2, não confirmada palavra por palavra); o lutador sai com 1,8 m pela escala de import, como o 0,98414 do UAL2 (F-056 §3).
- As dicas de nome `-col`, `-colonly`, `-noimp` e `loop` (F-051 §1.3); o `.import` no git e a `.godot/` fora (§1.7); texturas com Detect 3D (§1.8); snake_case (§1.9).
- Um rig só, o do UAL2 (F-056 §3); a Animation Library compartilhada (F-051 §1.4); clipes in place, nunca root motion para mover o corpo (F-051 §1.6; F-052 §6.3); a marca do ativo à mão (F-056 §4); todo clipe reajustado fase a fase pelo estado (F-052 §6.2); a pose é uma função do estado, sem máquina de estados no AnimationTree (DEC-0022 §3).
- A base CC0: UAL1 v2.0 do itch e UAL2; KayKit para arco e armas depois de um teste de retarget; os 15 a 18 clipes de identidade à mão (F-052 §7.5), com a ferramenta escolhida na fase 1; nada se compra; Paragon, Mixamo e Synty não entram (F-054 §4, escolha 4; F-058).
- O orçamento v0: 10 mil vértices por lutador no detalhe máximo, com a arma, e LOD a distância; o MSAA 2x; a sombra e o contorno ligados, o contorno de 1,2 cm por casco invertido como parte da cara do jogo; se o quadro apertar, o contorno sai de quem está longe, nunca de vez (F-056 §5 e §6; F-059; Q-22). O greybox até o movimento ser divertido (F-054 §4, escolha 1).

**DEC-0031 — Os tokens de leitura e a base da interface.** Fontes: F-007, F-053, F-054, F-055, F-061, F-062, F-063. Substitui duas frases: a da regra 2 da DEC-0004 ("Som e VFX só tocam em tick novo, nunca na re-simulação") e a do atraso de visão da DEC-0026 §2 ("o tick atual menos o `get_last_known_state()` do oponente").
- Três canais por estado: cor, pose e som; a cor marca a exceção; o leve não tem cor. A tabela v0: carregado em azul celeste `#56B4E9` desde o tick 0; ativo em vermelhão `#D55E00` no rastro; parry em amarelo `#F0E442` na janela e no acerto, com o "clang"; quebra de guarda com a mão em vermelhão desde o tick 0, o contorno pulsando e o pisão (hipótese depois da F-063); a finta com o corte visível e audível (DEC-0016); a arma de longe carregada em `#CC79A7`, a conferir sob deuteranopia (F-061 §4); bloqueio e reação sem cor. O sinal mora no mundo; o HUD é redundância e cobre o que está fora da tela (F-053 §5).
- A paleta no eixo azul–amarelo da Okabe-Ito; nenhum verde; laranja nunca junto do vermelhão ou do amarelo; 3:1 contra o fundo (F-053 §3.4 e §3.6). A cor de time é o contorno e o anel, nunca uma cor de token; o anel do 2 em 1 usa forma (F-053 §6).
- O bus "leitura", com um player por som, nunca cortado pela polifonia, e um compressor em sidechain que abaixa música e ambiente em uns 12 dB (v0) enquanto um token toca (F-051 §5.1 e §5.2; F-053 §4; F-061 §4).
- Os tokens são dado num Resource em `data/`, lidos do estado (DEC-0004, regra 3).
- A chave do evento: som e efeito tocam uma vez por evento, pela chave (nó, tipo, id), quando o evento aparece pela primeira vez no estado exibido, nunca de novo na re-simulação; um evento apresentado nunca é desfeito (F-007 §1; F-061 §2). O `is_fresh` do netfox cobre só o nó que o peer simula (F-061 §2). O atraso de visão vem do tick que o próprio estado carrega (`sim_tick`), porque o `get_last_known_state()` devolve zero para o oponente (F-061 §2).
- A base da interface: um Theme só em `gui/theme/custom`, criado com a primeira cena de interface; a base de 1920 × 1080 com `canvas_items` e `expand`, guardada; a escala por `content_scale_factor`, de 0,8 a 1,5 (v0); as teclas por posição física, remapeáveis desde o primeiro dia, salvas em `user://`, com o rótulo do teclado ativo; nenhuma informação só por cor; nomes de acessibilidade nos menus; chaves de tradução por ID com pt-BR e en; o leitor de tela na partida fora do v0 (F-051 §3 e §4).
- Para a fase 2: Q-21, Q-25, o som com fone, a pose com o boneco; o jitter da entrega para a Q-09 (F-061 §3).

### 2. `docs/design/visual-e-audio.md` (critério 1)

Novo, com `revisado_em` e `fontes`, com os títulos do critério: Estado atual; A política de assets (as licenças aceitas e recusadas; a linha do `CREDITS.md` por tipo; o arquivo de licença ao lado do pack; a regra do repositório privado para EULA, como razão da recusa; a conta da cota do LFS; a lista de formatos do LFS e o porquê de cada um fora); O pipeline de import; O caminho da animação; O orçamento de vértices e o quadro; Os tokens do combate; A base da interface e a acessibilidade mínima; Em aberto. Cada número com a fonte.

### 3. `assets/CREDITS.md` e a checagem no portão (critério 3)

- O `CREDITS.md` ganha o resumo da política, a convenção da pasta e as colunas por tipo de licença; a tabela segue vazia.
- `tools/check_assets.sh`, no padrão de `tools/check_core_purity.sh`: uma função `check_root <dir>` que roda na raiz de verdade e em cada canário. Para cada pack, só no segundo nível de `assets/third_party/<fonte>/<pack>/`, exige um arquivo de licença dentro dela e uma linha do `assets/CREDITS.md` que contenha o caminho canônico sem barra final. Rejeita arquivo solto no nível 0 ou 1 e nome de pasta fora de `[a-z0-9_]+`. Sem `assets/third_party/`: "no packs yet (canaries ok: ...)". Shell POSIX.
- Os canários em `tools/canaries/assets/`, cobertos pelo `.gdignore`: `bad_no_line/`, `bad_no_license/`, `bad_stray_file/`, `good_pack/`, cada um com o próprio `assets/CREDITS.md` e um `modelo.txt` como asset, nunca um `.glb` (o filtro do LFS deixa um arquivo vazio passar como blob comum). A linha final: `canaries ok: N bad flagged, M good clean`.
- `tools/gate.sh` ganha o passo "Assets and LFS (DEC-0029)" depois da pureza.

### 4. `.gitattributes` e a prova do LFS (critério 7)

- Entram no LFS: `*.gltf`, `*.bin`, `*.obj`, `*.dae`, `*.tga`, `*.dds`, `*.ktx2`, `*.flac`, `*.woff`, `*.woff2`. O cabeçalho cita a DEC-0029. Nenhum arquivo rastreado tem essas extensões (o implementer confere).
- A prova é o próprio git, no mesmo passo do portão: `git check-attr filter -- <caminho de sonda>` tem de dizer `lfs` para um caminho de cada formato da lista e `unspecified` para `main.tscn`, `x.import`, `icone.svg` e `modelo.txt`. Hoje `.glb` dá `lfs` e `.gltf` dá `unspecified`: é o buraco.
- O "arquivo de sonda": um `.gltf` e um `.woff2` não vazios num pack temporário, `git lfs ls-files` com os dois nas notas da task, e fora antes do commit. Sem teste do gdUnit4 para isso.

### 5. `project.godot` e as guardas (critério 6)

- `display/window/size/viewport_width=1920`, `viewport_height=1080` e `rendering/anti_aliasing/quality/msaa_3d=1` (2x). O stretch já é `canvas_items` + `expand`.
- `test/project_settings_test.gd` ganha cinco guardas: a base, o stretch `canvas_items` e `expand`, o MSAA 2x. Cada guarda derrubada por sonda.
- A ordem das chaves: gravar por um script sem tela (`ProjectSettings.set_setting` e `save`), ou provar por sonda que uma regravação pelo editor deixa o diff vazio.

### 6. O que acompanha

- `AGENTS.md` (meta: até 12.300 caracteres): a regra 2 vira a chave do evento (DEC-0031); a linha de `assets/` do mapa ganha a convenção da pasta e o `CREDITS.md` (DEC-0029); a linha de `docs/design/` ganha "visual and audio"; a lista do portão ganha "assets and LFS"; a linha do LFS cita a DEC-0029. Para caber, o inventário de "Machine and tools" vai para `docs/arquitetura/testes-e-entrega.md`, com um ponteiro de duas linhas.
- `.claude/agents/reviewer.md`: a regra "sound and VFX only on fresh ticks" vira a chave do evento.
- `docs/arquitetura/rede.md` (§2, §5 e §6), `visao-geral.md` (a frase e "só uma frase da DEC-0004 mudou" vira duas), `testes-e-entrega.md` (a tabela do portão e a lista de canários, e o inventário de máquina e ferramentas).
- `DEC-0004` e `DEC-0026`: só o frontmatter `substituida_por` e uma linha de aviso no topo, datada; o corpo e o status não mudam, como a DEC-0022 fez. `docs/decisoes/README.md`: três linhas em Vigentes, as linhas da DEC-0004, DEC-0026 e DEC-0027 atualizadas, duas linhas em "O que foi substituído".
- Glossário: "Tick novo" e "Token de leitura" deixam de dizer "só nele tocam"; "Orçamento de vértices" ganha os 10 mil; "Pack de terceiros" entra.
- `mudancas.md`: a política decidida; as duas frases substituídas; a base e o MSAA no `project.godot`; o orçamento de vértices. `pendencias.md`: Q-09 ganha a linha do jitter (F-061 §3).

### 7. A ordem e o harness (DEC-0009)

1. O ok do plano vira a F-065.
2. A pergunta fixa da chave do evento; a reconferência do netfox; a sonda do "antes".
3. O orquestrador escreve o texto.
4. O `implementer` (um round): o `check_assets.sh` com os canários, a prova do `git check-attr` e o passo no gate; o `.gitattributes`; o `project.godot` com as cinco guardas, cada uma derrubada por sonda; o `git lfs ls-files` do pack temporário; o portão verde. Sem test-writer: não há regra de núcleo.
5. O `reviewer` (contexto limpo, Fable): os 7 critérios, com a checagem de que cada citação contém o que afirma e de que cada número vem de `docs/design/` ou é v0 marcado.
6. O portão num clone limpo, com `file:///C:/...` (F-056 §1).
7. A task: critérios e DoD pela CLI (o DoD 2 "não se aplica: `core/` sem código"), as notas por `--append-notes`, Done; o PR em português; o merge é do Arthur. A vitrine ganha "O fechamento". O diário continua a sessão 9; o registro ganha a linha; as três DECs vão para o Yabadoo.

### Verificação

- `bash tools/gate.sh` verde, com o passo dos assets dizendo `no packs yet (canaries ok: 3 bad flagged, 1 good clean)` e os formatos do LFS conferidos, e nenhuma linha `ERROR:`.
- As sondas, registradas nas notas: antes, o pack falso passa; depois, o pack sem linha derruba o portão, e com a linha e a licença passa; o pack temporário aparece em `git lfs ls-files`; o `project.godot` com a base em 1152 × 648 ou o MSAA em 0 derruba o `project_settings_test.gd`.
- O clone limpo roda o portão verde em menos de 90 s.
- O reviewer devolve APPROVE com a prova de cada critério.

## §2 — A crítica do agente de planejamento, em resumo

Dezesseis achados, seis obrigatórios: a DEC-0026 também tem uma frase a substituir (o `get_last_known_state()` do atraso de visão), e as DECs vigentes precisam de uma reconferência do netfox contra a F-061; a prova do critério 7 tem de ser o `git check-attr` com um arquivo não vazio, porque um `.glb` de 0 bytes nem vai para o LFS, e um casador de globs num teste provaria o casador; o `visual-e-audio.md` precisa dizer a regra do repositório privado como razão da recusa da EULA; a checagem de assets precisa tratar a pasta ausente, o arquivo solto, os nomes de licença em qualquer caixa e o caminho canônico; a sonda do "depois" não pode usar um `.glb` vazio dentro do projeto, porque o import o rejeita; a substituição de uma frase só muda o frontmatter e o aviso no topo; o `reviewer.md`, duas linhas do glossário e o `testes-e-entrega.md` contradiriam a DEC-0031. Os demais: o `AGENTS.md` precisa de um corte real para caber; a autoria da DEC-0029 registra a delegação; o ducking de 12 dB e a escala de 0,8 a 1,5 são v0 do Claude; as citações da F-050 usam `§1.x` e `§3 Cxx`; os nomes dos settings do Godot 4.7.2 estão certos e a ordem das chaves é o risco; o `.gitattributes` não tem arquivo rastreado das extensões novas; a DEC-0031 diz que um evento apresentado nunca é desfeito; e as peças do fechamento que as TASK-5 e TASK-6 fizeram (a F do plano, a sonda do "antes", o clone com `file:///C:/`, o DoD 2, os comandos da CLI, a vitrine, o diário, o registro, o Yabadoo, a pergunta fixa).
