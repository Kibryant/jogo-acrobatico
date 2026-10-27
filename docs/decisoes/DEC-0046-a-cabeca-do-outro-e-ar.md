---
id: DEC-0046
titulo: A cabeça do outro é ar — quem cai sobre outro lutador fica no ar para as regras e escorrega para fora, pelo jogo e não pela rede (a Q-16)
data: 2026-10-26
status: aceita
decidido_por: Arthur (F-152; F-155; F-156; F-165)
fontes: [F-025, F-151, F-152, F-154, F-155, F-156, F-165]
substitui:
substituida_por:
---

# DEC-0046 — A cabeça do outro é ar: quem cai sobre outro lutador fica no ar para as regras e escorrega para fora, pelo jogo e não pela rede (a Q-16)

## Contexto

A Q-16 perguntava se um lutador pode ficar em pé na cabeça do outro (`pendencias.md`). Ela nasceu na rede: a sonda do Desenho 2 achou ali as últimas divergências do rollback, 6 a 30 ticks e 32 a 60, até 15 cm (F-025 §3). A DEC-0036 deixou a decisão para a fase 1, jogando.

Na TASK-10.7, o Arthur começou a regra proibida (F-152). A sonda C mostrou, antes de qualquer regra, que o código de hoje já não diverge na cabeça: o snap de reserva da DEC-0037 tinha zerado as divergências, e desligá-lo as traz de volta (`rede.md` §4; `mudancas.md`, 26/10/2026). O motivo da rede caiu. Na conferência, o Arthur mesmo achou o motivo de jogo: "conta como chão traz todas as consequências de chão", e o pulo duplo renovado encadearia pulo duplo, cabeça, pulo duplo (F-154 §1). Ele manteve a proibição (F-155 §1), jogou com a regra e achou que "tá tudo bem do jeito que tá" (F-156 §1), e pediu esta DEC agora (F-165 §1).

## Opções consideradas

1. **A cabeça é ar (escolhida):** quem cai sobre outro lutador fica no ar para as regras e escorrega para fora a 3 m/s, como no CoD. Fecha o encadeamento de pulos duplos e o degrau de 1,8 m que passaria do bloco de 3 m (`movimento.md`, "Métricas de nível").
2. **A cabeça é chão, como no CS:** ficar em pé na cabeça do colega vira jogada (o "boost"). Sem regra nova; o rollback já acerta. Abre o encadeamento e o degrau.

## Decisão

Aceita pelo Arthur: a regra (F-152 §1), mantida pelo jogo depois da sonda C (F-155 §1), aprovada jogando (F-156 §1) e pedida como DEC agora (F-165 §1).

1. **A cabeça de outro lutador nunca é chão para as regras** (`Movement.stands`): quem cai em cima fica no ar, sem pulo do chão nem dash, sem renovar o pulo, o pulo duplo nem a última parede, sem coyote e com a gravidade do ar; o pulo duplo guardado e o gancho saem como no ar (`movimento.md`, "O corpo": "A cabeça do outro").
2. **Escorrega para fora a 3 m/s**, pela normal do contato achatada, e sai da cabeça em até 12 ticks a 60 (`movimento.md`, "O corpo": "Escorregar da cabeça").
3. **O motor segue dizendo chão:** o `on_floor` é o veredito do motor, que o contorno D lê (DEC-0025 §2; DEC-0037); a regra pergunta outra coisa.
4. **A cabeça não é plataforma:** os lutadores só tratam o cenário como plataforma e não herdam velocidade ao sair de outro corpo.

## Consequências

- **A Q-16 fecha** com esta DEC (`pendencias.md`, datada).
- **A sessão online da TASK-10.8** confere o escorregão da cabeça do bot a ping 100. Um problema ali é bug de rede, corrigido sem mudar esta regra.
- **O rollback:** a cena `cabeca` da SyncTest segue no portão, com 0 divergência e o veneno no `:state:slide_off_dir` (`rede.md` §8).

## Revisitar se

- O teste dos 15 minutos ou o combate da fase 2 pedirem um jeito de usar o outro corpo como apoio (um "boost" desenhado, com custo).
- O escorregão parecer um bug jogando online.
