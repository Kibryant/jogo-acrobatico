---
id: DEC-0027
titulo: Testes e entrega — o portão com canários e log limpo, as cinco camadas com quando nascem, a SyncTest à mão, o replay por inputs e os hooks do Claude Code
data: 2026-10-07
status: aceita
decidido_por: Arthur
fontes: [F-007, F-009, F-010, F-021, F-038, F-039, F-040, F-041, F-042, F-043, F-044, F-047, F-048, F-049]
substitui: DEC-0006
substituida_por:
---

# DEC-0027 — Testes e entrega: o portão com canários e log limpo, as cinco camadas com quando nascem, a SyncTest à mão, o replay por inputs e os hooks do Claude Code

## Contexto

A DEC-0006 escolheu o gdUnit4, as cinco camadas de teste e o mesmo portão no pre-push e no CI, e deixou o resto "a confirmar no Desenho 4 (TASK-6)". A DEC-0009 adiou para cá os hooks do próprio Claude Code. A DEC-0011 adiou para cá o detalhe do replay.

Três checagens já tinham deixado passar erro em sondas:
- o glob do lefthook, consertado na sessão 2 (registro da harness);
- o `#` dentro de string, que escondia código da pureza (F-010 §2);
- o script que nenhum teste carrega, que chegava verde ao fim do portão (F-021).

O registro da harness pediu um autoteste das checagens já na TASK-1.

O Desenho 4 rodou em três rodadas:
- **Rodada 1:** os consertos, os canários e os hooks, provados nesta sessão e numa sessão nova (F-039; F-040).
- **Rodada 2:** o replay jogado de verdade, o Linux e o custo da SyncTest (F-042 a F-044).
- **Rodada 3:** as builds, as versões e o fluxo, que estão na DEC-0028.

O fechamento foi aprovado no modo de plano (F-048).

## Opções consideradas

1. **Confirmar a DEC-0006 como estava.** Não cobre os furos, o replay nem os hooks.
2. **Uma DEC nova, que substitui a DEC-0006 inteira e repete o que dela continua.** Foi a escolhida (F-048).
3. **Várias DECs pequenas,** uma por peça. Mais arquivos para a ordem de leitura do `AGENTS.md`.

## Decisão

### 1. O portão

O `tools/gate.sh` roda, nesta ordem, e para na primeira falha:
1. formato e lint;
2. a pureza do núcleo, com os canários;
3. as travas dos testes de aceite;
4. o import;
5. compilar tudo, com os canários;
6. os testes.

O que vale para ele:
- **O mesmo portão no pre-push e no CI,** abaixo de 90 s. Em 04/10, depois da rodada 1, ele levava 31 s (F-039, contexto; F-049 §5).
- **O CI roda também** o gitleaks no histórico inteiro. Nos PRs e nas tags, roda os jobs de build da DEC-0028.
- **O pre-commit fica abaixo de 15 s,** com o gitleaks, o formato e a pureza.
- **Continuam da DEC-0006:**
  - o gdUnit4 6.2.1, fixado em `addons/gdUnit4`;
  - o lefthook gerenciando os hooks do git;
  - arte, áudio, fontes e vídeo pelo Git LFS;
  - nunca `--no-verify`.
- **Os canários** (`tools/canaries/`) são arquivos com erro de propósito. A pureza e a compilação precisam barrá-los em toda rodada. Se uma checagem perder uma regra, o canário dela falha (F-039, contexto).
- **O log limpo:** se os testes passam, mas o log tem uma linha `ERROR:`, `SCRIPT ERROR:` ou `USER ERROR:`, o portão reprova. O Arthur escolheu "Mantém, reprova (Recomendado)" (F-039 §2).
- **O gdUnit4 roda com `-c`** (`--continue`, F-047 §1.8) e mostra todas as falhas de uma vez. O truque do `--remote-debug` saiu, porque sem o `-d` não existe depurador para travar (F-039, contexto; F-049 §4).

### 2. As cinco camadas de teste

Cada camada pega um tipo de erro (F-007 §7).

| Camada | Pega o quê | Onde roda | Nasce | Quanto gasta |
|---|---|---|---|---|
| 1. A especificação | A regra do núcleo diferente do papel | portão | TASK-9, com a primeira regra em `core/` | sem medida; mede-se na TASK-9 |
| 2. A SyncTest | Estado escondido: refazer um tick dá outro resultado | portão | TASK-9 (DEC-0025): rampa, beirada, pouso e empurrão, com os ticks à mão (§3) | pelo relógio do netfox, cada cenário custa o tempo de jogo dele: 5 s de rampa, 6,3 s de portão (F-042 §1); à mão, sem medida; ela precisa caber com folga no portão (F-044 §2) |
| 3. A checagem dos dados | Um número impossível num `.tres` | portão | com o primeiro `.tres` de design (F-048) | sem medida |
| 4. O replay como referência | Uma mudança de código que altera o movimento sem querer, como o snapshot do Jest | portão e CI | TASK-9: um percurso de bot, com números do movimento congelados, só do teste, e o hash conferido no Windows e no Linux (F-044 §2) | 1.200 ticks em 11 a 13 ms (F-042 §3) |
| 5. A rede à mão | A sensação com lag | o Arthur, jogando | TASK-9, e de tempos em tempos (DEC-0026) | o tempo dele, e o que ele sentiu (F-041) |

