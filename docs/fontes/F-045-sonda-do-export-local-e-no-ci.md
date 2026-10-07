---
id: F-045
titulo: A sonda do export — os dois presets exportam neste PC e no Linux do CI, o servidor exportado sobe e fecha com código 0, e o .exe feito no Linux roda aqui com a versão certa (sessão 7, 07/10/2026)
recebido_em: 2026-10-07
como: Medido pelo Claude na sessão 7 (rodada 3 da TASK-6), num clone fora do repositório (`../export-sonda`) e em dois runs do GitHub numa branch de sonda já apagada. Números como saíram dos logs.
status: vigente
substituida_por:
---

## §1 — Os templates de export

- O Arthur baixou pelo editor só os templates de Windows e Linux, x86_64, release e debug.
- Eles ficaram em `%APPDATA%\Godot\export_templates\4.7.2.stable`, com 344 MB no disco:

| Arquivo | Bytes |
|---|---|
| `windows_release_x86_64.exe` | 109.268.480 |
| `windows_debug_x86_64.exe` | 103.176.704 |
| `windows_release_x86_64_console.exe` e `windows_debug_x86_64_console.exe` | 188.928 cada |
| `linux_release.x86_64` | 73.519.416 |
| `linux_debug.x86_64` | 73.703.800 |

## §2 — O export neste PC

**A montagem:** o clone do commit `abb30d2`, com dois presets escritos à mão no `export_presets.cfg`.
- **"Cliente Windows":** PCK embutido, `application/modify_resources` ligado, nome e descrição do produto.
- **"Servidor Linux":** modo servidor dedicado, recursos com "strip visuals".
- **Nos dois:** fora `test/*`, `addons/gdUnit4/*`, `tools/*` e `reports/*`.
- **A cena de sonda** (`probe_main.gd`) imprime a versão, o commit, a feature tag `dedicated_server` e se roda sem tela, e fecha com código 0. O `project.godot` do clone ganhou `config/version="0.1.0"`, `config/commit` e a cena principal.
- **O editor**, aberto no clone, reordenou as chaves novas do `project.godot` e não mexeu no `export_presets.cfg`.

| Export | Código de saída | Tempo | Tamanho |
|---|---|---|---|
| Cliente Windows (`--export-release`) | 0 | 10,9 s | 109.360.480 bytes |
| Servidor Linux (`--export-release`) | 0 | 8,2 s | 73.750.648 bytes |
| Pacote do cliente (`--export-pack`) | 0 | 8,0 s | 232.784 bytes |
| Pacote do servidor (`--export-pack`) | 0 | 7,9 s | 231.228 bytes |

**O que entrou nos pacotes** (formato 4, Godot 4.7.2, lido por um script da sonda):
- 163 arquivos, ~216 kB em cada um: o netfox (core, extras e internals: 147 arquivos), a cena de sonda compilada (`.gdc`), o `project.binary` e o cache do `.godot`.
- Nenhum caminho de `test/`, do gdUnit4, de `tools/`, de `reports/` nem dos canários.

**A build rodando:**
- O `.exe` do cliente, sem tela, imprimiu `BUILD version=0.1.0 commit=abb30d2 dedicated_server=false headless=true platform=Windows editor=false` e saiu com código 0 em 0,6 s.
- Nas propriedades do arquivo, o Windows mostra `FileVersion 0.1.0.0`, `ProductVersion 0.1.0.0` e `ProductName Jogo Acrobático`.
- O wrapper de console não saiu: `debug/export_console_wrapper=1` só gera o wrapper na build de debug.

## §3 — O export no CI

**A montagem:** dois runs no `ubuntu-24.04`, com o `setup-godot@v2` e `include-templates: true`, que baixa o pacote inteiro de 1,28 GB e guarda no cache.
- O CI escreveu os 7 primeiros caracteres do commit em `config/commit` antes de exportar.
- O primeiro push foi barrado pelo pre-push: o lint achou uma linha de 102 colunas na cena de sonda. Depois do conserto, o portão passou em 39 s no worktree novo.

| Passo | Run 1, cache frio (37666674563) | Run 2, cache quente (37669368480) |
|---|---|---|
| `setup-godot` com os templates | 51 s | 30 s (cache restaurado) |
| Import | 8 s | 8 s |
| Export do cliente Windows | 4,1 s, código 0 | 3,3 s, código 0 |
| Export do servidor Linux | 5,3 s, código 0 | 3,2 s, código 0 |
| Servidor exportado rodando sem tela | `dedicated_server=true`, código 0 | `dedicated_server=true`, código 0 |
| Upload do artefato | 7 s | 6 s |
| Job inteiro | 83 s | 57 s |

- O Godot não caiu ao sair depois dos exports: o #123712 não apareceu.
- O artefato com as duas builds tem 68.393.762 bytes compactado e foi guardado por 1 dia.

## §4 — O .exe feito no Linux, rodando neste PC

- O `.exe` do run 2, baixado com o `gh run download`, rodou sem tela neste PC.
- Ele imprimiu `BUILD version=0.1.0 commit=3e97177 dedicated_server=false headless=true platform=Windows editor=false` e saiu com código 0 em 1,0 s.
- Nas propriedades: `FileVersion 0.1.0.0`, `ProductVersion 0.1.0.0` e `ProductName Jogo Acrobático`, escritos no Linux sem rcedit.
