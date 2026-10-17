---
id: F-087
titulo: O Arthur escolhe o snap de reserva do contorno D e tira a trava de 5 s da SyncTest — erra duas vezes a conferência do contorno D (sessão 13, 17/10/2026)
recebido_em: 2026-10-17
como: Respostas escolhidas nas opções de duas rodadas de perguntas do Claude Code, depois da rodada B2 da parte 1 da TASK-9. Texto das perguntas, dos rótulos e das descrições como foram mostrados.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: a rodada B2 da parte 1 da TASK-9 (a SyncTest, critério 8) voltou do implementer como BLOCKED. A SyncTest achou um defeito no contorno D (DEC-0025 §2) na beirada da plataforma: a cápsula que sai correndo fica apoiada na quina pela base redonda, e, restaurada nesse tick, a sonda de 0,83 mm para baixo não encosta em nada. O "estava no chão" do motor fica com o valor do presente (no ar), e o tick refeito sai do chão um tick antes: 84 divergências em 2.526 conferências, até 5,7 cm, e 1 dos 2 pulos de coyote perdido. As outras três cenas deram zero. O implementer mediu três correções como mudanças descartáveis: a sonda a 0,2 m/s (E1), a 0,5 m/s (E2) e o snap do motor de reserva (E3). O Claude conferiu na própria máquina a divergência e a E3: zero divergência nas quatro cenas, 2 de 2 pulos de coyote, e o autoteste continuou acusando. O implementer também mediu os quatro cenários em uns 2 s com o PC quieto, de 3,8 a 4,3 s com programas abertos e uma vez 15 s; o Claude mediu 3,3 e 3,5 s. A explicação usou o campo privado de um objeto TypeScript que o `JSON.stringify` não salva. A primeira conferência errou. O Claude tirou a trava de 5 s do teste, porque essa escolha era outro assunto, e explicou de novo com os dois cadernos, nomeando a ideia errada: a posição volta exata. O caderno do netfox volta inteiro no rollback, e o do motor tem uma linha que o netfox não grava. A segunda conferência também errou. O Claude avaliou que falar do pulo de coyote perdido, o sintoma, puxou para "a tecla do pulo". Explicou uma terceira vez com uma tabela das duas execuções do mesmo tick, em que só a anotação do motor difere, sem pergunta nova. Disse ao Arthur que as cinco conferências erradas da sessão pesam mais na explicação, longa demais, do que nele, e que vai explicar uma coisa por vez.

## §1 — A primeira rodada

Pergunta: "Por que o tick refeito saía diferente do original na beirada?"

Resposta: "O netfox não gravava a posição"

A opção dizia: "A posição da cápsula na quina ficava fora do que o netfox salva." A esperada era "O motor achava que estava no ar", cuja descrição dizia: "A cutucada não alcançava a quina, e o \"estava no chão\" do motor ficava com o valor do presente."

Pergunta: "Qual correção entra no contorno D?"

Resposta: "E3, snap de reserva (Recomendado)"

A opção dizia: "Se a cutucada não acha o chão que o estado diz, o motor dá o puxão de todo tick. Duas linhas no lutador; zero divergência e 2 de 2 coyotes. Vira uma DEC nova que completa a DEC-0025."

Pergunta: "E a trava de 5 s da SyncTest no portão?"

Resposta: "Mostra, sem trava (Recomendado)"

A opção dizia: "O tempo aparece em toda rodada do portão, e o revisor confere os 5 s com o PC quieto. Com o PC ocupado, o portão não fica vermelho à toa."

## §2 — Depois da segunda explicação

Pergunta: "Depois do rollback na quina, o que estava errado?"

Resposta: "A tecla do pulo"

A opção dizia: "O netfox restaurava a tecla errada no tick refeito." A esperada era "A anotação do motor", cuja descrição dizia: "A cápsula voltava para o lugar certo, mas o motor anotava \"no ar\"."

Pergunta: "Com o contorno D explicado de novo: a correção continua a E3?"

Resposta: "Continua a E3 (Recomendado)"

A opção dizia: "O snap de reserva no contorno D, duas linhas no lutador, registrado numa DEC nova que completa a DEC-0025."
