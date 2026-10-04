---
id: F-040
titulo: A sonda dos hooks do Claude Code numa sessão nova — a trava nega o Edit e o Write, também num subagente, e o formatador formata (sessão 6, 04/10/2026)
recebido_em: 2026-10-04
como: Relatório gravado por uma sessão nova do Claude Code que o Arthur abriu nesta máquina, com o roteiro de `../esteira-sonda/PROMPT-SESSAO-NOVA.md`, em `../esteira-sonda/hook-probe-resultado.md`. Texto como chegou, sem o título.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: depois do commit `963bdca`, o Arthur abriu outra sessão do Claude Code (v2.1.289) na pasta do projeto. O `/hooks` mostrou os dois hooks do projeto, num print mandado a esta sessão: "2 hooks on 2 events", o PreToolUse `guard_locked_tests.sh` em `Edit|Write|MultiEdit|NotebookEdit` e o PostToolUse `format_gd.sh` em `Edit|Write|MultiEdit`. Ele colou o roteiro, e a sessão nova gravou o relatório abaixo. Enquanto ela rodava, esta sessão não mexeu em nenhum arquivo.

TASK-6, critério 7 · 2026-10-04, 17:10–17:12 · Claude Code (Opus 5.5) no PC do Arthur

**Veredito: os dois hooks funcionaram numa sessão nova, nos quatro caminhos.** A trava negou o Edit e o Write na conversa principal e o Edit de um subagente. O formatador deixou no formato canônico um `.gd` salvo torto. A limpeza devolveu o repositório ao estado de antes: `git status --short` vazio no começo e no fim.

Esta é a "prova numa sessão nova" que as notas da TASK-6 davam como pendente. O critério 7 ainda pede o resultado no registro da harness (`.claude/harness/registro.md`), e esta sonda não podia mexer no repositório: essa linha ainda falta.

## Condições

- Repositório `jogo-acrobatico`, `main` em `963bdca`, com `git status --short` vazio no início.
- Sessão nova: os hooks vieram do `.claude/settings.json` versionado, lido na abertura da sessão, sem nenhuma mudança de configuração no meio.
- Modo **bypass permissions** ligado na conversa principal e no subagente (o subagente percebeu e relatou isso sozinho). Quem negou foi o hook, e não um pedido de permissão.
- Hooks em teste, de `.claude/settings.json`:
  - PreToolUse `Edit|Write|MultiEdit|NotebookEdit` → `.claude/hooks/guard_locked_tests.sh` (a trava);
  - PostToolUse `Edit|Write|MultiEdit` → `.claude/hooks/format_gd.sh` (o formatador).

## Resumo

| Passo | Tentativa | Esperado | Resultado |
|---|---|---|---|
| 1 | Trava `TASK-6.sha256` criada pelo Bash | criada | ✅ criada |
| 2 | Edit na 1ª linha do teste travado | negado | ✅ negado |
| 3 | Write de uma linha no teste travado | negado | ✅ negado; o `git checkout` não foi preciso |
| 4 | O mesmo Edit, por um subagente general-purpose | negado | ✅ negado |
| 5 | Write de um `.gd` mal formatado | sai formatado | ✅ formatado |
| 6 | Limpeza | nada sobra | ✅ `git status --short` vazio |

## Passo 1: a trava

```
$ sha256sum test/project_settings_test.gd > .claude/harness/locks/TASK-6.sha256
$ cat .claude/harness/locks/TASK-6.sha256
36b515e6ccefce5d64271055ead4d729a65cf6b7e1e75a87a2eef322ebbb4c7e *test/project_settings_test.gd
```

O `sha256sum` do Git for Windows escreve no modo binário, com `*` antes do caminho. A regex do hook (`[ *]`) aceita os dois modos, e o resto da sonda mostra que ela bateu.

## Passo 2: Edit na conversa principal

Tentativa: trocar a linha 1 (`# Guards the project settings decided in DEC-0002, DEC-0005, DEC-0022, DEC-0023, DEC-0024 and`) por `# Hook probe (TASK-6, criterion 7): this edit must be denied.`

Mensagem exata:

```
<error>PreToolUse:Edit hook error: test/project_settings_test.gd is a locked acceptance test (.claude/harness/locks/TASK-6.sha256). Do not change it: stop and report BLOCKED; only Arthur unlocks it (DEC-0009).</error>
```

## Passo 3: Write na conversa principal

Tentativa: reescrever o arquivo inteiro com uma linha só, `# Hook probe (TASK-6, criterion 7): this write must be denied.`

Mensagem exata:

```
<error>PreToolUse:Write hook error: test/project_settings_test.gd is a locked acceptance test (.claude/harness/locks/TASK-6.sha256). Do not change it: stop and report BLOCKED; only Arthur unlocks it (DEC-0009).</error>
```

O Write não passou, então o `git checkout` não foi preciso. A prova, logo depois:

