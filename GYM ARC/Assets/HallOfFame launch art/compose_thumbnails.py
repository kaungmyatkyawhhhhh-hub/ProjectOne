"""Composes GYM ARC's Hall of Fame launch thumbnails (1920x1080) and icon (512x512) from real Studio captures."""
import math
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageChops

TOOL = r"C:/Users/kaung/.claude/projects/C--ObsidianOne-Claude-Obsidian/2aac7ed2-d2c1-47cd-a76c-5d2d3e15174b/tool-results/"
STORE = r"C:/Users/kaung/AppData/Local/Temp/claude/C--ObsidianOne-Claude-Obsidian/2aac7ed2-d2c1-47cd-a76c-5d2d3e15174b/scratchpad/store/"
OUT = sys.argv[1] if len(sys.argv) > 1 else STORE + "out/"
FONTS = r"C:/Users/kaung/AppData/Local/Roblox/Versions/version-5a21b87bbc2641cf/content/fonts/"
BLACK = FONTS + "Montserrat-Black.ttf"
BOLD = FONTS + "Montserrat-Bold.ttf"
LOGO = STORE + "asset_86034269506160.png"

W, H = 1920, 1080
GOLD = [(255, 243, 196), (242, 193, 78), (201, 138, 18)]
INK = (42, 30, 8)


def gradient_fill(size, stops):
    """A vertical gradient image (RGBA) through the colour stops."""
    w, h = size
    img = Image.new("RGBA", size)
    px = img.load()
    for y in range(h):
        t = y / max(1, h - 1)
        seg = min(int(t * (len(stops) - 1)), len(stops) - 2)
        lt = t * (len(stops) - 1) - seg
        a, b = stops[seg], stops[seg + 1]
        c = tuple(int(a[i] + (b[i] - a[i]) * lt) for i in range(3)) + (255,)
        for x in range(w):
            px[x, y] = c
    return img


def text_layer(text, font_path, size, fill_stops, stroke, stroke_color, shear=0.2, shadow=True):
    """The game's title look: heavy font, faux italic, gold gradient face, dark outline, soft drop shadow."""
    font = ImageFont.truetype(font_path, size)
    pad = stroke * 2 + 20
    l, t, r, b = font.getbbox(text, stroke_width=stroke)
    w, h = r - l + pad * 2, b - t + pad * 2
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).text((pad - l, pad - t), text, font=font, fill=255)
    outline = Image.new("L", (w, h), 0)
    ImageDraw.Draw(outline).text((pad - l, pad - t), text, font=font, fill=255, stroke_width=stroke, stroke_fill=255)
    face = gradient_fill((w, h), fill_stops) if isinstance(fill_stops, list) else Image.new("RGBA", (w, h), fill_stops + (255,))
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    if shadow:
        sh = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        sh.putalpha(outline.filter(ImageFilter.GaussianBlur(stroke * 1.2)).point(lambda v: int(v * 0.7)))
        layer = Image.alpha_composite(layer, ImageChops.offset(sh, int(stroke * 0.6), int(stroke * 0.9)))
    ol = Image.new("RGBA", (w, h), stroke_color + (255,))
    ol.putalpha(outline)
    layer = Image.alpha_composite(layer, ol)
    face.putalpha(mask)
    layer = Image.alpha_composite(layer, face)
    # faux italic (the game's display font is Montserrat Black Italic)
    if shear:
        extra = int(h * shear)
        layer = layer.transform((w + extra, h), Image.AFFINE, (1, shear, -extra, 0, 1, 0), resample=Image.BICUBIC)
    return layer


def load_base(name, box=None):
    img = Image.open(TOOL + name).convert("RGB")
    if box is None:
        iw, ih = img.size
        ch = int(iw * 9 / 16)
        top = (ih - ch) // 2
        box = (0, top, iw, top + ch)
    img = img.crop(box).resize((W, H), Image.LANCZOS)
    img = img.filter(ImageFilter.UnsharpMask(radius=2, percent=55, threshold=2))
    return img.convert("RGBA")


def shade_top(img, height_frac=0.42, strength=0.55):
    """A soft dark band at the top so the words read on any sky."""
    band = Image.new("L", (1, H), 0)
    for y in range(H):
        t = 1 - y / (H * height_frac)
        band.putpixel((0, y), int(255 * strength * max(0.0, t) ** 1.6))
    band = band.resize((W, H))
    dark = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    dark.putalpha(band)
    return Image.alpha_composite(img, dark)


def vignette(img, strength=0.35):
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).ellipse((-W * 0.15, -H * 0.2, W * 1.15, H * 1.25), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(160))
    inv = ImageChops.invert(mask).point(lambda v: int(v * strength))
    dark = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    dark.putalpha(inv)
    return Image.alpha_composite(img, dark)


def paste_logo(img, width, at):
    logo = Image.open(LOGO).convert("RGBA")
    h = int(logo.height * width / logo.width)
    logo = logo.resize((width, h), Image.LANCZOS)
    img.alpha_composite(logo, at)
    return img


