---
id: TASK-7
title: 'Desenho 5: base visual, de áudio e de interface'
status: In Progress
assignee: []
created_date: '2026-10-02 16:48'
updated_date: '2026-10-08 11:38'
labels:
  - desenho
milestone: m-0
dependencies:
  - TASK-3
ordinal: 7000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
Quinta conversa da fase de desenho (DEC-0012). O combate precisa ser legível antes de ser bonito: antecipação proporcional ao dano, aviso visual e sonoro (F-001; DEC-0014), e nada acontece escondido (pilar 1, `visao.md`). Todo asset de terceiros precisa da licença conferida na origem (`assets/CREDITS.md`). A pesquisa de 07/10 (F-050 a F-053) mostrou três coisas que mudam o plano: o golpe leve de 300 ms não se defende por reação, e por isso a cor marca a exceção (F-053 §2.4); asset com EULA (Synty, Sonniss, Mixamo) obriga o repositório a ficar privado para sempre, porque o git guarda o histórico (F-050 §6); e o kit v0 pede de 77 a 150 clipes de animação, dos quais 15 a 18, os de identidade, não existem em nenhuma fonte grátis (F-052 §7).

Vitrine do visual, privada (DEC-0019): https://claude.ai/artifact/LUcBUHKJaCfjfacgPHnmzX

### Perguntas em aberto
A pauta da conversa: cada item sai com resposta, DEC ou pendência.

Rodada 1, os assets e o pipeline, com a mão na massa:
- Abre com a demonstração do git: num repositório de sonda, um arquivo apagado num commit novo continua recuperável no histórico e nos objetos do LFS. A conferência da licença errou duas vezes ao deixar a task Ready (F-054 §2 e §3).
- A política de assets: as licenças aceitas (CC0, CC BY, OFL, Apache, MIT, ISC) e as recusadas (NC, ND, Editorial, só-Unreal, uso pessoal, RemArc, e BY-SA sem ok); a linha do `CREDITS.md` por tipo de licença; o arquivo de licença ao lado do pack; a pasta dos assets de EULA e a regra do repositório privado; a cota do LFS, 10 GiB guardados e 10 GiB por mês, 2 GB por arquivo e orçamento zero sem cartão (F-050 §5); o `.gitattributes`, que hoje deixa `.gltf`, `.bin`, `.obj` e `.woff2` fora do LFS (F-050 §5).
- A checagem no portão: asset sem linha no `CREDITS.md` ou sem o arquivo de licença ao lado não entra.
- O pipeline de import: glTF como formato de entrada e FBX só quando não houver glTF (F-051 §1.1); 1 unidade = 1 m e o lutador com 1,8 m; as dicas de nome `-col`, `-colonly`, `-noimp` e `loop` (F-051 §1.3); o `.import` no git e a `.godot/` fora (F-051 §1.7); as texturas com Detect 3D no Compatibility (F-051 §1.8); a Animation Library e o rig único (F-051 §1.4; F-052 §2.1).
- O caminho da animação: a base CC0 com um rig só (Quaternius UAL1 v2.0 e UAL2, F-052 §2.1), o KayKit para arco e armas depois de um teste de retarget (F-052 §2.2), os 15 a 18 clipes de identidade à mão, com a ferramenta escolhida na fase 1 (Cascadeur Indie a R$ 42/mês no anual, ou Blender 5.2 com Rigify, F-052 §4 e §5), e a pose como função do estado, sem máquina de estados no AnimationTree (F-052 §6; DEC-0022 §3). Nenhum clipe de biblioteca tem os nossos tempos: todo clipe é reajustado fase a fase (F-052 §6.2).
- A sonda, fora do repositório (`../assets-sonda`): um personagem CC0 com clipes de espada do UAL2 importado no Godot 4.7.2, com material toon e contorno por casco invertido (F-051 §2.5), medindo a altura e os fps em 1080p neste PC com 1, 2 e 16 lutadores animados, com o MSAA desligado e ligado (DEC-0002; DEC-0004, regra 6). O Arthur assiste e diz o que sentiu (F-041).

