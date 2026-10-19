---
id: F-101
titulo: O plano aprovado da TASK-10.1 — a vaga do buffer, a posição no before_move, a stamina como valor mais carimbo e a SyncTest comparando o estado inteiro, com a salvaguarda de 1 mm (sessão 14, 19/10/2026)
recebido_em: 2026-10-19
como: O plano escrito pelo Claude no modo de plano da sessão 14, a partir do blueprint da fase 1 (o único workflow da TASK-10) e da crítica de completude; aprovado pelo Arthur no ExitPlanMode. O §1 é o plano como foi aprovado.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: o ok no modo de plano é consentimento de verdade, mas não deixa F-xxx; por isso o plano aprovado vira fonte logo depois (registro da TASK-4). A pergunta da rodada 1 dizia que os detalhes da arquitetura da TASK-10.1 passariam pelo modo de plano (F-100 §1).

## §1 — O plano aprovado


### Contexto

A TASK-10.1 é a primeira filha da fase 1 (F-100). Ela traz o pulo duplo e a stamina, e fixa a interface da fase inteira, para nenhum teste travado ser reescrito nas filhas seguintes (DEC-0009). Na pergunta de hoje, você fechou as escolhas com os padrões, e a descrição dizia que os detalhes da arquitetura passariam por aqui.

O que já existe, sem commit e reversível: a branch `task-10.1-double-jump-stamina`; as leituras v0 no `movimento.md` ("Pulo e ar", "Perdão", "Stamina"); a DEC-0039, aceita por você; o aviso na DEC-0022; seis termos no glossário; a `visao-geral.md` com os campos novos; a linha do `mudancas.md`. O test-writer já escreve os testes dos critérios 1 a 7, cego ao código.

### O que você aprova aqui: quatro mudanças na arquitetura

1. **A vaga do buffer** (DEC-0039, já aceita): o `jump_pressed_tick` vira `buffered_command` mais `buffered_tick`. O último aperto vence, e a janela é inclusiva, como o código da TASK-9 já faz. É um debounce: o último pedido substitui o anterior.
2. **A posição no `before_move`** (DEC-0039): entra agora e fica sem uso até o gancho (TASK-10.6).
3. **A stamina como valor mais carimbo:** o estado guarda `stamina_at_spend` (a barra logo depois do último gasto) e `stamina_spent_tick` (o tick do gasto). A barra se calcula pelo tick, nunca por contador (DEC-0022). É o "flash 12:30" no chat do LoL: o chat guarda quando ele foi usado, e qualquer um calcula quando ele volta.
4. **A SyncTest compara o estado inteiro gravado.** Hoje ela compara a posição (até 1 mm), o `on_floor` e o `mode`. Passa a comparar todo campo gravado: inteiros, booleanos e nomes exatos; floats, vetores e a posição até 0,000001 m. É trocar um `expect` de três campos por um `toEqual` do objeto inteiro: pega o campo novo esquecido antes de virar bug de rede.
   - **A salvaguarda:** se os quatro cenários da TASK-9 mostrarem ruído acima de 0,000001 m, a posição continua em 1 mm e o resto fica exato. O implementer mede na rodada B, e você ouve o número. A sonda do Desenho 3 mediu erro máximo de 0,000000 m (`rede.md` §4).
   - A conferência da rede (`tools/net_run.sh`) continua em 1 mm.

Mais o `double_jump_tick`, o carimbo do pulo duplo, que vira a chave do sinal visual na TASK-10.4.

### O que não muda

- Nenhum contato novo com o motor: o `fighter.gd` só passa a `global_position` e o `fighter.tscn` só troca os caminhos gravados.
- Os contornos (DEC-0025; DEC-0037), a configuração do netfox e o input (continua `move`, `yaw` e `jump`).

### Os arquivos

- **Núcleo:** `core/fighter/fighter_state.gd`, `movement.gd` e `movement_config.gd`; novos `core/fighter/fighter_command.gd` e `core/fighter/stamina.gd`.
- **Dados:** `data/movement_data.gd` (cinco campos novos, com a checagem), `data/movement_v0.tres` e `test/reference/frozen_movement.tres` (os números novos, de propósito).
- **Adaptador:** `fighter/fighter.gd` (a posição) e `fighter/fighter.tscn` (os caminhos do estado).
- **Testes do test-writer, travados:** `movement_double_jump_test.gd`, `stamina_test.gd`, as linhas novas de `movement_data_test.gd`, o `movement_rig.gd` e os seis testes da TASK-9 em `movement_jump_test.gd`. Um aperto no ar agora dá o pulo duplo.
- **Testes do implementer:**
  - `test/support/sync_observer.gd`: a comparação do estado inteiro;
  - `test/fighter/fighter_sync_test.gd`: o cenário "pulo duplo" e dois testes de veneno;
  - o HopBot do pouso ganha um pulo duplo no topo, para o aperto perto do chão continuar indo para a vaga;
  - `fighter_scene_test.gd`: os caminhos novos.
- **A referência:** o aperto no ar do passo 513 vira pulo duplo. A rota ganha um aperto no topo antes dele, e o `route.trace` é regravado com o motivo no commit.

### A ordem

1. **test-writer** (Fable, high), já rodando: os critérios 1 a 7. Eu travo os arquivos com o sha256.
2. **implementer, rodada A** (Opus 5.5, xhigh): o núcleo, os dados, a configuração e a assinatura, com o tempo do portão medido em silêncio.
3. **implementer, rodada B:** o observador, o cenário, os venenos, a referência regravada e o `rede.md` §4 e §8 e o `testes-e-entrega.md`.
4. **reviewer** (Fable, high), de contexto limpo.
5. **O portão**, rodado por mim, e o commit.
6. **Você joga:** sobe o bloco de 2 m direto, aperta perto do pouso e gasta três pulos duplos seguidos. Ainda não tem barra na tela: o HUD é a TASK-10.2.

### Verificação

- `bash tools/gate.sh` verde, com o tempo impresso.
- O resumo da SyncTest mostra pelo menos 3 pulos duplos, 1 depois da beirada, 1 recusado, os 2 pulos guardados do pouso e zero divergências; os dois venenos acusam.
- A referência precisa dar o mesmo hash no Linux do CI. Isso pede subir a branch num PR rascunho, e eu peço o seu ok na hora.
- À mão: `godot --path .` abre o Sozinho.

### Riscos

- **O portão** já levou de 61 a 114 s contra o limite de 90 s. Medido na rodada A: acima de 90 s, a divisão do job do CI (DEC-0027 §4) vira uma DEC nesta task, e você ouve antes.
- **A referência regravada** só se prova no Linux com um push, que espera o seu ok.
