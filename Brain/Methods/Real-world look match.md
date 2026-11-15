---
tags: [brain, method, look, maps, landmarks]
created: 2026-11-16
---
# Real-world look match

**Owner's words:**
- "the materials, textures, looks, colors, designs, lighting is not same as the real life myanmar plaza" (16 Nov 2026)
- "the scaling measurements must be 1:1 accurate too" (16 Nov 2026)
- "save them ... as a blueprint for future map updates and future updates and for future games" (16 Nov 2026)

**Use when:** building any real place, building or object in a Roblox game, or when the owner says something "doesn't look like the real one".
**Skill:** none yet. Offer to make one when it is used again.

## Steps
1. **Lock the scale first.**
   - Use one scale for everything: map, buildings, cars and players.
   - In City Legends that is 3 studs per metre: the cars' STUDS_PER_METRE, the players' size.
   - Use real lane widths, real floor heights, real door and ceiling heights.
   - Never mix a "map scale" with "player-scale floors": buildings come out tall and thin, and players and cars too big.
2. **Gather references.**
   - Several photos per surface, in different light: midday sun, overcast, dusk, night.
   - Add satellite (it leans: move tower bases back), OSM outlines and real floor counts.
3. **Measure, don't guess.**
   - Draw boxes on clean flat areas of each surface. Take the median and 20th / 80th percentile sRGB values.
   - Save a crop for every box.
   - Write down the photo's light and colour cast, the finish (matte, satin, glossy, mirror) and the joint pattern.
   - Check the white balance on something known to be white (a kerb, a banner).
4. **Measure the game's light.**
   - Make colour test panels: each material x 10 greys, in sun and in shade.
   - Shoot them in Studio under the exact Play lighting, then measure the screenshots.
   - If whites come out tinted (Yangon's came out blue), fix the light itself (ask the owner: it changes the whole map). Don't just push the colours.
5. **Convert photo colours to part colours** with the measured curves (`look_calib.py`), so they render as the photos. Pick materials that render predictably:
   - SmoothPlastic with a little Reflectance for stone, panels and paint.
   - Glass with Reflectance 0.2 for reflective glass.
   - Avoid textured materials for exact colours: they render much darker.
6. **Build the night too.**
   - Lit windows as separate panes in front of the glass, for the measured share of bays, in the measured colours (offices mixed amber, yellow and cool; hotels warm and sparse).
   - Letters and signs that glow.
   - Everything hidden by day.
7. **Fill the inside if players can walk in:** shops fitted by kind, people walking the floors.
8. **Check in the game.** Screenshots in Play, by day and by night, next to the photos. Fix and repeat.
9. **Save the research** in the game's folder as a research note: tables, light notes, findings, file paths.

## Tools
- Python (PIL, numpy) for measuring.
- City Legends tools:
  - `tools/yangon/Swatches.luau`, `PlayLight.luau`
  - `tools/yangon/city/swatch_measure.py`, `look_calib.py`
  - `geom3d.py` (`lit_bays`), `landmark_glb3d.py` (`GROUPS`, `NIGHT`)
- Workflow agents: one per building part, each measuring its photos in parallel.

## Output
- A research note in the game's folder with every measured colour, finish, light note and night share.
- Colours set in code, plus a before / after screenshot pair, by day and by night.

## Used on
- 2026-11-16, City Legends, Myanmar Plaza and Sedona: daylight warmed, colours matched, night windows, shops, shoppers, the Sedona gate. Research: [[2026-11-16 Research - Myanmar Plaza and Sedona real look (photo measurements)]].

## Learned
- **Use midday or overcast photos for colours, never sunset or dusk** (16 Nov: Myanmar Plaza's white panels and walls came out cream from evening photos, and the owner caught it twice). When photos disagree, pick the more neutral, lighter reading, and say the colours in words first ("white bands, dark glass").
- **Measure the light before the colours.** Under a blue-tinted light no part colour looks right.
- **Scale is part of "real".** The owner noticed the half-scale map before any colour fix.
- Photos at dusk read 30-40% darker than daylight. Use daylight or "lit" values for the day look.
- Real glass has no colour of its own: it takes the sky's (navy at noon, grey when overcast, silver at grazing angles). Model it as reflective glass, not a blue colour.
