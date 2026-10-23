# Phoenix rebirth rewards (made by Claude, 2026-10-14)
Claude Code reported that the rebirth reward row shows the track, but the rewards don't exist yet. These are the models and textures for them. The look is in Content Plan section 12 ("What the rewards look like").

![[previews/rewards_sheet.png]]

| Rebirth | Reward | Files | How to build it |
|---|---|---|---|
| 1 | **Phoenix Dummy** (training post) | `R1_PhoenixDummy.glb` (Post, Arms, Leg, Frame, Star, Pad) | Place it on the empty grass right of the training area. It works like a training post giving **1.5x your best post**. The Star spins slowly and glows (Neon gold + PointLight); the Pad glows orange. VFX: gold sparks + `feather` sprites on each punch (RebirthVFX sprites). Black silhouette until unlocked (same as other posts). |
| 2 | **Phoenix Gloves** (Mythic) | `R2_PhoenixGlove_R.glb`, `R2_PhoenixGlove_L.glb` (Glove, Cuff, Wings) | **Changed (2026-10-14):** not a separate x65 glove (that skipped the glove shop every run). The Phoenix Gloves are a **permanent glove look plus +20%**. While "Phoenix look" is on, you see the Phoenix Gloves on your hands, but your power is **your equipped shop glove's multiplier x1.2** (x1.5 → x1.8 ... Infinity x50 → x60). It is kept through rebirths, so the glove shop still matters every run and Phoenix makes every glove better. ~~Toggle "Phoenix look" in the glove window.~~ **Shop display (owner, 2026-10-14):** no "PHOENIX: ON" button and no "Wearing: x1.8 (+20%)" text in the bottom bar. Instead the Phoenix Gloves are **their own special tile, first in the grid**: an animated orange-red flame gradient background, a gold border, the glove picture and a small "+20%" badge. Before rebirth 2 it's a locked silhouette with "REBIRTH 2" under it. Clicking it shows the big preview on the right: "Phoenix Gloves", a **MYTHIC** tag, "+20% to any glove", "Kept forever", and one button **WEAR** / **WEARING** (switches the look on/off; the +20% always stays). Effects: small `flame_flipbook` flames trailing from each fist and a flame puff on each punch. `GameConfig.PhoenixRewards.GlovesMultiplier` → replace with `GlovesBonus = 1.2`. |
| 3 | **Rebirth Aura** | no model | `VFX.PlayerAura(character, "#FFD34D", math.huge)` style but softer and permanent: a slow ring of gold `star` sprites around the feet + rising white-gold glow. Low Graphics: just the ring. |
| 4 | **+1 pet slot** | no model | Show it in the row as "PET SLOT" with a lock note "Coming with Pets!" until the Pets update exists; then it gives +1 equipped pet. |
| 5/10 | Bronze / Silver belt | already in the belt system | (master belts) |
| 7 | **Phoenix Bed skin** | `R7_PhoenixBed_blanket.png`, `R7_PhoenixBed_pillow.png` | Upload both. For the player who owns it (and has it on), every bed's blanket top gets a `Texture` (Face Top) with the blanket image (night blue with gold stars and a gold border) and the pillow gets the phoenix pillow image. Bed frame turns gold. Client-side only, toggle in Settings ("Phoenix Beds"). |

## Sensei legs
Not needed (owner, 2026-10-14). Keep Sensei as he is.

## Rainbow koi (polish 7)
- New, stronger textures are in `../7_RainbowKoi_textures_v2/` (Body, TailFin, Fins): fully saturated rainbow patches with dark outlines, so the glow doesn't wash them out.
- Make the koi **1.8x bigger**, use **3 koi instead of 5**, and lower the glow: Highlight FillTransparency 0.9 (instead of ~0.78) and a smaller PointLight.
