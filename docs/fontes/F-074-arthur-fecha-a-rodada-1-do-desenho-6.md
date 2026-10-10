---
id: F-074
titulo: O Arthur fecha a rodada 1 do Desenho 6 — o esqueleto andante neste PC com a imagem do servidor testada no CI, a VPS em São Paulo na fase 3, e o fechamento limpo por comando próprio com o tini de rede de segurança (sessão 10, 10/10/2026)
recebido_em: 2026-10-10
como: Respostas escolhidas nas opções de uma pergunta do Claude Code com três questões. Texto das perguntas, dos rótulos e das descrições como foram mostrados.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: as perguntas da rodada 1 vieram depois da sonda (F-073) e do que o Arthur sentiu (F-072), antes do ping no horário de pico, que segue pendente. As decisões viram DEC no fechamento da TASK-8.

## §1 — As respostas

Pergunta: "Pergunta fixa: deu para entender o que a sonda mostrou e o que estas duas perguntas decidem?"

Resposta: "Entendi", cuja descrição dizia: "O servidor num contêiner sobe em 1,5 s e gasta ~14% de um núcleo em São Paulo, com ping estável de 37 ms no jogo; agora a gente decide onde roda o servidor do esqueleto andante e como ele fecha."

Pergunta: "Onde roda o servidor do esqueleto andante (TASK-9), e qual a direção para as fases seguintes?"

Resposta: "PC + imagem no CI (Recomendado)", cuja descrição dizia: "O servidor e os clientes neste PC, como a TASK-9 já diz, e a imagem Docker do servidor construída e testada no CI a cada push. Nada pago até a fase 3; aí, uma VPS em São Paulo (US$ 7,50/mês); a Edgegap grátis para testes de 60 minutos."

Pergunta: "Hoje o servidor morre pelo sinal de parada (saída 143). Como o esqueleto andante fecha?"

Resposta: "Comando próprio + tini (Recomendado)", cuja descrição dizia: "O servidor fecha limpo por um comando nosso: para o tick, fecha a conexão e sai com 0, como a TASK-9 já pede no PC (DEC-0026 §6). O tini fica como rede de segurança no contêiner, e o teste confere a saída 0."
