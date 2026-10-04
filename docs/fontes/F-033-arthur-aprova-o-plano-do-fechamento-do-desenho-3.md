---
id: F-033
titulo: O Arthur aprova, no modo de plano, o plano do fechamento do Desenho 3 — as quatro DECs, o netfox em addons/ com o teste do res://, o rede.md e a prova num clone limpo (sessão 5, 04/10/2026)
recebido_em: 2026-10-04
como: Aprovação do plano no modo de plano do Claude Code, que pede o ok de mudança de arquitetura (AGENTS.md). O §2 é o plano como ele aprovou, sem correção.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: depois da rodada 2 (F-032), o Claude juntou num plano tudo o que fecha a TASK-5. Um agente de planejamento, de contexto limpo, revisou o primeiro rascunho e achou oito pontos. Os aceitos entraram no plano antes da aprovação:
>
> - os 9 `.import` do netfox, que o Godot 4.7.2 reescreve, entram já atualizados;
> - a prova do critério 2 sai de um clone de verdade;
> - o teste guarda o mapa exato dos autoloads e o `directory_rules`;
> - o contorno D ganha uma DEC própria.
>
> O plano registra também um desvio do critério 4 da TASK-5, que pedia as hipóteses provadas "com um servidor dedicado, dois clientes e lag simulado". Só a hipótese 1 foi medida pela rede (F-026). As hipóteses 2 e 3 foram provadas pela SyncTest num processo só (F-025 §1). Esse teste é mais duro que a rede, porque força um rollback da profundidade de 220 ms a cada tick e compara cada tick refeito com o original. As medições com servidor e clientes rodaram com os dois contornos ligados (F-026 §1; F-029 §1). Com a aprovação, o critério 4 vale assim.

## §1 — A aprovação

O Claude Code respondeu ao fim do modo de plano: "User has approved your plan. You can now start coding."

## §2 — O plano aprovado

# Plano: fechar o Desenho 3 (TASK-5)

## Contexto

As duas rodadas do Desenho 3 estão decididas. Na rodada 1 vieram o netfox no 4.7.2, 60 ticks e o contorno D (F-024 a F-030). Na rodada 2 vieram a defesa no tempo de quem defende, a posição na tela de quem ataca, o teto de 200 ms, o input, o oponente no passado, a detecção no núcleo, a fase 1 no tick e a Main (F-032). Faltam os critérios 2 a 7 da TASK-5:

- as DECs;
- o netfox em `addons/` com o teste do `res://`;
- o tickrate guardado;
- o `rede.md`;
- o registro, o reviewer e o portão.

Nenhum código de jogo entra; ele é da TASK-9. Um agente de planejamento revisou o primeiro rascunho, e os pontos aceitos já estão aqui.

## Passo 1 — Antes do código (orquestrador)

- **F-033:** este plano aprovado, como a F-022 no Desenho 2. Registra também um desvio do critério 4: as hipóteses 2 e 3 foram provadas pela SyncTest num processo só, mais dura que a rede porque força rollback de 220 ms a cada tick. As medições com servidor e clientes rodaram com os dois contornos ligados.
- **DEC-0023, o netfox no Godot 4.7.2:**
  - main fixada no `cf5189d` (plugin 1.49.4), com core, extras e internals;
  - a suíte com 297 de 301, os 4 de float16 de fora e o float16 sem uso;
  - os autoloads em `res://`, guardados por teste;
  - a única diferença do upstream: os 9 `.import`, que o Godot 4.7.2 reescreve;
  - fecha a Q-02 e completa a DEC-0003.
- Ela vem antes do implementer porque a regra dele proíbe dependência sem decisão registrada.

## Passo 2 — O netfox em `addons/` (implementer, em paralelo com o passo 3)

**Cópia:** `git archive` de `../netfox-sonda` no `cf5189d`, com três pastas:

- `addons/netfox`
- `addons/netfox.extras`
- `addons/netfox.internals`

Entram os `LICENSE` (MIT), `.uid` e `.off` como vieram, e os 9 `.import` já atualizados pelo import do 4.7.2. Assim, um clone novo não suja a árvore. Não entram `examples/`, `vest`, `test/`, `docs/` nem `netfox.noray`. A procedência é provada comparando cada arquivo com o hash do `git ls-tree -r cf5189d`; só os 9 `.import` diferem.

