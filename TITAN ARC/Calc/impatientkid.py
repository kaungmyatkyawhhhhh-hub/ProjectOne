"""STOMP EVOLUTION impatient-kid simulation (owner's method), 11 Nov 2026.
DESIGN STAGE: there is no build, so this runs on the PLAN numbers (design doc v0 + titansim.py).
Re-run it on the LIVE config before any launch (the method's rule: read the live game, never the plan).
The kid walks the street and stomps the next prop; buys an upgrade when he can afford one and notices it.
Boredom: +1/s when nothing happens, x0.5 while something is pressable, x0.7 when a visible bar is about
to fill, x1.3 after 25 s with nothing NEW. Rewards cut boredom; repeats wear off, NEW things count most.
Patience per kid: lognormal, median 11 s (also 7 s and 16 s).
Run: python impatientkid.py
"""
import math, random, statistics as st

PROPS0 = [("Flower", 0, 1, 1), ("Bike", 2.2, 4, 3), ("Car", 3.5, 14, 8), ("Bus", 6, 45, 22),
         ("House", 10, 150, 60), ("Shop row", 18, 520, 180), ("Tower block", 32, 1900, 550)]
UPG = dict(power=(8, 2.1), shock=(20, 2.6), speed=(12, 1.7))   # base cost, growth
UPG_MAX = dict(power=99, shock=4, speed=6)
def height(m): return 1.7 * (1 + m / 40.0) ** 0.24

BASE = dict(
    name="A  the plan v0 (first evolve at 2.2 m, flowers only until then)",
    forms=[2.2, 12.0, 24.0],     # heights (m) where you evolve
    district2=18.0,
    welcome=10,
    starter_kinds=1,             # prop kinds on the first street (variety from second one)
    stomp_wear=0.020,            # how fast a repeated stomp gets boring
    first_pad_walk=(1.0, 2.0), pad_walk=(3.0, 6.0), notice=0.7,
    golden_first=None,           # a guaranteed golden prop near a new player at this time (s)
    golden_rate=1 / 200,
    combo_first=15, combo_every=15,
    stages=False,                # 3 visible growth stages inside each form
    mini_every=None,             # a small street event every N s (after minute 2.5)
    walk=(0.9, 2.0),
    bike_at=2.2,                 # height where bikes unlock
)
V = [BASE]
def add(name, **kw):
    v = dict(V[-1]); v.update(kw); v["name"] = name; V.append(v)
add("B  + evolution-first: 7 evolves before the boss, the first at 1.9 m", forms=[1.9, 2.8, 4.5, 8.0, 13.0, 21.0, 28.0])
add("C  + 3 prop kinds on the first street (flower, mailbox, bin)", starter_kinds=3, stomp_wear=0.014)
add("D  + step-on upgrade pads along the street (no detour)", pad_walk=(1.0, 2.0), notice=0.9)
add("E  + a golden prop for every new player at ~25 s, first Ground Pound at stomp 6", golden_first=(22, 32), combo_first=6)
add("F  + 3 visible growth stages inside each form", stages=True)
add("G  + a small street event every ~70 s after minute 2.5", mini_every=70)
add("H  + fill the 30-60 s hole: bikes at 2.05 m, second evolve at 2.4 m", bike_at=2.05, forms=[1.9, 2.4, 3.0, 4.5, 8.0, 13.0, 21.0, 28.0])

