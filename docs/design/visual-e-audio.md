---
revisado_em: 2026-10-26
fontes: [F-050, F-051, F-052, F-053, F-054, F-056, F-058, F-059, F-061, F-062, F-063, F-100, F-121, F-122, F-137, F-139, F-140, F-141, F-146, F-147, F-148, F-152, F-153, F-156, F-157, F-158]
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

Toda linha: pack e caminho, autor, licença com versão e link, URL de origem, data do download, modificado (o quê), onde é usado, arquivo de licença (F-050 §6).

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
| O Theme | Um só, em `gui/theme/custom`, criado com a primeira cena de interface, o HUD: `ui/theme/game_theme.tres`; tipos como seletores, itens como propriedades, variações como classes | F-051 §3.1 e §3.2; F-100 §1; TASK-10.2 |
| A base | 1920 × 1080 com `canvas_items` e `expand`, guardada no teste de configurações; hoje valia 1152 × 648 | F-051 §3.3; F-054 §2 |
| A escala | `content_scale_factor` nas opções, de 0,8 a 1,5 (v0) | F-051 §4.4 |
| As teclas | Posição física, remapeáveis desde o primeiro dia, salvas em `user://`, com o rótulo do teclado ativo | F-051 §4.2 e §4.3 |
| A cor | Nenhuma informação só por cor | F-053 §2.2 |
| Os menus | Nomes de acessibilidade; o leitor de tela na partida fica fora do v0 | F-051 §4.1 |
| As traduções | Chaves por ID, com pt-BR e en | F-051 §3.5 |
| O HUD | Barras e números leem o estado, nunca um timer | F-051 §3.4 |

### O HUD da stamina (TASK-10.2)

Leitura v0 do Claude, que o Arthur julga jogando (DEC-0017; TASK-10.2).

- **A barra:** 300 × 12 px na base de 1080p, no canto inferior esquerdo. O papel não tem pixel; a medida é a da tela (TASK-10.2).
- **O número:** ao lado da barra, em pontos inteiros, arredondado para baixo. O modo vem acima, em texto: "No chão" ou "No ar" (TASK-10.2).
- **O traço:** abaixo do custo do pulo duplo, 10 pontos, o número ganha um traço de 2 px embaixo. É forma, não cor (DEC-0031 §2; `movimento.md`, "Pulo e ar").
- **De onde vem:** a barra se calcula do estado exibido a cada quadro, pelo valor e pelo carimbo da stamina. Nenhum timer, nenhum contador (F-051 §3.4; `movimento.md`, "Stamina").
- **Quem tem:** só o PC com tela; o servidor dedicado nunca cria o HUD (`arquitetura/visao-geral.md`, "As cenas").

### O Theme, o lugar das fontes (TASK-10.2)

- O Theme único, `ui/theme/game_theme.tres`, guarda a fonte, os tamanhos e as cores de toda a tela. Nenhuma cena de interface carrega fonte ou cor própria; um teste confere (DEC-0031 §8).
- A fonte é a padrão do Godot, em 16 px na base de 1080p, o tamanho que os textos da TASK-9 já tinham. O texto ganha um contorno escuro de 4 px, para se ler sobre os blocos claros. A margem do canto é de 24 px. Leitura v0 do Claude (DEC-0017; TASK-10.2).
- As cores do HUD são branco e preto: a barra cheia em branco sobre um fundo preto translúcido. Nenhuma cor de token (DEC-0031 §1 e §3).
- Cada texto da tela é uma chave de tradução, com pt-BR e en. Um teste reprova a chave sem mensagem num dos dois idiomas (DEC-0031 §8).

### Toda manobra nasce com o seu sinal (F-139)

Decisão do Arthur, depois de jogar a parede ajustada: "Ter um feedback visual de tudo" (F-137; F-139).

- **A regra:** toda manobra nova entra no jogo já com um sinal visual que mostra que ela aconteceu e em que fase está: o rastro e a baforada (TASK-10.4), a marca, a inclinação e o rastro da parede (TASK-10.5; TASK-10.10). Uma manobra sem sinal não está pronta.
- **No plano de cada task de manobra:** o sinal é um critério de aceite, com os números v0 do Claude escritos aqui antes do código (DEC-0017).
- **Como os outros sinais:** só na tela, fora do estado, uma vez por chave e nunca na re-simulação (DEC-0031 §6); no tom neutro do lutador e sem ativo novo enquanto não houver arte (DEC-0029).
- **O som** segue a Q-32: entra quando houver um pacote com licença.

