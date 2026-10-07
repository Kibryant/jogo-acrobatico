---
id: F-046
titulo: O Arthur fecha a rodada 3 do Desenho 4 — entende as builds, a versão e o fluxo, quer a build no PR e na tag e fecha versões e fluxo com os padrões (sessão 7, 07/10/2026)
recebido_em: 2026-10-07
como: Respostas escolhidas nas opções de uma pergunta do Claude Code na sessão 7, depois da rodada 3 da TASK-6. Texto das perguntas, dos rótulos e das descrições como foram mostrados.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: na rodada 3, o Arthur baixou pelo editor os templates de Windows e Linux e olhou os dois presets no clone `../export-sonda`. O Claude exportou os dois neste PC e numa branch de sonda no CI, rodou o servidor exportado no Linux e o .exe feito no Linux neste PC (F-045). A vitrine ganhou a seção "A rodada 3" e as propostas nos cartões "A cota", "As versões" e "O fluxo" (versão 8).

## §1 — As respostas

Pergunta: "Pergunta fixa: deu para entender como o projeto vira as duas builds, o que a versão e o commit carimbado fazem e como fica o fluxo de branch e PR?"

Resposta: "Entendi"

Pergunta: "Quando a build sai no CI?"

Resposta: "No PR e na tag (Recomendado)"

A opção dizia: "A build de cada PR fica 3 dias, para você jogar antes do merge; a da tag vira release e fica para sempre. Push na main não gera build. No pior caso, uns 200 MB da cota."

Pergunta: "Versões e fluxo (cartões \"As versões\" e \"O fluxo\" da vitrine): fecho com os padrões?"

Resposta: "Pode fechar (Recomendado)"

A opção dizia: "SemVer 0.y.z (o y sobe a cada marco do roteiro, o z a cada build que sai), commit carimbado, tag com release e o aperto de mão; a task Ready na main, uma branch por task do In Progress ao Done, PR em português, você no merge (merge commit) e um worktree por sessão paralela."

## §2 — As versões, como a vitrine as mostrou

- "O número: SemVer `0.y.z`, só dígitos e pontos. O `0.1.0` vira `0.1.0.0` nas propriedades do .exe, como a sonda mostrou (F-045 §2)."
- "Quando sobe, na proposta: o `y` sobe quando um marco do roteiro fecha. O 0.1.0 é o esqueleto andante, o 0.2.0 a fase 1, o 0.3.0 a fase 2, e assim por diante; o 1.0.0 é o lançamento. O `z` sobe a cada build que sai para alguém jogar dentro de uma fase."
- "Onde mora: em `application/config/version`, no `project.godot`, com um teste que confere o formato. O CI carimba o commit em `application/config/commit` na hora do export; no editor, ele fica vazio."
- "A tag e as notas: a tag `v0.y.z` vira uma release no GitHub, privada, com as duas builds e notas em português tiradas do diário."
- "O aperto de mão: o cliente manda versão e commit ao conectar, e o servidor recusa os diferentes, pedindo para atualizar. No rollback, os dois precisam rodar a mesma regra (DEC-0026). Mora na Main, na TASK-9."
- "A ligação com o replay: o cabeçalho do arquivo leva a mesma versão e o mesmo commit (F-044 §2)."

## §3 — O fluxo, como a vitrine o mostrou

1. "A task fica Ready na main, no papel, como hoje."
2. "No In Progress, nasce uma branch curta, `task-N-nome`, e todo commit da task vai nela: código, docs e o diário das sessões dela."
3. "No fim, o Claude abre o PR em português, com o que mudou, os critérios, como testar e o link da build. A task vira Done dentro do PR."
4. "O CI roda no PR: o portão e as duas builds."
5. "Você revisa e joga a build, e o merge é seu, ou do Claude com o seu ok, num merge commit: os commits das rodadas ficam, e desfazer a task inteira é um revert só."
6. "Sessão sem task, só de diário ou de decisão, vai direto na main."
7. "Duas sessões ao mesmo tempo nunca na mesma pasta: cada uma no seu worktree. Já aconteceu três vezes (registro da harness), e as branches de sonda desta TASK-6 rodaram assim."
