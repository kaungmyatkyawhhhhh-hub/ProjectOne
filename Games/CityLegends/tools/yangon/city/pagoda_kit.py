"""Pagoda generator, step 2 (2026-11-16): the shared stupa kit (pure Python, glb.py writer, no Blender).

One parametric Burmese zedi, made from the Kaba Aye pieces (tools/yangon/landmarks3d/kaba_aye_blender.py: bell profile,
moulding steps, ringed cone + lotus petal rows, banana bud, hti tiers with mast, vane and orb) but scaled to a base width W
instead of Kaba Aye's platform, and built in 5 size classes x 6 pieces = 30 unique meshes. Every pagoda in the city is a
copy of its class's pieces, scaled (MeshPart.Size) and turned in Studio.

Pieces per class (each its own mesh, so a pagoda's colour scheme is set per piece in Studio):
  BASE_sq / BASE_oct / BASE_rd   terraces (square / octagonal / round, per the real footprint) + 3 round moulding rings
  BELL                           the bell (khaung laung) + its two rings + the inverted bowl and ringed cone
  TOP                            lotus petal rows (kya hmauk / kya lan) + banana bud (hnget pyaw bu)
  HTI                            the hti: 3-7 umbrella tiers, mast, vane, orb (always gold)

Proportions (W = base width, the top of the hti at H = 1.9 W). A typical Yangon zedi is 1.6-2.2 x its base width tall
(Kaba Aye's bell 10 m on 34 m; Botataung 40 m on ~20 m bell; small monastery zedi 6-8 m on 3.5-4 m bases); 1.9 is the
middle. The placer scales Y on its own when a real height is known (OSM height, Wikipedia), so H/W can vary per pagoda.
  terraces   0     -> 0.30   half-width 0.50 -> 0.37 (the steps between them are the terrace walks)
  mouldings  0.30  -> 0.48   3 round rings r 0.31 / 0.285 / 0.26
  bell       0.48  -> 0.90   r 0.25 -> 0.115 (Kaba Aye's BELL_PROF, normalised)
  bowl/cone  0.90  -> 1.22   8 rings (Kaba Aye's ringed cone)
  lotus      1.22  -> 1.38   2 petal rows (3 on L / XL)
  bud        1.38  -> 1.55
  hti        1.55  -> 1.90
Units: the mesh is written at its class's reference width in studs (REF_W); the placer scales by real W / REF_W.
Ground y = 0 at the base; the lowest terrace has a skirt down to -0.05 W so a pagoda on a slope shows no gap.
No bottoms, no faces under the next piece (each piece sits on the open top of the one below: no coplanar pair, no flicker).
UVs: box projection, 1 UV unit = 1 stud at the reference size.

    python pagoda_kit.py            -> imports/sync/pagodas/pagoda_kit.glb + build/pagodas/pagoda_kit.json (offsets, tris)
"""
import json, math, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from glb import Mesh, write_glb  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
GLB = os.path.join(ROOT, 'imports', 'sync', 'pagodas', 'pagoda_kit.glb')
JSN = os.path.join(ROOT, 'build', 'pagodas', 'pagoda_kit.json')

H_RATIO = 1.9
# class: (max base width m, reference width studs, round segments, terraces, lotus rows, hti tiers)
CLASSES = {
    'XS': (5.0, 9.0, 12, 1, 1, 3),
    'S': (12.0, 24.0, 16, 2, 2, 4),
    'M': (25.0, 54.0, 24, 3, 2, 5),
    'L': (45.0, 105.0, 32, 3, 3, 6),
    'XL': (1e9, 180.0, 48, 4, 3, 7),
}
BOWL_RINGS = {'XS': 3, 'S': 4, 'M': 6, 'L': 7, 'XL': 7}
SHAPES = {'sq': 4, 'oct': 8, 'rd': None}
WHITE = (255, 255, 255)  # vertex colour white: the MaterialVariant / Color does the colour (a tint would pull it off)

