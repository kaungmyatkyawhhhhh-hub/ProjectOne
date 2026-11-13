"""Whole-Yangon map (14 Nov 2026): the ROAD NETWORK of batches 1 (west), 2 (downtown), 3 (east) as meshes.

Owner: "some are 4 lane and 6 lane and 2 lane but ingame theyre different", "the overhead bridges are too low". Batches 1-3
are ~86 km2 of real city: every public street and main road, in part style ~600k+ parts, so everything here is mesh roads +
invisible collision boxes, and the main roads get traffic.

    python roads.py <tag> [--no-glb] [--cells x0,z0,x1,z1]        (run from Games/CityLegends/tools/yangon/city)

Steps (modules beside this one):
  roadnet.py   OSM ways -> edges split at shared nodes, real lanes each way, divided roads merged onto their midline
               (median half 3), ground roads beside a flyover moved clear of it, clipped to the batch outline minus batch
               0.5, roads continuing a v5 game road's map-edge end cut / extended to end exactly on it
  ground.py    the ground field (SRTM smoothed like d4_heights, blended onto batch 0.5's ground at the seam), water levels
  heights.py   one height per junction, grades 6 % (main) / 10 % (streets), bridges / flyovers with 17 studs under the
               girders (water: 10), ramps along the road they continue, long ramps carried past junctions
  roadmesh.py  R / P / KR / KW / KG / L / MG / B triangles per 256-stud cell, zebras at signals
  roadlanes.py the traffic lanes (RivieraLanes format) and the dead-end check
Outputs in build/city/:
  roads_<tag>/roads_<tag>_<n>.glb   meshes named KIND_CELL_cx_cy_cz_sx_sy_sz (glb.code; <= 100 meshes / 90,000 triangles a
                                    file, <= 17,000 triangles a mesh) + manifest.json
  RoadCollide_<tag>_<n>.luau        collision boxes, one string each (< 190,000 characters), a line per box:
                                    "cx cy cz dx dy dz width walk kind"  (streets.py's StreetCollide line + a kind; cy is the
                                    TOP of the box, (dx, dy, dz) its length and slope, walk always 0):
                                    R carriageway (2 thick), P pavement (top +0.5, 2.5 thick), M median (like P),
                                    J junction square (2 thick), D bridge deck (DECK 3 thick), W parapet (1 wide, 5.5 thick)
  YangonLanesB<tag>_<n>.lua         traffic lane modules (src-ready, NOT copied into src)
  roads_<tag>.png                   preview: roads by class, bridges red, lanes overlay
  roads_<tag>_stats.json            the numbers printed at the end
  roads_<tag>_profile.json          per edge: centre line with surface / ground heights (for the terrain beds)
"""
import json, math, os, pickle, sys, time

import numpy as np

import geo
import ground
import heights as hts
import roadnet as rn
import roadmesh as rm
import roadlanes as rl
from glb import Mesh, write_glb, check_glb, code

OUT = os.path.join(geo.BUILD, 'city')
COLLIDE_CHARS = 189000
FILE_TRIS, FILE_MESHES = 90000, 100


def cell_id(i, j):
    f = lambda v: ('n%d' % -v) if v < 0 else str(v)
    return '%sx%s' % (f(i), f(j))


