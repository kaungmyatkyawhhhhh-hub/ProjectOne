# FEEL PASS (5 Nov) - PROPOSED numbers for body levels + named tiers, +BODY copies, island pads, Cosmic Level XP + perks.
# Maths, not playtesting. A best-choice buyer plays a fresh save for 30 real minutes; real time ~= sim time x REAL (design:
# players are ~1.3-1.5x slower). Vault note: "2026-11-05 Galaxy Incremental - Feel pass PLAN + numbers".
#  * body type k (0 Asteroid .. 3 Gas Giant in run 1; 4 Star from Supernova 1):
#      income = 5^k * level * copies * 2^(named tiers passed)   (a named tier every 10 levels: DUST, ROCK, IRON, ...)
#      UPGRADE (+1 level): 10 * 8^k * LV_GROWTH^level           (Regrowth's machine levels cost ~x1.22-1.33 a level)
#      +BODY (a copy in orbit, max 5): COPY_BASE * 8^k * COPY_GROWTH^(copies - 1)
#      UNLOCK Moon / Planet / Gas Giant: 80 / 640 / 5,120 (as now)
#  * pads: a chain, the next one lit; some give x1.15 stardust. KEPT through a Supernova
#  * Cosmic Level: XP/s = XP_BASE * log10(1 + stardust/s)^1.5; level n needs XP_NEED * XP_GROW^(n-1) more TOTAL XP; XP is
#    also spent on perks (the level never goes down: Regrowth's LVL + XP crystals). KEPT through a Supernova
#  * perks (XP), max PERK_MAX levels each, cost 2 * PERK_GROWTH^level: STARDUST +0.1x a level, FIRST LIGHT asteroids +0.5x
#    a level (stand-ins for the ~16 perks; the others are about comets, Surge, shards, XP)
#  * Supernova k needs NEED1 * NEED_GROWTH^(k-1) EARNED (kept things would make a flat need instant); Starfire +1 a Supernova
#  * comets: worth x1.5 income on average (as ring2.py)
import math
import sys

REAL = 1.4
NAMES = ["DUST", "ROCK", "IRON", "CRYSTAL", "PLASMA", "SOLAR", "NOVA", "PULSAR", "QUASAR", "COSMIC"]
TIERS = ["Asteroid", "Moon", "Planet", "Gas Giant", "Star"]
UNLOCK = {1: 80, 2: 640, 3: 5120}
LV_GROWTH = 1.8  # (5 Nov sweep: 1.25 gave a buy every ~1 s; 1.8 = one every ~6 s, like Regrowth)
MAX_COPIES, COPY_BASE, COPY_GROWTH = 5, 50, 4
XP_BASE, XP_NEED, XP_GROW = 0.12, 8, 1.3
PERK_MAX, PERK_GROWTH = 10, 1.6
# 20 pads (proposal): price, "*" = x1.15 stardust. Run 1 builds 1-10; the rest come in runs 2-4
PADS = [(15, ""), (60, ""), (150, "*"), (400, ""), (1.2e3, ""), (3e3, "*"), (8e3, ""), (2e4, ""), (6e4, "*"), (1.5e5, ""),
        (4e5, ""), (1e6, "*"), (2.5e6, ""), (6e6, ""), (1.5e7, "*"), (4e7, ""), (1e8, ""), (2.5e8, "*"), (6e8, ""), (1.5e9, "*")]
PAD_BONUS = 1.15
COMET = 1.5


