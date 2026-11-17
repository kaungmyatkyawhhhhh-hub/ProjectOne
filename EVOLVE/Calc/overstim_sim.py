"""Overstimulated-kid sim for Evolve. (live numbers from ServerScriptService.Evolution, UI from EvolutionUI, 18 Nov 2026).
The only screen emitter is the toast queue (one toast at a time, priority sort, cap 6) plus the windows a kid opens.
Run: python -I overstim_sim.py   -> version table + worst timelines.  Model, not a playtest: weights/reading speeds are estimates."""
import random, statistics

# ---- live game numbers (Evolution script) ----
STAGE_AT = [0, 3, 8, 15, 25, 40, 60, 90, 130, 180, 240, 320]
STAGE_NAME = ["Monkey", "Ape", "Australopithecus", "Homo habilis", "Homo erectus", "Neanderthal", "Homo sapiens",
              "Modern Human", "Cyborg", "Space Colonist", "Digital Mind", "Cosmic Being"]
ERA_AT = [0, 5, 12, 20, 30, 45, 65]
MODERN = 7          # 0-based index of Modern Human
BASE_LIFE, MIN_LIFE, RESPAWN = 45, 8, 3.5
MUT, LOSE, RISK = 0.3, 0.1, 0.15
UP = {"Aging": 25, "Brain": 15, "Family": 40}
BADGE_STAGES = {1: "First Steps", 4: "Firestarter", 7: "Modern Times"}

def stage_of(evo): return max(i for i, a in enumerate(STAGE_AT) if evo >= a)

# ---- toast styles (EvolutionUI STYLES): find, priority, hold ----
STYLES = [("asteroid", 10, 3.5), ("evolved", 10, 3.5), ("Badge", 9, 3), ("Thank you", 9, 3),
          ("entered the", 7, 3), ("Mutation", 6, 2.2), ("Caught", 5, 2.2)]
KEY = {"evolved": "evolve", "entered the": "era", "Badge": "badge", "Thank you": "purchase", "asteroid": "rebirth"}
SLIDE = 0.47  # in 0.25 + out 0.22

def style(line):
    for f, p, h in STYLES:
        if f in line: return f, p, h
    return None, 1, 2.2

# ---- player timeline: an idle evolver who buys the cheapest upgrade when affordable ----
def timeline(rng, minutes=10, mid=False):
    d = dict(DNA=0.0, Evo=0, Civ=0, Aging=0, Brain=0, Family=0, Gen=1, traits=0, sick=0, badges=set())
    if mid: d.update(Evo=60, Aging=8, Brain=10, Family=3, Gen=40, traits=2, badges={"First Steps", "Firestarter"})
    t, events, T = 0.0, [], minutes * 60
    while t < T:
        life = max(MIN_LIFE, BASE_LIFE * 0.9 ** d["Aging"])
        rate = 1 + d["Brain"]
        d["DNA"] += rate * (life + RESPAWN)
        t += life + RESPAWN
        for _ in range(4):  # buy what we can afford, cheapest first
            name = min(UP, key=lambda n: UP[n] * 1.6 ** d[n])
            c = int(UP[name] * 1.6 ** d[name])
            if d["DNA"] < c: break
            d["DNA"] -= c; d[name] += 1
        old_s, old_civ_era = stage_of(d["Evo"]), None
        old_era = max(i for i, a in enumerate(ERA_AT) if d["Civ"] >= a) if old_s >= MODERN else -1
        d["Gen"] += 1
        if old_s >= MODERN: d["Civ"] += 1
        d["Evo"] += 1 + d["Family"]
        news = []
        if d["traits"] and rng.random() < LOSE: d["traits"] -= 1; news.append("Long Legs was not passed on")
        if rng.random() < MUT and d["traits"] < 7: d["traits"] += 1; news.append("Mutation! Sharp Mind (+2 DNA/sec)")
        if rng.random() < RISK: news.append("Caught Parasites (shorter life)")
        s = stage_of(d["Evo"])
        news.insert(0, f"Your child evolved into {STAGE_NAME[s]}!" if s > old_s else f"Generation {d['Gen']} is born")
        era = max(i for i, a in enumerate(ERA_AT) if d["Civ"] >= a) if s >= MODERN else -1
        if era > old_era: news.insert(1, "Your people entered the Stone Age!")
        for st, b in BADGE_STAGES.items():
            if s >= st and b not in d["badges"]: d["badges"].add(b); news.append(f"Badge! {b} (+50 DNA)")
        if d["Gen"] == 100: news.append("Badge! Dynasty (+1000 DNA)")
        events.append((t, news))
    return events

