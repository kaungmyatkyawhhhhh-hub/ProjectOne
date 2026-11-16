# Owner 16 Nov: "exactly like the exploded diagram". Runs AFTER data.py on sheet_v2.png
# (= the exploded sheet's ASSEMBLED VIEW scaled into the turnaround's side frame + the turnaround's top/front views).
# Values read off side_ex_grid.png and the exploded parts row; all in the same sheet px as mosa6_data.json.
# Order: python analyse.py sheet_v2.png; python crys.py; python data.py; python data_exploded.py
import json
d = json.load(open('mosa6_data.json'))
d['src'] = 'mosasaurus_exploded_v1.png assembled view (side) + mosasaurus_turnaround_v1.png (top/front widths)'
d['cuts'] = dict(tail_tip=[52, 228], tail_base=[228, 430], torso=[430, 1080], neck=[1080, 1205], head=[1205, 1478])  # seams in the assembled view
d['belly_angle_deg'] = 112            # straight band, ~20 % of the body height as on the sheet
d['head'] = dict(corner=1215, upper_lip=[[1215, 295], [1300, 292], [1400, 288], [1478, 286]],
                 lower_lip=[[1200, 300], [1240, 305], [1350, 325], [1450, 345], [1458, 347]],
                 jaw_bot=[[1200, 350], [1300, 362], [1420, 378], [1458, 372]],
                 mouth_top=[[1215, 295], [1330, 300], [1450, 342]],
                 up_teeth=dict(n=9, x=[1290, 1465], len=18), lo_teeth=dict(n=8, x=[1300, 1445], len=15),
                 eye=dict(x=1308, y=245, w=34, h=24, half_sep=50))
# near-side flippers of the assembled view, mirrored (the sheet staggers L/R pairs ~1 m apart: not possible on a symmetric body)
d['flippers'] = [dict(name='Back', root=[495, 318], tip=[330, 420], spread=120, width=100, len_k=1.0, twist_deg=0),
                 dict(name='Front', root=[950, 318], tip=[815, 425], spread=120, width=100, len_k=1.0, twist_deg=0)]
d['plates'] = dict(rows_deg=[48, 74], step=68, r=26, th=7)
d['palette'].update(green=[38, 82, 52], dark=[24, 55, 40], light=[60, 108, 68], plate=[80, 132, 84], belly=[146, 151, 77])
d['crystals'] = json.load(open('crystals_side.json'))
if len(d['crystals']) == 14:          # the parts row has 15: one more tiny crystal at the tail end
    d['crystals'].insert(0, dict(x=386.0, x0=378, w=16, top=208, bot=224, a=0))
s0 = d['stations'][0]; s0['top'], s0['bot'] = 263.0, 269.0     # tail point (the median filter left a stray top here)
json.dump(d, open('mosa6_data.json', 'w'), indent=1)
print('crystals', len(d['crystals']), 'tail tip', s0)