def parallel_meshes(B, tag, jobs, cells, log=print):
    """the cells split over `jobs` processes (each rebuilds the network, ~25 s, then meshes every jobs-th cell); the
    raised strips are made here"""
    import subprocess
    procs = []
    for k in range(jobs):
        args = [sys.executable, '-u', os.path.abspath(__file__), tag, '--part', '%d/%d' % (k, jobs)]
        if cells:
            args += ['--cells', ','.join(str(v) for v in cells)]
        procs.append(subprocess.Popen(args, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE))
    meshes = {}
    B.tris_total = {}
    for k, pr in enumerate(procs):
        _, err = pr.communicate()
        if pr.returncode != 0:
            raise RuntimeError('mesh part %d failed: %s' % (k, err.decode('utf-8', 'replace')[-2000:]))
        part = os.path.join(OUT, 'roads_%s_part%d.pkl' % (tag, k))
        d = pickle.load(open(part, 'rb'))
        os.remove(part)
        for key, tris in d['meshes'].items():
            meshes[key] = np.concatenate([meshes[key], tris]) if key in meshes else tris
        for kk, v in d['tris'].items():
            B.tris_total[kk] = B.tris_total.get(kk, 0) + v
        if k == 0:
            B.zebras = d['zebras']
    # raised strips (cheap) in this process
    extra = {}
    for e, a, b in B.rpieces:
        for kind, tri in B._raised_strip(e, a, b):
            m = ((tri[0][0] + tri[1][0] + tri[2][0]) / 3, (tri[0][2] + tri[1][2] + tri[2][2]) / 3)
            if not B.allowed_p.contains(rm.Point(m)):
                continue
            key = (kind, math.floor(m[0] / rm.CELL), math.floor(m[1] / rm.CELL))
            extra.setdefault(key, []).append(tri)
            B.tris_total[kind] = B.tris_total.get(kind, 0) + 1
    for key, tl in extra.items():
        arr = np.asarray(tl, dtype=np.float32)
        meshes[key] = np.concatenate([meshes[key], arr]) if key in meshes else arr
    B.meshes = meshes
    log('  %d mesh parts merged' % jobs)
    return meshes


def mesh_part(tag, k, n, cells):
    net = rn.build(tag)
    G = ground.Ground()
    q = lambda *a: None
    hts.solve(net, G, log=q)
    if hts.extend_short(net, G, log=q):
        hts.solve(net, G, log=q)
    B = rm.Builder(net, G)
    allc = B.cells
    sel = allc()
    if cells:
        x0, z0, x1, z1 = cells
        sel = [c for c in sel if x0 <= c[0] * 256 < x1 and z0 <= c[1] * 256 < z1]
    mine = sel[k::n]
    B.cells = lambda: mine
    B.rpieces_all = B.rpieces
    B.rpieces = []          # the raised strips are made once, by the parent
    meshes = B.build(log=q)
    pickle.dump(dict(meshes=meshes, tris=B.tris_total, zebras=B.zebras),
                open(os.path.join(OUT, 'roads_%s_part%d.pkl' % (tag, k)), 'wb'))


def write_meshes(meshes, tag, log=print):
    d = os.path.join(OUT, 'roads_%s' % tag)
    os.makedirs(d, exist_ok=True)
    for f in os.listdir(d):
        if f.endswith('.glb'):
            os.remove(os.path.join(d, f))
    items = []
    for (kind, i, j), tris in sorted(meshes.items()):
        tris = np.asarray(tris)
        groups = [tris[k:k + rm.MAX_TRIS] for k in range(0, len(tris), rm.MAX_TRIS)]
        for gi, g in enumerate(groups):
            cid = cell_id(i, j) + ('s%d' % gi if len(groups) > 1 else '')
            items.append((kind, cell_id(i, j), cid, g))
    files, cur, n = [], [], 0
    for it in items:
        if cur and (len(cur) >= FILE_MESHES or n + len(it[3]) > FILE_TRIS):
            files.append(cur)
            cur, n = [], 0
        cur.append(it)
        n += len(it[3])
    if cur:
        files.append(cur)
    manifest = dict(files=[], kinds={})
    for fi, group in enumerate(files):
        named = []
        for kind, cell, cid, g in group:
            m = Mesh()
            col = rm.COL[kind]
            for a_, b_, c_ in np.asarray(g, dtype=np.float64).tolist():
                m.tri(a_, b_, c_, (a_[0] / 16, a_[2] / 16), (b_[0] / 16, b_[2] / 16), (c_[0] / 16, c_[2] / 16), col)
            if not m.T:
                continue
            lo, hi = m.box()
            c = [(lo[k] + hi[k]) / 2 for k in range(3)]
            sz = [max(hi[k] - lo[k], 0.01) for k in range(3)]
            named.append((code(kind, cid, c, sz), m, kind))
        path = os.path.join(d, 'roads_%s_%d.glb' % (tag, fi + 1))
        info = write_glb(path, [(nm_, m) for nm_, m, _ in named], generator='yangon city roads.py')
        try:
            nm, bad = check_glb(path, info)
            assert not bad and nm == len(named), (path, bad[:3])
        except ImportError:
            pass
        manifest['files'].append(dict(glb=os.path.basename(path), bytes=os.path.getsize(path),
                                      meshes=[dict(name=nm_, tris=m.tris) for nm_, m, _ in named]))
        for nm_, m, kind in named:
            manifest['kinds'][kind] = manifest['kinds'].get(kind, 0) + m.tris
        del named
    manifest['meshes'] = len(items)
    json.dump(manifest, open(os.path.join(d, 'manifest.json'), 'w'), indent=1)
    log('  %d meshes in %d .glb files (%s)' % (len(items), len(files), d))
    return manifest


