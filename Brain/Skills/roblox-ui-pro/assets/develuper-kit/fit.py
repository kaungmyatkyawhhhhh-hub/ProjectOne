"""Render exact.html with params.json, line it up on his frame, and print the measured differences.
Usage: python -I fit.py   (reads params.json, writes params.js, exact.png, side.png, diff.png)"""
import json, subprocess, os, sys
from PIL import Image, ImageChops

HERE = os.path.dirname(os.path.abspath(__file__))
REF = os.path.join(HERE, '..', 'video', 'big', 't_266.jpg')
BOX = (110, 280, 860, 520)          # his button in frame px
CHROME = r'C:\Program Files\Google\Chrome\Application\chrome.exe'

P = json.load(open(os.path.join(HERE, 'params.json')))
open(os.path.join(HERE, 'params.js'), 'w').write('window.P = ' + json.dumps(P) + ';')
out = os.path.join(HERE, 'exact.png')
subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--virtual-time-budget=6000',
                '--window-size=1280,720', f'--screenshot={out}', 'file:///' + os.path.join(HERE, 'exact.html').replace('\\', '/')],
               capture_output=True)

his = Image.open(REF).convert('RGB').crop(BOX)
ours = Image.open(out).convert('RGB').crop(BOX)
hx = lambda c: '#%02X%02X%02X' % c

def box(im, test, xr, yr):
    xs = [x for x in xr for y in yr[::2] if test(im.getpixel((x - BOX[0], y - BOX[1])))]
    ys = [y for y in yr for x in xr[::2] if test(im.getpixel((x - BOX[0], y - BOX[1])))]
    return (min(xs), min(ys), max(xs), max(ys)) if xs else None

white = lambda p: sum(p) > 740
dark = lambda p: sum(p) < 150
print('text white  his', box(his, white, range(175, 640), range(300, 466)), ' ours', box(ours, white, range(175, 640), range(300, 466)))
print('text dark   his', box(his, dark, range(150, 645), range(300, 466)), ' ours', box(ours, dark, range(150, 645), range(300, 466)))
print('icon white  his', box(his, white, range(650, 830), range(300, 466)), ' ours', box(ours, white, range(650, 830), range(300, 466)))
print('icon dark   his', box(his, dark, range(650, 830), range(300, 470)), ' ours', box(ours, dark, range(650, 830), range(300, 470)))
for x in (140, 820):
    print(f'column x={x}:')
    for y in range(286, 512, 6):
        a, b = his.getpixel((x - BOX[0], y - BOX[1])), ours.getpixel((x - BOX[0], y - BOX[1]))
        print(f'  {y} his {hx(a)} ours {hx(b)} {"<--" if sum(abs(a[i]-b[i]) for i in range(3)) > 90 else ""}')

side = Image.new('RGB', (his.width, his.height * 2 + 6), (40, 40, 40))
side.paste(his, (0, 0)); side.paste(ours, (0, his.height + 6)); side.save(os.path.join(HERE, 'side.png'))
d = ImageChops.difference(his, ours).convert('L').point(lambda v: 255 if v > 40 else 0)
print('pixels differing >40:', f'{sum(1 for v in d.getdata() if v) / (d.width * d.height):.1%}')
red = Image.blend(his, Image.new('RGB', his.size, (255, 0, 0)), 0.0)
red.paste((255, 0, 0), mask=d); red.save(os.path.join(HERE, 'diff.png'))
