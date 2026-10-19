# Astro: Missão Recomeço

Jogo de plataforma 2D para navegador, em português. Explore uma colônia lunar, recupere equipamentos e pratique decisões sobre energia, alimento, oxigênio e radiação. Arte original desenhada em Canvas, sem dependências ou recursos externos.

## Jogar

Abra `index.html` em um navegador moderno. Opcionalmente, execute `npm start` e acesse http://127.0.0.1:4174.

A/D ou setas movem; espaço, W ou seta para cima saltam; E interage; Esc pausa. Há controles de toque em dispositivos móveis. Pule sobre drones para desativá-los. Cápsulas verdes repõem oxigênio; abrigos reduzem radiação. Volte ao início do mapa com o equipamento e entre na base para planejar a noite.

## Treinamento

Três capítulos: armazenamento para a noite, proteção de radiação e cultivo de alimentos. Na base, instale melhorias, escolha se a estufa fica ligada e confira a previsão antes de testar o plano. Falhas explicam a causa e permitem ajustes sem perder recursos. A oficina tem seis lotes de peças por capítulo, evitando bloqueio por falta de recursos. Resgate automático preserva itens recuperados. A campanha não persiste após recarregar a página.

Os números são simplificações didáticas, não parâmetros de engenharia reais. A mecânica de radiação representa exposição e proteção qualitativamente. O jogo não coleta dados.

`npm run check` verifica sintaxe e executa testes de física, colisões, consumo, abrigo e progressão.