def collision(B, net):
    """invisible boxes: carriageways, pavements, medians, junction squares, decks and parapets"""
    from shapely.geometry import Polygon
    rows = []

    def row(p0, p1, y0, y1, width, kind, off=0.0, R=None):
        c = (p0 + p1) / 2
        if R is not None:
            c = c + R * off
        d = p1 - p0
        rows.append('%.2f %.2f %.2f %.2f %.2f %.2f %.2f 0 %s' % (c[0], (y0 + y1) / 2, c[1], d[0], y1 - y0, d[1], width, kind))
    for e in net.edges:
        lo, hi = B.lohi[e.id]
        r, rr = B.raised[e.id]
        n = len(e.P)
        i = 0
        while i < n - 1:
            j = min(n - 1, i + 2)
            p0, p1 = e.P[i], e.P[j]
            if np.linalg.norm(p1 - p0) < 0.5:
                i = j
                continue
            Rm = e.D[(i + j) // 2]
            Rv = np.array([-Rm[1], Rm[0]])
            l_, h_ = (lo[i] + lo[j]) / 2, (hi[i] + hi[j]) / 2
            y0, y1 = e.y[i], e.y[j]
            paired = e.oneway and e.w[i] > 0.5
            if r[i] or r[j]:
                inner = 0.0 if paired else l_ - rm.PARAPET_W
                row(p0, p1, y0, y1, h_ + rm.PARAPET_W - inner, 'D', (inner + h_ + rm.PARAPET_W) / 2, Rv)
                row(p0, p1, y0 + rm.PARAPET_H, y1 + rm.PARAPET_H, rm.PARAPET_W, 'W', h_ + rm.PARAPET_W / 2, Rv)
                if not paired:
                    row(p0, p1, y0 + rm.PARAPET_H, y1 + rm.PARAPET_H, rm.PARAPET_W, 'W', l_ - rm.PARAPET_W / 2, Rv)
            else:
                row(p0, p1, y0, y1, h_ - l_, 'R', (l_ + h_) / 2, Rv)
                # pavements, unless another carriageway lies there (a junction mouth)
                for side, a_, b_ in ((1, h_, h_ + e.walk), (-1, l_ - e.walk, l_)):
                    if side == -1 and paired:
                        continue
                    q = Polygon([p0 + Rv * a_, p1 + Rv * a_, p1 + Rv * b_, p0 + Rv * b_])
                    if _blocked(B, q, e):
                        continue
                    row(p0, p1, y0 + rm.PAVE_UP, y1 + rm.PAVE_UP, b_ - a_, 'P', (a_ + b_) / 2, Rv)
                if paired and l_ > 0.5:
                    q = Polygon([p0, p1, p1 + Rv * l_, p0 + Rv * l_])
                    if not _blocked(B, q, e):
                        row(p0, p1, y0 + rm.PAVE_UP, y1 + rm.PAVE_UP, l_, 'M', l_ / 2, Rv)
            i = j
    # junction squares
    inc = {}
    for e in net.edges:
        inc.setdefault(e.a, []).append((e, 0))
        inc.setdefault(e.b, []).append((e, -1))
    for key, lst in inc.items():
        if len(lst) < 3:
            continue
        e, end = lst[0]
        if B.raised[e.id][0][end]:
            continue
        reach = max(max(abs(B.lohi[f.id][0][k]), abs(B.lohi[f.id][1][k])) for f, k in lst) + 4
        p = e.P[end]
        d = e.D[end]
        row(p - d * reach, p + d * reach, e.y[end], e.y[end], 2 * reach, 'J')
    return rows


def _blocked(B, q, e):
    for k in B.ctree.query(q):
        f = B.meta[int(k)]
        if f.id == e.id:
            continue
        if B.carr[int(k)].intersection(q).area > 0.05 * q.area:
            return True
    return False


def write_collision(rows, tag):
    for f in os.listdir(OUT):
        if f.startswith('RoadCollide_%s_' % tag):
            os.remove(os.path.join(OUT, f))
    mods, cur = [], []
    size = 0
    for r in rows:
        if size + len(r) + 1 > COLLIDE_CHARS - 40:
            mods.append(cur)
            cur, size = [], 0
        cur.append(r)
        size += len(r) + 1
    if cur:
        mods.append(cur)
    for k, m in enumerate(mods):
        open(os.path.join(OUT, 'RoadCollide_%s_%d.luau' % (tag, k + 1)), 'w', encoding='utf-8', newline='\n').write(
            'return [==[\n' + '\n'.join(m) + '\n]==]\n')
    return len(mods)


def preview(net, B, lanes, tag, structs):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    from matplotlib.collections import PolyCollection, LineCollection
    x0, z0, x1, z1 = net.outline.bounds
    W = x1 - x0
    H = z1 - z0
    fig, ax = plt.subplots(figsize=(18, 18 * H / W))
    ax.set_facecolor((0.93, 0.92, 0.88))
    for pg in [net.outline]:
        xs, zs = pg.exterior.xy
        ax.plot(xs, zs, color=(0.3, 0.3, 0.3), lw=1.2)
    ex = net.exclusion.intersection(net.outline.buffer(300))
    for pg in rm._polys(ex):
        xs, zs = pg.exterior.xy
        ax.fill(xs, zs, color=(0.8, 0.8, 0.75), lw=0)
    for w in B.G.water:
        for pg in rm._polys(w['poly']):
            if pg.intersects(net.outline.buffer(500)):
                xs, zs = pg.exterior.xy
                ax.fill(xs, zs, color=(0.62, 0.78, 0.9), lw=0)
    colour = dict(trunk=(0.75, 0.2, 0.55), primary=(0.9, 0.45, 0.1), secondary=(0.85, 0.7, 0.1), tertiary=(0.55, 0.65, 0.2))
    polys, cols = [], []
    for k, e in enumerate(B.meta):
        pg = B.carr[k]
        c = colour.get(e.hw.replace('_link', ''), (0.45, 0.45, 0.45) if e.look == 'street' else (0.6, 0.6, 0.6))
        for g in rm._polys(pg):
            polys.append(np.array(g.exterior.coords))
            cols.append(c)
    ax.add_collection(PolyCollection(polys, facecolors=cols, edgecolors='none'))
    rp = [np.array(g.exterior.coords) for f in B.rfoot for g in rm._polys(f)]
    ax.add_collection(PolyCollection(rp, facecolors=[(0.85, 0.05, 0.05)], edgecolors='none'))
    segs = [l['pts'][:, [0, 2]] for l in lanes]
    ax.add_collection(LineCollection(segs, colors=[(0.1, 0.3, 0.9)], linewidths=0.25))
    for s in structs[:25]:
        if s['clear_min'] is None:
            continue
        eid, i0, i1 = net.runs[s['runs'][0]]
        p = net.edges[eid].P[(i0 + i1) // 2]
        ax.text(p[0], p[1], '%s %.0f' % (s['name'][:22], s['clear_min']), fontsize=6, color=(0.6, 0, 0))
    ax.set_xlim(x0 - 100, x1 + 100)
    ax.set_ylim(z1 + 100, z0 - 100)
    ax.set_aspect('equal')
    ax.set_title('Yangon batch %s roads (OSM ODbL): trunk purple, primary orange, secondary yellow, tertiary green, streets grey, '
                 'raised red (clearance labels), lanes blue' % tag, fontsize=9)
    p = os.path.join(OUT, 'roads_%s.png' % tag)
    fig.savefig(p, dpi=110, bbox_inches='tight')
    plt.close(fig)
    return p


def run(tag, glb=True, cells=None, log=print, jobs=1):
    t0 = time.time()
    log('batch %s: network' % tag)
    net = rn.build(tag)
    G = ground.Ground()
    log('  DEM %s, %d edges' % (G.source, len(net.edges)))
    hts.solve(net, G, log=log)
    if hts.extend_short(net, G, log=log):
        hts.solve(net, G, log=log)
    structs = hts.structures(net)
    log('  heights done %.0f s' % (time.time() - t0))
    B = rm.Builder(net, G)
    if cells:
        x0, z0, x1, z1 = cells
        allc = B.cells
        B.cells = lambda: [c for c in allc() if x0 <= c[0] * 256 < x1 and z0 <= c[1] * 256 < z1]
    if jobs > 1:
        meshes = parallel_meshes(B, tag, jobs, cells, log)
    else:
        meshes = B.build(log=log)
    log('  meshes done %.0f s' % (time.time() - t0))
    manifest = write_meshes(meshes, tag, log=log) if glb else None
    rows = collision(B, net)
    nmods = write_collision(rows, tag)
    lanes, links, lstats, _ = rl.build(net, tag, log=log)
    files, first = rl.write(lanes, links, tag, OUT)
    prev = preview(net, B, lanes, tag, structs)
    # profile for the terrain beds
    prof = [dict(id=e.id, name=e.name, hw=e.hw, raised=bool(((e.y - e.g) > hts.RAISE).any()),
                 pts=[[round(float(p[0]), 1), round(float(y), 2), round(float(p[1]), 1), round(float(g), 2)] for p, y, g in zip(e.P, e.y, e.g)],
                 half=[round(float(-rn.offsets(e)[0].max()), 1), round(float(rn.offsets(e)[1].max()), 1)], walk=e.walk)
            for e in net.edges]
    json.dump(prof, open(os.path.join(OUT, 'roads_%s_profile.json' % tag), 'w'))
    st = stats(net, B, structs, lanes, links, lstats, rows, nmods, files, first, manifest)
    st['seconds'] = round(time.time() - t0)
    json.dump(st, open(os.path.join(OUT, 'roads_%s_stats.json' % tag), 'w', encoding='utf-8'), indent=1, ensure_ascii=False)
    print_stats(st, log)
    log('preview: ' + prev)
    return net, B, st


def stats(net, B, structs, lanes, links, lstats, rows, nmods, files, first, manifest):
    km = {}
    lane_km = {}
    for e in net.edges:
        L = rn.chain(e.P)[-1] / geo.SPM / 1000
        k = e.hw
        km[k] = km.get(k, 0) + L
        xs = '%d' % e.nf if e.oneway else '%d+%d' % (e.nf, e.nb)
        key = ('one-way ' if e.oneway else '') + xs + (' divided' if e.oneway and (e.w > 0.5).mean() > 0.5 else '')
        lane_km[key] = lane_km.get(key, 0) + L
    br = []
    for s in structs:
        if s['length'] < 40:
            continue
        br.append(dict(name=s['name'], length_studs=round(s['length']), bridge_tagged_studs=round(s['bridge_len']),
                       max_height=round(s['hmax'], 1),
                       clearance_min=None if s['clear_min'] is None else round(s['clear_min'], 1), over=s['over']))
    fams = []
    for k, stt in net.fam_status.items():
        ids, land = net.fams[k]
        names = {}
        for i in ids:
            nm = net.edges[i].name or net.edges[i].hw
            names[nm] = names.get(nm, 0) + rn.chain(net.edges[i].P)[-1]
        fams.append(dict(name=max(names, key=names.get), status=stt, grade=net.fam_grade.get(k)))
    tris = dict(B.tris_total)
    tris['total'] = sum(B.tris_total.values())
    return dict(tag=net.tag, dem=None, km_by_class={k: round(v, 2) for k, v in sorted(km.items(), key=lambda kv: -kv[1])},
                km_total=round(sum(km.values()), 1), km_by_cross_section={k: round(v, 2) for k, v in sorted(lane_km.items(), key=lambda kv: -kv[1])},
                divided_pairs_km=round(net.stats_pair['paired_len'] / geo.SPM / 1000, 1), pushed_beside_flyovers=net.pushed,
                bridges=br, bridge_families=fams, spill_studs=round(net.spill), seams=net.seam_report,
                triangles=tris, meshes=manifest['meshes'] if manifest else None, glb_files=len(manifest['files']) if manifest else None,
                collision_boxes=len(rows), collision_modules=nmods,
                lanes=len(lanes), lane_links=len(links), lane_stats=lstats, lane_modules=[dict(file=os.path.basename(p), chars=c, lanes=n, first=f) for p, c, n, f in files],
                lanes_first=first, zebras=len(B.zebras))


def print_stats(st, log=print):
    log('---- batch %s ----' % st['tag'])
    log('km by class: ' + ', '.join('%s %.1f' % kv for kv in st['km_by_class'].items()) + ' | total %.1f km' % st['km_total'])
    log('km by cross-section: ' + ', '.join('%s %.1f' % kv for kv in st['km_by_cross_section'].items()))
    log('divided (merged pairs, one-way length) %.1f km; ground roads moved beside flyovers: %d' % (st['divided_pairs_km'], st['pushed_beside_flyovers']))
    log('bridges / flyovers (raised runs over 40 studs):')
    for b in st['bridges']:
        log('  %-40s %5d studs (tagged %4d), max %4.1f over ground, clearance %s %s' % (
            b['name'][:40], b['length_studs'], b['bridge_tagged_studs'], b['max_height'], b['clearance_min'], b['over'] or ''))
    for f in st['bridge_families']:
        if f['status'] != 'ok':
            log('  family %-33s %s' % (f['name'][:33], f['status']))
    log('raised outside the bridges: %d studs' % st['spill_studs'])
    log('seam with batch 0.5:')
    for s in st['seams']:
        log('  %-28s %-9s %s %s' % (s['road'], s['flag'], s['status'], '' if s['status'] != 'joined' else
                                    'OSM %s (%s) moved %.1f, game %s, OSM %s' % (s['osm'], 'one-way' if s['oneway'] else 'two-way', s['moved'], s['game_xs'], s['osm_xs'])))
    log('triangles: ' + ', '.join('%s %d' % kv for kv in st['triangles'].items()) + ' | meshes %s in %s files' % (st['meshes'], st['glb_files']))
    log('collision boxes %d in %d modules' % (st['collision_boxes'], st['collision_modules']))
    log('lanes %d, links %d, %s; first = %d; modules %s' % (st['lanes'], st['lane_links'], st['lane_stats'], st['lanes_first'],
                                                           ', '.join('%s (%d chars, %d lanes, first %d)' % (m['file'], m['chars'], m['lanes'], m['first']) for m in st['lane_modules'])))
    log('zebra stripes %d' % st['zebras'])


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    tag = sys.argv[1]
    cells = None
    if '--cells' in sys.argv:
        cells = [float(v) for v in sys.argv[sys.argv.index('--cells') + 1].split(',')]
    if '--part' in sys.argv:
        k, n = [int(v) for v in sys.argv[sys.argv.index('--part') + 1].split('/')]
        mesh_part(tag, k, n, cells)
    else:
        jobs = int(sys.argv[sys.argv.index('--jobs') + 1]) if '--jobs' in sys.argv else 1
        run(tag, glb='--no-glb' not in sys.argv, cells=cells, jobs=jobs)
