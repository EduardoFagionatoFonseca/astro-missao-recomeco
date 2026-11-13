# Guia de edição no Godot

Abra `project.godot` no Godot 4.7. A cena inicial é `scenes/main.tscn`. A estrutura separa a missão por responsabilidade e permite abrir cada componente sem depender de um único script.

## Cenas principais

- `scenes/main.tscn`: junta os sistemas e os atores.
- `scenes/ui/hud.tscn`: interface da partida e cenas de menu, briefing, controles, feedback, minigames e vídeos.
- `scenes/components/base_interior.tscn`: interior da base.
- `scenes/components/event_audio.tscn` e `scenes/components/audio_manager.tscn`: efeitos e músicas.
- `scenes/components/survival_system.tscn`, `scenes/components/mission_progression.tscn` e `scenes/components/exploration_system.tscn`: sobrevivência, energia, comunicações, movimento e coleta.
- `scenes/components/mission_readiness_quiz.tscn`, `inventory_panel.tscn` e `mission_map.tscn`: avaliação antes da missão, inventário consumível e minimapa.

Abra uma subcena pelo painel **Sistema de arquivos** para trabalhar nela isoladamente. Na cena principal, use a árvore para selecionar `World`, `Actors`, `BaseInterior` ou `HUD`.

## Pastas de código

- `scripts/core/`: coordenação da missão e opções salvas.
- `scripts/world/`: terreno, base e montagem do mundo.
- `scripts/gameplay/`: sobrevivência, progressão, controles e minigames.
- `scripts/ui/`: menu, briefing, HUD, guia, mensagens, tema e configurações.
- `data/mission_readiness.json`: perguntas, respostas, devolutivas e nota mínima de prontidão.
- `scripts/audio/`: música, efeitos e sons da missão.
- `shaders/`: efeitos visuais de radiação e exposição.
- `assets/`: modelos, imagens, áudio e vídeos.
- `tests/`: verificações automatizadas já existentes.

## Ajustes comuns pelo Inspetor

Selecione o nó `World` em `scenes/main.tscn`. O Inspetor permite ajustar a semente aleatória, quantidade de estrelas, rochas, crateras e marcadores, além das direções do acampamento, estufa e sol. As direções são vetores; o projeto as normaliza ao montar o mundo.

Selecione `Astro` em `scenes/main.tscn` para ajustar no Inspetor raio do planeta (32 por padrão), reservas, consumo de O₂/comida, duração dos ciclos, velocidade, limites de sobrevivência e paleta. A câmera se aproxima automaticamente ao alterar o raio. Se alterar `GOALS`, mantenha `TOTAL` igual à soma dos três valores. Os cálculos de sobrevivência ficam em `scripts/gameplay/survival_controller.gd`; energia e comunicação em `mission_progression.gd`; movimento, coleta e resgate em `exploration_controller.gd`.

## Interface e arte

Os componentes de interface têm cenas próprias em `scenes/components/` e estão reunidos em `scenes/ui/hud.tscn`. O botão **Treinar Tripulação** abre cinco cutscenes ilustradas, uma antes de cada pergunta. Edite tema, cenas e legendas em `data/mission_readiness.json`; a arte animada é desenhada em `scripts/ui/mission_quiz_cutscene.gd`. Somente a pontuação mínima libera o vídeo de abertura e o início da missão. O inventário abre com `I`, tem 36 espaços, pilhas de até 64 itens e uma barra rápida de nove posições; arraste itens para reorganizar, selecione com `1`–`9` e use o espaço ativo com `F` ou clique direito. A tecla `V` alterna entre visão de exploração e primeira pessoa; `M` amplia/reduz o minimapa. Selecione `HUDBuilder` dentro de `scenes/ui/hud.tscn` para ajustar margens e posições no Inspetor.

O mundo 3D é gerado na inicialização para distribuir os objetos pela superfície esférica. A montagem está em `scripts/world/world_builder.gd`; a forma do terreno está em `scripts/world/planet_terrain.gd`. As quantidades, a semente, o acampamento, a estufa e a direção do sol são propriedades do nó `World` no Inspetor.

Modelos e imagens ficam em `assets/space/` e `assets/ui/`. As trilhas e vídeos ficam em `assets/audio/` e `assets/cinematics/`. Para trocar uma imagem ou vídeo por outro arquivo, atualize também a referência no script que o usa.

## Como fazer uma alteração

1. Abra a cena do componente que quer alterar.
2. Ajuste propriedades disponíveis no Inspetor ou abra o script vinculado ao nó.
3. Para posicionamento e distribuição do mundo, selecione `World` na cena principal. Para ajustar os obstáculos ou os pontos de interação dentro da base, edite os campos do nó `BaseInterior`.
4. Salve a cena ou o script; o Godot atualiza as referências de recursos automaticamente.

A cena organiza os sistemas e os torna localizáveis. Alguns detalhes visuais, especialmente o planeta e os controles do HUD, são gerados por código; seus pontos de edição estão indicados acima.


