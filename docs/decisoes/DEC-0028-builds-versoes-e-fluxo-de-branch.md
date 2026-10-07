---
id: DEC-0028
titulo: Builds, versões e fluxo de branch — dois presets, build no PR e na tag, SemVer 0.y.z com o commit carimbado, uma branch por task com PR e um worktree por sessão paralela
data: 2026-10-07
status: aceita
decidido_por: Arthur
fontes: [F-009, F-017, F-038, F-045, F-046, F-047, F-048]
substitui:
substituida_por:
---

# DEC-0028 — Builds, versões e fluxo de branch: dois presets, build no PR e na tag, SemVer 0.y.z com o commit carimbado, uma branch por task com PR e um worktree por sessão paralela

## Contexto

A DEC-0012 pôs o pipeline de CI, as builds e as versões na fase de desenho. Até aqui, o projeto não tinha preset de export, número de versão nem fluxo de branch: o commit ia direto na main, e o plano Free do GitHub não aplica regra de branch em repositório privado (Q-03; F-017 §2).

Ao deixar a TASK-6 Ready, o Arthur escolheu provar a build numa sonda e partir do fluxo trunk-based, com uma branch curta por task e um PR (F-038 §4).

A rodada 3 mediu tudo (F-045):
- os dois presets exportam neste PC e no Linux do CI, sempre com código 0;
- o pacote do jogo leva o netfox e nada de `test/` ou do gdUnit4;
- o servidor exportado sobe no Linux como servidor dedicado e fecha com código 0;
- o `.exe` montado no Linux roda neste PC com a versão certa nas propriedades.

A pesquisa da sessão 6 trouxe a cota do plano Free, os templates e o export sem rcedit (F-047 §1).

## Opções consideradas

**Quando a build sai** (F-046 §1):
1. No PR e na tag: a escolhida.
2. Em todo push na main: com 68 MB por dupla, a retenção teria de ser de 1 dia para caber na cota.
3. Só na tag: quase nada de cota e de CI, mas a build de um PR sairia à mão.

**Quando a versão sobe:**
- o `y` a cada marco do roteiro, e o `z` a cada build que sai para alguém jogar: a escolhida (F-046 §2);
- subir a cada task não foi adiante, porque o commit carimbado já identifica cada build (raciocínio do agente).

**O fluxo** (F-038 §4; F-046 §3):
1. Uma branch curta por task, com PR: a escolhida.
2. O commit direto na main, como até a TASK-6.

## Decisão

### 1. Os dois presets

- **"Cliente Windows":** Windows Desktop, x86_64, PCK embutido (F-045 §2). O ícone e a versão do `.exe` são escritos pelo próprio Godot, com `application/modify_resources`, sem rcedit, desde o 4.5 (F-047 §1.5).
- **"Servidor Linux":** Linux, x86_64, PCK embutido, exportado como servidor dedicado (F-045 §2). Essa exportação liga a feature tag `dedicated_server` e tira a parte visual dos recursos (F-047 §1.6).
- **O que fica fora dos dois:** `test/*`, `addons/gdUnit4/*`, `tools/*` e `reports/*` (F-045 §2).
- **O `export_presets.cfg` entra no repositório,** e um teste guarda os presets (F-048).
- **Os templates:**
  - neste PC, só os de Windows e Linux, baixados pelo editor: 344 MB no disco (F-045 §1);
  - no CI, o `setup-godot` baixa o pacote inteiro, de 1,28 GB, e guarda no cache (F-047 §1.4; F-045 §3).

### 2. Quando a build sai

- **No PR,** guardada por 3 dias, para o Arthur jogar antes do merge.
- **Na tag `v0.y.z`,** como release do GitHub.
- **O push na main não gera build** (F-046 §1).
- **A conta da cota:**
  - o plano Free dá 500 MB para artefatos, divididos com os pacotes, e guarda cada artefato por 90 dias se ninguém disser outra coisa (F-047 §1.1);
  - uma dupla de builds compactada pesa 68,4 MB (F-045 §3);
  - com três PRs abertos, o pior caso fica em uns 200 MB (a conta: 3 × 68,4 MB);
  - o arquivo de uma release não entra nessa conta, até onde a documentação diz, mas isso não está confirmado (F-047 §1.1).
- **O tempo de CI:** o job de export levou 83 s com o cache frio e 57 s com o quente, dos 2.000 minutos do mês (F-045 §3; F-047 §1.1).

