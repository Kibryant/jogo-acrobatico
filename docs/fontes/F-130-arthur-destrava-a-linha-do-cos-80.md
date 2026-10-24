---
id: F-130
titulo: O Arthur acerta por que a linha travada do cos 80° nunca passa e a destrava para correção (sessão 15, 23/10/2026)
recebido_em: 2026-10-23
como: Respostas do Arthur às duas perguntas do Claude no terminal da sessão 15, depois de o implementer voltar BLOCKED na rodada B da TASK-10.5. Opções escolhidas, como chegaram.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: `test/core/fighter/movement_wall_test.gd`, em `test_the_valid_wall_threshold_is_cos_80_degrees`, exigia que |normal.y| a 80,0001° (0,1736465) fosse menor que 0,1736, o cos 80° arredondado do `movimento.md`. É uma conta sem código do projeto, falsa para qualquer implementação. A rodada B passava em 868 de 869 testes.

## §1 — As respostas

- Para conferir, "por que essa linha do teste travado nunca passa?": "Compara com um número arredondado". Certa, de primeira.
- "Posso destravar essa linha para o test-writer corrigir e travar de novo?": "Destrava e corrige (Recomendado)". A opção dizia: "Só essa linha: ela passa a comparar com o cos 80° exato, e a linha de cima continua conferindo o 0,1736 do design. O test-writer corrige, e eu travo de novo".
