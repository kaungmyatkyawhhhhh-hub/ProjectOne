# v2 (owner 16 Nov: "Yes, new sheets"): everything from mosasaurus_turnaround_v2.png, which ChatGPT drew straight from the CARD.
# Values read off side_v2_grid.png / head_v2_grid.png (sheet px). Order:
#   analyse.py ../mosasaurus_turnaround_v2.png -> crys.py -> data_v2.py -> data_v2_parts.py -> mosa6_build.py
import json
d = json.load(open('mosa6_data.json'))
d['cuts'] = dict(tail_tip=[24, 250], tail_base=[250, 470], torso=[470, 1000], neck=[1000, 1100], head=[1100, 1505])
d['belly_angle_deg'] = 112                 # a lighter-green underside band (the card has no yellow belly)
d['head'] = dict(corner=1135, upper_lip=[[1135, 262], [1250, 255], [1350, 240], [1505, 222]],
                 lower_lip=[[1120, 268], [1140, 270], [1250, 305], [1350, 335], [1460, 368], [1468, 370]],
                 jaw_bot=[[1120, 335], [1140, 342], [1250, 380], [1350, 396], [1450, 410], [1468, 398]],   # the sheet's jaw is deep
                 mouth_top=[[1135, 262], [1300, 270], [1460, 362]],
                 up_teeth=dict(n=10, x=[1260, 1495], len=22), lo_teeth=dict(n=10, x=[1250, 1462], len=20),
                 eye=dict(x=1235, y=197, w=58, h=34, half_sep=60))
d['flippers'] = [dict(name='Back', root=[520, 300], tip=[275, 440], spread=215, width=160, len_k=1.1, twist_deg=0),
                 dict(name='Front', root=[1010, 315], tip=[790, 465], spread=225, width=170, len_k=1.1, twist_deg=0)]
d['plates'] = dict(rows_deg=[45, 70], step=62, r=24, th=7)        # dark diamond scutes, two staggered rows
d['palette'].update(green=[28, 66, 42], dark=[13, 34, 23], light=[52, 100, 60], belly=[48, 92, 56],
                    plate=[26, 58, 38], eye=[255, 190, 40])
d['crystal_k'] = 1.0; d['yz_k'] = 1.0       # the v2 sheet already has the card's crystal size and chunky body
d['crystals'] = json.load(open('crystals_side.json'))
# the front view draws a much wider head than the top view (card: wide croc head) - widen from the neck forward
for st in d['stations']:
    if st['x'] > 1000: st['hw'] *= 1 + 0.38 * min(1.0, (st['x'] - 1000) / 120)
json.dump(d, open('mosa6_data.json', 'w'), indent=1)
print('crystals', len(d['crystals']), [round(c['x']) for c in d['crystals']])
