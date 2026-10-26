---
id: DEC-0047
titulo: A mesma parede vale de novo, sem devolver o pulo duplo — o fake na parede sai, e a escada de uma parede só não nasce
data: 2026-10-26
status: aceita
decidido_por: Arthur (F-166 §3; F-167 §2)
fontes: [F-128, F-135, F-166, F-167]
substitui:
substituida_por:
---

# DEC-0047 — A mesma parede vale de novo, sem devolver o pulo duplo

## Contexto

Hoje a mesma parede só aceita uma corrida nova depois de tocar o chão ou outra parede, para impedir subir em zigue-zague nela (`movimento.md`, "Corrida na parede": "Mesma parede"). O que é a mesma parede é o mesmo `wall_id` com a normal a até 10° (DEC-0042 §3). Começar uma corrida na parede devolve o pulo duplo (`movimento.md`, "Renovação do pulo duplo"; F-128).

No teste dos 15 minutos, o Arthur pediu o contrário: "eu não consigo andar na mesma parede depois de eu ir e voltar [...] se eu quero dar um fake, por exemplo, de que eu vou para outra parede, mas eu quero voltar para a mesma, eu deveria poder continuar andando na mesma parede" (F-166 §3).

A regra existe por causa do pulo duplo. Se a mesma parede valesse como nova, cada volta devolveria o pulo duplo, e ele pagaria a volta seguinte: o pulo da parede (+1,2 m) e o pulo duplo de volta (+1,0 m) subiriam 2,2 m por volta, sem fim. Com a stamina, a borda de 50 m subiria em uns 20 s, e o topo dela é fora da arena (vitrine "O teste da fase 1", seção "A mesma parede"; conta no papel com os números do `movimento.md`). Na conferência, o Arthur explicou a escada: "senão ele teria pulo infinito resetando ali toda hora, double jump" (F-167 §1).

Ele achou também a escada em Z entre duas paredes (F-167 §1). Ela já existe, e o `movimento.md` a deixa sem fim, limitada pela altura das paredes, por escolha dele (`movimento.md`, "Corredor estreito"; F-135). Um par de paredes é um lugar que o mapa desenha; uma parede só existe em todo lugar.

## Opções consideradas

1. **A mesma parede vale de novo, sem devolver o pulo duplo (escolhida):** o fake sai, porque a volta é uma corrida nova. A segunda volta não tem pulo duplo, então a escada de uma parede só não nasce. Saindo de uma parede, o mais alto passa de +2,2 m para +3,4 m, uma vez.
2. **Fica como está:** sem fake e sem código novo.
3. **A mesma parede vale como nova:** o fake sai sempre, mas toda parede comprida vira escada até o topo, e a borda de 50 m vira saída.

## Decisão

Aceita pelo Arthur: "Vale, sem devolver o pulo duplo (Recomendado)" e "Antes da 0.2.0 (Recomendado)" (F-167 §2).

1. **A mesma parede aceita uma corrida nova**, com as regras de entrada de toda corrida: no ar, com 4 m/s ou mais ao longo dela, a vertical zera e a velocidade vai a 8 m/s, ou à de entrada até 12 (`movimento.md`, "Corrida na parede").
2. **Essa corrida não devolve o pulo duplo.** Gasto, ele segue gasto; disponível, segue disponível. Só o chão ou uma corrida em outra parede o devolvem.
3. **A mesma parede** continua sendo o mesmo `wall_id` com a normal a até 10° (DEC-0042 §3), e a última parede só muda ao tocar o chão ou outra parede. A cabeça de outro lutador não a muda (DEC-0046 §1).
4. **Nada mais muda:** a emenda, o pulo da parede, a volta no pulo da parede e o Z entre duas paredes ficam como estão.
5. **Entra antes da 0.2.0**, numa filha da TASK-10, com os testes do núcleo (F-167 §2).

## Consequências

- O `movimento.md` troca a linha "Mesma parede" na filha que implementa a regra, e a vitrine "O teste da fase 1" segue no mesmo link (DEC-0019).
- A Q-07 ganha um candidato a técnica: o fake na mesma parede.
- O fechamento da fase 1 e a versão 0.2.0 saem da TASK-10.8 e esperam esta regra (F-167 §2).
- Os cantos da borda são outra questão. Duas bordas formam um par, como o corredor, e o Z ali vale com ou sem esta DEC; a TASK-10.8 mede o risco (F-167 §2).

## Revisitar se

- O fake pedir mais de uma volta jogando, ou o duelo da fase 2 mostrar a volta na mesma parede como fuga sem resposta.
- Um mapa novo tiver uma parede alta e comprida onde a volta única (+3,4 m) alcance um lugar que só o gancho devia alcançar.
