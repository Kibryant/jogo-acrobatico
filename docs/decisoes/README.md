# Decisões

Índice das decisões do projeto, em formato ADR. Cada arquivo tem Contexto, Opções consideradas, Decisão, Consequências e Revisitar se.

**Como ler:** só vale como regra o que está em "Vigentes". Decisão substituída fica no repositório para contar a história, nunca para ser seguida.

**Como mudar:** decisão aceita não se reescreve. Mudar de ideia gera uma DEC nova, com `substitui`. Na antiga só mudam `status` e `substituida_por`, e ela ganha no topo o aviso "⚠️ Substituída por DEC-XXXX em AAAA-MM-DD — não é a regra atual". Antes de criar, confira o último ID desta pasta. A skill `adr` faz esse passo a passo.

## Vigentes

| ID | Data | Decisão | Status |
|---|---|---|---|
| [DEC-0001](DEC-0001-engine-godot-gdscript.md) | 2026-10-02 | Godot 4.7.2 com GDScript | aceita |
| [DEC-0002](DEC-0002-piso-de-desempenho-renderer-e-fisica.md) | 2026-10-02 | 60 fps em 1080p no PC do Arthur, renderer Compatibility e física Jolt explícita | aceita |
| [DEC-0003](DEC-0003-rede-com-netfox.md) | 2026-10-02 | netfox, com servidor autoritativo e previsão com rollback, na main fixada num commit | aceita; completada pela DEC-0023 (o commit, os módulos e o contorno do #659) e pela DEC-0024 (60 ticks) |
| [DEC-0004](DEC-0004-arquitetura-nucleo-puro-e-ddd-estrategico.md) | 2026-10-02 | Núcleo puro, nós finos, DDD só estratégico e as seis regras | aceita; a frase sobre a RewindableStateMachine foi substituída pela DEC-0022, e a frase da regra 2 sobre o som no tick novo pela DEC-0031 |
| [DEC-0005](DEC-0005-codigo-tipado-e-pastas-por-feature.md) | 2026-10-02 | Tipagem obrigatória, pastas por feature e formatador da GDQuest | aceita; completada pela DEC-0022, que torna o acesso inseguro um erro e dá nome às pastas |
| [DEC-0007](DEC-0007-base-markdown-git-backlog-md.md) | 2026-10-02 | Markdown e git, com tasks no Backlog.md, no padrão do SkinHub | aceita |
| [DEC-0008](DEC-0008-idioma.md) | 2026-10-02 | Inglês no que é interno, português no que o Arthur lê, inclusive as tasks | aceita; as tasks em português foram confirmadas pela Q-08 (F-010 §2); completada pela DEC-0033 (o idioma dos arquivos públicos) |
| [DEC-0009](DEC-0009-harness-do-claude-code.md) | 2026-10-02 | A harness do SkinHub, mais leve | aceita; completada pela DEC-0027 nos hooks do Claude Code |
| [DEC-0010](DEC-0010-construir-e-ensinar.md) | 2026-10-02 | O Claude constrói e ensina; o Arthur dirige | aceita |
| [DEC-0011](DEC-0011-direcoes-para-depois.md) | 2026-10-02 | Direções para validação de acerto, hospedagem e replay | aceita, como direção; a validação de acerto da espada foi detalhada pela DEC-0026, e o replay pela DEC-0027; o ponto 2 completado pela DEC-0032 |
| [DEC-0012](DEC-0012-fase-de-desenho-antes-do-codigo.md) | 2026-10-02 | Fase de desenho com seis conversas e um esqueleto andante | aceita na sessão 2 (F-010 §2); completada pela DEC-0034 (os gatilhos dos serviços) e pela DEC-0036 (o fechamento da fase e o desenho por fase) |
| [DEC-0013](DEC-0013-camera-em-terceira-pessoa.md) | 2026-10-02 | Câmera em terceira pessoa | aceita; os números da câmera saem na rodada 2 do Desenho 1 |
| [DEC-0014](DEC-0014-tribo-do-combate-for-honor.md) | 2026-10-02 | Tribo do combate For Honor e Chivalry 2: tempo fixo e aviso claro | aceita |
| [DEC-0015](DEC-0015-registrar-ter-posicao-e-dizer-nao.md) | 2026-10-02 | O Claude registra o que o Arthur pensa em voz alta, tem posição e diz não | aceita; completa a DEC-0010 |
| [DEC-0016](DEC-0016-cancelamento-so-desenhado.md) | 2026-10-02 | Cancelamento só desenhado: na lista, com preço, com aviso e com janela larga | aceita; a lista do v0 é hipótese até a fase 2 |
| [DEC-0017](DEC-0017-numeros-v0-o-claude-fecha-o-arthur-sente.md) | 2026-10-02 | Números v0: o Claude fecha pela melhor experiência do jogador, e o Arthur julga jogando | aceita |
| [DEC-0018](DEC-0018-nome-provisorio-jogo-acrobatico.md) | 2026-10-02 | Nome provisório "Jogo Acrobático" até o fim da fase 1 | aceita |
| [DEC-0019](DEC-0019-numeros-em-artefato-visual.md) | 2026-10-02 | Número, medida e cálculo se mostram ao Arthur num artefato visual | aceita |
| [DEC-0020](DEC-0020-linguagem-gdscript-e-nucleo-trocavel.md) | 2026-10-02 | GDScript no jogo todo; só o núcleo muda de linguagem, se a medição de CPU pedir | aceita; completa a DEC-0001 |
| [DEC-0021](DEC-0021-explicar-no-mundo-do-arthur.md) | 2026-10-02 | Explicar no mundo do Arthur: pergunta fixa de entendimento, exemplo do que ele conhece e escolha como trade-off | aceita; completa a DEC-0010 |
| [DEC-0022](DEC-0022-arquitetura-detalhada.md) | 2026-10-02 | Arquitetura detalhada: estado em quatro caixas, máquina de estados no núcleo, tick em sanduíche, cenas, zero autoloads nossos, pastas e acesso inseguro como erro | aceita; substitui só a frase da DEC-0004 sobre a RewindableStateMachine. As cenas e as pastas foram aprovadas no plano (F-022). A hipótese 3 foi substituída pela DEC-0025 |
| [DEC-0023](DEC-0023-netfox-no-godot-4-7-2.md) | 2026-10-04 | O netfox no Godot 4.7.2: main fixada no `cf5189d`, com core, extras e internals em `addons/`, e os autoloads em `res://` guardados por teste | aceita; completa a DEC-0003 e fecha a Q-02; o §7 completado pela DEC-0038 (a sessão de teste com o simulador) |
| [DEC-0024](DEC-0024-sessenta-ticks-por-segundo.md) | 2026-10-04 | 60 ticks por segundo | aceita; fecha a Q-01 |
| [DEC-0025](DEC-0025-contornos-do-rollback-no-jolt.md) | 2026-10-04 | Os contornos do rollback no Jolt: o do transform em todo tick refeito e o contorno D no começo de cada rollback | aceita; substitui só a hipótese 3 da DEC-0022; o §2 completado pela DEC-0037 (o snap de reserva do contorno D) |
| [DEC-0026](DEC-0026-a-rede.md) | 2026-10-04 | A rede: o input, o oponente no passado, a compensação de lag, a detecção do golpe, a fase 1 no tick e a Main | aceita; completa a DEC-0011 na validação de acerto da espada; a frase do §2 sobre o atraso de visão pelo `get_last_known_state()` foi substituída pela DEC-0031; o §6 completado pela DEC-0032 (o fechamento no contêiner) |
| [DEC-0027](DEC-0027-testes-e-entrega.md) | 2026-10-07 | Testes e entrega: o portão com canários e log limpo, as cinco camadas com quando nascem, a SyncTest à mão, o replay por inputs e os hooks do Claude Code | aceita; substitui a DEC-0006 e completa a DEC-0009 e a DEC-0011; completada pela DEC-0029 (o passo dos assets e do LFS no portão); completada pela DEC-0032 (o job da imagem do servidor fora do portão) |
| [DEC-0028](DEC-0028-builds-versoes-e-fluxo-de-branch.md) | 2026-10-07 | Builds, versões e fluxo de branch: dois presets, build no PR e na tag, SemVer 0.y.z com o commit carimbado, uma branch por task com PR e um worktree por sessão paralela | aceita; a frase "O push na main não gera build" foi substituída pela DEC-0032; completada pela DEC-0033 |
| [DEC-0029](DEC-0029-politica-de-assets-e-fontes.md) | 2026-10-08 | A política de assets: só licença que deixa redistribuir e modificar, as fontes conferidas na origem, a pasta com a licença ao lado, a linha do CREDITS.md, a checagem no portão e a cota do LFS | aceita; completa a DEC-0027 no portão |
| [DEC-0030](DEC-0030-pipeline-de-import-e-caminho-da-animacao.md) | 2026-10-08 | O pipeline de import e o caminho da animação: glTF, 1,8 m pela escala de import, um rig só, a pose como função do estado, a base CC0 com os clipes de identidade à mão, e o orçamento de 10 mil vértices com MSAA 2x, sombra e contorno | aceita; fecha a Q-22 |
| [DEC-0031](DEC-0031-tokens-de-leitura-e-base-da-interface.md) | 2026-10-08 | Os tokens de leitura e a base da interface: três canais por estado com a cor na exceção, a chave do evento no lugar do tick novo, o atraso de visão pelo tick do estado, o bus "leitura", a cor de time pelo contorno, um Theme na base de 1920 × 1080, as teclas físicas e as chaves de tradução por ID | aceita; substitui uma frase da DEC-0004 e uma da DEC-0026 |
| [DEC-0032](DEC-0032-hospedagem-do-servidor.md) | 2026-10-10 | A hospedagem do servidor: o esqueleto andante neste PC com a imagem do servidor testada no CI, o fechamento limpo por comando próprio, nada pago até a fase 3 e uma VPS em São Paulo na fase 3 | aceita; substitui uma frase da DEC-0028; completa a DEC-0011, a DEC-0026 e a DEC-0027 |
| [DEC-0033](DEC-0033-repositorio-aberto-e-licenca.md) | 2026-10-10 | O repositório aberto e a licença: MIT no código, CC BY 4.0 nos assets próprios, o nome fora da licença, o histórico como está, a main sem force push e o PR de fora só com aprovação | aceita; completa a DEC-0008 e a DEC-0028; completada pela DEC-0035 (os docs na MIT) |
| [DEC-0034](DEC-0034-servicos-e-gatilhos.md) | 2026-10-10 | Os serviços e os gatilhos: o crash, as contas e o ranking, a comunidade no GitHub, só sinais rápidos no jogo, a assinatura pelo SignPath, a Steam e a lei | aceita; completa a DEC-0012 |
| [DEC-0035](DEC-0035-os-docs-na-mit.md) | 2026-10-10 | Os docs na MIT: tudo no repositório fica na MIT, inclusive os docs, as fontes e o AGENTS.md, salvo os assets próprios, os de terceiros e os addons, o código de conduta e o nome | aceita; completa a DEC-0033 |
| [DEC-0036](DEC-0036-fase-de-desenho-fechada-um-desenho-por-fase.md) | 2026-10-10 | A fase de desenho fechou: nenhum desenho de base novo; o desenho de jogo acontece um por fase, na abertura da fase, com a lista nomeada; o que aparecer no meio vira Q | aceita; completa a DEC-0012 e fecha a pergunta da F-035 e da F-082 |
| [DEC-0037](DEC-0037-snap-de-reserva-do-contorno-d.md) | 2026-10-17 | O snap de reserva do contorno D: quando a sonda não acha o chão que o estado diz, o lutador chama o snap do motor | aceita; completa a DEC-0025 §2 |
| [DEC-0038](DEC-0038-sessao-de-teste-com-o-simulador.md) | 2026-10-18 | A sessão de teste com o simulador de lag: um `override.cfg` temporário liga a conexão automática do netfox, e a `Main` usa a conexão do simulador | aceita; completa a DEC-0023 §7 |

## Propostas — ainda não são regra

Nenhuma proposta aberta.

## Histórico

| Decisão | O que foi substituído | Por | Data |
|---|---|---|---|
| [DEC-0004](DEC-0004-arquitetura-nucleo-puro-e-ddd-estrategico.md) | Só a frase "feita com a RewindableStateMachine do netfox". As seis regras continuam valendo | [DEC-0022](DEC-0022-arquitetura-detalhada.md) | 2026-10-02 |
| [DEC-0022](DEC-0022-arquitetura-detalhada.md) | Só a hipótese 3: o `on_floor` no estado no lugar do movimento extra de velocidade zero. O `on_floor` continua no estado, com o contorno D; o resto continua valendo | [DEC-0025](DEC-0025-contornos-do-rollback-no-jolt.md) | 2026-10-04 |
| [DEC-0006](DEC-0006-testes-e-portao.md) | Toda a DEC. A DEC-0027 repete o que dela continua: o gdUnit4 6.2.1, o pre-commit abaixo de 15 s, o pre-push abaixo de 90 s, o LFS e o nunca `--no-verify` | [DEC-0027](DEC-0027-testes-e-entrega.md) | 2026-10-07 |
| [DEC-0004](DEC-0004-arquitetura-nucleo-puro-e-ddd-estrategico.md) | Só a frase "Som e VFX só tocam em tick novo, nunca na re-simulação" da regra 2. O resto da regra 2 e as outras regras continuam valendo | [DEC-0031](DEC-0031-tokens-de-leitura-e-base-da-interface.md) | 2026-10-08 |
| [DEC-0026](DEC-0026-a-rede.md) | Só a frase do §2 que dá o atraso de visão pelo `get_last_known_state()`. O resto continua valendo | [DEC-0031](DEC-0031-tokens-de-leitura-e-base-da-interface.md) | 2026-10-08 |
| [DEC-0028](DEC-0028-builds-versoes-e-fluxo-de-branch.md) | Só a frase "O push na main não gera build" do §2. O resto continua valendo | [DEC-0032](DEC-0032-hospedagem-do-servidor.md) | 2026-10-10 |
