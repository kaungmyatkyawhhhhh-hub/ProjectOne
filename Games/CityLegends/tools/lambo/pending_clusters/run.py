"""run.py <name> [preview|overlay|assets|lua]: builds one car's Spec with tools/lambo/cluster_live.py's own pieces (copies in
lib/ if that folder is here, else the real tools/lambo modules, imported only: nothing in the repo is changed), composes it
standing and driving the way cluster_live.py's preview does, and writes "<Game name> cluster - photo and redraw.jpg"
(photo over redraw, standing left, driving right).
overlay: also <z>/<name>_overlay.jpg (redraw at 50 % over the photo) and <z>/<name>_stand.png (big); <z> is $CLUSTER_Z or
z/ here.
assets: the upload pictures into assets/<name>/; lua: the Luau table into assets/<name>/<name>.lua (a check that it
serialises).
Names: e92, f82, gt3rs (2026-11-10, previews written here) and every cluster_<name>.py with a PREVIEW_INFO dict
(the JDM clusters of 2026-11-14: game name, photo, states, preview file; previews written to "City Legends/")."""
import os
import sys

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(HERE, "lib")
if not os.path.isdir(LIB):
    LIB = os.path.normpath(os.path.join(HERE, ".."))  # tools/lambo itself (only imported)
sys.path.insert(0, LIB)
sys.path.insert(0, HERE)
REFS = "C:/Users/USER/ProjectOne/Games/CityLegends/imports/refs"
OWNER_DIR = "C:/Users/USER/ProjectOne/City Legends"
import cluster_art  # noqa: E402

cluster_art.REFS = REFS
import cluster_live as L  # noqa: E402

L.REFS = REFS
L.HERE = HERE  # masked() / spec_lua() read window_<name>.png from here
from PIL import Image, ImageDraw  # noqa: E402


def _paste_any(out, im, x, y):
    """alpha_composite that also takes a sprite starting left of / above the picture (the game draws those too: a
    needle whose pivot sits at the panel's edge)"""
    if x < 0 or y < 0:
        im = im.crop((max(0, -x), max(0, -y), im.width, im.height))
        x, y = max(0, x), max(0, y)
    if im.width > 0 and im.height > 0 and x < out.width and y < out.height:
        out.alpha_composite(im, (x, y))


def _compose():
    """cluster_live.compose with its paste clamp replaced by _paste_any (a copy: cluster_live.py itself is not changed)"""
    import inspect

    src = inspect.getsource(L.compose)
    old = "out.alpha_composite(im2, (max(0, round(left * scale)), max(0, round(top * scale))))"
    if old not in src:
        return L.compose
    ns = dict(L.__dict__)
    ns["_paste_any"] = _paste_any
    exec(src.replace(old, "_paste_any(out, im2, round(left * scale), round(top * scale))"), ns)
    return ns["compose"]


compose = _compose()

GAME = {"e92": "E92 V8", "f82": "F82", "gt3rs": "Stuttgart 991.2 Track"}
REF = {"e92": "e92_m3_cluster_owner.png", "f82": "f82_m4_cluster_owner.png", "gt3rs": "gt3rs_9912_cluster_owner.png"}
STATES = {
    "e92": [dict(v=0.0, gear="N", mph=0, manual=False, clock="10:57", odo="067528", distUnit="km", kmh=True, trip="200.2", fuel=0.0),
            dict(v=5.0, gear="3", mph=49.7, manual=False, clock="10:57", odo="067541", distUnit="km", kmh=True, trip="213.4", fuel=0.62)],
    "f82": [dict(v=0.9, gear="N", mph=0, manual=False, clock="10:57", odo="003230", distUnit="km", kmh=True, trip="525.3", fuel=0.27, date="02.05.2014", lights=True),
            dict(v=5.0, gear="3", mph=49.7, manual=False, clock="10:57", odo="003242", distUnit="km", kmh=True, trip="537.6", fuel=0.40, date="02.05.2014")],
    "gt3rs": [dict(v=0.0, gear="N", mph=0, manual=False, clock="09:58", odo="014848", distUnit="km", kmh=True, trip="182.3", fuel=0.0),
              dict(v=5.0, gear="3", mph=49.7, manual=False, clock="09:58", odo="014861", distUnit="km", kmh=True, trip="195.6", fuel=0.55)],
}


