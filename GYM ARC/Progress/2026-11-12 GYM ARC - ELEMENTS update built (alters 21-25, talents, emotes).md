---
date: 2026-11-12
tags: [gymarc, progress, elements, update]
---
# GYM ARC: ELEMENTS update built (12 Nov, for Sat 14 Nov)

Owner: "ok lets work on this weeks update". The plan is [[2026-11-11 GYM ARC - Next update decision (fix hotfix, then ELEMENTS 14 Nov)]].
Studio is saved as **version 1868, NOT published**. Art was made in the new PC's Chrome (owner: "use chrome from my new pc").

## 1. Alters 21-25 (Frost, Storm, Lava, Toxic, Plasma)
- **Art:** 5 ChatGPT textures, made in one chat for a consistent style ("Create Frost Texture").
- **Processing (`seamless.py`):**
  - min-cut quilting, one axis at a time, with a wrap-aware cut;
  - a 2x2 check of every tile: no seams;
  - limb set tiled x2, torso set x4 (the 6 Nov rule);
  - colour, normal and roughness maps; no metalness.
- **Files:** `Downloads\gymarc_elements\` (30 maps).
- **Uploads:** to Myanmar Builders Club (group 33151111); all 30 Approved.
- **Config/ArtIds.Skins:** `frost` / `storm` / `lava` / `toxic` / `plasma`, each with L and T sets.
- **Config/Alters:**
  - `textures = art(...)`, `mean`, `tone = "Raw"`;
  - `RawPlain` head colours (the map average x0.9).
- **ReplicatedStorage.SkinStages:** `Alter_<id>` + `Alter_<id>_T` built by hand. The AlterSkinsArt builder in Edit used a cached Alters module and skipped them.
- **Config/AlterLooks:** one look per element, kept below the Robux skins (max 2 pieces, light 1.5 / range 10).

| Alter | Shape | Light | Idle | Rep | Flex | Footstep |
|---|---|---|---|---|---|---|
| Frost | ice spikes on the shoulders | ice-blue light | frost mist | ice sparkles | frost burst | IceCrack |
| Storm | crackling chest core, storm cuffs | — | sparks | sparks | lightning veins | Sparkle |
| Lava | molten core | — | embers | ember burst | lava cracks | glowing steps |
| Toxic | toxic core | — | green fumes | slime drips | toxic veins | squelch |
| Plasma (tier finale) | pink crown, violet arm crystals | prism light | pink sparkles | prism beams | chrome ripple | — |

- **Gate:** `Alters.LastAvailable` needs the LiveEvents unlock `ElementAlters`. Before launch, "MORE ALTERS SOON" stays at 20; after launch it moves to 25.
- **Tested in Play:** Lava and Plasma on my test body. The skin maps load and the pieces, light and particles show. No errors.

## 2. Gem posing division = Flint's reward
- `PosingCompService`: a Gem-tier player (alters 16-20) who hasn't beaten Flint poses in the **Metal** division. Beating Flint opens Gem.

## 3. Three element Run Card talents
- **STORM SURGE** (Rare): every 20th rep is a LIGHTNING rep worth 5 reps, with a bolt effect.
- **FROST FOCUS** (Rare): 60 s of reps on one machine = CHILLED, +20% EXP until you leave it or stop for 10 s.
- **ERUPTION** (Legendary, needs Storm Surge): each lightning rep starts 15 s of 2x faster reps.
  - Uses the Adrenaline path: half-EXP split, safety net.
  - Cooldown 1 min.
- **Code:**
  - Config/RunCards: Talents, FULL rules, `RunCards.TalentOpen`. A talent with `unlock` is offered only once its icon id exists AND the update is live.
  - TalentService: OnRep, AfterRep, ExtraFor, SpeedPart.
  - TalentClient: popups, the bolt effect, and the chips CHILLED / ERUPTION / STORM n/20.
  - RunCardTip: status lines.
- **Icons:** ChatGPT, with the existing talent set attached as the reference. `Assets\icons_runcard_talents\rare_storm_surge / rare_frost_focus / legendary_eruption.png`. Ids:

| Talent | Asset id |
|---|---|
| Storm Surge | 111700733358350 |
| Frost Focus | 99015428265606 |
| Eruption | 134089211134520 |

- **Tested (server, with these cards held):**
  - rep 20 gave +4 reps' EXP;
  - Eruption gave 15 s at speed 2;
  - Frost: no bonus before 60 s, +20% after 62 s, nothing on another machine.

## 4. Emote icons (the 8 poses)
- The ChatGPT prompt from the 10 Nov part 3 note, cut into 8 icons.
- Files: `Assets\icons_emotes\emote_<id>.png`.
- `Config/ShowOff.EmoteIcons`. EmoteClient shows the illustrated icon (56 px) and keeps the old icon only as a fallback. Checked in the Emotes window.

## 5. Launch
- **Config/LiveEvents Elements:** `enabled = true`.
  - Opens Sat 14 Nov 15:00 (same convention as the Gem launch); countdown from 24 h before.
  - Cutscene "Elements"; reward: title Element Rush + x1.5 for 30 min; NEW popup for returning players.
- **Title tag:** `[🔥ELEMENTS] GYM ARC`. Set it on Saturday when the update goes live.
- **Discord post (draft):**
  > 🔥 **ELEMENTS UPDATE is LIVE!** 5 new Body Alters: **Frost, Storm, Lava, Toxic, Plasma** (up to 7'8"), each with its own look. 3 new Run Card talents (Storm Surge, Frost Focus, Eruption), a Gem posing division for everyone who beat Flint, and new pose icons. Be online at the opening for the **ELEMENT RUSH** title + 30 min of x1.5 EXP & coins!

## Owner: before Saturday
1. File > Save is done (v1868). Play once on a phone: the Emotes window, a Run Card pick, the countdown.
2. Publish when you're happy. This build also carries the 12 Nov fixes (UI loops, shorter tutorial).
3. Saturday: change the title tag and post on Discord.

## Not done / later
- An element VFX sheet: not needed, because the looks reuse the 6 Nov VFX art (tinted).
- Shape pieces for alters 6-15 stay on 21 Nov.
