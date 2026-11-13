"""Whole-Yangon map (14 Nov 2026): ground heights for the whole city box (SRTM 30 m through api.opentopodata.org, no key;
100 points a request, 1 request a second, 1,000 a day). Same source as batch 0.5's imports/refs/map/ygn_heights.json.

Grid: lon 96.095 .. 96.235, lat 16.750 .. 16.890, step 0.0005 deg (about 53 x 55 m) -> 281 x 281 = 78,961 points, 790 requests.
Writes build/city/dem_ygn.json {"lon0", "lat0", "step", "nx", "ny", "h": [rows south to north]} and resumes from
build/city/dem_partial.json if stopped.

Run from Games/CityLegends/tools/yangon/city:  python dem_fetch.py
"""
import json, os, sys, time, urllib.request

import geo

LON0, LAT0, LON1, LAT1, STEP = 96.095, 16.750, 96.235, 16.890, 0.0005
NX = int(round((LON1 - LON0) / STEP)) + 1
NY = int(round((LAT1 - LAT0) / STEP)) + 1
OUT = os.path.join(geo.BUILD, 'city', 'dem_ygn.json')
PART = os.path.join(geo.BUILD, 'city', 'dem_partial.json')


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    pts = [(LAT0 + j * STEP, LON0 + i * STEP) for j in range(NY) for i in range(NX)]
    got = json.load(open(PART)) if os.path.exists(PART) else {}
    todo = [k for k in range(0, len(pts), 100) if str(k) not in got]
    print(f'{NX} x {NY} = {len(pts)} points, {len(todo)} requests to go')
    for n, k in enumerate(todo):
        batch = pts[k:k + 100]
        q = '|'.join(f'{a:.5f},{b:.5f}' for a, b in batch)
        url = 'https://api.opentopodata.org/v1/srtm30m?locations=' + q
        for attempt in range(6):
            try:
                req = urllib.request.Request(url, headers={'User-Agent': 'CityLegendsMapTool/1.0'})
                d = json.load(urllib.request.urlopen(req, timeout=60))
                if d.get('status') == 'OK':
                    got[str(k)] = [r['elevation'] for r in d['results']]
                    break
                print('status', d.get('status'), d.get('error'))
            except Exception as e:
                print('retry', k, e)
            time.sleep(3 + attempt * 5)
        time.sleep(1.05)
        if n % 25 == 0:
            json.dump(got, open(PART, 'w'))
            print(f'{n + 1}/{len(todo)}', flush=True)
    json.dump(got, open(PART, 'w'))
    h = []
    for k in range(0, len(pts), 100):
        h += got[str(k)]
    rows = [h[j * NX:(j + 1) * NX] for j in range(NY)]
    json.dump({'lon0': LON0, 'lat0': LAT0, 'step': STEP, 'nx': NX, 'ny': NY, 'source': 'SRTM 30 m via api.opentopodata.org', 'h': rows},
              open(OUT, 'w'))
    print('wrote', OUT)


if __name__ == '__main__':
    main()
