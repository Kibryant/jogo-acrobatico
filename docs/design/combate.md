---
revisado_em: 2026-10-02
fontes: [F-001]
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

## Em aberto (F-001)

- **Q-07:** qual a técnica própria do jogo, o equivalente ao K-style do GunZ?
- **Leituras do v0 que fecham na fase 2:** o parry "80 / 200 (400 se errar)" admite duas leituras, uma janela de 80 ms com 200 ms de recuperação ou uma preparação de 80 ms com 200 ms de janela. A esquiva "60, com 250 invulnerável" foi lida como 60 ms de preparação e 250 ms invulnerável, e a recuperação dela ainda não tem número.