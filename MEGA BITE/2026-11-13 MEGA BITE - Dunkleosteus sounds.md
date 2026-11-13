# MEGA BITE - Dunkleosteus sounds (13 Nov 2026, 14:20-14:45)

Owner 14:19: "put sfx for the new ones". The new one in the game is the Dunkleosteus (evolution 8); it used the Hammerhead's ram sound and the shared bite.
Status: **in Studio, tested in Play, not published.**

## The sounds (our own synth, code in `Audio\dunkleosteus\dunk_sfx.py` + `sfxlib.py` = the helpers of `Audio\abil3\abil3.py`)
Family: bone and stone (armour plates, bone blades) with a lime-green glow shimmer, so it never sounds like the Hammerhead.

| Name | What it is | Length | LUFS / true peak | Asset id (Approved) |
|---|---|---|---|---|
| BoneBite (3 takes) | two bone blades snapping shut (a hollow wood-block TOK, not teeth) + the heavy jaw + a crunch + bubbles | 0.55 s | -14.1 / -1.5 to -2.2 dB | 70831803825527, 134012567956136, 135764103492917 |
| BoneRam | the ability BONE RAM on the HammerRam clip's timeline: armour plates locking + deep growl, charge whoosh, the skull TOK at 0.42 s (the clip's Ram marker), rubble, lime shimmer, bubbles | 1.70 s | -13.1 / -1.7 dB | 115950574660984 |
| EvolveAncient | evolving INTO the Dunkleosteus: horn + plates rising, the hit on the cutscene's white flash at 1.1 s, G-major bells + glow + bone chips | 3.30 s | -13.6 / -1.1 dB | 119956363824077 |

Listening file: `Audio\dunkleosteus\MEGA BITE - Dunkleosteus sounds (bite x3, Bone Ram, evolve).mp3`.

## Wiring
- `MB_Sounds`: new `remap`: a shark model can carry its own version of a sound with the attribute `MB_SoundMap` (`"Bite=BoneBite,HammerRam=BoneRam"` on `Sharks.Dunkleosteus`). Sounds placed on that shark are swapped. 2D sounds use the local player's own shark, but only for `Bite` and `Gulp` (the Kraken's slam also plays `HammerRam` in 2D and stays the Kraken's).
- `GameConfig`: `C.SoundPitch[8] = 0.72` (the shared body sounds — swish, gulp, dart, hurt — play deeper for the biggest shark); evolution row 8 `evolveSound = "EvolveAncient"`.
- `MB_HUD` evolve cutscene: plays the new evolution's `evolveSound` when it has one, else the usual `Evolve`.
- Backups: `MB_Sounds_preDunkSfx_13Nov`, `GameConfig_preDunkSfx_13Nov`, `MB_HUD_preDunkSfx_13Nov`.

## Tested (Play)
- Eating (2D bite) and a bite on the shark -> BoneBite; the ability on the shark (pressed F) -> BoneRam playing; the Kraken slam (2D HammerRam) -> still the Hammer sound; swish at speed 0.70.
- Evolving Megalodon -> Dunkleosteus: the cutscene plays EvolveAncient ("DUNKLEOSTEUS! ... NEW ABILITY: BONE RAM!").
- 0 script errors.

## Note
- The test account was at FOSSIL IV with 274K EXP when this Play session started (it was FOSSIL III, 1.4M EXP earlier): a Fossilize happened between sessions, not from these tests (only the Fossilize button sets FossilTier). EXP was put back to what it was at the start of the session.
- Mosasaurus and Leviathan get their own sound sets when they are built (same MB_SoundMap way).
