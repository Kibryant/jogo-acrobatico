---
id: DEC-0031
titulo: Os tokens de leitura e a base da interface — três canais por estado com a cor na exceção, a chave do evento no lugar do tick novo, o atraso de visão pelo tick do estado, o bus "leitura", a cor de time pelo contorno, um Theme na base de 1920 × 1080, as teclas físicas e as chaves de tradução por ID
data: 2026-10-08
status: aceita
decidido_por: Arthur (F-054 §4, escolha 5; F-062; F-063), com os números v0 pelo Claude (DEC-0017)
fontes: [F-007, F-051, F-053, F-054, F-055, F-061, F-062, F-063, F-065]
substitui: DEC-0004, só a frase "Som e VFX só tocam em tick novo, nunca na re-simulação" da regra 2; DEC-0026, só a frase do §2 que dá o atraso de visão pelo `get_last_known_state()`
substituida_por:
---

# DEC-0031 — Os tokens de leitura e a base da interface: três canais por estado com a cor na exceção, a chave do evento no lugar do tick novo, o atraso de visão pelo tick do estado, o bus "leitura", a cor de time pelo contorno, um Theme na base de 1920 × 1080, as teclas físicas e as chaves de tradução por ID

## Contexto

O pilar 1 diz que o corpo não mente e que nada acontece escondido; a DEC-0014 pede antecipação proporcional ao dano e aviso visual e sonoro. A pesquisa do Desenho 5 mediu o limite do reagível: uma pessoa reage a um estímulo em 213 a 273 ms, e com escolha demora mais; o leve de 300 ms não se defende por reação, o carregado de 500 a 900 ms se defende se parecer diferente desde o tick 0; os jogos da tribo põem cor só no golpe que exige outra resposta (F-053 §1 e §2). Ela também trouxe a paleta da Okabe-Ito para o daltonismo, que atinge um em cada doze homens (F-053 §3), e o som como aviso mais rápido, que o Godot não prioriza sozinho (F-053 §4; F-051 §5.1).

O Arthur confirmou a escolha 5 do Ready: três canais por estado, a cor na exceção, a paleta provada na sonda, o sinal no mundo, o bus com prioridade, a cor de time separada, um Theme, a base de 1920 × 1080 com guarda, as teclas físicas remapeáveis, nunca só por cor, e as chaves de tradução por ID (F-054 §4). Ele perguntou pela base: "seria 1920 × 1080 a base da interface ne?" (F-054 §2).

A rodada 2 pôs tudo numa sonda a 60 ticks com lag simulado (F-061) e o Arthur jogou quatro vezes (F-062; F-063). Ele acertou a pergunta fixa: o leve é o padrão, e a cor marca a exceção (F-062, contexto). O que ele leu: a cor do carregado ("eu sabia o que ia defender", F-062 §1) e o ritmo do leve ("eu senti que ia sair e apertei", F-063 §1); o que não leu: o tempo do carregado de carga sorteada e a forma da quebra de guarda (F-062 §3; F-063 §3). "E acho que não é o lag não" (F-063 §1), e os logs concordam: a ping 14 e a ping 119 o padrão foi o mesmo. "Deu bom" (F-063 §1).

A sonda também mostrou que duas afirmações sobre o netfox escritas em DECs não valem: o "som só no tick novo" da DEC-0004 cobre um caso de três, e o `get_last_known_state()` da DEC-0026 §2 devolve zero para o oponente espelhado (F-061 §2). Esta DEC as substitui, e registra a reconferência das outras.

## Opções consideradas

