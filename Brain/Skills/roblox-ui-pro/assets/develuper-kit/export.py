"""Export every kit piece from kitgen.html (and icons.html) as its own transparent PNG at 2x, under 1024 px.
Usage: python -I export.py [names...]"""
import os, re, subprocess, sys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SKIN = os.environ.get('SKIN', '')  # SKIN=neon -> kitgen.html?skin=neon, written to export_neon/
OUT = os.path.join(HERE, 'export' + ('_' + SKIN if SKIN else '')); os.makedirs(OUT, exist_ok=True)
CHROME = r'C:\Program Files\Google\Chrome\Application\chrome.exe'
S, M = 2, 6

def dims(page):
    """Read the PIECES / ICONS table sizes straight from the page source so the two never drift."""
    src = open(os.path.join(HERE, page), encoding='utf8').read()
    return {n: (int(w), int(h)) for n, w, h in re.findall(r"^\s+(\w+):\s*\[(\d+),\s*(\d+),", src, re.M)}

def render(page, name, w, h):
    W, H = (w + 2 * M) * S, (h + 2 * M) * S
    assert W <= 1024 and H <= 1024, f'{name} is {W}x{H}, over 1024'
    out = os.path.join(OUT, name + '.png')
    subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--default-background-color=00000000',
                    '--virtual-time-budget=4000', f'--window-size={W},{H}', f'--screenshot={out}',
                    'file:///' + os.path.join(HERE, page).replace('\\', '/') + ('?skin=' + SKIN if SKIN else '') + '#' + name], capture_output=True)
    im = Image.open(out)
    assert im.size == (W, H), (name, im.size)
    assert im.getchannel('A').getextrema()[0] == 0, f'{name}: background not transparent'
    return W, H

want = set(sys.argv[1:])
for page in ('kitgen.html', 'icons.html', 'hud.html'):
    if not os.path.exists(os.path.join(HERE, page)):
        continue
    d = dims(page)
    if page == 'hud.html': d.update({f'port{i}': (64, 70) for i in range(1, 13)})  # built in a loop, so not in the table text
    for name, (w, h) in d.items():
        if want and name not in want:
            continue
        print(name, *render(page, name, w, h))
