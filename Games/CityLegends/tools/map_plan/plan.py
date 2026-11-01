import sys, math, json
sys.path.insert(0, sys.argv[1])
from geo import load, Elev
from base import coast_chains, point_in_poly
from routes import catmull, contour_route, smooth, profile
OSM = sys.argv[2]; OUT = sys.argv[3]
ways = load(OSM + "/monaco.json"); el = Elev(OSM + "/elev.json")
SPM, VS = 1.6, 1.0  # studs per metre across, studs per metre up

chain = max(coast_chains(ways), key=len)
land = chain + [(9000, 9000), (-9000, 9000)]

X0, X1, Y0, Y1 = -2150, 2250, -1100, 760
W = 2400; SC = W / (X1 - X0); H = int((Y1 - Y0) * SC) + 230
P = lambda p: ((p[0] - X0) * SC, (Y1 - p[1]) * SC)
def path(pts, close=False):
    return "M" + " L".join("%.1f,%.1f" % P(p) for p in pts) + (" Z" if close else "")

exec(open(sys.argv[4], encoding="utf-8").read())  # ROUTES, STREETS, DISTRICTS, MARKS

o = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" font-family="Segoe UI, Arial">',
     '<defs><clipPath id="fr"><rect x="0" y="0" width="%d" height="%d"/></clipPath></defs>' % (W, int((Y1 - Y0) * SC)),
     '<rect width="100%" height="100%" fill="#10141c"/>', '<g clip-path="url(#fr)">']
