---
id: F-051
titulo: "Pesquisa: o que o Godot 4.7.2 oferece para importar modelo, animação e som, o renderer Compatibility, o Theme, a acessibilidade e o áudio (07/10/2026)"
recebido_em: 2026-10-07
como: Relatório final de um agente de pesquisa (Sonnet 5.5, esforço alto) de um workflow de 5 agentes do Claude Code, pedido ao deixar a TASK-7 Ready (sessão 8, 07/10/2026). O §1 está como chegou, em português, com o link de cada afirmação, só com os títulos rebaixados um nível. O §2 é o resumo e a lista do que o agente não confirmou, como chegaram. O §3 traz, para cada afirmação que o agente marcou como importante, o veredicto do verificador adversarial (Fable 5.1, esforço xhigh), que abriu a fonte e citou a frase. O §4 lista as demais afirmações, com o link. O relatório chamava o Arthur de "a Arthur" em dez trechos, por engano do agente; o orquestrador trocou o artigo, sem mudar nenhuma afirmação.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: quatro pesquisadores rodaram em paralelo, cada um com uma lente (licenças, Godot, animação e leitura do combate), e um verificador abriu 40 das 48 afirmações marcadas: 37 confirmadas, 1 refutada (o Standard grátis do UAL1 tem 42 animações, não 45) e 2 não verificáveis (os "60 movimentos" do pack da Synty e a licença do Paragon na Fab). As 8 restantes ficaram sem verificação, pelo limite do workflow. "Não confirmado" no texto quer dizer que o agente não conseguiu abrir a fonte primária. Fatos, inferências e recomendações estão marcados pelo próprio agente. O que vira regra sai da conversa da TASK-7, não daqui.

## §1 — O relatório, como chegou

Data da pesquisa: 2026-10-07. Lente: documentação oficial do Godot, notas de versão e código-fonte da tag `4.7.2-stable`.

