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

Reúna 6 pedras de regolito, 6 peças para a antena e 6 galões de combustível para abastecer o resgate. Os itens estão espalhados por toda a esfera, inclusive no outro hemisfério. Não há seta de navegação ou mensagem central a cada coleta: os três contadores e o som confirmam a descoberta. Ao completar tudo, a nave desce perto do jogador. Aproxime-se e pressione E para embarcar.

Sem combate ou perda permanente de progresso. Oxigênio e alimento exigem pequenas viagens de reabastecimento: a base repõe O₂ automaticamente; uma segunda base, a estufa, fica a aproximadamente 20 metros de arco da original e oferece refeições com E. A estufa não protege da radiação.

O oxigênio dura aproximadamente **29 segundos** fora da base; alimentos duram cerca de **56 segundos**. Avisos visuais e sonoros alertam sobre reservas baixas; abaixo de 15%, o aviso pisca. A base repõe O₂ em quatro segundos. A estufa oferece refeições com E.

Após 45 segundos de exploração, uma sirene anuncia **10 segundos de aviso** antes de uma onda solar que percorre o planeta por **10 segundos**, com som de propagação. O ciclo se repete; pausa e introdução congelam os relógios e pausam o áudio. A frente nasce no hemisfério oposto à base e exclui geometricamente o abrigo. Apenas tocar a faixa causa dano: −35 de O₂ e −12 de alimento, uma vez por onda. O restante da superfície é seguro antes e depois da passagem. O teste de contato considera o deslocamento entre quadros. Se O₂ ou alimento acabam, o traje retorna à base preservando os itens.

Três cartões grandes mostram os objetivos 0/6. A orientação do astronauta respeita a frente +Z do modelo Kenney e o movimento usa os eixos da câmera projetados na esfera.

É uma experiência didática, não uma simulação física de Marte ou engenharia real. O progresso não persiste após fechar o jogo.

## Arte e áudio

Modelos **Kenney Space Kit 2.0 (CC0)** reutilizados do Last Light conforme solicitado. Licença em `assets/space/License.txt`, origem em https://kenney.nl/assets/space-kit e proveniência em `docs/ASSETS.md`. O planeta, acampamento, nave, iluminação e interface são montados no projeto. Trilha original de 32 notas, baixo suave, sons de coleta, sirene e propagação são sintetizados localmente; não há gravações ou músicas de terceiros. Veja `docs/AUDIO.md`.

## Verificação

`godot --headless --path . --editor --import --quit`

`godot --headless --path . -- --smoke-test`

O teste verifica distribuição dos itens, alinhamento à esfera, coleta, chegada do resgate, pouso e conclusão. `godot --path . -- --capture` salva uma captura em `docs/preview.png`. Não depende de cliques automatizados.
