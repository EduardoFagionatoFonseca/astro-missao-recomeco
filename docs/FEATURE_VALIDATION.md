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

## Ajustes de sobrevivência e manutenção

`tests/mission_balance.gd`, executado pelo smoke test, verifica proteção somente dentro do abrigo, tutorial solar sem repetição, pane elétrica após 75 s, desconexão após 100 s, mudança de frequência na nova sintonia, mensagens sem duplicação, velocidade fixa e alarmes separados. As barras passam a vermelho com pulsação suave; o céu clareia em vez de uma sirene repetitiva. A onda atravessa a base externa e termina normalmente enquanto o astronauta está no interior.

Capturas adicionais: `warning-preview.png`, `critical-preview.png` e `signal-preview.png` mostram o primeiro aviso solar, reservas críticas e o novo osciloscópio do sinalizador.

Importação e exportação Web concluídas sem erros. `tests/web_smoke.cjs` abre o export local, inicia/pula o vídeo, entra na base, percorre o interior com teclado e exercita o joystick com toque emulado. Registra erros de console/página e capturas para inspeção. Como a interface é canvas, os testes usam coordenadas; confira as capturas junto ao console.

## Evidências e limites

Capturas `web-desktop-*.png` e `web-mobile-*.png` documentam menu, vídeo, exploração, base, painel e movimento. `intro-storyboard.png` mostra um quadro da cutscene.

Sem testes em celular físico ou Safari/iOS. O site foi servido localmente, sem publicação pública. Desempenho e recortes reais precisam de validação após hospedagem. Comunicação e resgate têm cobertura de estado no Godot; a inspeção web cobre abertura, vídeo, entrada e circulação na base.