### O dash na tela (TASK-10.4)

Leituras v0 do Claude, que o Arthur julga jogando (DEC-0017; TASK-10.4).

- **A tecla:** o dash é o Shift esquerdo, por posição física; o Shift direito não faz nada. O toque duplo na direção, como no GunZ, fica para depois, se o Arthur pedir (F-121; `project.godot`, `[input]`).
- **O modo:** o HUD diz "No dash" ("Dashing" em inglês) nos 200 ms do dash, além de "No chão" e "No ar" (TASK-10.4).
- **O arco da recarga:** acima do modo, um anel de 24 × 24 px na base de 1080p, com 4 px de espessura: o arco branco sobre o anel preto translúcido, as cores e a espessura do Theme (`DashCooldownArc`). Ele começa cheio no tick do dash e esvazia, no sentido horário a partir do topo, até o próximo poder sair: 600 ms, os 200 do dash mais os 400 da recarga (`movimento.md`, "Dash"). Ao lado, os décimos de segundo que faltam, arredondados para cima, para nunca dizer 0 enquanto espera: de "0,6 s" a "0,1 s", com a vírgula em pt-BR e o ponto em en, pela chave `HUD_DASH_COOLDOWN`. Com o dash livre, os dois somem, e a linha guarda a altura, para o resto não pular. Tudo se calcula do `dash_tick` e do tick, sem timer (F-051 §3.4).
- **Os sinais das manobras:** só visuais no v0; o som espera um pacote com licença (DEC-0029; Q-32).
  - **O rastro do dash:** a caixa do espaço que a cápsula varreu, da largura do diâmetro e da altura da cápsula, do ponto em que o dash apareceu até o corpo. Ela segue o corpo enquanto o dash dura e some em 200 ms, a duração do próprio dash.
  - **A baforada do pulo duplo:** um disco fino sob os pés, onde o pulo duplo saiu, que cresce do raio da cápsula até 3 raios e some na subida do pulo, 350 ms.
  - Os dois são translúcidos, a 40 %, sem luz, e usam o tom neutro do próprio lutador: o cinza claro de quem joga, o escuro do outro. Nenhum usa cor de token, nem o branco do flash da reação (DEC-0031 §1 e §3).
  - Tocam uma vez por chave (lutador, tipo, carimbo), quando aparecem pela primeira vez no estado exibido, e nunca na re-simulação (DEC-0031 §6). Sem tela, como no servidor dedicado e no portão, contam e não desenham.
- **A régua do dash:** faixas de 0,1 × 0,01 × 2 m a cada 4 m, a distância do dash, em x de −10 a 30 e em z de 14 a 16, ao sul dos pontos de nascimento, no cinza dos blocos. São só malha, sem colisão, e ficam fora do percurso da referência e das cenas da SyncTest (TASK-10.4).

### A parede na tela (TASK-10.5)

Leituras v0 do Claude, que o Arthur julga jogando (DEC-0017; TASK-10.5).

- **O modo:** o HUD diz "Na parede" ("Wall running" em inglês) da entrada ao fim da corrida, pela chave `HUD_MODE_WALL_RUN`, além de "No chão", "No ar" e "No dash".
- **A marca do pulo da parede:** a baforada do pulo duplo em pé contra a parede. Um disco fino com o eixo na normal da parede, na altura do meio do corpo, onde o lutador estava ao pular, que cresce do raio da cápsula até 3 raios e some na subida do pulo, 350 ms. Translúcido a 40 %, sem luz, no tom neutro do próprio lutador, como os outros sinais; toca uma vez por chave, pelo `wall_jump_tick`, durante o voo que o pulo começou, e nunca na re-simulação (DEC-0031 §6).
- **A inclinação da cápsula (TASK-10.10):** na corrida, a malha da cápsula e a viseira inclinam 15° para longe da parede, com o pivô nos pés, entrando em 100 ms na entrada e saindo em 100 ms no fim, de forma linear, a cada quadro exibido. Ao sair, ela volta inclinando para longe da parede que deixou. Só na tela: o estado, o corpo e a cápsula de colisão não mudam, e o rollback, o replay e a SyncTest não a veem (`movimento.md`, "O que se vê na parede"; DEC-0031 §6; Q-37).
- **O rastro da corrida (TASK-10.10):** o rastro do dash, curto. A mesma caixa translúcida no tom do lutador, mas só do ponto em que o corpo estava há 200 ms, a duração do dash, até o corpo: uns 1,6 m a 8 m/s, que acompanham a corrida em vez de desenhar a parede inteira. O comprimento conta os ticks do netfox, não o tempo do quadro, para ser o mesmo em qualquer fps. Some em 200 ms depois do fim da corrida. Toca uma vez por chave, pelo tick em que a corrida começou, então uma emenda continua o mesmo rastro, e o rollback não o duplica. "Curto" sem número no papel: a duração do dash é a leitura v0 do Claude (DEC-0017), e nenhum ativo novo entra (DEC-0029).
- **A câmera** não inclina na corrida no v0 (`movimento.md`, "Corrida na parede").
- **As peças da arena:** a `ParedeLonga`, o `CorredorOeste`, o `CorredorLeste` e o `PatamarDoCorredor` usam o cinza dos blocos, sem cor nova (`movimento.md`, "Métricas de nível").

