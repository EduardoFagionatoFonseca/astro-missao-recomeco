# Validação da versão cozy

- Godot 4.7: importação dos sete modelos OBJ concluída.
- Execução real com OpenGL 3.3 na GPU: captura da introdução e do mundo inspecionadas. Ajustadas iluminação, barra de progresso e posição dos painéis após revisão.
- Teste sem janela: posição e orientação dos 18 itens sobre a esfera, seis itens de cada tipo, movimento contínuo atravessando hemisférios, interação de coleta, surgimento da nave, pouso e encerramento.
- Modelos OBJ/MTL e licença copiados sem alteração; hashes comparados à origem.
- Não foram usados templates de exportação 4.6.1 com o motor 4.7. `Jogar.cmd` inicia o projeto com o Godot local, sem exigir um executável exportado.

Limites: ainda não houve uma sessão manual completa de exploração. O teste automatizado percorre a esfera e aciona as interações de coleta; não avalia sensação dos controles ou preferência artística. Na saída imediata do teste sem janela, o motor informa recursos ObjectDB remanescentes; a captura gráfica encerrou sem esse aviso.
