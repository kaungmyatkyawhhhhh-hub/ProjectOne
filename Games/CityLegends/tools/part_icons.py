"""The Part Shop's icons as sharp white PNGs, 512 px, transparent (owner, 2026-11-06).
Source: imports/refs/ui/upgrades/part_icons_more_source.html (it holds all 65 drawn icons as SVG, the
other sheet's too). Adds the engine swap icon with its layout badge (I4, I6 ...). Edge draws them, then
each is cut from the sheet.
Run from Games/CityLegends: python tools/part_icons.py  -> build/parts/<key>.png"""
import re
import subprocess
from pathlib import Path

from PIL import Image

SRC = Path("imports/refs/ui/upgrades/part_icons_more_source.html")
OUT = Path("build/parts")
OUT.mkdir(parents=True, exist_ok=True)
EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
SIZE, COLS = 512, 8
LAYOUTS = ["I4", "I5", "I6", "V6", "V8", "V10", "R", "F4", "F6"]

text = SRC.read_text(encoding="utf-8")
js = text[text.index("const S="):text.index("const T=[")]
js = js.replace('font-family="Inter"', 'font-family="Segoe UI Black, Arial Black, Arial" ')
page = f"""<html><head><style>
html,body{{margin:0;background:transparent}}
#g{{display:grid;grid-template-columns:repeat({COLS},{SIZE}px);grid-auto-rows:{SIZE}px}}
svg{{display:block}}
</style></head><body><div id="g"></div><script>
{js}
for (const l of {LAYOUTS!r}) {{
  const size = l.length > 2 ? 24 : 30;
  I['swap_' + l] = I.swap + `<rect x="62" y="82" width="56" height="36" rx="9" fill="#ffd34d"/><text x="90" y="${{108 - (30 - size) / 3}}" font-family="Segoe UI Black, Arial Black, Arial" font-weight="900" font-size="${{size}}" fill="#1a1205" text-anchor="middle">${{l}}</text>`;
}}
const keys = Object.keys(I);
document.getElementById('g').innerHTML = keys.map(k => `<svg width="{SIZE}" height="{SIZE}" viewBox="0 0 120 120">${{I[k]}}</svg>`).join('');
document.title = keys.join(',');
const m = document.createElement('pre'); m.id = 'keys'; m.textContent = keys.join(','); m.style.display = 'none'; document.body.appendChild(m);
</script></body></html>"""
html = OUT / "icons.html"
html.write_text(page, encoding="utf-8")

keys = re.findall(r"^([A-Za-z]+):", js, re.M) + ["swap_" + l for l in LAYOUTS]
# (a key can only appear once in the object: a repeat keeps its first place)
keys = list(dict.fromkeys(keys))
rows = (len(keys) + COLS - 1) // COLS
sheet = OUT / "sheet.png"
subprocess.run([
    EDGE, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
    "--default-background-color=00000000", f"--window-size={COLS * SIZE},{rows * SIZE}",
    f"--screenshot={sheet.resolve()}", f"--user-data-dir={(OUT / 'edge').resolve()}",
    html.resolve().as_uri(),
], check=True, timeout=120)
img = Image.open(sheet).convert("RGBA")
print(img.size, len(keys), "icons")
for i, k in enumerate(keys):
    x, y = (i % COLS) * SIZE, (i // COLS) * SIZE
    img.crop((x, y, x + SIZE, y + SIZE)).save(OUT / f"{k}.png")
(OUT / "keys.txt").write_text("\n".join(keys), encoding="utf-8")