def place(img, layer, x, y, anchor="lt"):
    w, h = layer.size
    if anchor[0] == "m":
        x -= w // 2
    elif anchor[0] == "r":
        x -= w
    img.alpha_composite(layer, (int(x), int(y)))


def thumb_before():
    img = load_base("mcp-Roblox_Studio-blob-1793196924955-1tt6ay.jpg", (0, 66, 1089, 678))
    img = vignette(shade_top(img, 0.40, 0.55), 0.3)
    paste_logo(img, 360, (44, 30))
    place(img, text_layer("OPENS SATURDAY", BLACK, 104, GOLD, 9, INK), W - 40, 30, "rt")
    place(img, text_layer("THE HALL OF FAME", BOLD, 50, (255, 255, 255), 6, (0, 0, 0), 0.18), W - 60, 168, "rt")
    return img


def thumb_after_night():
    img = load_base("mcp-Roblox_Studio-blob-1793196754645-tv919t.jpg", (0, 40, 1089, 652))
    img = vignette(shade_top(img, 0.36, 0.45), 0.3)
    paste_logo(img, 360, (44, 30))
    place(img, text_layer("HALL OF FAME", BLACK, 118, GOLD, 10, INK), W - 40, 26, "rt")
    place(img, text_layer("NOW OPEN", BOLD, 56, (255, 255, 255), 6, (0, 0, 0), 0.18), W - 64, 178, "rt")
    return img


def thumb_after_day():
    # the real launch cutscene frame (its own NOW OPEN / HALL OF FAME words); the letterbox bars cropped off
    img = load_base("mcp-Roblox_Studio-blob-1793192085442-xuefgw.jpg", (26, 74, 1063, 657))
    paste_logo(img, 300, (40, 26))
    return img


def icon_accent():
    """The current icon with a launch accent: a gold Hall of Fame star medal (no words), inside the rounded-corner safe area."""
    base = Image.open(STORE + "icon.png").convert("RGBA").resize((512, 512), Image.LANCZOS)
    S = 4  # supersampled
    size = 512 * S
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    cx, cy, r = 392 * S, 390 * S, 74 * S
    # glow
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((cx - r * 1.5, cy - r * 1.5, cx + r * 1.5, cy + r * 1.5), fill=(255, 200, 80, 150))
    glow = glow.filter(ImageFilter.GaussianBlur(26 * S))
    layer = Image.alpha_composite(layer, glow)
    d = ImageDraw.Draw(layer)
    d.ellipse((cx - r - 7 * S, cy - r - 7 * S, cx + r + 7 * S, cy + r + 7 * S), fill=INK + (255,))
    disc = gradient_fill((2 * r, 2 * r), [(255, 236, 170), (242, 193, 78), (176, 112, 10)])
    m = Image.new("L", (2 * r, 2 * r), 0)
    ImageDraw.Draw(m).ellipse((0, 0, 2 * r - 1, 2 * r - 1), fill=255)
    disc.putalpha(m)
    layer.alpha_composite(disc, (cx - r, cy - r))
    d = ImageDraw.Draw(layer)
    d.ellipse((cx - r * 0.82, cy - r * 0.82, cx + r * 0.82, cy + r * 0.82), outline=(120, 74, 6, 255), width=4 * S)
    # the star
    pts = []
    for i in range(10):
        ang = -math.pi / 2 + i * math.pi / 5
        rr = r * (0.62 if i % 2 == 0 else 0.26)
        pts.append((cx + rr * math.cos(ang), cy + rr * math.sin(ang)))
    shadow = [(x + 3 * S, y + 4 * S) for x, y in pts]
    d.polygon(shadow, fill=(110, 66, 4, 200))
    d.polygon(pts, fill=(255, 250, 230, 255), outline=INK + (255,))
    layer = layer.resize((512, 512), Image.LANCZOS)
    return Image.alpha_composite(base, layer)


def star_points(cx, cy, r_out, r_in, rot=0.0):
    pts = []
    for i in range(10):
        ang = -math.pi / 2 + rot + i * math.pi / 5
        rr = r_out if i % 2 == 0 else r_in
        pts.append((cx + rr * math.cos(ang), cy + rr * math.sin(ang)))
    return pts


