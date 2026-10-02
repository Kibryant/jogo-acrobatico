# Mudanças

Registro do que mudou de estado, e por quê. **Só acréscimo:** linha nova no fim, nunca edição nem remoção de linha antiga. Se uma linha estiver errada, a correção é outra linha.

| Data | Como era | Como ficou | Por quê | O que foi afetado |
|---|---|---|---|---|
| 2026-10-02 | Próxima sessão do estudo: jogar GunZ Remastered e Naraka (passo 3) e testar o s&box (passo 5) (F-001) | Os dois passos saíram do roteiro. O PC fica só para LoL, navegador, Claude Code, GitHub e o projeto | O Arthur não vai rodar jogo nessa máquina e quer focar no projeto (F-003 §2) | `roteiro.md` |
| 2026-10-02 | O briefing propunha seis sessões de estudo antes do código (F-002) | Construir aprendendo: o Claude constrói e ensina (DEC-0010) | Correção do Arthur (F-003 §4) | `AGENTS.md`; todas as tasks |
| 2026-10-02 | Fase 0 do estudo: reconhecimento de 2 a 4 semanas (F-001) | Base do repositório (TASK-1), fase de desenho (TASK-3 a TASK-8) e esqueleto andante (TASK-9) | Pedido do Arthur por uma base completa antes do código (F-003 §4); DEC-0012, proposta | `roteiro.md`; marco m-0 |
| 2026-10-02 | O estudo previa 60 atualizações por segundo (F-001) | O padrão do netfox é 30 ticks por segundo, e a escolha vai para o Desenho 3 (Q-01) | Pesquisa do netfox (F-005 §3) | `pendencias.md`; TASK-5 |
| 2026-10-02 | Fase 1 do estudo: movimento sem rede (F-001) | O Desenho 3 decide se o movimento já nasce no tick do netfox | Adaptar o rollback depois custa caro (F-007 §2) | `roteiro.md`; TASK-5 |
| 2026-10-02 | A fase de desenho era proposta (DEC-0012) | DEC-0012 aceita: seis conversas de desenho e um esqueleto andante antes do código de jogo | O Arthur aceitou a recomendação na sessão 2 (F-010 §2) | `decisoes/README.md`; `roteiro.md`; TASK-3 |
| 2026-10-02 | Tasks em português eram leitura do agente, a confirmar (DEC-0008; Q-08) | Confirmado: tasks em português | O Arthur aceitou a recomendação na sessão 2 (F-010 §2) | `decisoes/README.md`; `pendencias.md` |
| 2026-10-02 | As notas da TASK-1 diziam que a sonda da pureza ignorou texto entre aspas | Texto entre aspas conta (falso positivo), e um `#` dentro de string esconde o resto da linha (falso negativo) | Sonda da sessão 2, rodada numa cópia fora do projeto. O Arthur decidiu consertar no Desenho 4 (F-010 §2) | TASK-1; TASK-6 |
| 2026-10-02 | O job `core-purity` do pre-commit usava `core/**/*.gd`, que no dialeto padrão do lefthook exige uma subpasta: arquivo na raiz de `core/` passava | `glob_matcher: doublestar` no `lefthook.yml`, com o `format` em `**/*.gd`. A mesma sonda passou a ser barrada | Uma sonda em `core/probe.gd` passou pelo pre-commit no primeiro commit; o portão a teria barrado no pre-push. O Arthur aprovou o conserto (F-011 §1) | `lefthook.yml`; TASK-1 |