# ---- UI versions (cumulative) ----
VERSIONS_FINAL = [
    ("V0 live", {}),
    ("V1 toasts wait while a window is open + requeue cut toasts", {"pause": True, "requeue": True}),
    ("V2 + KEY hold = words/1.2 + 0.5 s (slowest 7-y-o)", {"pause": True, "requeue": True, "readhold": True, "wps": 1.2}),
    ("V3 + 'Generation N' only when nothing else happened", {"pause": True, "requeue": True, "readhold": True, "wps": 1.2, "genmerge": True}),
    ("V4 + cap drops lowest priority", {"pause": True, "requeue": True, "readhold": True, "wps": 1.2, "genmerge": True, "capfix": True}),
    ("V5 + toast below the menu buttons", {"pause": True, "requeue": True, "readhold": True, "wps": 1.2, "genmerge": True, "capfix": True, "toastmove": True}),
]
VERSIONS = [
    ("V0 live", {}),
    ("V1 toasts wait while a window is open", {"pause": True}),
    ("V2 + KEY toasts held for 7-y-o reading time", {"pause": True, "readhold": True}),
    ("V3 + routine 'Generation N is born' dropped (HUD shows Gen)", {"pause": True, "readhold": True, "nogen": True}),
    ("V4 + queue cap drops lowest priority, not newest", {"pause": True, "readhold": True, "nogen": True, "capfix": True}),
]

def words(s): return len(s.split())

def run_ui(events, opt, windows):
    """Return list of shown toasts: (line, start, end, hidden_seconds) and dropped lines."""
    queue, shown, dropped, seq = [], [], [], 0
    busy_until = 0.0
    def win_open(t): return any(a <= t < b for a, b in windows)
    pending = sorted(events)
    i, t = 0, 0.0
    allt = sorted(set([e[0] for e in events] + [b for _, b in windows]))
    # event-driven loop in 0.05 s steps (fine enough)
    end_t = (events[-1][0] if events else 0) + 120
    step = 0.05
    while t < end_t:
        while i < len(pending) and pending[i][0] <= t:
            for line in pending[i][1]:
                f, p, h = style(line)
                if opt.get("nogen") and line.startswith("Generation"): continue
                if opt.get("genmerge") and line.startswith("Generation") and len(pending[i][1]) > 1: continue
                seq += 1
                queue.append(dict(line=line, p=p, hold=h, seq=seq, key=KEY.get(f)))
                while len(queue) > 6:
                    if opt.get("capfix"):
                        queue.sort(key=lambda x: (-x["p"], x["seq"])); dropped.append(queue.pop())
                    else:
                        dropped.append(queue.pop())  # live code: table.remove(queue) = newest, before sorting
            i += 1
        if t >= busy_until and queue and not (opt.get("pause") and win_open(t)):
            queue.sort(key=lambda x: (-x["p"], x["seq"]))
            it = queue.pop(0)
            hold = it["hold"]
            if opt.get("readhold") and it["key"]: hold = max(hold, words(it["line"]) / opt.get("wps", 1.5) + 0.5)
            start, end = t + 0.25, t + 0.25 + hold
            hidden = sum(step for k in range(int(hold / step)) if win_open(start + k * step))
            if opt.get("requeue") and hidden:  # a window opened mid-toast: slide it out, show it again after close
                cut = next(start + k * step for k in range(int(hold / step)) if win_open(start + k * step))
                queue.append(it); busy_until = cut + 0.22; t += step; continue
            shown.append((it, start, end, hidden))
            busy_until = end + 0.22
        t += step
    return shown, dropped

