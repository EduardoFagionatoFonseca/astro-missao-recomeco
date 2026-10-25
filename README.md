# Astro · Um Pequeno Recomeço

Uma miniaventura cozy 3D no Godot 4.7.2. Isolado em Marte, explore o planeta, mantenha o abrigo funcionando e transmita sua localização para sua tripulação voltar. Inclui exportação para navegador e controles de celular.

Escolha **Fácil, Médio ou Difícil** antes de começar. O consumo de reservas e a frequência de panes/radiação usam multiplicadores de 0,8 / 1 / 1,2, acrescidos gradualmente de até 35% conforme os 19 itens são coletados. A janela de aviso solar de 5 s e a resistência de 3 s permanecem constantes. Setas animadas orientam as duas primeiras peças de antena e a primeira necessidade de oxigênio, comida, energia, transmissão e abrigo solar. Após resolver cada necessidade, sua seta não reaparece naquela partida.

A orientação mostra um objetivo por vez, priorizando a sobrevivência e a menor reserva. Uma rota com pontas animadas parte do astronauta, acompanha o terreno até o destino e termina no horizonte quando o destino fica no outro lado do planeta. No **fácil**, objetivos voltam sempre que necessários e acompanham coleta, suprimentos e resgate até o final; no **médio/difícil**, cada necessidade é orientada somente na primeira ocorrência. O guia inicial apresenta recuperar oxigênio e encontrar comida como objetivos. No navegador, o canvas acompanha o viewport visível, a densidade de pixels, áreas seguras, rotação e mudanças da barra de endereço.

Nas configurações, **Português / English** altera menus, guia, HUD, minigames, mensagens e legendas dos vídeos inicial/final. Os vídeos originais não têm fala nem textos gravados na imagem; usam legendas traduzidas. Idioma e dificuldade ficam salvos entre sessões.

## Jogar

No Windows, abra **Jogar.cmd**. O iniciador usa o Godot instalado na pasta Downloads deste computador, no PATH ou na variável `GODOT_EXE`. Para editar, importe `project.godot` no Godot 4.7 e pressione F5. Não há dependências de rede ou plugins.

- WASD ou setas: caminhar por toda a superfície esférica.
- Espaço: saltar sobre bordas e subir plataformas baixas. Movimento em velocidade fixa de 3,8934 m/s (+3%); não há corrida.
- E: recolher, entrar/sair da base, usar os painéis ou embarcar na nave.
- E na estufa: consumir uma refeição e reabastecer alimentos.
- Esc: fechar configurações ou minigame. A partida não tem pausa. Botão Som: ajustar volumes.
- Celular: joystick e botões aparecem automaticamente; jogue na horizontal. A orientação vertical suspende a partida.

O menu abre com arte marciana 2D e composição central, **Começar** em bege alaranjado e uma engrenagem, sem painel ou frase ao redor dos botões. A capa anterior permanece em `assets/ui/menu-mars.png`; a atual é `assets/ui/menu-mars-2d.png`. As configurações oferecem volumes independentes de geral, músicas, interações e avisos, salvos entre sessões. Space Galaxy toca na exploração/menu; Space Ship toca dentro da base, com transição suave. O ganho da música externa foi reduzido em cerca de 6 dB, e o da base em cerca de 2,4 dB; durante a radiação há redução adicional para destacar o ambiente sonoro.

Começar apresenta um vídeo original de 22 segundos com trilha e legendas. Pular, Espaço, Enter ou Esc abrem o guia da missão. O guia ocupa cerca de 70% da tela e tem duas páginas: **Próximo** e **Começar**. Recursos e eventos ficam suspensos até Começar. Reiniciar após derrota retorna ao menu e não repete o vídeo na mesma sessão. Embarcar inicia uma cutscene de decolagem de 14 segundos, também pulável; ao terminar ou pular, o jogo retorna automaticamente ao menu principal, pronto para uma nova missão.

## Um passeio completo

Primeiro, apenas as **6 peças de antena** estão disponíveis. Reúna-as e ative a transmissão no terminal da base para localizar **5 pedras e 8 galões de combustível**. Se a comunicação cair, os recursos restantes ficam invisíveis e não podem ser coletados até restaurar a conexão; o inventário permanece intacto. Os itens estão espalhados por toda a esfera, inclusive no outro hemisfério. Cartões animados mostram interações próximas. A nave só chega quando todos os materiais estão reunidos **e a conexão de rádio está ativa**. Aproxime-se e pressione E para embarcar.

