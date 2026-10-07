---
id: F-044
titulo: O Arthur fecha a rodada 2 do Desenho 4 — entende as camadas e o replay, quer a gravação na fase 1 e fecha as quatro escolhas com os padrões (sessão 7, 07/10/2026)
recebido_em: 2026-10-07
como: Respostas escolhidas nas opções de uma pergunta do Claude Code na sessão 7, depois da rodada 2 da TASK-6. Texto das perguntas, dos rótulos e das descrições como foram mostrados.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: a rodada 2 mediu o replay por inputs e a SyncTest (F-042). O Arthur jogou a sonda do replay duas vezes e contou o que sentiu (F-043). A vitrine ganhou as seções "A rodada 2" e "A SyncTest e o relógio" e as escolhas da rodada (versão 6).

## §1 — As respostas

Pergunta: "Pergunta fixa: deu para entender as cinco camadas de teste (o que cada uma pega e quanto gasta) e o que o replay precisa proteger desde já?"

Resposta: "Entendi"

Pergunta: "Quando a gravação do replay começa no jogo de verdade?"

Resposta: "Na fase 1 (Recomendado)"

A opção dizia: "Quando você achar um bug jogando o movimento, o arquivo de teclas vai junto, e o Claude refaz sem tela, em milissegundos. Você também revê a sua jogada, como na sonda. Custa um gravador pequeno na TASK-10."

Pergunta: "As quatro outras escolhas da rodada 2 (seção \"O plano\" da vitrine): SyncTest com os ticks à mão, a referência na TASK-9 com números congelados, um portão só abaixo de 90 s e o que proteger desde já. Fecho com os padrões?"

Resposta: "Pode fechar as quatro (Recomendado)"

A opção dizia: "Viram parte da DEC de testes e entrega no fim da TASK-6, e da TASK-9."

## §2 — As quatro escolhas, como a vitrine as mostrou

1. "A SyncTest da TASK-9 avança os ticks à mão, como a suíte do próprio netfox (`test/network-mocks.gd`), rodando o rollback de verdade dele, e fica no portão. Pelo relógio, os quatro cenários custariam uns 25 s (F-042 §1). Ela mexe em funções internas do netfox, mas ele está fixado no `cf5189d`: atualizar já é uma DEC nova, com a SyncTest de novo."
2. "O replay como referência nasce na TASK-9: um percurso de bot, com o hash conferido no portão, no Windows, e no CI, no Linux. Ele usa uma cópia congelada dos números do movimento, só para o teste: o ajuste fino do jogo não quebra a referência, e só uma mudança de código quebra. Regravar é um comando, como o `jest -u`, e o commit diz por quê."
3. "O portão continua um só, no pre-push e no CI, abaixo de 90 s (DEC-0006). Hoje ele está em 31 s, e a SyncTest à mão e a referência cabem com folga. Quando uma camada não couber, ela vira um job do CI fora do pre-push, com uma DEC."
4. "O que proteger desde já para o replay: o input que vale é o que o servidor aplicou; todo sorteio tem semente e mora no estado; o núcleo não lê relógio (DEC-0004); o cabeçalho leva formato, versão, commit, plataforma, ticks por segundo, arena, semente e configuração. Vai para o `testes-e-entrega.md` e para a DEC."
