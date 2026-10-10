---
id: F-077
titulo: O plano aprovado do fechamento do Desenho 6 — três DECs (a hospedagem, o repositório aberto e a licença, os serviços e os gatilhos), o infraestrutura.md, a entrada da TASK-9 e a TASK-11 Ready com as escolhas dela (sessão 10, 10/10/2026)
recebido_em: 2026-10-10
como: O plano escrito pelo Claude no modo de plano da sessão 10, criticado antes por um agente de planejamento com contexto limpo (Fable 5.1), que devolveu 22 achados, todos incorporados; aprovado pelo Arthur no ExitPlanMode, depois de ele pedir para seguir para o fechamento. O §1 é o plano como foi aprovado; as escolhas da TASK-11 que ele lista ficam confirmadas por esse ok.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: o ok no modo de plano é consentimento de verdade, mas não deixa F-xxx; por isso o plano aprovado vira fonte logo depois (registro da TASK-4).

## §1 — O plano aprovado

## Contexto

As duas rodadas da TASK-8 acabaram na branch `task-8-desenho-6`. Na rodada 1, o servidor do parry de brinquedo rodou num contêiner aqui e na Edgegap em São Paulo, e o Arthur decidiu a hospedagem do esqueleto andante e o fechamento limpo (F-072 a F-074). Na rodada 2, o ensaio deu o histórico sem segredo (F-075), e o Arthur decidiu a licença, a trava da main, o CI de PR de fora, os serviços e a lei (F-076). As escolhas do Ready estão na F-071 §4; a pesquisa, nas F-066 a F-069 com os veredictos.

O fechamento vira regra em três DECs, escreve o `docs/arquitetura/infraestrutura.md` (critério 1), deixa a entrada na TASK-9 e cria a TASK-11 Ready, que faz a abertura. Não há código de jogo. Os critérios 3 e 5 já estão provados (F-073; F-075). Um agente de planejamento com contexto limpo criticou o rascunho: foram 22 achados, todos incorporados abaixo.

### 0. Antes de escrever

- Os últimos IDs: DEC-0031, F-076, Q-26, TASK-10. Saem a DEC-0032 a 0034, a Q-27 e a Q-28, a F-077 (este plano) e a TASK-11.
- Toda afirmação cita a seção e o rótulo (Fato, Inferência ou ressalva do verificador). Número refutado não aparece: a Vultr em SP custa US$ 7,50 (F-066 §13). O que só tem fonte secundária leva a ressalva: a data do corte da Oracle (H-09) e o Discord (X-07 e X-08). "Sem segredo para PR de fork" é conhecimento geral, sem página (F-069 §10).
- O ping no horário de pico entra se der para rodar hoje à noite (nova F). Se não der, o critério 3 vale com sexta à tarde e sábado de manhã (F-070; F-073 §5), e o pico vai para "o que não foi medido" e para a Q-09.

### 1. As três DECs (`aceita`)