Rodada 2, a leitura do combate e a interface, com a mão na massa:
- Os tokens: cor, pose e som por estado: o leve sem cor, o carregado desde o tick 0, o ativo, a janela e o acerto do parry, a arma de longe carregada, a finta com o corte audível (DEC-0016), a quebra de guarda, o bloqueio e a reação; o sinal no mundo primeiro, e o HUD como redundância e para o que está fora da tela (F-053 §5); a paleta no eixo azul–amarelo da Okabe-Ito, provada sob simulação de daltonismo (F-053 §3.6); o bus de som "leitura" com prioridade e ducking, porque o Godot corta o som mais antigo e não tem prioridade (F-051 §5.1; F-053 §4); a cor de time separada dos tokens e o anel do 2 em 1 por forma (F-053 §6). Os tokens como dado num Resource, lidos do estado e tocados só no tick novo (DEC-0004, regra 2).
- O que a pesquisa anotou para a fase 2, sem mudar número (DEC-0017): o leve é leitura, o carregado é reação se a postura for diferente desde o tick 0, e a janela de 80 ms do parry é apertada (Q-21; F-053 §2.4).
- O Theme e a acessibilidade mínima: um Theme só em `gui/theme/custom` (F-051 §3.1); a base de 1920 × 1080 no `project.godot`, com guarda no teste de configurações, porque hoje vale o padrão de 1152 × 648 (F-051 §3.3); a escala da interface ajustável; as teclas remapeáveis desde o primeiro dia, guardando a posição física e mostrando o rótulo do teclado ativo (F-051 §4.2 e §4.3); nenhuma informação só por cor; os nomes de acessibilidade nos menus (F-051 §4.1); as chaves de tradução por ID, com pt-BR e en (F-051 §3.5).
- A sonda: o parry de brinquedo do Desenho 3 (`../netfox-sonda`, F-027) ganha os tokens a 60 ticks, com lag simulado e um filtro de daltonismo de tela cheia, que o Compatibility suporta (F-051 §4.5). O Arthur joga de defensor e diz o que leu e o que não leu (F-041). O som que só toca no tick novo é conferido com o rollback acontecendo.

### Escolhas confirmadas
Confirmadas pelo Arthur em 07/10 (F-054 §2 a §4):
1. Greybox até o movimento ser divertido: a arena de blocos e a cápsula como lutador no esqueleto andante (TASK-9) e no começo da fase 1. O pipeline é provado agora, na sonda, para o primeiro boneco CC0 entrar na fase 1 quando os números do movimento estiverem bons.
2. Duas rodadas com sonda fora do repositório, como nos Desenhos 3 e 4, e o fechamento no modo de plano, revisado antes por um agente de planejamento.
3. A política de assets: CC0 primeiro (Kenney, Quaternius, KayKit, Poly Haven); CC BY com crédito; OFL, Apache, MIT e ISC para fontes e ícones; EULA (Synty, Sonniss, Mixamo) só com o repositório privado para sempre, registrado no `CREDITS.md`; recusar NC, ND, Editorial, só-Unreal, uso pessoal, RemArc e BY-SA sem ok; nada pago sem o ok do Arthur, dentro dos R$ 3 a 7 mil por ano do estudo (F-001); "asset sem linha não entra" vira checagem do portão.
4. O caminho da animação: base CC0 com um rig só (UAL1 v2.0 e UAL2), KayKit para arco e armas depois do teste de retarget, os clipes de identidade à mão, com a ferramenta escolhida na fase 1. Nada se compra agora. Paragon não entra.
5. Os tokens e a base da interface: três canais por estado, a cor na exceção, a paleta Okabe-Ito provada na sonda, o sinal no mundo, o bus de som com prioridade, a cor de time separada; um Theme, a base de 1920 × 1080 com guarda, as teclas físicas remapeáveis, nunca só por cor, as chaves de tradução por ID.

