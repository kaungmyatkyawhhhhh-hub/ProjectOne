# VFX reference: "Claude makes professional level animations" (bbstudios, TikTok) - watched 11 Nov 2026

- URL: https://vt.tiktok.com/ZSpPXVDPD/ (@bbstudios4, video 7704058177859357982), 10.8 s, posted ~5 Nov 2026, #robloxdev #claude #ai #robloxdeveloper. On-screen text the whole time: "Claude makes professional level animations".
- How watched: yt-dlp on the PC was not reachable (Blender bridge down), so frames were pulled in Chrome (video seeked frame by frame onto a canvas, 0.14 s steps, cropped on the character). No audio transcript.
- Owner: "this vfx is crazy and it was made by claude too".

## What is on screen
A Roblox Studio viewport, dark grey baseplate, an R6 dummy doing a ~4 s looping sword combo (it plays 2.5 times).

| time in loop | beat | VFX |
|---|---|---|
| 0.0-0.6 s | idle, sword sheathed | nothing (calm before the hit) |
| ~0.4 s (1.20 s, 4.66 s, 8.26 s) | **anticipation flare** | big white 4-point star glint with **chromatic (RGB-split) fringes**, radial speed lines, a halftone-dot burst, a thin expanding ring, ground glow, a few rock chips. Lives ~0.15 s, fades fast |
| +0.15 s | draw | thin bright yellow sword with a glowing core, a few debris chips flying out |
| +0.3 s (1.76 s, 5.38 s) | **the slash** | two HUGE thick yellow crescent arcs (soft glowing edges, saturated core) sweeping across the screen, visible only 2-3 frames (~0.1 s); a dark wind smear swirls behind |
| +0.4-1.2 s | follow-through, spin | yellow sword trail; a dark scorch/crack streak stays on the ground and fades slowly; debris lands |
| +1.3 s | sheath | small sparks at the hilt, back to idle |

## Why it reads as "professional"
1. **Contrast in time**: long calm, then a 0.15 s flash, a 0.1 s slash, then a slow linger. Nothing is medium speed.
2. **Layering**: every hit is 4-6 layers at once (flare + ring + lines + crescent + smear + debris + ground mark), each simple.
3. **Anime glint language**: 4-point star + chromatic aberration + halftone dots = "this is a big moment".
4. **One hero colour** (yellow) on a dark scene; white for the flash; dark smoke for weight.
5. **Something stays**: the ground scorch fades over ~1 s, so the hit leaves a trace.

## For MEGA BITE (kid-friendly, no blood)
- **Big bite / CHOMP on a big fish**: anticipation glint at the jaw (4-point star + RGB fringe, 0.12 s) → 1-2 white/aqua bite crescents snapping shut (0.1 s) → bubble debris + a dark water swirl that fades over ~0.8 s.
- **Evolve / NEW ABILITY / crown**: star flare + halftone burst + ring on the shark, then the gold toast.
- **HUD**: the same glint (small, with the RGB fringe) sweeps across a counter when it pops; reward pops get a halftone burst behind the word.
- Rule to copy: calm → 0.1-0.2 s burst → slow linger. Layers, not complexity.
