# EVOLVE revamp, 18 Nov 2026

This was the "work on the game for 4 hours" session, followed by the owner's "3 more hours, think of yourself as the owner" session. The place was saved in Studio as **version 21**. The owner publishes.

## HUD: the owner's ChatGPT mock look
The owner compared our Neon HUD with a ChatGPT mock and said the mock was "SIGNIFICANTLY WAY BETTER". So the HUD was rebuilt to match the mock.

New generator: `Assets/UI art/scripts/hud.html`. The skill copy is `roblox-ui-pro/assets/develuper-kit/hud.html`. Asset ids are in `ids_hud.json`.

| Piece | What it is |
|---|---|
| `hudPlate` | Status plate: light blue bevel rim, deep navy face, cut corners, cyan corner brackets and slashes (330×128) |
| `port1`–`port12` | Gold hex portrait, one cartoon face per species **group** (Monkey → Cosmic Being) |
| `titleBand` | Brush stripe behind "Tiny Monkey · **Gen 1**" (Gen in gold, RichText) |
| `slot`, `miniTrack`, `fillGold` | Rows with an icon: hourglass + gold age bar; chevrons + "Next: Tree Monkey **0/1**" (count in cyan) |
| `sqGreen` / `sqBlue` / `sqPurple` | One colour per menu button; the Shop got a new `stall` icon |
| `dnaPlate` | DNA counter; the helix breaks out of the plate, with a green "+" to the Robux shop |
| `plate9` | 9-slice version for windows, toasts, the evolve banner and the world board |
| `magnet` | Horseshoe magnet icon for the DNA Magnet card (134837634359789) |

## "I cannot see at all": HUD moved out of the way
The owner and their friends tested it. The 1.7x HUD in the top centre covered the game.
- Everything persistent now sits in the **top-left corner**: the DNA plate, the menu buttons, and the status plate to their right.
- The root scale is capped at 1.2 (`k = clamp(min(W/760, H/400), .72, 1.2)`).
- The status plate is shown at 0.8 on PC and 1 on phones.
- Toasts slide in under the cluster.
- The evolve banner sits in the **lower third** (y 0.76, scale 0.85), not the centre.

## 100 species
"We need like 100 evolutions." The 12 species became 100 stages in 12 portrait groups:
- Monkeys → apes → early hominins → Homo habilis … floresiensis → erectus → heidelbergensis
- → sapiens → Modern Human … Superhuman → Cyborgs → Space → Digital → Cosmic (Omniverse at 1000 evolution points).
- The first species come one per life (thresholds 0, 1, 2 … 9, 11, …), so something new arrives every minute at the start.
- The 24 pre-modern stages have their own fur colour.
- Diets unlock by stage: Meat at Gibbon, Cooked at Homo erectus, Farmed at Farmer, Synthetic at Cyborg.
- The banner says "Species N / 100" with the group's portrait.
- Old saves are migrated: "S:Monkey" → every species up to your current stage is marked found.

## Growth teleport bug fixed
"When I get taller, I teleport back to the place I was 0.5 seconds ago." The cause was the server's `Model:ScaleTo`, which re-pivots at the lagging server position.

Now the server grows R15 bodies through the Humanoid scale values (`BodyHeightScale` etc.). R6 still uses ScaleTo as a fallback. Tested while walking: 0 backward steps.

## Index
- A tile for each of the 100 species, with that group's portrait.
- Unfound species are shown as a **navy shadow** (ImageColor3 50,60,100) with "???". The face shows faintly, so kids can see what's coming. Pure black looked like an empty hex.

## DNA orbs (revamped)
- **Spawning:** one orb appears every 3 s, 10–28 studs from you. At most 5 are out at once, and each lasts 25 s.
- **Reward:** touching one gives max(3, 4 s of DNA).
- **Look:**
  - a soft ForceField shell with a neon core;
  - a point light and a few sparks;
  - the helix billboard so kids read it as DNA.
- **Motion:** each client bobs and spins orbs locally from the `BaseY` attribute, while the server keeps them still so touches stay fair.
- **Golden orbs:** 6% chance, worth 10× (tested: 40 DNA instead of 4). The popup reads "GOLDEN +N DNA", bigger and in gold.
- **DNA Magnet pass (R$149):** your orbs within 30 studs are collected every second. The card is cyan with the magnet icon. *The pass logic is not playtested, because Studio can't own a pass.*

## Top Evolvers world board
- **Where:** `workspace.TopBoard`, a 16×10 panel on two wooden posts, 30 studs in front of spawn, facing it. The model can be moved freely; the script only looks for `Panel`.
- **Ranking:** top 10 players, ranked by species reached, then Gen. The data is in the OrderedDataStore `EvolveTop_v1`, written on every save, and the board refreshes every 60 s.
- **Live players:** players on the server are merged in, so the board is up to date before the next save and works in Studio.
- **Look:**
  - plate9 art, darkened (ImageColor3 150,155,175), because the world's colour correction brightened it;
  - a gold "TOP EVOLVERS" title;
  - gold, silver and bronze for #1–#3;
  - long names shrink to fit.

## Other new content
- **Upgrades:**
  - Lucky Genes: +4% mutation chance per level.
  - Immunity: 15% less disease risk per level.
  - Both cap at level 10, and the shop shows "MAX" at the cap.
- **Super Genes pass (R$249):** 2x mutation chance, and good genes are never lost.
- **"+" on the DNA counter** opens the Robux tab.
- **Daily streak:** day N gives 100 × N DNA, times the Ancestor multiplier, up to day 7. Missing a day starts the streak over. There are no timers.
- **Evolve celebration:**
  - On screen: the banner with the portrait. News waits behind it, and it replaces the duplicate toast.
  - In the world: a neon beam and a particle burst where the old body was.
- **leaderstats:** Gen and Species.
- **Robux card names:** Skip 5 Lives, Skip 20 Lives. "Skip 5 Generat…" was cut off.

## Sounds
These are Creator Store audio, inserted into `SoundService` as `SFX_*`. Audio created by a script failed to load until it was inserted into the place.
- **Rule:** one sound per moment. Routine toasts stay silent.

| Sound | Asset | Plays on |
|---|---|---|
| click | 88442833509532 (AmbientSorcery) | every button |
| pickup | 4612374209 | orb pickup |
| evolve | 138029541636833 (Audioscape) | evolve banner |
| news | 17669542615 (mixkit pop) | news toasts with priority ≥ 7 |

## Owner to-do
- **Game pass ids:** create the **Super Genes** and **DNA Magnet** game passes in Creator Hub. Put their ids into the `STORE` table in `ServerScriptService.Evolution`. All pass and product ids are still 0, so nothing can be bought yet.
- **Publish when happy.** The world board and saving only work in the live game, or in Studio with API access turned on.
- **Listen to the four sounds.** They were chosen by name and length, not by ear.

## Backups in Studio
- `ServerStorage.Evolution_backup_before_revamp`
- `ServerStorage.Evolution_backup_before_100`
- `ServerStorage.LightingBackup_before_world`
