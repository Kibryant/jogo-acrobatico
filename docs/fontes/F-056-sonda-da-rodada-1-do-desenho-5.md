---
id: F-056
titulo: Sonda da rodada 1 do Desenho 5 — o git que não esquece, o import do UAL2 no Godot 4.7.2, as marcas do golpe e os fps com 1, 2 e 16 lutadores animados (sessão 8, 07/10/2026)
recebido_em: 2026-10-07
como: Medido pelo Claude na sessão 8, neste PC, fora do repositório, em três pastas ao lado dele - `../git-sonda` (e o clone `../git-sonda-estranho`), `../assets-sonda-downloads` (o zip baixado, extraído numa pasta só dele) e `../assets-sonda` (o projeto Godot da sonda, que recebeu só os dois `.glb` e a licença). Os números da medição foram gerados pelo script a partir dos três arquivos de resultado da sonda, sem digitação; os do import, dos logs do modo de conferência sem tela.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: abertura da rodada 1 da TASK-7, com o ok do Arthur para começar (F-055). A rodada abre com a demonstração do git, porque a conferência da licença errou duas vezes no Ready (F-054), e segue com a sonda dos assets do critério 4: um personagem CC0 com golpes de espada, material estilizado e contorno, medido em 1080p com 1, 2 e 16 lutadores (DEC-0002; DEC-0004, regra 6; Q-22). O que está marcado como leitura do agente é inferência, não medição.

## §1 — A demonstração do git

Num repositório novo, `../git-sonda`, com o LFS ligado para `*.glb`, quatro commits: "fase 1: o jogo sem asset pago", "fase 2: o pack da Synty entra" (um arquivo `espada_synty.glb` de 61 bytes, com o texto "PACK PAGO DA SYNTY (EULA): US$ 59,99. Nao pode sair do time."), "fase 3: mais jogo" e "o pack e apagado". Depois, um clone, como faria qualquer pessoa diante de um repositório público:

```
$ git clone file:///C:/Users/arthu/Projects/git-sonda git-sonda-estranho
$ ls
jogo.txt
$ git log --oneline -- espada_synty.glb
36b29d8 o pack e apagado
4715a4e fase 2: o pack da Synty entra
$ git checkout 4715a4e -- espada_synty.glb
$ cat espada_synty.glb
PACK PAGO DA SYNTY (EULA): US$ 59,99. Nao pode sair do time.
```

- O objeto do LFS `f6f893b3560d5ced10a17a47c949e94818a424a36ac32fa6fc660fc600f7fab7` foi baixado para o clone no `checkout`.
- A primeira tentativa de clone, com o caminho no formato do Git Bash (`file:///c/Users/...`), falhou no adaptador do LFS para arquivos locais ("chdir /c/Users/arthu/Projects/git-sonda: The system cannot find the path specified"); com o caminho do Windows (`file:///C:/Users/...`), funcionou.

## §2 — O asset baixado

