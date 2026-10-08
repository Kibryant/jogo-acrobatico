---
id: DEC-0030
titulo: O pipeline de import e o caminho da animação — glTF, 1,8 m pela escala de import, um rig só, a pose como função do estado, a base CC0 com os clipes de identidade à mão, e o orçamento de 10 mil vértices com MSAA 2x, sombra e contorno
data: 2026-10-08
status: aceita
decidido_por: Arthur (F-054 §4, escolhas 1 e 4; F-059), com os números v0 pelo Claude (DEC-0017)
fontes: [F-051, F-052, F-054, F-056, F-058, F-059, F-065]
substitui:
substituida_por:
---

# DEC-0030 — O pipeline de import e o caminho da animação: glTF, 1,8 m pela escala de import, um rig só, a pose como função do estado, a base CC0 com os clipes de identidade à mão, e o orçamento de 10 mil vértices com MSAA 2x, sombra e contorno

## Contexto

O Desenho 5 precisava dizer como um asset chega à tela e de onde vêm as animações, antes de qualquer arte entrar. A pesquisa leu a documentação do Godot 4.7.2 (F-051 §1) e as fontes de animação (F-052). O kit v0 pede de 77 a 150 clipes, dos quais 15 a 18, os de identidade (parede, gancho, carregado em fases, parry, finta, atordoado, troca de arma), não existem em nenhuma fonte grátis (F-052 §7).

A rodada 1 provou o pipeline numa sonda fora do repositório (F-056): o manequim CC0 do UAL2 entrou no Godot 4.7.2 em 5,8 s, com 1,800 m pela escala de import, com material toon, contorno por casco invertido e uma espada de blocos, e 16 lutadores animados ficaram a 127 a 129 fps em 1080p na RX 550, com os 1% piores em 105; um manequim com três vezes os vértices caiu para 37 fps (F-056 §5 e §6). O Arthur assistiu: "achei muito liso, muito massa" e "o contorno ali eu achei muito importante [...] Quando eu desativei, mano, pareceu outra coisa, pareceu outro jogo" (F-059 §1).

Ao deixar a task Ready, o Arthur escolheu o greybox até o movimento ser divertido e o caminho da animação com base CC0, KayKit depois de um teste de retarget e os clipes de identidade à mão, sem comprar nada (F-054 §4, escolhas 1 e 4). Mixamo, Synty e Paragon saíram com a política de assets (DEC-0029; F-058).

## Opções consideradas

1. **FBX como entrada:** o Godot o lê pelo ufbx desde o 4.3, mas a documentação recomenda o glTF 2.0, e o `.glb` traz malha e texturas num arquivo só (F-051 §1.1). FBX fica só para o que não tem glTF.
2. **`.blend` no repositório:** o Godot chama o Blender para exportar, e todo mundo precisa do Blender instalado (F-051 §1.1), inclusive o CI (inferência do agente). Não entra.
3. **Root motion para mover o corpo:** o estado do jogo passaria a depender de um nó que o rollback não restaura (F-051 §1.6; F-007). O movimento vem do núcleo, e os clipes entram in place.
4. **Máquina de estados no AnimationTree:** a DEC-0022 §3 já tinha decidido o contrário; a sonda posou 16 lutadores por uma função do estado em 0,7 ms por quadro (F-056 §4 e §5).
5. **O orçamento de vértices:** 8,5 mil (o manequim medido), 10 mil ou 16 mil (onde a reta de dois pontos perde os 60 fps). Com 10 mil, os 16 ficam em uns 9,4 ms, pouco mais da metade do quadro, e sobra para a arena, os efeitos, a interface e a rede, que a sonda não tem (F-056 §6).
6. **O MSAA:** desligado, 2x (cerca de 0,8 ms com 16) ou 4x (cerca de 1,5 ms) (F-056 §6). O 2x suaviza a serrilha do contorno pela metade do custo do 4x.
7. **O contorno:** ligado (cerca de 1,1 ms com 16) ou desligado. É parte da cara do jogo (F-059): se o quadro apertar, sai de quem está longe, nunca de vez.

## Decisão

### 1. O formato e a escala

- A entrada é glTF 2.0 binário, `.glb`; FBX só quando a fonte não tiver glTF, e sempre medindo a altura depois do import (F-051 §1.1; §7). `.blend`, `.psd` e `.kra` não entram no projeto; se um dia um arquivo de origem entrar, fica numa pasta com `.gdignore`, no LFS (F-051 §1.9).
- 1 unidade é 1 metro, a convenção do Godot (F-051 §1.2: a frase não aparece palavra por palavra na documentação). O lutador sai com 1,8 m, a altura da cápsula (`movimento.md`), pela escala de import `nodes/root_scale` com `apply_root_scale`, que entra na malha, nos ossos e nos clipes e deixa o nó raiz com escala 1 (F-051 §1.2). O manequim do UAL2 tinha 1,829 m e ficou com 1,800 m com `0,98414` (F-056 §3).

### 2. As dicas de nome e o que vai para o git

- `-col` e `-colonly` criam a colisão dos mapas; `-noimp` descarta luzes e câmeras de apoio; `loop` no nome do clipe marca o laço (F-051 §1.3). O import do UAL2 tirou o sufixo `_Loop` e marcou o laço sozinho (F-056 §3).
- O `.import` ao lado de cada asset vai para o git; a pasta `.godot/` e os `.translation` não (F-051 §1.7).
- Arquivos e pastas em snake_case: o pacote do jogo diferencia maiúsculas, e o Windows não (F-051 §1.9).