# hills
step = 10
for gx in range(X0, X1, step):
    for gy in range(Y0, Y1, step):
        h = el.at(gx + step / 2, gy + step / 2)
        band = int(h // 40)
        t = min(h / 650, 1)
        sh = 0.92 + 0.08 * (band % 2)
        r = int((214 - 120 * t) * sh); g = int((206 - 95 * t) * sh); b = int((160 - 95 * t) * sh)
        x, y = P((gx, gy + step))
        o.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{step*SC+0.7:.1f}" height="{step*SC+0.7:.1f}" fill="rgb({r},{g},{b})"/>')
# sea = frame minus land
sea = [(X0 - 50, Y0 - 50), (X1 + 50, Y0 - 50), (X1 + 50, Y1 + 50), (X0 - 50, Y1 + 50)]
o.append(f'<path d="{path(sea, True)} {path(land, True)}" fill="#1f5f8f" fill-rule="evenodd"/>')
o.append(f'<path d="{path(chain)}" fill="none" stroke="#e8dcb5" stroke-width="3"/>')
for w in ways:
    L = sum(math.hypot(w["pts"][i][0]-w["pts"][i-1][0], w["pts"][i][1]-w["pts"][i-1][1]) for i in range(1, len(w["pts"])))
    if w["tags"].get("man_made") == "breakwater" or (w["tags"].get("man_made") == "pier" and L > 140):
        o.append(f'<path d="{path(w["pts"])}" fill="none" stroke="#cfcac0" stroke-width="{7 if w["tags"]["man_made"]=="breakwater" else 4}" stroke-linecap="round"/>')
# districts
for name, poly, col in DISTRICTS:
    o.append(f'<path d="{path(poly, True)}" fill="{col}" fill-opacity="0.22" stroke="{col}" stroke-width="2" stroke-dasharray="8 6"/>')
# roads
RW = 40 * SC  # 64 studs = 40 m
stats = []
def road(line, col, tunnel=None, width=RW, edge="#1b1b1b"):
    d = path(line)
    o.append(f'<path d="{d}" fill="none" stroke="{edge}" stroke-width="{width+6:.1f}" stroke-linejoin="round" stroke-linecap="round"/>')
    o.append(f'<path d="{d}" fill="none" stroke="{col}" stroke-width="{width:.1f}" stroke-linejoin="round" stroke-linecap="round"/>')
def sea_check(name, line):
    wet = [p for p in line[::3] if not point_in_poly(p, land)]
    if wet:
        print("IN SEA:", name, len(wet), "e.g. %.0f,%.0f" % wet[len(wet)//2])
for name, pts, col, opts in STREETS:
    line = catmull(pts, 8, opts.get("closed", False))
    sea_check(name, line)
    road(line, col, width=RW * opts.get("w", 1))
    ss, rr, hh = profile(el, line, None, VS, SPM, opts.get("grade", 0.10), {0: max(el.at(*line[0]), 2) * VS, -1: max(el.at(*line[-1]), 2) * VS} if not opts.get("closed") else None)
    g = max(abs(hh[i] - hh[i - 1]) / max(ss[i] - ss[i - 1], 1e-6) for i in range(1, len(hh)))
    cut = max(rr[i] - hh[i] for i in range(len(hh))); fill = max(hh[i] - rr[i] for i in range(len(hh)))
    print("%-16s len %5.0f  h %4.0f-%4.0f  grade %4.1f%%  cut %4.0f fill %4.0f  ends %4.0f/%4.0f" % (name, ss[-1], min(hh), max(hh), g * 100, cut, fill, hh[0], hh[-1]))
for name, pts, col, opts in ROUTES:
    line = catmull(pts, 8, opts.get("closed", False))
    sea_check(name, line)
    road(line, col)
    s, raw, h = profile(el, line, None, VS, SPM, opts.get("grade", 0.08), opts.get("fixed"))
    # bridges / tunnels: road far above / below the ground
    for i in range(1, len(line)):
        gap = h[i] - raw[i]
        tx = opts.get("tunnel")
        if tx and tx[0] <= line[i][0] <= tx[1]:
            o.append(f'<path d="{path(line[i-1:i+1])}" stroke="#000" stroke-opacity="0.55" stroke-width="{RW+6:.1f}" fill="none"/>')
            continue
        if gap > 12:
            o.append(f'<path d="{path(line[i-1:i+1])}" stroke="#f4f1ea" stroke-width="{RW*0.35:.1f}" fill="none"/>')
        elif gap < -14:
            o.append(f'<path d="{path(line[i-1:i+1])}" stroke="#000" stroke-opacity="0.55" stroke-width="{RW+6:.1f}" fill="none"/>')
    grades = [abs(h[i] - h[i - 1]) / max(s[i] - s[i - 1], 1e-6) for i in range(1, len(h))]
    stats.append((name, s[-1], min(h), max(h), max(grades), max(max(raw[i] - h[i] for i in range(len(h))), 0), max(max(h[i] - raw[i] for i in range(len(h))), 0)))
    for i in range(0, len(line), 70):
        x, y = P(line[i])
        o.append(f'<text x="{x:.0f}" y="{y+4:.0f}" font-size="11" fill="#111" text-anchor="middle" font-weight="700">{int(h[i])}</text>')
ALL = [(n, catmull(pts, 8, op.get("closed", False))) for n, pts, c, op in ROUTES + STREETS]
def seg_x(a, b, c, d):
    den = (b[0]-a[0])*(d[1]-c[1]) - (b[1]-a[1])*(d[0]-c[0])
    if abs(den) < 1e-9: return None
    t = ((c[0]-a[0])*(d[1]-c[1]) - (c[1]-a[1])*(d[0]-c[0])) / den
    u = ((c[0]-a[0])*(b[1]-a[1]) - (c[1]-a[1])*(b[0]-a[0])) / den
    return (a[0]+t*(b[0]-a[0]), a[1]+t*(b[1]-a[1])) if 0 <= t <= 1 and 0 <= u <= 1 else None
JUNCS = []
for ni, (na, la) in enumerate(ALL):
    for nb, lb in ALL[ni+1:]:
        for i in range(0, len(la)-1, 2):
            for k in range(0, len(lb)-1, 2):
                if abs(la[i][0]-lb[k][0]) > 40 or abs(la[i][1]-lb[k][1]) > 40: continue
                x = seg_x(la[i], la[min(i+2, len(la)-1)], lb[k], lb[min(k+2, len(lb)-1)])
                if x and all(math.hypot(x[0]-j[0], x[1]-j[1]) > 30 for j in JUNCS): JUNCS.append(x)
for n, pts, c, op in ROUTES + STREETS:
    if op.get("closed"): continue
    for e in (pts[0], pts[-1]):
        if all(math.hypot(e[0]-j[0], e[1]-j[1]) > 30 for j in JUNCS): JUNCS.append(e)
# roads running too close side by side (not at a junction)
for ni, (na, la) in enumerate(ALL):
    for nb, lb in ALL[ni+1:]:
        worst = None
        for p in la[::4]:
            if any(math.hypot(p[0]-j[0], p[1]-j[1]) < 90 for j in JUNCS): continue
            for q in lb[::4]:
                d = math.hypot(p[0]-q[0], p[1]-q[1])
                if d < 52 and (worst is None or d < worst[0]): worst = (d, p)
        if worst: print("TOO CLOSE: %s / %s  %.0f m at %.0f,%.0f" % (na, nb, worst[0], worst[1][0], worst[1][1]))
for jx in JUNCS:
    x, y = P(jx)
    o.append(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="7" fill="#fff" stroke="#000" stroke-width="2"/>')
print("junctions", len(JUNCS), " street length total %.0f studs" % (sum(sum(math.hypot(l[i][0]-l[i-1][0], l[i][1]-l[i-1][1]) for i in range(1, len(l))) for n, l in ALL) * SPM))
for kind, p, label in MARKS:
    x, y = P(p)
    if kind == "junction":
        o.append(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="9" fill="#fff" stroke="#000" stroke-width="2"/>')
    elif kind == "hairpin":
        o.append(f'<text x="{x:.0f}" y="{y+6:.0f}" font-size="18" text-anchor="middle" fill="#fff" stroke="#000" stroke-width="3" paint-order="stroke">⟲</text>')
    elif kind == "label":
        o.append(f'<text x="{x:.0f}" y="{y:.0f}" font-size="21" font-weight="800" fill="#fff" stroke="#000" stroke-width="4" paint-order="stroke" text-anchor="middle">{label}</text>')
    elif kind == "small":
        o.append(f'<text x="{x:.0f}" y="{y:.0f}" font-size="14" font-weight="700" fill="#fff" stroke="#000" stroke-width="3" paint-order="stroke" text-anchor="middle">{label}</text>')
    elif kind == "sea":
        o.append(f'<text x="{x:.0f}" y="{y:.0f}" font-size="26" font-style="italic" fill="#9fd0f0" text-anchor="middle" letter-spacing="6">{label}</text>')
o.append("</g>")
# legend
ly = int((Y1 - Y0) * SC) + 20
o.append(f'<text x="20" y="{ly+14}" font-size="22" font-weight="800" fill="#fff">CITY LEGENDS · RIVIERA MAP · PHASE 1 PLAN</text>')
lx = 20; ly2 = ly + 50
for name, pts, col, opts in ROUTES:
    st = [x for x in stats if x[0] == name][0]
    o.append(f'<rect x="{lx}" y="{ly2-14}" width="34" height="16" fill="{col}" stroke="#000"/>')
    o.append(f'<text x="{lx+44}" y="{ly2}" font-size="16" fill="#fff">{name}: {st[1]:,.0f} studs long, height {st[2]:.0f}–{st[3]:.0f}, steepest {st[4]*100:.0f}%</text>')
    ly2 += 26
o.append(f'<rect x="{lx}" y="{ly2-14}" width="34" height="16" fill="#9a958c" stroke="#000"/><text x="{lx+44}" y="{ly2}" font-size="16" fill="#fff">Town streets and climbs</text>')
ly2 += 26
o.append(f'<rect x="{lx}" y="{ly2-12}" width="34" height="12" fill="#f4f1ea"/><text x="{lx+44}" y="{ly2}" font-size="16" fill="#fff">Bridge / viaduct</text>')
o.append(f'<rect x="{lx+260}" y="{ly2-16}" width="34" height="18" fill="#000" fill-opacity="0.6"/><text x="{lx+304}" y="{ly2}" font-size="16" fill="#fff">Tunnel</text>')
o.append(f'<circle cx="{lx+450}" cy="{ly2-5}" r="8" fill="#fff" stroke="#000" stroke-width="2"/><text x="{lx+466}" y="{ly2}" font-size="16" fill="#fff">Junction</text>')
o.append(f'<text x="{lx+580}" y="{ly2}" font-size="16" fill="#fff">Small numbers on roads = road height in studs · harbours: quays only, no yachts</text>')
sx = W - 520; sy = ly + 40
m1000 = 1000 / SPM * SC
o.append(f'<rect x="{sx}" y="{sy}" width="{m1000:.0f}" height="10" fill="#fff"/><text x="{sx}" y="{sy+32}" font-size="15" fill="#fff">1,000 studs  ·  roads drawn at true width (64 studs, 2+2 lanes)</text>')
o.append(f'<text x="{sx}" y="{sy+58}" font-size="15" fill="#fff">Whole map: {(X1-X0)*SPM:,.0f} x {(Y1-Y0)*SPM:,.0f} studs · hills: darker = higher</text>')
o.append(f'<text x="{sx}" y="{sy+84}" font-size="13" fill="#aaa">Map shape based on © OpenStreetMap contributors (ODbL)</text>')
o.append("</svg>")
open(OUT, "w", encoding="utf-8").write("\n".join(o))
for st in stats:
    print("%-14s len %6.0f  h %4.0f-%4.0f  max grade %4.1f%%  max cut %4.0f  max fill %4.0f" % (st[0], st[1], st[2], st[3], st[4] * 100, st[5], st[6]))
print(W, H)
