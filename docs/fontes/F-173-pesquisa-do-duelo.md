---
id: F-173
titulo: "Pesquisa: o tranco e a vantagem, a vida, a partida, a queda e o hitstop, e o bot, o percurso e o log de crash, para o desenho do duelo (27/10/2026)"
recebido_em: 2026-10-27
como: Relatórios finais de três agentes de pesquisa, uma verificação adversarial e uma montagem, de um workflow de 5 agentes do Claude Code, pedido ao abrir o desenho do duelo, fase 2 (sessão 20, 27/10/2026). Os três pesquisadores rodaram em paralelo, cada um com uma lente; um verificador adversarial abriu as fontes das afirmações importantes; o redator (Sonnet 5.5) montou este arquivo sem mudar número nem link. Os pesquisadores do tranco e da vida rodaram em Opus 5.5 (esforço alto), o do bot em Sonnet 5.5 (esforço médio), o verificador em Fable 5.1 (esforço alto) e o redator em Sonnet 5.5 (esforço médio); o orquestrador refez o §5 a partir do diário do workflow, porque o texto das afirmações não tinha ido ao redator. O §1, o §2 e o §3 são os relatórios como chegaram, em português, só com os títulos rebaixados um nível. O §4 traz os resumos e as listas do que os agentes não confirmaram, como chegaram. O §5 traz, para cada afirmação marcada como importante, o veredicto do verificador, que citou a frase. O §6 lista as demais afirmações, com o link.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: três pesquisadores rodaram em paralelo, cada um com uma lente (o tranco e a vantagem; a vida, a partida, a queda e o hitstop; o bot, o percurso e o log de crash), e juntaram 78 afirmações. 40 foram marcadas como importantes e o verificador abriu 40 delas: 32 confirmadas, 0 refutadas e 8 não verificáveis. 0 ficaram sem verificação, pelo limite do verificador. As outras 38 não eram importantes e vão com o link, no §6. "Não confirmado" no texto quer dizer que o agente não conseguiu abrir a fonte primária. Fatos, inferências e recomendações estão marcados pelos próprios agentes. O que vira regra sai da conversa de design do duelo, não daqui.

## §1 — O tranco e a vantagem, como chegou

#### Pesquisa R1: o tranco e a vantagem (frame data da troca)

Data: 27/10/2026. Lente: hitstun, blockstun, vantagem de frame, armadura e castigo. Isto é **pesquisa, não decisão**: o que vira regra sai da conversa de design com o Arthur. Cada número tem link. **Fato** = li na fonte; **Inferência** = conta ou conclusão minha; **Recomendação** = proposta para o v0. Construí em cima da F-053 (tempos de reação, Infil, leitura), sem repetir a pesquisa dela.

Nota de método: o For Honor Info Hub é um app em JavaScript. Li o texto da página "General Info" dentro do pacote JS do próprio site e os dados de cada herói pela API pública do site (`/api/CharacterAttackData`, `/api/CharacterMaxPunishes/getAll`). Os dados do Chivalry 2 vieram do Polehammer, que diz que os tempos foram "sourced directly from in-game assets". Os dois são **fontes de comunidade**, não da Ubisoft nem da Torn Banner.

##### Termos

- **Tick** = 1/60 s = 16,7 ms (DEC-0024). Um "frame" dos jogos de luta a 60 fps é o mesmo tamanho.
- **Startup / preparação**: do início do golpe até ele poder acertar.
- **Ativo**: o trecho em que o golpe machuca. **Recuperação**: depois do ativo, até poder agir de novo.
- **Hitstun** (tranco de acerto): quanto tempo quem **levou** o golpe fica sem poder agir.
- **Blockstun** (tranco de bloqueio): o mesmo, para quem **bloqueou**.
- **Vantagem de frame**: quem volta a agir primeiro. "+3 no acerto" = o atacante age 3 ticks antes do defensor; "−6 no bloqueio" = o defensor age 6 ticks antes. Como no LoL, depois de uma troca de skills: quem tem o cooldown voltando antes "ganha a próxima".
- **Seguro (safe)**: o golpe bloqueado deixa o atacante para trás, mas não tanto que o defensor consiga acertar antes de ele se defender. **Castigável (punishable)**: o contrário.
- **Castigo garantido**: dano que o outro não consegue evitar com nenhuma ação.
- **Armadura (hyper armor / super armor)**: o golpe leva o dano mas não é interrompido.
- **Hitstop / hitlag**: o congelamento curto dos **dois** lutadores no impacto.
- **GB / CGB**: quebra de guarda / contra-quebra de guarda ("tech" da GB).

---

##### 1. For Honor (fonte: For Honor Info Hub, comunidade)

