# Custom VFX for the cutscenes (made by Claude, 2026-10-14)
The owner said the animals look ugly without VFX and asked for custom VFX on every cutscene. Everything here is custom: no Creator Store assets.

![[sprites_sheet.png]]

## Files
- `sprites/`: 23 custom particle images (256x256, transparent, mostly white so the code can tint them): glow, spark, star, flame, flame_white, smoke, feather, ember, snowflake, ice_shard, coin, bubble, ring, petal, claw_slash, lightning, rune_circle, rays, cloud, trail, energy, dust, orb.
- `RebirthVFX.luau`: a ModuleScript with **its own VFX for each of the 8 animals**: particles on the wings/tail/mouth/body, light trails on the wing tips and tails, a spirit outline and a pulsing inner light, afterimages, the burst moment (white flash, light rays, double shockwave ring, vertical ring, spinning rune circle, camera zoom-punch), each animal's special burst, and a dissolve into particles at the end. Compiles with Luau.
- `RebirthVFXAnchors.luau`: the exact points on each model (wing tips, tail tips, mouth, paws, spine...) the VFX attach to. Generated from the models, so they line up.

## Flames: no Roblox default fire (owner, 2026-10-14)
The owner said the flame around the character looked like Roblox's default Fire effect, which is ugly.
- **Never use Roblox's built-in `Fire`, `Smoke` or `Sparkles` instances** anywhere in the cutscenes.
- All flames now use `flame_flipbook.png`: a custom **animated cartoon flame** (16 frames, 4x4 flipbook, hard cel-shaded bands, sharp tongues, white-hot core) that stays upright. The code sets `FlipbookLayout = Grid4x4`, `FlipbookMode = Loop` and `Orientation = FacingCameraWorldUp`.
- The glow around the player is now `VFX.PlayerAura(character, color, seconds)`: an **anime power aura** with sharp energy spikes (`aura_flipbook.png`) rising in a ring around the feet, white-hot inner spikes, a soft body glow, rising embers, a ground ring and a light. Use it in the belt cutscenes (belt color), the rebirth cutscene (tier color) and the black belt cutscene (gold).

![[flame_flipbook_prev.png]]

## Swirl tornado: VFX only, no parts (owner, 2026-10-14)
The owner said the swirl bands around the player (rebirth step 2) were blocky parts. **Never build the swirl from Parts/MeshParts.** Use `VFX.Swirl(rootPart, {tierColor1, tierColor2}, seconds)`:
- 5 glowing **energy ribbons** (curved Beams with the flowing `swirl_band.png` texture) spiral up around the player. They spin faster and faster, tighten in, rise, and swell in the middle.
- **Spinning swirl particles** (`swirl.png`) under the feet, plus white sparks shooting up.
- At the end the ribbons thin out and vanish. It returns a stop() function. Low Graphics uses 3 ribbons.
- Colors per tier, for example the Phoenix uses {"#FFE27A", "#FF8A1E"} and the Galaxy dragon {"#E048C8", "#6A2CFF", "#3FA8FF"}.

![[swirl_band_prev.png]] ![[swirl_prev.png]]

## What each animal gets
| Animal | Looping VFX | Burst moment |
|---|---|---|
| Phoenix | gold flame aura, falling gold feathers from the wings, embers from the tail, sparkles on the crest, gold-orange trails on wing tips and 3 tail plumes | feather explosion |
| Tiger | orange spirit flames along the back, lightning crackles, dust under it, roar rings from the mouth, trails on all 4 paws and the tail | giant 3-line **claw slash**, dust cloud, glowing ground cracks |
| Crane | moonlight motes, slowly falling silver feathers, mist under the feet, long thin white trails | silver feathers, a big **full moon** behind it |
| Gold dragon | golden flames along the spine, **coins** spilling out, lucky clouds, twinkling stars, trails on whiskers, tail and body | coin explosion + **coin rain** from above |
| Ice dragon | snowflakes, falling ice shards from the wings, **frost breath**, ice sparkles, cold glow | ice shard explosion, snow, **frost spreading** on the ground |
| Fire phoenix | huge flames over the body, flame wings, ember storm, dark smoke, fire breath | fireball burst, smoke, **lava cracks** on the ground |
| Rainbow koi | bubbles, rainbow sparkles, sakura petals, water ripple rings, rainbow trails off the tail fin | bubble burst, rainbow sparks, a **rainbow arc** |
| Galaxy dragon | purple/blue nebula clouds, stars, energy at the mouth, tiny planets drifting off, cosmic trails | star explosion, a spinning **vortex**, **3 planets orbiting** you |

## How to use it (for Claude Code)
1. Upload all PNGs in `sprites/` (Asset Manager → Bulk Import) and paste the ids into `VFX.Sprites` at the top of `RebirthVFX.luau`.
2. Put `RebirthVFX` and `RebirthVFXAnchors` in ReplicatedStorage. The imported models must keep their part names (Body, WingR, Tail, ...) and be named Phoenix, Tiger, Crane, GoldDragon, IceDragon, FirePhoenix, RainbowKoi, GalaxyDragon.
3. In the rebirth cutscene (client): clone the model, then `local fx = VFX.Attach(model, name)` → move/animate it → `VFX.Burst(model, name, groundPos)` at the burst moment → `VFX.Dissolve(model, name, 0.8, fx)` at the end.
4. `VFX.SetLowGraphics(true)` when the player has Low Graphics on (fewer particles, no afterimages).
5. Tune sizes/rates by looking at it in Play. The numbers are a strong starting point, not final.
