---
id: F-083
titulo: "A conferência da fase de desenho: a tabela da DEC-0012 contra as DECs aceitas, os checklists de pré-produção e as fontes de fora sobre multiplayer, combate corpo a corpo, game feel e Godot, e o que ficou sem nome (10/10/2026)"
recebido_em: 2026-10-10
como: Conferência feita pelo Claude (Fable 5.1, esforço máximo) na sessão 12, a pedido do Arthur (F-082 §1 e §2). A parte interna leu o roteiro, as pendências, os cinco documentos de design, os quatro de arquitetura, as 35 DECs e as tasks TASK-9 a TASK-11 na main em f7857ca. A parte externa fez onze buscas na web em 10/10/2026 e leu duas páginas inteiras; o que está entre aspas é o que a ferramenta de busca devolveu de cada página, não a página inteira. O que vira regra sai da DEC-0036, não daqui.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: a pergunta era se falta algum desenho antes de codar (F-082 §1). A conferência separa duas coisas: o desenho de base, que a DEC-0012 mandou fechar antes do código, e o desenho do jogo em si (vida, partida, modos, armas, mapas), que a DEC-0012 mandou para "a hora da funcionalidade" sem dizer a hora. Os §1 e §2 provam que a base fechou; os §3 e §4 trazem o que o mundo de fora pede; o §5 lista o que ficou sem nome; o §6 diz o que a pesquisa não achou.

## §1 — A tabela da DEC-0012, item a item

A DEC-0012 listou o que se decide "agora, dentro da fase" e o que fica "na hora da funcionalidade". Cada item do "agora" tem DEC aceita:

| Item do "agora" (DEC-0012) | Onde fechou |
|---|---|
| Números de movimento e combate v0 | `movimento.md` e `combate.md`; DEC-0013, DEC-0014, DEC-0016, DEC-0017 (Desenho 1, TASK-3) |
| Forma do estado e do tick | DEC-0022 (Desenho 2, TASK-4); DEC-0024 e DEC-0025 (Desenho 3, TASK-5) |
| Teste do netfox no 4.7.2 | DEC-0023 e DEC-0026 (Desenho 3, TASK-5) |
| Pipeline de CI, builds e versões | DEC-0027 e DEC-0028 (Desenho 4, TASK-6) |
| Política de assets e tokens visuais do combate | DEC-0029, DEC-0030 e DEC-0031 (Desenho 5, TASK-7) |
| A sexta conversa, infraestrutura e serviços | DEC-0032, DEC-0033, DEC-0034 e DEC-0035 (Desenho 6, TASK-8) |

As seis tasks de desenho estão Done no quadro (`backlog task list --plain`). A condição de "revisitar" da DEC-0012, "uma conversa mostrar que faltou uma camada", não aconteceu em nenhuma das seis. O que a DEC-0012 mandou para "a hora da funcionalidade" (mapas, armas além das três primeiras, matchmaking e salas, contas e ranking, Steam e lançamento, arte final) continua lá, com os gatilhos da DEC-0034.

## §2 — O que o mundo de fora pede antes de produzir, e onde está aqui

| O que se pede | Onde está |
|---|---|
| Pitch, público e não-objetivos | `visao.md`: a frase do jogo, os cinco pilares e os anti-pilares (F-012; F-013) |
| Pilares em ordem, com desempate | Os cinco pilares em ordem, com exemplos de briga (`visao.md`) |
| Loop central com números | `movimento.md` e `combate.md` |
| Riscos técnicos prototipados | As sondas: a suíte do netfox no 4.7.2 (F-024), as três hipóteses do rollback no Jolt (F-025), a rede com 2 e com 8 clientes (F-026; F-029), o replay por inputs (F-042), o export local e no CI (F-045), os assets, o LFS e 16 lutadores na RX 550 (F-056), os tokens a ping 0 e 120 (F-061), o servidor no contêiner e em São Paulo (F-073) |
| Esteira, builds e versões | DEC-0027; DEC-0028 |
| Arte, import, leitura do golpe e interface | DEC-0029; DEC-0030; DEC-0031 |
| Hospedagem, serviços, licença e lei | DEC-0032 a DEC-0035 |
| Cronograma e orçamento | `roteiro.md`; o orçamento do estudo (F-001); nada pago até a fase 3 (DEC-0034) |
| Protótipo jogável do loop central | Não existe. É a fase 1 (TASK-10), com o teste "divertido sozinho por 15 min?" (F-001) |

