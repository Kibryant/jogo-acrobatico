---
id: F-021
titulo: O Arthur fecha a rodada 2 do Desenho 2 — entende cena, nó e autoload, quer zero autoloads nossos e acesso inseguro como erro, com o furo do portão na TASK-6 (sessão 3, 02/10/2026)
recebido_em: 2026-10-02
como: Respostas escolhidas nas opções de uma pergunta do Claude Code na sessão 3. Texto das perguntas e dos rótulos como foram mostrados.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: rodada 2 do Desenho 2 (TASK-4), já no formato da DEC-0021. O Claude explicou nó, cena, script e autoload com exemplos do React e do TypeScript, e mostrou as cenas, as pastas, os autoloads e os acessos inseguros como trade-off. Antes de perguntar, contou o que achou numa sonda: hoje o portão não pega nem a tipagem obrigatória num script que nenhum teste carrega, e compilar todos os scripts numa execução só do Godot leva 1,3 s.

## §1 — Respostas

Pergunta: "Pergunta fixa: deu para entender o que são cena, nó e autoload, e por que a gente decide a árvore de cena agora, com os caminhos do netfox funcionando como rotas de API?"

Resposta: "Entendi"

Pergunta: "Autoloads nossos: quantos?"

Resposta: "Zero nossos (Recomendado)"

Pergunta: "Acessos inseguros (o any do GDScript): o que fazemos?"

Resposta: "Erro, e o furo na TASK-6 (Recomendado)"

A opção dizia: "O project.godot e o teste mudam agora (critério 3). O passo novo do portão, que compila tudo em 1,3 s, entra na TASK-6 junto com o furo da pureza, antes de qualquer código de jogo."
