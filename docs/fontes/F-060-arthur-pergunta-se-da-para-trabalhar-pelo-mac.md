---
id: F-060
titulo: O Arthur pergunta se consegue usar o Claude no projeto pelo MacBook quando não está no PC, em viagem, se é muito complicado e qual seria a melhor opção (sessão irmã da sessão 8, 07/10/2026)
recebido_em: 2026-10-07
como: Mensagem por voz numa sessão irmã da sessão 8 (TASK-7), aberta no mesmo clone. Texto como chegou, sem correção.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: o Arthur tem um PC com Windows 11, que é a máquina mínima do jogo (DEC-0002) e onde ficam o Godot, as ferramentas e os hooks (AGENTS.md), e um MacBook. Ele não decidiu nada: perguntou e pediu conversa. A sessão irmã respondeu com as opções (o Mac como segunda bancada com o git de ponte, o Remote Control do Claude Code com o PC ligado em casa, e o Claude Code na web) e com o que nos scripts e hooks é específico do Windows. A decisão, se vier, fica em outra fonte.

## §1 — A mensagem

"Uma coisa, é, eu vou eu consigo fazer o projeto às vezes pelo Mac, eu tenho um MacBook aqui, e aí eu queria saber se alguma, tipo assim, eu tenho um MacBook, eu tenho um PC e em alguns momentos eu não vou estar presente aqui no meu PC para eu conseguir usar o Windows, teria como eu mexer pelo Mac e conseguir codar? Codar não, né? Conseguir usar o Claude para usar você, né, para conseguir fazer as coisas, ou seria tipo muito complicado? O que que você acha? Qual seria a melhor opção? Para quando eu viajar, esse tipo de coisa, parar de mexer, tentar mexer, é, faz sentido, não faz? O que que você acha? Vamos conversar"

## §2 — A resposta

> Contexto, escrito pelo agente: a sessão irmã respondeu com três jeitos de trabalhar longe do PC (o Mac como segunda bancada, com o git de ponte; o Remote Control do Claude Code, com o PC ligado em casa; o Claude Code na web), recomendou a segunda bancada como plano principal e o Remote Control como complemento, e fez três perguntas: uma de entendimento (onde o Godot roda no Remote Control), qual é o Mac, e o que ele quer fazer em viagem. Ele respondeu assim.

"Ah, ele fica, ele obriga a PC a ficar ligado porque ele vai continuar, ele vai ser controlado online, né? Então, por isso que ele precisa ficar ligado. É... Tá. Ah, meu Mac é um Apple linha M. Ele é do. Qual o nome que dá? Ah, esqueci, mas é o, é o chip da Apple, não é o Intel, não. Acho que é o Mac OS 26, 27, sei lá. É o mais recente. É um M4, é um Air M4. É... é, na verdade o ponto 3 aí eu faço na. Não pega muita viagem nisso não, só salva tudo isso aí, manda para outra seção, no caso, né, a seção que está aberta lá, essa mensagem, deixa ela se virar com as informações. Eu só quero só saber, eu só queria saber só a possibilidade, mas eu sei que você já deu, então só salva isso pra, lá para ela, envia para ela tudo isso daí, minha resposta, enfim, é isso."

## §3 — O que a sessão irmã verificou (escrito pelo agente, 07/10/2026)

- O repositório está no GitHub (`Kibryant/jogo-acrobatico`), com Git LFS e `eol=lf` no `.gitattributes`: um clone no Mac fica idêntico ao do PC.
- A gate já roda no Windows (Git Bash) e no CI (`ubuntu-24.04`). Para o macOS, duas diferenças, de uma linha cada: `tools/check_test_locks.sh` e o comando de trava do orquestrador usam `sha256sum`, que o macOS não traz (tem `shasum -a 256`, mesmo formato); os hooks `.claude/hooks/format_gd.sh` e `guard_locked_tests.sh` chamam `python`, que o macOS não traz (só `python3`). `tools/lib.sh` já aceita um `godot` no PATH ou `GODOT=`: basta um script de uma linha em `~/.local/bin/godot` apontando para `Godot.app/Contents/MacOS/Godot`.
- Ferramentas com versão para Mac: Godot 4.7.2 (binário universal); gdscript-formatter 0.27.0 publica `macos-aarch64` e `macos-x86_64` (conferido com `gh release view 0.27.0 --repo GDQuest/GDScript-formatter`); backlog, lefthook, gitleaks, gh e git-lfs pelo Homebrew ou npm. O clumsy é só Windows e só importa com quatro clientes ou mais (F-023 §2).
- Remote Control (https://code.claude.com/docs/en/remote-control.md): `claude remote-control` na pasta do projeto, no PC; entra-se por claude.ai/code ou pelo app iOS/Android; precisa de plano Pro, Max, Team ou Enterprise com login pelo claude.ai; só HTTPS de saída, sem porta de entrada; o PC fica ligado com o terminal aberto; reconecta sozinho se a rede cair; terminal fechado é offline, e `claude remote-control --continue` retoma em até cerca de 4 h; pedidos de permissão esperam resposta e podem ir para o celular.
- Claude Code na web (https://code.claude.com/docs/en/claude-code-on-the-web.md e https://code.claude.com/docs/en/cloud-environments.md): script de setup em bash, como root, no Ubuntu 24.04, em cache se terminar em cerca de 5 min; a allowlist de rede padrão inclui os release assets do GitHub (onde os builds do Godot são publicados), não o godotengine.org; o Git LFS não está documentado; cerca de 4 vCPU, 16 GB e 30 GB; push e PR pelo GitHub App; `claude --teleport` traz uma sessão da nuvem para a CLI, `claude --cloud` manda da CLI para a nuvem.
- Por máquina, fora do git: histórico de conversas, memória automática do Claude, `~/.claude/settings.json` e `.claude/settings.local.json`. Pelo git: AGENTS.md, `.claude/settings.json`, hooks, agentes e skills.
- Recomendação dada: o Mac como segunda bancada (cerca de uma hora de instalação, uma vez, mais as duas linhas), o Remote Control como complemento para ausências curtas, a nuvem não agora. O git é a ponte: commit e push antes de sair do PC, pull no Mac, cada máquina um clone próprio (DEC-0028), e nunca sincronizar a pasta por iCloud, Drive ou OneDrive. Jogar e sentir continuam no PC, que é a máquina mínima (DEC-0002; F-055).
