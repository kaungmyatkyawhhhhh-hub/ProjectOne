# EVOLVE revamp, 18 Nov 2026

This was the "work on the game for 4 hours" session, followed by the owner's "3 more hours, think of yourself as the owner" session. The place was saved in Studio as **version 30**. The owner publishes.

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

## Evolution tree (owner: "multiple evolution tree?")
The 100-stage ladder is unchanged, so pacing stays the same. At three forks you pick a path, and each path has its own species for that stretch.

| Fork | Stages | Paths (first species) |
|---|---|---|
| F1 "Where will your family live?" | 2–16 | Forest (Tree Monkey, the old line) · Savanna (Grass Monkey, sandy fur) · River (Swamp Monkey, wet grey fur) |
| F2 "The Ice Age is coming!" | 37–41 | Ice Age (Heidelbergensis) · Sea Coast (Shore Gatherer) |
| F3 "Choose your future!" | 61–90 | Machines (Cyborg, port9) · Space (Rocket Kid, port10) · Digital (Smart Glasses, port11) |

**How picking works**
- You pick while you're the species just before the fork.
- The picker window opens by itself once per life, but never over another window or the evolve banner. The HUD row says "Next: tap to pick a path!", and tapping it also opens the picker.
- Evolution waits up to 3 lives for your pick, then takes the first path ("Your family took the Forest path"). Idle and offline players never get stuck.

**Replay value**
- Rebirth resets your path, so you can take a different one next run.
- The Index now has **195 species** (it was 100), so filling it takes several runs.

**Code changes**
- Server: `FORKS`, `nodeOf(d, depth)`, `pendingFork`, the `ChooseFork` remote, and `d.Path` (e.g. "F1=Savanna"). The Index order comes from `ALL_SPECIES`.
- Old saves are migrated: Forest, Ice Age, and the future path that matches the species they already are (stages 71–80 → Space, 81–90 → Digital).
- The banner now says "Stage N / 100".
- Diet unlock labels now say "stage 9" and "stage 61", because Gibbon and Cyborg are only on some paths.

**Tested:** the picker opens at the start, picking Savanna leads to a Grass Monkey with sandy fur, and the Index reads 2/195.

**Not tested in Play:**
- the F2 and F3 pickers;
- the 3-life auto-pick. The server's 1100-generation self-check passes through it.

**Still open:** paths share one portrait per group, so the F1 cards all show a monkey face. Per-path portraits would make the choice pop more.

**Backup:** `ServerStorage.Evolution_backup_before_tree`.

## Curiosity hooks (owner: "bring in as much curiosity as possible")
- **Locked Index tiles say where to look.** A forked species shows "??? / River path", so kids can see that other paths exist and come back to try them.
- **Secrets section** (8 entries, `X:` in Index): each shows only a riddle clue until found. Finding one gives a pink "SECRET FOUND: … +N DNA" toast (priority 10, plays the news sound) and 2 minutes of DNA. Saved as `SECRETS` in the server script.

| Secret | Clue |
|---|---|
| Golden Monkey | A monkey that grabs gold |
| Giant Ape | An ape born a giant |
| Tiny Titan | Very small, very far in the future |
| Mutant King | Born with 3 mutations |
| Survivor | Get sick 5 times |
| Orb Hoarder | Grab 200 DNA orbs (new `d.Orbs` counter) |
| Path Walker | Live in forest, grass AND river |
| Time Traveler | Start over 3 times |

**Tested in Play:** Golden Monkey was found on a golden orb, the toast showed, and the Index read Secrets 1/8. Place saved as v25.

**Next curiosity ideas, not built yet:**
- per-path portraits;
- a "what's at the end?" teaser on the fork cards;
- secrets that change your body, not just the Index.

