"""side_by_side.py (2026-11-16): a reference photo next to an in-game screenshot, both scaled to one height, labels on top.

    python side_by_side.py out.jpg ref.jpg shot.jpg "left label" "right label"
"""
import sys

from PIL import Image, ImageDraw


def main():
    out, ref, shot, la, lb = sys.argv[1:6]
    H = 720
    ims = []
    for p in (ref, shot):
        im = Image.open(p).convert("RGB")
        im = im.resize((int(im.width * H / im.height), H))
        ims.append(im)
    W = ims[0].width + ims[1].width + 12
    canvas = Image.new("RGB", (W, H + 40), (24, 24, 26))
    canvas.paste(ims[0], (0, 40))
    canvas.paste(ims[1], (ims[0].width + 12, 40))
    d = ImageDraw.Draw(canvas)
    d.text((10, 12), la, fill=(240, 240, 240))
    d.text((ims[0].width + 22, 12), lb, fill=(240, 240, 240))
    canvas.save(out, quality=88)
    print(out, canvas.size)


if __name__ == "__main__":
    main()