def kid(v, rng, patience, T=300, slow=None):
    PROPS = [p if p[0] != 'Bike' else ('Bike', v['bike_at'], 4, 3) for p in PROPS0]
    slow = slow or rng.uniform(1.25, 1.7)          # kids are slower than the pacing bot
    t = 0.0; mass = 0.0; coins = v["welcome"]; lv = dict(power=0, shock=0, speed=0)
    boredom = 0.0; seen = {}; S = dict(last_new=0.0, quit=None)
    news = [0.0]; tl = []; first_buy = None; stomps = 0
    forms_done = 0; props_open = 1; d2 = False; stage_done = set(); bought_kinds = set()
    golden_at = rng.uniform(*v["golden_first"]) if v["golden_first"] else None
    giant_at = rng.uniform(5, 40)                   # a much bigger player walks past (the plan's crown + bodies)
    rampage_at = rng.uniform(0, 600)                # server clock, every 10 min
    next_mini = 150 + rng.uniform(0, v["mini_every"]) if v["mini_every"] else None
    def reward(kind, base, new=False):
        nonlocal boredom
        n = seen.get(kind, 0); seen[kind] = n + 1
        wear = v["stomp_wear"] if kind == "stomp" else 0.05
        boredom -= base / (1 + wear * n) / (1 + 0.002 * sum(seen.values()))
        boredom = max(0.0, boredom)
        if new: S["last_new"] = t; news.append(t); tl.append((round(t, 1), kind))
    def advance(dt, rate):
        nonlocal t, boredom
        if t - S["last_new"] > 25: rate *= 1.3
        t += dt; boredom += rate * dt
        return boredom > patience
    if v["welcome"]: reward("gift", 6, new=True)
    def gates():
        nonlocal forms_done, props_open, d2
        h = height(mass)
        while props_open < len(PROPS) and h >= PROPS[props_open][1]:
            props_open += 1; reward("newprop", 8, new=True)
        while forms_done < len(v["forms"]) and h >= v["forms"][forms_done]:
            forms_done += 1; reward("evolve", 28, new=True); reward("newmove", 14)
        if not d2 and h >= v["district2"]: d2 = True; reward("newzone", 14, new=True)
        if v["stages"]:
            lo = v["forms"][forms_done - 1] if forms_done else 1.7
            hi = v["forms"][forms_done] if forms_done < len(v["forms"]) else lo * 1.5
            for f in (1 / 3, 2 / 3):
                if (forms_done, f) not in stage_done and h >= lo + (hi - lo) * f:
                    stage_done.add((forms_done, f)); reward("stage", 10, new=True)
    def next_gate_close():
        h = height(mass)
        nxt = [g for g in v["forms"] if g > h] + [p[1] for p in PROPS if p[1] > h]
        return bool(nxt) and (min(nxt) - h) / min(nxt) < 0.05
    while t < T:
        # timed things
        if t >= giant_at: giant_at = 1e9; reward("giant seen", 7, new=True)
        if t >= rampage_at: rampage_at += 600; reward("rampage", 20, new=True)
        if golden_at and t >= golden_at:
            golden_at = None; mass += 25 * max(p[2] for p in PROPS[:props_open]); reward("golden", 12, new=True); gates()
        if next_mini and t >= next_mini: next_mini += v["mini_every"] * rng.uniform(0.7, 1.3); reward("mini event", 10, new=True)
        # buy?
        opts = [(UPG[k][0] * UPG[k][1] ** lv[k], k) for k in UPG if lv[k] < UPG_MAX[k]]
        cost, k = min(opts)
        if coins >= cost and rng.random() < v["notice"]:
            walk = v["first_pad_walk"] if first_buy is None else v["pad_walk"]
            if advance(rng.uniform(*walk) + rng.uniform(0.6, 2.2), 0.5): return False, t, tl, first_buy, news
            coins -= cost; lv[k] += 1
            if first_buy is None: first_buy = t
            if k not in bought_kinds: bought_kinds.add(k); reward("new upgrade", 9, new=True)
            else: reward("buy", 3.5)
            continue
        # walk + stomp
        dt = rng.uniform(*v["walk"]) * slow * (1 - 0.08 * lv["speed"])
        if advance(dt, 0.5 * (0.7 if next_gate_close() else 1.0)): return False, t, tl, first_buy, news
        stomps += 1
        best = max(PROPS[:props_open], key=lambda p: p[2])
        mult = (1 + 0.35 * lv["power"]) * (1 + lv["shock"])
        is_combo = stomps == v["combo_first"] or (stomps > v["combo_first"] and (stomps - v["combo_first"]) % v["combo_every"] == 0)
        if is_combo: mult *= 6; reward("ground pound", 6, new=(seen.get("ground pound", 0) == 0))
        if rng.random() < v["golden_rate"]: mult *= 25; reward("golden", 12, new=True)
        mass += best[2] * mult; coins += best[3] * (1 + lv["shock"])
        reward("stomp", 1.6)
        if stomps % 8 == 0: reward("size up", 4)
        if v["starter_kinds"] >= 2 and stomps == 3: reward("newprop", 8, new=True)
        if v["starter_kinds"] >= 3 and stomps == 7: reward("newprop", 8, new=True)
        gates()
    return True, T, tl, first_buy, news

