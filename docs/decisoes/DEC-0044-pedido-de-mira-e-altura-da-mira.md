---
id: DEC-0044
titulo: O pedido de mira e a altura da mira — o núcleo pede o raio pelo plano, o acerto volta nos fatos, e a altura do ombro mora no MovementData
data: 2026-10-24
status: aceita
decidido_por: Arthur (F-141)
fontes: [F-005, F-141]
substitui:
substituida_por: DEC-0045, só a direção pelo centro da tela com a câmera centralizada (§2)
---

> ⚠️ Em parte substituída por DEC-0045 em 2026-10-26: o raio não sai mais do ombro, e a câmera não é mais centralizada (§2). O raio sai do ponto O, na linha do centro da tela, 0,8 m à direita do ombro, calculado pelo núcleo, e um segundo raio do ombro ao ponto recusa a quina. O resto desta DEC continua valendo: o pedido de mira (§1), a cópia no `MovementData` (§3) e a sonda B (§4).

# DEC-0044 — O pedido de mira e a altura da mira: o núcleo pede o raio pelo plano, o acerto volta nos fatos, e a altura do ombro mora no `MovementData`

## Contexto

O gancho (TASK-10.6) prende num ponto do cenário a até 25 m, onde a mira aponta (`movimento.md`, "Gancho"). É a primeira regra que precisa perguntar ao cenário algo além do contato do próprio movimento: "o que tem na mira?". O núcleo é puro e não enxerga o cenário (DEC-0004, regra 1). O nó só chama o núcleo e espelha o estado (DEC-0004, regra 2).

O caminho já existe para a parede. O motor move, e o nó entrega ao núcleo, no `MoveFacts`, os fatos do contato e o raio acima da cabeça, que só lê o espaço da física (DEC-0042; `rede.md` §4). Com o rollback forçado, o raio da cabeça deu 0 divergência da resposta, do corpo e do estado (TASK-10.10; `rede.md` §4). O gancho difere em duas coisas:

- o raio é longo, 25 m, e só faz sentido no tick em que há um aperto válido;
- ele sai do ombro, pela mira da câmera, e o servidor dedicado não tem câmera.

A posição já entra no `before_move` desde a TASK-10.1, à espera do gancho (DEC-0039 §2).

A conferência aberta veio antes desta decisão. Perguntado por que o núcleo pede o raio ao nó, o Arthur respondeu: "seria alguma violação de camadas [...] O núcleo é puro, ele não, não pode enxergar o cenário" (F-141 §1).

## Opções consideradas

1. **O pedido de mira no tick (escolhida):** o núcleo liga um pedido no plano, o nó lança o raio depois do movimento, e a resposta volta nos fatos. Fica um sanduíche só, e o servidor refaz o raio ele mesmo. Custa um raio por tick, enquanto há um aperto válido na vaga.
2. **O raio sempre, em todo tick:** o nó responde a mira sem pedido. É mais simples no núcleo, mas custa um raio por tick e por lutador para nada, e enche os fatos de uma resposta que quase nunca serve.
3. **O raio no `_process`, com o acerto no input:** o PC de quem joga mira e manda o ponto. O servidor teria de confiar num ponto que o cliente escolhe, e um cliente adulterado prenderia através das paredes (DEC-0026 §1; F-005 §4). Fica como reserva, se a sonda B achar o raio diferente no tick refeito.

Para a altura da mira:

1. **Uma cópia no `MovementData` (escolhida):** `aim_height_m` = 1,6 m, guardada por um teste que exige a igualdade com o pivô do `camera_v0.tres`. O núcleo e o servidor leem a altura junto dos outros números do movimento. O número fica em dois arquivos, e o teste pega a diferença.
2. **Derivar no `MovementConfig.create` a partir do `CameraData`:** uma fonte só, mas o movimento passa a depender da câmera.

## Decisão

Aceita pelo Arthur em 24/10/2026, no plan mode da TASK-10.6 (F-141 §2), depois de acertar a conferência aberta (F-141 §1).

1. **O pedido de mira.** No tick em que a vaga do buffer guarda um aperto do gancho que pode sair, o `before_move` liga `MovePlan.aim_request`. Depois do movimento, o nó lança o raio, do ombro e pela mira daquele tick, só contra o cenário (`PhysicsLayers.WORLD`, sem o próprio corpo). Ele preenche `MoveFacts.aim_hit` e `MoveFacts.aim_point`, e `MoveFacts.position` traz a posição depois do movimento. O `after_move` decide se o gancho prende, pelo alcance medido do ombro. Sem pedido, não há raio.
2. **A direção da mira** é uma função pura do núcleo, `Aim.direction(yaw, pitch)`, a mesma que o nó usa no raio. Com a câmera centralizada, o raio do ombro passa pelo centro da tela (`fighter/camera_rig.gd`, `_follow`).
3. **A altura da mira.** `aim_height_m` = 1,6 m fica no `MovementData`, como cópia do pivô da câmera, e um teste de dados exige a igualdade com o `camera_v0.tres`.
4. **A sonda B roda antes de qualquer regra.** Com o rollback forçado de 7 ticks, ela confere que o raio de 25 m sai igual no tick novo, no refeito e num quadro de processo, contra uma parede de teste e contra o céu, e anota o custo de 1000 raios. Se falhar, o raio vai para o `_process` com o acerto no input, e o Arthur ouve antes.

## Consequências

- **O `MovePlan`** ganha `aim_request`; o **`MoveFacts`** ganha `position`, `aim_hit` e `aim_point`; o **`TickInput`** ganha `pitch` e `grapple`; o **núcleo** ganha `core/fighter/aim.gd`.
- **O `visao-geral.md`** ganha o pedido de mira no sanduíche, e o **`rede.md`** ganha o `pitch` e o `grapple` na tabela do input (§3) e o resultado da sonda B (§4).
- **O raio refeito** em cada tick refeito entra na SyncTest, no cenário do gancho (`rede.md` §8).
- **Online, a fase 3** decide o raio nos ticks previstos: um tick previsto reaproveita o último input, e um `grapple` de um toque dispararia de novo (TASK-10.6, "Fora do escopo").

## Revisitar se

- A sonda B ou a SyncTest acharem o raio diferente no tick refeito.
- O custo do raio pesar com 16 lutadores (DEC-0004, regra 6).
- A câmera ganhar o deslocamento de ombro das armas de longe, e o raio do ombro deixar de passar pelo centro da tela (`movimento.md`, "Câmera").
