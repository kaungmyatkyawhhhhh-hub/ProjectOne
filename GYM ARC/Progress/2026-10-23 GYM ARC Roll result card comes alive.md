---
date: 2026-10-23
tags: [gymarc, progress, trainers]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-23 GYM ARC Roll result card comes alive (prompt 56)

Prompt: [[2026-10-23 GYM ARC Prompt - 56 Roll result card comes alive]]

Game commit 4083e58. New module `Shared/UI/RollCardFX`; every number is in `Config/RollReveal` (Alive, Themes, Card, Time).

## What changed
- **The sunburst is gone.** Each trainer's card has his own moving background:
  - **Volta:** a dark blue storm. Lightning flickers behind him, and sparks crawl round the border.
  - **Duke:** dark steel with glowing orange forge cracks and drifting sparks.
  - **The Shadow:** black-purple smoke drifting up, and two purple eyes that glint now and then.
  - **Atlas:** warm gold with white-gold clouds, slow soft light beams and a faint laurel.
  - **Coach Sam to Coach Rex:** the hex in the rarity colour with a few calm drifting dots.
- **The screen behind** shows a faint version of the same theme:
  - Volta: lightning flashes light up the dark world.
  - Duke: embers.
  - The Shadow: purple smoke at the bottom.
  - Atlas: soft light beams.
  - Coach Sam to Coach Rex: the haze in the rarity colour.
- **The card is alive:**
  - His picture slowly breathes, with a small flex every ~6 s.
  - The evolve button's glow (ReadyGlow): a soft glow in the theme colour past the edge, and a bright highlight travelling round the outline.
  - The card floats (±4 px) and leans a little toward the mouse or finger. With no pointer (phones) it sways slowly.
  - A faint light sheen over the picture follows the lean.
  - Legendary and better: small particles escape from the card's edges (sparks, embers, smoke, gold petals), at most 8 at a time.
- **Text:**
  - The rarity pill glows in its colour.
  - The NAME is bigger (30 -> 38) and a shimmer sweeps across it once on every card (gold on Legendary+).
  - The boosts are stat rows like MY TRAINERS: an icon in a coloured badge and "+35% EXP", "+35% COINS", "+9% PROGRESS". They pop in one by one with a tick.
  - NEW! stamps in with a bounce, and a dupe's "X2 · 2/3 TO IRON-BORN" bar fills up.
- **Bottom bar:**
  - "1 NEW" is a gold sticker with white words; dupes show in white next to it.
  - TAP TO CONTINUE is white and pulses gently.
  - ROLL AGAIN has a coin and the price, a soft red glow and the usual press. CLOSE stays dark.
  - The bar slides up only after the stat rows finish. A tap brings it at once.
- **To make room for the stat rows:** the picture area is a little shorter (180 -> 165), so phones keep a bigger card.
- **Light on phones:**
  - Only a few particles; half with low graphics.
  - Every effect stops and is removed when the reveal closes (checked: no leftovers, blur gone).
  - Reduced Motion: no lean or sway, no lightning or flashes.

## Tested (Studio)
- **PC size (972x584):**
  - Coach Sam (Common, dupe)
  - Coach Rex (Epic, 2 rows, dupe bar filling)
  - Volta: storm (shot 03 holds one lightning strike still for the picture). Measured 4 lightning strikes in 6 s, the dark world lightening with each, 3 border sparks and 6 escaping particles.
  - The Shadow (Mythic, NEW!, "1 NEW" sticker)
  - Atlas (Secret, NEW!)
- **Phone layout (844x390, `TestPhoneSize`):**
  - Duke (forge, NEW!)
  - an X3 (Sam, Nia, Lou: bar after the rows)
  - The Shadow (dupe; the eyes glint)
- No script errors. Logic tests all pass.
- **Changed after the screenshots:**
  - Atlas's beams were softened: they looked like hard stripes. Shot 05 is from before.
  - The laurel leaves now sit in pairs.
  - The Shadow's smoke is lighter.

## Not tested
- 667x375 and tablet.
- A real phone: the frame rate with an X3 of Legendary+ cards.
- Reduced Motion by eye.
- The motion itself: no clip; still screenshots only.

## Needs the owner's eye
- **Phone card size:** on a phone a single Mythic / Secret card with a dupe bar fits at about 70% size (the height is the limit), so its stat rows are small. If that is too small, the picture can get shorter again, or the stat rows can move beside the picture on phones.
- **Not from this prompt:** a one-line change in SettingsClient, already in Studio (the settings labels lost `KeepItalic`), was backed up to GitHub with this commit.

![[GYM ARC/Screenshots/prompt56/01_sam_common.jpg]]
![[GYM ARC/Screenshots/prompt56/02_rex_epic_two_rows.jpg]]
![[GYM ARC/Screenshots/prompt56/03_volta_storm_strike.jpg]]
![[GYM ARC/Screenshots/prompt56/04_shadow_new.jpg]]
![[GYM ARC/Screenshots/prompt56/05_atlas_clouds.jpg]]
![[GYM ARC/Screenshots/prompt56/06_duke_forge_phone.jpg]]
![[GYM ARC/Screenshots/prompt56/07_x3_phone.jpg]]
![[GYM ARC/Screenshots/prompt56/08_shadow_phone.jpg]]
