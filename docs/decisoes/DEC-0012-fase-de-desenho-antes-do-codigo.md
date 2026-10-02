---
id: DEC-0012
titulo: Fase de desenho antes do código de jogo — seis conversas e um esqueleto andante
data: 2026-10-02
status: aceita
decidido_por: Arthur
fontes: [F-003, F-009, F-010]
substitui:
substituida_por:
---

# DEC-0012 — Fase de desenho antes do código de jogo: seis conversas e um esqueleto andante

## Contexto

O Arthur sente que faltam "alguns detalhes mínimos aí de, antes de, de sistema, de arquitetura, de design pra depois o jogo mesmo começar, começar o código de fato" (F-003 §4). Ele quer a base "muito bem feita, tudo bem estruturado", porque "o começo é o mais importante com IA" (F-003 §4).

No SkinHub, a DEC-0025 resolveu o mesmo problema com seis conversas curtas antes do código, cada uma terminando em documento e DEC, e um esqueleto andante como primeiro código (F-009).

## Opções consideradas

1. **Ir direto para o código de jogo**: é o mais rápido, mas o que é caro de mudar depois, como a rede e o estado da simulação, nasce sem desenho.
2. **Desenhar tudo, sem limite**: o risco é virar estudo sem fim.
3. **Fase de desenho curta, com saída definida**: a proposta.

## Decisão

Aceita pelo Arthur em 02/10/2026, na sessão 2: "Concordo com suas recomendacoes" (F-010 §2).

1. **Seis conversas**, cada uma terminando com um documento curto e com as decisões em DEC:
   1. o jogo no papel: pilares, movimento e combate em números (TASK-3);
   2. a arquitetura detalhada: estado, contextos, cenas e pastas (TASK-4);
   3. a rede: tick, input, rollback e compensação de lag, com o teste do netfox no 4.7.2 (TASK-5);
   4. testes, ambientes e entrega, que é o CI/CD (TASK-6);
   5. a base visual, de áudio e de interface (TASK-7);
   6. infraestrutura e serviços (TASK-8).
2. **O primeiro código é um esqueleto andante** (TASK-9): a cápsula em rede de ponta a ponta. O servidor dedicado roda com dois clientes e lag simulado, o CI fica verde e saem a build do Windows e a do servidor Linux.
3. **O que se decide agora e o que fica para a hora da funcionalidade:**

| Agora, dentro da fase | Na hora da funcionalidade |
|---|---|
| Números de movimento e combate v0 | Mapas, armas além das três primeiras |
| Forma do estado e do tick | Matchmaking e salas |
| Teste do netfox no 4.7.2 | Contas e ranking (Supabase) |
| Pipeline de CI, builds e versões | Steam e lançamento |
| Política de assets e tokens visuais do combate | Arte final |

## Consequências

- Nasce um marco, `m-0`, com as tasks TASK-3 a TASK-9.
- A fase 1 do roteiro, o movimento, só começa depois do esqueleto andante.

## Revisitar se

- A fase passar de 4 semanas a 10 horas por semana. Nesse caso, as conversas 5 e 6 encolhem para o mínimo que o esqueleto precisa.
- Uma conversa mostrar que faltou uma camada.
