# Astro · Um Pequeno Recomeço

Uma miniaventura cozy 3D no Godot 4.7.2. Isolado em Marte, explore o planeta, mantenha o abrigo funcionando e transmita sua localização para sua tripulação voltar. Inclui exportação para navegador e controles de celular.

## Jogar

No Windows, abra **Jogar.cmd**. O iniciador usa o Godot instalado na pasta Downloads deste computador, no PATH ou na variável `GODOT_EXE`. Para editar, importe `project.godot` no Godot 4.7 e pressione F5. Não há dependências de rede ou plugins.

- WASD ou setas: caminhar por toda a superfície esférica.
- Espaço: saltitar. Shift: caminhar mais rápido.
- E: recolher, entrar/sair da base, usar os painéis ou embarcar na nave.
- E na estufa: consumir uma refeição e reabastecer alimentos.
- Esc: fechar minigame ou pausar. Botão Som: silenciar música e efeitos.
- Celular: joystick e botões aparecem automaticamente; jogue na horizontal. A orientação vertical suspende a partida.

Iniciar missão apresenta um vídeo original de 22 segundos com trilha e legendas. Pular, Espaço, Enter ou Esc avançam para o jogo. Reiniciar após derrota não repete o vídeo na mesma sessão.

## Um passeio completo

Reúna 6 pedras de regolito, 6 peças para a antena e 6 galões de combustível para abastecer o resgate. Os itens estão espalhados por toda a esfera, inclusive no outro hemisfério. Cartões animados mostram interações próximas. A nave só chega quando todos os materiais estão reunidos **e o sinal foi transmitido**. Aproxime-se e pressione E para embarcar.

Dentro do raio de recuperação de oxigênio, use **Entrar na base**. O interior tem circulação livre, colisão com móveis, painel de energia e terminal de comunicação. A saída preserva sua posição externa e os itens coletados.

- **Energia:** selecione uma origem e um destino com a mesma letra para conectar três cabos. O reparo restaura 100% da bateria. Ela perde 0,12 ponto por segundo de jogo e 18 pontos ao terminar uma onda solar externa. Ao esgotar, refaça o reparo. A reserva de emergência mantém o O₂ mesmo sem energia.
- **Comunicação:** com energia e seis peças da antena, ajuste frequência e alinhamento. Mantenha o sinal acima de 92% por três segundos para enviar sua localização. A confirmação permanece válida mesmo após outra falha de energia.

Dentro da base, o O₂ se recupera e não há dano solar; o alimento continua sendo consumido. **Nos minigames, recursos e temporizadores ficam suspensos.** A onda solar aguarda enquanto o jogador está no interior. Fechar o painel preserva os cabos; interromper a transmissão exige nova estabilização.

Oxigênio e alimento exigem viagens de reabastecimento: a base repõe O₂ automaticamente; uma segunda base, a estufa, fica a aproximadamente 20 metros de arco da original e oferece refeições com E. A estufa não protege da radiação. A derrota encerra a expedição e exige recomeçar do zero.

O oxigênio dura aproximadamente **29 segundos** fora da base; alimentos duram cerca de **56 segundos**. Barras mostram as duas reservas, mudam de cor e pulsam quando estão baixas. As bordas da tela escurecem progressivamente. Depois de zerar uma reserva, há **dois segundos** para chegar à base ou comer antes da derrota. Cada reserva tem seu próprio prazo; recuperar uma não salva o personagem se a outra continua esgotada. Pausar congela os prazos. A base repõe O₂ em quatro segundos.

Após 45 segundos de exploração, uma sirene anuncia **10 segundos de aviso** antes de uma onda solar que percorre o planeta por **10 segundos**, com som de propagação. Uma luz distante aumenta e pulsa antes da onda; o ponto luminoso e a propagação usam a mesma direção no mundo. Não há texto de alerta ou contagem regressiva na tela. A frente exclui geometricamente o abrigo. Apenas tocar a faixa causa dano: −35 de O₂ e −12 de alimento, uma vez por onda. O restante da superfície é seguro antes e depois da passagem. O teste de contato considera o deslocamento entre quadros.

Três cartões grandes mostram os objetivos 0/6. A orientação do astronauta respeita a frente +Z do modelo Kenney e o movimento usa os eixos da câmera projetados na esfera.

É uma experiência didática, não uma simulação física de Marte ou engenharia real. O progresso não persiste após fechar o jogo.

## Navegador e hospedagem

O preset Web usa exportação sem threads e uma página que respeita recortes de celular. Gere com `tools/export_web.ps1`; os arquivos ficam em `build/web` e o pacote em `build/astro-web.zip`. Veja [docs/WEB.md](docs/WEB.md) para geração, teste local e hospedagem estática. Não há publicação automática.

## Arte e áudio

Modelos **Kenney Space Kit 2.0 (CC0)** reutilizados do Last Light conforme solicitado. Licença em `assets/space/License.txt`, origem em https://kenney.nl/assets/space-kit e proveniência em `docs/ASSETS.md`. O planeta, acampamento, nave, iluminação e interface são montados no projeto. Trilha ambiente espacial original: acordes longos com timbre de órgão, drone grave e camadas aéreas. Sons de coleta, sirene e propagação também são sintetizados localmente, sem gravações ou músicas de terceiros. Veja `docs/AUDIO.md`.

## Verificação

A introdução é um filme ilustrado procedural, com imagem e trilha originais. O arquivo já está incluído em `assets/cinematics/intro.ogv`; veja [docs/CINEMATICS.md](docs/CINEMATICS.md) para regenerar.

`godot --headless --path . --editor --import --quit`

`godot --headless --path . -- --smoke-test`

O teste verifica o mundo e a sobrevivência, multitoque, interior, colisões, cabos, energia, bloqueios/estabilidade do sinalizador e resgate. `godot --path . -- --capture-base` salva uma captura do interior. Veja [docs/FEATURE_VALIDATION.md](docs/FEATURE_VALIDATION.md) para testes do navegador e limitações.
