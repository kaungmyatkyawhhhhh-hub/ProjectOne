# LIVE first-10-minutes bot (9 Nov, owner: "most people have 3 mins of playtime"). Copies the LIVE game, not the plan:
# EconConfig (costs, income, pads, XP, perks), the 20-step Tutorial 2 (order, ~20 s payout per step), the comets (none
# before tutorial step 6, 2 tutorial comets, then every 20 s in run 1 worth 30-60 s of income, 1 in 10 golden x5) and the
# HUD's NEXT goal. Two players:
#   best    = the plan's best-choice buyer (Calc/feel.py's chooser), catches every comet
#   guided  = a NEW player: does what the tutorial step asks, buys the HUD's NEXT goal once it can pay for it, and
#             otherwise waits; catches 60% of comets
# Usage: py -I live.py [old|new]   (old = the live game today, new = with the 9 Nov fixes)
import math
import random
import sys
import os

MODE = sys.argv[1] if len(sys.argv) > 1 else "old"
CATCH = float(sys.argv[2]) if len(sys.argv) > 2 else 0.5  # (the guided player's comet catch rate)
NEW = MODE == "new"
TIERS = ["ASTEROID", "MOON", "PLANET", "GAS GIANT"]
NAMES = ["DUST", "ROCK", "IRON", "CRYSTAL", "PLASMA", "SOLAR", "NOVA", "PULSAR", "QUASAR", "COSMIC"]
UNLOCK = {1: 80, 2: 640, 3: 5120}
PADS = [15, 60, 150, 400, 1.2e3, 3e3, 8e3, 2e4, 6e4, 1.5e5, 4e5]
PAD_BONUS = {3, 6, 9}  # 1-based pads with x1.15
NEED1 = 2.5e5
XP_BASE, XP_NEED, XP_GROW, XP_START = 0.12, 8, 1.3, 2
# the 9 Nov fix: XP x EARLY_XP until Cosmic LVL 5 (only new levels; nothing a player owns changes)
EARLY_XP, EARLY_UNTIL = (float(os.environ.get("EARLYXP", "1.3")), 5) if NEW else (1, 0)
EARLY_FLOOR = float(os.environ.get("XPFLOOR", "0.12")) if NEW else 0
GIFT_AT, GIFT_MIN = (150, 5) if NEW else (None, 0)  # the 2:30 gift: x2 stardust for 5 min
import os
if os.environ.get("NOGIFT"):
    GIFT_AT = None
NEED1 = float(os.environ.get("NEED1", NEED1))
COMET_SCALE = float(os.environ.get("COMETX", "1"))  # (the run-1 comet's value x this)

OLD_TUT = ["Asteroid3", "FirstLight", "Pad1", "Moon", "Copy", "Comets", "Rock", "Planet", "Pads4", "Level3", "Giant", "Ready", "Supernova"]
NEW_TUT = ["Asteroid3", "FirstLight", "Pad1", "Moon", "Copy", "Comets", "Planet", "Pads4", "Level3", "Giant", "Rock", "Ready", "Supernova"]
TUT = NEW_TUT if NEW else OLD_TUT


def lv_cost(k, lv):
    return 10 * 8 ** k * 1.8 ** lv


def cp_cost(k, cp):
    return 50 * 8 ** k * 4 ** (max(cp, 1) - 1)


def perk_cost(lv):
    return math.ceil(2 * 1.6 ** lv)


def xp_for(level):
    return XP_NEED * (XP_GROW ** (level - 1) - 1) / (XP_GROW - 1)


