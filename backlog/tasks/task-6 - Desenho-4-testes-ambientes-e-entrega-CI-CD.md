---
id: TASK-6
title: 'Desenho 4: testes, ambientes e entrega (CI/CD)'
status: Ready
assignee: []
created_date: '2026-10-02 16:48'
updated_date: '2026-10-04 18:48'
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
Quarta conversa da fase de desenho (DEC-0012). A base já tem portão, hooks do git e um CI mínimo, mas a DEC-0006 ficou "a confirmar no Desenho 4", e três checagens já deixaram passar erro em sondas: o glob do lefthook, já consertado (registro da harness), o `#` dentro de string na pureza (F-010 §2) e o script que nenhum teste carrega (F-021). Faltam o desenho das camadas de teste, das builds, das versões e do fluxo de branch, os hooks do próprio Claude Code (DEC-0009) e o detalhe do replay (DEC-0011).

Vitrine da esteira, privada (DEC-0019): https://claude.ai/artifact/L9FpEtDFoyGJYWLSR6TFA1

### Perguntas em aberto
A pauta da conversa: cada item sai com resposta, DEC ou pendência.

Rodada 1, o portão e a harness, com a mão na massa:
- O furo da pureza: um `#` dentro de string esconde o resto da linha (comentário #1). Strings de três aspas ocupam várias linhas, e a sonda precisa delas.
- O furo da compilação: o portão só compila o script que algum teste carrega (comentário #3). Compilar todos numa execução só levou 1,3 s na sonda de 02/10, antes do netfox (F-021).
- Os dois ruídos: as duas linhas `ERROR:` do `--remote-debug` em todo teste (comentário #2) e o gdUnit4 que para no primeiro teste vermelho. A opção `-c` (`--continue`) existe no 6.2.1 (`GdUnitTestCIRunner.gd`).
- A peneira da peneira: um autoteste que passe sondas pelos caminhos reais do hook e do portão, pedido pelo registro da harness (TASK-1).
- Os hooks do Claude Code: travar teste de aceite e formatar depois de editar, provados numa sessão real nesta máquina (DEC-0009). Pela documentação lida em 04/10, a negação vale até no modo sem permissões e nos subagentes, uma escrita pelo Bash não passa pelo hook de Edit, e no Windows não há sandbox. Aqui o `python3` é o atalho da Microsoft Store; só o `python` funciona.
- O tempo do portão: 28 s de 90 em 04/10, dos quais 17,7 s são o `--import` e 7,6 s os testes (0,5 s de teste; o resto é o Godot subindo).

Rodada 2, as camadas e o replay:
- Abre com o replay por inputs rodando de verdade no Godot: as mesmas teclas, tocadas com outra regra, levam o boneco a outro lugar. A conferência errou duas vezes ao deixar a task Ready (F-038).
- As camadas de teste: o que cada uma pega, onde roda, quando nasce e quanto do portão pode gastar (F-007 §7; DEC-0006). O que não cabe nos 90 s roda onde?
- A referência por replay entre Windows e Linux: o float difere entre as plataformas (F-007 §6).
- O replay por inputs, re-rodado no servidor (DEC-0011): o que proteger desde já, o formato e quando a gravação começa.

Rodada 3, build, versões e fluxo:
- Os ambientes: o editor e o portão no PC do Arthur, o CI no Linux e a build de teste.
- As builds: os presets do cliente Windows e do servidor Linux sem tela, o que fica fora (`test/`, o gdUnit4), os templates e quando a build sai, dentro da cota do plano Free: 2.000 min por mês e 500 MB divididos entre artefatos e pacotes; uma dupla de builds compactada pesa ~66 MB, e o artefato fica 90 dias se ninguém disser outra coisa.
- Os riscos do export no 4.7.2: no Linux, o Godot cai ao sair depois de exportar, com código 134 (#123712); o gdUnit4 derruba o primeiro export feito sem a pasta `.godot` (gdUnit4 #1324).
- As versões: SemVer, tags, notas de release, o commit carimbado na build e o aperto de mão entre cliente e servidor. O `.exe` só aceita dígitos e pontos na versão.
- Branch e PR: a task abre e fecha no PR, como no YabaBuss? O plano Free não aplica regra de branch (Q-03). E o worktree, porque duas sessões já dividiram a mesma pasta duas vezes (registro da harness).

### Escolhas confirmadas
Confirmadas pelo Arthur em 04/10 (F-038 §2 a §4):
- A pauta em três rodadas, com o que o registro da harness mandou para cá: os dois ruídos do portão, a peneira da peneira e a regra do worktree.
- Os hooks do Claude Code no `.claude/settings.json` do projeto, versionados e valendo para toda sessão e todo subagente. Os scripts, em bash, leem o JSON com o Python que já está instalado: o `jq` seria ferramenta nova, e o portão continua sem Python. A prova é uma sessão real nesta máquina tentando editar um teste travado e salvar um `.gd` fora do formato.
- A build provada numa sonda: os templates do 4.7.2 neste PC, só Windows e Linux, pelo baixador do editor (~128 MB de download e ~360 MB no disco, em vez de 1,28 GB); os dois presets exportados de verdade, com tamanho e tempo medidos; e uma branch de sonda no CI, com PR em rascunho fechado e apagado depois, como na TASK-2, cada push pedindo permissão. O `export_presets.cfg` entra no repositório; o job de build de verdade entra no CI no esqueleto andante (TASK-9, critério 3), já com o jogo.
- O replay fica no papel: o que proteger desde já, o formato e quando a gravação começa. O código nasce com a primeira necessidade.
- O fluxo de partida: trunk-based, com branch curta por task e PR. A DEC sai na rodada 3; até lá, o commit segue direto na main, como hoje.

### Fora do escopo
- O deploy do servidor (Desenho 6, TASK-8, e o esqueleto andante).
- O job de build de verdade no CI, a Main e o teste de fumaça do servidor exportado: TASK-9.
- O código do replay.
- Assinar o `.exe`, a Steam e a loja: Desenho 6 e fase 5.
- Testes de rede automatizados com netem: só se doer (F-007 §7).

### O que você vai aprender
- Como um jogo é empacotado: o template de export, o `.pck`, as feature tags, e por que o servidor sai sem gráficos.
- O que cada camada de teste pega, e por que o snapshot do Jest é o "replay como referência" do jogo.
- Por que um replay por inputs só roda na build em que foi gravado, e por que cliente e servidor precisam estar na mesma versão.
- Como os hooks do Claude Code vigiam o próprio agente, e onde eles param.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando a conversa termina, `docs/arquitetura/testes-e-entrega.md` mostra as camadas de teste (o que cada uma pega, onde roda, quando nasce e quanto do portão gasta), os ambientes, o que o CI roda, as builds com a conta da cota do plano Free, as versões, o fluxo de branch e o replay por inputs, com a fonte de cada número.
- [ ] #2 Quando o Arthur decide as camadas, o fluxo de branch e as versões, DECs registram, e a DEC-0006 é confirmada ou substituída no que mudou.
- [ ] #3 Quando um `#` dentro de uma string, de aspas simples, duplas ou triplas, esconde código proibido em `core/`, `tools/check_core_purity.sh` falha; quando o `#` abre um comentário de verdade, o texto depois dele segue ignorado; uma sonda prova o antes e o depois.
- [ ] #4 Quando um script nosso tem erro de tipo ou acesso inseguro e nenhum teste o carrega, o portão falha; quando todos compilam, o passo fica verde e o tempo dele fica registrado; uma sonda prova o antes e o depois.
- [ ] #5 Quando um ou vários testes falham, o portão mostra todas as falhas da rodada; quando todos passam, o log do portão não tem linha `ERROR:`.
- [ ] #6 Quando uma checagem do portão deixa de barrar o erro que barrava, o autoteste das checagens falha.
- [ ] #7 Quando um hook do Claude Code entra, ele foi testado numa sessão real nesta máquina: a edição de um teste travado é negada pelo Edit e pelo Write, na conversa principal e num subagente; um `.gd` salvo fora do formato sai formatado; e o resultado está no registro da harness.
- [ ] #8 Quando os dois presets exportam, neste PC e numa branch de sonda no CI, saem o cliente Windows e o servidor Linux sem tela, sem `test/` nem o gdUnit4 dentro, com tamanho e tempo registrados; quando o Godot cai ao sair depois do export (#123712), a sonda registra, e o `testes-e-entrega.md` traz o contorno.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Rodada 1, o portão e a harness:
   - As sondas dos furos dos critérios 3 e 4 numa cópia fora do projeto, com o antes registrado; o conserto; o depois.
   - Os dois ruídos: o `-c` no `tools/run_tests.sh` e as linhas `ERROR:` do `--remote-debug`.
   - A peneira da peneira: arquivos com erro de propósito que cada checagem precisa barrar, rodando no portão.
   - Os hooks em `.claude/settings.json` e `.claude/hooks/`, provados nesta sessão e numa sessão nova, com o resultado no registro da harness.
   - O tempo do portão medido de novo, passo a passo; a vitrine republicada e as perguntas da rodada.
2. Rodada 2, as camadas e o replay:
   - A conferência do replay com ele rodando no Godot, numa sonda fora do projeto: gravar as teclas, mudar o pulo, tocar de novo.
   - A tabela das camadas: o que pega, onde roda, quando nasce e quanto do portão gasta; o que não cabe nos 90 s.
   - A referência entre Windows e Linux; o replay no papel; a vitrine e as perguntas.
3. Rodada 3, build, versões e fluxo:
   - Os templates de Windows e Linux pelo baixador do editor; os dois presets exportados neste PC, com tamanho e tempo.
   - A branch de sonda no CI, com PR em rascunho, cada push com permissão: o download dos templates, o cache, o export e o #123712.
   - A cota, as versões, o aperto de mão, o fluxo de branch e o worktree; a vitrine e as perguntas.
4. O plano no modo de plano, revisado antes por um agente de planejamento (registro da TASK-5). Com o ok: uma fonte com o plano, as DECs, o `docs/arquitetura/testes-e-entrega.md`, o `export_presets.cfg` com guarda no teste de configurações e o resto pelo implementer; o `AGENTS.md` acompanha o que mudar.
5. Registro: fontes, glossário, `mudancas.md`, `pendencias.md` e o registro da harness; depois o reviewer e o portão num clone limpo.
<!-- SECTION:PLAN:END -->

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

author: Claude
created: 2026-10-02 22:40
---
Furo achado na sessão 3 (02/10/2026, TASK-4), com sondas num clone fora do projeto (F-021; DEC-0022):
- Um `var count = 5` e um `node.velocity` num `Node`, os dois em `core/`, passaram com o portão verde, mesmo com os avisos configurados como erro. O `--import` não analisa a fundo um script que ninguém carrega.
- `godot --headless --check-only -s <arquivo>` pega os dois e ignora os addons, mas custa 1,2 s por arquivo e não escala.
- Carregar todos os nossos scripts numa execução só do Godot (`ResourceLoader.load` mais `can_instantiate`) pegou os dois em 1,3 s no total.
- O Arthur decidiu consertar aqui, antes de qualquer código de jogo (F-021 §1).
---
<!-- COMMENTS:END -->