def module(name):
    return __import__("cluster_" + name)


def info(name):
    """(game name, photo, states, preview path) for a builder"""
    if name in GAME:
        return GAME[name], REF[name], STATES[name], os.path.join(HERE, "%s cluster - photo and redraw.jpg" % GAME[name])
    pi = module(name).PREVIEW_INFO
    return pi["game"], pi["photo"], pi["states"], os.path.join(OWNER_DIR, pi.get("out", "%s cluster - photo and redraw.jpg" % pi["game"]))


def build(name):
    fn = getattr(module(name), name)
    sp = fn(L.Spec, L.needle_sprite, L.add_needle, L.glyph, L.solid_gear)
    sp.build_fonts()
    return sp


def render(sp, st, k):
    im = compose(sp, st, scale=k)
    win = os.path.join(HERE, "window_%s.png" % sp.name)
    if os.path.exists(win):
        m = Image.open(win).convert("L").resize(im.size, Image.LANCZOS)
        im = Image.composite(im, Image.new("RGB", im.size, (60, 60, 64)), m)
    return im


def label(st):
    kmh_unit = st.get("kmh", True)
    spd = round(st["mph"] * 1.609) if kmh_unit else round(st["mph"])
    return "%s: %d %s, %d rpm, gear %s" % ("standing" if st["mph"] < 1 else "driving", spd, "km/h" if kmh_unit else "mph", int(st["v"] * 1000), "P" if st["gear"] == "N" else st["gear"])


def main():
    name = sys.argv[1]
    what = sys.argv[2] if len(sys.argv) > 2 else "preview"
    sp = build(name)
    if what in ("assets", "lua"):
        d = os.path.join(HERE, "assets", name)
        os.makedirs(d, exist_ok=True)
        if what == "assets":
            L.write_assets(sp, d)
        else:
            t, sheets = L.spec_lua(sp, {})
            open(os.path.join(d, name + ".lua"), "w", encoding="utf-8").write("return {\n" + "\n".join(t) + "\n}\n")
            print("lua lines", len(t), "sheets", len(sheets))
        return
    game, ref, states, out = info(name)
    photo = Image.open(os.path.join(REFS, ref)).convert("RGB")
    box = (sp.ox, sp.oy, sp.ox + sp.W, sp.oy + sp.H)
    Wcol = 1200
    k = Wcol / sp.W
    ph = photo.crop(tuple(int(round(v)) for v in box)).resize((Wcol, round(sp.H * k)), Image.LANCZOS)
    ims = [render(sp, st, k) for st in states]
    gap, lab = 14, 26
    S = Image.new("RGB", (Wcol * 2 + gap, lab + ph.height + gap + lab + ims[0].height), (60, 60, 64))
    d = ImageDraw.Draw(S)
    for i, (im, st) in enumerate(zip(ims, states)):
        x = i * (Wcol + gap)
        S.paste(ph, (x, lab))
        S.paste(im, (x, lab + ph.height + gap + lab))
        d.text((x + 6, 6), "photo (%s)" % ref, fill=(255, 255, 0))
        d.text((x + 6, lab + ph.height + gap + 6), "redraw, " + label(st), fill=(255, 255, 0))
    S.save(out, quality=93)
    print("wrote", out, S.size, "pieces", len(sp.blocks), len(sp.shows), len(sp.readouts), len(sp.needles), "bg", sp.bg.size)
    if what == "overlay":
        z = os.environ.get("CLUSTER_Z", os.path.join(HERE, "z"))
        os.makedirs(z, exist_ok=True)
        k2 = 2400 / sp.W
        big = compose(sp, states[0], scale=k2)
        ph2 = photo.crop(tuple(int(round(v)) for v in box)).resize(big.size, Image.LANCZOS)
        Image.blend(ph2, big, 0.5).save(os.path.join(z, name + "_overlay.jpg"), quality=92)
        big.save(os.path.join(z, name + "_stand.png"))
        compose(sp, states[1], scale=k2).save(os.path.join(z, name + "_drive.png"))
        ph2.save(os.path.join(z, name + "_photo.png"))


if __name__ == "__main__":
    main()
