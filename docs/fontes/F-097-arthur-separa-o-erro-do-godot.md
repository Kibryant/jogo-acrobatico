---
id: F-097
titulo: O Arthur acerta que as linhas de ERROR do servidor Linux exportado não mudam nada para quem joga e escolhe ignorar só essa mensagem no job da imagem (sessão 13, 18/10/2026)
recebido_em: 2026-10-18
como: Uma rodada de perguntas no terminal da sessão 13, com as opções escritas pelo Claude. As respostas estão como o Arthur escolheu.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: no PR rascunho #8, o job `server-image` passou nas 15 conferências funcionais, mas reprovou porque o servidor exportado deixou quatro linhas no log ao fechar:
> `ERROR: Attempt to disconnect a nonexistent connection from '…'. Signal: 'tree_exited', callable: ''.`
> Elas saem dos nós `NetworkTickrateHandshake`, `Node`, `NetworkTime` e `Main`.
>
> O Claude achou o bug no rastreador do Godot, o #123751, fechado como "não planejado": só a build de release do 4.7.2 no Linux erra ao desfazer as ligações do cache de caminhos do multiplayer, quando o servidor fecha a conexão depois de um RPC. O #95512 é parecido. Neste PC, a build de release do Windows, na mesma sequência, fechou sem erro. O relato traz um contorno: liberar os nós que fizeram RPC antes de fechar a conexão. Aqui isso mexeria nos autoloads do netfox e na ordem de fechar da DEC-0026 §6.
>
> Antes das perguntas, o Claude explicou numa ideia só que as linhas são como um aviso que só aparece no build de produção, vindo de dentro de uma biblioteca, sem quebrar nada.

## §1 — As respostas

- **Conferência:** "Para quem joga, o que essas quatro linhas de ERROR mudam quando o servidor fecha?" Ele escolheu "Nada" ("O servidor fecha com 0 e o cliente recebe o aviso; só o log fica sujo."), a certa.
- **Decisão:** "Como o job da imagem do servidor deve tratar essas linhas?" Ele escolheu "Ignorar só essas (Recomendado)", cuja descrição dizia: "O job passa a ignorar exatamente essa mensagem, com o link do #123751. Qualquer outro ERROR continua reprovando. Volta a valer quando o Godot corrigir."