# Kaba Aye bell profile (r, z) from kaba_aye_blender.BELL_PROF: base r 5.0 at z 13.0 -> r 1.52 at z 20.57
_KB = [(5.0, 13.0), (5.0, 13.2), (4.92, 13.6), (4.79, 14.06), (4.64, 14.59), (4.43, 15.12), (4.34, 15.65), (4.16, 16.18),
       (3.85, 16.72), (3.53, 17.26), (3.17, 17.8), (2.72, 18.35), (2.42, 18.9), (2.05, 19.46), (1.82, 20.01), (1.52, 20.57)]


def bell_prof():
    """Kaba Aye's bell mapped to r 0.25 -> 0.115 over z 0.48 -> 0.90 (in W units)."""
    r0, r1 = _KB[0][0], _KB[-1][0]
    z0, z1 = _KB[0][1], _KB[-1][1]
    out = []
    for r, z in _KB:
        t = (r - r1) / (r0 - r1)
        out.append((0.115 + t * (0.25 - 0.115), 0.48 + (z - z0) / (z1 - z0) * 0.42))
    return out


def uv(p):
    return (p[0], p[2])


class Lathe:
    """Revolved surfaces into a glb Mesh (y up). Polygon shapes = revolve with n segments, turned so sides face the axes."""

    def __init__(s, mesh, scale):
        s.m, s.k = mesh, scale

    def ring(s, r, y, segs, phase):
        k = s.k
        return [(r * k * math.cos(phase + 2 * math.pi * j / segs), y * k, r * k * math.sin(phase + 2 * math.pi * j / segs))
                for j in range(segs)]

    def revolve(s, prof, segs, phase=0.0, smooth=False, rmod=None):
        """prof [(r, y)] bottom -> top, outward faces. r 0 = a point (cone tip)."""
        rings = []
        for i, (r, y) in enumerate(prof):
            ring = s.ring(r, y, segs, phase)
            if rmod:
                ring = [(p[0] * rmod(i, j), p[1], p[2] * rmod(i, j)) for j, p in enumerate(ring)]
            rings.append(ring)
        for i in range(len(prof) - 1):
            A, B = rings[i], rings[i + 1]
            nrm = None
            for j in range(segs):
                j2 = (j + 1) % segs
                a, b, c, d = A[j], A[j2], B[j2], B[j]
                if smooth:
                    nrm = [s._n(prof, i, j, segs, phase), s._n(prof, i, j2, segs, phase),
                           s._n(prof, i + 1, j2, segs, phase), s._n(prof, i + 1, j, segs, phase)]
                # seen from outside: a (j, low) -> d (j, high) -> c (j2, high) -> b (j2, low) is CCW (j grows CCW from +y)
                if prof[i][0] == 0:
                    s.m.tri(a, d, c, uv(a), uv(d), uv(c), WHITE, None if not nrm else (nrm[0], nrm[3], nrm[2]))
                elif prof[i + 1][0] == 0:
                    s.m.tri(a, d, b, uv(a), uv(d), uv(b), WHITE, None if not nrm else (nrm[0], nrm[3], nrm[1]))
                else:
                    s.m.quad(a, d, c, b, uv(a), uv(d), uv(c), uv(b), WHITE, None if not nrm else (nrm[0], nrm[3], nrm[2], nrm[1]))

    def _n(s, prof, i, j, segs, phase):
        r0, y0 = prof[max(0, i - 1)]
        r1, y1 = prof[min(len(prof) - 1, i + 1)]
        dr, dy = r1 - r0, y1 - y0
        nr, ny = dy, -dr
        L = math.hypot(nr, ny) or 1.0
        nr, ny = nr / L, ny / L
        t = phase + 2 * math.pi * j / segs
        return (nr * math.cos(t), ny, nr * math.sin(t))

    def cap(s, r, y, segs, phase=0.0, up=True):
        """a flat disc / polygon facing up (fan from the middle)."""
        ring = s.ring(r, y, segs, phase)
        c = (0.0, y * s.k, 0.0)
        for j in range(segs):
            a, b = ring[j], ring[(j + 1) % segs]
            if up:
                s.m.tri(c, b, a, uv(c), uv(b), uv(a), WHITE)
            else:
                s.m.tri(c, a, b, uv(c), uv(a), uv(b), WHITE)


def poly_r(apothem, n):
    return apothem / math.cos(math.pi / n)


