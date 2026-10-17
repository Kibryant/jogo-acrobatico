---
id: F-084
titulo: O Arthur deixa a TASK-9 Ready — erra duas vezes a conferência do modo Sozinho, escolhe as três partes e fecha as escolhas com as recomendações (sessão 13, 17/10/2026)
recebido_em: 2026-10-17
como: Mensagem de abertura da sessão 13, seguida das respostas escolhidas nas opções de duas rodadas de perguntas do Claude Code. Texto das perguntas, dos rótulos e das descrições como foram mostrados.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: refinamento da TASK-9, o esqueleto andante. Antes de perguntar, o Claude leu o quadro, a task e as DECs que ela cita (DEC-0012, DEC-0026 a DEC-0028, DEC-0032), o `movimento.md`, o `rede.md`, o `testes-e-entrega.md` e a `visao-geral.md`. Achou o commit da DEC-0036 (sessão 12) fora da main, numa branch de worktree nunca enviada. Propôs entregar a TASK-9 em três partes, cada uma com o seu PR, e mostrou as três escolhas que as DECs deixaram para a task e os padrões menores (§4). A primeira conferência errou. O Claude explicou de novo, nomeando a ideia errada: o modo Sozinho não roda no `_physics_process`, opção rejeitada na DEC-0026. Usou a Ferramenta de Treino do LoL, as linhas da `main.gd` da sonda do Desenho 3, em que o mesmo `probe_fighter.gd` rodou a SyncTest e o servidor com 2 e 8 clientes, e uma função pura do TypeScript chamada por uma rota nova. A segunda conferência também errou. O Claude avaliou que listar o que a parte 2 acrescenta (o aperto de mão, o fechamento, um lutador por cliente) puxou para "o lutador ganha código de rede", e explicou uma terceira vez com uma planilha e a linha do tempo de um pulo a ping 100, sem pergunta nova. Entre as rodadas, com o ok do §2, a DEC-0036 entrou na main e foi para o GitHub, e a worktree velha foi apagada.

## §1 — A abertura

"Bom dia, qual a proxima task para gente fazer?"

## §2 — As primeiras respostas

Pergunta: "Na parte 1, a cápsula roda no modo Sozinho, sem rede. O que acontece com esse código na parte 2?"

Resposta: "É reescrito para a rede", cuja descrição dizia: "O modo Sozinho roda no _physics_process do Godot, e a parte 2 passa o movimento para o tick do netfox."

A esperada era "O mesmo código segue", cuja descrição dizia: "O núcleo e o tick do netfox já são os da rede; a parte 2 só liga o servidor e os clientes em volta dele."

Pergunta: "Hoje a DEC-0036 entra na main e vai para o GitHub, que é público, e a TASK-9 fica Ready na main. Como a TASK-9 se entrega?"

Resposta: "Três partes (Recomendado)"

A opção dizia: "Uma task e três PRs: a cápsula sozinha, a cápsula em rede e a esteira. Você joga no fim de cada parte, e a parte 1 pode começar hoje."

Pergunta: "Fecho as escolhas da TASK-9 com as minhas recomendações (as três da tabela e os padrões menores)?"

Resposta: "Fechar com as recomendações (Recomendado)"

A opção dizia: "Última amostra do yaw, fechamento por arquivo, conexão provada no CI e os padrões menores da lista."

## §3 — Depois da segunda explicação

Pergunta: "Nova conferência: na parte 2, o que muda no código que move a cápsula (o _rollback_tick do lutador e o núcleo) para ela rodar em rede?"

Resposta: "Ganha uma versão de rede", cuja descrição dizia: "O lutador passa a ter dois caminhos de movimento: um para o Sozinho e outro para o servidor e os clientes."

A esperada era "Nada", cuja descrição dizia: "O mesmo _rollback_tick e o mesmo núcleo rodam no Sozinho, no servidor e nos clientes; o que muda em volta é a Main escolhendo o peer."

Pergunta: "Com o modo Sozinho explicado de novo: as três partes e as escolhas continuam valendo?"

Resposta: "Continuam (Recomendado)"

