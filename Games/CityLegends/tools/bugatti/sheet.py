from PIL import Image, ImageDraw, ImageFont, ImageOps
import sys
T = "C:/Users/USER/.claude/jobs/a86b922d/tmp/bug/rp/"
H = 330
font = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 26)
small = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 20)
def bright(im):
    # lift the dark cabins so the dials show (gamma), keep colours
    lut = [int(255 * (i / 255) ** 0.55) for i in range(256)]
    return im.convert("RGB").point(lut * 3)
def tile(path, lift):
    im = Image.open(path).convert("RGB")
    if lift: im = bright(im)
    w = int(im.width * H / im.height)
    return im.resize((w, H), Image.LANCZOS)
def sheet(rows, title, out):
    tiles = [[tile(T + f"{cid}_front34.png", False), tile(T + f"{cid}_cluster.png", True), tile(T + f"{cid}_wheel.png", True)] for cid, _, _ in rows]
    widths = [max(r[c].width for r in tiles) for c in range(3)]
    pad, head, lab = 12, 60, 64
    W = sum(widths) + pad * 4
    Ht = head + len(rows) * (H + lab + pad) + pad
    S = Image.new("RGB", (W, Ht), (24, 24, 28))
    d = ImageDraw.Draw(S)
    d.text((pad, 14), title, font=font, fill=(255, 255, 255))
    x = pad
    for c, name in enumerate(["Car", "Cluster (brightened)", "Steering wheel (brightened)"]):
        d.text((x, head - 26 + 4), name, font=small, fill=(200, 200, 200)); x += widths[c] + pad
    y = head + 6
    for (cid, label, note), r in zip(rows, tiles):
        d.text((pad, y), label, font=font, fill=(255, 210, 90))
        d.text((pad, y + 32), note, font=small, fill=(220, 220, 220))
        yy = y + lab
        x = pad
        for c in range(3):
            S.paste(r[c], (x, yy)); x += widths[c] + pad
        y = yy + H + pad
    S.save(out, quality=88)
V = "C:/Users/USER/ProjectOne/City Legends/"
sheet([
    ("veyron164", "Veyron 16.4 (2009)  ->  Veyrun 16.4", "PICK. Real modelled dials (sharp 1024 px, needles are parts). Good wheel, separate part. 790k triangles. Doors separate."),
    ("veyronss", "Veyron Super Sport (2010)  ->  Veyrun Super Sport", "Flat painted dials, small (512 px), needles + logos painted on. Plain low-detail wheel, big logo."),
    ("veyrongsv", "Veyron Grand Sport Vitesse WRC (2013)  ->  Veyrun Grand Sport Vitesse", "Same flat painted dials as the Super Sport (orange trim). Same plain wheel. 'WRC' = orange/black livery."),
], "Veyron family: clusters and steering wheels", V + "Bugatti clusters - Veyron family.jpg")
sheet([
    ("chiron", "Chiron (2016)  ->  Chiroun", "PICK. Real Chiron cluster: 500 km/h dial + both side screens (512 px, needle + logo painted on). Best wheel. Doors separate."),
    ("chironps", "Chiron Pur Sport (2021)  ->  Chiroun Pur Sport", "Speedometer only, side screens blank black (512 px atlas). Plain wheel."),
    ("chironss", "Chiron Super Sport (2022)  ->  Chiroun Super Sport", "Tiny cluster picture (256 px): blurry, side screens blank. Wheel OK but logo is a pixel picture."),
], "Chiron family: clusters and steering wheels", V + "Bugatti clusters - Chiron family.jpg")
print("ok")
