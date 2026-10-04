---
id: F-030
titulo: O Arthur fecha a rodada 1 do Desenho 3 — entende o que a sonda mostrou, escolhe 60 ticks por segundo (Q-01) e o contorno D da hipótese 3 (sessão 4, 04/10/2026)
recebido_em: 2026-10-04
como: Respostas escolhidas nas opções de uma pergunta do Claude Code na sessão 4. Texto das perguntas, dos rótulos e das descrições como foram mostrados.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: fim da rodada 1 do Desenho 3 (TASK-5). Antes de perguntar, o Claude mostrou na vitrine da rede (versão 6) e no terminal o que saiu das F-024 a F-029. Mostrou também as duas decisões como trade-off, cada uma com uma recomendação:
>
> - a Q-01, 60 ou 30 ticks. A recomendação era 60: o roteiro vai do 1v1 primeiro; o 4v4 precisa de otimização de qualquer jeito (Q-09); a F-007 §8 chama de armadilha desenhar o 8v8 antes de o 1v1 ser divertido; e o tickrate é um parâmetro (DEC-0022);
> - o contorno da hipótese 3. A recomendação era a variante D.

## §1 — As respostas

Pergunta: "Pergunta fixa: deu para entender o que a rodada 1 mostrou (as três hipóteses, o custo de 30 contra 60 e por que o parry falha com lag)?"

Resposta: "Entendi"

Pergunta: "Q-01: com quantos ticks por segundo o jogo nasce?"

Resposta: "60 ticks (Recomendado)"

A opção dizia: "O parry que você sentiu (72% contra 50%) e os números do design fiéis. Custa de 2 a 3,6 vezes a CPU de refazer; o 4v4 se revê na Q-09."

Pergunta: "Hipótese 3: qual contorno para o 'estava no chão' do motor?"

Resposta: "D, flag alinhado (Recomendado)"

A opção dizia: "Zero divergências a 30 e a 60, com um movimento extra por rollback. A SyncTest no CI vigia se o Godot mudar."
