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

`tests/mission_balance.gd`, executado pelo smoke test, verifica proteção somente dentro do abrigo, tutorial solar sem repetição, pane elétrica após 63,75 s, desconexão após 85 s, nova sintonia, mensagens únicas, velocidade de 3,8934 m/s e alarmes separados.

`tests/axios_ui.gd` cobre produção de O₂ dependente de energia, reparo preventivo em 30%, previsão solar e aviso de bateria somente com rádio, descarte dos avisos sem conexão, janela iluminada, reservas de 105 unidades e guia pós-vídeo com todos os temporizadores suspensos. Confere também a área do guia (~70%) e as três miniaturas.

O export Web foi conferido no Chrome e no Pixel 7 emulado: menu mínimo, vídeo, guia, exploração, interior e painel elétrico com o tema compartilhado. Os testes usam teclado/toque e capturas; as regras temporais são cobertas pelo smoke test do Godot.

Capturas adicionais: `briefing-preview.png`, `window-preview.png` e `web-*-briefing.png` mostram o guia e a janela em radiação. Capturas de iterações anteriores permanecem como histórico e podem refletir temas antigos.

Importação e exportação Web concluídas sem erros. `tests/web_smoke.cjs` abre o export local, inicia/pula o vídeo, entra na base, percorre o interior com teclado e exercita o joystick com toque emulado. Registra erros de console/página e capturas para inspeção. Como a interface é canvas, os testes usam coordenadas; confira as capturas junto ao console.

## Evidências e limites

Fluxo de missão: `tests/mission_flow.gd` verifica fechamento automático da antena, bloqueio da interação enquanto estável e reativação após falha. Confere que o rádio permanece silencioso antes da janela de 5 s, interrompe outra transmissão no momento correto, não repete o aviso e respeita conexão offline. Também verifica que o efeito de exposição cresce e desaparece dentro do abrigo. `tests/menu_return.gd` acompanha a troca real da cena após a cutscene final e valida menu visível, controles inativos e reservas/inventário reiniciados. O shader de exposição foi inspecionado em `solar-preview.png`; afeta a imagem do mundo, deixando o HUD nítido.

Contagens regressivas: `tests/countdowns_audio.gd` cobre resistência solar de 5 s, três contagens simultâneas, tempo da reserva mais tolerância final de O₂/comida, limpeza após abrigo/reabastecimento e escala musical 100%=0,8 / 50%=0,4. O smoke test verifica a derrota após 5 s de exposição contínua. Capturas `solar-preview.png`, `critical-preview.png` e `settings-preview.png` mostram os timers e o novo padrão de volume.

Ajuste de sobrevivência contínua: `tests/survival_tuning.gd` cobre menu sem painel/frase, botão de início quente, ganhos musicais reduzidos, Sol maior a 180 unidades/lua menor, explosão e loop solar audíveis nos dois ambientes até o fim do evento, avisos de O₂/comida sem rádio e ausência de pausa por Esc. Os testes de minigame/configurações agora exigem que comida e temporizadores continuem avançando. O guia anterior ao início permanece congelado. `critical-preview.png` mostra o aviso local combinado de recursos.

Correção de áudio e salto: `tests/terrain_mobile.gd` verifica bloqueio lateral das plataformas, salto com joystick e segundo dedo, pouso, queda ao sair da borda, alcance vertical de coleta, profundidade das crateras, oito direções com velocidade normalizada e cancelamento ao perder foco. Malha e movimentação consultam o mesmo campo de altura em `scripts/planet_terrain.gd`.

`tests/web_audio_mobile.cjs` usa Chrome com Pixel 7 emulado, sem flag para liberar autoplay. Mede amostras na saída Web Audio em menu/vídeo/exploração/base, verifica silêncio/retorno pelo volume geral e exercita oito direções, diagonais, soltura, salto em movimento com dois dedos, pouso sobre a plataforma, entrada e movimento no abrigo e cancelamento do joystick em orientação vertical. A execução terminou sem erros. Capturas: `web-mobile-jump.png`, `web-mobile-platform.png`, `web-mobile-audio-base.png`. O parâmetro local `?qa=1` habilita apenas a telemetria usada pelo teste; a partida normal não publica esse estado.

O menu 2D centralizado e seus botões maiores foram inspecionados em desktop e paisagem de celular emulado. A arte anterior continua preservada. O defeito de áudio foi reproduzido medindo saída zero apesar dos players ativos; após a correção Stream, a saída deixou de ser zero. Isso complementa os testes antigos, que verificavam estado e console mas não o sinal de áudio.

Menu e descoberta: `tests/radio_resources.gd` verifica 6 peças de antena antes da transmissão, 5 pedras/8 combustíveis depois dela, bloqueio de coleta sem sinal, itens ocultos após transição interior/exterior e preservação do inventário. Também cobre volumes independentes, zero silencioso, sobrevivência avançando nas configurações e troca entre os dois MP3 em loop. O teste web abre a engrenagem, ajusta música e percorre o início em desktop/toque. No desktop, recarrega a página e confere visualmente o ganho preservado em `web-desktop-settings-restored.png`. `menu-preview.png` e `settings-preview.png` mostram a nova interface; a origem e o prompt da arte estão em `MENU_ART.md`.

A atualização de decolagem cobre névoa planetária de 12 s, morte após 5 s de exposição contínua, proteção e reinício da exposição dentro do abrigo, pulso de energia baixa, sons distintos de coleta/derrota e escrita progressiva. A automação percorre as duas páginas do guia com a simulação congelada e verifica vídeo final antes do retorno automático ao menu. Capturas `solar-preview.png`, `briefing2-preview.png`, `outro-preview.png` e `outro-storyboard.png` registram os novos visuais. O teste web percorre ambos os slides em desktop e toque emulado.

Capturas `web-desktop-*.png` e `web-mobile-*.png` documentam menu, vídeo, exploração, base, painel e movimento. `intro-storyboard.png` mostra um quadro da cutscene.

Sem testes em celular físico ou Safari/iOS. O site foi servido localmente, sem publicação pública. Desempenho e recortes reais precisam de validação após hospedagem. Comunicação e resgate têm cobertura de estado no Godot; a inspeção web cobre abertura, vídeo, entrada e circulação na base.
