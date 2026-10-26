---
id: F-155
titulo: O Arthur mantém a cabeça do outro proibida no v0, agora pelo jogo e não pela rede, e libera a correção de uma linha no teste travado que podia travar o portão (sessão 18, 26/10/2026)
recebido_em: 2026-10-26
como: Respostas do Arthur às duas perguntas do Claude no terminal da sessão 18, depois da conferência (F-154). Opções escolhidas, como chegaram.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: a sonda C mostrou que a cabeça do outro já não diverge no código de hoje, porque o snap de reserva da DEC-0037 a zerou; metade do motivo da primeira escolha da F-152 caiu. O laço da linha 918 do `test/core/fighter/movement_head_test.gd`, travado, não tinha limite e travaria o portão em vez de falhar com uma regra errada.

## §1 — As respostas

- "Agora que o rollback já está certo, a cabeça do outro continua proibida no v0?": "Continua proibida (Recomendado)". A opção dizia: "Pelo jogo, não pela rede: a cabeça não renova o pulo duplo (o encadeamento que você viu) nem vira um degrau de 1,8 m que passa do bloco de 3 m. A task segue como aprovada. Você decide de vez jogando, na TASK-10.8." A outra era "Liberar, a cabeça vira chão".
- "Libero a correção de uma linha no teste travado que pode travar o portão?": "Libera (Recomendado)". A opção dizia: "O laço da linha 918 ganha um limite de ticks e passa a falhar, em vez de travar, se a regra estiver errada. O teste exige o mesmo; eu travo de novo e registro no mudancas.md, como na F-143." A outra era deixar como está.
