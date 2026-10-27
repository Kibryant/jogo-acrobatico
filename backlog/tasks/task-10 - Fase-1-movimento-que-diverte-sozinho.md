---
id: TASK-10
title: 'Fase 1: movimento que diverte sozinho'
status: Done
assignee: []
created_date: '2026-10-02 16:48'
updated_date: '2026-10-27 14:47'
labels:
  - jogo
milestone: m-1
dependencies:
  - TASK-9
ordinal: 10000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
Fase 1 do roteiro (`docs/roteiro.md`): correr, subir na parede, pular, dar dash e usar o gancho numa arena de blocos. O teste da fase é "divertido sozinho por 15 min?" (F-001). Esta é a task-mãe: as filhas, do tamanho de uma sessão, nascem com `-p TASK-10`.

### As filhas (19/10/2026; F-100)
Nove filhas, uma por sessão, em cadeia, cada uma com você jogando algo novo no fim: TASK-10.1 pulo duplo e stamina; TASK-10.2 a barra na tela, o Theme e o vão de 6 m; TASK-10.3 o gravador de replay por inputs; TASK-10.4 dash; TASK-10.5 corrida na parede; TASK-10.6 gancho; TASK-10.7 a cabeça do outro, o boneco e a borda; TASK-10.9 a tela de opções; TASK-10.8 os 15 minutos, a Q-16 online e a versão 0.2.0. A TASK-10 fecha no PR da TASK-10.8, com os dois critérios marcados e a v0.2.0 (DEC-0028 §3). O plano da fase, com a interface, as sondas do motor e os riscos, está nas notas de cada filha; o critério 1 desta task é o critério 4 da TASK-10.8, e o critério 2 é o critério 7 da TASK-10.1 e o 2 da TASK-10.8.

### Perguntas em aberto
Nenhuma: os números estão no `movimento.md`, e as leituras v0 nascem em cada filha (DEC-0017; DEC-0036).

### Escolhas confirmadas
Confirmadas pelo Arthur em 19/10/2026 (F-100 §1): a ordem "sentir primeiro" (pulo duplo e stamina → gravador → dash → parede → gancho → cabeça, arena e 15 min), com o gravador antes da primeira manobra que muda um contato com o motor; as três escolhas da TASK-10.1 com os padrões; a tela de opções como filha própria (TASK-10.9), antes da v0.2.0.

### Fora do escopo
- Combate (fase 2). O percurso cronometrado com fantasma (fase 2). A bancada do Mac (Q-24, task pequena à parte).

### O que você vai aprender
- Game feel: aceleração, coyote time, buffer de input e câmera.
- A máquina de estados como dado: cada manobra é um valor do `mode` com os próprios carimbos, nunca um nó nem um timer (F-100 §2).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Quando o Arthur joga 15 minutos sozinho na arena de blocos, ele quer continuar (o teste da fase, F-001).
- [x] #2 Quando um número de movimento muda no Resource, o jogo muda sem tocar no código.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Fechamento do plano da fase 1 (19/10/2026; F-100):
1. Nove filhas, uma por sessão, cada uma com 5 a 8 critérios e o Arthur jogando algo novo no fim: TASK-10.1 pulo duplo e stamina; TASK-10.2 a barra na tela, o Theme e o vão de 6 m; TASK-10.3 o gravador de replay; TASK-10.4 dash; TASK-10.5 parede; TASK-10.6 gancho; TASK-10.7 a cabeça do outro, o boneco e a borda; TASK-10.9 a tela de opções; TASK-10.8 os 15 minutos, a Q-16 online e a versão 0.2.0.
2. Cada filha depende da anterior; a TASK-10.1 depende da TASK-9; a TASK-10.9 depende da TASK-10.2, e a TASK-10.8 depende da TASK-10.7 e da TASK-10.9.
3. O replay vem antes do dash porque o dash é a primeira manobra que muda um contato com o motor (DEC-0025; DEC-0027 §5).
4. A parede e o gancho rodam uma sonda do motor antes da regra, com precondição (rede.md §4); a cabeça do outro mede a velocidade de plataforma antes da regra (F-025 §3).
5. A TASK-10.1 fixa a interface da fase: o buffer de uma vaga, o before_move com a posição e a SyncTest comparando o estado inteiro (DEC-0039, a aceitar).
6. Duas DECs novas nas filhas: DEC-0039 (TASK-10.1) e DEC-0040 (TASK-10.4), cada uma substituindo a DEC-0022 só no que diz.
7. Nenhum papel de design novo (DEC-0036): cada número cita a seção do movimento.md, e uma lacuna é "leitura v0 do Claude", escrita lá antes do test-writer, julgada jogando (DEC-0017).
8. O primeiro ensaio cronometrado de 15 minutos é no fim da TASK-10.5, com pulo duplo, dash e parede; o oficial fecha a TASK-10.8.
9. O blueprint em inglês que gerou as filhas saiu do único workflow da task (19 agentes) e de um crítico de completude; as notas de cada filha trazem o rascunho do plano dela.
10. Pendência nova: Q-32 (som mínimo antes do teste da fase, só se o ensaio da TASK-10.5 disser que o silêncio pesa).
<!-- SECTION:NOTES:END -->

## Comments

<!-- COMMENTS:BEGIN -->
created: 2026-10-07 17:52
---
Entrada do Desenho 4, rodada 2 (TASK-6; F-044 §1): a gravação do replay por inputs começa nesta fase. Quando o Arthur achar um bug jogando o movimento, o arquivo de teclas vai junto, e o Claude refaz sem tela, em milissegundos (F-042 §3). É um gravador pequeno, no formato que o testes-e-entrega.md definir. O mesmo arquivo serve para o fantasma do percurso cronometrado (visao.md, onboarding).
---
<!-- COMMENTS:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
A fase 1 fechou com a versão 0.2.0. Critério 1: o Arthur jogou 15 min 38 s sozinho e continuaria jogando (F-166 §2; TASK-10.8). Critério 2: test/data/movement_tuning_test.gd muda o pulo duplo para 1,5 m numa cópia do Resource, e o jogo muda sem tocar no código (TASK-10.8). As manobras: pulo duplo, dash, parede, gancho, a mesma parede e a tampa da arena (TASK-10.1 a TASK-10.15).
<!-- SECTION:FINAL_SUMMARY:END -->
