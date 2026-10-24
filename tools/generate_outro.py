"""Original illustrated departure film and synthesized score; no third-party media."""
from pathlib import Path
import argparse, subprocess, tempfile, wave, math
import numpy as np
from PIL import Image, ImageDraw
from generate_intro import STARS, W, H, FPS, ROOT
SECONDS = 14

def rocket(d, x, y, scale, t, ignition=True):
    def points(coords): return [(x+a*scale, y+b*scale) for a,b in coords]
    if ignition:
        flame=105+20*math.sin(t*35)
        d.polygon(points([(-13,48),(0,flame),(13,48)]), fill='#e8a274')
        d.polygon(points([(-7,48),(0,flame*.83),(7,48)]), fill='#fff0c8')
    d.polygon(points([(-19,38),(-35,60),(-33,17),(-17,0)]), fill='#899f9b')
    d.polygon(points([(19,38),(35,60),(33,17),(17,0)]), fill='#899f9b')
    d.polygon(points([(-19,47),(-19,-35),(0,-70),(19,-35),(19,47)]),fill='#dedfca')
    d.ellipse((x-10*scale,y-35*scale,x+10*scale,y-15*scale),fill='#385465')
    d.rectangle((x-19*scale,y+20*scale,x+19*scale,y+29*scale),fill='#a2bbb1')

def frame(t):
    im=Image.new('RGB',(W,H),'#0b1725'); d=ImageDraw.Draw(im)
    for x,y,r in STARS: d.ellipse((x-r,y-r,x+r,y+r),fill='#aabdc5')
    if t<7:
        d.polygon([(0,355),(190,300),(420,350),(720,302),(960,345),(960,540),(0,540)],fill='#955f4e')
        d.polygon([(0,420),(320,350),(600,402),(960,360),(960,540),(0,540)],fill='#bb8062')
        d.ellipse((140,335,390,455),fill='#c7cdbd')
        d.rectangle((140,395,390,450),fill='#c7cdbd')
        d.rectangle((244,385,282,450),fill='#415563')
        d.rectangle((164,382,216,408),fill='#819d9b')
        d.line((355,350,355,292),fill='#d6d8c2',width=4)
        rise=max(0,t-1.5)**2*22
        if t<4:
            for i in range(8):
                radius=12+(t*28+i*17)%85; cx=650+(i-4)*19
                d.ellipse((cx-radius,448-radius*.25,cx+radius,465+radius*.25),fill='#d6a580')
        rocket(d,650,380-rise,1,t,t>.7)
    else:
        p=(t-7)/7; r=260-p*120; cx=335-p*80; cy=520+p*100
        d.ellipse((cx-r,cy-r,cx+r,cy+r),fill='#b97d5c')
        for i in range(8):
            x=cx-r*.7+i*r*.17; y=cy-r*.6+((i*43)%90)*r/260
            d.ellipse((x,y,x+r*.2,y+r*.08),fill='#9f6550')
        rocket(d,580+p*110,260-p*100,.8-p*.32,t)
    fade=max(0,min(1,t/.8,(SECONDS-t)/1.2,abs(t-7)/.3))
    return Image.blend(Image.new('RGB',(W,H),'#07111c'),im,fade)

def main():
    parser=argparse.ArgumentParser(); parser.add_argument('--ffmpeg',required=True); args=parser.parse_args()
    with tempfile.TemporaryDirectory() as tmp:
        audio=Path(tmp)/'departure.wav'; rate=22050; t=np.arange(rate*SECONDS)/rate
        rng=np.random.default_rng(20261023)
        engine=(rng.normal(0,.035,len(t))+np.sin(2*np.pi*48*t)*.07)*np.minimum(1,t/2)*np.maximum(0,1-t/10)
        score=sum(np.sin(2*np.pi*f*t)*a for f,a in [(130.81,.07),(196,.05),(261.63,.04),(329.63,.025)])
        score*=np.minimum(1,t/3)*np.minimum(1,(SECONDS-t)/2)
        with wave.open(str(audio),'wb') as wav:
            wav.setnchannels(1); wav.setsampwidth(2); wav.setframerate(rate)
            wav.writeframes(((engine+score)*24000).astype('<i2').tobytes())
        target=ROOT/'assets/cinematics/outro.ogv'
        cmd=[args.ffmpeg,'-y','-f','rawvideo','-pixel_format','rgb24','-video_size',f'{W}x{H}','-framerate',str(FPS),'-i','pipe:0','-i',str(audio),'-c:v','libtheora','-q:v','6','-pix_fmt','yuv420p','-c:a','libvorbis','-q:a','3','-shortest',str(target)]
        proc=subprocess.Popen(cmd,stdin=subprocess.PIPE,stderr=subprocess.DEVNULL)
        for i in range(FPS*SECONDS): proc.stdin.write(frame(i/FPS).tobytes())
        proc.stdin.close()
        if proc.wait(): raise RuntimeError('FFmpeg failed')
    frame(9).save(ROOT/'docs/outro-storyboard.png')
    print(target)

if __name__=='__main__': main()
