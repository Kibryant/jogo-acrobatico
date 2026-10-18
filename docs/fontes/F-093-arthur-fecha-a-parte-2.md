---
id: F-093
titulo: O Arthur erra duas vezes a conferência do simulador de lag, aprova o pacote de docs da parte 2 com a DEC-0038 e manda subir, abrir o PR e fazer o merge com o CI verde (sessão 13, 18/10/2026)
recebido_em: 2026-10-18
como: Duas rodadas de perguntas no terminal da sessão 13, com as opções escritas pelo Claude. As respostas estão como o Arthur escolheu.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: o revisor aprovou a parte 2 da TASK-9 (critérios 9 a 13), com achados para o fechamento:
> - duas citações erradas, já corrigidas no commit `c9af37c`;
> - os números v0 de engenharia sem casa nos docs;
> - a sessão do simulador sem DEC;
> - os docs desatualizados.
>
> O Claude mostrou o pacote de docs e explicou, numa ideia só, que o lag simulado só existe durante a sessão de teste: os scripts escrevem um `override.cfg`, que o Godot lê por cima do `project.godot`, e o apagam assim que os jogos o leem. Antes, numa nota da mesma sessão, o Claude tinha dito que "o lag do simulador mora no servidor", porque o proxy dele fica no processo que hospeda. As duas respostas erradas seguem essa ideia.
>
> Depois da segunda, o Claude parou de perguntar e explicou uma vez com o próprio projeto: o autoload `NetworkSimulator`, na linha 22 do `project.godot`, que o `override.cfg` acorda em qualquer jogo que abre. Depois seguiu com as escolhas do Arthur, como manda a regra do registro do harness de 07/10/2026.

## §1 — A primeira rodada

- **Conferência:** "Você fecha o play_online.sh e, no dia seguinte, abre o jogo no modo Sozinho. O lag simulado está ligado?" Ele escolheu "Só se o servidor ficou aberto" ("O lag continua enquanto o servidor do script roda."). A certa era "Não, o arquivo já não existe".
- **Docs:** "Posso atualizar os docs da parte 2 e registrar a DEC-0038?" Ele escolheu "Atualiza tudo, com a DEC-0038 (Recomendado)", cuja descrição dizia: "rede.md, testes-e-entrega.md, glossário e mudancas, como na lista, mais a DEC-0038 completando a DEC-0023 §7. Só DEC aceita é regra, então a exceção fica onde as regras ficam."
- **PR:** "Com o portão verde, posso subir a branch, abrir o PR e fazer o merge quando o CI passar?" Ele escolheu "Sobe, PR e merge (Recomendado)", cuja descrição dizia: "Como na parte 1: subo, abro o PR em português e faço o merge com o CI verde."

## §2 — A segunda conferência

O Claude nomeou a ideia errada (o lag depende do servidor) e explicou de outro jeito, com o `NODE_ENV=test npm start` e uma tabela. A pergunta foi: "Imagine que o script esquecesse o override.cfg na pasta e todos os processos fechassem. O próximo jogo que você abrisse amanhã ligaria o simulador?" Ele escolheu "Não, o servidor já fechou" ("Sem o servidor do script, não tem quem ligue o lag."). A certa era "Sim, o arquivo estaria lá".