def base_piece(cls, shape):
    """terraces in the real footprint's shape + 3 round moulding rings. Each step's top is the ring between it and the next."""
    _, refw, segs, nter, _, _ = CLASSES[cls]
    m = Mesh()
    L = Lathe(m, refw)
    n = SHAPES[shape] or segs
    phase = math.pi / n if SHAPES[shape] else 0.0  # flats square to the axes
    rr = (lambda a: poly_r(a, n)) if SHAPES[shape] else (lambda a: a)
    halfs = [0.50 - (0.50 - 0.37) * k / max(1, nter - 1) for k in range(nter)] if nter > 1 else [0.50]
    hs = 0.30 / nter
    skirt = -0.05
    prof = []
    for k, a in enumerate(halfs):
        y0 = skirt if k == 0 else k * hs
        y1 = (k + 1) * hs
        lip = min(0.012, hs * 0.15)
        prof += [(rr(a), y0), (rr(a), y1 - lip), (rr(a + 0.008), y1 - lip * 0.5), (rr(a), y1)]
        nxt = halfs[k + 1] if k + 1 < len(halfs) else None
        if nxt is not None:
            prof.append((rr(nxt), y1))
    L.revolve(prof, n, phase)
    # top of the last terrace: a flat cap (the round mouldings stand on it, open-bottomed, so no face lies on it)
    L.cap(rr(halfs[-1]), 0.30, n, phase)
    # 3 round moulding rings, each with a small lip, stepping in to the bell
    mr = [(0.31, 0.30, 0.36), (0.285, 0.36, 0.42), (0.26, 0.42, 0.48)]
    prof = []
    for k, (r, y0, y1) in enumerate(mr):
        prof += [(r, y0), (r, y1 - 0.012), (r + 0.006, y1 - 0.006), (r - 0.004, y1)]
        nxt = mr[k + 1][0] if k + 1 < len(mr) else 0.25
        prof.append((nxt, y1))
    L.revolve(prof, segs, 0.0)
    return m


