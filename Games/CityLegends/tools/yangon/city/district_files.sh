#!/bin/sh
# district_files.sh <tag> [--no-roads] (2026-11-16, up to batch 3): the whole offline chain of a 1:1 district, then the
# three placement packs for DistrictPlace.luau. "district_files.sh P10 --no-roads buildings" skips roads and terrain. Run from tools/yangon/city. Logs in build/city_1to1/<step>_<tag>_log.txt.
set -e
T=$1; t=$(echo $T | tr P p); B=../../../build/city_1to1; S=../../../imports/sync/ygn1to1_$t
export YANGON_SCALE=1to1 PYTHONIOENCODING=utf-8
F=${3:-all}
[ "$2" = "--no-roads" ] || python -u roads.py $T --no-glb --jobs 6 > $B/roads_${T}_log.txt 2>&1
[ "$F" = "buildings" ] || python -u terrain.py $T > $B/terrain_${T}_log.txt 2>&1
python -u buildings_1to1.py $T > $B/buildings_${T}_log.txt 2>&1
python -u green_1to1.py $T > $B/green_${T}_log.txt 2>&1
python pagoda_rows.py $T
fs=$(ls $B/terrain_$T/Terrain${T}_*.luau | sort -V); n=$(echo "$fs" | wc -l); h=$((n / 2))
python ../pack_strings.py $S/terrain_${t}_a.rbxmx ${T}TerrainA $(echo "$fs" | head -n $h) | tail -1
python ../pack_strings.py $S/terrain_${t}_b.rbxmx ${T}TerrainB $(echo "$fs" | tail -n +$((h + 1))) | tail -1
python place_pack.py $T
ls -la $S/cells_*.glb
echo "district $T done"
