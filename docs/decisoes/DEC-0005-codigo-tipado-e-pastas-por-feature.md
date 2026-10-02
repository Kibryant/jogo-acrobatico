---
id: DEC-0005
titulo: Código — GDScript com tipagem obrigatória, pastas por feature e formatador da GDQuest
data: 2026-10-02
status: aceita
decidido_por: Arthur
fontes: [F-002, F-003, F-006]
substitui:
substituida_por:
---

# DEC-0005 — Código: GDScript com tipagem obrigatória, pastas por feature e formatador da GDQuest

## Contexto

O GDScript tem tipagem opcional, e os avisos do editor podem virar erro. A tipagem dá erro antes de rodar, autocomplete completo e código mais rápido. Não existe formatador oficial: o da GDQuest é o mais ativo, e o gdtoolkit está parado desde 10/2025 (F-006 §2 e §5).

## Opções consideradas

1. **Tipagem obrigatória, pastas por feature e formatador da GDQuest**, a escolhida.
2. Tipagem opcional, que é o padrão do Godot.
3. Pastas por tipo (`scripts/`, `scenes/`), que a documentação do Godot não recomenda (F-006 §12).

## Decisão

Aceita pelo Arthur em 02/10/2026 (F-003 §4; F-002):

- **Tipagem:** declaração sem tipo é erro (`untyped_declaration = 2`), e `:=` é permitido. Os acessos inseguros ficam como aviso (nível 1) e podem virar erro em `core/` no Desenho 2. `as` sem checagem é proibido: usa-se `is` com `assert`.
- **Pastas:** por feature, com `core/`, `common/`, `data/`, `assets/`, `addons/` e `test/`. Arquivos e pastas em snake_case; classes e nós em PascalCase.
- **Formatação e lint:** GDScript Formatter da GDQuest, versão 0.27.0, com tabs e linha de até 100 colunas.

## Consequências

- O editor, o pre-commit e o portão acusam código sem tipo e fora do formato.
- O formatador fica em `~/.local/bin` e no CI, sempre na mesma versão.

## Revisitar se

- O formatador da GDQuest parar de ser mantido ou não aceitar uma sintaxe nova do GDScript.
