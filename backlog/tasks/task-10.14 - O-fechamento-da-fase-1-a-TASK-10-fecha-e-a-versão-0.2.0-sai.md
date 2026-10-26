---
id: TASK-10.14
title: 'O fechamento da fase 1: a TASK-10 fecha e a versão 0.2.0 sai'
status: To Refine
assignee: []
created_date: '2026-10-26 23:04'
labels: []
dependencies:
  - TASK-10.8
  - TASK-10.13
parent_task_id: TASK-10
ordinal: 23000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
A fase 1 termina quando o teste dela passa (DEC-0028 §3), e o teste passou: o Arthur continuaria jogando (F-166 §2). Antes de fechar, ele pediu a regra da mesma parede (TASK-10.13) e a medida dos cantos da borda (TASK-10.8) (F-167 §2). Esta filha fecha a TASK-10 depois delas, sobe a versão para 0.2.0 e publica a segunda release, pública (F-165 §1).

### Perguntas em aberto
- Se a sonda do canto da TASK-10.8 mostrar que o Z passa dos 50 m da borda, o plano de morte vira filha da TASK-10 e entra nas dependências desta (F-167 §2).

### Escolhas a confirmar
Confirmadas pelo Arthur (F-165 §1; F-167 §2): a 0.2.0 é pública, com os builds e as notas em português tiradas do diário, e o push da tag espera o ok dele.

### Fora do escopo
- A fase 2 e qualquer mudança de regra.

### O que você vai aprender
- Como uma fase fecha: os critérios da mãe com prova, a versão no mesmo commit e a release pela tag.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando as filhas da TASK-10 estão Done, o PR marca os critérios 1 e 2 da TASK-10 com as provas (F-166 §2; o teste da cópia do Resource da TASK-10.8) e fecha a TASK-10 (DEC-0028 §3)
- [ ] #2 Quando o PR fecha a TASK-10, o mesmo commit sobe `application/config/version` para 0.2.0, e o teste do formato da versão segue verde (DEC-0028 §3)
- [ ] #3 Quando o Arthur dá o ok, a tag `v0.2.0` sai, e o CI publica a segunda release com os dois builds e as notas de `docs/releases/v0.2.0.md`, em português, tiradas do diário (DEC-0028 §4.3; DEC-0033; F-165 §1)
- [ ] #4 Quando a release sai, o `roteiro.md` marca a fase 1 fechada e o portão da fase 2, e o `mudancas.md` ganha a linha (DEC-0028)
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
