# FEEL PASS 2 (5 Nov): the Studio bot showed runs 4-6 collapse (18-35 s) once ring 2 piles up (Starfire x1.75 a level,
# Heavy Elements, the Star tier at Supernova 1, the Binary Star tier at Supernova 3). This sim = the game's numbers (EconConfig,
# 5 Nov): bodies (levels / copies / named tiers), unlocks, 20 pads (7 x1.15), XP + the perks (cheapest first, tiers at
# LVL 1/10/20/30), ring 2 bought like the bot (StarTier, Starfire, HeavyElements, BinaryStar when affordable), shards =
# 14 x sqrt(earned/need) x 1.25^n, comets x1.5. Time = the BOT's time (buys every 0.25 s); real = x REAL.
# Calibrated to the bot (needs 300K, 1.8M, 9M, 36M, 108M): bot Supernovas at 4:35, 5:56, 7:06, 7:24, 7:58, 8:33.
import math, sys

REAL = 1.4
LVG, COPYB, COPYG, MAXC = 1.8, 50, 4, 5
UNLOCK = {1: 80, 2: 640, 3: 5120}
PADS = [15, 60, 150, 400, 1.2e3, 3e3, 8e3, 2e4, 6e4, 1.5e5, 4e5, 1e6, 2.5e6, 6e6, 1.5e7, 4e7, 1e8, 2.5e8, 6e8, 1.5e9]
PADBONUS = {3, 6, 9, 12, 15, 18, 20}
PERKS = [("Stardust", 1), ("FirstLight", 1), ("CometLure", 1), ("CometValue", 1), ("OrbitSpeed", 10), ("MoonGlow", 10), ("PlanetCore", 10),
         ("XPFlow", 10), ("Readiness", 20), ("GiantStorm", 20), ("CheapLevels", 20), ("SurgePower", 20), ("StarHeart", 30),
         ("CheapBodies", 30), ("LuckyComet", 30), ("PadPower", 30)]
TIERPERK = {0: "FirstLight", 1: "MoonGlow", 2: "PlanetCore", 3: "GiantStorm", 4: "StarHeart"}
R2 = {"Starfire": [5, 8, 15, 25, 40], "StarTier": [3], "HeavyElements": [20], "BinaryStar": [5]}


def xp_for(n):
    return 8 * (1.3 ** (n - 1) - 1) / 0.3


def run_campaign(needs, minutes=45, verbose=False):
    lv = [1, 0, 0, 0, 0, 0]
    cp = [1, 0, 0, 0, 0, 0]
    perk = {p: 0 for p, _ in PERKS}
    r2 = {k: 0 for k in R2}
    pads, xp, xpt, shards, novas = 0, 2.0, 2.0, 0, 0
    cash = earned = 0.0
    t = 0.0
    dt = 0.25
    times = []
    level = 1

    def tiers_open():
        n = 4
        if r2["StarTier"]: n = 5
        if r2["BinaryStar"]: n = 6
        return n

    def tinc(k, L=None, C=None):
        L = lv[k] if L is None else L
        C = cp[k] if C is None else C
        if L <= 0: return 0.0
        b = 5 ** k * L * max(C, 1) * 2 ** (min(L // 10, 9))
        if k in TIERPERK: b *= 1 + 0.5 * perk[TIERPERK[k]]
        if r2["HeavyElements"]: b *= 1 + 0.25 * (k + 1)
        return b

    def allm():
        m = (1 + 0.1 * perk["Stardust"]) * (1 + 0.05 * perk["OrbitSpeed"]) * 1.75 ** r2["Starfire"]
        each = 1.15 + 0.01 * perk["PadPower"]
        m *= each ** sum(1 for i in range(pads) if (i + 1) in PADBONUS)
        return m * 1.5  # comets

    def lvcost(k, L):
        return 10 * 8 ** k * LVG ** L * (1 - 0.03 * perk["CheapLevels"])

    def cpcost(k, C):
        return COPYB * 8 ** k * COPYG ** (max(C, 1) - 1) * (1 - 0.04 * perk["CheapBodies"])

    limit = minutes * 60 / REAL
    while t < limit:
        need = needs[min(novas, len(needs) - 1)] if novas < len(needs) else needs[-1] * 3 ** (novas - len(needs) + 1)
        inc = sum(tinc(k) for k in range(6)) * allm()
        # income + XP
        cash += inc * dt
        earned += inc * dt
        g = 0.12 * math.log10(1 + inc) ** 1.5 * (1 + 0.1 * perk["XPFlow"]) * dt
        xp += g
        xpt += g
        while xpt >= xp_for(level + 1): level += 1
        t += dt
        if earned >= need:
            got = math.floor(14 * math.sqrt(earned / need) * 1.25 ** novas * (1 + 0.02 * perk["Readiness"]))
            shards += got
            novas += 1
            times.append(t)
            if verbose: print(f"  Supernova {novas} at {t/60:.2f} bot-min ({t*REAL/60:.1f} real) +{got} shards, need {need:.3g}")
            lv = [1, 0, 0, 0, 0, 0]
            cp = [1, 0, 0, 0, 0, 0]
            cash = earned = 0.0
            # ring 2 like the bot
            bought = True
            while bought:
                bought = False
                for k in ("StarTier", "Starfire", "HeavyElements", "BinaryStar"):
                    c = R2[k][r2[k]] if r2[k] < len(R2[k]) else None
                    gate = (k != "BinaryStar" or novas >= 3) and (k not in ("HeavyElements", "BinaryStar") or r2["StarTier"])
                    if c and shards >= c and gate:
                        shards -= c
                        r2[k] += 1
                        bought = True
                        break
            continue
        # one buy per tick (the bot): perk, pad, body
        open_perks = [p for p, at in PERKS if level >= at and perk[p] < 10]
        if open_perks:
            p = min(open_perks, key=lambda q: perk[q])
            c = math.ceil(2 * 1.6 ** perk[p])
            if xp >= c:
                xp -= c
                perk[p] += 1
                continue
        if pads < 20 and cash >= PADS[pads] and PADS[pads] <= 45 * inc:
            cash -= PADS[pads]
            pads += 1
            continue
        m = allm()
        opts = []
        for k in range(tiers_open()):
            if lv[k] == 0:
                if k in UNLOCK:
                    if k == 1 or lv[k - 1] > 0: opts.append((UNLOCK[k], 5 ** k * m, ("u", k)))
                else:
                    opts.append((lvcost(k, 0), 5 ** k * m, ("u", k)))
                continue
            opts.append((lvcost(k, lv[k]), (tinc(k, lv[k] + 1) - tinc(k)) * m, ("l", k)))
            if cp[k] < MAXC: opts.append((cpcost(k, cp[k]), (tinc(k, C=cp[k] + 1) - tinc(k)) * m, ("c", k)))
        best = min(opts, key=lambda o: o[0] / max(o[1], 1e-9) + max(0, o[0] - cash) / max(inc, 1e-9))
        if cash >= best[0]:
            cash -= best[0]
            kind, k = best[2]
            if kind == "u": lv[k], cp[k] = 1, 1
            elif kind == "l": lv[k] += 1
            else: cp[k] += 1
    return times, level, pads


if __name__ == "__main__":
    print("calibration (the game's needs on 5 Nov): bot had 4:35, 5:56, 7:06, 7:24, 7:58, 8:33")
    run_campaign([3e5, 1.8e6, 9e6, 3.6e7, 1.08e8], minutes=14, verbose=True)
