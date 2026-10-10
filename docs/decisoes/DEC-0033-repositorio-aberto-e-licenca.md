---
id: DEC-0033
titulo: O repositório aberto e a licença — MIT no código, CC BY 4.0 nos assets próprios, o nome fora da licença, o histórico aberto como está, a main sem force push e o PR de fora só com aprovação
data: 2026-10-10
status: aceita
decidido_por: Arthur (F-058; F-071 §3; F-076 §1), com o idioma dos arquivos públicos e as escolhas da TASK-11 confirmados no plano aprovado (F-077)
fontes: [F-058, F-067, F-068, F-069, F-071, F-075, F-076, F-077]
substitui:
substituida_por:
---

# DEC-0033 — O repositório aberto e a licença: MIT no código, CC BY 4.0 nos assets próprios, o nome fora da licença, o histórico aberto como está, a main sem force push e o PR de fora só com aprovação

## Contexto

O Arthur quer o jogo aberto: "eu quero deixar o jogo aberto, eu quero que outras pessoas no futuro possam contribuir pra, PRs, merges, correção de bugs, melhorias" e "Eu vou ser o mantenedor principal ainda" (F-058 §2). O repositório abre no Desenho 6, junto com a licença (Q-04).

A pesquisa mostrou que a licença decide três portas. A Valve diz que licença com copyleft, como a GPL, costuma ser problema com o SDK da Steam, e cita MIT, BSD e Apache como aceitáveis (F-067 §10, X-05). A assinatura grátis do SignPath pede licença aprovada pela OSI (F-069 §12, X-04). O Sentry para código aberto pede uma licença "amigável, como Apache ou MIT" (F-067 §10, X-06). A GPL só entra com uma exceção escrita para o SDK, e só os titulares podem dá-la (F-068 §4; L-13).

O ensaio num clone não achou segredo no histórico inteiro, nem IP, CPF ou telefone; as dependências copiadas, o gdUnit4 e o netfox, são MIT (F-075). Ficam públicos o e-mail do Arthur em 40 commits, o usuário do Windows em 14 caminhos, as linhas de coautoria e as falas dele nas fontes (F-075 §1 a §3). Ele disse que não liga de mostrar o e-mail (F-071 §3) e aceitou o ensaio (F-076 §1).

No plano Free, a regra de branch e o ruleset só valem em repositório público (F-069 §12, X-02), por isso a Q-03 escolheu "privado, sem regra de branch".

## Opções consideradas

1. **MIT no código e CC BY 4.0 nos assets:** a escolhida. Passa pelas três portas; o preço é que alguém pode fechar uma cópia (F-068 §4).
2. **GPL-3.0 e CC BY-SA 4.0:** impede a cópia fechada, mas exige a exceção da Steam desde o primeiro commit, e o plano do Sentry para código aberto pode não valer (F-068 §4; F-067 §10).
3. **Trocar o e-mail no próprio repositório:** não esconde, porque as páginas dos PRs guardam os commits antigos (F-069 §6 e §12). **Repositório novo com o histórico reescrito:** esconde, mas todo hash muda. O Arthur não liga para o e-mail (F-071 §3).
4. **PR obrigatório para tudo** na main: mudaria o fluxo da DEC-0028 §4. **Sem trava:** só o pre-push deste PC protegeria a main.

## Decisão

Decidida pelo Arthur em 10/10/2026: "MIT + CC BY 4.0 (Recomendado)" e "Trava leve + aprovação (Recomendado)" (F-076 §1).

### 1. A licença

- O código, os testes e as ferramentas ficam em MIT.
- Os assets que o projeto fizer ficam em CC BY 4.0. Os de terceiros seguem a DEC-0029, cada um com a sua licença.
- O nome e o logo ficam fora da licença, com um aviso no README. O registro no INPI só vem com o nome definitivo (F-068 §7); o nome segue provisório até o fim da fase 1 (DEC-0018).
- A contribuição entra pela seção D.6 dos termos do GitHub: o que alguém manda a um repositório com licença fica sob a mesma licença. Não há CLA (F-068 §6; L-15). Por isso a licença entra na main antes da virada para público.

### 2. O que fica público

O histórico abre como está: o e-mail, o usuário do Windows nos caminhos, as linhas de coautoria e as falas do Arthur nas fontes (F-071 §3; F-075; F-076 §1). Nada é reescrito.

### 3. A trava da main e o CI

- Um ruleset recusa force push e apagar a main.
- "PR só entra com o portão verde" é a prática do merge (DEC-0028 §4, item 5). O job `gate` só vira check obrigatório do ruleset se uma sonda mostrar que o commit direto das sessões sem task continua passando (DEC-0028 §4, item 6).
- O PR vindo de um fork só roda o CI depois da aprovação do Arthur ("Require approval for all external contributors"), com `permissions: contents: read`. O CI nunca usa `pull_request_target` nem um runner próprio (F-069 §2 e §12; R-06 a R-08). Que o PR de fork rode sem segredo é conhecimento geral, sem página que o confirme (F-069 §10).
- O job `gate` mantém `lfs: true`, porque o import lê os PNGs do gdUnit4. O `lfs: false` vale para jobs futuros sem import (F-069 §3).

### 4. O idioma dos arquivos públicos

Completa a DEC-0008. O texto das licenças fica no original, em inglês. O README, o CONTRIBUTING e o SECURITY ficam em português, com um resumo em inglês. O código de conduta é o Contributor Covenant 3.0 em português (F-069 §8). Commits e PRs seguem em português.

### 5. A abertura

A abertura é a TASK-11, porque o ato é voltado para fora, não se desfaz e precisa do ok do Arthur na hora (F-071 §4, escolha 6).

## Consequências

- A Q-04 fecha na licença; o nome definitivo vira a Q-27.
- A resposta da Q-03 muda na abertura: a main ganha o ruleset.
- O CI passa a ser grátis e roda em 4 núcleos (F-069 §1). As releases da tag ficam públicas; os artefatos do PR seguem na cota de 500 MB.
- Todo download do LFS, até de fork, sai da cota do Arthur (F-069 §3 e §12).

## Revisitar se

- Alguém fechar uma cópia do jogo e isso pesar para o Arthur: a MIT pode virar GPL depois; o caminho de volta pede o aceite de cada contribuidor (F-068 §4).
- O SignPath, a Valve ou o Sentry mudarem a regra de licença.
- A cota do LFS apertar com os assets.
