# Créditos de assets

Todo asset de terceiros entra nesta tabela no mesmo commit em que entra no projeto, com a licença conferida na fonte. Asset sem linha aqui não entra: o portão confere (DEC-0029 §4). A política inteira está em `docs/design/visual-e-audio.md` e na DEC-0029.

**O que entra:** só licença que deixa redistribuir e modificar: CC0 primeiro; CC BY com o crédito; OFL para fontes; MIT, Apache e ISC para ícones e código; CC BY-SA só com o ok do Arthur. Fica fora, pago ou grátis: NC, ND, Editorial, só-Unreal, uso pessoal, RemArc, EULA e "não redistribua", e qualquer coisa com "GunZ" ou "MAIET".

**Onde mora:** `assets/third_party/<fonte>/<pack>/`, em snake_case, com o arquivo de licença dentro da pasta do pack, com o nome com que veio (`LICENSE.txt`, `License.txt`, `OFL.txt`, `COPYING`). A linha cita o caminho `assets/third_party/<fonte>/<pack>`, sem barra final.

**A linha, por tipo:** toda linha tem as colunas abaixo. CC0 não pede nada a mais. CC BY leva, na coluna "Crédito", o texto exato que vai na tela de créditos do jogo, e marca "modificado" quando for o caso. OFL leva o nome da fonte e o `OFL.txt` ao lado do `.ttf`. Apache leva o `NOTICE`, se houver.

| Pack e caminho | Autor | Licença, versão e link | Origem (URL) | Baixado em | Modificado | Onde é usado | Arquivo de licença | Crédito |
|---|---|---|---|---|---|---|---|---|