### Fora do escopo
- A arte final, o boneco definitivo, os mapas e os cosméticos.
- A explicação da acrobacia no mundo do jogo (Q-13): o Arthur pediu para pensar mais à frente (F-015 §1). Fica para a fase 1, quando o boneco entrar.
- O nome, o logo e a licença do jogo (Q-04; Desenho 6, TASK-8).
- As animações em si: nascem na fase 1 (movimento) e na fase 2 (espada), com a primeira necessidade.
- Comprar qualquer ferramenta ou pack.
- O leitor de tela na partida.

### O que você vai aprender
- Como o Godot importa modelo, animação e som, e o que é um Theme: a folha de estilo do jogo.
- O que CC0, CC BY e EULA permitem de verdade, e por que o git guarda para sempre.
- Por que o golpe leve não se defende por reação, e o que isso faz com a cor.
- Por que o som e o efeito só tocam no tick novo, e o que o rollback faria com eles.
- Por que a pose é uma função do estado, e não uma máquina de estados do AnimationTree.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando a conversa termina, `docs/design/visual-e-audio.md` tem a política de assets (as licenças aceitas e recusadas, a linha do `CREDITS.md` por tipo, o arquivo de licença ao lado do pack, a regra do repositório privado para EULA e a conta da cota do LFS), o pipeline de import (formato, escala, nomes, animação, texturas e o que vai para o git), o caminho da animação (fontes, rig, a pose como função do estado e os buracos) e os tokens do combate (os três canais por estado, onde o sinal mora, a paleta e o som com prioridade), com a fonte de cada número.
- [ ] #2 Quando o Arthur decide a fonte de assets e a de animação, DECs registram cada uma com a licença conferida na origem: o nome, a versão ou a data, o link, a frase que permite o uso e o que ela proíbe (repositório público, redistribuição).
- [ ] #3 Quando um asset de terceiros entra no repositório sem linha no `assets/CREDITS.md` ou sem o arquivo de licença ao lado, o portão falha; quando a linha e o arquivo existem, o passo fica verde; uma sonda prova o antes e o depois, e um canário vigia a checagem.
- [ ] #4 Quando um personagem CC0 com animações de espada é importado no Godot 4.7.2 numa sonda fora do repositório, no renderer Compatibility neste PC, ele sai com 1,8 m, com material estilizado e contorno, e uma fonte registra a altura e os fps em 1080p com 1, 2 e 16 lutadores animados, com o MSAA desligado e ligado; quando ficar abaixo de 60 fps com 16, a Q-22 registra o que foi tentado (DEC-0002; DEC-0004, regra 6).
- [ ] #5 Quando o Arthur assiste à sonda dos tokens (cor, pose e som a 60 ticks, com lag simulado, com e sem a simulação de daltonismo), ele diz o que leu e o que não leu, e uma fonte registra (F-041); quando um token não se lê, ele muda antes da DEC; quando o rollback refaz o tick de um golpe, o som não toca de novo.
- [ ] #6 Quando a conversa termina, o Theme e a acessibilidade mínima estão desenhados: um Theme só, a base de 1920 × 1080 e a escala ajustável, as teclas remapeáveis guardando a posição física, nenhuma informação só por cor e as chaves de tradução por ID; o que muda o `project.godot` entra com guarda no teste de configurações.
- [ ] #7 Quando um arquivo de um formato que a política aceita entra (`.glb`, `.gltf`, `.bin`, `.obj`, `.wav`, `.ogg`, `.ttf`, `.woff2` e os demais da lista), o `.gitattributes` o manda para o LFS, e um teste prova com um arquivo de sonda; quando um formato está fora da lista, o `visual-e-audio.md` diz por quê.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Rodada 1, os assets e o pipeline:
   - Abre com a demonstração do git num repositório de sonda: um arquivo apagado num commit novo continua recuperável no histórico e no LFS (F-054).
   - A política no papel: as licenças, a linha do `CREDITS.md`, o arquivo ao lado do pack, a pasta de EULA, a cota do LFS e o `.gitattributes`.
   - A sonda em `../assets-sonda`: o personagem CC0 com os clipes do UAL2, toon e casco invertido; a altura; os fps com 1, 2 e 16, MSAA desligado e ligado; o Arthur assiste e diz o que sentiu; a fonte com as medições.
   - O pipeline e o caminho da animação no papel; a vitrine republicada e as perguntas da rodada.
