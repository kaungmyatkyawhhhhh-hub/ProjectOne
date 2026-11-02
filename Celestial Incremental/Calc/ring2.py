# Ring 2 (STELLAR branch) + Supernova Readiness prices (alpha part 1, 3 Nov) - maths, not playtesting.
# Same formulas as econ.py / ring1.py (design note, section 1) and the ring-1 prices in the game (EconConfig).
#  * Supernova: ready at 1M stardust EARNED this run; shards = floor(10 * sqrt(earned / 1e6)), +20% with Readiness
#  * reset: stardust, bodies (1 asteroid back), ring 1. Keeps: shards, ring 2.
#  * design rule for the shard ring: "a sensible build is worth about x(1 + 0.1 * shards earned)" income
#  * STELLAR: Starfire (all x1.5 a level, 5 levels), Star tier (Supernova 1), Binary Star tier (Supernova 3),
#    Heavy Elements (each tier x(1 + 0.25 * tier number), tier number 1 = Asteroid)
# Method:
#  1. the effective multiplier of a build = (time to 1M with no build) / (time to 1M with it) (the best-choice buyer; a new tier
#     isn't a flat multiplier, so its worth is measured by how much faster the run gets)
#  2. buy order: Starfire 1, Star, Starfire 2, Heavy Elements, Starfire 3, Binary Star, Starfire 4, Starfire 5
#  3. each purchase is priced so that once it's bought, the build's multiplier = 1 + 0.1 * (shards spent so far):
#     shards needed = (M_after - 1) / 0.1, cost = that - spent before (rounded)
#  4. then the campaign: Supernova as soon as ready, spend shards in that order, report each run's length
# Real time = best-choice time x ~1.4 (design: "a real player is ~1.3-1.5x slower").
import math
from econ import base_cost, tier_income

REAL = 1.4
CATCH, COMET_S = 0.5, 45.0
RING1 = {"LunarPull": (80, 1), "PlanetSeed": (640, 2), "GasGiant": (5120, 3), "OrbitSpeed": (55000, None), "CometLure": (80000, None)}
NEED = 1e6


def shards_of(earned, readiness):
    base = 10 * math.sqrt(earned / NEED)
    return math.floor(base * (1.2 if readiness else 1.0))


def run(build, readiness_cost=None, t_max=20000):
    """One run from a fresh reset to 1M earned. build: starfire level, star, binary, heavy. Returns (seconds, readiness bought)."""
    tiers = 4 + (1 if build.get("star") else 0) + (1 if build.get("binary") else 0)
    own = [1] + [0] * 5
    have = {"FirstLight": True}
    cash = earned = 0.0
    t = 0
    sf = 1.5 ** build.get("starfire", 0)

    def heavy(k):
        return (1 + 0.25 * (k + 1)) if build.get("heavy") else 1.0

    def comet():
        return 1 + CATCH * COMET_S / (30.0 if have.get("CometLure") else 45.0)

    def m_all():
        return sf * (1.5 if have.get("OrbitSpeed") else 1.0) * comet()

    def tier_inc(k, n):
        return tier_income(k, n) * (2 if k == 0 else 1) * heavy(k)

    def open_(k):
        if k == 0:
            return True
        if k <= 3:
            return have.get([n for n, (c, kk) in RING1.items() if kk == k][0], False)
        return True  # (star / binary only counted in `tiers` when owned)

    while earned < NEED and t < t_max:
        inc = sum(tier_inc(k, own[k]) for k in range(tiers)) * m_all()
        opts = []
        for k in range(tiers):
            if not open_(k):
                continue
            c = base_cost(k) * 1.15 ** own[k]
            g = (tier_inc(k, own[k] + 1) - tier_inc(k, own[k])) * m_all()
            opts.append((c / g, c, ("body", k)))
        for nid, (c, k) in RING1.items():
            if have.get(nid):
                continue
            if k:
                g = tier_inc(k, 1) * m_all()
                opts.append(((c + base_cost(k)) / g, c, ("node", nid)))
            elif nid == "OrbitSpeed":
                opts.append((c / (inc / 3.0), c, ("node", nid)))
            else:
                g = inc * (CATCH * COMET_S * (1 / 30 - 1 / 45)) / comet()
                opts.append((c / g, c, ("node", nid)))
        best = min(opts, key=lambda o: o[0] + max(0, o[1] - cash) / max(inc, 1e-9))
        # Readiness: bought once its price is under 60 s of income (a player buys it when it's cheap for them)
        if readiness_cost and not have.get("Readiness") and cash >= readiness_cost and readiness_cost <= 60 * inc:
            cash -= readiness_cost
            have["Readiness"] = True
            continue
        if cash >= best[1]:
            cash -= best[1]
            kind, what = best[2]
            if kind == "body":
                own[what] += 1
            else:
                have[what] = True
            continue
        cash += inc
        earned += inc
        t += 1
    return t, have.get("Readiness", False)


