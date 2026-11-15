# Astro · Um Pequeno Recomeço

Uma miniaventura cozy 3D no Godot 4.7.2. Isolado em Marte, explore o planeta, mantenha o abrigo funcionando e transmita sua localização para sua tripulação voltar. Inclui exportação para navegador e controles de celular.

Escolha **Fácil, Médio ou Difícil** antes de começar. O consumo de reservas e a frequência de panes e radiação usam multiplicadores de 0,8 / 1 / 1,2, acrescidos gradualmente de até 35% conforme os 22 itens são coletados. O aviso solar de 16 s e a resistência à exposição de 3 s valem em todas as dificuldades. Uma rota e uma seta no minimapa orientam o retorno ao abrigo a cada tempestade, mesmo sem rádio.

A orientação mostra um objetivo por vez, priorizando a sobrevivência e a menor reserva. A rota acompanha o terreno, com uma folga visual em torno do astronauta, e termina no horizonte se o destino estiver no outro hemisfério. No **fácil**, o guia acompanha a missão até o resgate. No **médio/difícil**, orienta as duas primeiras peças e a primeira necessidade de oxigênio, comida, energia e transmissão. No navegador, o canvas acompanha o viewport visível, a densidade de pixels, áreas seguras, rotação e mudanças da barra de endereço.

O idioma padrão é inglês. Em **Settings → Language**, escolha **Português** ou **English** para menus, guia, HUD, minigames, mensagens e legendas dos vídeos inicial/final. Os vídeos originais não têm fala nem textos gravados na imagem; usam legendas traduzidas. Idioma e dificuldade ficam salvos entre sessões.

## Jogar

No Windows, abra **Jogar.cmd**. O iniciador usa o Godot instalado na pasta Downloads deste computador, no PATH ou na variável `GODOT_EXE`. Para editar, importe `project.godot` no Godot 4.7 e pressione F5. Não há dependências de rede ou plugins. Para entender a árvore de cenas e onde ajustar cada parte, consulte [docs/EDITING.md](docs/EDITING.md).

- WASD ou setas: caminhar por toda a superfície esférica.
- Espaço: saltar sobre bordas e subir plataformas baixas. A caminhada é de **5,18 m/s**, chegando a **6,47 m/s** com o rover.
- E: recolher, entrar/sair da base, usar os painéis ou embarcar na nave.
- M: ampliar o minimapa.
- E na estufa: consumir uma refeição e reabastecer alimentos.
- Esc: abrir ou fechar configurações, fechar o índice ou sair do minigame. A engrenagem também abre as configurações.
- Celular: joystick e botões aparecem automaticamente; jogue na horizontal. A orientação vertical suspende a partida.

O menu abre com arte marciana 2D e composição central, **Começar** em bege alaranjado e uma engrenagem, sem painel ou frase ao redor dos botões. A capa anterior permanece em `assets/ui/menu-mars.png`; a atual é `assets/ui/menu-mars-2d.png`. As configurações oferecem volumes independentes de geral, músicas, interações e avisos, salvos entre sessões. Space Galaxy toca na exploração/menu; Space Ship toca dentro da base, com transição suave. O ganho da música externa foi reduzido em cerca de 6 dB, e o da base em cerca de 2,4 dB; durante a radiação há redução adicional para destacar o ambiente sonoro.

Começar apresenta um vídeo original de 22 segundos com trilha e legendas. Pular, Espaço, Enter ou Esc abrem o guia da missão. O guia ocupa cerca de 70% da tela e tem duas páginas: **Próximo** e **Começar**. Recursos e eventos ficam suspensos até Começar. Reiniciar após derrota retorna ao menu. Cada nova missão começa pelo vídeo. Embarcar inicia uma cutscene de decolagem de 14 segundos, também pulável; ao terminar ou pular, o jogo retorna automaticamente ao menu principal, pronto para uma nova missão.

Na primeira conclusão de cada tarefa de energia, antena, oxigênio, estufa e proteção solar, aparece uma pergunta curta em português ou inglês. A resposta libera uma explicação e o link da fonte da NASA. A pergunta sobre radiação aparece depois que a névoa passa e pode ser pulada.

## Um passeio completo

O **Índice de Marte**, no lado esquerdo do HUD, reúne as fotos já recuperadas. Cada foto vem com créditos e fonte. As imagens são incluídas no pacote do jogo. A partida pausa enquanto o índice está aberto.

Em Configurações, **Voltar ao menu principal** encerra a missão atual.

Reúna as **6 peças de antena** e ative a transmissão no terminal da base para localizar **8 galões de combustível**. O último galão ativa o rover do acampamento, que acompanha o astronauta na superfície, aumenta sua velocidade em **25%** e libera as **8 fotos de Marte**. Se a comunicação cair, os combustíveis e pontos de foto ficam ocultos até restaurar a conexão. O inventário e o bônus do rover continuam ativos. A nave se aproxima assim que as oito fotos são recuperadas com o rádio ativo. Aproxime-se e pressione E para embarcar.

Dentro do raio de recuperação de oxigênio, use **Entrar na base**. O interior tem circulação livre, colisão com móveis, painel de energia e terminal de comunicação. A saída preserva sua posição externa e os itens coletados.

A superfície tem crateras rasas, relevos suaves e plataformas de 0,38–0,44 m. A borda das plataformas bloqueia a caminhada; pule para subir, pouse no topo e caminhe para fora para cair de volta à superfície. Uma peça de antena fica na plataforma de prática perto da base. A altura também conta para alcançar itens. No celular, segure o joystick com um dedo e toque **Saltar** com outro. Diagonais têm velocidade normalizada; soltar, perder foco ou girar a tela cancela o movimento. Dentro da base, o botão de salto fica inativo.

