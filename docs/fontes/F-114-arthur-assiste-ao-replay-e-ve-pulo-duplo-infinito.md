---
id: F-114
titulo: O Arthur joga, assiste ao replay com o --watch, acha massa e conta que parece ter pulo duplo infinito (sessão 15, 23/10/2026)
recebido_em: 2026-10-23
como: Mensagem do Arthur no terminal da sessão 15, por voz, depois de jogar o Sozinho por uns 3 minutos (11 180 ticks gravados) e assistir à jogada refeita com `bash tools/replay.sh ... --watch`. Texto como chegou.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: é o teste à mão da TASK-10.3 (critério 8). A janela refez os 11 180 ticks até o fim, a 63,7 quadros por segundo, e se separou da jogada ao vivo no último bit de um float a partir do tick 347, como a medição do critério 5 já mostrava.

## §1 — A mensagem

"Oh, achei massa, achei massa. Gostei bastante. Gostei. Bem tranquilo. Eu acho que uma coisa. Eu tô conseguindo dar double jump infinito. Não sei se isso entra agora, mas eu tô conseguindo dar double jump infinito. Mesmo quando a estamina tá lá embaixo, eu dou, tipo assim, ela desceu, zerou. Eu dou o primeiro pulo, ela já recarrega o suficiente pra eu já dar o segundo jump, sabe? Parece que eu sempre tenho estamina. Mas, acho que a única coisa é essa, assim, que eu vi de diferente agora. Pareceu que eu tinha double jump infinito, mas se isso não é pra agora ou se foi proposital, não tem problema. Só tô avisando só o que eu vi."

## §2 — A conta, escrita pelo agente

Com os números v0 (`movimento.md`, "Stamina" e "Pulo e ar"), o pulo duplo mais rápido possível sai a cada 64 ticks: 21 subindo no pulo, 19 subindo no pulo duplo, 23 caindo 2,2 m e 1 no chão. A barra precisa de 68 ticks para ir de 0 a 10: 48 de espera e mais 20 recuperando a 0,5 por tick. Faltam 4 ticks, uns 67 ms, que somem no ritmo de quem joga. Com um pulo duplo por voo, a barra só pesa quando o dash (15 pontos, TASK-10.4) e o combate também gastarem.
