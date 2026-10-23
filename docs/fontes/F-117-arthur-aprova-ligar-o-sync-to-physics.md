---
id: F-117
titulo: O Arthur acerta por que a janela se separava e aprova ligar o sync_to_physics (sessão 15, 23/10/2026)
recebido_em: 2026-10-23
como: Resposta do Arthur à conferência do Claude e aprovação do plano no plan mode, no terminal da sessão 15, com a vitrine "Os dois relógios do tick" (https://claude.ai/artifact/Ape9s5PRHTeD2g335LAWmb). Opção escolhida e aprovação, como chegaram.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: a sonda de 23/10 mediu o replay de 11 180 ticks do Arthur (F-114).
> - Com o `sync_to_physics` desligado, a janela do `--watch` se separa da refeita sem tela entre o tick 342 e o 408, com no máximo 5 a 13 µm, a 30, 60 e 144 fps. Só a posição e a velocidade diferem, e a diferença não cresce.
> - Ligado, a janela sai igual byte a byte em todos os fps.
> - Com o modo ligado, 495 de 497 testes passaram. Os 2 que falharam fixavam "desligado" no cabeçalho do replay.

## §1 — A conferência

"Para conferir: por que, com o modo desligado, a janela do --watch dá um número um pouquinho diferente da refeita sem tela?": "O fator muda a cada quadro". Certa, de primeira.

## §2 — O plano

O Arthur aprovou o plano "Ligar o sync_to_physics" no plan mode. O plano:
- liga `netfox/time/sync_to_physics=true` numa DEC nova;
- guarda a configuração com um teste;
- faz os dois testes do replay seguirem a configuração;
- abre uma branch `sync-to-physics` com PR;
- passa por revisor, portão, `net_run.sh`, uma refeita com `--watch` e o jogo à mão.
