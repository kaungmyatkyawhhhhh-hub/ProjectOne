# MEGA BITE - New evolutions after the Megalodon: plan and design sheets (13 Nov 2026, 13:05-13:40)

Owner 12:37: "all my friends said the game needs some polishing and also more evolutions cuz they got to megalodon and game got boring". Owner 12:43: "ok do next".
Status: **design sheets made, nothing built yet.**

## Decision (research first, then decided)
- This morning's kid sims said the same thing ("nothing to do after Megalodon"). Titan Levels (built today) is a bar, not a new shark. Friends asked for new sharks to become.
- Hungry Shark Evolution, the game we take our ladder feel from, continues after the Megalodon with prehistoric sea monsters: Big Daddy (Dunkleosteus), Mr. Snappy (Mosasaurus), ..., Leo (Liopleurodon), Nessie (Hungry Shark Wiki, Megalodon page, "Common Sharks" list). Real prehistoric animals are free to use; we draw our own, with our own names and looks. No HSE names, characters or art.
- Three new evolutions, built one at a time:

| # | Creature | Look | Why |
|---|---|---|---|
| 8 | **Dunkleosteus** | ivory armoured head with bone blades, emerald body, lime glow lines | the real "next after Megalodon"; a new silhouette (helmet head), still a fish, so the shark rig and clips fit |
| 9 | **Mosasaurus** | teal tiger stripes, orange belly, four flippers, orange glow | kids know it from dinosaur films and toys; long reptile shape |
| 10 | **Leviathan** | black scales, red belly, gold glowing sail and horns | a legend as the final form; the longest; swims sideways like an eel, so the same rig works |

- Dropped: a giant whale (tail moves up and down: needs a new rig and new clips), the Kraken (already the boss), a robot or demon shark (not our theme).
- Each one keeps the family marks of our sharks: glowing eye orb under an angry brow, glow lines, closed grin, no gore.

## Sheets (ChatGPT, one conversation, the approved Megalodon sheet attached once as the style)
- Files: `Art\HSE_sheets\mb_hse_dunkleosteus.png`, `mb_hse_mosasaurus.png`, `mb_hse_leviathan.png`; all three in `MEGA_BITE_new_evolutions_sheets_13Nov.jpg`.
- Conversation: "Create Megalodon Model", https://chatgpt.com/c/6af6aebf-c2a4-83ec-bb43-50443bbd7313 . All three came out in one try.
- Common prompt: "Create ONE image, 1536x1024. Flat solid MAGENTA #FF00FF background, no gradient, no shadow on it, no magenta or pink-purple anywhere in the art. A character turnaround sheet of ONE giant sea monster (a HERO form the player grows into: the next evolution after the shark in the attached image) for a kids' mobile game, orthographic views, in EXACTLY the same layout as the attached image: TOP ROW the side view (nose pointing right, body straight and horizontal, the whole body from nose to tail tip, mouth CLOSED); BOTTOM LEFT the top view seen from directly above, the same length, nose pointing right; BOTTOM RIGHT the front view facing the viewer, mouth closed. Wide empty magenta space around each view; no view touches another view or the image edge. STYLE: match the attached image exactly: glossy 3D cartoon render like a premium mobile shark game, soft shading with highlights, a clean dark outline around every shape, thin glowing lines on the body, a small round glowing eye (a glowing orb, no slit pupil) under an angry brow, a closed confident grin. Fierce and cool but kid-friendly: no blood, no wounds, no gore. THE CREATURE: ... NO text, NO numbers, NO letters, NO bubbles, NO extra objects, NOT a photo."
- Dunkleosteus: "an original DUNKLEOSTEUS, the armoured prehistoric fish, heavier and more massive than the shark in the attached image, about 3.2 times as long as it is tall. The front third of the body is a huge rounded HELMET of thick bony armour: 5 or 6 big smooth plates in pale ivory-bone colour with darker tan seams ... a blunt, tall, bulldog-like face. Instead of teeth it has sharp bony BLADES: one pair hanging from the front of the upper jaw and one pair rising from the front of the lower jaw; with the mouth closed in a heavy underbite grin the blade tips overlap ... A small round glowing YELLOW-GREEN eye set in a bony ring under a heavy armour brow. Behind the armour: a thick muscular shark-like body in deep EMERALD GREEN with a pale cream belly, divided by a clean zig-zag line; thin glowing LIME-GREEN lines ... one tall rounded dorsal fin, two broad pectoral fins, two small pelvic fins, one small anal fin, a long tail fin with a big upper lobe and a small lower lobe ..."
- Mosasaurus and Leviathan: follow-up messages with only the creature text and the rules repeated (full text is in the conversation).
- Watch when building: the Mosasaurus and Leviathan side views come within about 12 px of the right edge of the picture.

## Build plan (per creature, in this order)
1. FishKit v3 from the sheet (`/tmp/claude-0/fish`, same kit as the Megalodon HSE9: closed mouth traced from the sheet, Jaw bone, fin atlas), triangle budget about 15-18K for a hero. Gates: outline, face landmarks, flat render at the sheet's pixel scale.
2. Four skins (`skins2.py`), upload model + skins, wait for Approved.
3. Studio: `MB_InstallV2`, clips module (the shark clips re-scaled to the new rig), `C.Evolutions` entry, ability, quest text, Shop and Index entries, evolve cutscene check.
4. EXP curve: first proposal Megalodon 40,000 -> Dunkleosteus 150,000 -> Mosasaurus 500,000 -> Leviathan 1,500,000; to be tuned with the impatient-kid long sim before it goes in. Titan Levels start after the LAST evolution automatically (`#C.Evolutions`).
5. Sizes: first proposal 46 / 56 / 70 studs long (Megalodon is 40).
6. Abilities: new ones (working names BONE CRUSH, MEGA LUNGE, MAELSTROM), each with its own VFX and code-made sound.

## Open
- Owner has the sheets (13:38) and has not judged them yet.
- "Polish": asked the owner what the friends pointed at; no answer yet.

Sources: https://hungry-shark.fandom.com/wiki/Megalodon_(HSE)