def run(v, n=2000, med=11, seed=1):
    rng = random.Random(seed); quits = []; fb = []; evo1 = []; dead = []; evos5 = []; dead5 = []
    for _ in range(n):
        pat = med * math.exp(rng.gauss(0, 0.35))
        stayed, t, tl, first_buy, news = kid(v, rng, pat)
        quits.append(300 if stayed else t)
        if first_buy is not None: fb.append(first_buy)
        e = [x for x, kind in tl if kind == "evolve"]
        if e: evo1.append(e[0])
        if stayed: evos5.append(len(e))
        m1 = [x for x in news if x <= 60] + [min(60, quits[-1])]
        dead.append(max(b - a for a, b in zip(m1, m1[1:])) if len(m1) > 1 else 60)
        if stayed:
            m5 = news + [300]; dead5.append(max(b - a for a, b in zip(m5, m5[1:])))
    stay = lambda s: 100 * sum(q >= s for q in quits) / n
    return dict(s15=stay(15), s30=stay(30), s60=stay(60), s120=stay(120), s180=stay(180), s300=stay(300),
                fb=st.median(fb) if fb else float("nan"), evo1=st.median(evo1) if evo1 else float("nan"),
                dead=st.median(dead), evos5=st.median(evos5) if evos5 else float("nan"),
                dead5=st.median(dead5) if dead5 else float("nan"))

def boss_time(v, runs=20):
    PROPS = [p if p[0] != 'Bike' else ('Bike', v['bike_at'], 4, 3) for p in PROPS0]
    """Best-choice bot (no boredom) to the boss gate at 34 m: checks the big moment does not move."""
    out = []
    for s in range(runs):
        rng = random.Random(100 + s); vv = dict(v)
        t = 0.0; mass = 0.0; coins = v["welcome"]; lv = dict(power=0, shock=0, speed=0); stomps = 0
        golden_at = sum(v["golden_first"]) / 2 if v["golden_first"] else None
        while height(mass) < 34 and t < 2000:
            if golden_at and t >= golden_at:
                golden_at = None; mass += 25 * max(p[2] for p in PROPS if height(mass) >= p[1])
            while True:
                cost, k = min((UPG[k][0] * UPG[k][1] ** lv[k], k) for k in UPG if lv[k] < UPG_MAX[k])
                if coins >= cost: coins -= cost; lv[k] += 1
                else: break
            t += rng.uniform(*v["walk"]) * (1 - 0.08 * lv["speed"]); stomps += 1
            best = max((p for p in PROPS if height(mass) >= p[1]), key=lambda p: p[2])
            mult = (1 + 0.35 * lv["power"]) * (1 + lv["shock"])
            if stomps == v["combo_first"] or (stomps > v["combo_first"] and (stomps - v["combo_first"]) % v["combo_every"] == 0): mult *= 6
            mass += best[2] * mult; coins += best[3] * (1 + lv["shock"])
        out.append(t)
    return st.median(out)

if __name__ == "__main__":
    print("IMPATIENT KID on the PLAN (2,000 kids per version, patience median 11 s)")
    print(f"{'version':74} 15s  30s  60s  2min 3min 5min | 5min@7s | 1st buy 1st evolve | no-NEW gap: min1  5min | evolves by 5min | boss (bot)")
    for v in V:
        r = run(v); r7 = run(v, med=7)
        print(f"{v['name']:74} {r['s15']:3.0f}% {r['s30']:3.0f}% {r['s60']:3.0f}% {r['s120']:3.0f}% {r['s180']:3.0f}% {r['s300']:3.0f}% |  {r7['s300']:3.0f}%   | {r['fb']:4.1f} s  {r['evo1']:5.1f} s   |      {r['dead']:4.1f} s {r['dead5']:5.1f} s |      {r['evos5']:2.0f}        | {boss_time(v)/60:4.1f} min")
    print()
    for med in (7, 16):
        a, f = run(V[0], med=med), run(V[-1], med=med)
        print(f"sensitivity, patience {med:2d} s: A stays 60 s {a['s60']:.0f}% / 5 min {a['s300']:.0f}%   ->   last version 60 s {f['s60']:.0f}% / 5 min {f['s300']:.0f}%")
    rng = random.Random(7)
    ok, t, tl, fb, news = kid(V[-1], rng, 11, slow=1.45)
    print("\nlast version, one median kid, NEW things in the first 60 s:")
    print("  " + "  ".join(f"{x:.0f}s {k}" for x, k in tl if x <= 75))
