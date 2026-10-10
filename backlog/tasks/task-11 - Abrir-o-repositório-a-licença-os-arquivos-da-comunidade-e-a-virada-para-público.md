---
id: TASK-11
title: >-
  Abrir o repositório: a licença, os arquivos da comunidade e a virada para
  público
status: Done
assignee: []
created_date: '2026-10-10 13:20'
updated_date: '2026-10-10 21:55'
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
- [x] #1 Quando a task começa, antes da virada, a main tem `LICENSE` (MIT), `LICENSE-ASSETS` (CC BY 4.0), o `README` com o aviso do nome, o `CONTRIBUTING.md`, o `CODE_OF_CONDUCT.md` (Contributor Covenant 3.0 em português), o `SECURITY.md` e os modelos de issue e de PR, nos idiomas da DEC-0033 §4.
- [x] #2 Quando o workflow do CI muda, ele roda com `permissions: contents: read` e sem `pull_request_target`, e um PR de sonda prova que o portão segue verde; o job `gate` mantém `lfs: true`.
- [x] #3 Quando o histórico final está pronto para abrir, o gitleaks em todas as refs sai limpo, os logs e artefatos antigos do Actions foram revistos, nenhuma branch de task está aberta e a `task-7-desenho-5` foi apagada; quando algo disso falha, a virada espera.
- [x] #4 Quando tudo acima está verde, o repositório só vira público com o ok do Arthur no momento, e uma fonte registra o ok.
- [x] #5 Quando o repositório já é público, o ruleset da main recusa force push e apagar, o PR de fora pede aprovação para rodar o CI, e o Discussions, o secret scanning com push protection, o Dependabot e o relato privado de vulnerabilidade ficam ligados.
- [x] #6 Quando a abertura termina, uma sonda prova que um force push na main é recusado e que um commit direto de sessão sem task passa, e o CI roda no repositório público sem gastar a cota de minutos; a aprovação de PR de fora fica para conferir no primeiro PR de verdade, anotado na task.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [x] #3 Diário da sessão escrito e glossário atualizado
- [x] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Parte 1 (10/10, sessão 11), antes da virada, no PR #4:
- O PR #3 (TASK-8) entrou primeiro, com o ok do Arthur (merge commit `1490d10`). A conferência do PR de fora falhou na primeira vez e acertou depois do PR #662 do netfox (F-078).
- Um agente de planejamento com contexto limpo (Fable 5.1) criticou o roteiro: 10 achados, nenhum bloqueio. Entraram um quarto commit solto na varredura, o passo "Runner size" no CI como prova da cota, a sonda do force push que troca em vez de tirar, o Discussions e o Wiki antes da virada, o Watch depois dela e a pergunta da licença dos docs, que virou a DEC-0035 (F-078 §4).
- Os arquivos: `LICENSE` (o modelo MIT do GitHub), `LICENSE-ASSETS` (o texto oficial da CC BY 4.0, sem cabeçalho, para o GitHub reconhecer), o README no formato "tudo é MIT, exceto", o CONTRIBUTING e o SECURITY com resumo em inglês, o código de conduta traduzido do Contributor Covenant 3.0 (sem tradução oficial em português; CC BY-SA 4.0), o formulário de bug, o `config.yml` e o modelo de PR (F-079 §3).
- O CI com `permissions: contents: read`: o bloco "GITHUB_TOKEN Permissions" perdeu o `Packages: read`; o runner privado tinha 2 vCPU e 7,8 GB.
- O reviewer aprovou os critérios 1 e 2 com cinco ajustes de texto, feitos no mesmo PR. O GitHub lê o repositório como MIT, e o perfil da comunidade deu 100%; a API não conta formulários de issue (o Godot também vem vazio).

Parte 2 (10/10, sessão 11), a conferência, a virada e as sondas (F-080; F-081):
- A conferência final: só a `main` no GitHub; o gitleaks limpo em todas as refs e nos quatro commits soltos; os mesmos 14 caminhos da F-075; os 20 logs do Actions sem dado pessoal; nenhum artefato.
- A virada às 21:25:46 UTC, com o ok do Arthur na hora.
- Logo depois: o ruleset 24855428 (`deletion` e `non_fast_forward`, sem ninguém para pular), a aprovação de todo PR de fora, o secret scanning com push protection, o alerta do Dependabot e o relato privado, cada um conferido por leitura.
- As sondas: o commit vazio `f7857ca` passou direto na main; o force push de um commit igual foi recusado com o GH013; o CI no repositório público rodou em 4 vCPU e 15 GB, verde. A primeira tentativa de force push não testou nada (o amend recusou o commit vazio); a segunda tinha uma trava contra isso.
- **A aprovação de PR de fora fica para conferir no primeiro PR de verdade vindo de um fork.**
- O Watch: às 21:32 UTC a API respondia `UNSUBSCRIBED`; o Arthur pôs o Watch de novo, e às 21:38 a API respondia `SUBSCRIBED` (F-081 §6). Ele também conferiu na tela que o formulário de issue aparece (F-080 §4).
- O CodeRabbit, app do GitHub que comenta em todo PR, fica por enquanto (F-080 §4); no primeiro PR de fora, ver se o resumo dele ajuda ou atrapalha quem contribui.
- A TASK-11 fugiu da DEC-0028 §4 em três pontos, registrados no `mudancas.md`: dois PRs, um commit vazio direto na main e a branch `task-11-fechamento`.
- O DoD 2 (teste para regra do núcleo) não se aplica: não há código em `core/`.

Fechamento (10/10, sessão 11), no PR #5:
- O reviewer (Fable 5.1, contexto limpo) aprovou os critérios 3 a 6 com prova ao vivo: o próprio gitleaks num clone espelho novo, os 22 logs do Actions, o ruleset com `current_user_can_bypass: never` e o registro de atividade do GitHub, que mostra só a `main` entre 21:19 e 21:37 UTC, em volta da virada. A prova da cota é inferência (o runner de 4 núcleos, que o GitHub dá de graça a repositório público), como a F-081 §5 diz. Os ajustes de texto (duas linhas do glossário) entraram no PR.
<!-- SECTION:NOTES:END -->