class G:
    def __init__(self):
        self.lv = [1, 0, 0, 0]
        self.cp = [1, 0, 0, 0]
        self.pads = 0
        self.cash = 0.0
        self.earned = 0.0
        self.xp = self.xpt = XP_START
        self.perk = {"FirstLight": 0, "Stardust": 0}
        self.tut = 0
        self.comets = 0
        self.boost = 0  # seconds of x2 left
        self.log = []
        self.t = 0

    def level(self):
        n = 1
        while self.xpt >= xp_for(n + 1):
            n += 1
        return n

    def body(self, k, lv=None, cp=None):
        lv = self.lv[k] if lv is None else lv
        cp = self.cp[k] if cp is None else cp
        if lv <= 0:
            return 0.0
        b = 5 ** k * lv * max(cp, 1) * 2 ** (lv // 10)
        return b * (1 + 0.5 * self.perk["FirstLight"]) if k == 0 else b

    def mult(self):
        pads = 1.15 ** sum(1 for i in range(self.pads) if i + 1 in PAD_BONUS)
        return (1 + 0.1 * self.perk["Stardust"]) * pads * (2 if self.boost > 0 else 1)

    def income(self):
        return sum(self.body(k) for k in range(4)) * self.mult()

    def say(self, kind, text):
        self.log.append((self.t, kind, text))

    # ---- what can be bought (stardust): (cost, gain/s, action, label, is_new)
    def options(self):
        m = self.mult()
        o = []
        for k in range(4):
            if self.lv[k] == 0:
                if k == 0 or self.lv[k - 1] > 0:
                    o.append((UNLOCK[k], 5 ** k * m, ("unlock", k), "UNLOCK " + TIERS[k], True))
                continue
            nl = self.lv[k] + 1
            named = nl % 10 == 0
            o.append((lv_cost(k, self.lv[k]), (self.body(k, nl) - self.body(k)) * m, ("level", k),
                      (NAMES[nl // 10] + " " if named else "") + TIERS[k] + (" Lv" + str(nl)), named))
            if self.cp[k] < 5:
                o.append((cp_cost(k, self.cp[k]), (self.body(k, cp=self.cp[k] + 1) - self.body(k)) * m, ("copy", k), "+BODY " + TIERS[k], True))
        if self.pads < len(PADS):
            o.append((PADS[self.pads], 0.0, ("pad",), "PAD " + str(self.pads + 1), True))
        return o

    def buy(self, opt):
        cost, _, act, label, _new = opt
        self.cash -= cost
        if act[0] == "unlock":
            self.lv[act[1]], self.cp[act[1]] = 1, 1
            self.say("new", "NEW BODY: " + TIERS[act[1]])
        elif act[0] == "level":
            self.lv[act[1]] += 1
            self.say("tier" if self.lv[act[1]] % 10 == 0 else "buy", label)
        elif act[0] == "copy":
            self.cp[act[1]] += 1
            self.say("copy", label + " x" + str(self.cp[act[1]]))
        else:
            self.pads += 1
            self.say("pad", "PAD " + str(self.pads))

    # ---- the HUD's NEXT goal
    def next_goal(self):
        o = self.options()
        if not NEW:
            # LIVE today: the cheapest NAMED thing you can NOT pay for yet (unlocks, the next named tier = the levels up to
            # it summed, the next pad). What you can buy now is never shown.
            best = None
            for k in range(4):
                if self.lv[k] == 0:
                    if k > 0 and self.lv[k - 1] > 0 and UNLOCK[k] > self.cash:
                        c = UNLOCK[k]
                        best = min(best or (c, None), (c, ("unlock", k)), key=lambda x: x[0])
                else:
                    at = (self.lv[k] // 10 + 1) * 10
                    c = sum(lv_cost(k, l) for l in range(self.lv[k], at))
                    if c > self.cash and (best is None or c < best[0]):
                        best = (c, ("tier", k))
            if self.pads < len(PADS) and PADS[self.pads] > self.cash and (best is None or PADS[self.pads] < best[0]):
                best = (PADS[self.pads], ("pad",))
            return best
        # 9 Nov fix: while the tutorial asks for a buy, NEXT is that buy (they never point two ways); else a goal you
        # reach in under ~60 s: the cheapest NEW thing (unlock, +BODY, pad, named tier) within 60 s of income; else the
        # cheapest UPGRADE
        step = TUT[self.tut] if self.tut < len(TUT) else None
        tgt = tut_target(self, step) if step else None
        if tgt:
            return (tgt[0], tgt)
        inc = max(self.income(), 1e-9)
        soon = [x for x in o if x[4] and x[0] <= self.cash + 60 * inc]
        pick = min(soon, key=lambda x: x[0]) if soon else min((x for x in o if x[2][0] == "level"), key=lambda x: x[0])
        return (pick[0], pick)


def tut_done(g, step):
    return {
        "Asteroid3": g.lv[0] >= 3, "FirstLight": g.perk["FirstLight"] >= 1, "Pad1": g.pads >= 1, "Moon": g.lv[1] >= 1,
        "Copy": g.cp[0] >= 2, "Comets": g.comets >= 2, "Rock": g.lv[0] >= 10, "Planet": g.lv[2] >= 1, "Pads4": g.pads >= 4,
        "Level3": g.level() >= 3, "Giant": g.lv[3] >= 1, "Ready": g.earned >= NEED1, "Supernova": False,
    }[step]


def tut_target(g, step):  # what the step's arrow points at
    o = {x[3]: x for x in g.options()}
    if step in ("Asteroid3", "Rock"):
        return next(x for x in g.options() if x[2] == ("level", 0))
    if step == "Moon":
        return o.get("UNLOCK MOON")
    if step == "Planet":
        return o.get("UNLOCK PLANET")
    if step == "Giant":
        return o.get("UNLOCK GAS GIANT")
    if step == "Copy":
        return o.get("+BODY ASTEROID")
    if step in ("Pad1", "Pads4"):
        return next((x for x in g.options() if x[2] == ("pad",)), None)
    return None


def run(player, seed=1, minutes=10):
    rnd = random.Random(seed)
    g = G()
    catch = (float(sys.argv[3]) if len(sys.argv) > 3 else 1.0) if player == "best" else CATCH
    next_comet, tut_comets_from = None, None
    inc_log = []
    lvl = 1
    for t in range(minutes * 60):
        g.t = t
        inc = g.income()
        # tutorial
        def check_tut():
            paid = False
            while g.tut < len(TUT) and tut_done(g, TUT[g.tut]):
                g.tut += 1
                if not paid:  # (live: steps done together pay once)
                    g.cash += max(10, g.income() * 20)
                    paid = True
                g.say("tut", "TUTORIAL " + str(g.tut) + " " + TUT[g.tut - 1])
        check_tut()
        step = TUT[g.tut] if g.tut < len(TUT) else None
        # comets
        if g.tut == 5:
            if tut_comets_from is None:
                tut_comets_from = t
            if (t - tut_comets_from) % 15 == 2 and rnd.random() < max(catch, 0.6):
                g.comets += 1
                g.cash += inc * rnd.uniform(30, 60)
                g.earned += 0
        elif g.tut > 5:
            next_comet = next_comet if next_comet is not None else t + 20
            if t >= next_comet:
                next_comet = t + 20
                if rnd.random() < catch:
                    v = inc * rnd.uniform(30, 60) * (5 if rnd.random() < 0.1 else 1) * COMET_SCALE
                    g.cash += v
                    g.earned += v
                    g.comets += 1
        # the 2:30 gift (new)
        if GIFT_AT is not None and t == GIFT_AT:
            g.boost = GIFT_MIN * 60
            g.say("gift", "GIFT: x2 STARDUST 5 MIN")
        # perks (XP)
        for _ in range(5):
            pk = min(g.perk, key=lambda p: g.perk[p])
            if player == "guided" and step == "FirstLight":
                pk = "FirstLight"
            c = perk_cost(g.perk[pk])
            # (a new player buys a perk when the tutorial asks (FIRST LIGHT) or, in the new game, when NEXT shows one)
            if g.xp >= c and (player == "best" or step == "FirstLight" or (NEW and g.level() >= 3)):
                g.xp -= c
                g.perk[pk] += 1
                g.say("perk", "PERK " + pk + " Lv" + str(g.perk[pk]))
            else:
                break
        # buying
        for _ in range(30):
            check_tut()
            step = TUT[g.tut] if g.tut < len(TUT) else None
            inc = g.income()
            if player == "best":
                if g.pads < len(PADS) and g.cash >= PADS[g.pads] and PADS[g.pads] <= 45 * inc:
                    g.buy((PADS[g.pads], 0, ("pad",), "", True))
                    continue
                o = [x for x in g.options() if x[2][0] != "pad"]
                b = min(o, key=lambda x: x[0] / max(x[1], 1e-9) + max(0, x[0] - g.cash) / max(inc, 1e-9))
                if g.cash >= b[0]:
                    g.buy(b)
                    continue
                break
            # guided: the tutorial step's target, else the NEXT goal, else wait
            tgt = tut_target(g, step) if step else None
            if tgt and g.cash >= tgt[0]:
                g.buy(tgt)
                continue
            ng = g.next_goal()
            if ng and ng[1] and g.cash >= ng[0]:
                act = ng[1]
                if isinstance(act, tuple) and len(act) == 5:
                    g.buy(act)
                    continue
                if act[0] == "unlock":
                    g.buy((UNLOCK[act[1]], 0, act, "", True))
                    continue
                if act[0] == "tier":
                    k = act[1]
                    g.buy((lv_cost(k, g.lv[k]), 0, ("level", k), TIERS[k] + " Lv" + str(g.lv[k] + 1), False))
                    continue
                if act[0] == "pad":
                    g.buy((PADS[g.pads], 0, ("pad",), "", True))
                    continue
            break
        inc = g.income()
        g.cash += inc
        g.earned += inc
        gain = XP_BASE * math.log10(1 + inc) ** 1.5
        if g.level() < EARLY_UNTIL:  # (9 Nov: the first levels come fast: x EARLY_XP, at least EARLY_FLOOR a second)
            gain = max(gain * EARLY_XP, EARLY_FLOOR)
        g.xp += gain
        g.xpt += gain
        if g.level() > lvl:
            lvl = g.level()
            g.say("level", "COSMIC LEVEL " + str(lvl))
        if g.boost > 0:
            g.boost -= 1
        if t % 30 == 0:
            ng = g.next_goal()
            inc_log.append((t, inc, g.cash, ng[0] if ng else 0))
        if g.earned >= NEED1:
            g.say("nova", "SUPERNOVA READY (" + f"{g.earned:,.0f}" + ")")
            break
    return g, inc_log


def mmss(t):
    return f"{t // 60}:{t % 60:02d}"


def report(player):
    g, inc_log = run(player)
    nova = next((mmss(t) for t, k, _ in g.log if k == "nova"), "not in 10 min")
    caught = CATCH if player == "guided" else 1.0
    print(f"\n=== {MODE.upper()} game, {player} player (comets caught {caught:.0%}): SUPERNOVA {nova} ===")
    buys = [t for t, k, _ in g.log if k in ("buy", "tier", "copy", "new", "pad")]
    gaps = [b - a for a, b in zip([0] + buys, buys + [g.t])]  # (to the end of the run too: a long wait at the end counts)
    print(f"  purchases in 10 min: {len(buys)}, longest gap between buys: {max(gaps) if gaps else '-'} s")
    news = [t for t, k, _ in g.log if k in ("tier", "copy", "new", "pad", "level", "perk", "nova") and t <= 300]
    ngaps = [b - a for a, b in zip([0] + news, news + [min(g.t, 300)])]
    print(f"  NEW things in 5 min: {len(news)}, longest gap: {max(ngaps) if ngaps else '-'} s")
    print("  every 30 s: time  income/s  stardust  NEXT-goal cost (s to reach)")
    for t, inc, cash, ng in inc_log:
        wait = max(0, ng - cash) / max(inc, 1e-9)
        print(f"    {mmss(t):>5}  {inc:8.1f}  {cash:9.0f}  {ng:9.0f} ({wait:4.0f} s)")
    print("  timeline (named things):")
    for t, k, text in g.log:
        if k != "buy":
            print(f"    {mmss(t):>5}  {text}")


if __name__ == "__main__":
    report("guided")
    report("best")
