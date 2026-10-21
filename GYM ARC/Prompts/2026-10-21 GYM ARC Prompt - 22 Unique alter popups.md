---
date: 2026-10-21
tags: [gymarc, prompt]
status: todo
---
# 22 Unique Body Alter popup per alter

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
The BODY ALTER READY popup looks the same for every alter. Make it unique for each alter, matching its name. Follow CLAUDE.md Speed rules. Mobile first (fits 667x375).

Art (made by the planner) in C:\Users\kaung\Downloads\gym_arc_alters\ui_tier1\:
  alter01_pumped_bg.png, alter02_shredded_bg.png, alter03_tanned_bg.png, alter04_vascular_bg.png, alter05_peak_bg.png (1200x480 backgrounds, no text)
  mockups.png = how each popup should look (layout + colors). Upload the 5 backgrounds (or tell me to bulk import them and list the files).

1) THEME PER ALTER (config, one entry per alter)
- background image, accent color (border, ALTER button), button text color, title gradient (2 colors), intro animation, sound, particles.
- OWNER UPDATE (21 Oct, see the updated mockups.png): border = 4 px (on screen, at the same scale as the trainer tiles) in the accent color + a 2 px dark inner ring + the soft outer glow (same as the trainer tiles). ALL text in the chunky font (LuckiestGuy) with dark strokes: one top line "BODY ALTER READY · ALTER 3" (adds " · TIER 1 COMPLETE" on the 5th alter) in white, then the alter NAME big, then the multiplier as the second-loudest line "x1.15 GAINS" in the accent color with a glow. Shredded has more and brighter slashes; Peak has a strong gold summit edge, a sun glow behind it, rays and gold particles (it's the finale).
- Layout stays the same for all: small "BODY ALTER READY" on top, the alter NAME big in the middle (Luckiest Guy, gradient + soft shadow), "Alter N · gains xN.NN" under it, ALTER (accent) + LATER (dark) buttons. The 5th alter of a tier adds "TIER 1 COMPLETE".

2) TIER 1 THEMES (match mockups.png)
- PUMPED: crimson; title red gradient. Intro: the panel pulses twice like a heartbeat (scale 1 -> 1.04 -> 1), the heartbeat line glows; a heartbeat thump sound.
- SHREDDED: steel/silver; ice-blue accent. Intro: the panel slices in with 2 quick diagonal flashes, the title wipes in from left to right; a sharp "shing" sound.
- TANNED: bronze sunset; orange-gold accent. Intro: the panel rises in, the sun rays slowly rotate behind (a rotating ray image or UIGradient), warm glow; a warm whoosh.
- VASCULAR: dark purple; red-to-blue title. Intro: the veins glow brighter in a wave from the edges to the center, a light pulse running along them; a deep pulse sound.
- PEAK: black + gold; gold title. Intro: a spotlight sweeps down onto the title, gold dust sparkles, the mountain edge shines; a triumphant hit. This is the tier finale, so it's the biggest one.

3) TIERS 2-6 (no art yet)
- Give each tier a theme from colors and UIGradients only, until the planner makes art: Stone (grey/brown, crack lines, a heavy thud), Metal (chrome/steel shine sweep, a metal clang), Gem (jewel color per alter: jade green, ruby red, sapphire blue, amethyst purple, diamond white, with a sparkle), Elements (frost blue / storm purple / lava orange / toxic green / plasma pink, each with fitting particles), Legend (titan bronze, galaxy stars, royal purple-gold, eclipse black-orange, celestial white-gold).
- Each alter uses its own name color, so no two popups look the same.

4) THE TRANSFORMATION MOMENT MATCHES TOO
- When ALTER is pressed, the transformation flash and title card use the same theme (color, sound, particles): e.g. Vascular veins flash over the screen, Tanned gets a sun flare, Peak gets the gold spotlight.

