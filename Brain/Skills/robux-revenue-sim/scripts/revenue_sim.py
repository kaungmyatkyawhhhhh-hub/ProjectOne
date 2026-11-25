"""Robux revenue simulator for a Roblox game (Monte Carlo, one player at a time).

Usage:
  python revenue_sim.py model.json                 # 30-day forecast + per-offer table
  python revenue_sim.py model.json --sweep OFFER   # price sweep for one offer (finds the best price)
  python revenue_sim.py --example > model.json     # starter model to edit
  python revenue_sim.py --selftest

Every number in model.json is an input you should replace with your own Creator Dashboard numbers
(retention D1/D7/D30, payer conversion, ARPPU, session minutes); tune payer_potential / wtp_median
until the sim's payer_rate and ARPPU match the dashboard, THEN trust what-if changes. The defaults are public benchmarks,
not your game. The sim shows ranges (p10/p50/p90 over runs), never one "true" number.
"""
import json, math, random, sys, statistics

EXAMPLE = {
    "days": 30,
    "new_players_per_day": 2000,
    "retention": {"d1": 0.25, "d7": 0.08, "d30": 0.03},
    "minutes_per_day_active": 22,
    "premium_share": 0.12,
    "premium_robux_per_premium_minute": 0.005,
    "us_adult_share_of_spend": 0.10,
    "devex_usd": 0.0038,
    "devex_usd_us_adult": 0.0054,
    "creator_share": 0.70,
    "payer_potential": 0.06,
    "wtp_median": 90,
    "wtp_sigma": 1.1,
    "runs": 200,
    "seed": 1,
    "offers": [
        {"name": "Starter Pack", "kind": "product_once", "price": 49, "value": 2.0, "impulse": 0.20, "seen_from_day": 0},
        {"name": "2x Gains", "kind": "pass", "price": 199, "value": 1.6, "impulse": 0.06, "seen_from_day": 0},
        {"name": "Energy Shake x5", "kind": "product_repeat", "price": 25, "value": 0.6, "impulse": 0.10, "seen_from_day": 0},
        {"name": "VIP", "kind": "subscription", "price": 450, "value": 2.5, "impulse": 0.02, "seen_from_day": 1, "monthly_churn": 0.35}
    ]
}


def daily_return_curve(ret):
    """Chance a player is active on day d (d>=1): power law through D1, D7, D30 (least squares in log space)."""
    pts = [(1, ret["d1"]), (7, ret["d7"]), (30, ret["d30"])]
    xs = [math.log(d) for d, _ in pts]
    ys = [math.log(max(r, 1e-6)) for _, r in pts]
    mx, my = sum(xs) / 3, sum(ys) / 3
    b = sum((x - mx) * (y - my) for x, y in zip(xs, ys)) / sum((x - mx) ** 2 for x in xs)
    a = my - b * mx
    return lambda d: 1.0 if d == 0 else min(1.0, math.exp(a + b * math.log(d)))


def buys(o, price, wtp, rng):
    """A would-be payer looks at the offer today (impulse) and buys if its worth to them (wtp * value) covers the price."""
    return rng.random() < o.get("impulse", 0.05) and wtp * o.get("value", 1.0) >= price


def simulate(model, price_override=None, rng=None):
    rng = rng or random.Random(model.get("seed", 1))
    active = daily_return_curve(model["retention"])
    days = model["days"]
    offers = model["offers"]
    gross = {o["name"]: 0.0 for o in offers}
    payers = set()
    premium_minutes = 0.0
    dau_total = 0
    pid = 0
    for start in range(days):
        n = model["new_players_per_day"]
        for _ in range(n):
            pid += 1
            premium = rng.random() < model["premium_share"]
            # most players never pay; would-be payers get a lognormal willingness to pay (Robux per purchase)
            wtp = rng.lognormvariate(math.log(model["wtp_median"]), model["wtp_sigma"]) if rng.random() < model["payer_potential"] else 0.0
            owned, subbed, paid = set(), False, False
            for d in range(days - start):
                if rng.random() >= active(d):
                    continue
                dau_total += 1
                if premium:
                    premium_minutes += model["minutes_per_day_active"]
                for o in offers:
                    if wtp <= 0:
                        break
                    if d < o.get("seen_from_day", 0):
                        continue
                    price = price_override[1] if price_override and price_override[0] == o["name"] else o["price"]
                    kind = o["kind"]
                    if kind in ("pass", "product_once") and o["name"] in owned:
                        continue
                    if kind == "subscription":
                        if subbed:
                            if d % 30 == 0 and rng.random() >= o.get("monthly_churn", 0.35):
                                gross[o["name"]] += price
                            elif d % 30 == 0:
                                subbed = False
                            continue
                    if buys(o, price, wtp, rng):
                        gross[o["name"]] += price
                        paid = True
                        payers.add(pid)
                        if kind in ("pass", "product_once"):
                            owned.add(o["name"])
                        if kind == "subscription":
                            subbed = True
    share = model["creator_share"]
    spend = sum(gross.values())
    earned_sales = spend * share
    earned_premium = premium_minutes * model["premium_robux_per_premium_minute"]
    usa = model["us_adult_share_of_spend"]
    usd = earned_sales * (usa * model["devex_usd_us_adult"] + (1 - usa) * model["devex_usd"]) + earned_premium * model["devex_usd"]
    players = pid
    return {
        "players": players,
        "dau_avg": dau_total / days,
        "spend_robux": spend,
        "earned_robux": earned_sales + earned_premium,
        "premium_robux": earned_premium,
        "usd": usd,
        "payer_rate": len(payers) / players if players else 0,
        "arppu": spend / len(payers) if payers else 0,
        "arpdau_robux": spend / dau_total if dau_total else 0,
        "by_offer": gross,
    }


