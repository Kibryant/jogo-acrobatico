---
id: TASK-12.10
title: >-
  Os clipes de identidade à mão: parede, gancho, carregado, parry, finta e
  tranco no Blender
status: To Refine
assignee: []
created_date: '2026-10-27 22:02'
labels:
  - jogo
milestone: m-2
dependencies:
  - TASK-12.9
parent_task_id: TASK-12
ordinal: 37000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
Os 15 a 18 clipes que nenhuma base grátis tem (F-052 §7): a corrida na parede, o pulo da parede, a puxada do gancho, o carregado em fases, o parry, a finta, a quebra e o tech, o tranco, o KO. A DEC-0030 §5 deixou a ferramenta para quando o primeiro clipe fosse necessário; o Arthur escolheu o Blender, grátis, porque nada se paga antes da fase 3 (DEC-0034; F-174 §2; DEC-0050).

### Perguntas em aberto
- A lista exata dos clipes que faltam depois da TASK-12.9.

### Escolhas a confirmar
Nenhuma além da ferramenta, já escolhida.

### Fora do escopo
- Polimento de animação; a arte final (fase 5).

### O que você vai aprender
- O rig do UAL2 no Blender com o Rigify, e como um clipe in place volta ao Godot pela Animation Library (DEC-0030 §4).
- Por que a marca do ativo é feita à mão em cada clipe de golpe.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando um clipe de identidade entra, ele está na Animation Library compartilhada, in place, com a marca do ativo quando é golpe, e o arquivo-fonte do Blender fica fora do pacote do jogo, numa pasta com `.gdignore` no LFS (DEC-0030 §1).
- [ ] #2 Quando o lutador corre na parede, pula da parede, é puxado pelo gancho, carrega, apara, finta, agarra, responde ao tech, leva o tranco e cai no KO, cada estado tem o seu clipe, e a pose segue sendo função do estado.
- [ ] #3 Quando o carregado começa, a postura dele é diferente da do leve desde o primeiro tick, com a espada acima da cabeça (DEC-0031 §1).
- [ ] #4 Quando o Arthur assiste a um duelo contra o bot, ele nomeia cada golpe pela pose, antes da cor.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
