"""TITAN ARC pacing bot (draft v0, 11 Nov 2026).
A best-choice player in district 1-2: walks to the best prop it can break, stomps, buys the cheapest useful upgrade.
Checks the vault targets (K02/K03): something every ~3 s in the first 30 s, 90% of gaps <= 7 s in the first 3 min,
no wait over ~20 s in the first 10 min, first form ~60 s, first boss 5-10 min.
Run: python3 titansim.py
"""
import random, statistics

CFG = dict(
    # props: (name, min height in m to break it, mass it gives, coins it gives)
    props=[("Flower", 0, 1, 1), ("Bike", 2.2, 4, 3), ("Car", 3.5, 14, 8), ("Bus", 6, 45, 22),
           ("House", 10, 150, 60), ("Shop row", 18, 520, 180), ("Tower block", 32, 1900, 550)],
    walk=(0.9, 2.0),            # seconds between props (dense streets)
    mass_to_height=lambda m: 1.7 * (1 + m / 40.0) ** 0.24,   # height in metres from total mass (tuned 11 Nov)
    forms=[("Rookie", 0), ("Brute", 2.2), ("Stone Titan", 12.0), ("Iron Titan", 24.0)],  # height gates (m)
    district2_height=18.0,
    boss_height=34.0,           # Scrap Colossus gate (end of the district 1-2 slice)
    welcome_coins=10,
    upgrades=dict(              # name: (base cost, growth, effect per level)
        power=(8, 2.1, 0.35),      # +35% mass per stomp per level
        shock=(20, 2.6, 1),         # +1 extra prop hit per stomp (shockwave), max 4
        speed=(12, 1.7, 0.08),      # -8% walk time per level, max 6
    ),
    combo_every=15, combo_bonus=6.0,   # every 15th stomp = a GROUND POUND worth x6 (the 'comet')
)

def run(seed, cfg=CFG, limit=900):
    r = random.Random(seed)
    t, mass, coins = 0.0, 0.0, cfg["welcome_coins"]
    lv = dict(power=0, shock=0, speed=0)
    events, miles = [0.0], {}
    form_i, stomps = 0, 0
    while t < limit:
        h = cfg["mass_to_height"](mass)
        # milestones
        while form_i + 1 < len(cfg["forms"]) and h >= cfg["forms"][form_i + 1][1]:
            form_i += 1; miles[cfg["forms"][form_i][0]] = t; events.append(t)
        if "district2" not in miles and h >= cfg["district2_height"]: miles["district2"] = t; events.append(t)
        if h >= cfg["boss_height"]: miles["boss"] = t; break
        # buy the cheapest affordable upgrade (an event)
        bought = True
        while bought:
            bought = False
            opts = []
            for k, (base, g, _) in cfg["upgrades"].items():
                if k == "shock" and lv[k] >= 4: continue
                if k == "speed" and lv[k] >= 6: continue
                opts.append((base * g ** lv[k], k))
            c, k = min(opts)
            if coins >= c:
                coins -= c; lv[k] += 1; events.append(t); bought = True
        # walk + stomp
        best = max((p for p in cfg["props"] if h >= p[1]), key=lambda p: p[2])
        t += r.uniform(*cfg["walk"]) * (1 - 0.08 * lv["speed"])
        stomps += 1
        mult = (1 + 0.35 * lv["power"]) * (1 + lv["shock"])
        if stomps % cfg["combo_every"] == 0: mult *= cfg["combo_bonus"]
        mass += best[2] * mult; coins += best[3] * (1 + lv["shock"])
        events.append(t)
    gaps = [b - a for a, b in zip(events, events[1:])]
    def window(lo, hi):
        g = [b - a for a, b in zip(events, events[1:]) if lo <= a < hi]
        return g or [0]
    return miles, window(0, 30), window(0, 180), window(0, 600), cfg["mass_to_height"](mass)

if __name__ == "__main__":
    rows = [run(s) for s in range(20)]
    def med(key): 
        v = [m[key] for m, *_ in rows if key in m]; return (statistics.median(v), min(v), max(v), len(v)) if v else None
    for k in ["Brute", "Stone Titan", "district2", "Iron Titan", "boss"]:
        x = med(k)
        print(f"{k:12s}", "never" if not x else f"median {x[0]:6.1f} s ({x[0]/60:4.1f} min)  range {x[1]:.0f}-{x[2]:.0f} s  runs {x[3]}/20")
    g30 = [g for _, a, *_ in rows for g in a]; g180 = [g for _, _, b, *_ in rows for g in b]; g600 = [g for _, _, _, c, _ in rows for g in c]
    print(f"first 30 s : max gap {max(g30):.1f} s")
    print(f"first 3 min: max gap {max(g180):.1f} s, share <= 7 s {100*sum(g<=7 for g in g180)/len(g180):.0f}%, events/run {len(g180)/20:.0f}")
    print(f"first 10 min: max gap {max(g600):.1f} s")