4a) THE ALTER BUTTON (owner, 21 Oct, LATEST, overrides the details below): style it like the trainer EVOLVE button and the updated mockups.png. A wide rounded bar (~20% wider than before) with a BRIGHT saturated accent-color gradient fill (light at the top, deeper at the bottom), not a dark panel, and the alter's own motif layered over it at ~50% (Pumped: heartbeat line + pulse rings; Shredded: bright diagonal slashes; Tanned: sunburst rays from the bottom; Vascular: red + blue veins; Peak: gold mountain summit with a bright edge, sun glow, rays and gold dust), 4 px dark outline, a white highlight line on the top edge, a thick darker bottom edge (6-7 px), soft glow in the accent color. Text: the alter NAME in chunky font with a DARK fill and a bright accent-colored stroke + glow (lit from behind), and "ALTER >" under it in white stroked text at ~60% of the name's size, so the button previews what you become. LATER: the small grey chunky button with the same 4 px outline, top highlight and 6-7 px bottom edge. The banner outline is 4 px + inner ring.
4a-old) THE ALTER BUTTON MUST LOOK LIKE A REAL BUTTON (owner: it looks flat). See the updated mockups.png.
- Raised 3D look: the face has a vertical gradient (lighter accent on top, darker at the bottom), a darker "lip" under it (6-8 px, about 45% of the accent color) so it looks thick, a soft drop shadow under that, a 2-3 px lighter UIStroke, and a glossy highlight strip on the top half (white, ~75% transparent, rounded).
- Text: Luckiest Guy "ALTER" with an arrow icon (>), white with a dark outline on dark accents, dark text on light accents (Shredded, Tanned, Peak), always high contrast.
- An outer glow in the accent color that breathes slowly, and a shine that sweeps across the face every ~2.5 s.
- Press feel: on press the face moves down into the lip (lip shrinks to 1-2 px, face 6 px lower, a bit darker) with a "clunk" sound; on release it pops back with a small bounce. Hover (PC): slightly brighter and 1.03x scale.
- LATER is the same 3D style but dark grey and smaller, so ALTER is clearly the main button.
- Big tap target on phones (at least 56 px tall). Make this button style a reusable component (Kit) so other important buttons in the game can use it later.

4b) MAKE IT DRAMATIC, WITH VFX (owner: "more exciting, dramatic")
Reuse the VFX textures in C:\Users\kaung\Downloads\gym_arc_aura_vfx\ (shockwave_ring, spark_star, ember_dot, lightning_flipbook_4x4, smoke_shaded_4x4, flame_flipbook_4x4, wisp_flipbook_4x4, rim_glow, ground_circle, droplet). Use UI ImageLabels (flipbooks via ImageRectOffset) for the popup and ParticleEmitters/Beams on the character for the transformation.

Popup entrance (about 1.2 s, the same beats for every alter, themed per alter):
- The screen dims to ~60% black with a vignette, the game sound ducks, a low riser sound builds.
- Letterbox bars slide in (top and bottom, black, 8% of the screen height).
- The panel slams in (scale 1.3 -> 1.0 with an overshoot), with a bass hit, a shockwave ring bursting out from the panel in the accent color, and a small camera shake (none with Reduced Motion).
- The alter NAME stamps in a beat later (scale 2 -> 1, white flash on the text, then the gradient), with sparks bursting from behind it.
- Looping while the popup is open: the accent border glows and pulses slowly, a light shine sweeps across the title every ~2.5 s, and themed particles drift behind the panel.
- The ALTER button breathes (glow pulse) to pull the tap.

Per-alter VFX (popup + transformation):
- PUMPED: red pulse shockwaves on every heartbeat, red embers rising, the screen edge throbs red with the beat.
- SHREDDED: white-blue slash lines cut across the screen, silver sparks, a quick freeze-frame on the slash.
- TANNED: a sun flare + god rays from below, golden heat shimmer, warm embers.
- VASCULAR: lightning-style vein crackles (lightning flipbook tinted red and blue) racing along the panel edges, a pulse traveling through the veins.
- PEAK: a gold spotlight cone, a gold dust rain, a big gold shockwave, and a crowd cheer. The biggest one.
- Tiers 2-6: same beats, with themed particles (stone: dust + falling chips; metal: sparks + shine sweep; gem: sparkles + prism flashes; elements: frost/lightning/fire/toxic bubbles/plasma; legend: stars + golden rays).

