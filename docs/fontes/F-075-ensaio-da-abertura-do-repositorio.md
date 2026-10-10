---
id: F-075
titulo: "O ensaio da abertura do repositório num clone: o gitleaks no histórico inteiro sem achado, os autores, o tamanho, as licenças das dependências, os refs do GitHub e a busca por dado pessoal (10/10/2026)"
recebido_em: 2026-10-10
como: Ensaio feito pelo Claude na sessão 10, num clone completo do repositório em `../abertura-ensaio`, fora do repositório, com todas as branches buscadas. O gitleaks 8.30.1 varreu o histórico de todas as refs; os demais números saem do git e de uma busca por padrão no `git log --all -p`.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: é o critério 5 da TASK-8. O ensaio roda antes de qualquer decisão da rodada 2, para o Arthur decidir sabendo o que fica público. Cite como F-075 §1 a §3.

## §1 — Segredos e autores

- O gitleaks varreu 40 commits, uns 2,9 MB, e não achou vazamento (`no leaks found`).
- Os commits de todas as refs têm dois autores: `Kibryant <arthurgustavon@gmail.com>` em 40 e `Arthur Gustavo <124307212+Kibryant@users.noreply.github.com>` em 1, o merge do PR #2.
- No GitHub, os refs são `main`, `task-7-desenho-5` (já juntada na main) e `refs/pull/1/head` e `refs/pull/2/head`.

## §2 — O que fica público

| O que | Valor |
|---|---|
| Arquivos na main | 901, uns 1,8 MB |
| `addons/` | 693 arquivos: o gdUnit4 e o netfox, os dois com licença MIT e o arquivo `LICENSE` ao lado |
| `docs/` | 126 arquivos, com as fontes em que estão as falas do Arthur e os diários |
| `backlog/`, `.claude/`, `tools/`, `test/` | 13, 13, 38 e 4 arquivos |
| Assets de terceiros | nenhum ainda |
| Objetos no LFS | 8 |
| Maior arquivo do histórico | 74 KB, a F-051 |

## §3 — A busca por dado pessoal no histórico inteiro

| Padrão | Achados |
|---|---|
| IPv4 público | 4 endereços de documentação ou de teste: `1.0.0.0`, `100.64.0.0` (a faixa do CGNAT), `1.1.1.1` e `216.238.98.118` (o endpoint de ping da Vultr em São Paulo). O IP desta casa não aparece. |
| CPF | nenhum |
| Telefone celular brasileiro | nenhum |
| E-mails | o do Arthur, o noreply dele, o `noreply@anthropic.com` das linhas de coautoria e um exemplo de formato |
| Caminhos com o usuário do Windows (`Users/arthu`) | 14 |
