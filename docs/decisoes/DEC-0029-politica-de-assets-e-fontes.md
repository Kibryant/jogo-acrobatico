---
id: DEC-0029
titulo: A política de assets — só licença que deixa redistribuir e modificar, as fontes conferidas na origem, a pasta com a licença ao lado, a linha do CREDITS.md, a checagem no portão e a cota do LFS
data: 2026-10-08
status: aceita
decidido_por: Arthur (F-054 §4; F-058), com a política só-redistribuível e o momento de abrir o repositório decididos pelo Claude por delegação (F-058 §2), e os números v0 pelo Claude (DEC-0017)
fontes: [F-050, F-052, F-054, F-056, F-058, F-065]
substitui:
substituida_por:
---

# DEC-0029 — A política de assets: só licença que deixa redistribuir e modificar, as fontes conferidas na origem, a pasta com a licença ao lado, a linha do CREDITS.md, a checagem no portão e a cota do LFS

## Contexto

Todo asset de terceiros precisa da licença conferida na fonte, e asset sem linha no `assets/CREDITS.md` não entra: a regra vale desde a TASK-1, mas ninguém a conferia. A pesquisa do Desenho 5 leu as licenças na origem em 07/10/2026 (F-050) e achou três famílias: a CC0, em que o autor abre mão de tudo; a CC BY, que pede crédito; e a EULA de loja, que vende o direito de usar e proíbe passar o arquivo adiante (F-050 §1.5; §3 C05).

Ao deixar a TASK-7 Ready, o Arthur confirmou uma política que ainda aceitava EULA, desde que o repositório ficasse privado para sempre (F-054 §4, escolha 3). A conferência de entendimento sobre isso errou duas vezes (F-054 §2 e §3), e a rodada 1 abriu com a demonstração num repositório de sonda: um pack apagado dois commits antes voltou inteiro num clone, com o objeto do LFS junto (F-056 §1). O git não esquece.

Na mesma rodada, o Arthur disse o que quer do jogo: "eu deixo o repo publico, como falei, nao quero ganhar dinheiro em cima disso" (F-058 §1) e "eu quero deixar o jogo aberto, eu quero que outras pessoas no futuro possam contribuir pra, PRs, merges, correção de bugs, melhorias [...] Não quero lucrar nada em cima [...] Eu quero, tipo, tentar tudo ao máximo gratuito [...] Eu vou ser o mantenedor principal ainda" (F-058 §2). E delegou: "Me explica melhor aí. Enfim. Ou já toma as decisões baseadas nisso que eu já falei" (F-058 §2). Sob essa delegação, o Claude tirou a exceção da EULA e marcou a abertura do repositório para o Desenho 6, junto com a licença do código (Q-04).

## Opções consideradas

1. **EULA só em repositório privado para sempre** (a escolha 3 do Ready, F-054 §4): mantém Synty, Mixamo e Sonniss disponíveis, mas tranca o repositório ou obriga a reescrever o histórico e os objetos do LFS antes de abrir (F-050 §1.6, item 4; F-056 §1). Caiu quando o jogo virou aberto (F-058).
2. **Só licença que deixa redistribuir e modificar:** a escolhida. Um repositório público entrega cada arquivo a quem clona; só entra o que pode ser entregue.
3. **Comprar packs:** o Arthur não quer ("Po, eu preciso comprar mesmo? nao tem nada gratis nao que da pra usar?", F-058 §1). Nada se compra. As versões pagas de Kenney, Quaternius e KayKit continuam CC0 (F-050 §1.1 a §1.3), então, se um dia ele quiser, a licença não é o problema.
4. **Isolar os assets de EULA numa pasta própria**, para saber o custo de abrir (F-050 §1.6, item 4): sem EULA, não precisa.

## Decisão

### 1. As licenças