1. **Cor em todo golpe** ou **cor só na exceção:** For Honor e Naraka põem cor no golpe que muda a regra; o Chivalry 2 não põe em nada (F-053 §1). A exceção, escolhida: o leve é o padrão e não tem cor.
2. **O sinal principal no HUD** (For Honor) ou **no mundo** (Naraka, Chivalry 2): o pilar 1 e a terceira pessoa pedem o mundo; o HUD é redundância e cobre o que está fora da tela (F-053 §5).
3. **Som e efeito pelo `is_fresh`** ou **pela chave do evento:** o `is_fresh` não existe para o oponente espelhado, e o veredito do contato nasce num tick refeito; na sonda a ping 120, ele veria de um terço a metade dos eventos (F-061 §2). A chave, escolhida.
4. **O atraso de visão pelo `get_last_known_state()`** ou **pelo tick do próprio estado:** o primeiro devolve zero para o oponente, porque o histórico regrava o estado espelhado a cada tick (F-061 §2). O tick do estado, escolhido.
5. **A cor de time em vermelho e azul**, como no Valorant e no LoL, ou **pelo contorno e pelo anel, sem cor de token:** o vermelho colidiria com o ativo; o Overwatch deixa escolher entre nove cores (F-053 §3.5 e §6). O contorno, escolhido: a sonda usou branco para quem joga e preto para o oponente.
6. **A quebra de guarda só por forma** (a mão à frente, o contorno pulsando e o pisão) ou **com cor:** só a forma não se leu em 27 lances (F-062 §3); a mão em vermelhão entrou como hipótese e, na primeira exposição, ainda não mudou a resposta (F-063 §3). Fica com cor, a provar na fase 2.
7. **O filtro de daltonismo na tela toda** como recurso do jogo, ou **só como ferramenta de conferência:** o Overwatch abandonou o filtro na tela inteira em favor de cores por elemento (F-053 §3.5). O filtro fica como ferramenta nossa; o recurso é "nunca só por cor".
8. **A base da interface em 1152 × 648**, o padrão, ou **em 1920 × 1080:** a documentação recomenda a segunda para jogo 3D de desktop, com `canvas_items` e `expand` (F-051 §3.3).
9. **`keycode`** ou **`physical_keycode`:** o segundo guarda a posição, e WASD funciona no ABNT2, no AZERTY e no Dvorak (F-051 §4.3).

## Decisão

### 1. Os três canais e a cor na exceção

Cada estado do combate emite cor, pose e som, sempre os três, porque a cor some para o daltônico e na periferia, a pose some pelas costas e o som fica (F-053 §2.2). A cor marca a exceção que exige outra resposta; o leve, o padrão, não tem cor. A tabela v0, com as cores da Okabe-Ito (F-053 §3.6), como a sonda mostrou (F-061 §1):

| Estado | Cor | Pose | Som | Onde |
|---|---|---|---|---|
| Leve, preparação | Nenhuma | Preparação curta, a lâmina vai para trás | "Whoosh" curto | Mundo |
| Carregado, preparação | Azul celeste `#56B4E9` na lâmina e numa aura, desde o tick 0 | Postura própria desde o tick 0: a espada acima da cabeça | Som longo, subindo | Mundo; o HUD repete com um triângulo |
| Ativo, qualquer golpe | Vermelhão `#D55E00` na lâmina e no rastro | O arco da lâmina | "Swish" do corte | Mundo; o HUD repete com um círculo |
| Parry, a janela e o acerto | Amarelo `#F0E442` na lâmina e na aura; o acerto dá um flash nos dois e faíscas | A lâmina cruzada à frente | Um toque na janela; o "clang" no acerto, o som mais forte do jogo | Mundo |
| Quebra de guarda, preparação | A mão em vermelhão `#D55E00` desde o tick 0 (hipótese, a provar na fase 2; F-063 §4) | A espada baixa, a mão vem à frente, o contorno pulsa | Um pisão | Mundo; o HUD repete com um quadrado |
| Finta, o corte | Nenhuma | A pose volta num estalo | Um estalo seco (DEC-0016) | Mundo; o HUD repete com um X |
| Arma de longe carregada | Roxo-avermelhado `#CC79A7`, a conferir sob deuteranopia, onde se aproxima do cinza do leve (F-061 §4) | A puxada | A puxada ouvida pelo alvo, com direção 3D | Mundo e som |
| Bloqueio | Nenhuma | A lâmina vertical à frente, subindo em 100 ms | Um som baixo ao subir; o "tunk" no impacto | Mundo |
| Reação (levou o golpe, atordoado) | Um flash branco | O corpo recua | O "thud" | Mundo |