def kid_windows(rng, T):
    w, t = [], rng.uniform(20, 60)
    while t < T:
        dur = rng.uniform(5, 15); w.append((t, t + dur)); t += dur + rng.expovariate(1 / 50)
    return w

def simulate(opt, n=2000, mid=False, seed=1):
    rng = random.Random(seed)
    res = dict(missed={}, total={}, over=[], coll=0, worst=[])
    m7 = [0, 0]
    for _ in range(n):
        age = rng.uniform(5, 12)
        slots = 2 if age < 7 else 3 if age < 10 else 3.5
        rs = max(0.6, min(4.0, (0.5 * age - 2) * rng.uniform(0.8, 1.2)))   # words / s: ~1.5 at 7, ~3 at 10
        ev = timeline(rng, mid=mid)
        wins = kid_windows(rng, 600)
        shown, dropped = run_ui(ev, opt, wins)
        over = 0.0
        for it, a, b, hid in shown:
            # on screen: toast 0.5 + window 2 (if open) + death/respawn moment 1 if within 1 s of a life end
            for k in range(int((b - a) / 0.1)):
                tt = a + k * 0.1
                wsum = 0.5 + (2 if any(x <= tt < y for x, y in wins) and not hid else 0) \
                     + (1 if any(abs(tt - e[0]) < 0.5 for e in ev) else 0)
                if wsum > slots: over += 0.1
            if not opt.get("toastmove"): res["coll"] += 1  # toast corner over the Index button (y104 vs buttons to y112)
            if it["key"]:
                need = words(it["line"]) / rs
                seen = (b - a) - hid >= need and hid == 0
                res["total"][it["key"]] = res["total"].get(it["key"], 0) + 1
                if not seen: res["missed"][it["key"]] = res["missed"].get(it["key"], 0) + 1
                if 7 <= age < 8: m7[0] += 1; m7[1] += not seen
        for it in dropped:
            if it["key"]:
                res["total"][it["key"]] = res["total"].get(it["key"], 0) + 1
                res["missed"][it["key"]] = res["missed"].get(it["key"], 0) + 1
                if 7 <= age < 8: m7[0] += 1; m7[1] += 1
        res["over"].append(over)
    tot = sum(res["total"].values()); mis = sum(res["missed"].values())
    return dict(over=statistics.mean(res["over"]), miss=100 * mis / max(tot, 1), miss7=100 * m7[1] / max(m7[0], 1),
                by={k: f"{100 * res['missed'].get(k, 0) / v:.0f}%" for k, v in res["total"].items()},
                coll=res["coll"] / n)

if __name__ == "__main__":
    # self-check: the live cap drops the newest line, the fix drops the lowest priority
    burst = [(1.0, ["Generation 2 is born"] * 6 + ["Your child evolved into Ape!"])]
    _, d0 = run_ui(burst, {}, []); _, d1 = run_ui(burst, {"capfix": True}, [])
    assert d0[0]["line"].startswith("Your child") and d1[0]["line"].startswith("Generation"), "cap model broken"
    for mid in (False, True):
        print("\n== " + ("mid-game 10 min (Homo sapiens, Aging 8)" if mid else "first 10 min") + " ==")
        print(f"{'version':58} overload s/10min  KEY missed  KEY missed 7yo  toast-on-button/kid  by type")
        for name, opt in VERSIONS_FINAL:
            r = simulate(opt, n=400, mid=mid)
            print(f"{name:58} {r['over']:8.1f}        {r['miss']:6.1f}%     {r['miss7']:6.1f}%        {r['coll']:5.1f}   {r['by']}")
