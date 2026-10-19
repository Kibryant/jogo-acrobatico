---
id: F-112
titulo: O Arthur abre a TASK-10.3 — acerta que o replay guarda as teclas e a câmera, e escolhe que o Sozinho grave sempre (sessão 14, 19/10/2026)
recebido_em: 2026-10-19
como: Respostas escolhidas nas opções de duas perguntas do Claude Code na sessão 14, na rodada que deixou a TASK-10.3 Ready. Texto das perguntas, dos rótulos e das descrições como foram mostrados.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: antes da rodada, o Claude explicou uma ideia, o replay por inputs, com o exemplo do replay do LoL, um arquivo pequeno que o cliente toca de novo, e disse que a escolha do `sync_to_physics` fica para depois da medição, com os números na mesa. A TASK-10.3 trazia duas escolhas; a segunda virou o passo "medir primeiro e voltar ao Arthur antes da TASK-10.4".

## §1 — A conferência

Pergunta: "Conferência (uma só é verdadeira): o que o arquivo de replay guarda a cada tick?"

Resposta: "As teclas e a câmera"

A opção dizia: "O input que você deu naquele tick; o resto se refaz rodando a partida de novo."

As outras opções eram "As posições do lutador", "Um vídeo da tela" e "O estado inteiro".

## §2 — A decisão

Pergunta: "O Sozinho grava todo jogo, sempre, em `user://replays/`, guardando os 20 arquivos mais novos?"

Resposta: "Sim, sempre (Recomendado)"

A opção dizia: "Quando você achar um bug jogando, o arquivo já existe. São uns 4 MB a cada 15 minutos de jogo; os 20 mais novos cabem em menos de 100 MB. Os testes gravam numa pasta temporária e nunca escrevem aí."

A outra opção era "Só quando eu pedir" ("O jogo grava só com `--replay=CAMINHO`. Um bug que você achar sem ter ligado a gravação não tem arquivo.").
