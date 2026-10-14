# Phoenix rebirth rewards (made by Claude, 2026-10-14)
Claude Code reported that the rebirth reward row shows the track, but the rewards don't exist yet. These are the models and textures for them. The look is in Content Plan section 12 ("What the rewards look like").

![[previews/rewards_sheet.png]]

| Rebirth | Reward | Files | How to build it |
|---|---|---|---|
| 1 | **Phoenix Dummy** (training post) | `R1_PhoenixDummy.glb` (Post, Arms, Leg, Frame, Star, Pad) | Place it on the empty grass right of the training area. It works like a training post giving **1.5x your best post**. The Star spins slowly and glows (Neon gold + PointLight); the Pad glows orange. VFX: gold sparks + `feather` sprites on each punch (RebirthVFX sprites). Black silhouette until unlocked (same as other posts). |
| 2 | **Phoenix Gloves** (Mythic) | `R2_PhoenixGlove_R.glb`, `R2_PhoenixGlove_L.glb` (Glove, Cuff, Wings) | A new glove in the glove list, unlocked by Rebirth 2 (not sold). It is welded to each hand like the other gloves; the hand sits inside Glove, Cuff toward the arm, and the Wings fan out of the cuff. Effects: small `flame_flipbook` flames trailing from each fist (rate low), plus a flame puff on each punch. Better than the best Cash glove. |
| 3 | **Rebirth Aura** | no model | `VFX.PlayerAura(character, "#FFD34D", math.huge)` style but softer and permanent: a slow ring of gold `star` sprites around the feet + rising white-gold glow. Low Graphics: just the ring. |
| 4 | **+1 pet slot** | no model | Show it in the row as "PET SLOT" with a lock note "Coming with Pets!" until the Pets update exists; then it gives +1 equipped pet. |
| 5/10 | Bronze / Silver belt | already in the belt system | (master belts) |
| 7 | **Phoenix Bed skin** | `R7_PhoenixBed_blanket.png`, `R7_PhoenixBed_pillow.png` | Upload both. For the player who owns it (and has it on), every bed's blanket top gets a `Texture` (Face Top) with the blanket image (night blue with gold stars and a gold border) and the pillow gets the phoenix pillow image. Bed frame turns gold. Client-side only, toggle in Settings ("Phoenix Beds"). |

## Sensei legs
Not needed (owner, 2026-10-14). Keep Sensei as he is.

## Rainbow koi (polish 7)
- New, stronger textures are in `../7_RainbowKoi_textures_v2/` (Body, TailFin, Fins): fully saturated rainbow patches with dark outlines, so the glow doesn't wash them out.
- Make the koi **1.8x bigger**, use **3 koi instead of 5**, and lower the glow: Highlight FillTransparency 0.9 (instead of ~0.78) and a smaller PointLight.
