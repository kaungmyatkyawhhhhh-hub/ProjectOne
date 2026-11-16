"""pagoda_rows.py <tag> (2026-11-16, up to batch 3): PagodaPlace rows (id|name|x|z|groundY|W|H|shape|yaw|class|scheme|0,
studs) of every build/pagodas/pagodas.json pagoda inside a 1:1 district box -> build/city_1to1/pagodas_<tag>.txt
(place_pack.py packs it as PagodaData). pagodas.json covers pagodas_plan.PLACE_BOX only."""
import json, os, sys
import geo

tag = sys.argv[1]
lo0, la0, lo1, la1 = geo.PILOT_LL[tag]
d = json.load(open(os.path.join(geo.BUILD, 'pagodas', 'pagodas.json'), encoding='utf-8'))
rows = ['%s|%s|%.2f|%.2f|%.2f|%.2f|%.2f|%s|%s|%s|%s|0' % (p['id'], p['name'].replace('|', ' '), p['x'], p['z'], p['ground_y'],
        p['w'] * 3, p['h'] * 3, p['shape'], p['yaw'], p['cls'], p['scheme'])
        for p in d['pagodas'] if lo0 <= p['lon'] <= lo1 and la0 <= p['lat'] <= la1]
open(os.path.join(geo.BUILD, 'city_1to1', 'pagodas_%s.txt' % tag), 'w', encoding='utf-8', newline='\n').write('\n'.join(rows) + '\n')
print(tag, len(rows), 'pagodas; place box', d['place_box'])
