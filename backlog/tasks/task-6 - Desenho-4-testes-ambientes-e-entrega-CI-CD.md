---
id: TASK-6
title: 'Desenho 4: testes, ambientes e entrega (CI/CD)'
status: To Refine
assignee: []
created_date: '2026-10-02 16:48'
updated_date: '2026-10-02 21:25'
labels:
  - infra
  - desenho
milestone: m-0
dependencies:
  - TASK-4
  - TASK-2
ordinal: 6000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
Quarta conversa da fase de desenho (DEC-0012). A base já tem portão, hooks e um CI mínimo (DEC-0006). Falta o desenho completo: o que cada camada de teste cobre, as builds, as versões e os hooks do próprio Claude Code (DEC-0009).

### Perguntas em aberto
- As camadas de teste: o que entra em cada uma, e quando (F-007 §7).
- As builds: presets de export do cliente Windows e do servidor Linux sem tela; templates de export, que têm 1,28 GB com todas as plataformas (F-006 §7).
- As versões: SemVer, tags e notas de release.
- Branch e PR: a task abre e fecha no PR, como no YabaBuss? Lembrando que o plano Free não aplica regra de branch (Q-03).
- Os hooks do Claude Code: travar teste de aceite e formatar depois de editar, testados numa sessão real nesta máquina.
- O replay por inputs, re-rodado no servidor (DEC-0011).

### Escolhas a confirmar
- Trunk-based, com branch curta por task e PR. Padrão sugerido: esse.

### Fora do escopo
- O deploy do servidor (Desenho 6 e esqueleto andante).

### O que você vai aprender
- Como um jogo é empacotado (templates de export, .pck, feature tags) e como o CI produz a build.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando a conversa termina, `docs/arquitetura/testes-e-entrega.md` mostra as camadas de teste, o que o CI roda, as builds e as versões.
- [ ] #2 Quando o Arthur decide o fluxo de branch e as versões, uma DEC registra.
- [ ] #3 Quando um hook do Claude Code entra, ele foi testado numa sessão real nesta máquina e está no registro da harness.
- [ ] #4 Quando um `#` dentro de uma string esconde código proibido na mesma linha de `core/`, `tools/check_core_purity.sh` falha, e uma sonda prova o antes e o depois.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->

## Comments

<!-- COMMENTS:BEGIN -->
author: Claude
created: 2026-10-02 17:10
---
Furo achado na sessão 2 (02/10/2026), com uma sonda numa cópia fora do projeto. `var label := "Time.get_ticks_msec()"` foi barrado: texto entre aspas conta (falso positivo, o lado seguro). `var c := "#ff0000"; var t := Time.get_ticks_msec()` passou: o `#` da string vira comentário e esconde o resto da linha (falso negativo). O Arthur decidiu consertar nesta conversa, antes de existir código em `core/` (F-010 §2).
---

author: Claude
created: 2026-10-02 21:25
---
Achados do primeiro CI, na sessão 3 (02/10/2026, TASK-2):
- Ruído no log: o truque `--remote-debug tcp://127.0.0.1:0` do `tools/run_tests.sh` imprime duas linhas `ERROR: ... Remote Debugger` em todo run de teste. Na sonda do critério 3 (PR #1), elas apareceram coladas na falha de verdade e despistam quem lê o log. Nada decidido: só registrado para esta conversa.
- O runner `ubuntu-latest` passa a ser o Ubuntu 26 a partir de 19/10/2026 (Q-15).
---
<!-- COMMENTS:END -->
