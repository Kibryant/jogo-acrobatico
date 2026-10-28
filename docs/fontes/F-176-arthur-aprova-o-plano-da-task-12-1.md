---
id: F-176
titulo: O Arthur aprova o plano da TASK-12.1 no modo de plano — a foto do tick, o passo do combate antes do movimento e o contato aplicado no tick seguinte (sessão 20, 27/10/2026)
recebido_em: 2026-10-27
como: Aprovação do Arthur ao plano que o Claude apresentou no modo de plano do Claude Code, na sessão 20, sem texto junto. O plano aprovado está resumido abaixo, como foi mostrado; o arquivo inteiro ficou em `C:\Users\arthu\.claude\plans\playful-kindling-hare.md`.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: a TASK-12.1 muda o tick (AGENTS.md: mudança de arquitetura passa pelo modo de plano e pelo ok do Arthur). O plano abria com a conferência aberta da DEC-0043, repetida da F-175: "se cada lutador lesse o outro ao vivo, e não na foto, o que daria errado quando os dois golpeiam no mesmo instante?". O Arthur aprovou sem responder a conferência pela segunda vez. A leitura do agente: a aprovação é a decisão dele (DEC-0015); a conferência fica registrada como não respondida, e a explicação volta no "depois" da task, quando ele vir a troca acontecer jogando.

## §1 — O plano, como foi aprovado (resumo das seções 1 a 5)

- **A foto do tick:** no `after_prepare_tick` do netfox, o `Match` copia de cada lutador o nome, os pés e o estado para uma `TickPhoto`, em `core/fighter/`; cada lutador lê os outros só nela (DEC-0026 §3).
- **O passo do combate antes do movimento:** o `Combat.step`, puro, aplica os contatos que a foto mostra contra o lutador, carimbados no tick anterior; faz a vida voltar ao máximo 2 s depois do último golpe levado, no treino do Sozinho; avança a fase da ação; escreve o aperto do leve na vaga e dispara o leve em pé no chão, sem golpe em curso, com 8 de stamina; segue a câmera com a direção do golpe só na preparação; e, no ativo, testa a fatia do tick contra os outros da foto, com um contato por janela ativa.
- **O movimento aprende a ação,** sem mudar a assinatura do `before_move`: com um golpe em curso, nenhum comando sai da vaga; em pé, o alvo da velocidade é 3 m/s; do primeiro tick ativo ao fim, o corpo olha para a direção do golpe.
- **A vaga:** o leve é escrito antes do pulo, do dash e do gancho, então no mesmo tick qualquer tecla de movimento vence; só o combate escreve o leve.
- **O preço da foto:** quem levou vê o contato um tick depois, 16,7 ms; o dano e o tranco contam do tick do contato.
- **O estado novo:** `action`, `action_since`, `action_move`, `action_yaw`, `contact_tick`, `contact_target`, `contact_move`, `health` e `hurt_tick`. **O input novo:** `light_attack`, no botão esquerdo do mouse.
- **Os números:** um `CombatData` em ms, m e graus, com o leve num sub-recurso por golpe; o andar de 3 m/s no `MovementData`.
- **A lâmina:** o segmento radial da mão, a 0,6 m do eixo, à ponta, a 2,0 m, a 1,3 m de altura; a fatia do tick k do ativo de −60° + 20°·(k − 1) a −60° + 20°·k; o toque com a cápsula pela distância exata de até 0,43 m.
- **A tela:** a espada de blocos com a pose como função do estado, o rastro em vermelhão e o flash branco uma vez por evento, as duas barras de vida no HUD, a linha "Golpe leve" nas opções, e os tempos novos na tabela dos tokens.
- **O replay:** o cabeçalho grava o `CombatData` inteiro, como o `MovementData`.

## §2 — A resposta

O plano foi aprovado no modo de plano, sem texto.
