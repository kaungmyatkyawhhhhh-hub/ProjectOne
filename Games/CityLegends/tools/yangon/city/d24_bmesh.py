"""d24_bmesh.py plots.json [outdir] [--prefix name] [--glbdir dir] [--atlas atlas.json]: the Yangon mesh buildings, cell by cell, as .glb packs for Studio.

INPUT: a JSON list of plot records (one per building):
  {
    "id": str,                       unique (OSM "w123" / "r456", or an infill id)
    "poly": [[x, z], ...],           the outline in world studs, counter-clockwise seen from above (north = -Z),
                                     NOT closed, 3+ points; real OSM outlines (concave and near-circular are fine)
    "y": float,                      ground height at the base in studs (lowest ground under the outline, from the
                                     Studio probe); may be missing before the probe (then 0, and a warning)
    "floors": int,                   ground floor 12 studs, each upper floor 9 (game scale, YangonBuildings.luau:39)
    "style": "walkup"|"shophouse"|"house"|"shed"|"mass"|"tower"|"round"|"villa"|"hall",
    "roof": "flat"|"gable"|"hip"|"shed",
    "roof_colour": [r, g, b],        0-255; multiplies the roof rows (corrugated or concrete)
    "wall_colour": [r, g, b],        0-255; multiplies the wall rows (drawn near white)
    "front": int or null,            index of the polygon edge (poly[i] -> poly[i+1]) that faces the street
    "shop": bool,                    ground-floor shopfront (roller shutters, open shops, a sign band) on the front edge
    "name": str or null
  }

OUTPUT in outdir (default build/ygn_bmesh/; the .glb files in --glbdir, default imports/sync/ygn_bmesh/: Open Cloud
uploads only from the owner-approved imports/ folder, and imports/sync/ is gitignored):
  <prefix>_<n>.glb   at most 100 meshes / 90,000 triangles a file (a Model of 150+ meshes fails to load). Each mesh is a
                     node named  KIND_CELL_cx_cy_cz_sx_sy_sz  (hundredths of a stud, "n" = minus; export_fbx.py style):
                     KIND F = walls (shadows on), R = roofs and props, G = the night windows (a see-through copy of
                     the window walls 0.08 in front, shown at night only); CELL = "<i>x<j>" of the 256-stud cell
                     (i = floor(x / 256), j = floor(z / 256), "n" = minus) plus "s<k>" when a mesh over 17,000 triangles
                     was split. Positions are relative to the box centre with x and z negated (glb.py), so in Studio:
                     Size from the name, CFrame = CFrame.new(centre) (no half turn; checked in the pilot).
  manifest.json      {files: [{glb, meshes: [{name, cell, kind, tris, buildings}]}], cells, totals, styles}
  Collide_<n>.luau   `return [==[ ... ]==]`, one line a building: `id|x y z sx sy sz yaw|...` (a box: centre, size,
                     yaw for CFrame.Angles(0, yaw, 0)), each module under 190,000 characters.
Then in Studio: tools/yangon/YangonBuildingMeshes.luau (place, collide; see its header).
"""
import json
import math
import os
import sys
from collections import Counter, defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from glb import Mesh, write_glb, check_glb, code  # noqa: E402
from shells import Context, build_plot  # noqa: E402

CELL = 256.0
MAX_TRIS = 17000
FILE_TRIS = 90000
FILE_MESHES = 100
COLLIDE_CHARS = 190000


def cell_id(i, j):
    f = lambda v: ("n%d" % -v) if v < 0 else str(v)
    return "%sx%s" % (f(i), f(j))


