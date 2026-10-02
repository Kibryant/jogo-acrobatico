# core/

O núcleo puro da simulação (DEC-0004, regra 1). Aqui moram as regras do jogo: movimento, combate, stamina e tempo. Elas são escritas em GDScript sem nó, como classes `RefCounted` e funções estáticas, com estado plano (int, float, Vector3, StringName) e tudo contado em ticks.

O portão barra o que não pode entrar aqui (`tools/check_core_purity.sh`):

- nó do Godot e `get_tree`;
- `Input`, `Engine`, `Time` e `OS`;
- `load` e `preload`;
- `Timer` e `await`;
- sorteio sem semente.

O motivo é que o mesmo código roda no servidor e no cliente, volta no tempo no rollback e é testado sem abrir cena.
