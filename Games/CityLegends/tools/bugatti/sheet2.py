from PIL import Image, ImageDraw, ImageFont
T = "C:/Users/USER/.claude/jobs/a86b922d/tmp/bug/s2/"
V = "C:/Users/USER/ProjectOne/City Legends/"
H = 300
font = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 26)
small = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 20)
lut = [int(255 * (i / 255) ** 0.8) for i in range(256)]
def tile(fn):
    im = Image.open(T + fn).convert("RGB").point(lut * 3)
    return im.resize((int(im.width * H / im.height), H), Image.LANCZOS)
def sheet(rows, title, out):
    cols = ["Before: its own cluster", "After: shared cluster", "After: shared steering wheel"]
    tiles = [[tile(a), tile(b), tile(c)] for _, _, a, b, c in rows]
    widths = [max(r[i].width for r in tiles) for i in range(3)]
    pad, head, lab = 12, 70, 62
    S = Image.new("RGB", (sum(widths) + pad * 4, head + len(rows) * (H + lab + pad) + pad), (24, 24, 28))
    d = ImageDraw.Draw(S)
    d.text((pad, 10), title, font=font, fill=(255, 255, 255))
    x = pad
    for i, c in enumerate(cols):
        d.text((x, head - 26), c, font=small, fill=(200, 200, 200)); x += widths[i] + pad
    y = head + 4
    for (label, note, *_), r in zip(rows, tiles):
        d.text((pad, y), label, font=font, fill=(255, 210, 90)); d.text((pad, y + 32), note, font=small, fill=(220, 220, 220))
        x = pad; yy = y + lab
        for i in range(3):
            S.paste(r[i], (x, yy)); x += widths[i] + pad
        y = yy + H + pad
    S.save(out, quality=88)
sheet([
    ("Veyrun 16.4", "The donor: keeps its own cluster and wheel (needles go live in Step 3).", "v164_cluster.png", "v164_cluster.png", "v164_wheel.png"),
    ("Veyrun Super Sport", "The 16.4's sharp dial faces fitted onto its own dials (no painted needles); the 16.4's wheel.", "vss_before_cluster.png", "vss_after_cluster.png", "vss_after_wheel.png"),
    ("Veyrun Grand Sport Vitesse", "Same: the 16.4's dial faces and wheel. Its orange trim stays.", "vgsv_before_cluster.png", "vgsv_after_cluster.png", "vgsv_after_wheel.png"),
], "Step 2 - Veyron family: one cluster and one steering wheel for all 3", V + "Bugatti Step 2 - Veyron family shared cockpit.jpg")
sheet([
    ("Chiroun", "The donor: keeps its own screen and wheel (needle and screens go live in Step 3).", "ch_cluster.png", "ch_cluster.png", "ch_wheel.png"),
    ("Chiroun Pur Sport", "The Chiron's screen fitted where its own was (its blank screens removed); the Chiron's wheel in black leather.", "cps_before_cluster.png", "cps_after_cluster.png", "cps_after_wheel.png"),
    ("Chiroun Super Sport", "Same. Its lower hood hides the very top of the speedometer a little.", "css_before_cluster.png", "css_after_cluster.png", "css_after_wheel.png"),
], "Step 2 - Chiron family: one cluster and one steering wheel for all 3", V + "Bugatti Step 2 - Chiron family shared cockpit.jpg")
print("ok")
