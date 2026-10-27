---
id: TASK-10.15
title: 'O plano de morte: quem sai da arena volta ao início'
status: To Refine
assignee: []
created_date: '2026-10-26 23:44'
labels: []
dependencies: []
parent_task_id: TASK-10
ordinal: 24000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
A sonda do canto da TASK-10.8 mediu a saída da arena. No canto nordeste, o Z entre as duas bordas tem a última entrada a 47,85 m; um pulo duplo no topo, para o canto, leva os pés a 50,0 m, e a cápsula sobe na quina de cima da borda, anda por ela e cai do lado de fora, sem chão e sem fim. Um gancho a partir de uma corrida a 16,9 m faz o mesmo (`movimento.md`, "A borda"). O Arthur decidiu que, nesse caso, o plano de morte entra antes da 0.2.0: "cair fora da arena e voltar ao início" (F-167 §2).

### Perguntas em aberto
- Onde fica o plano: uma altura abaixo do chão, uma caixa em volta da arena, ou as duas.
- O que volta ao início: a posição no ponto de nascimento, a velocidade zerada, a barra e as recargas cheias, como um lutador novo.
- Online e no replay: o plano é uma regra do núcleo, que o servidor decide e o rollback refaz como qualquer outra.
- Uma tampa sobre a arena, na altura do topo da borda, tira a quina de cima e impede a saída antes da queda. Ela entra junto, no lugar do plano, ou não entra?

### Escolhas a confirmar
A confirmar com o Arthur no refinamento.

### Fora do escopo
- O que cair fora vale num duelo (fase 2).
- Mudar a borda, o Z ou o gancho.

### O que você vai aprender
- Uma rede de segurança no núcleo: a regra que pega o que o mapa não previu.
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
