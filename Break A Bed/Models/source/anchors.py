import sys, os, json, numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from creatures import ALL
import trimesh

def cat(ms): return np.vstack([m.vertices for m in ms])
def ext(V, d): d = np.asarray(d, float); return V[np.argmax(V @ d)]
SPECS = {
 "Phoenix": [("WingR_Tip","WingR",(1,0.4,0)),("WingL_Tip","WingL",(-1,0.4,0)),("WingR_Back","WingR",(0.5,-1,0.8)),("WingL_Back","WingL",(-0.5,-1,0.8)),
             ("Tail_Mid","Tail",(0,-0.3,1)),("Tail_R","Tail",(1,0,0.6)),("Tail_L","Tail",(-1,0,0.6)),("Crest","Head",(0,1,0.3)),("Beak","Beak",(0,-0.3,-1)),("Chest","Body",(0,-0.2,-1))],
 "Tiger": [("Paw_FR","Legs",(0.3,0,-1)),("Paw_FL","Legs",(-0.3,0,-1)),("Paw_BR","Legs",(0.3,-0.3,1)),("Paw_BL","Legs",(-0.3,-0.3,1)),
           ("Mouth","Head",(0,-0.6,-1)),("TailTip","Tail",(0,1,-0.2)),("Back","Body",(0,1,0)),("Belly","Body",(0,-1,0))],
 "Crane": [("WingR_Tip","WingR",(1,0.2,0)),("WingL_Tip","WingL",(-1,0.2,0)),("WingR_Back","WingR",(0.4,-0.6,1)),("WingL_Back","WingL",(-0.4,-0.6,1)),
           ("Beak","Beak",(0,-0.2,-1)),("Feet","Legs",(0,0,1)),("Tail","Tail",(0,0,1)),("Back","Body",(0,1,0))],
 "IceDragon": [("WingR_Tip","WingR",(1,0.6,0)),("WingL_Tip","WingL",(-1,0.6,0)),("WingR_Low","WingR",(0.7,-1,0.6)),("WingL_Low","WingL",(-0.7,-1,0.6)),
               ("Mouth","Head",(0,-0.3,-1)),("TailTip","Crystals",(0,0,1)),("Back","Body",(0,1,0.2)),("Chest","Body",(0,-0.3,-1))],
 "FirePhoenix": None,  # same as Phoenix
 "RainbowKoi": [("Mouth","Body",(0,0,-1)),("Tail_Top","TailFin",(0,1,0.6)),("Tail_Bottom","TailFin",(0,-1,0.6)),("Dorsal","Fins",(0,1,0.2)),
                ("FinR","Fins",(1,-0.3,0)),("FinL","Fins",(-1,-0.3,0))],
}
NAMES = {"1_Phoenix":"Phoenix","2_Tiger":"Tiger","3_Crane":"Crane","4_GoldDragon":"GoldDragon","5_IceDragon":"IceDragon","6_FirePhoenix":"FirePhoenix","7_RainbowKoi":"RainbowKoi","8_GalaxyDragon":"GalaxyDragon"}
out = {}
for key, (fn, _) in sorted(ALL.items()):
    nm = NAMES[key]; P = fn()
    centers = {p: (cat(ms).max(0)+cat(ms).min(0))/2 for p, ms in P.items()}
    res = {}
    spec = SPECS.get(nm) if SPECS.get(nm) is not None else SPECS["Phoenix"]
    if nm in ("GoldDragon", "GalaxyDragon"):
        Bv = cat(P["Body"]); hc = centers["Head"]
        Hv = cat(P["Head"]); snout = Hv[np.argmax(np.linalg.norm(Hv - centers["Body"], axis=1))]
        res["Mouth"] = ("Head", snout)
        Tv = cat(P["TailTip"]); res["TailTip"] = ("TailTip", Tv[np.argmax(np.linalg.norm(Tv - hc, axis=1))])
        if "Whiskers" in P:
            Wv = cat(P["Whiskers"]); res["Whisker"] = ("Whiskers", Wv[np.argmax(np.linalg.norm(Wv - hc, axis=1))])
        ys = Bv[:, 1]
        for i, q in enumerate(np.linspace(0.1, 0.9, 6)):
            band = Bv[np.abs(ys - np.quantile(ys, q)) < 0.3]
            res[f"Spine{i+1}"] = ("Body", band[np.argmax(band[:, 1])])
    else:
        for an, part, d in spec:
            res[an] = (part, ext(cat(P[part]), d))
    out[nm] = {a: {"part": p, "offset": [round(float(v), 3) for v in (pt - centers[p])]} for a, (p, pt) in res.items()}
    out[nm]["_size"] = [round(float(v), 2) for v in np.ptp(np.vstack([cat(m) for m in P.values()]), 0)]
json.dump(out, open(sys.argv[1], "w"), indent=1)
print({k: len(v) for k, v in out.items()})
