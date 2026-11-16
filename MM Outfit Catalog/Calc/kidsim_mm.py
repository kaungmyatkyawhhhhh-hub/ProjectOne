"""Impatient-kid sim for MM Outfit Catalog's first 5 minutes (16 Nov 2026).

No currency here: the "economy" is a chain of steps with fixed costs in seconds (read from the live build):
loading cover -> spawn (a View outfit prompt already in reach) -> viewer -> Try On -> see it on you ->
more outfits / Featured NEW / runway show / photo booth. A kid quits when boredom > patience.
Boredom +1/s while nothing new happens, x0.5 while something is tappable, x1.4 while a screen is just waiting
(loading). Rewards (new outfit seen, outfit on ME, runway hearts, photo) cut boredom, with habituation.
"""
import random, statistics as st

def kid(rng, patience, v):
    t, bored, seen, had = 0.0, 0.0, 0, 0
    def reward(size):
        nonlocal bored, had
        bored = max(0.0, bored - size / (1 + 0.35 * had))
        had += 1
    def wait(sec, mult):
        nonlocal t, bored
        bored += sec * mult
        t += sec
        return bored <= patience
    # 1. loading cover (branded, but nothing to do)
    if not wait(v["loading"], 1.4 if not v["loading_tip"] else 1.0): return t
    # 2. spawn: the hint + a View outfit prompt in reach (or a walk to the nearest mannequin)
    react = rng.uniform(0.6, 2.2)
    if not wait(react + v["walk_to_first"], 0.5): return t
    for minute_actions in range(400):
        if t > 300: return 300
        # open a viewer: a NEW outfit spinning = reward (smaller once many seen)
        if not wait(v["open_viewer"], 0.5): return t
        seen += 1
        reward(9 if seen <= 15 else 2)
        # wants it ON them: taps to Try On (+ close the viewer to see it)
        if rng.random() < v["try_rate"]:
            if not wait(v["try_taps"] * rng.uniform(0.8, 1.6), 0.6): return t
            reward(14)  # the best moment: the whole outfit on you
        # side quests that some kids find (each once)
        if seen == 2 and rng.random() < v["runway_find"]:
            if not wait(rng.uniform(3, 6), 0.5): return t
            reward(16)  # spotlight + hearts
        if seen == 4 and rng.random() < v["booth_find"]:
            if not wait(rng.uniform(4, 8), 0.5): return t
            reward(12)
        # walk to the next mannequin (pads line the runway, 3-5 studs apart)
        if not wait(rng.uniform(2, 4) + rng.uniform(0.6, 2.2), 0.5 if seen < 15 else 1.0): return t
    return t

def run(v, n=2500, median=11.0, seed=1):
    rng = random.Random(seed)
    times = []
    for _ in range(n):
        p = rng.lognormvariate(0, 0.45) * median
        times.append(kid(rng, p, v))
    stay = {s: round(100 * sum(1 for x in times if x >= s) / n) for s in (15, 30, 60, 120, 180, 300)}
    return stay

LIVE = dict(loading=9.0, loading_tip=False, walk_to_first=0.0, open_viewer=1.2,
            try_rate=0.55, try_taps=4.0,  # viewer -> Outfit actions -> Try On -> panel closes viewer (3 taps + wait)
            runway_find=0.25, booth_find=0.15)
VERSIONS = [
    ("A live", {}),
    ("B + tip line on the loading cover", dict(loading_tip=True)),
    ("C + 'Try it on' button in the viewer (1 tap)", dict(loading_tip=True, try_taps=1.5, try_rate=0.7)),
    ("D + runway ring visible from spawn (sign)", dict(loading_tip=True, try_taps=1.5, try_rate=0.7, runway_find=0.45)),
    ("E + Photo booth sign", dict(loading_tip=True, try_taps=1.5, try_rate=0.7, runway_find=0.45, booth_find=0.3)),
]

if __name__ == "__main__":
    for name, change in VERSIONS:
        v = dict(LIVE, **change)
        row = [f"{name:48s}"]
        for med in (7, 11, 16):
            s = run(v, median=med)
            row.append(f"p{med}: " + " ".join(f"{k}s {s[k]:3d}%" for k in (30, 60, 300)))
        print(" | ".join(row))
