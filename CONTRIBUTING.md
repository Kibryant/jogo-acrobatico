# Como contribuir

Obrigado pelo interesse! O Jogo Acrobático é um projeto de hobby, aberto, com um mantenedor principal, o Arthur Gustavo, que decide a direção do jogo. As contribuições entram por pull request e seguem as regras do projeto, descritas aqui e no `AGENTS.md`.

*English summary at the end.*

## Antes de começar

- **Mudança pequena**, como um erro de digitação, um bug claro ou um teste que falta: pode abrir o PR direto.
- **Mudança grande**, como uma mecânica nova, um número de design, a arquitetura ou uma dependência nova: abra antes uma conversa no [Discussions](https://github.com/Kibryant/jogo-acrobatico/discussions) ou uma issue. As decisões do projeto ficam em `docs/decisoes/` (DEC-xxxx) e são do mantenedor; um PR que contradiz uma DEC aceita só entra com uma DEC nova.
- Os números do jogo (tempos, dano, distâncias) moram em `docs/design/` e mudam por decisão do mantenedor, depois de jogar (DEC-0017).

## Preparar a máquina

As ferramentas, nas versões que o CI e o mantenedor usam:

- Godot 4.7.2, chamado como `godot` no PATH;
- gdscript-formatter 0.27.0;
- gitleaks 8.30.1;
- lefthook (2.1.16 aqui);
- Git com o Git LFS;
- Backlog.md (`backlog`, 1.53.0 aqui), opcional, para ler as tasks.

No clone:

1. `git lfs install`, uma vez por máquina, e `lefthook install`.
2. `godot --headless --path . --import`.
3. `bash tools/gate.sh`, que precisa sair verde.

Os scripts são bash; no Windows, use o Git Bash.

## O portão

O `bash tools/gate.sh` roda o formato, o lint, a pureza do núcleo, os assets e o LFS, os testes travados, o import, a compilação de todo script e os testes (DEC-0027). O pre-push roda o mesmo portão, e o CI também. Um PR só entra com o portão verde.

Se uma checagem parecer errada, diga no PR em vez de contorná-la: nada de `--no-verify`, de afrouxar uma checagem ou de editar um teste travado. Os testes travados estão listados em `.claude/harness/locks/` (DEC-0009).

## Como o código é escrito

- GDScript com tipagem estática em tudo; declaração sem tipo e acesso inseguro são erro (DEC-0005; DEC-0022).
- Arquivos e pastas em snake_case; classes e nós em PascalCase; tabs; linhas de até 100 colunas, formatadas pelo gdscript-formatter (`bash tools/check_format.sh --fix`).
- As regras da simulação ficam em `core/`, puras: sem nó, sem relógio, sem aleatório sem semente, tudo em ticks inteiros (DEC-0004). O `tools/check_core_purity.sh` confere.
- Toda regra nova em `core/` vem com teste no gdUnit4, com o nome dizendo o comportamento, como `test_parry_beats_charged_attack`.
- Código, comentários e testes em inglês; commits, PRs e `docs/` em português (DEC-0008; DEC-0033).

## Assets

- Asset de terceiros só entra com uma licença que permita redistribuir num repositório público: nada com "não redistribua" nem com EULA de loja, pago ou grátis. Ele mora em `assets/third_party/<fonte>/<pack>/`, com o arquivo de licença ao lado e uma linha em `assets/CREDITS.md`, no mesmo commit (DEC-0029).
- Arte, áudio, modelos e fontes passam pelo Git LFS (`.gitattributes`).
- Nada do GunZ entra: nem nome, nem arte, nem mapa, nem som, nem código (F-001).

## A licença da sua contribuição

Pela seção D.6 dos termos do GitHub, o que você manda para um repositório com licença entra sob essa licença: código, testes, ferramentas e documentação sob a MIT; assets próprios em `assets/` sob a CC BY 4.0. Não há contrato extra (CLA). Só mande o que você tem o direito de licenciar assim (DEC-0033).

## O pull request

- Uma branch por mudança, a partir da `main`.
- O texto do PR e as mensagens de commit em português; o modelo de PR mostra o que escrever.
- O CI de um PR vindo de fork só roda depois que o mantenedor aprova; é normal o PR ficar esperando.
- O merge é do mantenedor, num merge commit (DEC-0028).

## Agentes de código

O projeto é feito com o Claude Code. O `AGENTS.md` traz as instruções dos agentes, escritas para o fluxo do mantenedor; as regras de código, de teste e de idioma dele valem para todo mundo, com ou sem agente.

## Convivência e segurança

Todos seguem o [código de conduta](CODE_OF_CONDUCT.md). Falha de segurança não vai em issue pública: veja o [SECURITY.md](SECURITY.md).

## English summary

Thanks for your interest! Jogo Acrobático is an open hobby project with one lead maintainer, Arthur Gustavo, who sets the game's direction.

- Small fixes can go straight to a pull request. For bigger changes (new mechanics, design numbers, architecture, new dependencies), open a Discussion or an issue first. Project decisions live in `docs/decisoes/` and are the maintainer's.
- Set up Godot 4.7.2, gdscript-formatter 0.27.0, gitleaks 8.30.1, lefthook and Git LFS. Run `git lfs install`, `lefthook install` and `godot --headless --path . --import`, then `bash tools/gate.sh`, which must pass. The same gate runs on pre-push and in CI. Never bypass or weaken a check, and never edit a locked test.
- Statically typed GDScript; pure simulation rules in `core/`, with gdUnit4 tests. Code and comments are in English; commit messages and pull request descriptions are in Portuguese.
- Third-party assets need a license that allows redistribution in a public repository, and go under `assets/third_party/` with their license file and a row in `assets/CREDITS.md`.
- Under section D.6 of GitHub's Terms of Service, your contribution is licensed under the repository's licenses (MIT for code, CC BY 4.0 for original assets). There is no CLA.
- CI for pull requests from forks runs only after the maintainer approves it. The maintainer merges with a merge commit.
- Follow the Code of Conduct, and report security issues privately as described in SECURITY.md.