### 3. As texturas

- As texturas de material 3D usam Detect 3D, que liga mipmaps e a compressão de vídeo; no Compatibility, em desktop, sai S3TC (F-051 §1.8). Ícones e HUD ficam em Lossless.

### 4. A animação

- **Um rig só:** o do UAL2, com 65 ossos e os nomes no padrão do Unreal (F-056 §3). O UAL1 v2.0 do itch usa o mesmo esquema (F-052 §2.1).
- **Uma Animation Library** compartilhada, com os clipes salvos em arquivo, para as trilhas próprias sobreviverem ao reimport (F-051 §1.4). O manequim feminino tocou os clipes do masculino pela mesma biblioteca (F-056 §4).
- **Clipes in place:** o deslocamento vem do núcleo; o root motion nunca move o lutador (F-051 §1.6; F-052 §6.3).
- **A marca do ativo à mão em cada clipe de golpe:** a biblioteca não traz; no `Sword_Regular_A` ela fica de 46% a 69% do clipe (F-056 §4).
- **Todo clipe reajustado fase a fase pelo estado:** o golpe leve do desenho toca a preparação 1,5 vez mais devagar que o clipe e a recuperação 4,4 vezes mais rápido (F-056 §4; F-052 §6.2). O tempo vem do núcleo, sempre.
- **A pose é uma função do estado:** a cada quadro, qual clipe e em que ponto, a partir do modo, do tick de início e do tick atual, com o mixer em modo manual; nada de máquina de estados no AnimationTree (DEC-0022 §3; F-051 §1.6; F-052 §6.2).
- **Retarget** só para juntar fontes diferentes, com o `BoneMap` e o perfil humanoide, e com os limites que a documentação declara (F-051 §1.5).

### 5. As fontes de animação

- A base CC0 com um rig só: o UAL1 v2.0 do itch e o UAL2 (DEC-0029 §2).
- O KayKit Character Animations para arco, pistola e mosquete, depois de um teste de retarget, porque o rig dele não tem pescoço, clavícula nem dedos (F-052 §2.2; §8).
- Os 15 a 18 clipes de identidade feitos ou ajustados à mão (F-052 §7.5), com a ferramenta escolhida na fase 1, quando o primeiro clipe de parede for necessário: o Cascadeur Indie (R$ 42 por mês no anual, perpétua depois de 12 meses) ou o Blender 5.2 com Rigify, grátis (F-052 §4 e §5). Nada se compra agora (F-054 §4, escolha 4).
- Mixamo, Synty e Paragon não entram (DEC-0029; F-052 §8).

### 6. O orçamento de vértices e o quadro

Números v0, fechados pelo Claude a partir da sonda (F-056 §5 e §6; DEC-0017):

| O quê | Valor v0 | De onde vem |
|---|---|---|
| Vértices por lutador, no detalhe máximo, com a arma | 10 mil | Com 8.546, os 16 ficam a 127 a 129 fps; com 25.636, a 37. Pela reta entre os dois pontos, cerca de 1,1 ms a cada mil vértices a mais por lutador; com 10 mil, uns 9,4 ms, pouco mais da metade do quadro de 60 fps (F-056 §6) |
| MSAA | 2x | Cerca de 0,8 ms com 16 lutadores; o 4x custa 1,5 ms (F-056 §6). Entra no `project.godot`, com guarda |
| Sombra | Ligada | Cerca de 2,6 ms com 16; mostra a altura de quem está no ar (F-056 §6; pilar 1) |
| Contorno por casco invertido | Ligado, 1,2 cm | Cerca de 1,1 ms com 16 (F-056 §5 e §6); "pareceu outro jogo" sem ele (F-059 §1) |
| LOD e o contorno a distância | A primeira saída se o quadro apertar | O LOD vem do import (`meshes/generate_lods`, F-056 §3); o contorno sai de quem está longe, nunca de vez (F-059; Q-22) |

### 7. O greybox

A arena é de blocos e o lutador é a cápsula no esqueleto andante (TASK-9) e no começo da fase 1; o primeiro boneco CC0 entra quando os números do movimento estiverem bons (F-054 §4, escolha 1).

## Consequências

- A TASK-9 e a TASK-10 começam com a cápsula; o manequim do UAL2 entra na fase 1 pelo import da sonda, com o mesmo `root_scale`.
- A fase 1 escolhe a ferramenta dos clipes de identidade, com o primeiro clipe de parede; a fase 2 marca o ativo nos clipes de espada.
- O teste de retarget do KayKit acontece antes do arco, na fase 3.
- O `project.godot` ganha o MSAA 2x, guardado por teste (TASK-7, critério 6).
- A Q-22 está respondida; a confirmação com o jogo de verdade vem no 4v4 e no 8v8 (DEC-0004, regra 6). O LOD e o contorno a distância só se desenham se o quadro apertar.
- A vitrine da rodada 1 guarda as capturas e os fps (F-056).

## Revisitar se

- O jogo de verdade, com arena, efeitos, interface e rede, cair abaixo de 60 fps com 16 lutadores no PC do piso (DEC-0002).
- Uma fonte CC0 sumir ou mudar de licença.
- O teste de retarget do KayKit falhar: aí os clipes de arco e armas entram na conta do que se faz à mão.
- O Arthur não gostar do toon com o manequim de verdade.
