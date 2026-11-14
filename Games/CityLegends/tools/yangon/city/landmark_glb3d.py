"""landmark_glb3d.py: material groups for real-geometry landmarks, and the export of a Geo (geom3d.py) to .glb packs.

GROUPS: code -> Roblox look. In Studio (LandmarkPlace3D.luau) every MeshPart named "<CODE>_<id>s<k>_<box>" gets that
group's Material, Color, Transparency, Reflectance, DoubleSided and CastShadow; no TextureID (owner, 2026-11-14:
"make myanmar plaza 3d, not with textures and decals").

export(geo, y0, out_glb, plane=None, ground_groups=(), tag="mc")
    model (x east, y north, z up) -> world: X = OX + x, Y = base + z, Z = OZ - y (a proper rotation: winding kept);
    base = y0, or the paving plane at that vertex for ground groups. Each group is split into meshes of at most
    MAX_TRIS triangles, named glb.code(CODE, "<tag>s<k>", centre, size). A Model of 150+ meshes fails to load, so packs
    of at most 90 meshes are written: out_glb, out_glb with _2, _3 ...
"""
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from glb import Mesh, write_glb, code, check_glb  # noqa: E402

OX, OZ = 32600.0, -1350.0
MAX_TRIS = 9000

# code: (Material, (r, g, b), transparency, reflectance, double_sided, cast_shadow)
GROUPS = {
    "GLA": ("Glass", (46, 60, 76), 0.0, 0.12, False, True),        # office glass (dark blue-grey, opaque)
    "GLB": ("Glass", (40, 62, 86), 0.0, 0.18, False, True),        # tower B glass (bluer)
    "GLP": ("Glass", (52, 62, 70), 0.0, 0.08, True, True),         # podium ribbon glass (seen from inside too)
    "GLL": ("Glass", (150, 146, 132), 0.0, 0.12, False, True),     # lobby glass with no interior behind (opaque, warm)
    "GLS": ("Glass", (176, 196, 204), 0.55, 0.05, True, False),     # see-through glass: shopfronts, entrances, skylight
    "SPA": ("Metal", (198, 170, 124), 0.0, 0.0, False, True),      # tower A spandrels (champagne)
    "SPB": ("Metal", (206, 208, 212), 0.0, 0.0, False, True),      # tower B spandrels (silver)
    "MUL": ("Metal", (84, 88, 94), 0.0, 0.0, False, True),         # dark mullions / frames
    "MUW": ("SmoothPlastic", (236, 234, 228), 0.0, 0.0, False, True),  # white frames, fascias, struts
    "GRN": ("Sandstone", (196, 178, 150), 0.0, 0.0, False, True),  # podium granite (Granite rendered near-black in game)
    "CRN": ("SmoothPlastic", (226, 214, 190), 0.0, 0.0, False, True),  # tower A crown (cream)
    "DRK": ("SmoothPlastic", (38, 40, 44), 0.0, 0.0, False, True),    # dark panels, skirts, reveals
    "CHR": ("SmoothPlastic", (58, 60, 64), 0.0, 0.0, False, True),    # charcoal screen wall
    "PGR": ("SmoothPlastic", (112, 46, 40), 0.0, 0.0, False, True),  # plinth maroon granite (Marble went black)
    "PBD": ("SmoothPlastic", (216, 206, 186), 0.0, 0.0, False, True),  # plinth cream band
    "ORG": ("SmoothPlastic", (246, 112, 30), 0.0, 0.0, False, True),   # orange letters
    "GLD": ("SmoothPlastic", (214, 186, 120), 0.0, 0.0, False, True),  # gold / cream small letters
    "WLT": ("SmoothPlastic", (246, 246, 244), 0.0, 0.0, False, True),  # white letters
    "RDL": ("SmoothPlastic", (170, 120, 60), 0.0, 0.0, False, True),   # bronze letters (Melia)
    "HDG": ("Grass", (64, 108, 44), 0.0, 0.0, False, True),         # clipped hedge
    "LAW": ("Grass", (104, 150, 66), 0.0, 0.0, False, False),       # lawn
    "PAV": ("Pavement", (124, 122, 116), 0.0, 0.0, False, False),   # plaza paving
    "ROF": ("Concrete", (150, 150, 146), 0.0, 0.0, False, False),   # flat roofs
    "SOL": ("Glass", (40, 54, 86), 0.0, 0.2, False, False),         # solar panels
    "MEL": ("SmoothPlastic", (238, 238, 234), 0.0, 0.0, False, True),  # Melia white
    "RES": ("SmoothPlastic", (228, 218, 198), 0.0, 0.0, False, True),  # Lake Suites cream
    "RAL": ("Glass", (200, 220, 228), 0.6, 0.05, True, False),      # glass balustrades
    "STL": ("Metal", (160, 162, 166), 0.0, 0.0, False, True),       # steel
    "STP": ("DiamondPlate", (96, 98, 104), 0.0, 0.0, False, True),  # escalator steps
    "MAR": ("Marble", (205, 198, 185), 0.0, 0.0, False, False),     # mall floors (cream speckled granite tiles)
    "CAR": ("SmoothPlastic", (165, 120, 70), 0.0, 0.0, False, False),  # caramel floor border at the shop fronts
    "GRD": ("Metal", (170, 150, 115), 0.0, 0.0, False, False),      # the atrium's beige-gold grid ceiling
    "CEL": ("SmoothPlastic", (240, 240, 236), 0.0, 0.0, False, False),  # ceilings, inner walls, partitions
    "LIT": ("Neon", (196, 182, 156), 0.0, 0.0, False, False),       # light panels / strips (toned down: full white bloomed in game)
    "SGN": ("SmoothPlastic", (30, 32, 36), 0.0, 0.0, False, True),   # shop sign bands
    "SH1": ("SmoothPlastic", (236, 206, 166), 0.0, 0.0, False, False),  # shop interiors (warm)
    "SH2": ("SmoothPlastic", (206, 218, 228), 0.0, 0.0, False, False),  # shop interiors (cool)
    "RED": ("SmoothPlastic", (196, 30, 36), 0.0, 0.0, False, True),  # red banners / boards
    "WAT": ("Glass", (64, 170, 210), 0.25, 0.1, False, False),      # pool water
    "EAV": ("SmoothPlastic", (88, 60, 46), 0.0, 0.0, False, True),  # dark brown eaves / fascias (Sedona)
    "TER": ("SmoothPlastic", (134, 86, 66), 0.0, 0.0, False, True),  # terracotta hip roofs (ClayRoofTiles rendered black: the map's override)
    "SED": ("SmoothPlastic", (236, 236, 230), 0.0, 0.0, False, True),  # Sedona Garden Wing white walls
    "SEW": ("Glass", (88, 124, 110), 0.0, 0.1, False, True),        # Sedona green-tinted windows
    "CRT": ("SmoothPlastic", (56, 120, 92), 0.0, 0.0, False, False),  # tennis court
    "CRM": ("SmoothPlastic", (216, 206, 184), 0.0, 0.0, False, True),  # Inya Wing cream cladding
    "GLU": ("Glass", (70, 100, 140), 0.0, 0.15, False, True),       # Inya Wing blue window glass
    "POL": ("SmoothPlastic", (150, 200, 220), 0.0, 0.0, False, False),  # pool tiles
    "TEN": ("SmoothPlastic", (164, 82, 60), 0.0, 0.0, False, False),  # tennis surround (red-brown)
    "FEN": ("DiamondPlate", (40, 58, 44), 0.55, 0.0, True, False),   # chain-link fence
    "DRV": ("Asphalt", (64, 64, 66), 0.0, 0.0, False, False),       # site drives
    "BLU": ("SmoothPlastic", (40, 62, 150), 0.0, 0.0, False, True),  # blue sign board
    "WOD": ("WoodPlanks", (150, 104, 70), 0.0, 0.0, True, True),    # timber (escalator cladding, the atrium cove)
}