Dentro do raio de recuperação de oxigênio, use **Entrar na base**. O interior tem circulação livre, colisão com móveis, painel de energia e terminal de comunicação. A saída preserva sua posição externa e os itens coletados.

A superfície tem crateras rasas, relevos suaves e plataformas de 0,38–0,44 m. A borda das plataformas bloqueia a caminhada; pule para subir, pouse no topo e caminhe para fora para cair de volta à superfície. Uma peça de antena fica na plataforma de prática perto da base. A altura também conta para alcançar itens. No celular, segure o joystick com um dedo e toque **Saltar** com outro. Diagonais têm velocidade normalizada; soltar, perder foco ou girar a tela cancela o movimento. Dentro da base, o botão de salto fica inativo.

- **Energia:** conecte três cabos com letras iguais. O reparo restaura 100% e reinicia o ciclo de **63,75 segundos**. Em 30%, já é possível reparar preventivamente. **Sem energia, a produção de O₂ para**, inclusive dentro da base, e a reserva do traje continua caindo. A partida começa com energia ativa.
- **Comunicação:** o rádio de avisos começa ativo e cai após **85 segundos**. Para restaurar a antena e enviar a posição ao resgate, reúna seis peças e sobreponha as ondas por três segundos. O painel fecha sozinho ao concluir, e a estação fica sem interação enquanto o sinal permanecer estabilizado. Uma nova queda reabilita a tarefa e muda a sintonia. Depois de chamar a nave, não há novas quedas durante a aproximação.

Dentro da base, o O₂ se recupera **se houver energia** e não há dano solar; o alimento continua sendo consumido. A janela fica iluminada durante o aviso e a névoa, apagando quando é seguro sair. **A sobrevivência continua durante minigames, configurações e orientação vertical**; apenas os controles ficam indisponíveis. Falta de energia interrompe a sintonia da antena. O guia anterior ao início continua sem consumir recursos.

As mensagens da tripulação se limitam ao início, confirmação do sinal e pouso. **Inteligência artificial AXIOS** avisa sobre energia em 30%, a primeira pane e radiação prevista. Sem comunicação, os avisos ligados à antena são descartados, inclusive os já abertos; o primeiro diagnóstico local de desconexão apenas explica que os avisos foram suspensos. A janela e os indicadores físicos continuam funcionando sem rádio.

Oxigênio e alimento exigem viagens de reabastecimento: a base com energia repõe O₂; a estufa oferece refeições com E e não protege da radiação. A derrota encerra a expedição e exige recomeçar do zero.

As reservas aumentaram 5%: O₂ dura cerca de **31 segundos** e comida cerca de **58 segundos**. Internamente vão até 105 unidades; a interface continua mostrando 100% quando cheias. Barras ficam vermelhas e pulsam quando baixas; avisos locais na tela aparecem em 25% e 12%, mesmo sem rádio, e voltam a funcionar após reabastecer. A partir de 12%, contagens regressivas mostram o tempo restante até a derrota por fome ou falta de O₂, incluindo os dois segundos de tolerância após zerar. A recuperação de O₂ no abrigo energizado remove sua contagem; reabastecer a comida remove a de fome.

Após 100 segundos, o céu clareia durante dez segundos de aviso, seguidos de uma névoa que cobre o planeta inteiro por 12 segundos. A antena conectada avisa pelo rádio somente **5 segundos antes da névoa**, com prioridade sobre transmissões em andamento. Uma explosão com eco marca o início da radiação, seguida de ruído contínuo até o fim, também audível dentro do abrigo. O Sol visual é maior e fica a 180 unidades do centro do planeta; a lua ficou 25% menor. **Só o interior protege**. Cinco segundos de exposição contínua causam derrota; entrar no abrigo zera a exposição. Uma contagem mostra a resistência restante. Fora dele, a imagem recebe desfoque sutil e bordas alaranjadas que avançam com a exposição, preservando a nitidez da interface.

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
