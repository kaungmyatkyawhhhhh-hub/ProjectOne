"""Stomp Evolution: does 'every stomp pays, even on bare ground' break the pacing? (11 Nov 2026, after watching Titan Simulator clips)
In Titan Simulator every click paid, with no target. Here: while walking between props the player keeps tapping
(one stomp per 0.45 s) and each bare-ground stomp pays FRAC x the best prop's Mass (no coins, no shockwave).
Run: python3 anytap.py
"""
import random, statistics, copy
from titansim import CFG

def run(seed, frac, cfg=CFG, limit=1200, tap=0.45):
    r = random.Random(seed)
    t, mass, coins = 0.0, 0.0, cfg["welcome_coins"]
    lv = dict(power=0, shock=0, speed=0); miles = {}; form_i = 0; stomps = 0; taps = 0; paid = 0; evs=[0.0]
    while t < limit:
        h = cfg["mass_to_height"](mass)
        while form_i + 1 < len(cfg["forms"]) and h >= cfg["forms"][form_i + 1][1]:
            form_i += 1; miles[cfg["forms"][form_i][0]] = t
        if h >= cfg["boss_height"]: miles["boss"] = t; break
        bought = True
        while bought:
            bought = False; opts = []
            for k, (base, g, _) in cfg["upgrades"].items():
                if k == "shock" and lv[k] >= 4: continue
                if k == "speed" and lv[k] >= 6: continue
                opts.append((base * g ** lv[k], k))
            c, k = min(opts)
            if coins >= c: coins -= c; lv[k] += 1; bought = True
        best = max((p for p in cfg["props"] if h >= p[1]), key=lambda p: p[2])
        w = r.uniform(*cfg["walk"]) * (1 - 0.08 * lv["speed"])
        n = int(w / tap)                       # bare-ground stomps on the way
        taps += n + 1
        if frac > 0:
            mass += n * frac * best[2] * (1 + 0.35 * lv["power"]); paid += n + 1
            for i in range(n): evs.append(t + (i + 1) * tap)
        else: paid += 1
        t += w; stomps += 1; evs.append(t)
        mult = (1 + 0.35 * lv["power"]) * (1 + lv["shock"])
        if stomps % cfg["combo_every"] == 0: mult *= cfg["combo_bonus"]
        mass += best[2] * mult; coins += best[3] * (1 + lv["shock"])
    g=[b-a for a,b in zip(evs,evs[1:]) if a<60]
    return miles, paid / max(1, taps), max(g)

print("frac  first form  boss (min)  taps that pay  longest wait for a reward in minute 1")
for frac in [0, 0.05, 0.10, 0.15, 0.25, 0.50]:
    rows = [run(s, frac) for s in range(200)]
    f = statistics.median(m.get("Brute", 9e9) for m, *_ in rows); b = statistics.median(m.get("boss", 9e9) for m, *_ in rows)
    print(f"{frac:4.2f}  {f:7.1f} s  {b/60:8.1f}     {100*statistics.mean(p for _, p, _ in rows):5.0f}%        {statistics.median(g for *_, g in rows):.1f} s")
