---
revisado_em: 2026-10-08
fontes: [F-050, F-051, F-052, F-053, F-054, F-056, F-058, F-059, F-061, F-062, F-063]
---

# Visual e áudio

Estado atual: a base decidida no Desenho 5 (TASK-7; DEC-0029, DEC-0030 e DEC-0031). Nenhuma arte final existe: a arena é de blocos e o lutador é a cápsula até o movimento ser divertido (DEC-0030 §7). O que está aqui é como a arte entra, de onde vem, como o golpe se lê e qual é a base da interface. Cada número traz a fonte; os números v0 são do Claude (DEC-0017) e o Arthur julga jogando.

## A política de assets (DEC-0029)

### As licenças aceitas e recusadas

| Entra | Com o quê | Fonte |
|---|---|---|
| CC0 1.0, primeiro | Nada; registra-se a origem mesmo assim | F-050 §1.1 a §1.4 |
| CC BY 3.0 e 4.0 | O crédito com autor, copyright, licença com link, isenção de garantia, link do material e "modificado" | F-050 §6 |
| OFL 1.1, para fontes | O copyright e a licença em cada cópia; sem vender a fonte sozinha; sem o Reserved Font Name em versão modificada ou subset | F-050 §3 |
| MIT, Apache 2.0 e ISC, para ícones e código | O aviso e a licença; o NOTICE na Apache | F-050 §2 |
| CC BY-SA | Só com o ok do Arthur | F-050 §6 |

Fica fora, pago ou grátis: NC, ND, Editorial, só-Unreal, uso pessoal, RemArc, EULA e "não redistribua" (Synty, Mixamo, Sonniss GDC, Fab Standard, ZapSplat), e qualquer coisa com "GunZ" ou "MAIET" (F-050 §6; F-001). Nada se compra (F-058).

### A linha do `CREDITS.md` por tipo

Toda linha: pack e caminho, autor, licença com versão e link, URL de origem, data do download, modificado (o quê), onde é usado, arquivo de licença (F-050 §1.6).

| Tipo | A mais |
|---|---|
| CC0 | Nada; a linha é prova de proveniência |
| CC BY | O texto exato do crédito que vai na tela de créditos do jogo, e a marcação "modificado" |
| OFL | O nome da fonte e o `OFL.txt` ao lado do `.ttf` |
| Apache | O `NOTICE`, se houver |

### O arquivo de licença ao lado do pack

`assets/third_party/<fonte>/<pack>/`, em snake_case, com a licença dentro, com o nome com que veio: `LICENSE.txt`, `License.txt`, `OFL.txt`, `COPYING` (DEC-0029 §3). O UAL2, por exemplo, traz `License.txt` (F-056 §2). O portão derruba o pack sem o arquivo ou sem a linha (DEC-0029 §4).

### A regra do repositório privado para EULA

Um asset com EULA ou "não redistribua" obrigaria o repositório a ficar privado para sempre, ou o histórico a ser reescrito antes de abrir, porque o git guarda cada commit e cada objeto do LFS: na sonda, um pack apagado dois commits antes voltou inteiro num clone (F-056 §1; F-050 §6). O repositório abre no Desenho 6 (F-058; Q-04). Por isso nenhum asset assim entra, nem em privado (DEC-0029 §1).

### A conta da cota do LFS

| Número | Valor | Fonte |
|---|---|---|
| Armazenamento | 10 GiB por conta | F-050 §5; veredicto C10 |
| Banda | 10 GiB por mês; o CI gasta ao baixar | F-050 §5 |
| Arquivo | Até 2 GB | F-050, veredicto C11 |
| Orçamento sem cartão | Zero: estourou, o LFS trava até o mês seguinte | F-050, veredicto C12 |
| Excedente, se houver cartão | US$ 0,07 por GiB-mês guardado e US$ 0,0875 por GiB baixado | F-050, veredicto C12 |
| Cada versão enviada | Conta o arquivo inteiro | F-050 §5 |

Um exemplo, com os valores de partida da calculadora da vitrine (F-054, contexto), não uma medida: 300 MB de assets com 3 versões por mês somam 0,9 GiB guardados por mês; 20 rodadas do CI que baixam os assets somam 6 GiB de banda. Baixar os assets em toda rodada não cabe por muito tempo; o CI faz checkout com LFS hoje (`.github/workflows/ci.yml`), e a conta volta quando o primeiro pack entrar.

