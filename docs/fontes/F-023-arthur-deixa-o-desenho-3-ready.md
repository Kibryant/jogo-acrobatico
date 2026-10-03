---
id: F-023
titulo: O Arthur deixa o Desenho 3 Ready — entende o problema da rede, acerta a conferência e escolhe medir 8 clientes já, com o clumsy (sessão 4, 03/10/2026)
recebido_em: 2026-10-03
como: Mensagem de abertura da sessão 4, seguida das respostas escolhidas nas opções de uma pergunta do Claude Code. Texto das perguntas e dos rótulos como foram mostrados.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: refinamento da TASK-5 (Desenho 3). Antes de perguntar, o Claude publicou a vitrine "A rede por dentro" (https://claude.ai/artifact/Sb4Q5e4M16UymdoaR9UAzp) e contou o que conferiu no dia: a main do netfox parada no `cf5189d` desde 26/09, o #659 ainda aberto, a suíte do netfox rodando sem tela e um risco novo na hipótese 3 da DEC-0022 (o `move_and_slide()` guarda o próprio "estava no chão", em `character_body_3d.cpp:95`). A pergunta das escolhas trazia uma recomendação; o Arthur escolheu outra opção, cujo texto dizia o custo dela.

## §1 — A abertura

"Bom dia, vamo fazer isso: deixar Ready o Desenho 3, a rede (TASK-5). É lá que o netfox finalmente roda no 4.7.2 e prova, ou derruba, as três hipóteses. É também onde se decide entre 30 e 60 ticks, já com a evidência do parry na mão."

## §2 — As respostas

Pergunta: "Pergunta fixa: deu para entender qual problema o Desenho 3 resolve e o que a gente vai fazer nele?"

Resposta: "Entendi"

Pergunta: "Você e o oponente com ping 100, a 30 ticks. Ele aperta o golpe leve. Quando o golpe começa na sua tela?"

Resposta: "Uns 100 a 170 ms depois"

Pergunta: "As cinco escolhas (seção \"O plano\" da vitrine): fecho com os padrões e marco a TASK-5 como Ready?"

Resposta: "Fechar, com 8 clientes já"

A opção dizia: "Mede 8 clientes nesta task. Exige o clumsy, ferramenta nova que pede administrador, e alonga a rodada 1."

A recomendada era "Pode fechar as cinco (Recomendado)", que deixava 8 clientes e jitter para a Q-09.

## §3 — As cinco escolhas, como a vitrine as mostrou

1. "O netfox na main fixada no `cf5189d`, core e extras (DEC-0003). Se a suíte falhar só nos 4 testes de float16, ele entra assim mesmo, sem usar float16. Se falhar em rollback, tempo ou sincronização, a sonda testa o release v1.35.3, e a escolha volta para você."
2. "O contorno do #659: os autoloads do netfox com `res://` no `project.godot`, guardados por um teste, em vez de remendar o código do netfox."
3. "As sondas moram fora do repositório, numa pasta `netfox-sonda` ao lado dele. O `rede.md` guarda o commit, a montagem e os números. A prova permanente nasce como teste na TASK-9 (DEC-0004, regra 4)."
4. "A medição usa o simulador do próprio netfox: um servidor dedicado, dois clientes e ping 0, 100 e 220. Sem ferramenta nova: 8 clientes e jitter ficam para a Q-09, porque o simulador trava com 4 ou mais (#554) e o clumsy pede administrador."
5. "A compensação de lag e a detecção do golpe ficam no papel, com a viabilidade conferida no código do netfox. O código delas nasce com a espada: local na fase 2, em rede na fase 3."

Com a resposta do §2, a escolha 4 muda: a medição também roda com 8 clientes, e o clumsy entra para eles. As outras quatro valem como foram mostradas.
