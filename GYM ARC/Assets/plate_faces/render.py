# Bakes each plate template's face SurfaceGui (rings + number + "M WEIGHTS" letters) into one 512 px PNG, 1:1 with the gui.
import json, math
from PIL import Image, ImageDraw, ImageFont
N = 512
d = json.load(open("plates.json"))
FONT = "Oswald-Bold.ttf"

def hexc(h, a=1.0):
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), int(round(255 * a)))

def fit_font(text, bw, bh):
    lo, hi = 1, 400
    while lo < hi:
        mid = (lo + hi + 1) // 2
        f = ImageFont.truetype(FONT, mid)
        asc, desc = f.getmetrics()
        w = f.getlength(text)
        if w <= bw and asc + desc <= bh: lo = mid
        else: hi = mid - 1
    return ImageFont.truetype(FONT, lo)

def render(face, canvas_px):
    img = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    k = N / canvas_px  # image px per gui px
    items = face["items"]
    # rings: a UIStroke on a round frame (stroke outside the frame's edge)
    for it in items:
        if it["class"] == "UIStroke":
            r = it["parentSize"] * N / 2
            t = it["thick"] * k
            layer = Image.new("RGBA", (N, N), (0, 0, 0, 0))
            dr = ImageDraw.Draw(layer)
            dr.ellipse([N / 2 - r - t, N / 2 - r - t, N / 2 + r + t, N / 2 + r + t], outline=hexc(it["color"], 1 - it["T"]), width=max(1, round(t)))
            img = Image.alpha_composite(img, layer)
    for it in items:
        if it["class"] != "TextLabel" or it["text"] == "": continue
        bw, bh = it["size"][0] * N, it["size"][1] * N
        if bw < 4 or bh < 4: continue  # (the 5 plate's numbers are 1 px in game: invisible)
        f = fit_font(it["text"], bw, bh)
        asc, desc = f.getmetrics()
        w = f.getlength(it["text"])
        pad = 8
        box = Image.new("RGBA", (int(math.ceil(max(bw, w))) + 2 * pad, int(math.ceil(max(bh, asc + desc))) + 2 * pad), (0, 0, 0, 0))
        dr = ImageDraw.Draw(box)
        x = (box.width - w) / 2
        y = (box.height - (asc + desc)) / 2
        alpha = 1 - it.get("strokeT", 1)
        if alpha > 0.01:  # text stroke (1 gui px)
            sw = max(1, round(k))
            dr.text((x, y), it["text"], font=f, fill=(0, 0, 0, 0), stroke_width=sw, stroke_fill=(0, 0, 0, int(255 * alpha)))
        dr.text((x, y), it["text"], font=f, fill=hexc(it["color"], 1 - it.get("T", 0)))
        box = box.rotate(-it["rot"], resample=Image.BICUBIC, expand=True)
        cx, cy = it["pos"][0] * N, it["pos"][1] * N
        img.alpha_composite(box, (int(round(cx - box.width / 2)), int(round(cy - box.height / 2))))
    return img

for t in d["templates"]:
    face = next(f for f in t["faces"] if f["face"] == "FaceRight")
    canvas_px = face["size"][0] * face["pps"]
    img = render(face, canvas_px)
    img.save(f"face_{t['name']}.png")
    # preview over the plate's own colour
    body = next(p for p in t["parts"] if p["name"] == "Body")
    prev = Image.new("RGBA", (N, N), (40, 40, 44, 255))
    dr = ImageDraw.Draw(prev)
    dr.ellipse([0, 0, N, N], fill=hexc(body["color"]))
    prev.alpha_composite(img)
    prev.convert("RGB").save(f"preview_{t['name']}.png")
    print(t["name"], "canvas", round(canvas_px), "px")
