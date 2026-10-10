---
revisado_em: 2026-10-10
fontes: [F-001, F-050, F-066, F-067, F-068, F-069, F-070, F-071, F-073, F-074, F-075, F-076]
---

# Infraestrutura e serviços

Onde o jogo roda fora deste PC, quanto custa e quando cada serviço entra. As regras estão na DEC-0032 (a hospedagem), na DEC-0033 (o repositório aberto e a licença) e na DEC-0034 (os serviços e os gatilhos). Nada se paga, e nenhum cartão se cadastra, antes da fase 3 (F-071 §4, escolha 1).

## Estado atual

- O servidor e os clientes rodam neste PC. O servidor da sonda já rodou num contêiner Docker aqui e na Edgegap em São Paulo (F-073).
- O repositório é privado e abre na TASK-11, em MIT para o código e CC BY 4.0 para os assets próprios (DEC-0033).
- Nenhum serviço pago está ativo.

## O servidor

### Por fase

| Fase | Onde o servidor roda | Custo |
|---|---|---|
| 0 a 2 | Este PC. O CI constrói e testa a imagem do servidor a cada push (DEC-0032 §1). A Edgegap grátis serve para testes de 60 minutos, sem cartão (F-066 §2; X-10) | R$ 0 |
| 3 | A primeira VPS em São Paulo: a referência é a Vultr `vc2-1c-1gb`, a US$ 7,50 por mês, com 2 partidas de 1v1 por máquina (F-066 §13) | da tabela abaixo |
| 4 e 5 | Direção proposta, a decidir na fase 4: o oficial, os servidores da comunidade e a lista de salas no próprio oficial (DEC-0032 §3; F-066 §6, Inferência) | o oficial; a comunidade paga os dela |

### O custo por faixa

A conta do pesquisador, corrigida com o preço de São Paulo, reserva 0,375 núcleo por partida de 1v1 e liga tudo 24 horas no pico, com o dólar a R$ 5,16 já com o IOF de 3,5% (F-066 §8 e §13).

| Jogadores ao mesmo tempo | VPS em São Paulo | Edgegap 24 h | Edgegap 3 h de pico | Comunidade + 1 oficial |
|---|---|---|---|---|
| 10 | R$ 116 | R$ 745 | R$ 92 | R$ 155 |
| 50 | R$ 503 | R$ 3.725 | R$ 459 | R$ 155 |
| 200 | R$ 1.935 | R$ 14.890 | R$ 1.837 | R$ 155 |
| 1.000 | R$ 9.675 | R$ 74.500 | R$ 9.185 | R$ 155 |

O orçamento do estudo, de R$ 3 a 7 mil por ano, cobre uns 50 jogadores ao mesmo tempo em VPS (F-001; F-066 §13).

### O que a sonda mediu

| O que | Valor | Fonte |
|---|---|---|
| CPU de um 1v1 a 60 ticks no data center | mediana 13,9% de um núcleo | F-073 §3 |
| CPU do mesmo servidor no contêiner daqui | mediana 21,5% de um núcleo | F-073 §2 |
| Memória no contêiner daqui | 43 MB | F-073 §2 |
| Imagem | 222 MB; pronta em 1,2 a 1,6 s | F-073 §1 e §2 |
| Saída do servidor | uns 16 kB/s para os dois clientes | F-073 §2 e §3 |
| Ping desta casa até São Paulo | 24 a 26 ms; 37 ms no jogo, estável | F-070; F-073 §3 e §5 |
| `docker stop` | saída 143: o Godot não trata o SIGTERM | F-073 §2 |

### Correção do estudo

O estudo disse que a Oracle cortou o servidor gratuito em 15/06/2026 (F-001). O plano grátis continua, cortado para 2 núcleos Arm e 12 GB, com região em São Paulo (F-066 §3 e §12). A data só aparece numa fonte secundária (H-09). O plano não foi escolhido: pede o servidor em Linux Arm, e as máquinas grátis costumam faltar (F-066 §4).

## O repositório aberto

