# Break A Bed: Effects

#break-a-bed #effects

Back to [[Break A Bed/Project Overview|Project Overview]].

Owner's request (2026-10-12): effects as flashy as the simulator the owner likes (glowing auras, swirls, sparkles, bloom, neon colors, big announcements). Everything below is made from Roblox `ParticleEmitter`, `Beam`, `PointLight`, `Highlight` and lighting effects, using our own white particle images. White images can be **any color**: the emitter's `Color` tints them.

![[_fx-sheet.png]]

## Particle images (this folder; Bulk Import them)
| File | Look | Use |
|---|---|---|
| `fx-star4.png` | 4-point twinkle | sparkles everywhere |
| `fx-glow.png` | soft round glow | auras, light orbs, the base of every burst |
| `fx-ring.png` | glowing ring | shockwaves on bed breaks and level ups |
| `fx-swirl.png` | 3-arm swirl | spinning magic around auras and boosts |
| `fx-spark.png` | thin streak | fast sparks flying out of hits |
| `fx-smoke.png` | soft puff | dust when a bed breaks |
| `fx-shard.png` | crystal shard | bed pieces / crystal beds |
| `fx-beam.png` | soft light strip | `Beam` texture for light beams |

## 1. Lighting (the base of the "glowy" look)
In `Lighting`:
- `Bloom`: Intensity 0.6, Size 28, Threshold 0.92 (bright and neon things glow).
- `ColorCorrection`: Saturation 0.15, Contrast 0.08, Brightness 0.02 (more colorful).
- `SunRays`: Intensity 0.06, Spread 0.6.
- `Atmosphere`: Density 0.25, Haze 1.2, Glare 0.3, Color light blue.
- Low Graphics setting ([[Break A Bed/Settings|Settings]]) turns Bloom and SunRays off.

## 2. Bed break (the biggest moment)
Played on the breaking player's screen, at the bed:
1. **Flash:** a white `fx-glow` burst (Emit 1, Size 0 → 18, Lifetime 0.25, Transparency 0 → 1, LightEmission 1).
2. **Shockwave:** `fx-ring` flat on the ground (Emit 1, Size 2 → 22, Lifetime 0.4, fading). It's tinted the bed's tier color.
3. **Sparkles:** `fx-star4` (Emit 25, Speed 12–25, SpreadAngle 180, Size 1.5 → 0, Lifetime 0.6–1, RotSpeed ±200, LightEmission 1) in the tier color + white.
4. **Sparks:** `fx-spark` (Emit 15, Speed 30–45, Orientation VelocityParallel, Size 0.4 → 0, Lifetime 0.3).
5. **Dust:** `fx-smoke` (Emit 8, Speed 3–6, Size 4 → 8, Transparency 0.4 → 1, Lifetime 1.2, grey).
6. **Light pop:** a `PointLight` (Brightness 6, Range 20, tier color) tweened to 0 in 0.4 s.
7. Keep the existing pieces, cash and confetti, and add a small camera shake (already in the game).
- **Later beds get crazier:** from the Crystal Bed on, add rising `fx-swirl` and a vertical light beam (`fx-beam` Beam, Width 6, LightEmission 1, 0.6 s). From the Galaxy Bed on, everything is doubled and purple/pink.

## 3. Beds glow by tier
- Beds from the Ice Bed onwards get a `Highlight` (FillTransparency 0.85, OutlineTransparency 0.3, the tier color), Neon trim parts and a slow `fx-star4` sparkle emitter (Rate 3, Size 0.6, Lifetime 1.5).
- The Infinity Bed has a rainbow-cycling Highlight and floating `fx-glow` orbs.

## 4. Player auras (show progress; others can see them)
Attached to the HumanoidRootPart. Better aura = more status = players want to level up and rebirth.
| Level / status | Aura |
|---|---|
| Level 10+ | slow white `fx-star4` sparkles (Rate 4) |
| Level 25+ | + a blue `fx-glow` aura (Rate 6, Size 3–4, Transparency 0.7, LockedToPart) |
| Level 50+ | + purple `fx-swirl` spinning around the body (RotSpeed 90, Rate 2) |
| Rebirth 1+ | + a `Trail` behind the player in the rebirth color |
| VIP | a gold aura + gold sparkles + a gold Trail |
| Active boost | a colored swirl at the feet (x2 green, x3 cyan, x5 purple, x10 rainbow) while it lasts |
- Settings "Other Players' Effects OFF" hides other people's auras.

## 5. Hits and numbers
- Each punch: a small white `fx-glow` pop + 3 `fx-spark` on the bed, and a big **italic** damage number that pops up (scale 0 → 1.2 → 1, Back Out) and floats away. Critical hits are orange, twice as big, with a `fx-ring` pulse.
- "+$" numbers fly toward the Cash counter.

## 6. Big text and announcements
- **Server announcements** at the top center for everyone (white with a dark stroke, the important part colored): "**Rong** broke the **INFINITY BED!**", "**Rong** bought **SERVER x2 STRENGTH!**", "**Rong** reached **Level 50!**". They slide down, stay 4 s and fade.
- **Big center text** with a glow for: NEW BED UNLOCKED!, LEVEL UP!, SERVER x2 STRENGTH!, WEEKEND EVENT! It pops in (0 → 1.15 → 1), has a `fx-ring` burst behind it and plays a sound.
- **Level up:** a gold `fx-ring` shockwave + a sparkle fountain from the feet + a light beam up for 0.8 s.

## 7. World
- Floating `fx-glow` orbs and `fx-star4` sparkles over the bed path (Rate low, big area, slow).
- Neon edges on zone gates and the later zones' tiles, color-matched to each zone.

## Performance
- All effects are client-side, emitted only near the player, and capped (the game already pools effects).
- Low Graphics: half the particles, no bloom, no auras on other players.

## For Claude Code (in the code folder: `Cashgrab` or `BAB`)
Build an `Effects` module (client) with functions `BedBreak(bed, tier)`, `Hit(pos, crit)`, `LevelUp(player)`, `Announce(text, highlight)`, `BigText(text)`, plus aura setup on character spawn. Use the particle images from this folder and the numbers above. Test in Studio and on the phone emulator.
