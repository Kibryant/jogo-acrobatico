---
id: F-048
titulo: O Arthur aprova, no modo de plano, o plano do fechamento do Desenho 4 — duas DECs, o testes-e-entrega.md, os presets com guarda, a versão 0.0.0 e as instruções da harness (sessão 7, 07/10/2026)
recebido_em: 2026-10-07
como: Plano escrito pelo Claude e aprovado pelo Arthur no modo de plano do Claude Code (ExitPlanMode), na sessão 7. Texto como foi aprovado, sem o título.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: depois das três rodadas da TASK-6 (F-038 a F-046), o Claude escreveu um rascunho do fechamento e o passou por um agente de planejamento de contexto limpo, que achou 15 pontos. Os três graves foram números da vitrine sem fonte no repositório (daí a F-047), o contorno do #123712 sem lugar e escolhas do plano virando regra sem fonte. O plano abaixo incorpora os 15. As escolhas que ele faz e que o Arthur não tinha feito antes valem por esta aprovação: a versão 0.0.0 até o esqueleto andante, a referência só no Linux se as plataformas divergirem, a checagem dos dados com o primeiro `.tres`, o teste de fumaça na TASK-9, a leitura do `export_presets.cfg` num teste, os cortes do `AGENTS.md` e as duas checagens novas do reviewer.


## Contexto