| # | O que | Número | Fonte |
|---|---|---|---|
| C01 | Janela de parry | abre **300 ms antes** do contato e fecha **100 ms antes**: **200 ms** (12 ticks) | [Info Hub, General Info](https://forhonorinfohub.com/generalinfo) |
| C02 | Tranco de quem teve o golpe aparado | leve aparado: **900 ms**; pesado aparado: **600 ms** | [Info Hub, General Info](https://forhonorinfohub.com/generalinfo) |
| C03 | O que o parry garante (Warden, exemplo) | parry de leve → pesado de cima (27 de dano, golpe de 900 ms); parry de pesado → dois leves laterais (15 de dano). Mediana das entradas listadas para todos os heróis: parry de leve 26, parry de pesado 14, GB 24 | [Info Hub API, MaxPunishes](https://forhonorinfohub.com/api/CharacterMaxPunishes/getAll) |
| C04 | Velocidade dos golpes básicos (tempo até acertar) | leve de abertura: **500 ms** em 77 de 79 entradas, 400 ms em 2. Pesado de abertura: 800 ms (50), 900 (19), 700 (11) | [Info Hub API, AttackData](https://forhonorinfohub.com/api/CharacterAttackData) |
| C05 | Tabela de tranco (recuperação até poder **atacar**) | acerto leve **600**, médio **800**, forte **1000** ms; bloqueio leve **600**, médio **700**, forte **800** ms; bloqueio superior: **400** em todos | [Info Hub, General Info](https://forhonorinfohub.com/generalinfo) |
| C06 | Sinal da vantagem | leves básicos são "minus" no acerto (recuperação maior que o tranco que causam); pesados finalizadores são "plus" no acerto; muitos finalizadores são neutros no bloqueio | [Info Hub, General Info](https://forhonorinfohub.com/generalinfo) |
| C07 | Recuperação do leve (Raider, exemplo) | leve de 500 ms recupera **700 ms** no acerto e no bloqueio superior. O bloqueio comum faz bloqueio superior nos leves normais | [Info Hub API, AttackData](https://forhonorinfohub.com/api/CharacterAttackData); [General Info](https://forhonorinfohub.com/generalinfo) |
| C08 | Quebra de guarda | GB de **400 ms** (300 ms logo depois de uma finta), custa 15 de stamina. Janela de contra-GB: **300 ms a partir do contato** ("600-700ms reaction time" contando do início da GB) | [Info Hub, General Info](https://forhonorinfohub.com/generalinfo) |
| C09 | Depois da GB | tranco de **800 ms**; se o atacante começa um golpe, o tranco se estende para dar 800 ms de janela de castigo. Quem faz a contra-GB fica **+33 ms** | [Info Hub, General Info](https://forhonorinfohub.com/generalinfo) |
| C10 | GB errada | ricochete: 1000 ms de recuperação; GB no vazio: 1000 ms até trocar a guarda, 900 ms até esquivar ou tentar outra GB | [Info Hub, General Info](https://forhonorinfohub.com/generalinfo) |
| C11 | Armadura | hyper armor "prevents a unit from flinching upon taking damage". Nos dados: a maioria dos pesados de abertura **não tem** armadura; alguns finalizadores têm a partir de **100 ms**, e três pesados de abertura a partir de 500 ms. A GB pega um pesado de abertura nos primeiros **433 ms** dele | [General Info](https://forhonorinfohub.com/generalinfo); [API](https://forhonorinfohub.com/api/CharacterAttackData) |
| C12 | Sem stamina (OOS) | só leves e pesados básicos; sem finta, rolamento nem corrida; os golpes ficam mais lentos e com janela de parry de 400 ms; quem é aparado sem stamina perde o equilíbrio | [Info Hub, General Info](https://forhonorinfohub.com/generalinfo) |
| — | Finta e esquiva | finta "dura" até **400 ms** antes do contato; 200 ms de recuperação depois da finta. Invulnerabilidade da esquiva de 166 a 300 ms | [Info Hub, General Info](https://forhonorinfohub.com/generalinfo) |

**Fato (C05 + C07):** o leve do Raider tem 700 ms de recuperação; o defensor que o bloqueia (bloqueio superior) recupera em 400 ms. **Inferência:** o defensor fica **+300 ms** depois de bloquear um leve. Mesmo assim, o leve não é castigável, porque o golpe mais rápido do jogo leva 400–500 ms (C04). É a mesma regra do Tekken (§5): ficar para trás só vira castigo quando a desvantagem passa do startup do golpe mais rápido.

**Fato (C05):** um leve que acerta trava o alvo por 600 ms até ele poder atacar; o leve recupera em 700 ms. **Inferência:** o leve fica −100 ms no acerto. O For Honor quis que acertar um leve **não** desse a vez a quem acertou, e assim não existe pressão infinita de leves.

**Stamina no bloqueio.** Nos dados, os golpes básicos custam stamina a quem ataca (Warden: leve 9, pesado 12) e têm `stamina_damage` vazio. **Inferência:** bloquear um golpe básico não gasta a stamina de quem defende. Não achei frase do Info Hub dizendo isso com todas as letras: **não confirmado** como regra.

**Golpe leve contra pesado em preparação.** **Fato:** sem armadura, o golpe "faz recuar" (*flinch*, C11). **Inferência:** um leve de 500 ms interrompe um pesado de 800–900 ms que começou junto. No For Honor, então, o pesado **não** vence o leve. O triângulo dele é outro: pesado contra guarda, parry contra pesado, GB contra quem fica parado. O nosso (carregado vence leve) se parece mais com o do Naraka.

---

##### 2. Chivalry 2

| # | O que | Número | Fonte |
|---|---|---|---|
| C13 | Fases do golpe (Espada Longa, corte) | "holding" fixo de **350 ms** em todas as armas, depois windup, release (ativo) e recovery. Leve: windup **225**, release **475**, recovery **800** ms. Pesado: **475 / 500 / 950** ms. Estocada leve: windup 275, release 400. O riposte troca o windup por 225 ms (leve) | [Polehammer](https://polehammer.net/) (dados das armas no pacote JS do site) |
| — | Estocada da Espada Longa, oficial | windup base da estocada de 0,25 para **0,275 s** (patch 2.4.2), "to improve readability" | [Patch 2.4.2](https://chivalry2.com/2022/03/28/patch-2-4-2/) |
| C14 | Stamina no bloqueio e sem stamina | golpe bloqueado tira de stamina **1/3 do dano base** (Espada Longa: leve 12, pesado 18 no Polehammer). Quem leva um golpe **sem stamina larga a arma**, leva metade do dano e cambaleia | [Chivalry Wiki, Combat](https://chivalry.wiki.gg/wiki/Combat_(Chivalry_II)); [Polehammer](https://polehammer.net/) |
| C15 | Interrupção (flinch) e chute | "A player is vulnerable during both the windup and release phase"; o jab "will interrupt an opponent's attack that is still in windup". O chute **não** interrompe quem ataca; contra a guarda levantada, quebra a guarda e faz cambalear por mais tempo | [Chivalry Wiki, Combat](https://chivalry.wiki.gg/wiki/Combat_(Chivalry_II)) |
| — | Exceção ao flinch | as Katares não fazem o alvo recuar (patch 2.6) | [Patch 2.6](https://chivalry2.com/2022/10/04/reinforced-update-patch-notes/) (via resumo de busca, ver "O que não confirmei") |
| C16 | Riposte e contra-ataque | riposte: janela de **meio segundo** depois do bloqueio, com ~0,5 s de auto-parry. Contra-ataque: o golpe tem de começar **depois do release** do oponente e **antes** de ele acertar, também com ~0,5 s de auto-parry. Riposte não gasta stamina; contra-ataque gasta | [Chivalry Wiki, Combat](https://chivalry.wiki.gg/wiki/Combat_(Chivalry_II)) |

**Inferência:** no Chivalry 2 o leve leva **575 ms** até poder acertar (350 + 225), quase o dobro do nosso leve de 300 ms. O release longo (475 ms) é a arma varrendo o espaço, não um ativo parado. Como a regra é que **todo golpe interrompe a preparação do outro** (só a arma leve "jab" é rápida o bastante para isso), quem ataca primeiro ganha a troca. O Chivalry não tem armadura nos básicos.

---

##### 3. Naraka: Bladepoint

| # | O que | Fonte |
|---|---|---|
| C17 | O triângulo: focus (azul) vence básico, parry vence focus, básico vence parry. Quem carrega um focus "will take damage from basic attacks while charging, but they won't interrupt you". O dano que o focus devolve é "far greater" | [Steam, guia de comunidade](https://steamcommunity.com/sharedfiles/filedetails/?id=2855559230) |
| C18 | Parry bem-feito: o inimigo cai, a arma dele vai ao chão, e vem um contra-ataque "extremely damaging". Básicos não se aparam. Exceções: as espadas duplas só ganham a armadura **depois de soltar** o golpe; o espadão perde a armadura no fim de uma carga longa | [Steam, guia de comunidade](https://steamcommunity.com/sharedfiles/filedetails/?id=2855559230) |
| — | Choque: básico contra básico e focus contra focus "clash", e os dois levam um pouco de dano | [Steam, guia de comunidade](https://steamcommunity.com/sharedfiles/filedetails/?id=2855559230) |
| — | Gancho contra quem está em focus: o gancho não interrompe um focus | [Steam, guia de comunidade](https://steamcommunity.com/sharedfiles/filedetails/?id=2855559230) |

**Números do Naraka:** não achei tempos medidos (janela do parry, tempo no chão, quanto a arma fica fora) em nenhuma fonte que eu tenha conseguido abrir. Um fórum fala em "0.2 sec delay" de ativação do parry, sem método: **não confirmado**. Também não achei um "agarrão" corpo a corpo no Naraka (só o gancho): **não confirmado**.

**Inferência importante:** no Naraka, o "carregado vence leve" vem da **armadura desde o começo da carga**, não de velocidade. É isso que faz o triângulo valer quando os dois começam juntos.

---

##### 4. Sekiro (fonte: Fextralife, wiki de comunidade)

| # | O que | Número | Fonte |
|---|---|---|---|
| C19 | Janela do deflect | **12 frames (0,2 s)** antes do golpe, de padrão. Cada aperto recente encolhe a janela até **4 frames**, e até **0** se apertar rápido demais. A punição some depois de **30 frames** ou logo após um deflect bem-feito | [Fextralife, Deflection](https://sekiroshadowsdietwice.wiki.fextralife.com/Deflection) |
| C20 | Postura: bloquear contra desviar | bloquear "fills the defender's posture gauge and does not affect the attacker". O deflect dá "a high amount of posture damage to the attacker" e pouca ao defensor. O deflect "staggers most enemies briefly, allowing you a small window to counter attack" | [Fextralife, Posture](https://sekiroshadowsdietwice.wiki.fextralife.com/Posture); [Deflection](https://sekiroshadowsdietwice.wiki.fextralife.com/Deflection) |

A Fextralife não diz quem mediu os 12 frames. Não existe "deflect perfeito" separado do deflect: um fórum discute isso e a wiki não menciona.

---

##### 5. Convenções dos jogos de luta (referência para as regras)

| # | O que | Número | Fonte |
|---|---|---|---|
| C21 | Street Fighter 6, Ryu (dados oficiais da Capcom) | soco fraco em pé: startup **4**, **+4** no acerto, **−1** no bloqueio. Soco forte em pé: **10**, **+4 / −2**. Soco forte agachado: **9**, **+1 / −7**. Short Uppercut: −13 no bloqueio | [Capcom, frame data do Ryu](https://www.streetfighter.com/6/character/ryu/frame) |
| C22 | Tekken 8: castigo | "hitstun is typically longer than blockstun". O ataque mais rápido da maioria dos personagens é de **10 frames**: −10 ou pior é castigável, −9 ou melhor é "seguro"; −15 dá castigo com launcher. Jab "i10, +1 on block" (Kazumi) | [Wavu Wiki, Punishment](https://wavu.wiki/t/Punishment) |
| C23 | Um acerto por janela ativa | "only one of an attack's active frames are allowed to connect"; o tranco não muda com o frame em que pega, mas começa mais tarde se pegar num frame ativo tardio ("meaty") | [Wavu Wiki, Punishment](https://wavu.wiki/t/Punishment) |
| C24 | Smash Ultimate: tranco no escudo e hitlag | shieldstun = ⌊0,8 × d × t × m × p + 2⌋ (d = dano; t = 0,725 smash, 0,33 aéreo, 1 o resto). Hitlag (congelamento) = ⌊(d × 0,65 + 6) × multiplicadores⌋ frames, para o atacante **e** a vítima. No escudo, o atacante sofre o hitlag mas **não** o shieldstun | [SmashWiki, Shieldstun](https://www.ssbwiki.com/Shieldstun); [SmashWiki, Hitlag](https://www.ssbwiki.com/Hitlag) |
| C25 | Definições de "seguro" e de armadura | seguro: "make sure the gulf is smaller than your opponent's fastest" ataque. A armadura "can be thrown" e pode ser quebrada por golpes específicos | [Infil, Glossary: Safe](https://glossary.infil.net/?t=Safe); [Infil, Glossary: Armor](https://glossary.infil.net/?t=Armor) |

**Fato (C22):** no Tekken a entrada tem de 2 a 3 frames de atraso mínimo. **Inferência:** o "−10 é castigável" já embute que o defensor **guarda o comando no buffer** durante o blockstun. Ele não reage depois do bloqueio, porque já sabia que ia bloquear.

---

#### Princípios e inferências

**P1. Três números e uma subtração decidem tudo.** A vantagem depois do contato é **tranco do defensor − o que falta do atacante** (o resto do ativo mais a recuperação). Fonte da definição: [Info Hub](https://forhonorinfohub.com/generalinfo) e [Wavu](https://wavu.wiki/t/Punishment). No v0, com contato no 1º tick ativo:

| Golpe v0 | Preparação | Ativo | Recuperação | Falta ao atacante depois do contato |
|---|---|---|---|---|
| Leve | 300 ms = 18 ticks | 100 = 6 | 250 = 15 | **350 ms = 21 ticks** |
| Carregado | 500–900 = 30–54 | 120 = 7 | 450 = 27 | **~570 ms = 34 ticks** |

(Inferência; os tempos vêm de `docs/design/combate.md`, como chegaram no pedido.)

**P2. No nosso jogo, "seguro" tem um limite diferente do jogo de luta. É a conta mais importante deste relatório.** No SF6 e no Tekken, bloquear é instantâneo. No nosso, **levantar o bloqueio leva 100 ms (6 ticks)**. Então o atacante que ficou D ticks para trás só se salva se `D + 6 < 18` (o leve do castigo pega aos 18 ticks).
- **Seguro contra leve:** desvantagem **menor que 12 ticks (200 ms)**.
- **Contra a esquiva:** 60 ms de startup até a invulnerabilidade, ~4 ticks. A esquiva escapa até ~14 ticks (233 ms).

Inferência a partir do [Infil Glossary](https://glossary.infil.net/?t=Safe) e dos números do v0.

**P3. Um castigo garantido depois de um bloqueio não precisa de reação; depois de um tranco curto, precisa.** Quem bloqueia um carregado já o viu chegando por 500 ms ou mais, então pode deixar o leve no buffer. Para o castigo ser garantido basta: **vantagem do defensor ≥ startup do castigo − 6 ticks do bloqueio do outro**, ou seja, mais de 12 ticks (200 ms) para um leve e mais de 24 ticks (400 ms) para um carregado mínimo.

Para quem **não** usa buffer e reage ao "clang" (~213–273 ms, F-053), o blockstun também precisa ser **≥ ~250 ms (15 ticks)**, para a reação caber dentro dele. O For Honor resolve isso de outro jeito: **estende** o tranco da GB quando o castigo começa (C09). Inferência.

**P4. Bloqueio dá a vez, parry dá o castigo.** For Honor:
- o bloqueio deixa o defensor à frente, mas sem castigo (C05, C07);
- o parry dá 600–900 ms de tranco e um golpe garantido (C02, C03).

Sekiro: bloquear custa postura a quem defende, o deflect custa ao atacante (C20). Naraka: o parry derruba e desarma (C18).

**Inferência:** se o bloqueio do carregado já desse castigo garantido, ninguém arriscaria o parry, que custa 400 ms quando erra. O triângulo "parry vence carregado" precisa que o parry pague **bem mais** que o bloqueio.

**P5. O triângulo "carregado vence leve" exige armadura.** Se os dois começam juntos, o leve pega aos 18 ticks e o carregado só aos 30 ou mais. Sem armadura o leve sempre ganha, como no For Honor (C11) e no Chivalry (C15). O Naraka, nosso modelo, dá armadura **durante toda a carga** (C17). A armadura não impede o dano; o Naraka cobra o dano do leve. A GB pode passar pela armadura ("armor can be thrown", C25; no For Honor, a GB pega o pesado nos primeiros 433 ms, C11). Inferência.

**P6. A janela do parry não se acerta por reação ao início do golpe, e sim pelo tempo até o contato.** As três referências medidas estão perto de **200 ms**:
- For Honor: 200 ms, de 300 a 100 ms antes do contato (C01);
- Sekiro: 12 frames, 200 ms (C19);
- Chivalry: meio segundo para o riposte, mas isso é **depois** do bloqueio (C16).

Os nossos 80 ms (~5 ticks) ficam bem abaixo de todas. Contra spam, há dois freios na referência: o Sekiro encolhe a janela a cada aperto (C19), e o nosso v0 já cobra 400 ms no erro.

**Inferência sobre o 0 em 21:** o For Honor tem o pesado de **velocidade fixa** e um ponto sem volta **400 ms antes do contato** (a finta tem de vir antes dele). O parry abre 300 ms antes do contato, depois desse ponto. Ou seja, a janela fica num trecho do golpe que **sempre** dura o mesmo. No nosso v0 a soltura do carregado é livre (500 a 900 ms), e não há trecho fixo entre "soltou" e "pegou".

**P7. A GB do For Honor também não é reagível na preparação; a defesa vem depois do contato.** A GB de 400 ms tem contra-GB em **300 ms contados do contato** (C08). Reagir a "fui agarrado" é reação **simples**: um estímulo, uma resposta, a faixa reagível do Infil na F-053. Escolher entre parry, bloqueio e esquiva durante a preparação é reação de **escolha**: foi aí que o Arthur não conseguiu com 350 ms. Quem dá a contra-GB fica +33 ms (C09), e a troca recomeça em pé de igualdade. Inferência.

**P8. Um acerto por alvo por janela ativa** é a regra do Tekken (C23). Também é a que faz sentido num núcleo em ticks: o golpe guarda "já acertei o alvo X" no estado e ignora os outros ticks ativos contra ele. Inferência.

**P9. O hitstop compartilhado não mexe na vantagem.** No Smash os dois congelam pelo mesmo tempo (C24), então quem estava à frente continua à frente. Ele serve ao **peso** do golpe e dá tempo de ler o que aconteceu. Inferência. Como é estado do núcleo, entra no rollback (DEC-0004).

---

#### Recomendações para o v0

Tudo aqui é **recomendação**, a sentir jogando (DEC-0017). Ticks a 60; arredondei para o tick mais próximo e mostro a conta. "Contato" é o 1º tick ativo.

| # | Item | ms | Ticks | Vantagem resultante | Por quê |
|---|---|---|---|---|---|
| R1 | Hitstun do **leve** (acerto) | 400 | 24 | atacante **+3** (24 − 21) | Hitstun maior que blockstun (C22). Um +3 pequeno dá a vez a quem acertou, sem combo garantido: para isso precisaria de +18. A pressão de leves não fica infinita porque o carregado com armadura (R6) a quebra. Mais generoso que o For Honor (−100 ms, C05), que não tem a armadura do Naraka |
| R2 | Blockstun do **leve** | 250 | 15 | atacante **−6** | Seguro, porque −6 fica longe do limite de −12 (P2). O defensor ganha a vez, como no For Honor (C07) e no SF6, onde o soco fraco é −1 (C21). Os 15 ticks também cobrem a reação ao "clang" (P3) |
| R3 | Hitstun do **carregado** (acerto) | 700 | 42 | atacante **+8** (42 − 34) | Plus no acerto, como os pesados finalizadores do For Honor (C06). Não emenda num leve (precisaria de +18): é iniciativa, não combo |
| R4 | Blockstun do **carregado** | 417 | 25 | atacante **−9** | **Seguro por 3 ticks** (P2), mas o defensor ganha a vez: um leve dele pega 9 ticks antes de um leve do atacante. O bloqueio **não** dá castigo garantido, para que o parry valha a pena (P4). Se o Arthur quiser que bloquear o carregado dê castigo de leve, a desvantagem tem de passar de 12 ticks: blockstun **≥ 47 ticks (783 ms)**, ou ≥ 52 ticks (867 ms) para caber uma margem de 5 |
| R5 | Janela do **parry** | 200 | 12 | — | Comparação: **80 ms ≈ 5 ticks**, abaixo de toda referência; **133 ms = 8 ticks**, o meio-termo; **200 ms = 12 ticks**, igual ao For Honor (C01) e ao Sekiro (C19). A janela se acerta pelo tempo até o contato, não pela reação (P6). O erro já custa 400 ms (v0), e o leve não se apara (Naraka, C18), então uma janela larga não vira spam. **Condição:** colocar a janela num trecho fixo antes do contato (ver R11) |
| R6 | **Armadura** do carregado | desde 0 | desde o tick 0 da preparação | — | Sem ela, o leve iniciado junto pega aos 18 ticks e o carregado só aos ≥ 30: o triângulo se inverte (P5). É o modelo do Naraka (C17). A armadura vale **só contra leves**: leva o dano e não recua. Não vale contra GB, parry nem outro carregado (carregado contra carregado = troca). Alternativa: começar no tick 6 (100 ms, como os finalizadores do For Honor, C11), para que um leve já no ar ainda interrompa. Recomendo o **tick 0**: uma regra só, mais fácil de ler |
| R7 | Tranco depois do **parry** bem-feito | 800 | 48 | castigo de carregado **garantido** | Quem aparou se recupera em 200 ms (12 ticks, v0). O carregado mínimo pega em 12 + 30 = **42 ticks (700 ms)**, antes dos 48: sobram 6 ticks (100 ms) de folga para o atraso de soltar o botão. O leve pega em 30 ticks. A esquiva da vítima só ficaria invulnerável no tick 48 + 4, depois do golpe. **Sim, garante o carregado de 500 ms.** Referências: o For Honor dá 900 ms ao leve aparado, com um pesado de 900 garantido (C02, C03), e o Naraka derruba e desarma (C18) |
| R8 | **GB**: preparação | 350 (sem mudar) | 21 | — | Continua **não reagível por escolha**, de propósito: é a ferramenta contra quem fica só bloqueando. A defesa passa para depois do contato (R9), como no For Honor (P7). Se o Arthur preferir uma GB reagível **na preparação**, ela precisa de **≥ 500 ms (30 ticks)**: o Infil põe ~40 frames como reagível e 20 frames com escolha como não reagível (F-053), e o Drive Impact de 26 frames é "just enough" para **um** golpe esperado. Só que, com 500 ms, a esquiva (250 de reação + 60 de startup = 310) passa sempre, e a GB perde a função |
| R9 | **Contra-GB** (tech): janela depois do contato | 333 | 20 | quem dá o tech fica **+2** (33 ms) | É a janela do For Honor, 300 ms a partir do contato (C08), mais 2 ticks de margem pelo atraso de rede (F-053 §2.2). Reagir ao agarrão é reação simples (~213–273 ms) e cabe com folga de 60 a 120 ms. O +2 copia o +33 ms do For Honor (C09). Mesmo botão da GB |
| R10 | Tranco da **GB** sem tech | 900 a partir do contato | 54 | carregado **garantido** | Durante o tech (20 ticks) os dois ficam presos na animação. Depois, quem quebrou a guarda age: o carregado mínimo pega em 20 + 30 = **50 ticks**, antes dos 54 (4 de folga); o leve, em 38. Referência: 800 ms no For Honor, estendidos quando o castigo começa (C09) |
| R11 | **Trecho fixo** do carregado antes do contato | 400 | 24 | — | O pedido não traz este item; ele vem do 0 em 21 do Arthur. Depois de soltar o carregado, os últimos 400 ms até o contato são **sempre iguais**, com sinal de "soltou" (pose e som, F-053). A janela do parry (R5) fica nos últimos 200 ms. Quem vê a soltura e reage em 213–273 ms cai dentro da janela (de 200 a 400 ms depois da soltura). É o ponto sem volta do For Honor, 400 ms antes do contato (§1). **Muda a forma do carregado:** vai à conversa de design, não é um ajuste de número |
| R12 | Um acerto por alvo por janela ativa | — | — | — | Regra do Tekken (C23); um conjunto "já acertei" no estado do núcleo (P8) |
| R13 | GB no vazio (esquivada) | ≥ castigável | ver nota | — | O For Honor cobra 900–1000 ms (C10). A conta exata depende da duração **total** da esquiva, que não está nos números do v0: **NEEDS_CONTEXT**. A regra: a recuperação da GB tem de passar da recuperação da esquiva mais 18 ticks (o leve) |
| R14 | Hitstop compartilhado (opcional) | 50 leve, 100 carregado | 3 e 6 | não muda | Dá peso ao golpe e não mexe na vantagem (P9, C24). Pelo modelo do Smash daria de 7 a 12 frames, o que pesa demais num jogo a 60 ticks com rede. **A decidir**, não é essencial |

**Resumo da escada de recompensa (inferência):**
- leve bloqueado: o defensor fica +6, ganha a vez;
- carregado bloqueado: +9, ganha a vez sem castigo;
- carregado aparado: 48 ticks, carregado garantido;
- GB não respondida: 54 ticks, carregado garantido;
- GB respondida (tech): +2 e tudo recomeça.

Cada risco maior paga mais. É o desenho do For Honor (C02, C05, C09) com a armadura do Naraka (C17).

**Stamina (fora da lente, só referência).** O Chivalry tira 1/3 do dano no bloqueio e desarma quem é acertado sem stamina (C14). O For Honor deixa quem está sem stamina mais lento, sem finta e mais fácil de aparar (C12). O nosso v0 (10 por golpe bloqueado) fica entre os dois. Não recomendo mudar sem jogar.

---

#### O que não confirmei

- **Naraka:** nenhum número medido. Faltam a janela do parry, quanto tempo a vítima fica no chão e quanto tempo a arma fica fora. O "0.2 sec delay" do parry é de um fórum, sem método. Não achei agarrão corpo a corpo, só o gancho. As páginas da PCGamer, da Sportskeeda e de outros guias não foram abertas.
- **For Honor:** o Info Hub não diz com todas as letras que bloquear um golpe básico não gasta a stamina de quem defende (é inferência do `stamina_damage` vazio). Também não tem fonte oficial da Ubisoft para nenhum número: tudo é comunidade. A fandom wiki deu 402/403.
- **For Honor:** não achei o regen de stamina nem o custo exato de um parry em stamina.
- **Chivalry 2:** não achei a duração da janela de parry ativo, nem o tempo de cambaleio depois do chute e do desarme. A exceção das Katares (sem flinch) veio de um resumo de busca da nota do patch 2.6, sem a página aberta. O campo `blocked: 0.75` dos dados do Polehammer não tem definição, então não o usei.
- **Sekiro:** a Fextralife não diz quem mediu os 12 frames. Um fórum fala em 500 ms, o que contradiz a wiki. Também não há valores de postura por golpe.
- **Tempo de reação de escolha** (lei de Hick) com números de estudo primário: não achei. Uso a medida do Arthur e o Infil (F-053).
- **Tekken 8:** os números vêm da Wavu Wiki (comunidade), não da Bandai Namco.
- **Street Fighter 6:** só olhei o Ryu; não confirmei as janelas do Drive Parry nem do Perfect Parry.
- **SuperCombo Wiki e fandom wikis:** deram 403/402.

## §2 — A vida, a partida, a queda e o hitstop, como chegou

#### Pesquisa R2: vida, dano, formato da partida, queda para fora e hitstop (27/10/2026)

Lente: vida, dano, formato de partida, cair para fora da arena e hitstop. Isto é **pesquisa, não decisão**: o que vira regra sai da conversa de design com o Arthur. Cada número tem a URL que eu abri. Marcação: **Fato** (li na fonte), **Inferência** (minha conclusão), **Recomendação** (o que eu sugiro para o v0), **não confirmado** (não consegui abrir a fonte primária). Parte da F-053 (reação, cores, som) e não repete o que ela já cobriu.

---

#### Termos

- **Hitstop / hitlag / impact freeze:** o "congelamento" de poucos frames quando um golpe acerta. No Smash o nome é *hitlag*; na comunidade de luta, *hitstop*. É o que faz o golpe "pesar", como o micro-travamento quando um tiro do CoD acerta o inimigo e o marcador aparece.
- **Blockstop:** o mesmo congelamento quando o golpe é bloqueado.
- **Stock:** uma "vida" no Smash; perder todas é perder o jogo. Como as vidas de um fliperama.
- **Blast line / blast zone:** a linha invisível fora da tela do Smash; cruzou, morreu.
- **Death plane / KillZ:** um volume ou altura abaixo do nível; quem passa dele morre ou é destruído. No Unreal é a propriedade `KillZ`.
- **Out of bounds (OOB):** a área proibida com um cronômetro: volte antes de zerar ou morra (Apex).
- **Time out / time over:** o tempo do round acabou com os dois vivos.
- **Double KO:** os dois morrem no mesmo instante.
- **TTK (time to kill) / hits to kill:** quantos golpes ou quanto tempo para matar.
- **Ring out / environmental kill:** matar jogando o outro num abismo, espinho ou fogo.
- **Tick:** 1/60 s = 16,7 ms (DEC-0024). "Frame a 60 fps" é a mesma medida.

---

#### 1. Vida, dano e golpes para matar

| Jogo | Medida | Valor | Fonte |
|---|---|---|---|
| For Honor | Vida dos heróis (amostra de 20) | **120 a 140**. 120: Peacekeeper, Orochi, Gladiator, Nobushi, Shinobi, Shaman, Afeera. 125: Kensei. 130: Warden, Raider, Berserker, Highlander, Jormungandr, Hitokiri, Gryphon, Pirate, Medjay. 140: Conqueror, Lawbringer, Warlord, Shugoki | [For Honor Wiki, Shugoki/Main](https://forhonor.fandom.com/wiki/Shugoki/Main) e páginas `/Main` de cada herói (lidas pela API da wiki; wiki de comunidade) |
| For Honor | Teto de vida | O Shugoki "used to feature the highest amount of health at 160 before the maximum health a Hero can have naturally was capped at 140" | [For Honor Wiki, Shugoki/Main](https://forhonor.fandom.com/wiki/Shugoki/Main) |
| For Honor | Stamina | 120 na maioria; 130 a 150 em alguns (Gladiator 150) | idem, páginas `/Main` |
| For Honor | Dano do leve | 13 ("Top Light in Chain now deals 13 damage (up from 9)"); 15 ("Light Finishers now deal 15 damage") | [Ubisoft, Patch Notes 2.40.0](https://www.ubisoft.com/en-us/game/for-honor/news-updates/5K7gJrsS7BGjegCjnnZydv/patch-notes-2400-for-honor) |
| For Honor | Dano do pesado | 26 a 30 (Raider: pesado encadeado 28, lateral 26, finalizador 28 a 30; Zhanhu: finalizador 28) | [Ubisoft, Patch Notes 2.40.0](https://www.ubisoft.com/en-us/game/for-honor/news-updates/5K7gJrsS7BGjegCjnnZydv/patch-notes-2400-for-honor) |
| For Honor | Golpes para matar | **Inferência:** 130 de vida ÷ 13–15 = 9–10 leves; ÷ 26–30 = 5 pesados | conta minha sobre as linhas acima |
| Chivalry 2 | Vida por classe | Knight 175; Footman 150; Vanguard 130; Archer 90 | [Knight](https://chivalry.wiki.gg/wiki/Knight_(Chivalry_II)), [Vanguard](https://chivalry.wiki.gg/wiki/Vanguard_(Chivalry_II)), [Archer](https://chivalry.wiki.gg/wiki/Archer_(Chivalry_II)) (wiki de comunidade); Footman 150 só em busca: **não confirmado** |
| Chivalry 2 | Dano do Battle Axe (corpo) | Slash 55 a 69; Overhead 65 a 81; Heavy Slash 75 a 94; Heavy Overhead 85 a 106 (cresce do Archer ao Knight). A extração da tabela veio embaralhada; a ordem das colunas é inferida | [Chivalry Wiki, Battle Axe](https://chivalry.wiki.gg/wiki/Battle_Axe) |
| Chivalry 2 | Golpes para matar | **Inferência:** Vanguard (130) morre com 3 slashes (55) ou 2 heavy overheads (85); Knight (175) com 3 slashes (69) ou 2 heavy overheads (106). O Chivalry 2 mata em 2 a 3 golpes | conta minha sobre as duas linhas acima |
| Naraka | Armadura máxima por raridade | Common 600, Rare 900, Epic 1.200, Legendary 1.500, Extreme 1.800; cada segmento da barra = 300 | [Naraka, atualização 29/03/2024](https://www.narakathegame.com/news/update/20240329/33459_1146145.html) |
| Naraka | Dano da Longsword lendária | Horizontal 172; vertical 176; carregado horizontal 819; carregado vertical 713. O carregado dá ~4 a 5 vezes o normal | [zilliongamer (guia, sem data)](https://zilliongamer.com/naraka-bladepoint/c/weapon/naraka-bladepoint-longsword-stats-combos-souljades-skins-list) |
| Naraka | Vida base | Não achei fonte: **não confirmado** | — |
| Street Fighter 6 | Vida | 10.000 para quase todos; Zangief 11.000; E. Honda e Marisa 10.500 (jun/2023) | [EventHubs](https://eventhubs.com/news/2023/jun/07/everyone-sf6-stamina-three-exceptions) |
| Tekken 8 | Vida máxima | 180 no lançamento; 200 na 2.00.02 (17/04/2025); **190** na 3.02.01 (19/08/2026) | [Wavu Wiki, Patches (Tekken 8)](https://wavu.wiki/t/Patches_(Tekken_8)) (wiki de comunidade) |
| Smash Ultimate | Vida | Não tem vida: o dano em % aumenta o arremesso; morre quem cruza a blast line | [SmashWiki, Blast line](https://www.ssbwiki.com/Blast_line) |

**Leitura da tabela (inferência).** O For Honor, que é a nossa tribo, dá ao leve ~10–12% da vida e ao pesado ~20–25%. O Chivalry 2 é bem mais letal (2–3 golpes), e o Naraka vive de um carregado que vale 4–5 normais.

---

#### 2. Formato da partida: rounds, tempo, empate

| Jogo | Formato | Tempo do round | Tempo esgotado | Empate | Fonte |
|---|---|---|---|---|---|
| For Honor, Duelo | 5 rounds, vence quem ganha 3 | 5 min (Wikipedia). A partida personalizada oferece 1, 3 ou 10 min e melhor de 1, 3, 5, 9 ou 99 | Desde a v1.11 (10/08/2017): "Time out victory is awarded to the Player with the most HP remaining". Na mesma versão entrou o "Anti Run Away" (quem foge perde 20% de velocidade e tem a stamina drenada; quem persegue ganha 30%) | A wiki diz que morte simultânea é empate e que partida longa demais vira empate. Esta segunda parte é anterior à v1.11 e conflita com ela | [Wikipedia](https://en.wikipedia.org/wiki/For_Honor); [Ubisoft v1.11](https://www.ubisoft.com/en-us/game/for-honor/news-updates/6BLnxNeyg4hUICdMjgLjbm/for-honor-v111-patch-notes); [Wiki, Custom Match](https://forhonor.fandom.com/wiki/Custom_Match); [Wiki, Duel](https://forhonor.fandom.com/wiki/Duel) |
| For Honor, Duelo | Cada round começa num lugar diferente do mapa | — | — | — | [Wiki, Duel](https://forhonor.fandom.com/wiki/Duel) |
| Naraka, Bloodsport (1v1) | Torneio de 16 em duelos; finais em melhor de 3 | Tem limite, o valor não é dado ("75 s" aparece só num guia: **não confirmado**) | Desempate: 1) mais dano causado; 2) mais vida + armadura; 3) quem causou o primeiro dano; 4) sorteio | Sorteio, se ninguém causou dano | [Naraka, atualização 14/10/2021](https://narakathegame.com/news/update/20211013/33459_978559.html) |
| Naraka, Bloodsport | "Health, armor and skill cooldowns are reset after each round"; ultimates proibidas; resistências aumentadas | — | — | — | idem |
| Street Fighter 6 (torneio) | 2 de 3 rounds por jogo; 2 de 3 jogos (3 de 5 no top 3) | 99 s | Vence quem tem mais vida (regra da série) | Vida igual: o round vira empate (StrategyWiki da série); a regra exata do SF6 **não confirmada** | [start.gg, regras que citam o CPT 2024](https://www.start.gg/tournament/frag-fest-spring-2025/event/frag-fest-spring-2025-street-fighter-6-double-elimination/overview/rules) |
| Tekken 8 (torneio TWT) | 3 de 5 rounds | 60 s | "the character with more health will be declared the winner. If one does not exist, the round will be a draw"; morte simultânea é "Double K.O." | Round empatado | [start.gg, TWT Challenger](https://www.start.gg/tournament/first-attack-2025/event/tekken-8-twt-challenger-event/overview/rules); [StrategyWiki, Tekken/Gameplay](https://strategywiki.org/wiki/Tekken/Gameplay) |
| Smash Ultimate (torneio) | 3 stocks; melhor de 3 ou 5 | 6 a 8 min; o padrão listado é 7:00 | Vence quem tem mais stocks e, depois, menos % de dano | Stock e % iguais, ou os dois perdem o último stock juntos: desempate de 1 stock e 3 min | [SmashWiki, Tournament rulesets (SSBU)](https://www.ssbwiki.com/Tournament_rulesets_(SSBU)) |
| Smash Ultimate (casual) | Empate no tempo vira Sudden Death: 300% de dano em cada um, a tela fecha aos poucos e bombas caem 14 s depois | — | — | — | [SmashWiki, Sudden Death](https://www.ssbwiki.com/Sudden_Death) |
| Smash (geral) | Nos últimos 5 s, o locutor conta em voz alta e números grandes aparecem | — | — | — | [SmashWiki, Time out](https://www.ssbwiki.com/Time_out) |

**Transição entre rounds** (tempo de KO, contagem regressiva, reset): não achei nenhum número em fonte para For Honor, SF6 ou Tekken. **Não confirmado.** O único dado de reset é o do Naraka: vida, armadura e recargas voltam ao cheio.

---

#### 3. Cair para fora: abismos, death plane e fora do mapa

| Jogo / motor | Regra | Fonte |
|---|---|---|
| Unreal Engine | `KillZ`: "Any actor falling below this level gets destroyed"; `KillZDamageType` define o tipo de dano. É o death plane como configuração do mundo | [Epic, AWorldSettings](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/Engine/AWorldSettings) |
| Smash | A blast line fica "beyond the borders of the screen"; as linhas laterais e a de baixo matam; a de cima só mata com velocidade vertical suficiente | [SmashWiki, Blast line](https://www.ssbwiki.com/Blast_line) |
| For Honor (comunidade) | Espinhos e abismos matam na hora. No beta, em Duelo e Brawl, eram "just plain frustrating"; havia um código não escrito de não jogar o outro do penhasco "provided the match was even", e o autor se curvava e ia para uma área sem perigos | [Inverse](https://inverse.com/article/27133-for-honor-closed-beta-environment-hazards) |
| For Honor (wiki) | "Players who are not aware of their environment can find themselves [...] thrown from a cliff or wall, skewered on spikes or shoved into a fire" | [Wiki, Duel](https://forhonor.fandom.com/wiki/Duel) |
| Overwatch | Environmental kill: o herói cai do mapa depois de um controle de grupo; o crédito vai só para o último controle aplicado; conta como dano igual à vida restante | [Overwatch Wiki, Environmental kill](https://overwatch.fandom.com/wiki/Environmental_kill) (wiki de comunidade) |
| Apex Legends | Fora dos limites por mais de 15 s: morte instantânea. Em 06/10/2020 o cronômetro deixou de reiniciar a cada área nova, passou a 30 s fixos e só se renova até 5 s | [Apex Wiki, Battle Royale](https://apexlegends.fandom.com/wiki/Battle_Royale); [Apex Wiki, patch 06/10/2020](https://apexlegends.fandom.com/wiki/October_06,_2020_Patch) |
| Titanfall 2, Gauntlet | Curso de tutorial com meta de menos de 2 min; quem cai na grama "reset[s]" (trivia da wiki) | [Titanfall Wiki](https://titanfall.fandom.com/wiki/The_Pilot%27s_Gauntlet) |
| Celeste | A morte reinicia no começo da sala, sem tela de morte demorada (crítica). Na morte, o código chama `level.Shake()` e uma vibração leve | [Final Weapon](https://finalweapon.net/2026/08/15/celeste-and-a-lesson-in-making-difficulty-satisfying/); [Celeste, Player.cs](https://github.com/NoelFB/Celeste/blob/master/Source/Player/Player.cs) |
| Trackmania | O respawn volta ao último checkpoint (tecla Backspace por padrão; fórum de jogadores). Se o relógio continua: **não confirmado** | [Steam, TM² Canyon](https://steamcommunity.com/app/228760/discussions/2/2961642818658406421) |

---

#### 4. Hitstop: números e quem congela

| Jogo / fonte | Medida | Valor | Fonte |
|---|---|---|---|
| Smash Ultimate | Fórmula do hitlag (frames) | ⌊⌊⌊(d×0,65+6)×h×e×s⌋×p⌋×c⌋; d = dano em %. Um golpe de 15% dá **15 frames** (250 ms) | [SmashWiki, Hitlag](https://www.ssbwiki.com/Hitlag) |
| Smash Ultimate | Teto | 30 frames (500 ms) | idem |
| Smash Ultimate | No escudo (bloqueio) | s = 0,67× | idem |
| Smash Ultimate | Por número de jogadores | p: 1,0 com 2 jogadores … 0,862 com 4 … 0,75 com 8 (só quando o hitlag passa de 10 frames) | idem |
| Smash Ultimate | Quem congela | "experienced by both the attacker and victim". No **perfect shield** (o parry do Smash): "the attacker suffers from hitlag while the defender receives none" | idem |
| Smash Ultimate | Sem dano | "If the attack deals no damage, hitlag is always zero" | idem |
| Smash Ultimate (comparação) | Os mesmos 15% | 15 frames no Ultimate; 10 no Brawl e no Smash 4; 8 no Melee | idem |
| Sakurai (Famitsu, 2015) | Definição | "both parties momentarily freeze"; no Smash "both you and your opponent freeze for the exact same amount of time"; mais dano, mais hitstop; quem apanha treme (para os lados no chão, para cima e para baixo no ar) e o tremor diminui ao longo do congelamento; quem ataca também treme um pouco | [Source Gaming](https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/) |
| Jogos de luta em geral | Por força | "light attacks freeze around 9 frames, medium attacks around 11, hard attacks around 13" (150 / 183 / 217 ms); SF2 antigo: ~14 para todos; UMK3: zero | [Sonic Hurricane, Impact Freeze](https://sonichurricane.com/?p=1043) |
| Jogos de luta em geral | Acerto vs bloqueio, projétil | O mesmo congelamento no acerto e no bloqueio (pode variar por jogo); o projétil congela só a vítima, "around 12 frames" | idem |
| Jogos de luta em geral | Para que serve | "it stabilizes cancel timing": dá uma janela fixa de input. É **simulação** (dado de frame), não só efeito visual | idem |
| Street Fighter V | Por força | 8 / 12 / 15 (leve, médio, forte); o Ken tem 8 / 10 / 12. Só no resumo de busca do Shoryuken, porque a página não abriu: **não confirmado** | [Shoryuken, 2016](http://shoryuken.com/2016/06/07/hitstop-in-street-fighter-v-kens-not-so-little-secret/) |
| Street Fighter 6 | Pesado em pé (JP) | 13; 20 em Punish Counter. Só no resumo de busca, página com 403: **não confirmado** | [SuperCombo, JP/Data](https://wiki.supercombo.gg/w/Street_Fighter_6/JP/Data) |
| Tekken 8 | Golpes com Balcony Break | "Hitstop 20f on hit" (333 ms), como propriedade especial do golpe | [Wavu Wiki, Bryan movetable](https://wavu.wiki/t/Bryan_movetable) |
| Celeste | Freeze do dash | `Celeste.Freeze(.05f)` = **50 ms** (3 ticks); no lançamento por explosão, `.1f` = 100 ms | [Celeste, Player.cs](https://github.com/NoelFB/Celeste/blob/master/Source/Player/Player.cs) |
| Celeste | Tremor de câmera | `DirectionalShake(DashDir, .2f)` no dash especial; `.1f` em batidas na parede (o 2º argumento parece ser a duração em s: **inferência**) | idem |
| Monster Hunter Wilds | Great Sword (True Charged Slash) | "two-three freeze frames" (artigo de jogadores; sem tabela por arma) | [TheGamer](https://www.thegamer.com/monster-hunter-wilds-beta-hit-stop-missing/) |
| Vlambeer, "The art of screenshake" (INDIGO 2013) | Conteúdo | ~45 min, 30 ajustes num jogo de tiro lateral, como o tremor da tela no sentido contrário ao tiro. O item "sleep" (pausa ao acertar o inimigo) só aparece numa lista de tempos feita por usuário | [Game Developer](https://www.gamedeveloper.com/design/vlambeer-co-founder-shares-advice-on-building-better-action-games); [Internet Archive](https://archive.org/details/the-art-of-screenshake) |
| Jonasson e Purho, "Juice it or lose it" | Conteúdo | Um Breakout com tweening, esticar e espremer; "maximum output for minimum input". Sem números | [Game Developer, 2013](https://www.gamedeveloper.com/design/video-is-your-game-juicy-enough-) |
| Camera shake (Eiserloh, GDC 2016, modelo de "trauma") | Valores de quem implementou a palestra | O pacote npm usa ângulo máximo 10 e deslocamento 30 por padrão; o exemplo do Bevy usa 20 px, "low enough not to be distracting". Os números da palestra **não confirmados** | [npm screen-shake](https://www.npmjs.com/package/screen-shake); [Bevy](https://bevy.org/examples/camera/2d-screen-shake/) |

Dark Souls, Elden Ring e Hollow Knight: não achei número nem fonte de desenvolvedor sobre a pausa no acerto, só fóruns. **Não confirmado.**

---

#### Princípios e inferências

1. **O tempo esgotado decide pela vida, em todos.** For Honor (desde 2017), Tekken, a série Street Fighter e o Smash (stocks, depois %) dão o round a quem tem mais vida. O For Honor só mudou isso depois de ver jogadores com muita mobilidade fugindo até o relógio zerar, e no mesmo patch criou o anti-fuga. **Inferência:** com dash, gancho de 25 m e wall run numa arena de 80 × 80 m, fugir é ainda mais fácil para nós; precisamos da regra da vida no tempo esgotado desde o v0.
2. **O empate tem desempate determinístico antes de cair no sorteio.** O Naraka usa dano, depois vida, depois o primeiro golpe e só então sorteia. O Smash joga um round extra de 1 stock. **Inferência:** num 1v1 sem cura e com a mesma vida máxima, "mais dano causado" é igual a "mais vida restante"; o critério útil que sobra é **quem acertou primeiro**. Sorteio contraria a DEC-0004 (nada de aleatoriedade sem semente) e o sentimento de justiça.
3. **Na tribo, o leve vale ~1/10 da vida e o pesado ~1/4–1/5.** For Honor: 9–10 leves ou 5 pesados. O Chivalry 2 é mais letal (2–3 golpes), porque é batalha de 64 em que a morte é barata. **Inferência:** para um duelo de leitura, o For Honor é a régua certa: dá tempo de ler o adversário ao longo do round.
4. **No duelo, a morte pelo cenário é mal vista.** Jogadores do For Honor chamam de frustrante e criaram um código de não usar o abismo. **Inferência:** a arena de duelo v0 não deveria ter abismo; o death plane fica só como rede de segurança.
5. **O death plane é uma altura ou volume abaixo do nível** (KillZ no Unreal, blast line no Smash), e cruzar é morte imediata. Num modo de percurso a regra é outra: voltar ao checkpoint (Trackmania) ou ao começo da sala (Celeste). A punição é o tempo perdido, não a partida.
6. **O cronômetro de fora dos limites precisa resistir a abuso.** O Apex trocou o cronômetro que reiniciava a cada área nova por um fixo, porque os jogadores o exploravam.
7. **O hitstop dos jogos de luta é simulação e é simétrico.** Os dois congelam o mesmo tempo, então a vantagem de frames não muda (Sakurai; Sonic Hurricane). A exceção que nos interessa: no **perfect shield** do Smash, só o atacante congela. É um precedente direto para o nosso parry dar vantagem a quem aparou.
8. **O hitstop cresce com o dano, tem teto e diminui com mais jogadores.** O Smash usa base + 0,65 × dano, teto de 30 frames, 0,67× no escudo e 0,75× com 8 jogadores. **Inferência:** o Smash reduz o congelamento justamente quando há mais gente, como no nosso 4v4 e 8v8: dois lutadores travados no meio de outros ficam expostos.
9. **Os valores de luta 2D são altos para nós.** Leves de 8–9 frames (133–150 ms) seriam metade da preparação do nosso leve (300 ms). **Inferência:** um hitstop longo mudaria o ritmo que o estudo calculou e faria o golpe parecer "grudar". O Celeste mostra que 50 ms (3 ticks) já se sente.
10. **A rede pesa (inferência).** Pela F-053 e pela `rede.md`, o oponente não é previsto. Um hitstop na simulação que chega tarde vira uma correção (rollback) do tamanho do hitstop. Quanto mais curto, menor o "salto". Um hitstop só visual não mexe no core, mas descasa a animação da simulação: depois do congelamento a animação teria que pular para alcançar, e isso estraga a leitura do golpe (DEC-0014). O curto e simulado é o meio-termo.
11. **O tremor de câmera é apresentação, não simulação.** O Celeste usa 0,1–0,2 s. Implementações do modelo de trauma usam amplitudes "baixas o bastante para não distrair". **Inferência:** o tremor entra pela regra da DEC-0031 (toca uma vez por evento, nunca na re-simulação) e precisa de uma opção para desligar.

---

#### Recomendações para o v0

Todas são **recomendação**, para sentir jogando (DEC-0017). A conversão é 1 tick = 16,67 ms.

##### Vida e dano

| Item | Valor | Ticks | Por quê |
|---|---|---|---|
| Vida do lutador | **100** | — | Conta em %: 12 de dano = 12% da barra. É a mesma proporção do For Honor (130 de vida), sem os números quebrados |
| Leve | **12** | — | ~10–12% da vida, como o leve do For Honor (13–15 sobre 120–140). **9 leves** matam |
| Carregado | **30**, fixo de 500 a 900 ms | — | ~23–25% da vida, como o pesado do For Honor (26–30). **4 carregados** matam. Fixo porque, se a carga longa desse mais dano, todos segurariam até o fim, e o momento de soltar viraria previsível; a carga fica como arma de tempo (o mixup que o estudo quis). Alternativa: escalar de 25 a 35, se a carga longa precisar de recompensa |
| Quebra de guarda | **15** de dano direto, sem acompanhamento garantido | — | Fica entre o leve e o carregado. Não exige criar o estado "atordoado" nem combos no v0. Alternativa: 0 de dano e abrir um leve garantido (como no For Honor), o que pede uma janela de atordoamento ≥ 400 ms (24 ticks: 300 de preparação + 100 de ativo) |
| Resposta ao parry (riposte) | **20** de dano direto em quem foi aparado, no tick do contato | — | O parry ganha do carregado com lucro claro (20 de dano + o custo de stamina do atacante), mas vale menos que um carregado (30), para não virar jackpot. Dano direto é determinístico e fácil de testar |
| Golpe bloqueado | **0** de dano | — | O bloqueio já cobra 10 de stamina; dano que atravessa a defesa fica para depois |
| Combinação de referência | 2 carregados + 4 leves = 108 | — | Mostra que o round se decide em ~6 golpes certos |

##### Partida

| Item | Valor | Ticks | Por quê |
|---|---|---|---|
| Formato | **Vence quem ganha 3 rounds** (melhor de 5) | — | É o Duelo do For Honor, a tribo mais próxima. Alternativa mais curta: 2 de 3, como o SF6 e as finais do Naraka |
| Tempo do round | **90 s** | **5.400** | Fica entre o Tekken (60 s) e o SF6 (99 s), longe dos 5 min do For Honor. Com 9 leves e um ciclo de leve de 650 ms, matar leva no mínimo ~6 s. 90 s sobram para ler e tentar de novo, e são curtos o bastante para fugir com gancho e dash não compensar |
| Tempo esgotado | Vence quem tem **mais vida** | — | A regra de For Honor, Tekken, SF e Smash |
| Vida igual no tempo esgotado | Vence quem deu o **primeiro golpe**; se ninguém acertou, round **empatado, sem ponto para ninguém** | — | Critério 3 do Naraka, sem o sorteio (DEC-0004). Round vazio não premia ninguém |
| Morte dos dois no mesmo tick | Round **empatado, sem ponto** | — | É o Double KO do Tekken e a regra do Duelo do For Honor |
| Limite de rounds | **9**; depois disso, a partida é empate | — | Só para evitar uma partida sem fim de empates; não deve acontecer na prática |
| Anti-fuga | Fora do v0; a regra do tempo esgotado pela vida já pune a fuga | — | O For Honor precisou dela, mas só depois de jogo real. Entra na lista do protótipo |

##### Transição entre rounds

| Fase | ms | Ticks | Por quê |
|---|---|---|---|
| Hitstop do golpe que mata | 200 | **12** | O KO precisa pesar mais que qualquer golpe; fica abaixo do Balcony Break do Tekken (333 ms) |
| "Fim de round" | 2.000 | **120** | A simulação segue, mas os inputs são ignorados. Dá tempo de ver o KO e de o som tocar; impede bater no corpo |
| Reset | 0 | **0** | Teleporte para os pontos de início **alternando os lados** a cada round (o For Honor muda o lugar a cada round). Vida 100, stamina 100 e recargas zeradas, como o Naraka |
| Contagem regressiva | 3.000 | **180** | "3, 2, 1, lutem", com inputs travados e câmera livre. Duração sem precedente com número em fonte; é convenção |
| Total entre rounds | ~5.200 | ~312 | Curto o bastante para manter o ritmo |

##### Death plane e fora dos limites

| Item | Duelo | Contra o relógio (time trial) | Por quê |
|---|---|---|---|
| Arena | Sem abismo no v0, parede em volta | Pode ter vãos | A comunidade do For Honor rejeita a morte pelo cenário no duelo |
| Death plane | Volume a **5 m abaixo** do piso mais baixo | Idem | Com a gravidade padrão do Godot (9,8 m/s², **inferência**: não sei se a nossa é essa), 5 m de queda livre levam ~1,0 s (60 ticks). É curto para o jogador não "cair para sempre" e longo para não matar quem só tropeçou numa borda |
| Ao cruzar | **KO imediato**; o ponto vai para o oponente; se os dois cruzarem no mesmo tick, empate | **Volta ao último checkpoint** após 500 ms (**30 ticks**), velocidade zerada, **relógio correndo** | O duelo segue a blast line do Smash e o KillZ do Unreal. O time trial segue o Trackmania e o Celeste: a punição é o tempo perdido. Os 500 ms dão um respiro para entender o que aconteceu, sem a tela de morte longa que o Celeste evita |
| Crédito (4v4, depois) | Para o último que acertou ou empurrou nos últimos 3 s | — | É a ideia do environmental kill do Overwatch. Os 3 s são **recomendação**, sem fonte |
| Fora dos limites (por cima do muro) | 3 s de aviso e depois KO; o cronômetro **não** reinicia ao reentrar | Volta ao checkpoint | É a lição do Apex (cronômetro fixo). 3 s porque a arena é pequena (80 m); o Apex usa 15–30 s num mapa de km |

##### Hitstop (na simulação, curto, com teto)

Fórmula sugerida, no espírito do Smash e escalada para baixo: **ticks = 2 + ⌊dano / 6⌋**, com teto de 8 ticks para golpes comuns; no bloqueio, ⌊× 0,67⌋ (o fator do escudo do Smash).

| Evento | Quem congela | ms | Ticks | Por quê |
|---|---|---|---|---|
| Leve acerta (12) | Os dois | 67 | **4** | Sente-se (o Celeste usa 3 ticks) e não quebra o ritmo de 300 ms. É ~1/3 do leve de luta 2D (9 frames), pelos motivos dos princípios 8 a 10 |
| Carregado acerta (30) | Os dois | 117 | **7** | Quase o dobro do leve: o pesado precisa "doer" mais (Sakurai: mais dano, mais hitstop) |
| Quebra de guarda (15) | Os dois | 67 | **4** | Mesmo peso do leve |
| Leve bloqueado | Os dois | 33 | **2** | 0,67 × 4. O clang do bloqueio precisa existir, mas menor que o acerto |
| Carregado bloqueado | Os dois | 67 | **4** | 0,67 × 7 = 4,7 → 4 |
| Parry com sucesso | **Só o atacante** | 150 | **9** | Precedente do perfect shield do Smash: o aparado congela e quem aparou fica livre. É o momento mais forte do combate; casa com o "clang" mais alto do jogo (F-053 §4) |
| Riposte (20) | Os dois | 83 | **5** | Pela fórmula |
| Golpe que mata (KO) | Os dois | 200 | **12** | Fixo; marca o fim do round |
| 4v4 e 8v8 (depois) | — | — | × 0,75 | O fator do Smash com 8 jogadores, para não deixar dois lutadores travados no meio da briga |

Regras que acompanham:
- O hitstop **pausa o relógio do golpe** (preparação, ativo e recuperação) dos dois lutadores, como nos jogos de luta. Assim a vantagem de frames do estudo não muda.
- Ele **não** pausa o relógio do round nem os outros lutadores.
- No core, é um campo "congelado até o tick T" no estado.
- **Teste de rollback:** um acerto confirmado tarde não pode "dobrar" o hitstop.

##### Tremor de câmera (apresentação, fora do core)

| Evento | Duração | Ticks | Rotação máx. | Em quem |
|---|---|---|---|---|
| Leve recebido | 100 ms | 6 | 0,5° | Câmera de quem apanhou |
| Carregado recebido | 200 ms | 12 | 1,5° | Quem apanhou; metade em quem bateu |
| Bloqueio | 100 ms | 6 | 0,3° | Quem bloqueou |
| Parry | 150 ms | 9 | 1,0° | Os dois |
| KO | 300 ms | 18 | 2,0° | Os dois |

- **Por quê:** as durações seguem o Celeste (0,1–0,2 s).
- **Amplitudes:** pequenas, porque em terceira pessoa a câmera também é a mira do arco e das armas, e um tremor grande atrapalha a leitura (DEC-0014). Os graus são **chute inicial**, sem fonte, para ajustar jogando.
- **Modelo:** decaimento por "trauma²", a forma usada pelas implementações da palestra de Eiserloh.
- **Execução:** toca uma vez por evento (DEC-0031).
- **Opção para desligar:** necessária.

---

#### O que não confirmei

- **For Honor:**
  - O tempo do round do Duelo hoje (Wikipedia diz 5 min; a partida personalizada oferece 1/3/10).
  - A regra de empate atual. A wiki diz que partida longa vira empate, o patch 1.11 diz que vence a vida maior.
  - O tempo entre rounds e a contagem regressiva.
  - A faixa completa de dano de todos os heróis (vi só exemplos do patch 2.40.0).
  - O acompanhamento garantido da quebra de guarda.
- **Chivalry 2:**
  - A vida do Footman (150), só em busca.
  - A tabela do Battle Axe veio embaralhada na extração.
  - Convenções de servidor de duelo (reverência, ninguém se meter): não achei fonte; só o mapa "Duelyard", em resumo de busca.
- **Naraka:**
  - Vida base.
  - Duração do round do Bloodsport (75 s só num guia).
  - Os números da Longsword vêm de um guia sem data.
- **Street Fighter 6:**
  - Hitstop por força (SuperCombo deu 403).
  - A regra exata de empate por vida igual.
  - Os 8/12/15 do SFV (a página do Shoryuken não renderiza sem JavaScript).
- **Tekken 8:** formato e tempo da partida ranqueada; hitstop comum.
- **Monster Hunter:** hitstop por arma em frames.
- **Dark Souls, Elden Ring e Hollow Knight:** a pausa no acerto.
- **Palestras:**
  - Vlambeer: o item "sleep" e o tempo dele vêm de lista de usuário.
  - "Juice it or lose it": a fonte diz GDC Europe 2013, outras dizem 2012.
  - Eiserloh: os valores exatos.
  - Sakurai: o episódio do YouTube sobre hitstop (só li a coluna da Famitsu, via Source Gaming).
- **Fora dos limites e respawn:**
  - Apex: os 5 s nas Arenas (a página deu 403).
  - Titanfall 2: o cronômetro fora dos limites.
  - Mirror's Edge: o que acontece ao cair num time trial.
  - Trackmania: se o relógio continua após o respawn.
  - Celeste: a duração exata da morte até o respawn.
- **Overwatch:** a regra oficial de crédito (só wiki de comunidade).
- **Nossas recomendações:**
  - Gravidade do nosso jogo: assumi 9,8 m/s² na conta da queda de 5 m.
  - Graus do tremor de câmera, 3 s de crédito e 3 s de contagem: sem precedente numérico em fonte.

## §3 — O bot, o percurso e o log de crash, como chegou

#### Pesquisa r3: o bot que reage como gente, o percurso com fantasma e o log de queda no Godot 4.7

Data: 27/10/2026. Isto é pesquisa, não decisão. **Fato** = li na fonte (link). **Inferência** = conclusão minha. **Recomendação** = proposta para o v0, a decidir com Arthur. "**não confirmado**" = não consegui abrir a fonte primária (a seção final lista cada caso). Os rótulos [bot:Cxx] ligam a linha à lista de afirmações. Não repito a pesquisa de cores, tempos de reação e som da F-053.

#### Termos

- **Fantasma (ghost):** uma cópia translúcida da sua melhor corrida, que corre ao lado de você. Como o "fantasma" do Mario Kart.
- **Checkpoint:** um volume (esfera ou caixa) no mapa. Cruzar o volume grava "passei aqui" e o tempo parcial. É o save de um jogo de plataforma.
- **Trigger volume:** o volume do checkpoint, que reage a quem entra.
- **Reação de escolha:** reagir quando há mais de uma resposta possível (aparar, bloquear ou esquivar). É mais lenta que a reação simples (F-053 §2.3).
- **Atraso de percepção:** o tempo entre o evento existir no jogo e o bot "enxergar" o evento. É a única coisa que faz o bot parecer humano.
- **Árvore de comportamento (BT):** a decisão do bot como uma árvore de condições e ações, lida a cada tick. Parecido com um `if/else` encadeado organizado em blocos.
- **Seletor / sequência:** o seletor tenta os filhos até um dar certo ("ou"). A sequência roda os filhos até um falhar ("e").
- **Minidump:** arquivo com a memória e a pilha no instante da queda. É o que o Sentry recebe.

#### 1. Percursos cronometrados e fantasmas: o que cada jogo faz

| Jogo | O que a fonte diz | Tipo | Fonte |
|---|---|---|---|
| Titanfall 2, Gauntlet | Alvos inimigos aparecem no percurso; deixar de matar um soma penalidade de tempo. [bot:C01] | Fato (wiki de fãs) | https://titanfall.wiki.gg/wiki/The_Pilot's_Gauntlet |
| Titanfall 2, Gauntlet | O tempo é comparado ao "ghost recorder time" de um piloto do jogo (a conquista "The Student..."). As fontes divergem sobre quem: a wiki cita Capitão Lastimosa; guias citam Anderson com 56,65 s. [bot:C02] | Fato com divergência | https://titanfall.wiki.gg/wiki/The_Pilot's_Gauntlet ; https://www.trueachievements.com/a225198/the-student-achievement |
| Titanfall 2, Gauntlet | Passar pelo ponto de partida em alta velocidade pode fazer a corrida não registrar como iniciada; o fim fica num vazio e é preciso voltar ao início ou ao "latest checkpoint". Mostra que o início é um gatilho por cruzamento, e que a posição entre dois frames pode furá-lo. [bot:C03] | Fato (wiki) e inferência | https://titanfall.wiki.gg/wiki/The_Pilot's_Gauntlet |
| Titanfall 2, Gauntlet | Penalidade de 2 s por alvo vivo e alvo "de 15 inimigos": só aparece em resumo de busca, sem página aberta. | **não confirmado** | https://www.cheatcc.com/?p=87121 |
| Titanfall 2, Gauntlet | A página não diz o que acontece ao cair ou sair do percurso. | Fato (ausência) | https://titanfall.wiki.gg/wiki/The_Pilot's_Gauntlet |
| Mirror's Edge, Time Trial | Cada fase tem checkpoints que devem ser cruzados em ordem (quatro a cinco, em geral), e tempos de aprovação dão 1, 2 ou 3 estrelas; o jogo mostra o tempo em cada checkpoint. Exemplo: "Edge" 1:10,00 / 0:55,00 / 0:47,00. [bot:C04] | Fato só em resumo de busca; guia de fãs | https://www.trueachievements.com/game/Mirrors-Edge/walkthrough/4 |
| Neon White | Medalhas Bronze, Prata, Ouro e Ace por tempo; a medalha prata libera o seu fantasma; reiniciar é um botão. [bot:C05] | Fato só em resumo de busca | https://en.wikipedia.org/wiki/Neon_White |
| Celeste | Morrer reinicia a tela na hora, sem punição. | Só resumo de busca | https://cyberpost.co/?p=1195610 |
| Trackmania | Os replays gravam **inputs** para reproduzir 1:1 ("TrackMania, Doom and N use size-efficient replay files that record inputs"). [bot:C06] | Fato | https://en.wikipedia.org/wiki/Game_replay |
| Trackmania | Pode-se reaparecer (respawn) depois de cruzar um checkpoint; o changelog de 2020 diz que reaparecer num checkpoint mostra o fantasma do melhor tempo naquele checkpoint. [bot:C07] | Fato de segunda mão | https://devtrackers.gg/trackmania/p/76400859-23-07-2020-new-update-and-changelog |
| Trackmania | Medalhas bronze, prata, ouro e autor guardadas em milissegundos. | Fato (biblioteca de terceiros) | https://py-trackmaniaio.readthedocs.io/en/stable/trackmania.tmmap.html |

**Fantasma por posição ou por input.** A técnica de input (guardar só os botões e rodar de novo a simulação) ocupa pouco, mas só reproduz se a simulação for idêntica. Um guia recomenda carimbar cada replay com a versão da simulação e recusar a reprodução se não bater. Não consegui abrir esse texto (**não confirmado**). A técnica de posição (guardar a posição a cada tick de física) não depende da simulação, mas o fantasma pode ficar errado se o mapa mudar; um desenvolvedor Godot descreve gravar posições com um carimbo que avança com o delta de física (https://troystorygames.itch.io/messenger-mouse/devlog/945109/record-and-replay-ghost-races). **Inferência:** nosso núcleo (`core/`) é puro e em ticks inteiros (DEC-0004), então um replay de input seria reproduzível na mesma build; mas qualquer ajuste de número do combate ou do movimento invalida todos os fantasmas guardados.

**Checkpoint ordenado ou livre.** Mirror's Edge exige ordem (fonte acima). Não achei fonte aberta que descreva a regra de ordem ou a punição por pular checkpoint no Trackmania (**não confirmado**). **Inferência:** a ordem fixa é a regra mais simples de testar, e um fantasma só faz sentido se todos passam pelos mesmos pontos.

#### 2. Bots que reagem como pessoas

| Item | O que a fonte diz | Fonte |
|---|---|---|
| FightingICE / DareFightingICE | A informação mandada à IA tem atraso de 15 frames (a 60 fps, 250 ms), para "simular o atraso de reação de jogadores humanos" e dar mais risco à defesa. IAs visuais podem fugir do atraso. Li esta regra só no trecho de busca da página oficial, que não abriu (conexão recusada). [bot:C08] | https://ice.ci.ritsumei.ac.jp/~ftgaic/index-3.html |
| IA de luta com RL (artigo) | Adicionou atraso fixo médio de ~230 ms às decisões para a IA não ter vantagem; o número vem do resumo de busca. [bot:C09] | https://arxiv.org/pdf/1904.03821 |
| OpenAI Five (Dota 2) | A IA reage com tempo "aleatoriamente distribuído entre 5 e 8 frames (167 a 267 ms)"; os autores citam 250 ms como a reação humana medida em laboratório. Pelo resumo de busca; o PDF não abriu como texto. [bot:C10] | https://arxiv.org/pdf/1912.06680 |
| Atraso com cauda | Um preprint de 2026 modela os atrasos com uma gaussiana exponencialmente modificada (ex-Gaussian) por causa da assimetria dos tempos humanos, com 140 a 190 ms somados. Preprint, resumo de busca. | https://arxiv.org/html/2610.31726 |
| For Honor, bots | A palestra da GDC "Streamlining Bot Development in For Honor" descreve bots treinados com aprendizado por reforço e auto-jogo, um sistema de máscara de ações para os designers ajustarem a dificuldade, e lógica roteirizada como árvores de comportamento. Só o resumo de busca; a página redirecionou para manutenção. [bot:C11] | https://gdcvault.com/play/1035522/Streamlining-Bot-Development-in-For |
| For Honor, nível dos bots | Jogadores dizem que o nível 3 "parry god" reage a qualquer bash e tem mais vida e dano; um jogador acha que o bot responde ao seu input. Opinião de fórum, não documentado. | https://devtrackers.gg/for-honor/p/2613d599-pvp-level-3-bots |
| Tekken 8, Ghost Battle | O Super Ghost é feito do estilo de luta de um jogador, fica mais preciso quanto mais ele luta, e copia "comportamento e manias". Dados de partidas online e do Arcade Quest alimentam os fantasmas; o texto não fala de níveis de dificuldade. [bot:C12] | https://en.bandainamcoent.eu/tekken/news/tekken-8-discover-about-super-ghost-battles |
| Killer Instinct, Shadows | O shadow é montado a partir de treino do jogador; um comentário diz que não é aprendizado de máquina puro, e que boa parte da estrutura e dos ajustes foi feita à mão. Só resumo de busca. | https://gamedeveloper.com/programming/the-killer-groove-the-shadow-ai-of-killer-instinct |
| Street Fighter 6, CPU | Nenhum resultado útil. | **não confirmado** |

**Princípios e inferências (bot).**

- **Inferência:** as três alavancas que aparecem nas fontes são o atraso de percepção, a taxa de erro (acertos propositais errados) e o peso das opções. As fontes de IA de luta (FightingICE, o artigo do RL) controlam a justiça pelo atraso de percepção, não por esconder informação do bot.
- **Inferência:** trapacear lendo o que o jogador não vê (o input do botão, o instante sorteado da carga) é a crítica ao For Honor, mas ela vem de opinião de fórum. Para a nossa regra "bot só produz input" (DEC-0022), basta o bot ler o mesmo estado público que o jogador vê.
- **Inferência:** um atraso fixo fica previsível, e o jogador aprende a explorá-lo. A distribuição do OpenAI Five (5 a 8 frames) e a ex-Gaussian mostram atraso sorteado por evento.
- **Inferência:** o atraso tem de ser sorteado **uma vez por evento** (quando o golpe do oponente entra na preparação), não a cada tick. Sorteando a cada tick, o bot tenderia ao menor valor sorteado.

#### 3. Árvore de comportamento em GDScript puro, em simulação por ticks

- **Fato:** o Godot diz que o algoritmo do `RandomNumberGenerator` é "um detalhe de implementação e não deve ser usado como base"; hoje usa PCG32; uma semente dada dá "uma sequência reproduzível". A semente não tem efeito avalanche (sementes parecidas dão fluxos parecidos). Não se deve definir `state` com valores arbitrários. [bot:C13] [bot:C14] https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html
- **Inferência:** esse aviso é uma razão para o bot não depender do `RandomNumberGenerator` se queremos testes que valham entre versões do Godot. Uma função de hash inteira simples, chamada com (semente da partida, id do bot, tick, contador de sorteio) devolve um inteiro sem estado nenhum, o que cabe na regra de núcleo puro (DEC-0004) e é trivial de testar. Só recomendo; não testei.
- **Fato:** LimboAI é MIT, cobre Godot 4.6 e 4.7 (como módulo; é preciso compilar o Godot) e o README não diz se é determinístico; sem preço, aceita doação. [bot:C15] https://github.com/limbonaut/limboai
- **Fato:** Beehave é MIT, Godot 4.5+ (versões 2.10+), árvore montada em nós da cena. [bot:C16] https://github.com/bitbrain/beehave
- **Inferência:** a árvore de nós dessas duas é feita de nós da cena, e a nossa DEC-0004 quer o núcleo sem nós. Uma árvore de comportamento mínima, em dados, cabe em poucas dezenas de linhas de GDScript tipado: um nó é um objeto com `tick(state, memory) -> Status` (SUCCESS, FAILURE, RUNNING), a sequência falha no primeiro filho que falha, o seletor acaba no primeiro que dá certo. Não achei fonte que prove isso; é conhecimento geral, **não confirmado** por fonte. A memória do bot (tick de início do atraso, golpe visto) ficaria em dados planos.
- **Recomendação:** nenhum addon para o v0 (coerente com "nenhuma dependência sem ok", AGENTS.md). Se um dia a árvore crescer a ponto de pedir editor visual, LimboAI (MIT, grátis) é a opção a estudar.

#### 4. Log de queda no cliente Windows exportado

| Item | Valor / comportamento | Fonte |
|---|---|---|
| `debug/file_logging/enable_file_logging` | padrão `false` [bot:C17] | https://docs.godotengine.org/en/stable/classes/class_projectsettings.html |
| `debug/file_logging/enable_file_logging.pc` | padrão `true` (o override para desktop) | idem |
| `debug/file_logging/log_path` | padrão `"user://logs/godot.log"` | idem |
| `debug/file_logging/max_log_files` | padrão `5`; a cada sessão nasce um arquivo novo e o antigo é renomeado com a data de rotação [bot:C18] | https://docs.godotengine.org/en/stable/tutorials/scripting/logging.html |
| `user://` no Windows | `%APPDATA%\Godot\app_userdata\[nome_do_projeto]`; com `application/config/use_custom_user_dir` o caminho vira `%APPDATA%\[nome_do_projeto]` [bot:C19] | https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html |
| `print()` em build release | "A saída padrão só é descarregada quando o projeto sai ou cai"; o erro padrão (stderr) é descarregado a cada impressão; `application/run/flush_stdout_on_print` (padrão `false`) muda isso [bot:C20] | https://docs.godotengine.org/en/stable/tutorials/scripting/logging.html |
| Erro de GDScript em release | Backtraces vêm desligados por padrão, por desempenho; `debug/settings/gdscript/always_track_call_stacks` (padrão `false`) liga. Desde o Godot 4.5, um erro de GDScript registra um backtrace até a origem [bot:C21] | https://docs.godotengine.org/en/4.6/tutorials/scripting/logging.html |
| Queda do motor | O backtrace de queda sai no stderr e no mesmo arquivo de log ("Program crashed with signal"). Só é útil se o binário tiver símbolos de depuração, e os binários oficiais não têm [bot:C22] | https://docs.godotengine.org/en/stable/tutorials/scripting/logging.html |
| Tratador de queda no Windows | `platform/windows/crash_handler_windows_signal.cpp` existe no master, usa libbacktrace e DbgHelp e imprime "Dumping the backtrace." com uma mensagem tirada de `debug/settings/crash_handler/message`. Li o master, não a tag 4.7.x [bot:C23] | https://github.com/godotengine/godot/blob/master/platform/windows/crash_handler_windows_signal.cpp |
| `--verbose` | Liga a saída verbosa e as chamadas `print_verbose()`; também existem `--quiet` e `--print-fps` | https://docs.godotengine.org/en/stable/tutorials/scripting/logging.html |

**Inferência:** um erro de GDScript no exportado (o caso mais provável de bug em teste) só tem pilha legível se ligarmos `always_track_call_stacks`, que custa desempenho (medir no PC mínimo antes de manter ligado). Uma queda nativa (rara) em template oficial deve dar só endereços sem nomes; se o tratador do Windows imprime algo no template oficial 4.7 sem símbolos, não verifiquei (**não confirmado**).

**sentry-godot (só para a fase 3; NÃO entra agora).** MIT; é uma GDExtension em C++ sobre o sentry-native; exige Godot 4.5+ nas séries 1.x e 2.x (0.x pedia 4.3+); Windows x86_64 coberto. [bot:C24] https://github.com/getsentry/sentry-godot . Queda nativa no Windows e Linux sai como minidump via Native SDK; para nomes de função e linhas é preciso exportar com templates que tenham símbolos de depuração e subir os símbolos ao Sentry, porque "os builds oficiais só dão templates sem informação de depuração" [bot:C25] https://docs.sentry.io/platforms/godot . Preço e plano grátis do serviço: a página não diz (**não confirmado**).

#### Princípios e inferências (síntese)

1. **Fato:** todos os percursos cronometrados lidos têm checkpoints em ordem, tempos de referência (estrelas ou medalhas) e um jeito rápido de recomeçar. **Inferência:** o que dá "só mais uma tentativa" é o recomeço instantâneo, não o checkpoint.
2. **Inferência:** o fantasma serve a quem treina contra o próprio tempo; o fantasma de posição é o mais robusto a mudanças de número, enquanto o de input é mais barato e exato, mas morre a cada patch.
3. **Inferência:** o bot parece humano pela soma de três coisas: atraso sorteado por evento, erro proposital e a restrição de ver só o que o jogador vê. O atraso não pode ser menor que o do jogador mais rápido que o jogo foi desenhado para suportar (F-053: 213 a 273 ms).
4. **Inferência:** reaction de escolha é o que o bot deve imitar na defesa. O leve de 300 ms (18 ticks) não é reagível por pessoas (F-053 §2.4); então um bot nível 3 só deve aparar o leve **por leitura** (palpite), não por reação, senão ele quebra o triângulo que queremos manter.

#### Recomendações para o v0

Tudo **Recomendação**, a decidir com Arthur; os números de bot e de percurso são palpites meus, nenhum veio de fonte, e se julgam jogando (DEC-0017). Ticks a 60 por segundo (1 tick = 16,7 ms).

**Percurso cronometrado**

| Item | Proposta | Por quê |
|---|---|---|
| Estrutura | 1 portão de partida, 6 checkpoints em ordem fixa, 1 portão de chegada, dentro da arena de 80 x 80 m, usando parede, pulo duplo, dash e gancho | Mirror's Edge usa 4 a 5 checkpoints por fase; 6 cobre as 5 habilidades de movimento sem ser longo |
| O que cruza um checkpoint | Teste de segmento entre a posição do tick anterior e a do tick atual contra o volume (esfera de ~3 m); regra no `core/` | Em 7 m/s o personagem anda 0,12 m por tick; no dash de 4 m em 200 ms (12 ticks), 0,33 m por tick; o gancho de 25 m é mais rápido. Testar só a posição do tick pode furar o volume, como o bug do portão de partida do Gauntlet (C03) |
| Ordem | Fixa. Cruzar o 4 antes do 3 não conta | Mais simples de testar, e o fantasma passa pelos mesmos pontos |
| Cronômetro | Começa ao cruzar o portão de partida; para ao cruzar o de chegada com todos os checkpoints. Guardado em ticks inteiros (60 ticks = 1 s) | Núcleo puro, sem relógio (DEC-0004) |
| Queda | Cair abaixo do chão ou sair da arena reaparece no último checkpoint, **o tempo continua correndo** (a punição é o tempo perdido). Um botão de recomeço total reinicia na hora, sem tela de carregamento | Mantém o fluxo do Celeste e do Neon White, e a queda custa tempo sem travar |
| Medalhas | Bronze, prata e ouro por tempo de referência, definidos depois que Arthur correr o percurso | Não invento números; o tempo do ouro sai do tempo que ele marcar |
| Fantasma | Gravar a posição, a rotação e o modo do personagem uma vez por tick, só da melhor corrida; desenhar uma cópia translúcida sem colisão. Guardar junto o número da versão e descartar o fantasma se a versão mudar | Posição não depende de a simulação ser idêntica. 60 ticks x 60 s x ~20 bytes (3 floats, 1 rotação e 1 modo) = ~72 KB por minuto (conta minha) |

**Bot**

| Item | Proposta (ms / ticks) | Por quê |
|---|---|---|
| Média da reação | Nível 3: 260 ms / 16 ticks; desvio 40 ms / 2 ticks; mínimo 180 ms / 11 ticks | Cai dentro dos 213 a 273 ms medidos (F-053), perto do 250 ms do OpenAI Five e do 230 ms do artigo de luta (C09, C10); o chão evita um bot mais rápido que qualquer pessoa |
| Níveis | N1: média 450 ms (27 ticks), desvio 90, erro 30%. N2: 330 ms (20), desvio 60, erro 15%. N3: 260 ms (16), desvio 40, erro 5% | Níveis só por atraso e erro, sem trapaça. Os valores de N1 e N2 são só um degrau para ele sentir; nenhuma fonte dá esses |
| Quando sorteia | Uma vez por evento: o golpe do oponente entra na preparação e o bot guarda o tick de reação = tick do evento + atraso sorteado | Evita o viés do menor valor (princípio acima) |
| O que lê | O estado público: modo e posição do oponente, tick em que o modo começou, direção. Não lê o botão apertado, nem o instante sorteado de soltar a carga, nem a vida de quem está fora de vista | O mesmo que o jogador vê; o carregado sorteado deu 0 parries em 21 em Arthur porque o instante era desconhecido, então o bot também não pode saber |
| Erro | Com a taxa do nível, ignora o golpe (não reage) ou escolhe a resposta errada | Erro de escolha é o que o jogador faz sob pressão |
| Opções | Pesos por situação: bloquear, aparar, esquivar, contra-atacar; o nível 3 só apara leves por palpite com peso baixo | Preserva o triângulo carregado > leve, parry > carregado, leve > parry |
| Aleatoriedade | Hash inteiro de (semente da partida, id do bot, tick, contador) em vez de `RandomNumberGenerator` | Núcleo puro e testável; o Godot não promete a mesma sequência entre versões |
| Estrutura | Árvore de comportamento mínima em GDScript tipado: seletor e sequência, condições, ações; saída = o próximo input | Sem addon (DEC-0022); cabe em poucas dezenas de linhas |

**Log de queda (Godot 4.7, cliente Windows exportado)**

| Ajuste | Valor | Documentação |
|---|---|---|
| `debug/file_logging/enable_file_logging` | `true` (explícito, mesmo que o `.pc` já seja `true`) | https://docs.godotengine.org/en/stable/classes/class_projectsettings.html |
| `debug/file_logging/enable_file_logging.pc` | `true` | idem |
| `debug/file_logging/log_path` | manter `user://logs/godot.log` | idem |
| `debug/file_logging/max_log_files` | `10` (o padrão é 5) | https://docs.godotengine.org/en/stable/tutorials/scripting/logging.html |
| `application/run/flush_stdout_on_print` | `true`, para a saída aparecer no arquivo mesmo antes da queda | idem |
| `debug/settings/gdscript/always_track_call_stacks` | `true`, medir o custo no PC mínimo | https://docs.godotengine.org/en/4.6/tutorials/scripting/logging.html |
| `debug/settings/crash_handler/message` | texto com o pedido ao testador ("envie o godot.log desta pasta...") | https://github.com/godotengine/godot/blob/master/platform/windows/crash_handler_windows_signal.cpp |
| Primeira linha do log | imprimir a versão (`application/config/version`) e o commit logo ao iniciar | decisão nossa |

Cada ajuste está em `project.godot`; AGENTS.md pede dizer qual e por quê, e o `test/project_settings_test.gd` guarda os decididos.

**Passos do testador (Windows)**

1. Jogar normalmente. Se o jogo fechar ou der erro, **não abrir o jogo de novo** antes de copiar o log (cada sessão nova renomeia o log anterior com a data; ele não some, mas fica com outro nome).
2. Apertar Win+R, colar `%APPDATA%\Godot\app_userdata\<nome do projeto>\logs` e dar Enter.
3. Copiar o `godot.log` mais recente (ou o arquivo `godotAAAA-MM-DD...` se já reabriu o jogo) e mandar a Arthur, dizendo o que estava fazendo.
4. (Opcional, para detalhe) abrir o jogo com `--verbose` no atalho e repetir.

#### O que não confirmei

- A regra dos 15 frames do FightingICE: li só o trecho de busca da página oficial (a página recusou a conexão) e o PDF do artigo não abriu como texto. A frase "simular o atraso de reação" vem do resumo de busca.
- O 230 ms médio do artigo de RL de luta (arXiv 1904.03821) e os 167 a 267 ms do OpenAI Five: vêm de resumos de busca; os PDFs não abriram como texto.
- O preprint de 140 a 190 ms (ex-Gaussian) tem número de arXiv que não pude abrir; trate como indício.
- A palestra de For Honor na GDC: só o resumo de busca; a página redirecionou para manutenção. Nenhuma fonte primária descreve o que fazem os níveis 1, 2 e 3 do For Honor.
- Street Fighter 6 CPU: nada encontrado. Killer Instinct Shadows: só resumo de busca da GDC e da Game Developer.
- Mirror's Edge (checkpoints em ordem, estrelas), Neon White (medalhas, fantasma) e Celeste (reinício instantâneo): só resumos de busca, a página do TrueAchievements deu 403.
- Titanfall 2: o início e o fim do cronômetro, a penalidade exata por alvo, e a regra de queda ou saída do percurso. O que existe vem de wikis de fãs.
- Trackmania: regra oficial de checkpoint ordenado, respawn e punição por pular. Só achei changelog repassado por tracker de comunidade.
- Guia sobre carimbar a versão do replay (bugnet.io): a página abriu sem o texto do artigo.
- Beehave e LimboAI: nenhuma das duas diz ser determinística; a árvore em GDScript puro vem de conhecimento geral, sem fonte aberta.
- O tratador de queda do Windows no template oficial 4.7 (se imprime backtrace sem símbolos e se o template oficial é MinGW): li o arquivo do master, não a tag 4.7.x; o relato antigo (issue 42540, Godot 3.2.3) dizia que o tratador era desligado em builds MinGW, sem confirmação para hoje.
- Preço e plano grátis do Sentry, e a licença do serviço (só do SDK).

## §4 — Os resumos e o que não foi confirmado, pelos agentes

### Resumo — O tranco e a vantagem

Relatório de 27 KB em PT-BR. For Honor (Info Hub): parry 200 ms, de 300 a 100 ms antes do contato; leve aparado fica 900 ms em stagger, pesado 600; GB de 400 ms com contra-GB em 300 ms depois do contato; stun da GB 800 ms; tabela completa de hit/block stun. Chivalry 2 (Polehammer): holding de 350 ms mais windup/release/recuperação. Naraka: armadura durante toda a carga. Sekiro: deflect de 12 frames. Tekken: −10 é castigável; um acerto por janela ativa. Achado central: no nosso jogo o bloqueio leva 100 ms para subir, então 'seguro' é desvantagem menor que 12 ticks (200 ms), não 18. Recomendações v0: hitstun do leve 400 ms/24 ticks (+3); blockstun do leve 250/15 (−6); hitstun do carregado 700/42 (+8); blockstun do carregado 417/25 (−9, seguro, sem castigo); parry 200/12; stun do parry 800/48 (garante o carregado de 500 ms); armadura do carregado desde o tick 0, só contra leves; GB fica em 350/21, com tech de 333/20 depois do contato e stun de 900/54. Trecho fixo de 400 ms entre soltar o carregado e o contato: vai à conversa de design.

O que o agente não confirmou:

- Naraka: nenhum número medido (janela do parry, tempo no chão, tempo sem arma); o '0.2 sec delay' do parry é só de fórum; não achei um agarrão corpo a corpo, só o gancho.
- For Honor: que bloquear um golpe básico não custa stamina a quem defende é inferência (stamina_damage vazio nos dados); não há fonte oficial da Ubisoft para nenhum número; a fandom wiki deu 402/403.
- For Honor: o regen de stamina e o custo em stamina do parry não foram achados.
- Chivalry 2: a duração da janela de parry ativo e o tempo de stagger depois do chute e do desarme não foram achados; a exceção das Katares (sem flinch, patch 2.6) só aparece em resumo de busca; o campo 'blocked: 0.75' do Polehammer não tem definição.
- Sekiro: a Fextralife não diz quem mediu os 12 frames; um fórum fala em 500 ms, contra a wiki; faltam valores de postura por golpe.
- Tempo de reação de escolha (lei de Hick): nenhum número de estudo primário encontrado.
- Tekken 8: os números são da Wavu Wiki (comunidade), não da Bandai Namco.
- SF6: só o Ryu foi conferido; as janelas de Drive Parry e Perfect Parry não foram confirmadas.
- SuperCombo Wiki e as wikis da fandom deram 403/402.

### Resumo — A vida, a partida, a queda e o hitstop

Fato: no For Honor o leve vale ~10-12% da vida (13-15 de 120-140) e o pesado ~20-25%. Duelo: melhor de 5, no tempo vence a maior vida; essa regra e o anti-fuga vieram juntos em 2017, contra a fuga por mobilidade. Tekken, SF e Smash também decidem o tempo esgotado pela vida. A morte pelo cenário no duelo é vista como frustrante. Hitstop: nos jogos de luta é simulação e simétrico (9/11/13 frames); no Smash cresce com o dano e encolhe com 8 jogadores; no perfect shield só o atacante congela; o Celeste usa 50 ms. Recomendação v0: vida 100, leve 12, carregado 30 fixo, quebra 15, riposte 20; vence quem ganha 3 rounds de 90 s (5400 ticks); empate vai para quem acertou primeiro, sem sorteio; death plane 5 m abaixo, KO no duelo e checkpoint no time trial; hitstop simulado de 4/7/2-4 ticks (leve/carregado/bloqueado), parry com 9 ticks só no atacante, KO 12; tremor curto, só apresentação.

O que o agente não confirmou:

- For Honor: tempo atual do round de Duelo (só Wikipedia diz 5 min; personalizada oferece 1/3/10 min) e regra de empate atual (a wiki diz que longo demais vira empate, o patch 1.11 diz que vence quem tem mais HP)
- For Honor: tempo entre rounds, contagem regressiva e reset; faixa completa de dano de todos os heróis; acompanhamento garantido da quebra de guarda
- Chivalry 2: vida do Footman (150) só em busca; tabela do Battle Axe veio embaralhada; convenções de servidor de duelo (reverência, não se meter) sem fonte
- Naraka: vida base; duração do round do Bloodsport (75 s só num guia); números da Longsword vêm de guia sem data
- Street Fighter 6: hitstop por força (SuperCombo deu 403) e a regra exata de empate por vida igual; os 8/12/15 frames do SFV (Shoryuken não renderizou)
- Tekken 8: formato e tempo da partida ranqueada; hitstop comum
- Monster Hunter: hitstop por arma em frames; Dark Souls, Elden Ring e Hollow Knight: pausa no acerto
- Palestras: o item 'sleep' da Vlambeer vem de lista de usuário; ano do 'Juice it or lose it' (2012 ou 2013); valores exatos da palestra de Eiserloh; episódio do Sakurai no YouTube sobre hitstop
- Apex: 5 s fora dos limites nas Arenas; Titanfall 2: cronômetro fora dos limites; Mirror's Edge: queda no time trial; Trackmania: se o relógio continua após o respawn; Celeste: duração da morte até o respawn
- Overwatch: regra oficial de crédito do environmental kill (só wiki de comunidade)
- Gravidade do nosso jogo (assumi 9,8 m/s² na queda de 5 m); graus do tremor de câmera, 3 s de crédito e 3 s de contagem sem precedente numérico

### Resumo — O bot, o percurso e o log de crash

Report in Portuguese covers ghost time trials, human-like bots, plain-GDScript behavior trees and Godot crash logging. Time trials in the sources use ordered checkpoints, reference times and instant restart; the Gauntlet start is a crossing trigger, so a swept segment test is advised. Ghost by position survives patches; input replays only reproduce on the same build. Bot difficulty comes from per-event sampled perception delay plus error rate and option weights, reading only public state (FightingICE 15 frames, OpenAI Five 167-267 ms). Proposed: N3 mean 260 ms/16 ticks, sd 40, floor 180; N1 and N2 are guesses. Godot: file logging is already on for PC; recommended flush_stdout_on_print, always_track_call_stacks, crash_handler/message, plus tester steps. Many bot and game claims are search-snippet only and marked as such.

O que o agente não confirmou:

- FightingICE 15-frame rule: only search snippet of the rules page; page refused connection, PDFs unreadable
- Numbers from arXiv PDFs (230 ms fighting RL paper, OpenAI Five 167-267 ms, 140-190 ms ex-Gaussian preprint) only from search snippets
- For Honor GDC talk content and what bot levels 1/2/3 do: no primary source opened
- Street Fighter 6 CPU levels: nothing found; Killer Instinct Shadows only snippets
- Mirror's Edge, Neon White, Celeste details: search snippets only (TrueAchievements 403)
- Titanfall 2 timer start/stop, exact per-target penalty and fall/leave rule: no source
- Trackmania official checkpoint order, respawn and skip penalty rules: not found
- Replay-version-stamping guide (bugnet.io): page opened without the article text
- Plain GDScript behavior tree is general knowledge, no source; LimboAI/Beehave determinism not stated
- Whether the official Windows 4.7 export template prints a C++ backtrace without symbols: read only master, old issue 42540 suggests MinGW disabled it
- Sentry pricing/free tier not stated

## §5 — As afirmações importantes e o veredicto do verificador

- **tranco:C01** — For Honor: a janela de parry abre 300 ms antes do contato e fecha 100 ms antes, 200 ms no total (For Honor Info Hub, comunidade).
  - Veredicto: **CONFIRMED**. Page is a JS app with no server-rendered text; the sentence was read from its bundle static/js/main.bbea47a3.js (section 'Parry'). 200 ms total is arithmetic.
  - Lido em: https://forhonorinfohub.com/generalinfo
  - Trecho: This window starts 300ms before an attack connects (Just past feint window), and ends 100ms before an attack connects.
- **tranco:C02** — For Honor: quem tem um leve aparado fica 900 ms em stagger; quem tem um pesado aparado, 600 ms.
  - Veredicto: **CONFIRMED**. Read from the page's JS bundle (main.bbea47a3.js).
  - Lido em: https://forhonorinfohub.com/generalinfo
  - Trecho: Stagger for having your Lights Parried is 900ms, whilst the stagger for having your Heavies Parried is 600ms.
- **tranco:C03** — For Honor (Warden): o parry de um leve garante um pesado de cima de 900 ms (27 de dano); o de um pesado garante dois leves (15). Medianas: parry de leve 26, de pesado 14, GB 24.
  - Veredicto: **CONFIRMED**. Punish damages 27/15/24 confirmed. The API has no duration field, so the '900 ms' top heavy is not on this page. Medians computed from the first-listed punish of all 39 heroes: light parry 26, heavy parry 14, GB 24, consistent with the claim.
  - Lido em: https://forhonorinfohub.com/api/CharacterMaxPunishes/getAll
  - Trecho: Warden ... Light Parry: "instructions":"Top Heavy","damage":"27" ... Heavy Parry: "instructions":"Double Side Lights","damage":"15" ... Guard Break: "instructions":"Side Heavy","damage":"24"
- **tranco:C05** — For Honor: tempo até poder atacar depois de um acerto, por nível: 600/800/1000 ms (leve/médio/forte); depois de um bloqueio, 600/700/800 ms; depois de um bloqueio superior, 400 ms.
  - Veredicto: **CONFIRMED**. Hit/block stun table (Low/Medium/High x Block/Dodge/Attack) read from the page's JS bundle; the 'Attack' column gives 600/800/1000 on hit, 600/700/800 on block, 400 on superior block.
  - Lido em: https://forhonorinfohub.com/generalinfo
  - Trecho: On Hit | 600 500 600 | 600 700 800 | 600 900 1000 ; On Block | 600 600 600 | 600 700 700 | 600 800 800 ; On Superior Block | 400 400 400 | 400 400 400 | 400 400 400
- **tranco:C08** — For Honor: a GB leva 400 ms (300 ms logo depois de uma finta) e custa 15 de stamina; a contra-GB tem uma janela de 300 ms que começa no contato.
  - Veredicto: **CONFIRMED**. Read from the page's JS bundle.
  - Lido em: https://forhonorinfohub.com/generalinfo
  - Trecho: Guardbreaks (GB) are 400ms, except when buffered after a feint as they become 300ms. Performing a Guard Break costs 15 Stamina. ... Counter guard break (CGB) window is 300ms ... CGB window starts upon landing.
- **tranco:C09** — For Honor: a GB deixa o alvo 800 ms em stun, prazo que se estende quando o castigo começa; quem faz a contra-GB fica com +33 ms de vantagem.
  - Veredicto: **CONFIRMED**. Read from the page's JS bundle.
  - Lido em: https://forhonorinfohub.com/generalinfo
  - Trecho: Guardbreak stun time is 800ms, during which the target can be attacked or thrown. If an attack is performed, the stun will be extended ... The player who countered the guard break will have +33ms of frame advantage
- **tranco:C11** — For Honor: hyper armor impede o flinch; a maioria dos pesados de abertura não tem, alguns finalizadores têm a partir de 100 ms; a GB pega o pesado de abertura nos 433 ms iniciais.
  - Veredicto: **NOT_VERIFIABLE**. Two parts confirmed (flinch prevention; 433 ms GB vulnerability on heavy openers). The page does not say that most opening heavies lack hyper armor or that some finishers get it from 100 ms; that would come from hero pages, not generalinfo.
  - Lido em: https://forhonorinfohub.com/generalinfo
  - Trecho: Hyper Armor, also known as Uninterruptible Stance, is a property given to certain actions that prevents a unit from flinching upon taking damage. ... All heavy opener attacks have 433ms GB vulnerability.
- **tranco:C13** — Chivalry 2: 350 ms fixos de holding em toda arma. Espada Longa, corte leve: windup 225, release 475, recuperação 800 ms; pesado: 475/500/950 ms. Dados de jogo via Polehammer.
  - Veredicto: **NOT_VERIFIABLE**. Holding time confirmed. The Longsword windup/release/recovery numbers are not in the page's static text (JS app). A search snippet from chivalry.wiki.gg gives Longsword light slash windup 0.225 s, release 0.475 s, recovery 0.8 s but heavy windup 0.575 s, not 0.475; not opened, so unverified.
  - Lido em: https://polehammer.net/
  - Trecho: This is a fixed 350ms for all weapons.
- **tranco:C14** — Chivalry 2: um golpe bloqueado tira 1/3 do dano base em stamina; quem é atingido sem stamina larga a arma, leva metade do dano e cambaleia.
  - Veredicto: **CONFIRMED**.
  - Lido em: https://chivalry.wiki.gg/wiki/Combat_(Chivalry_II)
  - Trecho: When blocked, all weapons deal stamina damage equivalent to 1/3rd of their base damage. ... A player who is hit while out of stamina will drop their weapon and take some half damage. They will also stagger, resulting in a loss of initiative.
- **tranco:C17** — Naraka: focus vence básico, parry vence focus, básico vence parry. Quem carrega um focus leva o dano dos básicos, mas não é interrompido (guia de comunidade).
  - Veredicto: **CONFIRMED**. Opened on the third attempt (two HTTP 429s) via the ?l=english variant of the same guide.
  - Lido em: https://steamcommunity.com/sharedfiles/filedetails/?id=2855559230
  - Trecho: Focus attacks that beat basic attacks. ... Parry that beats focus attacks. ... Basic attacks that beat parry. ... You will take damage from basic attacks while charging, but they won't interrupt you.
- **tranco:C19** — Sekiro: o deflect tem janela de 12 frames (0,2 s); apertar seguido a encolhe para 4 frames, ou 0; a punição some depois de 30 frames ou de um deflect certo (Fextralife).
  - Veredicto: **CONFIRMED**.
  - Lido em: https://sekiroshadowsdietwice.wiki.fextralife.com/Deflection
  - Trecho: The time window to deflect enemy attacks is actually 12 frames by default (0.2 seconds before the attack hits) ... to as little as 4 frames, even 0 frames if you spam it too fast ... the stacking penalty is removed after a period of time (30 frames) as well as immediately following a successful Deflect.
- **tranco:C22** — Tekken 8: hitstun costuma ser maior que blockstun; com o golpe mais rápido em 10 frames, −10 no bloqueio é castigável, −9 é seguro e −15 leva launcher (Wavu Wiki).
  - Veredicto: **CONFIRMED**. Page also states launch punishment starts at -15 because the fastest launcher is 15 frames.
  - Lido em: https://wavu.wiki/t/Punishment
  - Trecho: To reward players for landing a hit, hitstun is typically longer than blockstun. ... The fastest attack for most characters is 10 frames. ... moves that are -9 on block or better are considered "safe".
- **tranco:C23** — Tekken: só um dos frames ativos de um golpe pode conectar; o stun não muda com o frame em que o golpe pega, mas começa mais tarde se pegar num frame tardio.
  - Veredicto: **CONFIRMED**.
  - Lido em: https://wavu.wiki/t/Punishment
  - Trecho: only one of an attack's active frames are allowed to connect ... the hitstun, blockstun, and recovery don't change based on when the move connects ... the stun starts later if it's caused by later active frames.
- **tranco:C25** — Infil Glossary: um golpe é seguro se a diferença entre o blockstun e a recuperação for menor que o startup do golpe mais rápido do oponente.
  - Veredicto: **CONFIRMED**. The page is a JS app; the entry was read from its data file https://glossary.infil.net/json/glossary.json (term 'Safe').
  - Lido em: https://glossary.infil.net/?t=Safe
  - Trecho: it's a race between the block stun of your move and the recovery of your move. ... you just have to make sure the gulf is smaller than your opponent's fastest move.
- **vida:C01** — For Honor: vida dos heróis de 120 a 140 numa amostra de 20 (ex.: Peacekeeper 120, Warden 130, Conqueror 140); o teto natural é 140, e o Shugoki já teve 160.
  - Veredicto: **NOT_VERIFIABLE**. Fandom returned HTTP 402 to WebFetch (also for /wiki/Shugoki and ?action=raw) and a 5 KB block page to curl. A web search found no page stating these health values.
  - Lido em: https://forhonor.fandom.com/wiki/Shugoki/Main
- **vida:C02** — For Honor patch 2.40.0: leve encadeado 13 de dano e finalizador leve 15; pesados do Raider e do Zhanhu entre 26 e 30.
  - Veredicto: **CONFIRMED**. Raider heavies 26-30 and Zhanhu heavy finisher 28 are present; the 13/15 light lines belong to one hero's section in the notes.
  - Lido em: https://www.ubisoft.com/en-us/game/for-honor/news-updates/5K7gJrsS7BGjegCjnnZydv/patch-notes-2400-for-honor
  - Trecho: Top Light in Chain now deals 13 damage (up from 9) ... Light Finishers now deal 15 damage ... Chained Side Heavy now deals 26 damage (down from 27) ... Top Heavy Finisher now deals 30 damage (down from 33) ... Heavy Finishers now deal 28 damage (down from 32)
- **vida:C09** — For Honor, Duelo: melhor de 5 rounds, round de 5 minutos; no fim do tempo vence quem tem mais vida.
  - Veredicto: **CONFIRMED**. Duel section also describes the best-of-five format.
  - Lido em: https://en.wikipedia.org/wiki/For_Honor
  - Trecho: have more remaining health by the end of the five minute round in order to win
- **vida:C10** — For Honor v1.11 (2017): vitória no tempo vai para quem tem mais HP, e o Anti Run Away tira 20% da velocidade de quem foge e drena a stamina dele, porque a mobilidade permitia enrolar.
  - Veredicto: **CONFIRMED**.
  - Lido em: https://www.ubisoft.com/en-us/game/for-honor/news-updates/6BLnxNeyg4hUICdMjgLjbm/for-honor-v111-patch-notes
  - Trecho: Time out victory is awarded to the Player with the most HP remaining ... Navigation Speed reduced by 20 % ... Automatic Stamina drain over time ... High mobility in Duel can enable some characters to easily stall by running away until the clock runs out.
- **vida:C12** — Naraka Bloodsport (1v1): finais em melhor de 3. Desempate no tempo: mais dano, depois mais vida e armadura, depois quem acertou primeiro, por fim sorteio. Vida, armadura e recargas resetam a cada round.
  - Veredicto: **CONFIRMED**. Tiebreak order on the page: damage dealt, then remaining health and armor, then first to deal damage, then random.
  - Lido em: https://narakathegame.com/news/update/20211013/33459_978559.html
  - Trecho: The final rounds are decided in a best-of-three. ... Health, armor and skill cooldowns are reset after each round. ... The player dealt higher damage. ... one will be determined the victor at random.
- **vida:C16** — Smash Ultimate em torneio: 3 stocks, 7:00. No tempo vencem os stocks e depois a menor %; empate total leva a um desempate de 1 stock e 3 min.
  - Veredicto: **CONFIRMED**. 3 stocks / 7:00 are the Unified rulesets; the generic Singles section says 'Time Limit: 6-8 minutes'.
  - Lido em: https://www.ssbwiki.com/Tournament_rulesets_(SSBU)
  - Trecho: Stocks: 3 ... Timer: 7:00 ... if time runs out, the winner is first determined by how many stocks remain, and then by the percentage after time is up. ... a tiebreaker is played, which consists of a 1 stock and 3 minute match
- **vida:C18** — Unreal Engine: KillZ, 'Any actor falling below this level gets destroyed'; é o death plane como configuração do mundo.
  - Veredicto: **CONFIRMED**. Description of the KillZ property on AWorldSettings.
  - Lido em: https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/Engine/AWorldSettings
  - Trecho: Any actor falling below this level gets destroyed
- **vida:C19** — For Honor beta: abismos e espinhos que matam na hora eram 'just plain frustrating' em Duelo e Brawl; os jogadores combinavam não jogar o outro do penhasco.
  - Veredicto: **CONFIRMED**. Article frames the frustration in the smaller modes (1v1 Duel, 2v2 Brawl) and the informal no-ledge agreement among players.
  - Lido em: https://inverse.com/article/27133-for-honor-closed-beta-environment-hazards
  - Trecho: these hazards are just plain frustrating ... We wouldn't throw each other off provided the match was even.
- **vida:C22** — Smash Ultimate: hitlag = (dano x 0,65 + 6) x multiplicadores; 15% de dano dá 15 frames; teto de 30; x0,67 no escudo; x0,75 com 8 jogadores.
  - Veredicto: **CONFIRMED**. Player-count table lists 0.75 for 8 players in Ultimate.
  - Lido em: https://www.ssbwiki.com/Hitlag
  - Trecho: ⌊⌊⌊(d×0.65+6)×h×e×s⌋×p⌋×c⌋ ... 15 frames in Ultimate ... 30 frames (20 for the victim if crouch cancelling) from Brawl onward ... shielding; 0.67×
- **vida:C23** — Smash: o hitlag atinge atacante e vítima; no perfect shield (o parry) só o atacante congela e o defensor fica livre; golpe sem dano não tem hitlag.
  - Veredicto: **CONFIRMED**.
  - Lido em: https://www.ssbwiki.com/Hitlag
  - Trecho: experienced by both the attacker and victim ... the attacker suffers from hitlag while the defender receives none. ... If the attack deals no damage, hitlag is always zero.
- **vida:C24** — Sakurai: no hitstop os dois congelam exatamente o mesmo tempo; mais dano dá mais hitstop; quem apanha treme, e o tremor diminui.
  - Veredicto: **CONFIRMED**.
  - Lido em: https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/
  - Trecho: With hitstop, both you and your opponent freeze for the exact same amount of time. ... the more damage an attack inflicts, the longer the hitstop period. ... The distance that characters vibrate is not set, starting out large and growing much smaller by the end.
- **vida:C25** — Jogos de luta: leve congela ~9 frames, médio ~11, forte ~13; igual no acerto e no bloqueio; o projétil congela só a vítima; serve para estabilizar o timing de cancel.
  - Veredicto: **CONFIRMED**. The hit-vs-block equality comes from the author's comment on the post: 'Impact freeze is generally the same regardless of whether the attack hits or gets blocked.'
  - Lido em: https://sonichurricane.com/?p=1043
  - Trecho: In most games, light attacks freeze around 9 frames, medium attacks around 11, hard attacks around 13. ... they cause impact freeze to the victim but not to the attacker. ... stabilizes cancel timing
- **vida:C26** — Celeste (código-fonte): o dash congela o jogo por 0,05 s (3 ticks) e o lançamento por explosão por 0,1 s; os tremores de câmera direcionais duram 0,1 a 0,2 s.
  - Veredicto: **CONFIRMED**. Read via the raw file; DirectionalShake durations .1f (super bounce, wall) and .2f (dash) are present. '3 ticks' is 0.05 s at 60 Hz, an inference.
  - Lido em: https://github.com/NoelFB/Celeste/blob/master/Source/Player/Player.cs
  - Trecho: private void DashBegin() { ... Celeste.Freeze(.05f); ... SceneAs<Level>().DirectionalShake(DashDir, .2f); ... public Vector2 ExplodeLaunch(...) { ... Celeste.Freeze(.1f);
- **bot:C01** — Titanfall 2 Gauntlet: enemy targets appear on the course and skipping them adds a time penalty (fan wiki).
  - Veredicto: **CONFIRMED**.
  - Lido em: https://titanfall.wiki.gg/wiki/The_Pilot's_Gauntlet
  - Trecho: Enemy targets appear on the course, and not killing them will add a time penalty.
- **bot:C03** — Gauntlet start is a crossing trigger: passing the start point at speed can leave the run unregistered, so checkpoint tests need a swept check.
  - Veredicto: **CONFIRMED**. The page states the glitch only; 'crossing trigger' and 'swept check' are the report's inference, not on the page.
  - Lido em: https://titanfall.wiki.gg/wiki/The_Pilot's_Gauntlet
  - Trecho: By going past the start point at a certain speed, the game can glitch and not register the Gauntlet starting
- **bot:C04** — Mirror's Edge time trials: checkpoints hit in order, split times shown, 1 to 3 stars by pass times (search snippet only).
  - Veredicto: **NOT_VERIFIABLE**. HTTP 403. Search summaries say the walkthrough lists 1/2/3-star times per trial and GameSpot mentions 4-5 checkpoint stages, but split times were not found anywhere.
  - Lido em: https://www.trueachievements.com/game/Mirrors-Edge/walkthrough/4
- **bot:C05** — Neon White: Bronze/Silver/Gold/Ace medals; silver unlocks your ghost; one-button restart (search snippet only).
  - Veredicto: **NOT_VERIFIABLE**. Medals confirmed; the page does not say silver unlocks the ghost nor mention a one-button restart (it only says the developers added ghost support).
  - Lido em: https://en.wikipedia.org/wiki/Neon_White
  - Trecho: they receive a medal based their completion time, ranging from Bronze, Silver, Gold, and Ace.
- **bot:C06** — Trackmania replays record inputs for a 1:1 replay, which only reproduces on the same simulation.
  - Veredicto: **NOT_VERIFIABLE**. Input-recording 1:1 replay confirmed; the page says nothing about requiring the same simulation/version to reproduce.
  - Lido em: https://en.wikipedia.org/wiki/Game_replay
  - Trecho: such as TrackMania, Doom, and N, use size-efficient replay files that record inputs to get a 1:1 replay in lossless fidelity.
- **bot:C08** — FightingICE delays information to AIs by 15 frames to simulate human reaction (seen only in search snippet of the rules page).
  - Veredicto: **NOT_VERIFIABLE**. Server refused the connection on 443 and 80 (ECONNREFUSED), also via www. Search snippets quote the rules page as 'the information sent to AIs will have a delay of 15 frames' to simulate human reaction, but the page itself could not be opened.
  - Lido em: https://ice.ci.ritsumei.ac.jp/~ftgaic/index-3.html
- **bot:C10** — OpenAI Five reaction time is random between 5 and 8 frames (167-267 ms), vs 250 ms human lab figure (search snippet).
  - Veredicto: **CONFIRMED**. The PDF fetched as binary; the text was read from the ar5iv HTML rendering of the same paper (https://ar5iv.labs.arxiv.org/html/1912.06680). The paper also states 'OpenAI Five can react to a game event in 217ms on average.'
  - Lido em: https://arxiv.org/pdf/1912.06680
  - Trecho: reaction time randomly distributed between 5 and 8 frames (167ms to 267ms) ... human reaction time has been measured at 250ms in controlled experimental settings
- **bot:C11** — GDC For Honor bot talk: RL with self-play, action masking for designers to tune difficulty, plus scripted logic like behavior trees (snippet).
  - Veredicto: **NOT_VERIFIABLE**. GDC Vault redirects to https://gdconf.com/gdc-vault-maintenance/ (302). A search summary of the abstract matches the claim (RL, self-play, action masking for designer control, hybrid with behavior trees) but the page was not opened.
  - Lido em: https://gdcvault.com/play/1035522/Streamlining-Bot-Development-in-For
- **bot:C13** — Godot RandomNumberGenerator: the algorithm is an implementation detail that should not be depended upon (currently PCG32).
  - Veredicto: **CONFIRMED**. The page's description names PCG32 as the current algorithm.
  - Lido em: https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html
  - Trecho: Note: The underlying algorithm is an implementation detail and should not be depended upon.
- **bot:C17** — File logging defaults: enable_file_logging false, enable_file_logging.pc true, log_path user://logs/godot.log, max_log_files 5.
  - Veredicto: **CONFIRMED**.
  - Lido em: https://docs.godotengine.org/en/stable/classes/class_projectsettings.html
  - Trecho: debug/file_logging/enable_file_logging false ... debug/file_logging/enable_file_logging.pc true ... debug/file_logging/log_path "user://logs/godot.log" ... debug/file_logging/max_log_files 5
- **bot:C18** — Each session creates a new log file and the previous one is renamed with a rotation date; up to 5 are kept by default.
  - Veredicto: **CONFIRMED**.
  - Lido em: https://docs.godotengine.org/en/stable/tutorials/scripting/logging.html
  - Trecho: Each session creates a new log file, with the old file renamed to contain the date at which it was rotated. Up to 5 log files are kept by default.
- **bot:C19** — On Windows user:// is %APPDATA%\Godot\app_userdata\[project_name].
  - Veredicto: **CONFIRMED**.
  - Lido em: https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html
  - Trecho: %APPDATA%\Godot\app_userdata\[project_name]
- **bot:C20** — In release exports stdout is flushed only on exit or crash, stderr always; application/run/flush_stdout_on_print changes it.
  - Veredicto: **CONFIRMED**.
  - Lido em: https://docs.godotengine.org/en/stable/tutorials/scripting/logging.html
  - Trecho: standard output is only flushed when the project exits or crashes to improve performance ... is always flushed on every print, even in projects exported in release mode ... enabling application/run/flush_stdout_on_print in the Project Settings
- **bot:C21** — Release exports disable GDScript backtraces by default; Always Track Call Stacks enables them; since 4.5 errors log a backtrace.
  - Veredicto: **não verificada** (ficou fora do limite do verificador)
  - Lido em: https://docs.godotengine.org/en/4.6/tutorials/scripting/logging.html
- **bot:C22** — A crash backtrace goes to stderr and the log file, but is only usable with debug symbols; official binaries have none.
  - Veredicto: **não verificada** (ficou fora do limite do verificador)
  - Lido em: https://docs.godotengine.org/en/stable/tutorials/scripting/logging.html

## §6 — As demais afirmações, com o link

- tranco:C04 — For Honor: os leves de abertura levam 500 ms até acertar em 77 de 79 entradas (400 ms em 2); os pesados de abertura, em geral 800 ms (50), 900 (19) ou 700 (11). — https://forhonorinfohub.com/api/CharacterAttackData
- tranco:C06 — For Honor: os leves básicos são 'minus' no acerto e os pesados finalizadores são 'plus' no acerto; muitos finalizadores ficam neutros no bloqueio. — https://forhonorinfohub.com/generalinfo
- tranco:C07 — For Honor (Raider): o leve de 500 ms recupera em 700 ms no acerto e no bloqueio superior; o bloqueio comum já dá bloqueio superior contra os leves normais. — https://forhonorinfohub.com/api/CharacterAttackData
- tranco:C10 — For Honor: a GB que ricocheteia tem 1000 ms de recuperação; a GB que erra leva 1000 ms até trocar a guarda e 900 ms até esquivar ou tentar outra GB. — https://forhonorinfohub.com/generalinfo
- tranco:C12 — For Honor: sem stamina, só saem leves e pesados básicos, sem finta, rolamento ou corrida; os golpes ficam mais lentos, com janela de parry de 400 ms. — https://forhonorinfohub.com/generalinfo
- tranco:C15 — Chivalry 2: quem ataca fica vulnerável no windup e no release; o jab interrompe um ataque ainda em windup; o chute não interrompe quem ataca, mas quebra a guarda erguida. — https://chivalry.wiki.gg/wiki/Combat_(Chivalry_II)
- tranco:C16 — Chivalry 2: o riposte tem janela de meio segundo e ~0,5 s de auto-parry; o contra-ataque precisa começar depois do release do oponente e antes de o golpe dele acertar. — https://chivalry.wiki.gg/wiki/Combat_(Chivalry_II)
- tranco:C18 — Naraka: no parry certo, o inimigo cai e larga a arma, e vem um contra-ataque pesado; básicos não se aparam; as espadas duplas só ganham armadura depois de soltar o golpe. — https://steamcommunity.com/sharedfiles/filedetails/?id=2855559230
- tranco:C20 — Sekiro: bloquear enche a postura de quem defende e não afeta o atacante; o deflect tira muita postura do atacante e pouca do defensor. — https://sekiroshadowsdietwice.wiki.fextralife.com/Posture
- tranco:C21 — SF6, dados oficiais da Capcom: o soco fraco em pé do Ryu tem startup 4, +4 no acerto e −1 no bloqueio; o soco forte em pé, startup 10, +4/−2; o forte agachado, −7 no bloqueio. — https://www.streetfighter.com/6/character/ryu/frame
- tranco:C24 — Smash Ultimate: shieldstun = ⌊0,8·d·t·m·p + 2⌋; o atacante sofre o hitlag mas não o shieldstun. Hitlag = ⌊(d·0,65+6)·mult⌋, para os dois lados. — https://www.ssbwiki.com/Shieldstun
- vida:C03 — Chivalry 2: Knight tem 175 de vida e o Vanguard 130 (o Archer, 90, em outra página da wiki). — https://chivalry.wiki.gg/wiki/Knight_(Chivalry_II)
- vida:C04 — Chivalry 2, Battle Axe: slash de 55 a 69 e heavy overhead de 85 a 106 no corpo, conforme a classe atingida; mata em 2 a 3 golpes (inferência). — https://chivalry.wiki.gg/wiki/Battle_Axe
- vida:C05 — Naraka (29/03/2024): armadura máxima de 600 (Common) a 1.800 (Extreme); cada segmento da barra vale 300. — https://www.narakathegame.com/news/update/20240329/33459_1146145.html
- vida:C06 — Naraka, Longsword lendária (guia): golpes normais de 172 e 176; carregados de 819 e 713, ou seja, ~4-5x o normal. — https://zilliongamer.com/naraka-bladepoint/c/weapon/naraka-bladepoint-longsword-stats-combos-souljades-skins-list
- vida:C07 — Street Fighter 6: 10.000 de vida para quase todos; Zangief 11.000, E. Honda e Marisa 10.500 (jun/2023). — https://eventhubs.com/news/2023/jun/07/everyone-sf6-stamina-three-exceptions
- vida:C08 — Tekken 8: vida máxima de 180 no lançamento, 200 na 2.00.02 (abr/2025) e 190 na 3.02.01 (ago/2026). — https://wavu.wiki/t/Patches_(Tekken_8)
- vida:C11 — Wiki do For Honor: no Duelo, morte simultânea é empate e cada round começa num lugar diferente do mapa. — https://forhonor.fandom.com/wiki/Duel
- vida:C13 — Regras de torneio de SF6 que seguem o CPT 2024: 2 de 3 rounds por jogo, timer de 99 s. — https://www.start.gg/tournament/frag-fest-spring-2025/event/frag-fest-spring-2025-street-fighter-6-double-elimination/overview/rules
- vida:C14 — Tekken World Tour (regras de evento): 3 de 5 rounds, limite de 60 s por round. — https://www.start.gg/tournament/first-attack-2025/event/tekken-8-twt-challenger-event/overview/rules
- vida:C15 — Tekken: no tempo esgotado vence quem tem mais vida; sem ninguém à frente, o round empata; morte simultânea é Double K.O. — https://strategywiki.org/wiki/Tekken/Gameplay
- vida:C17 — Smash: a blast line fica além da borda da tela; cruzar a lateral ou a de baixo é KO, e a de cima só mata com velocidade vertical suficiente. — https://www.ssbwiki.com/Blast_line
- vida:C20 — Overwatch (wiki de comunidade): environmental kill é cair do mapa após um controle de grupo; o crédito vai para o último controle aplicado. — https://overwatch.fandom.com/wiki/Environmental_kill
- vida:C21 — Apex: 15 s fora dos limites mata na hora; em out/2020 o cronômetro deixou de reiniciar a cada área nova e passou a 30 s fixos, por causa de abuso. — https://apexlegends.fandom.com/wiki/October_06,_2020_Patch
- vida:C27 — Tekken 8: golpes com Balcony Break têm 'Hitstop 20f on hit' (333 ms) como propriedade especial. — https://wavu.wiki/t/Bryan_movetable
- vida:C28 — Monster Hunter Wilds: o True Charged Slash da Great Sword tem 'two-three freeze frames', segundo artigo de jogadores; não há tabela por arma. — https://www.thegamer.com/monster-hunter-wilds-beta-hit-stop-missing/
- vida:C29 — Vlambeer, 'The art of screenshake' (INDIGO 2013): ~45 min e 30 ajustes, entre eles tremer a tela no sentido contrário ao tiro. — https://www.gamedeveloper.com/design/vlambeer-co-founder-shares-advice-on-building-better-action-games
- vida:C30 — Exemplo do Bevy baseado em Eiserloh (GDC 2016, modelo de trauma): translação máxima de 20 px, 'low enough not to be distracting'. — https://bevy.org/examples/camera/2d-screen-shake/
- bot:C02 — Gauntlet time is compared to a developer-pilot 'ghost recorder time'; sources disagree on whose (Lastimosa vs Anderson 56.65 s). — https://www.trueachievements.com/a225198/the-student-achievement
- bot:C07 — Trackmania 2020 changelog: respawning at a checkpoint shows your best-checkpoint ghost (relayed by a community tracker). — https://devtrackers.gg/trackmania/p/76400859-23-07-2020-new-update-and-changelog
- bot:C09 — A fighting-game RL paper added a fixed ~230 ms average decision delay so the AI has no advantage (search snippet). — https://arxiv.org/pdf/1904.03821
- bot:C12 — Tekken 8 Super Ghost is built from a player's style and quirks and gets more accurate the more they fight; no difficulty levels mentioned. — https://en.bandainamcoent.eu/tekken/news/tekken-8-discover-about-super-ghost-battles
- bot:C14 — A given RNG seed gives a reproducible sequence, but seeds have no avalanche effect and state must not be set to arbitrary values. — https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html
- bot:C15 — LimboAI is MIT, supports Godot 4.6 (GDExtension) and 4.7 (module), free, optional donations; determinism not stated. — https://github.com/limbonaut/limboai
- bot:C16 — Beehave behavior-tree addon is MIT, Godot 4.5+ on the 4.x branch (2.10+). — https://github.com/bitbrain/beehave
- bot:C23 — Godot master has a Windows crash handler using libbacktrace and DbgHelp, printing a message from debug/settings/crash_handler/message (master, not 4.7 tag). — https://github.com/godotengine/godot/blob/master/platform/windows/crash_handler_windows_signal.cpp
- bot:C24 — sentry-godot is MIT, a C++ GDExtension on sentry-native, needs Godot 4.5+ for 1.x/2.x releases, Windows x86_64 supported. — https://github.com/getsentry/sentry-godot
- bot:C25 — Sentry: Windows native crashes arrive as minidumps; readable frames need export templates with debug symbols uploaded to Sentry. — https://docs.sentry.io/platforms/godot
