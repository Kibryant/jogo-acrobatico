---
id: F-195
titulo: O Arthur libera a correção mínima de dois testes travados da TASK-12.3 — a armadura que exigia quem carrega nunca congelar, e o parry que procurava um tick livre que não existe (sessão 21, 30/10/2026)
recebido_em: 2026-10-30
como: Resposta do Arthur à pergunta do Claude no terminal da sessão 21, depois do BLOCKED do implementer e da confirmação do reviewer em contexto limpo. Opção escolhida, como chegou; a pergunta e as opções estão como foram mostradas, com a recomendação do Claude em primeiro lugar.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: o implementer construiu a TASK-12.3 e parou com BLOCKED. Dos 2.033 casos, só 6 falharam, todos em dois testes travados. O reviewer confirmou, sem saber da conclusão do Claude, que as duas asserções estão erradas e que o código está certo.
>
> Na armadura (`combat_armor_test.gd`, linhas 278-279 e 346-347), o teste exigia que quem carrega nunca congelasse e que as fases do golpe não andassem, por todo o golpe. Só que o carregado dele pega quem deu o leve, e quem acerta um carregado congela 7 ticks pela foto (DEC-0055 §4; `combate.md`, "O hitstop e o tremor").
>
> No parry (`combat_parry_test.gd`, linha 684), o ajudante procurava o primeiro tick com a ação vazia depois da postura. Mas o carregado do castigo sai no mesmo tick em que a postura acaba, e a linha 686 exige justamente isso. As duas linhas não podem valer juntas.
>
> É a sexta e a sétima suposição de teste travado na fase 2 (F-177; F-187).

## §1 — A pergunta e as opções, como foram mostradas

"Libero a correção mínima dos dois testes travados da TASK-12.3, que o reviewer confirmou estarem errados?"

- "Libera as duas (Recomendado)": "Armadura: a checagem de que quem carrega nunca congela passa a parar no tick antes de o carregado dele pegar, e depois exige a paradinha de 7 ticks desse acerto. Prova a armadura e a paradinha ao mesmo tempo, mais do que antes. Parry: sai a linha que procurava um tick livre que não existe; a linha seguinte já prova que o carregado começa no contato + 12. Só os hashes desses dois arquivos mudam na trava."
- "Quero ver as linhas antes": "Mostro o diff exato dos dois arquivos e pergunto de novo antes de mexer na trava."

## §2 — A resposta

"Libera as duas (Recomendado)"
