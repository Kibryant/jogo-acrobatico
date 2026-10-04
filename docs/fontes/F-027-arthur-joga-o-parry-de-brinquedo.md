---
id: F-027
titulo: O Arthur joga o parry de brinquedo — o primeiro era ilegível; com lag ele quase não defende, e sem lag defende metade a 30 ticks e 72% a 60 (sessão 4, 04/10/2026)
recebido_em: 2026-10-04
como: Mensagens do Arthur na sessão 4, escritas e por voz transcrita, sem correção, mais o resumo dos logs das partidas que ele jogou com `play.sh` (`C:\Users\arthu\Projects\netfox-sonda\sonda\runs\play-you-*.out`), feito pelo `analyze_parrier.py`.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: rodada 1 do Desenho 3 (TASK-5). O parry de brinquedo é a sonda da F-025 com um bot atacante. Ele usa o golpe leve do v0 (300 ms de preparação, 100 de ativo, 250 de recuperação) e a janela de parry de 80 ms (`combate.md`). O alcance de 2,5 m é número de brinquedo, não de design. O servidor julga o parry no relógio dele, que é o que o netfox faz sozinho. O ping vem do simulador do netfox.

## §1 — O primeiro brinquedo

"Ou deixa eu te falar o bot nao se mexeu em nenhum momento, e os ataques ficaram aumentando sem eu atacar e sem eu me defender o bot tava 100% parado"

O que o Claude achou depois, por prints da tela:

- o bot ficava parado de propósito, e o Claude não tinha avisado;
- o golpe acertava a qualquer distância;
- a câmera, fixa e longe, deixava as cápsulas miúdas.

O brinquedo foi refeito: o bot anda até a pessoa, só acerta ao alcance, tem o letreiro "PREPARANDO" / "GOLPE!", e a câmera fica de lado. O log também mostrou um defeito no julgamento: um F no mesmo tick do golpe não contava, e a janela real era de 1 tick. Foi corrigido antes dos jogos do §3.

## §2 — O que ele disse durante os jogos

"Ou, nao consegui da um parry mesmo spawmando o f (literalmente fiquei apertando desde antes aparecer ate o final nesse primeiro teste, vou mandar so para registrar, vou testar os outros, enquanto voce estava ai eu testei o segundo (60 100), e consegui da parry, vou rodar aqui para voce ter os logs, to so registrando espera eu testar o segundo, o jogo nao travou nn, rodou bem, vou testar agora o segundo"

"É, aproveitando aqui, vou dar um feedback. Eu sei que é dev e tal, mas, caralho, eu, eu, talvez tenha sido, pode ser eu, mas eu não consegui Assim, eu consegui alguns, mas eu fui bem pouco. Eu não consegui dar muito parrys, ou meu reflexo esta ruim ou e dificil mesmo kkkkkkkk, so dando feedback"

O "primeiro teste" da primeira citação é o jogo de 30 ticks com ping 100 na versão com o defeito do §1: 36 golpes, 33 levados, 3 errados por distância e nenhum parry, com uns 230 apertos de F.

## §3 — As partidas, na versão corrigida

| Jogo | Golpes ao alcance | Parries | Taxa | Atraso dos F que perderam, mediana (ms) | Apertos de F |
|---|---|---|---|---|---|
| 30 ticks · ping 0 | 21 | 10 | 48 % | 84 | 29 |
| 60 ticks · ping 0 | 18 | 13 | 72 % | 75 | 16 |
| 30 ticks · ping 100 | 18 | 7 | 39 % | 67 | 246 |
| 60 ticks · ping 100 | 23 | 3 | 13 % | 67 | 79 |
| 30 ticks · ping 220 | 25 | 5 | 20 % | 133 | 174 |
| 60 ticks · ping 220 | 40 | 8 | 20 % | 167 | 147 |

- Ordem em que ele jogou: 60 · 100, 30 · 220, 60 · 220, 30 · 100, 30 · 0 e 60 · 0. O jogo de 60 sem lag foi o último, depois de todo o treino.
- O ping medido foi de uns 115 ms no "ping 100", 232 ms no "ping 220" e 15 a 16 ms no "ping 0".