Regras da paleta: o eixo azul–amarelo e o claro–escuro; nenhum verde; laranja nunca junto do vermelhão ou do amarelo; contraste de 3:1 contra o fundo da arena (F-053 §3.3, §3.4 e §3.6). Sob deuteranopia e protanopia, os quatro tokens seguem separados pelo brilho (F-061 §4).

### 2. Onde o sinal mora

O sinal principal mora no mundo: a pose, o rastro e o brilho na arma, que o espectador e o replay também veem (pilar 1; pilar 5). O HUD é redundância, com forma e cor, e cobre o que está fora da tela, como uma seta na borda para o golpe ou a flecha pelas costas (F-053 §5). Nunca uma informação só por cor (F-053 §2.2; F-051 §4.5).

### 3. A cor de time e o anel

A cor de time é o contorno e o anel, com cor ajustável, e nunca repete uma cor de token; os tokens ficam presos à arma e à pose, com cor fixa (F-053 §6). O anel do 2 em 1 do 4v4 usa forma, espessura e segmentos, porque é visto na periferia, onde a cor quase não se percebe (F-053 §2.2 e §6). Na sonda, quem joga tem o contorno branco e o oponente o preto (F-061 §1).

### 4. O som: o bus "leitura"

Um bus "leitura", com um player por som, que nunca é cortado pelo limite de vozes, porque o Godot corta o som mais antigo e não tem prioridade (F-051 §5.1; F-053 §4). Um compressor em sidechain abaixa a música e o ambiente enquanto um token toca, em uns 12 dB: número v0, fechado pelo Claude, porque a sonda abaixou de 33 a 39 dB e isso é mais do que um jogo quer (F-061 §4). Efeitos curtos em WAV mono com Trim; música e ambiente em Ogg (F-051 §5.3). O Doppler fica desligado (F-051 §5.1).

### 5. Os tokens como dado

A tabela de tokens é um Resource em `data/`, imutável, lido do estado: o lutador lê o estado e procura o token; nada no Resource decide regra (DEC-0004, regra 3). A sonda fez isso com uma tabela estado → cor, pose, som, texto e forma (F-061 §1).

### 6. A chave do evento

- Som e efeito tocam uma vez por evento, pela chave (nó, tipo, id), quando o evento aparece pela primeira vez no estado exibido, depois de cada laço de ticks; nunca de novo na re-simulação; e um evento apresentado nunca é desfeito, mesmo que a re-simulação o apague (F-007 §1; F-061 §2). É a `key` de uma lista no React: reaplicar o mesmo estado não cria evento.
- O `is_fresh` do netfox cobre um caso só, o nó que o peer simula. O oponente espelhado não tem tick novo, porque é o último estado que chegou, reaplicado depois de cada rollback (DEC-0026 §2); e o veredito do contato, julgado na tela de quem defende (DEC-0026 §3), nasce sempre num tick refeito, porque a marca do contato chega depois de o tick já ter sido simulado novo. Na SyncTest com rollback forçado, apresentados e `is_fresh` coincidem (42 e 42, com 168 pela regra ingênua); no cliente a ping 120, o `is_fresh` veria de 18 a 24 de 42 a 56 eventos (F-061 §2). O próprio netfox avisa: "the `is_fresh` parameter may not work as expected" (`addons/netfox/rollback/network-rollback.gd`, na documentação do `input_delay`).
- Esta DEC substitui a frase "Som e VFX só tocam em tick novo, nunca na re-simulação" da regra 2 da DEC-0004. As outras cinco regras e o resto da regra 2 continuam valendo.

### 7. O atraso de visão pelo tick do estado

