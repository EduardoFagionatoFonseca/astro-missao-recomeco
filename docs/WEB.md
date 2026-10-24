# Versão web

Requer Godot **4.7.2** e Python 3 para obter o template oficial. O jogo exportado não precisa de Python.

```powershell
powershell -ExecutionPolicy Bypass -File tools/export_web.ps1 -GodotPath "C:\caminho\godot.exe" -PythonPath "python"
```

O script baixa somente o template Web sem threads do pacote oficial por HTTP Range, verifica seu CRC e grava em `.runtime/templates/`. Se o ambiente bloquear downloads parciais, instale os templates pelo Godot e limpe os campos **Custom Template** no preset Web.

Saídas: `build/web/` contém o site, `build/astro-web.zip` contém os arquivos para upload. A pasta build fica fora do controle de versão.

## Testar

```text
python -m http.server 8060 --bind 127.0.0.1 --directory build/web
```

Abra http://127.0.0.1:8060. Abrir por `file://` não funciona. Para o teste automatizado, instale Playwright em seu ambiente de testes e rode `node tests/web_smoke.cjs` com Chrome instalado. `PLAYWRIGHT_MODULE` permite fornecer um caminho para o módulo; `BROWSER_CHANNEL` permite outro canal Chromium instalado.

## Hospedar

Envie **todos os arquivos** de `build/web` para hospedagem estática HTTPS, mantendo nomes e estrutura. Inclua `.wasm`, `.pck`, `.js` e os worklets de áudio. Sirva `.wasm` como `application/wasm`; gzip/Brotli reduz o download. Esta variante não usa SharedArrayBuffer e não requer COOP/COEP. Não há publicação automática.

## Celular

- Detecção combina identificação Android/iOS e capacidade de toque, incluindo iPadOS em modo desktop. Computadores touch continuam com a interface de computador. A largura da janela não ativa controles mobile.
- Dedos independentes permitem mover e saltar/interagir simultaneamente. Não há corrida. Pausa, troca de tela, perda de foco e redimensionamento limpam os toques ativos.
- A página respeita `safe-area-inset` e bloqueia scroll sobre o canvas. Na orientação vertical, movimento e entrada do puzzle aguardam o aparelho ser girado, mas recursos e eventos de sobrevivência continuam.
- Vídeo Theora 960×540/24 fps reproduzido pelo Godot após Iniciar, com legendas separadas. Falha/travamento do decoder tem texto de contexto e limite de duração. Pular fica disponível desde o início.

Chrome desktop e emulação Android foram exercitados localmente. **Safari/iPhone, Android físico, recortes e desempenho em aparelhos reais ainda precisam de validação.**
