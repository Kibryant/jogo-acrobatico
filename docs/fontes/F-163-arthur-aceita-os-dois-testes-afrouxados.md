---
id: F-163
titulo: O Arthur aceita os dois testes afrouxados da TASK-10.9 — a lista com nome das palavras iguais em pt-BR e en, e o silêncio do motor na leitura do arquivo corrompido (sessão 18, 26/10/2026)
recebido_em: 2026-10-26
como: Resposta do Arthur à pergunta do Claude no terminal da sessão 18, depois do relatório do implementer da TASK-10.9. Opção escolhida, como chegou.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: afrouxar uma conferência é decisão do Arthur (AGENTS.md, "Harness": "The harness only tightens; loosening is Arthur's call"). O `test/ui/game_text_test.gd` exigia todo texto diferente em pt-BR e en; o implementer pôs uma lista com nome, `GameText.SAME_IN_BOTH`, que precisa ser curta e falha se uma palavra dela passar a diferir. O `test/ui/options/options_store_test.gd` cala as mensagens de erro do motor só na leitura de um arquivo corrompido de propósito, para o log verde não ganhar um `ERROR:` que o próprio teste provoca. O revisor julgou as duas estreitas e bem guardadas.

## §1 — A resposta

- "O implementer afrouxou dois testes. Você aceita os dois?": "Aceito os dois (Recomendado)". A opção dizia: "1) O teste das traduções exigia todo texto diferente em pt-BR e en; agora aceita uma lista curta com nome (\"Dash\", \"Mouse\", \"Interface\", \"Mouse {n}\"), e se uma palavra da lista passar a diferir, o teste falha. 2) O teste do arquivo de opções corrompido cala as mensagens de erro do motor só naquela leitura, para o log verde não ganhar um ERROR que o próprio teste provoca." As outras eram aceitar só o das traduções, ou nenhum.