### 3. As versões

- **SemVer `0.y.z`,** só dígitos e pontos. O `.exe` mostra `0.1.0` como `0.1.0.0`, e qualquer outra coisa o faz cair para `1.0.0.0` (F-045 §2; F-047 §1.5).
- **O `y` sobe no commit que fecha um marco do roteiro:**
  - o 0.1.0 é o esqueleto andante;
  - o 0.2.0 é a fase 1;
  - o 0.3.0 é a fase 2, e assim por diante;
  - o 1.0.0 é o lançamento (F-046 §2).
- **O `z` sobe a cada build que sai com tag para alguém jogar,** dentro de uma fase (F-046 §2).
- **Onde mora:** em `application/config/version`, no `project.godot`. Até o esqueleto andante, vale `0.0.0`, que quer dizer "nada lançado ainda" (F-048). Um teste confere o formato.
- **Quem sobe:** o Claude, no commit da tag, com o ok do Arthur (F-048).
- **O CI carimba o commit** em `application/config/commit` na hora do export, e no editor ele fica vazio (F-046 §2). Na sonda, o CI escreveu o carimbo antes de exportar (F-045 §3), e o `.exe` feito no Linux o leu neste PC (F-045 §4).
- **A tag `v0.y.z` vira uma release no GitHub,** privada, com as duas builds e notas em português tiradas do diário (F-046 §2).
- **O aperto de mão:** o cliente manda versão e commit ao conectar, e o servidor recusa os diferentes, pedindo para atualizar. No rollback, os dois precisam rodar a mesma regra (DEC-0026). Mora na Main, na TASK-9 (F-046 §2).
- **O replay leva no cabeçalho** a mesma versão e o mesmo commit (DEC-0027).

### 4. O fluxo de branch

1. A task fica Ready na main, no papel (F-046 §3).
2. No In Progress, nasce uma branch curta, `task-N-nome`, e todo commit da task vai nela: código, docs e o diário das sessões dela.
3. No fim, o Claude abre o PR em português, com o que mudou, os critérios, como testar e o link da build. A task vira Done dentro do PR.
4. O CI roda no PR o portão e as duas builds.
5. O Arthur revisa e joga a build. O merge é dele, ou do Claude com o ok dele, num merge commit: os commits das rodadas ficam, e desfazer a task inteira é um revert só.
6. Sessão sem task, só de diário ou de decisão, vai direto na main.
7. Duas sessões ao mesmo tempo nunca dividem a mesma pasta: cada uma trabalha no seu worktree (F-046 §3).

### 5. Os ambientes

- **O PC do Arthur:** o editor, o portão local e as sondas, que ficam fora do repositório.
- **O CI no GitHub, no Linux:** o portão e as builds.
- **A build de teste:** o artefato do PR ou a release.
- **O servidor de verdade:** do Desenho 6 (TASK-8).

O endereço do servidor vem dos argumentos da Main (DEC-0026).

## Consequências

- **A TASK-9 herda:**
  - o job de build no PR e na tag;
  - o teste de fumaça do servidor exportado;
  - o 0.1.0 com a tag `v0.1.0`;
  - o aperto de mão na Main.

  O critério 3 dela, que pedia a build a cada push na main, é refeito quando ela ficar Ready.
- **O #123712, o Godot caindo ao sair depois de exportar no Linux,** não apareceu em quatro exports (F-045 §3; F-047 §1.6). Se aparecer no job da TASK-9, o job confere o artefato e o teste de fumaça, e não só o código de saída.
- **O import roda antes do export,** o que evita o #1324 do gdUnit4, que derruba o primeiro export feito sem a pasta `.godot` (F-047 §1.6).
- **A TASK-6 abriu antes desta DEC e fecha na main.** A primeira branch é a da próxima task.
- **O plano Free não impõe o fluxo** (Q-03). O pre-push continua sendo a trava, e o CI no PR é a segunda conferência.
- **O merge para pedindo a permissão do Arthur,** como todo o resto voltado para fora (DEC-0009).

## Revisitar se

- A cota de artefatos apertar: a retenção cai, ou a build sai só na tag.
- O tempo do CI incomodar: o cache pode guardar só os dois templates usados.
- O #123712 aparecer no CI.
- O PR por task atrasar mais do que ajuda.
- Alguém de fora começar a testar as builds (Q-20).
