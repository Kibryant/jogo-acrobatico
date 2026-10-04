---
id: F-032
titulo: O Arthur fecha a rodada 2 do Desenho 3 — entende quem paga o atraso, escolhe a posição na tela de quem ataca e fecha com os padrões o input, o oponente no passado, a detecção no núcleo, a fase 1 no tick, a Main e o teto de 200 ms (sessão 5, 04/10/2026)
recebido_em: 2026-10-04
como: Mensagem de abertura da sessão 5, seguida das respostas escolhidas nas opções de uma pergunta do Claude Code. Texto das perguntas, dos rótulos e das descrições como foram mostrados; as escolhas do §3 e as tabelas do §4 estão como a vitrine as mostrou.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: rodada 2 do Desenho 3 (TASK-5). Antes de perguntar, o Claude leu no código do netfox (`cf5189d`) o que a compensação precisa e republicou a vitrine da rede na versão 8 (https://claude.ai/artifact/Sb4Q5e4M16UymdoaR9UAzp), com seis seções novas: quem paga o atraso, a posição na espada, o input, a detecção do golpe, a fase 1 no tick e a Main. No terminal, mostrou:
>
> - que o atraso não some, e cada jogo escolhe quem paga: no CoD, quem leva o tiro; no For Honor, quem defende, com 33 ms de atraso em todo input de ataque, menos o parry (artigo da Ubisoft de 2018); no nosso, cada um tem razão sobre o que fez na própria tela, até um teto (DEC-0011; F-001);
> - um modelo calibrado com o bot de reação de gente (F-029) e o atraso medido a 60 ticks (F-026): com ping 100, 8% de parry no relógio do servidor, 28% com o atraso do For Honor e 69% no tempo de quem defende;
> - o teto de 200 ms, fechado pelo Claude como v0 (DEC-0017), e o custo para quem ataca: descobrir o resultado uns 240 ms depois, com ping 100.
>
> As perguntas traziam uma recomendação cada.

## §1 — A abertura

"Boa tarde, vamo fazer essa sessao agora: A rodada 2 do Desenho 3. É o desenho do input, da compensação a favor de quem defende (que a rodada 1 mostrou ser obrigatória), da detecção do golpe, da fase 1 no tick e da Main. Depois vêm o plano, as DECs, o netfox em addons/ e o rede.md."

## §2 — As respostas

Pergunta: "Pergunta fixa: deu para entender o problema da rodada 2 e o que estamos desenhando (quem paga o atraso, o teto de 200 ms e as cinco peças)?"

Resposta: "Entendi"

Pergunta: "Na espada, a tela de quem decide se o golpe pegou na posição? (Parry, bloqueio e esquiva já valem na tela de quem defende.)"

Resposta: "A de quem ataca (Recomendado)"

A opção dizia: "Como no CoD e no estudo: a espada pega o que você vê, e o \"encostou\" nunca é desfeito. Quem só correu leva o golpe uns 1,8 m depois de sair, na tela dele (ping 100). Esquiva, parry e bloqueio salvam."

As outras opções eram "O servidor" ("Divide a conta: quem ataca mira uns 0,9 m à frente de quem corre, e quem defende sai uns 0,9 m antes do que parece. Nenhuma tela tem razão, e o \"encostou\" pode ser desfeito.") e "A de quem defende" ("Correu na sua tela, escapou. Quem ataca mira uns 1,8 m à frente de quem corre e vê a lâmina atravessar o boneco. Com lag, correr em círculo vira estratégia.").

Pergunta: "As outras cinco escolhas (input, oponente no passado, detecção no núcleo, fase 1 no tick e Main) e o teto de 200 ms: fecho com os padrões?"

Resposta: "Fechar com os padrões (Recomendado)"

A opção dizia: "Fecho as cinco e o teto como na seção \"O plano\" da vitrine e sigo para o plano, no modo de plano."

## §3 — As escolhas da rodada 2, como a vitrine as mostrou

1. "A defesa por tempo no tempo de quem defende, com teto de 200 ms (direção da DEC-0011). Parry, bloqueio e esquiva valem como você viu; acima do teto, quem tem o atraso paga o excesso."
2. "A posição na espada: a tela de quem ataca, como o estudo propõe (F-001). Para você decidir."
3. "O input: os campos da tabela, o comando de um toque entregue a um tick só, `input_delay` 0, redundância 3, sem broadcast e o `view_lag` na fase 3."
4. "O oponente no passado, sem previsão, suavizado entre ticks. A previsão da main tem bug aberto (#613), e a compensação precisa do passado real."
5. "A detecção por forma no núcleo, em fatias varridas por tick. Parede no meio, se precisar, vira um fato que o motor responde."
6. "A fase 1 já no tick do netfox, jogada no modo \"Sozinho\", com a SyncTest no CI a cada manobra nova."
7. "A Main com três modos: servidor dedicado, cliente e sozinho, e o fechamento limpo."

Na seção da Main, os três modos apareciam assim: servidor dedicado com `godot --headless -- --server --port=9999`, ou o build exportado como servidor, que liga a feature `dedicated_server`; cliente com `godot -- --connect=127.0.0.1:9999`; sozinho com `godot`, sem argumento, no par offline do Godot.

## §4 — As tabelas a que a escolha 3 se refere

Os campos do input:

| Campo | O que é | Desde |
|---|---|---|
| `move` | Para onde andar, até 1, relativo à câmera | esqueleto andante |
| `yaw` | Para onde a câmera olha; o corpo vira junto | esqueleto andante |
| `jump` | Um toque | esqueleto andante |
| `pitch` | A mira na vertical, para o gancho prender no ponto da mira | fase 1 |
| `dash`, `grapple` | Um toque | fase 1 |
| `light`, `parry`, `dodge`, `feint`, `swap` | Um toque | fase 2 |
| `heavy`, `block` | Segurar: o carregado carrega enquanto você segura | fase 2 |
| `view_lag` | Quão velho estava o oponente na sua tela, em ticks: o carimbo da compensação | fase 3; a regra nasce na fase 2 com zero |

A configuração do netfox:

| Configuração | Valor | O que faz |
|---|---|---|
| `input_delay` | 0 | "O seu boneco obedece no tick seguinte, sem espera. O For Honor usa 33 ms nos ataques; aqui a defesa já é compensada, então fica como botão de reserva, se a espera de quem ataca incomodar." |
| `input_redundancy` | 3 (padrão) | "Cada pacote repete os 3 últimos ticks: um pacote perdido não perde o aperto." |
| `enable_input_broadcast` | desligado (padrão da main) | "O seu input vai só para o servidor. Os outros clientes não veem as suas teclas: menos banda e menos material para quem trapaceia." |
| Previsão dos outros | desligada | "O oponente aparece no passado, como ele foi de verdade, suavizado entre ticks. A previsão da main tem bug aberto (#613), e o carimbo da compensação precisa de um passado real." |
| `history_limit` | 64 ticks (padrão) | "O quanto o netfox volta no tempo: 1,07 s a 60 ticks. Também é, por enquanto, o teto do lag switch do lado de quem ataca; a fase 3 revê." |
