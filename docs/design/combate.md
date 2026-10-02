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

## Em aberto (F-001)

- **Q-06:** tribo Mordhau, com profundidade de comando e ~440 jogadores, ou For Honor e Chivalry 2, legíveis, com 2 a 4 mil? As regras v0 puxam para a segunda.
- **Q-07:** qual a técnica própria do jogo, o equivalente ao K-style do GunZ?
