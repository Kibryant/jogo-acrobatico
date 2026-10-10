---
id: F-079
titulo: "O levantamento da abertura e a origem dos textos públicos: o estado do repositório no GitHub antes da TASK-11, os quatro commits de sonda fora das branches, de onde vêm a MIT, a CC BY 4.0 e o Contributor Covenant 3.0, a cláusula ShareAlike e o PR de fora do netfox (10/10/2026)"
recebido_em: 2026-10-10
como: Levantamento feito pelo Claude na sessão 11, antes do primeiro commit da TASK-11, com o `gh` (chamadas GET na API do GitHub), o git e o `curl`. Os textos das licenças foram baixados para fora do repositório e lidos inteiros antes de entrar nele. O §2 nasceu de um achado de um agente de planejamento com contexto limpo (Fable 5.1), conferido pelo Claude.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: o levantamento sustenta o roteiro da abertura e o que os arquivos públicos afirmam. Cite como F-079 §1 a §4.

## §1 — O repositório no GitHub antes da TASK-11

| O que | Valor |
|---|---|
| Visibilidade e plano | privado, GitHub Free, conta pessoal; branch padrão `main` |
| PR #3 (TASK-8) | aberto, com os checks `gate` e CodeRabbit verdes e o merge limpo (`CLEAN`); juntado na sessão 11 como o merge commit `1490d10` |
| Branches no GitHub | `main`, `task-7-desenho-5` (já juntada pelo PR #2) e `task-8-desenho-6`; mais `refs/pull/1/head` a `refs/pull/3/head` |
| Actions | 16 execuções, todas do workflow `ci`; nenhum artefato; 2 caches: o Godot de 75,8 MB na `main` e o Godot com templates de 1,34 GB na `refs/heads/probe/export-linux`, usado pela última vez em 07/10/2026 |
| Segredos, variáveis, webhooks, chaves de deploy, ambientes, tags, releases e Pages | nenhum |
| Permissão padrão do token do Actions | `read` (`default_workflow_permissions`) |
| O bloco "GITHUB_TOKEN Permissions" do log da última execução | `Contents: read`, `Metadata: read` e `Packages: read` |
| Núcleos da máquina no log do Actions | o log não mostra |
| Merge | merge commit, squash e rebase permitidos; `delete_branch_on_merge` desligado |
| Wiki, Projects e Discussions | ligado, ligado e desligado |
| Recursos de segurança | `security_and_analysis` vazio; o alerta do Dependabot e o relato privado de vulnerabilidade respondem 404 |
| Aprovação de PR de fora | a chamada responde 422, "Fork PR approval is not allowed for private repositories." |
| Prova da cota de minutos | a chamada de tempo da execução (`/timing`) dá `total_ms` 0 até para uma execução do repositório privado; o relatório de uso do billing pede o escopo `user`, que o token do `gh` não tem (`gist`, `read:org`, `repo`, `workflow`) |
| Comentários nos PRs | o CodeRabbit comentou uma vez em cada PR, do #1 ao #3; o Arthur comentou no #1. Nenhum traz e-mail, caminho do Windows ou padrão de token |

## §2 — Os commits de sonda fora das branches

`git rev-list 3e97177 0353917 3fb7b48 --not --all` devolve quatro commits que não estão em nenhuma branch, de duas branches de sonda da TASK-6 apagadas em 07/10/2026. O GitHub serve os quatro pela API de commits, e o SHA de três deles aparece na lista de execuções do Actions:

| Commit | Assunto | Arquivos |
|---|---|---|
| `6b97c12` | "Sonda da TASK-6, rodada 3: os dois presets exportados no Linux" | `.github/workflows/probe-export.yml`, `export_presets.cfg`, `probe_main.gd`, `probe_main.tscn`, `project.godot` |
| `0353917` | "Sonda da TASK-6, rodada 3: a linha da cena de sonda dentro de 100 colunas" | `probe_main.gd` |
| `3e97177` | "Sonda da TASK-6, rodada 3: segundo run, para medir o cache dos templates" | nenhum (commit vazio) |
| `3fb7b48` | "Sonda da TASK-6, rodada 2: o replay gravado no Windows, rodado no Linux" | `.github/workflows/probe-replay.yml` e os arquivos de `probes/replay/` |

## §3 — De onde vêm os textos públicos

- **MIT:** o modelo do próprio GitHub (`gh api licenses/mit`), com `[year]` trocado por 2026 e `[fullname]` por "Arthur Gustavo and contributors" (F-078 §2).
- **CC BY 4.0:** `https://creativecommons.org/licenses/by/4.0/legalcode.txt`, 18.657 bytes, sha256 `9ba9550ad48438d0…`, copiado sem mudança para o `LICENSE-ASSETS`. Ele difere do modelo que o GitHub usa para reconhecer a CC-BY-4.0 (`gh api licenses/cc-by-4.0`) só em espaços e quebras de linha: duas linhas com um espaço a menos e o último parágrafo quebrado em outro lugar.
- **Contributor Covenant 3.0:** o arquivo `content/version/3/0/code_of_conduct.md` do repositório `EthicalSource/contributor_covenant`, branch `release`, último commit `d379fc9` (04/08/2025). A pasta tem as traduções `bn`, `de`, `es`, `fr`, `hu`, `ja`, `ko` e `zh-cn`; nenhuma em português. A atribuição do texto diz: "Contributor Covenant is stewarded by the Organization for Ethical Source and licensed under CC BY-SA 4.0."
- **CC BY-SA 4.0:** `https://creativecommons.org/licenses/by-sa/4.0/legalcode.txt`. A seção 1(a): "Adapted Material means material subject to Copyright and Similar Rights that is derived from or based upon the Licensed Material and in which the Licensed Material is translated, altered, arranged, transformed, or otherwise modified". A seção 3(b)(1): "The Adapter's License You apply must be a Creative Commons license with the same License Elements, this version or later, or a BY-SA Compatible License." Por isso uma tradução do Contributor Covenant 3.0 fica na CC BY-SA 4.0.

## §4 — Um PR de fora num projeto aberto: o netfox

O PR #662 do `foxssake/netfox`, "fix: recover rollback after main-thread stalls", foi aberto em 09/10/2026 a partir do fork `upalvstavai/netfox`. Ele estava aberto em 10/10/2026, e as três execuções do CI dele (uma delas a `37962927404`) tinham a conclusão `action_required`: esperavam a aprovação de um mantenedor.
