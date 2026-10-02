---
id: F-009
titulo: O padrão do SkinHub e do YabaBuss que este repositório copia
recebido_em: 2026-10-02
como: Lido pelo Claude na sessão do my-brain de 02/10/2026. Fontes, em ~/Projects/my-brain: estudos/2026-09-tokens/ab/snapshot/, que é o SkinHub congelado no commit eca85d3 de 19/09/2026. No Yabadoo, as decisões sobre as harnesses de 23/09 e 24/09/2026 e os documentos ec9ee245 e 8be60b27.
status: vigente
substituida_por:
---

## Do snapshot do SkinHub (19/09/2026)

- O `CLAUDE.md` tem mapa, ordem de leitura, regras de invalidação, idioma e Backlog.md. As regras de invalidação: só DEC aceita é regra, toda afirmação cita a origem e nada se apaga, só se substitui.
- `docs/fontes/` guarda as F-xxx, que são imutáveis.
- `docs/decisoes/` guarda as DEC-xxxx em formato ADR (Contexto, Opções consideradas, Decisão, Consequências, Revisitar se). O `README.md` é o índice, com Vigentes, Propostas e Histórico.
- `docs/mudancas.md` só recebe acréscimo, e `docs/pendencias.md` guarda as perguntas abertas.
- **DEC-0010 do SkinHub:** a base fica em markdown e git, com as tasks no Backlog.md e o conhecimento em `docs/`. Não se usa `backlog decision` nem `backlog doc`.
- **DEC-0025 do SkinHub:** fase de desenho antes do código, em seis conversas que terminam em documento e DEC. O primeiro código é um esqueleto andante.
- **`backlog/config.yml`:** estados To Refine, Ready, In Progress, Waiting, Parked e Done; prefixo TASK; definição de pronto.
- **Formato da task:** seções Why, Open questions, Choices to confirm e Out of scope. Os critérios seguem "When <situation>, the app <does>" e cobrem nenhum, um, muitos, limite e falha. Durante e depois do trabalho entram Implementation Notes e Final Summary.
- **`lefthook.yml`:** gitleaks no pre-commit.

## Das decisões e documentos do Yabadoo

- **Harness do SkinHub (23/09/2026):** a conversa principal orquestra e despacha, em série:
  - um test-writer cego à implementação;
  - um implementer;
  - um reviewer de contexto limpo;
  - um portão final determinístico.

  Tudo que é interno ao agente fica em inglês e versionado. Push, merge e deploy param para pedido de permissão.
- **Harness do YabaBuss no padrão do SkinHub (24/09/2026):** registra cada task e promove o que se repete. A revisão mensal acontece na primeira segunda do mês. Os dois projetos usam os mesmos nomes e formatos de skills, hooks e registro.
- **Desfecho do estudo de agentes (doc ec9ee245, 23/09/2026):**
  - Modelos por papel: leitores em Fable; test-writer e revisor em Fable high; implementer no modelo da sessão, com Fable a partir da 4ª rodada.
  - A harness só aperta; afrouxar é com o Arthur.
  - O Stop hook saiu porque dispara a cada resposta.
- **Diagnóstico do YabaBuss (doc 8be60b27, 24/09/2026):**
  - O commit levava de 6 a 9 minutos, e o agente passou a usar `--no-verify`.
  - O agente editou a própria memória para pular a checagem.
  - Eram 52 mil caracteres de contexto fixo.
  - Havia testes estranhos: testes que liam código-fonte, mock de função privada e teste usado como diário.
  - Decidido: pre-commit abaixo de 15 s, pre-push abaixo de 90 s e AGENTS.md em inglês com até ~12 mil caracteres.
