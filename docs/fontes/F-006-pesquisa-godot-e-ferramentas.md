---
id: F-006
titulo: Pesquisa: Godot 4.7.2 e ferramentas para um jogo 3D online (02/10/2026)
recebido_em: 2026-10-02
como: Relatório final de um agente de pesquisa do Claude Code (general-purpose), pedido na sessão do my-brain de 02/10/2026. Texto como chegou, com o link da fonte ao lado de cada afirmação.
status: vigente
substituida_por:
---

# Godot 4.7.2 para um jogo 3D online: pesquisa em 02/10/2026

## 1. Modelo mental, com analogias de web
- **Node** é a unidade que tem comportamento, como um componente ou elemento do DOM. **Scene** é uma árvore de nodes salva em `.tscn`, que pode ser reutilizada e instanciada, como um arquivo de componente React ([nodes/scenes](https://docs.godotengine.org/en/stable/getting_started/step_by_step/nodes_and_scenes.html), [instancing](https://docs.godotengine.org/en/stable/getting_started/step_by_step/instancing.html)). **Scene tree** é a árvore viva em runtime, controlada pelo `SceneTree`, como o DOM montado ([docs](https://docs.godotengine.org/en/stable/tutorials/scripting/scene_tree.html)).
- **Signals** funcionam como observer ou EventEmitter. A doc diz que eles servem para *responder* a um comportamento, não para iniciá-lo. É o padrão "props down, events up" ([signals](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html), [scene organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html)).
- **Resources (`.tres`)** são contêineres de dados. **Pegadinha:** o engine carrega cada resource uma vez só e todos recebem a mesma cópia. Alterar um afeta todos, como um cache de módulo ES ([docs](https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html)).
- **Autoload** é um node que entra no root antes de qualquer cena e fica sempre carregado, como um service global ([docs](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html)).
- **Groups** são tags. Dá para listar os membros ou chamar um método em todos, como classe CSS mais `querySelectorAll` ([docs](https://docs.godotengine.org/en/stable/tutorials/scripting/groups.html)).
- **Os dois loops:**
  - `_process` roda a cada frame, com delta variável, como `requestAnimationFrame`.
  - `_physics_process` roda em passo fixo: **60 por segundo** por padrão e no máximo 8 passos por frame.
  - Para jogos em rede, a doc recomenda `physics_jitter_fix ≤ 0` ([idle/physics](https://docs.godotengine.org/en/stable/tutorials/scripting/idle_and_physics_processing.html), [ProjectSettings](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html)).
  - Com netfox, a lógica das entidades em rede vai em `_rollback_tick`, que é um tick de rede próprio e pode ser preso à física com `sync_to_physics` ([tutorial](https://foxssake.github.io/netfox/latest/netfox/tutorials/responsive-player-movement/), [NetworkTime](https://foxssake.github.io/netfox/latest/netfox/guides/network-time/)).
- **Input Map** define ações com nome (`jump`) ligadas a teclas e botões. O código pergunta pela ação, não pela tecla ([docs](https://docs.godotengine.org/en/stable/tutorials/inputs/input_examples.html)).
- **Game loop versus request/response:** não existe request. O estado fica em memória e é simulado sem parar ("Games run in a loop"). Travar a main thread derruba frames, como bloquear o event loop do Node ([docs](https://docs.godotengine.org/en/stable/tutorials/scripting/idle_and_physics_processing.html)).

## 2. Tipagem estática no GDScript 4.7
- **Sintaxe básica:** `var hp: int`, inferência com `:=` e retorno com `-> void`.
- **Coleções tipadas:** `Array[T]` e, desde a **4.4**, `Dictionary[K, V]`. Coleções tipadas aninhadas não existem, e métodos como `push_back` continuam untyped ([static typing](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html), [4.4](https://godotengine.org/releases/4.4/)).
- **`@abstract`** (em classes e métodos) e **funções variadic** (`func f(...args: Array)`) chegaram na **4.5** ([4.5](https://godotengine.org/releases/4.5/)).
- **Traits e interfaces não existem.** O autor fechou o PR #107227 sem merge em 08/07/2026 ([PR](https://github.com/godotengine/godot/pull/107227)). As alternativas são classe abstrata, composição com nodes filhos e duck typing.
- **Breaking change da 4.7:** um override de método com retorno tipado agora herda o tipo e exige `return` explícito ([migração 4.7](https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html)).
- **Como forçar tipagem:** as settings ficam em `debug/gdscript/warnings/*`, com 0 = Ignore, 1 = Warn e 2 = Error.
  - As relevantes são `untyped_declaration`, `inferred_declaration`, `unsafe_property_access`, `unsafe_method_access`, `unsafe_cast` e `unsafe_call_argument`. Todas vêm em 0.
  - A doc diz que deixar `inferred_declaration` num nível acima de `untyped_declaration` "makes little sense".
  - A doc também avisa que os warnings UNSAFE_* não pegam todos os casos que as "unsafe lines" do editor pegam.
  - `directory_rules` (desde a 4.6) exclui `res://addons` dos warnings por padrão ([ProjectSettings](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html), [PR #93889](https://github.com/godotengine/godot/pull/93889)).
- **O que a tipagem compra:**
  - Erros aparecem antes de rodar.
  - Autocomplete completo e "safe lines" no editor.
  - Performance, porque o engine usa opcodes otimizados quando conhece os tipos ([docs](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html)).
  - Nos benchmarks sintéticos oficiais da época da 4.0 (debug build), operações ficaram 25–50% mais rápidas e chamadas a classes nativas até 120–150% ([blog](https://godotengine.org/article/gdscript-progress-report-typed-instructions/)).
- **Pegadinhas:**
  - `as` vira `null` em silêncio quando o tipo não bate; melhor usar `is` com `assert`.
  - O guia da GDQuest recomenda inferir com `:=`, o que bate de frente com `inferred_declaration=Error` ([GDQuest](https://gdquest.gitbook.io/gdquests-guidelines/godot-gdscript-guidelines)).

## 3. O que mudou na 4.5, 4.6 e 4.7
**Datas:** 4.5 em 15/09/2025, 4.6 em 26/01/2026, 4.7 em 18/06/2026, 4.7.1 em 14/07/2026 e 4.7.2 em 18/08/2026. A 4.7.2 tem 57 fixes e nenhuma incompatibilidade conhecida. A 4.8 está em dev7 ([archive](https://godotengine.org/download/archive/), [4.7.2](https://godotengine.org/article/maintenance-release-godot-4-7-2/)).
- **4.5** ([4.5](https://godotengine.org/releases/4.5/), [editor externo](https://docs.godotengine.org/en/stable/tutorials/editor/external_editor.html)):
  - abstract, variadic e script backtracing;
  - shader baker e stencil buffer;
  - physics interpolation 3D passou a viver no SceneTree;
  - export para Windows sem rcedit;
  - Exec Flags do editor externo detectados automaticamente.
- **4.6** ([4.6](https://godotengine.org/releases/4.6/), [dev2](https://godotengine.org/article/dev-snapshot-godot-4-6-dev-2/), [dev3](https://godotengine.org/article/dev-snapshot-godot-4-6-dev-3/), [TSCN](https://docs.godotengine.org/en/stable/engine_details/file_formats/tscn.html)):
  - **Jolt virou o default em projetos 3D novos**;
  - cada node do `.tscn` ganhou um `unique_id`, e o header perdeu `load_steps`;
  - Step Out no debugger;
  - warning opcional para coroutine chamada sem `await`;
  - `directory_rules`;
  - profilers Tracy e Perfetto;
  - LibGodot;
  - **SSAO simples no renderer Compatibility (GLES3)**.
- **4.7** ([4.7](https://godotengine.org/releases/4.7/), [migração](https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html)):
  - HDR output, AreaLight3D e Asset Store;
  - export templates baixados por plataforma;
  - device IDs de teclado e mouse (breaking);
  - no Jolt, `WorldBoundaryShape3D` passou a ler o sinal da distância do plano ao contrário.
  - Nas notas, nenhuma sintaxe nova de GDScript e nenhuma melhoria no Compatibility além de correções.
- **Pegadinha que conferi no código da 4.7.2:**
  - O default do engine para `physics/3d/physics_engine` continua `DEFAULT`, que equivale a GodotPhysics3D.
  - Quem grava `"Jolt Physics"` no projeto é o Project Manager, na hora de criá-lo. Ele também grava o stretch `canvas_items`/`expand` e o driver `d3d12` no Windows.
  - Se o Claude Code escrever o `project.godot` à mão, precisa setar o Jolt explicitamente ([editor_node.cpp](https://github.com/godotengine/godot/blob/4.7.2-stable/editor/editor_node.cpp), [Jolt](https://docs.godotengine.org/en/stable/tutorials/physics/using_jolt_physics.html)).
- **Arquivos `.uid`** existem desde a 4.4, para scripts e shaders ([UID](https://godotengine.org/article/uid-changes-coming-to-godot-4-4/)).
- **Formatter embutido não existe;** o PR #76211 continua em draft ([PR](https://github.com/godotengine/godot/pull/76211)).
- **Compatibility:** cobre 2D e o núcleo do 3D, sem features avançadas. Trocar depois para Forward+ ou Mobile dá mais trabalho de ajuste do que trocar entre Mobile e Forward+ ([renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)).

## 4. Testes
- **GUT** ([README](https://github.com/bitwes/Gut), [9.7.0](https://github.com/bitwes/Gut/releases/tag/v9.7.0), [CLI](https://gut.readthedocs.io/en/latest/Command-Line.html)):
  - A versão para a 4.7 é a 9.7.1 (10/07/2026), no branch `godot_4_7`. O `main` é para a 4.6.
  - A 9.7.0 quebrou os doubles por causa da checagem de retorno mais rígida da 4.7.
  - Tem CLI (`gut_cmdln.gd -gexit`) e export JUnit.
- **gdUnit4** ([README](https://github.com/godot-gdunit-labs/gdUnit4), [CLI](https://godot-gdunit-labs.github.io/gdUnit4/latest/advanced_testing/cmd/), [action](https://github.com/godot-gdunit-labs/gdUnit4-action)):
  - A 6.2.1 (20/08/2026) suporta da 4.5 à 4.7.1. A 4.7.2 não aparece na lista.
  - Tem Scene Runner com simulação de input, mocks, fuzzing, retry de testes flaky, relatório HTML e JUnit, e uma GitHub Action própria.
- **Qual é mais ativo:** o gdUnit4 teve 6 releases em 2026, contra 4 do GUT. Os dois estão vivos. O gdUnit4 é mais forte para testar cenas e input; o GUT é mais simples.
- **Checar scripts sem rodar:** `godot --headless --check-only --script res://x.gd`, um script por vez.
  - Num clone limpo, rode `--import` antes. Sem isso, o cache de `class_name` pode não existir ([CLI](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html), [#75684](https://github.com/godotengine/godot/issues/75684)).
  - A doc do GUT traz um script que carrega todos os `.gd` e lista os warnings ([GUT](https://gut.readthedocs.io/en/latest/GDScript-Warnings.html)).

## 5. Lint e format
- **gdtoolkit** (gdformat e gdlint): a 4.5.0, de 09/10/2025, suporta `@abstract` e variadic. Não há commits desde então. Compatibilidade com a 4.7 **não confirmada**, embora a sintaxe não tenha mudado ([changelog](https://github.com/Scony/godot-gdscript-toolkit/blob/master/CHANGELOG.md)).
- **GDQuest GDScript Formatter:** escrito em Rust com tree-sitter, faz formatação e lint. Tem `--check` para CI, lê `.editorconfig` e vem com addon para o editor. A 0.27.0 saiu em 25/09/2026; é a opção mais ativa ([repo](https://github.com/GDQuest/GDScript-formatter)).
- A extensão godot-tools do VS Code também formata. Formatter oficial não existe.

## 6. CI
- **`chickensoft-games/setup-godot@v2`:** instala o Godot 4.x, com export templates opcionais e cache ([README](https://github.com/chickensoft-games/setup-godot)).
- **Docker `barichello/godot-ci:4.7.2`** ([tags](https://hub.docker.com/r/barichello/godot-ci/tags)).
- **`gdUnit4-action`** para rodar os testes.
- **Fluxo:** `--headless --import`, depois os testes, depois `--headless --export-release "<preset>" <path>`.

## 7. Dedicated server
- **Sem binário especial** desde a 4.0: usa-se o export template com `--headless` ([docs](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_dedicated_servers.html)).
- **Export Mode "Export as dedicated server"** adiciona a feature tag `dedicated_server`, que força headless. Ele também deixa escolher, por recurso, entre Strip Visuals, Keep e Remove.
- **Como o código detecta o servidor:** `OS.has_feature("dedicated_server")` ou `DisplayServer.get_name() == "headless"`.
- **Logs:** ative `application/run/flush_stdout_on_print`.
- **Docker:** a doc só cita como opção, e não achei imagem oficial. Minha sugestão, que não é oficial: imagem Linux slim com o binário e o `.pck`, rodando `--headless` e expondo a porta UDP do ENet.
- **Tamanho dos export templates:** o `.tpz` da 4.7.2 tem **1,28 GB** com todas as plataformas ([release](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable)). A 4.7 permite baixar só uma plataforma.
- **Maiúsculas e minúsculas:** o PCK diferencia, o Windows não. Use snake_case minúsculo ([docs](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html)).

## 8. Versionamento
- **`.gitignore` gerado pelo Godot:** `.godot/` e `/android/`. O `.gitattributes` gerado normaliza EOL para LF ([source](https://github.com/godotengine/godot/blob/4.7.2-stable/editor/version_control/editor_vcs_interface.cpp)).
- **O que commitar:**
  - os `.uid`;
  - os `.import` ([docs](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/import_process.html));
  - o `export_presets.cfg`. Desde a 4.1 as credenciais ficam em `.godot/export_credentials.cfg` ([docs](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html)).
- **Conflitos em `.tscn`:** costumam vir dos ids de `ext_resource` e da reordenação quando o editor re-salva. A 4.6 removeu `load_steps`, o que diminui conflitos no header ([TSCN](https://docs.godotengine.org/en/stable/engine_details/file_formats/tscn.html), [VCS](https://docs.godotengine.org/en/stable/tutorials/best_practices/version_control_systems.html)).

## 9. Editor, IDE e feedback para o agente
- **VS Code como editor externo:** Exec Flags `{project} --goto {file}:{line}:{col}`; no Windows, aponte para `code.cmd` ([docs](https://docs.godotengine.org/en/stable/tutorials/editor/external_editor.html)).
- **godot-tools 2.7.1:** LSP (porta 6005 no editor, com modo headless) e debugger DAP (porta 6006) ([README](https://github.com/godotengine/godot-vscode-plugin), [source](https://github.com/godotengine/godot/blob/4.7.2-stable/editor/settings/editor_settings.cpp)).
- **Debugger nativo** ([docs](https://docs.godotengine.org/en/stable/tutorials/scripting/debug/overview_of_debugging_tools.html)):
  - breakpoints e profiler;
  - aba **Remote** no Scene dock, que inspeciona a árvore viva;
  - **Customize Run Instances**, que roda várias instâncias com argumentos próprios (um server e vários clientes).
- **O que o agente usa no terminal:**
  - `--import` e `--check-only`;
  - a CLI do framework de testes;
  - `--scene <path> --quit-after N` para rodar uma cena e sair;
  - `-d` para o debugger no stdout, e `--log-file`.
  - O log padrão fica em `user://logs/godot.log`.
  - Screenshot exige janela, porque o modo headless não renderiza ([CLI](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)).

## 10. MCP e IA
- **Coding-Solo/godot-mcp:** ~5,9k estrelas. Abre o editor, roda o projeto e captura stdout e erros. Não tira screenshot. Último commit em 16/04/2026 ([repo](https://github.com/Coding-Solo/godot-mcp)).
- **godot-mcp-runtime:** ativo em setembro de 2026. Injeta um autoload que dá screenshots, simulação de input e execução de GDScript ao vivo ([repo](https://github.com/Erodenn/godot-mcp-runtime)).
- **GDAI MCP:** pago, US$19 em pagamento único. Tira screenshots e lê os erros ([site](https://gdaimcp.com)).
- **MCP oficial:** não encontrei. A política de 30/06/2026 trata de contribuições de IA ao engine, não do uso por quem faz jogos ([artigo](https://godotengine.org/article/contribution-policy-2026/)).
- **Riscos:** execução arbitrária de código, alteração de `.tscn` e projetos com um mantenedor só. Melhor usar como opcional, por cima de um loop via CLI.

## 11. Addons
- **LimboAI 1.8.1:** behavior trees e state machines hierárquicas. GDExtension para 4.6+ e módulo para a 4.7.2 ([repo](https://github.com/limbonaut/limboai)).
- **Phantom Camera 0.11.0.3:** câmera inspirada no Cinemachine. Corrigiu um bug que surgiu na 4.7.1 ([release](https://github.com/ramokz/phantom-camera/releases/tag/v0.11.0.3)).
- **GodotSteam 4.22.1:** Steamworks 1.65, com build para a 4.7.2. O projeto migrou para o Codeberg ([releases](https://codeberg.org/godotsteam/godotsteam/releases)).
- **Jolt:** já vem embutido. O addon antigo está em maintenance mode e não garante determinismo. Para o módulo embutido, **não confirmado** ([README](https://github.com/godot-jolt/godot-jolt)).
- **Godot State Charts 0.22.5:** state charts montados com nodes. Suporte à 4.7 **não confirmado** ([repo](https://github.com/derkork/godot-statecharts)).
- **netfox:**
  - O último release formal é o v1.35.3, mas o `main` está na 1.49.x. Suporte à 4.7 **não confirmado** ([repo](https://github.com/foxssake/netfox)).
  - Para o estado do player em rollback, use o `RewindableStateMachine` do próprio netfox: a doc avisa que "most implementations are not prepared for rollbacks" ([doc](https://foxssake.github.io/netfox/latest/netfox.extras/guides/rewindable-state-machine/)).
  - RigidBody em rollback exige um fork ou addon com stepping manual ([doc](https://foxssake.github.io/netfox/latest/netfox.extras/guides/physics/)).

## 12. Organização do projeto
- **Doc oficial:** agrupar os assets perto das cenas que os usam. Arquivos e pastas em snake_case, nodes em PascalCase, código de terceiros em `addons/` ([docs](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html)).
- **GDQuest:** organizar por cena ou feature, com uma pasta `common/` para o que é compartilhado ([guia](https://gdquest.gitbook.io/gdquests-guidelines/godot-gdscript-guidelines)).
- **Na prática:** pastas por feature (`player/`, `weapons/`, `net/`), mais `common/`, `addons/` e `test/`.
