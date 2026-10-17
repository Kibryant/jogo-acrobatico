---
id: DEC-0037
titulo: O snap de reserva do contorno D — quando a sonda não acha o chão que o estado diz, o motor faz o snap
data: 2026-10-17
status: aceita
decidido_por: Arthur
fontes: [F-087, F-086, F-025]
substitui:
substituida_por:
---

# DEC-0037 — O snap de reserva do contorno D: quando a sonda não acha o chão que o estado diz, o motor faz o snap

## Contexto

O contorno D (DEC-0025 §2) acerta, no primeiro tick de cada rollback, o "estava no chão" que o `move_and_slide()` do Godot guarda do movimento anterior. Ele faz isso com uma sonda: 0,05 m/s por um passo de física, 0,83 mm, para baixo quando o estado diz chão e para cima quando diz ar (F-025 §4).

A SyncTest permanente da TASK-9 (critério 8; `test/fighter/fighter_sync_test.gd`) achou um caso que a sonda do Desenho 3 não cobria (F-087, contexto):

- a cápsula que sai correndo da beirada da plataforma de 1 m fica, por um ou dois ticks, apoiada na quina pela base redonda, de 1 a 6 cm abaixo do topo, presa pelo snap do chão;
- restaurada nesse tick, a sonda de 0,83 mm para baixo não encosta na quina, porque o apoio é inclinado;
- o snap que o próprio `move_and_slide()` da sonda faria não roda, porque o "estava no chão" do motor é do presente, em que o corpo já está no ar;
- o motor fica com "no ar", o tick refeito não puxa o corpo para a quina, e ele sai do chão um tick antes do que na primeira vez.

Na cena da beirada foram 84 divergências em 2.526 conferências, até 5,7 cm. O carimbo da saída do chão anda um tick para trás, e 1 dos 2 pulos de coyote se perdeu; as outras três cenas deram zero (F-087, contexto). No Sozinho nada muda, porque nada é refeito. Na rede, um rollback que comece nesse tick come o pulo de coyote dado no fim da janela, o pulo atrasado com que o Arthur subiu a escada dos blocos (F-086 §1).

## Opções consideradas

1. **E3, o snap de reserva:** depois da sonda, se o estado diz chão e o motor não achou chão, o lutador chama o `apply_floor_snap()`. É o mesmo snap que o `move_and_slide()` faz quando o "estava no chão" do motor é verdadeiro, e o alcance acompanha o snap do chão (0,121 m a 60 ticks). Deu zero divergência nas quatro cenas e 2 de 2 pulos de coyote, conferido pelo Claude, com o portão verde (F-087, contexto). **A escolhida.**
2. **E1, a sonda maior:** 0,2 m/s, 3,3 mm. Também deu zero divergência nas quatro cenas, mas é um número sem razão física, e outra quina pode pedir mais.
3. **E2, a sonda ainda maior:** 0,5 m/s, 8,3 mm. Deu zero divergência nas cenas em que foi medida.
4. **Deixar como está:** o critério 8 da TASK-9 fica vermelho, e na rede o pulo de coyote do fim da janela pode sumir.

## Decisão

1. **O contorno D ganha o snap de reserva.**
   - A sonda de 0,05 m/s continua.
   - Se depois dela o estado diz chão e o `is_on_floor()` do motor diz que não, o lutador chama o `apply_floor_snap()`.
   - A posição e a velocidade voltam ao que eram, como antes (DEC-0025 §2).
2. **Nos ticks em que a sonda acha o chão, nada muda.**
3. **As palavras do Arthur:**
   - Na pergunta, ele escolheu "E3, snap de reserva (Recomendado)", cuja descrição dizia: "Se a cutucada não acha o chão que o estado diz, o motor dá o puxão de todo tick. Duas linhas no lutador; zero divergência e 2 de 2 coyotes. Vira uma DEC nova que completa a DEC-0025." (F-087 §1)
   - A conferência errou e o Claude explicou de novo. Ele confirmou com "Continua a E3 (Recomendado)" (F-087 §2).

## Consequências

- A DEC-0025 continua valendo inteira; o índice a marca como completada por esta DEC.
- A ordem do tick do lutador não muda: o contorno D continua no primeiro tick de cada rollback, depois do contorno do transform e antes do sanduíche (DEC-0025, Consequências).
- O `rede.md` §4 ganha a frase do snap de reserva. Ela vai na proposta de docs do fechamento da parte 1 da TASK-9.
- A SyncTest permanente vigia o caso: a cena da beirada conta os pulos de coyote e exige 2 de 2.

## Revisitar se

- O Godot ganhar um jeito de definir o estado de chão do `CharacterBody3D`. O contorno D inteiro poderia sair (DEC-0025, Revisitar se).
- A SyncTest acusar divergência numa quina ou num degrau mais funda que o snap do chão.
- As manobras da fase 1 (parede, gancho, dash) mudarem o snap do chão.