```
$ sha256sum -c .claude/harness/locks/TASK-6.sha256
test/project_settings_test.gd: OK
$ git status --short
?? .claude/harness/locks/TASK-6.sha256
```

## Passo 4: Edit num subagente

Um subagente `general-purpose` leu as 5 primeiras linhas e tentou o mesmo Edit uma vez, com a nova linha `# Hook probe (TASK-6, criterion 7): this subagent edit must be denied.`. A ordem era não tentar outro caminho se fosse negado. A mensagem que ele relatou, literal:

```
<error>PreToolUse:Edit hook error: test/project_settings_test.gd is a locked acceptance test (.claude/harness/locks/TASK-6.sha256). Do not change it: stop and report BLOCKED; only Arthur unlocks it (DEC-0009).</error>
```

O resto do relato dele:

> The hook blocked the edit. `test/project_settings_test.gd` was not changed. [...] I made one Edit call and stopped. I did not retry, did not re-read the file to check, and touched no other file. [...] The Read (lines 1–5) returned only the file's lines, with no hook message. [...] That last note means the session was in bypass permissions mode, so the block came from the hook itself and not from a permission prompt.

Foram 2 chamadas de ferramenta, em cerca de 33 s. A notificação do subagente chegou com `<` e `>` escapados como `&lt;` e `&gt;`; aqui eles já aparecem desescapados.

A prova depois do subagente, antes de apagar a trava: `sha256sum -c` → `test/project_settings_test.gd: OK`.

## Passo 5: o formatador

O Write gravou isto, com 4 espaços e sem linha em branco:

```gdscript
extends RefCounted
func f() -> int:
    return 1
```

O Write respondeu:

```
File created successfully at: C:\Users\arthu\Projects\jogo-acrobatico\tools\zz_hook_probe.gd (file state is current in your context — no need to Read it back)
```

E o Claude Code acrescentou, por conta própria:

```
PostToolUse:Write hook additional context: PostToolUse hook modified C:\Users\arthu\Projects\jogo-acrobatico\tools\zz_hook_probe.gd after your edit (likely a formatter). Your next Edit will not fail with a stale-file error, but if its old_string targets a region the hook reformatted, Read the file first.
```

Como o arquivo ficou, pelo Read:

```
1	extends RefCounted
2	
3	
4	func f() -> int:
5		return 1
```

Os bytes, pelo `cat -A` (`^I` é um tab, `$` é um fim de linha LF):

```
extends RefCounted$
$
$
func f() -> int:$
^Ireturn 1$
```

O `gdscript-formatter --check tools/zz_hook_probe.gd` respondeu `All 1 file(s) are formatted`, com exit 0. Nenhum `.uid` apareceu, porque o hook só chama o formatador, e não o Godot.

## Passo 6: limpeza

```
$ sha256sum -c .claude/harness/locks/TASK-6.sha256
test/project_settings_test.gd: OK
$ rm -v tools/zz_hook_probe.gd
removed 'tools/zz_hook_probe.gd'
(não havia tools/zz_hook_probe.gd.uid)
$ rm -v .claude/harness/locks/TASK-6.sha256
removed '.claude/harness/locks/TASK-6.sha256'
$ ls -la .claude/harness/locks/
total 0
drwxr-xr-x 1 arthu 197609 0 Oct  4 17:12 .
drwxr-xr-x 1 arthu 197609 0 Oct  2 14:16 ..
-rw-r--r-- 1 arthu 197609 0 Oct  2 13:48 .gitkeep
$ git status --short
$ git diff HEAD --stat
```

As duas últimas saídas vieram vazias, como no início. O `git status --short --ignored` também não mostrou nenhum resto da sonda.

## Observações

1. **"hook error" aqui é uma negação de propósito.** O Claude Code põe o prefixo `PreToolUse:Edit hook error:` até numa negação deliberada, e um agente apressado poderia ler isso como defeito do hook. O texto do motivo resolve ("Do not change it: stop and report BLOCKED"), e tanto a conversa principal quanto o subagente pararam como deviam. Nada a mudar agora.
2. **A negação valeu no modo bypass**, na conversa principal e no subagente, como dizia a documentação lida em 04/10 (TASK-6, descrição).
3. **O aviso do PostToolUse ajuda o implementer.** Depois de um Write num `.gd`, o Claude Code avisa que o arquivo mudou no disco, e um Edit seguinte tem de partir do texto formatado.

## O que esta sonda não prova

- A escrita pelo Bash, que fica sem guarda por decisão do Arthur (F-039 §2). A trava de verdade continua sendo o `sha256` do portão.
- O MultiEdit e o NotebookEdit, que estão no matcher mas ficaram fora do roteiro.
- O tempo que cada hook gasta por edição, que esta sonda não mediu (a sessão anterior mediu de 0,2 a 0,8 s).
- O registro da harness, que o critério 7 exige: essa linha ainda falta.
