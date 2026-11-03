# SVJ cluster under its own frame (2026-11-03)

Owner: "Under the SVJ and SVJ 63 cluster there is the cluster's outline cover; put the cluster under that outline."

1. `probe.py` (Blender, `-b build/svj/<car>.blend --python probe.py -- out.json "[at]" "[face]"`):
   casts rays from the driver's side across the cluster frame, on a 2 mm grid in the old
   CLUSTER_RECT plane, and stores the depth and material of what each ray hits.
2. Openings = spots at the screen's own depth (the centre and side windows); the frame and its
   ribs stand ~1-1.5 cm in front of it.
3. `fit2.py` (Blender's Python, has numpy): finds the panel's middle, width and height so the
   picture's three screens cover the openings, with as little stretch as possible.
4. `mask.py`: where the picture would show past the frame (over the windscreen) it is cut away:
   `tools/svj_cluster_mask.png`, applied by `svj_cluster_art.py --assets`.

Results (CarSkin.CLUSTER_RECT): SVJ w 0.336 h 0.136, SVJ 63 w 0.324 h 0.132, both just behind the
frame. DashGauges' AventadorSVJ fills the panel (no aspect lock) with a see-through back.
