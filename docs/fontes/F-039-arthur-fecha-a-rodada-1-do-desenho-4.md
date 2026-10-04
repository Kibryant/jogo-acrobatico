---
id: F-039
titulo: O Arthur fecha a rodada 1 do Desenho 4 — entende o portão e os hooks, deixa o Bash sem guarda por enquanto e mantém o log limpo como regra (sessão 6, 04/10/2026)
recebido_em: 2026-10-04
como: Respostas escolhidas nas opções de duas perguntas do Claude Code na sessão 6, antes e depois da rodada 1 da TASK-6. Texto das perguntas, dos rótulos e das descrições como foram mostrados.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: com a TASK-6 Ready (F-038), o Arthur escolheu começar a rodada 1 na mesma sessão. As sondas do "antes", num clone fora do projeto (`../esteira-sonda`), provaram os dois furos: `var label := "#%d" % randi()` em `core/` passou na pureza, e `var count = 5` mais `body.velocity.length()` em `core/` deixaram o portão inteiro verde (41 s). Sem o `-d`, o gdUnit4 não travou num erro de sintaxe (saída 105) e relatou falhas e erros de execução como antes. O implementer fez os consertos e achou, com sondas, dois fatos do Godot 4.7.2: um script quebrado carrega como um Script que não instancia, em vez de `null`, e strings de aspas simples ou duplas também podem ocupar várias linhas. O Claude conferiu por conta própria: o portão verde em 31 s, sem linha de erro no log; no clone, cada furo fechado; cada checagem estragada de propósito fez os canários gritarem. Os dois hooks valeram nesta sessão sem reiniciar: o Edit e o Write num teste travado foram negados, e o Edit de um subagente também; um `.gd` torto voltou formatado. A vitrine ganhou a seção "A rodada 1" (versão 4).

## §1 — Começar a rodada 1

Pergunta: "Próximo passo: começo a rodada 1 do Desenho 4 agora, ou fecho a sessão?"

Resposta: "Começa a rodada 1 (Recomendado)"

## §2 — As respostas da rodada 1

Pergunta: "Pergunta fixa: deu para entender o que a rodada 1 mudou no portão e nos hooks, e por que o hook do Claude é só guarda-corpo (a trava de verdade continua no portão)?"

Resposta: "Entendi"

Pergunta: "Escrita pelo Bash num teste travado (um sed -i, um >): o hook também barra?"

Resposta: "Não, por enquanto (Recomendado)"

A opção dizia: "O sha256 do portão barra no push. Se um agente tentar esse atalho uma vez, o registro da harness pede a regra (DEC-0009)."

Pergunta: "Testes verdes com uma linha ERROR no log agora reprovam o portão (o #659 do netfox se escondeu assim: saída 0, erro só no log). Mantém?"

Resposta: "Mantém, reprova (Recomendado)"

A opção dizia: "Um push_error do nosso código ou um erro do motor durante os testes derruba o portão. Um teste que espera um erro vai precisar de um jeito explícito de dizer isso, quando aparecer."
