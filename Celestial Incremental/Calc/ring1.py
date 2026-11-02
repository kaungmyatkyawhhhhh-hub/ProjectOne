# Ring 1 prices (owner, 2 Nov) - maths, not playtesting. Same formulas as econ.py (design note, section 1).
# Rules from the owner:
#  * unlock nodes = the new tier's first body cost 10*8^k: Lunar Pull 80, Planet Seed 640, Gas Giant 5,120; First Light free
#  * Orbit Speed (all x1.5) and Comet Lure (comets every 45 s -> 30 s): each pays back in about the same time as the best
#    next body at the moment a normal player can first afford it, cost ~30-60 s of income
#  * check: all of ring 1 bought back from zero in ~2 min at a fresh-run income after Supernova 1
# Comets (design): one every 45 s (30 s with Comet Lure), each worth 30-60 s of income (mean 45 s). ASSUMPTION: a normal
# player catches about half of them.
#
# Method: run the best-choice buyer (bodies + unlock nodes) and record, every second, the income I and the best body
# payback P (cost / extra income of the best body). A node with extra income g*I priced at C pays back in C/(g*I).
#  Orbit Speed: g = 0.5 (x1.5). Comet Lure: g = catch * 45 s * (1/30 - 1/45) = 0.25 (with catch 0.5).
# The node is priced at the first moment where "payback = P" gives a cost of 45 s of income (mid of 30-60):
#  Orbit: C = 45*I and C/(0.5 I) = 90 s -> the moment P reaches 90 s. Lure: C/(0.25 I) = 180 s -> P reaches 180 s.
# (Real time = best-choice time x ~1.4, the design's "real player is ~1.3-1.5x slower".)
from econ import base_cost, tier_income

CATCH, COMET_S = 0.5, 45.0
REAL = 1.4
UNLOCK = {"LunarPull": 1, "PlanetSeed": 2, "GasGiant": 3}


def comet_share(lure):
    return CATCH * COMET_S / (30.0 if lure else 45.0)


def run(nodes, mult=1.0, t_max=4000, until_all=False, trace=False):
    own = [1, 0, 0, 0]                       # the asteroid already orbits at 0 s
    have = {"FirstLight": True}              # free (tutorial step 2): asteroids x2
    cash, t, log = 0.0, 0, []

    def m_all():
        return mult * (1.5 if have.get("OrbitSpeed") else 1.0) * (1 + comet_share(have.get("CometLure")))

    def tier_inc(k, n):
        return tier_income(k, n) * (2 if k == 0 else 1)

    def body_options():
        out = []
        for k in range(4):
            if k > 0 and not have.get([n for n, kk in UNLOCK.items() if kk == k][0]):
                continue
            c = base_cost(k) * 1.15 ** own[k]
            g = (tier_inc(k, own[k] + 1) - tier_inc(k, own[k])) * m_all()
            out.append((c / g, c, ("body", k)))
        return out

    while t < t_max:
        inc = sum(tier_inc(k, own[k]) for k in range(4)) * m_all()
        opts = body_options()
        P = min(o[0] for o in opts)
        if trace:
            log.append((t, inc, P))
        for nid, c in nodes.items():
            if have.get(nid):
                continue
            if nid in UNLOCK:
                k = UNLOCK[nid]
                g = tier_inc(k, 1) * m_all()
                opts.append(((c + base_cost(k)) / g, c, ("node", nid)))
            elif nid == "OrbitSpeed":
                opts.append((c / (inc / 3.0), c, ("node", nid)))   # x1.5 of the whole = +1/3 of the new total
            elif nid == "CometLure":
                g = inc * (comet_share(True) - comet_share(False)) / (1 + comet_share(False))
                opts.append((c / g, c, ("node", nid)))
        best = min(opts, key=lambda o: o[0] + max(0, o[1] - cash) / inc)
        if cash >= best[1]:
            cash -= best[1]
            kind, what = best[2]
            if kind == "body":
                own[what] += 1
            else:
                have[what] = True
                if until_all and all(have.get(n) for n in nodes):
                    return t, own, log
            continue
        cash += inc
        t += 1
    return t, own, log


