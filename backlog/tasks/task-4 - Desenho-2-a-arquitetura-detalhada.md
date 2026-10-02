---
id: TASK-4
title: 'Desenho 2: a arquitetura detalhada'
status: Done
assignee: []
created_date: '2026-10-02 16:48'
updated_date: '2026-10-02 22:49'
labels:
  - desenho
milestone: m-0
dependencies:
  - TASK-3
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
Segunda conversa da fase de desenho (DEC-0012). As regras já estão fixadas (DEC-0004), mas falta a forma concreta: o estado, o input, o encaixe do núcleo no netfox, as cenas e as pastas (`docs/arquitetura/visao-geral.md`).

### Perguntas em aberto
A pauta da conversa: cada item sai com resposta, DEC ou pendência.
- A forma do estado e do input: tipos, IDs e o que é sincronizado. O esqueleto andante em detalhe, a fase 1 esboçada e o combate só nomeado (F-018 §1).
- O `step` do núcleo dentro do `_rollback_tick`: a assinatura, o sanduíche com o `move_and_slide()` e onde vive a configuração.
- A máquina de estados do personagem. A DEC-0004 diz `RewindableStateMachine`, mas nela cada estado é um nó com lógica, contra a regra 1. Ela mora no núcleo, como dado?
- As cenas do lutador e da arena; os autoloads, quais e por quê.
- Os acessos inseguros. O Godot 4.7.2 não regula o nível de aviso por pasta: o `directory_rules` só inclui ou exclui. Viram erro no projeto todo, com os addons de fora, ou seguem como aviso (DEC-0005)?
- As pastas por feature dentro do jogo, e o nome do personagem no código.

### Escolhas confirmadas
- Configuração: os números de design ficam em Resources, em ms e metros, e viram na carga um objeto imutável, em ticks, que o núcleo só lê (DEC-0004, regra 3; F-018 §1).
- Escopo do estado: o esqueleto em detalhe, a fase 1 esboçada e o combate só nomeado (F-018 §1).

### Fora do escopo
- O protocolo de rede, o tickrate e a compensação de lag (Desenho 3, TASK-5).
- Instalar o netfox no projeto. Aqui ele é lido no código-fonte, e a prova com ele rodando é do Desenho 3 (Q-02).
- O estado do combate em detalhe: golpe, parry, bloqueio e hitbox (fase 2; Q-10; Q-14).
- Código de jogo: o primeiro código é o esqueleto andante (TASK-9).

### O que você vai aprender
- Functional core, imperative shell na prática, e o sanduíche do movimento.
- Por que o rollback pede estado feito de valores, e não de objetos.
- Como o Godot carrega cena e script; o que é um autoload, e por que evitar estado global.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Quando a conversa termina, `docs/arquitetura/visao-geral.md` mostra o estado, o input, o `step` e as cenas, com diagrama.
- [x] #2 Quando o Arthur aprova a forma do estado e as pastas, uma DEC registra.
- [x] #3 Quando a decisão sobre os acessos inseguros sai, o `project.godot` e o teste de configurações acompanham.
- [x] #4 Quando um termo novo aparece, ele entra no glossário com o nome no código.
- [x] #5 Quando o desenho depende de um comportamento do netfox, o documento cita o arquivo do netfox que o confirma, num commit identificado, e o que só o Desenho 3 pode provar fica marcado como hipótese.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Critérios de aceite verificados
- [x] #2 Teste automatizado para toda regra do núcleo (core/)
- [x] #3 Diário da sessão escrito e glossário atualizado
- [x] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Leitura do netfox no código-fonte, sem instalar: como o RollbackSynchronizer lê e restaura as propriedades, o `_rollback_tick`, a `RewindableStateMachine` e os cuidados com o CharacterBody3D.
2. Rodada 1, o núcleo: estado, input, `step`, o sanduíche e a máquina de estados, com um artefato visual de um tick e de um rollback (DEC-0019).
3. Rodada 2, a casca: cenas, autoloads, pastas, nome do personagem e acessos inseguros.
4. Proposta pelo modo de plano; com o ok do Arthur, a DEC e o `visao-geral.md`.
5. Registro: as palavras do Arthur numa F-xxx, o glossário, `mudancas.md`, `pendencias.md`, e o `project.godot` com o teste, se os avisos mudarem.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Sessão 3 (02/10/2026):
- Leitura do netfox no código-fonte, main, commit `cf5189d`, sem instalar: snapshot por valor com `get_indexed`, caminho aninhado, ordem de simulação, a RewindableStateMachine plana, os padrões e os cuidados com o CharacterBody3D.
- Rodada 1, o núcleo, no artefato "O tick por dentro". O Arthur não entendeu o tick; a explicação foi refeita no mundo dele (F-020 §2 a §4; DEC-0021) e ele confirmou as quatro caixas, a máquina de estados no núcleo e os cinco detalhes (F-020 §5).
- Rodada 2, a casca: cenas, zero autoloads nossos e acesso inseguro como erro (F-021 §1).
- O plano aprovado no modo de plano (F-022) virou a DEC-0022, a visão geral reescrita, o glossário, o `project.godot` com teste, o AGENTS.md, o critério 5 da TASK-6 e as hipóteses da TASK-5.
- Sondas: o pulo de 1,2 m chega a 1,09 m a 30 ticks com a fórmula contínua; o portão não compila script que nenhum teste carrega; o teste novo falha se um aviso voltar para 1.
- O reviewer pediu mudanças: o `MovePlan` no glossário, a aprovação das pastas numa fonte (F-022), o status da DEC-0004 de volta a `aceita` e quatro citações do netfox. Tudo corrigido.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Fechada na sessão 3 (02/10/2026), em duas rodadas e um plano aprovado.
- DEC-0022: o estado em quatro caixas, a máquina de estados no núcleo como dado, o tick em sanduíche, as cenas, zero autoloads nossos, as pastas com nome e o acesso inseguro como erro. Substitui só a frase da DEC-0004 sobre a RewindableStateMachine.
- `docs/arquitetura/visao-geral.md` reescrita, com 5 diagramas e a tabela do netfox no commit `cf5189d`, com as hipóteses marcadas.
- Glossário: lutador, jogador, frame, modo, ação, carimbo de tick, sanduíche do tick, plano e fatos do movimento, configuração e estado do lutador.
- `project.godot`: os quatro avisos `unsafe_*` em 2, guardados pelo `test_unsafe_access_is_an_error`.
- Processo: a DEC-0021 nasceu do pedido do Arthur por explicação no mundo dele.
- Artefato, versão 2: https://claude.ai/artifact/EJCYbVj6oCZcim765nDH8B
- Portão: `gate green in 12s`, com 5 testes.
- DoD #2: task de desenho, sem regra de núcleo; o teste novo guarda configuração.
<!-- SECTION:FINAL_SUMMARY:END -->
