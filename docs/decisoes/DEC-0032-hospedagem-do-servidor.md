---
id: DEC-0032
titulo: A hospedagem do servidor — o esqueleto andante neste PC com a imagem do servidor testada no CI, o fechamento limpo por comando próprio, nada pago até a fase 3 e uma VPS em São Paulo na fase 3
data: 2026-10-10
status: aceita
decidido_por: Arthur (F-071 §4, escolhas 1 e 4; F-074), com a direção da fase 4 proposta pelo Claude e a decidir na fase 4 (DEC-0012)
fontes: [F-066, F-070, F-071, F-072, F-073, F-074, F-077]
substitui: DEC-0028, só a frase "O push na main não gera build" do §2
substituida_por:
---

# DEC-0032 — A hospedagem do servidor: o esqueleto andante neste PC com a imagem do servidor testada no CI, o fechamento limpo por comando próprio, nada pago até a fase 3 e uma VPS em São Paulo na fase 3

## Contexto

A DEC-0011 deu a direção, "VPS em São Paulo com Docker, ou a Edgegap, se ela tiver região SP", e deixou o detalhe para o Desenho 6. A DEC-0028 deixou "o servidor de verdade" para o mesmo desenho.

A pesquisa conferida na origem mostrou que a Edgegap tem São Paulo, mas escolhe o lugar pelo ping de quem joga e não deixa travar a região. Ligada o dia todo, ela custa umas 7,7 vezes uma VPS em São Paulo, onde a Vultr cobra US$ 7,50 por mês pelo plano de 1 núcleo (F-066 §1, §2, §12 e §13). A "relay grátis até 50 jogadores" só serve para jogo P2P (F-066 §2; H-01 e H-02). O ping desta casa é de uns 24 a 26 ms até São Paulo e de 111 a 195 ms até os EUA, e a conexão tem CGNAT provável (F-070; F-073 §5).

Na rodada 1, o servidor do parry de brinquedo rodou num contêiner Docker aqui e na Edgegap, que o pôs em São Paulo (F-073). Ali, um 1v1 a 60 ticks gastou mediana de 13,9% de um núcleo, com 24 ms de ping e 37 ms no jogo, estáveis e sem perda (F-073 §3). No contêiner daqui, o servidor usou 43 MB de memória e ficou pronto em 1,2 a 1,6 s (F-073 §2). O `docker stop` o matou com saída 143: o Godot não trata o SIGTERM (F-073 §2; F-066 §5). O Arthur jogou e achou liso (F-072 §3).

## Opções consideradas

1. **O esqueleto só neste PC, sem imagem:** é o menor trabalho, mas a build Linux do servidor só seria provada rodando na fase 3.
2. **Este PC e a imagem testada no CI a cada push:** a escolhida (F-074).
3. **O esqueleto já num servidor fora:** quebra "nada pago antes da fase 3" (F-071 §4, escolha 1), ou depende de um deploy grátis de 60 minutos a cada teste.
4. **A Edgegap como servidor de produção:** só compensa com menos de umas 3 horas de partida por dia, e não deixa travar São Paulo (F-066 §13; H-07).
5. **O Oracle A1 grátis em São Paulo:** pede o servidor em Linux Arm, e as máquinas grátis costumam faltar (F-066 §4, Inferência). O plano grátis não acabou; foi cortado para 2 núcleos Arm e 12 GB (F-066 §3; a data só aparece numa fonte secundária, H-09).
6. **AWS t4g, Lightsail e Azure B:** são de CPU "burstable", que não aguenta 60 ticks sem parar (F-066 §3, Inferência).
7. **O PC de casa como servidor para amigos:** o CGNAT impede um amigo de entrar direto; só com túnel (F-070 §4; F-066 §4).

## Decisão

Decidida pelo Arthur em 10/10/2026: "PC + imagem no CI (Recomendado)" e "Comando próprio + tini (Recomendado)" (F-074 §1).

### 1. O esqueleto andante (TASK-9)

- O servidor e os clientes rodam neste PC, como a TASK-9 já diz.
- Um job do CI, fora do portão e do pre-push, constrói a imagem Docker do servidor Linux em todo push na main e em todo PR e confere que ela sobe e fecha com saída 0. O job não guarda a imagem como artefato. A receita da imagem e o teste saem da TASK-9.
- Isso substitui a frase "O push na main não gera build" da DEC-0028 §2: o push na main passa a construir a imagem do servidor para testar. As builds guardadas seguem como a DEC-0028 diz: no PR e na tag.

### 2. O fechamento limpo

- O servidor fecha por um comando nosso, fora de banda (pela entrada padrão, por um arquivo ou por RPC, escolhido na TASK-9): para o tick, fecha a conexão e sai com 0. É a regra da DEC-0026 §6, levada ao contêiner.
- O SIGTERM continua matando o processo com saída 143, porque o Godot não o trata (F-066 §5; F-073 §2). No contêiner, o `tini` é o PID 1 só para repassar o sinal e evitar o processo zumbi.

### 3. Por fase

- **Até a fase 2:** este PC. Nenhum servidor fora de casa. A Edgegap grátis serve para testes de 60 minutos, sem cartão (F-066 §2; X-10).
- **Fase 3:** a primeira VPS em São Paulo. A referência é a Vultr `vc2-1c-1gb`, a US$ 7,50 por mês, com 2 partidas de 1v1 por máquina (F-066 §13).
- **Fase 4 em diante (direção proposta pelo Claude, a decidir na fase 4):** o servidor oficial, os servidores da comunidade e a lista de salas no próprio servidor oficial (F-066 §6, Inferência).
- Nada se paga, e nenhum cartão se cadastra, antes da fase 3 (F-071 §4, escolha 1).

### 4. Os números de referência

- 13,9% de um núcleo por 1v1 a 60 ticks no data center (F-073 §3). A conta de custo continua reservando 0,375 núcleo por partida (F-066 §8 e §13).
- 43 MB de memória, medidos no contêiner daqui (F-073 §2). A memória no data center não foi medida.
- O 4v4 e o 8v8 seguem sem medida (Q-09).

## Consequências

- A Q-05 está respondida: a Edgegap tem São Paulo e pôs o servidor lá; a relay grátis só serve para P2P (F-066 §2; F-073 §3).
- A TASK-9 recebe a entrada do Desenho 6: o job da imagem, o comando de fechamento e a receita da sonda em `../servidor-sonda`.
- A DEC-0028 fica em parte substituída, só na frase do §2.
- Completa a DEC-0027: o job da imagem roda no CI fora do portão, sem mudar o portão nem o pre-push.

## Revisitar se

- O 1v1 no servidor de verdade passar de 0,375 núcleo por partida, ou o 4v4 medido não couber numa VPS de 2 núcleos.
- A Vultr deixar São Paulo ou mudar o preço da região.
- O Godot ganhar tratamento do SIGTERM por script (proposta #1361, F-066 §5).
