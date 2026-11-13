"""MEGA BITE quality-nerd kid, round 7 BUILT (13 Nov 2026, afternoon). Same model as nerd_v3.py; row G uses the map numbers
measured after the build (10 seeds per zone; the earlier rows used 5, so about +-0.5 per minute is noise)."""
import json, importlib.util, io, contextlib
spec = importlib.util.spec_from_file_location('n3', 'nerd_v3.py'); n3 = importlib.util.module_from_spec(spec)
with contextlib.redirect_stdout(io.StringIO()): spec.loader.exec_module(n3)
BUILT = dict(reef=(3.05, 0, 1.2), inner=(2.4, 0, 0.47), outer=(3.23, 0.1, 0.9), trench=(3.0, 1.0, 1.2), titan=(2.3, 0.93, 0.63))
BUILT_REEF_AS_BEFORE = dict(BUILT, reef=(2.5, 0, 1.1))   # the reef was not touched: its old number, to show the noise
rows = [('C  live at noon (before the build)', n3.LIVE1, n3.ELIVE, 0.15, 1.0),
        ('E  the forecast for the two swaps', n3.F2, n3.ELIVE, 0.15, 1.0),
        ('G  BUILT and measured (spires, boulders, trench flora mixed; Titan Gate)', BUILT, n3.ELIVE, 0.17, 1.0),
        ('G2 the same, with the reef at its old measured number', BUILT_REEF_AS_BEFORE, n3.ELIVE, 0.17, 1.0)]
out = []
for name, M, X, we, zw in rows:
    t, top, w, lk = n3.run(M, X, wow_events=we, zone_wow=zw)
    print('%-76s %6.1f   %-45s %5.1f  %3d%%' % (name, t, ', '.join('%s %.1f' % q for q in top), w, lk)); out.append((name, t, top, w, lk))
json.dump(out, open('nerd_v4_out.json', 'w'))
