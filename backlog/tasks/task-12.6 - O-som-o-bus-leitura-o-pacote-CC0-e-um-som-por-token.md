---
id: TASK-12.6
title: 'O som: o bus leitura, o pacote CC0 e um som por token'
status: To Refine
assignee: []
created_date: '2026-10-27 22:02'
labels:
  - jogo
milestone: m-2
dependencies:
  - TASK-12.2
parent_task_id: TASK-12
ordinal: 33000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
### Por quê
Os três canais só valem com os três (DEC-0031 §1), e o som nunca entrou no jogo porque só entra áudio com licença livre (DEC-0029; Q-32). O Arthur escolheu que ele entra na fase 2, com um pacote CC0 pequeno e um som por token (F-172 §2; DEC-0050; `visual-e-audio.md`, "O som entra na fase 2").

### Perguntas em aberto
- Qual pacote CC0: o implementer lista dois ou três candidatos conferidos na origem (DEC-0029 §2), e o Arthur escolhe antes de o pack entrar.

### Escolhas a confirmar
- O pacote, pela lista acima.

### Fora do escopo
- Música e ambiente. O som das manobras do movimento (pulo duplo, dash, parede, gancho), que entra junto só se o mesmo pacote tiver sons que sirvam; senão, outra filha.

### O que você vai aprender
- O bus com prioridade e o sidechain: por que o Godot não prioriza vozes sozinho (F-051 §5.1), e como 12 dB de ducking soam.
- A chave do evento também no som: tocar uma vez, nunca na re-simulação (DEC-0031 §6).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Quando um pacote CC0 entra, ele fica em `assets/third_party/<fonte>/<pack>/` com a licença ao lado e a linha no `CREDITS.md`, e o passo dos assets do portão passa (DEC-0029).
- [ ] #2 Quando cada estado da tabela dos tokens aparece pela primeira vez no estado exibido, o som dele toca uma vez, pela chave do evento, no bus "leitura"; a re-simulação não o toca de novo.
- [ ] #3 Quando um som do bus "leitura" toca, a música e o ambiente baixam uns 12 dB pelo sidechain e voltam depois (DEC-0031 §4).
- [ ] #4 Quando o jogo roda sem tela, nenhum player de som é criado, e o portão segue sem linha ERROR.
- [ ] #5 Quando a cena do leve roda na SyncTest, os sons apresentados são tantos quanto os eventos, como os sinais visuais.
- [ ] #6 Quando o Arthur joga com fone, ele diz o que ouviu de cada golpe: o "whoosh", o som longo do carregado, o "clang" do parry e o "thud" (F-063 §3, o canal que faltou).
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Critérios de aceite verificados
- [ ] #2 Teste automatizado para toda regra do núcleo (core/)
- [ ] #3 Diário da sessão escrito e glossário atualizado
- [ ] #4 Mudanças registradas em docs/mudancas.md
<!-- DOD:END -->
