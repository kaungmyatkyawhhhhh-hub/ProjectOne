import math
from PIL import Image, ImageDraw
import aura2 as A
N = 1024; S = 2; W = N * S
cols = [(40,120,235),(235,40,200),(255,215,20),(80,200,50),(150,70,235),(255,145,20),(30,200,240),(230,50,60)]
labels = ['CASH','x2 STR','+1 SPIN','BIG CASH','x2 CASH','+1 LEVEL','MEGA CASH','JACKPOT']
def wheel(with_text=False):
    im = Image.new('RGBA', (W, W), (0,0,0,0)); d = ImageDraw.Draw(im); c = W/2
    d.ellipse((0,0,W-1,W-1), fill=(20,16,24)); d.ellipse((W*.025,)*2+(W*.975,)*2, fill=(255,210,20))
    r0 = (W*.06, W*.06, W*.94, W*.94)
    n = len(cols); step = 360/n
    for i, col in enumerate(cols):            # slice i centred on the top pointer when wheel rotation = -i*45
        a0 = -90 - step/2 + i*step
        d.pieslice(r0, a0, a0 + step, fill=col)
    for i in range(n):                          # divider lines exactly on the slice edges
        a = math.radians(-90 - step/2 + i*step)
        d.line((c, c, c + W*.44*math.cos(a), c + W*.44*math.sin(a)), fill=(20,16,24), width=int(W*.012))
    d.ellipse((c-W*.12,)*2+(c+W*.12,)*2, fill=(20,16,24)); d.ellipse((c-W*.105,)*2+(c+W*.105,)*2, fill=(255,210,20))
    im = im.resize((N, N), Image.LANCZOS)
    if with_text:
        for i, t in enumerate(labels):
            lay = Image.new('RGBA', (N, N), (0,0,0,0))
            fs = 46 if len(t) <= 7 else 38
            A.stroke_text(lay, (N/2 + N*.285, N/2), t, fs, (255,255,255), (235,235,240), anchor='mm')
            im.alpha_composite(lay.rotate(90 - i*step, resample=Image.BICUBIC))
    return im
wheel().save('wheel-base.png'); wheel(True).save('wheel-preview.png')