2. Rodada 2, a leitura e a interface:
   - Os tokens no papel, com a paleta e o som; o Theme, a base de 1920 × 1080, as teclas e as chaves de tradução.
   - A sonda: o parry de brinquedo com os tokens, o filtro de daltonismo e o lag; o som só no tick novo com o rollback rodando; o Arthur joga de defensor; a fonte com o que ele sentiu.
   - A vitrine e as perguntas.
3. O plano no modo de plano, revisado antes por um agente de planejamento (registro da TASK-5). Com o ok: uma fonte com o plano, as DECs (a política e as fontes de assets; o caminho da animação; os tokens e a base da interface), o `docs/design/visual-e-audio.md`, o `CREDITS.md` com a política, a checagem e o canário no portão, o `.gitattributes`, o `project.godot` com guarda, e o `AGENTS.md` acompanha o que mudar.
4. Registro: fontes, glossário, `mudancas.md`, `pendencias.md` (Q-21 e Q-22) e o registro da harness; depois o reviewer e o portão num clone limpo.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Rodada 1 (07/10, sessão 8), os assets e o pipeline:
- A demonstração do git num repositório de sonda (`../git-sonda`): o pack apagado num commit novo voltou inteiro num clone, com um comando, e o objeto do LFS veio junto (F-056 §1).
- O UAL2 Standard (CC0, OpenGameArt, zip com sha256 `ec0e40d6…`) entrou no Godot 4.7.2 em 5,8 s. O import tirou o `_Loop` do nome dos clipes e marcou o laço, e cortou cada clipe de 195 para 57 trilhas. Com `root_scale = 0,98414`, o manequim saiu com 1,800 m, a altura da cápsula (F-056 §2 e §3).
- A espada de blocos ficou na mão pela linha dos nós dos dedos. Oito quadros do `Sword_Regular_A` mostraram o ativo de 46% a 69% do clipe, e o clipe não traz essa marca. O golpe leve do desenho toca a preparação 1,5 vez mais devagar que o clipe e a recuperação 4,4 vezes mais rápido (F-056 §4).
- Os fps em 1080p, em duas rodadas: 16 manequins de 8.546 vértices a 127 a 129 fps, com os 1% piores em 105; com MSAA 4x, 107 a 108. Um manequim de 25.636 vértices derruba os 16 para 37 fps; o que pesa é o número de vértices (F-056 §5 e §6). A Q-22 ganhou a resposta medida.
- A vitrine ganhou a seção da rodada 1 (versão 3).
- Um tropeço da sonda: um argumento mal lido deixou o modo de assistir aberto em tela cheia até o limite de 300 s, numa das medições do feminino; a rodada foi refeita.

