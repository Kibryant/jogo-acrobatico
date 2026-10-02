---
id: DEC-0009
titulo: Harness do Claude Code — a do SkinHub, numa versão mais leve
data: 2026-10-02
status: aceita
decidido_por: Arthur
fontes: [F-002, F-003, F-008, F-009]
substitui:
substituida_por:
---

# DEC-0009 — Harness do Claude Code: a do SkinHub, numa versão mais leve

## Contexto

O Arthur quer usar o projeto para testar o Claude Code, com o SkinHub como base (F-003 §3). O briefing recomendou uma harness leve, com test-writer cego no núcleo, reviewer e portão rápido, e ele aceitou (F-002; F-003 §4). O SkinHub e o YabaBuss já fixaram nomes, formatos e lições (F-009).

## Opções consideradas

1. **A harness do SkinHub, mais leve**: a escolhida.
2. **A harness completa do SkinHub**: pesada demais para um hobby de 10 horas por semana (F-009).
3. **Sem harness**: deixa o agente sem trava e sem registro.

## Decisão

- **Arquivos:** o `AGENTS.md` é o canônico, em inglês, e o `CLAUDE.md` só importa esse arquivo.
- **Orquestração:**
  - A conversa principal orquestra: faz o "Entendi assim" com o Arthur e despacha, em série, o `test-writer`, o `implementer` e o `reviewer`.
  - O `test-writer` é cego e escreve os testes do núcleo antes do código.
  - O `implementer` não toca teste travado.
  - O `reviewer` trabalha com contexto limpo e começa do "não".
  - No fim, a conversa principal roda o portão.
  - O `explorer` só lê, e trabalho trivial fica com a conversa principal.
- **Modelos:** explorer, test-writer e reviewer em Fable. O implementer usa o modelo da sessão e passa para o Fable a partir da 4ª rodada.
- **Travas e registro:**
  - O teste travado tem o sha256 guardado em `.claude/harness/locks/` e é conferido no portão.
  - Cada task deixa uma linha em `.claude/harness/registro.md`, e o que se repete é promovido.
  - A harness só aperta; afrouxar é com o Arthur.
- **Permissão:** push, merge, criação de repositório e deploy param para pedido de permissão (`.claude/settings.json`).
- **Estilo e skills:** estilo de saída Explanatory e as skills `adr`, `diario` e `explicar`.

## Consequências

- Os hooks do próprio Claude Code, como travar teste por hook dentro do agente, ficam para o Desenho 4 (TASK-6). Eles precisam ser testados numa sessão real nesta máquina. Por enquanto a trava real é o portão, mais os hooks do git.
- A revisão mensal da harness segue o mesmo ritual dos outros projetos (F-009).

## Revisitar se

- A revisão mensal mostrar custo sem ganho.
- Um papel do agente nunca for usado.
