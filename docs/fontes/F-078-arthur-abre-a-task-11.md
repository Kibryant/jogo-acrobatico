---
id: F-078
titulo: O Arthur abre a TASK-11 — erra a conferência do PR de fora, acerta depois do PR #662 do netfox, autoriza o merge do PR #3, escolhe o nome e o contato dos arquivos públicos e põe os docs na MIT (sessão 11, 10/10/2026)
recebido_em: 2026-10-10
como: Mensagem de abertura da sessão 11, seguida das respostas escolhidas nas opções de três perguntas do Claude Code, a primeira com três questões e as outras com uma. Texto das perguntas e das descrições como foram mostradas, copiado da transcrição da sessão.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: antes das perguntas, o Claude mostrou o que o levantamento achou (o PR #3 aberto com o CI verde; 16 execuções do Actions, nenhum artefato e 2 caches; os comentários do CodeRabbit nos PRs #1 a #3; o Contributor Covenant 3.0 sem tradução oficial para o português e sob CC BY-SA 4.0), explicou os conceitos (a licença antes da virada pela seção D.6, o ruleset como o pre-push do lado do servidor, o PR de fora com o CI parado e o token só de leitura, o que não se desfaz) e o plano em seis etapas. A conferência falhou na primeira vez. O Claude nomeou a ideia errada ("o GitHub recusa PR de quem não é colaborador"), mostrou o PR #662 do netfox, aberto em 09/10/2026 por quem não é do time, a partir de um fork, com 3 execuções do CI em `action_required`, e desenhou as quatro travas depois da porta; a segunda conferência acertou. O merge do PR #3 saiu como o commit `1490d10`, antes da segunda conferência, porque não depende do conceito conferido.

## §1 — A abertura

"Boa tarde, vamo fazer essa task: TASK-11"

## §2 — A primeira rodada de perguntas

Pergunta: "Pergunta fixa: depois de aberto, um estranho faz um fork e abre um PR que muda o `ci.yml` para tentar empurrar um commit na sua main. O que acontece?"

Resposta: "O GitHub recusa o PR", cuja descrição dizia: "Quem não é colaborador não consegue abrir PR num repositório público."

As opções eram "Roda na hora e consegue", "Fica parado até você aprovar" e "O GitHub recusa o PR". A esperada era "Fica parado até você aprovar", cuja descrição dizia: "O CI do PR espera você olhar o diff; mesmo aprovado, o token só lê, e o empurrão falha."

Pergunta: "Posso fazer o merge do PR #3 (Desenho 6) agora e começar a etapa 1? O CI está verde e o reviewer aprovou."

Resposta: "Pode fazer o merge (Recomendado)", cuja descrição dizia: "Eu junto num merge commit com o título em português, apago a branch task-8-desenho-6 e abro a task-11-abrir-repositorio a partir da main. Paro de novo antes do merge do PR #4."

Pergunta: "Como você aparece nos arquivos públicos: o nome na licença e o contato para relatar um problema de conduta?"

Resposta: "Arthur Gustavo + Gmail (Recomendado)", cuja descrição dizia: "O nome do seu perfil do GitHub e o e-mail que já está nos commits. A licença diz "Copyright (c) 2026 Arthur Gustavo and contributors". Falha de segurança vai pelo botão privado do GitHub, sem e-mail."

## §3 — A segunda conferência

Pergunta: "Depois da abertura, um amigo seu, sem acesso de colaborador, quer corrigir um erro de digitação no README. O que ele consegue fazer sozinho?"

Resposta: "Abrir o PR, que espera você", cuja descrição dizia: "O PR dele aparece na sua aba; o CI espera a sua aprovação, e a main só muda com o seu merge."

## §4 — A licença dos docs

> Contexto, escrito pelo agente: um agente de planejamento com contexto limpo (Fable 5.1) criticou o roteiro da abertura e apontou que a DEC-0033 §1 não diz a licença dos docs. O Claude mostrou o que mudava no roteiro por causa da crítica e fez a pergunta.

Pergunta: "Qual licença cobre os docs (docs/, as fontes com as suas falas, os diários, as DECs e o AGENTS.md)?"

Resposta: "MIT, como o código (Recomendado)", cuja descrição dizia: "Uma licença só para tudo o que não é asset, sem fronteira para discutir (o AGENTS.md, as skills e os comentários misturam código e texto). Quem copia mantém o aviso da licença; pode copiar e mudar, inclusive as suas falas nas fontes."

A outra opção era "CC BY 4.0, como os assets".
