---
id: TASK-5
title: 'Desenho 3: a rede'
status: Done
assignee: []
created_date: '2026-10-02 16:48'
updated_date: '2026-10-04 18:00'
labels:
  - rede
  - desenho
milestone: m-0
dependencies:
  - TASK-4
ordinal: 5000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
Terceira conversa da fase de desenho (DEC-0012). A rede é a parte mais cara de mudar depois. O netfox resolve previsão e rollback, mas a compensação de lag para espada e tiro não vem pronta (F-005 §4), e ele nunca rodou no 4.7.2 (Q-02). O Desenho 2 deixou três hipóteses para provar com ele rodando (DEC-0022), e a Q-01, 30 ou 60 ticks, espera a medição, já com a evidência do parry: 80 ms viram 67 a 30 ticks e 83 a 60 (DEC-0022).

Vitrine da rede, privada (DEC-0019): https://claude.ai/artifact/Sb4Q5e4M16UymdoaR9UAzp

### Perguntas em aberto
A pauta da conversa: cada item sai com resposta, DEC ou pendência.

Rodada 1, o netfox de verdade:
- Q-02: a suíte do netfox no 4.7.2, o #659 e o commit. Conferido em 03/10: a main segue no `cf5189d`, e o #659 segue aberto.
- Hipótese 1 (DEC-0022): o caminho aninhado `:state:mode` grava, restaura e vai pela rede. Lido em 03/10: o RollbackSynchronizer guarda o nó e o caminho `state:mode` e relê o objeto a cada vez (`property-pool.gd`, `property-entry.gd`); o serializador manda os valores em ordem, nó por nó (`dense-snapshot-serializer.gd`).
- Hipótese 2: o contorno do transform (estático, transform, cinemático) faz um lutador colidir com o outro na posição certa ao refazer um tick. O lugar dele é o `after_prepare_tick` (`network-rollback.md`).
- Hipótese 3, em risco: `on_floor` no estado substitui o movimento extra de velocidade zero. Lido em 03/10: o `move_and_slide()` do Godot 4.7.2 guarda o próprio "estava no chão" (`character_body_3d.cpp:95`) e o usa no snap (linhas 394 e 495); depois de um rollback, esse valor é do presente. A sonda testa em rampa de 45°, beirada e pouso.
- Q-01: 30 ou 60 ticks, medindo e jogando.

