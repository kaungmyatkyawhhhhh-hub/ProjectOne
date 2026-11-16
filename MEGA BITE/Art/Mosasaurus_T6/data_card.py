# Owner 16 Nov (card vs model side by side: "it have so much difference"): the CARD is the target where the
# ChatGPT sheets drifted from it. Runs AFTER data_exploded.py. Order:
#   analyse.py sheet_v2.png -> crys.py -> data.py -> data_exploded.py -> data_card.py -> mosa6_build.py
import json
d = json.load(open('mosa6_data.json'))
# card: green all over (the sheets invented the yellow belly) - the underside is just a lighter green
d['palette'].update(green=[40, 86, 52], dark=[20, 46, 32], light=[78, 128, 74], belly=[70, 118, 70],
                    plate=[30, 64, 42],                 # card: raised scutes are DARKER than the skin
                    eye=[255, 196, 40])                 # card: orange-yellow glowing eye
# card: big clustered crystals, the row runs down the tail to its tip
d['crystal_k'] = 1.3
tail = [(345, 15, 15), (305, 13, 13), (265, 11, 11), (225, 10, 9), (185, 8, 8), (148, 7, 6), (115, 6, 5)]  # x, height, width (sheet px)
have = {round(c['x']) for c in d['crystals']}
for x, h, w in tail:
    if x not in have: d['crystals'].append(dict(x=float(x), x0=x - w // 2, w=w, top=0, bot=h, a=0))
d['crystals'].sort(key=lambda c: c['x'])
# card: huge paddles, the front pair sticks out to the sides
d['flippers'] = [dict(name='Back', root=[495, 318], tip=[330, 425], spread=170, width=125, len_k=1.35, twist_deg=-20),
                 dict(name='Front', root=[950, 318], tip=[800, 430], spread=210, width=140, len_k=1.45, twist_deg=-25)]
# card: bigger teeth
d['head']['up_teeth']['len'] = 24; d['head']['lo_teeth']['len'] = 20
json.dump(d, open('mosa6_data.json', 'w'), indent=1)
print('crystals', len(d['crystals']))
