"""Quality-nerd kid sim for MM Outfit Catalog (17 Nov 2026).
A picky kid walks the main route for 10 minutes, judging a view every 2 s.
Per-view probabilities come from the Studio audit (part counts, repeats, screenshots).
Score = 1.6*log(1+wows) - sum(w*log(1+count)) per tell kind. 2,000 kids per version."""
import math, random
random.seed(17)
VIEWS = 300  # 10 min / 2 s
# where kids spend time on the live route (share of views)
ROUTE_A = {"showroom": .30, "viewer": .25, "penthouse": .20, "tower": .25}
TELL_W = {"empty_view": 1.0, "same_prop": .6, "zones_same": 1.1, "placeholder_ui": .9, "flat_dated_outfit": 1.2,
          "blocky_furniture": .8, "dark_or_blown_light": .7, "no_reaction": .5, "hud_clutter": .6, "palette_clash": .6}
def zone_model(v):
    # per-zone chance per view of each tell / wow, from the audit; versions switch fixes on
    z = {
     "showroom": {"empty_view": .30, "blocky_furniture": .35, "placeholder_ui": .25, "dark_or_blown_light": .25,
                  "flat_dated_outfit": .30, "palette_clash": .25, "hud_clutter": .15, "no_reaction": .10, "wow": .04},
     "viewer":   {"flat_dated_outfit": .45, "placeholder_ui": .05, "hud_clutter": .05, "wow": .05},
     "penthouse":{"empty_view": .30, "blocky_furniture": .45, "placeholder_ui": .20, "palette_clash": .30,
                  "same_prop": .10, "no_reaction": .15, "wow": .03},
     "tower":    {"empty_view": .65, "zones_same": .55, "same_prop": .35, "blocky_furniture": .25, "no_reaction": .30, "wow": .01},
    }
    route = dict(ROUTE_A)
    if v >= 1:   # B: cut the tower to 3 themed floors (no empty floors on the route)
        route = {"showroom": .38, "viewer": .30, "penthouse": .22, "tower": .10}
        z["tower"].update({"empty_view": .20, "zones_same": .10, "same_prop": .15, "wow": .06})
    if v >= 2:   # C: one palette + a lighting grade (warm boutique night, windows not blown out)
        for k in z: z[k]["palette_clash"] = z[k].get("palette_clash", 0) * .2; z[k]["dark_or_blown_light"] = z[k].get("dark_or_blown_light", 0) * .2
    if v >= 3:   # D: outfits on R15 mannequins with layered clothing + 12+ outfits that rotate
        for k in z: z[k]["flat_dated_outfit"] = z[k].get("flat_dated_outfit", 0) * .15
        z["viewer"]["wow"] += .06; z["showroom"]["wow"] += .03
    if v >= 4:   # E: a real furniture/mesh kit (boutique racks, mirrors, curved sofas) instead of blocks
        for k in z: z[k]["blocky_furniture"] = z[k].get("blocky_furniture", 0) * .2; z[k]["same_prop"] = z[k].get("same_prop", 0) * .5
    if v >= 5:   # F: set pieces: a lit runway with arches, fitting-room mirrors, a neon MM sign, the rain window bar
        z["showroom"]["empty_view"] *= .3; z["penthouse"]["empty_view"] *= .4; z["showroom"]["wow"] += .07; z["penthouse"]["wow"] += .05
    if v >= 6:   # G: ambient life + real signage: NPC shoppers posing, clothes on racks swaying, readable boards
        for k in z: z[k]["no_reaction"] = z[k].get("no_reaction", 0) * .25; z[k]["placeholder_ui"] = z[k].get("placeholder_ui", 0) * .3
        z["showroom"]["wow"] += .02
    if v >= 7:   # H: HUD down to 4 buttons (+ a menu), no zone banner over the view
        for k in z: z[k]["hud_clutter"] = z[k].get("hud_clutter", 0) * .2
    return route, z
def run(v, kids=2000):
    route, z = zone_model(v); zones = list(route); weights = [route[k] for k in zones]
    likes = 0; tells_tot = {k: 0 for k in TELL_W}; wows_tot = 0
    for _ in range(kids):
        pick = random.uniform(.7, 1.3)  # how picky this kid is
        counts = {k: 0 for k in TELL_W}; wows = 0
        for _ in range(VIEWS // 6):  # a "look" every ~12 s is what kids actually notice
            zone = random.choices(zones, weights)[0]
            for k, p in z[zone].items():
                if k == "wow": wows += random.random() < p
                elif random.random() < p * pick: counts[k] += 1
        score = 1.6 * math.log(1 + wows) - sum(TELL_W[k] * math.log(1 + c) for k, c in counts.items())
        likes += score > -6.0
        for k in counts: tells_tot[k] += counts[k]
        wows_tot += wows
    per10 = {k: tells_tot[k] / kids for k in tells_tot}
    top = sorted(per10.items(), key=lambda kv: -kv[1])[:3]
    return sum(per10.values()), top, wows_tot / kids, likes / kids
NAMES = ["A live build", "B cut tower to 3 themed floors", "C one palette + lighting grade", "D R15 layered outfits, 12+",
         "E real furniture/mesh kit", "F set pieces (runway, mirrors, neon)", "G ambient life + readable signs", "H HUD trimmed"]
if __name__ == "__main__":
    print(f"{'version':38s} {'tells/10min':>11s} {'wows':>5s} {'like%':>6s}  top tells")
    for v, n in enumerate(NAMES):
        t, top, w, l = run(v)
        print(f"{n:38s} {t:11.1f} {w:5.1f} {100*l:5.0f}%  " + ", ".join(f"{k} {c:.1f}" for k, c in top))

# --- 17 Nov evening: score the CURRENT rebuilt build (partial fixes weighted) ---
_BASE_MODEL = zone_model
def current_build():
    route, z = _BASE_MODEL(0)
    route = {"showroom": .45, "viewer": .30, "penthouse": .20, "tower": .05}  # tower cut; floor 18 lower level only
    z["tower"].update({"empty_view": .25, "zones_same": .05, "same_prop": .10, "wow": .03})
    for k in z:                                   # palette done on boutique + penthouse, lighting grade not yet: half
        z[k]["palette_clash"] = z[k].get("palette_clash", 0) * .4
        z[k]["dark_or_blown_light"] = z[k].get("dark_or_blown_light", 0) * .6
        z[k]["flat_dated_outfit"] = z[k].get("flat_dated_outfit", 0) * .35   # 4 of 7 outfits layered, all R15 + idles
        z[k]["hud_clutter"] = z[k].get("hud_clutter", 0) * .3                # 5 buttons + More, no banners
        z[k]["placeholder_ui"] = z[k].get("placeholder_ui", 0) * .5          # boards readable; some old signs left
        z[k]["no_reaction"] = z[k].get("no_reaction", 0) * .4                # shoppers + idles + watcher
    z["showroom"]["blocky_furniture"] *= .35; z["showroom"]["empty_view"] *= .35  # racks, booth, fitting rooms, runway
    z["penthouse"]["blocky_furniture"] *= .8                                     # recoloured, still block furniture
    z["showroom"]["wow"] += .12; z["viewer"]["wow"] += .07; z["penthouse"]["wow"] += .01
    return route, z
if __name__ == "__main__":
    import random as _r
    _r.seed(17)
    orig = zone_model
    zone_model = lambda v: current_build()
    t, top, w, l = run(0)
    print(f"{'CURRENT BUILD 17 Nov (evening)':38s} {t:11.1f} {w:5.1f} {100*l:5.0f}%  " + ", ".join(f"{k} {c:.1f}" for k, c in top))
