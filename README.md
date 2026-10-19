# Astro · Um Pequeno Recomeço

Uma miniaventura cozy 3D no Godot 4.7. Explore um pequeno planeta vermelho, reúna materiais e receba a nave de resgate. Substitui completamente o antigo protótipo web.

## Jogar

No Windows, abra **Jogar.cmd**. O iniciador usa o Godot instalado na pasta Downloads deste computador, no PATH ou na variável `GODOT_EXE`. Para editar, importe `project.godot` no Godot 4.7 e pressione F5. Não há dependências de rede ou plugins.

- WASD ou setas: caminhar por toda a superfície esférica.
- Espaço: saltitar. Shift: caminhar mais rápido.
- E: recolher um item próximo ou embarcar na nave.
- Esc: pausar. Botão ♪: silenciar música e efeitos.

## Um passeio completo

Reúna 6 pedras de regolito, 6 peças para a antena e 6 cápsulas de suprimentos. Os itens estão espalhados por toda a esfera, inclusive no outro hemisfério. A bússola mostra a direção e a distância pela superfície até a próxima descoberta. Ao completar a coleta, a nave desce perto do jogador. Aproxime-se e pressione E para embarcar. Você pode reiniciar pela tela final.

Sem combate, limite de tempo ou recursos que se esgotam. O tema educacional aparece no propósito dos materiais: proteção do abrigo, comunicação e reservas durante a espera. É uma experiência de exploração, não uma simulação física de Marte ou engenharia de missão. O progresso não persiste após fechar o jogo.

## Arte e áudio

Modelos **Kenney Space Kit 2.0 (CC0)** reutilizados do Last Light conforme solicitado. Licença em `assets/space/License.txt`, origem em https://kenney.nl/assets/space-kit e proveniência em `docs/ASSETS.md`. O planeta, acampamento, nave, iluminação e interface são montados no projeto. Música e sons de coleta são sintetizados localmente.

## Verificação

`godot --headless --path . --editor --import --quit`

`godot --headless --path . -- --smoke-test`

O teste verifica distribuição dos itens, alinhamento à esfera, coleta, chegada do resgate, pouso e conclusão. `godot --path . -- --capture` salva uma captura em `docs/preview.png`. Não depende de cliques automatizados.