| Família | Entra? | Por quê |
|---|---|---|
| CC0 1.0 | Sim, primeiro | O autor abre mão de tudo; uso comercial, modificação e redistribuição livres, sem crédito (F-050 §1.1 a §1.4) |
| CC BY 3.0 e 4.0 | Sim, com crédito | A CC BY 4.0 exige identificar o autor, o aviso de copyright, a licença com link, o aviso de isenção de garantia, o link do material e "indicate if You modified", "in any reasonable manner" (F-050 §1.6) |
| OFL 1.1 | Sim, para fontes | Embutir leva o copyright e a licença em cada cópia; a fonte não se vende sozinha; versão modificada não usa o Reserved Font Name, e subset conta como modificação (F-050 §1.3; §3 C09) |
| MIT, Apache 2.0, ISC | Sim, para ícones e código | Levar o aviso de copyright e a licença; a Apache leva também o NOTICE (F-050 §1.2) |
| CC BY-SA | Só com o ok do Arthur | Cláusula contra DRM e efeito viral (F-050 §1.6, item 3; §1.8) |
| NC, ND | Não | NC fecha a porta de doação ou loja; ND impede ajustar escala, cor e material (F-050 §1.6, item 3) |
| Editorial, só-Unreal, uso pessoal, RemArc | Não | Proíbem uso comercial, prendem a uma engine ou a um uso (F-050 §1.6, item 3; §1.7) |
| EULA e "não redistribua" (Synty, Mixamo, Sonniss GDC, Fab Standard, ZapSplat) | Não, pago ou grátis | Um asset assim obriga o repositório a ficar privado para sempre, porque o git guarda cada commit e cada objeto do LFS (F-050 §1.6, item 4; F-056 §1), e o repositório abre no Desenho 6 (F-058) |
| Qualquer coisa com "GunZ" ou "MAIET", ou ripada de jogo | Não | Nada do GunZ entra no jogo (F-001; F-050 §1.6, item 5) |

### 2. As fontes conferidas na origem

Cada fonte com a licença lida na página em 07/10/2026, a frase que permite o uso como a fonte traz, e o que ela proíbe ou exige.

| Fonte | Licença, versão ou data | Link | A frase que permite | O que proíbe ou exige |
|---|---|---|---|---|
| Kenney | CC0 1.0 | https://kenney.nl/support | "Yes, all game assets on the asset pages are public domain licensed (CC0). [...] You're free to use them, even in commercial projects. [...] Attribution is not required" (F-050 §3 C01) | O logo da Kenney: "Do not use our logo" (F-050 §1.1) |
| Quaternius | CC0 1.0 | https://quaternius.com/faq.html | "All models are under the CC0 License. [...] these assets can be used for free without the need for attribution in commercial, educational, and personal projects." (F-050 §3 C02) | Nada |
| Quaternius, Universal Animation Library 2 Standard | CC0 1.0; zip de 10.257.419 bytes, sha256 `ec0e40d6…`, baixado em 07/10/2026 | https://opengameart.org/content/universal-animation-library-2 | O `License.txt` do zip: "License: CC0 1.0 Universal (CC0 1.0) Public Domain Dedication https://creativecommons.org/publicdomain/zero/1.0/ ... Models by @Quaternius" (F-056 §2) | Nada |
| Quaternius, Universal Animation Library 1, v2.0 (2026-01-23) | CC0 1.0; o `License.txt` do zip diz "CC0 1.0 Universal" | https://quaternius.itch.io/universal-animation-library | A página do itch e o `License.txt` (F-052 §2.1) | Nada. Baixar do itch, não do OpenGameArt, cujo zip de 2025 tem o rig antigo (F-052 §2.1) |
| KayKit (Kay Lousberg) | CC0 1.0 | https://kaylousberg.itch.io/kaykit-adventurers | "Free for personal and commercial use, no attribution required. (CC0 Licensed)" (F-050 §3 C03) | Pede, sem força de licença, "please don't resell unmodified copies or claim them as your own" (F-050 §3 C03). O Character Animations é CC0, em FBX e GLTF (F-050 §1.3) |
| Poly Haven | CC0 | https://polyhaven.com/license | "You can use our assets for any purpose, including commercial work. [...] You can redistribute them, share them around, include them when sharing your own work, or even in a product you sell." (F-050 §3 C04) | Nada |
| Google Fonts | OFL 1.1 na maioria; Apache 2.0 em algumas; Ubuntu UFL nas Ubuntu, pela pasta `ofl/`, `apache/` ou `ufl/` | https://openfontlicense.org/open-font-license-official-text/ | "Original or Modified Versions of the Font Software may be bundled, redistributed and/or sold with any software, provided that each copy contains the above copyright notice and this license." (F-050 §3 C09) | "may be sold by itself" é proibido; versão modificada não usa o Reserved Font Name; subset é modificação (F-050 §1.3) |
| game-icons.net | CC BY 3.0 | https://game-icons.net/about.html | O crédito por autor: "Icons made by {author}. Available on https://game-icons.net" (F-050 §1.2) | Exige o crédito por autor |
| Lucide | ISC; MIT nos ícones vindos do Feather | https://lucide.dev/license | Levar o aviso de copyright e a licença "in all copies" (F-050 §1.2) | Exige o aviso e a licença |
| Material Symbols | Apache 2.0 | https://developers.google.com/fonts/docs/material_symbols | A licença Apache 2.0 (F-050 §1.2) | Levar a cópia da licença e o NOTICE, se houver (Apache 2.0 §4; F-050 §1.2) |
| Freesound | Som a som: CC0, CC BY 4.0 ou CC BY-NC 4.0 | https://freesound.org/help/faq/ | "freesound lets the user select one of three licenses for their sounds" (F-050 §3 C07) | Só entram os CC0 e os CC BY; os NC não |
| OpenGameArt | Por asset: CC0, CC BY, CC BY-SA, GPL, OGA-BY | https://opengameart.org/content/faq | O crédito sugerido: "[asset name] by [author name] licensed [license(s)]: [asset url]" (F-050 §1.8) | Só entram os CC0 e os CC BY; BY-SA só com o ok do Arthur |