Decidido na rodada 1 (07/10), sob a delegação do Arthur (F-058):
- O jogo é aberto: repositório público, contribuições por PR e o Arthur como mantenedor principal, sem lucro. O repositório abre no Desenho 6 (TASK-8), junto com a licença do código (Q-04); até lá, segue privado.
- A política de assets fica só com licença que deixa redistribuir e modificar: CC0 primeiro; CC BY com crédito; OFL para fontes; MIT, Apache e ISC para ícones e código. A EULA e o "não redistribua" saem de vez, pagos ou grátis (Synty, Sonniss, Mixamo, Fab Standard); NC, ND, Editorial, só-Unreal, uso pessoal e RemArc seguem fora; BY-SA, só com o ok do Arthur. Nada se compra. Muda a escolha 3 do Ready (F-054 §4).
- O pipeline da sonda vira o padrão: glTF (`.glb`); a escala de import que leva o lutador à cápsula de 1,8 m; o `.import` no git; `_Loop` no nome para o laço; clipes in place; a marca do ativo à mão em cada clipe de golpe; a pose como função do estado; um rig só, o do UAL2.
- O orçamento v0 de vértices: 10 mil por lutador no detalhe máximo, com a arma, e LOD para quem está longe. Com 10 mil, os 16 ficam em uns 9,4 ms na RX 550, pela conta de dois pontos (F-056 §6). Número v0 fechado pelo Claude (DEC-0017).
- No v0, o MSAA fica em 2x (cerca de 0,8 ms com 16 lutadores), e a sombra e o contorno ficam ligados: a sombra mostra a altura de quem está no ar, e o contorno, a silhueta (pilar 1). Cortar o contorno a distância e o LOD são a primeira saída se o quadro apertar (Q-22). O MSAA entra no `project.godot`, com guarda, no fechamento.
- A sonda fica para o Arthur assistir quando quiser (`godot --path ../assets-sonda`); o que ele sentir entra numa fonte (F-041; F-055).
- A conferência da licença ficou sem resposta. A política já não depende dela, porque nada com EULA entra.
- O Arthur assistiu à sonda: achou o movimento liso, e o contorno o surpreendeu; sem ele, "pareceu outro jogo" (F-059). O contorno entra na DEC do fechamento como parte da cara do jogo: se o quadro apertar, a saída é cortá-lo de quem está longe, não desligá-lo.

Rodada 2 (noite de 07 para 08/10, sessão 9), a leitura do combate e a interface:
- A sonda (`../netfox-sonda/sonda`, F-061): o parry de brinquedo ganhou os quatro golpes (leve, carregado com carga sorteada, quebra de guarda, finta), as três defesas, os tokens como dado num Resource, o som sintetizado no bus "leitura" com ducking do ambiente, o filtro de daltonismo de tela cheia com as matrizes da vitrine, o Theme único com a base de 1920 × 1080 e a escala pelas teclas, as teclas por posição física com o rótulo do layout, as cadeias por ID em pt-BR e en, e a versão de brinquedo do julgamento na tela de quem defende (DEC-0026 §3).
- Achado de arquitetura (F-061 §2; `mudancas.md`): "som só no tick novo" cobre um caso só. O oponente espelhado nunca tem tick novo, e o veredito do contato nasce sempre num tick refeito. A regra que cobre os três casos é a chave do evento: cada cue apresentada uma vez, quando aparece no estado exibido. No cliente a ping 120, o `is_fresh` veria de um terço a metade dos eventos (SyncTest: 42 apresentados, 42 `is_fresh`, 168 ingênuos, zero divergência em 10.752 conferências). A redação da DEC-0004 (regra 2) e do `rede.md` muda no fechamento, com o ok do Arthur.
- O atraso de visão vem do próprio estado (`sim_tick`): o `get_last_known_state()` do netfox devolve zero para o oponente no cliente.
- O bot leitor de 200 ± 40 ms a ping 120: carregado aparado 8 de 8 com 50 ms de margem (contra zero no relógio do servidor no Desenho 3), quebra esquivada 13 de 16 (as 3 perdidas chegaram 14 a 25 ticks atrasadas: jitter, Q-09), finta sem morder 12 de 12, leve bloqueado 5 de 12 (a moeda da F-053 §2.4).
- O Arthur jogou dois jogos, visão comum e deuteranopia (F-062): achou complicado e pouco claro, foi "no susto", desconfia do ping, não formou opinião sobre o som (sem fone) e pediu para testar mais. Os logs: a cor do carregado se leu (F em meio segundo, 29 de 29), o tempo do parry não (1 em 29, com a carga sorteada; 3 parries de 0 a 33 ms no leve, de preparação fixa); a forma da quebra não se leu (F em vez de esquiva, 1 esquiva em 27); a finta mordida 8 de 27; o leve "não tinha nem como reagir" (300 ms, F-053 §2.4).
- O que muda antes da DEC (critério 5): a quebra ganha cor, a mão em vermelhão desde o tick 0, com o pulso e o pisão mantidos (trocado na sonda); o carregado de carga variável vai para a Q-21; o próximo teste roda a ping 0 e 100, com fone, antes do fechamento.
- Sob deuteranopia o par vermelho × verde vira dois tons de oliva; os tokens seguem separados pelo brilho; o roxo "de longe" chega perto do cinza do leve (ponto para o arco).
- A vitrine ganhou a seção da rodada 2 (versão 4).