def runs(model, price_override=None):
    n = model.get("runs", 200)
    rng = random.Random(model.get("seed", 1))
    small = dict(model)
    # shortcut: each run simulates 1/10 of the players and scales up; raise "scale" to 1 for exact counts
    scale = model.get("scale", 10)
    small["new_players_per_day"] = max(1, model["new_players_per_day"] // scale)
    out = []
    for _ in range(n):
        r = simulate(small, price_override, rng)
        for k in ("players", "dau_avg", "spend_robux", "earned_robux", "premium_robux", "usd"):
            r[k] *= scale
        r["by_offer"] = {k: v * scale for k, v in r["by_offer"].items()}
        out.append(r)
    return out


def pct(vals, q):
    vals = sorted(vals)
    return vals[min(len(vals) - 1, int(q * len(vals)))]


def report(model):
    rs = runs(model)
    def row(key, fmt="{:,.0f}"):
        v = [r[key] for r in rs]
        return f"{key:14} p10 {fmt.format(pct(v, .1)):>12}  p50 {fmt.format(pct(v, .5)):>12}  p90 {fmt.format(pct(v, .9)):>12}"
    print(f"{model['days']}-day forecast, {len(rs)} runs")
    for k in ("players", "dau_avg", "spend_robux", "earned_robux", "premium_robux", "usd"):
        print(row(k))
    print(row("payer_rate", "{:.2%}"))
    print(row("arppu", "{:,.0f}"))
    print(row("arpdau_robux", "{:.2f}"))
    print("\nspend by offer (p50 Robux):")
    for o in model["offers"]:
        print(f"  {o['name']:20} {pct([r['by_offer'][o['name']] for r in rs], .5):>12,.0f}")


def sweep(model, name, prices=None):
    o = next(x for x in model["offers"] if x["name"] == name)
    prices = prices or sorted({max(1, round(o["price"] * f)) for f in (0.25, 0.5, 0.75, 1, 1.25, 1.5, 2, 3)})
    m = dict(model, runs=max(30, model.get("runs", 200) // 4))
    print(f"price sweep: {name} (value {o.get('value', 1.0)}, impulse {o.get('impulse', 0.05)})")
    best = None
    for p in prices:
        v = pct([r["usd"] for r in runs(m, (name, p))], .5)
        print(f"  {p:>6} R$  ->  total USD p50 {v:>10,.0f}")
        if best is None or v > best[1]:
            best = (p, v)
    print(f"best: {best[0]} R$ (only as good as the wtp/value inputs: confirm with a Roblox price test)")


def selftest():
    m = json.loads(json.dumps(EXAMPLE))
    m.update(runs=20, days=10, new_players_per_day=500)
    curve = daily_return_curve(m["retention"])
    assert abs(curve(1) - 0.25) < 0.05 and abs(curve(7) - 0.08) < 0.03 and curve(0) == 1
    base = pct([r["spend_robux"] for r in runs(m)], .5)
    assert base > 0
    m2 = json.loads(json.dumps(m))
    m2["payer_potential"] *= 2
    assert pct([r["spend_robux"] for r in runs(m2)], .5) > base * 1.5, "doubling would-be payers should ~double spend"
    o, rng = m["offers"][1], random.Random(3)
    cheap = sum(buys(o, 50, 100, rng) for _ in range(5000))
    dear = sum(buys(o, 500, 100, rng) for _ in range(5000))
    assert cheap > 0 and dear == 0, "nobody pays more than the offer is worth to them"
    print("selftest ok")


if __name__ == "__main__":
    a = sys.argv[1:]
    if not a:
        print(__doc__)
    elif a[0] == "--example":
        print(json.dumps(EXAMPLE, indent=2))
    elif a[0] == "--selftest":
        selftest()
    else:
        model = json.load(open(a[0], encoding="utf-8"))
        if "--sweep" in a:
            sweep(model, a[a.index("--sweep") + 1])
        else:
            report(model)