Mais as checagens que já existem ou vêm junto:
- **A guarda das configurações:** existe desde o Desenho 2.
- **Compilar tudo e os canários:** da rodada 1 (F-039).
- **O teste de fumaça da build:** o servidor exportado sobe e fecha com código 0. Nasce na TASK-9, com a Main (F-048).

### 3. A SyncTest com os ticks à mão

- **Pelo relógio do netfox, a SyncTest custa o tempo real.** O `--fixed-fps` não acelera, porque o relógio dele segue o tempo de verdade. Os quatro cenários somariam uns 25 s de portão (F-042 §1; F-044 §2).
- **A da TASK-9 avança os ticks à mão,** como a suíte do próprio netfox (`test/network-mocks.gd`), rodando o rollback de verdade dele (F-044 §2).
- **É uma exceção escrita à regra de testar só por interface pública:** ela chama funções internas do netfox.
- **A exceção é segura** porque o netfox está fixado no `cf5189d` (DEC-0023). Atualizar o netfox já é uma DEC nova, e com ela a SyncTest é refeita (F-044 §2).

### 4. O que não cabe nos 90 s

Vira um job do CI fora do pre-push, com uma DEC nova (F-044 §2).

### 5. O replay por inputs (o detalhe da DEC-0011)

- **O arquivo guarda o input que o servidor aplicou** em cada tick, e não o vídeo.
- **Para assistir, o jogo roda a partida de novo** na mesma build (F-044 §2).
- **O cabeçalho leva:** formato, versão, commit, plataforma, ticks por segundo, arena, semente e configuração (F-044 §2).
- **O que precisa ser verdade desde já** (F-044 §2):
  - todo sorteio tem semente e mora no estado;
  - o núcleo não lê relógio (DEC-0004);
  - a build carrega a versão.
- **A gravação começa na fase 1,** para reproduzir sem tela o bug de movimento que o Arthur achar jogando (F-044 §1).
- **Na mesma build, o replay se repete byte a byte,** com e sem janela, num laço ou um tick por quadro (F-042 §3).
- **Windows e Linux bateram** nas seis comparações (F-042 §5). Se um dia divergirem, a referência vale só no Linux, como a DEC-0011 já previa (F-048).

### 6. Os hooks do Claude Code

- **A trava** (PreToolUse, em `Edit|Write|MultiEdit|NotebookEdit`): nega a edição de um arquivo listado em `.claude/harness/locks/*.sha256`, também para um subagente. Provada nesta sessão e numa sessão nova, no modo sem permissões (F-040).
- **O formatador** (PostToolUse): formata o `.gd` nosso logo depois de salvar (F-040).
- **A escrita pelo Bash fica sem guarda por enquanto.** O Arthur escolheu "Não, por enquanto (Recomendado)" (F-039 §2). No Windows, o Claude Code não tem caixa de areia (F-047 §2).
- **A trava de verdade continua sendo o sha256** conferido no portão.

### 7. Um teste pode ler arquivo de configuração

- A regra de não ler código-fonte num teste segue valendo.
- Um arquivo de configuração sem API em tempo de execução, como o `export_presets.cfg`, pode ser lido num teste com `ConfigFile` (F-048).

## Consequências

- O furo da pureza e o da compilação estão fechados, e os canários vigiam os dois em toda rodada (F-039).
- Um `push_error` do nosso código durante os testes derruba o portão. Um teste que espera um erro vai precisar de um jeito explícito de dizer isso, quando aparecer (F-039 §2).
- O formato, o lint, as travas, o import e o log limpo ainda não têm canário (TASK-6, notas da rodada 1).
- **A TASK-9 herda:** a SyncTest à mão, a referência, a checagem dos dados e o teste de fumaça.
- **A TASK-10 herda o gravador do replay** (F-044 §1).
- A DEC-0009 fica completada nos hooks, e a DEC-0011 fica detalhada no replay. As duas seguem valendo.

## Revisitar se

- O portão passar de 90 s, ou o pre-commit passar de 15 s.
- A SyncTest à mão não couber com folga no portão, ou uma versão nova do netfox mudar as funções internas que ela usa.
- O mesmo replay divergir entre o Windows e o Linux.
- Um agente contornar a trava pela escrita no Bash.
- Um teste precisar esperar um erro no log.
