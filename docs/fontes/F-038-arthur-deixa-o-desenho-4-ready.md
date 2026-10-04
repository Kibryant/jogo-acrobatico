---
id: F-038
titulo: O Arthur deixa o Desenho 4 Ready — entende o problema, erra duas vezes a conferência do replay por inputs e confirma as cinco escolhas (sessão 6, 04/10/2026)
recebido_em: 2026-10-04
como: Mensagem de abertura da sessão 6, seguida das respostas escolhidas nas opções de duas perguntas do Claude Code. Texto das perguntas, dos rótulos e das descrições como foram mostrados.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: refinamento da TASK-6 (Desenho 4). Antes de perguntar, o Claude mediu neste PC o portão (28 s de 90, com 17,7 s de `--import` e 7,6 s de testes), o gitleaks do pre-commit (1,7 s) e os 6 runs do CI no GitHub (21 a 29 s). Pesquisou as cotas do plano Free, os templates do Godot 4.7.2 e os hooks do Claude Code, e publicou a vitrine "A esteira por dentro" (https://claude.ai/artifact/L9FpEtDFoyGJYWLSR6TFA1). A primeira conferência errou. O Claude explicou de novo com o xadrez, o Redux e uma figura nova na vitrine (versão 2: as mesmas teclas tocadas com as regras da 0.2.0 e com as de uma 0.3.0 inventada, de pulo 0,9 m). A segunda conferência também errou. O Claude avaliou que o exemplo do LoL, na vitrine, pode ter puxado para a ideia de formato de arquivo, e explicou uma terceira vez com uma planilha, sem nova pergunta.

## §1 — A abertura

"Boa tarde, vamo fazer isso agora: deixa Ready o Desenho 4 (TASK-6)"

## §2 — As primeiras respostas

Pergunta: "Pergunta fixa: deu para entender qual problema o Desenho 4 resolve e o que a gente vai fazer nele?"

Resposta: "Entendi"

Pergunta: "Na quarta você acha um bug jogando a versão 0.2.0. Na sexta, o Claude já mudou o pulo e o jogo está na 0.3.0. O replay por inputs gravado na quarta reproduz o bug na sexta?"

Resposta: "Sim, as teclas são as mesmas"

A esperada era "Só rodando a build 0.2.0", cuja descrição dizia: "O replay roda o jogo de novo com aquelas teclas."

Pergunta: "As cinco escolhas (seção \"O plano\" da vitrine): fecho com os padrões e marco a TASK-6 como Ready?"

Resposta: "Pode fechar as cinco (Recomendado)"

## §3 — Depois da segunda explicação

Pergunta: "Nova conferência: por que o replay gravado na 0.2.0 não reproduz o bug na 0.3.0, se só o pulo mudou?"

Resposta: "O formato do arquivo muda"

A esperada era "A tecla leva a outro lugar", cuja descrição dizia: "A mesma tecla, rodando a regra nova do pulo, leva o boneco para outro lugar, e tudo depois muda junto."

Pergunta: "Com o replay explicado de novo: as cinco escolhas continuam valendo, com o replay no papel nesta task?"

Resposta: "Continuam as cinco (Recomendado)"

A opção dizia: "A TASK-6 vira Ready como está na vitrine. O replay sai da rodada 2 com o que proteger desde já, o formato e quando a gravação começa."

## §4 — As cinco escolhas, como a vitrine as mostrou

1. "A pauta em três rodadas, com o que o registro da harness mandou para cá: os dois ruídos do portão, a peneira da peneira e a regra do worktree."
2. "Os hooks do Claude Code no `.claude/settings.json` do projeto, versionados e valendo para toda sessão e todo subagente. Os scripts, em bash, leem o JSON com o Python que já está instalado: o `jq` seria ferramenta nova, e o portão continua sem Python. A prova é uma sessão real nesta máquina tentando editar um teste travado e salvar um `.gd` fora do formato."
3. "A build provada numa sonda. Os templates do 4.7.2 neste PC, só Windows e Linux, pelo baixador do editor: ~128 MB de download e ~360 MB no disco, em vez de 1,28 GB. Os dois presets exportados de verdade, com tamanho e tempo medidos, e uma branch de sonda no CI, com PR em rascunho fechado e apagado depois, como na TASK-2; cada push ainda pede a sua permissão. O `export_presets.cfg` entra no repositório. O job de build de verdade entra no CI no esqueleto andante (TASK-9, critério 3), já com o jogo."
4. "O replay fica no papel: o que proteger desde já, o formato e quando a gravação começa. O código nasce com a primeira necessidade."
5. "O fluxo de partida: trunk-based, com branch curta por task e PR, a escolha que já estava na task. A DEC sai na rodada 3; até lá, o commit segue direto na main, como hoje."
