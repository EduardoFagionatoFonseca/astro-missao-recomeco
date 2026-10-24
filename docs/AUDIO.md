# Áudio original

Todos os sons desta versão são gerados no próprio Godot, sem downloads ou material musical de terceiros:

- Música: ambiente espacial original de 32 segundos, com acordes lentos, timbre de órgão suave, transições de 2,5 segundos, drone grave e camadas aéreas. Substitui a antiga melodia de sinos; não reproduz uma composição de filme.
- Alerta solar: um único ruído grave de explosão distante com três ecos progressivamente mais baixos, a −20 dB. A indicação principal é o céu clareando. Não se repete a cada segundo.
- Névoa solar: cauda curta do eco, a −23 dB, sem loop. Dentro da base, os dois efeitos solares são interrompidos.
- O₂/alimento: dois pulsos suaves em 920/700 Hz, em canal próprio. Avisos em 25% e 12%; abaixo de 12%, repetição com intervalo de oito segundos.
- Pane de energia: estalo elétrico e zumbido de 100 Hz, com envelope suave.
- Desconexão: três notas descendentes com leve estática, distintas da pane elétrica e do alerta vital.
- Rádio: toque breve e baixo no início de cada mensagem da tripulação.
- Coletas: clique macio e três notas ascendentes sobrepostas, com decaimento de sino.
- Digitação: pulsos de 35 ms, baixos e espaçados, somente enquanto aparecem letras.
- Derrota: acorde grave descendente de 1,5 segundo, em canal próprio.

Os novos efeitos ficam em `scripts/event_audio.gd`, com geração determinística e canais separados. Não existe licença externa, atribuição obrigatória ou dependência de streaming. O botão **Som** silencia todos os canais; a pausa suspende música e alertas. A coleta não interrompe os avisos. Os diálogos de rádio são textos na interface, sem voz gravada.