- O estado de cada lutador carrega o tick em que foi calculado. O atraso de visão de quem defende é o tick atual menos esse tick no estado do oponente que está na tela (F-061 §2).
- O `get_last_known_state()` do `RollbackSynchronizer` promete "the tick of the latest state received from the state owner" (`addons/netfox/rollback/rollback-synchronizer.gd`), mas devolve zero para o oponente espelhado, porque o histórico regrava o estado dele a cada tick e a idade do "último estado" é sempre zero (F-061 §2). Esta DEC substitui a frase do §2 da DEC-0026 que dava o atraso de visão por essa função; o resto da DEC-0026 continua valendo, e o `view_lag` no input (DEC-0026 §3) passa a vir do tick do estado.
- A reconferência das outras afirmações sobre o netfox nas DECs vigentes, contra a F-061: a DEC-0022 §3, comparar o modo desenhado com o do estado, é coerente com a chave do evento; a DEC-0026 §2, o oponente no último estado que chegou, reaplicado depois de cada rollback, foi o que a sonda viu; a DEC-0026 §3, o servidor espera o input de quem defende antes de julgar, foi o que fez o bot aparar 8 de 8 a ping 120 (F-061 §3). Quando o netfox subir de versão (DEC-0023), as três voltam à sonda.

### 8. A base da interface e a acessibilidade mínima

- **Um Theme só**, em `gui/theme/custom`, criado com a primeira cena de interface; a cascata resolve o resto, e as variações de tipo são as classes (F-051 §3.1 e §3.2).
- **A base de 1920 × 1080** no `project.godot`, com `canvas_items` e `expand`, guardada por teste (F-051 §3.3; F-054 §2). As fontes do Theme valem em pixels de 1080p.
- **A escala da interface** por `content_scale_factor`, exposta nas opções, de 0,8 a 1,5: número v0, fechado pelo Claude; a sonda subiu até 1,2 (F-051 §4.4; F-062 §2).
- **As teclas por posição física** (`physical_keycode`), remapeáveis desde o primeiro dia com o `InputMap`, salvas em `user://` e mostradas com o rótulo do teclado ativo (`keyboard_get_label_from_physical`) (F-051 §4.2 e §4.3). O núcleo recebe só o input traduzido (DEC-0004).
- **Nunca só por cor** (F-053 §2.2); **nomes de acessibilidade** nos menus; o leitor de tela na partida fica fora do v0 (F-051 §4.1).
- **As chaves de tradução por ID**, com pt-BR e en desde o começo (F-051 §3.5).

### 9. O que fica para a fase 2

- A janela do parry e a carga variável do carregado (Q-21): o parry por leitura pede uma preparação fixa por arma, ou um aviso próprio da soltura (F-062 §3; F-063 §3).
- A quebra de guarda por escolha (Q-25): 350 ms cabem a reação simples, não a escolha entre três defesas (F-063 §3).
- O som com fone, e a pose com o boneco e os clipes (F-063 §3).
- O jitter da entrega, que a sonda viu e o simulador do netfox não tem (Q-09; F-061 §3).

## Consequências

- O `AGENTS.md`, o `rede.md`, o `visao-geral.md`, o `reviewer.md` e o glossário trocam "só no tick novo" pela chave do evento.
- O `project.godot` ganha a base de 1920 × 1080, com cinco guardas no teste de configurações (TASK-7, critério 6).
- A fase 2 cria o Resource dos tokens em `data/`, o bus "leitura" e o apresentador que compara o estado exibido com o último apresentado, como o `present()` da sonda (F-061 §1); e uma SyncTest que conta os eventos apresentados contra as transições.
- A TASK-9 começa com as teclas físicas e as chaves de tradução; o Theme nasce com a primeira cena de interface.
- A DEC-0004 e a DEC-0026 ganham o aviso da frase substituída.

## Revisitar se

- Um token não se ler no duelo da fase 2, com o boneco e os clipes.
- O netfox mudar o `is_fresh` ou o `get_last_known_state()` numa versão nova (DEC-0023).
- A cor da arma de longe não se separar do cinza do leve sob deuteranopia, ou do amarelo sob tritanopia (F-053 §3.6; F-061 §4).
- A mão vermelha da quebra seguir sem se ler na fase 2.
