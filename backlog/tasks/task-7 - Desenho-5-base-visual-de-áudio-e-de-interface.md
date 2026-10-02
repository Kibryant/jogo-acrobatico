---
id: TASK-7
title: 'Desenho 5: base visual, de áudio e de interface'
status: To Refine
assignee: []
created_date: '2026-10-02 16:48'
labels:
  - desenho
milestone: m-0
dependencies:
  - TASK-3
ordinal: 7000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
Quinta conversa da fase de desenho (DEC-0012). O combate precisa ser legível antes de ser bonito: antecipação proporcional ao dano, indicador visual e som (F-001). E todo asset de terceiros precisa da licença conferida (`assets/CREDITS.md`).

### Perguntas em aberto
- A direção de arte estilizada: fontes de assets (Kenney e Quaternius, CC0; Synty; Fab) e as licenças (F-001).
- O pipeline de import: glTF, escala e nomes.
- Os tokens da leitura do combate: cor e som por estado do golpe, pela janela de parry e pela arma de longe carregando.
- O tema da interface (Theme do Godot) e a acessibilidade: remapear teclas e cores seguras para daltonismo.
- A animação, o maior buraco do estudo: de 80 a 150 animações, com Mixamo ou Cascadeur (F-001).

### Escolhas a confirmar
- Greybox, só blocos, até o movimento ser divertido. Padrão sugerido: sim.

### Fora do escopo
- Arte final.

### O que você vai aprender
- Como o Godot importa modelo, animação e som, e o que é um Theme.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando a conversa termina, `docs/design/visual-e-audio.md` tem a política de assets, o pipeline de import e os tokens do combate.
- [ ] #2 Quando o Arthur decide a fonte de assets e a de animação, uma DEC registra, com a licença conferida.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