### 3. A pasta e a linha

- Todo asset de terceiros mora em `assets/third_party/<fonte>/<pack>/`, com os nomes em snake_case (F-051 §1.9), e o arquivo de licença dentro da pasta do pack, com o nome com que veio (`LICENSE.txt`, `License.txt`, `OFL.txt`, `COPYING`). Para fontes, o `OFL.txt` ao lado do `.ttf` (F-050 §1.3).
- Cada pack tem uma linha no `assets/CREDITS.md`, com o caminho `assets/third_party/<fonte>/<pack>` sem barra final e as colunas: pack e caminho, autor, licença com versão e link, URL de origem, data do download, se foi modificado e o quê, onde é usado, e o arquivo de licença. A CC BY leva o texto exato do crédito que vai na tela de créditos do jogo (F-050 §1.6).
- A linha entra no mesmo commit que o asset.

### 4. A checagem no portão

- "Asset sem linha não entra" é um passo do portão (`tools/check_assets.sh`), com canários como os da pureza (DEC-0027): um pack sem linha ou sem o arquivo de licença derruba o portão, com o nome do pack; um arquivo solto fora de um pack também.
- O mesmo passo prova o LFS pelo próprio git (`git check-attr`): cada formato da lista vai para o LFS, e os formatos de texto ficam de fora.

### 5. A cota do LFS e os formatos

- O plano Free dá 10 GiB guardados e 10 GiB de banda por mês, por conta, com arquivos de até 2 GB; cada versão enviada conta o arquivo inteiro; o CI gasta banda ao baixar; sem cartão, o orçamento é zero e o LFS trava até o mês seguinte (F-050 §1.5; §3 C10 a C12).
- Vão para o LFS: modelos (`.glb`, `.gltf`, `.bin`, `.fbx`, `.obj`, `.dae`, `.blend`), imagens (`.png`, `.jpg`, `.jpeg`, `.webp`, `.tga`, `.exr`, `.hdr`, `.dds`, `.ktx2`, `.psd`, `.kra`), áudio (`.wav`, `.ogg`, `.mp3`, `.flac`), fontes (`.ttf`, `.otf`, `.woff`, `.woff2`) e vídeo (`.mp4`, `.webm`). Ficam fora, porque são texto e o diff importa: `.svg`, `.tres`, `.tscn`, `.import`, `.csv`, `.po`. Os `.res` e `.scn` binários não se usam. A lista completa, com o porquê, está em `docs/design/visual-e-audio.md`.
- Nenhum asset de origem pesado (`.blend`, `.psd`, `.kra`) entra por enquanto; se entrar, fica numa pasta com `.gdignore`, no LFS (F-051 §1.9).

### 6. O repositório abre no Desenho 6

Com a licença do código (Q-04; F-058). Até lá segue privado, mas nada que entra hoje precisaria sair para abrir.

## Consequências

- O `assets/CREDITS.md` ganha a política e as colunas; a tabela segue vazia até o primeiro pack.
- O `tools/gate.sh` ganha o passo "Assets and LFS"; o `.gitattributes` ganha os formatos que faltavam (`.gltf`, `.bin`, `.obj`, `.dae`, `.tga`, `.dds`, `.ktx2`, `.flac`, `.woff`, `.woff2`), que hoje iriam para o git comum (F-050 §1.5).
- O `AGENTS.md` ganha a convenção da pasta e o passo do portão.
- A tela de créditos do jogo lista as fontes CC BY e OFL com o texto que a linha do `CREDITS.md` guarda; nasce com a primeira interface.
- O Desenho 6 (TASK-8) escolhe a licença do código e abre o repositório.
- Mixamo, Synty e Sonniss ficam fora para sempre, mesmo em privado.

## Revisitar se

- O Arthur quiser comprar um pack: só se a versão paga continuar CC0 ou CC BY, como as de Kenney, Quaternius e KayKit (F-050 §1.1 a §1.3).
- Um asset necessário só existir sob NC ou EULA: o caminho é fazer à mão ou achar outro, não abrir exceção.
- O armazenamento ou a banda do LFS chegarem perto dos 10 GiB.
- O repositório for aberto antes do Desenho 6.
