"""Render card.html with card_params.json at his card's exact frame position and print the differences."""
import json, subprocess, os
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REF = os.path.join(HERE, '..', 'video', 'big', 't_348.jpg')
BOX = (740, 25, 965, 300)
CHROME = r'C:\Program Files\Google\Chrome\Application\chrome.exe'

P = json.load(open(os.path.join(HERE, 'card_params.json')))
open(os.path.join(HERE, 'card_params.js'), 'w').write('window.P = ' + json.dumps(P) + ';')
out = os.path.join(HERE, 'card_exact.png')
subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--virtual-time-budget=6000',
                '--window-size=1280,720', f'--screenshot={out}', 'file:///' + os.path.join(HERE, 'card.html').replace('\\', '/')],
               capture_output=True)
his = Image.open(REF).convert('RGB'); ours = Image.open(out).convert('RGB')
hx = lambda c: '#%02X%02X%02X' % c

def bb(im, test, x0, y0, x1, y1):
    pts = [(x, y) for x in range(x0, x1) for y in range(y0, y1) if test(im.getpixel((x, y)))]
    return (min(p[0] for p in pts), min(p[1] for p in pts), max(p[0] for p in pts), max(p[1] for p in pts)) if pts else None
green = lambda p: p[1] > 150 and p[0] < 150 and p[2] < 100
white = lambda p: sum(p) > 720
dark = lambda p: sum(p) < 120
for name, t, b in (('pill green', green, (760, 180, 946, 280)), ('title white', white, (762, 45, 944, 95)),
                   ('price white', white, (820, 200, 940, 250)), ('card dark L/R', dark, (745, 140, 960, 160)),
                   ('card dark T/B', dark, (775, 25, 785, 300))):
    print(f'{name:14} his {bb(his, t, *b)}  ours {bb(ours, t, *b)}')
if P['mode'] == 'his':
    tot = 0
    for x in (770, 935):
        for y in range(48, 284, 12):
            a, b = his.getpixel((x, y)), ours.getpixel((x, y)); d = sum(abs(a[i] - b[i]) for i in range(3)); tot += d
            print(f'  x{x} y{y} his {hx(a)} ours {hx(b)} {d}{"  <--" if d > 90 else ""}')
    print('colour gap total', tot)
side = Image.new('RGB', ((BOX[2] - BOX[0]) * 2 + 6, BOX[3] - BOX[1]), (40, 40, 40))
side.paste(his.crop(BOX), (0, 0)); side.paste(ours.crop(BOX), (BOX[2] - BOX[0] + 6, 0))
side.resize((side.width * 2, side.height * 2)).save(os.path.join(HERE, 'card_side.png'))
