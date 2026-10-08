---
revisado_em: 2026-10-08
fontes: [F-007, F-009, F-010, F-021, F-038, F-039, F-040, F-041, F-042, F-043, F-044, F-045, F-046, F-047, F-048, F-049]
---

# Testes e entrega

Estado atual: o Desenho 4 (TASK-6) fechado, com as DEC-0027 e DEC-0028. Nenhum código de jogo existe ainda.

- O portão, os canários e os hooks do Claude Code já rodam.
- As camadas de teste do jogo, o job de build e o aperto de mão nascem no esqueleto andante (TASK-9).
- O gravador do replay nasce na fase 1 (TASK-10).
- A versão visual e interativa deste documento é a vitrine [A esteira por dentro](https://claude.ai/artifact/L9FpEtDFoyGJYWLSR6TFA1), privada (DEC-0019).

## 1. A esteira

O caminho de uma mudança até o jogo na mão de quem joga, com uma checagem em cada estação. Os tempos foram medidos neste PC (Ryzen 3 PRO 3200G) e no GitHub.

| Estação | O que confere | Tempo |
|---|---|---|
| O Claude edita | Os hooks: a trava do teste de aceite e o formatador (§9) | 0,2 a 0,8 s por hook; um `.gd` passa pelos dois (F-049 §6) |
| `git commit` | O pre-commit: gitleaks, formato e pureza | de 0,8 a 2,9 s nos commits, quase tudo o gitleaks (F-049 §2), de um teto de 15 (DEC-0027) |
| `git push` | O pre-push: o portão inteiro (§2) | 31 s, de um teto de 90 (F-049 §5) |
| O CI no GitHub | O gitleaks no histórico e o mesmo portão; no PR e na tag, as duas builds | 21 a 29 s só com o portão, antes da rodada 1 (F-038, contexto); o job de export, de 57 a 83 s (F-045 §3) |
| A build | O cliente Windows e o servidor Linux (§6) | Nasce na TASK-9 |
| Quem joga | A versão certa, conferida na conexão (§7) | Nasce na TASK-9 |

## 2. O portão (DEC-0027 §1)

O `tools/gate.sh` é o mesmo no pre-push e no CI. Ele para na primeira falha.

| Passo | O que pega | Tempo em 04/10, neste PC |
|---|---|---|
| Formato e lint | Código fora do formato do `gdscript-formatter` 0.27.0 | 0,6 s |
| Pureza do núcleo | Nó, relógio, timer ou sorteio sem semente em `core/`; o `#` dentro de string não esconde mais nada | 0,4 s |
| Assets e LFS | Um pack de terceiros sem linha no `CREDITS.md` ou sem o arquivo de licença, um arquivo solto, ou um formato da lista fora do LFS, provado pelo `git check-attr` (DEC-0029) | menos de 1 s (08/10) |
| Travas | Um teste de aceite travado que mudou | 0,2 s |
| Import | Um erro ao importar o projeto | 15,7 s (em outras rodadas, de 9,7 a 17,7 s; F-049 §1 e §5) |
| Compilar tudo | Um erro de tipo num script que nenhum teste carrega | 3,9 s |
| Testes | Uma falha, um erro, ou uma linha `ERROR:` no log com tudo verde | 9,7 s |

Os tempos são os da rodada B depois dos consertos (F-049 §5). O total foi 31,3 s; antes da rodada 1, era 28,3 s (F-049 §1).

- **Os canários** (`tools/canaries/`) são arquivos com erro de propósito: 9 para a pureza, 5 para os assets e 3 para a compilação. Se uma checagem perder uma regra, o canário dela falha. A prova: estragadas de propósito, as duas checagens fizeram os canários gritarem (F-039, contexto; F-049 §5).
- **O log limpo:** testes verdes com uma linha `ERROR:` reprovam. O bug #659 do netfox se escondeu assim no Desenho 3: saída 0, erro só no log (F-039 §2).
- **O `-c`:** o gdUnit4 mostra todas as falhas de uma vez, e não só a primeira (F-047 §1.8).
- **Sem o `--remote-debug`:** sem o `-d`, o Godot não tem depurador para travar num erro de sintaxe. A sonda mostrou a saída 105 em 7,1 s e as falhas relatadas como antes (F-049 §4).
- **Ainda sem canário:** o formato, o lint, as travas, o import e o log limpo (TASK-6, notas da rodada 1).

## 3. As camadas de teste (DEC-0027 §2)

| Camada | Pega o quê | Onde roda | Nasce | Quanto gasta |
|---|---|---|---|---|
| 1. A especificação | A regra do núcleo diferente do papel; o teste de unidade do Jest para função pura | portão | TASK-9 | sem medida |
| 2. A SyncTest | Estado escondido: refazer um tick dá outro resultado (DEC-0025) | portão | TASK-9, com os ticks à mão | pelo relógio, ~6 s por cenário de 5 s (F-042 §1); à mão, sem medida |
| 3. A checagem dos dados | Um número impossível num `.tres` | portão | com o primeiro `.tres` de design (F-048) | sem medida |
| 4. O replay como referência | Uma mudança de código que muda o movimento sem querer; o snapshot do Jest | portão e CI | TASK-9 | 1.200 ticks em 11 a 13 ms (F-042 §3) |
| 5. A rede à mão | A sensação com lag | o Arthur | TASK-9, e de tempos em tempos (DEC-0026) | o tempo dele, e o que ele sentiu (F-041) |
| A guarda das configurações | Uma configuração decidida que voltou atrás | portão | desde o Desenho 2 | dentro dos testes |
| Compilar tudo e os canários | §2 | portão | rodada 1 (F-039) | ~4 s e menos de 1 s (F-049 §5) |
| O teste de fumaça da build | O servidor exportado não sobe, ou não fecha com código 0 | CI | TASK-9, com a Main (F-048) | sem medida; na sonda, ele subiu e fechou com código 0 (F-045 §3) |

**A SyncTest com os ticks à mão.**
- Pelo relógio do netfox, cada cenário custa o tempo de jogo dele, e o `--fixed-fps` não acelera (F-042 §1).
- A SyncTest da TASK-9 avança os ticks como a suíte do próprio netfox faz em `test/network-mocks.gd`: chama `NetworkTime._before_tick_loop()`, os sinais do tick e `_after_tick_loop()`. Assim ela roda o rollback de verdade dele sem esperar o relógio.
- É a exceção escrita à regra de testar só por interface pública. O netfox está fixado no `cf5189d` (DEC-0023), e atualizá-lo já é uma DEC nova, com a SyncTest refeita (F-044 §2).

**A referência (golden master).**
- É um percurso de bot gravado como replay, com o hash do caminho conferido no portão, no Windows, e no CI, no Linux.
- Ela usa uma cópia congelada dos números do movimento, só do teste. O ajuste fino do jogo não quebra a referência; só uma mudança de código quebra.
- Regravar é um comando, como o `jest -u`, e o commit diz por quê (F-044 §2).

**O que não cabe nos 90 s** vira um job do CI fora do pre-push, com uma DEC nova (DEC-0027 §4).

## 4. O replay por inputs (DEC-0027 §5)

É event sourcing: guarda o input de cada tick, e não o vídeo. Para assistir, o jogo roda a partida de novo.

- **O que entra no arquivo:**
  - um cabeçalho com formato, versão, commit, plataforma, ticks por segundo, arena, semente e configuração (F-044 §2);
  - o input que o servidor aplicou em cada tick.
- **O que precisa ser verdade desde já** (F-044 §2):
  - todo sorteio tem semente e mora no estado;
  - o núcleo não lê relógio (DEC-0004);
  - a build carrega a versão.
- **Só reproduz na mesma build.** A mesma tecla, com outra regra, leva o boneco a outro lugar. Na sonda, com o pulo trocado de 1,2 para 0,6 m, as duas jogadas do Arthur se separaram exatamente no tick do primeiro pulo e chegaram a 15 m de distância (F-042 §4).
- **Na mesma build, ele se repete byte a byte:** com e sem janela, num laço ou um tick por quadro, em processos diferentes (F-042 §3).
- **No Windows e no Linux:** os seis replays deram o mesmo sha256 (F-042 §5). Vale para a cápsula de hoje; seno, cosseno e física com vários corpos não passaram por essa prova. Se um dia divergirem, a referência vale só no Linux (DEC-0011; F-048).
- **O tamanho:** uns 4 bytes por tick em texto, com dois campos (F-042 §2). Com o input completo da fase 3 (`rede.md` §3), seriam uns 19 bytes por lutador por tick, sem compressão: `move` 8, `yaw` 4, `pitch` 4, os dez botões 2 e o `view_lag` 1 (estimativa do agente).
- **Quando a gravação começa:** na fase 1, para o Claude refazer sem tela o pulo exato em que o Arthur achou um bug (F-044 §1).
- **Para que mais serve:**
  - a referência (§3);
  - rever denúncia contra trapaça (Q-19);
  - o fantasma do percurso cronometrado e o replay que marca o erro (`visao.md`).

## 5. Os ambientes (DEC-0028 §5)

| Ambiente | O que roda ali |
|---|---|
| O PC do Arthur | O editor, o portão local e as sondas, fora do repositório (`../netfox-sonda`, `../replay-sonda`, `../export-sonda`) |
| O CI no GitHub (Linux, `ubuntu-24.04`) | O portão; no PR e na tag, as duas builds |
| A build de teste | O artefato do PR, por 3 dias, ou a release da tag |
| O servidor de verdade | Desenho 6 (TASK-8) |

O endereço do servidor vem dos argumentos da Main (DEC-0026).

## 6. As builds (DEC-0028 §1 e §2)

**Os dois presets, no `export_presets.cfg`:**

| Preset | Plataforma | O que tem | Tamanho medido |
|---|---|---|---|
| Cliente Windows | Windows Desktop, x86_64 | PCK embutido; ícone e versão do `.exe` escritos pelo Godot, sem rcedit (F-047 §1.5) | 109 MB (F-045 §2) |
| Servidor Linux | Linux, x86_64 | PCK embutido; servidor dedicado, com a feature tag `dedicated_server` e sem a parte visual (F-047 §1.6) | 74 MB (F-045 §2) |

- **O que fica fora:** `test/*`, `addons/gdUnit4/*`, `tools/*` e `reports/*`. Neste PC, o pacote do jogo teve 163 arquivos (~216 kB), sem nenhum desses (F-045 §2). No CI, o conteúdo do pacote não foi listado.
- **Hoje a build não roda nada:** falta a Main, que nasce na TASK-9. A sonda usou uma cena própria, que imprimia a versão e o commit (F-045 §2).
- **Os templates:**
  - neste PC, só os de Windows e Linux, baixados pelo editor: 344 MB no disco, contra 1,28 GB do pacote inteiro (F-045 §1);
  - no CI, o `setup-godot` baixa o pacote inteiro, em 51 s, ou restaura do cache em 30 s (F-045 §3; F-047 §1.4).

**Quando a build sai:**
- **No PR,** guardada por 3 dias.
- **Na tag `v0.y.z`,** como release.
- **Nunca no push da main** (F-046 §1).

**A conta da cota:**
- o plano Free dá 2.000 minutos de CI por mês e 500 MB para artefatos, divididos com os pacotes; o artefato fica 90 dias se ninguém disser outra coisa (F-047 §1.1);
- uma dupla de builds compactada pesa 68,4 MB (F-045 §3); três PRs abertos ocupam uns 200 MB (3 × 68,4);
- o arquivo de uma release não entra nessa conta, até onde a documentação diz, mas isso não está confirmado (F-047 §1.1);
- o job de export levou de 57 a 83 s (F-045 §3).

**Os riscos do export:**
- **O #123712:** o Godot cai ao sair depois de exportar no Linux, com código 134. Não apareceu em quatro exports, dois neste PC e dois no CI (F-045 §2 e §3; F-047 §1.6). Se aparecer no job da TASK-9, ele confere o artefato e o teste de fumaça, e não só o código de saída.
- **O #1324 do gdUnit4:** derruba o primeiro export feito sem a pasta `.godot`. O import roda antes do export, e o gdUnit4 fica fora do pacote (F-047 §1.6).

## 7. As versões (DEC-0028 §3)

- **SemVer `0.y.z`,** só dígitos e pontos. O `.exe` mostra `0.1.0` como `0.1.0.0`, e qualquer outra coisa o faz cair para `1.0.0.0` (F-045 §2; F-047 §1.5).
- **O `y` sobe quando um marco do roteiro fecha:** 0.1.0 é o esqueleto andante, 0.2.0 a fase 1, 0.3.0 a fase 2; o 1.0.0 é o lançamento.
- **O `z` sobe a cada build que sai com tag** para alguém jogar (F-046 §2).
- **Onde mora:** `application/config/version` no `project.godot`. Até o esqueleto andante, vale `0.0.0`. Quem sobe é o Claude, no commit da tag, com o ok do Arthur (F-048).
- **O commit carimbado:** o CI escreve os 7 primeiros caracteres em `application/config/commit` na hora do export (F-045 §3), e o `.exe` feito no Linux leu o carimbo neste PC (F-045 §4).
- **A tag e as notas:** a tag `v0.y.z` vira uma release privada no GitHub, com as duas builds e notas em português tiradas do diário (F-046 §2).
- **O aperto de mão:** o cliente manda versão e commit ao conectar, e o servidor recusa os diferentes. No rollback, os dois precisam rodar a mesma regra (DEC-0026). O replay leva o mesmo carimbo (§4).

## 8. O fluxo de branch e o worktree (DEC-0028 §4)

1. A task fica Ready na main.
2. No In Progress, nasce uma branch curta, `task-N-nome`, e todo commit da task vai nela, inclusive o diário das sessões dela.
3. No fim, o Claude abre o PR em português, com o que mudou, os critérios, como testar e o link da build. A task vira Done dentro do PR.
4. O CI roda no PR o portão e as duas builds.
5. O Arthur revisa e joga a build. O merge é dele, ou do Claude com o ok dele, num merge commit.
6. Sessão sem task vai direto na main.
7. Duas sessões ao mesmo tempo usam worktrees separados. As branches de sonda da TASK-6 já rodaram assim, num worktree à parte (F-045 §3).

O plano Free não impõe nada disso: o pre-push continua sendo a trava, e o CI no PR é a segunda conferência (Q-03). A TASK-6 abriu antes do fluxo e fechou na main; a primeira branch é a da próxima task.

## 9. Os hooks do Claude Code (DEC-0027 §6)

| Hook | Quando | O que faz |
|---|---|---|
| `guard_locked_tests.sh` | Antes de `Edit`, `Write`, `MultiEdit` e `NotebookEdit` | Nega a edição de um arquivo listado em `.claude/harness/locks/*.sha256`, com o motivo |
| `format_gd.sh` | Depois de `Edit`, `Write` e `MultiEdit` | Formata o `.gd` nosso; um erro do formatador volta para o Claude |

- **Provados duas vezes:** nesta sessão, sem reiniciar, e numa sessão nova, no modo sem permissões. A trava negou o Edit e o Write na conversa principal e o Edit de um subagente, e o formatador consertou um `.gd` torto (F-040).
- **Os scripts leem o JSON com `python`** (F-038 §4), nunca com `python3`, que neste PC é o atalho falso da Microsoft Store (TASK-6, pauta da rodada 1).
- **A escrita pelo Bash não passa pela trava** (F-039 §2), e no Windows não há caixa de areia (F-047 §2). A trava de verdade continua sendo o sha256 no portão.

## 10. As medições

- **O portão, passo a passo:** §2 (F-049 §1 e §5).
- **O replay e a SyncTest:** F-042 (sessão 7).
- **O export, neste PC e no CI:** F-045 (sessão 7).
- **A prova a partir deste repositório,** com os presets que entraram: nas notas de fechamento da TASK-6.

## 11. O que fica para depois

- **TASK-9, o esqueleto andante:**
  - a especificação, a SyncTest à mão, a checagem dos dados e a referência;
  - o job de build no PR e na tag, e o teste de fumaça;
  - o 0.1.0 com a tag `v0.1.0`, e o aperto de mão na Main.

  O critério 3 dela é refeito quando ela ficar Ready.
- **TASK-10, a fase 1:** o gravador do replay.
- **Q-20:** a assinatura do `.exe`, antes de alguém de fora testar.
- **Canários** para o formato, o lint, as travas, o import e o log limpo, se um furo aparecer ali.
- **Um job do CI fora do pre-push,** quando uma camada não couber nos 90 s.

## 12. A máquina e as ferramentas

O inventário que o `AGENTS.md` resumia (veio para cá no fechamento do Desenho 5, F-065):

- Windows 11 com o Git Bash; os scripts são bash.
- No PATH (`~/.local/bin`): `godot` (o console do 4.7.2), `backlog`, `gdscript-formatter` 0.27.0, `lefthook`, `gitleaks` e `gh`; o `git-lfs` vem com o Git.
- O clumsy 0.3 (`~/.local/opt/clumsy-0.3`, como administrador) simula lag para 4 clientes ou mais (F-023 §2).
- O `node` 24 e o `python` 3.14 servem scripts de apoio e os hooks, nunca o portão (F-016 §2); `python`, nunca `python3`, que aqui é um atalho da Store.
- As sondas ficam fora do repositório, em pastas ao lado dele (`../netfox-sonda`, `../assets-sonda`, `../git-sonda`).
