# Jogo Acrobático (nome provisório)

Jogo de ação 3D online e gratuito. A identidade é o movimento acrobático: correr na parede, dar dash e usar o gancho. O jogador combina espada, arco e arma de fogo como quiser, sem classes. Começa em duelos 1v1 e depois vai para 4v4 e 8v8. É um sucessor espiritual do GunZ só na mecânica: não usa nome, arte nem código do GunZ (F-001).

O Arthur faz o jogo com o Claude Code. O Claude escreve o código e ensina enquanto constrói; o Arthur define a sensação, decide a arquitetura, revisa e testa (DEC-0010).

## Stack

Godot 4.7.2, GDScript com tipagem obrigatória e netfox, com servidor autoritativo e previsão com rollback. O renderer é o Compatibility, a física é o Jolt e os testes rodam no gdUnit4 (DEC-0001 a DEC-0006). O piso de desempenho é 60 fps em 1080p no PC do Arthur (DEC-0002).

## Como rodar

As ferramentas ficam em `~/.local/bin`: `godot`, `backlog`, `gdscript-formatter`, `lefthook`, `gitleaks` e `gh`. O `git-lfs` vem com o Git.

1. **Na primeira vez em um clone:** `lefthook install` e `godot --headless --path . --import`.
2. **Abrir o editor:** atalho "Godot 4.7.2" ou `godot --path . --editor`.
3. **Rodar o portão completo**, o mesmo do pre-push e do CI: `bash tools/gate.sh`.
4. **Rodar só os testes:** `bash tools/run_tests.sh`. O relatório HTML fica em `reports/`.
5. **Formatar:** `bash tools/check_format.sh --fix`.
6. **Ver o board:** `backlog board`, ou `backlog task list --plain`.

## Onde está cada coisa

| Pasta | O que tem |
|---|---|
| `core/` | As regras puras da simulação: sem nó, tudo em ticks (DEC-0004) |
| `common/`, `data/`, `assets/` | Código compartilhado, dados de design (.tres), arte e áudio |
| `addons/` | Addons de terceiros, fixados na versão (gdUnit4 6.2.1) |
| `test/` | Testes do gdUnit4 |
| `tools/` | O portão e as checagens |
| `backlog/` | As tasks, no Backlog.md |
| `docs/fontes/` | O que chegou e como chegou (F-xxx) |
| `docs/decisoes/` | As decisões (DEC-xxxx); o `README.md` é o índice |
| `docs/design/` | O jogo no papel: visão, combate, movimento e glossário |
| `docs/arquitetura/` | Como o jogo é construído |
| `docs/diario/` | Uma entrada por sessão: o que foi feito e o que se aprendeu |
| `docs/roteiro.md`, `docs/mudancas.md`, `docs/pendencias.md` | Fases, mudanças de estado e perguntas abertas |

As instruções dos agentes estão no `AGENTS.md`, em inglês (DEC-0008). O `CLAUDE.md` só importa esse arquivo.
