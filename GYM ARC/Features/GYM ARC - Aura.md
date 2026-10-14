---
date: 2026-10-14
tags: [gymarc, feature, monetization]
status: built
aliases: [Auras, Aura system]
---
# GYM ARC - Aura

Back to [[00 GYM ARC Home|GYM ARC Home]].

A cosmetic glow around your character (owner, 14 Oct). Everyone sees everyone's aura. Built 14 Oct.

## What an aura is
- Three layers, all sized from your character (a tiny new player and a 7'0" mass monster both look right):
  1. **Inner glow:** soft particles around the upper body and a soft light.
  2. **Outer energy:** flames, smoke, mist, electricity, stars or toxic bubbles rising from the body (each aura has its style and two colors).
  3. **Sparks:** sparks bursting out and a thin column of light.
- **Walking around:** only the inner glow, at half strength.
- **Lifting:** the glow at full; layer 2 joins at 50% PUMP; layer 3 at 100% PUMP or while PUMPED.
- **New personal record:** every layer bursts once with a sound.
- **Equipping** shows it at full power for 3 seconds.
- No Highlight effects (Roblox limits them).

## The 13 auras (`Config/Auras`)
| Aura | Rarity | How to get it |
|---|---|---|
| Ember | Common | Reach LVL 10 |
| Frost | Uncommon | Reach LVL 25 |
| Storm | Rare | Reach LVL 50 |
| Golden | Legendary | Reach 7'0" |
| Titan | Legendary | Finish every Coach quest |
| Inferno, Blood Moon, Void, Neon, Galaxy | Epic | Aura Pack pass (2033954299) |
| Royal | Legendary | VIP pass (2032988308) |
| Toxic | Rare | 50,000 coins |
| Shadow | Epic | 150,000 coins |

Earned and bought auras are kept forever. Pass auras count while you own the pass, and unlock the moment you buy it.

## Where you pick it
- **Titles > AURAS tab:** the picked aura big on the left (art, name, rarity, how to get it, EQUIP / EQUIPPED / the coin price / AURA PACK / VIP) and "Aura: Off"; a grid of all 13 on the right.
- **Store > AURAS tab:** all 13 with how to get them; "VIEW AURAS" opens the Titles tab.
- A live 3D preview inside the window isn't possible (Roblox doesn't draw particles in a ViewportFrame); the icon art shows instead, and equipping shows the real aura on your character.

## Other players and performance
- Other players' auras: off beyond 40 studs, only the glow from 20 to 40 studs, at most the nearest 8.
- Settings "Others' Auras" On / Off; Low Graphics also turns them off.
- Half the particles on phones.

## Where it lives
- `Config/Auras` (the list, icons, distances), `AuraService` (server: who owns what, buying, the worn aura), `AuraClient` (draws them), `TitlesClient` (the tab), `StoreClient` (the Store tab). The PR burst comes from `MachineService`.
- The 13 icons were uploaded from Studio, so they're in the owner's own inventory (see [[GYM ARC - Assets]]).

## Screenshots
![[GYM ARC/Screenshots/aura_golden.jpg]]
![[GYM ARC/Screenshots/aura_ember.jpg]]
![[GYM ARC/Screenshots/aura_frost.jpg]]
![[GYM ARC/Screenshots/aura_storm.jpg]]
![[GYM ARC/Screenshots/aura_titan.jpg]]
![[GYM ARC/Screenshots/aura_inferno.jpg]]
![[GYM ARC/Screenshots/aura_blood_moon.jpg]]
![[GYM ARC/Screenshots/aura_void.jpg]]
![[GYM ARC/Screenshots/aura_neon.jpg]]
![[GYM ARC/Screenshots/aura_galaxy.jpg]]
![[GYM ARC/Screenshots/aura_royal.jpg]]
![[GYM ARC/Screenshots/aura_toxic.jpg]]
![[GYM ARC/Screenshots/aura_shadow_before_fix.jpg]]
![[GYM ARC/Screenshots/aura_panel.jpg]]
![[GYM ARC/Screenshots/aura_store_tab.jpg]]

(Shadow was too faint in that picture; its smoke was made thicker and lighter after it.)

## History
- 13 Oct (planned, not built): a 4-layer aura that grows with the set, with colors sold through the Aura Pack:

- **Layers (more turn on as the set gets harder or the player gets stronger):**
  - **Layer 1** (any lift): soft heat haze rising off the body, low opacity
  - **Layer 2** (rep 5+ in the set, or lift at least 70% of max): flame-like wisps from the shoulders and back
  - **Layer 3** (lift at least 85% of max): a bright outline glow that pulses on each rep
  - **Layer 4** (personal record or mass monster): sparks / electric arcs around the arms + a burst on rep complete
- **Colors:** default red / orange; `Config.Aura.Colors` with red, blue, purple, gold, green for the shop (the "Aura Pack" pass unlocks all).
- **Rules:** follows the body at every size (skinny to mass monster, up to 7'0"), never floats; fades out 1 s after the set; must not hide the muscles or the red training tint.
- **Performance:** max particle counts in Config; fewer particles on other players; layers 3-4 off for others under 45 FPS or with more than 8 players nearby; 60 FPS on the phone emulator with 4 players lifting.

## Related
[[GYM ARC - Game Feel]], [[GYM ARC - Monetization]], [[GYM ARC - Muscles and Bodies]]
