# Astro · Um Pequeno Recomeço

Uma miniaventura cozy 3D no Godot 4.7. Explore um pequeno planeta vermelho, reúna materiais e receba a nave de resgate. Substitui completamente o antigo protótipo web.

## Jogar

No Windows, abra **Jogar.cmd**. O iniciador usa o Godot instalado na pasta Downloads deste computador, no PATH ou na variável `GODOT_EXE`. Para editar, importe `project.godot` no Godot 4.7 e pressione F5. Não há dependências de rede ou plugins.

- WASD ou setas: caminhar por toda a superfície esférica.
- Espaço: saltitar. Shift: caminhar mais rápido.
- E: recolher um item próximo ou embarcar na nave.
- E na estufa: consumir uma refeição e reabastecer alimentos.
- Esc: pausar. Botão ♪: silenciar música e efeitos.

## Um passeio completo

Reúna 6 pedras de regolito, 6 peças para a antena e 6 galões de combustível para abastecer o resgate. Os itens estão espalhados por toda a esfera, inclusive no outro hemisfério. Não há setas, dicas de interação ou mensagens centrais durante a exploração: os três contadores e o som confirmam a descoberta. Ao completar tudo, a nave desce perto do jogador. Aproxime-se e pressione E para embarcar. Os controles estão na introdução e no menu de pausa.

Oxigênio e alimento exigem viagens de reabastecimento: a base repõe O₂ automaticamente; uma segunda base, a estufa, fica a aproximadamente 20 metros de arco da original e oferece refeições com E. A estufa não protege da radiação. A derrota encerra a expedição e exige recomeçar do zero.

O oxigênio dura aproximadamente **29 segundos** fora da base; alimentos duram cerca de **56 segundos**. Barras mostram as duas reservas, mudam de cor e pulsam quando estão baixas. As bordas da tela escurecem progressivamente. Depois de zerar uma reserva, há **dois segundos** para chegar à base ou comer antes da derrota. Cada reserva tem seu próprio prazo; recuperar uma não salva o personagem se a outra continua esgotada. Pausar congela os prazos. A base repõe O₂ em quatro segundos.

Após 45 segundos de exploração, uma sirene anuncia **10 segundos de aviso** antes de uma onda solar que percorre o planeta por **10 segundos**, com som de propagação. Uma luz distante aumenta e pulsa antes da onda; o ponto luminoso e a propagação usam a mesma direção no mundo. Não há texto de alerta ou contagem regressiva na tela. A frente exclui geometricamente o abrigo. Apenas tocar a faixa causa dano: −35 de O₂ e −12 de alimento, uma vez por onda. O restante da superfície é seguro antes e depois da passagem. O teste de contato considera o deslocamento entre quadros.

Três cartões grandes mostram os objetivos 0/6. A orientação do astronauta respeita a frente +Z do modelo Kenney e o movimento usa os eixos da câmera projetados na esfera.

É uma experiência didática, não uma simulação física de Marte ou engenharia real. O progresso não persiste após fechar o jogo.

## Arte e áudio

Modelos **Kenney Space Kit 2.0 (CC0)** reutilizados do Last Light conforme solicitado. Licença em `assets/space/License.txt`, origem em https://kenney.nl/assets/space-kit e proveniência em `docs/ASSETS.md`. O planeta, acampamento, nave, iluminação e interface são montados no projeto. Trilha ambiente espacial original: acordes longos com timbre de órgão, drone grave e camadas aéreas. Sons de coleta, sirene e propagação também são sintetizados localmente, sem gravações ou músicas de terceiros. Veja `docs/AUDIO.md`.

## Verificação

`godot --headless --path . --editor --import --quit`

`godot --headless --path . -- --smoke-test`

O teste verifica distribuição dos itens, alinhamento à esfera, coleta, chegada do resgate, pouso e conclusão. `godot --path . -- --capture` salva uma captura em `docs/preview.png`. Não depende de cliques automatizados.