### A lista de formatos do LFS, e o que fica fora

| Vai para o LFS | Por quê |
|---|---|
| Modelos: `.glb`, `.gltf`, `.bin`, `.fbx`, `.obj`, `.dae`, `.blend` | Binários, ou texto grande sem diff útil; o `.gltf` traz o `.bin` ao lado |
| Imagens: `.png`, `.jpg`, `.jpeg`, `.webp`, `.tga`, `.exr`, `.hdr`, `.dds`, `.ktx2`, `.psd`, `.kra` | Binários |
| Áudio: `.wav`, `.ogg`, `.mp3`, `.flac` | Binários |
| Fontes: `.ttf`, `.otf`, `.woff`, `.woff2` | Binários |
| Vídeo: `.mp4`, `.webm` | Binários |

| Fica fora | Por quê |
|---|---|
| `.svg` | Texto; o diff de um ícone importa, e é pequeno |
| `.tres`, `.tscn`, `.import`, `.gd` | Texto do Godot; o diff é a revisão (F-051 §1.7) |
| `.csv`, `.po` | Texto das traduções (F-051 §3.5) |
| `.res`, `.scn` | Binários do Godot: não se usam; só os de texto |
| `.blend`, `.psd`, `.kra` | Estão na lista do LFS, mas não entram no projeto; se um arquivo de origem entrar um dia, fica numa pasta com `.gdignore` (F-051 §1.9; DEC-0030 §1) |

O portão prova a lista pelo próprio git (`git check-attr`) a cada rodada (DEC-0029 §4).

## O pipeline de import (DEC-0030)

| O quê | Como | Fonte |
|---|---|---|
| Formato | glTF 2.0 binário (`.glb`); FBX só sem glTF, medindo a altura depois; `.blend` fora | F-051 §1.1 |
| Escala | 1 unidade = 1 m; o lutador com 1,8 m pela escala de import (`nodes/root_scale`, com `apply_root_scale`); o UAL2 ficou em 1,800 m com `0,98414` | F-051 §1.2; F-056 §3 |
| Nomes | `-col` e `-colonly` para a colisão dos mapas; `-noimp` para luzes e câmeras de apoio; `loop` no nome do clipe | F-051 §1.3 |
| Animação | O import tira o `_Loop` e marca o laço; cada clipe cai de 195 para 57 trilhas | F-056 §3 |
| Texturas | Detect 3D nos materiais 3D: mipmaps e compressão de vídeo, S3TC no Compatibility; ícones e HUD em Lossless | F-051 §1.8 |
| O que vai para o git | O `.import` ao lado de cada asset; a `.godot/` e os `.translation` não | F-051 §1.7 |
| Pastas e arquivos | snake_case, porque o pacote do jogo diferencia maiúsculas e o Windows não | F-051 §1.9 |
| O import de um pack | 5,8 s para os dois `.glb` do UAL2, sem tela | F-056 §3 |

## O caminho da animação (DEC-0030)

- **As fontes:** a base CC0 com um rig só, o UAL1 v2.0 do itch e o UAL2; o KayKit para arco, pistola e mosquete depois de um teste de retarget; os 15 a 18 clipes de identidade à mão, com a ferramenta escolhida na fase 1 (F-052 §2.1, §2.2, §7.5 e §8).
- **O rig:** o do UAL2, 65 ossos com nomes no padrão do Unreal; o manequim feminino tem o mesmo esqueleto (F-056 §3). Retarget só para juntar fontes, com o `BoneMap` e o perfil humanoide (F-051 §1.5).
- **A pose como função do estado:** a cada quadro, qual clipe e em que ponto, a partir do modo, do tick de início e do tick atual; o mixer em modo manual; sem máquina de estados no AnimationTree; os clipes in place, nunca root motion para mover (DEC-0022 §3; F-051 §1.6; F-052 §6). Posar 16 lutadores custou 0,7 ms por quadro na sonda (F-056 §5).
- **As marcas e o tempo:** o ativo marcado à mão em cada clipe de golpe (no `Sword_Regular_A`, de 46% a 69%); todo clipe reajustado fase a fase pelo estado, porque nenhum tem os nossos tempos (F-056 §4; F-052 §6.2).
- **Os buracos:** cerca de 22 clipes de movimento, 25 de espada v0, 22 de arco e armas e 8 a 12 transições, de 77 a 150 no total; faltam em qualquer fonte grátis a corrida na parede, o pulo da parede, o gancho, o virar parado, o carregado em fases, o parry, a finta, o atordoado, a troca de arma e a recarga do mosquete (F-052 §7).