- Fonte: [OpenGameArt, "Universal Animation Library 2"](https://opengameart.org/content/universal-animation-library-2), licença CC0 na página, enviado por "quaternius". Arquivo `universal_animation_library_2standard.zip`, 10.257.419 bytes, sha256 `ec0e40d6d78fe9aaad59e322f40865a8675c22f0745e291622e54520391a9217`, baixado em 07/10/2026.
- Dentro do zip, com datas de 18 a 23/01/2026: `UAL2_Standard.glb` (8.061.600 bytes, o manequim com os clipes), `Mannequin_F.glb` (1.442.824 bytes, o manequim feminino, sem clipes), as versões FBX e `.blend`, três imagens de montagem (Godot, Unity e Unreal) e o `License.txt`. Não há a versão com root motion separada que a página do itch menciona (F-052 §2.1).
- O `License.txt`, como veio: "License: CC0 1.0 Universal (CC0 1.0) Public Domain Dedication https://creativecommons.org/publicdomain/zero/1.0/ ... Models by @Quaternius".
- O `README.txt` do manequim feminino, como veio: "The female mannequin doesn't include the animations, as duplicating them wouldn't make sense. You can easily retarget them from the library files in Blender, or even better, directly in your engine, since both mannequins share the same rig and very similar proportions."
- A imagem `Godot_Setup.png` mostra o retarget no Godot: na janela de import, o `Skeleton3D`, Retarget > Bone Map > New BoneMap, Profile > New SkeletonProfileHumanoid, e Reimport.

## §3 — O import no Godot 4.7.2

Godot 4.7.2-stable (official), sem tela, `godot --headless --path . --import`:

- O primeiro import dos dois `.glb` levou 5,8 s.
- O `.import` gerado traz, entre outros, `nodes/apply_root_scale=true`, `nodes/root_scale=1.0`, `meshes/generate_lods=true`, `animation/fps=30` e `animation/remove_immutable_tracks=true`.
- Lido no `.glb` (o JSON do arquivo): o manequim é uma malha com 2 superfícies (material principal laranja e material das juntas roxo, sem textura), uma pele de 65 ossos com nomes no padrão do Unreal (`root`, `pelvis`, `spine_01`, `upperarm_l`, `hand_r`, dedos, `thigh_l`...) e 43 animações, cada uma com 195 canais (65 ossos x posição, rotação e escala). O manequim feminino tem o mesmo esqueleto, com os mesmos nomes e a mesma pose de repouso no `root` e na `pelvis`.
- Depois do import, cada clipe ficou com 57 trilhas: o import tirou as que não mudam.
- O sufixo `_Loop` saiu do nome dos clipes, que ganharam a marca de laço: `Idle_FoldArms`, `Idle_Lantern`, `Idle_No`, `Idle_Rail`, `Idle_Shield`, `Idle_TalkingPhone`, `NinjaJump_Idle`, `Slide`, `TreeChopping`, `Walk_Carry`, `Zombie_Idle`, `Zombie_Walk_Fwd`.

| Manequim | Vértices | Superfícies | Ossos | Altura bruta | Altura com `root_scale = 0,98414` |
|---|---|---|---|---|---|
| UAL2 (masculino) | 8.546 | 2 | 65 | 1,829 m | 1,800 m |
| Feminino | 25.636 | 2 | 65 | 1,806 m (topo em 1,808 m) | 1,778 m (topo em 1,780 m) |

- O fator 0,98414 é 1,8 / 1,829, a altura da cápsula (`movimento.md`) sobre a altura bruta. Com `apply_root_scale`, a escala entra na malha, nos ossos e nos clipes, e o nó raiz fica com escala 1. O feminino recebeu o mesmo fator, para os dois continuarem na mesma régua.
- Num print com os dois lado a lado na pose T (`A_TPose`), o manequim e a cápsula de 1,8 m × 0,35 m têm a mesma altura.

Os clipes de interesse, com a duração lida no Godot:

| Clipe | ms | Laço | Trilhas |
|---|---|---|---|
| `A_TPose` | 2500 | não | 57 |
| `Hit_Knockback` | 833 | não | 57 |
| `Hit_Knockback_RM` | 833 | não | 57 |
| `Idle_Shield` | 2500 | sim | 57 |
| `Idle_Shield_Break` | 1067 | não | 57 |
| `Melee_Hook` | 467 | não | 57 |
| `Melee_Hook_Rec` | 600 | não | 57 |
| `NinjaJump_Idle` | 2000 | sim | 57 |
| `NinjaJump_Land` | 1267 | não | 57 |
| `NinjaJump_Start` | 967 | não | 57 |
| `Shield_Dash_RM` | 1100 | não | 57 |
| `Shield_OneShot` | 833 | não | 57 |
| `Slide` | 2000 | sim | 57 |
| `Slide_Exit` | 500 | não | 57 |
| `Slide_Start` | 833 | não | 57 |
| `Sword_Block` | 1233 | não | 57 |
| `Sword_Dash_RM` | 1567 | não | 57 |
| `Sword_Regular_A` | 433 | não | 57 |
| `Sword_Regular_A_Rec` | 967 | não | 57 |
| `Sword_Regular_B` | 533 | não | 57 |
| `Sword_Regular_B_Rec` | 1033 | não | 57 |
| `Sword_Regular_C` | 2000 | não | 57 |
| `Sword_Regular_Combo` | 3000 | não | 57 |

## §4 — A espada, as marcas do golpe e o tempo do desenho

- O UAL2 não traz espada nem osso de arma. A sonda pôs uma espada de blocos (cabo de 20 cm, guarda de 20 cm, lâmina de 90 cm) num `BoneAttachment3D` no osso `hand_r`.
- Seis direções fixas do modelo na pose de repouso (±X, ±Y, ±Z), levadas para o espaço do osso, não deram uma pegada plausível. A do eixo da frente (+Z) deu, na leitura do agente, um arco incoerente ao longo do golpe. A direção medida na pose de repouso, do nó do dedo mínimo (`pinky_01_r`) ao do indicador (`index_01_r`), com o cabo a 85% do caminho do pulso aos nós, deu um golpe coerente: a lâmina vem de trás, varre baixo pela frente e sobe.
- Oito quadros do `Sword_Regular_A` (433 ms), de 0 a 433 ms: o corpo se encolhe com a lâmina atrás até uns 186 ms, a lâmina cruza a frente perto dos 248 ms e sobe até o fim. A sonda marcou o "ativo" de 46% a 69% do clipe, de 199 a 299 ms. A marca é leitura do agente a partir dos quadros: o clipe não traz a marca de contato.
- O golpe leve do `combate.md` (300 / 100 / 250 ms) sobre esse clipe e o `Sword_Regular_A_Rec` (967 ms): a preparação de 300 ms toca 199 ms de clipe (1,5 vez mais devagar), o ativo de 100 ms toca 100 ms de clipe (no ritmo dele), e a recuperação de 250 ms toca 1.101 ms de clipe, os 134 ms finais do golpe mais os 967 ms do `_Rec` (4,4 vezes mais rápido). No ritmo próprio do clipe, o golpe inteiro leva 1.400 ms; no do desenho, 650 ms.
- A pose sai de uma função do tempo: a cada quadro, a sonda calcula qual clipe e em que ponto, com o `AnimationPlayer` em modo manual (`seek`). Com 16 lutadores, essa conta custou de 0,71 a 0,73 ms por quadro; com 1, 0,088 ms (§5).
- O manequim feminino tocou os clipes do masculino pela mesma biblioteca de animações, sem retarget no import, com as trilhas de posição removidas, menos as da `root` e da `pelvis`.

## §5 — A medição

Montagem:

- O PC do Arthur: Radeon RX550/550 Series (ATI Technologies Inc.), OpenGL 3.3.0 Core Profile Context 26.5.2.260413, renderer Compatibility, tela (1920, 1080) em tela cheia, vsync desligado e fps sem limite. Outros programas do Arthur podiam estar abertos.
- A cena: chão de 60 × 60 m com grade de 1 m, três blocos de 1, 2 e 3 m, luz direcional com sombra (alcance de 40 m), céu de cor e luz ambiente. Lutadores numa grade 4 × 4, a 2,2 m um do outro, todos na tela, com a câmera a 10,5 m e 3,2 m de altura, campo de visão vertical de 70° (`movimento.md`).
- O lutador: material toon (`DIFFUSE_TOON`, sem especular), contorno por casco invertido (`next_pass` com `grow` de 1,2 cm e `CULL_FRONT`), a espada de blocos e o golpe leve, o segundo golpe e o bloqueio em laço, cada lutador com um atraso diferente.
- Cada cenário: 2 s de aquecimento e 6 s de medição. O tempo do quadro é a diferença entre dois quadros seguidos (`Time.get_ticks_usec`). "1% piores" é o fps do 99º percentil do tempo de quadro. "Pose" é o tempo da função que posa os lutadores. Chamadas de desenho e primitivas são médias do quadro.

Duas rodadas completas, com cerca de 2 minutos entre elas (rodada 1 / rodada 2):

| Lutadores | Manequim | MSAA | Contorno | Sombras | fps médio | fps nos 1% piores | ms médio | Pior quadro (ms) | Desenhos | Primitivas | Pose (ms) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | UAL2 | desligado | sim | sim | 328,1 / 333,9 | 271,4 / 272,0 | 3,05 / 2,99 | 10,06 / 9,49 | 47 | 51.542 | 0,088 |
| 1 | UAL2 | 4x | sim | sim | 210,8 / 214,5 | 190,8 / 188,1 | 4,74 / 4,66 | 14,23 / 14,61 | 47 | 51.565 | 0,087 |
| 2 | UAL2 | desligado | sim | sim | 311,2 / 315,1 | 263,7 / 259,5 | 3,21 / 3,17 | 4,19 / 4,19 | 78 | 92.540 | 0,130 |
| 2 | UAL2 | 4x | sim | sim | 202,6 / 206,4 | 183,2 / 182,2 | 4,94 / 4,84 | 5,67 / 5,80 | 78 | 92.386 | 0,132 |
| 16 | UAL2 | desligado | sim | sim | 126,6 / 129,4 | 105,2 / 105,4 | 7,90 / 7,73 | 10,30 / 9,94 | 520 | 581.995 | 0,720 |
| 16 | UAL2 | 4x | sim | sim | 107,4 / 108,2 | 96,5 / 98,2 | 9,31 / 9,24 | 10,82 / 10,61 | 521 | 582.560 | 0,733 |
| 16 | UAL2 | 2x | sim | sim | 115,9 / 117,6 | 103,9 / 103,8 | 8,63 / 8,50 | 9,87 / 9,90 | 521 | 582.911 | 0,728 |
| 16 | UAL2 | desligado | não | sim | 145,9 / 152,2 | 115,8 / 121,2 | 6,85 / 6,57 | 9,09 / 8,78 | 268 | 296.910 | 0,720 |
| 16 | UAL2 | desligado | sim | não | 193,8 / 192,0 | 156,2 / 157,5 | 5,16 / 5,21 | 6,93 / 7,09 | 167 | 176.762 | 0,709 |
| 16 | feminino | desligado | sim | sim | 37,4 / 37,9 | 34,6 / 34,1 | 26,71 / 26,42 | 32,53 / 30,49 | 520 | 1.243.793 | 0,778 |
| 16 | feminino | 4x | sim | sim | 35,9 / 36,0 | 32,3 / 32,8 | 27,84 / 27,76 | 31,28 / 31,03 | 520 | 1.243.289 | 0,817 |

O manequim feminino (25.636 vértices), numa rodada só:

| Lutadores | Contorno | Sombras | fps médio | fps nos 1% piores | ms médio | ms no 99º percentil | Desenhos | Primitivas |
|---|---|---|---|---|---|---|---|---|
| 16 | sim | sim | 37,6 | 34,9 | 26,62 | 28,62 | 520 | 1.244.352 |
| 16 | não | sim | 52,0 | 47,8 | 19,24 | 20,91 | 268 | 627.007 |
| 16 | sim | não | 56,5 | 47,8 | 17,70 | 20,94 | 167 | 379.610 |
| 16 | não | não | 70,9 | 64,8 | 14,11 | 15,43 | 87 | 191.706 |
| 1 | sim | sim | 245,6 | 207,0 | 4,07 | 4,83 | 47 | 98.959 |
| 2 | sim | sim | 181,9 | 161,7 | 5,50 | 6,19 | 77 | 187.053 |
| 8 | sim | sim | 64,6 | 58,4 | 15,48 | 17,12 | 269 | 698.639 |

## §6 — O que os números dizem, na leitura do agente

- Com o manequim do UAL2, 16 lutadores animados ficam a 127 a 129 fps em média, com os 1% piores em 105, perto do dobro do piso de 60 fps da DEC-0002. Com MSAA 4x, 107 a 108 fps (1% piores de 96 a 98).
- O custo de cada recurso com 16 lutadores leves, pela diferença entre os cenários: sombra, cerca de 2,6 ms; MSAA 4x, cerca de 1,5 ms (2x, cerca de 0,8 ms); contorno, cerca de 1,1 ms. A função que posa os 16 custa cerca de 0,7 ms.
- Com o manequim feminino, que tem 3 vezes os vértices, 16 lutadores caem para 37 a 38 fps, e 8 ficam a 64,6 fps, com os 1% piores em 58,4. Sem contorno e sem sombra, os 16 voltam a 70,9 fps. O número de vértices por lutador é o que mais pesa nesta placa, e cada passada extra (contorno, sombra) multiplica esse peso.
- Entre os dois pontos medidos (8,5 mil vértices: 7,7 a 7,9 ms; 25,6 mil: 26,4 a 26,7 ms, com 16 lutadores), o quadro cresce cerca de 1,1 ms a cada mil vértices a mais por lutador. Por essa conta de dois pontos, o piso de 60 fps se perde perto de 16 a 17 mil vértices por lutador; com 10 mil, os 16 lutadores ficariam em uns 9,4 ms, pouco mais da metade do quadro de 60 fps (16,7 ms). A curva não é reta: pela reta que liga 2 e 16 manequins leves, os 16 femininos custariam uns 19 ms, e custaram 26,6.
- O que a medição não tem: a rede, a física, os efeitos, a interface, uma arena de verdade e o lutador do jogador perto da câmera. O jogo de verdade pesa mais que a sonda.

## §7 — Onde está a sonda e como rodar

- `../assets-sonda/main.gd` (o script inteiro), `main.tscn`, `project.godot` e `assets/ual2/` com os dois `.glb`, os `.import` e o `LICENSE.txt`. Os resultados ficam em `bench_results.json`.
- `godot --path ../assets-sonda` abre o modo de assistir, em tela cheia: [1], [2] e [3] trocam entre 1, 2 e 16 lutadores; [T] mostra o mesmo golpe no tempo do clipe e no do desenho, lado a lado; [M] troca o MSAA; [C] liga e desliga o contorno; [S], as sombras; [F] troca o manequim; [V], o vsync; [Esc] sai.
- `-- --bench` roda as 11 medições da tabela do §5; `-- --bench-set=female`, as 7 do manequim feminino; `-- --check`, sem tela, imprime a altura, os vértices e os clipes.