Rodada 2, o desenho:
- O input: o que vai nele, o comando de um toque e o `input_delay`.
- O oponente no passado: interpolação ou previsão de input (a da main tem bug aberto, o #613), e o efeito no parry (F-007 §6).
- A compensação de lag: o golpe a favor de quem ataca, até ~220 ms, e o bloqueio no tempo de quem defende (DEC-0011), com um teto contra o lag switch (F-005 §4).
- A detecção do golpe de espada dentro do rollback: ShapeCast3D ou forma analítica no núcleo (F-007 §8).
- Se a fase 1 já nasce no tick do netfox (`roteiro.md`).
- A `Main`: como o mesmo projeto sobe como servidor dedicado ou como cliente (DEC-0022 §5).

### Escolhas confirmadas
Confirmadas pelo Arthur em 03/10, com 8 clientes já (F-023 §2 e §3):
- O netfox na main fixada no `cf5189d`, com core e extras (DEC-0003). Se a suíte falhar só nos 4 testes de float16, ele entra assim mesmo, sem usar float16. Se falhar em rollback, tempo ou sincronização, a sonda testa o release v1.35.3, e a escolha volta para o Arthur.
- O contorno do #659: os autoloads do netfox com `res://` no `project.godot`, guardados por um teste, em vez de remendar o código do netfox.
- As sondas moram fora do repositório, em `../netfox-sonda`. O `rede.md` guarda o commit, a montagem e os números; a prova permanente nasce como teste na TASK-9 (DEC-0004, regra 4).
- A medição roda com um servidor dedicado sem tela e com 2 e com 8 clientes, a ping 0, 100 e 220, a 30 e a 60 ticks. Com 2 clientes, o simulador do netfox; com 8, o clumsy 0.3, porque o simulador trava com 4 ou mais (#554). O clumsy é ferramenta nova, aprovada pelo Arthur (F-023 §2); usa o driver WinDivert e pede administrador.
- A compensação de lag e a detecção do golpe ficam no papel, com a viabilidade conferida no código do netfox. O código delas nasce com a espada: local na fase 2, em rede na fase 3.

### Fora do escopo
- Hospedagem (Desenho 6, TASK-8).
- Código de jogo: a cápsula em rede é a TASK-9. As sondas são descartáveis e ficam fora do repositório.
- O código da compensação de lag e da detecção do golpe (fases 2 e 3).
- Jitter e 16 lutadores: seguem com a Q-09 e com a regra 6 da DEC-0004.
- noray e NAT: com servidor dedicado, não são necessários (F-005 §9).

### O que você vai aprender
- Previsão, reconciliação, rollback e interpolação funcionando de verdade, com um servidor, 2 e 8 clientes e lag simulado, e você jogando a 30 e a 60 ticks.
- Por que o oponente está sempre no passado, e o que isso faz com o parry.
- Compensação de lag: quem o servidor favorece, e por que o killcam do CoD mostra você na mira atrás da parede.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Quando a suíte do netfox roda no Godot 4.7.2, sem tela, no commit `cf5189d`, o resultado fica registrado numa fonte, com o total de testes, os que falham e o motivo de cada falha (Q-02).
- [x] #2 Quando a suíte não falha em rollback, tempo nem sincronização, o netfox (core e extras) entra em `addons/` fixado no commit, com uma DEC, e o portão fica verde num clone limpo, com import do zero; quando falha, ele não entra, e a DEC registra o contorno ou o release v1.35.3, decidido com o Arthur.
- [x] #3 Quando um autoload do netfox aparece com `uid://` no `project.godot`, o teste de configurações falha (#659).
- [x] #4 Quando a sonda roda com um servidor dedicado, dois clientes e lag simulado, cada hipótese da DEC-0022 fica provada ou derrubada no `rede.md`, com o que foi medido; uma hipótese derrubada vira uma DEC que substitui o trecho da DEC-0022, e a `visao-geral.md` acompanha.
- [x] #5 Quando a sonda roda a 30 e a 60 ticks, com 2 e com 8 clientes e ping 0, 100 e 220, o `rede.md` e a vitrine da rede registram a CPU por tick do servidor e dos clientes, a banda por cliente e o atraso de ponta a ponta; se o servidor não acompanhar os 8, isso fica registrado na Q-09.
- [x] #6 Quando o Arthur joga os dois tickrates e escolhe, uma DEC registra o tickrate, a Q-01 fecha, e o `project.godot` e o teste de configurações guardam o valor.
- [x] #7 Quando a conversa termina, `docs/arquitetura/rede.md` existe, com o tick, o input, o rollback, o oponente no passado, a compensação de lag, a detecção do golpe, a fase 1 no tick e a `Main`, e cada comportamento do netfox citado pelo arquivo e pelo commit.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Critérios de aceite verificados
- [x] #2 Teste automatizado para toda regra do núcleo (core/)
- [x] #3 Diário da sessão escrito e glossário atualizado
- [x] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Rodada 1, o netfox de verdade:
   - Clone do netfox em `../netfox-sonda`, no `cf5189d`; a suíte (`sh/test.sh`) no Godot 4.7.2, sem tela.
   - A sonda: dois lutadores com o `FighterState` aninhado, rampa de 45°, beirada e pouso, Jolt explícito e servidor dedicado sem tela; o contorno do transform no `after_prepare_tick`.
   - A medição: 2 clientes no simulador do netfox e 8 no clumsy, com um cenário rodado nas duas ferramentas para conferir que dão o mesmo. Com 8, sete clientes rodam sem tela, com input roteirizado, e o Arthur joga o oitavo. A CPU da máquina inteira entra no registro, porque os 9 processos dividem os 4 núcleos do 3200G.
   - Os números: os monitores do `NetworkPerformance` (duração do loop de rollback, ticks refeitos), os bytes do ENet e o atraso de ponta a ponta.
   - O Arthur joga a 30 e a 60 ticks, com um parry de brinquedo (o golpe leve e a janela de 80 ms do v0).
   - A vitrine republicada com os números; perguntas da Q-01 e do que cair das hipóteses.
2. Rodada 2, o desenho: o input, o oponente no passado, a compensação, a detecção do golpe, a fase 1 no tick e a `Main`, com a vitrine e as perguntas.
3. O plano no modo de plano; com o ok, uma fonte com o plano, as DECs (o netfox no 4.7.2, o tickrate e a rede), o netfox em `addons/` com o teste do `res://` (implementer) e o `rede.md`.
4. Registro: fontes, glossário, `mudancas.md`, `pendencias.md` (Q-01, Q-02, Q-09), `roteiro.md`, o clumsy no `AGENTS.md` e a `visao-geral.md` se uma hipótese cair; depois o reviewer e o portão.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Sessão 4 (03 e 04/10/2026), rodada 1, o netfox de verdade, concluída:
- Q-02: a suíte do netfox no 4.7.2, no `cf5189d`, passou em 297 de 301 testes; os 4 que falham são de float16. O #659 foi reproduzido: o import do zero com `uid://` dá 30 erros e sai com código 0 (F-024). Critério 1 cumprido.
- Sonda fora do repositório (`C:\Users\arthu\Projects\netfox-sonda\sonda`), com SyncTest por rollback forçado (F-025):
  - hipótese 1 provada: gravação, restauração e rede, com 349 de 349 pulos e depois 747 e 764 de 764;
  - hipótese 2 provada com o contorno do transform; sobra o caso de ficar em pé na cabeça do outro (Q-16);
  - hipótese 3 derrubada; o contorno D zera as divergências.
- Medição com 2 clientes, a 30 e 60 ticks, ping 0, 100 e 220 (F-026), e com 8 clientes pelo clumsy (F-029). Com 8 lutadores, 30 ticks deixa o servidor deste PC no limite com lag, e 60 não cabe.
- O parry de brinquedo:
  - o Arthur jogou seis partidas (F-027), depois de o brinquedo ser refeito com prints da tela;
  - o bot de reação fixa (F-028) mostrou que, pela regra do netfox, não se defende por reação com ping de 100 ms ou mais;
  - o bot com reação de gente, sem lag, deu 50% a 30 ticks e 72% a 60 (F-029).
- Decisões do Arthur (F-030): 60 ticks por segundo (Q-01) e o contorno D. As DECs saem no plano do fim do Desenho 3.
- No caminho, o Smart App Control do Windows passou a barrar o `backlog.exe`; o Arthur o desligou (F-031).
- Falta: a rodada 2 (o desenho), o plano, as DECs, o netfox em `addons/` com o teste do `res://`, o `rede.md`, o reviewer e o portão.
Sessão 5 (04/10/2026), rodada 2 e fechamento:
- Rodada 2, o desenho (F-032). O Arthur:
  - entendeu quem paga o atraso;
  - escolheu a posição na espada pela tela de quem ataca;
  - fechou com os padrões o input, o oponente no passado, a detecção no núcleo, a fase 1 no tick, a Main e o teto de 200 ms.
  - As perguntas saíram da vitrine na versão 8.
- O plano:
  - foi revisado antes por um agente de planejamento: 8 pontos, 3 graves, todos absorvidos;
  - foi aprovado no modo de plano (F-033);
  - registra que o critério 4 vale com a SyncTest para as hipóteses 2 e 3.
- As DECs:
  - DEC-0023, o netfox no 4.7.2;
  - DEC-0024, 60 ticks;
  - DEC-0025, os contornos do rollback, que substitui a hipótese 3 da DEC-0022;
  - DEC-0026, a rede.
- O implementer:
  - copiou o netfox para addons/ com git archive do cf5189d: 177 arquivos, e só os 9 .svg.import diferem do upstream (F-036 §2);
  - o project.godot ganhou os 14 autoloads em res://, os 3 plugins, tickrate 60 e as duas linhas de [physics] na ordem em que o Godot grava;
  - o test/project_settings_test.gd ganhou 12 testes, 17 no total.
- As sondas: autoload em uid://, tickrate 30, autoload fora de ordem, autoconnect ligado e plugin desligado fazem falhar o teste certo. Abrir e fechar o editor não muda nenhum arquivo.
- A base:
  - o rede.md cobre o tick, o input, o rollback e as hipóteses, o oponente no passado, a compensação, a detecção, a fase 1, a Main e as medições (critérios 4, 5 e 7);
  - a F-034 traz a CPU por tick dos clientes e a banda de subida, dos mesmos logs;
  - a F-036 traz o GitHub em 04/10, os .import e o modelo do parry.
- A vitrine está na versão 9 (https://claude.ai/artifact/Sb4Q5e4M16UymdoaR9UAzp). A tabela do critério 5 fica na seção "30 ou 60 ticks", em "O que a sonda mediu: servidor dedicado, com 2 e com 8 clientes".
- O reviewer pediu mudanças: 4 citações sem apoio na fonte e um teste que a DEC prometia. Depois do conserto, aprovou.
- O portão:
  - verde aqui, com 17 testes em 17 s;
  - verde num clone limpo do commit 640040b, sem .godot e com import do zero, em 24 s, com o git status vazio depois.
- DoD #2: task de desenho, sem regra de núcleo; os testes novos guardam configuração.
- O Arthur perguntou sobre o desenho do jogo e sobre hacks (F-035). A proteção contra hack virou a Q-19.
<!-- SECTION:NOTES:END -->

## Comments

<!-- COMMENTS:BEGIN -->
author: Claude
created: 2026-10-02 22:40
---
Entrada do Desenho 2 (TASK-4; DEC-0022), para este desenho provar com o netfox rodando no 4.7.2. Leitura feita no código-fonte, main, commit `cf5189d`:
- Hipótese 1: o caminho aninhado `:state:mode` funciona de ponta a ponta: grava, restaura e vai pela rede. O `snapshot.gd` lê com `get_indexed`, mas a serialização para a rede não foi lida.
- Hipótese 2: o contorno do transform (estático, transform, cinemático) do `rollback-caveats.md`, que o guia diz valer para o Jolt, deixa um lutador colidir com o outro na posição certa durante a re-simulação.
- Hipótese 3: guardar `on_floor` no estado substitui o movimento extra de velocidade zero que o guia sugere para o `is_on_floor()`.
- Evidência para a Q-01: com o arredondamento da DEC-0022, a janela de parry de 80 ms vira 2 ticks (67 ms, −17 %) a 30 ticks, e 5 ticks (83 ms, +4 %) a 60. O buffer de 150 ms vira 167 ms a 30 ticks e fica exato a 60.
---
<!-- COMMENTS:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Desenho 3 fechado. O netfox entra em addons/ fixado no cf5189d, com os autoloads em res:// e o tickrate de 60 guardados por teste (DEC-0023, DEC-0024). A SyncTest provou as hipóteses 1 e 2 e derrubou a 3, que o contorno D substitui (DEC-0025). A rodada 2 desenhou a rede (DEC-0026): o input; o oponente no passado, sem previsão; a compensação, com a defesa na tela de quem defende e o contato na de quem ataca, até 200 ms; a detecção por forma no núcleo, em fatias varridas; a fase 1 no tick; e a Main com três modos. O detalhe e as medições estão em docs/arquitetura/rede.md. Ficam abertas a Q-09 (8 lutadores a 60 ticks), a Q-16, a Q-17, a Q-18 e a Q-19.
<!-- SECTION:FINAL_SUMMARY:END -->
