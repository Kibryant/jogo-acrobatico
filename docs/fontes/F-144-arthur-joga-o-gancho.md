---
id: F-144
titulo: O Arthur joga o gancho, gosta muito, acha certa a recarga longa, sente um "boost" ao soltar perto da parede e acha a mira ruim, com o boneco na frente dela (sessão 16, 26/10/2026)
recebido_em: 2026-10-26
como: Mensagem do Arthur por voz no terminal da sessão 16, com três prints da tela, depois de jogar duas sessões no Sozinho com `godot --path .` na branch `task-10.6-grapple` (5.949 e 12.851 ticks). Transcrição como chegou.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: o roteiro pedia prender no topo das torres, cruzar os 16 m, soltar cedo com o pulo, subir o pilar e esperar os 6 s (TASK-10.6, critério 9). Os três prints mostram a mira de 24 px em cima da cabeça da cápsula, no centro da tela: no chão perto de uma parede, de frente para uma parede e em cima de uma torre.

## §1 — A mensagem

"Tô te mandando alguns prints aqui, achei muito massa, eu acho que era isso que eu esperava. É muito foda a questão do gancho ali, gostei muito, o delay faz sentido ser grande. Achei muito foda. Eu vou pontuar só algumas coisas. A primeira coisa, eu não sei dizer exatamente se foi visual ou não. Eu acho que foi nessa partida, inclusive, na segunda, que eu fiz o quê? Eu soltei o gancho, e aí eu soltei o gancho, eu não subi na parede, eu fiquei... Sabe aquelas paredes de... que era pra andar na parede? Então, eu fiz o gancho em uma dessas paredes, eu meio que andei muito rápido, sei lá, parece que eu tinha ganhado um boost do nada quando eu soltei o gancho, grudei na parede, e sei lá, parece que eu tinha dado um boost e consegui correr mais rápido. Não sei se foi viagem minha, enfim, mas eu acho que só isso de diferente que aconteceu. E a segunda coisa, achei muito ruim de mirar. Você vai ver aí no que eu mandei, tipo, tava muito ruim pra mirar, eu não sabia onde eu tava mirando, sabe? Tipo, deu a sensação assim de que eu não sabia onde eu ia mirar. Tipo, não que eu não sabia, na verdade eu não sabia onde mirar, onde eu tava mirando exato, sabe? Eu achei a mira meio difícil. Não ficou muito legal, não. Essa questão da mira ali. Parece que tipo, o boneco ficou muito perto da imagem. Não deu pra mirar certo, sabe? Não sei explicar melhor. Eu acho que os prints talvez falem. A mira, tipo, o meu boneco ficava na frente da mira, sabe? Eu acho que é isso. A mira tem que dar uma melhorada. Eu acho que é isso. É isso, mas gostei muito."

## §2 — O que os replays mostram (medido pelo agente)

- **Sessão 1 (99 s):** 11 apertos de Q e 5 ganchos; 5 solturas pela distância; em cima da `TorreA` uns 4 s e da `TorreB` uns 20 s; os pés chegaram a 10 m perto do pilar, sem pousar nele; 1 aperto na recarga e 5 apertos seguidos sem superfície de 3 a 25 m na mira.
- **Sessão 2 (214 s):** 13 apertos e 12 ganchos; 11 solturas pela distância e 1 pelo pulo; em cima da `TorreA` uns 32 s, da `TorreB` uns 29 s e do `Pilar10m` uns 19 s; os pés chegaram a 13,6 m, 3,6 m acima do topo do pilar.
- **O "boost":** na sessão 2, a soltura do tick 12125 ficou ao lado do `CorredorOeste`, com os pés a 4,3 m. O corpo seguiu no ar, colado na parede, a 15 m/s ao longo dela por mais de 0,7 s, quase o dobro dos 8 m/s da corrida na parede. Não foi uma corrida na parede: com os pés a 4,3 m, a parede de 5 m não passava da cabeça, e a entrada foi recusada. São os 18 m/s da soltura, conservados, que a batida virou para o comprido da parede.
- Os dois replays tocam idênticos no tocador sem tela (primeiro tick divergente: nenhum).

## §3 — O que o agente lê (não é decisão)

- O gancho agradou, e a recarga de 6 s pareceu certa.
- O "boost" é real e vem de duas regras desenhadas: a velocidade se conserva entre manobras, e no ar o input não corta o excesso (`movimento.md`, "Princípios"; F-127).
- A mira fica atrás do próprio corpo: a câmera está centralizada, 3,5 m atrás do ombro e na altura dele, então o centro da tela passa pela cabeça da cápsula. O `movimento.md` deixou o deslocamento para o ombro para a mira das armas de longe ("Câmera"); o gancho é a primeira coisa que se mira, e a DEC-0044 já previa revisitar o raio quando a câmera ganhar o ombro.
