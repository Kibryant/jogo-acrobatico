---
id: F-076
titulo: O Arthur fecha a rodada 2 do Desenho 6 — MIT no código e CC BY 4.0 nos assets, a trava leve da main com aprovação do PR de fora, os serviços na hora certa, o GitHub como casa da comunidade com sinais rápidos no jogo, e a assinatura, a Steam e a lei como na vitrine (sessão 10, 10/10/2026)
recebido_em: 2026-10-10
como: Respostas escolhidas nas opções de duas perguntas do Claude Code, com três questões cada, depois do ensaio da abertura (F-075). Texto das perguntas como foram mostradas e, para cada resposta, a descrição da opção escolhida, copiados da transcrição da sessão.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: antes da primeira pergunta, o Claude mostrou o resultado do ensaio e explicou a licença (a MIT do Godot e do netfox contra a GPL do Linux), a regra da main como o pre-push do lado do servidor e o PR vindo de um fork. As decisões viram DEC no fechamento da TASK-8.

## §1 — A licença, a main e o CI

Pergunta: "Pergunta fixa: deu para entender o que o ensaio mostrou e o que a rodada 2 decide?"

Resposta: "Entendi", cuja descrição dizia: "O histórico está limpo para abrir; agora a gente decide a licença, como os outros contribuem, a trava da main e o CI de quem vem de fora. Depois vêm os serviços e a lei."

Pergunta: "Qual a licença do jogo aberto?"

Resposta: "MIT + CC BY 4.0 (Recomendado)", cuja descrição dizia: "Código em MIT, como o Godot e o netfox; assets que a gente fizer em CC BY 4.0 (uso livre com crédito); o nome e o logo fora da licença; quem manda PR entra pela regra do GitHub, sob a mesma licença, sem contrato extra. Passa na Steam, no SignPath e no Sentry. O preço: alguém pode fechar uma cópia."

Pergunta: "A trava da main e o CI de quem vem de fora, quando o repositório abrir:"

Resposta: "Trava leve + aprovação (Recomendado)", cuja descrição dizia: "A main recusa force push e apagar; um PR só entra com o portão verde no CI; você (e eu, na sua sessão) segue podendo commitar direto na main nas sessões sem task (DEC-0028 §4). Todo PR de fora só roda o CI depois que você aprova, sem segredo, e os jobs que não usam binário não baixam o LFS."

## §2 — Os serviços e a lei

Pergunta: "Contas, ranking e relatório de crash: quando entram e com o quê?"

Resposta: "Na hora certa (Recomendado)", cuja descrição dizia: "Crash: na fase 2, o log do Godot com a pilha de chamadas, que o amigo manda à mão; na fase 3, o Sentry no plano grátis para código aberto, sem IP nem dado pessoal. Contas e ranking só na fase 4, com login pela Steam ou pelo Discord, sem senha guardada por nós; o ranking gravado só pelo servidor oficial. Onde guardar (Supabase ou banco do próprio servidor) se decide lá, pelo custo."

Pergunta: "Comunidade e conversa dentro do jogo, sabendo que muito menor de idade vai jogar:"

Resposta: "GitHub + sinais rápidos (Recomendado)", cuja descrição dizia: "A casa da comunidade é o GitHub Discussions, aberto junto com o repositório. O Discord só entra como canal extra, nunca o único, porque está sob processo no Brasil e classificado 18+. No jogo, só sinais rápidos ("boa", "de novo?"), sem chat livre, o que poupa a denúncia e a moderação que o ECA Digital pede para chat."

Pergunta: "Assinatura da build, Steam e a lei: as direções para registrar."

Resposta: "Como na vitrine (Recomendado)", cuja descrição dizia: "Assinatura grátis pelo SignPath assim que o repositório abrir, antes de os amigos testarem (Q-20). Steam: página na fase 4, Steam Direct (US$ 100) na fase 5, o SDK nunca no repositório e a build Steam como opcional. Lei: aviso de privacidade quando o servidor guardar IP, classificação indicativa no lançamento e um advogado antes das contas e do chat. Nome no INPI só quando for definitivo."
