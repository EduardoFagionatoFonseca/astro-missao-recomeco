# Introdução em vídeo

`assets/cinematics/intro.ogv`: filme original de 22 segundos, 960×540, 24 fps, Theora + Vorbis mono, cerca de 1,3 MiB. Imagem e trilha procedurais, sem conteúdo de terceiros. Estilo ilustrado com movimentos lentos, poeira, transições e pulsos de rádio.

1. 0–5,5 s: Marte e a nave distante.
2. 5,5–11 s: tempestade, astronauta e abrigo.
3. 11–16,5 s: rádio e promessa da tripulação.
4. 16,5–22 s: abrigo isolado e objetivo de sobrevivência.

Legendas em português em `scripts/intro_video.gd` acompanham o vídeo. Botão, toque, Espaço, Enter ou Esc permitem pular. Depois do vídeo vem o guia da missão, com recursos e eventos suspensos; a partida só começa ao confirmar o guia. Reiniciar a cena conserva a marca de vídeo visto na sessão; em nova abertura, ele reaparece.

Para regenerar, instale Pillow e numpy no Python e use FFmpeg com libtheora/libvorbis:

```text
python tools/generate_intro.py --ffmpeg /caminho/ffmpeg
```

O gerador também grava `docs/intro-storyboard.png`. Não é necessário regenerar para jogar ou exportar.

## Decolagem

`assets/cinematics/outro.ogv`: vídeo original de 14 segundos, 960×540 a 24 fps, no mesmo estilo ilustrado da abertura. Mostra ignição, subida e Marte ficando para trás, com trilha sintetizada e ruído de motor originais. Não utiliza mídia externa. Gere com `python tools/generate_outro.py --ffmpeg /caminho/ffmpeg`.

Embarcar congela a partida e inicia o vídeo. Finalizar ou pular recarrega a cena e retorna automaticamente ao menu principal, com missão nova e volumes preservados. As opções de pular são iguais às da introdução. O guia inicial tem duas páginas; apenas **Começar**, na segunda, inicia recursos e eventos.