def icon_stars():
    """The current icon with the Hall of Fame accent: three gold stars in an arc over his head (the owner's HoF art
    motif), a warm glow behind them. No words; nothing in the corners."""
    art = Image.open(STORE + "icon.png").convert("RGBA").resize((512, 512), Image.LANCZOS)
    # the picture moves down DROP px (the shorts' hem goes off the bottom); the space above is the art's own bright
    # ceiling, stretched and softened, for the stars
    DROP = 70
    base = Image.new("RGBA", (512, 512))
    top = art.crop((0, 0, 512, 40)).resize((512, DROP + 40), Image.BICUBIC).filter(ImageFilter.GaussianBlur(6))
    base.paste(top, (0, 0))
    fade = Image.new("L", (512, 512 - DROP), 255)
    ImageDraw.Draw(fade).rectangle((0, 0, 512, 24), fill=0)
    fade = fade.filter(ImageFilter.GaussianBlur(10))
    lowered = art.crop((0, 0, 512, 512 - DROP))
    base.paste(lowered, (0, DROP), fade)
    S = 4
    size = 512 * S
    stars = [(256, 48, 38, 0.0), (180, 66, 26, -0.22), (332, 66, 26, 0.22)]
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for x, y, r, _ in stars:
        gd.ellipse(((x - r * 1.6) * S, (y - r * 1.6) * S, (x + r * 1.6) * S, (y + r * 1.6) * S), fill=(255, 205, 90, 170))
    glow = glow.filter(ImageFilter.GaussianBlur(18 * S))
    layer = Image.alpha_composite(Image.new("RGBA", (size, size), (0, 0, 0, 0)), glow)
    for x, y, r, rot in stars:
        cx, cy, ro = x * S, y * S, r * S
        outer = star_points(cx, cy, ro + 7 * S, (ro + 7 * S) * 0.46, rot)
        mask_o = Image.new("L", (size, size), 0)
        ImageDraw.Draw(mask_o).polygon(outer, fill=255)
        ink = Image.new("RGBA", (size, size), INK + (255,))
        ink.putalpha(mask_o)
        # drop shadow
        sh = Image.new("RGBA", (size, size), (0, 0, 0, 255))
        sh.putalpha(mask_o.filter(ImageFilter.GaussianBlur(5 * S)).point(lambda v: int(v * 0.55)))
        layer = Image.alpha_composite(layer, ImageChops.offset(sh, 3 * S, 5 * S))
        layer = Image.alpha_composite(layer, ink)
        inner = star_points(cx, cy, ro, ro * 0.46, rot)
        mask_i = Image.new("L", (size, size), 0)
        ImageDraw.Draw(mask_i).polygon(inner, fill=255)
        box = (int(cx - ro), int(cy - ro), int(cx + ro), int(cy + ro))
        grad = gradient_fill((box[2] - box[0], box[3] - box[1]), [(255, 246, 200), (246, 200, 84), (196, 128, 12)])
        face = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        face.paste(grad, box[:2])
        face.putalpha(ImageChops.multiply(mask_i, face.getchannel("A")))
        layer = Image.alpha_composite(layer, face)
        # a shine on the upper-left arm
        shine = Image.new("L", (size, size), 0)
        ImageDraw.Draw(shine).polygon([inner[0], inner[9], (cx, cy)], fill=120)
        hl = Image.new("RGBA", (size, size), (255, 255, 255, 255))
        hl.putalpha(ImageChops.multiply(shine, mask_i))
        layer = Image.alpha_composite(layer, hl)
    layer = layer.resize((512, 512), Image.LANCZOS)
    return Image.alpha_composite(base, layer)


def preview_sheet(paths, out):
    """How they look small on a phone's Home row: each thumbnail at 300 px wide, the icon at 150 px."""
    thumbs = [Image.open(p).convert("RGB").resize((300, 169), Image.LANCZOS) for p in paths["thumbs"]]
    icons = [Image.open(p).convert("RGB").resize((150, 150), Image.LANCZOS) for p in paths["icons"]]
    sheet = Image.new("RGB", (20 + 320 * len(thumbs), 20 + 189 + 170), (24, 24, 28))
    for i, t in enumerate(thumbs):
        sheet.paste(t, (20 + i * 320, 20))
    for i, ic in enumerate(icons):
        sheet.paste(ic, (20 + i * 170, 20 + 189))
    sheet.save(out, quality=90)


if __name__ == "__main__":
    import os
    os.makedirs(OUT, exist_ok=True)
    thumb_before().convert("RGB").save(OUT + "GYMARC_thumb_HallOfFame_opens_saturday.jpg", quality=92)
    thumb_after_night().convert("RGB").save(OUT + "GYMARC_thumb_HallOfFame_now_open_night.jpg", quality=92)
    thumb_after_day().convert("RGB").save(OUT + "GYMARC_thumb_HallOfFame_now_open_day.jpg", quality=92)
    icon_stars().save(OUT + "GYMARC_icon_HallOfFame.png")
    preview_sheet({
        "thumbs": [OUT + "GYMARC_thumb_HallOfFame_opens_saturday.jpg", OUT + "GYMARC_thumb_HallOfFame_now_open_night.jpg",
            OUT + "GYMARC_thumb_HallOfFame_now_open_day.jpg", STORE + "thumb1.png"],
        "icons": [STORE + "icon.png", OUT + "GYMARC_icon_HallOfFame.png"],
    }, STORE + "preview_small.jpg")
    for f in sorted(os.listdir(OUT)):
        print(f, os.path.getsize(OUT + f) // 1024, "KB")
