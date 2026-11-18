---
id: F-219
titulo: O Arthur aprova o plano da TASK-12.15 no modo de plano — a câmera centrada e 0,6 m mais alta por uma opção ao abrir o jogo, o ponto O que sobe com ela e o corpo que fica (sessão 24, 18/11/2026)
recebido_em: 2026-11-18
como: Aprovação do Arthur ao plano que o Claude apresentou no modo de plano do Claude Code, na sessão 24, sem texto junto. O plano aprovado está resumido abaixo; o arquivo inteiro ficou em `C:\Users\arthu\.claude\plans\precious-percolating-steele.md`.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: o plano vem da escolha da F-218, experimentar a câmera centrada sem mudar o padrão, e do mapa do código feito por um agente explorer. A subida de 0,6 m é a opção "o jeito do GunZ" que já estava na lista da DEC-0045, com os pés a 55 px da borda de baixo. Ela entrou no plano como escolha a confirmar, e a aprovação do plano a confirmou.

## §1 — O plano, como foi aprovado (resumo)

- **A opção.** `--camera=shoulder|center`, só no Sozinho, recusada com `--server`, `--connect` ou `--watch`, porque o servidor e os clientes precisam da mesma mira. Sem a opção, nada muda.
- **A câmera centrada.** Ombro 0 e subida 0,6 m, com o pivô a 2,2 m dos pés. A distância, o campo de visão e a sensibilidade ficam os de hoje.
- **O ponto O** fica no eixo do corpo, na altura `aim_height + aim_rise`: 2,2 m na centrada. A mira da tela, o raio do gancho e o alcance de 3 a 25 m saem dele. O segundo raio do gancho e o cabo seguem saindo do ombro do corpo, a 1,6 m.
- **O golpe** sai na direção da câmera, porque `Aim.swing_yaw` com ombro 0 já dá o golpe reto.
- **Os dados.**
  - `CameraData.rise_m` e `MovementData.aim_rise_m` são novos e valem 0 no v0.
  - Entram dois arquivos, `camera_center.tres` e `movement_center.tres`. Os testes garantem que cada um é igual ao seu v0 menos os campos da mira, e que a cópia no movimento é igual à da câmera.
- **O replay.** O cabeçalho já grava os números do movimento, então o replay centrado toca igual. O `--watch` monta a câmera com o ombro e a subida do cabeçalho. Os replays de antes pedem `--force`, por causa do campo novo.
- **Os seis critérios.** Os cinco primeiros são os da câmera, do ponto O, do golpe reto, da recusa e do replay. O sexto: o Arthur joga as duas câmeras e escolhe o padrão. Se ficar a centrada, uma DEC nova substitui a DEC-0045.
- **A ordem.** A task fica pronta no main; os docs vêm primeiro na branch; depois test-writer, trava, implementer, reviewer e o portão; por fim o Arthur joga as duas câmeras.
