---
id: DEC-0010
titulo: Como trabalhamos — o Claude constrói e ensina, o Arthur dirige
data: 2026-10-02
status: aceita
decidido_por: Arthur
fontes: [F-002, F-003]
substitui:
substituida_por:
---

# DEC-0010 — Como trabalhamos: o Claude constrói e ensina, o Arthur dirige

## Contexto

O Arthur não quer ser espectador: "eu não quero codar e ficar só como um, um telespectador vendo você codar", e quer entender "o que está acontecendo, até para eu poder opinar" (F-003 §3). O briefing propôs seis sessões de estudo antes do código (F-002). O Arthur corrigiu: "a gente vai construindo o jogo junto [...] você vai construindo e me ensinando [...] Eu vou construir o projeto aprendendo o Godó" (F-003 §4).

## Opções consideradas

1. **Sessões de estudo separadas antes do código**: era a proposta do briefing, e o Arthur descartou (F-003 §4).
2. **Construir aprendendo**: a escolhida.

## Decisão

O Claude escreve todo o código e ensina enquanto constrói. O Arthur define a sensação, decide, revisa e testa. Em cada task:

1. **Antes do código**, em português: o que vamos construir, os conceitos de Godot, rede ou arquitetura que a task toca, e o plano. Mudança de arquitetura passa pelo plan mode e pelo ok do Arthur.
2. **Durante**: o estilo de saída Explanatory fica ligado.
3. **Depois**: o que mudou e por quê, os conceitos novos, com o glossário atualizado, e como testar e o que sentir.
4. **No fim da sessão**: o diário (skill `diario`).

Decisão que afeta sensação, arquitetura, dependência, tipagem ou ferramenta é do Arthur. São no máximo três perguntas por vez, cada uma com recomendação, como no SkinHub (F-009).

## Consequências

- Toda task tem a seção "O que você vai aprender".
- A definição de pronto inclui o diário da sessão e o glossário atualizado (`backlog/config.yml`).

## Revisitar se

- O Arthur sentir que está virando espectador.
- A explicação atrasar demais o trabalho.
