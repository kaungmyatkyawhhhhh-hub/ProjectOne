"""green_edges.py (2026-11-16, P1, owner's two pictures): the Inya Lake walk and the Kabar Aye Pagoda Road green bank.

Owner refs (Games/CityLegends/build/landmarks/refs/owner/):
  owner_inya_walkway.webp            the lake walk beside Kabar Aye Pagoda Road: a grassy bank sloping DOWN to the water
                                     (no wall), a narrow concrete walkway, a row of fan palms with flowering bushes, white
                                     square planters and green bins on the road side, a small green bench shelter on the bank
  owner_kabaraye_roadside_greenbank.png  Kabar Aye Pagoda Road in front of Myanmar Plaza: pavement, a LOW BLACK RAILING, a
                                     grass verge that SLOPES UP (embankment), a row of trees with straight dark trunks and
                                     full canopies, evenly spaced, a big flat lawn behind

edges(G, water, prof, H, lmk, outside, bld_d, road) -> dict(
    cols=[(x, z, top, wet)],     terrain columns (4 x 4 studs) to set: ground up to `top`; wet = water above it up to the lake
    parts=["CODE x y z sx sy sz yaw"],  WALK (concrete walk), BRAIL / BPOST (black railing)
    models=["NAME x y z yaw scale"],    FANPALM, BUSH, PLANTER, BIN, SHELTER, BANKTREE (Studio clones its templates)
    mask=bool raster (no generated trees there), stats=dict)
"""
import math

import numpy as np
from PIL import ImageDraw

RES = 4.0
LAKE_LEVEL = 40.5
WALK_TOP = LAKE_LEVEL + 3.6        # 1.2 m over the water
WALK_W = 6.0                       # 2 m narrow walk
BANK_OUT = 15.0                    # the grass bank reaches this far into the old water line (studs)
BANK_IN = 4.0                      # walk's water edge this far inland of the old shoreline
STRIP_W = 24.0                     # planting strip between the walk and the road (palms, bushes, planters, bins)
PALM_GAP = 18.0                    # a fan palm every 6 m
BIN_GAP = 180.0
SHELTER_GAP = 600.0
KA_ROAD = "Kabar Aye Pagoda Road"
BANK_RISE = 6.0                    # the embankment rises 2 m
BANK_RUN = 12.0                    # over 4 m
BANK_FLAT = 30.0                   # flat top out to 10 m from the pavement
TREE_OFF = 20.0                    # tree row 6.7 m from the pavement
TREE_GAP = 24.0                    # every 8 m


