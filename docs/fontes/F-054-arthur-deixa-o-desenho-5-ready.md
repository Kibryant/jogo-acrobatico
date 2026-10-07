---
id: F-054
titulo: O Arthur deixa o Desenho 5 Ready — pede modelo e esforço por tarefa com um teto de 5 agentes, entende o problema, erra duas vezes a conferência da licença, pergunta pela base da interface e confirma as cinco escolhas (sessão 8, 07/10/2026)
recebido_em: 2026-10-07
como: Mensagem de abertura da sessão 8, seguida das respostas escolhidas nas opções de duas perguntas do Claude Code (três e duas questões). Texto das perguntas, dos rótulos e das descrições como foram mostrados. A resposta da terceira questão do §2 veio digitada no campo livre.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: refinamento da TASK-7 (Desenho 5). Antes de perguntar, o Claude rodou um workflow de 5 agentes (quatro pesquisadores, em Opus 5.5 e Sonnet 5.5, e um verificador adversarial em Fable 5.1), como o Arthur pediu na abertura, e guardou os relatórios como F-050 a F-053. Publicou a vitrine "Legível antes de bonito" (https://claude.ai/artifact/LUcBUHKJaCfjfacgPHnmzX), com a linha do tempo do golpe em tempo real, a simulação de daltonismo, a matriz de licenças, a calculadora da cota do LFS, o buraco da animação e as cinco escolhas. A primeira conferência, sobre um pack com EULA num repositório, errou. O Claude explicou de novo com a skin do LoL e o jogo da Steam (compra-se o direito de usar, não o arquivo), com a frase da EULA da Synty e com o git que guarda o histórico. A segunda conferência, com um cenário (abrir o repositório um ano depois com o pack dentro), também errou. O Claude explicou uma terceira vez, com o álbum de fotos (cada commit é uma foto completa; apagar hoje não tira as fotos antigas do álbum), sem nova pergunta, acrescentou a figura à vitrine (versão 2) e abriu a rodada 1 da task com uma demonstração num repositório de sonda. A escolha 3, confirmada, mantém a regra conservadora: EULA só com o repositório privado para sempre.

## §1 — A abertura

"Boa tarde, vamo deixa Ready o Desenho 5 (TASK-7), a base visual, de áudio e de interface. Ativei o ultracode, max 5 agentes, gerencia eles com cautela, use modelos e efforts que facam sentido para a tarefa que ele for fazer, nao use so o fable 5.1 para todos sem necessidade."

## §2 — As primeiras respostas

Pergunta: "Pergunta fixa: deu para entender qual problema o Desenho 5 resolve e o que a gente vai fazer nele?"

Resposta: "Entendi"

A opção dizia: "O problema é como a arte, o som e a interface entram sem quebrar a leitura do combate nem a licença. A gente decide a política de assets, o pipeline, o caminho da animação, os tokens e a base da interface, em duas rodadas com sonda."

Pergunta: "Conferência: você compra o pack de animação de espada da Synty (EULA própria, US$ 59,99). Os arquivos podem entrar no repositório do jogo no GitHub?"

Resposta: "Sim, em qualquer repositório", cuja descrição dizia: "Depois de pagar, o arquivo é meu e posso guardar onde quiser."

A esperada era "Sim, mas só enquanto for privado", cuja descrição dizia: "O time pode usar; abrir o repositório seria compartilhar o arquivo-fonte com terceiros, e o git guarda o histórico."

Pergunta: "As cinco escolhas (seção \"O plano\" da vitrine): fecho com os padrões e marco a TASK-7 como Ready?"

Resposta, digitada: "1 mas me responde uma duvida, seria 1920 × 1080 a base da interface ne?"

A opção 1 era "Pode fechar as cinco (Recomendado)". O Claude respondeu que sim: a base da interface fica em 1920 × 1080, dentro da escolha 5, com guarda no teste de configurações; hoje vale o padrão de 1152 × 648, e a mudança no `project.godot` acontece na rodada 2.

## §3 — Depois da segunda explicação

Pergunta: "Nova conferência: daqui a um ano o jogo vai bem e você decide abrir o código no GitHub (Q-04). O pack da Synty está dentro do repositório desde a fase 2. O que acontece?"

Resposta: "Nada: eu paguei, pode abrir", cuja descrição dizia: "O pack foi comprado, então pode ficar num repositório público."

A esperada era "Tirar o pack e reescrever o histórico, ou ficar privado", cuja descrição dizia: "Abrir com o pack dentro, mesmo apagado depois, entrega o arquivo-fonte a terceiros, o que a EULA proíbe; o git guarda os commits antigos e os objetos do LFS."

Pergunta: "Com a licença explicada de novo: as cinco escolhas continuam valendo, com a base 1920 × 1080 dentro da escolha 5, e marco a TASK-7 como Ready?"

Resposta: "Continuam as cinco (Recomendado)"

A opção dizia: "A TASK-7 vira Ready como está na vitrine: greybox com a cápsula, duas rodadas com sonda, CC0 primeiro e EULA só privado com a checagem no portão, base CC0 de animação com os buracos à mão, três canais e a base da interface em 1920 × 1080."

## §4 — As cinco escolhas, como a vitrine as mostrou

1. "Greybox até o movimento ser divertido. A arena é de blocos e o lutador é a cápsula no esqueleto andante (TASK-9) e no começo da fase 1. O pipeline é provado agora, na sonda, para o primeiro boneco CC0 entrar na fase 1 sem surpresa, quando os números do movimento estiverem bons."
2. "Duas rodadas com sonda, fora do repositório. Como nos Desenhos 3 e 4: cada rodada abre com algo rodando de verdade neste PC, e o fechamento passa pelo modo de plano com um agente de planejamento revisando antes."
3. "A política de assets. CC0 primeiro (Kenney, Quaternius, KayKit, Poly Haven); CC BY com crédito; OFL, Apache e MIT para fontes e ícones. EULA (Synty, Sonniss, Mixamo) só com o repositório privado para sempre, registrado no CREDITS.md. Recusar NC, ND, Editorial, só-Unreal, uso pessoal, RemArc e BY-SA. Nada pago sem o seu ok, dentro dos R$ 3 a 7 mil por ano do estudo. \"Asset sem linha não entra\" vira checagem do portão."
4. "O caminho da animação. Base CC0 com um rig só (UAL1 v2.0 + UAL2), KayKit para arco e armas depois de um teste de retarget, e os 15 a 18 clipes de identidade feitos ou ajustados à mão. A ferramenta (Cascadeur Indie ou Blender com Rigify) se escolhe na fase 1, quando o primeiro clipe de parede for necessário. Nada se compra agora. Paragon não entra."
5. "Os tokens e a base da interface. Três canais por estado; a cor marca a exceção e o leve fica sem cor; paleta no eixo azul–amarelo da Okabe-Ito, provada na sonda; sinal no mundo, HUD como redundância; bus de som com prioridade; cor de time separada. Um Theme, base 1920 × 1080 com guarda, teclas físicas remapeáveis, nunca só por cor, chaves de tradução por ID. Os tokens viram dado num Resource e só tocam no tick novo."
