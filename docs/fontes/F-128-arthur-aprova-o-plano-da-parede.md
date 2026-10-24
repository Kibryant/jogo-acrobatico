---
id: F-128
titulo: O Arthur aprova o plano da TASK-10.5, a corrida na parede, no plan mode (sessão 15, 23/10/2026)
recebido_em: 2026-10-23
como: Aprovação do Arthur ao plano "TASK-10.5 — A corrida na parede: o plano para o seu ok", no plan mode do terminal da sessão 15. Aprovação como chegou, sem texto.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: o plano veio depois das escolhas da F-127.

## §1 — O plano aprovado

**Quatro mudanças de arquitetura:**
- **Os fatos da parede como dado (DEC-0042):** `MoveFacts.wall_normal` e `MoveFacts.wall_id`. O estado guarda `wall_id` (o caminho do nó relativo à arena), `wall_normal` e `wall_jump_tick`, e nunca um RID do motor.
- **A sonda só de teste durante a corrida:** `move_and_collide` com `test_only`, 5 cm para dentro. Um empurrão de 1 m/s só entra se a sonda A mostrar falha numa emenda, e o Arthur ouve antes.
- **As duas trocas de modo pela DEC-0041:** a entrada por contato no `after_move` e o pulo da parede por comando no `before_move`. `WALL_RUN` é comprometido.
- **O momento no ar conservado:** o input gira e freia só pela aceleração do ar, sem cortar o excesso; no chão, o excesso cai aos poucos.

**Os números v0 do Claude:**
- parede de 80° ou mais;
- entrada a 4 m/s ou mais ao longo da parede;
- 8 m/s na parede, ou a velocidade de entrada até 12;
- 1,5 s de altura mantida, depois a descida de 10% da gravidade, crescendo por tick, até soltar aos 2,5 s;
- pulo da parede de 1,2 m e 5 m/s para fora, que conta como o primeiro pulo;
- mesma parede com a normal a até 10°;
- na arena: a `ParedeLonga` de 24 m, o corredor de 3,5 m e o patamar de 3 m.

**A ordem:**
- a sonda A antes de qualquer regra (se achar estado escondido, o Claude para e traz ao Arthur);
- o test-writer cego nos critérios 2 a 6 e nos dados do 7;
- o implementer nas rodadas B e C;
- o revisor, o portão e o `net_run.sh`;
- o Arthur jogando, com o ensaio de 15 minutos.

Se a rodada C estourar, a arena e o ensaio passam para uma filha de ajuste.
