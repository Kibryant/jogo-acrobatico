---
id: TASK-2
title: Criar o repositório privado no GitHub e rodar o primeiro CI
status: In Progress
assignee: []
created_date: '2026-10-02 16:48'
updated_date: '2026-10-02 21:25'
labels:
  - infra
milestone: m-0
dependencies: []
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
O CI está escrito (`.github/workflows/ci.yml`), mas nunca rodou: o repositório só existe nesta máquina (TASK-1). Com o remoto, o histórico fica guardado e o portão roda também numa máquina Linux limpa (DEC-0006).

### Perguntas em aberto
- O repositório fica privado sem proteção, público ou no GitHub Pro (Q-03)?

### Escolhas a confirmar
- Nome do repositório: `jogo-acrobatico`, na conta Kibryant. Padrão sugerido: esse.
- Visibilidade: privado, sem regra de branch (Q-03). Padrão sugerido: privado.
- Login do gh: o Arthur roda `gh auth login`, que é interativo.

### Fora do escopo
- Builds e releases (Desenho 4, TASK-6).

### O que você vai aprender
- Como o GitHub Actions roda o mesmo portão numa máquina Linux limpa, e o que muda entre Windows e Linux: Godot sem janela, LFS e permissões de arquivo.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Quando o primeiro push acontece, o repositório existe no GitHub com o histórico local e os binários no LFS.
- [x] #2 Quando o push chega na main, o workflow `ci` roda e termina verde, com o gitleaks e o portão.
- [x] #3 Quando o CI falha, o log mostra o passo que falhou e por quê.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Critérios de aceite verificados
- [x] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [x] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Checagem prévia, sem publicar: versões fixadas do CI, gitleaks no histórico, portão num clone limpo e hook do LFS dentro do lefthook.
2. Criar o repositório privado `Kibryant/jogo-acrobatico` e ligar o `origin` (Q-03: privado sem regra de branch).
3. Primeiro push: o pre-push roda o portão, e o lefthook sobe os PNGs no LFS.
4. Acompanhar o CI até o verde (critérios 1 e 2).
5. Sonda do critério 3: branch e PR em rascunho criados no GitHub, com um teste que falha de propósito; conferir o log; fechar o PR e apagar o branch.
6. Registro: a fonte com as respostas do Arthur, a Q-03, `mudancas.md` e o registro da harness.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Sessão 3 (02/10/2026):
- Checagem prévia, sem publicar: as versões fixadas do CI existem; o gitleaks varreu o histórico sem achar segredo; o portão ficou verde num clone limpo em 16 s; o lefthook 2.1.16 chama `git lfs pre-push` por dentro.
- Repositório: https://github.com/Kibryant/jogo-acrobatico, privado, sem regra de branch (Q-03; F-017 §2).
- Primeiro push: o pre-push rodou o portão pela primeira vez (verde em 10 s) e subiu 8 objetos no LFS (9 PNGs, dois iguais).
- Critérios 1 e 2: CI verde em 20 s no Ubuntu 24.04, com o LFS no checkout, o gitleaks sem achado e os 4 testes verdes no Godot 4.7.2. Run: https://github.com/Kibryant/jogo-acrobatico/actions/runs/37066177321
- Critério 3: sonda criada no servidor (branch `probe/ci-failure`, teste que falha de propósito, PR #1 em rascunho). O log mostrou o passo `Gate (tools/gate.sh)`, o passo do portão `== Tests (gdUnit4)`, o arquivo, a linha e o motivo ("Expecting 3 but was 2"). PR fechado sem merge e branch apagado. Run: https://github.com/Kibryant/jogo-acrobatico/actions/runs/37066396280
- Achados levados para a TASK-6: o ruído do `--remote-debug` no log e o `ubuntu-latest` virando Ubuntu 26 em 19/10 (Q-15).
- DoD #2: task de infraestrutura, sem regra de núcleo. DoD #3: fecha com o diário da sessão 3; nenhum termo de domínio novo.
- Uma segunda sessão do Claude, no mesmo diretório, levou esta edição da task no commit f3170b1. Nada se perdeu.
<!-- SECTION:NOTES:END -->
