---
id: F-141
titulo: O Arthur acerta por que o núcleo pede o raio e aprova o plano da TASK-10.6, o gancho, no plan mode (sessão 16, 24/10/2026)
recebido_em: 2026-10-24
como: Resposta do Arthur por voz à conferência aberta (transcrição como chegou) e aprovação ao plano "TASK-10.6 — O gancho: o plano para o seu ok", no plan mode do terminal da sessão 16, sem texto.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: a primeira conferência aberta (DEC-0043). Antes dela, o Claude explicou que o núcleo é puro e não enxerga o cenário, então pede o raio da mira ao nó, que devolve a resposta nos fatos, como uma função pura do TypeScript que não pode fazer `fetch`. A pergunta: "Com as suas palavras: por que o núcleo pede o raio ao nó, em vez de olhar o cenário ele mesmo?"

## §1 — A resposta

"Porque o núcleo Porque o núcleo é... Porque aí seria alguma violação de camadas, provavelmente. Ele não... O núcleo é puro, ele não, não pode enxergar o cenário. Ele é só... um núcleo, entendeu? Ele não pode sujar, se sujar com o cenário, podemos dizer assim."

Certa, de primeira.

## §2 — O plano aprovado

**Duas escolhas de arquitetura:**

- **O pedido de mira:** no tick em que há um Q válido na vaga, o `before_move` liga `MovePlan.aim_request`. Depois do movimento, o nó lança o raio do ombro, só contra o cenário, e devolve `aim_hit`, `aim_point` e `position` no `MoveFacts`; o `after_move` decide se prende. A reserva, se a sonda B falhar, é o raio no `_process` com o acerto no input, e volta ao Arthur antes.
- **A altura da mira:** `aim_height_m` = 1,6 m no `MovementData`, cópia do pivô da câmera, com um teste que exige a igualdade com o `camera_v0.tres`.
- As duas viram a DEC-0044, com a sonda B antes de qualquer regra.

**Os números v0 do Claude:**

- não mudam: 25 m, o cabo de 100 ms, 18 m/s sem gravidade e sem input, a soltura a 1,5 m, a trava abaixo de 9 m/s (50%) a partir do 2º tick da puxada, a recarga de 6 s contada da soltura, sem custo, do chão, do ar e da parede (a corrida acaba no disparo), a velocidade conservada;
- mudam: os pés vão ao ponto (a soltura conta dos pés); o alcance vai de 3 a 25 m, medido do ombro; o pulo na puxada só solta, e o pulo duplo fica para o próximo aperto; um pulo apertado com o cabo voando não solta; sair do chão puxado não abre o coyote, e a parede ganha a mesma correção (Q-35); o dash espera na vaga com o cabo voando; o raio passa pelos lutadores e prende no cenário;
- o erro não gasta a recarga, o aperto espera na vaga pelos 150 ms, e o raio é refeito a cada tick; no mesmo tick, o pulo vence o dash, que vence o gancho.

**O sinal na tela:** a mira de 24 px que ganha um ponto de 5 px quando o Q prenderia agora; o cabo de 3 cm do ombro à ponta; o rastro curto na puxada; "No gancho" e a linha da recarga no HUD, acima da do dash.

**A arena:** `TorreA` e `TorreB`, de 4 × 6 × 4 m, com 16 m entre as faces, e o `Pilar10m`, de 2 × 10 × 2 m. O pilar pode escorregar para a TASK-10.7; o cabo não.

**A ordem:** a DEC-0044, os docs de desenho e a task Ready na main; a branch `task-10.6-grapple`; o test-writer (Fable, high) nos critérios 3 a 7 e na metade do `Aim` do 2, travados; o implementer (Opus 5.5, xhigh) nas rodadas A, B e C, parando se a sonda B falhar; o revisor (Fable, high), o portão e o Arthur jogando; push, PR e merge, cada um com o ok dele.
