---
id: F-081
titulo: "A conferência final, a virada e as sondas da abertura: o histórico limpo em todas as refs e nos commits soltos, os 20 logs do Actions, o repositório público às 21:25 UTC, a trava e os recursos ligados e conferidos, o commit direto aceito, o force push recusado e o CI em 4 núcleos (10/10/2026)"
recebido_em: 2026-10-10
como: Medições feitas pelo Claude na sessão 11, com o `gh` (chamadas na API do GitHub), o git, o gitleaks 8.30.1 e scripts de busca por padrão, num clone espelho fora do repositório. As saídas foram gravadas na hora; os horários são UTC.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: são os critérios 3, 5 e 6 da TASK-11. O ok do Arthur para a virada está na F-080 §2. Cite como F-081 §1 a §6.

## §1 — Depois do merge do PR #4, ainda privado

- O merge commit `3fd067c` pôs na `main` a licença e os arquivos da comunidade.
- A API de licença do GitHub lê o repositório como MIT, pelo arquivo `LICENSE`.
- O perfil da comunidade dá 100%, com o README, a licença (`mit`), o CONTRIBUTING, o código de conduta (`other`, porque a tradução não é um texto que o GitHub conheça) e o modelo de PR.
- O modelo de issue aparece como ausente na API, e a lista de modelos do GraphQL vem vazia. O `godotengine/godot`, que só usa formulários em YAML, também vem vazio nas duas, então a API não conta formulários. O `config.yml` foi lido: o link "Perguntas e ideias" aparece.
- O Discussions foi ligado e o Wiki desligado logo depois do merge (F-080 §1).

## §2 — A conferência final (critério 3)

| O que | Resultado |
|---|---|
| Branches no GitHub | só a `main`, depois de apagar a `task-7-desenho-5`; a `task-11-abrir-repositorio` saiu no merge do PR #4 |
| PRs abertos | nenhum |
| Refs no clone espelho | `refs/heads/main` e `refs/pull/1/head` a `refs/pull/4/head`; 50 commits |
| gitleaks em todas as refs | 47 commits, uns 3 MB, nenhum vazamento |
| Os quatro commits soltos (F-079 §2) | em nenhuma ref, mas servidos pelo SHA; o gitleaks no patch deles (236.481 bytes) não achou vazamento |
| E-mails no histórico | o do Arthur, o noreply dele, o `noreply@anthropic.com` das coautorias, o exemplo de formato da F-069 e dois falsos positivos (um trecho de link da documentação do Godot e o `@AGENTS.md` do `CLAUDE.md`) |
| Caminhos com o usuário do Windows | 15 linhas na `main`: os mesmos 14 caminhos da F-075 e a própria F-075 escrevendo o padrão; nenhum nos commits soltos |
| CPF, celular e padrão de token | nenhum |
| IPv4 | `127.0.0.1`, três números de versão (`0.1.0.0`, `1.0.0.0`, `0.11.0.3`) e os mesmos endereços de documentação da F-075 §3 (`100.64.0.0`, `216.238.98.118`, `1.1.1.1`) |
| Logs do Actions | as 20 execuções, todas baixadas (896.728 bytes): nenhum e-mail, caminho do Windows, token, CPF ou celular; só o `127.0.0.1`; o gitleaks nos logs não achou vazamento |
| Artefatos do Actions | nenhum |

## §3 — A virada (critério 4)

- 21:25:43: privado, 0 estrelas, 0 watchers.
- `gh repo edit Kibryant/jogo-acrobatico --visibility public --accept-visibility-change-consequences`, saída 0.
- 21:25:46: público.

## §4 — Logo depois (critério 5)

Às 21:25:55, antes de qualquer mudança, o GitHub tinha deixado:
- o secret scanning, o push protection, o alerta do Dependabot e o relato privado desligados;
- a aprovação de PR de fora em `first_time_contributors`;
- nenhum ruleset e nenhuma regra na `main`.