### O gancho na tela (TASK-10.6)

Leituras v0 do Claude, que o Arthur julga jogando (DEC-0017; F-141). O sinal nasce com a manobra (F-139).

- **A tecla:** o gancho é o Q, por posição física (F-140 §1; DEC-0031 §8).
- **A mira:** um anel de 24 × 24 px na base de 1080p, no centro da tela, com 2 px de traço, branco com contorno escuro translúcido, as cores do HUD. Ele ganha um ponto de 5 px no centro quando o Q prenderia agora: um raio só da tela acha cenário de 3 a 25 m, e o gancho está livre, fora do dash, sem outro gancho no ar e fora da recarga. É forma, não cor (DEC-0031 §2). O raio da mira sai do ponto O exibido, os pés exibidos mais 1,6 m para cima e 0,8 m para a direita do yaw da câmera, pela câmera, a cada quadro, e nunca entra no estado (`movimento.md`, "Gancho"; DEC-0045). O anel fica onde esse raio se projeta na tela: o centro, com a câmera livre; quando uma parede empurra a câmera, para trás ou pelo ombro, o anel acompanha o raio, para nunca mentir (TASK-10.11). As cores e o traço vêm da classe `Reticle` do Theme, e o ponto lê as mesmas regras do núcleo que a simulação (`Movement.can_grapple` e `Movement.in_reach`) e o mesmo segundo raio da quina, então ele nunca promete um gancho que a regra recusa. No `--watch` de um replay, a câmera fica com o pitch em 0, e o ponto mostra a mira nivelada, não a gravada; o replay em si toca o pitch gravado.
- **O modo:** o HUD diz "No gancho" ("Grappling" em inglês) durante a puxada, pela chave `HUD_MODE_GRAPPLE`. Com o cabo voando, o modo ainda é o de antes.
- **A recarga:** uma linha acima da do dash, com um anel igual ao dele, de 24 × 24 px e 4 px de espessura (a classe `GrappleCooldownArc` do Theme, com os valores da `DashCooldownArc`), e o texto "Gancho 5,9 s" ("Grapple 5.9 s"), em décimos arredondados para cima, pela chave `HUD_GRAPPLE_COOLDOWN`. O anel começa cheio na soltura e esvazia no sentido horário a partir do topo, em 6 s. Com o gancho livre, os dois somem, e a linha guarda a altura. Tudo se calcula do `grapple_end_tick` e do tick, sem timer (F-051 §3.4).
- **O cabo:** uma linha de 3 cm de espessura, opaca, sem luz, no tom neutro do próprio lutador, do ombro exibido (1,6 m acima dos pés) até a ponta. Nos 100 ms de voo, a ponta vai do ombro ao ponto, contando os ticks do netfox; na puxada, fica no ponto; na soltura, o cabo some. Toca uma vez por chave, pelo `grapple_fired_tick` (DEC-0031 §6).
- **A puxada:** o rastro curto da corrida na parede, a mesma caixa translúcida a 40 %, do ponto em que o corpo estava há 200 ms até ele, enquanto o modo é o gancho. Some em 200 ms depois da soltura. Toca uma vez por chave, pelo tick em que a puxada começou.
- **Nenhum ativo novo** entra: o anel, o ponto, a linha e a caixa são formas do Godot (DEC-0029). O som do cabo espera a Q-32.
- **As peças da arena:** a `TorreA`, a `TorreB` e o `Pilar10m` usam o cinza dos blocos, sem cor nova (`movimento.md`, "Métricas de nível").

