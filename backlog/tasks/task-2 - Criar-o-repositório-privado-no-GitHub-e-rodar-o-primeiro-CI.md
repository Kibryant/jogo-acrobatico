---
id: TASK-2
title: Criar o repositório privado no GitHub e rodar o primeiro CI
status: To Refine
assignee: []
created_date: '2026-10-02 16:48'
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
- [ ] #1 Quando o primeiro push acontece, o repositório existe no GitHub com o histórico local e os binários no LFS.
- [ ] #2 Quando o push chega na main, o workflow `ci` roda e termina verde, com o gitleaks e o portão.
- [ ] #3 Quando o CI falha, o log mostra o passo que falhou e por quê.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
