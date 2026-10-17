---
id: F-085
titulo: O Arthur aceita o conserto do portão e erra a conferência do tick perdido (sessão 13, 17/10/2026)
recebido_em: 2026-10-17
como: Respostas escolhidas nas opções de uma rodada de perguntas do Claude Code, depois da rodada B1 da parte 1 da TASK-9. Texto das perguntas, dos rótulos e das descrições como foram mostrados.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: a rodada B1 da parte 1 da TASK-9 (as cenas, o input e o modo Sozinho) voltou do implementer com o portão verde (229 testes) e duas descobertas. Primeira: sem notícia da rede, como no Sozinho, o netfox simula só o último tick de um loop; num frame de dois ticks, o primeiro some, com o movimento e o pulo dele. O `Match` passou a pedir o primeiro tick do loop (`docs/mudancas.md`, 17/10/2026). Segunda: a checagem de compilação do portão (`tools/check_scripts.gd`) rodava no `_init()`, antes de o Godot registrar os autoloads, e reprovava todo script que nomeia o `NetworkTime`. O implementer trocou para o `_initialize()` e pôs as primeiras exceções do linter no repositório: 4 linhas no ajudante de teste que move o relógio do netfox na mão (DEC-0027 §3). O Claude conferiu o código do netfox (`network-rollback.gd`, `_rollback`), rodou o portão (verde em 52 s) e explicou as duas coisas, com o laço `for` do TypeScript para o tick perdido. A conferência errou. O Claude explicou de novo, nomeando a ideia errada: o pulo dobrado é o problema que o comando de um toque já resolvia, e o do netfox era um tick a menos. Usou uma planilha com uma linha por tick e o Flash do LoL que o servidor nunca registra, sem pergunta nova; a próxima conferência vem com a proposta do `rede.md`, no fechamento da parte 1. O ok do portão valeu, por ser outro assunto.

## §1 — A rodada da B1

Pergunta: "Antes do conserto, o que acontecia no Sozinho quando um frame atrasado rodava dois ticks de uma vez?"

Resposta: "Os dois rodavam, pulo dobrado"

A opção dizia: "Cada tick rodava, mas um aperto do pulo contava duas vezes." A esperada era "Só o segundo tick rodava", cuja descrição dizia: "O primeiro tick nunca era calculado."

Pergunta: "A checagem de compilação do portão rodava antes de o netfox carregar e reprovava código válido. Aceito o conserto?"

Resposta: "Aceita os dois (Recomendado)"

A opção dizia: "O conserto de uma linha na checagem e as 4 exceções declaradas ao linter no ajudante de teste. As checagens não mudam, e os scripts de teste da checagem continuam reprovando os ruins."