- **Energia:** conecte três cabos com letras iguais. O reparo restaura 100% e reinicia o ciclo de **63,75 segundos**. Em 30%, já é possível reparar preventivamente. **Sem energia, a produção de O₂ para**, inclusive dentro da base, e a reserva do traje continua caindo. A partida começa com energia ativa.
- **Comunicação:** o rádio de avisos começa ativo e cai após **85 segundos**. Para restaurar a antena e enviar a posição ao resgate, reúna seis peças e sobreponha as ondas por três segundos. O painel fecha sozinho ao concluir, e a estação fica sem interação enquanto o sinal permanecer estabilizado. Uma nova queda reabilita a tarefa e muda a sintonia. Depois de chamar a nave, não há novas quedas durante a aproximação.

Dentro da base, o O₂ se recupera **se houver energia** e não há dano solar; o alimento continua sendo consumido. A janela fica iluminada durante o aviso e a névoa, apagando quando é seguro sair. A sobrevivência continua durante minigames e configurações. Girar o celular para a vertical ou abrir uma pergunta suspende o consumo e os eventos. Falta de energia interrompe a sintonia da antena. O guia anterior ao início continua sem consumir recursos.

As mensagens da tripulação se limitam ao início, confirmação do sinal e pouso. **Inteligência artificial AXIOS** avisa sobre energia em 30%, a primeira pane e radiação prevista. Sem comunicação, as mensagens de rádio são descartadas, inclusive as já abertas. A janela e os alertas do traje continuam funcionando sem rádio.

Oxigênio e alimento exigem viagens de reabastecimento: a base com energia repõe O₂; a estufa oferece refeições com E e não protege da radiação. A derrota encerra a expedição e exige recomeçar do zero.

Com dificuldade média e sem materiais coletados, uma reserva cheia dura cerca de **89 segundos de O₂** e **135 segundos de comida**. Internamente vão até 105 unidades; a interface continua mostrando 100% quando cheias. Barras ficam vermelhas e pulsam quando baixas; avisos locais na tela aparecem em 25% e 12%, mesmo sem rádio, e voltam a funcionar após reabastecer. A partir de 12%, contagens regressivas mostram o tempo restante até a derrota por fome ou falta de O₂, incluindo os três segundos de tolerância após zerar. A recuperação de O₂ no abrigo energizado remove sua contagem; reabastecer a comida remove a de fome.

Depois do período calmo, o traje dá um aviso de **16 segundos**, seguido de até **9 segundos** de névoa. Com sinal, AXIOS também anuncia o alerta. Se entrar na base enquanto o aviso estiver correndo, a névoa começa assim que você estiver protegido e termina em **3 segundos**. Se a névoa já tiver começado, restam no máximo 3 segundos. A contagem de dentro mostra quando é seguro sair. **Só o interior protege**. Três segundos de exposição contínua causam derrota, e entrar no abrigo zera a exposição.

O₂ e alimento ficam progressivamente vermelhos e pulsam suavemente quando baixos. Energia também pulsa em vermelho aos 30% ou menos. Um aviso de dois tons, diferente do sol, soa em 25% e 12%; na faixa crítica, pode repetir a cada oito segundos. Energia e desconexão têm sons próprios. Mensagens aparecem a 70 caracteres por segundo com digitação discreta. Coletas tocam notas ascendentes; derrota toca um acorde descendente. Os efeitos são sintetizados originalmente; as duas músicas de ambiente foram fornecidas pelo usuário e estão identificadas em [assets/audio/README.md](assets/audio/README.md). A arte do menu e seu prompt estão em [docs/MENU_ART.md](docs/MENU_ART.md).

Os três objetivos mostram miniaturas dos próprios modelos, renderizadas uma vez em viewports independentes. Um tema compartilhado personaliza painéis, botões, barras e sliders com slots escuros, bordas retas e fontes maiores; não usa a aparência padrão dos controles. Os textos de jogo foram reduzidos e as primeiras falhas ensinam suas regras em contexto.

É uma experiência didática, não uma simulação física de Marte ou engenharia real. O progresso não persiste após fechar o jogo.

## Navegador e hospedagem

O preset Web usa exportação sem threads e uma página que respeita recortes de celular. Gere com `tools/export_web.ps1`; os arquivos ficam em `build/web` e o pacote em `build/astro-web.zip`. Veja [docs/WEB.md](docs/WEB.md) para geração, teste local e hospedagem estática. Não há publicação automática.

## Arte e áudio

Modelos **Kenney Space Kit 2.0 (CC0)** reutilizados do Last Light conforme solicitado. Licença em `assets/space/License.txt`, origem em https://kenney.nl/assets/space-kit e proveniência em `docs/ASSETS.md`. O planeta, acampamento, nave, iluminação e interface são montados no projeto. As duas trilhas de ambiente foram fornecidas pelo usuário; coleta, explosão, ruído solar e alertas são sintetizados localmente. Veja `docs/AUDIO.md`.

## Verificação

A introdução é um filme ilustrado procedural, com imagem e trilha originais. O arquivo já está incluído em `assets/cinematics/intro.ogv`; veja [docs/CINEMATICS.md](docs/CINEMATICS.md) para regenerar.

`godot --headless --path . --editor --import --quit`

`godot --headless --path . -- --smoke-test`

O teste verifica o mundo e a sobrevivência, multitoque, interior, colisões, cabos, energia, bloqueios/estabilidade do sinalizador e resgate. `godot --path . -- --capture-base` salva uma captura do interior. Veja [docs/FEATURE_VALIDATION.md](docs/FEATURE_VALIDATION.md) para testes do navegador e limitações.
