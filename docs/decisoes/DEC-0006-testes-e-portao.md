---
id: DEC-0006
titulo: Testes e portão — gdUnit4, cinco camadas, hooks rápidos e o mesmo portão no pre-push e no CI
data: 2026-10-02
status: aceita
decidido_por: Arthur
fontes: [F-002, F-003, F-006, F-007, F-009]
substitui:
substituida_por:
---

# DEC-0006 — Testes e portão: gdUnit4, cinco camadas, hooks rápidos e o mesmo portão no pre-push e no CI

## Contexto

Os dois frameworks de teste estão vivos no Godot 4.7. O gdUnit4 é mais ativo e testa cena com input simulado; o GUT é mais simples (F-006 §4).

No YabaBuss, um portão lento fez o agente contornar os hooks com `--no-verify` (F-009). O Arthur pediu CI/CD e infraestrutura na base desde o começo (F-003 §4).

## Opções consideradas

1. **gdUnit4, com o mesmo portão no pre-push e no CI**, a escolhida.
2. GUT.
3. Portão só no CI.

## Decisão

O framework foi aceito pelo Arthur em 02/10/2026 (F-003 §4; F-002). O resto é a base desta sessão, a confirmar no Desenho 4 (TASK-6).

- **Framework:** gdUnit4 6.2.1, fixado em `addons/gdUnit4`.
- **As cinco camadas de teste** (F-007 §7):
  1. a especificação do combate;
  2. o teste de rollback no estilo SyncTest;
  3. a checagem dos dados;
  4. o replay como referência;
  5. a rede testada à mão.
- **Pre-commit, abaixo de 15 s:** gitleaks, formatação e pureza do núcleo.
- **Pre-push, abaixo de 90 s, e CI:** `tools/gate.sh`. Ele roda formatação, lint, pureza do núcleo, testes travados, import e todos os testes.
- **Hooks:** gerenciados pelo lefthook, e nunca se usa `--no-verify`.
- **Binários:** arte, áudio, fontes e vídeo vão pelo Git LFS. O plano Free do GitHub dá 10 GB de armazenamento e 10 GB de banda por mês.

## Consequências

- O CI roda no GitHub Actions, com 2.000 minutos por mês num repositório privado no plano Free.
- O plano Free não aplica regra de branch em repositório privado (Q-03). Por isso o portão local é a trava real.
- O portão foi provado nesta máquina em 02/10/2026: 4 testes verdes, além da formatação, do lint e da pureza. O CI ainda não rodou, porque o repositório não tem remoto (TASK-2).

## Revisitar se

- O pre-commit passar de 15 s ou o pre-push passar de 90 s.
- O CI estourar a cota.
- O LFS passar de 10 GB.
