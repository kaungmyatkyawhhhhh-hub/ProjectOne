"""
Fits the Summit Pass to the hill (2026-11-04): the first build sat its hairpin legs too far up the
face for their heights, so the road ran in cuttings up to ~150 studs deep. This searches the pass's
shape parameters (highway.PASS_PARAMS: where each stack of hairpins starts, the legs' direction,
length and spacing, the traverse between the stacks) one at a time, a few rounds, for the road that
needs the least digging and filling, keeping clear of the Mountain Road and its own legs apart.
Prints the best parameters to paste into highway.PASS_PARAMS.

usage (from Games/CityLegends): python tools/map_plan/pass_fit.py
"""
import json
import math
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import highway as hw  # noqa: E402

meta, H = hw.ground()
old = json.load(open(os.path.join(hw.RIV, "roads.json")))["roads"]
mr = [r for r in old if r["name"] == "Mountain Road"][0]["s"]
mr_xz = np.array([[q[0], q[2]] for q in mr])
others = np.array([[q[0], q[2]] for r in old if r["name"] not in ("Mountain Road",) for q in r["s"]])
link = json.load(open(os.path.join(hw.RIV, "highway.json")))["roads"][0]
link_xz = np.array([[q[0], q[2]] for q in link["s"]])
link_y = np.array([q[1] for q in link["s"]])
k = int(np.argmin(np.linalg.norm(link_xz - np.array(hw.PASS_START), axis=1)))
hw.PASS_START = (float(link_xz[k, 0]), float(link_xz[k, 1]))
y0 = float(link_y[k])
m = int(np.argmin(np.linalg.norm(mr_xz - np.array(hw.PASS_END), axis=1)))
hw.PASS_END = (float(mr_xz[m, 0]), float(mr_xz[m, 1]))
y1 = mr[m][1]


def score(P):
    try:
        ps, _ = hw.resample(hw.pass_line(P), False)
    except Exception:
        return 1e18, None
    for _ in range(3):
        q = ps.copy()
        q[3:-3] = (ps[1:-5] + ps[2:-4] + ps[3:-3] + ps[4:-2] + ps[5:-1]) / 5
        ps = q
    g = hw.smooth(hw.sample_h(meta, H, ps[:, 0], ps[:, 1]), 6, False)
    keep = hw.HIGHWAY_GRADE
    hw.HIGHWAY_GRADE = hw.PASS_GRADE
    y = hw.profile(g, hw.STEP, False, {0: y0, len(ps) - 1: y1})
    hw.HIGHWAY_GRADE = keep
    cut = np.maximum(g - y, 0)
    fill = np.maximum(y - g, 0)
    s = float(np.mean(cut ** 2) + 0.6 * np.mean(fill ** 2))
    # clear of the Mountain Road (apart from the run into the T) and of the other roads
    n = len(ps)
    body = ps[: max(1, n - 30)]
    dm = np.min(np.linalg.norm(body[:, None, :] - mr_xz[None, ::3, :], axis=2), axis=1)
    s += float(np.sum(np.maximum(78 - dm, 0) ** 2)) * 50
    # the pass's own legs apart (samples far along the road but close in space)
    sub = ps[::3]
    d2 = np.linalg.norm(sub[:, None, :] - sub[None, :, :], axis=2)
    idx = np.arange(len(sub))
    far = np.abs(idx[:, None] - idx[None, :]) > 40
    s += float(np.sum(np.maximum(44 - d2[far], 0) ** 2)) * 20
    # the grade it can't keep (the profile pins the ends): big penalty
    gr = np.abs(np.diff(y)) / hw.STEP
    s += float(np.sum(np.maximum(gr - hw.PASS_GRADE - 0.005, 0))) * 1e5
    return s, (float(cut.max()), float(fill.max()), float(cut.mean()), len(ps) * hw.STEP)


steps = {
    "w_x": [-60, -30, 30, 60], "w_z": [-60, -30, 30, 60], "w_ang": [-12, -6, 6, 12], "w_len": [-60, -30, 30, 60],
    "w_gap": [-12, -6, 6], "t1": [-80, -40, 40, 80], "t2": [-80, -40, 40, 80],
    "s_x": [-60, -30, 30, 60], "s_z": [-60, -30, 30, 60], "s_ang": [-10, -5, 5, 10], "s_len": [-60, -30, 30, 60],
    "s_gap": [-12, -6, 6],
}
P = dict(hw.PASS_PARAMS)
best, info = score(P)
print("start: score %.0f  max cut %.0f  max fill %.0f  mean cut %.1f  length %.0f" % (best, *info))
for rnd in range(4):
    improved = False
    for key, deltas in steps.items():
        for dv in deltas:
            Q = dict(P)
            Q[key] = P[key] + dv
            if key in ("w_gap", "s_gap") and not (48 <= Q[key] <= 76):
                continue
            if key in ("w_len", "s_len") and not (220 <= Q[key] <= 520):
                continue
            sc, inf = score(Q)
            if sc < best:
                best, info, P, improved = sc, inf, Q, True
    print("round %d: score %.0f  max cut %.0f  max fill %.0f  mean cut %.1f  length %.0f" % (rnd + 1, best, *info))
    # finer steps next round
    steps = {k: [d / 2 for d in v] for k, v in steps.items()}
    if not improved and rnd > 1:
        break
print("PASS_PARAMS = " + json.dumps({k: round(v, 1) if isinstance(v, float) else v for k, v in P.items()}))
