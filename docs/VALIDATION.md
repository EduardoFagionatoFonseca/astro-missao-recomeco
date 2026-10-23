# Validação da versão cozy

Registro histórico do protótipo anterior ao interior da base. As regras e verificações atuais, incluindo proteção solar somente no interior, estão em `FEATURE_VALIDATION.md`.

- Godot 4.7: importação dos sete modelos OBJ concluída.
- Execução real com OpenGL 3.3 na GPU: captura da introdução e do mundo inspecionadas. Ajustadas iluminação, barra de progresso e posição dos painéis após revisão.
- Teste sem janela: posição e orientação dos 18 itens sobre a esfera, seis itens de cada tipo, movimento contínuo atravessando hemisférios, interação de coleta, surgimento da nave, pouso e encerramento.
- Modelos OBJ/MTL e licença copiados sem alteração; hashes comparados à origem.
- Não foram usados templates de exportação 4.6.1 com o motor 4.7. `Jogar.cmd` inicia o projeto com o Godot local, sem exigir um executável exportado.
- Atualização de sobrevivência: regressão das quatro direções de movimento e orientação visual do modelo; consumo e reposição de oxigênio; interação para refeições na estufa; aviso solar, onda, exposição fora da base e proteção dentro; retorno de emergência sem perda de itens. Teste passou no Godot 4.7.
- Dificuldade e radiação por contato: verificados os novos consumos, aviso de 10 segundos e onda de 10 segundos, ausência de dano fora da frente visível, varredura de colisão entre quadros, um único impacto por onda, exclusão do abrigo tanto da colisão quanto dos vértices da faixa, reprodução do áudio da onda, alertas de reservas e resgate sem perda de itens. Capturas gráficas conferidas com e sem onda.
- Versão atual: retorno automático substituído por derrota e reinício da expedição. Testados os dois segundos após O₂ ou alimento zerarem, recuperação de O₂ na base e refeição durante essa janela, derrota sem teletransporte e reinício pelo recarregamento da cena. Verificados os valores das barras, intensidade da vinheta e alinhamento entre luz distante e origem da onda. Capturas com onda e fome crítica inspecionadas. Dicas, textos de alerta solar e popups de coleta foram retirados do HUD.

Limites: ainda não houve uma sessão manual completa de exploração. O teste automatizado percorre a esfera e aciona as interações de coleta; não avalia sensação dos controles ou preferência artística. Ao encerrar, o motor pode informar recursos ObjectDB remanescentes tanto no teste sem janela quanto na captura. Não houve erro de script, importação ou renderização.