**`project.godot`**, editado à mão em três pontos:

| O quê | Por quê |
|---|---|
| `[autoload]`: os 14 autoloads em `res://`, copiados do `sonda/project.godot` na mesma ordem (12 do core, mais `WindowTiler` e `NetworkSimulator` do extras) | O contorno do #659. Com todos listados, o plugin não acrescenta nenhum com `uid://`. A ordem importa, porque um autoload chama o outro no `_ready` |
| `[editor_plugins]`: os 3 `plugin.cfg` do netfox | Ligar o netfox (DEC-0003) |
| `[netfox] time/tickrate=60` | Q-01 (F-030) |

O resto fica no padrão do netfox.

**`test/project_settings_test.gd`** ganha:

- **o mapa exato dos autoloads:** os 14 nomes, cada um com `"*res://addons/…"`. Pega o autoload que falta, o `uid://`, o `*` perdido e qualquer autoload nosso, que a DEC-0022 proíbe (critério 3);
- **o tickrate 60;**
- **o resto da configuração da F-032:** `input_delay` 0, broadcast desligado, `input_redundancy` 3 e `history_limit` 64. Cada um é lido com o padrão do netfox como valor de reserva, porque o editor apaga do arquivo o que é igual ao padrão;
- **o `directory_rules`:** `res://addons` fora dos avisos-erro, e as nossas pastas dentro. O verde de hoje não prova isso, porque o gdUnit4 não tem declaração sem tipo, e o netfox tem.

**Sondas, fora do commit:**

- um autoload trocado para `uid://` faz o teste falhar;
- tickrate 30 também faz falhar;
- depois, os dois voltam;
- o editor de verdade é aberto e fechado (`godot -e --quit-after`), o gatilho real do #659, e o `git status` precisa ficar limpo.

**Risco:** se o import ou os testes acusarem erro de tipo dentro do netfox, eu paro e volto a você. Nunca remendar o netfox.

## Passo 3 — As DECs, o `rede.md` e a base (orquestrador)

**As DECs** (skill `adr`):

- **DEC-0024, 60 ticks por segundo:** a medição, o parry com 72 % contra 50 % e o custo de 2 a 3,6 vezes; fecha a Q-01.
- **DEC-0025, os contornos do rollback no Jolt:**
  - o do transform no `after_prepare_tick`, obrigatório para todo corpo que o rollback move;
  - o D, que alinha o "estava no chão" do motor no começo de cada rollback;
  - substitui só a hipótese 3 da DEC-0022, que ganha o aviso parcial no topo, como a DEC-0004.
- **DEC-0026, a rede:**
  - o input;
  - o oponente no passado, sem previsão;
  - a compensação: o contato na tela de quem ataca, a defesa por tempo na de quem defende, o teto de 200 ms e o `view_lag`;
  - a detecção por forma no núcleo, em fatias varridas;
  - a fase 1 no tick;
  - a Main com três modos e o fechamento limpo;
  - completa a DEC-0011.
- **O índice** `decisoes/README.md` ganha Vigentes, Histórico e as notas das DEC-0003, 0011 e 0022.

**F-034, os números que faltavam do critério 5:** saem dos logs brutos da sonda, com o `analyze_net.py`:

- a CPU por tick dos clientes, pelo loop médio;
- a banda de subida por cliente.

A F-034 também registra por que faltam as corridas de 8 clientes a 60 ticks com ping 100 e 220: o servidor já fica para trás sem lag (F-029).

**`docs/arquitetura/rede.md`** (critérios 4, 5 e 7). Cada comportamento do netfox é citado pelo arquivo e pelo commit `cf5189d`, e os guias pelo link do GitHub fixado no commit.

1. O netfox no projeto.
2. O tick: a ordem do loop e o histórico.
3. O input:
   - os campos;
   - o toque único;
   - a redundância;
   - sem broadcast;
   - a recusa a reescrever o passado.