def export(geo, y0, out_glb, plane=None, ground_groups=(), tag="mc"):
    named = []
    k = 0
    for grp in sorted(geo.g):
        if grp not in GROUPS:
            raise KeyError("unknown group " + grp)
        rgb = GROUPS[grp][1]
        tris = geo.g[grp]
        for start in range(0, len(tris), MAX_TRIS):
            m = Mesh()
            for a, b, c in tris[start:start + MAX_TRIS]:
                P = []
                for (x, y, z) in (a, b, c):
                    X, Z = OX + x, OZ - y
                    base = y0
                    if plane and grp in ground_groups:
                        base = plane[0] + plane[1] * (X - OX) + plane[2] * (Z - OZ)
                    P.append((X, base + z, Z))
                m.tri(P[0], P[1], P[2], (0.5, 0.5), (0.5, 0.5), (0.5, 0.5), rgb)
            if not m.T:
                continue
            k += 1
            lo, hi = m.box()
            c = [(lo[i] + hi[i]) / 2 for i in range(3)]
            s = [hi[i] - lo[i] for i in range(3)]
            named.append((code(grp, "%ss%d" % (tag, k), c, s), m))
    os.makedirs(os.path.dirname(out_glb), exist_ok=True)
    files = []
    for i in range(0, len(named), 90):
        path = out_glb if i == 0 else out_glb.replace(".glb", "_%d.glb" % (i // 90 + 1))
        info = write_glb(path, named[i:i + 90], generator="landmark_glb3d.py")
        n, bad = check_glb(path, info)
        files.append((path, n, sum(v["tris"] for v in info.values()), bad))
    return files


def collide_text(boxes, y0, plane=None, tag="mc"):
    """Boxes (cx, cy, z0, sx, sy, sz, yaw) in model coords -> YangonBuildingMeshes.collide data (one line)."""
    parts = []
    for cx, cy, z0, sx, sy, sz, yaw in boxes:
        X, Z = OX + cx, OZ - cy
        base = y0
        if plane:
            base = max(y0, plane[0] + plane[1] * (X - OX) + plane[2] * (Z - OZ)) if z0 <= 0.01 else y0
        parts.append("%.2f %.2f %.2f %.2f %.2f %.2f %.4f" % (X, base + z0 + sz / 2, Z, sx, sz, sy, yaw))
    return tag + "|" + "|".join(parts)


def groups_lua():
    """The group table as a Luau table literal (for the Studio placer)."""
    rows = []
    for k, (mat, rgb, tr, rf, ds, sh) in sorted(GROUPS.items()):
        rows.append('\t%s = { "%s", %d, %d, %d, %.2f, %.2f, %s, %s },' % (k, mat, rgb[0], rgb[1], rgb[2], tr, rf,
                                                                           "true" if ds else "false",
                                                                           "true" if sh else "false"))
    return "local GROUPS = {\n" + "\n".join(rows) + "\n}"


if __name__ == "__main__":
    print(groups_lua())