Como li as fontes: a página `docs.godotengine.org/en/stable` mostra "Godot Engine 4.7 documentation" (verificado em 2026-10-07). Para ter o texto exato, baixei os arquivos `.rst` da branch `4.7` do repositório [godot-docs](https://github.com/godotengine/godot-docs/tree/4.7). Eles são a fonte dessas páginas. Cada afirmação abaixo marca se é **fato** (com link), **inferência** (eu concluí a partir de fatos) ou **recomendação** (minha opinião para a conversa de design).

O Godot 4.7.2 saiu em 18/08/2026 e é uma versão de manutenção com 57 correções, sem mudança de recurso ([anúncio](https://godotengine.org/article/maintenance-release-godot-4-7-2/), checado em 2026-10-07). Por isso trato a documentação 4.7 como válida para o 4.7.2.

---

### 1. Importação de modelos 3D e animações

#### 1.1 Formatos suportados e qual a documentação recomenda

| Formato | O que a documentação diz | Desde |
|---|---|---|
| glTF 2.0 (`.glb` / `.gltf`) | "glTF 2.0 **(recommended)**". O `.glb` (binário) é o menor e já traz malha e texturas. | já era o caminho principal no 4.0 (inferência) |
| FBX | Importado pela biblioteca ufbx. O fluxo antigo, FBX2glTF, exige um programa externo ligado ao SDK proprietário da Autodesk, e a doc recomenda o ufbx. | ufbx é o padrão para FBX adicionado a partir do 4.3 |
| `.blend` | O Godot chama o Blender para exportar glTF de forma transparente. Exige Blender 3.0+ instalado (recomendado 3.5+). Todo mundo do time precisa ter o Blender. | 4.0 (inferência) |
| COLLADA (`.dae`) | "Mais antigo, mas suportado". Para cenas complexas ou com animação, a doc recomenda glTF. | |
| OBJ | Sem esqueleto, sem animação, sem UV2, sem PBR. | |

Fatos, com link: [available_formats.rst](https://github.com/godotengine/godot-docs/blob/4.7/tutorials/assets_pipeline/importing_3d_scenes/available_formats.rst) (página: [Available 3D formats](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html)). O ufbx entrou no 4.3 ([notas do 4.3](https://godotengine.org/releases/4.3/): "Native ufbx importer"). O 4.7.2 usa ufbx 0.21.3, licença MIT ([thirdparty/README.md](https://github.com/godotengine/godot/blob/4.7.2-stable/thirdparty/README.md)).

Detalhes que importam para o Arthur:

- **Exportação do Blender para glTF:** se o modelo tiver blend shapes, a opção "Data > Armature > Export Deformation Bones Only" precisa estar ligada, senão o sombreamento sai errado. O Blender exporta materiais com a face de trás visível (cull mode "Disabled"). Isso custa desempenho. A doc manda ligar "Backface Culling" no material do Blender antes de exportar (mesma página).
- **Triangular antes de exportar:** a doc recomenda usar o modificador Triangulate no Blender e marcar "Apply Modifiers", em vez de deixar o Godot triangular ([model_export_considerations.rst](https://github.com/godotengine/godot-docs/blob/4.7/tutorials/assets_pipeline/importing_3d_scenes/model_export_considerations.rst)).
- **Pose de repouso:** exporte com o esqueleto na T-pose ou na pose padrão (mesma página).
- **Eixos:** o Godot usa Y para cima, mão direita, e -Z é a frente da câmera. Personagens olham para +Z no asset, ou seja, de frente para a câmera por padrão. No Blender, +Y é atrás e -Y é frente (mesma página).
- **Texturas separadas ou embutidas:** a opção de importação "Embedded Texture Handling" escolhe entre descartar, extrair para arquivos, ou embutir (como Basis Universal ou sem compressão). Extrair dá mais controle sobre as opções de cada textura ([import_configuration.rst](https://github.com/godotengine/godot-docs/blob/4.7/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.rst)).

#### 1.2 Unidades e escala

- **Fato:** o Godot usa 1 unidade = 1 metro por convenção, e a doc de glTF aponta para a especificação glTF 2.0, que define a unidade em metros. A frase "1 unit = 1 m" não aparece palavra por palavra nas páginas que li; a página de exportação só linka a [especificação](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#coordinate-system-and-units), que não abri. Marquei como não confirmado.
- **Fato (código-fonte):** no 4.7.2, o importador de FBX configura o ufbx com `target_unit_meters = 1.0`, eixos de mão direita com Y para cima e `space_conversion = UFBX_SPACE_CONVERSION_MODIFY_GEOMETRY` ([fbx_document.cpp, linhas 2029 a 2032](https://github.com/godotengine/godot/blob/4.7.2-stable/modules/fbx/fbx_document.cpp)). Ou seja, o importador tenta converter a unidade do arquivo para metros sozinho.
- **O problema do "Mixamo escala 0.01":** a documentação do Godot não fala de Mixamo. Resultados de busca e issues da comunidade dizem que os personagens do Mixamo chegam em centímetros, com um nó acima dos ossos com escala 0.01. **Não confirmei isso numa fonte oficial nem no 4.7.2.** Recomendação: fazer um teste de importação e medir a altura. A cápsula do jogo tem 1,8 m; o modelo importado deve ter cerca de 1,8 m de altura.
- **Ferramentas de correção no Godot (fato):** a opção `nodes/root_scale` multiplica a cena inteira. Com `nodes/apply_root_scale = true` (padrão) a escala é aplicada nas malhas, ossos e animações, e o nó raiz fica com escala (1,1,1) ([ResourceImporterScene](https://docs.godotengine.org/en/stable/classes/class_resourceimporterscene.html)). Isso importa, porque escala no nó raiz de um lutador atrapalharia colisão e câmera.
- **Fato:** o ufbx tem "Allow Geometry Helper Nodes", que cria nós auxiliares (GeometryTransformHelper, ScaleHelper) para casos de transformação de geometria.

#### 1.3 Dicas de importação nos nomes dos nós

Todos os sufixos funcionam com `-`, `$` ou `_` e não diferenciam maiúscula de minúscula. Exceção: `loop` e `cycle` em animações não precisam de hífen. Fonte: [node_type_customization.rst](https://github.com/godotengine/godot-docs/blob/4.7/tutorials/assets_pipeline/importing_3d_scenes/node_type_customization.rst) (página: [Node type customization](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/node_type_customization.html)).

| Sufixo | Vale para | Efeito |
|---|---|---|
| `-noimp` | nó ou animação | Remove na importação, qualquer tipo. |
| `-col` | malha | Cria colisão estática filha, com a geometria da malha (triângulos: lenta, exata). |
| `-convcol` | malha | Colisão convexa (ConvexPolygonShape3D) em vez de triângulos. |
| `-colonly` | malha | Remove a malha e cria um StaticBody3D só de colisão. |
| `-convcolonly` | malha | Igual ao anterior, mas convexo por decomposição. |
| `-occ` / `-occonly` | malha | Cria Occluder3D (sem remover a malha / convertendo a malha). |
| `-navmesh` | malha | Vira malha de navegação (a malha original é removida). |
| `-vehicle`, `-wheel` | malha | Vira filha de VehicleBody3D / VehicleWheel3D. |
| `-rigid` | malha | Vira RigidBody3D. |
| `-loop`, `-cycle` | animação | A animação entra com o flag de loop. No Blender exige o editor NLA e o nome da Action começando ou terminando com `loop` ou `cycle`. |
| `-alpha` | material | Importa com transparência alfa. |
| `-vcol` | material | Importa com cor de vértice como albedo e flag sRGB. |

Três opções de importação controlam isso: `nodes/use_name_suffixes`, `nodes/use_node_type_suffixes` e o `-noimp`, que continua valendo mesmo com os outros desligados.

Equivalente na interface: na janela **Advanced Import Settings** cada nó tem "Skip Import", "Generate > Physics / NavMesh / Occluder" e, para malhas, "Save to File", "Generate > Shadow Meshes / Lightmap UV / LODs" ([advanced_import_settings.rst](https://github.com/godotengine/godot-docs/blob/4.7/tutorials/assets_pipeline/importing_3d_scenes/advanced_import_settings.rst)). Dá para extrair os materiais para `.tres` com **Actions > Extract Materials**, e o Godot não sobrescreve suas edições ao reimportar (mesma página). Isso é a analogia de um "override" em CSS: o arquivo externo vence o que veio do Blender.

Recomendação para o jogo: usar `-colonly`/`-convcolonly` nos mapas (separa o que se vê do que colide), `-noimp` em luzes e câmeras de apoio do Blender, e `-loop` nos nomes das Actions de corrida e de postura de guarda.

#### 1.4 Como as animações entram

Fatos ([import_configuration.rst](https://github.com/godotengine/godot-docs/blob/4.7/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.rst), [advanced_import_settings.rst](https://github.com/godotengine/godot-docs/blob/4.7/tutorials/assets_pipeline/importing_3d_scenes/advanced_import_settings.rst)):

- A cena importada ganha um AnimationPlayer com as animações. O otimizador roda por padrão e reduz muito o tamanho; a doc diz para deixá-lo ligado, salvo suspeita de animação quebrada.
- **FPS de amostragem:** padrão 30; a doc diz que há pouco ganho acima disso, por causa da interpolação. **Trimming** (padrão desligado) corta o começo e o fim sem mudança. **Remove Immutable Tracks** (padrão ligado) tira trilhas que só têm o valor padrão.
- **Animation Library:** no painel Import, mude o tipo de importação para "Animation Library". O arquivo glTF vira um AnimationLibrary em vez de uma cena. A doc diz que isso serve para distribuir animações separadas dos modelos e usar o mesmo conjunto em vários personagens.
- **Save to file:** por padrão as animações ficam embutidas. Salvar em arquivo permite adicionar trilhas próprias que sobrevivem à reimportação. Isso é útil para marcar os eventos de som e de efeito por tick.
- **Slices:** uma linha do tempo só, com uma animação chamada `default`, pode ser fatiada em várias.
- **Filter script:** um arquivo de texto com `@+*_Loop` e `+*`/`-Skeleton:*Control` escolhe animações e trilhas a manter.
- **Scene inheritance:** abrir a cena importada oferece criar uma cena herdada, onde dá para adicionar nós sem perder a ligação com o arquivo fonte. Não dá para remover nós nem editar subrecursos.

#### 1.5 Retargeting com SkeletonProfileHumanoid e BoneMap

Fatos ([retargeting_3d_skeletons.rst](https://github.com/godotengine/godot-docs/blob/4.7/tutorials/assets_pipeline/retargeting_3d_skeletons.rst), página: [Retargeting 3D Skeletons](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html)):

- **Por que existe:** no Godot as animações guardam trilhas de Transform por osso. Dois esqueletos com os mesmos nomes de osso ainda podem ter posições de repouso (Bone Rest) diferentes. Para compartilhar animação é preciso igualar nomes e repousos. Analogia: seria como duas classes TypeScript com o mesmo nome de método mas contratos diferentes.
- **BoneMap + SkeletonProfile:** no Advanced Import, ao selecionar o Skeleton3D, a seção "Retarget" tem uma propriedade `bone_map`. Crie um BoneMap com um SkeletonProfile; o preset `SkeletonProfileHumanoid` faz mapeamento automático por padrão de nome. A doc recomenda usar nomes de osso comuns em inglês. Ossos faltando ou duplicados aparecem em magenta e não bloqueiam a importação.
- **Rest Fixer:** as regras do perfil humanoide são T-pose, olhando para +Z, sem Transform no nó, eixo +Y do osso pai para o filho. Opções: *Apply Node Transform*, *Normalize Position Tracks* (usa a altura do osso "Hips" como `motion_scale`, para a passada não escorregar entre modelos de alturas diferentes), *Overwrite Axis* e *Fix Silhouette* (para modelos em A-pose).
- **Limites declarados pela própria doc:** *Overwrite Axis* "pode dar resultados horríveis se o Bone Rest original for importante". *Fix Silhouette* não conserta silhuetas muito diferentes e pode não corrigir a rotação do osso. Em A-pose, os pés podem ficar ruins, dependendo da altura do salto do modelo.
- **Desde quando:** os Retarget options novos para FBX saíram no 4.3 ([notas do 4.3](https://godotengine.org/releases/4.3/)). A primeira versão com BoneMap/SkeletonProfile não confirmei (inferência: 4.0).
- **Nó de runtime:** existe `RetargetModifier3D` na referência de classes do 4.7 ([classe](https://docs.godotengine.org/en/stable/classes/class_retargetmodifier3d.html)). Não li o corpo, então não afirmo detalhes.

Inferência: para um jogo de espada com um corpo só (cápsula de 1,8 m), o retargeting só vale a pena se o Arthur for juntar animações de fontes diferentes, como um pacote de espada mais um pacote de acrobacia. Um esqueleto único feito para o jogo dispensa o retargeting.

#### 1.6 Root motion, e por que um jogo com rollback não o usa para mover o corpo

Fatos ([AnimationMixer](https://docs.godotengine.org/en/stable/classes/class_animationmixer.html)):

- `root_motion_track` é o caminho de uma trilha de posição, rotação ou escala. A transformação dessa trilha é cancelada visualmente, e os métodos `get_root_motion_position()`, `get_root_motion_rotation()` e `get_root_motion_scale()` devolvem o deslocamento por quadro.
- O exemplo da própria documentação usa `get_root_motion_position()` para mover um CharacterBody3D.
- `callback_mode_process` tem o valor `ANIMATION_CALLBACK_MODE_PROCESS_MANUAL = 2`: "Do not process animation. Use `advance()` to process the animation manually". O método é `advance(delta)`.
- `deterministic` (padrão `false`): quando `true`, o blend usa um algoritmo determinístico (pesos sem normalizar, valor inicial 0 ou a animação `RESET`).

Inferência (conecta com DEC-0004, DEC-0022 e F-007): o root motion lê a animação para mover o corpo. A animação é apresentação, e o netfox não sincroniza AnimationTree ([issue #553](https://github.com/foxssake/netfox/issues/553), título "Synchronized AnimationTree", item de investigação). Se o corpo andasse pela animação, o estado do jogo passaria a depender de um nó que o rollback não restaura. Por isso o movimento fica no núcleo (inteiros por tick), e a animação só lê o estado. O AnimationMixer em modo manual com `advance()` chamado a partir do estado do lutador é o caminho coerente com a F-007.

#### 1.7 Arquivos `.import`, `.godot/` e o que commitar

Fatos ([import_process.rst](https://github.com/godotengine/godot-docs/blob/4.7/tutorials/assets_pipeline/import_process.rst), [version_control_systems.rst](https://github.com/godotengine/godot-docs/blob/4.7/tutorials/best_practices/version_control_systems.rst)):

- Importar cria um `<asset>.import` ao lado do arquivo fonte. **Commite esses arquivos**: guardam as opções de importação.
- O resultado importado fica em `res://.godot/imported/`. A doc **não recomenda** commitar a pasta `.godot/`; ela é regenerada.
- Ignore também `*.translation` (gerados dos CSV).
- Com Git LFS, configure antes do primeiro commit dos binários. O `.gitattributes` do projeto já cobre `.glb`, `.fbx`, `.blend`, `.png`, `.wav`, `.ogg`, `.ttf` e outros. Observação: os arquivos `.import` não estão na lista de LFS, o que está correto, porque são texto pequeno.

#### 1.8 Importar como: malhas e texturas

- **Malhas** ([ResourceImporterScene](https://docs.godotengine.org/en/stable/classes/class_resourceimporterscene.html)): `meshes/ensure_tangents` (padrão `true`), `meshes/generate_lods` (padrão `true`), `meshes/create_shadow_meshes` (padrão `true`), `meshes/light_baking` (padrão 1) e `meshes/force_disable_compression` (padrão `false`). A doc diz que desligar tangentes e LODs reduz tamanho e tempo de importação quando não são necessários. Recomendação: personagens de estilo "toon" sem normal map não precisam de tangentes; LOD só vale para o que aparece de longe.
- **Texturas** ([importing_images.rst](https://github.com/godotengine/godot-docs/blob/4.7/tutorials/assets_pipeline/importing_images.rst)): o padrão (sem mipmaps, Lossless) serve para 2D. A opção **Detect 3D** liga mipmaps e muda a compressão para **VRAM Compressed** quando a textura é usada num material 3D. VRAM Compressed é "o modo padrão e mais comum para 3D" e reduz também a memória de vídeo. Em desktop usa S3TC (DXT1 para opacas, DXT5 para transparentes ou normal map) ou BPTC (BC7 e BC6H) na opção alta qualidade.
- **No renderer Compatibility:** a opção "Compress > High Quality" (BPTC) "é sempre considerada desativada". Ou seja, com Compatibility, o que sai em desktop é S3TC.
- **Pixel art e UI:** a doc diz que texturas "pixel art" devem ficar sem VRAM compression mesmo em 3D. Ícones e HUD ficam em Lossless.
- **sRGB:** o importador marca o que for cor como sRGB. Para normal maps, use o formato OpenGL (Y+); se vier no estilo DirectX, ligue "Normal Map Invert Y". Vertex colors são tratados como sRGB e convertidos para linear na renderização ([BaseMaterial3D](https://docs.godotengine.org/en/stable/classes/class_basematerial3d.html)).
- **Material de projeto:** o projeto ainda não tem `import_s3tc_bptc` no `project.godot`. A configuração do projeto `rendering/textures/vram_compression/import_s3tc_bptc` é uma sobrescrita e o importador "sempre importa o formato que a plataforma precisa", mesmo com `false` ([ProjectSettings](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html)). Para o Arthur: nada a mexer no desktop; o exportador cuida.

#### 1.9 Organização do projeto e sensibilidade a maiúsculas no PCK

Fatos ([project_organization.rst](https://github.com/godotengine/godot-docs/blob/4.7/tutorials/best_practices/project_organization.rst)): a doc sugere agrupar os ativos perto das cenas que os usam (por exemplo `/characters/player/cubio.dae` e `/characters/player/cubio.png`) e manter terceiros em `addons/`, com exceções razoáveis para ativos de personagem. Usar **snake_case** em pastas e arquivos "evita problemas de maiúscula e minúscula que podem surgir depois de exportar para Windows". O PCK do Godot é sensível a maiúsculas, enquanto Windows e macOS não são. Isso casa com a regra do AGENTS.md (snake_case).

Um arquivo `.gdignore` vazio numa pasta impede a importação e esconde a pasta do FileSystem. Útil para `assets/fontes_originais/` com `.blend`, `.psd`, `.kra` pesados que não precisam ser importados. Cuidado: pastas ignoradas não podem ser carregadas por `load()` nem `preload()`.

---

### 2. O renderer Compatibility no Godot 4.7.2

Fonte: [renderers.rst](https://github.com/godotengine/godot-docs/blob/4.7/tutorials/rendering/renderers.rst) (página: [Overview of renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)), mais as classes citadas. Jargão: o **Compatibility** usa OpenGL; Mobile e Forward+ usam Vulkan, Direct3D 12 ou Metal. O projeto usa `gl_compatibility` (`project.godot`).

#### 2.1 Tabela: o que o Compatibility tem e não tem

| Recurso | Compatibility | Observação |
|---|---|---|
| MSAA 3D | Sim | O padrão do projeto é desligado (`msaa_3d = 0`). Precisa ser ligado. |
| MSAA 2D | Não | |
| FXAA | **Não** | Mobile e Forward+ têm. |
| SMAA | **Não** | |
| TAA / FSR2 | **Não** | |
| SSAA (supersampling) | Sim | Via escala 3D. Caro. |
| Glow | Sim, versão simplificada | Sem `glow_levels/*`, `glow_normalized`, `glow_strength`, `glow_blend_mode`, `glow_mix`, `glow_map`. Sempre usa o modo Screen ([Environment](https://docs.godotengine.org/en/stable/classes/class_environment.html)). |
| SSAO | Sim, simples | Entrou no 4.6 (ver 2.2). O Mobile não tem. |
| SSR | **Não** | |
| SSIL, SDFGI, VoxelGI | **Não** | |
| LightmapGI | Parcial | Renderiza lightmaps já assados. Assar exige hardware com RenderingDevice. |
| ReflectionProbe | Sim | No máximo 2 por malha. |
| Fog (profundidade e altura) | Sim | |
| Volumetric Fog | **Não** | |
| Tonemapping e Adjustments | Sim | Adjustments inclui brilho, contraste, saturação e LUT de cor. |
| Decals | **Não** | |
| Light projector textures | **Não** | |
| PCSS (sombra suave) | **Não** | |
| Contact shadows | **Não** | |
| Luzes | 8 omni e 8 spot por malha ("Can be increased"), até 8 direcionais | Limite global padrão: 32 luzes posicionais por quadro (`rendering/limits/opengl/max_renderable_lights`). |
| Sombras | Sim, com abordagem de múltiplos passes e mistura menos precisa | "Lights with shadows use a multi-pass approach and less accurate blending." |
| Screen texture (`hint_screen_texture`) | Sim | |
| Depth texture (`hint_depth_texture`) | Sim | A profundidade é de 24 bits sem reverse Z. |
| Normal/Roughness buffer | **Não** | `hint_normal_roughness_texture` só no Forward+. |
| Compute shaders | **Não** | |
| CompositorEffects | **Não** | |
| Custom post-processing com fullscreen quad | Sim | O caminho para efeitos de tela cheia. |
| Debanding | **Não** | |
| Particle trails e colisão SDF | **Não** | |
| Depth of field | **Não** | |
| VSync adaptativo e Mailbox | **Não** | |
| HDR output (novo no 4.7) | **Não** | O HDR de saída vale só para Mobile e Forward+. |
| Precisão de cor | RGBA8 (baixa faixa dinâmica) | |
| GPUParticles3D / CPUParticles3D | Não consta na tabela | Ver 2.3. |
| Stencil (4.5) | Não consta na tabela | Ver 2.4. |

Observação sobre a faixa do renderer: a tabela diz "Custo de renderização: custo base baixo, mas custo de escala alto" para o Compatibility. Para a RX 550 em 1080p isso importa: resolução e MSAA são os botões caros.

#### 2.2 Quando o SSAO entrou no Compatibility

Fato: o snapshot [Godot 4.6 dev 3](https://godotengine.org/article/dev-snapshot-godot-4-6-dev-3/) lista "Rendering: Implement a very simple SSAO in GLES3 (GH-109447)". A referência de `Environment.ssao_enabled` diz: "SSAO is only supported in the Forward+ and Compatibility rendering methods, not Mobile." As notas finais do 4.6 e 4.5 não citam isso numa linha própria que eu tenha achado; a prova é o snapshot e a classe. O adjetivo "very simple" é do changelog, não meu. Inferência: espere uma qualidade menor que a do Forward+; teste no hardware do Arthur antes de depender dele.

#### 2.3 Partículas

A tabela da página de renderers não lista GPUParticles3D nem CPUParticles3D. O que está lá são as exceções do Compatibility: partículas com trails (rastros) e colisão SDF não existem. Na classe GPUParticles3D, a única restrição ao Compatibility é `emit_particle()`, "só suportado em Forward+ e Mobile" ([GPUParticles3D](https://docs.godotengine.org/en/stable/classes/class_gpuparticles3d.html)). Inferência: GPUParticles3D funciona no Compatibility, sem trails nem `emit_particle()`. **Não vi uma frase afirmando isso**, então fica como não confirmado. CPUParticles3D é a alternativa que não depende do GPU.

#### 2.4 Stencil

- **Fato (versão):** o buffer de stencil é a novidade de renderização do [Godot 4.5](https://godotengine.org/releases/4.5/) ("Stencil buffer support"). A doc de shaders avisa: "Stencil support is experimental, use at your own risk" e que só se lê o stencil no passe transparente ([spatial_shader.rst](https://github.com/godotengine/godot-docs/blob/4.7/tutorials/shaders/shader_reference/spatial_shader.rst)). O `BaseMaterial3D` tem presets `STENCIL_MODE_OUTLINE` e `STENCIL_MODE_XRAY`, com `stencil_outline_thickness` (padrão 0,01).
- **Fato (código-fonte):** o backend OpenGL do Compatibility no 4.7.2 contém código de stencil (`FLAG_USES_STENCIL`, `enable_gl_stencil_test`, `glClear(... GL_STENCIL_BUFFER_BIT)` em [rasterizer_scene_gles3.cpp](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/rasterizer_scene_gles3.cpp)).
- **Inferência:** stencil existe no Compatibility 4.7.2, mas a documentação não o lista na tabela de recursos e o recurso é rotulado experimental. Teste antes de contar com ele (por exemplo, para o contorno do lutador atrás de parede).

#### 2.5 O que isso significa para um visual estilizado

Fatos de material ([BaseMaterial3D](https://docs.godotengine.org/en/stable/classes/class_basematerial3d.html)):

- `shading_mode` aceita *Unshaded* ("o mais rápido, desliga toda interação com luzes"), *Per-Vertex* e *Per-Pixel*.
- `diffuse_mode` aceita `DIFFUSE_TOON` ("um corte duro na luz, com suavização afetada pela rugosidade") e `specular_mode` aceita `SPECULAR_TOON`. O Compatibility não faz multiespalhamento nos metais.
- `grow` (propriedade do material) expande a malha ao longo das normais. Combinado com cull mode da face da frente, é o casco invertido (inverted hull) para contornos. Não li o texto completo da propriedade; é a técnica padrão (inferência).
- Cor de vértice: `vertex_color_use_as_albedo` e, na importação, o sufixo `-vcol`.

| Técnica de contorno | Como funciona | No Compatibility | Custo e riscos |
|---|---|---|---|
| Casco invertido | Segunda malha ou `next_pass` levemente maior, só com as faces de trás, em cor sólida | Funciona (material comum) | Dobra os vértices do lutador. Espessura varia com a distância. Cantos duros abrem buracos se as normais não forem suavizadas. |
| Stencil outline do Godot | Preset `STENCIL_MODE_OUTLINE` ou shader próprio | Código existe, recurso experimental | Evita contorno interno. Exige `material_overlay` ou `next_pass`. Testar. |
| Pós-processo por profundidade ou normal | Quad de tela cheia lê `hint_depth_texture` | Profundidade sim. **Normais não** (só Forward+) | Detecta bordas só por profundidade. O Compatibility usa NDC de OpenGL (Z de -1 a 1), a doc de pós-processo explica a diferença e oferece `RENDERER_COMPATIBILITY` para tratar. |

Recomendação: começar pelo casco invertido (garantido no Compatibility), fazer o personagem com sombreamento `DIFFUSE_TOON` ou *Unshaded* com cor de vértice, e medir. O realce de "leitura" do golpe (pilar 1) pode ser feito com cor/brilho no material do lutador, sem pós-processo. Isso é inferência de projeto, não fato do Godot.

---

### 3. Interface (UI)

#### 3.1 O que é um Theme

Fato ([Introduction to GUI skinning](https://docs.godotengine.org/en/stable/tutorials/ui/gui_skinning.html), [Theme](https://docs.godotengine.org/en/stable/classes/class_theme.html)): o `Theme` é um recurso para estilizar nós `Control` e `Window`. Guarda "itens de tema" de seis tipos: Color, Constant (inteiro), Font, Font size, Icon e StyleBox. Cada item pertence a um "tipo de tema" (por exemplo `Button`, `Label`). O tema se aplica em cascata do pai para os filhos, enquanto a cadeia de controles não for interrompida.

Analogia para o Arthur: o Theme é uma folha de estilo CSS. Um tipo de tema é um seletor (`Button`), um item é uma propriedade (`font_color`), e as **variações de tipo** (`theme_type_variation`) são classes CSS (por exemplo um `Header` que é variação de `Label`). Os **overrides locais** (`add_theme_color_override`) são o `style=""` inline. A diferença: o Godot não tem especificidade por seletor composto; a ordem é fixa.

Ordem de busca de um item, segundo a doc: (1) override local; (2) tema do próprio controle e dos ancestrais, usando variação, classe e classes-pai; (3) tema do projeto; (4) tema padrão (`ThemeDB`); (5) um valor padrão do tipo.

#### 3.2 Tema do projeto, tema padrão, fontes

- **Tema do projeto:** `gui/theme/custom` aponta para um `.tres`/`.theme`. `gui/theme/custom_font` define a fonte de reserva ([ProjectSettings](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html)). O tema padrão é "constante e não pode ser alterado".
- **ThemeDB** ([classe](https://docs.godotengine.org/en/stable/classes/class_themedb.html)): `fallback_font_size` padrão 16, `fallback_base_scale` padrão 1,0, `get_default_theme()` e `get_project_theme()`.
- **Escala do tema padrão:** `gui/theme/default_theme_scale` (padrão 1,0) só é lido na inicialização; em tempo de execução use `ThemeDB.fallback_base_scale`. Para escalar toda a interface em tempo de execução, a doc prefere `Window.content_scale_factor`.
- **Fontes:** `FontFile` carrega TTF/OTF; `FontVariation` (propriedades `variation_embolden`, `variation_opentype`, `variation_transform`, `spacing_*`, `base_font`) deriva negrito sintético, espaçamento e eixos de fonte variável de uma fonte base sem ter outro arquivo ([FontVariation](https://docs.godotengine.org/en/stable/classes/class_fontvariation.html), [Using fonts](https://docs.godotengine.org/en/stable/tutorials/ui/gui_using_fonts.html)).
- **MSDF** (Multichannel Signed Distance Field): opção na importação da fonte (`multichannel_signed_distance_field`, padrão `false`; `msdf_pixel_range` 16, `msdf_size` 48). Vantagens: fica nítida em qualquer tamanho e causa menos travadinha ao desenhar glifos grandes pela primeira vez. Desvantagens: custo base maior, tamanhos pequenos ficam menos claros (sem hinting), sem subpixel LCD, e fontes com contornos que se cruzam saem erradas ([Using fonts](https://docs.godotengine.org/en/stable/tutorials/ui/gui_using_fonts.html)). Recomendação: fonte rasterizada (padrão) para texto pequeno de menu e chat; MSDF só para números de dano ou títulos que mudam de tamanho com animação.

#### 3.3 Como o stretch `canvas_items` + `expand` se comporta

O que está no `project.godot` hoje: `window/stretch/mode="canvas_items"` e `window/stretch/aspect="expand"`. **Não há tamanho base definido**, então vale o padrão: 1152 x 648 ([ProjectSettings](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html), `display/window/size/viewport_width` e `_height`).

Fatos ([Multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html)):

- `canvas_items`: o tamanho base é esticado para cobrir a tela; "o 3D não é afetado", e o 2D (UI) é renderizado direto na resolução final, sem correspondência 1:1 de pixels.
- `expand`: mantém a proporção, mas não segura largura nem altura. Em tela mais larga que a base ganha área na horizontal; em tela mais alta, na vertical. Por isso a doc manda ancorar os Controls (menu Layout) nos cantos certos.
- Receita da doc para jogo de desktop 3D, não pixel art: base **1920 x 1080**, stretch `canvas_items`, aspect `expand`, e expor "resolution scaling" (escala 3D) nas opções, para ajustar a resolução 3D separadamente da UI.
- `Window.content_scale_factor` (padrão 1,0) é o botão em tempo de execução para o jogador aumentar a interface por acessibilidade ("canvas_items: elementos 2D escalados em relação ao tamanho base, depois multiplicados pelo Scale").
- `scale_mode`: `fractional` (padrão) ou `integer`.

Conta (minha, a partir dos números acima): com a base padrão 1152 x 648 e uma tela de 1920 x 1080, o fator é 1920/1152 = 1,667 nos dois eixos (a proporção é 16:9, igual), então a UI cobre a tela inteira, ampliada 1,667 vezes. Em 2560 x 1440 o fator é 2,222. Em 1366 x 768 é 1,186. Em tela 21:9 (2560 x 1080), `expand` mantém a altura na escala 1,667 e acrescenta largura. Recomendação: definir a base em 1920 x 1080 (a doc sugere isso), para os tamanhos de fonte no tema valerem em pixels de 1080p. Mexer em `project.godot` é decisão do Arthur; o `test/project_settings_test.gd` guarda configurações já decididas.

#### 3.4 Controles para um HUD

Da referência de classes ([Control](https://docs.godotengine.org/en/stable/classes/class_control.html), [ProgressBar](https://docs.godotengine.org/en/stable/classes/class_progressbar.html), [TextureProgressBar](https://docs.godotengine.org/en/stable/classes/class_textureprogressbar.html), [LabelSettings](https://docs.godotengine.org/en/stable/classes/class_labelsettings.html)):

- `Label`: texto. `LabelSettings` é um recurso reaproveitável com fonte, contorno e sombra, bom para números de dano.
- `ProgressBar`: porcentagem, mostra o valor no centro, pode ser indeterminada.
- `TextureProgressBar`: mais modos de preenchimento (radial, horizontal, vertical) e texturas. Serve para a barra de stamina e para mostrar o cooldown do arremesso do gancho em círculo.
- `Container` (HBox, VBox, Grid, Margin, Center) controla o layout (doc [gui_containers.rst](https://github.com/godotengine/godot-docs/blob/4.7/tutorials/ui/gui_containers.rst)).
- **Novidade do 4.7:** as propriedades `offset_transform` deixam transladar, girar ou escalar um Control "sem afetar o resto do container", e por padrão não afetam a entrada do mouse ([notas do 4.7](https://godotengine.org/releases/4.7/)). Útil para um "soco" de escala na barra quando a stamina acaba.
- Regra do projeto: a UI só lê o estado e só toca som ou efeito em ticks "frescos" (`is_fresh`). Isso vale para barras: ler o valor do estado e não de um `Timer`.

#### 3.5 Localização

Fatos ([Internationalizing games](https://docs.godotengine.org/en/stable/tutorials/i18n/internationalizing_games.html), [Importing translations](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_translations.html), [TranslationServer](https://docs.godotengine.org/en/stable/classes/class_translationserver.html)):

- Duas abordagens: usar um idioma como chave (geralmente inglês) ou usar IDs únicos. A doc diz que jogos em geral usam IDs.
- Formatos: **CSV** (importador especial; a primeira coluna é a chave e as outras são os idiomas) e **gettext `.po`** ("se precisar de um formato mais poderoso").
- Cadastro: Project Settings > Localização > Translations. Arquivos `.translation` são gerados do CSV e não vão para o Git.
- Em código: `tr("CHAVE")`, `tr_n(singular, plural, n)` para plurais e contexto de tradução. Nós `Label` e outros `Control` traduzem sozinhos o texto que coincide com uma chave (controlado por `Node.auto_translate_mode`).
- `TranslationServer.set_locale("pt_BR")` muda o idioma. A função padroniza o código (por exemplo `en-US` vira `en_US`). O idioma de reserva padrão é `en` (`internationalization/locale/fallback`).
- Placeholders: `tr("...%s...") % valor`; a doc recomenda nomes de placeholder para que o tradutor possa mudar a ordem.
- Existe uma página de pseudo-localização ([pseudolocalization.rst](https://github.com/godotengine/godot-docs/blob/4.7/tutorials/i18n/pseudolocalization.rst)) no repositório 4.7; não li o corpo.

Recomendação: como o Arthur lê tudo em português e o jogo é para jogadores do Brasil e do mundo, escrever as chaves como IDs (`UI_STAMINA_LOW`) desde o começo, mesmo com um idioma só, custa pouco e evita refazer depois.

---

### 4. Acessibilidade

#### 4.1 Leitor de tela (AccessKit)

Fatos:

- **4.5:** "Thanks to AccessKit, we added screen reader support to Control nodes, and we also added screen reader bindings in order to customize the behavior of any type of Node." O texto avisa que a integração é **experimental** ([notas do 4.5](https://godotengine.org/releases/4.5/)).
- **4.7:** "navegação por marcos" (landmark navigation), que dá ao leitor de tela informação de contexto da região da interface ([notas do 4.7](https://godotengine.org/releases/4.7/)).
- **Configuração do projeto** ([ProjectSettings](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html)): `accessibility/general/accessibility_support` com `Auto` (0, padrão: só processa se um leitor estiver ativo), `Always Active` (1) e `Disabled` (2); `accessibility/general/accessibility_driver` = `"accesskit"`; `updates_per_second` = 60. Ferramentas de depuração como Accessibility Insights não contam como leitor de tela; para testá-las use `Always Active`.
- **O que um Control tem:** `accessibility_name`, `accessibility_description`, `accessibility_live` (modo de região ao vivo), `accessibility_labeled_by_nodes`, `accessibility_described_by_nodes`, `accessibility_controls_nodes`, `accessibility_flow_to_nodes`. Existe o modo de foco `FOCUS_ACCESSIBILITY`: o nó só recebe foco quando um leitor de tela está ativo ([Control](https://docs.godotengine.org/en/stable/classes/class_control.html)).
- **Classe de servidor:** `AccessibilityServer` ("A server interface for screen reader support") com `is_supported()` e cerca de 96 papéis (roles) ([classe](https://docs.godotengine.org/en/stable/classes/class_accessibilityserver.html)).
- **Plataformas:** a doc de `DisplayServer` indica o método de detecção de leitor "implementado no Linux, macOS e Windows". Para o suporte em outras plataformas não há afirmação nas páginas que li.

Inferência: os `Control` padrão (Button, Label, Slider, LineEdit) ganham suporte quase de graça. O que o Arthur desenhar à mão (`_draw`) ou em 3D (por exemplo, a mira ou a seta do alvo) não aparece para o leitor sem trabalho extra. Para um jogo de luta em primeira instância, o ganho prático está nos menus (lobby, opções, remapeamento), não na partida. Recomendação: nomear os controles dos menus com `accessibility_name` e tratar leitor de tela no HUD de partida como fora do v0.

#### 4.2 Remapeamento de teclas em tempo de execução

Fatos ([InputMap](https://docs.godotengine.org/en/stable/classes/class_inputmap.html)): a API tem `action_erase_events(action)` ("Removes all events from an action"), `action_add_event(action, event)`, `action_erase_event`, `action_get_events`, `action_has_event`, `load_from_project_settings()` (recarrega o mapa original) e `event_is_action`. Para salvar, `ConfigFile.save("user://...")` e `load()` ([ConfigFile](https://docs.godotengine.org/en/stable/classes/class_configfile.html)). No Windows, `user://` aponta por padrão para `%APPDATA%\Godot\app_userdata\[nome do projeto]` ([data_paths.rst](https://github.com/godotengine/godot-docs/blob/4.7/tutorials/io/data_paths.rst)).

Receita (inferência de montagem): ao confirmar um novo botão, `InputMap.action_erase_events("dash")`, `InputMap.action_add_event("dash", novo_evento)` e gravar o evento no `ConfigFile`; ao iniciar o jogo, ler e reaplicar depois de `load_from_project_settings()`. A API e o armazenamento são fatos; a receita é minha. Para o netfox: o mapa de ações pertence à camada de apresentação e de entrada; o núcleo recebe só a entrada já traduzida em bits por tick (inferência coerente com DEC-0004).

#### 4.3 `physical_keycode` ou `keycode`, e o teclado ABNT2

Fatos ([InputEventKey](https://docs.godotengine.org/en/stable/classes/class_inputeventkey.html)):

- `physical_keycode`: "a posição física de uma tecla no teclado QWERTY US de 101/102 teclas. **Feito para entrada de jogo, como movimento WASD**, onde só importa a posição da tecla."
- `keycode`: o rótulo latino impresso na tecla no layout atual; "feito para atalhos expressos com teclado latino padrão, como Ctrl+S".
- `key_label`: o rótulo localizado impresso na tecla; "feito para exibir dicas de tecla".

Mostrar o nome da tecla ao jogador:

- `OS.get_keycode_string(code)` devolve o texto de um código de tecla ([OS](https://docs.godotengine.org/en/stable/classes/class_os.html)).
- `InputEventKey.as_text_physical_keycode()` e `as_text_keycode()` devolvem o texto do evento.
- `DisplayServer.keyboard_get_label_from_physical(keycode)` "converte um keycode físico (QWERTY US) para o rótulo localizado impresso na tecla no layout ativo". `keyboard_get_keycode_from_physical()` converte para o keycode do layout ativo. Os dois são "implementados no Linux (X11/Wayland), macOS e Windows" ([DisplayServer](https://docs.godotengine.org/en/stable/classes/class_displayserver.html)).

Inferência sobre ABNT2 (layout brasileiro, tem a tecla extra à direita do "Ç" e o `/` e `?` no lugar da tecla `ª`): a tecla que fica no lugar do `;` do US pode ser rotulada `Ç`. Com `physical_keycode`, o jogo guarda a **posição**, então WASD funciona em ABNT2, AZERTY e Dvorak. Para o prompt na tela ("aperte Shift"), converta a posição física para o rótulo do layout ativo com `keyboard_get_label_from_physical`. Recomendação: gravar `physical_keycode` no arquivo de configuração e exibir o rótulo localizado.

#### 4.4 Escala de texto

Fatos: `Window.content_scale_factor` e `display/window/stretch/scale` multiplicam a UI em tempo de execução ("a doc: expor isso aos jogadores para ajudar na acessibilidade"); `ThemeDB.fallback_base_scale` e `fallback_font_size` dão controle do tema padrão. Em temas customizados, mudar tamanhos de fonte de um tema por tipo é o caminho. O tema sobe em cascata: "ajustes para daltônicos podem ser aplicados em um só lugar" ([gui_skinning.rst](https://github.com/godotengine/godot-docs/blob/4.7/tutorials/ui/gui_skinning.rst)).

#### 4.5 Daltonismo: existe filtro embutido?

**Não.** Procurei nas páginas de documentação (`.rst` da branch 4.7: tutoriais de UI, fontes, shaders, ambiente) e nas notas de versão 4.5, 4.6 e 4.7; a única menção a daltonismo é uma frase de passagem sobre temas. Não achei um filtro ou simulador embutido (isso é ausência de evidência, mas bem consistente). O `Environment` tem *Adjustments* (brilho, contraste, saturação, LUT de cor 1D ou 3D), que não simulam daltonismo.

A abordagem usual: um shader de pós-processo que lê a tela (`hint_screen_texture`) e aplica uma matriz de cor. No Compatibility isso é possível, segundo fatos da tabela: "Screen texture: Sim", "Custom post-processing com fullscreen quad: Sim", "CompositorEffects: Não". Dois caminhos:

1. Um `ColorRect` de tela cheia numa `CanvasLayer`, com um shader `canvas_item` e `hint_screen_texture` ([Screen-reading shaders](https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html), que traz um exemplo de brilho, contraste e saturação). Pega a imagem 3D e a UI que estiver abaixo dessa camada.
2. Um quad de tela cheia no 3D ([Advanced post-processing](https://docs.godotengine.org/en/stable/tutorials/shaders/advanced_postprocessing.html)); só afeta o 3D.

Inferência: o caminho 1 serve. O mais importante para o jogo não é o filtro, e sim **nunca depender só de cor** na "leitura" (pilar 1): equipe, golpe que quebra guarda e golpe carregado precisam ter forma, ícone e som diferentes, além da cor. É a mesma lógica da DEC-0014: aviso visual e sonoro.

---

### 5. Áudio

#### 5.1 Nós de reprodução

Fatos ([Audio streams](https://docs.godotengine.org/en/stable/tutorials/audio/audio_streams.html), [AudioStreamPlayer3D](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer3d.html)):

- `AudioStreamPlayer`: sem posição; toca em qualquer bus (música, interface).
- `AudioStreamPlayer3D`: posicional; pan por posição relativa à câmera (estéreo, 5.1 ou 7.1).
- **Atenuação:** `attenuation_model` com `INVERSE_DISTANCE` (padrão, "linear" segundo a descrição), `INVERSE_SQUARE_DISTANCE`, `LOGARITHMIC` e `DISABLED` (continua posicional, sem queda por distância; combinado com `max_distance` maior que 0 dá queda linear até o limite). Padrões: `unit_size = 10.0`, `max_distance = 0.0` (sem limite), `max_db = 3.0`, `panning_strength = 1.0`. Existem também `attenuation_filter_cutoff_hz` (5000) e `attenuation_filter_db` (-24) para o abafamento com a distância, e `emission_angle_*` para sons direcionais.
- **Doppler:** `doppler_tracking` vem **desligado** (`DOPPLER_TRACKING_DISABLED = 0`). Para ligar, escolha Idle (objeto movido em `_process`) ou Physics (`_physics_process`); a Camera3D também precisa do tracking. Recomendação: deixar desligado. A mudança de tom por velocidade de lutadores que dão dash e gancho seria inconsistente com a leitura do golpe, e a velocidade que o Doppler lê vem de nó, não do estado.
- `max_polyphony` padrão **1**: "tocar sons adicionais depois de atingir esse valor corta os sons mais antigos". Um único AudioStreamPlayer3D por lutador tocando passos e golpes cortaria o som anterior. Aumentar o valor ou usar `AudioStreamPolyphonic` evita isso.
- `area_mask`, e `Area3D` com "Reverb Bus" desviam o som para buses de reverb por sala.
- **Web:** efeitos, reverb e Doppler não funcionam se o `playback_type` for *Sample* (padrão na Web); o `playback_type` é experimental.

#### 5.2 Buses e efeitos

Fatos ([Audio buses](https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html)): quantidade de buses e efeitos livre, limitada só pelo hardware; o bus *Master* sai para os alto-falantes; a roteirização sempre vai da direita para a esquerda, o que evita laços. A escala é em decibéis (6 dB dobram ou reduzem pela metade a amplitude; abaixo de -60 a -80 dB não se ouve). Evite que o Master passe de 0 dB (clipping). O layout padrão é `res://default_bus_layout.tres` (`audio/buses/default_bus_layout`). Há efeitos como Compressor, Limiter, HardLimiter, EQ, Reverb, Delay, Distortion e filtros na referência de classes.

Recomendação (projeto): buses `Master`, `SFX`, `Voz/Aviso`, `Musica`, `UI`, para o Arthur dar volumes separados nas opções; e um Limiter no Master. Os nomes são minha sugestão.

#### 5.3 Formatos e importação

Fatos ([Importing audio samples](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_audio_samples.html)):

- Três formatos: **WAV**, **Ogg Vorbis** e **MP3**.
- WAV: leve para tocar (centenas de vozes simultâneas são tranquilas), mas ocupa muito disco. Compressão padrão do WAV é *Quite OK Audio* (QOA); há também *PCM (sem compressão)* e *IMA ADPCM*.
- Ogg Vorbis: arquivo muito menor, mas exige bem mais CPU para tocar. MP3: compressão melhor que WAV comprimido e pior que Ogg; usa menos CPU que Ogg.
- A dica da doc: "Considere WAV para efeitos curtos e repetitivos, e Ogg Vorbis para música, fala e efeitos longos. MP3 é útil em mobile e web com CPU limitada".
- Tabela de tamanho (1 s): WAV 16 bit 44 kHz mono = 88 KB; QOA mono = 17 KB; Ogg 128 kb/s estéreo = 16 KB.
- Opções de WAV: Force > Mono, Force > Max Rate, Edit > Trim (corta silêncio inicial e final abaixo de -50 dB, com fade de 500 amostras; reduz o atraso na hora do disparo), Normalize, Loop Mode (Detect from WAV, Disabled, Forward, Ping-Pong, Backward) com Loop Begin e Loop End em amostras.
- Opções de Ogg e MP3: Loop, Loop Offset (em segundos), BPM, Beat Count, Bar Beats (para música interativa). Ogg e MP3 só têm ponto de início de loop, não de fim.
- Boas práticas da doc: 24 bits e taxa acima de 48 kHz não trazem ganho audível; muitos efeitos podem ser mono.
- Nota: com loop, o sinal `finished` do AudioStreamPlayer não é emitido.

Recomendação (projeto): efeitos de golpe e passo em WAV mono com Trim ligado (o atraso inicial de silêncio some, o que importa para a leitura do golpe), música e ambiente em Ogg. A licença de cada arquivo entra em `assets/CREDITS.md`, como já manda a regra do projeto.

#### 5.4 Latência

Fatos ([ProjectSettings](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html), [AudioServer](https://docs.godotengine.org/en/stable/classes/class_audioserver.html)):

- `audio/driver/output_latency` (padrão **15 ms**): "valores menores resultam em menos latência de áudio, ao custo de mais CPU. Valores baixos podem causar estalos em hardware lento." O sistema operacional pode limitar o valor; use `AudioServer.get_output_latency()` para saber o valor real. Cuidado: "isso pode ser caro, não chame todo quadro". Dá para sobrescrever na linha de comando com `--audio-output-latency <ms>`.
- `audio/driver/mix_rate` (padrão **44100** Hz): "em geral é melhor não mexer e deixar para o sistema operacional".
- `AudioServer` tem `get_time_to_next_mix()` e `get_time_since_last_mix()` para compensar a latência.

Conta de ordem de grandeza (minha): um quadro a 60 fps tem 16,7 ms. O golpe leve tem preparação de 300 ms (18 ticks) e o parry tem janela de 80 ms (cerca de 5 ticks) (`docs/design/combate.md`). Os 15 ms de latência de saída do áudio são do tamanho de um tick. É pouco contra 300 ms, mas é visível na janela de 80 ms. Recomendação: manter os 15 ms de padrão no v0, medir em `AudioServer.get_output_latency()` no hardware do Arthur e decidir depois de ouvir com o fone. **Não medi nada disso**; é inferência de tamanho.

#### 5.5 Variação de som com AudioStreamRandomizer

Fato ([AudioStreamRandomizer](https://docs.godotengine.org/en/stable/classes/class_audiostreamrandomizer.html)): "Wraps a pool of audio streams with pitch and volume shifting." Sorteia um stream do conjunto e aplica deslocamento aleatório de tom (`random_pitch` e `random_pitch_semitones`) e de volume (`random_volume_offset_db`). O `playback_mode` padrão é `PLAYBACK_RANDOM_NO_REPEATS`, que sorteia segundo os pesos mas evita repetir o mesmo som duas vezes seguidas. A página de áudio diz que serve para "variação em sons tocados com frequência". Versão de introdução: não confirmei.

Inferência de arquitetura: o sorteio do randomizer **não** é determinístico, mas som é apresentação (DEC-0004: som só toca em ticks frescos), então a regra de "sem aleatoriedade sem semente" que vale para `core/` não é violada, desde que o resultado do sorteio nunca volte para o estado.

---

### 6. Versões em que cada recurso apareceu (resumo)

| Recurso | Versão | Fonte |
|---|---|---|
| ufbx como importador de FBX padrão | 4.3 | [notas 4.3](https://godotengine.org/releases/4.3/), [available_formats](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html) |
| SkeletonModifier3D e novas opções de retargeting | 4.3 | [notas 4.3](https://godotengine.org/releases/4.3/) |
| Stencil buffer | 4.5 | [notas 4.5](https://godotengine.org/releases/4.5/) |
| Leitor de tela (AccessKit) | 4.5 (experimental) | [notas 4.5](https://godotengine.org/releases/4.5/) |
| Jolt como física padrão para projetos novos | 4.6 | [notas 4.6](https://godotengine.org/releases/4.6/) |
| SSAO simples no Compatibility | 4.6 | [snapshot 4.6 dev 3](https://godotengine.org/article/dev-snapshot-godot-4-6-dev-3/) |
| Glow misturado com Screen por padrão | 4.6 | [notas 4.6](https://godotengine.org/releases/4.6/) |
| HDR output (não no Compatibility) | 4.7 | [notas 4.7](https://godotengine.org/releases/4.7/) |
| Navegação por marcos no leitor de tela | 4.7 | [notas 4.7](https://godotengine.org/releases/4.7/) |
| `offset_transform` em Control | 4.7 | [notas 4.7](https://godotengine.org/releases/4.7/) |

---

### 7. Recomendações para a conversa de design (minhas, não são fatos)

1. **Formato:** glTF binário (`.glb`) como formato padrão de entrada. FBX só quando a fonte do asset não oferecer glTF, e sempre medindo a altura depois da importação.
2. **Estilo visual:** casco invertido para contorno, `DIFFUSE_TOON` ou Unshaded com cor de vértice. Testar o stencil só como experimento.
3. **Antialiasing:** sem FXAA nem TAA no Compatibility; o caminho é MSAA 3D (hoje desligado no projeto) e escolher o nível medindo na RX 550. A medição é do Arthur.
4. **Pós-processo:** brilho, contraste, saturação e LUT estão no `Environment`; filtros de daltonismo por shader de tela cheia funcionam. Normal buffer, DoF, decals e volumetric fog não existem aqui; decida o estilo sem eles.
5. **Interface:** definir a base 1920 x 1080 (decisão dele, mexe no `project.godot`), um Theme de projeto em `gui/theme/custom`, fontes rasterizadas para texto pequeno, e `content_scale_factor` exposto nas opções.
6. **Teclas:** guardar `physical_keycode`; mostrar `keyboard_get_label_from_physical`; salvar em `user://` com `ConfigFile`.
7. **Acessibilidade mínima viável:** nomes de acessibilidade nos menus, informação nunca só por cor, escala de interface ajustável. Leitor de tela na partida fica para depois.
8. **Áudio:** WAV mono com Trim para efeitos, Ogg para música, AudioStreamRandomizer para variação, `max_polyphony` maior que 1 nos lutadores, Doppler desligado, e `output_latency` no padrão até alguém ouvir um problema.
9. **Animação:** AnimationMixer em modo manual (`advance`), root motion fora do jogo, e animações compartilhadas por Animation Library se houver mais de um conjunto.

### 8. Lacunas e limites desta pesquisa

- Não confirmei o comportamento de escala de arquivos Mixamo no 4.7.2.
- Não confirmei que GPUParticles3D funciona no Compatibility por uma frase; é inferência.
- Não medi desempenho nenhum (MSAA, SSAO, sombras, contorno) na RX 550.
- Não verifiquei se o hardware do Arthur permite assar lightmaps no editor (exige RenderingDevice).
- Não abri a especificação glTF para confirmar "metro" como unidade.
- Não li o corpo das páginas de `RetargetModifier3D` nem de pseudo-localização.
- A versão em que `BoneMap`/`SkeletonProfileHumanoid` e `AudioStreamRandomizer` apareceram não foi confirmada.
- A abertura das páginas de `docs.godotengine.org` por ferramenta de resumo (WebFetch) deu resultados incompletos em alguns casos; por isso baixei os `.rst` da branch 4.7 e conferi neles as citações exatas.

## §2 — O resumo e o que não foi confirmado, pelo agente

1. O Compatibility do 4.7.2 não tem FXAA, SMAA, TAA, SSR, decals, volumetric fog, DoF nem HDR output. Tem MSAA 3D (desligado hoje no projeto), glow simplificado, SSAO simples (entrou no 4.6), ReflectionProbe (2 por malha), fog, tonemapping, adjustments e leitura de screen/depth texture. A escolha de antialiasing é MSAA, medido na RX 550.
2. O projeto não define tamanho base de janela: vale o padrão 1152x648. Com canvas_items+expand a UI é ampliada 1,667x em 1080p. A doc recomenda base 1920x1080 para jogo 3D de desktop; mexer no project.godot é decisão da Arthur.
3. glTF 2.0 é o formato recomendado; FBX usa ufbx (padrão desde o 4.3, ufbx 0.21.3 no 4.7.2). O 4.7.2 converte unidade para metro (target_unit_meters = 1.0). O problema do Mixamo 0.01 não está na doc oficial e não foi confirmado; teste medindo se o modelo tem 1,8 m.
4. Lista de hints de importação confirmada: -noimp, -col, -convcol, -colonly, -convcolonly, -occ, -occonly, -navmesh, -vehicle, -wheel, -rigid, -loop/-cycle (sem hífen), -alpha, -vcol. Retargeting por SkeletonProfileHumanoid+BoneMap existe, com limites declarados (Overwrite Axis, Fix Silhouette, nomes de osso em inglês).
5. AnimationMixer tem modo manual (callback_mode_process = 2, advance(delta)), o que combina com a F-007. O root motion existe mas não deve mover o corpo, porque o netfox não sincroniza AnimationTree (issue #553). Isso é inferência de arquitetura.
6. Stencil existe no código do backend OpenGL do 4.7.2, mas a doc o chama de experimental e não o lista na tabela do Compatibility. Contorno seguro: casco invertido.
7. Daltonismo: não há filtro embutido. A abordagem é um shader de tela cheia com hint_screen_texture, que o Compatibility suporta (CompositorEffects não). AccessKit (leitor de tela) é de 4.5, experimental, e cobre Controls; HUD desenhado à mão não ganha suporte de graça.
8. Teclas: guardar physical_keycode (posição, funciona em ABNT2), mostrar o rótulo com DisplayServer.keyboard_get_label_from_physical, remapear com InputMap.action_erase_events/action_add_event e salvar em user:// com ConfigFile.
9. Áudio: WAV para efeitos curtos, Ogg para música, MP3 existe. AudioStreamPlayer3D tem max_polyphony padrão 1 (corta o som anterior), Doppler desligado por padrão, output_latency padrão 15 ms. AudioStreamRandomizer dá variação de tom e volume; é apresentação, não viola a pureza do core.
10. Texturas 3D: Detect 3D liga mipmaps e VRAM Compressed; no Compatibility "High Quality" (BPTC) é ignorado e sai S3TC. Commitar os .import, não a pasta .godot/. Nomes em snake_case por causa do PCK sensível a maiúsculas.

O que o agente não confirmou:

- Comportamento do problema 'Mixamo escala 0.01' no Godot 4.7.2: só achei relatos em buscas e issues da comunidade, sem fonte oficial nem teste.
- Que 1 unidade = 1 metro no glTF: a doc do Godot só linka a especificação glTF 2.0, que não abri.
- GPUParticles3D e CPUParticles3D no Compatibility: a tabela de renderers não lista; a conclusão de que funcionam (sem trails nem emit_particle) é inferência.
- Stencil no Compatibility: existe código no backend OpenGL do 4.7.2, mas a doc não o lista na tabela e o recurso é experimental.
- Se o hardware da Arthur (RX 550) permite assar lightmaps no editor (exige RenderingDevice).
- Versão em que BoneMap e SkeletonProfileHumanoid apareceram (inferi 4.0) e versão em que AudioStreamRandomizer apareceu.
- Corpo da página de RetargetModifier3D e da página de pseudo-localização: não li.
- Cobertura do AccessKit em plataformas além de Windows, macOS e Linux, e para HUD desenhado à mão ou em 3D.
- Qualquer desempenho (MSAA, SSAO, sombras, contornos, latência de áudio) na RX 550: nada foi medido.
- Sugestão de Blender 'Apply Scalings = FBX Units Scale' para exportar FBX: veio só de resumo de busca, não abri a fonte.

## §3 — As afirmações marcadas como importantes e o veredicto do verificador

- **godot:C1** — O Godot 4.7 lista glTF 2.0 como formato de cena 3D recomendado (texto .gltf e binário .glb); .blend chama o Blender para exportar glTF; DAE e OBJ são suportados com limitações.
  - Veredicto: **CONFIRMED**. Lido no .rst do branch 4.7 (raw). A limitação citada para DAE é sobre o exportador COLLADA do Blender ('does not work properly for the needs of game engines'); o doc diz apenas que DAE é 'an older format that is supported'.
  - Lido em: https://raw.githubusercontent.com/godotengine/godot-docs/4.7/tutorials/assets_pipeline/importing_3d_scenes/available_formats.rst
  - Trecho: "glTF 2.0 **(recommended)**. Godot has support for both text (``.gltf``) and binary (``.glb``) formats. [...] ``.blend`` (Blender). This works by calling Blender to export to glTF in a transparent manner (requires Blender to be installed). [...] DAE (COLLADA), an older format that is supported. [...] OBJ (Wavefront) format + their MTL material files. This is also supported, but pretty limited given the format's limitations"
- **godot:C2** — FBX é importado pela biblioteca ufbx, padrão para arquivos FBX adicionados no Godot 4.3 ou posterior; o 4.7.2 embute ufbx 0.21.3 (MIT). FBX2glTF é o fluxo antigo e não recomendado.
  - Veredicto: **CONFIRMED**. Doc 4.7 confirma ufbx como padrão desde 4.3 e FBX2glTF 'generally not recommend'; thirdparty/README.md da tag 4.7.2-stable diz '## ufbx ... Version: 0.21.3 ... License: MIT'.
  - Lido em: https://raw.githubusercontent.com/godotengine/godot-docs/4.7/tutorials/assets_pipeline/importing_3d_scenes/available_formats.rst
  - Trecho: "By default any FBX file added to a Godot project in Godot 4.3 or later will use the ufbx import method. [...] If you want to setup the FBX2glTF workflow, which is generally not recommend unless you have a specific reason to use it"
- **godot:C3** — Lista de dicas de importação por sufixo de nome: -noimp, -col, -convcol, -colonly, -convcolonly, -occ, -occonly, -navmesh, -vehicle, -wheel, -rigid, -loop/-cycle (sem hífen), -alpha, -vcol; funcionam com -, $ ou _ e não diferenciam maiúsculas.
  - Veredicto: **CONFIRMED**. Títulos das seções no .rst 4.7: (-noimp), (-col, -convcol, -colonly, -convcolonly), (-occ, -occonly), (-navmesh), (-vehicle), (-wheel), (-rigid), (-loop, -cycle), (-alpha), (-vcol); loop/cycle sem hífen confirmado.
  - Lido em: https://raw.githubusercontent.com/godotengine/godot-docs/4.7/tutorials/assets_pipeline/importing_3d_scenes/node_type_customization.rst
  - Trecho: "All the suffixes described below can be used with ``-``, ``$``, and ``_`` and are **case-insensitive**. [...] Animation clips in the source 3D file that start or end with the token ``loop`` or ``cycle`` will be imported as a Godot Animation with the loop flag set. **Unlike the other suffixes described above, this does not require a hyphen.**"
- **godot:C4** — Retargeting: no Advanced Import, o Skeleton3D tem a propriedade bone_map; cria-se um BoneMap com SkeletonProfile e o preset SkeletonProfileHumanoid faz mapeamento automático por nomes. Overwrite Axis e Fix Silhouette têm limites declarados.
  - Veredicto: **CONFIRMED**. Propriedade bone_map, BoneMap + SkeletonProfile, preset SkeletonProfileHumanoid com auto-mapping por nomes, e limites de Overwrite Axis ('can produce horrible results if the original Bone Rest set externally is important') e Fix Silhouette ('cannot fix silhouettes which are too different, and it may not work for fixing bone roll').
  - Lido em: https://raw.githubusercontent.com/godotengine/godot-docs/4.7/tutorials/assets_pipeline/retargeting_3d_skeletons.rst
  - Trecho: "The Retarget section has a single property ``bone_map``. [...] first set up a new BoneMap and SkeletonProfile. Godot has a preset called SkeletonProfileHumanoid for humanoid models. [...] When you use SkeletonProfileHumanoid, auto-mapping will be performed when the SkeletonProfile is set. [...] The auto-mapping uses pattern matching for the bone names."
- **godot:C5** — Tabela de recursos do renderer Compatibility (4.7): MSAA 3D sim; FXAA, SMAA, TAA e FSR2 não; glow sim; SSAO sim (Mobile não); SSR, SDFGI, VoxelGI, volumetric fog e decals não.
  - Veredicto: **CONFIRMED**. Todas as linhas da tabela (colunas Compatibility | Mobile | Forward+) conferem: MSAA 3D sim; FXAA, SMAA, TAA, FSR2 não no Compatibility; Glow sim; SSAO sim (Mobile não); SSR, SDFGI, VoxelGI, Volumetric fog e Decals não.
  - Lido em: https://raw.githubusercontent.com/godotengine/godot-docs/4.7/tutorials/rendering/renderers.rst
  - Trecho: "| MSAA 3D | ✔️ Supported. | ✔️ Supported. | ✔️ Supported. | [...] | FXAA | ❌ Not supported. | ✔️ Supported. | ✔️ Supported. | [...] | SSAO | ✔️ Supported. | ❌ Not supported. | ✔️ Supported. | [...] | Decals | ❌ Not supported. | ✔️ Supported. | ✔️ Supported. |"
- **godot:C6** — No Compatibility, ReflectionProbe é suportado com 2 por malha; LightmapGI renderiza lightmaps assados, mas assar exige hardware com RenderingDevice; luzes: 8 omni e 8 spot por malha.
  - Veredicto: **CONFIRMED**. Linhas da tabela no .rst 4.7 conferem para ReflectionProbe, LightmapGI, OmniLights e SpotLights no Compatibility.
  - Lido em: https://raw.githubusercontent.com/godotengine/godot-docs/4.7/tutorials/rendering/renderers.rst
  - Trecho: "| ReflectionProbe | ✔️ Supported, 2 per mesh. | [...] | LightmapGI | ⚠️ Rendering of baked lightmaps is supported. Baking requires hardware with RenderingDevice support. | [...] | Maximum OmniLights | 8 per mesh. Can be increased. | [...] | Maximum SpotLights | 8 per mesh. Can be increased. |"
- **godot:C7** — No Compatibility, screen texture e depth texture são suportadas; normal/roughness buffer, compute shaders e CompositorEffects não; custom post-processing com fullscreen quad sim; HDR output (novo no 4.7) não é suportado no Compatibility.
  - Veredicto: **CONFIRMED**. Linhas conferem no .rst 4.7; a linha 'HDR output' não existe nos .rst dos branches 4.6 e 4.5, e a página de lançamento do 4.7 diz 'HDR output has been made possible for Windows, macOS, iOS, visionOS, and Linux (Wayland) in Godot 4.7'.
  - Lido em: https://raw.githubusercontent.com/godotengine/godot-docs/4.7/tutorials/rendering/renderers.rst
  - Trecho: "| Screen texture | ✔️ Supported. | [...] | Depth texture | ✔️ Supported. | [...] | Normal/Roughness buffer | ❌ Not supported. | [...] | Compute shaders | ❌ Not supported. | [...] | Custom post-processing with CompositorEffects | ❌ Not supported. | [...] | Custom post-processing with fullscreen quad | ✔️ Supported. | [...] | HDR output | ❌ Not supported. | ✔️ Supported. | ✔️ Supported. |"
- **godot:C8** — O suporte a leitor de tela via AccessKit foi adicionado no Godot 4.5, em estado experimental, para nós Control e com bindings para qualquer Node.
  - Veredicto: **CONFIRMED**. Página oficial de lançamento do Godot 4.5, seção 'Screen reader support'.
  - Lido em: https://godotengine.org/releases/4.5/
  - Trecho: "Thanks to AccessKit, we added screen reader support to Control nodes, and we also added screen reader bindings in order to customize the behavior of any type of Node. As this feature is quite new, please note that its integration is still in its experimental phase."
- **godot:C9** — API de remapeamento do InputMap: action_erase_events remove todos os eventos de uma ação; action_add_event adiciona um InputEvent; load_from_project_settings recarrega o mapa original. ConfigFile.save/load gravam em user://.
  - Veredicto: **CONFIRMED**. Doc stable (4.7) da classe InputMap; ConfigFile mostra o exemplo config.save("user://scores.cfg") e config.load("user://scores.cfg").
  - Lido em: https://docs.godotengine.org/en/stable/classes/class_inputmap.html
  - Trecho: "action_erase_events: Removes all events from an action. / action_add_event: Adds an InputEvent to an action. This InputEvent will trigger the action. / load_from_project_settings: Clears all InputEventAction in the InputMap and load it anew from ProjectSettings."
- **godot:C10** — O Godot importa áudio em três formatos (WAV, Ogg Vorbis, MP3); a doc recomenda WAV para efeitos curtos e repetitivos e Ogg Vorbis para música, fala e efeitos longos.
  - Veredicto: **CONFIRMED**. Doc 4.7 de importação de áudio (IMA ADPCM e QOA aparecem só como compressões dentro de WAV).
  - Lido em: https://raw.githubusercontent.com/godotengine/godot-docs/4.7/tutorials/assets_pipeline/importing_audio_samples.rst
  - Trecho: "Godot provides 3 options to import your audio data: WAV, Ogg Vorbis and MP3. [...] Consider using WAV for short and repetitive sound effects, and Ogg Vorbis for music, speech, and long sound effects."
- **godot:C11** — SSAO foi implementado de forma simples para o GLES3 (renderer Compatibility) no ciclo do Godot 4.6; a classe Environment diz que SSAO só é suportado em Forward+ e Compatibility.
  - Veredicto: **CONFIRMED**. Artigo oficial do snapshot 4.6 dev 3 (2025-11-04) lista o PR; a doc stable (4.7) de Environment diz: 'SSAO is only supported in the Forward+ and Compatibility rendering methods, not Mobile.'
  - Lido em: https://godotengine.org/article/dev-snapshot-godot-4-6-dev-3/
  - Trecho: "Rendering: Implement a very simple SSAO in GLES3 (GH-109447)."
- **godot:C12** — O buffer de stencil foi a novidade de renderização do Godot 4.5; a doc de shaders o chama de experimental, e o código do backend OpenGL (Compatibility) do 4.7.2 contém suporte a stencil, embora a tabela de recursos não o liste.
  - Veredicto: **CONFIRMED**. 'Stencil buffer support' é o primeiro item dos Highlights do 4.5 (o 'Shader baker' também é highlight ligado a renderização); spatial_shader.rst 4.7: 'Stencil support is experimental, use at your own risk.'; renderers.rst 4.7 não contém a palavra 'stencil'; drivers/gles3/rasterizer_scene_gles3.cpp da tag 4.7.2-stable tem código de stencil (ex.: 'if (p_material->shader_data->stencil_enabled)').
  - Lido em: https://godotengine.org/releases/4.5/
  - Trecho: "Stencil buffer support [...] A stencil buffer is a special buffer that meshes can write to for later comparison."

## §4 — As demais afirmações, com o link

- godot:C2b — A thirdparty do Godot 4.7.2-stable traz ufbx versão 0.21.3, licença MIT. — https://github.com/godotengine/godot/blob/4.7.2-stable/thirdparty/README.md
- godot:C13 — Stencil é experimental e só pode ser lido no passe transparente. — https://github.com/godotengine/godot-docs/blob/4.7/tutorials/shaders/shader_reference/spatial_shader.rst
- godot:C14 — O importador de FBX do 4.7.2 configura o ufbx com target_unit_meters = 1.0, eixos Y-up de mão direita e space_conversion MODIFY_GEOMETRY. — https://github.com/godotengine/godot/blob/4.7.2-stable/modules/fbx/fbx_document.cpp
- godot:C15 — AnimationMixer tem modo manual de processamento e o método advance(delta); root_motion_track cancela visualmente a trilha escolhida e get_root_motion_position() devolve o deslocamento. — https://docs.godotengine.org/en/stable/classes/class_animationmixer.html
- godot:C16 — Importar cria um arquivo .import ao lado do original, que deve ser commitado; a pasta .godot/ não é recomendada no controle de versão. — https://github.com/godotengine/godot-docs/blob/4.7/tutorials/assets_pipeline/import_process.rst
- godot:C17 — O PCK do Godot é sensível a maiúsculas e minúsculas; a doc recomenda snake_case e minúsculas em todos os arquivos. — https://github.com/godotengine/godot-docs/blob/4.7/tutorials/best_practices/project_organization.rst
- godot:C18 — Detect 3D liga mipmaps e muda a compressão para VRAM Compressed em texturas usadas em 3D; a opção High Quality (BPTC) é sempre considerada desativada no Compatibility; sem ela, desktop usa S3TC. — https://github.com/godotengine/godot-docs/blob/4.7/tutorials/assets_pipeline/importing_images.rst
- godot:C19 — O projeto atual não define tamanho de viewport; o padrão é 1152x648. A doc recomenda base 1920x1080, canvas_items e expand para jogo 3D de desktop. — https://docs.godotengine.org/en/stable/classes/class_projectsettings.html
- godot:C20 — Stretch canvas_items: o 3D não é afetado e o 2D é renderizado diretamente na resolução alvo; expand mantém a proporção sem segurar largura nem altura. — https://github.com/godotengine/godot-docs/blob/4.7/tutorials/rendering/multiple_resolutions.rst
- godot:C21 — Theme é um recurso que estiliza Controls e Windows em cascata; o tema do projeto é definido em gui/theme/custom e a busca de itens segue override local, temas dos ancestrais, tema do projeto, tema padrão. — https://github.com/godotengine/godot-docs/blob/4.7/tutorials/ui/gui_skinning.rst
- godot:C22 — Renderização de fonte MSDF: fica nítida em qualquer tamanho, mas tem custo base maior, não suporta subpixel LCD e fontes com contornos auto-intersectantes saem erradas. — https://github.com/godotengine/godot-docs/blob/4.7/tutorials/ui/gui_using_fonts.rst
- godot:C23 — Não há filtro de daltonismo embutido na documentação do 4.7; a menção encontrada é só uma frase sobre ajustes de tema para daltônicos. O Compatibility suporta post-processing por fullscreen quad e screen texture. — https://github.com/godotengine/godot-docs/blob/4.7/tutorials/ui/gui_skinning.rst
- godot:C24 — Configuração accessibility/general/accessibility_support: Auto (padrão), Always Active e Disabled; ferramentas de depuração de acessibilidade exigem Always Active. — https://docs.godotengine.org/en/stable/classes/class_projectsettings.html
- godot:C25 — O Godot 4.7 adicionou navegação por marcos (landmark) para o leitor de tela, além de HDR output e offset_transform em Control. — https://godotengine.org/releases/4.7/
- godot:C26 — InputEventKey.physical_keycode é feito para entrada de jogo (posição na QWERTY US); keycode é para atalhos; key_label é para exibir dicas de tecla. — https://docs.godotengine.org/en/stable/classes/class_inputeventkey.html
- godot:C27 — DisplayServer.keyboard_get_label_from_physical converte um keycode físico (QWERTY US) para o rótulo localizado impresso na tecla no layout ativo; implementado em Linux, macOS e Windows. — https://docs.godotengine.org/en/stable/classes/class_displayserver.html
- godot:C28 — AudioStreamPlayer3D: attenuation_model padrão INVERSE_DISTANCE, unit_size 10.0, max_distance 0.0, doppler desligado por padrão, max_polyphony padrão 1 (sons adicionais cortam os mais antigos). — https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer3d.html
- godot:C29 — audio/driver/output_latency tem padrão de 15 ms; valores baixos aumentam o uso de CPU e podem estalar em hardware lento; mix_rate padrão 44100 Hz. — https://docs.godotengine.org/en/stable/classes/class_projectsettings.html
- godot:C30 — AudioStreamRandomizer escolhe um stream de um conjunto e aplica variação aleatória de tom e volume; o modo padrão evita repetir o mesmo som em sequência. — https://docs.godotengine.org/en/stable/classes/class_audiostreamrandomizer.html
- godot:C31 — A localização aceita CSV e gettext .po; jogos em geral usam IDs únicos como chave; tr() e TranslationServer.set_locale() são a API. — https://github.com/godotengine/godot-docs/blob/4.7/tutorials/assets_pipeline/importing_translations.rst
- godot:C32 — O Godot 4.7.2 é uma versão de manutenção de 18/08/2026, sem recursos novos. — https://godotengine.org/article/maintenance-release-godot-4-7-2/
- godot:C33 — O netfox tem uma issue aberta/investigação para sincronizar AnimationTree, o que mostra que hoje ela não é sincronizada. — https://github.com/foxssake/netfox/issues/553
- godot:C34 — No Compatibility o glow usa implementação simplificada e sempre o modo Screen; propriedades como glow_levels, glow_strength e glow_mix ficam indisponíveis. — https://docs.godotengine.org/en/stable/classes/class_environment.html