Às 21:26:08 entraram:
- o ruleset 24855428, "Trava da main (DEC-0033)": ativo, na branch padrão (`~DEFAULT_BRANCH`), com as regras `deletion` e `non_fast_forward` e a lista de quem pode pular vazia;
- a aprovação de PR de fora em `all_external_contributors`;
- o secret scanning e o push protection;
- o alerta do Dependabot;
- o relato privado de vulnerabilidade.

A conferência por leitura, às 21:26:21:
- as regras que valem na `main` são `deletion` e `non_fast_forward`, do ruleset 24855428;
- a aprovação está em `all_external_contributors`;
- o secret scanning e o push protection estão `enabled`;
- o alerta do Dependabot responde 204;
- o grafo de dependências tem 3 pacotes;
- o relato privado está `enabled: true`;
- o Discussions está ligado e o Wiki desligado.

Seguem desligados, porque o critério não os pede: as atualizações de segurança do Dependabot (os PRs automáticos), os padrões fora dos provedores e a checagem de validade do secret scanning.

## §5 — As sondas (critério 6)

- **Commit direto:** o commit vazio `f7857ca` foi direto na `main` às 21:27:42 e passou (`3fd067c..f7857ca  main -> main`). O lefthook pulou o portão do pre-push ("gate (skip) no matching push files"), porque o commit não muda arquivo.
- **Primeira tentativa de force push:** não testou nada. O `git commit --amend --no-edit` recusou o commit vazio ("No changes"), o commit novo saiu igual ao antigo, e o push respondeu "Everything up-to-date".
- **Segunda tentativa:** com `--allow-empty`, saiu o commit `cfdba79`, com a mesma árvore e o mesmo pai do `f7857ca`. Às 21:28:47, `git push --force-with-lease=refs/heads/main:f7857ca… origin cfdba79…:refs/heads/main` foi recusado:

  ```
  remote: error: GH013: Repository rule violations found for refs/heads/main.
  remote: - Cannot force-push to this branch
   ! [remote rejected] cfdba79ccb3c14cbad8bb1395038b432d581affa -> main (push declined due to repository rule violations)
  ```

  A `main` seguiu em `f7857ca`.
- **Apagar a main:** não houve sonda, porque o GitHub recusa apagar a branch padrão com ou sem regra, e a sonda não distinguiria uma coisa da outra. A regra `deletion` aparece entre as que valem na `main` (§4).
- **O CI no repositório público:** a execução 38087716179 (push na `main`, `f7857ca`, 21:27:50) saiu verde.
  - O token tinha só `Contents: read` e `Metadata: read`.
  - O passo "Runner size" mostrou `vCPU: 4` e `Mem: 15Gi`; no PR #4, ainda privado, a execução 38085327312 mostrou `vCPU: 2` e `Mem: 7.8Gi`. Só repositório público ganha o runner padrão de 4 núcleos, e de graça (F-069 §1 e §12, R-01).
  - O portão saiu verde em 10 s, e o gitleaks não achou vazamento em 46 commits.
- **O que não foi medido:** a página de uso do billing não foi lida. A sonda do check obrigatório da DEC-0033 §3 não foi feita, porque a trava leve que o Arthur escolheu não o inclui (F-076 §1).

## §6 — O que fica para depois

- A aprovação de PR de fora só se confere no primeiro PR de verdade vindo de um fork.
- Às 21:32:55, depois de o Arthur dizer que clicou em Watch (F-080 §3), o GraphQL respondeu `viewerSubscription: UNSUBSCRIBED` e 0 watchers. A API da inscrição pede o escopo `notifications`, que o token do `gh` não tem.
- A TASK-11 fugiu da DEC-0028 §4 em três pontos, que a ordem dos blocos (F-077 §1) e os critérios 1 e 6 da task pedem:
  - dois PRs, porque a licença precisava estar na `main` antes da virada e o fechamento só existe depois dela;
  - um commit vazio direto na `main`, feito numa sessão com task, porque a sonda do critério 6 é um push direto;
  - a branch do fechamento, `task-11-fechamento`, com outro nome.