## O orçamento de vértices e o quadro (DEC-0030)

Medido na sonda da rodada 1, em 1080p, no PC do piso, com 16 lutadores animados, toon, contorno e sombra (F-056 §5 e §6):

| O quê | Custo com 16 lutadores | Valor v0 |
|---|---|---|
| 16 manequins de 8.546 vértices | 127 a 129 fps; 105 nos 1% piores | O orçamento é 10 mil vértices por lutador, com a arma: uns 9,4 ms pela reta entre os dois pontos medidos |
| 16 manequins de 25.636 vértices | 37 fps | Fora do orçamento |
| Sombra | Cerca de 2,6 ms | Ligada: mostra a altura de quem está no ar |
| MSAA 4x | Cerca de 1,5 ms | 2x, cerca de 0,8 ms, no `project.godot` |
| Contorno | Cerca de 1,1 ms | Ligado, 1,2 cm; sai de quem está longe se o quadro apertar, nunca de vez (F-059) |
| Posar os 16 | Cerca de 0,7 ms | A função pose = f(estado) |

A sonda não tem rede, física, efeitos, interface nem arena; o jogo de verdade pesa mais (F-056 §6). A confirmação vem no 4v4 e no 8v8 (DEC-0004, regra 6; Q-22).

## Os tokens do combate (DEC-0031)

### Os três canais por estado

| Estado | Cor | Pose | Som |
|---|---|---|---|
| Leve, preparação (300 ms) | Nenhuma: é o padrão | A lâmina vai para trás | "Whoosh" curto |
| Carregado, preparação (500 a 900 ms) | Azul celeste `#56B4E9` na lâmina e na aura, desde o tick 0 | A espada acima da cabeça desde o tick 0 | Som longo, subindo |
| Ativo | Vermelhão `#D55E00` na lâmina e no rastro | O arco da lâmina | "Swish" |
| Parry, janela (80 ms) e acerto | Amarelo `#F0E442` na lâmina e na aura; flash e faíscas no acerto | A lâmina cruzada à frente | Um toque; o "clang" no acerto, o mais forte |
| Quebra de guarda, preparação (350 ms) | A mão em vermelhão desde o tick 0 (hipótese, F-063 §4) | A espada baixa, a mão à frente, o contorno pulsando | Um pisão |
| Finta, o corte (300 a 450 ms) | Nenhuma | A pose volta num estalo | Um estalo seco |
| Arma de longe carregada | Roxo-avermelhado `#CC79A7`, a conferir sob deuteranopia | A puxada | A puxada ouvida pelo alvo, com direção |
| Bloqueio (100 ms para subir) | Nenhuma | A lâmina vertical à frente | Um som baixo ao subir; "tunk" no impacto |
| Reação | Um flash branco | O corpo recua | "Thud" |

Os tempos são do `combate.md`; as cores, da Okabe-Ito (F-053 §3.6); as poses e os sons, os da sonda (F-061 §1). Por que o leve não tem cor: ninguém reage a 300 ms com os 100 ms do bloqueio, então ele se defende por leitura ou distância, e a cor marca a exceção que exige outra resposta (F-053 §2.4; For Honor e Naraka, F-053 §1).

### Onde o sinal mora

No mundo: a pose, o rastro e o brilho na arma. O HUD repete com forma e cor, e cobre o que está fora da tela (F-053 §5). Nunca só por cor (F-053 §2.2).

### A paleta

