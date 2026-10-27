---
id: DEC-0051
titulo: O combate no tick — a foto no começo do tick, o passo do combate antes do movimento, o contato aplicado no tick seguinte e a vaga dividida com o leve
data: 2026-10-27
status: aceita
decidido_por: Arthur (F-176; F-175 §2)
fontes: [F-007, F-073, F-173, F-175, F-176]
substitui:
substituida_por:
---

# DEC-0051 — O combate no tick

## Contexto

Até a fase 1, cada lutador só mexia no próprio corpo. O golpe leve da TASK-12.1 é a primeira regra em que um lutador muda o outro. A DEC-0026 §3 decidiu o princípio: um lutador escreve só o próprio estado e lê o dos outros numa foto do tick, tirada no `after_prepare_tick`, para a ordem dos nós na árvore não mudar o resultado; o contato fica no estado de quem ataca, e o resultado no de quem defende. A DEC-0026 §4 decidiu a conta da lâmina no núcleo, com a fatia varrida de cada tick. Faltavam a forma da foto, o lugar do combate no sanduíche da DEC-0022 e a convivência do leve com a vaga do buffer da DEC-0039.

O sanduíche de hoje é `before_move`, o motor e o `after_move` (DEC-0022 §2; DEC-0041). O `before_move` escreve os apertos na vaga, com o pulo vencendo o dash, que vence o gancho, no mesmo tick (DEC-0039 §4), e dispara o comando da vaga.

## Opções consideradas

1. **Um passo do combate antes do `before_move` (escolhida):** puro, com configuração própria. A ação muda antes de o movimento decidir, então o primeiro tick do golpe já anda devagar e não dispara outro comando.
2. **O leve dentro do `before_move`:** uma vaga e um lugar só, mas o `before_move` precisaria dos números do combate e mudaria de assinatura em todos os testes do movimento.
3. **O combate depois do movimento:** o golpe começaria um tick depois de o corpo já ter andado livre, e a lâmina testaria o atacante depois de mover contra o alvo antes de mover.

## Decisão

Aceita pelo Arthur no modo de plano (F-176), com as duas escolhas da abertura: o golpe anda a 3 m/s e o leve sai no botão esquerdo do mouse (F-175 §2).

1. **A foto:** no `after_prepare_tick` do netfox, depois de ele restaurar o estado do tick, o `Match` copia de cada lutador o nome do nó (a rota do netfox, única na partida), os pés e uma cópia do `FighterState` para uma `TickPhoto`, classe só de valores em `core/fighter/`. Cada lutador lê os outros só nela. Sem `Match`, a foto fica vazia.
2. **O passo do combate,** `Combat.step`, puro, em `core/fighter/combat.gd`, roda no `_rollback_tick` antes do `Movement.before_move`, nesta ordem:
   1. aplica os contatos da foto contra o lutador carimbados no tick anterior: o dano do golpe, a vida nunca abaixo de 0, e o `hurt_tick` com o tick do contato;
   2. a volta da vida ao máximo, quando a configuração a liga, 2 s depois do `hurt_tick`;
   3. avança a fase da ação pelos ticks do golpe;
   4. escreve o aperto do leve na vaga, chama a escrita dos comandos do movimento, e dispara o leve quando a vaga o guarda;
   5. a direção do golpe segue a câmera só na preparação;
   6. no ativo, a fatia do tick contra os outros da foto, em ordem de nome, com um contato por janela ativa.
3. **O contato no tick seguinte:** quem levou aplica o contato no primeiro tick em que a foto o mostra, o seguinte ao do carimbo. O dano e o tranco contam do tick do contato. Dois golpes que pegam no mesmo tick tiram o dano dos dois no tick seguinte, em qualquer ordem dos nós.
4. **A vaga dividida:** o leve é escrito na vaga antes do gancho, do dash e do pulo, então, no mesmo tick, qualquer comando do movimento vence o leve. Só o combate escreve o leve; o `before_move` continua escrevendo só os três comandos dele, por uma função extraída sem mudança (`Movement.take_presses`), que o combate também chama. Escrever o leve de novo no movimento devolveria à vaga o aperto que o combate acabou de disparar.
5. **O movimento lê a ação,** sem mudar a assinatura do `before_move`: com um golpe em curso, nenhum comando sai da vaga e não há pedido de mira; em pé, o alvo da velocidade é o andar devagar, 3 m/s; do primeiro tick ativo ao fim do golpe, o corpo olha para a direção do golpe.
6. **Os campos:** no `FighterState`, `action`, `action_since`, `action_move` (o golpe por ID, nunca o Resource; F-007 §5), `action_yaw`, `contact_tick`, `contact_target`, `contact_move`, `health` e `hurt_tick`; no input, `light_attack`. Os números do combate vêm de um `CombatData`, em ms, convertido na carga, como o `MovementData` (DEC-0004, regra 3).

## Consequências

- O sanduíche fica: restaurar, a foto, os contornos, o combate, o `before_move`, o motor, o `after_move` e a gravação (`visao-geral.md`, "O tick por dentro").
- Quem levou um golpe só o sente um tick, 16,7 ms, depois do contato. Nenhum número do `combate.md` muda, porque o tranco conta do contato.
- A fase 3 preenche o `view_lag` com as mesmas peças: a foto passa a vir do histórico de poses, e quem defende aplica o contato quando ele aparece na tela dele (DEC-0026 §3).
- Um golpe guarda um contato só. No 1v1 isso é "um acerto por alvo por janela ativa" (Q-26); um golpe que acerta dois alvos, no 4v4, pede outra forma (fase 4).
- O replay grava o `CombatData` no cabeçalho, como o `MovementData`, e um arquivo gravado antes toca só com `--force`.

## Revisitar se

- O tick de atraso aparecer na leitura, numa troca que o Arthur jogue e veja errada.
- O 4v4 pedir um golpe que acerta dois alvos.
- A fase 3 mostrar que a foto do começo do tick e o histórico de poses precisam ser a mesma peça.
