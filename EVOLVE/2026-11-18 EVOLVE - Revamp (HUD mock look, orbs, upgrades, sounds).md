# EVOLVE revamp, 18 Nov 2026

This was the "work on the game for 4 hours" session. The place was saved in Studio as version 15; the owner publishes.

## HUD: the owner's ChatGPT mock look
The owner compared our Neon HUD with a ChatGPT mock and said the mock was "SIGNIFICANTLY WAY BETTER". So the HUD was rebuilt to match the mock.

New generator: `Assets/UI art/scripts/hud.html`. The skill copy is `roblox-ui-pro/assets/develuper-kit/hud.html`. Asset ids are in `ids_hud.json`.

| Piece | What it is |
|---|---|
| `hudPlate` | Status plate: light blue bevel rim, deep navy face, cut corners, cyan corner brackets and slashes |
| `port1`–`port12` | Gold hex portrait, one cartoon face per species (Monkey → Cosmic Being) |
| `titleBand` | Brush stripe behind "Monkey · **Gen 1**" (Gen in gold, RichText) |
| `slot`, `miniTrack`, `fillGold` | Rows with an icon: hourglass + gold age bar; chevrons + "Next: Ape **0/3**" (count in cyan) |
| `sqGreen` / `sqBlue` / `sqPurple` | One colour per menu button; the Shop got a new `stall` icon |
| `dnaPlate` | DNA counter; the helix breaks out of the plate, with a green "+" to the Robux shop |
| `plate9` | 9-slice version for windows, toasts and the evolve banner |

Checked at PC size and at an emulated 844×390 phone. The status plate sits right of the menu column on narrow screens.

## New content and features
**DNA orbs**
- A glowing orb with a helix billboard spawns every 3 s near you. There are at most 5 at a time, and each lasts 25 s.
- Touching one gives max(3, 4 s of DNA), shows a floating "+N DNA" and pops the DNA counter.

**Upgrades**
- Lucky Genes: +4% mutation chance per level.
- Immunity: 15% less disease risk per level.
- Both are capped at level 10, and the shop shows "MAX" at the cap.

**Monetization**
- New Super Genes pass, R$249: 2x mutation chance, and good genes are never lost (Weak Heart can still be lost).
- The "+" on the DNA counter opens the Robux tab.

**Daily streak**
- Day N gives 100 × N DNA, multiplied by the Ancestor multiplier, up to day 7.
- Missing a day starts the streak over. There are no timers.

**Evolve celebration**
- A centre "EVOLVED!" banner shows the new species' portrait and "Species N / 12". News waits behind it, and it replaces the duplicate toast.
- In the world, a neon beam and a particle burst appear where the old body was.

**Leaderboard**
- `leaderstats` shows Gen and Species.

## Sounds
These are Creator Store audio, inserted into `SoundService` as `SFX_*`. Audio created by a script failed to load until it was inserted into the place.
- **Rule:** one sound per moment. Routine toasts stay silent.

| Sound | Asset | Plays on |
|---|---|---|
| click | 88442833509532 (AmbientSorcery) | every button |
| pickup | 4612374209 | orb pickup |
| evolve | 138029541636833 (Audioscape) | evolve banner |
| news | 17669542615 (mixkit pop) | news toasts with priority ≥ 7 |

- I skipped results ripped from other games (Undertale, Slime Rancher, Darkest Dungeon).
- **Kid-sim follow-up:** the news sound is the cue the 5–6-year-olds were missing.

## Owner to-do
- Create the Super Genes game pass in Creator Hub and put its id in the `STORE` table in `ServerScriptService.Evolution`. All pass and product ids are still 0.
- Publish when happy.
- Listen to the four sounds in Studio. They were chosen by name and length, not by ear.

## Backups in Studio
- `ServerStorage.Evolution_backup_before_revamp`: server script before this session.
- `ServerStorage.LightingBackup_before_world`: lighting before this session.
