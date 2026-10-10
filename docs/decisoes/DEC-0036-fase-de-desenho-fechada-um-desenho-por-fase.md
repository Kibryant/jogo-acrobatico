---
id: DEC-0036
titulo: A fase de desenho fechou — um desenho de jogo por fase, na abertura da fase
data: 2026-10-10
status: aceita
decidido_por: Arthur (F-082 §3)
fontes: [F-035, F-082, F-083]
substitui:
substituida_por:
---

# DEC-0036 — A fase de desenho fechou: um desenho de jogo por fase, na abertura da fase

## Contexto

A DEC-0012 abriu a fase de desenho com seis conversas e um esqueleto andante, e disse o que se decide "agora, dentro da fase" e o que fica "na hora da funcionalidade". As seis conversas fecharam entre 02/10 e 10/10/2026 (TASK-3 a TASK-8), cada uma com as suas DECs, da DEC-0013 à DEC-0035 (F-083 §1). A DEC-0012 não dizia quando a fase termina, nem onde o desenho do jogo em si acontece: vida, partida, modos, armas e mapas foram para "a hora da funcionalidade" sem a hora ter nome.

O Arthur perguntou duas vezes se vai ter desenho do jogo em si e se falta algum desenho antes de codar (F-035 §1; F-082 §1). Hoje ele pediu para bater o martelo e nunca mais reabrir: "bate martelo hoje do que fechou, fechou. E eu nunca mais nunca mais pergunto. E se eu perguntar, você tem que falar que já está fechado" (F-082 §1), conferindo "não só o que está dentro do repositório" (F-082 §2).

A conferência (F-083) não achou camada de base faltando: cada item do "agora" da DEC-0012 tem DEC aceita (F-083 §1), e o que a pré-produção costuma pedir está na base, menos o protótipo jogável do loop, que é a fase 1 (F-083 §2). Achou cinco coisas sem nome, nenhuma de base: a vida do lutador e o formato da partida, o hitstop, o modo do 4v4 e do 8v8, a hora do arco e das armas no roteiro e o gamepad (F-083 §5). As fontes de fora apontam o risco oposto ao temido: documento grande antes do protótipo, e meses de netcode antes de saber se o jogo diverte (F-083 §3 e §4).

## Opções consideradas

1. **Reabrir a fase com um "Desenho 7", o jogo em si:** armas, personagens, mapas, modos e vida no papel, agora. Rejeitada: os números se julgam jogando (DEC-0017), e o duelo depende do que só o movimento jogado mostra, como o alcance de um golpe contra 7 m/s de corrida ou a janela do parry vista pela câmera a 3,5 m. Seria chute no papel sobre chute no papel, e é o erro que as fontes de fora mais avisam (F-083 §3).
2. **Não registrar nada e deixar "a hora da funcionalidade" implícita:** a pergunta voltaria a cada sessão, como voltou em 04/10 e em 10/10.
3. **Fechar a fase e marcar um desenho de jogo por fase, na abertura da fase, com a lista nomeada:** a escolhida.

## Decisão

Aceita pelo Arthur em 10/10/2026: "eu concordo com a proposta" e "sim, pode registrar" (F-082 §3).

1. **A fase de desenho da DEC-0012 está fechada em 10/10/2026.** Não se abre desenho de base novo. A resposta a "falta desenho?" é esta DEC, e o Claude não reabre a conversa: responde que está fechado e aponta para cá (F-082 §1).
2. **O desenho de jogo acontece um por fase, como a primeira rodada da fase,** dentro da task-mãe da fase e com a mesma mecânica dos seis desenhos: vitrine quando houver número (DEC-0019), números v0 fechados pelo Claude e julgados pelo Arthur jogando (DEC-0017), decisões de identidade do Arthur em DEC. A lista, com o que cada desenho fecha:

| Quando | O desenho | O que fecha |
|---|---|---|
| Fase 1 (TASK-10) | Nenhum papel novo: os v0 estão no `movimento.md` | Em aberto, pelo jogo: Q-07, Q-13, Q-16; a bancada do Mac, Q-24 |
| Fase 2 | O desenho do duelo | A vida do lutador e o formato da partida (Q-29); o tranco (Q-10); a matriz de posição (Q-14); a janela do parry (Q-21); a quebra de guarda (Q-25); o golpe que acerta uma vez (Q-26); o hitstop; o bot de reação de gente (F-029); o percurso cronometrado (`roteiro.md`); o relatório de crash pelo log (DEC-0034) |
| Fase 3 | O 1v1 online | O lag switch e a conferência do `view_lag` (Q-17); a VPS em São Paulo (DEC-0032); o Sentry (DEC-0034) |
| Entre a fase 3 e a 4 | O arco e as armas | O marco da DEC-0004, regra 6; o tiro a favor de quem ataca (DEC-0011); as armas além das três (Q-11); os corpos (Q-12) |
| Antes da fase 4 | O anti-hack e o 4v4 | A proteção contra hack (Q-19); o `view_lag` por oponente (Q-18); o modo do 4v4 e do 8v8 (Q-30); salas, matchmaking, contas, ranking e o replay para o jogador (DEC-0034; DEC-0011); a Steam e a idade (Q-28) |
| Fim da fase 1 e fase 5 | O nome, a Steam, os mapas e a arte final | O nome definitivo e o INPI (Q-27); a Steam (DEC-0034); os mapas e a arte final (DEC-0012) |

3. **O que aparecer fora da lista vira Q em `pendencias.md`,** com a fase onde se resolve, nunca uma fase de desenho nova. O gamepad é o primeiro caso (Q-31).
4. **Nada aqui muda as regras da base:** as DECs da DEC-0013 à DEC-0035 continuam valendo como estão.

## Consequências

- O `roteiro.md` ganha a linha do fechamento e a linha do arco e das armas entre a fase 3 e a 4.
- As `pendencias.md` ganham a Q-29 (vida e formato da partida), a Q-30 (modo do 4v4 e do 8v8) e a Q-31 (gamepad).
- O glossário ganha o hitstop, ainda sem número: ele é v0 do Claude na fase 2 (DEC-0017).
- A DEC-0012 fica completada por esta: o fechamento e o desenho por fase.
- O risco real, de nenhum número ter sido sentido, continua, e o roteiro já o trata: a fase 1 só passa com "divertido sozinho por 15 min?" (F-001), e nada se constrói em cima antes disso.

## Revisitar se

- A fase 1 falhar no teste "divertido sozinho por 15 min?" e a causa for uma camada de base, não um número. Número se troca no Resource; camada pede DEC.
- O desenho de uma fase mostrar que uma regra de base (DEC-0022 a DEC-0026) não comporta o duelo. Aí a mudança é uma DEC com `substitui`, não um desenho novo.