The transformation (after ALTER is pressed, about 3 s, skippable with a tap):
1. Camera cuts close to the character in slow motion; everything else goes dark (local Lighting/ColorCorrection tween).
2. Themed energy gathers into the body (particles pulled inward, rim_glow on the body in the accent color), a rising sound.
3. FLASH (full white for 0.15 s) + a shockwave ring on the floor (ground_circle) + a big bass hit + a camera shake.
4. The new skin is revealed with the body flexing (front double biceps pose), embers/sparks bursting out, then the title card "ALTER 3: TANNED" in the theme style, then the camera returns.
- Other players nearby see the flash, shockwave and particles too (not the camera move).

Performance: max ~40 particles on screen during the peak moment, ~20 while idle, everything cleaned up afterwards. Low graphics: fewer particles, no blur.

4c) VERY SATISFYING SOUND (owner request)
Sound is half of the drama. Build each moment from layered sounds, timed exactly to the visuals.
- Use only sounds from the Creator Store that are free to use in games (Roblox-uploaded or public audio). Search with the asset search tool, preview them, and pick clean, punchy ones. No copyrighted music. Put every sound ID in the theme config so I can swap them.
- Make a SoundGroup "AlterFX" and duck the music/gym sounds to ~30% during the popup and transformation, then fade them back over 1 s.

Popup entrance layers:
1. Riser (0.0-0.8 s): a rising whoosh/tension build, volume fading in.
2. IMPACT when the panel slams in: a deep sub-bass boom + a short punchy hit on top (both at the same moment, so it feels heavy).
3. Name stamp: a crisp "thwack"/stamp hit + a short shimmer tail.
4. Themed sting (one per alter): Pumped = 2 heartbeat thumps; Shredded = a sharp blade "shing"; Tanned = a warm whoosh + bright chime; Vascular = an electric crackle pulse; Peak = a triumphant brass-like hit + crowd cheer. Tiers 2-6: stone thud, metal clang, crystal chime, element sound (ice crack / thunder / lava roar / bubble / plasma zap), cosmic swell.
5. Idle: a very soft low hum loop while the popup is open.
6. ALTER button tap: a deep, satisfying confirm "clunk" (like a heavy plate locking in).

Transformation layers:
1. Slow-mo: all sound low-passed (EqualizerSoundEffect, highs down) + a heartbeat/charge-up build getting faster.
2. Energy gathering: a rising synth swell that gets louder and higher.
3. The FLASH: the biggest moment: a huge boom + a glass-like shatter/sparkle + a reverb tail (ReverbSoundEffect), with a short silence (0.2 s) right before it for contrast.
4. Reveal: a bright "level up" chime + the themed sting + a crowd "ooh/cheer".
5. Title card: a final punchy hit when the text lands.

Make it feel like progress:
- Raise the pitch of the chime by a small step for each alter (PlaybackSpeed 1.0, 1.03, 1.06...), so each alter sounds a little "higher" than the last.
- The 5th alter of a tier (tier finale) gets an extra layer (a bigger boom + longer cheer).

Mixing: nothing clips or is too loud; the impact is the loudest, voices/cheers are lower. Test on phone speakers (thin sound): the impact needs a mid-range punch layer, not only sub bass. Other players nearby hear the flash and boom at a lower volume (3D sound on the character).

5) SAME STYLE IN OTHER PLACES
- The Alters tab in the inventory and the PUMP SHOP Alters section: each alter's card uses its accent color and a cropped strip of its background.

Keep it light: one background image, a few tweens, max ~20 particles. Test each Tier 1 popup once (phone screenshot of 2 of them). Short progress note in the vault.
```
