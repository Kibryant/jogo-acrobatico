---
id: DEC-0042
titulo: Os fatos da parede — o caminho do nó como identidade, a normal no estado e a sonda só de teste durante a corrida
data: 2026-10-23
status: aceita
decidido_por: Arthur (F-127; F-128)
fontes: [F-127, F-128, F-100]
substitui:
substituida_por:
---

# DEC-0042 — Os fatos da parede: o caminho do nó como identidade, a normal no estado e a sonda só de teste durante a corrida

## Contexto

A corrida na parede (TASK-10.5) é o primeiro fato do motor que o núcleo lê além do chão. A DEC-0025 achou estado escondido no chão: o motor lembrava de um contato que o rollback não desfazia. A parede pode ter o seu. A regra da "mesma parede" (`movimento.md`, "Corrida na parede") precisa saber qual parede é qual, e essa resposta viaja na rede e no replay. Correndo paralelo a uma parede, o `move_and_slide()` pode não registrar colisão (`CharacterBody3D.xml`:86).

## Opções consideradas

1. **A identidade da parede:**
   - pelo caminho do nó do colisor relativo à `Arena`, junto com a normal (escolhida);
   - pelo id ou pelo RID do motor, cuja vida não está documentada.
2. **O contato durante a corrida:**
   - uma sonda só de teste (`move_and_collide` com `test_only`, 5 cm para dentro), que não move nada (escolhida);
   - um empurrão de 1 m/s para dentro, que suja a velocidade.
3. **Onde mora a parede:** nos fatos do movimento (`MoveFacts`), lidos pelo núcleo (escolhida), ou num nó que o núcleo consultasse, o que quebraria a pureza (DEC-0004).

## Decisão

Aceita pelo Arthur em 23/10/2026. Ele escolheu o caminho do nó (F-127) e aprovou o plano no plan mode (F-128).

1. **O `MoveFacts` ganha `wall_normal` e `wall_id`.** Eles valem `Vector3.ZERO` e `&""` sem parede. O nó os preenche depois de mover:
   - na entrada, pelas colisões do próprio movimento, com o colisor mais horizontal que não é um lutador;
   - durante a corrida, pela sonda só de teste.
2. **O estado guarda `wall_id`, `wall_normal` e `wall_jump_tick`.** O `wall_id` é `StringName(str(arena.get_path_to(collider)))`, que sai igual no servidor, no cliente, no SubViewport e no replay. Um RID ou um id do motor nunca entra no estado nem no input.
3. **A mesma parede** é o mesmo `wall_id` com a normal a até 10°, inclusive (`wall_same_face_deg`).
4. **A sonda A roda antes de qualquer regra.** Ela confere, com o rollback forçado de 7 ticks, que os fatos da parede saem iguais no tick novo e no refeito, numa emenda e num canto. Se a sonda só de teste perder o contato numa emenda, o empurrão de 1 m/s entra, e o Arthur ouve antes.

## Consequências

- **O `rede.md` §4** ganha o resultado da sonda A e a regra dos fatos da parede. O `visao-geral.md` ganha os campos.
- **A arena:** um colisor que mudar de nome muda a identidade da parede. Renomear nó da arena passa a mudar a impressão da arena no replay, como qualquer mudança nela.
- **O gancho (TASK-10.6)** pode identificar o ponto de ancoragem pelo mesmo caminho.

## Revisitar se

- A sonda A achar estado escondido na parede.
- Uma arena gerada em tempo de execução não tiver caminhos estáveis.
- O Godot documentar a vida do RID, se isso trouxer alguma vantagem.
