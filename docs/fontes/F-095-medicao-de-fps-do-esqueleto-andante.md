---
id: F-095
titulo: A medição de fps do esqueleto andante — 312,71 fps de média e 157,62 nos 1% piores, em 1080p no PC do Arthur, com os dois lutadores na vista o tempo todo (sessão 13, 18/10/2026)
recebido_em: 2026-10-18
como: O Arthur rodou `bash tools/measure_fps.sh` no terminal da sessão 13, no commit `43ffd0b` da branch `task-9-delivery-pipeline` (TASK-9, critério 17). A saída do script e o JSON estão como chegaram; os logs ficaram na pasta temporária que o script imprime.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: o script exporta o cliente Windows aqui, sem carimbo de commit. Depois sobe um servidor sem tela e um cliente parado sem tela, os dois do código-fonte, e abre a build em tela cheia, com o bot jogando o lutador dela, a ping 0. A build entra em tela cheia com o vsync desligado e o fps sem limite, como a sonda dos assets (F-056 §5). Quando o lutador dela joga, ela espera 2 s e mede 60 s quadro a quadro. Os "1% piores" são o fps do 99º percentil do tempo de quadro.
>
> O servidor e o outro cliente rodaram no mesmo PC, limitados a 144 fps, e por isso a medida é pessimista. O Claude tinha pedido para fechar o League of Legends e o cliente da Riot antes, e não se sabe se estavam fechados. Os logs não têm `ERROR`, `WARNING` nem `SCRIPT ERROR`, e nenhum processo do Godot ficou aberto.

## §1 — A saída

```
client: Godot exited with 0 after 19 s
client: build/windows/jogo-acrobatico.exe is whole, 109461944 bytes
exit codes: the window 0, the server 0, the other client 0
```

```json
{
	"frames": 18764,
	"measured_s": 60.003,
	"average_fps": 312.71,
	"average_frame_ms": 3.198,
	"p99_frame_ms": 6.344,
	"one_percent_low_fps": 157.62,
	"worst_frame_ms": 11.179,
	"two_fighters_in_view_pct": 100.0,
	"window_size": "1920x1080",
	"screen_size": "1920x1080",
	"screen_refresh_hz": 59.94,
	"vsync": "disabled",
	"gpu": "Radeon RX550/550 Series",
	"gpu_api": "3.3.0 Core Profile Context 26.5.2.260413",
	"godot": "4.7.2-stable (official)",
	"version": "0.0.0",
	"commit": ""
}
```

```
312.71 fps on average, 1% low 157.62 fps (99th percentile 6.344 ms), worst frame 11.179 ms
window 1920x1080 on a 1920x1080 screen at 59.94 Hz, vsync disabled, Radeon RX550/550 Series; both fighters in view in 100.0% of the frames
measure fps took 105 s
PASS: 312.71 fps on average, at or above the 60 fps of DEC-0002
```

## §2 — Leitura do agente

- **O piso da DEC-0002 passa com folga:** a média dá 5,2 vezes os 60 fps, e os 1% piores, 2,6 vezes. O pior quadro, 11,2 ms, ainda cabe nos 16,7 ms de um quadro a 60.
- **A média bate com a da sonda dos assets,** que mediu 311 fps com dois lutadores (F-056 §5). Os 1% piores ficam abaixo dos 264 de lá: aquela sonda não tinha rede, física nem os ticks do netfox, e o servidor e o outro cliente não dividiam o PC (F-056 §6).
- **Esta é a medida do esqueleto andante:** uma cápsula sem animação, numa arena de blocos. O boneco com clipes, as armas e os efeitos vão gastar desta folga. A medição volta a valer a cada fase.