### A cabeça do outro na tela (TASK-10.7)

Leituras v0 do Claude, que o Arthur julga jogando (DEC-0017; F-152). O sinal nasce com a regra (F-139).

- **O escorregão:** o rastro curto do dash, da parede e da puxada, a mesma caixa translúcida a 40 %, acompanha quem escorrega de uma cabeça, do ponto em que o corpo estava há 200 ms até ele. Some em 200 ms depois de ele sair. Toca uma vez por pouso, pelo tick em que o contato com a cabeça começou (DEC-0031 §6). Ele lê como "o jogo me empurrou", e não como um bug.
- **O modo:** o HUD diz "No ar" em cima de uma cabeça, porque para as regras é ar.
- **O boneco:** o segundo lutador do Sozinho, parado no `SpawnB`, usa o tom do outro lutador, o mais escuro, como um adversário.
- **A borda:** as quatro paredes de 50 m não fazem sombra (`movimento.md`, "Métricas de nível"); a cor delas está em "A cara da arena" (TASK-10.12).
- **Nenhum ativo novo** entra (DEC-0029).

### A cara da arena (TASK-10.12)

A cara "Dia claro", escolhida pelo Arthur na vitrine "A cara da arena" (F-158), no ajuste v0 do Claude: o sol um pouco mais quente, a luz do céu mais fraca, as peças num concreto neutro e a cápsula de quem joga em 0,86, para estourar menos (DEC-0017). Nenhum ativo novo: o céu procedural, a luz, a neblina e as cores dos materiais do próprio Godot (F-157; DEC-0029). O cenário fica em tons médios e pouco saturados, atrás dos sinais do combate (DEC-0031; "A paleta"). As cores são `Color` do Godot, de 0 a 1.

| O quê | Valor | Nota |
|---|---|---|
| Fundo | o céu procedural | Antes, uma cor chapada |
| Céu, topo | (0,12, 0,32, 0,72) | Azul de dia claro |
| Céu, horizonte | (0,62, 0,74, 0,88) | |
| Chão do céu, fundo | (0,14, 0,14, 0,15) | Neutro, para a luz de baixo não azular as sombras |
| Chão do céu, horizonte | (0,45, 0,47, 0,50) | |
| Disco do sol, ângulo máximo | 25° | |
| Luz ambiente | do céu, energia 0,4 | O céu pinta as sombras de azul; mais forte, a arena inteira azula |
| Tonemapping | Filmic, exposição 0,9 | Comprime as luzes fortes antes da tela; com 1,0, a cápsula estourava |
| Neblina | ligada, cor (0,66, 0,74, 0,86), densidade 0,0015, efeito no céu 0,15 | Leve: só dá profundidade à borda |
| Ajustes de cor | saturação 1,05, contraste 1,08 | |
| Sol | 50° de altura, 30° de giro (`rotation_degrees` = (−50, 30, 0)), cor (1,0, 0,95, 0,86), energia 1,5, com sombra | Branco um pouco quente |
| Chão | (0,18, 0,18, 0,19) | Asfalto neutro, mais escuro que tudo, menos o outro lutador |
| Peças: blocos, plataformas, rampa, paredes, corredor, patamar e a régua do dash | (0,56, 0,54, 0,50) | Concreto neutro, um pouco quente |
| Torres e pilar | (0,32, 0,36, 0,44) | Cinza-azulado: as peças altas se separam dos blocos |
| Borda | (0,13, 0,15, 0,19), sem sombra | Uma moldura escura, que não toma o quadro |
| Quem joga | (0,86, 0,86, 0,84) | Mais claro que toda superfície da arena (F-156 §3) |
| O outro, e o boneco | (0,11, 0,11, 0,13) | Mais escuro que toda superfície da arena |

- **O céu quase não aparece:** a borda de 50 m o esconde de quase todo ponto da arena. Ele ainda conta, porque é ele que pinta a luz ambiente.
- **Os 60 fps em 1080p** no PC do Arthur seguem valendo, medidos com o `tools/measure_fps.sh` (DEC-0002).

## Em aberto

- Q-21: a janela do parry e a carga variável do carregado.
- Q-25: a quebra de guarda por escolha.
- O roxo da arma de longe sob deuteranopia; o som lido com fone; a pose com o boneco (F-063 §3).
- Q-09: o jitter da entrega, que a sonda viu e o simulador do netfox não tem (F-061 §3).
- Q-13: a explicação da acrobacia no mundo do jogo, para a fase 1.