## §3 — Pré-produção e documento de design: o que as fontes disseram

- Room 8 Studio, "Video Game Development Pre Production Process: 9 Core Steps" (https://room8studio.com/news/game-pre-production-core-steps/, acessado em 10/10/2026). Resumo da busca: pilares de três a cinco, em ordem, usados para recusar funcionalidade; o documento de design nasce curto e cresce na produção; o protótipo prova a mecânica, não o acabamento.
- Stray Spark, "Game Design Document Template for Indie Devs" (https://www.strayspark.studio/blog/game-design-document-template-indie-developers-2026, acessado em 10/10/2026). Resumo da busca: uma página com pitch, pilares, não-objetivos e loop central; o resto do documento cresce "as production answers questions". Os pilares "evolve in pre-production and get locked during production".
- Video Game Development Authority, "The Game Development Production Pipeline" (https://videogamedevelopmentauthority.com/game-development-production-pipeline, acessado em 10/10/2026). Resumo da busca: o portão de saída da pré-produção pede "major technical risks identified and prototyped", um cronograma com marcos e o estilo de arte e as especificações de asset travados.
- The Level Design Book, "Pre-production" (https://book.leveldesignbook.com/process/preproduction, página lida inteira em 10/10/2026). Frases devolvidas: "Big design documents are discouraged"; para testar o controle do personagem, "big boxy courtyard levels filled with varied floors, room shapes, and game objects", "to make sure the player can comfortably move around in the game"; "Do not design for the genre, do not sleepwalk into familiar patterns". O mínimo para um projeto solo: pitch, ferramentas e escopo; o recomendado: dois ou três pilares, metas de experiência por nível, as mecânicas e uma lista de assets. A página não dá medidas de movimento: manda testá-las no mapa de caixas.
- Wayline, "The Peril of Over-Planning" e "The 'Fun First' Prototyper" (https://www.wayline.io/blog/the-peril-of-over-planning-why-flexibility-wins-in-indie-game-development e https://www.wayline.io/blog/fun-first-prototyper-indie-game-success, acessados em 10/10/2026). Resumo da busca, de um só fornecedor: provar o loop central antes de ampliar o escopo; protótipo feio, porque o acabamento esconde um núcleo fraco; parar de prototipar quando o loop diverte, para não cair em "analysis paralysis"; feedback de fora cedo.

## §4 — Multiplayer, combate corpo a corpo, game feel, acessibilidade e Godot

- Crux, "Rollback Netcode Explained" (https://crux.supercraft.host/blog/rollback-netcode-explained/, acessado em 10/10/2026). Frase devolvida: "you should not sink months into netcode before you know your multiplayer game is fun". E a diferença entre rollback P2P e compensação de lag com servidor autoritativo, "architecturally different".
- Edgegap, "Kickin' out netcode issues with Edgegap", o caso do Kung Fu Kickball (https://edgegap.com/blog/kickin-out-netcode-issues-with-edgegap, acessado em 10/10/2026). Resumo da busca: "even rollback isn't enough to hide the latency between players"; o jogo foi para "server authoritative rollback netcode". É o nosso desenho desde a DEC-0003 e a DEC-0026.
- Uhiyama Lab, "A Game Feel Primer with Hit Stop, Flash, Shake, and Sound" (https://uhiyama-lab.com/en/notes/unity/unity-game-feel-hit-feedback/, acessado em 10/10/2026). Resumo da busca: sem efeito, o acerto parece "hitting a pillow"; os efeitos "carry information, not just decoration"; o hitstop, uma pausa de quem bate e de quem leva no acerto, fica perto de 50 a 100 ms nos golpes pesados; o tremor da tela com moderação; tudo se afina jogando. Nenhuma fonte com post-mortem de For Honor, Chivalry 2 ou Mordhau apareceu; o que veio foram entrevistas e comparações (Unreal Engine, "Chivalry 2 is designed to make you feel like you're in a medieval war", https://www.unrealengine.com/en-US/developer-interviews/chivalry-2-is-designed-to-make-you-feel-like-you-re-in-a-medieval-war; TheSixthAxis, "Mordhau vs. Chivalry 2", https://www.thesixthaxis.com/2023/08/26/mordhau-vs-chivalry-2-which-medieval-multiplayer-game-is-better/; acessados em 10/10/2026), com uma frase útil: "multiplayer melee action has been a tough concept for developers to nail, with no such blueprint for this subgenre".
- Microsoft, "Xbox Accessibility Guidelines" (https://devdocs.xbox.com/build/game-principles/accessibility/xbox-accessibility-guidelines, acessado em 10/10/2026) e um guia de UX devolvido pela busca (https://tessl.io/registry/skills/github/Donchitos/Claude-Code-Game-Studios/ux-review). Resumo da busca: "Every input action must be remappable", em "keyboard, mouse, gamepad, touch", com perfis por dispositivo guardados; conferir as diretrizes contra os pilares ainda no desenho. Aqui, as teclas são físicas e remapeáveis desde o primeiro dia (DEC-0031); o gamepad não foi pensado.
- GodotCon 2024, "I made a Godot 4 multiplayer game in all the wrong ways" (https://talks.godotengine.org/godotcon-24/talk/ELJCML/, resumo lido inteiro em 10/10/2026). Só o resumo está público; ele promete lições sobre "running multiple instances in Godot, changing scenes, managing your bandwidth, and deploying your game server to the cloud". As quatro já têm resposta aqui: as sondas rodaram até 8 clientes (F-029), a Main tem os três modos (DEC-0026 §6), a banda foi medida (`rede.md` §10) e o servidor rodou em contêiner e em São Paulo (F-073). Dois devlogs de jam no itch.io (https://darngeek.itch.io/technotabbyrefuge/devlog/638669/godot-413-and-our-struggles; https://hellman.itch.io/sabba/devlog/189571/gamejam-postmortem, acessados em 10/10/2026) falam dos tropeços do `MultiplayerSynchronizer` e da autoridade de nó, que o projeto não usa: o netfox grava por caminho e o estado mora nas quatro caixas (DEC-0022; DEC-0023).

## §5 — O que a conferência achou sem nome

Nenhum é camada de base; todos cabem num desenho de fase.

1. A vida do lutador e o formato da partida. O `combate.md` tem o dano do arco (15 a 45) e do mosquete (60), sem um total de vida; o `visao-geral.md` nomeia o contexto "Partida e round" como "máquina de estados pequena e pura", sem desenho; nenhuma Q os cobre.
2. O hitstop, a pausa no acerto. Os tokens da DEC-0031 têm, na reação, o flash branco, o recuo do corpo e o "thud", e nenhuma pausa; as fontes do §4 o tratam como padrão do gênero.
3. O modo do 4v4 e do 8v8. O estudo só diz "anel visível contra 2 em 1" e "leitura de mapa" (F-001; `combate.md`).
4. Quando o arco e as armas entram. A DEC-0004, regra 6, os põe depois do online e antes do 4v4; o `roteiro.md` não tem a linha.
5. O gamepad. As teclas são remapeáveis (DEC-0031), mas só mouse e teclado foram pensados; a sensibilidade da câmera é por pixel do mouse (`movimento.md`).

## §6 — O que a pesquisa não achou

- Nenhum checklist único e reconhecido de pré-produção: o §2 é a prática comum, juntada de várias fontes.
- Nenhum post-mortem formal de For Honor, Chivalry 2 ou Mordhau, nem palestra da GDC deles sobre leitura do golpe ou formato de partida. A palestra da GDC 2018 sobre o Titanfall 2, "Designing Unforgettable Titanfall Single Player Levels with Action Blocks" (https://gdcvault.com/play/1025105/Designing-Unforgettable-Titanfall-Single-Player), está atrás de login.
- Nenhuma fonte sobre escolha de tickrate, falhas de anti-cheat ou erros de matchmaking com evidência; só guias genéricos.
- Nenhum post-mortem de jogo multiplayer lançado no Godot 4; só devlogs de jam e o resumo da GodotCon.