- MIT no código e CC BY 4.0 nos assets próprios; o nome e o logo fora da licença; a contribuição pela seção D.6 dos termos do GitHub (DEC-0033 §1).
- O histórico abre como está, com o e-mail do Arthur (F-071 §3; F-075).
- A main recusa force push e apagar; PR de fora só roda o CI depois da aprovação, com o token só de leitura (DEC-0033 §3).
- Em repositório público, o Actions é grátis e roda em 4 núcleos, e todo download do LFS, até de fork, sai da cota do dono: 10 GiB guardados e 10 GiB baixados por mês, bloqueados sem cartão em vez de cobrados (F-069 §1 e §3; F-050 §5).

## Os serviços

O custo dos serviços abaixo não depende da faixa de jogadores, a não ser onde a linha diz.

| Serviço | Gatilho | Direção | Custo | O que a lei pede | Fonte |
|---|---|---|---|---|---|
| Servidor | Fase 3 | VPS em São Paulo | Da tabela do servidor | Aviso de privacidade quando o servidor guardar IP | DEC-0032; F-068 §1 |
| Relatório de crash | Fase 2; Sentry na fase 3 | O log do Godot com a pilha, mandado à mão; depois o Sentry de código aberto, sem dado pessoal (`send_default_pii` e `attach_log` desligados) | R$ 0: o plano grátis tem 5 mil eventos por mês e o de código aberto, 5 milhões, nas quatro faixas | Sem IP nem dado pessoal no relatório | DEC-0034; F-067 §5 e §10 |
| Contas e ranking | Fase 4 | Login pela Steam ou pelo Discord, sem senha nossa; o ranking gravado só pelo servidor oficial | R$ 0 no Supabase grátis, que pausa sem uso; o Pro custa US$ 25 por mês (uns R$ 129), o mesmo nas quatro faixas até 100 mil usuários ativos por mês | LGPD art. 14: dados mínimos, sem data de nascimento; consentimento de um dos pais para menor de 12 quando a base é o consentimento; um canal de contato | DEC-0034; F-067 §1; F-068 §1 |
| Comunidade | A abertura (TASK-11) | O GitHub Discussions; o Discord só como canal extra | R$ 0 | O Discord é classificado como não recomendado para menores de 18 (S-15) | DEC-0034; F-067 §6 e §10 |
| Conversa no jogo | O primeiro jogo em rede | Só sinais rápidos, sem chat livre | R$ 0 | Chat livre pediria denúncia, recurso e interação limitada por padrão (ECA Digital, art. 21) | DEC-0034; F-068 §2 |
| Assinatura da build | Depois da abertura e da primeira release | O SignPath, grátis para código aberto; antes disso, um passo a passo para os testadores | R$ 0 | — | DEC-0034; F-069 §7 e §12 |
| Steam | Fases 4 e 5 | O SDK fora do repositório; a build Steam opcional | US$ 100 por app, uma vez | A classificação indicativa no acesso; o questionário da Steam gera classificações regionais, e a do Brasil só consta num post de moderador, sem documentação oficial (F-068 §3 e §11) | DEC-0034; F-067 §2 e §3; F-068 §3 |
| O repositório | A abertura (TASK-11) | MIT e CC BY 4.0, o ruleset e a aprovação de PR de fora | R$ 0, com o LFS na cota grátis | Citar o GunZ como inspiração é baixo risco; o nome nunca vai no título, no logo ou na Steam | DEC-0033; F-068 §8; F-069 §1 |

O ECA Digital só proíbe expressamente a loot box paga, e o jogo não tem loja. Um advogado confere, antes das contas e do chat, se uma pessoa física que publica um jogo grátis conta como "fornecedor" (F-068 §2).

## O que não foi medido

- O ping no horário de pico da noite: as medidas são de uma sexta à tarde e de um sábado de manhã (F-070; F-073 §5).
- A CPU e a banda de um 4v4 e de um 8v8 (Q-09).
- A memória do servidor no data center (F-073 §3 não traz).
- Se a página da Steam exige a taxa paga, e o login de menores pela Steam ou pelo Discord (Q-28).
