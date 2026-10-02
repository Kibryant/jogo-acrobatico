---
id: F-002
titulo: Briefing do jogo acrobático — dependências, arquitetura e decisões (02/10/2026)
recebido_em: 2026-10-02
como: Documento do Claude Docs escrito pelo Claude na sessão do my-brain de 02/10/2026, a partir de F-004 a F-008, em https://claude.ai/artifact/7ZF23XCJcaHTWLctvdEmXg. O resumo está no Yabadoo, documento a4a44cdb-f4d6-42f9-a683-e0217f8cb9bb.
status: vigente
substituida_por:
---

> O briefing vive no Claude Docs, com o mapa, as tabelas e as fontes. Aqui fica o que o repositório precisa dele: as 16 decisões e a resposta do Arthur. O plano de estudo de seis sessões que o briefing propunha foi descartado pelo Arthur no mesmo dia (F-003 §4; DEC-0010).

## As 16 decisões, como estavam no briefing

| Decisão | Recomendação | Status no briefing |
|---|---|---|
| Engine e linguagem | Godot 4.7.2 + GDScript | Decidida em 02/10 |
| Desempenho mínimo | 60 fps em 1080p no PC do Arthur | Decidida em 02/10 |
| Renderer | Compatibility; trocar depois custa ajuste visual | A decidir |
| Tipagem | Obrigatória: declaração sem tipo vira erro, `:=` permitido | A decidir |
| Framework de testes | gdUnit4, se rodar limpo no 4.7.2 | A decidir |
| Versão do netfox | Main fixada num commit, com a suíte do netfox rodando no 4.7.2 | A decidir |
| Ticks por segundo | Medir: 30 é o padrão; 60 deixa o parry mais preciso e custa CPU e banda | A decidir |
| Arquitetura | Núcleo puro e nós finos, com DDD só estratégico | A decidir |
| Máquina de estados | RewindableStateMachine no personagem; LimboAI só nos bots | A decidir |
| Pastas | Por feature, com common/, addons/ e test/ | A decidir |
| Idioma | Código e arquivos do agente em inglês; ADR, diário e explicações em português | A decidir |
| Harness | Leve: test-writer cego no núcleo, reviewer e portão rápido | A decidir |
| Estilo de saída do Claude | Explanatory | A decidir |
| Validação de acerto | Tiro a favor de quem ataca até ~220 ms, bloqueio julgado no tempo de quem defende | Depois, fase 3 |
| Hospedagem | VPS em São Paulo com Docker; Edgegap se tiver região SP | Depois, fase 3 |
| Replay | Por inputs, re-rodados no próprio servidor | Depois, fase 4 |

## A resposta do Arthur

"eu aceito todas as decisões lá é, não tenho muito ponto para bater" (F-003 §4).