class Save:
    def __init__(self):
        self.lv = [1, 0, 0, 0, 0]
        self.cp = [1, 0, 0, 0, 0]
        self.pads = 0
        self.xp_total = self.xp = 0.0
        self.cosmic = 1
        self.perk = {"STARDUST": 0, "FIRST LIGHT": 0}
        self.starfire = 0
        self.star_open = False

    def reset(self):  # Supernova: stardust, levels, copies, unlocks; keeps pads, Cosmic Level, XP, perks, ring 2
        self.lv = [1, 0, 0, 0, 0]
        self.cp = [1, 0, 0, 0, 0]

    def all_mult(self):
        pads = PAD_BONUS ** sum(1 for i in range(self.pads) if PADS[i][1])
        return (1 + 0.1 * self.perk["STARDUST"]) * pads * COMET * 1.75 ** self.starfire

    def body_inc(self, k, lv=None, cp=None):
        lv = self.lv[k] if lv is None else lv
        cp = self.cp[k] if cp is None else cp
        if lv == 0:
            return 0.0
        b = 5 ** k * lv * cp * 2 ** (lv // 10)
        return b * (1 + 0.5 * self.perk["FIRST LIGHT"]) if k == 0 else b

    def income(self):
        return sum(self.body_inc(k) for k in range(5)) * self.all_mult()


def lv_cost(k, lv):
    return 10 * 8 ** k * LV_GROWTH ** lv


def cp_cost(k, cp):
    return COPY_BASE * 8 ** k * COPY_GROWTH ** (cp - 1)


def perk_cost(lv):
    return math.ceil(2 * PERK_GROWTH ** lv)


def xp_for(level):  # total XP to reach `level`
    return XP_NEED * (XP_GROW ** (level - 1) - 1) / (XP_GROW - 1)


def play(s, need, t_max, log, t0):
    cash = earned = 0.0
    t = 0
    while earned < need and t < t_max:
        inc = s.income()
        m = s.all_mult()
        gain = XP_BASE * math.log10(1 + inc) ** 1.5
        s.xp += gain
        s.xp_total += gain
        while s.xp_total >= xp_for(s.cosmic + 1):
            s.cosmic += 1
            log.append((t0 + t, "level", f"COSMIC LEVEL {s.cosmic}"))
        while True:
            open_perks = [p for p in s.perk if s.perk[p] < PERK_MAX]
            if not open_perks:
                break
            pk = min(open_perks, key=lambda p: s.perk[p])
            c = perk_cost(s.perk[pk])
            if s.xp < c:
                break
            s.xp -= c
            s.perk[pk] += 1
            log.append((t0 + t, "perk", f"{pk} perk Lv{s.perk[pk]}"))
        # the lit pad, once it costs <= 45 s of income
        if s.pads < len(PADS) and cash >= PADS[s.pads][0] and PADS[s.pads][0] <= 45 * inc:
            cash -= PADS[s.pads][0]
            s.pads += 1
            log.append((t0 + t, "pad", f"PAD {s.pads}{' (x1.15)' if PADS[s.pads - 1][1] else ''}"))
            continue
        opts = []
        for k in range(5 if s.star_open else 4):
            if s.lv[k] == 0:
                if k == 4 or k - 1 < 0 or s.lv[k - 1] > 0:
                    c = UNLOCK.get(k, lv_cost(k, 0))
                    opts.append((c, 5 ** k * m, ("unlock", k)))
                continue
            opts.append((lv_cost(k, s.lv[k]), (s.body_inc(k, s.lv[k] + 1) - s.body_inc(k)) * m, ("level", k)))
            if s.cp[k] < MAX_COPIES:
                opts.append((cp_cost(k, s.cp[k]), (s.body_inc(k, cp=s.cp[k] + 1) - s.body_inc(k)) * m, ("copy", k)))
        best = min(opts, key=lambda o: o[0] / max(o[1], 1e-9) + max(0, o[0] - cash) / max(inc, 1e-9))
        if cash >= best[0]:
            cash -= best[0]
            kind, k = best[2]
            if kind == "unlock":
                s.lv[k], s.cp[k] = 1, 1
                log.append((t0 + t, "new", f"NEW BODY: {TIERS[k].upper()}"))
            elif kind == "level":
                s.lv[k] += 1
                log.append((t0 + t, "tier" if s.lv[k] % 10 == 0 else "buy",
                            f"{TIERS[k]} -> {NAMES[s.lv[k] // 10]} (Lv{s.lv[k]})" if s.lv[k] % 10 == 0 else f"{TIERS[k]} Lv{s.lv[k]}"))
            else:
                s.cp[k] += 1
                log.append((t0 + t, "copy", f"+BODY {TIERS[k]} x{s.cp[k]}"))
            continue
        cash += inc
        earned += inc
        t += 1
    return t


def campaign(need1, growth, minutes=30):
    s = Save()
    log, t, runs, n = [], 0, [], 0
    limit = minutes * 60 / REAL
    while t < limit:
        dt = play(s, need1 * growth ** n, limit - t, log, t)
        t += dt
        if t >= limit:
            break
        n += 1
        runs.append(dt)
        log.append((t, "nova", f"SUPERNOVA {n}"))
        s.starfire = min(5, s.starfire + 1)
        s.star_open = True
        s.reset()
    return s, log, runs


def report(need1, growth, timeline=False):
    s, log, runs = campaign(need1, growth)
    print(f"\n=== Supernova 1 needs {need1:,.0f}, each next one x{growth} ===")
    print("  runs to each Supernova (real min):", ", ".join(f"{r * REAL / 60:.1f}" for r in runs[:8]))
    buys = sorted(e[0] * REAL for e in log if e[1] in ("buy", "tier", "copy", "new", "pad"))
    for mm in (5, 10, 20, 30):
        print(f"  stardust purchases by {mm:>2} min: {sum(1 for x in buys if x <= mm * 60)}")
    gaps = sorted(b - a for a, b in zip(buys, buys[1:]) if b <= 1800)
    if gaps:
        print(f"  gap between purchases: median {gaps[len(gaps) // 2]:.0f} s, 90% {gaps[int(len(gaps) * 0.9)]:.0f} s, longest {gaps[-1]:.0f} s")
    nt = sorted(e[0] * REAL for e in log if e[1] in ("tier", "new", "pad", "nova", "level", "copy") and e[0] * REAL <= 1800)
    ng = sorted(b - a for a, b in zip([0] + nt, nt))
    print(f"  NEW named things (tier, body, +BODY, pad, level, Supernova): {len(nt)}; median gap {ng[len(ng) // 2]:.0f} s, longest {ng[-1]:.0f} s")
    print(f"  at 30 min: Cosmic Level {s.cosmic}, pads {s.pads}/20, perks {s.perk}, Supernovas {len(runs)}")
    if timeline:
        print("\n  TIMELINE (real time) - named things:")
        for t, kind, text in log:
            if kind in ("tier", "new", "pad", "nova", "level", "copy") and t * REAL <= 1800:
                print(f"    {int(t * REAL) // 60:>2}:{int(t * REAL) % 60:02d}  {text}")


if __name__ == "__main__":
    if len(sys.argv) > 2:
        report(float(sys.argv[1]), float(sys.argv[2]), timeline=True)
    else:
        for need in (2e5, 5e5, 1e6):
            for g in (5.0, 10.0):
                report(need, g)
