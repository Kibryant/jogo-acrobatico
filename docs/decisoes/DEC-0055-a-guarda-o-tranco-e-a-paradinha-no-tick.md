---
id: DEC-0055
titulo: A guarda, o tranco e a paradinha no tick — a ação ganha a guarda e o tranco, quem defende resolve o contato pelo próprio estado, cada um congela quando sabe o resultado, e um tick congelado pula o motor
data: 2026-10-28
status: aceita
decidido_por: Arthur (F-183; F-182 §2)
fontes: [F-173, F-182, F-183]
substitui:
substituida_por:
---

# DEC-0055 — A guarda, o tranco e a paradinha no tick

## Contexto

A DEC-0051 pôs o golpe no tick: a foto, o passo do combate antes do movimento e o contato aplicado no tick seguinte. A TASK-12.2 põe a defesa e o peso do impacto: a guarda pela frente (DEC-0054), o tranco e a paradinha simulada, que congela os dois sem mudar a vantagem (`combate.md`, "O hitstop e o tremor"; F-173 §2). Três peças faltavam: onde a guarda e o tranco moram no estado, quem decide se um golpe foi bloqueado, e o que um tick congelado faz no sanduíche.

No refino, o Claude disse que os dois congelariam juntos a partir do tick seguinte ao contato (F-182, contexto). Isso não fecha com a DEC-0026 §3: a defesa é decidida por quem defende, que vê o contato um tick depois de quem bateu, e quem bateu só vê o resultado mais um tick depois, pela foto.

## Opções consideradas

Para a paradinha:

1. **Cada um congela quando sabe o resultado (escolhida):** quem levou no tick seguinte ao contato, quem bateu um tick depois, pela mesma duração. Um tick de diferença na tela; um golpe que não pegou nem foi bloqueado, como o esquivado, não congela ninguém.
2. **Os dois juntos, com uma duração provisória para quem bateu,** esticada quando o resultado chega: os mesmos ticks na tela, mas um golpe esquivado congelaria quem bateu por nada.
3. **Quem bateu decide o bloqueio** pela foto do alvo: contraria a DEC-0026 §3, e na fase 3 cada tela veria um resultado.

## Decisão

Aceita pelo Arthur no modo de plano (F-183).

1. **A ação ganha `BLOCK`, `HITSTUN` e `BLOCKSTUN`.** O estado ganha `stun_until_tick` (quando o tranco acaba), `block_tick` (o contato do último golpe bloqueado) e `frozen_until_tick` (o último tick congelado). O `hurt_tick` continua sendo o contato do último golpe que pegou.
2. **A guarda é uma ação:** `BLOCK`, com o tick em que começou a subir; está alta depois dos 6 ticks. O leve sai da guarda; o pulo, o dash e o gancho a derrubam no `before_move`; com o botão segurado, ela volta a subir em pé no chão, sem golpe e sem tranco.
3. **Quem defende resolve o contato** no passo 1 do `Combat.step`, pelo próprio estado do começo do tick, que é o do fim do tick do contato: bloqueia com a guarda alta, o atacante a até 90° (DEC-0054) e stamina para o custo; senão, leva, e o golpe dele em curso acaba.
4. **Cada um congela quando sabe:** quem levou ou bloqueou no tick em que resolve; quem bateu quando a foto mostra o `hurt_tick` ou o `block_tick` do alvo no contato dele. A duração é a do resultado (`combate.md`, "O hitstop e o tremor").
5. **Um tick congelado pula o motor:** o `Combat.step` só escreve os apertos na vaga e resolve contatos novos; o `before_move` devolve um plano congelado, e o nó não chama o `move_and_slide()` nem o `after_move`, então o corpo fica parado e a velocidade fica no corpo. Ao começar o congelamento, o `action_since` e o `stun_until_tick` andam a duração para a frente.

## Consequências

- O sanduíche ganha um caminho curto: num tick congelado, o nó para depois do `before_move` (`visao-geral.md`, "O tick por dentro").
- Quem bateu e quem levou param a mesma duração, um tick de diferença um do outro, e a vantagem não muda.
- O dash com invulnerabilidade da TASK-12.4 e o parry da TASK-12.3 dão resultados novos que quem bateu lê pela foto do mesmo jeito.
- Só o relógio do golpe e o do tranco andam com a paradinha; a stamina, a vaga do buffer e as recargas seguem o tick, e isso fica para rever se um congelamento no meio de uma manobra aparecer.

## Revisitar se

- O tick de diferença entre os dois aparecer na tela.
- Um congelamento no meio de um dash, de uma corrida na parede ou de uma puxada do gancho fizer a manobra acabar errado.
- A fase 3 mostrar que a foto do resultado chega tarde demais para a paradinha de quem bateu.
