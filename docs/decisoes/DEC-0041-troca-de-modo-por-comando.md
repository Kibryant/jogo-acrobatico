---
id: DEC-0041
titulo: A troca de modo por comando no before_move — a DEC-0022 muda só nisso
data: 2026-10-23
status: aceita
decidido_por: Arthur (F-122)
fontes: [F-100, F-121, F-122]
substitui: DEC-0022, só a frase de que o after_move é quem atualiza o modo
substituida_por:
---

# DEC-0041 — A troca de modo por comando no `before_move`: a DEC-0022 muda só nisso

## Contexto

A DEC-0022 pôs a máquina de estados do lutador no núcleo, como dado: um `mode` e o `mode_since`, trocados por funções puras. Ela deu a troca ao `after_move`, que recebe os fatos do motor (no chão ou não) e atualiza o modo (DEC-0022, "O tick por dentro"). No esqueleto andante e na TASK-10.1, todo modo muda por contato: `GROUND` e `AIR`.

O dash (TASK-10.4) é o primeiro modo que nasce de um comando: o aperto sai no `before_move`, que já decide a velocidade do tick. É um modo comprometido. Nos 200 ms, a direção não muda, o pulo não o corta e ele só termina pela própria regra (F-121). Se o `after_move` continuasse dono do modo, o primeiro tick do dash já veria "no chão" e voltaria a `GROUND`. O pulo da parede e o gancho (TASK-10.5 e 10.6) são comandos do mesmo tipo.

## Opções consideradas

1. **A troca por comando no `before_move`, a troca por contato no `after_move`:** cada troca mora onde a sua causa aparece. O `after_move` não mexe num modo comprometido. A escolhida.
2. **Tudo no `after_move`,** com o comando passado como fato: o `after_move` passaria a ler o input, que não é um fato do motor, e o tick do comando ficaria um tick atrasado na velocidade.
3. **Um campo de modo separado para as manobras:** dois modos ao mesmo tempo, e cada regra perguntaria pelos dois.

## Decisão

Aceita pelo Arthur em 23/10/2026, no plan mode da TASK-10.4 (F-122), depois de acertar a conferência do dash comprometido (F-121).

1. **O `before_move` troca o modo por comando.** Quando a vaga do buffer guarda um comando vivo e legal (DEC-0039), ele muda o modo e carimba o `mode_since` com o tick. O primeiro comando assim é o dash: `GROUND → DASH`.
2. **Um modo comprometido termina pela própria regra, no `before_move`.** O `DASH` termina quando os 12 ticks passam. O modo volta a `GROUND` ou `AIR` conforme o `on_floor` do estado, e no mesmo tick um aperto guardado pode sair.
3. **O `after_move` troca o modo por contato,** `GROUND` e `AIR`, só fora de um modo comprometido. Ele continua atualizando o `on_floor`, o carimbo de saída do chão e os pulos usados em todo tick.
4. **O empate no mesmo tick** segue a DEC-0039 §4: o pulo vence o dash.

## Consequências

- **A DEC-0022** ganha o aviso de substituição parcial no topo e continua valendo no resto.
- **O `visao-geral.md`** ("O tick por dentro") ganha a frase das duas trocas. O glossário ganha "Troca por comando", "Troca por contato" e "Saída desenhada".
- **O pulo da parede (TASK-10.5) e o gancho (TASK-10.6)** entram como novos modos comprometidos pela mesma regra, sem DEC nova.

## Revisitar se

- Jogando, o dash parecer preso, e um corte pelo pulo voltar à mesa (F-121): o corte seria um cancelamento, com preço e aviso (DEC-0016), numa DEC nova.
- Uma manobra precisar mudar de modo no meio de outro modo comprometido, como um gancho durante o dash.
