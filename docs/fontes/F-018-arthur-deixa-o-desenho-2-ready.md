---
id: F-018
titulo: O Arthur deixa o Desenho 2 Ready, com o escopo do estado e a configuração imutável, e fixa o runner do CI (sessão 3, 02/10/2026)
recebido_em: 2026-10-02
como: Respostas escolhidas nas opções de uma pergunta do Claude Code na sessão 3. Texto das perguntas e dos rótulos como foram mostrados.
status: vigente
substituida_por:
---

> Contexto, escrito pelo agente: refinamento da TASK-4 (Desenho 2), logo depois de a TASK-2 fechar com o CI verde. Antes de perguntar, o Claude mostrou dois achados: a `RewindableStateMachine` do netfox põe lógica em nós, contra a regra 1 da DEC-0004; e o Godot 4.7.2 não regula o nível de aviso por pasta. Cada pergunta trazia uma recomendação.

## §1 — Escopo do estado e configuração

Pergunta: "Até onde o Desenho 2 detalha o estado da simulação?"

Resposta: "Esqueleto em detalhe (Recomendado)"

A opção dizia: "O estado do esqueleto andante campo a campo (corpo, chão, pulo, perdão, câmera). A fase 1 (pulo duplo, parede, dash, gancho, stamina) fica esboçada, para provar que a forma aguenta. O combate só ganha nome, porque os números dele são hipótese até a fase 2."

Pergunta: "A escolha que a task pede para confirmar: os números de design ficam em Resources (.tres), em ms e metros, e viram na carga um objeto imutável, em ticks, que o núcleo só lê?"

Resposta: "Imutável em ticks (Recomendado)"

## §2 — O runner do CI (Q-15)

Pergunta: "Q-15: o CI roda em ubuntu-latest, que vira o Ubuntu 26 a partir de 19/10. Fixo em ubuntu-24.04?"

Resposta: "Fixar ubuntu-24.04 (Recomendado)"