**DEC-0032 — A hospedagem do servidor.** Fontes: F-066, F-070, F-071, F-073, F-074. Completa a DEC-0011 (ponto 2) e a DEC-0026 §6. Substitui só a frase "O push na main não gera build" da DEC-0028 §2. A DEC-0028 ganha `substituida_por` parcial, o aviso e uma linha no Histórico, pelo procedimento da F-065 §6.
- Decidido pelo Arthur (F-074): o esqueleto andante roda neste PC, servidor e clientes. Um job de CI fora do portão constrói a imagem do servidor Linux a cada push na main e nos PRs e confere que ela sobe e fecha com saída 0 (precedente: DEC-0027, "um job do CI fora do pre-push, com uma DEC nova"). Nada pago até a fase 3. Na fase 3, uma VPS em São Paulo (Vultr `vc2-1c-1gb`, US$ 7,50 por mês, F-066 §13). A Edgegap grátis fica para testes de 60 minutos.
- O fechamento limpo é por um comando nosso, fora de banda (stdin, arquivo ou RPC, a escolher na TASK-9), que para o tick, fecha a conexão e sai com 0. O SIGTERM segue matando com 143, porque o Godot não o trata (F-066 §5, proposta #1361). O `tini` só evita o processo zumbi (F-073 §2).
- Direção proposta pelo Claude, a decidir na fase 4 (DEC-0012): o servidor oficial, os servidores da comunidade e a lista de salas no próprio oficial (F-066 §6, Inferência).
- Opções consideradas: a Edgegap ligada 24 h (~7,7 vezes a VPS, F-066 §13); o Oracle A1 grátis (build arm64 e falta de máquinas, F-066 §4); AWS t4g, Lightsail e Azure B (CPU burstable, Inferência de F-066 §3); o PC de casa para amigos (CGNAT, F-070 §4).
- A referência medida: 13,9% de um núcleo por 1v1 no data center (F-073 §3); 43 MB medidos no contêiner aqui (F-073 §2); a memória no data center não foi medida. O 4v4 segue sem medida (Q-09). A DEC responde à Q-05 (F-066 §2 e §12; F-073 §3).
- A receita da imagem (`debian:trixie-slim`, usuário sem root, 7777/udp, `flush_stdout_on_print`) fica fora da DEC: vai no comentário da TASK-9 como ponto de partida do Claude, com a Dockerfile de `../servidor-sonda` (F-066 §5; contexto da F-073).

**DEC-0033 — O repositório aberto e a licença.** Fontes: F-058, F-067, F-068, F-069, F-071, F-075, F-076. Fecha a Q-04 (a licença; o nome segue provisório até o fim da fase 1, DEC-0018, e o definitivo vira a Q-27). Muda a resposta da Q-03 a partir da abertura. Completa a DEC-0008 e a DEC-0028.
- MIT no código; CC BY 4.0 nos assets próprios; o nome e o logo fora da licença. A contribuição entra pela seção D.6 dos termos do GitHub, sem CLA. A D.6 só vale com a licença já no repositório antes da virada (F-068 §6 e §7; L-15).
- O que fica público, aceito pelo Arthur (F-071 §3; F-076 §1): o histórico como está, o e-mail, o usuário do Windows em 14 caminhos, as linhas de coautoria e as falas dele nas fontes (F-075 §1 a §3).
- A trava: o ruleset bloqueia force push e apagar a main. "PR só entra com o portão verde" é a prática do merge do Arthur (DEC-0028 §4.5); o check obrigatório só entra se uma sonda mostrar que o commit direto das sessões sem task segue passando. PR de fork roda o CI só com aprovação ("Require approval for all external contributors"), com `permissions: contents: read`, nunca com `pull_request_target` nem runner próprio (F-069 §2; R-06 a R-08).
- O LFS: o job `gate` mantém `lfs: true`, porque o import lê os PNGs do gdUnit4. O `lfs: false` vale para jobs futuros sem import (F-069 §3).
- Idioma dos arquivos públicos (completa a DEC-0008): o texto das licenças em inglês; README, CONTRIBUTING e SECURITY em português com um resumo em inglês; commits e PRs seguem em português.
- Consequência: as releases da tag ficam públicas; os artefatos do PR seguem na cota de 500 MB (F-069 §1).

**DEC-0034 — Os serviços e os gatilhos.** Fontes: F-001, F-066 a F-069, F-071, F-076. Completa a DEC-0012.
- Decidido pelo Arthur (F-076 §2):
  - **Crash:** na fase 2, o log do Godot com a pilha, mandado à mão; na fase 3, o Sentry de código aberto com `send_default_pii` e `attach_log` desligados (F-067 §5).
  - **Contas e ranking:** na fase 4, login pela Steam ou pelo Discord, sem senha guardada por nós, e o ranking gravado só pelo servidor oficial, com a chave secreta só nele (F-067 §1). O lugar (Supabase ou banco do servidor) se decide lá.
  - **Comunidade:** o GitHub Discussions; o Discord só como canal extra.
  - **No jogo:** só sinais rápidos, sem chat livre.
  - **Assinatura:** pelo SignPath, pedida depois da abertura e da primeira release (v0.1.0, TASK-9). O SignPath pede projeto "já lançado", e a página dele está em rascunho (F-069 §7; X-04). Até lá, um passo a passo para os testadores. A Certum é plano B não confirmado. Responde à Q-20.
  - **Steam:** o SDK nunca no repositório; a build Steam é opcional; o Steam Direct custa US$ 100 por app, com 30 dias de espera e a página no ar 2 semanas antes (F-067 §2 e §3). Se a página exige a taxa paga, vira a Q-28.
  - **Lei:** aviso de privacidade quando o servidor guardar IP; classificação indicativa no lançamento; um advogado antes das contas e do chat; sem loot box paga (F-068 §1 a §3).
  - **Regra de já:** nada pago e nenhum cartão antes da fase 3 (F-071 §4).
- Consequências e tensões em aberto: o Supabase não tem login da Steam nativo, porque a Steam usa OpenID 2.0 (S-04). O login pelo Discord encontra a classificação 18+ (S-15). As duas ficam para a fase 4.

### 2. `docs/arquitetura/infraestrutura.md` (critério 1)

O documento é novo, com `revisado_em` e `fontes`. Seções: Estado atual; O servidor; O repositório aberto; Os serviços; O que não foi medido.

Uma tabela leva cada serviço do critério (servidor, contas e ranking, Steam, relatório de crash, comunidade, assinatura da build e o repositório) a gatilho, direção, custo nas faixas de 10, 50, 200 e 1.000 jogadores, o que a lei pede e a fonte. Onde o custo não depende da faixa, a linha diz isso. As fontes do custo:
- Servidor: F-066 §13.
- Supabase: grátis, e o Pro a US$ 25 (F-067 §1).
- Sentry: 5 mil eventos no grátis, 5 milhões no de código aberto (F-067 §5, com a ressalva X-06).
- Steam: US$ 100 uma vez (F-067 §2).
- SignPath: R$ 0 (F-069 §7).
- Actions e Discussions: R$ 0 em repositório público (F-069 §1).
- LFS: a cota (F-069 §3).

O documento também traz a correção da Oracle, prometida no `mudancas.md`. O `docs/arquitetura/README.md` atualiza a linha.

### 3. O que acompanha

- **`docs/roteiro.md`:** a fase 4 troca "Discord" por "comunidade no GitHub", e a fase 3 ganha a VPS em SP.
- **`docs/pendencias.md`:**
  - Respostas com data e DEC: Q-04, com a licença; Q-05; Q-20.
  - Notas: na Q-03 (a regra da main entra na abertura) e na Q-09 (o ping estável de 37 ms e o pico não medido).
  - Novas: Q-27 (o nome definitivo) e Q-28 (a página da Steam pede a taxa? e o login de menores, Steam ou Discord).
- **`docs/decisoes/README.md`:** as três linhas, com "completa" e "substitui" nos lugares certos (DEC-0008, 0011, 0012, 0026, 0027 e 0028), e a linha do Histórico.
- **`mudancas.md`:** linhas para a frase da DEC-0028, a Q-03, o detalhe da DEC-0011, a Q-05, a Q-20, a licença e a fase 3 do roteiro.
- **Glossário:** registro de imagens, deploy, PID 1 e sinal de parada, ruleset, PR de fork, inbound=outbound.
- **`AGENTS.md`:** "The project" ganha "open source: code MIT, assets CC BY 4.0 (DEC-0033)". "Branches and versions" ganha "the main refuses force push (DEC-0033)". Para compensar, a linha `addons/` do mapa encolhe. O arquivo tem 3 caracteres de folga, e o reviewer confere o total.
- **TASK-9:** o comentário "Entrada do Desenho 6" leva o job da imagem, o comando de fechamento fora de banda, o `flush_stdout_on_print` e a receita da sonda.
- **TASK-11, criada Ready pela CLI**, dependendo da TASK-8. A TASK-9 passa a depender da TASK-11, para o histórico estar parado na virada. Os critérios vêm em quatro blocos:
  1. **Antes:** na main, os arquivos `LICENSE`, `LICENSE-ASSETS`, `README` com o aviso do nome, `CONTRIBUTING`, `CODE_OF_CONDUCT` e `SECURITY`; o workflow com `permissions: contents: read`, provado num PR; o gitleaks de novo no histórico final; os logs antigos do Actions revistos; nenhuma branch de task aberta; a `task-7-desenho-5` apagada.
  2. **A virada:** com o ok do Arthur na hora.
  3. **Logo depois:** o ruleset; a aprovação de PR de fora; o Discussions; o secret scanning e o push protection; o Dependabot; o relato privado de vulnerabilidade.
  4. **O que só se confere depois:** os minutos grátis; o ruleset recusando um force push, por sonda, e aceitando o commit direto; a aprovação de PR de fora só quando chegar o primeiro de verdade.
- **As escolhas da TASK-11**, que este ok confirma:
  - Contributor Covenant 3.0 em português;
  - o aviso do nome dentro do README, sem `TRADEMARK.md`;
  - um modelo de issue e um de PR;
  - os arquivos públicos em português com resumo em inglês.
- **A vitrine:** ganha as seções das rodadas 1 e 2 e é republicada.
- **Fontes:** a F-077 guarda este plano aprovado.

### 4. Verificação

- Reviewer com contexto limpo, critério a critério, conferindo se cada citação contém o que afirma.
- Correções; depois o portão num clone limpo (`bash tools/gate.sh`, com as últimas linhas na nota).
- Os critérios marcados; o diário pela skill `diario`; o PR em português para o Arthur fazer o merge.
- O DoD 2 não se aplica: não há código em `core/`.
