---
id: F-057
titulo: O Arthur decide que não haverá MCP do Godot por enquanto, com um gatilho de dois níveis, e confirma o registro na sessão da TASK-7 (07/10/2026)
recebido_em: 2026-10-07
como: As duas mensagens do Arthur foram ditas por voz numa sessão irmã do Claude Code, aberta na mesma pasta (jogo-acrobatico-50), e chegaram à sessão 8 por mensagem entre sessões, com o texto como recebido lá. A confirmação veio na sessão 8, escolhida nas opções de uma pergunta do Claude Code, com o texto da pergunta e da opção como foram mostrados.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: na sessão irmã, o Arthur perguntou se valia construir um MCP do Godot. A recomendação que ele aceitou, resumida pela sessão irmã: um MCP é como um servidor Express que expõe funções tipadas, e um script em `tools/` é como um `npm run`; com um terminal, o script já é a ferramenta, e o MCP só se paga com estado entre chamadas ou com um cliente sem terminal. O registro do harness mostra que o atrito com o Godot até aqui foi de olhos (a sonda do parry chegou ilegível, TASK-5), de premissas erradas sobre o motor (TASK-6) e de um processo que ficou vivo em segundo plano (TASK-5); nenhum foi falta de uma ferramenta chamável. A sessão irmã acrescentou a Q-23 em `docs/pendencias.md` e pediu à sessão da TASK-7 a fonte, a resposta da Q-23, a nota no registro do harness e a frase no `AGENTS.md`. A pergunta de conferência da sessão irmã ("em que situação o MCP passaria a valer a pena?") ficou sem resposta. O primeiro script candidato da Q-23, rodar uma cena por N segundos e salvar o PNG e o log, é o que a sonda da rodada 1 do Desenho 5 fez à mão (F-056).

## §1 — As mensagens, na sessão irmã

Mensagem 1: "Uma dúvida, será que faz sentido a gente construir um MCP para o Godot, para a gente usar aqui localmente, enfim, até para a gente conseguir criar um bom MCP? Um MCP bem completo? Ou será que está dando conta, por enquanto, ou você acha que te, tem algum gatilho que a gente deveria deixar ativo para, tipo assim, olha, isso aqui deu muito trabalho para fazer assim, então será que se a gente criar um padrão, e aí a gente criaria um MCP no futuro, enfim, o que, que você acha de criar um MCP para usar o Godot, é, ou não, ou é loucura, ou seria, tipo, over-engineer agora, o que, que você acha, qual é, que é a sua opinião?"

Mensagem 2: "É, eu sigo com suas, suas recomendações aí, fez sentido. Mas só cuidado que tem agora uma sessão trabalhando aí na task 7. Então cuidado aí pra não... Manda uma mensagem pra ela que eu acho que vai ser melhor do que você mexer. Ela é a... Des... Na verdade, acho que ela tá na 5. Perdão. Uma sessão aí que está aberta agora, na verdade. Você vai conseguir identificar."

## §2 — A confirmação, na sessão 8

Pergunta: "A outra sessão aberta pediu que eu registre a sua decisão: nada de MCP do Godot por enquanto. O que se repete duas vezes vira script em tools/. O MCP só volta quando um script precisar guardar estado entre chamadas na mesma rodada, ou quando você quiser usar o Claude num cliente sem terminal. Isso põe uma frase nova no AGENTS.md. Confirma?"

Resposta: "Confirmo, pode registrar (Recomendado)"

A opção dizia: "Uma fonte com as suas palavras, a resposta da Q-23, a nota no registro do harness e a frase no AGENTS.md, no commit desta branch."
