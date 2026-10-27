---
id: DEC-0050
titulo: As escolhas do desenho do duelo — a partida em rounds curtos com tempo e vida fixa, cair fora é a morte do round, o som entra na fase 2 com um pacote CC0, a matriz de posição com a regra das mãos, a esquiva é o dash, e a cápsula até as regras estarem jogáveis, com o manequim do UAL2 e os clipes de identidade no Blender antes dos amigos
data: 2026-10-27
status: aceita
decidido_por: Arthur (F-172 §2; F-174 §2)
fontes: [F-001, F-012, F-052, F-056, F-062, F-063, F-083, F-172, F-173, F-174]
substitui:
substituida_por:
---

# DEC-0050 — As escolhas do desenho do duelo

## Contexto

A fase 2 abriu em 27/10/2026 com o desenho do duelo, a primeira rodada da fase, dentro da TASK-12 (DEC-0036; F-172 §1). Num desenho, o Claude fecha os números v0 pela melhor experiência e o Arthur os julga jogando (DEC-0017); o que muda a identidade do jogo passa por ele, com a recomendação em primeiro lugar (DEC-0010; DEC-0015). Seis pontos do duelo eram identidade, e foram perguntados em duas rodadas: três antes da pesquisa da tribo (F-172 §2) e três depois dela (F-174 §1).

O chão de cada recomendação:

- **A partida.** O estudo pedia um 1v1 "pensado" (F-001) e deixava a vida e o formato sem número (F-083 §5; Q-29). Na tribo, o duelo é melhor de 5 com tempo por round, e o tempo esgotado decide pela vida em todos os jogos medidos (F-173 §2).
- **Cair fora.** A tampa da arena fechou a saída por cima (DEC-0049) e adiou para cá o plano de morte e o que a queda vale num duelo (Q-48). O ring-out é a regra do For Honor e do Smash (F-173 §2).
- **O som.** Os tokens de leitura são cor, pose e som (DEC-0031 §1), e o som nunca entrou porque só entra áudio com licença livre (DEC-0029; Q-32). Na sonda, o Arthur leu as trocas com dois canais e sentiu a falta do terceiro (F-063 §3).
- **A matriz de posição.** O estudo dava a cada lugar da acrobacia uma força e uma fraqueza (F-012 §1; Q-14), e a regra das mãos era proposta do Claude na Q-14.
- **A esquiva.** O estudo tinha uma esquiva à parte, com 60 ms de preparação e 250 invulnerável, numa tecla própria (F-001); o dash de 4 m em 200 ms existe desde a TASK-10.4 (`movimento.md`, "Dash"). Na sonda, escolher entre parry, guarda e esquiva em 350 ms falhou em 20 de 22 (F-063 §3): cada tecla a menos pesa.
- **O boneco.** A leitura da troca precisa da pose, o canal que a cápsula menos dá (F-063 §3). A DEC-0030 fechou o pipeline do manequim CC0 do UAL2 (F-056) e deixou a ferramenta dos clipes de identidade, o Cascadeur Indie ou o Blender, para quando o primeiro clipe fosse necessário (DEC-0030 §5; F-052 §4 e §5); nada se paga antes da fase 3 (DEC-0034).

## Opções consideradas

Por ponto, a escolhida em primeiro, como foi mostrada ao Arthur (F-172 §2; F-174 §1):

1. **O formato da partida (Q-29):** rounds curtos, melhor de 5, com tempo por round e vida fixa; morrer encerra o round, e no tempo esgotado vence quem tem mais vida. Ou um round só com mais vida, menos tenso. Ou a vida que não zera entre rounds, que puxa para o atrito, longe da tribo For Honor (DEC-0014).
2. **Cair fora (Q-48):** no duelo, a morte do round; no percurso cronometrado, voltar ao último checkpoint com o relógio correndo. Ou voltar ao início sem perder, que anula o preço (pilar 2, `visao.md`). Ou perder vida e voltar, uma regra nova para explicar.
3. **O som:** entra na fase 2, com um pacote CC0 pequeno (whoosh, swish, clang, thud, pisão) e a linha no `CREDITS.md` (DEC-0029). Ou a fase 2 sem som, com o terceiro canal na fase 3.
4. **A matriz de posição (Q-14):** parede e gancho sem ataque nem defesa, porque as mãos estão ocupadas; no ar, só o leve, que desce em 45°; a regra das mãos; um golpe derruba da parede e solta o gancho. Ou o leve sai da parede também. Ou tudo vale em todo lugar, sem matriz.
5. **A esquiva:** o dash é a esquiva, invulnerável dos ticks 3 a 10 dos seus 12, numa tecla só. Ou duas teclas: o dash do movimento e a esquiva do estudo.
6. **O boneco na fase 2:** a cápsula até as regras do duelo estarem jogáveis e julgadas, depois o manequim do UAL2 com os clipes de identidade feitos à mão no Blender, antes de os amigos jogarem. Ou o manequim primeiro. Ou a cápsula na fase 2 inteira.

