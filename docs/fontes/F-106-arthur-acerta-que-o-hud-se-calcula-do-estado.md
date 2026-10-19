---
id: F-106
titulo: O Arthur acerta que a barra de stamina se calcula do estado exibido a cada quadro, na abertura da TASK-10.2 (sessão 14, 19/10/2026)
recebido_em: 2026-10-19
como: Resposta escolhida nas opções de uma pergunta do Claude Code na sessão 14, na abertura da TASK-10.2. Texto da pergunta, dos rótulos e das descrições como foram mostrados.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: a TASK-10.2 ficou Ready sem escolha para o Arthur, porque as escolhas já estavam na F-100 §1 e os números v0 são do Claude (DEC-0017; AGENTS.md). Antes do código, o Claude explicou uma ideia, o HUD que se calcula do estado a cada quadro, com o exemplo do render do React contra um `setInterval`, e fez a conferência (DEC-0021).

## §1 — A conferência

Pergunta: "Conferência (uma só é verdadeira): no jogo online, um rollback refaz os últimos ticks e a stamina corrigida sai diferente da que estava na tela. O que a barra mostra no quadro seguinte?"

Resposta: "A stamina corrigida"

A opção dizia: "A barra se calcula do estado exibido a cada quadro, então mostra o valor novo na hora."

As outras opções eram "A antiga, até o timer acabar", "As duas, piscando" e "Nada, até o próximo gasto".
