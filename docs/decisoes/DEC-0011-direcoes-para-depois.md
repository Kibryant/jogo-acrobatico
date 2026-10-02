---
id: DEC-0011
titulo: Direções aceitas para depois — validação de acerto, hospedagem e replay
data: 2026-10-02
status: aceita
decidido_por: Arthur
fontes: [F-001, F-002, F-003]
substitui:
substituida_por:
---

# DEC-0011 — Direções aceitas para depois: validação de acerto, hospedagem e replay

## Contexto

O briefing deixou três decisões marcadas como "depois", cada uma com uma recomendação (F-002). O Arthur aceitou todas as decisões do briefing (F-003 §4). Elas valem como direção; o detalhe sai dos desenhos.

## Opções consideradas

As alternativas de cada ponto estão no briefing (F-002) e no estudo (F-001).

## Decisão

1. **Validação de acerto:** o tiro é julgado a favor de quem ataca, até ~220 ms. O bloqueio é julgado no tempo de quem defende (F-001). O detalhe sai do Desenho 3 (TASK-5).
2. **Hospedagem:** VPS em São Paulo com Docker, ou a Edgegap, se ela tiver região SP (F-001; F-005 §9). O detalhe sai do Desenho 6 (TASK-8).
3. **Replay:** por inputs, re-rodados no próprio servidor, na mesma build e na mesma plataforma (F-007 §6). O detalhe sai do Desenho 4 (TASK-6).

## Consequências

- Os desenhos partem destas direções, e mudar alguma delas exige uma DEC nova.

## Revisitar se

- O desenho de rede mostrar que a compensação de lag a favor de quem ataca não cabe no netfox (F-005 §4).
