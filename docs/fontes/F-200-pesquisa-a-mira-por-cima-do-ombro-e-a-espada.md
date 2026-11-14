---
id: F-200
titulo: Pesquisa — a mira de quem atira por cima do ombro, o tiro que vai da arma ao ponto da mira com um ponto fixo quando o raio não acha nada, e a assistência que mira a espada no Naraka (sessão 22, 14/11/2026)
recebido_em: 2026-11-14
como: Três buscas na web feitas pelo Claude no refino da TASK-12.14, antes de recomendar o ponto da espada, como o Arthur pediu (F-180 §2). Resumo pelos resultados das buscas; as páginas não foram abertas uma a uma.
status: vigente
substituida_por:
---

## §1 — Nos jogos de tiro em terceira pessoa, o problema tem nome e solução padrão

- A documentação da Cinemachine, da Unity ("Third Person Aim"), descreve o problema: com a origem do tiro deslocada da câmera, um tiro ao longo do eixo da câmera erra o alvo pelo tamanho do deslocamento. https://docs.unity3d.com/Packages/com.unity.cinemachine@3.1/manual/CinemachineThirdPersonAim.html
- A correção comum tem dois passos: um raio da câmera acha o ponto que a mira indica, e o tiro sai da arma para esse ponto. Quando o raio não acha nada, usa-se um ponto a uma distância fixa. Um comentário avisa que uma distância fixa mal escolhida faz o tiro errado parecer errar por muito, e outro que a queima-roupa é onde o deslocamento mais pesa. https://forums.unrealengine.com/t/third-person-shooter-aiming-at-crosshair/129180 ; https://lr.eu.psf.lt/r/howdidtheycodeit/comments/1e0rwfo/how_does_projectile_over_the_shoulder_aiming_work
- O Monday Night Combat usava três raios: da mão à ponta do cano, da câmera para a frente e do cano ao ponto que a câmera achou; um raio que saísse só da câmera atiraria através do cenário. https://www.forrestthewoods.com/blog/adventures_with_guns_in_a_third_person_shooter/
- Os desenvolvedores do Spellbreak contaram o custo de entortar o tiro para a mira: dá para errar com o personagem virado para o lado certo. https://devtrackers.gg/spellbreak/p/98beb1c4-some-information-and-feedback-regarding-the-3-1-aim-changes

## §2 — Na espada, o Naraka vai pela assistência

- Um guia de configurações do Naraka: Bladepoint lista "Attack Aim Assist" (atacar na direção do analógico), "Autolock Target" (desligado no guia) e "Aim Assist" (fraco). https://www.sportskeeda.com/gaming-tech/naraka-bladepoint-settings-need-change
- No controle, o modo padrão "Aim Assist + Camera Shift" mira os golpes automaticamente no inimigo, com a câmera virada para ele no ataque. https://www.player.one/naraka-bladepoint-melee-assist-mode-controllers-has-been-added-latest-147789
- A busca não trouxe uma explicação oficial de como o Naraka resolve a paralaxe sem a assistência.

## §3 — O que a busca não trouxe

- Nenhuma fonte direta sobre a espada com a câmera no ombro e sem assistência. A ponte para o nosso caso é a geometria: a lâmina sai da mão como o tiro sai do cano, e o ponto fixo é o do tiro que não acha nada.
