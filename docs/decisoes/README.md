# Decisões

Índice das decisões do projeto, em formato ADR. Cada arquivo tem Contexto, Opções consideradas, Decisão, Consequências e Revisitar se.

**Como ler:** só vale como regra o que está em "Vigentes". Decisão substituída fica no repositório para contar a história, nunca para ser seguida.

**Como mudar:** decisão aceita não se reescreve. Mudar de ideia gera uma DEC nova, com `substitui`. Na antiga só mudam `status` e `substituida_por`, e ela ganha no topo o aviso "⚠️ Substituída por DEC-XXXX em AAAA-MM-DD — não é a regra atual". Antes de criar, confira o último ID desta pasta. A skill `adr` faz esse passo a passo.

## Vigentes

| ID | Data | Decisão | Status |
|---|---|---|---|
| [DEC-0001](DEC-0001-engine-godot-gdscript.md) | 2026-10-02 | Godot 4.7.2 com GDScript | aceita |
| [DEC-0002](DEC-0002-piso-de-desempenho-renderer-e-fisica.md) | 2026-10-02 | 60 fps em 1080p no PC do Arthur, renderer Compatibility e física Jolt explícita | aceita |
| [DEC-0003](DEC-0003-rede-com-netfox.md) | 2026-10-02 | netfox, com servidor autoritativo e previsão com rollback, na main fixada num commit | aceita; os ticks por segundo saem do Desenho 3 (Q-01) |
| [DEC-0004](DEC-0004-arquitetura-nucleo-puro-e-ddd-estrategico.md) | 2026-10-02 | Núcleo puro, nós finos, DDD só estratégico e as seis regras | aceita; a frase sobre a RewindableStateMachine foi substituída pela DEC-0022 |
| [DEC-0005](DEC-0005-codigo-tipado-e-pastas-por-feature.md) | 2026-10-02 | Tipagem obrigatória, pastas por feature e formatador da GDQuest | aceita; completada pela DEC-0022, que torna o acesso inseguro um erro e dá nome às pastas |
| [DEC-0006](DEC-0006-testes-e-portao.md) | 2026-10-02 | gdUnit4, cinco camadas de teste e o mesmo portão no pre-push e no CI | aceita; o pipeline se confirma no Desenho 4. O CI rodou verde no primeiro push, num repositório privado sem regra de branch (Q-03; F-017 §2) |
| [DEC-0007](DEC-0007-base-markdown-git-backlog-md.md) | 2026-10-02 | Markdown e git, com tasks no Backlog.md, no padrão do SkinHub | aceita |
| [DEC-0008](DEC-0008-idioma.md) | 2026-10-02 | Inglês no que é interno, português no que o Arthur lê, inclusive as tasks | aceita; as tasks em português foram confirmadas pela Q-08 (F-010 §2) |
| [DEC-0009](DEC-0009-harness-do-claude-code.md) | 2026-10-02 | A harness do SkinHub, mais leve | aceita |
| [DEC-0010](DEC-0010-construir-e-ensinar.md) | 2026-10-02 | O Claude constrói e ensina; o Arthur dirige | aceita |
| [DEC-0011](DEC-0011-direcoes-para-depois.md) | 2026-10-02 | Direções para validação de acerto, hospedagem e replay | aceita, como direção |
| [DEC-0012](DEC-0012-fase-de-desenho-antes-do-codigo.md) | 2026-10-02 | Fase de desenho com seis conversas e um esqueleto andante | aceita na sessão 2 (F-010 §2) |
| [DEC-0013](DEC-0013-camera-em-terceira-pessoa.md) | 2026-10-02 | Câmera em terceira pessoa | aceita; os números da câmera saem na rodada 2 do Desenho 1 |
| [DEC-0014](DEC-0014-tribo-do-combate-for-honor.md) | 2026-10-02 | Tribo do combate For Honor e Chivalry 2: tempo fixo e aviso claro | aceita |
| [DEC-0015](DEC-0015-registrar-ter-posicao-e-dizer-nao.md) | 2026-10-02 | O Claude registra o que o Arthur pensa em voz alta, tem posição e diz não | aceita; completa a DEC-0010 |
| [DEC-0016](DEC-0016-cancelamento-so-desenhado.md) | 2026-10-02 | Cancelamento só desenhado: na lista, com preço, com aviso e com janela larga | aceita; a lista do v0 é hipótese até a fase 2 |
| [DEC-0017](DEC-0017-numeros-v0-o-claude-fecha-o-arthur-sente.md) | 2026-10-02 | Números v0: o Claude fecha pela melhor experiência do jogador, e o Arthur julga jogando | aceita |
| [DEC-0018](DEC-0018-nome-provisorio-jogo-acrobatico.md) | 2026-10-02 | Nome provisório "Jogo Acrobático" até o fim da fase 1 | aceita |
| [DEC-0019](DEC-0019-numeros-em-artefato-visual.md) | 2026-10-02 | Número, medida e cálculo se mostram ao Arthur num artefato visual | aceita |
| [DEC-0020](DEC-0020-linguagem-gdscript-e-nucleo-trocavel.md) | 2026-10-02 | GDScript no jogo todo; só o núcleo muda de linguagem, se a medição de CPU pedir | aceita; completa a DEC-0001 |
| [DEC-0021](DEC-0021-explicar-no-mundo-do-arthur.md) | 2026-10-02 | Explicar no mundo do Arthur: pergunta fixa de entendimento, exemplo do que ele conhece e escolha como trade-off | aceita; completa a DEC-0010 |
| [DEC-0022](DEC-0022-arquitetura-detalhada.md) | 2026-10-02 | Arquitetura detalhada: estado em quatro caixas, máquina de estados no núcleo, tick em sanduíche, cenas, zero autoloads nossos, pastas e acesso inseguro como erro | aceita; substitui só a frase da DEC-0004 sobre a RewindableStateMachine. As cenas e as pastas foram aprovadas no plano (F-022) |

## Propostas — ainda não são regra

Nenhuma proposta aberta.

## Histórico

| Decisão | O que foi substituído | Por | Data |
|---|---|---|---|
| [DEC-0004](DEC-0004-arquitetura-nucleo-puro-e-ddd-estrategico.md) | Só a frase "feita com a RewindableStateMachine do netfox". As seis regras continuam valendo | [DEC-0022](DEC-0022-arquitetura-detalhada.md) | 2026-10-02 |
