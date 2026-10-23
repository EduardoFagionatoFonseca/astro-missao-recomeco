"""Original procedural 22 s film. Requires Pillow, numpy and FFmpeg with libtheora.
Usage: python tools/generate_intro.py --ffmpeg /path/to/ffmpeg
No downloaded pictures, footage, fonts or audio recordings.
"""
from pathlib import Path
import argparse
import math
import random
import subprocess
import tempfile
import wave
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
W, H, FPS, SECONDS = 960, 540, 24, 22
random.seed(60318)
STARS = [(random.randrange(W), random.randrange(340), random.choice([1, 1, 2])) for _ in range(140)]

def astronaut(d, x, y, s):
    def box(coords, color, radius=5):
        d.rounded_rectangle(tuple(v*s + (x if i%2==0 else y) for i,v in enumerate(coords)), radius=radius*s, fill=color)
    box((-22,-56,22,-10), '#e4dcc5', 12)
    box((-16,-47,16,-26), '#365466', 8)
    box((-20,-9,20,41), '#d1ccb9', 6)
    box((-29,-4,-20,31), '#bec5b7')
    box((20,-4,29,31), '#bec5b7')
    box((-18,34,-3,62), '#aab6af')
    box((3,34,18,62), '#aab6af')
    box((-11,2,11,18), '#7b9994', 2)

def frame(t):
    sky = np.zeros((H,W,3), dtype=np.uint8)
    for y in range(H):
        a=y/H
        sky[y,:,:]=[int(9+30*a), int(19+18*a), int(33+14*a)]
    im=Image.fromarray(sky)
    d=ImageDraw.Draw(im)
    for x,y,r in STARS:
        c=int(150+50*math.sin(t*.25+x))
        d.ellipse((x-r,y-r,x+r,y+r),fill=(c,c,min(255,c+25)))
    if t<5.5:
        # Wide orbital establishing shot, approaching the red planet.
        r=370+t*10
        d.ellipse((W*.5-r,300-t*4,W*.5+r,300-t*4+r*2),fill='#b97859')
        d.arc((W*.5-r+25,325-t*4,W*.5+r-25,300-t*4+r*2),195,345,fill='#d9a07c',width=6)
        for i in range(15):
            x=(i*193)%860+30; y=390+(i*73)%150
            d.ellipse((x,y,x+50,y+14),fill='#9c624f')
        # Distant departing shuttle.
        x=670+t*10; y=125-t*3
        d.polygon([(x-34,y+8),(x+25,y),(x+11,y-12),(x-22,y-8)],fill='#e2ddc8')
        d.polygon([(x-30,y),(x-60-8*math.sin(t*17),y+2),(x-30,y+6)],fill='#f2ba90')
    else:
        # Slow dolly across the shelter after the storm.
        pan=20*math.sin((t-5.5)*.11)
        d.polygon([(0,345),(210,300),(380,338),(610,290),(960,332),(960,540),(0,540)],fill='#955d4c')
        d.polygon([(0,390),(290,345),(520,375),(800,340),(960,372),(960,540),(0,540)],fill='#bd8061')
        for i in range(24):
            x=(i*137)%980+pan; y=390+(i*53)%150
            d.ellipse((x,y,x+12+(i%4)*5,y+4),fill='#a46b53')
        x=650+pan
        d.ellipse((x-155,265,x+155,451),fill='#506871')
        d.ellipse((x-150,250,x+150,430),fill='#c6cdbd')
        d.rectangle((x-150,355,x+150,440),fill='#c6cdbd')
        d.rounded_rectangle((x-40,335,x+40,445),radius=17,fill='#395562')
        d.rounded_rectangle((x-26,350,x+26,400),radius=9,fill='#91b5b2')
        d.line((x-50,439,x+50,439),fill='#f2ba90',width=6)
        d.polygon([(x+190,375),(x+280,358),(x+302,400),(x+212,420)],fill='#577f99')
        d.line((x+244,410,x+244,448),fill='#a9b3a6',width=5)
        d.line((x-190,380,x-190,306),fill='#bdc8bc',width=6)
        d.arc((x-230,260,x-145,325),10,165,fill='#d5d7c4',width=12)
        astronaut(d,350+pan,390,1.0)
        d.ellipse((315+pan,450,390+pan,458),fill='#9b634f')
        if t>=11:
            # Radio pulse, then a hopeful signal arc above the habitat.
            for i in range(3):
                r=20+((t*18+i*28)%90)
                a=int(max(0,170-r))
                overlay=Image.new('RGBA',(W,H))
                od=ImageDraw.Draw(overlay)
                od.arc((x-190-r,280-r,x-190+r,280+r),205,335,fill=(183,216,191,a),width=3)
                im=Image.alpha_composite(im.convert('RGBA'),overlay).convert('RGB')
        if t<11:
            overlay=Image.new('RGBA',(W,H))
            od=ImageDraw.Draw(overlay)
            for i in range(85):
                px=(i*131-t*220)%1100-60; py=(i*71)%H
                od.line((px,py,px+60,py-6),fill=(225,174,130,55),width=2)
            im=Image.alpha_composite(im.convert('RGBA'),overlay).convert('RGB')
    # Dissolves between acts, fade in/out. Captions remain live UI for readability.
    fade=min(1,t/1.0,(SECONDS-t)/1.2)
    for cut in [5.5,11,16.5]: fade=min(fade,min(1,abs(t-cut)/.35))
    return Image.blend(Image.new('RGB',(W,H),'#07111c'),im,max(0,fade))

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--ffmpeg', required=True)
    args=parser.parse_args()
    target=ROOT/'assets/cinematics/intro.ogv'
    target.parent.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        audio=Path(tmp)/'score.wav'
        rate=22050
        t=np.arange(rate*SECONDS)/rate
        envelope=np.minimum(1,t/2)*np.minimum(1,(SECONDS-t)/2)
        sound=(np.sin(2*np.pi*55*t)*.12+np.sin(2*np.pi*110*t)*.07+np.sin(2*np.pi*164.81*t)*.04+np.sin(2*np.pi*220*t)*.025)*envelope
        for start in [11.5,12.5,13.5]:
            p=t-start
            sound+=np.sin(2*np.pi*740*p)*np.where((p>0)&(p<.14),.035,0)
        with wave.open(str(audio),'wb') as wav:
            wav.setnchannels(1); wav.setsampwidth(2); wav.setframerate(rate)
            wav.writeframes((sound*25000).astype('<i2').tobytes())
        cmd=[args.ffmpeg,'-y','-f','rawvideo','-pixel_format','rgb24','-video_size',f'{W}x{H}','-framerate',str(FPS),'-i','pipe:0','-i',str(audio),'-c:v','libtheora','-q:v','6','-pix_fmt','yuv420p','-c:a','libvorbis','-q:a','3','-shortest',str(target)]
        proc=subprocess.Popen(cmd,stdin=subprocess.PIPE)
        for i in range(FPS*SECONDS): proc.stdin.write(frame(i/FPS).tobytes())
        proc.stdin.close()
        if proc.wait(): raise RuntimeError('FFmpeg failed')
    frame(18).save(ROOT/'docs/intro-storyboard.png')
    print(target)

if __name__=='__main__': main()
