---
date: 2026-11-12
tags: [stomp-evolution, titan, armour, stone-set, bundle, studio]
status: STONE v6 IN STUDIO (saved, version 12, not published). Owner on v5: "way better but korblox still looks way better".
---
# Stomp Evolution: Stone set v6 (full cuirass, crystal crests) — 12 Nov 2026, 12:10 to 13:00

Follows [[2026-11-12 Stomp Evolution - Stone set v5 (bundle proportions, body-part swap)]].

## What Korblox General does (close-up study in Studio, `Art\Stone\v6\korblox_general_closeup.jpg`)
1. The armour covers the whole torso up to the collar: one big carved block, no under-suit visible above the belt.
2. Strong silhouette: tall crystal spikes on BOTH shoulders (symmetric), sticking up past the head.
3. Every plate edge has a light trim band (pale blue strip) = crisp readable shapes at any distance.
4. Carved pattern bands (a key/meander pattern) on the collar, belt and skirt; one focal design on the chest (a carved face with crystal eyes).
5. Dark base colour + ONE bright accent (ice crystals). Hands are plain gloves; thighs plain dark.
6. Texture: one classic TextureID per part (no SurfaceAppearance).

## v6 changes (`Art\Stone\stone_v6.py`, `stone_v6_paint.py`)
- Full stone cuirass over the torso with raised top and bottom rims; chest straps removed (cleaner).
- Stone plate on the upper arm under the pauldron (no suit showing).
- Three green crystals on each pauldron, mirrored (silhouette like Korblox, our own shapes, top below the hair).
- Paint: light rim on every plate edge, darker crevices.
- Measured: UpperTorso 2.53 wide (Korblox 2.41), LowerTorso 1.64.
- Assets (Myanmar Builders Club): model `118479513000221`; Torso colour `113491146669083` (TextureID); Arms `97310338748240` / glow `108676499561812`; Legs `84827377445998` / glow `133277814429064`. v5b template kept in `ServerStorage.StompEvolution.Raw.Stone_v5b`.

## Problems found (lessons)
- **A texture used before Roblox approves it is cached as a failure for the whole Studio session.** Wait for `moderationState = Approved` (poll the assets API) BEFORE putting the ID on anything; if it already failed, upload a fresh copy.
- **The torso SurfaceAppearance did not render in Play (stayed plain grey) even with fetch status Success**, while arms and legs did. The torso now uses the classic `TextureID` (like the catalog bundles). `ArmourKit.Apply` sets those parts and the torso body colour to white, otherwise the texture is tinted by skin colour. Glow on the torso is baked into the colour (no bloom).
- The dark wedge on the chest in the Blender renders is the head's shadow from the render light, not a texture bug.

## Honest list: why Korblox still wins
1. Our colours read muddy in Studio's light (beige-grey on grey); Korblox is near-black with bright trim and bright crystals = high contrast.
2. No carved pattern bands; our surfaces are plain.
3. No single strong focal design on the chest (our gem is small).
4. Our crystals are small and thin next to Korblox's.

## Next (in order)
1. Higher contrast palette: darker stone body + pale sandstone trim bands on every plate edge as real geometry (not only paint).
2. Carved pattern band on collar, belt and skirt; a bigger carved chest emblem with the gem.
3. Bigger crystals (still symmetric, top below the head top).
4. Try a ChatGPT hand-painted texture sheet for the stone surfaces (the owner's pipeline) instead of procedural paint.
