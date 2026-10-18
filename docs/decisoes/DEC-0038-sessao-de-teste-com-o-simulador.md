---
id: DEC-0038
titulo: A sessão de teste com o simulador de lag — um override.cfg temporário liga a conexão automática do netfox, e a Main usa a conexão do simulador
data: 2026-10-18
status: aceita
decidido_por: Arthur
fontes: [F-093, F-089, F-091, F-023]
substitui:
substituida_por:
---

# DEC-0038 — A sessão de teste com o simulador de lag: um override.cfg temporário liga a conexão automática do netfox, e a Main usa a conexão do simulador

## Contexto

A DEC-0023 §7 deixa o `NetworkSimulator` do netfox inerte no jogo de verdade, com o `netfox/autoconnect/enabled` desligado, "porque quem conecta é a `Main`" (DEC-0026 §6).

Os critérios 12 e 13 da TASK-9 pedem a rede a ping 100 e 220 neste PC (`rede.md` §10). O simulador do netfox só aplica a latência quando ele mesmo conecta o jogo (`addons/netfox.extras/network-simulator.gd`, `_ready`):

- ele só roda numa build do editor, com o `autoconnect` ligado, e sai cedo quando existe a variável `CI`, `NETFOX_CI` ou `NETFOX_NO_AUTOCONNECT`;
- o primeiro jogo que abre hospeda na porta do `autoconnect/port`, com o proxy de UDP na porta seguinte, dentro do processo dele; os outros entram pelo proxy;
- o `simulated_latency_ms` vale em cada sentido, então o ping é o dobro.

A sonda do Desenho 3 já ligava o simulador por um `override.cfg` (`../netfox-sonda/sonda/play.sh`). O plano da parte 2, mostrado ao Arthur, descrevia o mesmo caminho (TASK-9, plano da rodada C2; F-089).

## Opções consideradas

1. **Um `override.cfg` só durante a sessão de teste, e a `Main` usa a conexão do simulador.** O `project.godot` não muda. Os scripts escrevem o arquivo, abrem os jogos e o apagam assim que eles o leem, ou em qualquer saída. **A escolhida.**
2. **Ligar o `autoconnect` no `project.godot`.** Todo jogo aberto pelo editor ligaria o simulador, inclusive o Sozinho e os testes. Quebra a DEC-0023 §7 e a guarda do teste de configurações.
3. **O clumsy no lugar do simulador.** Ele atrasa os pacotes do Windows, por fora do jogo, mas pede administrador e ficou para 4 clientes ou mais (F-023 §2).
4. **Um proxy de lag próprio.** Seria uma ferramenta nova para manter, sem ganho sobre o simulador para 2 clientes.

## Decisão

1. **O `project.godot` segue com o `netfox/autoconnect/enabled` desligado,** e o teste de configurações guarda isso (DEC-0023 §7).
2. **Só os scripts de teste com lag ligam o simulador:** `tools/net_run.sh` e `tools/play_online.sh`.
   - Eles escrevem na raiz um `override.cfg` com o `autoconnect` ligado, a porta 7777 e a latência de metade do ping em cada sentido.
   - Apagam o arquivo assim que os jogos da sessão o leram, e em qualquer saída, com Ctrl+C ou falha.
   - O `override.cfg` está no `.gitignore`.
3. **Nessa sessão, a `Main` usa a conexão que o simulador abriu.**
   - Ela espera até 10 frames pela conexão.
   - Um endereço ou uma porta nos argumentos diferente do simulador é recusado, e o Sozinho também.
   - O servidor conectado pelo simulador espera a latência mais 100 ms antes de sair, para o adeus passar pelo proxy.
4. **O portão e o `tools/net_check.sh` se recusam a rodar enquanto houver um `override.cfg` na raiz** (`tools/lib.sh`, `refuse_override_cfg`).
5. **As palavras do Arthur:** ele escolheu "Atualiza tudo, com a DEC-0038 (Recomendado)" (F-093 §1). Ele errou duas vezes a conferência do mecanismo, e a decisão segue a escolha dele, pela regra do registro do harness de 07/10/2026 (F-093 §2).

## Consequências

- A DEC-0023 continua valendo inteira, e o índice a marca como completada por esta DEC. O jogo exportado nunca liga o simulador, porque ele sai cedo fora do editor.
- Todo cliente da sessão loga `ERROR: Couldn't create an ENet host.`, porque o simulador tenta hospedar antes de entrar e a porta já é do servidor. O `tools/net_run.sh` ignora só essa linha, pelo texto exato.
- Um `override.cfg` esquecido ligaria o simulador no próximo jogo aberto pelo editor, em qualquer modo. O portão e o Sozinho recusam rodar, e o comentário no topo do arquivo manda apagá-lo.
- O simulador trava com 4 peers ou mais (#554). Acima de 2 clientes, o lag continua com o clumsy (`rede.md` §10).
- O `rede.md` §9 e §10 descreve a sessão.

## Revisitar se

- O netfox mudar o simulador. Atualizar o netfox já é uma DEC nova (DEC-0023).
- A medição de 4 clientes ou mais pedir lag simulado, porque o #554 trava o simulador.
- Um teste no CI precisar de lag, porque o simulador sai cedo com a variável `CI`.
