---
id: F-100
titulo: O Arthur abre a Fase 1 — escolhe a ordem das filhas da TASK-10, fecha as três escolhas da TASK-12 com os padrões e passa a conferência do modo como dado na segunda tentativa (sessão 14, 19/10/2026)
recebido_em: 2026-10-19
como: Respostas escolhidas nas opções de perguntas do Claude Code na sessão 14, na rodada 1 da TASK-10. Texto das perguntas, dos rótulos e das descrições como foram mostrados; a resposta livre da primeira conferência, como chegou.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: a TASK-10 estava em "To Refine" e a DEC-0036 diz que a fase 1 não tem papel novo. O Arthur abriu a sessão com "vamo fazer a Task 10", ligou o ultracode e pediu para usá-lo uma vez só na task, com os agentes em modelo e esforço de acordo com a tarefa. O único workflow rodou 19 agentes (seis leitores, duas propostas, dois juízes, um sintetizador, cinco refutadores, um consertador) e produziu o blueprint da fase: seis filhas, cada uma do tamanho de uma sessão. O consertador travou ao devolver o resultado inteiro numa resposta só; o blueprint reparado foi lido do arquivo que ele deixou, e um crítico de completude e um fechador rodaram como agentes comuns. A rodada 1 trouxe uma conferência de entendimento e duas decisões. A primeira conferência foi lida como escolha; o Claude explicou de novo, com uma ideia só, e a segunda passou. As perguntas falavam em "TASK-12" e "TASK-18"; ao criar as filhas, o CLI do backlog numerou-as pelo id da mãe, e elas são a TASK-10.1 (pulo duplo e stamina) e a TASK-10.9 (a tela de opções).

## §1 — As decisões

Pergunta: "A ordem das filhas: qual?"

Resposta: "Sentir primeiro (Recomendado)"

A opção dizia: "Pulo duplo e stamina → gravador → dash → parede → gancho → cabeça, arena e 15 min. Cada sessão termina com algo novo para jogar; o gravador entra antes da primeira manobra que muda o contato com o motor (o dash mexe no snap do chão), e o ensaio cronometrado chega no fim da parede."

As outras opções eram "Risco primeiro" ("Gravador → pulo duplo → dash → parede → gancho → cabeça. Nenhuma manobra é depurada sem arquivo de teclas, mas a primeira sessão termina sem manobra nova para jogar.") e "Manobras primeiro, gravador por último" ("Pulo duplo → dash → parede → gancho → gravador → cabeça. Mais jogo cedo; um bug da parede ou do gancho sem arquivo de teclas volta a ser reproduzido na mão.").

Pergunta: "As três escolhas da TASK-12 que são suas: (1) o buffer vira uma vaga só, o último aperto vence, e a DEC-0039 substitui a DEC-0022 só nisso, na assinatura com a posição e na janela inclusiva; (2) no ar, com o pulo duplo disponível, o aperto sai na hora, mesmo a poucos ticks do pouso, leitura v0 que você julga jogando; (3) a TASK-12 traz o Theme único e as chaves de tradução, e a tela de opções (teclas e escala, DEC-0031 §8) vira a TASK-18, antes da v0.2.0. Fecho com os padrões?"

Resposta: "Fechar com os padrões (Recomendado)"

A opção dizia: "As três entram como está. O resto da TASK-12 (a stamina guardada como valor mais carimbo, a posição no `before_move`, a SyncTest comparando o estado inteiro) é detalhe meu, como na TASK-9, e passa pelo modo de plano."

As outras opções eram "A tela de opções entra na TASK-12" ("A parte 2 da TASK-12 cresce com a tela de remapear teclas e a escala, como a DEC-0031 §8 lê ao pé da letra; a sessão fica mais longa e o pulo duplo demora mais para chegar nas suas mãos.") e "Quero mudar outra coisa".

## §2 — A conferência do modo como dado

Pergunta: "Conferência: quando a corrida na parede entrar no jogo, o que aparece no código?", com as opções "Um valor novo no campo mode", "Um nó WallRun na cena", "Um Timer de 2,5 s" e "Uma classe fora do estado".

Resposta, em texto livre: "Qual voce recomenda e porque?"

O Claude explicou de novo, nomeando a ideia errada (uma manobra nova virar um nó ou um timer na cena) e a certa (um valor novo no campo `mode`, com os carimbos dentro do `FighterState`), com o exemplo do `status` de um pedido no backend.

Pergunta: "Conferência (não é escolha: uma só é verdadeira). Depois de a parede entrar, qual frase descreve o código?", com as opções "O mode ganha WALL_RUN", "Nasce um nó WallRun", "Um Timer conta os 2,5 s" e "Uma classe à parte do estado".

Resposta: "O mode ganha WALL_RUN"

A opção dizia: "O `FighterState` ganha o valor `WALL_RUN` no campo `mode` e os carimbos da parede; a corrida é uma regra pura em `core/`, e o netfox grava tudo como grava a posição."
