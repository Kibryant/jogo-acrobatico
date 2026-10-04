---
id: F-031
titulo: O Arthur desliga o Smart App Control do Windows, que passou a barrar o backlog.exe (sessão 4, 04/10/2026)
recebido_em: 2026-10-04
como: Mensagem do Arthur na sessão 4, enquanto o Claude investigava o bloqueio. Texto como chegou. O contexto vem dos comandos que o Claude rodou.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: ao gravar as notas da TASK-5, o `backlog.exe` deixou de rodar. O Git Bash dava "Permission denied", e o PowerShell dava "An Application Control policy has blocked this file". O log de Code Integrity do Windows registrou 9 bloqueios (eventos 3077 e 3033) entre 12:37:34 e 12:38:22 de 04/10/2026, e o `Get-MpComputerStatus` mostrava o Smart App Control como "On". O formatador, o gitleaks, o lefthook e o Godot seguiam rodando. O Claude ainda estava investigando e não tinha sugerido nenhuma mudança.

## §1 — A mensagem

"Desativei"

## §2 — O que se seguiu

- O `Get-MpComputerStatus` passou a mostrar o Smart App Control como "Off".
- O `backlog --version` voltou a responder: 1.53.0.
