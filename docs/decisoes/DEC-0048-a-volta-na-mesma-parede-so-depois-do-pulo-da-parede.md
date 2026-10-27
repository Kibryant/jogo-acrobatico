---
id: DEC-0048
titulo: A volta na mesma parede só vale depois de um pulo da parede — completa a DEC-0047 e guarda o limite de 2,5 s
data: 2026-10-27
status: aceita
decidido_por: Arthur (F-168 §2)
fontes: [F-166, F-167, F-168]
substitui:
substituida_por:
---

# DEC-0048 — A volta na mesma parede só vale depois de um pulo da parede

## Contexto

A DEC-0047 §1 deixou a mesma parede aceitar uma corrida nova, sem devolver o pulo duplo, para o fake de "ir e voltar" (F-166 §3; F-167 §2). Na TASK-10.13, o implementer achou o que a regra antiga escondia: uma corrida que acaba pelo tempo, pela trava ou pelo disparo do gancho deixa o corpo encostado na parede, e a mesma parede começaria uma corrida nova no tick seguinte, com a vertical zerada. Segurar o direcional contra a parede faria a corrida sem fim, e a "Duração máxima" de 2,5 s cairia (`movimento.md`, "Corrida na parede"), contra a DEC-0047 §4 ("Nada mais muda"). Na conferência, o Arthur explicou: "porque a corrida recomeçaria toda vez que acaba encostada" (F-168 §1).

## Opções consideradas

1. **Só depois de um pulo da parede (escolhida):** a volta vale quando o voo atual começou com um pulo da parede. Qualquer outra saída recusa a mesma parede até o chão ou outra parede. Sem campo novo no estado.
2. **Depois de perder o contato:** pede um campo novo no rollback, e tirar o direcional da parede por um tick reabre a corrida sem fim.

## Decisão

Aceita pelo Arthur: "Só depois de um pulo da parede (Recomendado)" (F-168 §2).

1. **A mesma parede aceita uma corrida nova só quando o voo atual começou com um pulo da parede**, com as regras de entrada de toda corrida e sem devolver o pulo duplo (DEC-0047 §1 e §2).
2. **Uma corrida que acaba pelo tempo, pela trava, pelo gancho ou pelo contato** continua recusando a mesma parede até o chão ou outra parede, como antes da DEC-0047.
3. A DEC-0047 continua valendo; esta DEC completa o §1 dela.

## Consequências

- O limite de 2,5 s segue inteiro, e os testes antigos da corrida voltam a valer.
- Depois de uma corrida que acaba pelo tempo, cair e voltar com o pulo duplo para a mesma parede é recusado.
- A cena de um caso travado da TASK-10.13 ganha um caminho de volta mais longo, com o ok do Arthur, e a trava é refeita (F-168 §2).

## Revisitar se

- Jogando, o Arthur sentir falta da volta depois de uma corrida que acabou pelo tempo.