4. O rollback:
   - o lutador sem input não é simulado;
   - cada hipótese com o método, a prova e o que sobrou (1 em 14.268; Q-16);
   - efeito só em tick novo;
   - um lutador escreve só o próprio estado e lê o dos outros numa foto do tick.
5. O oponente no passado.
6. A compensação de lag:
   - a regra;
   - o histórico de poses no servidor;
   - o teto;
   - a viabilidade no código;
   - o que nasce na fase 2 com atraso zero e o que a fase 3 preenche.
7. A detecção do golpe.
8. A fase 1 no tick.
9. A Main.
10. As medições: a CPU e o loop por tick do servidor e dos clientes, a banda nos dois sentidos e o atraso de ponta a ponta, com 2 e com 8 clientes, e as corridas que faltam.
11. O que fica para depois.

**O resto da base:**

| Arquivo | O que muda |
|---|---|
| `arquitetura/visao-geral.md` | O tick a 60; as hipóteses viram resultados; os dois contornos; os 14 autoloads; aponta para o `rede.md` |
| `arquitetura/README.md` | O `rede.md` como detalhado |
| `design/combate.md` | Seção "A rede no combate": o teto de 200 ms (v0, DEC-0017), a defesa por tempo e a posição |
| `roteiro.md` | A fase 1 nasce no tick do netfox |
| `design/glossario.md` | Atraso de visão (`view_lag`), teto de compensação, contato, fatia varrida, histórico de poses, comando de um toque, oponente no passado, par offline e os modos da Main, contorno do transform, contorno D, lag switch; atualiza "Ticks por segundo" e "Compensação de lag" |
| `pendencias.md` | Q-01 e Q-02 respondidas; Q-09 com as corridas que faltam; **Q-17** nova: a regra contra o lag switch de quem ataca e a conferência do `view_lag` com o ping (fase 3); **Q-18** nova: o `view_lag` por oponente no 4v4 (fase 4) |
| `mudancas.md` | Uma linha por mudança de estado |
| `AGENTS.md` | Netfox fixado na linha de `addons/`, 60 ticks na stack, o clumsy (`~/.local/opt/clumsy-0.3`) e um ponteiro para o `rede.md`. Cabem uns 350 caracteres: hoje são 11.642 |
| Vitrine | Republicada no mesmo link: a rodada 2 decidida e a tabela medida com a CPU por tick dos clientes e a subida |
| TASK-9 | Comentário "Entrada do Desenho 3" pelo CLI: as configurações, os modos da Main, o fechamento limpo, a SyncTest com os dois contornos e o padrão do input |

## Passo 4 — Revisão

- O **reviewer**, com contexto limpo, julga os 7 critérios, a Definition of Done e as regras de arquitetura.
- Para que ele veja os arquivos novos, eles entram com `git add -N`.
- Ele revisa `git diff HEAD -- . ':!addons/netfox*'`; o netfox é conferido pelos hashes.
- A DoD #2 fica marcada como não se aplica: não há regra do núcleo, e o test-writer não entra.
- Conserto do que ele pedir, e portão verde aqui.

## Passo 5 — Commits e prova no clone

- **Commit 1, local em `main`, como nas sessões anteriores:** o netfox, as DECs, o `rede.md` e a base.
- **Clone limpo:**
  - um `git clone` do repositório no scratchpad;
  - o portão do zero, com o tempo comparado ao limite de 90 s do pre-push;
  - o `git status --porcelain` vazio, o que prova que o import não reescreveu nada (critério 2).
- **O fechamento:**
  - a TASK-5 recebe pelo CLI os critérios marcados, as notas e o resumo final; as notas apontam a versão e a seção da vitrine;
  - a skill `diario` escreve a sessão 5, uma linha no `registro.md` e as DEC-0023 a 0026 no Yabadoo;
  - a TASK-5 vira Done.
- **Commit 2, local**, com o fechamento.
- **O push fica para o seu ok.**

## Verificação e como você testa

- O portão verde aqui e no clone, com import do zero, e a árvore limpa depois.
- As sondas fazem o teste falhar e voltar ao verde.
- Você abre e fecha o editor do Godot, o gatilho real do #659, e o `git status` continua limpo.
- Cada critério da TASK-5 com prova: arquivo, teste ou saída.
- Veredito do reviewer.
