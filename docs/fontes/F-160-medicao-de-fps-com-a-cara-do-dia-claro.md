---
id: F-160
titulo: A medição de fps com a cara do dia claro — 153,04 fps de média e 116,84 nos 1% piores, em 1080p no PC do Arthur, com os dois lutadores na vista o tempo todo (sessão 18, 26/10/2026)
recebido_em: 2026-10-26
como: O Claude rodou `bash tools/measure_fps.sh` no PC do Arthur, com o ok dele e o PC quieto, no commit `eba697c` da branch `task-10.12-visual-da-arena` (TASK-10.12, critério 3). O resumo do script e o JSON estão como chegaram; os logs ficaram na pasta temporária que o script imprimiu.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: o script exporta o cliente Windows, sobe um servidor e um cliente parado sem tela e abre a build em tela cheia com o bot jogando, a ping 0; ela mede 60 s quadro a quadro depois de 2 s de aquecimento. Antes de rodar, nenhum processo do Godot estava aberto e a CPU estava a 6 %. A cara nova põe o céu procedural, a luz do céu, o Filmic, a neblina e os ajustes de cor no ambiente, com o sol fazendo sombra.

## §1 — O resultado

```
	"frames": 9183,
	"measured_s": 60.002,
	"average_fps": 153.04,
	"average_frame_ms": 6.534,
	"p99_frame_ms": 8.558,
	"one_percent_low_fps": 116.84,
	"worst_frame_ms": 11.076,
	"two_fighters_in_view_pct": 100.0,
	"window_size": "1920x1080",
	"screen_size": "1920x1080",
	"screen_refresh_hz": 59.94,
	"vsync": "disabled",
	"gpu": "Radeon RX550/550 Series",
	"godot": "4.7.2-stable (official)",

153.04 fps on average, 1% low 116.84 fps (99th percentile 8.558 ms), worst frame 11.076 ms
measure fps took 95 s
PASS: 153.04 fps on average, at or above the 60 fps of DEC-0002
```

## §2 — O que o agente lê (não é decisão)

- O critério 3 da TASK-10.12 passa: 153 fps de média, 2,5 vezes o piso da DEC-0002, e o pior quadro em 11 ms.
- A medição anterior, da TASK-9 em 18/10, deu 312,71 fps de média e 157,62 nos 1% piores (F-095). Entre as duas entraram o HUD, as peças da arena, os sinais das manobras, o gancho, a borda, o boneco e a cara nova; a queda não foi atribuída a nenhuma delas, porque não houve medição no meio.