## Global layer (owner: "the entire game is like a global game instead of progressing solo?")
**Decision:** keep your own family (kids need progress that's theirs) and add a shared world on top.
- **World Age:** every life anyone lives, on any server, is summed once a minute in DataStore `EvolveWorld_v1` under key `Gens`. Age thresholds are 0 / 500 / 2k / 6k / 15k / 40k / 100k / 250k / 600k / 1.5M / 4M. Each Age gives **every player +5% DNA**, up to +50% at Age 10. When the world reaches a new Age, every server announces it. The HUD shows a World pill under the menu buttons: "World Age N +X% DNA" with a gold bar to the next Age.
- **World firsts:** the first player ever to find each species or secret gets their name saved forever (key `Firsts`, written with UpdateAsync so two servers can't both claim it). Every server is told through MessagingService: "World first! NAME found Grass Monkey (+N more)". Found Index tiles show "1st: NAME".
- **Global already:** the Top Evolvers board (OrderedDataStore).
- **In Studio** (DataStore off), everything falls back to this server only. Tested: the World pill draws, firsts are claimed, and the Index shows "1st: …".
- **Shortcut:** if the minute's DataStore write fails, those lives aren't added to the world total, and lives lived in a server's last minute before it shuts down aren't sent either.
- **Untested until publish:** real cross-server messages and the real global total.
- **Backup:** `ServerStorage.Evolution_backup_before_world`. Place saved as v26.

**Ideas for later:** a weekly world goal with a reward chest, and a world Index page showing how many players found each species.

## Shared frontier (owner: "if 1 guy progresses alone and the others are maxed out, he won't be curious")
**The fix:** nobody can max out ahead of the world. The furthest open stage depends on World Age:
- Age 0: stage 60 (Superhuman, so rebirth works from day one)
- Age 1: stage 70
- Age 2: stage 80
- Age 3: stage 90
- Age 4: stage 95
- Age 5: all 100 stages

World Age thresholds were lowered to 300 / 1.2k / 4k / 10k / 25k / 60k / … lives.

At the frontier, the HUD says "Next: ??? opens at World Age N", and locked Index tiles say "??? World Age N". Newcomers and veterans chase the same mystery.

**Trail:** after the first fork, if you're more than 20 stages behind the frontier, you evolve 2x. The HUD shows a green "2x". New players quickly catch up to where everyone else is.

**Age announcement:** "The world reached Age N! New species opened! +X% DNA for everyone".

**Tested:** the Index shows "World Age 1" past stage 60, and the self-check runs a full game in a fully aged world.

## Simpler for new players (owner: "this game is a bit complex")
New players see only Shop and Index. Other things appear with a small pop when they start to matter:

| Feature | Appears when |
|---|---|
| Diet button | stage 9 (the Index button slides over until then) |
| World pill | stage 5 |
| Lucky Genes and Immunity cards | stage 9 |
| Extinction card | once rebirth is possible (before that it isn't shown at all) |

The path picker doesn't open by itself during a new player's first 20 seconds.

## Camps: how new players are born (owner wanted "new players spawn when 2 people…")
**Rejected:** I turned down a mating mechanic because it breaks Roblox's rules on romantic and sexual content. The owner then turned down "high five" as childish.

**Built:** "Build camp" ProximityPrompt on every character (each client hides its own).
- One player presses it on another, and the other has 15 s to press it back. This lights a campfire between them: a stone ring, crossed logs and a Fire effect.
- Both players get 20 s of DNA. The same pair has to wait 60 s before building another camp.

**Births:**
- The next 3 brand-new players who join the server are born at that camp ("born into A & B's tribe"), and both builders get 60 s of DNA each time.
- Joins are never blocked. If there are more newcomers than camps, the extras are born next to a random player, who gets the gift.
- If there are more camps than newcomers, camps wait and burn out after 10 minutes. A server holds at most 6 camps; a 7th removes the oldest.

**Not tested in Play:** needs 2 players. A solo Studio test confirmed the prompt is on the character and hidden for its owner, and the camp visual was checked.

## Light enough for huge servers (owner: "if the game is light to run, there can be huge player servers")
- **DNA orbs have no server parts any more.** The server keeps orb spots in a table, tells only the owner through the `Orbs` remote ("add" / "del"), and checks pickups by distance 5x a second (5 studs). The client draws and bobs its own orbs in `workspace.MyDNAOrbs`. Before this, every player's 5 glowing orbs (with light, sparks and a label) were sent to every client, and every client animated all of them each frame. Tested: walking into an orb picked it up (DNA 105 → 110), and no server orb folder exists.
- **Graves:** 6 per player instead of 15.
- **Towns:** 16 plots. Players past 16 keep their civilization progress but get no physical town. Code marks this as `shortcut:`.
- **MaxPlayers is currently 60.** Raising it is a Creator Hub setting (Places → Server size, up to 700). That's the owner's call. Test with ~50 first, using the Studio local server test with 8–10 players, to watch server heartbeat.
- **Backups:** `ServerStorage.Evolution_backup_before_frontier`, `Evolution_backup_before_light`. Place saved as v30.

**Still heavy at big sizes (next):**
- every life reloads the character with `LoadCharacterWithHumanoidDescription`;
- the evolve beam and burst are seen by everyone;
- the per-player town models.

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
