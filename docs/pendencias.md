---
revisado_em: 2026-10-03
---

# Pendências

Perguntas abertas, cada uma com o lugar onde se resolve. A resposta vira DEC, e a pergunta fica aqui com a data e o ID da DEC.

| ID | Pergunta | Onde se resolve | Recomendação do agente | Resposta |
|---|---|---|---|---|
| Q-01 | Ticks por segundo: 30, o padrão do netfox, ou 60, o do estudo? 60 deixa o parry mais preciso e custa CPU e banda (F-005 §3; F-007 §8) | Desenho 3 (TASK-5), medindo | Medir os dois com 2 e com 8 clientes, a ping 0, 100 e 220, e o Arthur jogar os dois (F-023). Evidência do Desenho 2: a 30 ticks, a janela de parry de 80 ms vira 67 ms (−17 %); a 60, 83 ms (DEC-0022). Pelo modelo do netfox, refazer o passado custa na proporção do quadrado do tickrate: a ping 100, 60 ticks simulam 2,7 vezes os ticks de 30 (vitrine da rede) | — |
| Q-02 | O netfox roda no 4.7.2? O bug #659 tem contorno? Release ou main? (F-005 §8) | Desenho 3 (TASK-5) | Main fixada no `cf5189d`, com a suíte do netfox verde no 4.7.2 (DEC-0003). O #659 se contorna com os autoloads em `res://` e um teste que vigia (F-023 §3) | — |
| Q-03 | No plano Free, o GitHub não aplica regra de branch em repositório privado. Fica privado sem proteção, público, ou no GitHub Pro? | TASK-2 | Privado sem proteção; o portão local é a trava | 2026-10-02: privado, sem regra de branch. O pre-push local é a trava, e o CI avisa (F-017 §2; DEC-0006) |
| Q-04 | Qual o nome do jogo, e qual a licença do código e dos assets? | Desenho 1 (TASK-3) e Desenho 6 (TASK-8) | Nome provisório até o Desenho 1; código fechado por enquanto | 2026-10-02: "Jogo Acrobático" é o nome provisório até o fim da fase 1 (DEC-0018; F-016 §1). O nome definitivo e a licença seguem abertos |
| Q-05 | A Edgegap tem servidor em São Paulo e relay grátis até 50 jogadores? (F-001, em aberto) | Desenho 6 (TASK-8) | — | — |
| Q-06 | Combate: tribo Mordhau, com profundidade de comando e ~440 jogadores, ou For Honor e Chivalry 2, legíveis, com 2 a 4 mil? As regras v0 puxam para a segunda (F-001) | Desenho 1 (TASK-3) | A segunda, como as regras v0 já fazem | 2026-10-02: For Honor e Chivalry 2 (DEC-0014; F-013 §1) |
| Q-07 | Qual a técnica própria do jogo, o equivalente ao K-style do GunZ? (F-001) | Começa no Desenho 1; a resposta pode nascer do protótipo | Deixar espaço no movimento para ela surgir | — |
| Q-08 | As tasks ficam em português, diferente do SkinHub (DEC-0008)? | Começo da próxima sessão | Português, porque você aprende pelas tasks | 2026-10-02: português, como a DEC-0008 já previa (F-010 §2) |
| Q-09 | O netfox segura parry de 80 a 200 ms com 8 clientes? Se não, o 4v4 vira 3v3 (F-001) | Começa no Desenho 3 (TASK-5), que mede 8 clientes com o clumsy (F-023 §2); o esqueleto andante (TASK-9) e a fase 3 confirmam com bots | Medir cedo, com bots | — |
| Q-10 | Tranco (hitstun e blockstun): quanto tempo fica sem agir quem leva um golpe ou o bloqueia? O v0 não define, e sem isso a vantagem de um golpe bloqueado não tem conta (F-001) | Fase 2, no desenho do duelo | Definir junto com o primeiro golpe jogável, medindo a vantagem do leve bloqueado | — |
| Q-11 | O equipamento v0 tem três slots e troca de arma (F-001). O Arthur imagina combinações nas duas mãos (pistola e espada, pistola e faca, duas pistolas) e mais armas: espada grande, duas espadas, 12, metralhadora e bazuca (F-012 §1). Como o equipamento comporta isso? | Fase 2 em diante; armas além das três primeiras ficam fora do Desenho 1 (TASK-3) | Decidir com o duelo de espada jogável, que é o primeiro marco (DEC-0004, regra 6) | — |
| Q-12 | Corpos diferentes: o Arthur imagina três (um mais duro, um médio e um mais rápido), com a hitbox à vista e afinidade com tipos de arma, e não quer todos com o mesmo boneco (F-015 §1). Choca com o anti-pilar 4, sem classe nem herói, e multiplica animação, hitbox e balanceamento | Depois do 1v1 online (fase 3) | Um corpo só até lá, com variedade visual por cosmético que não muda a silhueta (pilar 1). Se corpos voltarem, só como escolha livre, um quarto slot do equipamento, sem travar arma | — |
| Q-13 | Qual a explicação, no mundo do jogo, para a acrobacia e para ninguém tomar dano de queda? Ideia do Arthur: uma bota ou um exoesqueleto (F-015 §1) | Desenho 5 (TASK-7) ou depois; o Arthur pediu para pensar mais à frente | — | — |
| Q-14 | A matriz de posição: o que chão, parede e ar ganham e perdem no combate (F-012 §1). E a regra das mãos, proposta do Claude: manobra que ocupa uma mão só deixa usar arma de uma mão | Fase 2, no desenho do duelo | Desenhar com o duelo de espada jogável | — |
| Q-15 | O CI roda em `ubuntu-latest`, que passa a ser o Ubuntu 26 a partir de 19/10/2026, segundo um aviso do GitHub no primeiro run (TASK-2). Fixar `ubuntu-24.04`, como já se fixam o Godot, o formatador e o gitleaks? | Desenho 4 (TASK-6), ou antes de 19/10 | Fixar `ubuntu-24.04`: é uma linha, e o resto do CI já é fixado. A troca de imagem vira uma decisão, e não uma surpresa | 2026-10-02: fixado em `ubuntu-24.04` (F-018 §2) |
