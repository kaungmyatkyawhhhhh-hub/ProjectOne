# Look check (run on the screenshots before calling a look done)

Look at the before/after screenshots at phone size first (a Galaxy A06 is ~705×338), then PC. For each problem below: does it show? Fix the top 3.

## Readability (fix first)
- [ ] **Can I see where to go?** The path, the goal and the enemies stand out from the background (brighter, more contrast, more saturated, or outlined).
- [ ] **The darkest playable spot** is still readable on a phone at the default quality. Dark corners need Ambient up or a light, not "it's moody".
- [ ] **White UI over the world** (prices, names, damage numbers) is still readable: the world isn't so bright that white text vanishes, and bloom doesn't glow behind it.
- [ ] **Things far away** you need to see (landmarks, the next zone) are hazy but visible, not lost in fog.

## "Default Roblox" tells
- [ ] Grey horizon, grey shadows, grey sky → no Atmosphere colour, Ambient left grey, default sky.
- [ ] Flat, no contrast → ColorCorrection missing, or Contrast 0.
- [ ] Everything the same brightness → no key colour pair (warm light + cool shadow).
- [ ] Big flat surfaces with one colour → random textures / tone variation, a material variant, or terrain detail.
- [ ] The baseplate grid still shows in a "finished" game.

## Overdone tells
- [ ] **Washed out:** white parts glow, the sky is blown white → Bloom Threshold too low or Brightness too high.
- [ ] **Neon soup:** saturation > 0.5, every colour shouting → lower Saturation, keep Contrast.
- [ ] **Grey wall:** the horizon is a solid haze 50 studs away → Atmosphere Density too high or Offset too high on a land map.
- [ ] **Blurry game:** enemies or pickups blurred at mid range → DepthOfField too strong.
- [ ] **Filter look:** everything is tinted orange/blue like a phone filter → TintColor channel below ~215.
- [ ] **Sun rays everywhere:** streaks across the screen during play → SunRays Intensity > 0.15.

## Consistency
- [ ] Zone moods blend (no snap when crossing borders), and each zone still reads as the same game.
- [ ] Runtime scripts (day/night, biome mood, cutscene grade, hit flash) don't fight the new base. Check in Play, not Edit.
- [ ] The UI kit's window blur isn't stacking on top of the world's DepthOfField (double blur behind menus).

## Device check
- [ ] Phone screenshot: is it still pretty with fewer shadows? Phones drop shadow quality first, so the look must not depend on crisp shadows alone.
- [ ] PC screenshot: shadows are sharp where you wanted them and not jagged.
- [ ] Console (if supported): a 10-foot view, so contrast matters even more.