def nice(x):
    import math
    e = 10 ** (len(str(int(x))) - 2)
    return int(round(x / e) * e)


if __name__ == "__main__":
    unlock = {n: base_cost(k) for n, k in UNLOCK.items()}
    print("Unlock nodes = 10*8^k:", unlock)
    # trace a run with only the unlock nodes (no Orbit / Lure yet; comets at the base 45 s)
    _, _, log = run(unlock, t_max=1500, trace=True)
    prices = {}
    for nid, target_P, g in (("OrbitSpeed", 90.0, 0.5), ("CometLure", 180.0, 0.25)):
        for t, inc, P in log:
            if P >= target_P:
                c = 45.0 * inc
                prices[nid] = nice(c)
                print(f"{nid}: best body payback reaches {target_P:.0f} s at {t} s best-choice (~{t*REAL/60:.1f} min real), "
                      f"income {inc:.0f}/s -> cost 45 s of income = {c:.0f} -> {prices[nid]:,}; "
                      f"payback {prices[nid]/(g*inc):.0f} s vs best body {P:.0f} s")
                break
    nodes = dict(unlock, **prices)
    t, own, _ = run(nodes, until_all=True)
    print(f"\nFresh game (mult 1): whole ring 1 owned at {t} s best-choice (~{t*REAL/60:.1f} min real), bodies {own}")
    t2, own2, _ = run(nodes, mult=2.0, until_all=True)
    print(f"Rebuy check after Supernova 1 (fresh run, x(1 + 0.1*10 shards) = x2): whole ring 1 at {t2} s best-choice "
          f"(~{t2*REAL/60:.1f} min real), bodies {own2}")
    # how much of it is the unlock nodes alone?
    t3, _, _ = run(unlock, mult=2.0, until_all=True)
    print(f"  of which the 3 unlock nodes alone: {t3} s best-choice (~{t3*REAL/60:.1f} min real)")
    for scale in (0.5, 0.25):
        sc = dict(unlock, **{k: nice(v * scale) for k, v in prices.items()})
        t4, _, _ = run(sc, mult=2.0, until_all=True)
        print(f"  Orbit/Lure x{scale}: {sc['OrbitSpeed']:,} / {sc['CometLure']:,} -> whole ring at {t4} s (~{t4*REAL/60:.1f} min real)")

    # FINAL (x0.5 to fit the ~2 min rebuy): where each is first affordable in a fresh game and its payback there
    final = dict(unlock, OrbitSpeed=nice(prices["OrbitSpeed"] * 0.5), CometLure=nice(prices["CometLure"] * 0.5))
    print("\nFINAL:", {k: f"{v:,}" for k, v in final.items()})
    _, _, log = run(unlock, t_max=1500, trace=True)
    cash_if_saving = 0.0
    for nid, g in (("OrbitSpeed", 0.5), ("CometLure", 0.25)):
        c = final[nid]
        for t, inc, P in log:
            if c <= 45.0 * inc:   # the moment it costs <= 45 s of income (a player can save for it in under a minute)
                print(f"  {nid} {c:,}: costs 45 s of income at {t} s best-choice (~{t*REAL/60:.1f} min real), "
                      f"income {inc:.0f}/s, payback {c/(g*inc):.0f} s vs best body {P:.0f} s")
                break
    tf, ownf, _ = run(final, until_all=True)
    tr, ownr, _ = run(final, mult=2.0, until_all=True)
    print(f"  fresh game: whole ring 1 at {tf} s (~{tf*REAL/60:.1f} min real); rebuy after Supernova 1: {tr} s "
          f"(~{tr/60:.1f} min best-choice, ~{tr*REAL/60:.1f} min real)")
