---
id: F-022
titulo: O Arthur aprova, no modo de plano, o plano do Desenho 2 com as cenas, os autoloads e as pastas (sessão 3, 02/10/2026)
recebido_em: 2026-10-02
como: Aprovação do plano no modo de plano do Claude Code, que pede o ok de mudança de arquitetura (AGENTS.md). O §2 é o plano como ele aprovou, sem correção.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: depois das rodadas 1 e 2 do Desenho 2 (F-020 §5; F-021 §1), o Claude juntou todas as decisões num plano único. Nas duas rodadas, as cenas e as pastas foram mostradas como trade-off, mas não tiveram pergunta própria. A aprovação delas está aqui. O reviewer da TASK-4 apontou essa lacuna, e esta fonte a fecha.

## §1 — A aprovação

O Claude Code respondeu ao fim do modo de plano: "User has approved your plan."

## §2 — O plano aprovado

# Desenho 2 (TASK-4): registrar a arquitetura detalhada

## O que você está aprovando, em uma frase

Que as decisões das rodadas 1 e 2 virem regra escrita: uma DEC nova (DEC-0022), a `visao-geral.md` reescrita com diagramas, termos novos no glossário e a mudança de tipagem no `project.godot`, com teste. Nenhum código de jogo nasce aqui: o primeiro código é o esqueleto andante (TASK-9).

## Contexto

As regras gerais já existiam (DEC-0004), mas faltava a forma concreta. Nas duas rodadas, com a explicação refeita no seu mundo (DEC-0021), você decidiu (F-018, F-020 §5, F-021):

- **Estado em quatro caixas:** o corpo (`position`, `velocity`) no nó `Fighter`; as regras no `FighterState` (`mode`, `mode_since`, `on_floor`, `left_floor_tick`, `jump_pressed_tick`, `jumps_used`, `facing_yaw`), gravadas campo a campo pelo caminho `:state:campo`; o input (`move`, `yaw`, `jump`) no nó `Input` do dono, jogador ou bot; a configuração imutável em ticks (`MovementConfig`), fora do estado. A fase 1 fica esboçada e o combate só com nome.
- **Máquina de estados no núcleo, como dado:** `mode` + `mode_since`, com regra pura e hierarquia como função. O combate será um segundo modo, paralelo (`action`). A `RewindableStateMachine` do netfox não entra.
- **O tick em sanduíche:** `before_move()` (puro) → `move_and_slide()` (motor) → `after_move()` (puro).
- **Os cinco detalhes:** tempo como carimbo de tick; física derivada para o tamanho do tick, com teste da altura do pulo; ms → tick pelo mais próximo (empate sobe), com teste de meio tick; efeito e animação depois do loop de ticks, sem barramento de eventos; o nome **lutador** (`Fighter`).
- **As cenas:** `Fighter` (Collision, Input, RollbackSynchronizer, TickInterpolator, Visual), `CameraRig` só para o seu lutador, `Arena`, `Match` (carrega o `.tres`, cria a configuração e entrega aos lutadores) e `Main` (a entrada, cujo detalhe é do Desenho 3).
- **Zero autoloads nossos**; só os do netfox.
- **As pastas:** `core/fighter/`, `core/time/`, `data/` (os `.tres` e as classes deles), `fighter/`, `arena/`, `match/`, e `net/` e `ui/` quando chegarem.
- **Acesso inseguro vira erro** no projeto todo, com os addons de fora. O furo achado no portão vai para a TASK-6.

## O que muda, arquivo por arquivo

1. **`docs/decisoes/DEC-0022-arquitetura-detalhada.md`** (nova, aceita): tudo o que está acima, com o trade-off de cada escolha e os motivos tirados do código do netfox (commit `cf5189d`).
   - Ela substitui **só uma frase** da DEC-0004, a da `RewindableStateMachine`. Na DEC-0004 mudam só `status` e `substituida_por`, e entra um aviso no topo: "⚠️ Em parte substituída por DEC-0022 em 2026-10-02: a frase sobre a RewindableStateMachine não é a regra atual. As seis regras continuam valendo."
   - **Trade-off dessa forma:** as dezenas de referências à DEC-0004 continuam certas e as seis regras não precisam ser copiadas. Em troca, a DEC-0004 passa a ter um trecho que não vale mais, e o aviso no topo é o que impede alguém de seguir esse trecho.
   - A DEC-0005 fica marcada no índice como completada pela DEC-0022, porque ela deixou o acesso inseguro "para o Desenho 2".
