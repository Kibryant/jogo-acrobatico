---
id: DEC-0003
titulo: Rede com netfox — servidor autoritativo, previsão com rollback, main fixada num commit
data: 2026-10-02
status: aceita
decidido_por: Arthur
fontes: [F-001, F-002, F-003, F-005]
substitui:
substituida_por:
---

# DEC-0003 — Rede com netfox: servidor autoritativo, previsão com rollback e main fixada num commit

## Contexto

O estudo pede um servidor autoritativo, com previsão e correção no cliente, interpolação dos outros jogadores e compensação de lag (F-001). A rede nativa do Godot não tem previsão (F-005 §10). O netfox faz previsão e rollback num relógio de ticks comum (F-005 §3).

O estado do netfox em 02/10/2026 (F-005 §8):

- O último release é a v1.35.3, de 11/2025. A main está 69 commits à frente, sem versão.
- O CI do netfox só testa no Godot 4.2.2.
- O bug #659 quebra os autoloads no primeiro import no 4.7.2.

## Opções consideradas

1. **netfox**, a escolhida.
2. **Rede nativa do Godot**: só replica estado, sem previsão (F-005 §10).
3. **Godot Rollback Netcode, do Snopek**: P2P e determinístico, feito para jogo de luta 2D (F-005 §10).
4. **Photon Fusion para Godot**: é comercial e está em preview (F-005 §10).

## Decisão

Usar o netfox, com os módulos core e extras, na main fixada num commit. A suíte de testes do netfox precisa passar no 4.7.2 antes de ele entrar no projeto. Aceito pelo Arthur em 02/10/2026 (F-003 §4; F-002).

Os ticks por segundo, 30 ou 60, saem de uma medição no Desenho 3 (Q-01).

## Consequências

- A compensação de lag a favor de quem ataca e a detecção do golpe de espada não vêm prontas: viram trabalho nosso, desenhado no Desenho 3 (F-005 §4).
- Para simular lag com 4 jogadores ou mais é preciso o clumsy, por causa do bug #554 (F-005 §6).
- Corpo rígido em rollback exige uma build não oficial do Godot. O movimento fica cinemático (F-005 §5).

## Revisitar se

- O #659, ou outro bug, travar o 4.7.2 sem contorno.
- O netfox não segurar 8 clientes com parry de 80 a 200 ms; o estudo deixou isso em aberto (F-001).
