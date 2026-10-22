---
date: 2026-10-23
tags: [gymarc, progress]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-23 GYM ARC Evolutions chart discovery + aura detail panel

Prompts:
- [[2026-10-23 GYM ARC Prompt - Evolutions chart undiscovered stages]]
- [[2026-10-23 GYM ARC Prompt - Aura detail panel like alters]]

Game commit bb57631.

## Evolutions chart: undiscovered stages
- **Tracking:** stages are tracked again per player (`trainers.discovered`).
  - It includes BASE always, every stage you own now, and every stage a copy has reached. A stage stays discovered even after those copies are evolved away.
  - Existing players get the stages they own counted on their first load.
- **Chart look:** a stage you've never had shows the trainer as a black silhouette, "???", no LV, the background darkened with its effect off, and a grey border. The caption ("3x BEAST-MODE") stays.
- **First reveal:** the first time the chart opens after you reach a new stage, that tile flips over with a gold burst and a sparkle.
  - It uses the same "seen" save as the other reveals, so the very first open after this update shows no flips.
- **Unchanged:** the next-stage button in MY TRAINERS still names the real stage, and there's no server message.

## Inventory > Auras detail panel
- **Base:** the ALTERS detail's twin (196 wide, same rows and spacing).
- **Backgrounds:** each aura has its own moving background (`Shared/UI/AuraBackdrop`, made in code from shapes and the existing FX textures, no uploads), plus soft rings from the orb:

  | Look | Auras | Motion |
  |---|---|---|
  | Toxic | Toxic | rising bubbles |
  | Flame | Ember, Inferno, Titan, … | drifting embers and a low glow |
  | Golden | Golden, Royal, Living Legend, Gemstone | turning light rays and sparkles |
  | Frost | Frost, Stone Skin | glinting cracks and slow flakes |
  | Electric | Storm, Neon, Forged | faint lightning now and then |
  | Smoke | Shadow, Void, Blood Moon | slow smoke |
  | Stars | Galaxy | twinkling stars and a nebula |

- **Panel parts:**
  - outline in the aura's colour;
  - the orb centred with its glow (60 px, was 78);
  - the name white and stroked like "PUMPED";
  - the benefit in a slim dark pill outlined in its colour;
  - "RARE · AURA" with the rarity in its colour.
- **Button:** graphite. EQUIP, or EQUIPPED with a thin gold outline and gold text, or the price / pass when the aura is for sale.
- **Show effect:** a slim switch in the aura's colour, with "Boost stays active when hidden." under it.
- **Locked "???":** the same theme, darker and still, a silhouette orb with a grey rim, "???", and a grey switch so the colour isn't given away.

## Tested (Studio 844x390, temporary save)
- **Chart:**
  - a save at IRON-BORN: BEAST-MODE, COLOSSUS and LIMITLESS show "???";
  - evolved to BEAST-MODE, reopened: it flips to revealed.
- **Auras:** Golden owned, Toxic for sale then bought (EQUIPPED), and a locked one, next to the Pumped alter panel.
- No script errors; the tests pass.

## Not tested
- The motion and the sparkle sound (screenshots only).
- The other aura themes (Ember, Frost, Storm, Shadow, Galaxy) were only built, not screenshotted.

![[GYM ARC/Screenshots/chart_discovery/01_reached_iron_born.jpg]]
![[GYM ARC/Screenshots/chart_discovery/02_after_evolve_before_flip.jpg]]
![[GYM ARC/Screenshots/chart_discovery/03_beast_mode_revealed.jpg]]
![[GYM ARC/Screenshots/aura_detail/00_ref_pumped_alter.jpg]]
![[GYM ARC/Screenshots/aura_detail/01_golden.jpg]]
![[GYM ARC/Screenshots/aura_detail/02_toxic_for_sale.jpg]]
![[GYM ARC/Screenshots/aura_detail/03_toxic_equipped.jpg]]
![[GYM ARC/Screenshots/aura_detail/04_locked_storm.jpg]]
