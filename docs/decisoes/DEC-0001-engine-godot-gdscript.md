---
id: DEC-0001
titulo: Engine e linguagem — Godot 4.7.2 com GDScript
data: 2026-10-02
status: aceita
decidido_por: Arthur
fontes: [F-001, F-002, F-003, F-004]
substitui:
substituida_por:
---

# DEC-0001 — Engine e linguagem: Godot 4.7.2 com GDScript

## Contexto

O estudo deixou o Godot como padrão e combinou decidir pelas peças do PC Windows: com 32 GB e placa dedicada, o s&box e o Unreal entrariam na conta; com menos, ficaria o Godot (F-001, "Próxima sessão"). O PC tem 16 GB de RAM e uma Radeon RX 550 de 4 GB (F-004).

## Opções consideradas

1. **Godot 4.7.2 com GDScript**, a escolhida. É MIT e texto puro, bom para o Claude Code, e o GDScript lembra Python (F-001).
2. **s&box**: fica abaixo do mínimo até para jogar, que pede Ryzen 5 3600 e GTX 1060 ou RX 580 de 6 GB (F-002).
3. **Unreal 5.8**: a Epic recomenda 32 GB e 8 GB de VRAM (F-002).
4. **Unity 6.3**: era o plano B do estudo (F-001).

## Decisão

Godot 4.7.2 com GDScript. O Arthur decidiu em 02/10/2026: "eu fecho com Godot" (F-003 §2).

## Consequências

- O Godot 4.7.2 foi instalado pelo winget e tem o comando `godot` no PATH (README).
- Não existe plugin oficial de Easy Anti-Cheat para o Godot; o anti-cheat começa pela validação no servidor (F-001).

## Revisitar se

- O netfox não funcionar no 4.7 e não houver contorno (DEC-0003).
- Uma troca de peças reabrir a conta do s&box ou do Unreal.
