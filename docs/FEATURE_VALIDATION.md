# Validação das features

Base: main `f9259e0`. Ambiente: Windows, Godot 4.7.2, Chrome. Capturas geradas pelo jogo e pelo export web.

## Automação

`godot --headless --path . -- --smoke-test` passou sem erros:

- Suíte original: mundo, orientação, sobrevivência, recuperação, morte, onda solar, coleta e pouso.
- Coletar tudo não cria nave sem transmissão.
- Dois dedos independentes para joystick/corrida e limpeza da entrada.
- Limites da sala, bloqueio de móveis, estações e posição externa preservada.
- Conexão errada não avança; três corretas restauram energia.
- Sinal bloqueado sem energia/seis peças; três segundos de estabilidade, perda de estabilidade e pausa.
- Bateria esgotável; objetos coletados não reaparecem ao sair.
- Arquivo de vídeo incluído.

Importação e exportação Web concluídas sem erros. `tests/web_smoke.cjs` abre o export local, inicia/pula o vídeo, entra na base, percorre o interior com teclado e exercita o joystick com toque emulado. Registra erros de console/página e capturas para inspeção. Como a interface é canvas, os testes usam coordenadas; confira as capturas junto ao console.

## Evidências e limites

Capturas `web-desktop-*.png` e `web-mobile-*.png` documentam menu, vídeo, exploração, base, painel e movimento. `intro-storyboard.png` mostra um quadro da cutscene.

Sem testes em celular físico ou Safari/iOS. O site foi servido localmente, sem publicação pública. Desempenho e recortes reais precisam de validação após hospedagem. Comunicação e resgate têm cobertura de estado no Godot; a inspeção web cobre abertura, vídeo, entrada e circulação na base.