## Decisão

Aceita pelo Arthur nas duas rodadas: "Sim e aceito as recomendacoes dos 3 pontos que voce me passou" (F-172 §2) e "Eu sigo suas recomendações. Sigo suas recomendações, os três pontos que você me passou" (F-174 §2). As seis recomendações valem:

1. **A partida é em rounds curtos:** vida fixa por round, tempo por round, vence quem ganha 3; morrer encerra o round, e no tempo esgotado vence quem tem mais vida. Os números (vida 100, 90 s por round, o desempate, a transição) são v0 do Claude em `partida.md`, "O duelo" (DEC-0017).
2. **Cair fora é a morte do round** no duelo, e o ponto vai para o outro; no percurso cronometrado, é a volta ao último checkpoint com o relógio correndo. O plano de morte é regra do núcleo, numa altura abaixo do chão mais baixo (`partida.md`, "O plano de morte"); a altura é v0.
3. **O som entra na fase 2,** com um pacote CC0 pequeno e um som por token, pela política de assets (DEC-0029); o pacote em si passa pelo Arthur antes de entrar (`visual-e-audio.md`, "O som entra na fase 2").
4. **A matriz de posição:** no chão, tudo; no dash, nada, com a invulnerabilidade; no ar, só o leve, que desce em 45°, e nenhuma defesa; na corrida na parede e na puxada do gancho, nenhum ataque nem defesa, e um golpe derruba da parede e solta o gancho. A regra das mãos vale: uma manobra que ocupa uma mão só deixa usar arma de uma mão. A quebra não agarra quem está no ar (`combate.md`, "A matriz de posição").
5. **A esquiva é o dash:** uma tecla só. O dash ganha a invulnerabilidade dos ticks 3 a 10 dos seus 12 e mantém os 4 m, os 200 ms, os 15 de stamina, a recarga de 400 ms e o "só no chão"; a esquiva à parte do estudo não existe (`combate.md`, "A esquiva e o dash"; `movimento.md`, "Dash").
6. **A cápsula até as regras estarem jogáveis,** depois o manequim do UAL2 pelo pipeline da DEC-0030, e os clipes de identidade feitos à mão no Blender, grátis, antes de os amigos jogarem. O Blender fecha a escolha que a DEC-0030 §5 deixou aberta.

## Consequências

- O `combate.md`, o `partida.md`, o `movimento.md`, o `visual-e-audio.md`, o `roteiro.md` e o glossário perdem os "a confirmar"; a Q-14, a Q-29, a Q-32 e a Q-48 fecham em `pendencias.md`.
- As filhas da TASK-12 nascem com a forma destas escolhas: a quebra e a esquiva como dash (TASK-12.4), a matriz (TASK-12.5), o som (TASK-12.6), a partida e o plano de morte (TASK-12.7), o manequim (TASK-12.9) e os clipes no Blender (TASK-12.10), antes do teste com os amigos (TASK-12.13).
- Esta DEC completa a DEC-0030 (a ferramenta dos clipes e quando o manequim entra) e a DEC-0049 (o plano de morte, que ela adiou para a fase 2). Nenhuma das duas muda de texto.
- "No ar ninguém se defende" deixa de ser uma regra à parte: é o que sobra quando a única esquiva fica no chão.
- O preço de cada escolha fica registrado: a esquiva no dash tira uma carta de quem está no ar; a matriz expõe quem corre na parede por até 2,5 s; o som é um asset novo e passa pela DEC-0029; o manequim depois das regras significa que o Arthur julga o leve e o parry ainda na cápsula.
- A conferência da DEC-0043 desta rodada ficou na F-174: o motivo da vantagem acertou, e a diferença entre a vez de agir e o castigo garantido foi explicada.

## Revisitar se

- Jogando contra o bot, a fuga comer o round apesar do tempo esgotado pela vida (Q-50), ou a arena de 80 × 80 m se mostrar grande demais para o 1v1 (Q-51).
- Um mapa com vão fizer o ring-out virar o jeito comum de vencer: jogadores do For Honor acham a morte pelo cenário frustrante no duelo (F-173 §2).
- O dash com invulnerabilidade virar a defesa única, e o parry e o bloqueio sumirem das trocas: a esquiva à parte do estudo volta como opção.
- A leitura na parede pedir o leve, depois de os amigos jogarem.
- O manequim atrasar o teste da fase: os amigos jogam com a cápsula, e o manequim passa para depois do portão.