- Correção: a vitrine da rodada 2 é a versão 5 do artefato, não a 4.

- Re-teste na mesma noite, a ping 0 e 100, com fone (F-063): o mesmo padrão sem lag. Nenhum parry no carregado em 21 (a carga sorteada), a quebra respondida com F mesmo com a mão vermelha (esquiva a tempo 2 de 22), 3 parries no leve com margem de 0 a 17 ms ("senti que ia sair e apertei"), a finta mordida 7 de 20. O lag está descartado; a quebra vira a Q-25 (reação de escolha em 350 ms); a Q-21 ganha a prova a ping 0. A sonda não muda de novo; o fechamento pode seguir.

Fechamento (08/10, sessão 9), sob o plano aprovado (F-065):
- A sonda do "antes" do critério 3: um pack falso em `assets/third_party/sonda/pack/modelo.txt`, sem linha no `CREDITS.md` e sem licença, passou pelo portão de hoje: `bash tools/gate.sh` terminou em "gate green in 18s", com saída 0. O buraco existia.
- A pergunta fixa da chave do evento foi acertada: "o is_fresh só existe para o nó que este PC simula".

- O implementer (um round): `tools/check_assets.sh` com os canários (`bad_no_line`, `bad_no_license`, `bad_stray_file`, `good_pack`; o orquestrador acrescentou `bad_name` para a regra do snake_case, que só a sonda provava), o passo "Assets and LFS (DEC-0029)" no portão, o `.gitattributes` com dez formatos novos (nenhum arquivo rastreado tinha essas extensões), o `project.godot` gravado por `ProjectSettings.save()` sem tela (a regravação deixou o arquivo idêntico, `cmp`), e quatro testes com cinco guardas no `project_settings_test.gd`, cada uma derrubada por sonda (1152, 648, "disabled", "ignore", 0).
- A sonda do "depois" do critério 3: o pack `assets/third_party/sonda/pack/modelo.txt` sem licença e sem linha derruba o portão com duas linhas nomeando o pack; com `LICENSE.txt`, cai só pela linha; o canário `good_pack` prova o caso que passa. Um arquivo solto e uma pasta `sonda-x` caem pelos dois motivos.
- A prova do LFS (critério 7): `git check-attr` em 28 formatos diz `lfs` e em 6 de texto diz `unspecified`; um `modelo.gltf` e um `fonte.woff2` de 52 bytes num pack temporário apareceram em `git lfs ls-files` (`f7d16005b0` e `3b68579668`) e o `cat-file` mostrou o ponteiro; um arquivo vazio não vira ponteiro (provado num repositório de sonda), por isso os canários usam `modelo.txt`. O pack temporário saiu antes do commit.
- Ressalvas do implementer: a largura e a altura ficaram num teste só, com uma asserção de `Vector2i` (as cinco guardas caem); o `grep -F -w` evita que a linha de `pack_v2` valha pela de `pack`.
<!-- SECTION:NOTES:END -->