A opção dizia: "A TASK-9 fica Ready na main em três partes, com as escolhas da tabela e os padrões menores."

## §4 — As três partes e as escolhas, como a mensagem as mostrou

As três partes:

| Parte | O que nasce | O que você joga ou vê no fim |
|---|---|---|
| 1. A cápsula sozinha | Os números do `movimento.md` num `.tres`, convertidos em ticks. As regras de chão, pulo, coyote e buffer em `core/`, com teste. O lutador, a arena de blocos, a câmera e o modo Sozinho da `Main`. A SyncTest com os quatro cenários | A cápsula correndo a 7 m/s e pulando 1,2 m, com a câmera a 3,5 m: a primeira vez que você sente os números v0 |
| 2. A cápsula em rede | Os modos servidor e cliente da `Main`, a checagem de versão na conexão (o "aperto de mão"), o fechamento limpo, o oponente suavizado e um script que abre o servidor e dois clientes com lag | Duas janelas a ping 100: a sua cápsula responde na hora e a outra chega suavizada |
| 3. A esteira | As builds no PR e na tag, a imagem Docker do servidor testada no CI, a referência (um replay com hash igual no Windows e no Linux), os 60 fps em 1080p e a versão 0.1.0 com a tag | A build baixada do GitHub rodando neste PC, e o teste da fase 0: "gosto de jogar ou só da ideia?" |

As três escolhas que as DECs deixaram para a TASK-9:

| Escolha | Recomendo | Por quê, e quanto custa |
|---|---|---|
| Como o `yaw` (a direção da câmera) entra no tick (DEC-0026 §1) | A última amostra | A cápsula olha para onde a câmera estava no instante do tick, como no CoD a bala vai para onde a mira está no clique. A média chega meio tick atrasada |
| O comando para fechar o servidor (DEC-0032 §2) | Um arquivo, que o servidor confere a cada segundo | É o mais simples e funciona igual no Windows e no Linux; no Docker, basta um `docker exec … touch`. Pode levar até 1 s para fechar. Ler a entrada padrão trava o Godot e pede uma thread só para isso. Fechar por mensagem de rede (RPC), num jogo de código aberto, precisaria de senha |
| Provar a conexão no CI (DEC-0032 §1) | Sim: um cliente sem tela conecta no contêiner, passa no aperto de mão e sai; um cliente de versão errada é recusado | É o teste ponta a ponta contra o servidor de verdade, como um Playwright contra o servidor real e não contra um mock. Pela minha conta, uns 30 s a mais por push, e o CI é grátis no repositório público (DEC-0033) |

Os padrões menores:

- no máximo 2 jogadores, e o terceiro é recusado com uma mensagem;
- na SyncTest, o cenário do empurrão fica no chão. A Q-16 (ficar em pé na cabeça do outro) continua na fase 1, onde se decide jogando;
- os quatro cenários da SyncTest juntos em menos de 5 s (o portão hoje leva uns 31 s, de um teto de 90);
- o teste à mão a ping 100, com 220 como limite;
- no `project.godot`, duas configurações novas, guardadas pelo teste: a cena principal `Main` e o `flush_stdout_on_print`, sem o qual o log do servidor só aparece quando o buffer enche (F-073);
- a porta 7777/udp como padrão, trocável por `--port`;
- o aperto de mão compara versão e commit exatos, e o commit vazio do editor só bate com outro vazio.

## §5 — O ok para subir o Ready e começar a parte 1

Pergunta: "Pergunta fixa: deu para entender o que a parte 1 constrói e o que você joga no fim dela?"

Resposta: "Entendi"

Pergunta: "O Ready vai para o GitHub, que é público, e a parte 1 começa agora, na branch task-9-solo-capsule, com o harness da tabela?"

Resposta: "Sobe e começa (Recomendado)"

A opção dizia: "Push do Ready na main; abro a branch, ponho a TASK-9 em In Progress e chamo o test-writer." A tabela mostrava o test-writer no Fable, o implementer no Opus 5.5 da sessão e o reviewer no Fable.
