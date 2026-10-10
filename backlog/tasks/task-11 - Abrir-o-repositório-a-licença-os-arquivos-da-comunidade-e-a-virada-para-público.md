---
id: TASK-11
title: >-
  Abrir o repositório: a licença, os arquivos da comunidade e a virada para
  público
status: Ready
assignee: []
created_date: '2026-10-10 13:20'
labels:
  - infra
milestone: m-0
dependencies:
  - TASK-8
ordinal: 11000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
O Arthur quer o jogo aberto, com PRs da comunidade e ele como mantenedor principal (F-058). O Desenho 6 decidiu como: MIT no código, CC BY 4.0 nos assets próprios, o nome e o logo fora da licença, o histórico aberto como está, a main sem force push e o PR de fora só com aprovação (DEC-0033). Abrir é voltado para fora e não se desfaz, por isso é uma task própria, com o ok do Arthur na hora (F-071 §4, escolha 6). O ensaio num clone não achou segredo nem dado pessoal além do e-mail, que ele aceita mostrar (F-075; F-071 §3).

### Perguntas em aberto
Nenhuma: as escolhas saíram da TASK-8 (F-076; F-077). A ordem importa:
- Antes da virada: a licença e os arquivos da comunidade na main, o CI endurecido e o histórico conferido de novo.
- A virada: o repositório passa a público, com o ok do Arthur no momento.
- Logo depois: as travas e os recursos que o GitHub só liga em repositório público no plano Free (F-069 §12, X-02).
- O que só se confere depois: o que precisa de um repositório público ou de uma pessoa de fora.

### Escolhas confirmadas
Confirmadas pelo Arthur no plano aprovado do fechamento do Desenho 6 (F-077) e na rodada 2 (F-076):
1. `LICENSE` com a MIT; `LICENSE-ASSETS` com a CC BY 4.0 para os assets próprios (DEC-0033 §1).
2. O aviso de que o nome e o logo ficam fora da licença mora no README, sem `TRADEMARK.md`.
3. O código de conduta é o Contributor Covenant 3.0 em português.
4. Os arquivos públicos (README, CONTRIBUTING, SECURITY) ficam em português, com um resumo em inglês; o texto das licenças fica no original (DEC-0033 §4).
5. Um modelo de issue e um de PR.
6. O job `gate` mantém `lfs: true`; o `lfs: false` vale para jobs futuros sem import (DEC-0033 §3).

### Fora do escopo
- O pedido ao SignPath: vem depois da primeira release (DEC-0034).
- Reescrever o histórico ou trocar o e-mail (F-071 §3).
- O job da imagem do servidor no CI: é da TASK-9 (DEC-0032).

### O que você vai aprender
- O que muda num repositório quando ele vira público: o que o GitHub liga, o que ele zera e o que não dá para desfazer.
- Como um ruleset e a aprovação de PR de fora protegem a main de quem não tem o seu PC.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando a task começa, antes da virada, a main tem `LICENSE` (MIT), `LICENSE-ASSETS` (CC BY 4.0), o `README` com o aviso do nome, o `CONTRIBUTING.md`, o `CODE_OF_CONDUCT.md` (Contributor Covenant 3.0 em português), o `SECURITY.md` e os modelos de issue e de PR, nos idiomas da DEC-0033 §4.
- [ ] #2 Quando o workflow do CI muda, ele roda com `permissions: contents: read` e sem `pull_request_target`, e um PR de sonda prova que o portão segue verde; o job `gate` mantém `lfs: true`.
- [ ] #3 Quando o histórico final está pronto para abrir, o gitleaks em todas as refs sai limpo, os logs e artefatos antigos do Actions foram revistos, nenhuma branch de task está aberta e a `task-7-desenho-5` foi apagada; quando algo disso falha, a virada espera.
- [ ] #4 Quando tudo acima está verde, o repositório só vira público com o ok do Arthur no momento, e uma fonte registra o ok.
- [ ] #5 Quando o repositório já é público, o ruleset da main recusa force push e apagar, o PR de fora pede aprovação para rodar o CI, e o Discussions, o secret scanning com push protection, o Dependabot e o relato privado de vulnerabilidade ficam ligados.
- [ ] #6 Quando a abertura termina, uma sonda prova que um force push na main é recusado e que um commit direto de sessão sem task passa, e o CI roda no repositório público sem gastar a cota de minutos; a aprovação de PR de fora fica para conferir no primeiro PR de verdade, anotado na task.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
