---
id: F-167
titulo: O Arthur acha a escada em Z entre duas paredes e decide — a mesma parede vale de novo sem devolver o pulo duplo, antes da 0.2.0, e o canto da borda se mede agora (sessão 18, 26/10/2026)
recebido_em: 2026-10-26
como: Mensagem do Arthur no terminal da sessão 18, por voz, respondendo à pergunta de conferência do Claude sobre a mesma parede (DEC-0043), e as opções que ele escolheu nas três perguntas seguintes. Transcrito como chegou.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: o Arthur pediu para voltar para a mesma parede depois de ir e voltar com o pulo duplo, para dar um fake (F-166 §3). O Claude respondeu que concordava com o fake e não com tirar a regra: começar uma corrida na parede devolve o pulo duplo, e se a mesma parede valesse como nova, cada volta subiria 2,2 m sem fim, até o topo da borda de 50 m. Propôs que a mesma parede valha de novo sem devolver o pulo duplo, e perguntou, em aberto: "por que a mesma parede contando como nova vira escada, e o que na proposta faz a escada parar?". A vitrine "O teste da fase 1" (https://claude.ai/artifact/FwtupAUFCANw72rkedVZ7r) desenhou os três casos.

## §1 — A resposta à conferência

"Tá, você trouxe um ponto... Tipo assim, você trouxe um ponto, mas agora eu não sei também, acho que você vai me responder. Essa ideia da parede contando como nova vira escada, eu entendi, porque senão ele teria pulo infinito resetando ali toda hora, double jump. Mas aí entra um ponto que eu fiquei em dúvidas, que é... Ele tem esse reset infinito, não? Se ele for pra... Tipo assim, tem duas paredes lado a lado. Se ele vai pra uma, dando double jump, ele reseta na outra, volta dando double jump. Então ele continua sendo infinito também. Seria uma escada em Z infinita também, não? Ou eu tô louco?"

> Nota do agente: o Claude respondeu que sim, a escada em Z entre duas paredes já existe e já está no papel, limitada pela altura das paredes por escolha dele (`movimento.md`, "Corredor estreito"; F-135); que um par de paredes é um lugar que o mapa desenha, e uma parede só existe em todo lugar; e que a pergunta dele acertou os cantos da borda, onde duas bordas de 50 m formam um par, anotado na TASK-10.7 como "um especialista talvez escape por um canto", sem medida (`movimento.md`, "A borda").

## §2 — As escolhas

- "A mesma parede: como ela fica?": "Vale, sem devolver o pulo duplo (Recomendado)". A opção dizia: "Voltar para a mesma parede vale, mas ela não devolve o pulo duplo; só o chão ou outra parede devolvem. O fake sai uma vez, e a escada de uma parede só não nasce. Saindo de uma parede, o mais alto passa de +2,2 m para +3,4 m, uma vez." As outras eram "Fica como está" e "Vale como parede nova".
- "Quando a regra nova da parede entra?": "Antes da 0.2.0 (Recomendado)". A opção dizia: "Uma filha da TASK-10, com os testes do núcleo, antes de fechar a fase. A release sai com o movimento que você aprovou e com o fake. Custa uma task antes de começar a fase 2." A outra era "Na fase 2".
- "Os cantos da borda: o que fazer com o risco de alguém sair da arena em Z?": "Medir agora (Recomendado)". A opção dizia: "O implementer tenta o Z num canto da borda com uma sonda, nesta task. Se subir os 50 m, o plano de morte (cair fora da arena e voltar ao início) vira uma task antes da 0.2.0. Se não subir, a anotação vira medida." A outra era "Deixar anotado".
