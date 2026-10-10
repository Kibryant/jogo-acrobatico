# Jogo Acrobático (nome provisório)

Jogo de ação 3D online e gratuito. A identidade é o movimento acrobático: correr na parede, dar dash e usar o gancho. O jogador combina espada, arco e arma de fogo como quiser, sem classes. Começa em duelos 1v1 e depois vai para 4v4 e 8v8. É um sucessor espiritual do GunZ só na mecânica: não usa nome, arte nem código do GunZ (F-001).

O Arthur faz o jogo com o Claude Code. O Claude escreve o código e ensina enquanto constrói; o Arthur define a sensação, decide a arquitetura, revisa e testa (DEC-0010).

**Em que pé está:** o jogo ainda está no papel. O desenho da fase 0 terminou (`docs/design/` e `docs/arquitetura/`), e o próximo passo é o esqueleto andante, uma cápsula em rede de ponta a ponta. Ainda não há build para jogar (`docs/roteiro.md`).

*English summary at the end.*

## Stack

Godot 4.7.2, GDScript com tipagem obrigatória e netfox, com servidor autoritativo e previsão com rollback. O renderer é o Compatibility, a física é o Jolt e os testes rodam no gdUnit4 (DEC-0001 a DEC-0005 e DEC-0027). O piso de desempenho é 60 fps em 1080p no PC do Arthur (DEC-0002).

## Como rodar

As ferramentas precisam estar no PATH: `godot` (4.7.2), `gdscript-formatter` (0.27.0), `gitleaks` (8.30.1), `lefthook` e o Git com o `git-lfs`; o `backlog` e o `gh` são opcionais. No PC do Arthur, elas ficam em `~/.local/bin`.

1. **Na primeira vez em um clone:** `git lfs install`, `lefthook install` e `godot --headless --path . --import`.
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
| `addons/` | Addons de terceiros, fixados na versão (gdUnit4 6.2.1 e netfox `cf5189d`, DEC-0023) |
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

## Como contribuir

O repositório é aberto e aceita contribuições por pull request. Antes de abrir um, leia o [CONTRIBUTING.md](CONTRIBUTING.md); a convivência segue o [código de conduta](CODE_OF_CONDUCT.md). Perguntas e ideias vão para o [Discussions](https://github.com/Kibryant/jogo-acrobatico/discussions); falhas de segurança vão pelo relato privado descrito no [SECURITY.md](SECURITY.md).

## Licença

Tudo neste repositório está sob a licença MIT ([LICENSE](LICENSE)): o código, os testes, as ferramentas e a documentação, inclusive `docs/` e o `AGENTS.md` (DEC-0033; DEC-0035). As exceções:

- Os assets feitos para o projeto, em `assets/` fora de `assets/third_party/`, estão sob a CC BY 4.0 ([LICENSE-ASSETS](LICENSE-ASSETS)): dá para usar, mudar e redistribuir, dando o crédito "Arthur Gustavo and contributors, https://github.com/Kibryant/jogo-acrobatico, CC BY 4.0".
- Os assets de terceiros, em `assets/third_party/`, e os addons, em `addons/`, seguem cada um a sua licença, que fica ao lado dos arquivos; os assets de terceiros também têm uma linha em `assets/CREDITS.md` (DEC-0029).
- O código de conduta é uma tradução do Contributor Covenant 3.0 e está sob a CC BY-SA 4.0, como o original.
- O nome e o logo do jogo não estão sob nenhuma licença; veja abaixo.

Quem manda um pull request entrega a contribuição sob a licença da parte do repositório que ela muda, pela seção D.6 dos termos do GitHub, sem contrato extra (DEC-0033).

### O nome e o logo

O nome do jogo, hoje o provisório "Jogo Acrobático" (DEC-0018), e o logo, quando existir, não fazem parte de nenhuma das licenças acima. Quem fizer uma cópia ou um jogo derivado precisa usar outro nome e outro logo, e não pode dar a entender que é o jogo oficial. Dizer que o seu projeto se baseia neste continua livre.

## English summary

Jogo Acrobático (a working title) is a free online 3D action game built around acrobatic movement (wall-running, dashing and a grappling hook) and a free mix of sword, bow and guns, starting with 1v1 duels. It is made in Godot 4.7.2 with typed GDScript and netfox, and it is still on paper: there is no playable build yet. The project is written in Portuguese, including commit messages and pull requests; CONTRIBUTING.md has an English summary.

Everything in this repository is under the MIT License (LICENSE), including code, tests, tools and documentation, with these exceptions. Original assets under `assets/`, outside `assets/third_party/`, are under CC BY 4.0 (LICENSE-ASSETS), credited as "Arthur Gustavo and contributors, https://github.com/Kibryant/jogo-acrobatico, CC BY 4.0". Third-party assets and addons keep their own licenses. The Code of Conduct is a translation of the Contributor Covenant 3.0 under CC BY-SA 4.0. The game's name and logo are not licensed: copies and derived games must use a different name and logo and must not suggest they are the official game; saying that your project is based on this one is fine.