2. **`docs/decisoes/README.md`**: a linha da DEC-0022, os status da DEC-0004 e da DEC-0005, e o histórico da substituição parcial.
3. **`docs/arquitetura/visao-geral.md`** (reescrita), com diagramas mermaid:
   - o que é um tick (Valorant, `setInterval`);
   - as quatro caixas;
   - o sanduíche;
   - a máquina de estados em duas regiões;
   - o tempo no estado;
   - as cenas, os autoloads, as pastas e a tipagem;
   - "o que o Desenho 3 prova", com as hipóteses marcadas e os arquivos do netfox citados no commit `cf5189d` (critério 5).
   - O `docs/arquitetura/README.md` ganha o status novo.
4. **`docs/design/glossario.md`**:
   - **termos novos:** lutador (`Fighter`), jogador (`peer`), modo (`mode`), ação (`action`, fase 2), carimbo de tick (`*_tick`), frame, sanduíche do tick (`before_move` e `after_move`), fatos do movimento (`MoveFacts`), configuração (`MovementConfig`) e estado do lutador (`FighterState`);
   - **ajuste:** "Estado" passa de "sem objeto" para "valores planos, nunca referência a outro objeto".
5. **`project.godot`**, editado à mão: os quatro avisos `unsafe_property_access`, `unsafe_method_access`, `unsafe_cast` e `unsafe_call_argument` passam de 1 para 2, ou seja, viram erro (DEC-0022; F-021). Testado num clone: o portão segue verde.
6. **`test/project_settings_test.gd`**: um teste novo, `test_unsafe_access_is_an_error`, que guarda os quatro valores (critério 3).
7. **`AGENTS.md`**: quatro trocas curtas, e o arquivo fica abaixo de 12k caracteres.
   - A máquina de estados mora no `core/`, como dado (DEC-0022).
   - "Zero autoloads nossos".
   - A pasta de exemplo vira `fighter/`, e não `player/`.
   - "Acesso inseguro também é erro".
8. **Backlog:**
   - **TASK-6** ganha um critério: "Quando um script nosso tem erro de tipo e nenhum teste o carrega, o portão falha; uma sonda prova o antes e o depois". Leva junto as medidas: 1,3 s numa execução só, contra 1,2 s por arquivo com `--check-only`.
   - **TASK-5** ganha um comentário com as três hipóteses para provar: o caminho `:state:mode` de ponta a ponta; o contorno do transform no Jolt para um lutador colidir com o outro na re-simulação; `on_floor` como estado. Leva também a evidência para a Q-01: a 30 ticks, a janela de parry de 80 ms vira 67 ms.
9. **`docs/pendencias.md`**: a evidência do parry na linha da Q-01.
10. **`docs/mudancas.md`**: quatro linhas:
    - a máquina de estados sai da `RewindableStateMachine` para o núcleo;
    - o acesso inseguro passa de aviso a erro;
    - as pastas ganham nome;
    - o portão não compila script que nenhum teste carrega, e o conserto vai para a TASK-6.
11. **O artefato "O tick por dentro"**, republicado no mesmo link: a explicação nova do tick (Valorant, `setInterval`, frame contra tick), o carimbo com o Flash do LoL, as decisões marcadas como decididas, com trade-off, e a rodada 2 (cenas, autoloads, pastas e tipagem).

## Fechamento da sessão

- Revisão dos 5 critérios da TASK-4 por um agente de contexto limpo (`reviewer`), que começa do "não".
- O portão rodado, com as últimas linhas coladas aqui.
- Commits só com os meus arquivos.
- A TASK-2 e a TASK-4 viram Done no backlog.
- Linha no registro da harness: o terceiro furo de checagem achado por sonda, e a DEC-0021.
- Diário da sessão 3 e as decisões no Yabadoo: a DEC-0021, a DEC-0022, e a DEC-0020 se a outra sessão ainda não a registrou.
- **Push:** ele sai da máquina, então eu paro e peço a sua permissão. Ele leva também o commit `365ccf9`, da outra sessão.

## Como verificar

- `bash tools/gate.sh` verde, com 5 testes: os 4 de hoje mais o do acesso inseguro.
- O teste novo falha se alguém voltar um dos quatro avisos para 1.
- A `visao-geral.md` mostra o estado, o input, o `step`/sanduíche e as cenas, com diagrama (critério 1).
- Cada afirmação sobre o netfox cita o arquivo e o commit `cf5189d`, e as hipóteses estão marcadas (critério 5).
- O artefato abre no mesmo link com a explicação nova.