def main():
    args = [a for i, a in enumerate(sys.argv) if i > 0 and not a.startswith("--") and not sys.argv[i - 1].startswith("--")]
    opts = {sys.argv[i]: sys.argv[i + 1] for i in range(1, len(sys.argv) - 1) if sys.argv[i].startswith("--")}
    src = args[0]
    out = args[1] if len(args) > 1 else os.path.join(HERE, "..", "..", "..", "build", "ygn_bmesh")
    prefix = opts.get("--prefix", "ygn_bmesh")
    # the .glb packs go where Open Cloud may upload from (the owner approved imports/; imports/sync/ is gitignored)
    glbdir = opts.get("--glbdir", os.path.join(HERE, "..", "..", "..", "imports", "sync", "ygn_bmesh"))
    os.makedirs(out, exist_ok=True)
    os.makedirs(glbdir, exist_ok=True)
    plots = json.load(open(src, encoding="utf-8"))
    apath = opts.get("--atlas", os.path.join(out, "atlas.json"))
    if not os.path.exists(apath):
        apath = os.path.join(HERE, "..", "..", "..", "build", "ygn_bmesh", "atlas.json")
    atlas = json.load(open(apath))
    ctx = Context(plots, atlas)
    noy = sum(1 for p in plots if "y" not in p)
    if noy:
        print("WARNING: %d plots have no y (ground height): built at y = 0" % noy)
    cells = defaultdict(list)  # cell -> [(plot, F, R)]
    collide = []
    styles = defaultdict(list)
    skipped = 0
    # duplicates: OSM often holds the same building twice (an old and a new way); keep the first, drop any outline that
    # lies mostly inside one already kept (they would z-fight)
    import shapely
    from shapely.geometry import Polygon
    kept, kept_polys, dupes = [], [], []
    for p in sorted(plots, key=lambda q: -Polygon(q["poly"]).buffer(0).area):
        g = Polygon(p["poly"]).buffer(0)
        hit = None
        if kept_polys and not g.is_empty:
            tree = shapely.STRtree(kept_polys)
            for j in tree.query(g, predicate="intersects"):
                inter = g.intersection(kept_polys[j]).area
                if inter > 0.5 * min(g.area, kept_polys[j].area):
                    hit = j
                    break
        if hit is None:
            kept.append(p)
            kept_polys.append(g)
        else:
            dupes.append(p["id"])
    if dupes:
        print("dropped %d overlapping duplicates: %s" % (len(dupes), " ".join(dupes[:20])))
    plots = kept
    ctx = Context(plots, atlas)
    for p in plots:
        F, R, G, boxes, info = build_plot(p, ctx)
        if info["skipped"]:
            skipped += 1
            continue
        xs = [q[0] for q in p["poly"]]
        zs = [q[1] for q in p["poly"]]
        cx, cz = sum(xs) / len(xs), sum(zs) / len(zs)
        cells[(math.floor(cx / CELL), math.floor(cz / CELL))].append((p, F, R, G, cx))
        styles[info["style"] + ("/" + info["roof"] if info["roof"] != "flat" else "")].append((F.tris + R.tris, G.tris))
        collide.append(str(p["id"]) + "|" + "|".join(" ".join(("%g" % v) for v in b) for b in boxes))
    # meshes per cell and kind, split by buildings (sorted along x) past MAX_TRIS
    meshes = []
    for (i, j), items in sorted(cells.items()):
        items.sort(key=lambda t: t[4])
        for kind, k in (("F", 1), ("R", 2), ("G", 3)):
            groups, cur, n = [], [], 0
            for it in items:
                t = it[k].tris
                if cur and n + t > MAX_TRIS:
                    groups.append(cur)
                    cur, n = [], 0
                cur.append(it)
                n += t
            if cur:
                groups.append(cur)
            for gi, g in enumerate(groups):
                m = Mesh()
                for it in g:
                    m.extend(it[k])
                if not m.T:
                    continue
                cid = cell_id(i, j) + ("s%d" % gi if len(groups) > 1 else "")
                meshes.append(dict(kind=kind, cell=cell_id(i, j), cid=cid, mesh=m, buildings=len(g)))
    # pack into files
    files, cur, n = [], [], 0
    for me in meshes:
        if cur and (len(cur) >= FILE_MESHES or n + me["mesh"].tris > FILE_TRIS):
            files.append(cur)
            cur, n = [], 0
        cur.append(me)
        n += me["mesh"].tris
    if cur:
        files.append(cur)
    manifest = dict(files=[], cells=len(cells), skipped=skipped)
    tot = Counter()
    for fi, group in enumerate(files):
        named = []
        for me in group:
            lo, hi = me["mesh"].box()
            c = [(lo[k] + hi[k]) / 2 for k in range(3)]
            s = [hi[k] - lo[k] for k in range(3)]
            me["name"] = code(me["kind"], me["cid"], c, s)
            named.append((me["name"], me["mesh"]))
        path = os.path.join(glbdir, "%s_%d.glb" % (prefix, fi + 1))
        info = write_glb(path, named)
        nm, bad = check_glb(path, info)
        assert not bad and nm == len(named), (path, bad)
        manifest["files"].append(dict(glb=os.path.basename(path), bytes=os.path.getsize(path),
                                      meshes=[dict(name=me["name"], cell=me["cell"], kind=me["kind"], tris=me["mesh"].tris,
                                                   buildings=me["buildings"]) for me in group]))
        for me in group:
            tot[me["kind"]] += me["mesh"].tris
            tot["meshes"] += 1
    manifest["totals"] = dict(tot, buildings=len(plots) - skipped, files=len(files))
    manifest["styles"] = {k: dict(n=len(v), avg=round(sum(a for a, b in v) / len(v)), max=max(a for a, b in v),
                                  night=round(sum(b for a, b in v) / len(v))) for k, v in sorted(styles.items())}
    json.dump(manifest, open(os.path.join(out, "manifest.json"), "w"), indent=1)
    # collision modules
    mods, cur = [], ""
    for line in collide:
        if len(cur) + len(line) + 1 > COLLIDE_CHARS - 40:
            mods.append(cur)
            cur = ""
        cur += line + "\n"
    if cur:
        mods.append(cur)
    for k, s in enumerate(mods):
        with open(os.path.join(out, "Collide_%d.luau" % (k + 1)), "w", newline="\n") as fh:  # LF: CRLF would pass 190k
            fh.write("return [==[\n" + s + "]==]\n")
    print("buildings %d (skipped %d) in %d cells -> %d meshes in %d files; F %d tris, R %d tris, G (night) %d tris; collide %d modules"
          % (len(plots) - skipped, skipped, len(cells), tot["meshes"], len(files), tot["F"], tot["R"], tot["G"], len(mods)))
    for k, v in manifest["styles"].items():
        print("  %-14s n %4d  avg %5d  max %5d  night +%d" % (k, v["n"], v["avg"], v["max"], v["night"]))


if __name__ == "__main__":
    main()
