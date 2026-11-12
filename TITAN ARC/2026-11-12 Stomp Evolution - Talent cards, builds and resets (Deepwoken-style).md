# Stomp Evolution: talent cards, builds and resets (12 Nov 2026, 20:51-21:50)

Owner (20:51): "make players choose talent cards from deepwoken and then make a build which then they can reset the build like deepwoken when something happens u decide".

## Research: how Deepwoken does it (web, 12 Nov)
- Talents are cards. Every Power level you are shown a hand of cards and pick one. The pool is not fully random: cards have prerequisites (stats, power, other talents), so some only appear once you qualify.
- Rarities: common → rare → **advanced** cards that need several cards of one category and/or high stats.
- **Freeze** keeps a card in your hand for the next level-up; **Burn** deletes a card you don't want. Both use charges that refill as you level.
- A guide NPC can steer the next draw towards one family.
- Builds are reset by the **Shrine of Order** (redistributes stats; the community plans "pre-shrine / post-shrine" builds) and, harder, by a **wipe** (permadeath-style restart). Players plan builds in online "build makers" because a bad build has real cost.
- Sources: Destructoid beginner's guide (cards each Power level, freeze/burn), Pocket Tactics talents page, Deepwoken wiki (Leveling, 2023 version history on Shrine of Order).

## What we copy (the mechanics) and what we don't
Copied: a hand of cards per power-up, pick 1, rarity, advanced cards gated by family count, Freeze, Burn, a respec shrine, and a wipe-style reset with something carried over.
Not copied: any Deepwoken card names, art, icons, stats, factions or words. All 20 cards, the 4 families and both shrines are ours. No combat/stat system (our game is stomping).

## Design (decided by Claude)
- **Power-ups:** 3 per form (two growth stages + the evolve) = 21 by STAR, then one every +15% height (max 24). With no cards left, a power-up gives a +10% Mass shard.
- **Hand:** 3 cards (4 with Colossus). Weights: Common 70, Rare 30, Advanced 40 once unlocked (3 cards of its family). FREEZE 2 / BURN 2 per build (a burned card is replaced so the hand stays full).
- **4 families x 5 cards:**
  - QUAKE (stomp): Heavy Heel +15% Mass · Aftershock 20% +1 prop · Fault Line pound every 12th · Tremor Ring pound +2 props · **Epicenter** pound x10
  - GREED (coins): Pocket Change +20% coins · Lucky Rubble 2x golden · Tax Collector +1 coin/stomp per form · Golden Touch x40 golden · **Midas Stomp** every 25th stomp golden
  - STRIDE (move): Long Legs +12% speed · Big Reach +20% reach · Quick Feet stomp 15% faster · Rhythm 5 in a row = x2 · **Titan Stride** walk into small props to smash
  - GROWTH (mass): Big Bones +10% · Snack Time small props x3 · Overgrowth +25% on your biggest props · Bully x2 coins on tiny props · **Colossus** 4-card hands
- **"When something happens" (the resets):**
  1. **AWAKEN** (the wipe): at the golden altar at the end of the street, only as a STAR. Height, coins, upgrades and the build reset; you keep ONE Legacy card and get x1.5 Mass forever (stacks). Two-press confirm.
  2. **REFORGE SHRINE** (the respec): violet crystal beside the spawn. Costs 200 / 600 / 1.8K ... coins; every card goes back and you re-pick from fresh hands; Freeze/Burn refill; a Legacy card stays.
- All checks on the server (hand membership, charges, standing on the shrine, STAR for Awaken); the hand is saved so leaving and rejoining can't re-roll it.

## Built (Studio, saved v45; not published)
- `Config`: Families, Cards, CardOrder, Rarity, Charges, Power(h), Awaken, ReforgeCost.
- `StompServer`: deal / pick / freeze / burn / reforge / awaken (RemoteEvent `Cards`), card effects inside the stomp maths, power-ups, save fields.
- `TalentUI` (new LocalScript): TALENTS button with a pending badge (key T / gamepad Y), the hand window (cards deal in, hover lift, pick flies away, FREEZE/BURN under each card, frozen look), MY BUILD window (4 family columns, advanced progress "2/3"), shrine panels when you step on them, world signs. Kit plates, drawn family emblems (no images or emoji), text floor 14 px, one window at a time.
- `StompClient`: Big Reach / Quick Feet / Titan Stride on the client, toasts for power-up, new talent, reforge, awaken (gold flash).
- World: `ToyTown.Shrines` (ReforgeShrine at (-20,0,-52), AwakenAltar at (1230,0,0), streaming Persistent).

## Tested in Play
Power-up deals a hand (auto-opens the first time, after the evolve cutscene); picks chain hand to hand; Freeze shows the frozen card and survives into the next hand; Reforge returned 3 cards as 3 picks and took 200 coins; Awaken at STAR reset to 1.70 m with the Legacy card and Awaken 1. No script errors.

## Lessons
- `Instance.new("ScreenGui")` defaults to Global ZIndex: children of a ZIndex 5 window were drawn under it (blank window). Always set ZIndexBehavior = Sibling.
- Models a client script waits for (shrines, pads) must be streaming Persistent, or `WaitForChild` hangs the script.
- A window that opens on an event must wait for its data (the hand attribute arrives after the event) and for cutscenes to end.
- Studio's mouse tool hits small buttons unreliably by pixel; click by instance path in tests.

## Next
- Balance on the live numbers (Epicenter + Fault Line + Tremor Ring stack hard).
- Card art from the ChatGPT pipeline (family emblems are code-drawn for now); a "guide" choice like the research's family-steering NPC could be a later shop item (no paid random).
- Phone check of the hand window (4 cards with Colossus on a 667x375 screen).
