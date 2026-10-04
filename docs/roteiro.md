---
revisado_em: 2026-10-04
fontes: [F-001, F-007, F-032]
---

# Roteiro

As fases do estudo, cada uma com o teste que pode encerrar o projeto sem culpa (F-001). As estimativas são para 10 horas por semana e somam de 24 a 36 meses.

| Fase | O que é | Duração estimada | Teste que encerra ou segue |
|---|---|---|---|
| 0 | Base, desenho e esqueleto andante (marco m-0) | 2 a 4 semanas | "Gosto de jogar ou só da ideia?" |
| 1 | Movimento: correr, parede, pulo, dash e gancho numa arena de blocos | 3 a 5 meses | "Divertido sozinho por 15 min?" |
| 2 | Duelo contra bot e percurso cronometrado | 3 a 4 meses | "Amigos entendem cada troca?" |
| 3 | 1v1 online | 6 a 9 meses | "Justo entre cidades diferentes?" |
| 4 | Alpha com 1v1 e 4v4, salas, bot, replay e Discord | 6 a 8 meses | "20 pessoas voltam sem ninguém pedir?" |
| 5 | Lançamento grátis no Next Fest | 3 a 5 meses | "30+ no pico uma semana depois?" |

## Mudanças em relação ao estudo

O detalhe de cada mudança está em `mudancas.md`.

- **Fase 0:** virou base do repositório, fase de desenho e esqueleto andante (DEC-0012).
- **Fase 1:** no estudo, era "movimento sem rede". O rollback exige que o movimento rode dentro do tick desde o começo (F-007 §2). O Desenho 3 decidiu: a fase 1 nasce no tick do netfox e é jogada sozinha, no modo "Sozinho" da `Main`, sem rede. A SyncTest no CI cobre cada manobra nova (DEC-0026).

A rota alternativa do estudo continua de pé: primeiro um jogo para jogar sozinho ou em dupla contra o computador, com a mesma movimentação, para formar público (F-001).
