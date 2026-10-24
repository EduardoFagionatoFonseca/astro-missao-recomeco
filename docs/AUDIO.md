# Áudio original

Os efeitos são sintetizados no Godot. As duas músicas de exploração/base são os arquivos MP3 fornecidos pelo usuário, identificados em `assets/audio/README.md`:

- Música: Space Galaxy na exploração/menu e Space Ship dentro da base. Reprodução em loop com transição de 1,2 segundo; as cutscenes mantêm suas trilhas originais.
- Alerta solar: um único ruído grave de explosão distante com três ecos progressivamente mais baixos, a −20 dB. A indicação principal é o céu clareando. Não se repete a cada segundo.
- Névoa solar: cauda curta do eco, a −23 dB, sem loop. Dentro da base, os dois efeitos solares são interrompidos.
- O₂/alimento: dois pulsos suaves em 920/700 Hz, em canal próprio. Avisos em 25% e 12%; abaixo de 12%, repetição com intervalo de oito segundos.
- Pane de energia: estalo elétrico e zumbido de 100 Hz, com envelope suave.
- Desconexão: três notas descendentes com leve estática, distintas da pane elétrica e do alerta vital.
- Rádio: toque breve e baixo no início de cada mensagem da tripulação.
- Coletas: clique macio e três notas ascendentes sobrepostas, com decaimento de sino.
- Digitação: pulsos de 35 ms, baixos e espaçados, somente enquanto aparecem letras.
- Derrota: acorde grave descendente de 1,5 segundo, em canal próprio.

Os efeitos ficam em `scripts/event_audio.gd`, com geração determinística e canais separados. A engrenagem do menu e **Som**, durante a partida, abrem quatro volumes independentes: geral, músicas, interações e avisos. Zero silencia somente o canal escolhido; os ganhos persistem em `user://audio.cfg`. Abrir configurações suspende recursos e eventos. A pausa suspende música e alertas. A coleta não interrompe os avisos. Os diálogos de rádio são textos na interface, sem voz gravada.

## Correção da saída Web

Músicas e efeitos usam explicitamente `AudioServer.PLAYBACK_TYPE_STREAM`, com os quatro canais definidos em `default_bus_layout.tres` antes da inicialização da cena. O caminho anterior de reprodução Sample, combinado com os canais criados em execução, indicava `playing` sem produzir sinal na saída Web. A documentação descreve a escolha entre [Sample e Stream](https://docs.godotengine.org/en/latest/tutorials/audio/audio_streams.html).

O teste `tests/web_audio_mobile.cjs` mede a saída real do grafo Web Audio, sem liberar autoplay por flag: menu, vídeo, exploração e base devem ter RMS maior que zero. Também verifica silêncio ao zerar Geral e retorno do sinal ao restaurar o volume. Assim, verificar apenas `AudioStreamPlayer.playing` deixa de ser suficiente para validar áudio.
