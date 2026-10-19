---
id: F-098
titulo: O Arthur erra duas vezes a conferência sobre a release pública, aprova os docs da parte 3 e escolhe ler as notas da release antes de publicar a v0.1.0 (sessão 13, 18/10/2026)
recebido_em: 2026-10-18
como: Duas rodadas de perguntas no terminal da sessão 13, com as opções escritas pelo Claude. As respostas estão como o Arthur escolheu.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: o revisor aprovou os critérios 14 a 17 da TASK-9. A metade do critério 14 que fala da tag só se prova no critério 18. O Claude restringiu o filtro do erro do Godot ao job da imagem (commit `0b55f35`), mostrou o pacote de docs da parte 3 e a ordem do critério 18:
> 1. o diário;
> 2. as notas da release;
> 3. a versão 0.1.0;
> 4. a TASK-9 como Done;
> 5. o merge do PR #8;
> 6. a tag `v0.1.0`;
> 7. o marco m-0 arquivado.
>
> Antes das perguntas, explicou numa ideia só que a release é pública e fica: o artefato do PR some em 3 dias, e a release da tag fica na página de download do repositório para qualquer pessoa.
>
> Depois da primeira resposta errada, o Claude nomeou a ideia errada ("a release é como o artefato do PR") e comparou a release com um `npm publish`. Depois da segunda, parou de perguntar, como manda a regra do registro do harness de 07/10/2026, e explicou uma vez com o próprio projeto: o repositório aberto numa aba anônima mostra tudo, e a release vai aparecer em Releases.

## §1 — A primeira rodada

- **Conferência:** "Depois que a tag v0.1.0 sobe, quem consegue baixar o jogo?" Ele escolheu "Só você, por 3 dias" ("Como o artefato do PR."). A certa era "Qualquer pessoa".
- **Docs:** "Posso atualizar os docs da parte 3?" Ele escolheu "Atualiza tudo (Recomendado)", cuja descrição dizia: "testes-e-entrega.md, rede.md, glossário, README e mudancas, como na lista, com o custo real da referência e a exceção do erro do Godot."
- **Release:** "Como seguimos com a versão 0.1.0 e a primeira release pública?" Ele escolheu "Notas, você lê, publica (Recomendado)", cuja descrição dizia: "Escrevo o diário e as notas da release e te mostro as notas. Com o seu ok, faço o merge do PR #8 e subo a tag v0.1.0, que publica a release."

## §2 — A segunda conferência

"Um amigo seu, sem conta no GitHub, abre o link do repositório daqui a um mês. Ele consegue baixar a v0.1.0?" Ele escolheu "Só se você liberar" ("Precisa de acesso ao repositório."). A certa era "Sim, em Releases".