def bell_piece(cls):
    _, refw, segs, _, _, _ = CLASSES[cls]
    m = Mesh()
    L = Lathe(m, refw)
    bp = bell_prof()
    if segs <= 16:  # small classes: every second profile point
        bp = bp[:2] + bp[2:-1:2] + bp[-1:]
    L.revolve(bp, segs, 0.0, smooth=True)
    # two thin rings proud of the bell (Kaba Aye's double line and the leaf ring), each its own short band
    def r_at(z):
        for (r0, z0), (r1, z1) in zip(bp, bp[1:]):
            if z0 <= z <= z1 and z1 > z0:
                return r0 + (r1 - r0) * (z - z0) / (z1 - z0)
        return bp[-1][0]
    for zc, h in ((0.60, 0.012), (0.70, 0.016)):
        z0, z1 = zc - h / 2, zc + h / 2
        out = 0.006
        L.revolve([(r_at(z0) - 0.002, z0), (r_at(z0) + out, z0 + h * 0.2), (r_at(z1) + out, z1 - h * 0.2), (r_at(z1) - 0.002, z1)], segs)
    # inverted bowl (thabeik) + ringed cone: 8 rings from r 0.115 at 0.90 to 0.075 at 1.22
    prof = [(0.115, 0.90), (0.125, 0.915), (0.125, 0.95), (0.105, 0.965)]
    z, r = 0.965, 0.100
    nr = BOWL_RINGS[cls]
    dz = 0.252 / nr
    for k in range(nr):
        prof += [(r, z), (r + 0.007, z + dz * 0.22), (r + 0.007, z + dz * 0.72), (r - 0.003, z + dz)]
        z += dz
        r -= 0.0245 / nr
    prof.append((0.075, 1.22))
    L.revolve(prof, max(12, segs * 2 // 3), 0.0)
    return m


def top_piece(cls):
    _, refw, segs, _, rows, _ = CLASSES[cls]
    m = Mesh()
    L = Lathe(m, refw)
    s2 = max(12, segs * 2 // 3)
    z, r = 1.22, 0.075
    prof = []
    petal = []
    dz = 0.16 / rows
    for k in range(rows):  # lotus petal rows: each bulges out and in, petals by an 8-lobe radius change
        prof += [(r, z), (r + 0.012, z + dz * 0.15), (r + 0.006, z + dz * 0.8)]
        petal.append(len(prof) - 2)
        z += dz
        r -= 0.006
    prof.append((r, 1.38))
    # banana bud: swells then closes to the hti's foot
    prof += [(r + 0.005, 1.42), (r - 0.004, 1.49), (0.040, 1.55)]
    lobes = 8 if s2 >= 16 else 4

    def rmod(i, j):
        if i in petal:
            ph = 0.5 if petal.index(i) % 2 else 0.0
            return 1.0 + 0.10 * abs(math.cos(math.pi * lobes * (j + ph) / s2))
        return 1.0
    L.revolve(prof, s2, 0.0, rmod=rmod)
    return m


def hti_piece(cls):
    _, refw, segs, _, _, tiers = CLASSES[cls]
    m = Mesh()
    L = Lathe(m, refw)
    s3 = max(8, segs // 2)
    z = 1.55
    prof = [(0.040, z), (0.036, z + 0.01)]
    z += 0.01
    core = 0.030
    span = (1.80 - z) / tiers
    for i in range(tiers):  # umbrella tiers, widest at the bottom
        rt = 0.075 - i * (0.050 / max(1, tiers - 1))
        prof += [(core, z), (rt, z + span * 0.12), (rt, z + span * 0.28), (core * 0.85, z + span)]
        z += span
        core *= 0.85
    prof += [(0.008, z), (0.006, 1.86), (0.016, 1.865), (0.017, 1.875), (0.010, 1.885), (0.003, 1.89), (0.0, 1.90)]
    L.revolve(prof, s3, 0.0)
    # vane: a flat flag on the mast (two faces, back to back would z-fight, so a thin slab)
    k = refw
    y0, y1 = 1.835, 1.855
    t = 0.0015
    x0, x1 = 0.006, 0.05
    pts = [(x0, y0), (x1, y0 + 0.004), (x1 * 0.95, y1 - 0.002), (x0, y1)]
    front = [(px * k, py * k, t * k) for px, py in pts]
    back = [(px * k, py * k, -t * k) for px, py in pts]
    m.quad(front[0], front[1], front[2], front[3], uv(front[0]), uv(front[1]), uv(front[2]), uv(front[3]), WHITE)
    m.quad(back[3], back[2], back[1], back[0], uv(back[3]), uv(back[2]), uv(back[1]), uv(back[0]), WHITE)
    for i in range(4):
        a, b = front[i], front[(i + 1) % 4]
        c, d = back[(i + 1) % 4], back[i]
        m.quad(a, d, c, b, uv(a), uv(d), uv(c), uv(b), WHITE)
    return m


def build():
    named = []
    for cls in CLASSES:
        for sh in SHAPES:
            named.append(('PG_%s_BASE_%s' % (cls, sh), base_piece(cls, sh)))
        named.append(('PG_%s_BELL' % cls, bell_piece(cls)))
        named.append(('PG_%s_TOP' % cls, top_piece(cls)))
        named.append(('PG_%s_HTI' % cls, hti_piece(cls)))
    return named


def main():
    named = build()
    os.makedirs(os.path.dirname(GLB), exist_ok=True)
    os.makedirs(os.path.dirname(JSN), exist_ok=True)
    info = write_glb(GLB, named, generator='pagoda_kit.py')
    out = dict(h_ratio=H_RATIO, classes={k: dict(max_w_m=v[0], ref_w_studs=v[1], segs=v[2], terraces=v[3]) for k, v in CLASSES.items()},
               pieces=info, note='centre/size in studs at the class reference width; pivot = base centre on the ground (y 0)')
    json.dump(out, open(JSN, 'w'), indent=1)
    tot = 0
    for k, v in info.items():
        tot += v['tris']
        print('%-16s tris %5d  size %s' % (k, v['tris'], ['%.2f' % s for s in v['size']]))
    print('unique meshes', len(info), 'tris', tot, '->', GLB, os.path.getsize(GLB))


if __name__ == '__main__':
    main()
