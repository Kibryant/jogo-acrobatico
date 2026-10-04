---
revisado_em: 2026-10-04
fontes: [F-001, F-028, F-032]
---

# Combate

Estado atual: a proposta v0 do estudo, para testar (F-001). O estudo chama os números de "números de partida, não medidos": nenhum foi sentido em jogo. O Desenho 1 (TASK-3) e o protótipo vão mudá-los.

## A referência: Naraka (F-001)

- **O triângulo:** carregado vence básico, parry vence carregado e básico vence parry.
- **As críticas:**
  - o gancho ilimitado vira spam;
  - as armas de longe são fracas no duelo e "baratas" em grupo;
  - o arco foi enfraquecido três vezes por entrar em combo.

## Princípios v0 (F-001)

- Tempo de animação fixo: o jogador não deforma a animação (lição do Mordhau).
- Antecipação proporcional ao dano.
- Indicador visual no mundo e som.
- Feint custa stamina.
- Arma de longe paga antes do tiro.
- No ar ninguém se defende, e quem atira de longe usa projétil.
- Troca de arma com tempo fixo e sem cancelamento (lição do shotgun do GunZ).
- Uma barra de stamina para tudo.

## Equipamento v0 (F-001)

O equipamento tem três slots:

- **Corpo a corpo:** espada longa, lâminas duplas ou lança.
- **Distância:** arco, pistola ou mosquete.
- **Utilitário:** gancho de 6 s, fumaça ou âncora.

Regras de balanceamento:

- A tabela de atributos fica visível no jogo.
- Ajuste se uma combinação passar de 55% de vitória no 1v1 ou de 40% de escolha no 4v4.
- No máximo 2 armas de fogo por time no ranqueado.

## Regras v0 em ms (F-001)

Os tempos de golpe seguem o formato preparação / ativo / recuperação. No código, tudo vira tick (DEC-0004, regra 3).

| Ação | Tempos (ms) | Stamina | Observação |
|---|---|---|---|
| Golpe leve | 300 / 100 / 250 | 8 | Só a recuperação do leve cancela, e só para esquiva |
| Golpe carregado | 500 a 900 / 120 / 450 | 25 | |
| Bloqueio | 100 | 10 por golpe | |
| Parry | 80 / 200 (400 se errar) | 15 | |
| Esquiva | 60, com 250 invulnerável | 20 | |
| Quebra de guarda | 350 / 100 / 400 | 15 | |
| Feint | entre 300 e 450 | 15 | |
| Arco | puxada até 1.200; dano de 15 a 45 | | |
| Pistola | 6 tiros; recarga de 2,5 s | | |
| Mosquete | 1 tiro de 60; recarga de 3,5 s | | |
| Troca de arma | 700 | | Sem cancelamento |

## Times (F-001)

- **1v1:** preserva o "pensado".
- **4v4:** também preserva, com proteção contra 2 em 1: um anel visível.
- **8v8:** vira leitura de mapa, e a rede passa de 56 para 240 pares de jogadores por atualização.
- **Ordem:** 1v1, depois 4v4, e o 8v8 como evento.

## Decidido no Desenho 1

- **Tribo For Honor e Chivalry 2** (Q-06; DEC-0014): tempo fixo e aviso claro. A profundidade vem de ler e escolher, não de manipular a animação.
- **Cancelamento só desenhado** (DEC-0016): na lista, com preço, com aviso e com janela larga. O que não está na lista não cancela. A lista do v0, como hipótese até a fase 2:
  - a finta, que corta a preparação por 15 de stamina;
  - a recuperação do golpe leve, que pode passar para a esquiva, pagando os 20 de stamina da esquiva.
- **A barra de stamina** (máximo e recuperação) está em `movimento.md`, porque o pulo duplo e o dash também gastam dela (DEC-0017).

## A rede no combate (Desenho 3; DEC-0026)

Com ping, o golpe do outro chega atrasado na tela de quem defende. No relógio do servidor, ninguém defende por reação com ping de 100 ms ou mais (F-028 §3). O jogo julga cada um pela própria tela, até um teto. O detalhe está em `docs/arquitetura/rede.md` §6.

| Número ou regra | Valor | Unidade | Nota |
|---|---|---|---|
| Teto de compensação | 200 | ms | 12 ticks a 60. Número v0, fechado pelo Claude (DEC-0017). O estudo propõe de 150 a 200 para a espada (F-001). Acima dele, quem tem o atraso paga o excesso |
| Quem tem razão sobre a posição | a tela de quem ataca | — | A espada pega o que quem ataca via, e o contato nunca é desfeito. Escolha do Arthur (F-032 §2) |
| Quem tem razão sobre a defesa por tempo | a tela de quem defende | — | Parry, bloqueio e esquiva valem como quem defende viu. Direção da DEC-0011 |

**O que se sente:**

- Até o teto, quem defende tem a preparação inteira para reagir, como sem lag: o mesmo parry do ping 0.
- Quem ataca descobre o resultado depois do contato: uns 240 ms com ping 100.
- Quem só correu para sair do alcance leva o golpe se, na tela de quem ataca, ainda estava nele. A esquiva, o parry e o bloqueio salvam, porque valem no tempo de quem defende.

## Em aberto (F-001)

- **Q-07:** qual a técnica própria do jogo, o equivalente ao K-style do GunZ?
- **Leituras do v0 que fecham na fase 2:** o parry "80 / 200 (400 se errar)" admite duas leituras, uma janela de 80 ms com 200 ms de recuperação ou uma preparação de 80 ms com 200 ms de janela. A esquiva "60, com 250 invulnerável" foi lida como 60 ms de preparação e 250 ms invulnerável, e a recuperação dela ainda não tem número.