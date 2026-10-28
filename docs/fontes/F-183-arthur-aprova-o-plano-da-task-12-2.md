---
id: F-183
titulo: O Arthur aprova o plano da TASK-12.2 no modo de plano — a guarda e o tranco na ação, o contato resolvido por quem defende e a paradinha de cada um a partir de quando sabe o resultado (sessão 20, 28/10/2026)
recebido_em: 2026-10-28
como: Aprovação do Arthur ao plano que o Claude apresentou no modo de plano do Claude Code, na sessão 20, sem texto junto. O plano aprovado está resumido abaixo; o arquivo inteiro ficou em `C:\Users\arthu\.claude\plans\playful-kindling-hare.md`.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: o plano abria com uma correção ao que o Arthur tinha aceitado no refino (F-182): a paradinha não pode começar no mesmo tick para os dois, porque quem bateu só sabe se o golpe pegou ou foi bloqueado um tick depois de quem levou, pela foto (DEC-0026 §3; DEC-0051 §3). O plano repetia a conferência aberta da DEC-0043 que a F-182 deixou sem resposta: "se no impacto só quem levou o golpe congelasse, e quem bateu continuasse andando no tempo, o que aconteceria com a vantagem de quem bateu?". O Arthur aprovou sem responder a conferência. É a quinta conferência da sessão 20 sem resposta (F-172, F-175, F-176, F-182 e esta).

## §1 — O plano, como foi aprovado (resumo)

- **A ação ganha `BLOCK`, `HITSTUN` e `BLOCKSTUN`,** e o estado ganha `stun_until_tick`, `block_tick` e `frozen_until_tick`.
- **A guarda:** o input `guard`, segurado, no botão direito; com o botão, em pé no chão, sem golpe, sem tranco e sem congelar, a ação vira `BLOCK`, alta depois de 6 ticks; soltar derruba; o leve sai da guarda; o pulo, o dash e o gancho a derrubam no `before_move`; o andar devagar de 3 m/s com ela alta.
- **O contato resolvido por quem defende,** pelo próprio estado do fim do tick do contato: bloqueia com a guarda alta, o atacante a até 90° e stamina para o custo (5 de stamina, blockstun de 15, paradinha de 2); senão leva (o dano, hitstun de 24, paradinha de 4, o golpe dele acaba). Um golpe novo recomeça o tranco; depois do blockstun, com o botão segurado, a guarda já está alta.
- **A paradinha:** quem levou congela no tick seguinte ao contato; quem bateu, um tick depois, quando a foto mostra o `hurt_tick` ou o `block_tick` do alvo naquele contato, pela mesma duração; sem resultado, nada congela. Congelado, o núcleo não anda a fase nem testa a lâmina, o nó pula o motor e o `after_move`, a velocidade fica no corpo, e o `action_since` e o `stun_until_tick` andam a duração para a frente.
- **A tela:** o tremor da câmera por evento, com a linha "Tremor da câmera" nas opções; os tokens como Resource em `data/`; a forma e a cor do estado do outro no HUD; o boneco que dá um leve a cada 180 ticks, virado para quem joga.

## §2 — A resposta

O plano foi aprovado no modo de plano, sem texto.