def _resample(line, step):
    n = max(1, int(line.length // step))
    return np.array([line.interpolate(line.length * k / n).coords[0] for k in range(n + 1)])


def edges(G, water, prof, H, lmk, outside, d_bld, road, d_road, bund_near=170.0, landmark_boxes=()):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from scipy.ndimage import label, distance_transform_edt
    from shapely.geometry import LineString as LS, Point as Pt
    from shapely.ops import unary_union

    nx, nz = water.shape
    colmap = {}          # (i, j) -> (top, wet)
    parts, models = [], []
    mask_img = G.blank()
    dr = ImageDraw.Draw(mask_img)
    stats = dict(walk_m=0.0, palms=0, bushes=0, planters=0, bins=0, shelters=0, bank_m=0.0, bank_trees=0, rail_posts=0)

    def setcol(x, z, top, wet=False, mode="max"):
        i, j = int((x - G.X0) / RES), int((z - G.Z0) / RES)
        if not (0 <= i < nx and 0 <= j < nz) or outside[i, j] or lmk[i, j]:
            return
        if road[i, j] and not wet:
            return
        old = colmap.get((i, j))
        if old is None or (mode == "max" and top > old[0]) or (mode == "min" and top < old[0]):
            colmap[(i, j)] = (top, wet)

    def ground(x, z):
        i = min(max(int((x - G.X0) / RES), 0), nx - 1)
        j = min(max(int((z - G.Z0) / RES), 0), nz - 1)
        return float(H[i, j]), i, j

    lab, n = label(water)
    big = int(np.argmax(np.bincount(lab.ravel())[1:]) + 1) if n else 0
    lake = lab == big
    d_out = distance_transform_edt(~outside) * RES
    xs = G.X0 + np.arange(nx) * RES + RES / 2
    zs = G.Z0 + np.arange(nz) * RES + RES / 2
    fig = plt.figure()
    cs = plt.contour(xs, zs, lake.T.astype(float), [0.5])
    segs = [np.asarray(s_) for s_ in cs.allsegs[0] if len(s_) > 20]
    plt.close(fig)
    ka = [LS([(q[0], q[2]) for q in e["pts"]]) for e in prof if e.get("name") == KA_ROAD and len(e["pts"]) > 1]
    KA = unary_union(ka)

    def is_lake(x, z):
        i, j = int((x - G.X0) / RES), int((z - G.Z0) / RES)
        return 0 <= i < nx and 0 <= j < nz and bool(lake[i, j])

    # ------------------------------------------------------------------ 1. the lake walk (picture 2)
    runs = []
    for sg in segs:
        cur = []
        for x, z in sg:
            i, j = min(max(int((x - G.X0) / RES), 0), nx - 1), min(max(int((z - G.Z0) / RES), 0), nz - 1)
            ok = d_out[i, j] > 16 and KA.distance(Pt(x, z)) < bund_near and not any(
                b[0] - 30 < x < b[2] + 30 and b[1] - 30 < z < b[3] + 30 for b in landmark_boxes)
            if ok:
                cur.append((x, z))
            elif cur:
                runs.append(cur)
                cur = []
        if cur:
            runs.append(cur)
    rng = np.random.default_rng(77)
    for run in runs:
        line = LS(run).simplify(6.0)
        if line.length < 120:
            continue
        line = LS(_resample(line, 12.0)).simplify(2.0)
        P = _resample(line, 3.0)
        stats["walk_m"] += line.length / 3
        # per sample: landward normal
        N = []
        for k in range(len(P)):
            a, b = P[max(k - 1, 0)], P[min(k + 1, len(P) - 1)]
            d = b - a
            d = d / max(1e-6, np.hypot(*d))
            nrm = np.array([-d[1], d[0]])
            if is_lake(*(P[k] + nrm * 8)) and not is_lake(*(P[k] - nrm * 8)):
                nrm = -nrm
            N.append(nrm)
        N = np.array(N)
        # terrain: bank from BANK_OUT into the water up to the walk, flat under the walk, planting strip at grass level
        for k in range(len(P)):
            p, nrm = P[k], N[k]
            for off in np.arange(-BANK_OUT, BANK_IN + WALK_W + STRIP_W + 0.1, 2.0):
                q = p + nrm * off
                if off < BANK_IN:
                    t = (off + BANK_OUT) / (BANK_OUT + BANK_IN)            # 0 at the far toe, 1 at the walk
                    top = (LAKE_LEVEL - 2.5) + t * (WALK_TOP - 0.4 - (LAKE_LEVEL - 2.5))
                    setcol(q[0], q[1], top, wet=top < LAKE_LEVEL)
                elif off < BANK_IN + WALK_W:
                    setcol(q[0], q[1], WALK_TOP - 3.7, mode="min")          # under the walk part (4 deep)
                else:
                    i, j = int((q[0] - G.X0) / RES), int((q[1] - G.Z0) / RES)
                    if 0 <= i < nx and 0 <= j < nz and d_road[i, j] > 4.0:
                        setcol(q[0], q[1], WALK_TOP - 0.35)
        # walk parts: one per ~24 studs along the line
        Q = _resample(line, 24.0)
        for k in range(len(Q) - 1):
            a, b = Q[k], Q[k + 1]
            d = b - a
            L = float(np.hypot(*d))
            if L < 1:
                continue
            u = d / L
            mid = (a + b) / 2
            nrm = np.array([-u[1], u[0]])
            if is_lake(*(mid + nrm * 8)) and not is_lake(*(mid - nrm * 8)):
                nrm = -nrm
            alt = 0.06 * (k % 2)
            yaw = math.atan2(-u[1], u[0])
            c = mid + nrm * (BANK_IN + WALK_W / 2)
            parts.append("WALK %.2f %.2f %.2f %.2f %.2f %.2f %.5f" % (c[0], WALK_TOP - 2.0 + alt, c[1], L + 0.3, 4.0, WALK_W, yaw))
            # mask for the generated trees: bank + walk + strip
            far_ = BANK_IN + WALK_W + STRIP_W
            poly = [a - nrm * BANK_OUT, b - nrm * BANK_OUT, b + nrm * far_, a + nrm * far_]
            G.poly(dr, [tuple(v) for v in poly])
        # furniture along the strip
        S = _resample(line, PALM_GAP)
        acc_bin = acc_sh = 0.0
        for k in range(1, len(S) - 1):
            a, b = S[k - 1], S[k + 1]
            d = b - a
            u = d / max(1e-6, np.hypot(*d))
            nrm = np.array([-u[1], u[0]])
            if is_lake(*(S[k] + nrm * 8)) and not is_lake(*(S[k] - nrm * 8)):
                nrm = -nrm
            yaw = math.atan2(-u[1], u[0])
            base = S[k]

            def free(q, need=6.0):
                i, j = int((q[0] - G.X0) / RES), int((q[1] - G.Z0) / RES)
                return 0 <= i < nx and 0 <= j < nz and d_road[i, j] > need and d_bld[i, j] > need and not lmk[i, j]
            palm = base + nrm * (BANK_IN + WALK_W + 7.0)
            if free(palm):
                models.append("FANPALM %.2f %.2f %.2f %.4f %.3f" % (palm[0], WALK_TOP - 0.6, palm[1], rng.uniform(0, 6.28),
                                                                   rng.uniform(0.9, 1.15)))
                stats["palms"] += 1
            bush = base + u * (PALM_GAP / 2) + nrm * (BANK_IN + WALK_W + 4.5)
            if free(bush, 4.0):
                if k % 3 == 1:
                    models.append("PLANTER %.2f %.2f %.2f %.4f 1" % (bush[0], WALK_TOP - 0.35, bush[1], yaw))
                    stats["planters"] += 1
                else:
                    models.append("BUSH %.2f %.2f %.2f %.4f %.3f" % (bush[0], WALK_TOP - 0.5, bush[1], rng.uniform(0, 6.28),
                                                                    rng.uniform(0.8, 1.2)))
                    stats["bushes"] += 1
            acc_bin += PALM_GAP
            acc_sh += PALM_GAP
            if acc_bin >= BIN_GAP:
                q = base + u * 4.0 + nrm * (BANK_IN + WALK_W + 1.6)
                if free(q, 2.0):
                    models.append("BIN %.2f %.2f %.2f %.4f 1" % (q[0], WALK_TOP - 0.35, q[1], yaw))
                    stats["bins"] += 1
                    acc_bin = 0.0
            if acc_sh >= SHELTER_GAP:
                q = base + nrm * (BANK_IN - 4.5)
                models.append("SHELTER %.2f %.2f %.2f %.4f 1" % (q[0], WALK_TOP - 1.2, q[1], yaw))
                # a flat pad under it (the bank there at walk level)
                for oa in np.arange(-6, 6.1, 2.0):
                    for ob in np.arange(-6, 6.1, 2.0):
                        qq = q + u * oa + nrm * ob
                        setcol(qq[0], qq[1], WALK_TOP - 1.25, mode="max")
                stats["shelters"] += 1
                acc_sh = 0.0

    # ------------------------------------------------------------------ 2. the Kabar Aye green bank (picture 1)
    lake_d = distance_transform_edt(~lake) * RES
    for e in prof:
        if e.get("name") != KA_ROAD or e.get("raised") or len(e["pts"]) < 2:
            continue
        P = np.array([[p[0], p[2]] for p in e["pts"]], float)
        Y = np.array([p[1] for p in e["pts"]], float)
        L = np.hypot(*np.diff(P, axis=0).T)
        cum = np.concatenate([[0], np.cumsum(L)])
        if cum[-1] < 30:
            continue
        for side in (-1, 1):
            off0 = (e["half"][0] if side < 0 else e["half"][1]) + e["walk"]
            s_ = 0.0
            post_acc = 0.0
            tree_acc = TREE_GAP / 2
            run_pts = []
            nrail = [0]

            def flush_rail(end=False):
                if len(run_pts) >= 2:
                    (a_, ya), (b_, yb) = run_pts[0], run_pts[-1]
                    dd = b_ - a_
                    Lr = float(np.hypot(*dd))
                    if Lr > 0.5:
                        yaw_ = math.atan2(-dd[1], dd[0])
                        m_ = (a_ + b_) / 2
                        alt = 0.05 * (nrail[0] % 2)
                        nrail[0] += 1
                        yb_ = (ya + yb) / 2
                        parts.append("BRAIL %.2f %.2f %.2f %.2f 0.18 0.18 %.5f" % (m_[0], yb_ + 1.75 + alt, m_[1], Lr + 0.1, yaw_))
                        parts.append("BRAIL %.2f %.2f %.2f %.2f 0.12 0.12 %.5f" % (m_[0], yb_ + 0.95 + alt, m_[1], Lr + 0.1, yaw_))
                last = run_pts[-1] if run_pts and not end else None
                run_pts.clear()
                if last is not None:
                    run_pts.append(last)
            while s_ <= cum[-1]:
                k = max(0, min(int(np.searchsorted(cum, s_) - 1), len(L) - 1))
                t = (s_ - cum[k]) / max(L[k], 1e-6)
                p = P[k] + (P[k + 1] - P[k]) * t
                y = Y[k] + (Y[k + 1] - Y[k]) * t
                d = (P[k + 1] - P[k]) / max(L[k], 1e-6)
                nrm = np.array([-d[1], d[0]]) * side
                back = p + nrm * off0
                # open frontage: no building within 12 m, no lake within 40 m (that side is the lake walk), not
                # another road's corridor 3 m out
                probe = back + nrm * 18
                gi, gj = int((probe[0] - G.X0) / RES), int((probe[1] - G.Z0) / RES)
                ok = (0 <= gi < nx and 0 <= gj < nz and d_bld[gi, gj] > 36 and lake_d[gi, gj] > 120 and not road[gi, gj]
                      and not lmk[gi, gj] and not outside[gi, gj])
                if ok:
                    stats["bank_m"] += 3.0 / 3
                    base_y = y + 0.5
                    for off in np.arange(2.0, BANK_FLAT + 0.1, 2.0):
                        q = back + nrm * off
                        h_t = base_y + min(1.0, max(0.0, (off - 2.0) / BANK_RUN)) * BANK_RISE
                        g_, _, _ = ground(*q)
                        setcol(q[0], q[1], max(h_t, g_ - 0.0) if off > BANK_RUN + 2 else h_t, mode="max")
                    post_acc += 3.0
                    yaw = math.atan2(-d[1], d[0])
                    rp = back + nrm * 1.0
                    if post_acc >= 6.0:
                        parts.append("BPOST %.2f %.2f %.2f 0.25 1.80 0.25 %.5f" % (rp[0], base_y + 0.9, rp[1], yaw))
                        stats["rail_posts"] += 1
                        post_acc = 0.0
                    # rails: chords of up to 8 samples (24 studs); neighbours at alternating heights (no shared planes)
                    run_pts.append((rp.copy(), base_y))
                    if len(run_pts) >= 9:
                        flush_rail()
                    tree_acc += 3.0
                    if tree_acc >= TREE_GAP:
                        tq = back + nrm * TREE_OFF
                        models.append("BANKTREE %.2f %.2f %.2f %.4f %.3f" % (tq[0], base_y + BANK_RISE - 0.3, tq[1],
                                                                            rng.uniform(0, 6.28), rng.uniform(0.92, 1.08)))
                        stats["bank_trees"] += 1
                        tree_acc = 0.0
                    poly = [back - d * 2 + nrm * 0, back + d * 2, back + d * 2 + nrm * (BANK_FLAT + 4),
                            back - d * 2 + nrm * (BANK_FLAT + 4)]
                    G.poly(dr, [tuple(v) for v in poly])
                else:
                    tree_acc = TREE_GAP / 2
                    flush_rail(True)
                s_ += 3.0
            flush_rail(True)
    cols = [(G.X0 + i * RES + RES / 2, G.Z0 + j * RES + RES / 2, top, wet) for (i, j), (top, wet) in colmap.items()]
    stats["terrain_cols"] = len(cols)
    stats["walk_m"] = round(stats["walk_m"])
    stats["bank_m"] = round(stats["bank_m"])
    return dict(cols=cols, parts=parts, models=models, mask=G.arr(mask_img), stats=stats)
