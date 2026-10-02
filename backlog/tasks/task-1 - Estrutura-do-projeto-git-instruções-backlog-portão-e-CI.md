---
id: TASK-1
title: 'Estrutura do projeto: git, instruções, backlog, portão e CI'
status: In Progress
assignee: []
created_date: '2026-10-02 16:48'
updated_date: '2026-10-02 16:49'
labels:
  - base
milestone: m-0
dependencies: []
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
Primeira sessão do projeto: preparar o terreno antes de qualquer código de jogo, com a base no padrão do SkinHub (F-003 §4; DEC-0007; DEC-0009). O Arthur pediu git, CLAUDE.md, instruções, backlog e também o que ele tinha deixado de fora, como CI/CD e infraestrutura (F-003 §4).

### Perguntas em aberto
- Nenhuma. O que ficou aberto virou pendência (Q-01 a Q-09) e tasks (TASK-2 a TASK-10).

### Escolhas a confirmar
- Tasks em português (Q-08). Padrão sugerido: português.
- Fase de desenho antes do código de jogo (DEC-0012, proposta). Padrão sugerido: aceitar.

### Fora do escopo
- O repositório no GitHub e a primeira execução do CI (TASK-2).
- Qualquer código de jogo (TASK-9 em diante).

### O que você vai aprender
- O que é cada peça da base e por que ela existe: AGENTS.md, Backlog.md, portão, hooks do git, CI e Git LFS.
- Como o `project.godot` configura o projeto, e como um teste guarda essas escolhas.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Quando alguém clona o repositório e roda `lefthook install`, `godot --headless --path . --import` e `bash tools/gate.sh`, o portão termina verde sem conta de terceiros.
- [x] #2 Quando o `project.godot` perde o Jolt, o Compatibility, a tipagem obrigatória ou o jitter fix desligado, `test/project_settings_test.gd` falha.
- [x] #3 Quando um arquivo em `core/` usa nó, `Time`, `await` ou sorteio sem semente, `tools/check_core_purity.sh` falha, e comentário não conta.
- [x] #4 Quando um `.gd` sai do formato, o pre-commit e o portão falham.
- [x] #5 Quando um teste travado em `.claude/harness/locks/` muda, o portão falha.
- [ ] #6 Quando um agente abre o projeto, o `CLAUDE.md` carrega o `AGENTS.md`, com o mapa, as regras e o modo de construir e ensinar.
- [x] #7 Quando o Arthur quer saber de onde veio uma decisão, a DEC cita a fonte F-xxx com as palavras dele.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [x] #3 Diário da sessão escrito e glossário atualizado
- [x] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Na próxima sessão, aberta nesta pasta: conferir que o CLAUDE.md carregou o AGENTS.md (#6).
2. O Arthur revisa a base com a skill `explicar` e confirma a DEC-0012 e a Q-08.
3. Primeiro commit, com o Arthur vendo o lefthook rodar.
4. Marcar os critérios restantes e passar para Done.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Feito em 02/10/2026, a partir de uma sessão do my-brain. O que foi provado e como:

- Ferramentas em ~/.local/bin, sem precisar de administrador: Godot 4.7.2 (pelo winget, com o atalho `godot` para PowerShell e Git Bash), Backlog.md 1.53.0, GDScript Formatter 0.27.0, lefthook 2.1.16, gitleaks 8.30.1 e gh 2.102.0. O git-lfs 3.7.1 já vinha com o Git.
- O `project.godot` foi escrito à mão, com o Jolt explícito, porque o padrão do motor ainda é a física antiga (F-006 §3). O import sem janela passou sem erro.
- O gdUnit4 6.2.1 veio do código-fonte da tag, porque o release não publica binário. Está em `addons/gdUnit4`, com o plugin ligado. Os 4 testes de `test/project_settings_test.gd` passam em ~0,8 s.
- O portão completo (`tools/gate.sh`) fica verde em 11 s nesta máquina.
- A pureza do núcleo foi provada com uma sonda: barrou `Time`, `await`/`get_tree` e `randf()`, e ignorou comentário e texto entre aspas.
- A trava de testes foi provada com uma sonda: passa íntegra e falha quando o hash muda.
- O `lefthook validate` passou, e o gitleaks não achou segredo no diretório.
- As fontes F-001, F-003 e F-005 a F-008 foram extraídas das transcrições da sessão, sem redigitar. O estudo bate com o Yabadoo em 14.134 caracteres.
- Falta conferir: o CLAUDE.md carregando o AGENTS.md numa sessão real (#6), o primeiro commit com o lefthook rodando e o CI no GitHub (TASK-2).
<!-- SECTION:NOTES:END -->