def eff_mult(build):
    return run({})[0] / run(build)[0]


PLAN = [("starfire", 1), ("star", True), ("starfire", 2), ("heavy", True), ("starfire", 3), ("binary", True), ("starfire", 4), ("starfire", 5)]
GATE = {"binary": 3}  # Binary Star needs Supernova 3 (design)


def nice(x):
    if x < 10:
        return max(1, round(x))
    mag = 10 ** math.floor(math.log10(x))
    for step in (1, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10):
        if x <= step * mag * 1.12:
            return int(step * mag)
    return int(10 * mag)


def price_ring2():
    build, spent, prices = {}, 0, []
    for key, val in PLAN:
        build = dict(build)
        build[key] = val
        m = eff_mult(build)
        need = (m - 1) / 0.1
        cost = nice(max(1, need - spent))
        prices.append((key, val, cost, m))
        spent += cost
    return prices


def readiness_price():
    # the first run's income at ~70% of the way to 1M, x60 s (then rounded): affordable late in run 1, a real choice
    tiers, own = 4, [1, 0, 0, 0]
    t, _ = run({})
    # (cheap estimate: average income of run 1 = 1M / t; late-run income ~2x the average)
    late = 2 * NEED / t
    return nice(60 * late)


if __name__ == "__main__":
    base_t = run({})[0]
    print(f"run 1 (no build): {base_t} s best-choice = {base_t / 60:.1f} min (~{base_t * REAL / 60:.1f} min real)")
    rp = readiness_price()
    print(f"Supernova Readiness (+20% shards): PROPOSED {rp:,} stardust (~60 s of late run-1 income)")
    prices = price_ring2()
    print("ring 2 STELLAR prices (rule: build = x(1 + 0.1 * shards spent)):")
    for key, val, cost, m in prices:
        print(f"  {key} {val}: {cost} shards  (build after it: x{m:.2f} effective)")
    # FINAL (what goes in EconConfig): the rule's prices, but the two tier unlocks get a floor (the rule says 2 and 1 shard:
    # in 1M runs a Star / Binary Star barely pays back, yet they're "new tier" moments, not 1-shard throwaways)
    FINAL = {("starfire", 1): 5, ("star", True): 3, ("starfire", 2): 8, ("heavy", True): 20, ("starfire", 3): 15,
             ("binary", True): 5, ("starfire", 4): 25, ("starfire", 5): 40}
    prices = [(k, v, FINAL[(k, v)], m) for k, v, _, m in prices]
    print("FINAL:", ", ".join(f"{k} {v}={c}" for k, v, c, _ in prices))
    # the campaign: Supernova as soon as ready; spend in plan order when affordable and allowed
    build, shards, novas, total = {}, 0, 0, 0.0
    queue = list(prices)
    print("campaign with FINAL prices (best-choice; real ~x1.4):")
    for i in range(1, 11):
        t, ready = run(build, rp)
        total += t
        got = shards_of(NEED, ready)
        novas += 1
        shards += got
        while queue:
            key, val, cost, _ = queue[0]
            if shards < cost or novas < GATE.get(key, 0):
                break
            shards -= cost
            build[key] = val
            queue.pop(0)
        print(f"  Supernova {i}: run {t / 60:.1f} min (~{t * REAL / 60:.1f} real), at {total / 60:.1f} min total, +{got} shards (readiness {ready}), build {build}, left {shards}")
