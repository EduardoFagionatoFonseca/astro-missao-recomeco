# Validação das features

Base: main `f9259e0`. Ambiente: Windows, Godot 4.7.2, Chrome. Capturas geradas pelo jogo e pelo export web.

## Automação

`godot --headless --path . -- --smoke-test` passou sem erros:

- Suíte original: mundo, orientação, sobrevivência, recuperação, morte, névoa solar, coleta e pouso.
- Coletar tudo não cria nave sem transmissão.
- Dois dedos independentes para joystick/ação e limpeza da entrada.
- Limites da sala, bloqueio de móveis, estações e posição externa preservada.
- Conexão errada não avança; três corretas restauram energia.
- Sinal bloqueado sem energia/seis peças; três segundos de estabilidade, perda de estabilidade e pausa.
- Bateria esgotável; objetos coletados não reaparecem ao sair.
- Arquivo de vídeo incluído.

## Ajustes de sobrevivência e manutenção

`tests/mission_balance.gd`, executado pelo smoke test, verifica proteção somente dentro do abrigo, tutorial solar sem repetição, pane elétrica após 63,75 s, desconexão após 85 s, nova sintonia, mensagens únicas, velocidade de 3,78 m/s e alarmes separados.

`tests/axios_ui.gd` cobre produção de O₂ dependente de energia, reparo preventivo em 30%, previsão solar e aviso de bateria somente com rádio, descarte dos avisos sem conexão, janela iluminada, reservas de 105 unidades e guia pós-vídeo com todos os temporizadores suspensos. Confere também a área do guia (~70%) e as três miniaturas.

O export Web foi conferido no Chrome e no Pixel 7 emulado: menu mínimo, vídeo, guia, exploração, interior e painel elétrico com o tema compartilhado. Os testes usam teclado/toque e capturas; as regras temporais são cobertas pelo smoke test do Godot.

Capturas adicionais: `briefing-preview.png`, `window-preview.png` e `web-*-briefing.png` mostram o guia e a janela em radiação. Capturas de iterações anteriores permanecem como histórico e podem refletir temas antigos.

Importação e exportação Web concluídas sem erros. `tests/web_smoke.cjs` abre o export local, inicia/pula o vídeo, entra na base, percorre o interior com teclado e exercita o joystick com toque emulado. Registra erros de console/página e capturas para inspeção. Como a interface é canvas, os testes usam coordenadas; confira as capturas junto ao console.

## Evidências e limites

Menu e descoberta: `tests/radio_resources.gd` verifica 6 peças de antena antes da transmissão, 5 pedras/8 combustíveis depois dela, bloqueio de coleta sem sinal, itens ocultos após transição interior/exterior e preservação do inventário. Também cobre volumes independentes, zero silencioso, suspensão da simulação nas configurações e troca entre os dois MP3 em loop. O teste web abre a engrenagem, ajusta música e percorre o início em desktop/toque. No desktop, recarrega a página e confere visualmente o ganho preservado em `web-desktop-settings-restored.png`. `menu-preview.png` e `settings-preview.png` mostram a nova interface; a origem e o prompt da arte estão em `MENU_ART.md`.

A atualização de decolagem cobre névoa planetária de 12 s, morte após 3 s de exposição contínua, proteção e reinício da exposição dentro do abrigo, pulso de energia baixa, sons distintos de coleta/derrota e escrita progressiva. A automação percorre as duas páginas do guia com a simulação congelada e verifica vídeo final antes da tela de vitória. Capturas `solar-preview.png`, `briefing2-preview.png`, `outro-preview.png` e `outro-storyboard.png` registram os novos visuais. O teste web percorre ambos os slides em desktop e toque emulado.

Capturas `web-desktop-*.png` e `web-mobile-*.png` documentam menu, vídeo, exploração, base, painel e movimento. `intro-storyboard.png` mostra um quadro da cutscene.

Sem testes em celular físico ou Safari/iOS. O site foi servido localmente, sem publicação pública. Desempenho e recortes reais precisam de validação após hospedagem. Comunicação e resgate têm cobertura de estado no Godot; a inspeção web cobre abertura, vídeo, entrada e circulação na base.
