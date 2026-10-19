---
id: F-094
titulo: O Arthur começa a parte 3 da TASK-9, a esteira, erra a primeira conferência da referência, acerta a segunda e aprova o plano (sessão 13, 18/10/2026)
recebido_em: 2026-10-18
como: Mensagem do Arthur ("parte 3") e duas rodadas de perguntas no terminal da sessão 13, com as opções escritas pelo Claude. As respostas estão como o Arthur escolheu.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: a parte 2 da TASK-9 entrou na main no merge commit `55be8f8` (PR #7). O Claude ofereceu três caminhos: o passeio por um tick inteiro, a parte 3 ou o diário, e recomendou o passeio. O Arthur escolheu a parte 3. O Claude abriu a branch `task-9-delivery-pipeline`, mandou o explorer mapear as entradas e mostrou o plano em três rodadas: D1, a referência no portão e as sobras da parte 1; D2, as builds, a release e a imagem do servidor no CI; D3, a medição de fps neste PC. O critério 18 vem por último, com o ok do Arthur.
>
> Antes das perguntas, o Claude explicou numa ideia só que a referência é um snapshot do Jest para o movimento: os números ficam congelados numa cópia só do teste, e só uma mudança de código quebra a referência. Depois da primeira resposta, nomeou a ideia errada ("se reprovou, ficou velha, e é só regravar") e deu um exemplo do próprio código: o `yaw` da câmera entra no input e decide a direção da corrida.

## §1 — A primeira rodada

- **Conferência:** "Você muda só o código da câmera, e a referência reprova no portão. O que isso diz?" Ele escolheu "É só regravar" ("A câmera não é movimento, então a referência está desatualizada."). A certa era "A mudança mexeu no caminho".
- **Plano:** "Posso começar a parte 3 pela rodada D1?" Ele escolheu "Pode começar (Recomendado)", cuja descrição dizia: "D1, D2 e D3 em série, como no plano. Eu te chamo para rodar a medição do fps e para o ok da release."

## §2 — A segunda conferência

"Você atualiza o netfox para uma versão nova, sem mudar nada do jogo, e a referência reprova no portão. Qual é o primeiro passo?" Ele escolheu "Investigar a mudança" ("O netfox novo mudou o caminho do lutador; entender o porquê antes de qualquer coisa."), a certa.