As três rodadas da TASK-6 estão feitas (F-038 a F-046), e os critérios 3 a 7 estão cumpridos. Faltam o critério 1 (o `testes-e-entrega.md`), o 2 (as DECs, confirmando ou substituindo a DEC-0006) e o 8 (os presets exportados, com o contorno do #123712), mais a definição de pronto. Um agente de planejamento, de contexto limpo, criticou o rascunho e achou 15 pontos. Os três graves foram: números da vitrine sem fonte no repositório, o contorno do #123712 sem lugar e escolhas do plano virando regra sem fonte. Todos os 15 entraram aqui.

A TASK-6 abriu antes do fluxo de branch, e fecha na main. A primeira branch é a da próxima task. A DEC-0028 e o `mudancas.md` registram isso.

## A ordem

1. As fontes: a F-047, já guardada, e a F-048, com este plano, logo depois da sua aprovação.
2. O código, pelo implementer, e a prova do export a partir deste repositório.
3. As DECs, o documento, o `AGENTS.md` e as instruções da harness, num commit só.
4. O reviewer e o portão num clone limpo.
5. Só depois do APPROVE do reviewer: os critérios marcados, a TASK-6 em Done, o registro da harness, o diário e o push, com a sua permissão.

## 1. As fontes

- **F-047 (já feita):** as pesquisas da sessão 6. Traz a cota do GitHub Free (2.000 min, 500 MB divididos com os pacotes, 90 dias de retenção), os templates do 4.7.2, o export sem rcedit, o servidor dedicado, as issues #123712 e #1324, a versão do projeto, o gdUnit4 e os hooks. É a fonte que faltava para os números da vitrine.
- **F-048:** este plano, como aprovado (lição da TASK-4).
- **Uma linha de correção no `mudancas.md`:** a linha de 07/10 citava F-045 e F-046 para os "500 MB", e a fonte certa é a F-047.

## 2. O código, pelo implementer

- **`export_presets.cfg`** com os dois presets da sonda (F-045 §2), sem a cena de sonda, saindo em `build/`, que o git ignora.
- **A versão:** `application/config/version="0.0.0"` no `project.godot`, logo depois do nome, na ordem em que o editor grava.
  - O 0.0.0 diz "nada lançado ainda". O 0.1.0 entra no commit que fecha o esqueleto andante, com a tag `v0.1.0` (F-046 §2).
  - O `application/config/commit` não entra no repositório: o job de build da TASK-9 o carimba na hora do export.
- **As guardas**, cada uma provada por uma sonda que a quebra:
  - no `test/project_settings_test.gd`: a versão tem três números, só dígitos e pontos, porque com outra coisa o .exe cai para 1.0.0.0 (F-047 §1.5). O cabeçalho do arquivo passa a citar a DEC-0028.
  - num teste novo, `test/export_presets_test.gd`: os dois presets existem, com nome, plataforma, servidor dedicado no do servidor, PCK embutido e as quatro exclusões (`test/*`, `addons/gdUnit4/*`, `tools/*`, `reports/*`). Ele lê o `export_presets.cfg` com `ConfigFile`, porque o Godot não tem API de presets em tempo de execução. É arquivo de configuração, como o `project.godot`, e não código-fonte; a DEC-0027 registra a exceção.
- **As referências vivas à DEC-0006** passam para a DEC-0027 ou a DEC-0028: `tools/gate.sh`, `tools/run_tests.sh`, `lefthook.yml`, `.github/workflows/ci.yml`, `.gitattributes`, `README.md` e o glossário. As históricas (diário, mudanças, Q-03) ficam.
- **A prova do export, a partir deste repositório:** um `--export-pack` de cada preset, com código de saída, tempo e a lista do pacote (sem `test/`, gdUnit4, `tools/` e `reports/`), anotada na task. A build ainda não roda nada, porque falta a Main (TASK-9).
- **O portão verde**, com os passos e os tempos.

## 3. As DECs (critério 2)

**DEC-0027 — Testes e entrega.** Substitui a DEC-0006 inteira e repete o que dela continua: o gdUnit4 6.2.1, o pre-commit abaixo de 15 s, o pre-push abaixo de 90 s, o LFS e o "nunca `--no-verify`".
- **O portão:** formato e lint, pureza com canários, travas, import, compilar tudo com canários e testes com `-c`; um portão verde não tem `ERROR:` no log. O pre-push e o CI rodam o mesmo portão; nos PRs e nas tags, o CI roda também os jobs de build da DEC-0028.
- **As cinco camadas:** o que cada uma pega, onde roda e quando nasce. Só o que foi medido leva número (a SyncTest pelo relógio e o replay, F-042); o resto diz "sem medida; mede-se na TASK-9".
- **A SyncTest com os ticks à mão**, como a suíte do netfox. É uma exceção escrita à regra de testar só por interface pública: ela chama funções internas do netfox, que está fixado no `cf5189d`. Atualizar o netfox já é uma DEC nova, com a SyncTest refeita (F-044 §2).
- **O que não cabe nos 90 s** vira um job do CI fora do pre-push, com uma DEC.
- **O replay, detalhe da DEC-0011:**
  - por inputs aplicados pelo servidor, com a gravação desde a fase 1;
  - o cabeçalho e as invariantes; roda na mesma build;
  - Windows e Linux bateram (F-042 §5). Se um dia divergirem, a referência vale só no Linux, como a DEC-0011 já previa; é escolha deste plano (F-048).
- **Os hooks do Claude Code:** a trava e o formatador; o Bash fica sem guarda por enquanto (F-039); o sha256 do portão é a trava de verdade (F-040; F-047 §2).
- **Escolhas deste plano (F-048):** a checagem dos dados nasce com o primeiro `.tres` de design; o teste de fumaça da build nasce na TASK-9, com a Main.

**DEC-0028 — Builds, versões e fluxo de branch.**
- **Os presets e os templates** (F-045; F-047 §1). O ícone e a versão do .exe são escritos pelo próprio Godot, sem rcedit, desde o 4.5 (F-047 §1.5).
- **Quando a build sai:** no PR (3 dias) e na tag (release); o push na main não gera build. A conta da cota vem da F-047 §1.1 e da F-045 §3.
- **Os riscos do export, nas Consequências:**
  - o #123712 não apareceu em quatro exports (F-045 §3). Se aparecer no job da TASK-9, o job confere o artefato e o teste de fumaça, e não só o código de saída.
  - o import roda antes do export, o que evita o #1324 do gdUnit4 (F-047 §1.6).
- **As versões e o procedimento:**
  - o `y` sobe no commit que fecha um marco do roteiro; o `z` sobe a cada build que sai com tag para alguém jogar;
  - quem sobe é o Claude, no commit da tag, com o seu ok;
  - fica 0.0.0 até o esqueleto andante.
- **O fluxo e o worktree.** A TASK-6 fecha na main, e a primeira branch é a da próxima task.
- **Os ambientes:** o seu PC, o CI, a build de teste e o servidor.

**No índice das DECs:**
- as duas novas em Vigentes;
- a DEC-0006 no Histórico, com a nota de que a DEC-0027 repete o que dela continua. Na DEC-0006 mudam só `status`, `substituida_por` e o aviso no topo;
- a DEC-0009 e a DEC-0011 seguem `aceita`, com a nota "completada pela DEC-0027" no índice.

## 4. O documento (critério 1)

- **`docs/arquitetura/testes-e-entrega.md`**, com a fonte de cada número, em onze seções:
  1. a esteira;
  2. o portão;
  3. as camadas;
  4. o replay;
  5. os ambientes;
  6. as builds, com a conta da cota e os riscos do export;
  7. as versões;
  8. o fluxo e o worktree;
  9. os hooks;
  10. as medições;
  11. o que fica para depois.

  Ele diz com todas as letras que a build ainda não roda nada até a Main (TASK-9) e que o conteúdo do pacote foi listado só neste PC, não no CI.
- **Atualizações:** o índice da arquitetura; a `visao-geral.md` (o furo do portão fechou); o `rede.md` (a SyncTest com os ticks à mão e o aperto de mão na Main); o `roteiro.md` (a gravação do replay na fase 1).

## 5. As instruções da harness

**`AGENTS.md`.** Hoje tem 12.029 caracteres; o alvo é até ~12.300.

Entra:
- o fluxo de branch e PR e o worktree (DEC-0028, três linhas);
- os hooks (DEC-0027, uma linha);
- a exceção da SyncTest na regra dos testes;
- os canários e o log limpo, na linha do portão;
- perguntar "o que você sentiu?" depois de tudo que você joga ou olha (F-041);
- quando a conferência falha, explicar de novo nomeando a ideia errada (F-038).

Sai, sem perder regra (tudo continua em `docs/` ou na DEC citada):
- os parágrafos das DEC-0017, DEC-0019 e DEC-0021, encurtados para uma frase cada;
- a seção da máquina, enxugada, ganhando o "use `python`, nunca `python3`";
- as redundâncias do projeto e do "Arthur pensa em voz alta".

**`.claude/agents/reviewer.md`**, duas checagens novas:
- a citação (F-xxx) contém o que afirma. Já falhou três vezes: na TASK-4, na TASK-5 e agora no `mudancas.md`;
- a exceção da SyncTest na regra dos testes.

**`.claude/harness/README.md`:** os hooks.

## 6. O resto do registro

- **`docs/pendencias.md`, Q-20:** quem testar de fora pode esbarrar no Smart App Control, que já barrou o `backlog.exe` neste PC (F-031). Um .exe sem assinatura costuma cair também no SmartScreen; isso é inferência do agente. Resolve-se no Desenho 6, ou antes de amigos testarem na fase 2.
- **O glossário:**
  - termos novos: referência, números congelados, preset de export, template de export, pacote `.pck`, feature tag, artefato, release, versão, carimbo do commit, aperto de mão, branch da task, PR, merge commit e worktree;
  - o "Portão" passa a citar a DEC-0027.
- **A TASK-9:** um comentário com o que ela herda: o job de build no PR e na tag, os riscos do export, o 0.1.0 com a tag, o aperto de mão e o teste de fumaça. O critério 3 dela é refeito quando ela ficar Ready.
- **Depois do reviewer:** o `mudancas.md`, o registro da harness e o diário da sessão 7.
- **A vitrine,** republicada se algum número mudar.

## Verificação

- **O reviewer,** de contexto limpo, julga os 8 critérios e as regras. Da definição de pronto, o item "teste para toda regra do núcleo" não se aplica, porque não há código em `core/`.
- **O portão num clone limpo:** `bash tools/gate.sh` verde, com as linhas finais coladas.
- **As sondas das guardas novas:** a versão com sufixo e um preset sem as exclusões fazem o portão falhar.
- **O push,** com a sua permissão.
