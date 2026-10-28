"""GYM ARC thumbnails from the Blender renders of the real character on a real Pro Gym capture (1920x1080)."""
import os
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(__file__))
from compose import BLACK, BOLD, GOLD, INK, LOGO, text_layer, place  # noqa: E402

HERE = os.path.dirname(__file__)
TOOL = r"C:/Users/kaung/.claude/projects/C--ObsidianOne-Claude-Obsidian/2aac7ed2-d2c1-47cd-a76c-5d2d3e15174b/tool-results/"
BG = TOOL + "mcp-Roblox_Studio-blob-1793203545761-bzn819.jpg"
OUT = sys.argv[1]
W, H = 1920, 1080


def background(shift_x=0):
    bg = Image.open(BG).convert("RGB")
    s = W / bg.width * 1.08
    bg = bg.resize((int(bg.width * s), int(bg.height * s)), Image.LANCZOS)
    left = (bg.width - W) // 2 + shift_x
    top = int(bg.height * 0.16)
    bg = bg.crop((left, top, left + W, top + H)).filter(ImageFilter.GaussianBlur(3.2))
    bg = Image.blend(bg, Image.new("RGB", (W, H), (8, 8, 12)), 0.32).convert("RGBA")
    # vignette
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).ellipse((-W * 0.12, -H * 0.25, W * 1.12, H * 1.25), fill=255)
    inv = ImageChops.invert(mask.filter(ImageFilter.GaussianBlur(170))).point(lambda v: int(v * 0.6))
    dark = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    dark.putalpha(inv)
    return Image.alpha_composite(bg, dark)


def alpha_box(img, x0=0, x1=None):
    a = img.getchannel("A").crop((x0, 0, x1 or img.width, img.height))
    box = a.point(lambda v: 255 if v > 40 else 0).getbbox()
    return (box[0] + x0, box[1], box[2] + x0, box[3]) if box else None


def glow_behind(canvas, char, color, strength=0.9, radius=60):
    a = char.getchannel("A").filter(ImageFilter.GaussianBlur(radius))
    g = Image.new("RGBA", char.size, color + (255,))
    g.putalpha(a.point(lambda v: int(v * strength)))
    canvas.alpha_composite(g)


def contact_shadow(canvas, box, depth=0.35):
    x0, _, x1, y1 = box
    w = x1 - x0
    sh = Image.new("L", (W, H), 0)
    ImageDraw.Draw(sh).ellipse((x0 + w * 0.06, y1 - w * 0.06, x1 - w * 0.06, y1 + w * 0.05), fill=int(255 * depth))
    sh = sh.filter(ImageFilter.GaussianBlur(w * 0.05))
    dark = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    dark.putalpha(sh)
    canvas.alpha_composite(dark)


def char_layer(path, scale=1.0, dx=0, dy=0):
    img = Image.open(path).convert("RGBA")
    if scale != 1.0:
        img = img.resize((int(W * scale), int(H * scale)), Image.LANCZOS)
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    layer.alpha_composite(img, (int(dx), int(dy)) if dx >= 0 and dy >= 0 else (0, 0))
    if dx < 0 or dy < 0:
        layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        layer.paste(img, (int(dx), int(dy)), img)
    return layer


def logo(canvas, width, at):
    lg = Image.open(LOGO).convert("RGBA")
    lg = lg.resize((width, int(lg.height * width / lg.width)), Image.LANCZOS)
    canvas.alpha_composite(lg, at)


def hero():
    canvas = background(shift_x=-20)
    char = char_layer(os.path.join(HERE, "renders", "render_hero.png"), 1.0, -40, 10)
    box = alpha_box(char)
    contact_shadow(canvas, box, 0.45)
    glow_behind(canvas, char, (255, 190, 70), 0.75, 70)
    canvas.alpha_composite(char)
    logo(canvas, 380, (50, 34))
    place(canvas, text_layer("GET", BLACK, 150, GOLD, 11, INK), 70, 430)
    place(canvas, text_layer("HUGE", BLACK, 210, GOLD, 13, INK), 60, 580)
    return canvas


def before_after():
    canvas = background(shift_x=0)
    char = char_layer(os.path.join(HERE, "renders", "render_before_after.png"), 1.0, 0, 20)
    a = char.getchannel("A")
    # the two figures (small left of the middle gap, big right)
    small_box = alpha_box(char, 0, 820)
    big_box = alpha_box(char, 820, W)
    contact_shadow(canvas, small_box, 0.4)
    contact_shadow(canvas, big_box, 0.45)
    big_only = char.copy()
    ImageDraw.Draw(big_only).rectangle((0, 0, 820, H), fill=(0, 0, 0, 0))
    glow_behind(canvas, big_only, (255, 190, 70), 0.8, 70)
    canvas.alpha_composite(char)
    logo(canvas, 300, (40, 26))
    # the heights over each one, an arrow between
    sx = (small_box[0] + small_box[2]) // 2
    bx = (big_box[0] + big_box[2]) // 2
    place(canvas, text_layer("4'0\"", BLACK, 96, (255, 255, 255), 9, (0, 0, 0)), sx, small_box[1] - 150, "mt")
    place(canvas, text_layer("7'0\"", BLACK, 112, GOLD, 10, INK), bx, 6, "mt")
    arrow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(arrow)
    mid = (small_box[2] + big_box[0]) // 2
    ay, half, head, shaft = int(H * 0.5), 105, 70, 30
    ax0, ax1 = mid - half, mid + half
    pts = [(ax0, ay - shaft), (ax1 - head, ay - shaft), (ax1 - head, ay - 72), (ax1, ay), (ax1 - head, ay + 72), (ax1 - head, ay + shaft), (ax0, ay + shaft)]
    d.polygon(pts, fill=INK + (255,))
    inner = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(inner).polygon([(x + (6 if x == ax0 else (-9 if x == ax1 else 0)), y + (6 if y < ay else (-6 if y > ay else 0))) for x, y in pts], fill=(242, 193, 78, 255))
    sh = arrow.getchannel("A").filter(ImageFilter.GaussianBlur(7))
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    shadow.putalpha(sh.point(lambda v: int(v * 0.6)))
    canvas.alpha_composite(ImageChops.offset(shadow, 5, 7))
    canvas.alpha_composite(arrow)
    canvas.alpha_composite(inner)
    return canvas


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    hero().convert("RGB").save(os.path.join(OUT, "GYMARC_thumb_get_huge.jpg"), quality=92)
    before_after().convert("RGB").save(os.path.join(OUT, "GYMARC_thumb_4ft_to_7ft.jpg"), quality=92)
    print("ok")