O eixo azul–amarelo e o claro–escuro da Okabe-Ito; nenhum verde; laranja nunca junto do vermelhão ou do amarelo; 3:1 contra o fundo (F-053 §3.3, §3.4 e §3.6). Sob deuteranopia, o par vermelho × verde vira dois tons de oliva, e os tokens seguem separados pelo brilho; o roxo "de longe" chega perto do cinza do leve, a conferir no arco (F-061 §4). A cor de time é o contorno e o anel, nunca uma cor de token; o anel do 2 em 1 usa forma (F-053 §6).

### O som com prioridade

O bus "leitura", com um player por som, nunca cortado pelo limite de vozes (o Godot corta o mais antigo, sem prioridade, F-051 §5.1), e um compressor em sidechain que abaixa música e ambiente em uns 12 dB (v0; a sonda abaixou 33 a 39 dB, demais, F-061 §4). WAV mono com Trim para golpes e passos, Ogg para música; Doppler desligado (F-051 §5.3 e §5.1).

### A chave do evento

Som e efeito tocam uma vez por evento, pela chave (nó, tipo, id), quando o evento aparece pela primeira vez no estado exibido; nunca na re-simulação; e nunca se desfazem (DEC-0031 §6; F-061 §2). O `is_fresh` do netfox cobre só o nó que o PC simula: na sonda a ping 120, ele veria de um terço a metade dos eventos. O atraso de visão vem do tick que o próprio estado carrega (DEC-0031 §7).

### O que a sonda mediu e o que o Arthur leu

| Medida | Valor | Fonte |
|---|---|---|
| SyncTest com rollback forçado: eventos apresentados, `is_fresh`, ingênuos | 42, 42, 168, com zero divergência em 10.752 conferências | F-061 §2 |
| Cliente a ping 120, 36 s: apresentados, `is_fresh`, ingênuos | 42 a 56, 18 a 24, 98 a 113 | F-061 §2 |
| O bot leitor de 200 ms a ping 120: carregado, quebra, finta, leve | 8 de 8, 13 de 16, 12 de 12, 5 de 12 | F-061 §3 |
| O Arthur, 4 jogos: a cor do carregado | Lida: F em meio segundo, 29 de 29 no primeiro par de jogos | F-062 §3 |
| O tempo do parry no carregado de carga sorteada | 1 em 29, depois 0 em 21: o F de 200 a 770 ms cedo | F-062 §3; F-063 §2 |
| O parry no leve, de preparação fixa | 3 e 3, com margem de 0 a 33 ms | F-062 §2; F-063 §2 |
| A forma da quebra, depois com a mão vermelha | F em vez de esquiva; esquiva a tempo 1 de 27 e 2 de 22 | F-062 §3; F-063 §2 |
| A ping 14 contra a ping 119 | O mesmo padrão: não é o lag | F-063 §3 |

## A base da interface e a acessibilidade mínima (DEC-0031)

| O quê | Como | Fonte |
|---|---|---|
| O Theme | Um só, em `gui/theme/custom`, criado com a primeira cena de interface; tipos como seletores, itens como propriedades, variações como classes | F-051 §3.1 e §3.2 |
| A base | 1920 × 1080 com `canvas_items` e `expand`, guardada no teste de configurações; hoje valia 1152 × 648 | F-051 §3.3; F-054 §2 |
| A escala | `content_scale_factor` nas opções, de 0,8 a 1,5 (v0) | F-051 §4.4 |
| As teclas | Posição física, remapeáveis desde o primeiro dia, salvas em `user://`, com o rótulo do teclado ativo | F-051 §4.2 e §4.3 |
| A cor | Nenhuma informação só por cor | F-053 §2.2 |
| Os menus | Nomes de acessibilidade; o leitor de tela na partida fica fora do v0 | F-051 §4.1 |
| As traduções | Chaves por ID, com pt-BR e en | F-051 §3.5 |
| O HUD | Barras e números leem o estado, nunca um timer | F-051 §3.4 |

## Em aberto

- Q-21: a janela do parry e a carga variável do carregado.
- Q-25: a quebra de guarda por escolha.
- O roxo da arma de longe sob deuteranopia; o som lido com fone; a pose com o boneco (F-063 §3).
- Q-09: o jitter da entrega, que a sonda viu e o simulador do netfox não tem (F-061 §3).
- Q-13: a explicação da acrobacia no mundo do jogo, para a fase 1.
