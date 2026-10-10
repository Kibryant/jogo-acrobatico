---
id: DEC-0034
titulo: Os serviços e os gatilhos — o crash pelo log e depois pelo Sentry, as contas e o ranking na fase 4, a comunidade no GitHub, só sinais rápidos no jogo, a assinatura pelo SignPath, a Steam fora do repositório e a lei em cada gatilho
data: 2026-10-10
status: aceita
decidido_por: Arthur (F-071 §4, escolha 1; F-076 §2)
fontes: [F-001, F-066, F-067, F-068, F-069, F-071, F-076, F-077]
substitui:
substituida_por:
---

# DEC-0034 — Os serviços e os gatilhos: o crash pelo log e depois pelo Sentry, as contas e o ranking na fase 4, a comunidade no GitHub, só sinais rápidos no jogo, a assinatura pelo SignPath, a Steam fora do repositório e a lei em cada gatilho

## Contexto

A DEC-0012 deixou contas, ranking, salas e Steam para a hora da funcionalidade. O estudo listava o Supabase para contas e ranking, o Discord como pilar de relacionamento, a Steam Direct e a lei brasileira (F-001). O Desenho 6 fixa o gatilho e a direção de cada um.

A pesquisa conferida na origem mudou três coisas. O Discord está sob processo no Brasil e o Ministério da Justiça o classifica como não recomendado para menores de 18 (F-067 §10, S-15, X-07 e X-08, só imprensa). O ECA Digital alcança jogo eletrônico; a única proibição expressa é a loot box paga, e um jogo com chat pede denúncia, recurso e interação limitada por padrão (F-068 §2 e §13). Sem assinatura, o Smart App Control barra a build de um jogo novo, e a única assinatura grátis que atende uma pessoa física no Brasil é a do SignPath (F-069 §7 e §12).

## Opções consideradas

1. **O Supabase já escolhido para contas e ranking:** o plano grátis pausa sem uso, e o Pro custa US$ 25 por mês (F-067 §1). A escolha ficou para a fase 4, pelo custo.
2. **O Discord como casa da comunidade**, como previa o estudo: arrisca a idade e o processo.
3. **Chat livre no jogo:** pede o sistema de denúncia e a interação desligada por padrão do art. 21 do ECA Digital (F-068 §2).
4. **A Steam fora do roteiro até a fase 4.**

## Decisão

Decidida pelo Arthur em 10/10/2026: "Na hora certa (Recomendado)", "GitHub + sinais rápidos (Recomendado)" e "Como na vitrine (Recomendado)" (F-076 §2). O momento da assinatura foi refinado no plano aprovado (F-077 §1).

| Serviço | Gatilho | Direção |
|---|---|---|
| Relatório de crash | Fase 2, quando amigos testam | O log do Godot com a pilha de chamadas, mandado à mão; na fase 3, o Sentry no plano de código aberto, com `send_default_pii` e `attach_log` desligados (F-067 §5) |
| Contas e ranking | Fase 4 | Login pela Steam ou pelo Discord, sem senha guardada por nós; o ranking gravado só pelo servidor oficial, com a chave secreta só nele (F-067 §1). Supabase ou banco do servidor, decidido lá pelo custo |
| Comunidade | A abertura do repositório (TASK-11) | O GitHub Discussions é a casa; o Discord só entra como canal extra, nunca o único |
| Conversa no jogo | O primeiro jogo em rede | Só sinais rápidos ("boa", "de novo?"), sem chat livre |
| Assinatura da build | O Arthur escolheu "assim que o repositório abrir, antes de os amigos testarem" (F-076 §2). O plano aprovado refinou o momento: depois da abertura e da primeira release (v0.1.0, TASK-9), porque o SignPath exige projeto "já lançado" e tem a página em rascunho (F-077 §1; F-069 §7; X-04) | Pedido ao SignPath. Até lá, um passo a passo para os testadores. A Certum é plano B não confirmado |
| Steam | Fases 4 e 5 | O SDK nunca no repositório; a build Steam é opcional, com o SDK baixado no CI. O Steam Direct custa US$ 100 por app, com 30 dias entre pagar e lançar e a página "em breve" no ar pelo menos 2 semanas antes (F-067 §2, §3 e §10) |
| Lei | Cada gatilho acima | Aviso de privacidade quando o servidor guardar IP; dados mínimos nas contas; nenhuma loot box paga; classificação indicativa no lançamento; um advogado antes das contas e do chat (F-068 §1 a §3) |

Vale desde já: nada pago e nenhum cartão cadastrado antes da fase 3 (F-071 §4, escolha 1).

## Consequências

- A Q-20 está respondida: SignPath depois da primeira release, e o passo a passo antes.
- O roteiro troca o Discord da fase 4 pela comunidade no GitHub (`mudancas.md`).
- Duas tensões ficam para a fase 4, na Q-28: o Supabase não tem login nativo da Steam, que usa OpenID 2.0 (F-067 §10, S-04); e o login pelo Discord encontra a classificação 18+ (S-15). A Q-28 também pergunta se a página da Steam exige a taxa paga, o que a pesquisa não respondeu.

## Revisitar se

- A ANPD publicar a regra definitiva do ECA Digital para jogos.
- O SignPath recusar o projeto.
- O custo das contas na fase 4 passar do orçamento de R$ 3 a 7 mil por ano (F-001).
